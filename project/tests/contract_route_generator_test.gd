extends SceneTree
## Focused P4M5 check for seeded procedural contract route graphs and generated
## encounter assignment.
## Run with:
##   godot --headless --path project -s res://tests/contract_route_generator_test.gd

const ROUTE_GENERATOR := preload("res://scripts/systems/contract_route_generator/contract_route_generator.gd")


func _initialize() -> void:
	_check_same_seed_and_settings_repeat()
	_check_different_seeds_vary_output()
	_check_generated_route_metadata()
	_check_graph_constraints_across_seed_sample()
	_check_shape_pacing_constraints_across_seed_sample()
	_check_outgoing_ids_match_next_nodes()
	_check_generated_encounter_payloads_exist()
	_check_generated_rewards_follow_table()
	_check_pressure_scales_by_depth_role_and_completed_contracts()
	_check_blended_contract_progression_promotes_content_by_role()
	_check_contract_hp_scaling_curve()
	_check_contract_block_scaling_curve()
	_check_contract_absorb_scaling_curve()
	_check_early_contract_mechanic_guardrails()
	_check_contract_pressure_overflow_is_materialized()
	_check_anti_snowball_validation_notices()
	_check_pressure_axes_are_materialized()
	_check_p4m8_archetypes_are_route_reachable_with_axes()
	_check_dead_run_axis_validation_notices()
	_check_sparse_generated_previews_exist()
	_check_p4m8_presentation_pool_targets()
	_check_biome_presentation_tables_are_used()
	_check_captain_presentation_promotes_normal_names_without_duplicates()
	_check_presentation_identity_does_not_change_mechanics()
	_check_malformed_graphs_report_shape_errors()

	print("Contract route generator check: OK")
	quit()


func _check_same_seed_and_settings_repeat() -> void:
	var settings := {"allowed_biomes": ["Swamp", "Cave"], "route_difficulty": "medium"}
	var first: ContractDef = ROUTE_GENERATOR.generate(4242, settings)
	var second: ContractDef = ROUTE_GENERATOR.generate(4242, settings)

	_assert_no_notices(ROUTE_GENERATOR.validate(first), "same seed first")
	_assert_no_notices(ROUTE_GENERATOR.validate(second), "same seed second")
	assert(ROUTE_GENERATOR.graph_signature(first) == ROUTE_GENERATOR.graph_signature(second))


func _check_different_seeds_vary_output() -> void:
	var signatures := {}
	for seed in [101, 202, 303, 404, 505, 606]:
		var contract: ContractDef = ROUTE_GENERATOR.generate(seed)
		_assert_no_notices(ROUTE_GENERATOR.validate(contract), "seed variation %d" % seed)
		signatures[ROUTE_GENERATOR.graph_signature(contract)] = true
	assert(signatures.size() >= 2)


func _check_generated_route_metadata() -> void:
	var contract: ContractDef = ROUTE_GENERATOR.generate(777, {
		"allowed_biomes": ["Graveyard"],
		"route_difficulty": "hard",
		"min_path_length": 3,
		"max_path_length": 6,
	})

	assert(contract is ContractDef)
	assert(contract.has_generated_route_state())
	assert(contract.generated_route_id.begins_with("route.generated_"))
	assert(contract.source_seed == 777)
	assert(contract.generator_version == ROUTE_GENERATOR.GENERATOR_VERSION)
	assert(contract.route_difficulty == "hard")
	assert(contract.selected_biome == "Graveyard")
	assert(Array(contract.allowed_biomes) == ["Graveyard"])
	assert(contract.biome_table_version == ROUTE_GENERATOR.PRESENTATION_TABLE_VERSION)
	assert(contract.runtime_monster_generator_version == RuntimeMonsterGenerator.GENERATOR_VERSION)
	assert(contract.runtime_monster_archetype_library_version == RuntimeArchetypeLibraryLoader.EXPECTED_SCHEMA)
	assert(contract.template_id == contract.route_settings["template_id"])
	assert(contract.template_display_label == contract.route_settings["template_display_label"])
	assert(not contract.template_width_summary.is_empty())
	assert(int(contract.template_width_summary["max_width"]) >= 3)
	assert(contract.route_settings["template_id"] != "")
	assert(Array(contract.route_notices)[0].begins_with("template:"))


func _check_graph_constraints_across_seed_sample() -> void:
	for seed in range(20, 40):
		var contract: ContractDef = ROUTE_GENERATOR.generate(seed)
		var notices: PackedStringArray = ROUTE_GENERATOR.validate(contract)
		_assert_no_notices(notices, "graph constraints %d" % seed)

		var nodes := _nodes(contract)
		assert(nodes.size() >= 5)
		assert(nodes[0].node_type == ContractRouteNode.NodeType.START)
		assert(nodes[0].generated_node_id == "start")
		assert(nodes[nodes.size() - 1].node_type == ContractRouteNode.NodeType.BOSS)
		assert(nodes[nodes.size() - 1].generated_node_id == "boss")
		assert(_count_type(nodes, ContractRouteNode.NodeType.START) == 1)
		assert(_count_type(nodes, ContractRouteNode.NodeType.BOSS) == 1)
		assert(_path_count(nodes[0], nodes[nodes.size() - 1], {}) >= 2)
		assert(_max_width(nodes) >= 3)
		for node in nodes:
			assert(node.has_generated_state())
			assert(node.generated_node_id != "")
			assert(node.depth >= 0)
			assert(node.lane >= 0)
			if node.node_type == ContractRouteNode.NodeType.BOSS:
				assert(node.next_nodes.is_empty())
			else:
				assert(not node.next_nodes.is_empty())
			for next_node in node.next_nodes:
				assert(next_node.depth > node.depth)


func _check_shape_pacing_constraints_across_seed_sample() -> void:
	for seed in range(100, 130):
		var contract: ContractDef = ROUTE_GENERATOR.generate(seed)
		var notices: PackedStringArray = ROUTE_GENERATOR.validate(contract)
		_assert_no_notices(notices, "shape pacing %d" % seed)

		var paths := _paths(contract)
		assert(paths.size() >= 2)
		var shortest := 999
		var longest := 0
		for path in paths:
			var length: int = path.size() - 1
			shortest = mini(shortest, length)
			longest = maxi(longest, length)
			assert(length >= int(contract.route_settings["min_path_length"]))
			assert(length <= int(contract.route_settings["max_path_length"]))
			assert(not _has_back_to_back_elites(path))
		assert(shortest <= int(contract.route_settings["shortest_path_max"]))
		assert(longest >= int(contract.route_settings["longest_path_min"]))
		assert(_elite_count(_shortest_path(paths)) <= 1)


func _check_outgoing_ids_match_next_nodes() -> void:
	var contract: ContractDef = ROUTE_GENERATOR.generate(9090)
	for node in _nodes(contract):
		var expected := []
		for next_node in node.next_nodes:
			expected.append(next_node.generated_node_id)
		assert(Array(node.outgoing_node_ids) == expected)


