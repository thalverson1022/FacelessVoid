extends RefCounted
## T4 Bypass and Touch share the source-aware temporary-stat lifecycle.
const Effects = preload("res://scripts/systems/combat_effect_state.gd")
const Stats = preload("res://scripts/systems/combat_stat_state.gd")
const TimerMath = preload("res://scripts/systems/combat_timer_math.gd")
var stats
var state
var initialization_error := ""
var bypass_enabled := false
var bypass_grant := 1
var _touch_serial := 0
var _touch_duration := 12000
var _strength := 1.0

func _init(player: PlayerStats, trace = null) -> void:
	_strength = 2.0 if player.legendary_crown else 1.0
	stats = Stats.new(player)
	state = Effects.new(stats, trace)
	initialization_error = state.initialization_error
	bypass_enabled = player.bypass_enabled
	bypass_grant = stack_grant(player.bonus_bypass_stacks, player)
	var bypass_timer := TimerMath.scaled_duration(3000, player.increased_buff_duration)
	var touch_timer := TimerMath.scaled_duration(12000, player.increased_buff_duration)
	if bypass_timer.error != "" or touch_timer.error != "":
		initialization_error = bypass_timer.error if bypass_timer.error != "" else touch_timer.error
		return
	_touch_duration = touch_timer.duration_ms
	if initialization_error == "":
		initialization_error = state.define("bypass", {
			"source_id": "talent.assassin.bypass", "duration_ms": bypass_timer.duration_ms,
			"cap": 3, "mode": "add", "unit": "stacks", "magnitude_per_unit": 0.1 * _strength,
			"stat_inputs": {StatCatalog.PERCENT_ELEMENTAL_DAMAGE: 0.1}})

static func stack_grant(bonus: int, player: PlayerStats) -> int:
	return (1 + maxi(0, bonus)) * (2 if bool(player.special_effects.get("double_applied_stacks", false)) else 1)

func finish_cast(skill_id: String, connected: bool, time_ms: int, context: Dictionary) -> String:
	if not bypass_enabled or not connected or skill_id != "skill.stab":
		return ""
	return state.grant("bypass", bypass_grant, time_ms, context).error

func grant_touch(consumed: int, time_ms: int, context: Dictionary) -> String:
	if consumed <= 0:
		return ""
	_touch_serial += 1
	var id := "touch.%d" % _touch_serial
	var error: String = state.define(id, {"source_id": "skill.touch_of_darkness",
		"duration_ms": _touch_duration, "cap": -1, "mode": "add", "unit": "stacks",
		"magnitude_per_unit": 0.1 * _strength, "stat_inputs": {StatCatalog.INCREASED_ATTACK_SPEED: 0.1, StatCatalog.BASE_DAMAGE: 2.0}})
	if error != "":
		return error
	# Actual consumed quantity only: never reapply stack bonuses or doubling.
	return state.grant(id, consumed, time_ms, context).error

func live_player(base: PlayerStats) -> PlayerStats:
	if state.snapshot().is_empty():
		return base
	# Preserve opt-in combat descriptors applied after build stat derivation.
	# Only scalar outputs belong to the temporary-stat rebuild.
	var value: PlayerStats = base.duplicate(true)
	var derived: PlayerStats = stats.snapshot()
	for field in Stats.TEMP_FIELDS.values():
		value.set(field, derived.get(field))
	for field in ["base_poison_damage", "poison_damage_per_tick", "elemental_damage_multiplier",
		"physical_damage_multiplier", "gear_physical_damage_multiplier", "talent_physical_damage_multiplier",
		"physical_damage_uses_buckets", "temporary_physical_multiplier", "temporary_elemental_multiplier",
		"derived_physical_multiplier", "derived_elemental_multiplier", "skill_damage_multipliers",
		"stat_sources", "derivation_details"]:
		value.set(field, derived.get(field))
	value.legendary_added_ias = 0.0
	value.legendary_added_physical = 0.0
	value.legendary_added_flat = 0.0
	return value
