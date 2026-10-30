extends SceneTree
const Fixture = preload("res://tests/fixtures/m9_t9_mechanics_fixture.gd")
const TimerMath = preload("res://scripts/systems/combat_timer_math.gd")
const Defenses = preload("res://scripts/systems/combat_defense_debuffs.gd")
const StatState = preload("res://scripts/systems/combat_stat_state.gd")
const Forced = preload("res://scripts/resources/forced_poison_tick_effect.gd")
var failed := false
var checks: Array[Dictionary] = []
var witnesses := {}

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String, actual: Variant = null) -> void:
	checks.append({"passed": ok, "label": label, "actual": actual})
	if not ok:
		failed = true
		printerr("FAILED: " + label + " " + str(actual))

func legal(items: Array[GearItem], label: String) -> void:
	var slots := {}
	for item in items:
		check(item != null and not slots.has(item.slot), label + " unique slot", item.slot)
		slots[item.slot] = true
		var payload: Variant = SaveSystem._gear_entry_to_data(item)
		check(SaveSystem.gear_payload_error(payload, true) == "", label + " serialization domain", item.id)
		var restored: GearItem = SaveSystem._gear_from_save_entry(payload, "m9_t9_mechanics")
		check(restored != null and JSON.stringify(SaveSystem._gear_entry_to_data(restored)) == JSON.stringify(payload), label + " exact item roundtrip", item.id)
	check(slots.size() == 7, label + " seven occupied slots", slots.keys())

func stats(items: Array[GearItem], talents: Array[Talent] = []) -> PlayerStats:
	return BuildResolver.resolve_stats(null, [], talents, items)

func attack(id: String = "test.attack", amount: float = 100.0) -> Skill:
	var s := Skill.new()
	s.id = id
	s.base_execution_ms = 100
	s.min_execution_ms = 100
	var e := PhysicalDamageEffect.new()
	e.amount = amount
	s.effects = [e]
	return s

func target() -> Monster:
	var m := Monster.new()
	m.hp = 1000000000
	return m

func run() -> void:
	conversions()
	binary_stacking()
	cooldowns()
	durations_and_bases()
	procs()
	legendary_combinations()
	legal_budget()
	FileAccess.open("res://reports/m9_t9_mechanics.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": not failed, "count": checks.size(), "checks": checks, "witnesses": witnesses}, "\t"))
	print("M9 T9 combined mechanics " + ("FAIL" if failed else "PASS") + " checks=" + str(checks.size()))
	quit(1 if failed else 0)

func conversions() -> void:
	var items := Fixture.ordinary()
	Fixture.put(items, Fixture.unique(0, "convert_damage_to_physical"))
	Fixture.put(items, Fixture.unique(6, "convert_damage_to_magical"))
	Fixture.put(items, Fixture.unique(4, "all_stats_increased"))
	Fixture.put(items, Fixture.unique(5, "all_stats_increased"))
	legal(items, "dual conversion")
	var sheet = BuildResolver.resolve_gear_stat_sheet(items)
	for reverse in [false, true]:
		if reverse: items.reverse()
		sheet = BuildResolver.resolve_gear_stat_sheet(items)
		check(sheet.converts_damage_to_physical() and sheet.converts_damage_to_magical(), "both conversions survive caller equipment order")
		# A neutral packet isolates mitigation order from independent numeric fillers.
		for original in ["physical", "magical"]:
			var hit := DamageCalculator.resolve_damage_packet(100, original, 0, .2, 0, 1, null, 1, 0, 10, 5, 1, 1, sheet.converts_damage_to_physical(), sheet.converts_damage_to_magical())
			check(hit.amount == 67 and hit.blocked_amount == 10 and hit.absorbed_amount == 5, "both original types use physical then magical once", hit)
	Fixture.put(items, Fixture.unique(3, "ignore_resistance_physical_penalty"))
	Fixture.put(items, Fixture.unique(2, "ignore_armor_no_shred"))
	sheet = BuildResolver.resolve_gear_stat_sheet(items)
	legal(items, "conversion bypass coexistence")
	for pair in [["physical", 35.0], ["magical", 85.0]]:
		var hit := DamageCalculator.resolve_damage_packet(100, pair[0], 999, .99, 0, 1, null, 1, 0, 10, 5, 1, 1, true, true, sheet.ignores_armor_without_shred(), sheet.ignores_resistance_with_physical_penalty(), sheet.physical_damage_penalty())
		check(hit.amount == pair[1], "bypass penalty applies only to original physical", hit)
	var p := stats(items)
	var m := target()
	m.armor = 100
	var r := CombatResolver.resolve([attack()], p, m, 100, 11, true)
	check(r.is_valid and r.cast_events.all(func(e): return e.shred_stacks_applied == 0), "ignore armor still prohibits Shred with legal Shred affixes")

