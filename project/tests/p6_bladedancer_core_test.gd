extends SceneTree
const Core = preload("res://tests/fixtures/p6/bladedancer_core/core.gd")
const Lab = preload("res://scripts/tools/balance_lab.gd")
const Observation = preload("res://tests/helpers/p6_combat_observation_cases.gd")
var failed := false
var checks := 0
var report := {"scope": "T8 combat correctness; not balance or playable acceptance", "scenarios": [], "examples": []}

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed = true
		printerr("FAILED: " + label)

func _run() -> void:
	var registry := Core.registry()
	check(registry.validate_ranked() == "", "core registry readiness")
	var build := Core.build(registry)
	if build == null:
		check(false, "core purchase sequence")
		quit(1)
		return
	var rogue: ClassDef = registry.classes["class.rogue"]
	var gear: Array[GearItem] = [load("res://data/gear/crude_dagger.tres")]
	var resolved := BuildResolver.resolve_ranked_build(rogue, build, gear)
	check(resolved.error == "", "ranked resolution")
	if resolved.error != "":
		quit(1)
		return
	check(build.rank_map() == Core.RANKS and build.points_spent() == 10 and build.unspent_points() == 0, "exact ten-point allocation")
	var p: PlayerStats = resolved.stats
	check(is_equal_approx(p.retrigger_chance, 0.07) and p.bonus_physical_damage == 4.0, "intrinsic 5% + ten times 0.2%; Whetstone +4")
	check(p.footwork_rank == 5 and p.readiness_enabled and p.riposte_rank == 0 and p.dance_duration_ms == 0, "resolved lifecycle inputs without manual flags")
	var ids: Array[String] = []
	for skill in resolved.skills:
		ids.append(skill.id)
	ids.sort()
	var expected: Array[String] = ["skill.hold", "skill.stab", "skill.heavy_slash", "skill.quick_cut", "skill.leaping_plunge", "skill.parry_strike", "skill.rending_thrust"]
	expected.sort()
	check(ids == expected, "all seven unlocked skills; empty nine-point slot; no Dance")
	var rotation: Array[Skill] = Core.rotation(resolved.skills)
	check(rotation.size() == 5 and rotation[0].id == rotation[1].id, "exact five-slot rotation retains duplicate Quick Cut")
	report["build"] = Core.payload()
	report["stats"] = {"retrigger_chance": p.retrigger_chance, "base_damage_bonus": p.bonus_physical_damage, "footwork_rank": p.footwork_rank, "readiness_enabled": p.readiness_enabled}
	report["unlocked_skills"] = ids
	_allocation_boundaries(registry, rogue)
	_skill_contracts(resolved.skills)
	_scenarios(registry, rotation, p)
	_gear(registry, build, rogue)
	_readiness_and_shred(rotation, p)
	_boundaries(rotation, p)
	var decoded := BuildSaveCodec.decode(Core.payload(), registry)
	check(decoded.error == "" and decoded.model.rank_map() == Core.RANKS, "isolated codec roundtrip")
	var spec := _scenario("core_lab", {})
	var blocked := Lab.run_scenario_spec(spec)
	check(blocked.status == "not_ready" and blocked.seed_count == 0, "packaged registry cannot silently run unreleased core")
	var lab := Lab.run_scenario_spec(spec, registry)
	check(lab.status == "pass" and lab.seed_count == 20, "injected Balance Lab core runs twenty seeds")
	report["balance_lab"] = lab
	check(BuildContentRegistry.current().revision == "p6.compat.1", "playable registry unchanged")
	report["checks"] = checks
	report["pass"] = not failed
	var path: String = get_script().resource_path.get_base_dir().path_join("core_handoff.json")
	check(SaveSystem.write_json(path, report), "write reproducible handoff evidence")
	print("P6 M3 T8 core: %s (%d checks)" % ["FAIL" if failed else "PASS", checks])
	quit(1 if failed else 0)

func _allocation_boundaries(registry: BuildContentRegistry, rogue: ClassDef) -> void:
	var model := RankedBuild.new()
	model.configure(registry.trees["tree.bladedancer"], null, 10)
	check(not model.buy("talent.bladedancer.fancy_footwork"), "five-point gate enforced")
	for n in range(1, 5):
		model.buy("talent.bladedancer.wet_stone")
		var result := BuildResolver.resolve_ranked_build(rogue, model)
		check(result.stats.footwork_rank == 0 and not result.stats.readiness_enabled, "no premature lifecycle activation")
	model.buy("talent.bladedancer.rending_slash")
	for rank in range(1, 6):
		check(model.buy("talent.bladedancer.fancy_footwork"), "Footwork rank purchase")
		var result := BuildResolver.resolve_ranked_build(rogue, model)
		check(result.stats.footwork_rank == rank and result.stats.readiness_enabled, "rank and six-point Readiness binding")
	for rank in range(4, -1, -1):
		check(model.refund("talent.bladedancer.fancy_footwork", true), "rank refund")
		var result := BuildResolver.resolve_ranked_build(rogue, model)
		check(result.stats.footwork_rank == rank and result.stats.readiness_enabled == (rank > 0), "refund recomputes passives/unlocks")
	var invalid := Core.registry()
	invalid.talents["talent.bladedancer.fancy_footwork"].ranks[0].footwork_rank = 6
	check(invalid.validate_ranked() != "", "invalid rank contract rejected")
	check(registry.validate_ranked() == "", "fixture clones isolate invalid edit")

