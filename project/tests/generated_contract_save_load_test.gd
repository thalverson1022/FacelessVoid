extends SceneTree
## Focused P4M7-T9 checks for generated active contract save/load boundaries
## and generated economy state preservation.

const SaveSystemScript := preload("res://scripts/systems/save_system.gd")
const ContractOfferSourceScript := preload("res://scripts/systems/contract_offer_source.gd")

var _failed := false


func _initialize() -> void:
	# This suite intentionally exercises the retained legacy save fixture registry.
	SaveSystem.registry_override = BuildContentRegistry.current()
	SaveSystemScript.save_path = "res://.test_generated_contract_save.json"
	SaveSystemScript.delete_save()

	var build_state = root.get_node("BuildState")
	build_state.reset()

	_check_generated_offer_round_trips(build_state)
	_check_accepted_generated_route_round_trips(build_state)
	_check_selected_generated_node_round_trips(build_state)
	_check_claimed_generated_reward_round_trips(build_state)
	_check_completed_generated_contract_loop_round_trips(build_state)
	_check_supported_version_mismatch_loads_with_notice(build_state)
	_check_unsupported_generated_schema_rejects_without_mutation(build_state)
	_check_missing_current_generated_node_rejects_without_mutation(build_state)

	SaveSystemScript.delete_save()
	SaveSystemScript.save_path = SaveSystemScript.SAVE_PATH
	build_state.reset()
	if not _failed:
		print("Generated contract save/load check: OK")
	quit(1 if _failed else 0)


func _check_generated_offer_round_trips(build_state) -> void:
	_start_generated_contract_offer(build_state)
	var before := _generated_state_signature(build_state)
	_round_trip(build_state)
	_require(build_state.pending_contract_offer(), "Expected loaded generated offer state to remain pending.")
	var after := _generated_state_signature(build_state)
	_require(before == after, "Expected generated offer state to round-trip without regenerating.")


func _check_accepted_generated_route_round_trips(build_state) -> void:
	_start_generated_contract_offer(build_state)
	_require(build_state.accept_contract_offer(), "Expected generated contract acceptance to succeed.")
	var before := _generated_state_signature(build_state)
	_round_trip(build_state)
	_require(build_state.run_phase == BuildState.RunPhase.CONTRACT_ROUTE, "Expected accepted generated route phase after load.")
	_require(build_state.current_route_node.node_type == ContractRouteNode.NodeType.START, "Expected accepted generated route to remain at start.")
	var after := _generated_state_signature(build_state)
	_require(before == after, "Expected accepted generated route to round-trip without regenerating.")


func _check_selected_generated_node_round_trips(build_state) -> void:
	_start_generated_contract_offer(build_state)
	_require(build_state.accept_contract_offer(), "Expected generated acceptance before node selection.")
	var selected: ContractRouteNode = build_state.current_route_node.next_nodes[0]
	var saved_payload := selected.generated_encounter_payload.duplicate(true)
	var saved_combat_preview := selected.combat_preview.duplicate(true)
	var saved_debug_preview := selected.debug_preview.duplicate(true)
	_require(build_state.choose_contract_route_node(selected), "Expected generated route node selection to succeed.")
	_require(build_state.current_route_node.monster != null, "Expected selected generated node to be combat-ready before save.")
	var before := _generated_state_signature(build_state)
	_round_trip(build_state)
	_require(build_state.run_phase == BuildState.RunPhase.PLANNING, "Expected selected generated node to load into planning.")
	_require(build_state.current_route_node.monster != null, "Expected selected generated node monster to be restored.")
	_require(build_state.current_route_node.duration_ms > 0, "Expected loaded selected generated node duration to be restored.")
	_require(
		_payload_signature(build_state.current_route_node.generated_encounter_payload) == _payload_signature(saved_payload),
		"Expected generated encounter payload preservation."
	)
	_require(
		_preview_signature(build_state.current_route_node.combat_preview) == _preview_signature(saved_combat_preview),
		"Expected combat preview preservation."
	)
	_require(
		_debug_preview_signature(build_state.current_route_node.debug_preview) == _debug_preview_signature(saved_debug_preview),
		"Expected debug preview preservation."
	)
	_require(before == _generated_state_signature(build_state), "Expected selected generated node to round-trip without regenerating.")


