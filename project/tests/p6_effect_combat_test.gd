extends SceneTree
const Observation = preload("res://tests/helpers/p6_combat_observation_cases.gd")
var failed := false

func _initialize() -> void:
	_casts_and_cleanup()
	_expiry_order()
	_repeats_and_readiness()
	_invalid_input()
	_invalid_cleanup()
	print("P6 T4 effect combat: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		failed = true
		printerr("FAILED: " + label)

func skill(id: String, ms: int, minimum: int = 1) -> Skill:
	var value := Skill.new()
	value.id = id
	value.base_execution_ms = ms
	value.min_execution_ms = minimum
	var damage := PhysicalDamageEffect.new()
	damage.amount = 10
	value.effects = [damage]
	return value

func player() -> PlayerStats:
	var value := PlayerStats.new()
	value.footwork_rank = 5
	value.readiness_enabled = true
	return value

func _casts_and_cleanup() -> void:
	var stats := player()
	stats.bonus_footwork_stacks = 2
	var rotation: Array[Skill] = [skill("skill.quick_cut", 100), skill("skill.leaping_plunge", 2000, 500)]
	var result := CombatResolver.resolve(rotation, stats, Monster.new(), 900, 42, true)
	check(result.is_valid and result.cast_events.size() == 2, "core cast count")
	if result.cast_events.size() < 2:
		return
	var plunge := result.cast_events[1]
	check(plunge.cast_start_ms == 100 and plunge.time_ms == 900, "consumed stacks reduce actual windup")
	check(plunge.lifecycle_snapshot.footwork_consumed == 3 and plunge.lifecycle_snapshot.execution_ms == 800, "consumption snapshot matches cast duration")
	check(result.effect_lifecycle.state.snapshot().is_empty(), "normal result releases all effects")
	var replay := CombatResolver.resolve(rotation, stats, Monster.new(), 900, 42, true)
	check(replay.trace.records == result.trace.records and replay.rng_final_state == result.rng_final_state, "same-seed replay and retry")
	var quiet := CombatResolver.resolve(rotation, stats, Monster.new(), 900, 42, false)
	check(quiet.rng_final_state == result.rng_final_state and Observation.signature(quiet) == Observation.signature(result), "trace cannot affect simulation")
	var full_block := Monster.new()
	full_block.block = 10000
	var blocked := CombatResolver.resolve(rotation, stats, full_block, 900, 42, true)
	check(blocked.cast_events[0].physical_damage == 0 and blocked.cast_events[1].lifecycle_snapshot.footwork_consumed == 3, "full block still grants Footwork")
	var dodge := Monster.new()
	dodge.dodge_chance = 1.0
	var missed := CombatResolver.resolve(rotation, stats, dodge, 2100, 42, true)
	check(missed.cast_events[1].lifecycle_snapshot.footwork_consumed == 0 and missed.cast_events[1].time_ms == 2100, "dodge grants no Footwork")
	var clipped := CombatResolver.resolve(rotation, stats, Monster.new(), 899, 42, true)
	check(clipped.cast_events.size() == 1, "clipped cast never starts")
	for record in clipped.trace.records:
		check(record.lifecycle_reason != "consumed", "clipped cast never consumes stacks")

func _expiry_order() -> void:
	var rotation: Array[Skill] = [skill("skill.quick_cut", 100), skill("skill.hold", 3000), skill("skill.leaping_plunge", 2000, 500)]
	var result := CombatResolver.resolve(rotation, player(), Monster.new(), 4700, 1, true)
	check(result.cast_events.size() == 3 and result.cast_events[2].lifecycle_snapshot.footwork_consumed == 1, "hold completion preserves same-time start consumption")
	var expire_sequence := -1
	rotation = [skill("skill.quick_cut", 100), skill("skill.quick_cut", 3000)]
	result = CombatResolver.resolve(rotation, player(), Monster.new(), 3100, 1, true)
	var grants: Array[Dictionary] = []
	for record in result.trace.records:
		if record.kind == "effect_lifecycle" and record.payload.effect_id == "footwork":
			if record.lifecycle_reason == "expired":
				expire_sequence = record.sequence
			if record.lifecycle_reason == "granted":
				grants.append(record)
	check(grants.size() == 2 and grants[1].sequence > expire_sequence and grants[1].payload.after.stacks == 1, "same-deadline grant follows expiry")
	check(grants[0].effect_instance_id != grants[1].effect_instance_id, "fresh buff identity")

func _repeats_and_readiness() -> void:
	var stats := player()
	stats.retrigger_chance = 1.0
	var rotation: Array[Skill] = [skill("skill.quick_cut", 100), skill("skill.parry_strike", 500, 300)]
	var result := CombatResolver.resolve(rotation, stats, Monster.new(), 600, 4, true)
	var parries: Array[CombatResolver.CastEvent] = []
	for cast in result.cast_events:
		if cast.skill.id == "skill.parry_strike":
			parries.append(cast)
	check(parries.size() == 2, "unready repeated parry terminates branch")
	if parries.size() == 2:
		check(not parries[0].resource_unavailable and parries[0].lifecycle_snapshot.readiness_consumed == 1, "macro parry consumes readiness")
		check(parries[1].resource_unavailable and parries[1].physical_damage == 0, "parry repeat cannot self-enable")
	var first_grant := -1
	var deepest_end := -1
	for record in result.trace.records:
		if record.kind == "effect_lifecycle" and record.payload.effect_id == "footwork" and first_grant == -1:
			first_grant = record.sequence
		if record.kind == "cast_resolved" and record.cast_id == 17:
			deepest_end = record.sequence
	check(first_grant > deepest_end and deepest_end > 0, "buff grants wait for trigger descendants")
	rotation = [skill("skill.parry_strike", 500, 300)]
	result = CombatResolver.resolve(rotation, player(), Monster.new(), 1000, 4, true)
	check(result.cast_events.size() == 2 and result.total_damage == 0, "unready macro spends time and advances")
	for cast in result.cast_events:
		check(cast.resource_unavailable, "missing charge visible")
	var interrupted := Monster.new()
	interrupted.interrupt_skip_count = 1
	rotation = [skill("skill.quick_cut", 100), skill("skill.leaping_plunge", 500, 500), skill("skill.leaping_plunge", 500, 500), skill("skill.leaping_plunge", 500, 500)]
	result = CombatResolver.resolve(rotation, player(), interrupted, 1600, 4, true)
	check(result.cast_events[1].lifecycle_snapshot.footwork_consumed == 1 and result.cast_events[3].was_interrupted, "consumption precedes interruption handling")

func _invalid_input() -> void:
	var stats := player()
	stats.footwork_rank = 6
	var rotation: Array[Skill] = [skill("skill.quick_cut", 100)]
	var result := CombatResolver.resolve(rotation, stats, Monster.new(), 1000, 1, true)
	check(not result.is_valid and result.failure.code == "invalid_effect_lifecycle", "invalid lifecycle configuration fails closed")

func _invalid_cleanup() -> void:
	var stats := player()
	var cut := skill("skill.quick_cut", 100)
	var repeat := TriggeredSkillEffect.new()
	repeat.skill = cut
	repeat.chance = 1.0
	stats.triggered_skill_effects.append(repeat)
	for i in range(1024):
		stats.triggered_skill_effects.append(null)
	var rotation: Array[Skill] = [cut]
	var result := CombatResolver.resolve(rotation, stats, Monster.new(), 1000, 1, true)
	check(not result.is_valid and result.failure.code == "trigger_candidate_limit", "budget breach remains invalid")
	check(result.effect_lifecycle.state.snapshot().is_empty(), "budget failure removes already-granted effects")
	var reset_count := 0
	for record in result.trace.records:
		if record.lifecycle_reason == "invalid_simulation":
			reset_count += 1
	check(reset_count == 2, "both active core effects log invalidation cleanup")
