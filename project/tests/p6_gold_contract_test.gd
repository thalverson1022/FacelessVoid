extends "res://tests/p6_status_interactions_test.gd"
const Gold = preload("res://scripts/systems/combat_gold.gd")
const Theft = preload("res://scripts/resources/steal_gold_effect.gd")
const Mixed = preload("res://tests/fixtures/p6/mixed_build.gd")
const Contracts = preload("res://scripts/systems/p6_thief_contracts.gd")
const Lab = preload("res://scripts/tools/balance_lab.gd")

func _initialize() -> void:
	super._initialize()

func _run() -> void:
	_caps_and_transactions()
	_resolution_and_reset()
	_mixed_allocation()
	_thief_skills()
	_mixed_combat()
	_practice_and_gear()
	super._run()

func _mixed_allocation() -> void:
	var registry: BuildContentRegistry = Mixed.registry()
	for reversed_roles in [false, true]:
		var build: RankedBuild = Mixed.build(registry, reversed_roles)
		check(build != null, "exact mixed purchase sequence is legal")
		if build == null:
			continue
		check(build.rank_map() == Mixed.RANKS, "exact twenty-point allocation")
		var resolved := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"], build)
		check(resolved.error == "", "mixed scalar resolution")
		if resolved.error != "":
			continue
		var stats: PlayerStats = resolved.stats
		check(is_equal_approx(stats.gold_reward_multiplier, 1.2 if reversed_roles else 1.1), "Thief base plus primary-only scaling is additive")
		check(is_equal_approx(stats.retrigger_chance, 0.05 if reversed_roles else 0.08), "Bladedancer primary-only scaling")
		check(is_equal_approx(stats.elemental_damage_multiplier, 1.1) and is_equal_approx(stats.physical_damage_multiplier, 1.1), "Keen Eye affects both damage buckets")
		check(is_equal_approx(stats.crit_multiplier, registry.classes["class.rogue"].base_stats.crit_multiplier + 1.0), "Cloak adds 100 percentage points at rank two")
		check(stats.triggered_skill_effects.size() == 1 and is_equal_approx(stats.triggered_skill_effects[0].chance, 0.3), "Opportunity rank three is one thirty-percent Quick Cut trigger")
	var zero: RankedBuild = Mixed.build(registry, false, true)
	check(zero != null and zero.rank_of("talent.keen_eye") == 0, "zero secondary allocation")
	var resolved := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"], zero)
	check(resolved.error == "" and is_equal_approx(resolved.stats.gold_reward_multiplier, 1.1), "uninvested secondary still receives base intrinsic")

func _caps_and_transactions() -> void:
	var player := PlayerStats.new()
	player.gilded_blade_enabled = true
	player.crit_multiplier = 2.5
	for stash in [0, 100, 499, 500, 501, 10000]:
		var value := Gold.crit_values(player, stash, 0)
		check(value.gilded_counted_gold == mini(stash, 500), "Gilded counted stash cap")
		check(is_equal_approx(value.crit_multiplier, 2.5 + mini(stash, 500) * 0.01), "Gilded contribution does not cap other crit damage")
	player.crit_multiplier_per_current_gold = 0.001
	check(Gold.crit_values(player, 10000, 0).crit_multiplier == 17.5, "legacy gold scaling remains separate from Gilded cap")
	var transaction := Gold.theft(3, 1.3, 499, 0, "skill.steal", player)
	check(transaction.credited_amount == 3 and transaction.stash_after == 502 and transaction.stolen_after == 3, "baseline floor and separate gold counters")
	check(transaction.stats_before.gilded_counted_gold == 499 and transaction.stats_after.gilded_counted_gold == 500, "transaction records cap crossing")
	check(Gold.theft(3, 0.1, 0, 0, "test", player).credited_amount == 0, "fractional theft floors to zero")
	var talent := Talent.new()
	talent.id = "talent.gilded_blade"
	talent.gilded_blade_enabled = true
	var built := BuildResolver.resolve_stats(load("res://data/classes/rogue.tres"), [], [talent], [], 10000)
	check(built.gilded_blade_enabled and Gold.crit_values(built, 10000, 0).gilded_crit_bonus == 5.0, "explicit passive reaches resolved stats")

