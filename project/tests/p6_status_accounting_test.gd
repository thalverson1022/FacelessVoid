extends "res://tests/p6_combat_ordering_test.gd"

func _initialize() -> void:
	super._initialize()


func _run() -> void:
	var slash: Skill = load("res://data/skills/rending_slash.tres")
	var stats := PlayerStats.new()
	stats.weapon_damage_min = 100
	stats.weapon_damage_max = 100
	stats.bonus_shred_stacks = 2
	stats.special_effects = {"double_applied_stacks": true}
	var target := _monster()
	target.armor = 100
	var result := CombatResolver.resolve([slash], stats, target, 2800, 3, true)
	check(result.cast_events.size() == 2, "two Rending Slash casts")
	var first = result.cast_events[0]
	var second = result.cast_events[1]
	check(first.shred_stacks_applied == 8, "two base plus two bonus doubled exactly once")
	check(second.physical_damage > first.physical_damage, "later hit benefits from earlier Shred")
	var clean_hit: Skill = slash.duplicate(true)
	for i in range(clean_hit.effects.size() - 1, -1, -1):
		if clean_hit.effects[i] is ArmorReductionEffect:
			clean_hit.effects.remove_at(i)
	var baseline := CombatResolver.resolve([clean_hit], stats, target, 1400, 3)
	check(first.physical_damage == baseline.cast_events[0].physical_damage, "new Shred does not improve its own hit")
	var transaction: Dictionary = first.status_transactions[0]
	check(transaction.before == 0 and transaction.after == 8 and transaction.requested == 8 and transaction.overflow == 0, "exact Shred transaction")
	target.block = 100000
	var blocked := CombatResolver.resolve([slash], stats, target, 1400, 3)
	check(blocked.cast_events[0].physical_damage == 0 and blocked.cast_events[0].shred_stacks_applied == 8, "full block preserves Shred")
	target.dodge_chance = 1.0
	var dodged := CombatResolver.resolve([slash], stats, target, 1400, 3)
	check(dodged.cast_events[0].status_transactions.is_empty(), "dodge produces no status application")
	target = _monster()
	stats.bonus_shred_stacks = 300
	var capped := CombatResolver.resolve([slash], stats, target, 2800, 3, true)
	var cap_first: Dictionary = capped.cast_events[0].status_transactions[0]
	var cap_second: Dictionary = capped.cast_events[1].status_transactions[0]
	check(cap_first.requested == 604 and cap_first.applied == 500 and cap_first.overflow == 104, "cap separates requested actual overflow")
	check(cap_second.before == 500 and cap_second.after == 500 and cap_second.applied == 0 and cap_second.overflow == 604, "application at cap conserves quantity")
	stats = PlayerStats.new()
	stats.special_effects = {"decay_applies_shred": true, "double_applied_stacks": true}
	stats.bonus_decay_stacks = 2
	stats.bonus_shred_stacks = 10
	var decay := _skill("test.decay")
	decay.effects.append(PoisonResistanceReductionEffect.new())
	var poison := PoisonDamageEffect.new()
	poison.stacks_applied = 30
	decay.effects.append(poison)
	var zero := CombatResolver.resolve([decay], stats, target, 1000, 3, true)
	check(zero.active_decay_stacks == 6, "Decay quantity survives zero base resistance")
	check(zero.cast_events[0].shred_stacks_applied == 6, "mirrored Decay does not receive Shred bonuses or double again")
	var found_poison := false
	for row in zero.cast_events[0].status_transactions:
		if row.status == "poison":
			found_poison = row.requested == 60 and row.applied == 20 and row.overflow == 40
	check(found_poison, "poison cap diagnostics report actual application")
	target.cleanse_threshold = 2
	var cleansed := CombatResolver.resolve([decay], stats, target, 2000, 3, true)
	check(cleansed.active_decay_stacks == 0, "cleanse resets explicit Decay")
	var found_removal := false
	for row in cleansed.cast_events[1].status_transactions:
		if row.status == "decay" and row.reason == "cleansed":
			found_removal = row.before == 12 and row.after == 0 and row.removed == 12 and row.consumed == 0
	check(found_removal, "cleanse removal is not consumption")
	stats.special_effects["enemy_denial"] = {"cleanse": true}
	var immune := CombatResolver.resolve([decay], stats, target, 2000, 3, true)
	check(immune.active_decay_stacks == 12, "inherited full cleanse denial preserves Decay")
	var off := CombatResolver.resolve([decay], stats, target, 2000, 3)
	var again := CombatResolver.resolve([decay], stats, target, 2000, 3, true)
	check(immune.trace.records == again.trace.records, "same-seed status trace and fresh-fight equality")
	check(off.active_decay_stacks == immune.active_decay_stacks and off.total_damage == immune.total_damage and off.rng_final_state == immune.rng_final_state, "status observation leaves RNG and outcomes unchanged")
	for cast in immune.cast_events:
		for row in cast.status_transactions:
			check(row.before + row.applied - row.removed == row.after and row.requested == row.applied + row.overflow, "status conservation")
	super._run()
