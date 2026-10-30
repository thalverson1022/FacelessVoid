extends "res://tests/p6_combat_ordering_test.gd"

const Defense = preload("res://scripts/systems/combat_defense_debuffs.gd")
const Apply = preload("res://scripts/resources/apply_defense_debuff_effect.gd")
const Consume = preload("res://scripts/resources/consume_status_effect.gd")

func _initialize() -> void:
	super._initialize()

func _run() -> void:
	_categories()
	_lifetimes()
	_damage_order()
	_consumption()
	_cleanse_and_mirroring()
	_validation()
	super._run()

func _utility(id: String, category: Skill.Category = Skill.Category.DEBUFF) -> Skill:
	var skill := _skill(id)
	skill.category = category
	skill.effects.clear()
	return skill

func _apply(status: String, count: int) -> SkillEffect:
	var effect := Apply.new()
	effect.status = status
	effect.base_stacks = count
	return effect

func _consume(status: String, amount: int, conversion: int = 0) -> SkillEffect:
	var effect := Consume.new()
	effect.status = status
	effect.amount = amount
	effect.poison_per_consumed = conversion
	return effect

func _poison(count: int) -> SkillEffect:
	var effect := PoisonDamageEffect.new()
	effect.stacks_applied = count
	return effect

func _categories() -> void:
	var attack := _skill("test.attack")
	var powder := _utility("skill.blinding_powder")
	var buff := _utility("test.buff", Skill.Category.SELF_BUFF)
	var target := _monster()
	target.cleanse_threshold = 10
	target.interrupt_skip_count = 1
	var result := CombatResolver.resolve([attack, attack, powder, buff, attack], PlayerStats.new(), target, 5000, 3, true)
	check(result.cast_events[4].was_interrupted, "utilities preserve the two-attack interrupt streak")
	check(result.cast_events[2].interrupt_repeat_count_after == 2 and result.cast_events[3].interrupt_repeat_count_after == 2, "utilities neither advance nor reset interruption")
	check(result.cast_events[1].cleanse_counter == 2 and not result.cast_events[2].cleanse_triggered, "debuff does not advance cleanse")
	target.dodge_chance = 1.0
	target.cleanse_threshold = 1
	powder.effects.append(_poison(3))
	for category in [Skill.Category.DEBUFF, Skill.Category.SELF_BUFF]:
		powder.category = category
		var utility := CombatResolver.resolve([powder], PlayerStats.new(), target, 1000, 3, true)
		check(not utility.cast_events[0].was_dodged and not utility.cast_events[0].cleanse_triggered and utility.cast_events[0].poison_stacks_applied == 3, "utilities apply without a hit or cleanse increment")
	# Approved Blinding Powder fixture: one second base, half-second minimum, no CD.
	powder.category = Skill.Category.DEBUFF
	powder.effects.clear()
	var potency := Apply.new()
	potency.use_assassin_points = true
	powder.effects.append(potency)
	var stats := PlayerStats.new()
	stats.assassin_tree_points = 7
	stats.attack_speed = 100.0
	var fast := CombatResolver.resolve([powder], stats, target, 1000, 3, true)
	check(fast.cast_events.size() == 2 and fast.cast_events[0].time_ms == 500 and fast.total_damage == 0, "Blinding Powder obeys minimum and has no cooldown/damage")
	check(fast.cast_events[1].status_snapshot.defenses.absorb == -14.0, "Assassin points determine each Powder grant")

func _lifetimes() -> void:
	for rank in range(4):
		var stats := PlayerStats.new()
		stats.death_pact_rank = rank
		stats.finders_keepers_rank = 1
		stats.bonus_potency_stacks = 2
		stats.special_effects = {"double_applied_stacks": true}
		var trace := Trace.new()
		trace.enabled = true
		var defense := Defense.new(stats, 20.0, 10.0, trace)
		check(defense.grant("potency", 3, stats, 0, {}).error == "", "normal debuff application valid")
		check(defense.values().absorb == 0.0, "normal application adds bonuses then doubles once")
		check(defense.grant("penetration", 15, stats, 0, {}, true).error == "", "Death Pact grant valid")
		check(defense.values().block == -5.0, "Finders first then exact Death Pact count")
		var expiry := 3000 + 1000 * rank
		check(defense.state.advance(expiry - 1) == "" and defense.values().block == -5.0, "debuff survives before expiry")
		check(defense.state.advance(expiry) == "" and defense.values().block == 10.0, "exact expiry restores baseline")
		check(defense.grant("potency", 200, stats, expiry, {}).error == "", "cap grant")
		check(defense.state.snapshot("potency").stacks == 50, "50-stack cap")
		check(defense.grant("potency", 1, stats, expiry + 1, {}).error == "", "application at cap")
		check(defense.state.snapshot("potency").expires_at_ms == 2 * expiry + 1, "cap refreshes whole timer")
		check(defense.cleanse(expiry + 1, {}) == "" and defense.state.snapshot().is_empty(), "cleanse removes timed debuffs")
		check(trace.records.back().lifecycle_reason == "cleansed", "cleanse never records keyword consumption")
		check(trace.records.back().payload.before.owner_id == "enemy", "enemy ownership diagnosed")