func _skill_contracts(skills: Array[Skill]) -> void:
	var timings := {"skill.quick_cut": [850, 500, 0.66], "skill.rending_thrust": [1400, 650, 0.78], "skill.parry_strike": [500, 300, 1.2], "skill.leaping_plunge": [2500, 500, 1.9]}
	for skill in skills:
		if timings.has(skill.id):
			var t: Array = timings[skill.id]
			check(skill.base_execution_ms == t[0] and skill.min_execution_ms == t[1] and is_equal_approx(CombatResolver.weapon_scaling_for_skill(skill), t[2]), "approved skill contract " + skill.id)
		var core := Core.registry()
		var result := BuildResolver.resolve_ranked_build(core.classes["class.rogue"], Core.build(core))
		var combat := CombatResolver.resolve([skill], result.stats, Monster.new(), 10000, 13, true)
		check(combat.is_valid and combat.cast_events.size() > 0, "every unlocked skill executes " + skill.id)
		if skill.id == "skill.parry_strike":
			check(combat.total_damage == 0 and combat.cast_events[0].resource_unavailable, "Parry-only macro cannot manufacture Readiness")

func _scenario(id: String, overrides: Dictionary) -> Dictionary:
	var fields := {"hp": 1000000, "armor": 0, "poison_resistance": 0.0}
	fields.merge(overrides, true)
	return {"id": id, "label": id, "ranked_build": Core.payload(), "monster": "res://data/monsters/mouthy_drunk.tres",
		"monster_overrides": fields, "gear": ["res://data/gear/crude_dagger.tres"], "duration_ms": 30000, "seed_start": 1, "seed_count": 20}

func _scenarios(registry: BuildContentRegistry, rotation: Array[Skill], p: PlayerStats) -> void:
	var cases := {"neutral": {}, "armor": {"armor": 200}, "full_block": {"block": 100000}, "dodge": {"dodge_chance": 1.0}, "interrupt": {"interrupt_skip_count": 1}, "slow": {"slow": 0.5}, "cleanse": {"cleanse_threshold": 2}}
	for label in cases:
		var first := Lab.run_scenario_spec(_scenario(label, cases[label]), registry)
		var replay := Lab.run_scenario_spec(_scenario(label, cases[label]), registry)
		check(first.status == "pass" and first.samples == replay.samples and first.aggregate == replay.aggregate, "twenty-seed deterministic scenario " + label)
		report.scenarios.append(first)
	var target := Monster.new()
	var combat := CombatResolver.resolve(rotation, p, target, 30000, 7, true)
	var quiet := CombatResolver.resolve(rotation, p, target, 30000, 7)
	check(combat.is_valid and quiet.rng_final_state == combat.rng_final_state and Observation.signature(quiet) == Observation.signature(combat), "trace/RNG parity")
	check(combat.effect_lifecycle.state.snapshot().is_empty(), "fight cleanup")
	for row in combat.trace.records:
		if row.kind in ["cast_start", "effect_lifecycle", "cast_resolved", "status_transaction"]:
			report.examples.append(row)
		if report.examples.size() >= 45:
			break
	report["core_seed_7_trace"] = combat.trace.records

