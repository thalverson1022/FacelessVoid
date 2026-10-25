extends "res://tests/p6_combat_ordering_test.gd"

func _initialize() -> void:
	super._initialize()


func _run() -> void:
	_precision()
	_dance_readiness()
	_dodge_block_and_chains()
	_crit_and_poison()
	_boundaries()
	super._run()


func _stats() -> PlayerStats:
	var stats := PlayerStats.new()
	stats.weapon_damage_min = 100
	stats.weapon_damage_max = 100
	stats.precision_duration_ms = -1
	return stats


func _precision() -> void:
	var quick := _skill("skill.quick_cut")
	var stab := _skill("skill.stab")
	var heavy := _skill("skill.heavy_slash")
	var stats := _stats()
	var result := CombatResolver.resolve([quick, quick, stab, heavy], stats, _monster(), 4000, 17, true)
	check(result.is_valid and result.cast_events.size() == 5, "Precision caps at one despite two Quick Cuts")
	check(result.cast_events[2].lifecycle_snapshot.precision_consumed == 1, "initial Stab consumes Precision")
	check(result.cast_events[3].origin_kind == "guaranteed_repeat" and result.cast_events[3].time_ms == result.cast_events[3].cast_start_ms, "one zero-time guarantee")
	check(result.cast_events[4].lifecycle_snapshot.precision_consumed == 0, "later Heavy Slash has no stored extra charge")
	check(stats.retrigger_chance == 0.0 and stats.crit_chance == 0.0, "guarantee never mutates stat sheet")
	var heavy_result := CombatResolver.resolve([quick, heavy], stats, _monster(), 2000, 17, true)
	check(heavy_result.cast_events.size() == 3 and heavy_result.cast_events[2].skill.id == heavy.id, "Heavy Slash receives Precision")
	var dodge_target := _monster()
	dodge_target.dodge_chance = 0.5
	var found_dodge := false
	for seed_value in range(1, 65):
		var attempt := CombatResolver.resolve([quick, stab, heavy], stats, dodge_target, 3000, seed_value, true)
		if attempt.cast_events.size() == 3 and not attempt.cast_events[0].was_dodged and attempt.cast_events[1].was_dodged:
			check(attempt.cast_events[1].lifecycle_snapshot.precision_consumed == 1 and attempt.cast_events[2].lifecycle_snapshot.precision_consumed == 0, "dodge loses consumed Precision without refund")
			found_dodge = true
			break
	check(found_dodge, "deterministic hit-then-dodge fixture found")
	var state_script = load("res://scripts/systems/combat_stat_state.gd")
	stats.retrigger_chance = 0.2
	stats.stat_derivations = [{"kind": "double_dip", "fraction": 1.0, "source_id": "test.double_dip"}]
	var state = state_script.new(stats)
	var derived: PlayerStats = state.snapshot()
	check(is_equal_approx(derived.crit_chance, 0.2), "Double Dip baseline")
	var derived_result := CombatResolver.resolve([quick, stab], derived, _monster(), 2000, 17, true)
	for event in derived_result.cast_events:
		check(is_equal_approx(event.stat_snapshot.get("effective_crit_chance", 0.2), 0.2), "Precision cannot raise Double Dip crit")


func _dance_skill() -> Skill:
	var dance := _skill("skill.dance_of_death")
	dance.category = Skill.Category.SELF_BUFF
	dance.effects.clear()
	dance.cooldown_ms = 20000
	return dance


