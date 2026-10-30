extends SceneTree
const TimerMath = preload("res://scripts/systems/combat_timer_math.gd")
const Cases = preload("res://tests/helpers/p6_combat_observation_cases.gd")
const Forced = preload("res://scripts/resources/forced_poison_tick_effect.gd")
var failed := false
var checks: Array[Dictionary] = []
var witnesses := {}
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, label: String, value: Variant = null) -> void:
	checks.append({"passed": ok, "label": label, "actual": value})
	if not ok:
		failed = true
		printerr("FAILED: " + label + " " + str(value))
func target() -> Monster:
	var m := Monster.new()
	m.hp = 1000000
	return m
func attack(id: String = "test.attack", duration: int = 1000) -> Skill:
	var s := Skill.new()
	s.id = id
	s.base_execution_ms = duration
	s.min_execution_ms = duration
	var e := PhysicalDamageEffect.new()
	e.amount = 10.0
	s.effects = [e]
	return s
func player(flags: Array[String] = []) -> PlayerStats:
	var p := PlayerStats.new()
	p.poison_damage_per_tick = 10.0
	p.special_effects = {"legendary": {}}
	for flag in flags:
		p.special_effects.legendary[flag] = true
	return p
func records(r, kind: String) -> Array:
	return r.trace.records.filter(func(row): return row.kind == kind)
func run() -> void:
	baseline_differential()
	windows()
	preservation()
	live_poison()
	lightning()
	poison_lightning_gate()
	snapshot_hooks()
	guards()
	gold()
	FileAccess.open("res://reports/m9_t8_mechanics.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": not failed, "checks": checks, "count": checks.size(), "witnesses": witnesses}, "\t"))
	print("T8 mechanics " + ("FAIL" if failed else "PASS") + " checks=" + str(checks.size()))
	quit(1 if failed else 0)
func windows() -> void:
	for pair in [[1,2],[2,3],[3,4],[20000,26667],[30000,40000],[6917529027641081855,9223372036854775807]]:
		var w := TimerMath.fight_window(pair[0], true)
		check(w.error == "" and w.duration_ms == pair[1] and w.nominal_duration_ms == pair[0] and w.countdown_rate == 0.75, "checked exact Arctic endpoint", w)
	check(TimerMath.fight_window(6917529027641081856, true).error != "", "first overflowing Arctic nominal rejected")
	check(TimerMath.fight_window(0, false).error != "", "nonpositive rejected")
	check(TimerMath.fight_window(9223372036854775807, false).duration_ms == 9223372036854775807, "no Arctic preserves max integer")
	var p := player()
	p.legendary_arctic_mittens = true
	var r := CombatResolver.resolve([attack()], p, target(), 3000, 11, true)
	check(r.is_valid and r.duration_ms == 4000 and r.nominal_duration_ms == 3000 and r.cast_events.size() == 4, "resolve expands once, exact endpoint cast fits")
	check(r.cast_events[0].time_ms == 1000 and r.cast_events[3].time_ms == 4000, "cast clock remains normal")
	check(is_equal_approx(r.dps, r.total_damage / 4.0), "DPS denominator actual window")
	p.legendary_arctic_mittens = false
	check(r.duration_ms == 4000 and r.countdown_rate == 0.75, "recorded budgets frozen after equipment change")
	var baseline := CombatResolver.resolve([attack()], p, target(), 3000, 11, true)
	check(baseline.duration_ms == 3000 and baseline.countdown_rate == 1.0 and baseline.cast_events.size() == 3, "no Arctic baseline window")