func _check_claimed_generated_reward_round_trips(build_state) -> void:
	_start_generated_contract_offer(build_state)
	_require(build_state.accept_contract_offer(), "Expected generated acceptance before reward claim.")
	var selected: ContractRouteNode = build_state.current_route_node.next_nodes[0]
	_require(build_state.choose_contract_route_node(selected), "Expected generated route node selection before reward claim.")
	_require(selected.reward != null, "Expected selected generated node reward before claim.")
	_require(selected.reward.generated_gear_choice_count > 0, "Expected selected generated node to offer generated gear choices.")
	build_state.run_phase = BuildState.RunPhase.RESULT
	build_state.run_outcome = BuildState.RunOutcome.FIGHT_WIN
	build_state.last_fight_won = true
	var expected_gold: int = build_state.gold + build_state.modified_gold_reward(selected.reward.gold_amount)
	var expected_talent_points: int = build_state.earned_talent_points + selected.reward.talent_points
	_require(build_state.claim_current_reward(), "Expected generated reward claim before save.")
	_require(build_state.gold == expected_gold, "Expected generated reward gold before save.")
	_require(build_state.earned_talent_points == expected_talent_points, "Expected generated reward talent points before save.")
	_require(build_state.claimed_route_reward_ids.has(selected.id), "Expected generated claimed reward ID before save.")
	_require(build_state.pending_reward_choices.size() == selected.reward.generated_gear_choice_count, "Expected generated reward choices before save.")
	_assert_generated_reward_choice_metadata(build_state.pending_reward_choices)
	var before := _generated_state_signature(build_state)
	var pending_before := _gear_list_signature(build_state.pending_reward_choices)
	var reward_before := _reward_signature(selected)
	_round_trip(build_state)
	_require(build_state.run_phase == BuildState.RunPhase.RESULT, "Expected generated reward result phase after load.")
	_require(build_state.run_outcome == BuildState.RunOutcome.FIGHT_WIN, "Expected generated reward win outcome after load.")
	_require(build_state.last_fight_won, "Expected generated reward win flag after load.")
	_require(build_state.current_route_node != null and build_state.current_route_node.id == selected.id, "Expected generated reward current node after load.")
	_require(build_state.has_claimed_current_reward(), "Expected generated claimed reward helper after load.")
	_require(not build_state.claim_current_reward(), "Expected generated reward duplicate claim to stay rejected after load.")
	_require(build_state.gold == expected_gold, "Expected generated reward gold after load.")
	_require(build_state.earned_talent_points == expected_talent_points, "Expected generated reward talent points after load.")
	_require(_gear_list_signature(build_state.pending_reward_choices) == pending_before, "Expected generated pending reward choices to round-trip.")
	_assert_generated_reward_choice_metadata(build_state.pending_reward_choices)
	_require(_reward_signature(build_state.current_route_node) == reward_before, "Expected generated materialized reward to round-trip after claim.")
	_require(before == _generated_state_signature(build_state), "Expected claimed generated reward state to round-trip without regenerating.")
	_require(build_state.skip_pending_reward_gear(), "Expected loaded generated pending reward choices to be skippable.")
	_require(build_state.continue_after_win(), "Expected loaded claimed generated reward to continue to route.")
	_require(build_state.run_phase == BuildState.RunPhase.CONTRACT_ROUTE, "Expected generated route phase after continuing loaded reward.")