func _check_generated_encounter_payloads_exist() -> void:
	var contract: ContractDef = ROUTE_GENERATOR.generate(9911)
	var seen_seeds := {}
	for node in _nodes(contract):
		if node.node_type == ContractRouteNode.NodeType.START:
			assert(node.generated_encounter_payload.is_empty())
			assert(node.combat_preview.is_empty())
			assert(node.debug_preview.is_empty())
			continue

		assert(not node.generated_encounter_payload.is_empty())
		assert(not node.combat_preview.is_empty())
		assert(not node.debug_preview.is_empty())
		assert(String(node.generated_encounter_payload.get("id", "")) != "")
		assert(int(node.generated_encounter_payload.get("source_seed", 0)) > 0)
		assert(not seen_seeds.has(node.generated_encounter_payload["source_seed"]))
		seen_seeds[node.generated_encounter_payload["source_seed"]] = true
		assert(not (node.generated_encounter_payload.get("archetype_ids", []) as Array).is_empty())
		assert(not (node.generated_encounter_payload.get("selected_mechanics", []) as Array).is_empty())
		assert(not (node.generated_encounter_payload.get("defense_overrides", {}) as Dictionary).is_empty())
		assert((node.generated_encounter_payload.get("budget_metadata", {}) as Dictionary).has("budget"))
		assert((node.generated_encounter_payload.get("pressure_metadata", {}) as Dictionary).has("status"))
		assert((node.generated_encounter_payload.get("route_pressure_scale", {}) as Dictionary).has("raw_difficulty_id"))
		assert((node.generated_encounter_payload.get("route_pressure_axes", {}) as Dictionary).has("primary"))
		assert(node.debug_preview["source_seed"] == node.generated_encounter_payload["source_seed"])
		assert(node.debug_preview["raw_archetype_ids"] == node.generated_encounter_payload["archetype_ids"])
		assert(node.combat_preview["defense_overrides"] == node.generated_encounter_payload["defense_overrides"])
		assert(node.debug_preview["route_pressure_scale"] == node.generated_encounter_payload["route_pressure_scale"])
		assert(node.debug_preview["route_pressure_axes"] == node.generated_encounter_payload["route_pressure_axes"])

		var input: Dictionary = node.generated_encounter_payload["source_input"]
		var scale: Dictionary = node.generated_encounter_payload["route_pressure_scale"]
		assert(input["generator_version"] == RuntimeMonsterGenerator.GENERATOR_VERSION)
		assert(input["library_schema"] == RuntimeArchetypeLibraryLoader.EXPECTED_SCHEMA)
		assert(input["monster_kind"] == _expected_combat_kind(node))
		assert(int(input["difficulty_id"]) == int(scale["monster_difficulty_id"]))
		assert(int(scale["content_difficulty_id"]) >= int(scale["effective_contract_difficulty_id"]))
		assert(int(scale["contract_progression_stage"]) >= 1)
		if node.node_type == ContractRouteNode.NodeType.BOSS:
			assert(int(input["difficulty_id"]) >= 3)


func _check_generated_rewards_follow_table() -> void:
	var medium: ContractDef = ROUTE_GENERATOR.generate(9911, {"route_difficulty": "medium"})
	var hard: ContractDef = ROUTE_GENERATOR.generate(9911, {"route_difficulty": "hard", "completed_contract_count": 2})
	var medium_rewards := _reward_signatures(medium)
	var medium_repeat := _reward_signatures(ROUTE_GENERATOR.generate(9911, {"route_difficulty": "medium"}))
	var hard_rewards := _reward_signatures(hard)
	assert(medium_rewards == medium_repeat)
	assert(medium_rewards != hard_rewards)

	var elite_contract: ContractDef = null
	for seed in range(9900, 9930):
		var candidate: ContractDef = ROUTE_GENERATOR.generate(seed, {"route_difficulty": "medium"})
		if _first_node_of_type(candidate.offer_node, ContractRouteNode.NodeType.ELITE) != null:
			elite_contract = candidate
			break
	assert(elite_contract != null)

	var normal_seen := false
	var captain_seen := false
	var elite_seen := false
	var boss_seen := false
	for node in _nodes(elite_contract):
		if node.node_type == ContractRouteNode.NodeType.START:
			assert(node.reward == null)
			continue
		assert(node.reward != null)
		assert(node.reward.gold_amount > 0)
		assert(node.reward.generated_gear_choice_count > 0)
		assert(not node.reward.generated_gear_slots.is_empty())
		assert(node.reward_quality_label != "")
		assert(node.reward_summary != "")
		assert(node.reward_summary.contains("gear choice"))
		match node.node_type:
			ContractRouteNode.NodeType.FIGHT:
				normal_seen = true
				assert(node.reward.generated_gear_choice_count == 2)
				assert(node.reward.talent_points == 0)
				assert(node.reward_quality_label == "Steady")
			ContractRouteNode.NodeType.CAPTAIN:
				captain_seen = true
				assert(node.reward.generated_gear_choice_count == 2)
				assert(node.reward.talent_points == 0)
				assert(node.reward.gold_amount >= 8)
				assert(node.reward_quality_label == "Captain")
			ContractRouteNode.NodeType.ELITE:
				elite_seen = true
				assert(node.reward.talent_points == 0)
				assert(node.reward.generated_gear_choice_count == 2)
				assert(node.reward.gold_amount >= 11)
				assert(node.reward_quality_label == "Elite")
			ContractRouteNode.NodeType.BOSS:
				boss_seen = true
				assert(node.reward.generated_gear_choice_count == 2)
				assert(node.reward.talent_points == BuildProgression.CONTRACT_POINTS)
				assert(node.reward.generated_gear_tier >= GearItem.Tier.MASTER)
				assert(node.reward_quality_label == "Contract Victory")
	assert(normal_seen)
	assert(captain_seen)
	assert(elite_seen)
	assert(boss_seen)

	var medium_boss := _first_node_of_type(medium.offer_node, ContractRouteNode.NodeType.BOSS)
	var hard_boss := _first_node_of_type(hard.offer_node, ContractRouteNode.NodeType.BOSS)
	assert(hard_boss.reward.gold_amount > medium_boss.reward.gold_amount)
	assert(hard_boss.reward.generated_gear_tier >= medium_boss.reward.generated_gear_tier)

	var near_cap: ContractDef = ROUTE_GENERATOR.generate(9911, {"route_difficulty": "medium", "earned_talent_points": BuildProgression.POINT_CAP - 1})
	var capped: ContractDef = ROUTE_GENERATOR.generate(9911, {"route_difficulty": "medium", "earned_talent_points": ROUTE_GENERATOR.TALENT_POINT_REWARD_CAP})
	var near_cap_boss := _first_node_of_type(near_cap.offer_node, ContractRouteNode.NodeType.BOSS)
	var capped_boss := _first_node_of_type(capped.offer_node, ContractRouteNode.NodeType.BOSS)
	assert(near_cap_boss.reward.talent_points == 1)
	assert(near_cap_boss.reward_summary.contains("1 talent point"))
	assert(capped_boss.reward.talent_points == 0)
	assert(not capped_boss.reward_summary.contains("talent point"))


func _check_pressure_scales_by_depth_role_and_completed_contracts() -> void:
	var contract: ContractDef = ROUTE_GENERATOR.generate(4242, {"route_difficulty": "easy"})
	var shallow_normal: ContractRouteNode = null
	var deeper_normal: ContractRouteNode = null
	var captain_node: ContractRouteNode = null
	var elite: ContractRouteNode = null
	var boss: ContractRouteNode = null
	for node in _nodes(contract):
		match node.node_type:
			ContractRouteNode.NodeType.FIGHT:
				if shallow_normal == null or node.depth < shallow_normal.depth:
					shallow_normal = node
				if deeper_normal == null or node.depth > deeper_normal.depth:
					deeper_normal = node
			ContractRouteNode.NodeType.CAPTAIN:
				captain_node = node
			ContractRouteNode.NodeType.ELITE:
				elite = node
			ContractRouteNode.NodeType.BOSS:
				boss = node
	assert(shallow_normal != null)
	assert(deeper_normal != null)
	assert(boss != null)
	assert(_payload_difficulty(deeper_normal) >= _payload_difficulty(shallow_normal))
	assert(deeper_normal.reward.gold_amount >= shallow_normal.reward.gold_amount)
	assert(boss.reward.gold_amount > deeper_normal.reward.gold_amount)
	assert(boss.reward.generated_gear_tier >= deeper_normal.reward.generated_gear_tier)
	if captain_node != null:
		var comparable_normal_for_captain := _normal_at_or_after_depth(contract, captain_node.depth)
		if comparable_normal_for_captain != null:
			assert(_payload_difficulty(captain_node) >= _payload_difficulty(comparable_normal_for_captain))
			assert(captain_node.reward.gold_amount >= comparable_normal_for_captain.reward.gold_amount)
	if elite != null:
		var comparable_normal := _normal_at_or_after_depth(contract, elite.depth)
		assert(comparable_normal != null)
		assert(_payload_difficulty(elite) >= _payload_difficulty(comparable_normal))
		assert(elite.reward.gold_amount > comparable_normal.reward.gold_amount)
		assert(elite.reward.generated_gear_choice_count == comparable_normal.reward.generated_gear_choice_count)
		assert(elite.reward.generated_gear_choice_count == 2)

	var early_contract: ContractDef = ROUTE_GENERATOR.generate(5151, {
		"route_difficulty": "medium",
		"completed_contract_count": 0,
	})
	var later_contract: ContractDef = ROUTE_GENERATOR.generate(5151, {
		"route_difficulty": "medium",
		"completed_contract_count": 3,
	})
	var early_nodes := _nodes_by_id(early_contract)
	var later_nodes := _nodes_by_id(later_contract)
	for node_id in early_nodes:
		var early_node: ContractRouteNode = early_nodes[node_id]
		var later_node: ContractRouteNode = later_nodes[node_id]
		if early_node.node_type == ContractRouteNode.NodeType.START:
			continue
		assert(_payload_difficulty(later_node) >= _payload_difficulty(early_node))
		assert(later_node.reward.gold_amount >= early_node.reward.gold_amount)
		assert(later_node.reward.generated_gear_tier >= early_node.reward.generated_gear_tier)
	assert(ROUTE_GENERATOR.graph_signature(early_contract) != ROUTE_GENERATOR.graph_signature(later_contract))