func preservation() -> void:
	var add := attack("test.add", 100)
	add.poison_stacks_applied = 5
	add.category = Skill.Category.DEBUFF
	var strike := attack("skill.poison_strike", 100)
	strike.effects.clear()
	strike.effects.append(Forced.new())
	var p := player(["decrepit", "serpents_scales", "hands_of_the_lightning_lord", "coil"])
	p.death_pact_rank = 1
	p.critical_poison_enabled = true
	p.crit_chance = 1.0
	var seen_preserved := false
	var seen_paid := false
	var seen_repeat := false
	for seed_value in range(1, 101):
		var r := CombatResolver.resolve([add, strike], p, target(), 200, seed_value, true)
		check(r.is_valid, "Decrepit Scales resolve valid")
		var tick = r.tick_events[0]
		check(tick.legendary_fuel == 5 and tick.requested_stacks == 5 and tick.raw_damage == 50.0, "five-stack damage fuel independent of debit")
		check(tick.stacks_consumed == (0 if tick.stacks_preserved else 5), "entire cost preserved or paid once")
		if tick.stacks_preserved:
			seen_preserved = true
			check(records(r, "legendary_poison_consume").is_empty(), "preserved Consume grants no actual-consumption event")
			check(not records(r, "effect_lifecycle").any(func(row): return row.source_id in ["status.potency", "status.penetration"] and row.lifecycle_reason in ["granted", "refreshed", "replaced"]), "preserved Consume grants no Death Pact")
		else:
			seen_paid = true
			var grants := records(r, "effect_lifecycle").filter(func(row): return row.source_id in ["status.potency", "status.penetration"] and row.lifecycle_reason in ["granted", "refreshed", "replaced"])
			check(grants.size() == 2 and grants[0].payload.stacks_after == 5 and grants[1].payload.stacks_after == 5, "paid Decrepit actual Consume grants five each exactly once")
		for child in r.tick_events.slice(1):
			seen_repeat = true
			check(child.legendary_fuel == 5 and child.stacks_consumed == 0 and child.preservation_roll == -1.0 and child.origin_kind == "lightning_poison_repeat", "free repeat inherits fuel and never debits or rolls Scales")
			check(child.raw_damage >= 50.0, "free repeat freshly computes packet from live Consume buffs")
	check(seen_preserved and seen_paid and seen_repeat, "directed seeds cover paid preserved repeated packets")
	var partial := player(["serpents_scales"])
	partial.echoing_toxin_rank = 1
	add.poison_stacks_applied = 1
	var r := CombatResolver.resolve([add, strike], partial, target(), 200, 5, true)
	check(r.tick_events[0].requested_stacks == 2 and r.tick_events[0].legendary_fuel == 1 and r.tick_events[0].raw_damage == 10.0, "partial availability uses one fuel for two request")
	add.poison_stacks_applied = 0
	r = CombatResolver.resolve([add, strike], partial, target(), 200, 5, true)
	check(r.tick_events[0].legendary_fuel == 0 and r.tick_events[0].preservation_roll == -1.0 and not r.tick_events[0].is_crit, "empty original has no Scales or critical packet")
func lightning() -> void:
	var p := player(["hands_of_the_lightning_lord"])
	p.crit_chance = 1.0
	p.retrigger_chance = 0.3
	var outcomes := {}
	for seed_value in range(1, 201):
		var r := CombatResolver.resolve([attack()], p, target(), 1000, seed_value, true)
		var trials := records(r, "trigger_decision").filter(func(row): return row.cast_id == 1 and row.payload.has("roll"))
		check(trials.size() == 2, "root owns ordinary and independent Lightning candidates")
		check(r.trigger_candidates_evaluated == records(r, "trigger_decision").filter(func(row): return row.payload.has("roll")).size(), "failed and successful eligible Attack trials each spend candidate budget")
		if trials.size() != 2: continue
		check(trials[0].payload.candidate_origin == "random_repeat" and trials[1].payload.candidate_origin == "lightning_repeat", "ordinary subtree precedes Lightning sibling")
		var key := str(trials[0].payload.roll <= 0.3) + "/" + str(trials[1].payload.roll <= 0.2)
		outcomes[key] = true
		for event in r.cast_events:
			if event.origin_kind == "lightning_repeat": check(event.time_ms == 1000 and event.trigger_label == "RETRIGGER", "Lightning is full zero-windup Attack retrigger")
	check(outcomes.size() == 4, "independent trials produce all four immediate outcomes", outcomes)
	witnesses["independent_outcomes"] = outcomes
	var s := attack()
	var extra := PhysicalDamageEffect.new()
	extra.amount = 10.0
	s.effects.append(extra)
	p.retrigger_chance = 0.0
	var m := target()
	m.block = 100000.0
	var r := CombatResolver.resolve([s], p, m, 1000, 7, true)
	check(records(r, "trigger_decision").filter(func(row): return row.cast_id == 1 and row.payload.get("candidate_origin", "") == "lightning_repeat").size() == 1, "multiple critical contributions/full block yield one Lightning trial")
	var absent := player()
	var inactive := player(["hands_of_the_lightning_lord"])
	var a := CombatResolver.resolve([attack()], absent, target(), 2000, 45, true)
	var b := CombatResolver.resolve([attack()], inactive, target(), 2000, 45, true)
	check(a.rng_final_state == b.rng_final_state and a.total_damage == b.total_damage, "noncritical Lightning adds no RNG")
	p.legendary_signet = true
	r = CombatResolver.resolve([s], p, target(), 1000, 7, true)
	check(records(r, "trigger_decision").is_empty() and not r.cast_events[0].is_crit, "Signet suppresses critical Lightning trials")
