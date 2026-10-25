extends SceneTree

const Cases = preload("res://tests/helpers/p6_combat_observation_cases.gd")
const Order = preload("res://scripts/systems/combat_event_order.gd")
const Trace = preload("res://scripts/systems/combat_event_trace.gd")
var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_compatibility_and_observation()
	_check_order_and_ancestry()
	_check_budget()
	_check_boundaries_and_payloads()
	print("P6 T2 ordering/diagnostics: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)


func check(condition: bool, label: String) -> void:
	if not condition:
		failed = true
		printerr("FAILED: " + label)


func _check_compatibility_and_observation() -> void:
	var fixtures: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/p6/t2_compatibility_signatures.json"))
	var setup := Cases.setup()
	for seed_text in fixtures:
		var seed_value := int(seed_text)
		var off := CombatResolver.resolve(setup.rotation, setup.stats, setup.monster, 12000, seed_value)
		var on := CombatResolver.resolve(setup.rotation, setup.stats, setup.monster, 12000, seed_value, true)
		var replay := CombatResolver.resolve(setup.rotation, setup.stats, setup.monster, 12000, seed_value, true)
		check(Cases.signature(off) == fixtures[seed_text], "pre-T2 signature seed " + seed_text)
		check(Cases.signature(on) == Cases.signature(off), "trace does not change outcome")
		check(on.rng_final_state == off.rng_final_state, "trace does not consume RNG")
		check(on.trace.records == replay.trace.records, "same-seed exact trace equality")
		check(off.trace.records.is_empty(), "trace off stores no detail")
		check(on.trace.counts == off.trace.counts and on.trace.sequence == off.trace.sequence, "trace off retains accounting")
		var previous_time := 0
		var previous_sequence := 0
		for row in on.trace.records:
			check(row.time_ms >= previous_time and row.sequence == previous_sequence + 1, "monotonic time/sequence including stun gaps")
			check(row.schema_version == 1, "event schema version")
			previous_time = row.time_ms
			previous_sequence = row.sequence
		var damage := 0.0
		var gold := 0
		for row in on.trace.records:
			if row.kind in ["cast_resolved", "poison_tick"]:
				damage += row.payload.damage
				gold += int(row.payload.get("gold_stolen", 0))
		check(is_equal_approx(damage, on.total_damage) and gold == on.gold_stolen, "trace contribution reconciliation")
		var playback := CombatPlayback.new()
		var played_sequences: Array[int] = []
		playback.event_callback = func(event): played_sequences.append(event.tick.sequence if event.is_tick else event.cast.sequence)
		playback.start(on)
		playback.skip()
		var expected_sequences: Array[int] = []
		for row in on.trace.records:
			if row.kind in ["cast_resolved", "poison_tick"]:
				expected_sequences.append(row.sequence)
		check(played_sequences == expected_sequences, "legacy playback agrees with execution stream")


func _skill(id: String) -> Skill:
	var skill := Skill.new()
	skill.id = id
	skill.base_execution_ms = 1000
	skill.min_execution_ms = 500
	var hit := PhysicalDamageEffect.new()
	hit.amount = 10.0
	skill.effects = [hit]
	return skill


func _trigger(skill: Skill, source: String) -> TriggeredSkillEffect:
	var trigger := TriggeredSkillEffect.new()
	trigger.skill = skill
	trigger.source_skill_ids = PackedStringArray([source])
	trigger.chance = 1.0
	return trigger


func _monster() -> Monster:
	var monster := Monster.new()
	monster.hp = 100000
	return monster


func _check_order_and_ancestry() -> void:
	var a := _skill("test.a")
	var b := _skill("test.b")
	var c := _skill("test.c")
	var d := _skill("test.d")
	var stats := PlayerStats.new()
	stats.triggered_skill_effects = [_trigger(b, a.id), _trigger(c, a.id), _trigger(d, b.id)]
	var result := CombatResolver.resolve([a], stats, _monster(), 1000, 3, true)
	check(result.cast_events.size() == 4, "four casts")
	var ids: Array[String] = []
	for event in result.cast_events:
		ids.append(event.skill.id)
	check(ids == [a.id, b.id, d.id, c.id], "depth-first authored candidate order")
	check(result.cast_events[2].parent_cast_id == result.cast_events[1].cast_id, "grandchild parent")
	check(result.cast_events[3].parent_cast_id == result.cast_events[0].cast_id, "sibling parent")
	for event in result.cast_events:
		check(event.root_cast_id == 1, "root ancestry")
	check(result.tick_events[0].sequence < result.cast_events[0].sequence, "natural tick precedes simultaneous hit")
	var endings: Array[String] = []
	for row in result.trace.records:
		if row.kind == "cast_end":
			endings.append(row.source_id)
	check(endings == [d.id, b.id, c.id, a.id], "post-subtree buff handoff order")
	stats.triggered_skill_effects.clear()
	stats.retrigger_chance = 1.0
	var repeated := CombatResolver.resolve([a], stats, _monster(), 1000, 3, true)
	check(repeated.cast_events[1].origin_kind == "random_repeat", "random repeat distinct from authored proc")
	check(repeated.is_valid and repeated.cast_events.size() == 17, "inherited depth guard unchanged")
	check(repeated.cast_events.back().retrigger_cap_reached, "depth suppression remains observable")
	var blocked := _monster()
	blocked.block = 100000.0
	var blocked_result := CombatResolver.resolve([a], PlayerStats.new(), blocked, 1000, 1, true)
	for row in blocked_result.trace.records:
		if row.kind == "cast_resolved":
			check(row.payload.connected and row.payload.damage == 0.0, "fully blocked hit remains connected")
	blocked.dodge_chance = 1.0
	var dodged := CombatResolver.resolve([a], PlayerStats.new(), blocked, 1000, 1, true)
	for row in dodged.trace.records:
		if row.kind == "cast_resolved":
			check(not row.payload.connected and row.payload.dodged, "dodge is not a connected hit")


func _check_budget() -> void:
	var source := _skill("test.source")
	var leaf := _skill("test.leaf")
	var stats := PlayerStats.new()
	var filtered := _trigger(leaf, "test.unmatched")
	for i in CombatResolver.MAX_TRIGGER_CANDIDATES_PER_ROOT:
		stats.triggered_skill_effects.append(filtered)
	var exact := CombatResolver.resolve([source], stats, _monster(), 2000, 9, true)
	check(exact.is_valid and exact.cast_events.size() == 2, "exact limit allowed and reset for next root")
	check(exact.trigger_candidates_evaluated == 2048, "filtered candidates count; per-root budget resets")
	stats.triggered_skill_effects.append(filtered)
	var off := CombatResolver.resolve([source], stats, _monster(), 3000, 9)
	var on := CombatResolver.resolve([source], stats, _monster(), 3000, 9, true)
	check(not on.is_valid and not on.is_win, "limit breach invalidates outcome")
	check(on.cast_events.size() == 1 and on.tick_events.size() == 1, "no later macro casts or tail ticks after failure")
	check(on.failure.evaluated == 1024 and on.failure.candidate_index == 1024, "first over-budget candidate not evaluated")
	check(on.failure == off.failure and on.rng_final_state == off.rng_final_state, "failure and RNG identical with trace off")
	check(on.trace.records.back().kind == "simulation_failed", "failure ends event stream")
	check(on.dps == 0.0 and on.overkill_damage == 0.0, "invalid partial totals cannot become scored results")
	check(CombatResultFormatter.format(on, _monster()).contains("Simulation stopped"), "Adventure diagnostic")
	check(CombatResultFormatter.format_practice(on, _monster()).contains("Simulation stopped"), "Practice diagnostic")
	stats.triggered_skill_effects.clear()
	for i in 32:
		stats.triggered_skill_effects.append(_trigger(leaf, source.id))
	var broad := CombatResolver.resolve([source], stats, _monster(), 1000, 9, true)
	check(not broad.is_valid and broad.trigger_candidates_evaluated == 1024, "shallow branching shares root budget")
	for event in broad.cast_events:
		check(event.retrigger_depth <= 1, "budget catches breadth without deep recursion")
	var state = root.get_node("BuildState")
	state.reset()
	state.gold = 77
	state.run_phase = state.RunPhase.FIGHTING
	var failures: Dictionary = state.encounter_failure_counts.duplicate(true)
	state.record_fight_result(on, _monster())
	check(state.last_combat_result == null and state.run_encounter_history.is_empty(), "invalid results excluded from history")
	check(state.cancel_invalid_fight(on), "invalid fight can return to planning")
	check(state.run_phase == state.RunPhase.PLANNING and state.run_outcome == state.RunOutcome.NONE, "invalid is neither victory nor defeat")
	check(state.gold == 77 and state.encounter_failure_counts == failures, "no rewards or retries consumed")
	check(not state.cancel_invalid_fight(exact), "valid result cannot use invalid recovery")
	state.reset()


func _check_boundaries_and_payloads() -> void:
	check(Order.available_at_cast_start(3000, 2999), "consume before expiry")
	check(Order.available_at_cast_start(3000, 3000), "Plunge consumes on expiry tick")
	check(not Order.available_at_cast_start(3000, 3001), "no consumption after expiry")
	check(not Order.expired_before_grant(3000, 2999), "refresh before expiry")
	check(Order.expired_before_grant(3000, 3000), "Quick Cut replaces on expiry tick")
	check(Order.expired_before_grant(3000, 3001), "grant replaces after expiry")
	var trace := Trace.new()
	trace.enabled = true
	var payload := {"before": {"stacks": 4}, "after": {"stacks": 0}}
	trace.record("effect_lifecycle", 3000, {"source_id": "test.footwork", "effect_instance_id": "effect:1", "lifecycle_reason": "consumed"}, payload)
	payload.before.stacks = 0
	check(trace.records[0].payload.before.stacks == 4, "trace snapshots nested payloads")
	check(trace.records[0].effect_instance_id == "effect:1" and trace.records[0].lifecycle_reason == "consumed", "lifecycle envelope available for T4")
