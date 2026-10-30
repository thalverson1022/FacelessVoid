class_name CombatPlayback
extends RefCounted
## Presentation-layer playback controller for an already-resolved
## CombatResolver.CombatResult (user-requested combat-playback addition to
## P2:R7). Combat still resolves synchronously and completely inside
## CombatResolver.resolve() before this class ever sees the result -- this
## class only re-plays the recorded cast/tick event timeline in real time so
## the UI can animate the fight. It performs NO game-rule logic and mutates
## NO run state, per docs/Conventions.md's UI architecture principle: given
## the same result and the same advance() calls, the set of events fired by
## any time T is fully deterministic.
##
## Logic-only and renderer-free by design so it is headless-testable: the
## owner (combat_screen.gd) drives advance() from _process() and receives
## each fired event through event_callback, then finished_callback exactly
## once when the timeline completes. skip() fires every remaining event
## immediately and finishes -- the same path doubles as the instant mode
## headless tests rely on.


## One merged timeline entry: either a cast (with its CastEvent) or a poison
## tick (with its TickEvent), at its recorded resolver timestamp.
class PlaybackEvent:
	extends RefCounted
	var time_ms: int = 0
	var presentation_ms: float = 0.0
	var sequence: int = 0
	var root_id: int = 0
	var chain_index: int = 0
	var chain_count: int = 0
	var chain_damage: float = 0.0
	var chain_note := ""
	var visual_beat: bool = true
	var is_tick: bool = false
	var cast: CombatResolver.CastEvent = null
	var tick: CombatResolver.TickEvent = null
	## Damage this single event contributed (cast physical damage or tick
	## poison damage) -- what the HP bar should drain when it fires.
	var damage: float = 0.0
	var health_removed: float = 0.0
	var chain_health_removed: float = 0.0

	func total_health_loss() -> float:
		return damage + health_removed


## Playback speed multiplier applied to advance()'s delta (1.0 = real time).
var speed: float = 1.0
## Called as event_callback.call(event: PlaybackEvent) for each fired event,
## in timeline order.
var event_callback: Callable = Callable()
## Called as cast_start_callback.call(cast: CombatResolver.CastEvent) when a
## cast begins. This is presentation-only timing for macro highlights; damage
## and HUD changes still use event_callback at the resolved event timestamp.
var cast_start_callback: Callable = Callable()
## Called exactly once, with no arguments, when the timeline completes
## (either by advancing past the end or via skip()).
var finished_callback: Callable = Callable()

# Resolver time freezes during these bounded presentation-only pauses.
const MAX_VISIBLE_STRIKES := 16
const FLURRY_GAPS_MS := [260.0, 230.0, 210.0, 190.0, 180.0, 180.0, 180.0, 180.0, 180.0, 180.0, 180.0, 180.0, 180.0, 180.0, 230.0]
const FLURRY_MIN_REAL_GAP_MS := 140.0
const FLURRY_RECOVERY_MS := 200.0
const FLURRY_MIN_REAL_RECOVERY_MS := 125.0
const FLURRY_FINISH_DWELL_MS := 260.0
const FLURRY_MIN_REAL_DWELL_MS := 180.0
var _presentation_ms := 0.0
var _presentation_end_ms := 0.0
var _pauses: Array = []
var _events: Array = []
var _cast_starts: Array[CombatResolver.CastEvent] = []
var _cast_start_frontiers := {}
var _next_index: int = 0
var _next_cast_start_index: int = 0
var _elapsed_ms: float = 0.0
var _timeline_end_ms: int = 0
var _window_ms: int = 0
var _nominal_window_ms: int = 0
var _countdown_rate: float = 1.0
var _started: bool = false
var _finished: bool = false
var _damage_dealt: float = 0.0
var _health_removed: float = 0.0