func _check_completed_generated_contract_loop_round_trips(build_state) -> void:
	_start_generated_contract_offer(build_state)
	_require(build_state.accept_contract_offer(), "Expected generated acceptance before boss completion.")
	var boss := _advance_to_generated_boss(build_state)
	_require(boss != null and boss.node_type == ContractRouteNode.NodeType.BOSS, "Expected generated boss before completion save.")
	build_state.run_phase = BuildState.RunPhase.RESULT
	build_state.run_outcome = BuildState.RunOutcome.FIGHT_WIN
	build_state.last_fight_won = true
	_require(build_state.claim_current_reward(), "Expected generated boss reward claim before loop save.")
	if build_state.has_pending_reward_choice():
		_require(build_state.skip_pending_reward_gear(), "Expected generated boss reward choice skip before loop save.")
	_require(build_state.open_shop_round(), "Expected generated boss completion to open between-contract shop before save.")
	_assert_generated_shop_offer_metadata(build_state.shop_offers)
	var shop_signature := _gear_list_signature(build_state.shop_offers)
	_round_trip(build_state)
	_require(build_state.shop_round_pending, "Expected loaded between-contract shop to remain pending.")
	_require(build_state.run_phase == BuildState.RunPhase.RESULT, "Expected loaded completed boss to remain in result until shop closes.")
	_require(build_state.current_route_node != null and build_state.current_route_node.node_type == ContractRouteNode.NodeType.BOSS, "Expected loaded completed boss node.")
	_require(build_state.completed_contract_count == 0, "Expected completed count to wait until continuing after the shop.")
	_require(build_state.contract_offer_index == 0, "Expected offer index to wait until continuing after the shop.")
	_require(_gear_list_signature(build_state.shop_offers) == shop_signature, "Expected between-contract shop offers to round-trip.")
	_assert_generated_shop_offer_metadata(build_state.shop_offers)
	_require(build_state.close_shop_round(), "Expected loaded between-contract shop to close.")
	_require(build_state.continue_after_win(), "Expected loaded completed boss to advance to the next generated offer.")
	_require(build_state.completed_contract_count == 1, "Expected completed count after loaded loop continue.")
	_require(build_state.contract_offer_index == 1, "Expected offer index after loaded loop continue.")
	_require(build_state.run_phase == BuildState.RunPhase.CONTRACT_OFFER, "Expected generated offer after loaded loop continue.")
	_require(build_state.active_contract != null and build_state.active_contract.has_generated_route_state(), "Expected next loaded-loop contract to be generated.")
	_require(build_state.pending_contract_offers.size() == 3, "Expected next loaded-loop offer to contain generated choices.")
	var after_continue_signature := _generated_state_signature(build_state)
	_round_trip(build_state)
	_require(build_state.run_phase == BuildState.RunPhase.CONTRACT_OFFER, "Expected next generated offer to round-trip after completion.")
	_require(build_state.completed_contract_count == 1, "Expected completed count to round-trip after completion.")
	_require(build_state.contract_offer_index == 1, "Expected offer index to round-trip after completion.")
	_require(after_continue_signature == _generated_state_signature(build_state), "Expected next generated offer state to round-trip without regenerating.")


func _check_supported_version_mismatch_loads_with_notice(build_state) -> void:
	_start_generated_contract_offer(build_state)
	_require(SaveSystemScript.save_run(build_state), "Expected save before supported mismatch edit.")
	var data := _read_save_data()
	data["generated_active_contract"]["contract"]["generated_route_state"]["generator_version"] = "p4m6.test.old_generator"
	_write_save_data(data)
	build_state.reset()
	_require(SaveSystemScript.load_run(build_state), "Expected supported generated version mismatch to load.")
	_require(build_state.active_contract != null and build_state.active_contract.has_generated_route_state(), "Expected generated contract after mismatch load.")
	_require(
		_has_notice(SaveSystemScript.last_generated_load_notices, "generated_save_supported_mismatch:route_generator_version"),
		"Expected supported mismatch notice after load."
	)
	_require(
		_has_notice(build_state.active_contract.route_notices, "generated_save_supported_mismatch:route_generator_version"),
		"Expected mismatch notice on restored generated contract."
	)


func _check_unsupported_generated_schema_rejects_without_mutation(build_state) -> void:
	_start_generated_contract_offer(build_state)
	_require(SaveSystemScript.save_run(build_state), "Expected save before unsupported schema edit.")
	var data := _read_save_data()
	data["generated_active_contract"]["schema_version"] = SaveSystemScript.GENERATED_CONTRACT_SAVE_SCHEMA_VERSION + 1
	_write_save_data(data)
	build_state.reset()
	build_state.gold = 313
	build_state.run_phase = BuildState.RunPhase.RESULT
	_require(not SaveSystemScript.load_run(build_state), "Expected future generated save schema to reject.")
	_require(build_state.gold == 313, "Expected rejected load to leave live gold untouched.")
	_require(build_state.run_phase == BuildState.RunPhase.RESULT, "Expected rejected load to leave live phase untouched.")