func _check_blended_contract_progression_promotes_content_by_role() -> void:
	var stage_1: ContractDef = ROUTE_GENERATOR.generate(5151, {"route_difficulty": "medium", "completed_contract_count": 0})
	var stage_3: ContractDef = ROUTE_GENERATOR.generate(5151, {"route_difficulty": "medium", "completed_contract_count": 2})
	var stage_4: ContractDef = ROUTE_GENERATOR.generate(5151, {"route_difficulty": "medium", "completed_contract_count": 3})
	var stage_5: ContractDef = ROUTE_GENERATOR.generate(5151, {"route_difficulty": "medium", "completed_contract_count": 4})
	var hard_stage_1: ContractDef = ROUTE_GENERATOR.generate(5151, {"route_difficulty": "medium", "completed_contract_count": 5})
	var nightmare_overcap: ContractDef = ROUTE_GENERATOR.generate(5151, {"route_difficulty": "nightmare", "completed_contract_count": 8})

	var stage_1_boss := _first_node_of_type(stage_1.offer_node, ContractRouteNode.NodeType.BOSS)
	var stage_3_boss := _first_node_of_type(stage_3.offer_node, ContractRouteNode.NodeType.BOSS)
	assert(int(_scale(stage_1_boss)["monster_difficulty_id"]) == 3)
	assert(_content_difficulty(stage_1_boss) == 2)
	assert(int(_scale(stage_3_boss)["monster_difficulty_id"]) == 3)
	assert(_content_difficulty(stage_3_boss) == 3)
	assert(_promotion_reason(stage_3_boss) == "stage_3_boss_next_band")

	var stage_4_elite := _first_node_of_type(stage_4.offer_node, ContractRouteNode.NodeType.ELITE)
	if stage_4_elite != null:
		assert(int(_scale(stage_4_elite)["monster_difficulty_id"]) == 3)
		assert(_content_difficulty(stage_4_elite) == 3)
		assert(_promotion_reason(stage_4_elite) == "stage_4_elite_next_band")

	var stage_5_captain := _first_node_of_type(stage_5.offer_node, ContractRouteNode.NodeType.CAPTAIN)
	assert(stage_5_captain != null)
	assert(int(_scale(stage_5_captain)["monster_difficulty_id"]) == 3)
	assert(_content_difficulty(stage_5_captain) == 3)
	assert(_promotion_reason(stage_5_captain) == "stage_5_captain_next_band")

	var hard_normal := _first_node_of_type(hard_stage_1.offer_node, ContractRouteNode.NodeType.FIGHT)
	assert(hard_normal != null)
	assert(_scale(hard_normal)["effective_contract_difficulty_label"] == "hard")
	assert(_scale(hard_normal)["contract_progression_stage"] == 1)
	assert(_content_difficulty(hard_normal) == 3)

	var overcap_boss := _first_node_of_type(nightmare_overcap.offer_node, ContractRouteNode.NodeType.BOSS)
	assert(overcap_boss != null)
	assert(int(_scale(overcap_boss)["monster_difficulty_id"]) == 5)
	assert(int(_scale(overcap_boss)["overcap_pressure"]) > 0)


func _check_contract_pressure_overflow_is_materialized() -> void:
	var contract: ContractDef = ROUTE_GENERATOR.generate(6006, {
		"route_difficulty": "nightmare",
		"completed_contract_count": 3,
	})
	_assert_no_notices(ROUTE_GENERATOR.validate(contract), "contract pressure overflow")
	var overflow_seen := false
	for node in _nodes(contract):
		if node.node_type == ContractRouteNode.NodeType.START:
			continue
		var scale: Dictionary = node.generated_encounter_payload.get("route_pressure_scale", {})
		assert(not scale.is_empty())
		assert(int(scale["monster_difficulty_id"]) == 5)
		assert(int(scale["raw_difficulty_id"]) >= int(scale["monster_difficulty_id"]))
		assert(int(scale["contract_pressure_tier"]) == int(scale["raw_difficulty_id"]) - 5)
		if int(scale["contract_pressure_tier"]) > 0:
			overflow_seen = true
	assert(overflow_seen)


func _check_contract_hp_scaling_curve() -> void:
	var c1: ContractDef = ROUTE_GENERATOR.generate(5151, {"route_difficulty": "medium", "completed_contract_count": 0})
	var c6: ContractDef = ROUTE_GENERATOR.generate(5151, {"route_difficulty": "medium", "completed_contract_count": 5})
	var c10: ContractDef = ROUTE_GENERATOR.generate(5151, {"route_difficulty": "medium", "completed_contract_count": 9})
	var c20: ContractDef = ROUTE_GENERATOR.generate(5151, {"route_difficulty": "medium", "completed_contract_count": 19})
	var c30: ContractDef = ROUTE_GENERATOR.generate(5151, {"route_difficulty": "medium", "completed_contract_count": 29})

	var c1_boss := _first_node_of_type(c1.offer_node, ContractRouteNode.NodeType.BOSS)
	var c6_boss := _first_node_of_type(c6.offer_node, ContractRouteNode.NodeType.BOSS)
	var c10_boss := _first_node_of_type(c10.offer_node, ContractRouteNode.NodeType.BOSS)
	var c20_boss := _first_node_of_type(c20.offer_node, ContractRouteNode.NodeType.BOSS)
	var c30_boss := _first_node_of_type(c30.offer_node, ContractRouteNode.NodeType.BOSS)
	assert(is_equal_approx(_hp_multiplier(c1_boss), 1.0))
	assert(_hp_multiplier(c6_boss) > _hp_multiplier(c1_boss))
	assert(_hp_multiplier(c10_boss) > _hp_multiplier(c6_boss))
	assert(_hp_multiplier(c20_boss) > _hp_multiplier(c10_boss))
	assert(_hp_multiplier(c30_boss) > _hp_multiplier(c20_boss))
	assert(is_equal_approx(_hp_multiplier(c10_boss), 2.625))
	assert(is_equal_approx(_hp_multiplier(c20_boss), 7.25))
	assert(is_equal_approx(_hp_multiplier(c30_boss), 16.0))
	assert(is_equal_approx(_dps_multiplier(c1_boss), 1.0))
	assert(_dps_multiplier(c6_boss) > _dps_multiplier(c1_boss))
	assert(_dps_multiplier(c10_boss) > _dps_multiplier(c6_boss))
	assert(_dps_multiplier(c20_boss) > _dps_multiplier(c10_boss))
	assert(_dps_multiplier(c30_boss) > _dps_multiplier(c20_boss))
	assert(is_equal_approx(_dps_multiplier(c10_boss), 4.75))
	assert(is_equal_approx(_dps_multiplier(c20_boss), 14.5))
	assert(is_equal_approx(_dps_multiplier(c30_boss), 37.0))
	assert(is_equal_approx(_min_hp_budget_duration(c10_boss), 22.0))
	assert(is_equal_approx(_min_hp_budget_duration(c20_boss), 26.0))
	assert(is_equal_approx(_min_hp_budget_duration(c30_boss), 30.0))

	var c10_normal := _first_node_of_type(c10.offer_node, ContractRouteNode.NodeType.FIGHT)
	var c10_elite := _first_node_of_type(c10.offer_node, ContractRouteNode.NodeType.ELITE)
	if c10_elite != null:
		assert(_hp_multiplier(c10_elite) > _hp_multiplier(c10_normal))
		assert(_dps_multiplier(c10_elite) > _dps_multiplier(c10_normal))
	assert(_hp_multiplier(c10_boss) > _hp_multiplier(c10_normal))
	assert(_dps_multiplier(c10_boss) > _dps_multiplier(c10_normal))
	assert(is_equal_approx(_dps_multiplier(c10_normal), 3.125))
	assert(is_equal_approx(_min_hp_budget_duration(c10_normal), 22.0))
	assert(_hp_budget_duration(c10_normal) >= _display_duration(c10_normal))
	assert(_hp_budget_duration(c10_normal) >= _min_hp_budget_duration(c10_normal))
	assert(is_equal_approx(_armor_multiplier(c1_boss), 1.0))
	assert(_armor_multiplier(c6_boss) > _armor_multiplier(c1_boss))
	assert(_armor_multiplier(c10_boss) > _armor_multiplier(c6_boss))
	assert(_armor_multiplier(c20_boss) > _armor_multiplier(c10_boss))
	assert(_armor_multiplier(c30_boss) > _armor_multiplier(c20_boss))
	assert(is_equal_approx(_armor_multiplier(c10_boss), 3.43))
	assert(is_equal_approx(_armor_multiplier(c20_boss), 9.775))