func _resolution_and_reset() -> void:
	var player := PlayerStats.new()
	player.current_gold = 499
	player.gilded_blade_enabled = true
	player.crit_chance = 1.0
	player.gold_reward_multiplier = 1.5
	var skill := _skill("test.gold")
	var theft := Theft.new()
	theft.amount = 3
	skill.effects.append(theft)
	skill.effects.append(theft.duplicate(true))
	var result := CombatResolver.resolve([skill], player, _monster(), 2000, 42, true)
	check(result.gold_stolen == 16 and player.current_gold == 499, "simulation totals theft without crediting source stash")
	check(result.cast_events[0].stat_snapshot.gold.gilded_counted_gold == 499 and result.cast_events[1].stat_snapshot.gold.gilded_counted_gold == 500, "next hit observes credited gold")
	var sum := 0
	var previous := 499
	for row in result.trace.records:
		if row.kind == "gold_transaction":
			check(row.payload.stash_before == previous and row.payload.raw_amount == 3, "ordered transaction raw/stash accounting")
			previous = row.payload.stash_after
			sum += row.payload.credited_amount
	check(sum == result.gold_stolen and previous == 515, "gold trace reconciles with result")
	var replay := CombatResolver.resolve([skill], player, _monster(), 2000, 42, true)
	var off := CombatResolver.resolve([skill], player, _monster(), 2000, 42)
	check(replay.trace.records == result.trace.records and off.rng_final_state == result.rng_final_state, "repeat/retry and trace-neutral RNG")
	var state: Node = root.get_node("BuildState")
	state.reset()

	state.gold = 499
	state.record_combat_stolen_gold(result.gold_stolen)
	check(state.gold == 515 and state.combat_stolen_gold == 16, "playback credits stash and fight counter")
	state.clear_combat_stolen_gold()
	check(state.gold == 515 and state.combat_stolen_gold == 0, "new fight clears counter without removing stash")
	state.add_gold(10)
	check(state.gold == 525 and state.combat_stolen_gold == 0, "reward credit does not become theft")
	check(state.spend_gold(425) and state.gold == 100, "spending updates current stash")
	check(Gold.crit_values(player, state.gold, 0).gilded_crit_bonus == 1.0, "spending below cap reduces Gilded contribution")
	check(not state.spend_gold(101) and state.gold == 100, "failed purchase preserves gold")
	state.reset()