func _check_missing_current_generated_node_rejects_without_mutation(build_state) -> void:
	_start_generated_contract_offer(build_state)
	_require(SaveSystemScript.save_run(build_state), "Expected save before missing-current edit.")
	var data := _read_save_data()
	data["generated_active_contract"]["current_route_node_id"] = "route.generated.missing"
	_write_save_data(data)
	build_state.reset()
	build_state.gold = 919
	_require(not SaveSystemScript.load_run(build_state), "Expected missing current generated node to reject.")
	_require(build_state.gold == 919, "Expected rejected missing-current load to leave live state untouched.")


func _round_trip(build_state) -> void:
	_require(SaveSystemScript.save_run(build_state), "Expected generated save_run to succeed.")
	build_state.reset()
	_require(SaveSystemScript.load_run(build_state), "Expected generated load_run to succeed.")


func _start_generated_contract_offer(build_state) -> void:
	build_state.reset()
	build_state.set_adventure_seed(424242)
	var context := ContractOfferSourceScript.offer_context(
		424242,
		0,
		0,
		-1,
		{"route_difficulty": "medium", "allowed_biomes": ["Graveyard"]},
		false,
		true
	)
	_require(build_state.start_contract_offer(context), "Expected generated-only contract offer to start.")
	_require(build_state.active_contract != null and build_state.active_contract.has_generated_route_state(), "Expected active generated contract.")
	_require(not build_state.pending_contract_offers.is_empty(), "Expected generated pending offers.")


func _advance_to_generated_boss(build_state) -> ContractRouteNode:
	while (
		build_state.current_route_node != null
		and build_state.current_route_node.node_type != ContractRouteNode.NodeType.BOSS
	):
		_require(not build_state.current_route_node.next_nodes.is_empty(), "Expected route choices before generated boss.")
		var next_node: ContractRouteNode = build_state.current_route_node.next_nodes[0]
		_require(build_state.choose_contract_route_node(next_node), "Expected generated route node choice on boss path.")
		if next_node.node_type == ContractRouteNode.NodeType.BOSS:
			return next_node
		build_state.run_phase = BuildState.RunPhase.RESULT
		build_state.run_outcome = BuildState.RunOutcome.FIGHT_WIN
		build_state.last_fight_won = true
		_require(build_state.claim_current_reward(), "Expected generated boss-path reward claim.")
		if build_state.has_pending_reward_choice():
			_require(build_state.skip_pending_reward_gear(), "Expected generated boss-path pending reward choice skip.")
		_require(build_state.continue_after_win(), "Expected generated boss-path route continue.")
	return build_state.current_route_node