func _damage_order() -> void:
	var stats := PlayerStats.new()
	stats.physical_damage_multiplier = 2.0
	stats.finders_keepers_rank = 1
	var target := _monster()
	target.block = 20.0
	target.absorb = 4.0
	var debuff := _utility("test.pen")
	debuff.effects = [_apply("penetration", 15)]
	var hit := _skill("test.hit") # 10 base, not weapon-scaled.
	var result := CombatResolver.resolve([debuff, hit], stats, target, 2000, 3, true)
	check(result.cast_events[1].physical_damage == 21.0, "(10 base +0.5 from negative block) times 2")
	stats.special_effects = {"damage_conversion": {"magical": true}}
	var converted := CombatResolver.resolve([debuff, hit], stats, target, 2000, 3, true)
	check(converted.cast_events[1].physical_damage == 17.0, "original physical base bonus then conversion then positive absorb")
	stats.special_effects = {"enemy_denial": {"block": true}}
	var denied := CombatResolver.resolve([debuff, hit], stats, target, 2000, 3)
	check(denied.cast_events[1].physical_damage == 23.0, "gear denial zeroes baseline, preserves negative-block bonus")
	stats.finders_keepers_rank = 2
	var redundant := CombatResolver.resolve([debuff, hit], stats, target, 2000, 3)
	check(redundant.total_damage == denied.total_damage, "Finders rank two redundant with gear")
	stats = PlayerStats.new()
	stats.poison_damage_per_tick = 40.0
	stats.elemental_damage_multiplier = 2.0
	stats.death_pact_rank = 3
	stats.special_effects = {"enemy_denial": {"absorb": true}}
	var fuel := _utility("test.fuel")
	fuel.effects = [_poison(5)]
	var pot := _utility("test.pot")
	pot.effects = [_apply("potency", 10)]
	var wait := _utility("test.wait")
	wait.base_execution_ms = 3000
	var poison := CombatResolver.resolve([fuel, pot, wait], stats, target, 4000, 3, true)
	check(poison.tick_events[2].damage == 42.0, "negative absorb base bonus is scaled for Poison")
	stats.special_effects["damage_conversion"] = {"physical": true}
	var converted_poison := CombatResolver.resolve([fuel, pot, wait], stats, target, 4000, 3, true)
	check(converted_poison.tick_events[2].damage == 22.0, "original elemental bonus survives conversion then block removes 20")
	check(poison.defense_debuffs.state.snapshot().is_empty(), "fight cleanup clears enemy debuffs")
	var off := CombatResolver.resolve([fuel, pot, wait], stats, target, 4000, 3)
	var replay := CombatResolver.resolve([fuel, pot, wait], stats, target, 4000, 3, true)
	check(converted_poison.trace.records == replay.trace.records and off.rng_final_state == replay.rng_final_state and off.total_damage == replay.total_damage, "damage conversion trace and RNG parity")