func poison_lightning_gate() -> void:
	var saw_enabled_repeat := false
	for seed_value in range(1, 65):
		var p := player(["hands_of_the_lightning_lord"])
		p.critical_poison_enabled = true
		p.crit_chance = 1.0
		p.retrigger_chance = 0.0
		var r := CombatResolver.CombatResult.new()
		r.combat_rng = RandomNumberGenerator.new()
		r.combat_rng.seed = seed_value
		r.trace.enabled = true
		CombatResolver._resolve_poison_tick(r, 1000, 5, p, 0, 0.0, target(), 1000)
		check(r.tick_events.size() == 1 and records(r, "legendary_poison_repeat_trial").is_empty(), "Lightning alone cannot enable Poison retriggers")
		var baseline := CombatResolver.CombatResult.new()
		baseline.combat_rng = RandomNumberGenerator.new()
		baseline.combat_rng.seed = seed_value
		p.special_effects.legendary.erase("hands_of_the_lightning_lord")
		CombatResolver._resolve_poison_tick(baseline, 1000, 5, p, 0, 0.0, target(), 1000)
		check(r.combat_rng.state == baseline.combat_rng.state, "Coil-gated Lightning consumes no Poison trial RNG")
		p.special_effects.legendary["hands_of_the_lightning_lord"] = true
		p.special_effects.legendary["coil"] = true
		var enabled := CombatResolver.CombatResult.new()
		enabled.combat_rng = RandomNumberGenerator.new()
		enabled.combat_rng.seed = seed_value
		enabled.trace.enabled = true
		CombatResolver._resolve_poison_tick(enabled, 1000, 5, p, 0, 0.0, target(), 1000)
		var trials := records(enabled, "legendary_poison_repeat_trial")
		check(not trials.is_empty() and trials.all(func(row): return row.payload.candidate_origin == "lightning_poison_repeat" and row.payload.chance == 0.2), "Coil enables independent critical Poison trial without ordinary chance")
		check(p.retrigger_chance == 0.0, "Lightning does not add numeric Poison Retrigger Chance")
		saw_enabled_repeat = saw_enabled_repeat or enabled.tick_events.size() > 1
	check(saw_enabled_repeat, "Coil-gated critical Poison can repeat")

func guards() -> void:
	var p := player(["hands_of_the_lightning_lord", "coil"])
	p.crit_chance = 1.0
	p.critical_poison_enabled = true
	p.retrigger_chance = 1.0
	var add := attack("test.add", 100)
	add.poison_stacks_applied = 5
	var strike := attack("test.strike", 100)
	strike.effects.append(Forced.new())
	var r := CombatResolver.resolve([add, strike], p, target(), 200, 1, true)
	check(not r.is_valid and r.failure.code == "trigger_candidate_limit" and r.root_trigger_candidates == 1024, "shared Attack Poison candidate budget invalidates at 1024", r.failure)
	check(r.tick_events.any(func(t): return t.legendary_depth == 16) and not r.tick_events.any(func(t): return t.legendary_depth > 16), "Poison depth cutoff remains 16")
	check(records(r, "legendary_poison_repeat_trial").all(func(row): return row.payload.depth < 16), "depth cutoff performs no candidate/RNG")
	var root_id: int = r.failure.get("root_cast_id", 0)
	var attack_trials := records(r, "trigger_decision").filter(func(row): return row.root_cast_id == root_id and row.payload.has("roll"))
	var poison_trials := records(r, "legendary_poison_repeat_trial").filter(func(row): return row.root_cast_id == root_id)
	check(attack_trials.size() + poison_trials.size() == 1024 and not attack_trials.is_empty() and not poison_trials.is_empty(), "Attack and forced Poison share single 1024 root budget", [attack_trials.size(), poison_trials.size()])