## Builds the merged, time-ordered timeline from the result's cast and tick
## events. Always plays the FULL authored window on both a win and a loss
## (combat-playback adjustment round 1, 2026-07-19 -- previously a win
## truncated the timeline at the recorded kill moment; the user wants the
## full window to keep playing after the kill for an "overkill" feel, with
## the HUD's HP bar clamping at 0 rather than the timeline stopping early).
func start(result: CombatResolver.CombatResult) -> void:
	_events = _merge_events(result)
	_build_flurries()
	_presentation_ms = 0.0
	_presentation_end_ms = result.duration_ms + _delay_at(result.duration_ms)
	# Preserve an actual rendered finishing beat when the last chain lands on
	# the authored deadline. Skip still bypasses this presentation-only dwell.
	if not _events.is_empty() and _events[-1].chain_count > 1:
		_presentation_end_ms = maxf(_presentation_end_ms, _events[-1].presentation_ms + FLURRY_FINISH_DWELL_MS)
	_cast_starts.assign(result.cast_events.filter(func(cast): return cast.origin_kind == "macro"))
	_cast_start_frontiers.clear()
	# Consumption can precede the explicit cast_start record. Retain the
	# earliest record belonging to each cast, including those resource edits.
	for record in result.trace.presentation_records:
		var id := int(record.get("cast_id", 0))
		if id > 0 and not _cast_start_frontiers.has(id):
			_cast_start_frontiers[id] = int(record.sequence) - 1
	_window_ms = result.duration_ms
	_nominal_window_ms = result.nominal_duration_ms if result.nominal_duration_ms > 0 else result.duration_ms
	_countdown_rate = result.countdown_rate
	_timeline_end_ms = result.duration_ms
	_next_index = 0
	_next_cast_start_index = 0
	_elapsed_ms = 0.0
	_damage_dealt = 0.0
	_health_removed = 0.0
	_started = true
	_finished = false


## Advances the playback clock by delta_seconds * speed and fires every event
## whose presentation deadline has been reached, in resolver sequence order.
## The combat clock freezes through bounded retrigger pauses. Finishes once
## the full authored window, contacts and any final dwell have completed.
func advance(delta_seconds: float) -> void:
	if not _started or _finished:
		return
	# Integrate real time through each boundary. Ordinary casts honor speed;
	# flurry contacts retain a real-time floor even after a mid-chain change.
	var remaining := maxf(delta_seconds, 0.0) * 1000.0
	while remaining > 0.0 and _presentation_ms < _presentation_end_ms and speed > 0.0:
		var boundary := _presentation_end_ms
		var rate := speed
		for pause in _pauses:
			if _presentation_ms < pause.start:
				boundary = minf(boundary, pause.start)
				break
			if _presentation_ms < pause.start + pause.duration:
				boundary = minf(boundary, pause.start + pause.duration)
				rate = minf(rate, pause.duration / float(pause.get("min_real_ms", FLURRY_MIN_REAL_GAP_MS)))
				break
		if not _events.is_empty() and _events[-1].chain_count > 1:
			var dwell_start: float = _events[-1].presentation_ms
			if _presentation_ms < dwell_start:
				boundary = minf(boundary, dwell_start)
			elif _presentation_ms < dwell_start + FLURRY_FINISH_DWELL_MS:
				boundary = minf(boundary, dwell_start + FLURRY_FINISH_DWELL_MS)
				rate = minf(rate, FLURRY_FINISH_DWELL_MS / FLURRY_MIN_REAL_DWELL_MS)
		var step := minf(remaining * rate, boundary - _presentation_ms)
		_presentation_ms += step
		remaining -= step / rate
		if step <= 0.0: break
	_elapsed_ms = _resolver_time(_presentation_ms)
	_fire_due_events()
	if _presentation_ms >= _presentation_end_ms and _next_index >= _events.size():
		_finish()


## Fires every remaining event immediately, jumps the clock to the timeline
## end, and finishes. Also the instant mode used by headless tests.
func skip() -> void:
	if not _started or _finished:
		return
	_elapsed_ms = float(_timeline_end_ms)
	_presentation_ms = _presentation_end_ms
	_fire_due_events()
	_finish()


func elapsed_ms() -> float:
	return _elapsed_ms


## Where playback ends -- always the full authored DPS window on both a win
## and a loss (no more win truncation, adjustment round 1). Kept as its own
## accessor alongside window_ms() since callers historically read either
## name for the same "how long does this readout run" question.
func timeline_end_ms() -> int:
	return _timeline_end_ms


## The full authored DPS window -- what a countdown readout should show as
## the denominator.
func window_ms() -> int:
	return _window_ms


## Frozen result clock; equipment edits never retime a replay.
func nominal_window_ms() -> int:
	return _nominal_window_ms


