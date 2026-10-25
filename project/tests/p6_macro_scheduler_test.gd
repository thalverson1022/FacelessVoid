extends SceneTree
const Scheduler = preload("res://scripts/systems/combat_macro_scheduler.gd")
const Lifecycle = preload("res://scripts/systems/bladedancer_effect_lifecycle.gd")
const Observation = preload("res://tests/helpers/p6_combat_observation_cases.gd")
var failed := false

func _initialize() -> void:
	_zero_time_progress()
	_unready_slots()
	_planning_snapshots()
	_inherited_skills()
	_approved_core_damage()
	_stun_and_poison_order()
	_invalid_schedules()
	print("P6 T5 macro scheduling: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		failed = true
		printerr("FAILED: " + label)

func make_skill(id: String, duration: int, minimum: int = 0) -> Skill:
	var skill := Skill.new()
	skill.id = id
	skill.base_execution_ms = duration
	skill.min_execution_ms = minimum
	var damage := PhysicalDamageEffect.new()
	damage.amount = 10
	skill.effects = [damage]
	return skill

func _zero_time_progress() -> void:
	var stats := PlayerStats.new()
	stats.min_cast_time_proc_chance = 1.0
	var rotation: Array[Skill] = [make_skill("test.zero", 1000)]
	var result := CombatResolver.resolve(rotation, stats, Monster.new(), 10, 1, true)
	check(result.is_valid and result.cast_events.size() == 10, "minimum proc uses 1ms floor")
	for event in result.cast_events:
		check(event.time_ms - event.cast_start_ms == 1 and event.min_cast_time_proc_applied, "positive progress on every macro cast")
	check(result.trace.records.back().payload.decision == "window_exhausted", "window clipping diagnostic")
	stats.min_cast_time_proc_chance = 0
	rotation[0].base_execution_ms = 0
	result = CombatResolver.resolve(rotation, stats, Monster.new(), 10)
	check(result.cast_events.size() == 10, "ordinary zero-time floor preserved")

func _unready_slots() -> void:
	var stats := PlayerStats.new()
	stats.readiness_enabled = true
	var parry := make_skill("skill.parry_strike", 500, 300)
	var rotation: Array[Skill] = [parry, parry]
	var result := CombatResolver.resolve(rotation, stats, Monster.new(), 2000, 4, true)
	check(result.cast_events.size() == 4 and result.total_damage == 0, "all unready slots advance by cast duration")
	var decisions := 0
	for event in result.trace.records:
		if event.kind == "schedule_decision" and event.payload.get("reason") == "missing_readiness":
			check(event.payload.rotation_index == decisions % 2 and event.payload.execution_ms == 500, "duplicate slots retain order and spent time")
			decisions += 1
	check(decisions == 4, "each unready cast has a diagnostic")
	var replay := CombatResolver.resolve(rotation, stats, Monster.new(), 2000, 4, true)
	var quiet := CombatResolver.resolve(rotation, stats, Monster.new(), 2000, 4, false)
	check(replay.trace.records == result.trace.records, "same-seed scheduling replay")
	check(quiet.rng_final_state == result.rng_final_state and Observation.signature(quiet) == Observation.signature(result), "trace-on/off outcome and RNG parity")

func _planning_snapshots() -> void:
	var stats := PlayerStats.new()
	stats.attack_speed = 0.25
	var effects = Lifecycle.new(5, true)
	effects.finish_cast("skill.quick_cut", true, true, 0, 3)
	var plunge := make_skill("skill.leaping_plunge", 2500, 500)
	# D018: rank five * three stacks gives 60% reduction after IAS: 2000 * 0.4.
	var plan: Dictionary = Scheduler.plan(plunge, stats, 0.0, 3000, 5000, false, effects)
	check(plan.execution_ms == 800 and plan.fits_window, "ordinary speed then Footwork at exact deadline")
	check(effects.state.snapshot("footwork").stacks == 3, "planning never consumes")
	var clipped: Dictionary = Scheduler.plan(plunge, stats, 0, 3000, 3799, false, effects)
	check(not clipped.fits_window and effects.state.snapshot("footwork").stacks == 3, "clipped planning retains resources")
	var after: Dictionary = Scheduler.plan(plunge, stats, 0, 3001, 6000, false, effects)
	check(after.execution_ms == 2000, "expired Footwork excluded from preview")
	stats.attack_speed = 2
	check(plan.execution_ms == 800 and plan.attack_speed == 0.25, "planned windup is immutable")
	var parry := make_skill("skill.parry_strike", 500, 300)
	check(Scheduler.plan(parry, stats, 0, 0, 1000, false).execution_ms == 300, "ordinary minimum floor")
	check(Scheduler.plan(parry, stats, 1, 0, 1000, false).execution_ms == 600, "inherited slow after speed floor")

func _inherited_skills() -> void:
	# Every shipped skill shares the same planner, including Hold and nonattacks.
	var paths := DirAccess.get_files_at("res://data/skills")
	var tested := 0
	for path in paths:
		if not path.ends_with(".tres"):
			continue
		var skill := load("res://data/skills/" + path) as Skill
		if skill == null:
			continue
		var stats := PlayerStats.new()
		var expected := CombatTiming.execution_time_ms_with_slow(skill, stats.attack_speed, 0)
		var plan: Dictionary = Scheduler.plan(skill, stats, 0, 0, expected, false)
		check(plan.fits_window and plan.execution_ms == expected, "shared plan for " + skill.id)
		var rotation: Array[Skill] = [skill]
		var result := CombatResolver.resolve(rotation, stats, Monster.new(), expected, 1, true)
		check(result.is_valid and result.cast_events.size() == 1 and result.cast_events[0].time_ms == expected, "resolver executes " + skill.id)
		tested += 1
	check(tested > 0, "inherited resource coverage is nonempty")
	print("Inherited skills checked: " + str(tested))

func _invalid_schedules() -> void:
	var missing: Array[Skill] = [null]
	var result := CombatResolver.resolve(missing, PlayerStats.new(), Monster.new(), 1000)
	check(not result.is_valid and result.failure.code == "invalid_macro_schedule", "missing slot fails before dereference")
	var rotation: Array[Skill] = [make_skill("test", 10)]
	for duration in [0, -1]:
		result = CombatResolver.resolve(rotation, PlayerStats.new(), Monster.new(), duration)
		check(not result.is_valid and result.cast_events.is_empty(), "nonpositive window rejected")
	var empty: Array[Skill] = []
	result = CombatResolver.resolve(empty, PlayerStats.new(), Monster.new(), 1000)
	check(result.is_valid and result.cast_events.is_empty(), "empty macro preserves compatibility")

func _approved_core_damage() -> void:
	var stats := PlayerStats.new()
	stats.weapon_damage_min = 100
	stats.weapon_damage_max = 100
	for row in [["skill.quick_cut", 850, 500, 66.0], ["skill.parry_strike", 500, 300, 120.0], ["skill.leaping_plunge", 2500, 500, 190.0]]:
		var skill := make_skill(row[0], row[1], row[2])
		var rotation: Array[Skill] = [skill]
		# Direct scalar fixture: conditional eligibility is covered separately.
		var result := CombatResolver.resolve(rotation, stats, Monster.new(), int(row[1]))
		check(result.cast_events.size() == 1 and is_equal_approx(result.total_damage, float(row[3])), "approved weapon percentage " + str(row[0]))

func _stun_and_poison_order() -> void:
	var stats := PlayerStats.new()
	stats.footwork_rank = 5
	stats.poison_damage_per_tick = 3
	var cut := make_skill("skill.quick_cut", 100)
	cut.poison_stacks_applied = 5
	var monster := Monster.new()
	monster.hp = 1
	monster.stun_duration_ms = 3000
	var rotation: Array[Skill] = [cut, make_skill("skill.leaping_plunge", 2000, 500)]
	var result := CombatResolver.resolve(rotation, stats, monster, 4900, 1, true)
	check(result.cast_events.size() == 2, "stun gap advances macro start")
	if result.cast_events.size() != 2:
		return
	check(result.cast_events[1].cast_start_ms == 3100 and result.cast_events[1].time_ms == 4700, "stun resumes at inclusive Footwork deadline")
	var ticks_before_start := 0
	for record in result.trace.records:
		if record.kind == "poison_tick" and record.time_ms <= 3100:
			ticks_before_start += 1
		if record.kind == "schedule_decision" and record.cast_id == result.cast_events[1].cast_id:
			check(ticks_before_start == 3, "stun catch-up ticks precede next schedule decision")
	check(result.tick_events.size() == 4, "poison clock continues during stun and windup")
