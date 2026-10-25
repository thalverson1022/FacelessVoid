extends RefCounted
## Approved T1 consumer hooks. Scheduler calls begin_cast once, then finish_cast
## only after the complete trigger subtree. Precision alone grants on the hit,
## before children, under the user's D013 ordering correction.
const Effects = preload("res://scripts/systems/combat_effect_state.gd")
const TimerMath = preload("res://scripts/systems/combat_timer_math.gd")
var state
var initialization_error := ""
var _footwork_rank := 0
var _strength := 1.0
var _readiness_enabled := false
var _precision_enabled := false
var _dance_enabled := false
var _dance_duration := 0
var _dance_grants := 0


func _init(footwork_rank: int = 0, readiness_enabled: bool = false, stats = null, trace = null, repeat_config: Dictionary = {}) -> void:
	state = Effects.new(stats, trace)
	if footwork_rank < 0 or footwork_rank > 5:
		initialization_error = "Fancy Footwork rank must be between zero and five."
		return
	initialization_error = state.initialization_error
	_footwork_rank = footwork_rank
	_strength = 2.0 if repeat_config.get("legendary_crown", false) else 1.0
	_readiness_enabled = readiness_enabled
	var duration_increase := float(repeat_config.get("increased_buff_duration", 0.0))
	var footwork_timer := TimerMath.scaled_duration(3000, duration_increase)
	if footwork_timer.error != "":
		initialization_error = footwork_timer.error
		return
	state.define("footwork", {"source_id": "talent.bladedancer.fancy_footwork", "duration_ms": footwork_timer.duration_ms,
		"cap": 5, "mode": "add", "unit": "stacks", "cast_start_inclusive": true,
		"magnitude_per_unit": 0.04 * footwork_rank * _strength})
	state.define("readiness", {"source_id": "skill.parry_strike", "duration_ms": -1,
		"cap": 1, "mode": "add", "unit": "charges"})
	for effect_id in ["precision", "dance"]:
		var duration: int = int(repeat_config.get(effect_id, 0))
		if duration == 0:
			continue
		if effect_id == "dance" and duration > 0:
			var timer := TimerMath.scaled_duration(duration, duration_increase)
			if timer.error != "":
				initialization_error = timer.error
				return
			duration = timer.duration_ms
		var source_id := "talent.bladedancer.precision_attacks" if effect_id == "precision" else "skill.dance_of_death"
		var error: String = state.define(effect_id, {"source_id": source_id, "duration_ms": duration,
			"cap": 1, "mode": "add", "unit": "charges"})
		if error != "":
			initialization_error = error
			return
		if effect_id == "precision":
			_precision_enabled = true
		else:
			_dance_enabled = true
			_dance_duration = duration


## Non-mutating scheduling preview; do not consume a cast outside the fight window.
func preview_execution_ms(skill_id: String, ordinary_ms: int, minimum_ms: int, time_ms: int) -> int:
	var duration := maxi(1, maxi(ordinary_ms, minimum_ms))
	if skill_id != "skill.leaping_plunge" or _footwork_rank <= 0:
		return duration
	var buff: Dictionary = state.snapshot("footwork")
	var count := int(buff.get("stacks", 0)) if int(buff.get("expires_at_ms", -1)) >= time_ms else 0
	return maxi(maxi(500, minimum_ms), ceili(duration * (1.0 - 0.04 * _footwork_rank * _strength * count)))


func begin_cast(skill_id: String, ordinary_ms: int, minimum_ms: int, time_ms: int, context: Dictionary = {}) -> Dictionary:
	if initialization_error != "":
		return {"error": initialization_error}
	var error: String = state.advance(time_ms, true)
	if error != "":
		return {"error": error}
	var output := {"error": "", "execution_ms": maxi(1, maxi(ordinary_ms, minimum_ms)),
		"eligible": true, "footwork_consumed": 0, "readiness_consumed": 0}
	if skill_id == "skill.leaping_plunge" and _footwork_rank > 0:
		var used: Dictionary = state.consume("footwork", -1, time_ms, true, context)
		if used.error != "":
			return used
		output.footwork_consumed = used.consumed
		output.execution_ms = maxi(maxi(500, minimum_ms), ceili(float(output.execution_ms) * (1.0 - 0.04 * _footwork_rank * _strength * int(used.consumed))))
	if skill_id == "skill.parry_strike" and _readiness_enabled:
		var used: Dictionary = state.consume("readiness", 1, time_ms, true, context)
		if used.error != "":
			return used
		output.readiness_consumed = used.consumed
		output.eligible = int(used.consumed) > 0
	if output.eligible:
		var guarantees: PackedStringArray = []
		if _precision_enabled and skill_id in ["skill.stab", "skill.heavy_slash"]:
			var used: Dictionary = state.consume("precision", 1, time_ms, true, context)
			if used.error != "":
				return used
			output["precision_consumed"] = used.consumed
			if int(used.consumed) > 0:
				guarantees.append("precision")
		if _dance_enabled and context.get("origin_kind", "macro") == "macro" and _has_dance():
			guarantees.append("dance")
		output["guaranteed_repeat_sources"] = guarantees
	return output


## connected is false for dodge/interruption/missing cast-start resources, but
## true for full block. The caller supplies an already-resolved stack grant.
func finish_cast(skill_id: String, connected: bool, is_retrigger: bool, time_ms: int, footwork_grant: int = 1, context: Dictionary = {}) -> String:
	if initialization_error != "":
		return initialization_error
	if footwork_grant < 0:
		return "Footwork grants cannot be negative."
	var error: String = state.advance(time_ms, true)
	if error != "" or not connected:
		return error
	if skill_id == "skill.quick_cut" and _footwork_rank > 0:
		var granted: Dictionary = state.grant("footwork", footwork_grant, time_ms, context)
		if granted.error != "":
			return granted.error
	if is_retrigger and _readiness_enabled:
		var granted: Dictionary = state.grant("readiness", 1, time_ms, context)
		return granted.error
	return ""


## A connected Quick Cut makes Precision available to same-hit Death Blade Stab.
## This is not a second grant at cast end; Readiness/Footwork retain their timing.
func on_hit(skill_id: String, connected: bool, time_ms: int, context: Dictionary = {}) -> String:
	if not connected or skill_id != "skill.quick_cut" or not _precision_enabled:
		return ""
	var granted: Dictionary = state.grant("precision", 1, time_ms, context)
	return granted.error


func activate_dance(time_ms: int, context: Dictionary = {}) -> String:
	if not _dance_enabled:
		return ""
	_dance_grants += 1
	var id := "dance" if _dance_grants == 1 else "dance.%d" % _dance_grants
	if _dance_grants > 1:
		var error: String = state.define(id, {"source_id": "skill.dance_of_death", "duration_ms": _dance_duration,
			"cap": 1, "mode": "add", "unit": "charges"})
		if error != "":
			return error
	var granted: Dictionary = state.grant(id, 1, time_ms, context)
	return granted.error

func _has_dance() -> bool:
	for id in state.snapshot():
		if id == "dance" or String(id).begins_with("dance."):
			return true
	return false