func countdown_remaining_ms() -> float:
	if _elapsed_ms >= _window_ms:
		return 0.0
	return maxf(0.0, float(_nominal_window_ms) - _countdown_rate * _elapsed_ms)


func events_fired() -> int:
	return _next_index


func total_events() -> int:
	return _events.size()


## Cumulative damage of every event fired so far -- monster HP minus this is
## the HP the bar should currently show.
func damage_dealt() -> float:
	return _damage_dealt


func health_removed() -> float:
	return _health_removed


func is_finished() -> bool:
	return _finished


func active_cast() -> CombatResolver.CastEvent:
	if _next_cast_start_index <= 0 or _next_cast_start_index > _cast_starts.size():
		return null
	var cast: CombatResolver.CastEvent = _cast_starts[_next_cast_start_index - 1]
	if _elapsed_ms > float(cast.time_ms):
		return null
	return cast


func active_cast_progress() -> float:
	var cast := active_cast()
	if cast == null:
		return 0.0
	var duration_ms := maxi(cast.time_ms - cast.cast_start_ms, 1)
	return clampf((_elapsed_ms - float(cast.cast_start_ms)) / float(duration_ms), 0.0, 1.0)


func _fire_due_events() -> void:
	while true:
		var next_event = _events[_next_index] if _next_index < _events.size() else null
		var next_start: CombatResolver.CastEvent = _cast_starts[_next_cast_start_index] if _next_cast_start_index < _cast_starts.size() else null
		var event_due: bool = next_event != null and next_event.presentation_ms <= _presentation_ms
		var start_due: bool = next_start != null and float(next_start.cast_start_ms) + _delay_at(next_start.cast_start_ms) <= _presentation_ms
		if not event_due and not start_due:
			return
		if start_due and (not event_due or float(next_start.cast_start_ms) + _delay_at(next_start.cast_start_ms) < next_event.presentation_ms):
			_next_cast_start_index += 1
			if cast_start_callback.is_valid():
				cast_start_callback.call(next_start)
			continue
		_next_index += 1
		_damage_dealt += next_event.damage
		_health_removed += next_event.health_removed
		if event_callback.is_valid():
			event_callback.call(next_event)


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if finished_callback.is_valid():
		finished_callback.call()


## Merge casts and ticks, then use recorded resolver sequence for ties.
## Natural and forced ticks can surround a cast at the same timestamp.
## Sequence-free legacy fixtures retain the historical tick-first tie rule.
static func _merge_events(result: CombatResolver.CombatResult) -> Array:
	var merged: Array = []
	var roots := {}
	for record in result.trace.presentation_records:
		roots[int(record.sequence)] = int(record.get("root_cast_id", 0))
	var cast_index := 0
	var tick_index := 0
	while cast_index < result.cast_events.size() or tick_index < result.tick_events.size():
		var take_tick: bool
		if tick_index >= result.tick_events.size():
			take_tick = false
		elif cast_index >= result.cast_events.size():
			take_tick = true
		else:
			take_tick = result.tick_events[tick_index].time_ms <= result.cast_events[cast_index].time_ms
		var event := PlaybackEvent.new()
		if take_tick:
			var tick := result.tick_events[tick_index]
			tick_index += 1
			event.time_ms = tick.time_ms
			event.sequence = tick.sequence
			event.is_tick = true
			event.tick = tick
			event.damage = tick.damage
		else:
			var cast := result.cast_events[cast_index]
			cast_index += 1
			event.time_ms = cast.time_ms
			event.sequence = cast.sequence
			event.is_tick = false
			event.cast = cast
			event.damage = cast.physical_damage
			event.health_removed = cast.health_removed
		event.root_id = int(roots.get(event.sequence, event.cast.root_cast_id if not event.is_tick else 0))
		merged.append(event)
	# Recorded sequence disambiguates recursive trigger subtrees at tied time.
	# Legacy fixtures have sequence zero and retain the original tick-first merge.
	merged.sort_custom(func(a, b):
		if a.time_ms != b.time_ms: return a.time_ms < b.time_ms
		if a.sequence > 0 and b.sequence > 0: return a.sequence < b.sequence
		return a.is_tick and not b.is_tick)
	return merged