func _check_contract_block_scaling_curve() -> void:
	var c1: ContractDef = ROUTE_GENERATOR.generate(8201, {"route_difficulty": "medium", "completed_contract_count": 0})
	var c10: ContractDef = ROUTE_GENERATOR.generate(8210, {"route_difficulty": "medium", "completed_contract_count": 9})
	var c20: ContractDef = ROUTE_GENERATOR.generate(8220, {"route_difficulty": "medium", "completed_contract_count": 19})
	var c30: ContractDef = ROUTE_GENERATOR.generate(8230, {"route_difficulty": "medium", "completed_contract_count": 29})

	var c1_normal := _first_node_of_type(c1.offer_node, ContractRouteNode.NodeType.FIGHT)
	var c10_normal := _first_node_of_type(c10.offer_node, ContractRouteNode.NodeType.FIGHT)
	var c10_boss := _first_node_of_type(c10.offer_node, ContractRouteNode.NodeType.BOSS)
	var c20_boss := _first_node_of_type(c20.offer_node, ContractRouteNode.NodeType.BOSS)
	var c30_boss := _first_node_of_type(c30.offer_node, ContractRouteNode.NodeType.BOSS)
	assert(is_equal_approx(_block_multiplier(c1_normal), 1.0))
	assert(_block_multiplier(c10_normal) > _block_multiplier(c1_normal))
	assert(_block_multiplier(c10_boss) > _block_multiplier(c10_normal))
	assert(_block_multiplier(c20_boss) > _block_multiplier(c10_boss))
	assert(_block_multiplier(c30_boss) > _block_multiplier(c20_boss))
	assert(is_equal_approx(_block_multiplier(c10_normal), 1.77))
	assert(is_equal_approx(_block_multiplier(c10_boss), 2.68))
	assert(is_equal_approx(_block_multiplier(c20_boss), 7.24))


func _check_contract_absorb_scaling_curve() -> void:
	var c1: ContractDef = ROUTE_GENERATOR.generate(8401, {"route_difficulty": "medium", "completed_contract_count": 0})
	var c10: ContractDef = ROUTE_GENERATOR.generate(8410, {"route_difficulty": "medium", "completed_contract_count": 9})
	var c20: ContractDef = ROUTE_GENERATOR.generate(8420, {"route_difficulty": "medium", "completed_contract_count": 19})
	var c30: ContractDef = ROUTE_GENERATOR.generate(8430, {"route_difficulty": "medium", "completed_contract_count": 29})

	var c1_normal := _first_node_of_type(c1.offer_node, ContractRouteNode.NodeType.FIGHT)
	var c10_normal := _first_node_of_type(c10.offer_node, ContractRouteNode.NodeType.FIGHT)
	var c10_boss := _first_node_of_type(c10.offer_node, ContractRouteNode.NodeType.BOSS)
	var c20_boss := _first_node_of_type(c20.offer_node, ContractRouteNode.NodeType.BOSS)
	var c30_boss := _first_node_of_type(c30.offer_node, ContractRouteNode.NodeType.BOSS)
	assert(is_equal_approx(_absorb_multiplier(c1_normal), 1.0))
	assert(_absorb_multiplier(c10_normal) > _absorb_multiplier(c1_normal))
	assert(_absorb_multiplier(c10_boss) > _absorb_multiplier(c10_normal))
	assert(_absorb_multiplier(c20_boss) > _absorb_multiplier(c10_boss))
	assert(_absorb_multiplier(c30_boss) > _absorb_multiplier(c20_boss))
	assert(is_equal_approx(_absorb_multiplier(c10_normal), 1.77))
	assert(is_equal_approx(_absorb_multiplier(c10_boss), 2.68))
	assert(is_equal_approx(_absorb_multiplier(c20_boss), 7.24))


func _check_early_contract_mechanic_guardrails() -> void:
	for completed_count in range(0, 3):
		for seed in range(9100, 9140):
			var contract: ContractDef = ROUTE_GENERATOR.generate(seed, {
				"route_difficulty": "medium",
				"completed_contract_count": completed_count,
			})
			for node in _nodes(contract):
				if node.node_type == ContractRouteNode.NodeType.START:
					continue
				var overrides: Dictionary = node.generated_encounter_payload.get("defense_overrides", {}) as Dictionary
				if overrides.has("cleanse_threshold"):
					assert(int(overrides["cleanse_threshold"]) >= 4)
				if overrides.has("suppress"):
					assert(float(overrides["suppress"]) <= 0.451)
				if overrides.has("poison_resistance"):
					assert(float(overrides["poison_resistance"]) <= 0.351)
				if overrides.has("slow"):
					assert(float(overrides["slow"]) <= 0.251)
				if overrides.has("block"):
					assert(float(overrides["block"]) <= float(_early_block_cap_for_test(completed_count + 1, node)))
				if overrides.has("absorb"):
					assert(float(overrides["absorb"]) <= float(_early_absorb_cap_for_test(completed_count + 1, node)))
				assert(not (overrides.has("cleanse_threshold") and overrides.has("suppress") and overrides.has("poison_resistance")))
				assert(not (overrides.has("armor") and overrides.has("block") and overrides.has("crit_negation")))
				assert(not (overrides.has("slow") and overrides.has("stun_duration_ms") and overrides.has("interrupt_skip_count")))


func _check_anti_snowball_validation_notices() -> void:
	var valid: ContractDef = ROUTE_GENERATOR.generate(6060, {
		"route_difficulty": "medium",
		"completed_contract_count": 3,
	})
	_assert_no_notices(ROUTE_GENERATOR.validate(valid), "anti-snowball valid sample")

	var gear_ahead := ROUTE_GENERATOR.generate(6061, {"route_difficulty": "easy"})
	var first_normal := _first_node_of_type(gear_ahead.offer_node, ContractRouteNode.NodeType.FIGHT)
	assert(first_normal != null)
	first_normal.reward.generated_gear_tier = GearItem.Tier.CURSED
	assert(_has_notice(ROUTE_GENERATOR.validate(gear_ahead), "reward_gear_ahead_of_pressure"))

	var early_talent := ROUTE_GENERATOR.generate(6062, {"route_difficulty": "easy"})
	var early_normal := _first_node_of_type(early_talent.offer_node, ContractRouteNode.NodeType.FIGHT)
	assert(early_normal != null)
	early_normal.reward.talent_points = 1
	assert(_has_notice(ROUTE_GENERATOR.validate(early_talent), "early_talent_without_pressure"))

	var missing_scale := ROUTE_GENERATOR.generate(6063, {"route_difficulty": "medium"})
	var scaled_node := _first_node_of_type(missing_scale.offer_node, ContractRouteNode.NodeType.FIGHT)
	assert(scaled_node != null)
	scaled_node.generated_encounter_payload.erase("route_pressure_scale")
	assert(_has_notice(ROUTE_GENERATOR.validate(missing_scale), "pressure_scale_missing"))