func binary_stacking() -> void:
	var items := Fixture.ordinary()
	for slot in [3, 1, 2, 6]: Fixture.put(items, Fixture.unique(slot, "double_applied_stacks"))
	for slot in [4, 5]: Fixture.put(items, Fixture.unique(slot, "all_stats_increased"))
	legal(items, "repeated doubling and All Stats")
	var p := stats(items)
	var sheet = BuildResolver.resolve_gear_stat_sheet(items)
	check(sheet.count_for("double_applied_stacks") == 4 and sheet.count_for("all_stats_increased") == 2, "multiple legal copies recorded")
	check(sheet.all_stats_multiplier() == 1.2, "multiple All Stats applies one factor")
	var defenses := Defenses.new(p, 0, 0)
	var grant: Dictionary = defenses.grant("penetration", 1, p, 100, {})
	check(grant.state.stacks == mini(50, (1 + p.bonus_penetration_stacks) * 2), "four doubling copies double once after ordinary bonuses", grant)
	for id in ["disable_enemy_dodge", "disable_enemy_block", "disable_enemy_absorb", "disable_enemy_suppress", "disable_enemy_cleanse"]:
		items = Fixture.ordinary()
		for slot in [4, 1, 2, 5, 6]: Fixture.put(items, Fixture.unique(slot, id))
		var duplicated = BuildResolver.resolve_gear_stat_sheet(items)
		check(duplicated.count_for(id) == 5 and duplicated.active_specials().count(id) == 1, "five denial copies retain OR " + id)
	for id in ["immune_to_stun", "immune_to_slow", "immune_to_interrupt"]:
		items = Fixture.ordinary()
		for slot in [4, 5]: Fixture.put(items, Fixture.unique(slot, id))
		var duplicated = BuildResolver.resolve_gear_stat_sheet(items)
		check(duplicated.count_for(id) == 2 and duplicated.active_specials().count(id) == 1, "two immunity copies retain OR " + id)

func cooldowns() -> void:
	var items := Fixture.ordinary()
	for slot in [0, 3, 2, 5, 6]: Fixture.put(items, Fixture.chaos(slot, "cooldown_reduction"))
	Fixture.put(items, Fixture.unique(4, "all_stats_increased"))
	legal(items, "seven-slot high CDR")
	var expected := pow(.712, 4) * pow(.616, 4) * pow(.508, 12)
	var p := stats(items)
	check(p.derivation_error == "" and absf(p.cooldown_factor - expected) < 1e-14, "twenty separate CDR affixes multiply after All Stats", p.cooldown_factor)
	var sheet = BuildResolver.resolve_gear_stat_sheet(items)
	check(sheet.cooldown_contributions.size() == 20, "all CDR affixes retained in ledger")
	var order: Array = []
	for row in sheet.cooldown_contributions:
		if not order.has(row.source_slot): order.append(row.source_slot)
	check(order == [0, 3, 2, 5, 6], "CDR ledger has reviewed universal slot order", order)
	items.reverse()
	var reverse = BuildResolver.resolve_gear_stat_sheet(items)
	check(reverse.cooldown_contributions == sheet.cooldown_contributions and reverse.cooldown_factor == sheet.cooldown_factor, "reverse equipment order preserves exact CDR ledger/factor")
	check(TimerMath.cooldown(10000, p.cooldown_factor).duration_ms == 1, "legal seven-slot 10s cooldown reaches positive 1ms floor")
	var skill := attack()
	skill.cooldown_ms = 10000
	var r := CombatResolver.resolve([skill], p, target(), 200, 5, true)
	check(r.is_valid and r.cast_events[0].cooldown_available_at_ms == 101, "root scheduler consumes legal seven-slot factor", r.failure)
	var rebuild := StatState.new(p)
	check(rebuild.snapshot().cooldown_factor == p.cooldown_factor, "static rebuild preserves tiny factor")
	witnesses["cdr"] = {"factor": p.cooldown_factor, "affixes": 20, "cooldown_ms": 1}