func _dance_readiness() -> void:
	var stats := _stats()
	stats.dance_duration_ms = 5000
	stats.readiness_enabled = true
	var rotation: Array[Skill] = [_dance_skill(), _skill("skill.quick_cut"), _skill("skill.stab"), _skill("skill.parry_strike"), _skill("skill.parry_strike")]
	var result := CombatResolver.resolve(rotation, stats, _monster(), 5000, 31, true)
	check(result.is_valid and result.cast_events.size() == 8, "Dance and Precision emit one shared repeat")
	var stab = result.cast_events[3]
	check(stab.skill.id == "skill.stab" and stab.lifecycle_snapshot.precision_consumed == 1, "Precision spent despite active Dance")
	check(stab.lifecycle_snapshot.guaranteed_repeat_sources == PackedStringArray(["precision", "dance"]), "both guarantee sources recorded")
	check(result.cast_events[5].skill.id == "skill.parry_strike" and not result.cast_events[5].resource_unavailable, "prior connected repeat enables macro Parry")
	check(result.cast_events[6].origin_kind == "guaranteed_repeat" and result.cast_events[6].resource_unavailable, "Parry repeat is negated by missing Readiness")
	check(result.cast_events[6].physical_damage == 0 and result.cast_events[7].resource_unavailable, "negated repeat cannot grant Readiness")
	var off := CombatResolver.resolve(rotation, stats, _monster(), 5000, 31)
	var replay := CombatResolver.resolve(rotation, stats, _monster(), 5000, 31, true)
	check(result.trace.records == replay.trace.records, "same-seed guaranteed trace")
	check(result.rng_final_state == off.rng_final_state and result.total_damage == off.total_damage, "guarantee trace parity")
	check(result.effect_lifecycle.state.snapshot().is_empty(), "fight cleanup removes Dance and Precision")
	var cooldown := CombatResolver.resolve([_dance_skill(), _dance_skill()], stats, _monster(), 2200, 31, true)
	check(cooldown.cast_events.size() == 13 and cooldown.cast_events[1].cooldown_available_at_ms == cooldown.cast_events[0].time_ms + 20000, "Dance uses shared twenty-second cooldown with 100 ms attempts")


func _dodge_block_and_chains() -> void:
	var stats := _stats()
	stats.dance_duration_ms = 5000
	var target := _monster()
	target.dodge_chance = 1.0
	var dodged := CombatResolver.resolve([_dance_skill(), _skill("skill.stab")], stats, target, 2000, 3, true)
	check(dodged.cast_events.size() == 2 and dodged.cast_events[1].was_dodged, "100 percent guarantee cannot proc on dodge")
	var suppression := false
	for row in dodged.trace.records:
		if row.kind == "trigger_decision" and row.payload.reason == "guarantee_suppressed":
			suppression = row.payload.cause == "dodge"
	check(suppression, "dodge suppression diagnosed")
	target.dodge_chance = 0.0
	target.block = 100000
	var blocked := CombatResolver.resolve([_dance_skill(), _skill("skill.stab")], stats, target, 2000, 3)
	check(blocked.cast_events.size() == 3 and blocked.total_damage == 0, "fully blocked connected hit repeats")
	stats.dance_duration_ms = 0
	stats.retrigger_chance = 1.0
	var chain := CombatResolver.resolve([_skill("skill.quick_cut"), _skill("skill.stab")], stats, _monster(), 2000, 3, true)
	var guarantees := 0
	var randoms := 0
	for event in chain.cast_events:
		if event.origin_kind == "guaranteed_repeat":
			guarantees += 1
		if event.origin_kind == "random_repeat":
			randoms += 1
	check(chain.is_valid and guarantees == 1 and randoms == 31, "guarantee replaced initial roll; descendants use normal depth-bounded repeats")
	var opportunity := _trigger(_skill("skill.rending_thrust"), "skill.quick_cut")
	stats.retrigger_chance = 0.0
	stats.dance_duration_ms = 5000
	stats.triggered_skill_effects = [opportunity]
	var procs := CombatResolver.resolve([_dance_skill(), _skill("skill.quick_cut")], stats, _monster(), 2000, 3, true)
	check(procs.cast_events.size() == 5, "macro and guaranteed Quick Cut each proc Opportunity")
	check(procs.cast_events[2].skill.id == "skill.rending_thrust" and procs.cast_events[4].skill.id == "skill.rending_thrust", "Opportunity remains depth first")
	stats = _stats()
	stats.dance_duration_ms = 5000
	var reverse := CombatResolver.resolve([_skill("skill.quick_cut"), _dance_skill(), _skill("skill.stab")], stats, _monster(), 3000, 3, true)
	check(reverse.cast_events.size() == 4 and reverse.cast_events[2].lifecycle_snapshot.precision_consumed == 1, "Precision-before-Dance still gives one repeat and consumes Precision")


