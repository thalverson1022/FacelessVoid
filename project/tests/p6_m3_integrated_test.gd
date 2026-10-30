extends SceneTree
## Cross-package mechanics harness; deliberately not a legal full-tree build.
const Status = preload("res://scripts/systems/p6_status_skill_contracts.gd")
const Poison = preload("res://scripts/systems/p6_poison_contracts.gd")
const Thief = preload("res://scripts/systems/p6_thief_contracts.gd")
const Consume = preload("res://scripts/resources/consume_status_effect.gd")
const StatState = preload("res://scripts/systems/combat_stat_state.gd")
var failed := false
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed = true
		printerr("FAILED: " + message)

func _run() -> void:
	var player := PlayerStats.new()
	player.base_poison_damage = 10.0
	player.sync_poison_damage_per_tick()
	player.current_gold = 499
	player.gold_reward_multiplier = 1.5
	player.crit_chance = 0.25
	player.gilded_blade_enabled = true
	player.silvered_edge_rank = 3
	player.death_pact_rank = 3
	player.retrigger_chance = 0.2
	player.bribery_base_stacks = 6
	player.independent_decay_shred = true
	player.shred_cleanse_immune = true
	player.special_effects = {"double_applied_stacks": true}
	player = Status.apply_passives(player, 3, true, 3)
	player = Poison.apply_passives(player, 5, 5, 3, 4, true)
	player.stat_derivations = [{"kind": "fast_hands", "fraction": 0.5, "source_id": "test.fast_hands"}]
	player = StatState.new(player).snapshot()
	var decay := _skill("test.decay")
	decay.effects = [PoisonResistanceReductionEffect.new()]
	var conversion := _skill("test.distilled")
	var consume := Consume.new()
	consume.status = "decay"
	consume.amount = 5
	consume.poison_per_consumed = 1
	conversion.effects = [consume]
	var rotation: Array[Skill] = [Status.skill("poison_vile"), Status.skill("virulent_poison"),
		Status.skill("master_of_poisons"), Poison.poison_strike(), Status.skill("touch_of_darkness"),
		Thief.skill("pick_pocket"), decay, conversion, Status.skill("beguiling_presence"), Thief.skill("big_score")]
	var report := {"scope": "M3 cross-package correctness; not a legal build or balance target", "cases": []}
	for scenario in ["neutral", "zero_resistance", "mitigation", "physical_conversion", "cleanse", "slow_interrupt"]:
		var stats: PlayerStats = player.duplicate(true)
		var enemy := Monster.new()
		enemy.hp = 1000000
		enemy.poison_resistance = 0.4
		match scenario:
			"zero_resistance": enemy.poison_resistance = 0.0
			"mitigation":
				enemy.armor = 200
				enemy.block = 10000.0
				enemy.absorb = 10000.0
			"physical_conversion":
				stats.special_effects["damage_conversion"] = {"physical": true}
				enemy.armor = 100
				enemy.crit_negation = 0.5
			"cleanse": enemy.cleanse_threshold = 2
			"slow_interrupt":
				enemy.slow = 0.5
				enemy.suppress = 0.5
				enemy.interrupt_skip_count = 1
		var samples: Array = []
		for seed_value in range(1, 21):
			var result := CombatResolver.resolve(rotation, stats, enemy, 30000, seed_value, true)
			var replay := CombatResolver.resolve(rotation, stats, enemy, 30000, seed_value, true)
			var quiet := CombatResolver.resolve(rotation, stats, enemy, 30000, seed_value)
			check(result.is_valid and replay.is_valid and quiet.is_valid, "combined simulation valid")
			check(result.trace.records == replay.trace.records and result.rng_final_state == quiet.rng_final_state and result.total_damage == quiet.total_damage, "combined replay/trace neutrality")
			_accounting(result, enemy)
			check(result.talent_buffs.state.snapshot().is_empty() and (result.effect_lifecycle == null or result.effect_lifecycle.state.snapshot().is_empty()) and result.defense_debuffs.state.snapshot().is_empty() and result.self_buffs.instances.is_empty(), "every lifecycle cleaned up")
			check(stats.current_gold == 499 and stats.gold_reward_multiplier == 1.5, "simulation leaves source stats unchanged")
			samples.append({"seed": seed_value, "damage": result.total_damage, "gold": result.gold_stolen, "events": result.trace.sequence})
			if scenario == "neutral" and seed_value == 7:
				report["seed_7_trace"] = result.trace.records
			report["recap"] = CombatRecap.summarize(result, enemy)
		report.cases.append({"scenario": scenario, "samples": samples})
	_clipped_lifetimes()
	report["checks"] = checks
	report["pass"] = not failed
	var path: String = get_script().resource_path.get_base_dir().path_join("integrated_handoff.json")
	check(SaveSystem.write_json(path, report), "write integrated evidence")
	print("M3 integrated: %s (%d checks)" % ["FAIL" if failed else "PASS", checks])
	quit(1 if failed else 0)

func _accounting(result: CombatResolver.CombatResult, enemy: Monster) -> void:
	var damage := 0.0
	var gold := 0
	var poison := 0
	var decay := 0
	var sequence := 0
	var time_ms := 0
	for row in result.trace.records:
		check(row.sequence == sequence + 1 and row.time_ms >= time_ms and row.time_ms <= result.duration_ms, "bounded chronological event stream")
		sequence = row.sequence
		time_ms = row.time_ms
		if row.kind in ["cast_resolved", "poison_tick"]:
			damage += row.payload.damage
		if row.kind == "gold_transaction":
			check(row.payload.stolen_before == gold and row.payload.stash_before == 499 + gold, "gold source continuity")
			gold += row.payload.credited_amount
		if row.kind == "poison_tick":
			check(row.payload.stacks_before == poison, "tick sees reconciled Poison quantity")
			poison -= row.payload.stacks_depleted
			check(not row.payload.keyword_consume, "ticks do not become Consume under conversions")
		if row.kind == "status_transaction":
			var transaction: Dictionary = row.payload
			if transaction.status == "poison":
				check(transaction.before == poison, "Poison transaction continuity")
				poison = transaction.after
			if transaction.status == "decay":
				check(transaction.before == decay, "Decay transaction continuity")
				decay = transaction.after
		check(poison >= 0 and decay >= 0, "status quantities never negative")
	check(is_equal_approx(damage, result.total_damage) and gold == result.gold_stolen, "trace totals equal combat totals")
	var recap := CombatRecap.summarize(result, enemy)
	check(is_equal_approx(recap.physical_damage + recap.poison_damage, result.total_damage), "recap damage reconciles")

func _skill(id: String) -> Skill:
	var value := Skill.new()
	value.id = id
	value.base_execution_ms = 500
	value.min_execution_ms = 500
	value.category = Skill.Category.DEBUFF
	return value

func _clipped_lifetimes() -> void:
	var hold := _skill("skill.hold")
	hold.base_execution_ms = 10000
	var result := CombatResolver.resolve([Status.skill("master_of_poisons"), hold], PlayerStats.new(), Monster.new(), 2000, 7, true)
	var start := -1
	var end := -1
	for row in result.trace.records:
		if row.kind == "effect_lifecycle" and row.payload.effect_id == "master_of_poisons":
			if row.lifecycle_reason == "granted": start = row.time_ms
			if row.lifecycle_reason == "fight_end": end = row.time_ms
	check(start == 500 and end == 2000 and end - start == 1500, "Self Buff uptime clips to combat window")
	check(result.cast_events.size() == 1 and result.self_buffs.instances.is_empty(), "clipped cast neither executes nor leaks a buff")