func _check_pressure_axes_are_materialized() -> void:
	var contract: ContractDef = ROUTE_GENERATOR.generate(6161, {"route_difficulty": "medium"})
	_assert_no_notices(ROUTE_GENERATOR.validate(contract), "pressure axes valid sample")
	for node in _nodes(contract):
		if node.node_type == ContractRouteNode.NodeType.START:
			continue
		var profile: Dictionary = node.generated_encounter_payload.get("route_pressure_axes", {})
		assert(not profile.is_empty())
		assert(String(profile["primary"]) != "")
		assert(not (profile.get("axes", []) as Array).is_empty())
		assert(not (profile.get("source_archetype_ids", []) as Array).is_empty())


func _check_p4m8_archetypes_are_route_reachable_with_axes() -> void:
	var expected_axes := {
		"aegis": ROUTE_GENERATOR.PRESSURE_AXIS_PHYSICAL,
		"nullify": ROUTE_GENERATOR.PRESSURE_AXIS_MAGICAL_POISON,
		"spiteful": ROUTE_GENERATOR.PRESSURE_AXIS_DEBUFF_POISON,
		"riftbound": ROUTE_GENERATOR.PRESSURE_AXIS_MIXED,
	}
	var seen := {}
	for seed in range(7000, 7600):
		var contract: ContractDef = ROUTE_GENERATOR.generate(seed, {"route_difficulty": "hard"})
		_assert_no_notices(ROUTE_GENERATOR.validate(contract), "p4m8 archetype reachability %d" % seed)
		for node in _nodes(contract):
			if node.node_type == ContractRouteNode.NodeType.START:
				continue
			var payload: Dictionary = node.generated_encounter_payload
			var profile: Dictionary = payload.get("route_pressure_axes", {})
			for archetype_id in payload.get("archetype_ids", []):
				var id := String(archetype_id)
				if not expected_axes.has(id):
					continue
				seen[id] = true
				assert((profile.get("axes", []) as Array).has(expected_axes[id]))
				assert((profile.get("source_archetype_ids", []) as Array).has(id))
		if seen.size() == expected_axes.size():
			break
	for archetype_id in expected_axes:
		assert(seen.has(archetype_id))


func _check_dead_run_axis_validation_notices() -> void:
	var same_axis := _contract_from_edges({
		"start": _node("start", ContractRouteNode.NodeType.START, 0, 0),
		"pre": _node("pre", ContractRouteNode.NodeType.FIGHT, 1, 0, "Armor Gate"),
		"a": _node("a", ContractRouteNode.NodeType.FIGHT, 2, 0, "Armor A"),
		"b": _node("b", ContractRouteNode.NodeType.FIGHT, 2, 1, "Armor B"),
		"boss": _node("boss", ContractRouteNode.NodeType.BOSS, 3, 0),
	}, {"start": ["pre"], "pre": ["a", "b"], "a": ["boss"], "b": ["boss"], "boss": []})
	_apply_axis_payload(same_axis, "pre", "physical_mitigation", "", 2, 0, 10, GearItem.Tier.BASIC, 1)
	_apply_axis_payload(same_axis, "a", "physical_mitigation", "", 2, 0, 10, GearItem.Tier.BASIC, 1)
	_apply_axis_payload(same_axis, "b", "physical_mitigation", "", 2, 0, 10, GearItem.Tier.BASIC, 1)
	_apply_axis_payload(same_axis, "boss", "physical_mitigation", "", 5, 1, 44, GearItem.Tier.MASTER, 2)
	assert(_has_notice(ROUTE_GENERATOR.validate(same_axis), "branch_pressure_axis_not_distinct"))
	assert(_has_notice(ROUTE_GENERATOR.validate(same_axis), "all_paths_pressure_axis_dominated"))

	var tradeoff := _contract_from_edges({
		"start": _node("start", ContractRouteNode.NodeType.START, 0, 0),
		"normal": _node("normal", ContractRouteNode.NodeType.FIGHT, 1, 0, "Armor Normal"),
		"elite": _node("elite", ContractRouteNode.NodeType.ELITE, 1, 1, "Armor Elite"),
		"boss": _node("boss", ContractRouteNode.NodeType.BOSS, 2, 0),
	}, {"start": ["normal", "elite"], "normal": ["boss"], "elite": ["boss"], "boss": []})
	_apply_axis_payload(tradeoff, "normal", "physical_mitigation", "", 2, 0, 10, GearItem.Tier.BASIC, 1)
	_apply_axis_payload(tradeoff, "elite", "physical_mitigation", "", 3, 0, 22, GearItem.Tier.BASIC, 2)
	_apply_axis_payload(tradeoff, "boss", "magical_poison_mitigation", "", 5, 1, 44, GearItem.Tier.MASTER, 2)
	assert(not _has_notice(ROUTE_GENERATOR.validate(tradeoff), "branch_pressure_axis_not_distinct"))

	var low_prep := _contract_from_edges({
		"start": _node("start", ContractRouteNode.NodeType.START, 0, 0),
		"a": _node("a", ContractRouteNode.NodeType.FIGHT, 1, 0),
		"b": _node("b", ContractRouteNode.NodeType.FIGHT, 1, 1),
		"boss": _node("boss", ContractRouteNode.NodeType.BOSS, 2, 0),
	}, {"start": ["a", "b"], "a": ["boss"], "b": ["boss"], "boss": []})
	_apply_axis_payload(low_prep, "a", "physical_mitigation", "", 2, 0, 0, GearItem.Tier.BASIC, 0)
	_apply_axis_payload(low_prep, "b", "magical_poison_mitigation", "", 2, 0, 0, GearItem.Tier.BASIC, 0)
	_apply_axis_payload(low_prep, "boss", "timing_control", "", 5, 2, 44, GearItem.Tier.MASTER, 2)
	assert(_has_notice(ROUTE_GENERATOR.validate(low_prep), "low_reward_shortest_path"))


func _check_sparse_generated_previews_exist() -> void:
	var contract: ContractDef = ROUTE_GENERATOR.generate(9911)
	for node in _nodes(contract):
		assert(node.route_preview.has("biome"))
		assert(node.route_preview.has("monster_name"))
		assert(node.route_preview.has("encounter_level"))
		assert(node.route_preview.has("archetype_tags"))
		assert(not node.route_preview.has("source_seed"))
		assert(not node.route_preview.has("budget_metadata"))
		assert(not node.route_preview.has("pressure_metadata"))
		assert(not node.route_preview.has("route_pressure_scale"))
		assert(not node.route_preview.has("route_pressure_axes"))
		assert(not node.route_preview.has("defense_overrides"))
		assert(not node.route_preview.has("elite_variant_id"))
		assert(not node.route_preview.has("elite_variant_model_version"))
		assert(not node.route_preview.has("boss_variant_id"))
		assert(not node.route_preview.has("boss_variant_model_version"))
		if node.node_type != ContractRouteNode.NodeType.START:
			assert(String(node.route_preview["biome"]) != "")
			assert(String(node.route_preview["monster_name"]) != "")
			assert(not _preview_tags(node.route_preview).is_empty())
			assert(node.route_preview["archetype_tags"] == node.combat_preview["archetype_tags"])
			assert(String(node.route_preview["archetype_line"]) != "")

	var branch := _first_branch(contract.offer_node)
	assert(branch != null)
	var preview_a: Dictionary = branch.next_nodes[0].route_preview
	var preview_b: Dictionary = branch.next_nodes[1].route_preview
	assert(_preview_signature(preview_a) != _preview_signature(preview_b))