func _crit_and_poison() -> void:
	var stats := _stats()
	stats.side_step_enabled = true
	var target := _monster()
	target.crit_negation = 1.0
	var crit := CombatResolver.resolve([_skill("skill.parry_strike"), _skill("skill.stab")], stats, target, 2000, 3)
	check(crit.cast_events[0].is_crit and crit.cast_events[0].physical_damage == 0, "Side Step crit still respects full crit negation")
	check(not crit.cast_events[1].is_crit, "Side Step is skill-local")
	stats = _stats()
	stats.death_blade_enabled = true
	stats.death_blade_chance = 1.0
	stats.crit_chance = 1.0
	stats.elemental_proc_chance = 1.0
	var attack := _skill("test.poison")
	var poison := PoisonDamageEffect.new()
	poison.stacks_applied = 3
	attack.effects.append(poison)
	var result := CombatResolver.resolve([attack], stats, _monster(), 1000, 3, true)
	check(result.cast_events.size() == 3, "skill poison and crit poison are two applications, not four stack rolls")
	for index in [1, 2]:
		check(result.cast_events[index].skill.id == "skill.stab" and result.cast_events[index].poison_stacks_applied == 0, "Death Blade Stab suppresses crit poison and stops feedback")
	var stab := _skill("skill.stab")
	stab.effects.append(poison)
	var suppressed := CombatResolver.resolve([stab], stats, _monster(), 1000, 3, true)
	check(suppressed.cast_events.size() == 1 and suppressed.cast_events[0].poison_applications.is_empty(), "all Stab poison sources suppressed")
	poison.stacks_applied = 30
	var capped := CombatResolver.resolve([attack], stats, _monster(), 1000, 3, true)
	check(capped.cast_events.size() == 2 and capped.cast_events[0].poison_applications[1].applied == 0, "capped second application emits no Death Blade")
	stats.death_blade_chance = 0.0
	var disabled := CombatResolver.resolve([attack], stats, _monster(), 1000, 3, true)
	check(disabled.cast_events.size() == 1, "zero Death Blade chance emits no child")
	stats.death_blade_chance = 0.000001
	var failed_roll := CombatResolver.resolve([attack], stats, _monster(), 1000, 3, true)
	var saw_failed_roll := false
	for row in failed_roll.trace.records:
		if row.kind == "trigger_decision" and row.payload.reason == "roll_failed":
			saw_failed_roll = row.payload.application.applied > 0 and row.payload.roll > row.payload.chance
	check(failed_roll.cast_events.size() == 1 and saw_failed_roll, "seeded failed application roll is diagnosed")
	stats.death_blade_chance = 1.0
	attack.effects.remove_at(0)
	var pure := CombatResolver.resolve([attack], stats, _monster(), 1999, 3, true)
	check(pure.cast_events.size() == 2, "nonattack poison application can proc Stab; ticks cannot")
	var off := CombatResolver.resolve([attack], stats, _monster(), 1999, 3)
	var replay := CombatResolver.resolve([attack], stats, _monster(), 1999, 3, true)
	check(pure.trace.records == replay.trace.records and pure.rng_final_state == off.rng_final_state and pure.total_damage == off.total_damage, "Death Blade trace replay and RNG parity")
	stats = _stats()
	stats.death_blade_enabled = true
	stats.death_blade_chance = 1.0
	var poison_source := _skill("test.poison.source")
	poison_source.effects.append(poison)
	var mixed := CombatResolver.resolve([_skill("skill.quick_cut"), poison_source, _skill("skill.stab")], stats, _monster(), 3000, 3, true)
	check(mixed.cast_events.size() == 5, "Death Blade proc spends existing Precision for one repeat")
	check(mixed.cast_events[2].origin_kind == "proc" and mixed.cast_events[2].lifecycle_snapshot.precision_consumed == 1, "proc Stab consumes Precision")
	check(mixed.cast_events[3].origin_kind == "guaranteed_repeat" and mixed.cast_events[4].lifecycle_snapshot.precision_consumed == 0, "proc consumes charge before next macro Stab")
	# User's exact chain: Quick Cut -> crit poison -> Death Blade Stab -> repeat.
	stats.crit_chance = 1.0
	stats.elemental_proc_chance = 1.0
	var exact := CombatResolver.resolve([_skill("skill.quick_cut"), _skill("skill.stab")], stats, _monster(), 2000, 3, true)
	check(exact.cast_events.size() == 4, "same-hit Precision enables Death Blade repeat without a later duplicate grant")
	check(exact.cast_events[1].origin_kind == "proc" and exact.cast_events[1].lifecycle_snapshot.precision_consumed == 1, "same-hit proc sees freshly granted Precision")
	check(exact.cast_events[2].origin_kind == "guaranteed_repeat" and exact.cast_events[2].parent_cast_id == exact.cast_events[1].cast_id, "guaranteed Stab child belongs to Death Blade cast")
	check(exact.cast_events[2].lifecycle_snapshot.precision_consumed == 0 and exact.cast_events[3].lifecycle_snapshot.precision_consumed == 0, "consumed guarantee is not inherited or regranted at Quick Cut end")
	var grant_sequence := 0
	var proc_start_sequence := 0
	var grant_count := 0
	for row in exact.trace.records:
		if row.kind == "effect_lifecycle" and row.source_id == "talent.bladedancer.precision_attacks" and row.lifecycle_reason == "granted":
			grant_sequence = row.sequence
			grant_count += 1
		if row.kind == "cast_start" and row.cast_id == exact.cast_events[1].cast_id:
			proc_start_sequence = row.sequence
	check(grant_count == 1 and grant_sequence < proc_start_sequence, "Precision grant precedes Death Blade child exactly once")
	var exact_off := CombatResolver.resolve([_skill("skill.quick_cut"), _skill("skill.stab")], stats, _monster(), 2000, 3)
	var exact_replay := CombatResolver.resolve([_skill("skill.quick_cut"), _skill("skill.stab")], stats, _monster(), 2000, 3, true)
	check(exact.trace.records == exact_replay.trace.records and exact.rng_final_state == exact_off.rng_final_state and exact.total_damage == exact_off.total_damage, "same-hit repeat trace and RNG parity")
	var multi := _skill("skill.quick_cut")
	var extra_poison := PoisonDamageEffect.new()
	extra_poison.stacks_applied = 1
	multi.effects.append(extra_poison)
	var two_applications := CombatResolver.resolve([multi], stats, _monster(), 1000, 3, true)
	check(two_applications.cast_events.size() == 4, "two same-hit poison applications share one Precision charge")
	check(two_applications.cast_events[1].lifecycle_snapshot.precision_consumed == 1 and two_applications.cast_events[2].origin_kind == "guaranteed_repeat" and two_applications.cast_events[3].lifecycle_snapshot.precision_consumed == 0, "first Death Blade proc spends Precision; second uses ordinary repeat chance")