func gold() -> void:
	var state = root.get_node("BuildState")
	state.reset()
	state.set_class(load("res://data/classes/rogue.tres"))
	var g := GearItem.new()
	g.id = "test.greeves"
	g.slot = GearItem.SlotType.LEGS
	g.legendary_effect_id = "golden_greeves"
	state.equipped_legs = g
	var r := CombatResolver.CombatResult.new()
	r.is_win = true
	for pair in [[99,0],[100,20],[499,80],[500,100],[900,100]]:
		r.overkill_damage = pair[0]
		check(state.overkill_gold_for_result(r) == pair[1] and state.overkill_gold_for_result(r) == pair[1], "Greeves fresh capped component is idempotent", pair)
	state.equipped_legs = null
	state.inventory.append(g)
	check(state.overkill_gold_for_result(r) == 50, "inventory ownership does not activate Greeves")
	r.is_valid = false
	check(state.overkill_gold_for_result(r) == 0, "invalid result grants no overkill reward")
	state.reset()
	state.set_class(load("res://data/classes/rogue.tres"))
	state.choose_current_tavern_encounter()
	state.equipped_legs = load("res://data/gear/golden_greeves.tres")
	state.run_phase = state.RunPhase.RESULT
	state.last_fight_won = true
	state.last_combat_result = CombatResolver.CombatResult.new()
	state.last_combat_result.is_win = true
	state.last_combat_result.overkill_damage = 500.0
	var preview: int = state.current_modified_reward_gold()
	check(preview == 224, "Greeves reward-time numeric modifier multiplies base12 plus capped100", preview)
	check(SaveSystem.save_run(state), "preclaim RESULT save accepted", SaveSystem.last_error)
	state.last_combat_result = null
	check(SaveSystem.load_run(state), "preclaim RESULT resumes", SaveSystem.last_error)
	check(state.current_modified_reward_gold() == preview and state.current_overkill_gold() == 100, "resumed reward recomputes from raw overkill once")
	check(state.last_combat_result == null, "reward-only resume does not manufacture zero-DPS combat replay")
	var payload := SaveSystem._serialize(state)
	payload.reward_result_basis.overkill_damage = -1.0
	check(not SaveSystem._valid_run_shapes(payload), "negative saved reward basis rejected")
	check(state.modified_gold_reward(140) == 280, "40 base plus100 Overkill with Greeves Increased Gold gives280")
	check(state.claim_current_reward(true), "deferred claim commits")
	var committed: int = state.committed_reward_gold
	state.equipped_legs = null
	check(committed == preview and state.committed_reward_gold == preview and state.gold == 0, "commit freezes prior to deferred payout/equipment change")
	state.add_gold(committed)
	check(not state.claim_current_reward(true) and state.gold == preview, "claim ownership prevents second payout transaction")
	check(SaveSystem.save_run(state) and SaveSystem.load_run(state) and state.gold == preview and not state.claim_current_reward(), "claimed reward roundtrip cannot grant twice")
	var older := SaveSystem._serialize(state)
	older.erase("reward_result_basis")
	check(SaveSystem.write_json(SaveSystem.save_path, older), "old current-version optional-basis fixture writes")
	state.last_combat_result = CombatResolver.CombatResult.new()
	state.last_combat_result.is_win = true
	state.last_combat_result.overkill_damage = 900.0
	state.reward_result_basis = {"is_valid": true, "is_win": true, "overkill_damage": 900.0}
	check(SaveSystem.load_run(state) and state.last_combat_result == null and state.reward_result_basis.is_empty(), "older optional-basis load clears stale result and reward evidence")
	state.reset()

func snapshot_hooks() -> void:
	# A forced Poison critical is independent from its noncritical parent Attack.
	var add := attack("test.poison_source", 100)
	add.category = Skill.Category.DEBUFF
	add.poison_stacks_applied = 5
	var strike := attack("test.forced", 100)
	strike.effects.append(Forced.new())
	var p := player(["hands_of_the_lightning_lord", "samurai", "cloak", "coil"])
	p.critical_poison_enabled = true
	p.crit_chance = 0.5
	p.readiness_enabled = true
	var saw_split := false
	var saw_attack_hook := false
	for seed_value in range(1, 201):
		var r := CombatResolver.resolve([add, strike], p, target(), 200, seed_value, true)
		var parent = r.cast_events.filter(func(e): return e.origin_kind == "macro" and e.skill.id == strike.id)[0]
		if not parent.is_crit and r.tick_events[0].is_crit:
			saw_split = true
			check(not records(r, "trigger_decision").any(func(row): return row.cast_id == parent.cast_id and row.payload.get("candidate_origin", "") == "lightning_repeat"), "forced Poison critical cannot arm noncritical parent")
		for e in r.cast_events:
			if e.origin_kind == "lightning_repeat":
				saw_attack_hook = true
				check(records(r, "legendary_buff_grant").any(func(row): return row.cast_id == e.cast_id and row.payload.kind == "meditation"), "Lightning Attack gains Samurai Meditation")
				check(records(r, "effect_lifecycle").any(func(row): return row.cast_id == e.cast_id and row.payload.effect_id == "readiness" and row.lifecycle_reason in ["granted", "refreshed"]), "Lightning Attack grants Readiness through normal finish hook")
		if r.tick_events.size() > 1 and r.cast_events.size() == 2:
			check(not records(r, "effect_lifecycle").any(func(row): return row.source_id == "skill.parry_strike" and row.lifecycle_reason in ["granted", "refreshed", "replaced"]), "Poison Lightning does not gain Attack Readiness")
	check(saw_split and saw_attack_hook, "seeds exercise separate Attack Poison own-crit/hook outcomes")
	p = player(["hands_of_the_lightning_lord"])
	p.crit_chance = 0.5
	p.retrigger_chance = 1.0
	var saw_critical_child := false
	for seed_value in range(1, 31):
		var r := CombatResolver.resolve([attack()], p, target(), 1000, seed_value, true)
		if not r.cast_events[0].is_crit and r.cast_events.any(func(e): return e.parent_cast_id == 1 and e.is_crit):
			saw_critical_child = true
			check(not records(r, "trigger_decision").any(func(row): return row.cast_id == 1 and row.payload.get("candidate_origin", "") == "lightning_repeat"), "critical ordinary descendant cannot arm noncritical parent")
	check(saw_critical_child, "seed witnesses descendant-own-crit separation")