func _check_p4m8_presentation_pool_targets() -> void:
	assert(ROUTE_GENERATOR.DEFAULT_ALLOWED_BIOMES.size() == 6)
	for biome in ROUTE_GENERATOR.DEFAULT_ALLOWED_BIOMES:
		assert(ROUTE_GENERATOR.BIOME_PRESENTATION.has(biome))
		var table: Dictionary = ROUTE_GENERATOR.BIOME_PRESENTATION[biome]
		assert((table.get("normal", []) as Array).size() >= 4)
		assert((table.get("captain", []) as Array).size() >= 2)
		assert((table.get("elite", []) as Array).size() >= 3)
		assert((table.get("boss", []) as Array).size() >= 5)
		assert(_presentation_candidates(biome, "captain").size() >= 6)
	var graveyard_table: Dictionary = ROUTE_GENERATOR.BIOME_PRESENTATION["Graveyard"]
	assert((graveyard_table["captain"] as Array).has("Flesh Golem"))
	assert(not (graveyard_table["captain"] as Array).has("Golem"))
	var forest_table: Dictionary = ROUTE_GENERATOR.BIOME_PRESENTATION["Haunted Forest"]
	assert((forest_table["boss"] as Array).has("Great Warebear"))
	assert(not (forest_table["boss"] as Array).has("Great Werewolf"))


func _check_biome_presentation_tables_are_used() -> void:
	var contract: ContractDef = ROUTE_GENERATOR.generate(6611, {
		"allowed_biomes": ["Swamp", "Cave"],
	})
	assert(Array(contract.allowed_biomes) == ["Swamp", "Cave"])
	for node in _nodes(contract):
		assert(Array(contract.allowed_biomes).has(node.biome))
		assert(node.biome == contract.selected_biome)
		if node.node_type == ContractRouteNode.NodeType.START:
			assert(node.display_name == "Route Start")
			continue
		var kind := _expected_kind(node)
		assert(_presentation_candidates(node.biome, kind).has(node.monster_presentation_type))
		assert(node.display_name == node.monster_presentation_type)
		assert(node.route_preview["monster_name"] == node.monster_presentation_type)
		assert(node.route_preview["biome"] == node.biome)

	var cave_only: ContractDef = ROUTE_GENERATOR.generate(6611, {
		"allowed_biomes": ["Cave"],
	})
	for node in _nodes(cave_only):
		assert(node.biome == "Cave")


func _check_captain_presentation_promotes_normal_names_without_duplicates() -> void:
	var contract: ContractDef = null
	for seed in range(1, 240):
		var candidate: ContractDef = ROUTE_GENERATOR.generate(seed, {
			"allowed_biomes": ["Swamp"],
		})
		if _nodes_of_type(candidate, ContractRouteNode.NodeType.CAPTAIN).size() >= 3:
			contract = candidate
			break
	assert(contract != null)
	var captain_names := PackedStringArray()
	var visible_names := {}
	var duplicate_names := {}
	for node in _nodes(contract):
		if node.node_type == ContractRouteNode.NodeType.START:
			continue
		var name := String(node.monster_presentation_type)
		if visible_names.has(name):
			duplicate_names[name] = true
		visible_names[name] = true
		if node.node_type == ContractRouteNode.NodeType.CAPTAIN:
			captain_names.append(name)
	assert(duplicate_names.is_empty())
	assert(captain_names.size() >= 3)
	assert(_captain_promoted_names("Swamp").any(func(name: String) -> bool: return captain_names.has(name)))


func _check_presentation_identity_does_not_change_mechanics() -> void:
	var swamp: ContractDef = ROUTE_GENERATOR.generate(8801, {
		"allowed_biomes": ["Swamp"],
		"route_difficulty": "medium",
	})
	var cave: ContractDef = ROUTE_GENERATOR.generate(8801, {
		"allowed_biomes": ["Cave"],
		"route_difficulty": "medium",
	})
	var swamp_nodes := _nodes_by_id(swamp)
	var cave_nodes := _nodes_by_id(cave)
	var presentation_difference_seen := false
	for node_id in swamp_nodes:
		var swamp_node: ContractRouteNode = swamp_nodes[node_id]
		var cave_node: ContractRouteNode = cave_nodes[node_id]
		if swamp_node.node_type == ContractRouteNode.NodeType.START:
			continue
		presentation_difference_seen = presentation_difference_seen or swamp_node.monster_presentation_type != cave_node.monster_presentation_type
		assert(_mechanical_payload_signature(swamp_node) == _mechanical_payload_signature(cave_node))
	assert(presentation_difference_seen)


func _check_malformed_graphs_report_shape_errors() -> void:
	var short_route := _contract_from_edges({
		"start": _node("start", ContractRouteNode.NodeType.START, 0, 0),
		"boss": _node("boss", ContractRouteNode.NodeType.BOSS, 1, 0),
	}, {"start": ["boss"], "boss": []})
	assert(_has_notice(ROUTE_GENERATOR.validate(short_route), "path_too_short"))

	var stubby_route := _contract_from_edges({
		"start": _node("start", ContractRouteNode.NodeType.START, 0, 0),
		"a": _node("a", ContractRouteNode.NodeType.FIGHT, 1, 0),
		"b": _node("b", ContractRouteNode.NodeType.FIGHT, 1, 1),
		"boss": _node("boss", ContractRouteNode.NodeType.BOSS, 2, 0),
	}, {"start": ["a", "b"], "a": ["boss"], "b": ["boss"], "boss": []})
	assert(_has_notice(ROUTE_GENERATOR.validate(stubby_route), "longest_path_too_short"))

	var forced_elite := _contract_from_edges({
		"start": _node("start", ContractRouteNode.NodeType.START, 0, 0),
		"elite_a": _node("elite_a", ContractRouteNode.NodeType.ELITE, 1, 0),
		"elite_b": _node("elite_b", ContractRouteNode.NodeType.ELITE, 1, 1),
		"boss": _node("boss", ContractRouteNode.NodeType.BOSS, 2, 0),
	}, {"start": ["elite_a", "elite_b"], "elite_a": ["boss"], "elite_b": ["boss"], "boss": []})
	assert(_has_notice(ROUTE_GENERATOR.validate(forced_elite), "forced_elite_opener"))
	assert(_has_notice(ROUTE_GENERATOR.validate(forced_elite), "elite_branch_without_alternative"))

	var consecutive_elites := _contract_from_edges({
		"start": _node("start", ContractRouteNode.NodeType.START, 0, 0),
		"elite_a": _node("elite_a", ContractRouteNode.NodeType.ELITE, 1, 0),
		"normal_a": _node("normal_a", ContractRouteNode.NodeType.FIGHT, 1, 1),
		"elite_b": _node("elite_b", ContractRouteNode.NodeType.ELITE, 2, 0),
		"normal_b": _node("normal_b", ContractRouteNode.NodeType.FIGHT, 2, 1),
		"boss": _node("boss", ContractRouteNode.NodeType.BOSS, 3, 0),
	}, {
		"start": ["elite_a", "normal_a"],
		"elite_a": ["elite_b"],
		"elite_b": ["boss"],
		"normal_a": ["normal_b"],
		"normal_b": ["boss"],
		"boss": [],
	})
	assert(_has_notice(ROUTE_GENERATOR.validate(consecutive_elites), "back_to_back_elites"))
	assert(_has_notice(ROUTE_GENERATOR.validate(consecutive_elites), "elite_shortest_path_over_limit"))

	var indistinct_branch := _contract_from_edges({
		"start": _node("start", ContractRouteNode.NodeType.START, 0, 0),
		"a": _node("a", ContractRouteNode.NodeType.FIGHT, 1, 0, "Same Preview"),
		"b": _node("b", ContractRouteNode.NodeType.FIGHT, 1, 1, "Same Preview"),
		"boss": _node("boss", ContractRouteNode.NodeType.BOSS, 2, 0),
	}, {"start": ["a", "b"], "a": ["boss"], "b": ["boss"], "boss": []})
	assert(_has_notice(ROUTE_GENERATOR.validate(indistinct_branch), "branch_preview_not_distinct"))


