extends "res://tests/p6_status_interactions_test.gd"
const Contracts = preload("res://scripts/systems/p6_status_skill_contracts.gd")
const SelfBuffs = preload("res://scripts/systems/combat_self_buffs.gd")
const ForcedTick = preload("res://scripts/resources/forced_poison_tick_effect.gd")
const Theft = preload("res://scripts/resources/steal_gold_effect.gd")
const Scheduler = preload("res://scripts/systems/combat_macro_scheduler.gd")

func _initialize() -> void:
	super._initialize()

func _run() -> void:
	_contracts()
	_instances()
	_live_ticks()
	_beguiling()
	_bribery()
	_integration_boundaries()
	super._run()

func _contracts() -> void:
	var gear: GearItem = load("res://data/gear/crude_dagger.tres").duplicate(true)
	var extra := StatModifier.new()
	extra.stat_id = StatCatalog.INCREASED_ALL_STACKS
	extra.value = 1.0
	gear.affixes.append(extra)
	var base := BuildResolver.resolve_stats(load("res://data/classes/rogue.tres"), [], [], [gear])
	var stats: PlayerStats = Contracts.apply_passives(base, 3, true, 3)
	check(stats.bonus_poison_stacks == 10 and stats.bonus_potency_stacks == 10 and stats.bonus_penetration_stacks == 10, "gear plus Death Touch uses the same extra-stack fields")
	check(base.bonus_poison_stacks == 1 and stats.poison_stack_cap == 80 and stats.bribery_base_stacks == 6, "passives leave source build unchanged")
	stats.attack_speed = 10.0
	for name in ["master_of_poisons", "virulent_poison", "beguiling_presence"]:
		var skill: Skill = Contracts.skill(name)
		check(Scheduler.plan(skill, stats, 0.0, 0, 2000, false).execution_ms == 500, "self buff ignores IAS: " + name)
	var custom := _utility("test.slow_buff", Skill.Category.SELF_BUFF)
	custom.base_execution_ms = 1800
	check(Scheduler.plan(custom, stats, 0.0, 0, 2000, false).execution_ms == 1800, "category rule applies beyond fixed-minimum descriptors")
	var vile: Skill = Contracts.skill("poison_vile")
	check(vile.base_execution_ms == 1800 and vile.min_execution_ms == 500 and vile.cooldown_ms == 0, "Vile approved descriptor")
	stats = PlayerStats.new()
	stats.bonus_poison_stacks = 2
	stats.special_effects = {"double_applied_stacks": true}
	var capped := CombatResolver.resolve([vile], stats, _monster(), 1800, 1)
	check(capped.cast_events[0].poison_applications[0].requested == 44 and capped.cast_events[0].status_snapshot.poison == 20, "Vile bonuses then doubling then cap")
	stats.poison_stack_cap = 80
	check(CombatResolver.resolve([vile], stats, _monster(), 1800, 1).cast_events[0].status_snapshot.poison == 44, "Umbral cap allows full Vile grant")
	stats.attack_speed = 10.0
	check(CombatResolver.resolve([vile], stats, _monster(), 1000, 1).cast_events.size() == 2, "Vile scales to minimum and has no cooldown")

func _instances() -> void:
	var buffs := SelfBuffs.new()
	buffs.grant("virulent_poison", 0, {})
	buffs.spend_poison_charges(1)
	buffs.spend_poison_charges(2)
	buffs.grant("virulent_poison", 3, {})
	check(buffs.instances[0].charges == 3 and buffs.instances[1].charges == 5, "recast creates five independent charges")
	for i in 3:
		check(buffs.values().poison_multiplier == 4.0, "overlap multiplies twice")
		buffs.spend_poison_charges(4 + i)
	check(buffs.instances.size() == 1 and buffs.instances[0].charges == 2 and buffs.values().poison_multiplier == 2.0, "first instance exhausted independently")
	buffs.grant("beguiling_presence", 10, {}, 3.0)
	buffs.grant("beguiling_presence", 20, {}, 5.0)
	check(buffs.values().elemental_base == 8.0, "independent elemental bonuses sum")
	buffs.advance(10010)
	check(buffs.values().elemental_base == 5.0, "each timed instance expires independently at deadline")
	buffs.advance(10020)
	check(buffs.values().elemental_base == 0.0, "last instance expires")