func durations_and_bases() -> void:
	var items := Fixture.ordinary()
	Fixture.put(items, Fixture.unique(5, "all_stats_increased", "increased_buff_duration", ["percent_physical_damage", "crit_damage", "increased_gold"]))
	Fixture.put(items, Fixture.unique(4, "all_stats_increased", "crit_applies_penetration"))
	Fixture.put(items, Fixture.unique(6, "disable_enemy_dodge", "increased_buff_duration", ["base_damage", "base_elemental_damage", "increased_gold"]))
	legal(items, "duration and independent base buckets")
	var p := stats(items)
	check(is_equal_approx(p.increased_buff_duration, 1.104), "Pants .54 plus Gloves .38 is additive then All Stats once", p.increased_buff_duration)
	check(p.bonus_physical_damage == 14 and is_equal_approx(p.bonus_base_elemental_damage, 19.2), "Gloves physical14 stays14 while elemental16 becomes19.2", [p.bonus_physical_damage, p.bonus_base_elemental_damage])
	check(p.weapon_damage_weapon_id == items[0].id and p.weapon_damage_min > 0, "Gloves physical base does not replace weapon identity/range")
	p.death_pact_rank = 3 # Focused valid authored-rank timer witness, independent of gear.
	var defenses := Defenses.new(p, 0, 0)
	var grant: Dictionary = defenses.grant("potency", 1, p, 100, {})
	check(grant.state.expires_at_ms == 12724, "Pact 6000ms scales by2.104 before deadline", grant)
	var rebuild := StatState.new(p)
	check(rebuild.snapshot().increased_buff_duration == p.increased_buff_duration, "duration static rebuild does not amplify twice")
	check(TimerMath.scaled_duration(12000, 1e308).error != "" and TimerMath.deadline(TimerMath.INT64_MAX, 1).error != "", "malformed overflow inputs rejected by checked arithmetic")

func procs() -> void:
	var items := Fixture.ordinary()
	Fixture.put(items, Fixture.chaos(3, "crit_chance", "basic"))
	Fixture.put(items, Fixture.chaos(5, "crit_applies_penetration"))
	Fixture.put(items, Fixture.chaos(1, "crit_applies_potency"))
	Fixture.put(items, Fixture.unique(4, "all_stats_increased", "crit_applies_penetration"))
	Fixture.put(items, Fixture.unique(6, "double_applied_stacks", "cooldown_reduction"))
	legal(items, "critical defense procs")
	var p := stats(items)
	check(p.crit_chance == 1 and p.crit_applies_penetration == 1 and p.crit_applies_potency == 1, "legal seven-slot proc chances independently cap at one")
	var m := target()
	m.block = 1000000
	var r := CombatResolver.resolve([attack()], p, m, 100, 7, true)
	var trials: Array = r.trace.records.filter(func(row): return row.kind == "crit_defense_proc")
	check(r.is_valid and r.cast_events[0].physical_damage == 0 and trials.size() == 2, "connected zero-damage legal crit grants exactly two trials")
	check(trials.map(func(row): return row.payload.status) == ["penetration", "potency"], "seven-slot proc order is Penetration then Potency")
	check(r.cast_events[0].stat_snapshot.effective_block == 1000000, "proc grant does not retroactively reduce triggering packet defense")
	var zero_gear := Fixture.ordinary()
	var zero := stats(zero_gear)
	var plain := CombatResolver.resolve([attack()], zero, target(), 200, 7, false)
	var observed := CombatResolver.resolve([attack()], zero, target(), 200, 7, true)
	check(plain.rng_final_state == observed.rng_final_state and observed.trace.records.all(func(row): return row.kind != "crit_defense_proc"), "zero-chance gear adds no proc RNG and trace is passive")
	# Same source with no eligible critical: positive proc chances add no trials.
	p.crit_chance = 0
	var inactive := CombatResolver.resolve([attack()], p, target(), 100, 7, true)
	p.crit_applies_penetration = 0
	p.crit_applies_potency = 0
	var baseline := CombatResolver.resolve([attack()], p, target(), 100, 7, true)
	check(inactive.rng_final_state == baseline.rng_final_state, "ineligible critical procs consume no RNG")

