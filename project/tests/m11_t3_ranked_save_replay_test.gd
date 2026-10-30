extends SceneTree
## Current Adventure preparation roundtrip, compared as detached value snapshots.
var checks: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	assert(ok, label)
	checks.append(label)
# Script variables only: excludes Resource instance IDs, paths and editor metadata.
# Skills/effects/affixes become their authoritative fields recursively.
func snapshot(value: Variant) -> Variant:
	if value is Object:
		var fields := {}
		for property in value.get_property_list():
			if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				fields[property.name] = snapshot(value.get(property.name))
		return fields
	if value is Dictionary:
		var fields := {}
		for key in value: fields[key] = snapshot(value[key])
		return fields
	if value is Array:
		return value.map(snapshot)
	if value is PackedStringArray: return Array(value)
	return value
func result_snapshot(result: CombatResolver.CombatResult) -> Dictionary:
	return {"valid": result.is_valid, "failure": snapshot(result.failure),
		"casts": snapshot(result.cast_events), "ticks": snapshot(result.tick_events),
		"total_damage": result.total_damage, "health_removed": result.total_health_removed,
		"dps": result.dps, "win": result.is_win, "overkill": result.overkill_damage,
		"gold_stolen": result.gold_stolen, "duration": result.duration_ms,
		"nominal_duration": result.nominal_duration_ms, "countdown_rate": result.countdown_rate,
		"rng_final_state": result.rng_final_state, "trigger_candidates": result.trigger_candidates_evaluated,
		"root_candidates": result.root_trigger_candidates, "active_decay": result.active_decay_stacks,
		"legendary_buffs": snapshot(result.legendary_buffs), "trace": snapshot(result.trace)}
func input_snapshot(state) -> Dictionary:
	return {"preparation": snapshot(SaveSystem._serialize(state)), "stats": snapshot(state.current_player_stats()),
		"target": snapshot(state.current_target_monster()), "duration": state.current_target_duration_ms(),
		"seed": state.current_combat_rng_seed(), "rotation": snapshot(state.rotation)}
func resolve(state, seed: int) -> CombatResolver.CombatResult:
	return CombatResolver.resolve(state.rotation, state.current_player_stats(), state.current_target_monster(), state.current_target_duration_ms(), seed, true)