func _thief_skills() -> void:
	var stats := PlayerStats.new()
	stats.weapon_damage_min = 100
	stats.weapon_damage_max = 100
	var pocket: Skill = Contracts.skill("pick_pocket")
	var mug: Skill = Contracts.skill("mug")
	var big: Skill = Contracts.skill("big_score")
	var steal: Skill = Contracts.skill("steal")
	check(steal.base_execution_ms == 1100 and steal.min_execution_ms == 650 and is_equal_approx(CombatResolver.weapon_scaling_for_skill(steal), 1.06), "Steal inherits current approved values")
	check(mug.base_execution_ms == 1500 and mug.min_execution_ms == 700 and pocket.base_execution_ms == 1800 and pocket.min_execution_ms == 800 and big.base_execution_ms == 1800 and big.min_execution_ms == 700, "Thief skill timing descriptors")
	for skill in [steal, mug, big]:
		check(skill.cooldown_ms == 0, "no Thief attack cooldown")
	check(pocket.cooldown_ms == 8000, "Pick Pocket retains approved eight-second cooldown")
	# Isolate repeated-theft accounting below from cooldown scheduling.
	pocket.cooldown_ms = 0
	for rank in range(4):
		stats.silvered_edge_rank = rank
		for stolen in [0, 1, 24, 25, 26, 49, 50, 51, 74, 75, 76, 10000]:
			check(is_equal_approx(Gold.crit_values(stats, 10000, stolen).silvered_crit_bonus, minf(stolen * 0.01, 0.25 * rank)), "Silvered contribution cap per rank")
	stats.silvered_edge_rank = 0
	for gold in [0, 100, 499, 500, 501, 10000]:
		stats.current_gold = gold
		var no_theft := CombatResolver.resolve([mug], stats, _monster(), 1500, 7)
		check(no_theft.total_damage == 100 and no_theft.gold_stolen == 0, "stash does not fuel Mug")
		var fueled := CombatResolver.resolve([pocket, mug], stats, _monster(), 3300, 7)
		check(fueled.gold_stolen == 10 and fueled.cast_events[1].physical_damage == 110, "Mug uses actual current-fight theft")
	for pair in [[0,0],[1,1],[2,2],[3,3],[49,49],[50,50],[51,50],[99,50],[100,50],[200,50],[999,50]]:
		var theft: Skill = pocket.duplicate(true)
		theft.effects[0].amount = pair[0]
		var boundary := CombatResolver.resolve([theft,mug],stats,_monster(),3300,7,true)
		check(boundary.cast_events[1].physical_damage==100+pair[1] and boundary.cast_events[1].stat_snapshot.stolen_gold_base_damage==pair[1],"Mug adds credited theft up to its damage cap: %d" % pair[0])
	stats.gold_reward_multiplier = 20.0
	var capped := CombatResolver.resolve([pocket, mug], stats, _monster(), 3300, 7)
	check(capped.gold_stolen == 200 and capped.cast_events[1].physical_damage == 150 and capped.cast_events[1].stat_snapshot.stolen_gold_base_damage == 50, "Mug caps base contribution without removing credited gold")
	stats.gold_reward_multiplier = 1.5
	stats.silvered_edge_rank = 1
	var ramp := CombatResolver.resolve([pocket, mug], stats, _monster(), 3300, 7)
	check(ramp.gold_stolen == 15 and is_equal_approx(ramp.cast_events[1].stat_snapshot.effective_crit_chance, 0.15), "credited Increased Gold drives Silvered next hit")
	stats.silvered_edge_rank = 0
	stats.crit_chance = 1.0
	stats.crit_multiplier = 3.0
	check(CombatResolver.resolve([big], stats, _monster(), 1800, 7).total_damage == 1620, "Big Score multiplies full current crit multiplier by six")
	check(big.critical_damage_factor == 6.0 and SkillTooltipFormatter.conditions_for(big, null).contains("by 6x"), "Big Score live descriptor and tooltip agree")
	stats.gilded_blade_enabled = true
	stats.current_gold = 500
	check(CombatResolver.resolve([big], stats, _monster(), 1800, 7).total_damage == 4320, "Big Score factor includes Gilded Blade: (3+5)*6")
	stats.gilded_blade_enabled = false
	stats.current_gold = 0
	stats.crit_chance = 0.0
	check(CombatResolver.resolve([big], stats, _monster(), 1800, 7).total_damage == 90, "Big Score noncrit remains 90 percent")
	var target := _monster()
	target.dodge_chance = 1.0
	target.cleanse_threshold = 1
	target.interrupt_skip_count = 1
	var utility := CombatResolver.resolve([pocket], stats, target, 5400, 7)
	check(utility.gold_stolen == 45 and utility.total_damage == 0, "Pick Pocket debuff ignores dodge/interrupt without damage")
	for event in utility.cast_events:
		check(not event.cleanse_triggered and not event.was_interrupted and not event.was_dodged, "Pick Pocket preserves category counters")
	stats.crit_chance = 1.0
	stats.gilded_blade_enabled = true
	stats.current_gold = 499
	stats.retrigger_chance = 1.0
	var repeated := CombatResolver.resolve([steal], stats, _monster(), 1300, 7, true)
	check(repeated.cast_events.size() == CombatResolver.MAX_RETRIGGER_CHAIN_DEPTH + 1 and repeated.cast_events[1].stat_snapshot.gold.stash == 503 and repeated.cast_events[1].stat_snapshot.gold.gilded_counted_gold == 500, "same-time repeat sees parent credited theft and cap")
	check(repeated.gold_stolen == 4 * repeated.cast_events.size(), "each critical Steal credits floor(3 times 1.5)")

