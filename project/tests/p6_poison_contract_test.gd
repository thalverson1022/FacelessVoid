extends "res://tests/p6_status_interactions_test.gd"

const ForcedTick = preload("res://scripts/resources/forced_poison_tick_effect.gd")
const Poison = preload("res://scripts/systems/p6_poison_contracts.gd")
const Cadence = preload("res://scripts/systems/poison_cadence.gd")
const StatusSkills = preload("res://scripts/systems/p6_status_skill_contracts.gd")

func _initialize() -> void:
	super._initialize()

func _run() -> void:
	_rank_damage_and_crits()
	_cadence_and_descriptor()
	_tick_accounting()
	_order_and_consumption()
	super._run()

func _tick_accounting() -> void:
	var stats := PlayerStats.new()
	stats.poison_damage_per_tick = 10.0
	stats.death_pact_rank = 3
	for stacks in range(4):
		for forced in [false, true]:
			var result := CombatResolver.CombatResult.new()
			result.trace.enabled = true
			result.self_buffs.trace = result.trace
			result.self_buffs.grant("virulent_poison", 0, {"source_id": "test.buff.one"})
			result.self_buffs.grant("virulent_poison", 0, {"source_id": "test.buff.two"})
			var remaining := CombatResolver._resolve_poison_tick(result, 1000, stacks,
				stats, 0, 0.0, _monster(), 1000, forced,
				{"cast_id": 3, "parent_cast_id": 2, "root_cast_id": 1, "source_id": "test.forced"})
			var tick: CombatResolver.TickEvent = result.tick_events[0]
			check(tick.stacks_before == stacks and remaining == stacks - tick.stacks_consumed, "tick stack conservation")
			check(tick.stacks_consumed == (0 if stacks == 0 else 1), "settled natural versus forced depletion")
			check(tick.damage == (40.0 if stacks > 0 else 0.0), "independent Virulent multipliers")
			check(tick.charge_spends.size() == (2 if stacks > 0 else 0), "empty ticks preserve all charges")
			for spend in tick.charge_spends:
				check(spend.before == 5 and spend.after == 4 and not spend.source_id.is_empty(), "charge source and amount preserved")
			var row: Dictionary = result.trace.records.back()
			check(row.payload.charge_spends == tick.charge_spends and not row.payload.keyword_consume, "trace explains charge use without keyword Consume")
			check(row.cast_id == 3 and row.parent_cast_id == 2 and row.root_cast_id == 1, "tick retains triggering ancestry")
			check(row.payload.stacks_before - row.payload.stacks_depleted == row.payload.stacks_remaining, "trace stack reconciliation")

func _order_and_consumption() -> void:
	var stats := PlayerStats.new()
	stats.poison_damage_per_tick = 10.0
	stats.death_pact_rank = 1
	var fuel := _utility("test.fuel")
	fuel.base_execution_ms = 500
	fuel.effects = [_poison(3)]
	var strike := _skill("test.forced")
	strike.base_execution_ms = 500
	strike.effects.append(ForcedTick.new())
	var consume := _utility("test.consume", Skill.Category.SELF_BUFF)
	consume.base_execution_ms = 500
	consume.effects = [_consume("poison", 5), _consume("poison", 2)]
	var result := CombatResolver.resolve([fuel, strike, consume], stats, _monster(), 1500, 42, true)
	check(result.tick_events.size() == 2, "one natural and one forced tick at 1000 ms")
	if result.tick_events.size() == 2:
		check(result.tick_events[0].origin_kind == "natural_tick" and result.tick_events[1].origin_kind == "forced_tick", "natural tick precedes same-time forced tick")
		check(result.tick_events[0].stacks_remaining == 2 and result.tick_events[1].stacks_remaining == 1, "forced tick depletes post-natural fuel")
	var transactions: Array = result.cast_events[2].status_transactions
	check(transactions.size() == 2 and transactions[0].consumed == 1 and transactions[1].consumed == 0, "sequential Consume uses actual remainder")
	check(transactions[0].requested_consumption == 5 and transactions[1].requested_consumption == 2, "requested consumption retained separately")
	check(result.cast_events[2].status_snapshot.defenses.block == -1.0, "only actual keyword consumption grants Pact")
	var total := 0.0
	for row in result.trace.records:
		if row.kind in ["cast_resolved", "poison_tick"]:
			total += row.payload.damage
	check(is_equal_approx(total, result.total_damage), "all tick and cast damage reconciles")
	var replay := CombatResolver.resolve([fuel, strike, consume], stats, _monster(), 1500, 42, true)
	var off := CombatResolver.resolve([fuel, strike, consume], stats, _monster(), 1500, 42)
	check(replay.trace.records == result.trace.records, "Poison trace exact replay")
	check(off.rng_final_state == result.rng_final_state and off.total_damage == result.total_damage, "diagnostics preserve RNG and damage")