func _generated_state_signature(build_state) -> String:
	var contract: ContractDef = build_state.active_contract
	_require(contract != null, "Expected active generated contract for signature.")
	var parts: PackedStringArray = []
	parts.append("phase:%d" % build_state.run_phase)
	parts.append("active:%s" % contract.id)
	parts.append("route:%s" % contract.generated_route_id)
	parts.append("seed:%d" % contract.source_seed)
	parts.append("generator:%s" % contract.generator_version)
	parts.append("template:%s" % contract.template_id)
	parts.append("template_label:%s" % contract.template_display_label)
	parts.append("template_width:%s" % _template_width_signature(contract.template_width_summary))
	parts.append("biome_table:%s" % contract.biome_table_version)
	parts.append("runtime_generator:%s" % contract.runtime_monster_generator_version)
	parts.append("library:%s" % contract.runtime_monster_archetype_library_version)
	parts.append("modifier_model:%s" % contract.modifier_model_version)
	parts.append("route_modifiers:%s" % JSON.stringify(contract.generated_modifiers))
	parts.append("route_modifier_ids:%s" % ",".join(Array(contract.generated_modifier_ids)))
	parts.append("current:%s" % _route_node_id(build_state.current_route_node))
	parts.append("pending:%d" % build_state.pending_contract_offers.size())
	parts.append("claimed:%s" % JSON.stringify(build_state.claimed_route_reward_ids))
	parts.append("completed_contract_count:%d" % build_state.completed_contract_count)
	parts.append("contract_offer_index:%d" % build_state.contract_offer_index)
	for node in _collect_nodes(contract.offer_node):
		parts.append("node:%s|%s|%d|%d|%s" % [
			_route_node_id(node),
			node.display_name,
			node.node_type,
			node.duration_ms,
			",".join(Array(node.outgoing_node_ids)),
		])
		parts.append("route_preview_name:%s" % String(node.route_preview.get("monster_name", "")))
		parts.append("route_preview_modifier:%s" % String(node.route_preview.get("modifier_label", "")))
		parts.append("route_preview_elite_variant:%s" % String(node.route_preview.get("elite_variant_label", "")))
		parts.append("route_preview_boss_variant:%s" % String(node.route_preview.get("boss_variant_label", "")))
		parts.append("node_modifiers:%s:%s" % [
			",".join(Array(node.generated_modifier_ids)),
			",".join(Array(node.generated_modifier_labels)),
		])
		parts.append("branch_intent:%s:%s" % [
			node.branch_intent,
			",".join(Array(node.branch_intent_tags)),
		])
		parts.append("elite_variant:%s:%s:%s" % [
			node.elite_variant_model_version,
			node.elite_variant_id,
			node.elite_variant_label,
		])
		parts.append("boss_variant:%s:%s:%s" % [
			node.boss_variant_model_version,
			node.boss_variant_id,
			node.boss_variant_label,
		])
		parts.append("reward:%s" % _reward_signature(node))
		parts.append("combat_preview:%s" % _preview_signature(node.combat_preview))
		parts.append("debug_preview:%s" % _debug_preview_signature(node.debug_preview))
		parts.append("payload:%s" % _payload_signature(node.generated_encounter_payload))
		parts.append("monster:%s" % (node.monster.display_name if node.monster != null else "none"))
	return "\n".join(parts)


func _payload_signature(payload: Dictionary) -> String:
	if payload.is_empty():
		return "{}"
	var draft := GeneratedMonsterDraft.from_dictionary(payload)
	_require(draft != null, "Expected generated payload to normalize.")
	return JSON.stringify({
		"id": draft.id,
		"display_name": draft.display_name,
		"hp": draft.hp,
		"duration_ms": draft.duration_ms,
		"source_seed": draft.source_seed,
		"route_pressure_scale": _pressure_scale_signature(payload.get("route_pressure_scale", {})),
		"route_pressure_axes": _pressure_axes_signature(payload.get("route_pressure_axes", {})),
		"route_modifier_ids": _string_array(payload.get("route_modifier_ids", [])),
		"node_modifier_ids": _string_array(payload.get("node_modifier_ids", [])),
		"modifier_model_version": String(payload.get("modifier_model_version", "")),
		"branch_intent": String(payload.get("branch_intent", "")),
		"branch_intent_tags": _string_array(payload.get("branch_intent_tags", [])),
		"elite_variant_model_version": String(payload.get("elite_variant_model_version", "")),
		"elite_variant_id": String(payload.get("elite_variant_id", "")),
		"elite_variant_label": String(payload.get("elite_variant_label", "")),
		"elite_variant_pressure_axis": String(payload.get("elite_variant_pressure_axis", "")),
		"boss_variant_model_version": String(payload.get("boss_variant_model_version", "")),
		"boss_variant_id": String(payload.get("boss_variant_id", "")),
		"boss_variant_label": String(payload.get("boss_variant_label", "")),
		"boss_variant_pressure_axis": String(payload.get("boss_variant_pressure_axis", "")),
		"archetype_ids": Array(draft.archetype_ids),
		"tags": Array(draft.tags),
		"defense_overrides": _normalized_number_dictionary(draft.defense_overrides),
		"selected_mechanic_ids": _selected_mechanic_ids(draft.selected_mechanics),
	})


