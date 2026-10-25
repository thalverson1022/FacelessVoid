extends "res://tests/p6_combat_ordering_test.gd"
## Resolver-level source-origin coverage, followed by inherited ordering checks.

func _initialize() -> void:
	super._initialize()

func _run() -> void:
	var attack := _skill("test.origin")
	var effect := _trigger(attack, attack.id)
	effect.source_origin_kinds = PackedStringArray(["macro"])
	var stats := PlayerStats.new()
	stats.triggered_skill_effects = [effect]
	var on := CombatResolver.resolve([attack], stats, _monster(), 1000, 7, true)
	var off := CombatResolver.resolve([attack], stats, _monster(), 1000, 7)
	var replay := CombatResolver.resolve([attack], stats, _monster(), 1000, 7, true)
	check(on.is_valid and on.cast_events.size() == 2, "macro-only self proc cannot recurse")
	check(on.cast_events[1].origin_kind == "proc", "chance-one authored self proc remains proc")
	check(on.trigger_candidates_evaluated == 2, "origin-filtered candidate counted")
	check(on.trace.records == replay.trace.records, "filtered replay equality")
	check(on.rng_final_state == off.rng_final_state and on.total_damage == off.total_damage, "filtered trace parity")
	var rejected := false
	for row in on.trace.records:
		if row.kind == "trigger_decision" and row.payload.reason == "origin_filtered":
			rejected = row.origin_kind == "proc" and not row.payload.has("roll")
	check(rejected, "origin rejection reports provenance without a roll")
	# Compare a rejected candidate with no candidate to prove filtering spends no RNG.
	effect.source_origin_kinds = PackedStringArray(["proc"])
	var filtered := CombatResolver.resolve([attack], stats, _monster(), 1000, 7, true)
	var plain := CombatResolver.resolve([attack], PlayerStats.new(), _monster(), 1000, 7, true)
	check(filtered.cast_events.size() == 1 and filtered.rng_final_state == plain.rng_final_state, "rejected macro consumes no proc RNG")
	# A nonempty unknown origin fails closed. Every rejection still consumes budget.
	effect.source_origin_kinds = PackedStringArray(["unknown"])
	for i in CombatResolver.MAX_TRIGGER_CANDIDATES_PER_ROOT:
		stats.triggered_skill_effects.append(effect)
	var limited := CombatResolver.resolve([attack], stats, _monster(), 1000, 7, true)
	check(not limited.is_valid and limited.failure.evaluated == 1024, "origin filters cannot bypass root budget")
	stats.triggered_skill_effects = [effect]
	effect.source_origin_kinds = PackedStringArray()
	var legacy := CombatResolver.resolve([attack], stats, _monster(), 1000, 7, true)
	check(legacy.cast_events.size() == 17 and legacy.is_valid, "empty origins preserve inherited depth-limited chain")
	# Random repeats are independently selectable, not confused with authored procs.
	var leaf := _skill("test.leaf")
	effect.skill = leaf
	effect.source_origin_kinds = PackedStringArray(["random_repeat"])
	stats.retrigger_chance = 1.0
	var random := CombatResolver.resolve([attack], stats, _monster(), 1000, 7, true)
	check(random.is_valid and random.cast_events[1].origin_kind == "random_repeat", "macro skips proc before random repeat")
	check(random.cast_events[2].skill.id == leaf.id and random.cast_events[2].parent_cast_id == random.cast_events[1].cast_id, "random-repeat-only child has correct parent")
	super._run()