func _consumption() -> void:
	var stats := PlayerStats.new()
	stats.death_pact_rank = 1
	stats.bonus_poison_stacks = 2
	stats.bonus_potency_stacks = 20
	stats.bonus_penetration_stacks = 20
	var target := _monster()
	target.poison_resistance = 0.5
	var apply_decay := _utility("test.decay")
	for i in 7:
		apply_decay.effects.append(PoisonResistanceReductionEffect.new())
	var conversion := _utility("test.conversion")
	conversion.effects = [_consume("decay", 5, 1)]
	var result := CombatResolver.resolve([apply_decay, conversion], stats, target, 2000, 3, true)
	var after: Dictionary = result.cast_events[1].status_snapshot
	check(after.decay == 2 and is_equal_approx(after.poison_resistance, 0.32), "partial Decay removal restores base-relative resistance")
	check(after.poison == 7 and after.defenses.block == -5.0 and after.defenses.absorb == -5.0, "conversion bonuses once, Death Pact uses actual consumed count")
	check(is_equal_approx(CombatRecap.summarize(result, target).final_poison_resistance, 0.32), "recap reflects resistance restoration")
	stats.special_effects = {"double_applied_stacks": true}
	var doubled := CombatResolver.resolve([apply_decay, conversion], stats, target, 2000, 3)
	check(doubled.cast_events[1].status_snapshot.poison == 14 and doubled.cast_events[1].status_snapshot.defenses.block == -5.0, "conversion doubles but Death Pact never does")
	var empty := CombatResolver.resolve([conversion], stats, target, 1000, 3)
	check(empty.cast_events[0].poison_applications.is_empty() and empty.cast_events[0].status_snapshot.defenses.block == 0.0, "zero fuel grants neither Poison nor Death Pact")
	stats.special_effects.clear()
	stats.bonus_poison_stacks = 0
	var fill := _utility("test.fill")
	fill.effects = [_poison(20)]
	var consume_poison := _utility("test.consume_poison")
	consume_poison.effects = [_consume("poison", -1)]
	var consumed_poison := CombatResolver.resolve([fill, consume_poison], stats, target, 2000, 3, true)
	var poison_after: Dictionary = consumed_poison.cast_events[1].status_snapshot
	check(poison_after.poison == 0 and poison_after.defenses.block == -19.0 and poison_after.defenses.absorb == -19.0, "explicit Consume uses remaining Poison after natural depletion")
	var capped := CombatResolver.resolve([apply_decay, fill, conversion], stats, target, 3000, 3, true)
	var application: Dictionary = capped.cast_events[2].poison_applications[0]
	check(application.applied == 1 and application.overflow == 4 and capped.active_decay_stacks == 2, "overflow does not refund consumed Decay")
	stats.death_blade_enabled = true
	stats.death_blade_chance = 1.0
	var triggered := CombatResolver.resolve([apply_decay, conversion], stats, target, 2000, 3, true)
	check(triggered.cast_events.size() == 3 and triggered.cast_events[2].skill.id == "skill.stab", "one conversion application supplies one Death Blade candidate")
	var tick_only := CombatResolver.resolve([fill], stats, target, 2999, 3, true)
	for event in tick_only.cast_events:
		check(event.status_snapshot.defenses.block == 0.0, "natural ticks never grant Death Pact")
	for row in tick_only.trace.records:
		if row.kind == "poison_tick":
			check(not row.payload.keyword_consume, "tick depletion explicitly not Consume")

func _cleanse_and_mirroring() -> void:
	var stats := PlayerStats.new()
	stats.shred_cleanse_immune = true
	stats.independent_decay_shred = true
	stats.bonus_decay_stacks = 4
	stats.bonus_shred_stacks = 2
	stats.special_effects = {"decay_applies_shred": true}
	var debuff := _utility("test.all")
	debuff.effects = [PoisonResistanceReductionEffect.new(), _poison(4), _apply("potency", 7), _apply("penetration", 9)]
	var target := _monster()
	target.armor = 100
	target.poison_resistance = 0.5
	target.cleanse_threshold = 1
	var result := CombatResolver.resolve([debuff, _skill("test.cleanse")], stats, target, 2000, 3, true)
	check(result.cast_events[0].decay_stacks_applied == 5 and result.cast_events[0].shred_stacks_applied == 3, "independent Decay/Shred bases get their own bonuses")
	var after: Dictionary = result.cast_events[1].status_snapshot
	check(after.shred == 3 and after.armor == 70 and after.decay == 0 and after.poison == 0, "Virulent Corruption protects Shred only")
	check(after.defenses.block == 0.0 and after.defenses.absorb == 0.0, "cleanse removes both timed debuffs")
	check(CombatRecap.summarize(result, target).final_armor == 70, "recap preserves immune Shred")
	for row in result.trace.records:
		if row.kind == "effect_lifecycle" and row.lifecycle_reason == "cleansed":
			check(not row.payload.has("consumed"), "cleanse not consumption")

func _validation() -> void:
	var skill := _utility("test.invalid")
	skill.effects = [_consume("invalid", 5)]
	check(not CombatResolver.resolve([skill], PlayerStats.new(), _monster(), 1000).is_valid, "invalid Consume status rejected")
	var stats := PlayerStats.new()
	stats.death_pact_rank = 4
	check(not CombatResolver.resolve([_skill("test.attack")], stats, _monster(), 1000).is_valid, "invalid Pact rank rejected")