func _template_width_signature(summary: Dictionary) -> String:
	var wide_node_ids := _string_array(summary.get("wide_node_ids", []))
	wide_node_ids.sort()
	var branch_node_ids := _string_array(summary.get("branch_node_ids", []))
	branch_node_ids.sort()
	return JSON.stringify({
		"max_width": int(summary.get("max_width", 0)),
		"wide_node_ids": wide_node_ids,
		"branch_node_ids": branch_node_ids,
		"requires_wide_choice": bool(summary.get("requires_wide_choice", false)),
	})


func _preview_signature(preview: Dictionary) -> String:
	return JSON.stringify({
		"monster_name": String(preview.get("monster_name", "")),
		"biome": String(preview.get("biome", "")),
		"difficulty": String(preview.get("difficulty", "")),
		"kind": String(preview.get("kind", "")),
		"elite_variant_label": String(preview.get("elite_variant_label", "")),
		"boss_variant_label": String(preview.get("boss_variant_label", "")),
		"defenses": JSON.stringify(_normalized_number_dictionary(preview.get("defense_overrides", {}))),
	})


func _reward_signature(node: ContractRouteNode) -> String:
	if node.reward == null:
		return "none"
	return JSON.stringify({
		"gold_amount": node.reward.gold_amount,
		"talent_points": node.reward.talent_points,
		"generated_gear_choice_count": node.reward.generated_gear_choice_count,
		"generated_gear_tier": node.reward.generated_gear_tier,
		"generated_gear_slots": node.reward.generated_gear_slots.duplicate(),
		"quality_label": node.reward_quality_label,
		"summary": node.reward_summary,
	})


func _gear_list_signature(items: Array[GearItem]) -> String:
	var parts: PackedStringArray = []
	for item in items:
		parts.append(_gear_signature(item))
	return "\n".join(parts)


func _gear_signature(item: GearItem) -> String:
	if item == null:
		return "none"
	var affix_parts: PackedStringArray = []
	for affix in item.affixes:
		affix_parts.append("%03d:%03d:%0.4f" % [affix.stat, affix.operation, affix.value])
	affix_parts.sort()
	return "%s|%s|%d|%d|%d|%d|%s|%s|%s" % [
		item.id,
		item.display_name,
		item.slot,
		item.tier,
		item.source_kind,
		item.source_seed,
		item.source_context,
		item.deterministic_key,
		",".join(affix_parts),
	]


func _assert_generated_reward_choice_metadata(items: Array[GearItem]) -> void:
	for item in items:
		_require(item.source_kind == GearItem.SourceKind.GENERATED, "Expected generated reward choice source kind.")
		_require(item.source_context.begins_with("reward_choice:route:"), "Expected generated reward choice source context.")
		_require(item.source_seed == 424242, "Expected generated reward choice source seed.")
		_require(item.deterministic_key.begins_with("gear.generated.reward_"), "Expected generated reward choice deterministic key.")


func _assert_generated_shop_offer_metadata(items: Array[GearItem]) -> void:
	for item in items:
		_require(item.source_kind == GearItem.SourceKind.GENERATED, "Expected generated shop offer source kind.")
		_require(item.source_context.begins_with("shop_offer:route:"), "Expected generated shop offer source context.")
		_require(item.source_seed == 424242, "Expected generated shop offer source seed.")
		_require(item.deterministic_key.begins_with("gear.generated.shop_"), "Expected generated shop offer deterministic key.")


func _debug_preview_signature(preview: Dictionary) -> String:
	return JSON.stringify({
		"source_seed": int(preview.get("source_seed", 0)),
		"raw_archetype_ids": preview.get("raw_archetype_ids", []),
		"route_pressure_scale": _pressure_scale_signature(preview.get("route_pressure_scale", {})),
		"route_pressure_axes": _pressure_axes_signature(preview.get("route_pressure_axes", {})),
		"node_modifier_ids": _string_array(preview.get("node_modifier_ids", [])),
		"node_modifier_labels": _string_array(preview.get("node_modifier_labels", [])),
		"modifier_model_version": String(preview.get("modifier_model_version", "")),
		"branch_intent": String(preview.get("branch_intent", "")),
		"branch_intent_tags": _string_array(preview.get("branch_intent_tags", [])),
		"elite_variant_model_version": String(preview.get("elite_variant_model_version", "")),
		"elite_variant_id": String(preview.get("elite_variant_id", "")),
		"elite_variant_label": String(preview.get("elite_variant_label", "")),
		"boss_variant_model_version": String(preview.get("boss_variant_model_version", "")),
		"boss_variant_id": String(preview.get("boss_variant_id", "")),
		"boss_variant_label": String(preview.get("boss_variant_label", "")),
		"selected_mechanics": _selected_mechanic_ids(preview.get("selected_mechanics", [])),
	})