func _boundaries() -> void:
	var stats := _stats()
	stats.dance_duration_ms = 5000
	var long_attack := _skill("skill.stab")
	long_attack.base_execution_ms = 5000
	var result := CombatResolver.resolve([_dance_skill(), long_attack, _skill("skill.heavy_slash")], stats, _monster(), 7000, 3, true)
	check(result.cast_events.size() == 4, "start-active Dance guarantees long cast, expires before next macro start")
	check(result.cast_events[2].origin_kind == "guaranteed_repeat" and result.cast_events[3].origin_kind == "macro", "expiry cannot leak guarantee to next cast")
	var invalid := _stats()
	invalid.precision_duration_ms = -2
	check(not CombatResolver.resolve([_skill("skill.stab")], invalid, _monster(), 1000).is_valid, "invalid lifecycle definition fails explicitly")
	var filtered := _trigger(_skill("test.leaf"), "test.unmatched")
	for i in CombatResolver.MAX_TRIGGER_CANDIDATES_PER_ROOT:
		stats.triggered_skill_effects.append(filtered)
	var limited := CombatResolver.resolve([_dance_skill(), _skill("skill.stab")], stats, _monster(), 2000, 3, true)
	check(not limited.is_valid and limited.failure.evaluated == 1024, "guarantee obeys same root candidate budget")
	check(limited.effect_lifecycle.state.snapshot().is_empty(), "budget failure clears repeat buffs")