func _mixed_combat() -> void:
	var registry: BuildContentRegistry = Mixed.registry()
	check(registry.validate_ranked() == "", "mixed registry validates")
	var reports: Array = []
	for reversed_roles in [false, true]:
		for gold in [0, 100, 499, 500, 501, 10000]:
			var spec := _mixed_spec("mixed_%s_%d" % [reversed_roles, gold], reversed_roles, gold)
			var first := Lab.run_scenario_spec(spec, registry)
			var second := Lab.run_scenario_spec(spec, registry)
			check(first.status == "pass" and first.samples == second.samples and first.aggregate == second.aggregate, "twenty-seed exact mixed replay for both roles and gold boundaries")
			reports.append(first)
	for kind in ["crit_negation", "dodge", "block", "duplicate_dance", "zero_secondary"]:
		var spec := _mixed_spec(kind, false, 100)
		match kind:
			"crit_negation": spec.monster_overrides["crit_negation"] = 1.0
			"dodge": spec.monster_overrides["dodge_chance"] = 1.0
			"block": spec.monster_overrides["block"] = 100000.0
			"duplicate_dance": spec.ranked_build.rotation_skill_ids.insert(1, "skill.dance_of_death")
			"zero_secondary": spec.ranked_build = Mixed.payload(false, true)
		var first := Lab.run_scenario_spec(spec, registry)
		var second := Lab.run_scenario_spec(spec, registry)
		check(first.status == "pass" and first.samples == second.samples, "mixed boundary scenario " + kind)
		reports.append(first)
	var build := Mixed.build(registry)
	var resolved := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"], build, [load("res://data/gear/crude_dagger.tres")], 100)
	check(resolved.stats.dance_duration_ms == 5000 and resolved.skills.size() == 10, "all ten unlocks and Dance bound without manual flags")
	var requested: Array[Skill] = []
	for id in Mixed.ROTATION:
		var value := Skill.new()
		value.id = id
		requested.append(value)
	var rotation := BuildResolver.resolve_rotation(requested, resolved.skills)
	var result := CombatResolver.resolve(rotation, resolved.stats, _monster(), 30000, 7, true)
	var off := CombatResolver.resolve(rotation, resolved.stats, _monster(), 30000, 7)
	check(result.is_valid and result.total_damage == off.total_damage and result.rng_final_state == off.rng_final_state, "mixed trace and RNG neutrality")
	check(result.effect_lifecycle.state.snapshot().is_empty() and result.talent_buffs.state.snapshot().is_empty(), "mixed fight cleanup")
	check(Lab.run_scenario_spec(_mixed_spec("unreleased", false, 0)).status == "not_ready", "unreleased mixed fixture stays gated")
	check(BuildContentRegistry.current().revision == "p6.compat.1", "playable compatibility registry unchanged")
	var path: String = get_script().resource_path.get_base_dir().path_join("mixed_handoff.json")
	check(SaveSystem.write_json(path, {"scope": "T10 mixed shared-combat evidence; not balance acceptance", "build": Mixed.payload(), "scenarios": reports, "seed_7_trace": result.trace.records, "pass": not failed}), "write mixed handoff evidence")