func _nodes(contract: ContractDef) -> Array:
	var result := []
	var visited := {}
	_collect(contract.offer_node, visited, result)
	result.sort_custom(func(a: ContractRouteNode, b: ContractRouteNode): return a.depth < b.depth if a.depth != b.depth else a.lane < b.lane)
	return result


func _nodes_by_id(contract: ContractDef) -> Dictionary:
	var result := {}
	for node in _nodes(contract):
		result[node.generated_node_id] = node
	return result


func _nodes_of_type(contract: ContractDef, node_type: int) -> Array:
	var result := []
	for node in _nodes(contract):
		if node.node_type == node_type:
			result.append(node)
	return result


func _normal_at_or_after_depth(contract: ContractDef, depth: int) -> ContractRouteNode:
	var candidate: ContractRouteNode = null
	for node in _nodes(contract):
		if node.node_type != ContractRouteNode.NodeType.FIGHT:
			continue
		if node.depth < depth:
			continue
		if candidate == null or node.depth < candidate.depth:
			candidate = node
	return candidate


func _payload_difficulty(node: ContractRouteNode) -> int:
	var input: Dictionary = node.generated_encounter_payload.get("source_input", {})
	return int(input.get("difficulty_id", 0))


func _scale(node: ContractRouteNode) -> Dictionary:
	return node.generated_encounter_payload.get("route_pressure_scale", {}) as Dictionary


func _content_difficulty(node: ContractRouteNode) -> int:
	return int(_scale(node).get("content_difficulty_id", 0))


func _promotion_reason(node: ContractRouteNode) -> String:
	return String(_scale(node).get("content_promotion_reason", ""))


func _hp_multiplier(node: ContractRouteNode) -> float:
	var pressure: Dictionary = node.generated_encounter_payload.get("pressure_metadata", {}) as Dictionary
	return float(pressure.get("contract_hp_multiplier", 1.0))


func _dps_multiplier(node: ContractRouteNode) -> float:
	var pressure: Dictionary = node.generated_encounter_payload.get("pressure_metadata", {}) as Dictionary
	return float(pressure.get("contract_dps_multiplier", 1.0))


func _armor_multiplier(node: ContractRouteNode) -> float:
	var input: Dictionary = node.generated_encounter_payload.get("source_input", {}) as Dictionary
	var overrides: Dictionary = input.get("overrides", {}) as Dictionary
	var scaling: Dictionary = overrides.get("contract_armor_scaling", {}) as Dictionary
	return float(scaling.get("multiplier", 1.0))


func _block_multiplier(node: ContractRouteNode) -> float:
	var input: Dictionary = node.generated_encounter_payload.get("source_input", {}) as Dictionary
	var overrides: Dictionary = input.get("overrides", {}) as Dictionary
	var scaling: Dictionary = overrides.get("contract_block_scaling", {}) as Dictionary
	return float(scaling.get("multiplier", 1.0))


func _absorb_multiplier(node: ContractRouteNode) -> float:
	var input: Dictionary = node.generated_encounter_payload.get("source_input", {}) as Dictionary
	var overrides: Dictionary = input.get("overrides", {}) as Dictionary
	var scaling: Dictionary = overrides.get("contract_absorb_scaling", {}) as Dictionary
	return float(scaling.get("multiplier", 1.0))


func _early_block_cap_for_test(contract_number: int, node: ContractRouteNode) -> int:
	if contract_number <= 1:
		match node.node_type:
			ContractRouteNode.NodeType.CAPTAIN:
				return 7
			ContractRouteNode.NodeType.ELITE:
				return 9
			ContractRouteNode.NodeType.BOSS:
				return 10
		return 5
	if contract_number == 2:
		match node.node_type:
			ContractRouteNode.NodeType.CAPTAIN:
				return 9
			ContractRouteNode.NodeType.ELITE:
				return 10
			ContractRouteNode.NodeType.BOSS:
				return 12
		return 7
	match node.node_type:
		ContractRouteNode.NodeType.CAPTAIN:
			return 10
		ContractRouteNode.NodeType.ELITE:
			return 12
		ContractRouteNode.NodeType.BOSS:
			return 14
	return 8


func _early_absorb_cap_for_test(contract_number: int, node: ContractRouteNode) -> int:
	if contract_number <= 1:
		match node.node_type:
			ContractRouteNode.NodeType.CAPTAIN:
				return 4
			ContractRouteNode.NodeType.ELITE:
				return 5
			ContractRouteNode.NodeType.BOSS:
				return 7
		return 3
	if contract_number == 2:
		match node.node_type:
			ContractRouteNode.NodeType.CAPTAIN:
				return 5
			ContractRouteNode.NodeType.ELITE:
				return 7
			ContractRouteNode.NodeType.BOSS:
				return 8
		return 4
	match node.node_type:
		ContractRouteNode.NodeType.CAPTAIN:
			return 7
		ContractRouteNode.NodeType.ELITE:
			return 8
		ContractRouteNode.NodeType.BOSS:
			return 10
	return 5


func _min_hp_budget_duration(node: ContractRouteNode) -> float:
	var pressure: Dictionary = node.generated_encounter_payload.get("pressure_metadata", {}) as Dictionary
	return float(pressure.get("min_hp_budget_duration_sec", 0.0))


func _hp_budget_duration(node: ContractRouteNode) -> float:
	var pressure: Dictionary = node.generated_encounter_payload.get("pressure_metadata", {}) as Dictionary
	return float(pressure.get("hp_budget_duration_sec", 0.0))


func _display_duration(node: ContractRouteNode) -> float:
	var pressure: Dictionary = node.generated_encounter_payload.get("pressure_metadata", {}) as Dictionary
	return float(pressure.get("duration_sec", 0.0))


func _apply_axis_payload(
	contract: ContractDef,
	node_id: String,
	primary_axis: String,
	secondary_axis: String,
	monster_difficulty: int,
	contract_pressure: int,
	gold: int,
	gear_tier: int,
	gear_choices: int
) -> void:
	var node: ContractRouteNode = _nodes_by_id(contract)[node_id]
	var raw_difficulty := monster_difficulty + contract_pressure
	node.generated_encounter_payload = {
		"source_input": {
			"difficulty_id": monster_difficulty,
			"monster_kind": _expected_kind(node),
			"tempo_profile": "standard",
		},
		"route_pressure_scale": {
			"raw_difficulty_id": raw_difficulty,
			"monster_difficulty_id": monster_difficulty,
			"contract_pressure_tier": contract_pressure,
			"route_difficulty_base": monster_difficulty,
			"depth_bonus": 0,
			"node_level_bonus": 0,
			"completed_contract_pressure_bonus": 0,
			"monster_level": _expected_kind(node),
			"monster_difficulty_cap": 5,
		},
		"route_pressure_axes": {
			"primary": primary_axis,
			"secondary": secondary_axis,
			"axes": [primary_axis] if secondary_axis == "" else [primary_axis, secondary_axis],
			"source_archetype_ids": [primary_axis],
		},
	}
	node.debug_preview = {
		"route_pressure_scale": node.generated_encounter_payload["route_pressure_scale"].duplicate(true),
		"route_pressure_axes": node.generated_encounter_payload["route_pressure_axes"].duplicate(true),
	}
	var reward := EncounterReward.new()
	reward.gold_amount = gold
	reward.generated_gear_tier = gear_tier
	reward.generated_gear_choice_count = gear_choices
	var slots: Array[int] = []
	if gear_choices > 0:
		slots.append(GearItem.SlotType.WEAPON)
	reward.generated_gear_slots = slots
	node.reward = reward


func _reward_signatures(contract: ContractDef) -> Dictionary:
	var result := {}
	for node in _nodes(contract):
		if node.reward == null:
			result[node.generated_node_id] = "none"
			continue
		result[node.generated_node_id] = "%d:%d:%d:%d:%s:%s:%s" % [
			node.reward.gold_amount,
			node.reward.talent_points,
			node.reward.generated_gear_choice_count,
			node.reward.generated_gear_tier,
			",".join(_int_strings(node.reward.generated_gear_slots)),
			node.reward_quality_label,
			node.reward_summary,
		]
	return result
	

