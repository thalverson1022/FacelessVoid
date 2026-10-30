extends RefCounted
## Read-only replay of ordered resolver observations. No RNG, combat math or stash writes.
var records: Array = []
var cursor := 0
var time_ms := 0
var active: Dictionary = {}
# Display-only spent stacks; authoritative replay state still consumes immediately.
var held_effects: Array = []
var _cast_impacts: Dictionary = {}
var cooldowns: Dictionary = {}
## Monotonic presentation credits; observers consume each actual reduction once.
var cooldown_credits: Dictionary = {}
var statuses: Dictionary = {}
var stash := 0
var stolen := 0
var attempt: Dictionary = {}
var journal: Array[String] = []
var running := false
var stun_until_ms := 0
var slow := 0.0
var gold_stats: Dictionary = {}

func begin(result) -> void:
	clear()
	records = result.trace.presentation_records.duplicate(true)
	for event in records:
		if event.get("kind") == "cast_resolved":
			_cast_impacts[int(event.get("cast_id", 0))] = int(event.time_ms)
	statuses = result.presentation_initial.duplicate(true)
	stash = int(statuses.get("stash", 0))
	slow = float(statuses.get("slow", 0))
	gold_stats = statuses.get("gold_stats", {}).duplicate(true)
	running = true
	advance_to(0)

func clear() -> void:
	records = []
	cursor = 0
	time_ms = 0
	active.clear()
	held_effects.clear()
	_cast_impacts.clear()
	cooldowns.clear()
	cooldown_credits.clear()
	statuses.clear()
	attempt.clear()
	journal.clear()
	stash = 0
	stolen = 0
	running = false
	stun_until_ms = 0
	slow = 0.0
	gold_stats.clear()

func advance_to(target_ms: int, through_sequence: int = 9223372036854775807) -> void:
	if not running:
		return
	assert(target_ms >= time_ms)
	time_ms = target_ms
	while cursor < records.size() and int(records[cursor].time_ms) <= target_ms:
		if int(records[cursor].time_ms) == target_ms and int(records[cursor].get("sequence", 0)) > through_sequence:
			break
		apply(records[cursor])
		cursor += 1
	# Apply all tied records before expiry: Plunge's exact-deadline consumption wins.
	for key in active.keys():
		var expiry := int(active[key].state.get("expires_at_ms", -1))
		if expiry >= 0 and (expiry < target_ms or (expiry == target_ms and through_sequence == 9223372036854775807)):
			active.erase(key)
	for key in cooldowns.keys():
		if int(cooldowns[key]) <= target_ms:
			cooldowns.erase(key)

func apply(event: Dictionary) -> void:
	var payload: Dictionary = event.get("payload", {})
	var kind: String = event.get("kind", "effect_lifecycle")
	var source: String = event.get("source_id", "")
	var display_source: String = preload("res://scripts/ui/combat_effect_text.gd").name_for(source)
	var origin: String = event.get("origin_kind", "system")
	var note := ""
	match kind:
		"effect_lifecycle":
			var effect: String = payload.get("effect_id", "")
			var key: String = event.get("effect_instance_id", effect)
			if key.is_empty():
				key = effect
			_hold_consumed(event, payload, key)
			var after: Dictionary = payload.get("after", {})
			if after.is_empty():
				active.erase(key)
			else:
				var id := "status." + effect if effect in ["penetration", "potency"] else "buff." + effect
				if effect == "dance" or effect.begins_with("dance."):
					id = "buff.dance"
				if effect.begins_with("touch."):
					id = "buff.touch_of_darkness"
				var previous: Dictionary = active.get(key, {})
				var start_ms := int(event.get("time_ms", 0))
				if int(previous.get("state", {}).get("expires_at_ms", -1)) == int(after.get("expires_at_ms", -1)):
					start_ms = int(previous.get("timer_started_ms", start_ms))
				active[key] = {"id": id, "source": source, "state": after.duplicate(true), "timer_started_ms": start_ms}
			note = "%s: %s" % [preload("res://scripts/ui/combat_effect_text.gd").name_for(effect), event.get("lifecycle_reason", "updated")]
			if int(payload.get("consumed", 0)) > 0:
				note += " (%d spent)" % int(payload.consumed)
		"legendary_buff_grant":
			var buff_kind := String(payload.get("kind", ""))
			var after: Dictionary = payload.get("after", {}).duplicate(true)
			after["units"] = int(after.get("stacks", 0))
			after["unit"] = "stacks"
			active["legendary." + buff_kind] = {"id": "buff." + buff_kind, "source": after.get("source_id", source), "state": after, "timer_started_ms": int(event.time_ms)}
			note = "%s: %d/%d stacks; shared timer refreshed" % [buff_kind.capitalize(), after.units, int(payload.get("cap", after.units))]
		"legendary_buff_expired", "legendary_buff_reset":
			active.erase("legendary." + source)
			note = "%s: expired" % source.capitalize()
		"legendary_locket_trial":
			var changes: Dictionary = payload.get("deadlines", {})
			for id in changes:
				cooldowns[id] = int(changes[id].after)
				if int(changes[id].before) > int(changes[id].after):
					cooldown_credits[id] = int(cooldown_credits.get(id, 0)) + 1
			if not changes.is_empty(): note = "Locket: cooldowns reduced"
		"schedule_decision":
			if origin == "macro" and payload.get("decision") != "window_exhausted":
				attempt = payload.duplicate(true)
				attempt["skill_id"] = source
				var deadline := int(payload.get("cooldown_available_at_ms", 0))
				if deadline > int(event.time_ms):
					cooldowns[source] = deadline
			note = "%s: %s" % [display_source, str(payload.get("reason", payload.get("decision", ""))).replace("_", " ")]
		"cooldown_started":
			cooldowns[source] = int(payload.cooldown_available_at_ms)
			note = "%s: cooldown started" % display_source
		"cast_resolved":
			var cast_id := int(event.get("cast_id", 0))
			held_effects = held_effects.filter(func(item): return int(item.cast_id) != cast_id)
			stun_until_ms = maxi(stun_until_ms, int(event.time_ms) + int(payload.get("stun_duration_ms", 0)))
			var after: Dictionary = payload.get("status_after", {})
			if not after.is_empty():
				statuses.merge(after, true)
			note = "%s: %s" % [display_source, "interrupted" if payload.get("interrupted", false) else ("%.1f health removed" % float(payload.get("health_removed", 0)) if source == "skill.exsanguinate" else "%.1f damage" % float(payload.get("damage", 0)))]
		"poison_tick":
			statuses["poison"] = int(payload.get("stacks_remaining", 0))
			if origin == "poison_repeat":
				note = "Poison Retrigger: free packet; current buffs; no Poison consumed"
			elif payload.get("keyword_consume", false):
				note = "Poison Consume: %d stacks" % int(payload.get("stacks_depleted", 0))
			else:
				note = "Poison %s: %d stacks depleted (not Consume)" % ["forced tick" if origin == "forced_tick" else "natural tick", int(payload.get("stacks_depleted", 0))]
		"status_transaction":
			# Transactions explain snapshots; snapshots already include their final values.
			note = "%s: %s, %d -> %d" % [payload.get("status", "status"), payload.get("reason", "changed"), int(payload.get("before", 0)), int(payload.get("after", 0))]
		"gold_transaction":
			stash = int(payload.get("stash_after", stash))
			stolen = int(payload.get("stolen_after", stolen))
			# Greed mirrors credited fight theft; it adds no independent combat modifier.
			if stolen > 0:
				active["greed"] = {"id": "buff.greed", "source": "combat.theft", "state": {"units": stolen, "unit": "stacks", "expires_at_ms": -1}}
			else:
				active.erase("greed")
			gold_stats = payload.get("stats_after", gold_stats).duplicate(true)
			note = "Theft raw %d, credited %d; stash %d; stolen this fight %d" % [int(payload.get("raw_amount", 0)), int(payload.get("credited_amount", 0)), stash, stolen]
	if not note.is_empty():
		journal.append("%.3fs [%s] %s" % [int(event.time_ms) / 1000.0, origin, note])