func _gear(registry: BuildContentRegistry, build: RankedBuild, rogue: ClassDef) -> void:
	var item: GearItem = load("res://data/gear/crude_dagger.tres").duplicate(true)
	for pair in [[StatCatalog.INCREASED_ALL_STACKS, 1.0], [StatCatalog.INCREASED_ATTACK_SPEED, 1.0], [StatCatalog.CHANCE_FOR_RETRIGGER, 0.2]]:
		var modifier := StatModifier.new()
		modifier.stat_id = pair[0]
		modifier.value = pair[1]
		item.affixes.append(modifier)
	var result := BuildResolver.resolve_ranked_build(rogue, build, [item])
	check(is_equal_approx(result.stats.retrigger_chance, 0.27) and result.stats.bonus_footwork_stacks == 1, "gear and intrinsic combine once")
	var combat := CombatResolver.resolve(Core.rotation(result.skills), result.stats, Monster.new(), 30000, 19, true)
	check(combat.is_valid, "gear-enhanced core executes")
	for cast in combat.cast_events:
		if cast.origin_kind == "macro" and cast.skill.id == "skill.leaping_plunge":
			check(cast.time_ms - cast.cast_start_ms >= 500 and cast.lifecycle_snapshot.footwork_consumed <= 5, "gear-enhanced Plunge preserves minimum and cap")
	check(registry.revision == Core.REVISION, "gear case keeps fixture identity")
	var doubling := StatModifier.new()
	doubling.stat_id = StatCatalog.DOUBLE_APPLIED_STACKS
	doubling.value = 1.0
	item.affixes.append(doubling)
	var proc := TriggeredSkillEffect.new()
	proc.skill = load("res://data/skills/stab.tres")
	proc.source_skill_ids = ["skill.quick_cut"]
	proc.chance = 1.0
	item.triggered_skill_effects.append(proc)
	result = BuildResolver.resolve_ranked_build(rogue, build, [item])
	combat = CombatResolver.resolve(Core.rotation(result.skills), result.stats, Monster.new(), 10000, 19, true)
	var saw_proc := false
	var saw_grant := false
	for cast in combat.cast_events:
		if cast.origin_kind == "proc" and cast.skill.id == "skill.stab":
			saw_proc = true
			check(cast.trigger_source_skill_id == "skill.quick_cut", "gear proc obeys Quick Cut source filter")
	for row in combat.trace.records:
		if row.kind == "effect_lifecycle" and row.payload.effect_id == "footwork" and row.lifecycle_reason in ["granted", "refreshed"]:
			saw_grant = true
			check(row.payload.after.stacks <= 5 and row.payload.after.stacks >= 4, "resolved gear extra stacks double before Footwork cap")
	check(combat.is_valid and saw_proc and saw_grant, "core integrates inherited gear procs and stack doubling")

func _readiness_and_shred(rotation: Array[Skill], p: PlayerStats) -> void:
	var saw_ready := false
	var saw_unready := false
	for seed in range(1, 21):
		var result := CombatResolver.resolve(rotation, p, Monster.new(), 30000, seed, true)
		for cast in result.cast_events:
			if cast.skill.id == "skill.parry_strike":
				if cast.resource_unavailable:
					saw_unready = true
				else:
					saw_ready = true
					check(cast.lifecycle_snapshot.readiness_consumed == 1, "every successful Parry consumes Readiness")
	check(saw_ready and saw_unready, "natural 7% retrigger exercises ready and unready Parry")
	var target := Monster.new()
	target.armor = 200
	var rend: Skill = rotation[4]
	var result := CombatResolver.resolve([rend], p, target, 1400, 31, true)
	check(result.cast_events[0].shred_stacks_applied == 2 and result.cast_events[0].status_snapshot.armor == 180, "Rending deals damage against original armor before two Shred stacks")
	var event := result.cast_events[0]
	var raw := (event.weapon_damage_roll + p.bonus_physical_damage) * 0.78 * p.physical_damage_multiplier
	if event.is_crit:
		raw *= p.crit_multiplier
	check(event.physical_damage == float(roundi(raw * 0.5)), "Rending damage uses 200 armor's 50% mitigation before Shred")
	var sum := 0.0
	for cast in result.cast_events:
		sum += cast.physical_damage
	check(sum == result.total_damage, "cast damage reconciles with result total")

func _boundaries(rotation: Array[Skill], p: PlayerStats) -> void:
	# Timing probe uses an inherited Hold clone to land on the exact buff deadline.
	var hold: Skill = load("res://data/skills/hold.tres").duplicate(true)
	hold.base_execution_ms = 3000
	var probe: Array[Skill] = [rotation[0], hold, rotation[3]]
	var result := CombatResolver.resolve(probe, p, Monster.new(), 6100, 7, true)
	check(result.cast_events[2].cast_start_ms == 3850 and result.cast_events[2].lifecycle_snapshot.footwork_consumed == 1, "core Plunge consumes Footwork on exact expiry")
	hold.base_execution_ms = 3001
	result = CombatResolver.resolve(probe, p, Monster.new(), 6351, 7, true)
	check(result.cast_events[2].lifecycle_snapshot.footwork_consumed == 0, "one millisecond late loses Footwork")
	result = CombatResolver.resolve(rotation, p, Monster.new(), 3199, 7, true)
	for cast in result.cast_events:
		check(cast.skill.id != "skill.leaping_plunge", "clipped core Plunge never starts or consumes")
	var blocked := Monster.new()
	blocked.block = 100000
	result = CombatResolver.resolve(rotation, p, blocked, 10000, 7, true)
	check(result.cast_events[4].lifecycle_snapshot.footwork_consumed == 3 and result.total_damage == 0.0, "blocked core attacks still earn and consume Footwork/Readiness")
	blocked.dodge_chance = 1.0
	result = CombatResolver.resolve(rotation, p, blocked, 10000, 7, true)
	for cast in result.cast_events:
		if cast.skill.id == "skill.leaping_plunge":
			check(cast.lifecycle_snapshot.footwork_consumed == 0, "dodged core attacks earn no Footwork")
	var fresh := CombatResolver.resolve([rotation[2]], p, Monster.new(), 500, 7)
	check(fresh.cast_events[0].resource_unavailable, "new fight/retry starts without Readiness")