func run() -> void:
	var paths := SevenSlotSaveBoundary.paths()
	if paths.size() != 5:
		quit(1)
		return
	var distinct := {}
	for path in paths.values():
		if not String(path).begins_with("res://reports/"):
			quit(1)
			return
		distinct[path] = true
	check(distinct.size() == 5, "five distinct isolated paths")
	check(SevenSlotSaveBoundary.ensure_ready(), "isolated epoch ready")
	var state = root.get_node("BuildState")
	state.reset()
	SaveSystem.session_only = false
	var registry := BuildContentRegistry.adventure()
	check(registry.error == "", "current Adventure registry valid")
	state.set_class(registry.classes["class.rogue"])
	state.add_talent_points(1)
	check(state.configure_ranked_build(registry.trees["tree.shadow"]), "legal ranked Shadow primary")
	check(state.select_talent(registry.talents["talent.shadow.coated_weapons"]), "legal Coated Weapons rank1")
	state.adventure_seed = 812349
	state.current_encounter_index = 2
	check(state.choose_current_tavern_encounter(), "current Tavern encounter selected")
	state.encounter_retry_counts = {"encounter:2": 1}
	state.gold = 61
	for slot in GearItem.universal_slot_order():
		var item: GearItem
		if slot == GearItem.SlotType.WEAPON:
			item = load("res://data/gear/mithril_karambit.tres")
		else:
			var key := "m11.t3.slot.%d" % slot
			var generated := GearGenerator.generate_from_request({"slot": slot, "tier": GearItem.Tier.MASTER,
				"id": key, "deterministic_key": key, "source_context": "m11_t3_ranked_replay", "source_seed": 94831 + slot,
				"value_scale": 1.0, "contract_depth": 2})
			check(generated.ok, "legal generated slot %d" % slot)
			item = generated.item
		state.set("equipped_" + GearItem.SlotType.keys()[slot].to_lower(), item)
	var authored_rotation: Array[Skill] = [load("res://data/skills/stab.tres"), load("res://data/skills/heavy_slash.tres")]
	state.set_rotation(authored_rotation)
	check(state.rotation.size() == 2 and state.equipped_gear().size() == 7, "authored rotation and full7 equipped")
	var before := input_snapshot(state)
	var seed: int = state.current_combat_rng_seed()
	check(seed == RunRng.seed_for_context(state.adventure_seed, RunRng.CONTEXT_COMBAT, ["encounter:2", 1]), "effective seed uses saved encounter retry context")
	check(seed != RunRng.seed_for_context(state.adventure_seed, RunRng.CONTEXT_COMBAT, ["encounter:2", 0]), "retry1 effective seed differs from retry0")
	var first := resolve(state, seed)
	check(first.is_valid, "before-save result valid")
	check(not first.cast_events.is_empty() and not first.tick_events.is_empty(), "fixture exercises casts and poison ticks")
	var signature := result_snapshot(first)
	var original_hands: GearItem = state.equipped_hands
	var original_affix: StatModifier = original_hands.affixes[0]
	check(SaveSystem.save_run(state), "real SaveSystem write: " + SaveSystem.last_error)
	check(SaveSystem.has_save(), "saved legal current envelope accepted")
	var bytes := FileAccess.get_file_as_bytes(SaveSystem.save_path)
	# Keep only value snapshots for comparison. Reset live preparation and mutate a
	# former generated resource so aliases cannot conceal a failed restoration.
	state.reset()
	original_affix.value += 123.0
	check(SaveSystem.load_run_result(state).status == "loaded", "current Adventure validator load")
	check(state.equipped_hands != original_hands and state.equipped_hands.affixes[0] != original_affix, "generated resources detached on load")
	check(state.encounter_retry_counts.get("encounter:2") == 1, "current encounter retry1 restored")
	var after := input_snapshot(state)
	check(before == after, "exact preparation stats target duration effective seed and rotation restored")
	check(bytes == FileAccess.get_file_as_bytes(SaveSystem.save_path), "load preserves serialized bytes")
	var restored := resolve(state, state.current_combat_rng_seed())
	var repeated := resolve(state, state.current_combat_rng_seed())
	check(restored.is_valid and repeated.is_valid, "restored and repeated results valid")
	check(signature == result_snapshot(restored), "ordered full cast tick status proc RNG and totals equal after load")
	check(signature == result_snapshot(repeated), "repeated current resolution equal")
	# Negative controls prove comparison sees real authoritative differences.
	var altered := signature.duplicate(true)
	altered.casts[0].time_ms += 1
	check(signature != altered, "signature detects altered ordered cast timing")
	altered = signature.duplicate(true)
	altered.ticks[0].damage += 1.0
	check(signature != altered, "signature detects altered poison tick")
	var different := resolve(state, seed + 1)
	check(different.is_valid, "single different-seed result valid")
	var different_signature := result_snapshot(different)
	check(signature.casts != different_signature.casts or signature.ticks != different_signature.ticks, "single different seed changes authoritative event outcome")
	check(SaveSystem.write_json("res://reports/m11_t3_ranked_save_replay_witness.json", {
		"checks": checks, "before": before, "after": after, "effective_seed": seed, "different_seed": seed + 1,
		"registry_revision": registry.revision, "loaded_registry_revision": SaveSystem.registry().revision,
		"seven_gear_ids": state.equipped_gear().map(func(item): return item.id),
		"signature_sha256": JSON.stringify(signature, "", true, true).sha256_text(),
		"different_signature_sha256": JSON.stringify(different_signature, "", true, true).sha256_text(),
		"signature": signature, "different_signature": different_signature,
		"scope": "Current ranked Adventure preparation persistence and resolver replay; no power-loss durability or all-build claim."}), "write detailed witness")
	state.reset()
	print("M11 T3 ranked save replay PASS (%d checks)" % checks.size())
	quit()