func _pressure_scale_signature(value) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var scale: Dictionary = value
	return {
		"raw_difficulty_id": int(scale.get("raw_difficulty_id", 0)),
		"monster_difficulty_id": int(scale.get("monster_difficulty_id", 0)),
		"contract_pressure_tier": int(scale.get("contract_pressure_tier", 0)),
		"route_difficulty_base": int(scale.get("route_difficulty_base", 0)),
		"depth_bonus": int(scale.get("depth_bonus", 0)),
		"node_level_bonus": int(scale.get("node_level_bonus", 0)),
		"completed_contract_pressure_bonus": int(scale.get("completed_contract_pressure_bonus", 0)),
		"monster_level": String(scale.get("monster_level", "")),
		"monster_difficulty_cap": int(scale.get("monster_difficulty_cap", 0)),
	}


func _pressure_axes_signature(value) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var profile: Dictionary = value
	return {
		"primary": String(profile.get("primary", "")),
		"secondary": String(profile.get("secondary", "")),
		"axes": _string_array(profile.get("axes", [])),
		"source_archetype_ids": _string_array(profile.get("source_archetype_ids", [])),
	}


func _string_array(values) -> PackedStringArray:
	var result := PackedStringArray()
	if values is PackedStringArray:
		return values
	if values is Array:
		for value in values:
			result.append(String(value))
	return result


func _normalized_number_dictionary(value) -> Dictionary:
	var out := {}
	if typeof(value) != TYPE_DICTIONARY:
		return out
	var keys: Array = value.keys()
	keys.sort()
	for key in keys:
		out[String(key)] = float(value[key])
	return out


func _selected_mechanic_ids(mechanics) -> Array[String]:
	var ids: Array[String] = []
	if typeof(mechanics) != TYPE_ARRAY:
		return ids
	for mechanic in mechanics:
		if mechanic is Dictionary:
			ids.append(String(mechanic.get("id", "")))
	ids.sort()
	return ids


func _collect_nodes(root_node: ContractRouteNode) -> Array[ContractRouteNode]:
	var out: Array[ContractRouteNode] = []
	var visited := {}
	_collect_nodes_recursive(root_node, visited, out)
	return out


func _collect_nodes_recursive(node: ContractRouteNode, visited: Dictionary, out: Array[ContractRouteNode]) -> void:
	if node == null:
		return
	var node_id := _route_node_id(node)
	if node_id == "" or visited.has(node_id):
		return
	visited[node_id] = true
	out.append(node)
	for next_node in node.next_nodes:
		_collect_nodes_recursive(next_node, visited, out)


func _route_node_id(node: ContractRouteNode) -> String:
	if node == null:
		return ""
	return node.generated_node_id if node.generated_node_id != "" else node.id


func _has_notice(notices: PackedStringArray, prefix: String) -> bool:
	for notice in notices:
		if notice.begins_with(prefix):
			return true
	return false


func _read_save_data() -> Dictionary:
	var file := FileAccess.open(SaveSystemScript.save_path, FileAccess.READ)
	_require(file != null, "Expected save file to be readable.")
	var parsed = StrictSaveJson.read(file.get_as_text())["data"]
	file.close()
	_require(typeof(parsed) == TYPE_DICTIONARY, "Expected save JSON object.")
	return parsed


func _write_save_data(data: Dictionary) -> void:
	var file := FileAccess.open(SaveSystemScript.save_path, FileAccess.WRITE)
	_require(file != null, "Expected save file to be writable.")
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
	SaveSystemScript.delete_save()
	SaveSystemScript.save_path = SaveSystemScript.SAVE_PATH