func baseline_fields(event: RefCounted, fields: Array) -> Dictionary:
	var data := {}
	for field in fields:
		var value: Variant = event.get(field)
		data[field] = value.id if value is Skill else value
	return Cases._normalize(data)
func semantic_projection(r, baseline: Dictionary) -> Dictionary:
	var data := {"valid": r.is_valid, "failure": r.failure, "duration": r.duration_ms, "damage": r.total_damage,
		"health_removed": r.total_health_removed, "dps": r.dps, "win": r.is_win, "overkill": r.overkill_damage,
		"gold": r.gold_stolen, "cap": r.poison_stack_cap, "rng": r.rng_final_state, "candidates": r.trigger_candidates_evaluated,
		"casts": [], "ticks": []}
	for event in r.cast_events: data.casts.append(baseline_fields(event, baseline.cast_fields))
	for event in r.tick_events: data.ticks.append(baseline_fields(event, baseline.tick_fields))
	return data
func baseline_differential() -> void:
	var setup := Cases.setup()
	var baseline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/m9_t8_no_effect_baseline.json"))
	var rows: Array[Dictionary] = []
	for seed_text in baseline.seeds:
		var seed_value := int(seed_text)
		var r := CombatResolver.resolve(setup.rotation, setup.stats, setup.monster, 12000, seed_value, true)
		var digest := JSON.stringify(semantic_projection(r, baseline)).sha256_text()
		check(digest == baseline.seeds[seed_text], "pre-T8 exact original-field combat/RNG fixture", seed_value)
		rows.append({"seed": seed_value, "before": baseline.seeds[seed_text], "after": digest, "rng": r.rng_final_state})
	witnesses["pre_t8_differential"] = rows

func live_poison() -> void:
	var p := player(["serpents_scales", "coil"])
	p.retrigger_chance = 1.0
	p.critical_poison_enabled = true
	p.crit_chance = 1.0
	var r := CombatResolver.CombatResult.new()
	r.combat_rng = RandomNumberGenerator.new()
	r.combat_rng.seed = 7
	r.trace.enabled = true
	r.self_buffs.trace = r.trace
	check(r.self_buffs.grant("virulent_poison", 0, {}) == "", "Virulent live charge fixture")
	var expected := RandomNumberGenerator.new()
	expected.seed = 7
	var first_roll := expected.randf()
	CombatResolver._resolve_poison_tick(r, 1000, 1, p, 0, 0.0, target(), 1000)
	check(r.tick_events[0].preservation_roll == first_roll, "Scales draws exactly first before packet crit RNG")
	check(r.tick_events.size() == 17 and r.tick_events[16].legendary_depth == 16, "ordinary Poison repeats stop exactly at shared depth16")
	check(r.tick_events[0].charge_spends.size() == 1 and r.tick_events[0].charge_spends[0].after == 4, "original Poison spends Virulent even when preserved or paid")
	check(r.tick_events[4].charge_spends.size() == 1 and r.tick_events[4].charge_spends[0].after == 0 and r.tick_events[5].charge_spends.is_empty(), "free repeats spend live Virulent charges to exhaustion")
	check(r.tick_events[0].raw_damage == 20.0 and r.tick_events[5].raw_damage == 10.0, "repeats recalculate after live charge exhaustion")
	check(r.tick_events.slice(1).all(func(t): return t.stacks_consumed == 0 and t.preservation_roll == -1.0 and t.legendary_fuel == 1), "all free descendants inherit single original fuel without preservation RNG")
	check(records(r, "poison_tick").slice(1).all(func(row): return row.payload.parent_tick_sequence > 0), "Poison descendant packets retain direct packet-parent ancestry")