func _live_ticks() -> void:
	var stats := PlayerStats.new()
	stats.poison_damage_per_tick = 10.0
	stats.death_pact_rank = 1
	stats.bonus_poison_stacks = 20
	stats.special_effects = {"double_applied_stacks": true}
	var target := _monster()
	target.poison_resistance = 0.5
	var fuel: Skill = Contracts.skill("poison_vile")
	fuel.base_execution_ms = 500
	var master: Skill = Contracts.skill("master_of_poisons")
	var virulent: Skill = Contracts.skill("virulent_poison")
	var forced := _utility("test.forced")
	forced.base_execution_ms = 500
	forced.effects = [ForcedTick.new()]
	var result := CombatResolver.resolve([fuel, master, virulent, forced], stats, target, 2500, 9, true)
	check(result.tick_events[0].damage == 5.0, "tick at Master activation resolves before grant")
	check(result.tick_events[1].damage == 20.0 and result.tick_events[2].damage == 20.0, "natural and forced ticks both use Master and Virulent")
	check(result.tick_events[2].stacks_consumed == 1 and result.tick_events[2].stacks_remaining == result.tick_events[1].stacks_remaining - 1, "T9 forced tick depletes Poison without keyword Consume")
	var spent := 0
	for row in result.trace.records:
		if row.kind == "effect_lifecycle" and row.lifecycle_reason == "charge_spent":
			spent += 1
	check(spent == 2, "each actual tick spends one charge, unaffected by extra/doubling")
	check(result.self_buffs.instances.is_empty(), "fight cleanup removes all instances")
	var replay := CombatResolver.resolve([fuel, master, virulent, forced], stats, target, 2500, 9, true)
	var off := CombatResolver.resolve([fuel, master, virulent, forced], stats, target, 2500, 9)
	check(replay.trace.records == result.trace.records and off.rng_final_state == result.rng_final_state and off.total_damage == result.total_damage, "new effects deterministic and trace neutral")
	var direct := CombatResolver.CombatResult.new()
	direct.self_buffs.grant("master_of_poisons", 0, {})
	direct.self_buffs.grant("virulent_poison", 0, {})
	CombatResolver._resolve_poison_tick(direct, 4999, 1, stats, 0, 0.5, target, 1000)
	CombatResolver._resolve_poison_tick(direct, 5000, 1, stats, 0, 0.5, target, 1000)
	check(direct.tick_events[0].damage == 20.0 and direct.tick_events[1].damage == 10.0, "Master exact expiry restores live resistance")
	var charges: int = direct.self_buffs.instances[0].charges
	CombatResolver._resolve_poison_tick(direct, 6000, 0, stats, 0, 0.5, target, 1000)
	check(direct.self_buffs.instances[0].charges == charges and direct.tick_events[2].damage == 0.0, "empty ticks never spend charges")

func _beguiling() -> void:
	var decay := _utility("test.decay")
	decay.base_execution_ms = 500
	decay.effects = [PoisonResistanceReductionEffect.new()]
	var stats := PlayerStats.new()
	stats.bonus_decay_stacks = 2
	stats.elemental_damage_multiplier = 2.0
	stats.poison_damage_per_tick = 10.0
	stats.death_pact_rank = 1
	var target := _monster()
	target.poison_resistance = 0.5
	var fuel: Skill = Contracts.skill("poison_vile")
	fuel.base_execution_ms = 500
	var beguiling: Skill = Contracts.skill("beguiling_presence")
	var result := CombatResolver.resolve([decay, beguiling, fuel], stats, target, 2000, 4, true)
	check(result.cast_events[1].status_snapshot.decay == 0 and result.cast_events[1].status_snapshot.poison_resistance == 0.5, "Beguiling consumes actual Decay and restores resistance")
	check(result.cast_events[1].status_snapshot.defenses.block == -3.0, "Beguiling consumption triggers exact Death Pact conversion")
	# (10 + (3 Beguiling + 0.3 negative absorb bonus) * 2) * 0.5 = 8.3, rounded to 8.
	check(result.tick_events[1].damage == 8.0, "Beguiling base bonus scales once and combines with negative absorb")
	var zero := CombatResolver.resolve([beguiling], stats, target, 500, 4, true)
	for row in zero.trace.records:
		check(not (row.kind == "effect_lifecycle" and row.lifecycle_reason == "granted"), "zero fuel grants no bonus or Death Pact")

