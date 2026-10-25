extends "res://tests/p6_macro_scheduler_test.gd"
const Defenses = preload("res://scripts/systems/combat_defense_debuffs.gd")
const ForcedTick = preload("res://scripts/resources/forced_poison_tick_effect.gd")

func _initialize() -> void:
	_proc_trials()
	_context_and_local_crit()
	_ordering()
	print("T3 combat crit: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)

func _proc_trials() -> void:
	var skill := make_skill("test.critical", 100)
	skill.effects.append(skill.effects[0].duplicate(true))
	var player := PlayerStats.new()
	player.crit_chance = 1.0
	var target := Monster.new()
	target.block = 10000
	var baseline := CombatResolver.resolve([skill], player, target, 100, 42, true)
	var zero := CombatResolver.resolve([skill], player, target, 100, 42, false)
	check(zero.rng_final_state == baseline.rng_final_state, "zero new chances preserve baseline draws and trace parity")
	player.crit_applies_penetration = 1.0
	player.crit_applies_potency = 1.0
	player.bonus_penetration_stacks = 2
	player.bonus_potency_stacks = 3
	player.special_effects = {"double_applied_stacks": true}
	var result := CombatResolver.resolve([skill], player, target, 100, 42, true)
	check(result.is_valid and result.cast_events[0].physical_damage == 0 and result.cast_events[0].is_crit, "connected fully blocked rolled crit qualifies")
	var rng := RandomNumberGenerator.new()
	rng.state = baseline.rng_final_state
	rng.randf()
	rng.randf()
	check(result.rng_final_state == rng.state, "multiple damage effects make exactly one trial per stat, including chance one")
	var trials := []
	var counts := {}
	for record in result.trace.records:
		if record.kind == "crit_defense_proc":
			trials.append(record.payload.status)
		if record.kind == "effect_lifecycle" and record.lifecycle_reason == "granted":
			counts[record.payload.effect_id] = record.payload.stacks_after
	check(trials == ["penetration", "potency"], "new checks order is Penetration then Potency")
	check(counts.get("penetration") == 6 and counts.get("potency") == 8, "base one receives status bonus then doubling")
	target.dodge_chance = 1.0
	var dodge := CombatResolver.resolve([skill], player, target, 100, 42, true)
	check(_trial_count(dodge) == 0, "dodge excludes crit grants")
	target.dodge_chance = 0.0
	player.retrigger_chance = 1.0
	result = CombatResolver.resolve([skill], player, target, 100, 42, true)
	check(result.cast_events.size() > 1 and _trial_count(result) == 2 * result.cast_events.size(), "each eligible repeat has independent trials")

func _context_and_local_crit() -> void:
	var skill := make_skill("test.local", 100)
	var player := PlayerStats.new()
	player.crit_applies_penetration = 1.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 6
	var before := rng.state
	var event := CombatResolver.CastEvent.new()
	event.skill = skill
	var state := CombatResolver._apply_skill_effects(skill, event, player, Monster.new(), 0, 0.0, 0, 0, rng, "cast")
	check(state.get("error", "") != "" and rng.state == before, "missing lifecycle errors before any RNG draw")
	var result := CombatResolver.CombatResult.new()
	result.defense_debuffs = Defenses.new(player, 0, 0, result.trace)
	event.is_crit = true
	player.crit_chance = 0.0
	CombatResolver._apply_skill_effects(skill, event, player, Monster.new(), 0, 0.0, 0, 0, rng, "proc", 0, 0, result)
	check(result.defense_debuffs.state.snapshot().is_empty(), "cumulative event crit cannot authorize a noncritical local contribution")

func _ordering() -> void:
	var skill := make_skill("test.order", 100)
	skill.effects.append(ForcedTick.new())
	var seed_skill := make_skill("test.seed_poison", 100)
	seed_skill.category = Skill.Category.DEBUFF
	var poison := PoisonDamageEffect.new()
	poison.stacks_applied = 20
	seed_skill.effects = [poison]
	var player := PlayerStats.new()
	player.crit_chance = 1.0
	player.crit_applies_penetration = 1.0
	player.crit_applies_potency = 1.0
	player.bonus_penetration_stacks = 49
	player.bonus_potency_stacks = 49
	player.critical_poison_enabled = true
	player.poison_damage_per_tick = 10
	player.retrigger_chance = 1.0
	var target := Monster.new()
	target.cleanse_threshold = 1
	var result := CombatResolver.resolve([seed_skill, skill], player, target, 200, 6, true)
	check(result.is_valid, "ordering result valid")
	check(_trial_count(result) == (result.cast_events.size() - 1) * 2, "forced tick crits and debuff contributions never add trials")
	check(result.tick_events[0].had_active_stack and result.tick_events[0].is_crit and result.tick_events[0].damage == 30.0, "forced crit tick uses freshly granted fifty Potency: negative absorb adds five base before cleanse")
	var first_proc := -1
	var first_cleanse := -1
	var first_child_proc := -1
	for i in range(result.trace.records.size()):
		var record = result.trace.records[i]
		if record.kind == "crit_defense_proc":
			if first_proc < 0:
				first_proc = i
			elif record.parent_cast_id > 0 and first_child_proc < 0:
				first_child_proc = i
		if record.kind == "effect_lifecycle" and record.lifecycle_reason == "cleansed" and first_cleanse < 0:
			first_cleanse = i
	check(first_proc >= 0 and first_cleanse > first_proc and first_child_proc > first_cleanse, "root proc precedes cleanse and descendant proc follows cleanse")
	for event in result.cast_events:
		check(event.stat_snapshot.effective_block == 0.0, "triggering damage and descendants after cleanse see no retroactive defense reduction")
	player.retrigger_chance = 0.0
	target.cleanse_threshold = 0
	var maintained := CombatResolver.resolve([skill], player, target, 200, 6, true)
	check(maintained.cast_events[1].stat_snapshot.effective_block == -50.0 and maintained.cast_events[1].stat_snapshot.negative_block_base_bonus == 5.0, "fifty Penetration gives negative fifty block and five relevant base damage")

func _trial_count(result) -> int:
	var count := 0
	for record in result.trace.records:
		if record.kind == "crit_defense_proc":
			count += 1
	return count