func _mixed_spec(id: String, reversed_roles: bool, gold: int) -> Dictionary:
	return {"id": id, "label": id, "ranked_build": Mixed.payload(reversed_roles),
		"monster": "res://data/monsters/mouthy_drunk.tres", "monster_overrides": {"hp": 1000000, "armor": 0, "poison_resistance": 0.0},
		"gear": ["res://data/gear/crude_dagger.tres"], "gold": gold, "duration_ms": 30000, "seed_start": 1, "seed_count": 20}

func _practice_and_gear() -> void:
	var registry: BuildContentRegistry = Mixed.registry()
	var gear: GearItem = load("res://data/gear/crude_dagger.tres").duplicate(true)
	gear.affixes.append(Mixed.modifier(StatCatalog.INCREASED_GOLD, 0.5))
	gear.affixes.append(Mixed.modifier(StatCatalog.CRIT_DAMAGE, 0.5))
	var model := Mixed.build(registry, true)
	var resolved := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"], model, [gear], 500)
	check(is_equal_approx(resolved.stats.gold_reward_multiplier, 1.8), "gear gold bucket combines with additive primary intrinsic")
	resolved.stats.gilded_blade_enabled = true
	check(is_equal_approx(Gold.crit_values(resolved.stats, 500, 0).crit_multiplier, registry.classes["class.rogue"].base_stats.crit_multiplier + 1.0 + 0.5 + 5.0), "Gilded leaves Cloak and gear crit contributions intact")
	var credited := CombatResolver.resolve([Contracts.skill("pick_pocket")], resolved.stats, _monster(), 1800, 7)
	check(credited.gold_stolen == 18, "resolved gear plus intrinsic determines credited theft")
	var bandit: GearItem = load("res://data/gear/bandit_blade.tres")
	var initial := BuildResolver.resolve_stats(registry.classes["class.rogue"], [], [], [bandit], 100)
	var after_spend := BuildResolver.resolve_stats(registry.classes["class.rogue"], [], [], [bandit], 0)
	check(initial.bonus_physical_damage == 10.0 and after_spend.bonus_physical_damage == 0.0, "inherited gear gold-to-base contribution rebuilds after spending")
	for reversed_roles in [false, true]:
		var practice := TrainingRoomState.new()
		practice.set_class(registry.classes["class.rogue"])
		practice.set_talent_budget(20)
		var blade: SubclassTree = registry.trees["tree.bladedancer"]
		var thief: SubclassTree = registry.trees["tree.thief"]
		check(practice.configure_ranked_build(thief if reversed_roles else blade, blade if reversed_roles else thief), "Practice configures both role choices")
		for id in Mixed.RANKS:
			for rank in Mixed.RANKS[id]:
				check(practice.select_talent(registry.talents[id]), "Practice buys exact mixed ranks")
		practice.configured_gold = 100
		practice.gold = 100
		practice.equipped_weapon = load("res://data/gear/crude_dagger.tres")
		practice.selected_target = _monster()
		practice.duration_ms = 30000
		practice.random_fight_seed_enabled = false
		practice.fight_seed = 7
		var requests: Array[Skill] = []
		for id in Mixed.ROTATION:
			var skill := Skill.new()
			skill.id = id
			requests.append(skill)
		practice.set_rotation(requests)
		practice.set_locked(true)
		practice.run_fight()
		check(practice.last_result != null and practice.last_result.is_valid, "actual mixed Practice fight")
		if practice.last_result == null:
			continue
		var result: CombatResolver.CombatResult = practice.last_result
		check(practice.gold == 100 and practice.combat_stolen_gold == 0, "Practice resolution waits for playback credit")
		practice.add_practice_combat_gold(result.gold_stolen)
		check(practice.gold == 100 + result.gold_stolen, "Practice playback credits exact theft")
		practice.run_fight()
		check(practice.gold == 100 and practice.combat_stolen_gold == 0 and practice.last_result.total_damage == result.total_damage and practice.last_result.gold_stolen == result.gold_stolen, "Practice retry resets configured stash and fight counter deterministically")