func _bribery() -> void:
	var stats: PlayerStats = Contracts.apply_passives(PlayerStats.new(), 0, false, 2)
	stats.bonus_shred_stacks = 2
	stats.special_effects = {"double_applied_stacks": true}
	var pocket := _utility("skill.pick_pocket")
	var theft := Theft.new()
	theft.amount = 100
	pocket.effects = [theft]
	var target := _monster()
	target.dodge_chance = 1.0
	target.cleanse_threshold = 1
	var result := CombatResolver.resolve([pocket], stats, target, 1000, 4)
	check(result.cast_events[0].shred_stacks_applied == 12 and result.gold_stolen == 100, "Pick Pocket applies one Bribery grant regardless of gold amount")
	check(not result.cast_events[0].cleanse_triggered, "theft Debuff keeps category rules")
	theft.amount = 0
	check(CombatResolver.resolve([pocket], stats, target, 1000, 4).cast_events[0].shred_stacks_applied == 0, "zero theft grants no Bribery")
	var steal := _skill("test.steal")
	var critical := StealGoldOnCritEffect.new()
	critical.amount = 1
	steal.effects.append(critical)
	target.dodge_chance = 0.0
	target.cleanse_threshold = 0
	stats.crit_chance = 0.0
	check(CombatResolver.resolve([steal], stats, target, 1000, 4).cast_events[0].shred_stacks_applied == 0, "noncritical Steal grants no Bribery")
	stats.crit_chance = 1.0
	check(CombatResolver.resolve([steal], stats, target, 1000, 4).cast_events[0].shred_stacks_applied == 12, "critical successful Steal grants Bribery")

func _integration_boundaries() -> void:
	var stats := PlayerStats.new()
	stats.poison_damage_per_tick = 10.0
	stats.poison_tick_interval_multiplier = 3.0
	var fuel: Skill = Contracts.skill("poison_vile")
	fuel.base_execution_ms = 500
	var virulent: Skill = Contracts.skill("virulent_poison")
	var result := CombatResolver.resolve([fuel, virulent], stats, _monster(), 16000, 4, true)
	var overlap := false
	for row in result.trace.records:
		if row.kind == "poison_tick" and float(row.payload.buffs.poison_multiplier) >= 4.0:
			overlap = true
	check(overlap, "normal cooldown recasts overlap when tick cadence is slower")
	var master: Skill = Contracts.skill("master_of_poisons")
	var hit := _skill("test.converted")
	var target := _monster()
	target.poison_resistance = 0.75
	stats.special_effects = {"damage_conversion": {"magical": true}}
	var converted := CombatResolver.resolve([master, hit], stats, target, 1500, 4)
	check(converted.cast_events[1].physical_damage == 10.0 and converted.cast_events[1].status_snapshot.poison_resistance == 0.75, "Master applies to converted elemental hit without erasing underlying resistance")
	var attack: Skill = Contracts.with_forced_poison_tick(hit)
	target.dodge_chance = 1.0
	var dodged := CombatResolver.resolve([fuel, attack], stats, target, 1500, 4)
	check(dodged.tick_events.is_empty(), "dodged attack cannot cause a forced tick")
	var trace = Trace.new()
	trace.enabled = true
	var buffs := SelfBuffs.new(trace)
	buffs.grant("virulent_poison", 0, {"source_id": "skill.virulent_poison"})
	var id: String = trace.records[0].effect_instance_id
	buffs.spend_poison_charges(1)
	check(not id.is_empty() and trace.records[0].payload.after.charges == 5, "instance trace identity and immutable grant snapshot")
	buffs.reset(2, "invalid_simulation")
	check(buffs.instances.is_empty() and trace.records.back().lifecycle_reason == "invalid_simulation", "invalid cleanup clears instances")
	var dance = preload("res://scripts/systems/bladedancer_effect_lifecycle.gd").new(0, false, null, null, {"dance": 5000})
	dance.activate_dance(0)
	dance.activate_dance(1000)
	check(dance.state.snapshot().size() == 2, "Dance also retains independent self-buff instances")
	var cast: Dictionary = dance.begin_cast("skill.stab", 500, 500, 5000, {"origin_kind": "macro"}, true)
	check(cast.guaranteed_repeat_sources.size() == 1, "overlapping Dance preserves one approved guarantee")
	check(dance.state.snapshot().size() == 1, "first Dance instance expires independently")
