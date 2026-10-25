extends "res://tests/p6_macro_scheduler_test.gd"

func _initialize() -> void:
	var virulent: Skill = preload("res://scripts/systems/playable_assassin_content.gd").skill("virulent_poison")
	check(virulent.cooldown_ms == 10000 and virulent.base_execution_ms == 500, "Virulent: ten-second cooldown and half-second cast")
	var result := CombatResolver.resolve([virulent, virulent], PlayerStats.new(), Monster.new(), 11000, 1, true)
	var activations := []
	for event in result.cast_events:
		if not event.cooldown_blocked: activations.append(event.time_ms)
	check(activations == [500, 11000], "Virulent duplicates share ten seconds from completion")
	check(SkillTooltipFormatter.details_for(virulent, null).contains("Cooldown: 10.00s after cast completion"), "Virulent tooltip uses new cooldown")
	var pocket: Skill = preload("res://scripts/systems/p6_thief_contracts.gd").skill("pick_pocket")
	check(pocket.cooldown_ms == 8000 and pocket.effects[0].amount == 10, "Pick Pocket eight-second cooldown, ten raw gold")
	result = CombatResolver.resolve([pocket, pocket.duplicate(true)], PlayerStats.new(), Monster.new(), 11600, 1, true)
	activations.clear()
	for event in result.cast_events:
		if not event.cooldown_blocked: activations.append(event.time_ms)
		else: check(event.gold_stolen == 0 and event.time_ms-event.cast_start_ms == 100, "Cooling Pick Pocket skips in 100ms without gold")
	check(activations == [1800,11600] and result.gold_stolen == 20, "Pick Pocket duplicate slots share cooldown from completion")
	check(SkillTooltipFormatter.details_for(pocket, null).contains("Cooldown: 8.00s after cast completion"), "Pick Pocket tooltip reads runtime cooldown")
	_cycle()
	_clocks()
	_failures_and_repeats()
	print("P6 T5 cooldown scheduler: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)

func _cycle() -> void:
	var a := make_skill("test.cooldown", 100)
	a.cooldown_ms = 350
	var rotation: Array[Skill] = [a, a.duplicate(true)]
	var stats := PlayerStats.new()
	var result := CombatResolver.resolve(rotation, stats, Monster.new(), 500, 1, true)
	check(result.cast_events.size() == 5, "all cooling slots cycle every 100ms")
	for i in range(result.cast_events.size()):
		var cast := result.cast_events[i]
		check(cast.rotation_index == i % 2, "duplicate slots share cooldown and preserve order")
		check(cast.cooldown_blocked == (i in [1, 2, 3, 4]), "cooldown checked at start, no mid-attempt activation")
		if cast.cooldown_blocked:
			check(cast.physical_damage == 0 and cast.weapon_damage_rolls.is_empty() and cast.time_ms - cast.cast_start_ms == 100, "cooldown attempts have no attacks")
	check(result.scheduler.available_at(a.id) == 0, "fight cleanup clears cooldowns")
	var retry := CombatResolver.resolve(rotation, stats, Monster.new(), 500, 1, true)
	var quiet := CombatResolver.resolve(rotation, stats, Monster.new(), 500, 1, false)
	check(retry.trace.records == result.trace.records, "retry starts fresh")
	check(quiet.rng_final_state == result.rng_final_state and quiet.total_damage == result.total_damage, "trace parity")
	a.cooldown_ms = 400
	rotation = [a]
	result = CombatResolver.resolve(rotation, stats, Monster.new(), 600)
	check(not result.cast_events[5].cooldown_blocked, "exact cooldown deadline is eligible")
	stats.attack_speed = 9
	stats.min_cast_time_proc_chance = 1
	a.min_execution_ms = 1
	var monster := Monster.new()
	monster.slow = 2
	result = CombatResolver.resolve(rotation, stats, monster, 301)
	check(result.cast_events.size() == 4, "proc then three fixed cooldown attempts")
	for i in range(1, result.cast_events.size()):
		check(result.cast_events[i].time_ms - result.cast_events[i].cast_start_ms == 100 and not result.cast_events[i].min_cast_time_proc_applied, "speed slow and proc cannot change 100ms")
	var short := CombatResolver.resolve(rotation, stats, monster, 1)
	check(short.rng_final_state == result.rng_final_state, "cooldown attempts consume no RNG")

func _clocks() -> void:
	var stats := PlayerStats.new()
	stats.footwork_rank = 5
	stats.poison_damage_per_tick = 5
	var cut := make_skill("skill.quick_cut", 100)
	cut.poison_stacks_applied = 5
	cut.cooldown_ms = 10000
	var rotation: Array[Skill] = [cut]
	var result := CombatResolver.resolve(rotation, stats, Monster.new(), 3500, 1, true)
	check(result.tick_events.size() == 3 and result.tick_events[2].had_active_stack, "poison continues through cooldown attempts")
	var grants := 0
	var expired := false
	for event in result.trace.records:
		if event.kind == "effect_lifecycle" and event.payload.effect_id == "footwork":
			if event.lifecycle_reason == "granted":
				grants += 1
			if event.lifecycle_reason == "expired":
				expired = event.payload.expires_at_ms_before == 3100
	check(grants == 1 and expired, "cooling Quick Cut cannot grant or refresh Footwork")
	check(result.cast_events.size() == 35, "all-blocked macro remains finite")

func _failures_and_repeats() -> void:
	var attack := make_skill("test.attack", 100)
	attack.cooldown_ms = 300
	var rotation: Array[Skill] = [attack]
	var stats := PlayerStats.new()
	var dodge := Monster.new()
	dodge.dodge_chance = 1
	var result := CombatResolver.resolve(rotation, stats, dodge, 300)
	check(result.cast_events[0].was_dodged and result.cast_events[1].cooldown_blocked, "dodge retains cooldown")
	var interrupt := Monster.new()
	interrupt.interrupt_skip_count = 1
	attack.cooldown_ms = 100
	result = CombatResolver.resolve(rotation, stats, interrupt, 500)
	check(result.cast_events[4].was_interrupted and result.cast_events[4].cooldown_available_at_ms == 600, "interruption retains completion-owned cooldown")
	attack.cooldown_ms = 1000
	stats.retrigger_chance = 1
	result = CombatResolver.resolve(rotation, stats, Monster.new(), 200)
	check(result.cast_events.size() == 18 and result.cast_events.back().cooldown_blocked, "repeats bypass macro cooldown")
	for cast in result.cast_events:
		check(cast.cooldown_available_at_ms == 1100, "children do not restart cooldown")
	stats.retrigger_chance = 0
	stats.readiness_enabled = true
	var parry := make_skill("skill.parry_strike", 500, 300)
	parry.cooldown_ms = 10000
	rotation = [parry]
	result = CombatResolver.resolve(rotation, stats, Monster.new(), 1000)
	check(result.cast_events.size() == 2 and result.cast_events[1].resource_unavailable and result.cast_events[1].cooldown_available_at_ms == 0, "missing resource spends ordinary time without starting cooldown")
	parry.cooldown_ms = -1
	check(not CombatResolver.resolve(rotation, stats, Monster.new(), 1000).is_valid, "negative cooldown rejected")
	parry.cooldown_ms = 100
	var conflicting := parry.duplicate(true) as Skill
	conflicting.cooldown_ms = 200
	rotation = [parry, conflicting]
	check(not CombatResolver.resolve(rotation, stats, Monster.new(), 1000).is_valid, "conflicting duplicate IDs rejected")