func _first_node_of_type(node: ContractRouteNode, node_type: int, visited: Dictionary = {}) -> ContractRouteNode:
	if node == null or visited.has(node.generated_node_id):
		return null
	visited[node.generated_node_id] = true
	if node.node_type == node_type:
		return node
	for next_node in node.next_nodes:
		var found := _first_node_of_type(next_node, node_type, visited)
		if found != null:
			return found
	return null


func _collect(node: ContractRouteNode, visited: Dictionary, result: Array) -> void:
	if node == null or visited.has(node.generated_node_id):
		return
	visited[node.generated_node_id] = true
	result.append(node)
	for next_node in node.next_nodes:
		_collect(next_node, visited, result)


func _paths(contract: ContractDef) -> Array:
	var nodes := _nodes(contract)
	return _paths_from(nodes[0], nodes[nodes.size() - 1], {}, [])


func _paths_from(node: ContractRouteNode, boss: ContractRouteNode, visited: Dictionary, path: Array) -> Array:
	if node == null or visited.has(node.generated_node_id):
		return []
	var next_path := path.duplicate()
	next_path.append(node)
	if node == boss:
		return [next_path]
	var next_visited := visited.duplicate()
	next_visited[node.generated_node_id] = true
	var paths := []
	for next_node in node.next_nodes:
		paths.append_array(_paths_from(next_node, boss, next_visited, next_path))
	return paths


func _count_type(nodes: Array, node_type: int) -> int:
	var count := 0
	for node in nodes:
		if node.node_type == node_type:
			count += 1
	return count


func _max_width(nodes: Array) -> int:
	var result := 0
	for node in nodes:
		result = maxi(result, node.next_nodes.size())
	return result


func _path_count(node: ContractRouteNode, boss: ContractRouteNode, visited: Dictionary) -> int:
	if node == null:
		return 0
	if node == boss:
		return 1
	if visited.has(node.generated_node_id):
		return 0
	visited[node.generated_node_id] = true
	var count := 0
	for next_node in node.next_nodes:
		count += _path_count(next_node, boss, visited.duplicate())
	return count


func _shortest_path(paths: Array) -> Array:
	var shortest: Array = paths[0]
	for path in paths:
		if path.size() < shortest.size():
			shortest = path
	return shortest


func _elite_count(path: Array) -> int:
	var count := 0
	for node in path:
		if node.node_type == ContractRouteNode.NodeType.ELITE:
			count += 1
	return count


func _has_back_to_back_elites(path: Array) -> bool:
	var previous_elite := false
	for node in path:
		var current_elite: bool = node.node_type == ContractRouteNode.NodeType.ELITE
		if previous_elite and current_elite:
			return true
		previous_elite = current_elite
	return false


func _first_branch(node: ContractRouteNode) -> ContractRouteNode:
	if node == null:
		return null
	if node.next_nodes.size() > 1:
		return node
	for next_node in node.next_nodes:
		var branch := _first_branch(next_node)
		if branch != null:
			return branch
	return null


func _preview_signature(preview: Dictionary) -> String:
	return "%s|%s|%s|%s|%s|%s" % [
		preview.get("biome", ""),
		preview.get("monster_name", ""),
		preview.get("encounter_level", ""),
		preview.get("elite_variant_label", ""),
		preview.get("boss_variant_label", ""),
		",".join(_preview_tags(preview)),
	]


func _preview_tags(preview: Dictionary) -> PackedStringArray:
	var tags := PackedStringArray()
	for tag in preview.get("archetype_tags", []):
		tags.append(String(tag))
	return tags


func _expected_kind(node: ContractRouteNode) -> String:
	match node.node_type:
		ContractRouteNode.NodeType.CAPTAIN:
			return "captain"
		ContractRouteNode.NodeType.ELITE:
			return "elite"
		ContractRouteNode.NodeType.BOSS:
			return "boss"
	return "normal"


func _expected_combat_kind(node: ContractRouteNode) -> String:
	match node.node_type:
		ContractRouteNode.NodeType.ELITE:
			return "elite"
		ContractRouteNode.NodeType.BOSS:
			return "boss"
	return "normal"


func _presentation_candidates(biome: String, kind: String) -> Array:
	var table: Dictionary = ROUTE_GENERATOR.BIOME_PRESENTATION[biome]
	var candidates := Array(table[kind]).duplicate()
	if kind == "captain":
		candidates.append_array(_captain_promoted_names(biome))
	return candidates


func _captain_promoted_names(biome: String) -> Array:
	var table: Dictionary = ROUTE_GENERATOR.BIOME_PRESENTATION[biome]
	var promoted := []
	for normal_name in table["normal"]:
		promoted.append(String(ROUTE_GENERATOR.CAPTAIN_PROMOTED_NORMAL_NAMES.get(String(normal_name), "Veteran %s" % String(normal_name))))
	return promoted


func _mechanical_payload_signature(node: ContractRouteNode) -> String:
	var payload := node.generated_encounter_payload
	var input: Dictionary = payload.get("source_input", {})
	return "%s|%s|%s|%s|%s|%s|%s|%s" % [
		str(payload.get("source_seed", "")),
		String(input.get("monster_kind", "")),
		str(input.get("difficulty_id", "")),
		String(input.get("tempo_profile", "")),
		",".join(_string_array(payload.get("archetype_ids", []))),
		_mechanics_signature(payload.get("selected_mechanics", [])),
		str(payload.get("defense_overrides", {})),
		str(payload.get("pressure_metadata", {})),
	]


func _string_array(values: Array) -> PackedStringArray:
	var result := PackedStringArray()
	for value in values:
		result.append(String(value))
	return result


func _int_strings(values: Array) -> PackedStringArray:
	var result := PackedStringArray()
	for value in values:
		result.append(str(int(value)))
	return result


func _mechanics_signature(mechanics: Array) -> String:
	var parts := PackedStringArray()
	for entry in mechanics:
		parts.append("%s:%s:%s" % [
			String(entry.get("id", "")),
			str(entry.get("value", "")),
			str(entry.get("godot_value", "")),
		])
	return ";".join(parts)


func _contract_from_edges(nodes: Dictionary, edges: Dictionary) -> ContractDef:
	var contract := ContractDef.new()
	contract.apply_generated_route_state({
		"generated_route_id": "route.generated.test",
		"source_seed": 1,
		"generator_version": ROUTE_GENERATOR.GENERATOR_VERSION,
		"route_settings": ROUTE_GENERATOR.DEFAULT_SETTINGS.duplicate(true),
	})
	for node_id in edges:
		var node: ContractRouteNode = nodes[node_id]
		for next_id in edges[node_id]:
			node.next_nodes.append(nodes[next_id])
		node.sync_outgoing_node_ids_from_next_nodes()
	contract.offer_node = nodes["start"]
	return contract


func _node(id: String, node_type: int, depth: int, lane: int, monster_name: String = "") -> ContractRouteNode:
	var node := ContractRouteNode.new()
	node.id = "route.generated.test.%s" % id
	node.generated_node_id = id
	node.node_type = node_type
	node.depth = depth
	node.lane = lane
	node.biome = "Swamp"
	node.display_name = monster_name if monster_name != "" else id.capitalize()
	node.route_preview = {
		"biome": "Swamp",
		"monster_name": node.display_name,
		"encounter_level": _encounter_level(node),
		"archetype_tags": PackedStringArray(["test"]),
	}
	return node


func _encounter_level(node: ContractRouteNode) -> String:
	match node.node_type:
		ContractRouteNode.NodeType.START:
			return "Start"
		ContractRouteNode.NodeType.CAPTAIN:
			return "Captain"
		ContractRouteNode.NodeType.ELITE:
			return "Elite"
		ContractRouteNode.NodeType.BOSS:
			return "Boss"
	return "Normal"


func _has_notice(notices: PackedStringArray, code_prefix: String) -> bool:
	for notice in notices:
		if String(notice).begins_with(code_prefix):
			return true
	return false


func _assert_no_notices(notices: PackedStringArray, context: String) -> void:
	if not notices.is_empty():
		print("%s validation notices: %s" % [context, ", ".join(notices)])
	assert(notices.is_empty())