## At a frozen timestamp, only replay observations before the next unseen hit.
## This includes spent-at-start effects but defers its impact and parent grants
## which the resolver emits after recursively processing that child's subtree.
func record_frontier() -> int:
	var frontier := 9223372036854775807
	if _next_index < _events.size():
		var next: PlaybackEvent = _events[_next_index]
		if next.time_ms <= _elapsed_ms and next.sequence > 0:
			frontier = next.sequence - 1
	if _next_cast_start_index < _cast_starts.size():
		var next_start := _cast_starts[_next_cast_start_index]
		if next_start.cast_start_ms <= _elapsed_ms:
			frontier = mini(frontier, int(_cast_start_frontiers.get(next_start.cast_id, frontier)))
	return frontier


func _delay_at(time: int) -> float:
	var total := 0.0
	for pause in _pauses:
		if pause.time <= time: total += pause.duration
	return total


func _resolver_time(clock: float) -> float:
	var time := clock
	for pause in _pauses:
		time -= clampf(clock - pause.start, 0.0, pause.duration)
	# Subtracting many pause intervals can leave an exact millisecond a few
	# machine epsilon short, preventing clients advancing to that checkpoint.
	if absf(time - roundf(time)) < 0.0000001: time = roundf(time)
	return minf(time, _timeline_end_ms)


func _flurry_beat(index: int, count: int) -> int:
	if count <= MAX_VISIBLE_STRIKES or index < 4: return index
	if index == count - 1: return MAX_VISIBLE_STRIKES - 1
	var middle_beats := MAX_VISIBLE_STRIKES - 5
	return 4 + mini(middle_beats - 1, int(float(index - 4) * middle_beats / maxf(count - 5, 1)))


func _build_flurries() -> void:
	_pauses.clear()
	var offset := 0.0
	var index := 0
	while index < _events.size():
		var first: PlaybackEvent = _events[index]
		var end := index + 1
		if first.root_id > 0:
			while end < _events.size():
				var next: PlaybackEvent = _events[end]
				if next.time_ms != first.time_ms or next.root_id != first.root_id: break
				end += 1
		var count := 0
		for i in range(index, end):
			if not _events[i].is_tick: count += 1
		var delay := 0.0
		var damage := 0.0
		var removed := 0.0
		var previous_beat := 0
		var cast_index := 0
		var dodged := 0
		var interrupted := 0
		var unavailable := 0
		for i in range(index, end):
			var event: PlaybackEvent = _events[i]
			# Ticks are replayed in their original position between contacts;
			# they count toward damage, never toward the attack chain count.
			var beat := _flurry_beat(cast_index, count) if not event.is_tick else previous_beat
			if beat > previous_beat:
				var gap: float = FLURRY_GAPS_MS[mini(previous_beat, FLURRY_GAPS_MS.size() - 1)]
				_pauses.append({"time": first.time_ms, "start": first.time_ms + offset + delay, "duration": gap})
				delay += gap
			previous_beat = beat
			damage += event.damage
			removed += event.health_removed
			event.presentation_ms = event.time_ms + offset + delay
			if count > 1:
				event.chain_count = count
				event.chain_index = cast_index + (0 if event.is_tick else 1)
				event.chain_damage = damage
				event.chain_health_removed = removed
				if not event.is_tick:
					dodged += int(event.cast.was_dodged)
					interrupted += int(event.cast.was_interrupted)
					unavailable += int(event.cast.resource_unavailable)
				var notes: PackedStringArray = []
				if dodged > 0: notes.append("%d dodged" % dodged)
				if interrupted > 0: notes.append("%d interrupted" % interrupted)
				if unavailable > 0: notes.append("%d unavailable" % unavailable)
				event.chain_note = " | ".join(notes)
				event.visual_beat = not event.is_tick and (cast_index == count - 1 or _flurry_beat(cast_index + 1, count) != beat)
			if not event.is_tick: cast_index += 1
		if delay > 0:
			# Let the last copy complete before a macro whose resolver start
			# equals this root impact can begin its normal windup.
			_pauses.append({"time": first.time_ms, "start": first.time_ms + offset + delay, "duration": FLURRY_RECOVERY_MS, "min_real_ms": FLURRY_MIN_REAL_RECOVERY_MS})
			delay += FLURRY_RECOVERY_MS
			offset += delay
		index = end


func current_event_is_chain() -> bool:
	return _next_index > 0 and _events[_next_index - 1].chain_count > 1