func legendary_combinations() -> void:
	var outcomes := {}
	var max_candidates := 0
	for pants in ["serpents_scales", "golden_greeves"]:
		for gloves in ["arctic_mittens", "hands_of_the_lightning_lord"]:
			var items := Fixture.ordinary()
			for name in ["decrepit_blade", "serpents_coil", pants, gloves]: Fixture.legendary(items, name)
			Fixture.put(items, Fixture.chaos(3, "crit_chance", "basic"))
			Fixture.put(items, Fixture.unique(4, "all_stats_increased", "crit_applies_penetration"))
			legal(items, pants + "+" + gloves)
			# Same explicit rank fields used by RankedBuild's selected-Talent adapter;
			# focused mechanics carriers do not claim a full earned talent build.
			var critical := Talent.new()
			critical.id = "talent.assassin.critical_poison"
			critical.critical_poison_enabled = load("res://data/p6/assassin/critical_poison.tres").ranks[0].critical_poison_enabled
			var pact := Talent.new()
			pact.id = "talent.shadow.death_pact"
			pact.death_pact_rank = load("res://data/p6/shadow/death_pact.tres").ranks[0].death_pact_rank
			var p := stats(items, [critical, pact])
			check(p.derivation_error == "" and p.critical_poison_enabled and p.death_pact_rank == 1, "authored mixed talent stats resolve for pair")
			var add := attack("test.add")
			add.category = Skill.Category.DEBUFF
			add.poison_stacks_applied = 5
			var strike := attack("skill.poison_strike")
			strike.effects.append(Forced.new())
			for seed_value in range(1, 17):
				var r := CombatResolver.resolve([add, strike], p, target(), 600, seed_value, true)
				check(r.is_valid, "legal full-seven Legendary pair bounded simulation", [pants, gloves, seed_value, r.failure])
				check(r.duration_ms == (800 if gloves == "arctic_mittens" else 600), "Arctic only extends nominal window once")
				for row in r.trace.records:
					max_candidates = maxi(max_candidates, int(row.payload.get("budget_consumed", 0)))
				if pants == "serpents_scales":
					for tick in r.tick_events:
						if tick.legendary_fuel > 0 and tick.legendary_depth == 0:
							outcomes[str(tick.stacks_preserved)] = true
				if gloves == "hands_of_the_lightning_lord":
					var root_trials: Array = r.trace.records.filter(func(row): return row.kind == "trigger_decision" and row.cast_id == 2 and row.payload.has("roll"))
					if root_trials.size() == 2:
						outcomes["independent_legal_candidates"] = true
			check(p.retrigger_chance < 1, "new Lightning signature adds no ordinary numeric chance", p.retrigger_chance)
	check(outcomes.has("true") and outcomes.has("false") and outcomes.has("independent_legal_candidates"), "legal combinations witness preservation paid/free and independent Lightning candidates", outcomes)
	witnesses["legal_legendary_pairs"] = {"pairs": 4, "seeds_each": 16, "maximum_root_candidates": max_candidates, "outcomes": outcomes}

func legal_budget() -> void:
	var items := Fixture.ordinary()
	Fixture.put(items, Fixture.chaos(0, "chance_for_retrigger"))
	Fixture.legendary(items, "serpents_coil")
	Fixture.legendary(items, "serpents_scales")
	Fixture.legendary(items, "hands_of_the_lightning_lord")
	Fixture.put(items, Fixture.chaos(3, "crit_chance", "basic"))
	Fixture.put(items, Fixture.unique(4, "all_stats_increased"))
	legal(items, "reachable recursive budget stress")
	var critical := Talent.new()
	critical.id = "talent.assassin.critical_poison"
	critical.critical_poison_enabled = load("res://data/p6/assassin/critical_poison.tres").ranks[0].critical_poison_enabled
	var p := stats(items, [critical])
	check(p.derivation_error == "" and p.retrigger_chance == 1, "legal seven-slot endpoint reaches capped ordinary repeat chance")
	var add := attack("test.seed")
	add.category = Skill.Category.DEBUFF
	add.poison_stacks_applied = 5
	var strike := attack("skill.poison_strike")
	strike.effects.append(Forced.new())
	var m := target()
	var r := CombatResolver.resolve([add, strike], p, m, 200, 1, true)
	check(r.is_valid and r.root_trigger_candidates == 928, "legal capped-repeat seed1 remains valid with bounded928 candidate headroom", r.root_trigger_candidates)
	var budget_seed := 1
	for seed_value in range(2, 17):
		if not r.is_valid: break
		budget_seed = seed_value
		r = CombatResolver.resolve([add, strike], p, m, 200, seed_value, true)
	witnesses["budget_probe"] = {"seed": budget_seed, "candidates": r.root_trigger_candidates, "total_candidates": r.trigger_candidates_evaluated, "casts": r.cast_events.size(), "ticks": r.tick_events.size(), "chance": p.retrigger_chance}
	check(not r.is_valid and r.failure.get("code") == "trigger_candidate_limit" and r.root_trigger_candidates == 1024, "legal recursive gear exhausts shared1024 candidate budget", r.failure)
	var state = root.get_node("BuildState")
	state.reset()
	state.run_phase = state.RunPhase.FIGHTING
	state.last_combat_result = null
	state.highest_run_dps = 0
	state.record_fight_result(r, m)
	check(state.last_combat_result == null and state.highest_run_dps == 0 and state.run_encounter_history.is_empty(), "invalid budget result cannot enter recorded DPS/history")
	check(state.overkill_gold_for_result(r) == 0, "invalid budget result cannot grant Overkill Gold")
	check(state.cancel_invalid_fight(r) and state.run_phase == state.RunPhase.PLANNING and state.encounter_failure_counts.is_empty(), "invalid fight returns to preparation without consuming an attempt")
	witnesses["legal_budget_failure"] = r.failure