func _hold_consumed(event: Dictionary, payload: Dictionary, key: String) -> void:
	var cast_id := int(event.get("cast_id", 0))
	var consumed := int(payload.get("consumed", 0))
	# Instant effects and records without a later impact need no visual delay.
	if consumed <= 0 or cast_id <= 0 or int(_cast_impacts.get(cast_id, -1)) <= int(event.time_ms):
		return
	var previous: Dictionary = active.get(key, {})
	if previous.is_empty() or not str(previous.id).begins_with("buff."):
		return
	var held := previous.duplicate(true)
	held["cast_id"] = cast_id
	held.state["units"] = consumed
	held_effects.append(held)

func display_effects() -> Array:
	return active.values() + held_effects

func units(effect_id: String) -> int:
	var total := 0
	for value in active.values():
		if value.id == effect_id:
			total += int(value.state.get("units", value.state.get("charges", 0)))
	return total

func attempt_text() -> String:
	if time_ms < stun_until_ms:
		return "Stunned - %.1fs remaining" % ((stun_until_ms - time_ms) / 1000.0)
	if attempt.is_empty() or time_ms >= int(attempt.get("end_ms", 0)):
		return ""
	match attempt.get("reason", "ready"):
		"cooldown": return "Cooldown - 0.1s, no effects"
		"missing_readiness": return "No Readiness - spending cast time, no effects"
	var lifecycle: Dictionary = attempt.get("lifecycle", {})
	var spent := " | Footwork spent: %d" % int(lifecycle.footwork_consumed) if int(lifecycle.get("footwork_consumed", 0)) > 0 else " | Readiness spent: 1" if int(lifecycle.get("readiness_consumed", 0)) > 0 else ""
	return "Cast fixed at start: %.3fs" % (int(attempt.get("execution_ms", 0)) / 1000.0) + spent + (" | Slowed %.0f%%" % (slow * 100.0) if slow > 0 else "")

func details_for(skill: Skill) -> String:
	if not running:
		return ""
	var lines: PackedStringArray = ["Live playback at %.2fs" % (time_ms / 1000.0)]
	if skill.id == "skill.leaping_plunge":
		lines.append("Footwork now: %d/5. An accepted cast keeps its captured duration." % units("buff.footwork"))
	if skill.id == "skill.parry_strike":
		lines.append("Readiness now: %d stack" % units("buff.readiness"))
	if cooldowns.has(skill.id):
		lines.append("Shared cooldown remaining: %.1fs" % (maxi(0, int(cooldowns[skill.id]) - time_ms) / 1000.0))
	if attempt.get("skill_id", "") == skill.id and time_ms < int(attempt.get("end_ms", 0)):
		lines.append(attempt_text())
	if skill.stolen_gold_base_cap > 0:
		lines.append("Stash: %d | Stolen this fight: %d | Mug counted: %d/%d" % [stash, stolen, skill.stolen_gold_damage_bonus(stolen), skill.stolen_gold_base_cap])
	return "\n".join(lines)