func _rank_damage_and_crits() -> void:
	var base := PlayerStats.new()
	base.poison_damage_per_tick = 10.0
	check(Poison.apply_passives(base, 0, 1, 0, 0, false) == null, "Accelerant prerequisite")
	check(Poison.apply_passives(base, 0, 0, 0, 1, false) == null, "Resonance prerequisite")
	check(Poison.apply_passives(base, 6, 0, 0, 0, false) == null, "rank validation")
	for echo in range(4):
		for resonance in range(5):
			if resonance > 0 and echo == 0:
				continue
			var stats: PlayerStats = Poison.apply_passives(base, 0, 0, echo, resonance, true)
			stats.crit_chance = 1.0
			stats.crit_multiplier = 2.0
			for stacks in range(4):
				for forced in [false, true]:
					var result := CombatResolver.CombatResult.new()
					result.combat_rng = RandomNumberGenerator.new()
					result.combat_rng.seed = 123
					var expected_rng := RandomNumberGenerator.new()
					expected_rng.seed = 123
					if stacks > 0:
						expected_rng.randf()
					var required := 3 if resonance > 0 else (2 if echo > 0 else 1)
					var spent := mini(stacks, required)
					CombatResolver._resolve_poison_tick(result, 1000, stacks, stats, 0, 0.0, _monster(), 1000, forced)
					var tick: CombatResolver.TickEvent = result.tick_events[0]
					var raw := 10.0 * spent * (1.0 + resonance * 0.05)
					check(is_equal_approx(tick.raw_damage, raw), "per-stack damage then separate rank multipliers")
					check(tick.stacks_remaining == stacks - spent and tick.requested_stacks == required, "partial fuel damage/depletion")
					check(tick.is_crit == (stacks > 0) and tick.damage == roundf(raw * 2.0), "one crit multiplies whole packet before final rounding")
					check(result.combat_rng.state == expected_rng.state, "exactly one RNG draw per fueled critical tick")
	var stats: PlayerStats = Poison.apply_passives(base, 0, 0, 3, 4, true)
	stats.crit_chance_per_stolen_gold = 0.1
	stats.crit_multiplier_per_current_gold = 0.01
	stats.current_gold = 90
	var result := CombatResolver.CombatResult.new()
	result.combat_rng = RandomNumberGenerator.new()
	result.gold_stolen = 10
	CombatResolver._resolve_poison_tick(result, 1000, 3, stats, 0, 0.0, _monster(), 1000)
	check(is_equal_approx(result.tick_events[0].raw_damage, 36.0), "D015 max-rank example: 36.0 before crit/mitigation")
	check(result.tick_events[0].crit_multiplier == 3.0 and result.tick_events[0].crit_chance == 1.0, "current gold-derived crit inputs")
	var target := _monster()
	target.crit_negation = 1.0
	stats.special_effects = {"damage_conversion": {"physical": true}}
	CombatResolver._resolve_poison_tick(result, 2000, 3, stats, 0, 0.0, target, 1000)
	check(result.tick_events[1].is_crit and result.tick_events[1].damage == 0.0 and result.tick_events[1].crit_negation_applied > 0.0, "converted Poison uses existing physical crit-negation rule")

func _cadence_and_descriptor() -> void:
	var base := PlayerStats.new()
	for rank in range(4):
		base.echoing_toxin_rank = rank
		check(Cadence.interval(base, 0.0) == [1000, 1400, 1300, 1200][rank], "Echoing rank suppression without IAS")
		check(Cadence.interval(base, 0.5) == [1500, 1900, 1800, 1700][rank], "Echoing adds to enemy suppression")
		base.attack_speed = 1.0
		base.hastened_poison_rank = 5
		base.accelerant_rank = 5
		check(Cadence.interval(base, 0.0) == [500, 700, 650, 600][rank], "Echoing suppression with additive IAS scaling")
		base.attack_speed = 0.0
		base.hastened_poison_rank = 0
		base.accelerant_rank = 0
	base.echoing_toxin_rank = 0
	base.attack_speed = 1.0
	var stats: PlayerStats = Poison.apply_passives(base, 5, 0, 0, 0, false)
	check(Cadence.interval(stats, 0.0) == 667, "Hastened uses half IAS at rank five")
	stats.accelerant_rank = 5
	check(Cadence.interval(stats, 0.0) == 500 and Cadence.interval(stats, 1.0) == 1000, "additive scaling and inherited suppress")
	stats.attack_speed = 10000.0
	check(Cadence.interval(stats, 0.0) == 1, "one millisecond minimum")
	var clock := Cadence.new()
	clock.advance(500)
	clock.interval_ms = 500
	check(clock.deadline() == 750, "halfway through remains halfway after speed change")
	var strike: Skill = Poison.poison_strike()
	check(strike.base_execution_ms == 1200 and strike.min_execution_ms == 500 and strike.cooldown_ms == 0, "approved Poison Strike timing")
	stats = Poison.apply_passives(PlayerStats.new(), 5, 5, 3, 4, true)
	stats.poison_damage_per_tick = 10.0
	stats.crit_chance = 0.5
	stats.weapon_damage_min = 100
	stats.weapon_damage_max = 100
	var fuel := _utility("test.fuel")
	fuel.base_execution_ms = 500
	fuel.effects = [_poison(20)]
	var result := CombatResolver.resolve([fuel, strike], stats, _monster(), 1700, 7, true)
	check(result.cast_events[1].physical_damage in [83.0, 166.0], "Poison Strike 83 percent weapon scaling")
	check(result.tick_events.size() == 2 and result.tick_events[1].stacks_consumed == 3, "real Poison Strike executes shared tick")
	var replay := CombatResolver.resolve([fuel, strike], stats, _monster(), 1700, 7, true)
	var off := CombatResolver.resolve([fuel, strike], stats, _monster(), 1700, 7)
	check(result.trace.records == replay.trace.records and off.rng_final_state == result.rng_final_state and off.total_damage == result.total_damage, "critical tick seeded replay and tracing neutrality")
	stats.echoing_toxin_rank = 0
	stats.resonance_rank = 0
	var touch: Skill = StatusSkills.skill("touch_of_darkness")
	var hold := _utility("skill.hold")
	hold.base_execution_ms = 40000
	result = CombatResolver.resolve([fuel, touch, hold], stats, _monster(), 14000, 7, true)
	var changes: Array = []
	for row in result.trace.records:
		if row.kind == "poison_cadence":
			changes.append(row)
	check(changes.size() == 2, "Touch activation and expiry each reschedule once")
	if changes.size() == 2:
		check(changes[0].time_ms == 1000 and changes[0].payload.interval_ms == 345, "Touch's actual 19 stacks provide 190 percent IAS")
		check(changes[1].time_ms == 13000 and changes[1].payload.next_tick_ms == 13218, "expiry during clipped cast preserves fractional phase")
	check(result.tick_events.back().time_ms == 13218, "rescheduled deadline actually executes")
	fuel.base_execution_ms = 200
	fuel.min_execution_ms = 100
	hold.base_execution_ms = 14000
	hold.category = Skill.Category.SELF_BUFF # Long IAS-independent cast for the boundary probe.
	result = CombatResolver.resolve([fuel, touch, hold], stats, _monster(), 15000, 7, true)
	check(result.is_valid and result.tick_events[0].time_ms == 800, "mid-cycle Touch grant preserves 70 percent progress")
	var found_expiry := false
	for row in result.trace.records:
		if row.kind == "poison_cadence" and row.time_ms == 12700:
			found_expiry = true
	check(found_expiry and result.cast_events[2].time_ms == 14700, "IAS expiry processed inside a completed long cast")
	# Preserve a reproducible trace containing grant, empty beats and exact expiry.
	var path: String = get_script().resource_path.get_base_dir().path_join("poison_handoff.json")
	var report := FileAccess.open(path, FileAccess.WRITE)
	check(report != null, "write Poison validation trace")
	if report != null:
		report.store_string(JSON.stringify({"decision": "P6M3-D024", "trace": result.trace.records,
			"total_damage": result.total_damage, "rng_final_state": str(result.rng_final_state)}, "\t"))
		report.close()
	# Full block preserves the connected forced tick; dodge prevents it.
	fuel.base_execution_ms = 500
	stats.hastened_poison_rank = 0
	stats.accelerant_rank = 0
	stats.critical_poison_enabled = false
	var target := _monster()
	target.block = 100000.0
	result = CombatResolver.resolve([fuel, strike], stats, target, 1700, 7, true)
	check(result.cast_events[1].physical_damage == 0.0 and result.tick_events.size() == 2, "blocked connected hit still causes tick")
	target.dodge_chance = 1.0
	result = CombatResolver.resolve([fuel, strike], stats, target, 1700, 7, true)
	check(result.cast_events[1].was_dodged and result.tick_events.size() == 1, "dodge prevents forced tick")
	stats.echoing_toxin_rank = 3
	stats.resonance_rank = 4
	stats.critical_poison_enabled = true
	stats.crit_chance = 1.0
	result = CombatResolver.resolve([fuel, strike], stats, _monster(), 1700, 7, true)
	check(CombatRecap.summarize(result, _monster()).peak_poison_stacks == 20, "recap uses actual pre-tick stacks with three-stack depletion")
	var formatted := CombatResultFormatter.format(result, _monster())
	var forced_ticks: Array = result.tick_events.filter(func(tick): return tick.origin_kind == "forced_tick")
	check(forced_ticks.size() == 1 and forced_ticks[0].is_crit and forced_ticks[0].stacks_consumed == 3 and not forced_ticks[0].keyword_consume, "critical forced tick depletes three stacks without keyword Consume")
	check(formatted.contains("CRIT (forced) (3 stacks depleted; not Consume)"), "text reports critical forced multi-stack depletion without keyword Consume")
