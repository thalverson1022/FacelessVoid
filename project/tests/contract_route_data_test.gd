extends SceneTree
## Headless P2:R4:T2 check for The Gilded Serpent contract route data. Run with:
##   godot --headless --path project -s res://tests/contract_route_data_test.gd


func _initialize() -> void:
	var contract: ContractDef = load("res://data/contracts/the_gilded_serpent.tres")
	assert(contract != null)
	assert(contract.id == "contract.gilded_serpent")
	assert(contract.display_name == "The Gilded Serpent Contract")
	assert(contract.target_monster != null)
	assert(contract.target_monster.id == "monster.contract.vyra")
	assert(contract.offer_node != null)
	_assert_authored_contract_has_no_generated_route_state(contract)

	var offer := contract.offer_node
	assert(offer.node_type == ContractRouteNode.NodeType.OFFER)
	assert(offer.next_nodes.size() == 1)

	var secondary := offer.next_nodes[0]
	assert(secondary.node_type == ContractRouteNode.NodeType.SUBCLASS_CHOICE)
	assert(secondary.display_name == "Choose a Second Rogue Tree")
	assert(secondary.next_nodes.size() == 2)

	var door_guard := _find_next(secondary, "route.gilded_serpent.door_guard")
	var portly_cook := _find_next(secondary, "route.gilded_serpent.portly_cook")
	assert(door_guard != null)
	assert(portly_cook != null)

	_assert_node_stats(door_guard, "monster.contract.door_guard", 230, 160, 0.1, 16000)
	assert(door_guard.reward.gold_amount == 22)
	assert(door_guard.reward.generated_gear_tier == GearItem.Tier.MASTER)
	assert(door_guard.reward.generated_gear_slots == [GearItem.SlotType.WEAPON, GearItem.SlotType.TRINKET])
	assert(door_guard.next_nodes.size() == 2)

	_assert_node_stats(portly_cook, "monster.contract.portly_cook", 360, 0, 0.0, 20000)
	assert(portly_cook.reward.gold_amount == 26)
	assert(portly_cook.reward.generated_gear_tier == GearItem.Tier.BASIC)
	assert(portly_cook.reward.generated_gear_slots == [GearItem.SlotType.WEAPON, GearItem.SlotType.CHARM])
	assert(portly_cook.next_nodes.size() == 2)

	print("walking easy route: Portly Cook -> Lazy Henchman -> Knives -> Vyra")
	var lazy_henchman := _find_next(portly_cook, "route.gilded_serpent.lazy_henchman")
	assert(lazy_henchman != null)
	_assert_node_stats(lazy_henchman, "monster.contract.lazy_henchman", 500, 0, 0.0, 26000)
	assert(lazy_henchman.reward.talent_points == 0)
	assert(lazy_henchman.reward.generated_gear_tier == GearItem.Tier.BASIC)
	var easy_knives := _only_next(lazy_henchman)
	_assert_knives_to_vyra(easy_knives)

	print("walking harder route: Door Guard -> Cloaked Watchmen -> Knives -> Vyra")
	var cloaked_watchmen := _find_next(door_guard, "route.gilded_serpent.cloaked_watchmen")
	assert(cloaked_watchmen != null)
	_assert_node_stats(cloaked_watchmen, "monster.contract.cloaked_watchmen", 525, 160, 0.4, 26000)
	assert(cloaked_watchmen.reward.talent_points == 0)
	assert(cloaked_watchmen.reward.generated_gear_tier == GearItem.Tier.CURSED)
	var hard_knives := _only_next(cloaked_watchmen)
	_assert_knives_to_vyra(hard_knives)

	var post_tavern_tiers := [
		door_guard.reward.generated_gear_tier,
		cloaked_watchmen.reward.generated_gear_tier,
		hard_knives.reward.legendary_choice_pool[0].tier,
	]
	assert(post_tavern_tiers.has(GearItem.Tier.MASTER))
	assert(post_tavern_tiers.has(GearItem.Tier.CURSED))
	assert(post_tavern_tiers.has(GearItem.Tier.LEGENDARY))

	print("")
	print("Contract route data check: OK")
	quit()


func _assert_node_stats(node: ContractRouteNode, monster_id: String, hp: int, armor: int, poison_resistance: float, duration_ms: int) -> void:
	assert(node != null)
	assert(node.monster != null)
	assert(node.monster.id == monster_id)
	assert(node.monster.hp == hp)
	assert(node.monster.armor == armor)
	assert(is_equal_approx(node.monster.poison_resistance, poison_resistance))
	assert(node.duration_ms == duration_ms)
	assert(node.reward != null)
	assert(not node.difficulty_label.is_empty())
	assert(not node.reward_quality_label.is_empty())


func _assert_knives_to_vyra(knives: ContractRouteNode) -> void:
	_assert_node_stats(knives, "monster.contract.knives_right_hand", 540, 160, 0.3, 28000)
	assert(knives.node_type == ContractRouteNode.NodeType.ELITE)
	assert(knives.reward.gold_amount == 42)
	# P2:R9:T5 -- Knives now offers a seeded random choice of 2 of a 5-item
	# Legendary pool instead of a fixed pair; the pool itself is still
	# authored data, so its full membership is still assertable here.
	assert(knives.reward.legendary_choice_count == 2)
	assert(knives.reward.legendary_choice_pool.size() == 5)
	var legendary_ids: Array[String] = []
	for gear in knives.reward.legendary_choice_pool:
		legendary_ids.append(gear.id)
	assert(legendary_ids.has("gear.legendary.wyvern_kriss"))
	assert(legendary_ids.has("gear.legendary.mithril_karambit"))
	assert(legendary_ids.has("gear.legendary.bandit_blade"))
	assert(legendary_ids.has("gear.legendary.umbral_stiletto"))
	assert(legendary_ids.has("gear.legendary.bejeweled_push_dagger"))
	assert(knives.reward.legendary_choice_pool.all(func(gear): return gear.tier == GearItem.Tier.LEGENDARY))
	assert(knives.reward_quality_label == "Legendary Weapon")
	assert(knives.reward_summary.contains("2 of 5"))

	var vyra := _only_next(knives)
	_assert_node_stats(vyra, "monster.contract.vyra", 600, 160, 0.35, 30000)
	assert(vyra.node_type == ContractRouteNode.NodeType.BOSS)
	assert(vyra.reward.gold_amount == 120)
	assert(vyra.next_nodes.is_empty())


func _assert_authored_contract_has_no_generated_route_state(contract: ContractDef) -> void:
	assert(not contract.has_generated_route_state())
	assert(contract.generated_route_id == "")
	assert(contract.source_seed == 0)
	assert(contract.generator_version == "")
	assert(contract.route_difficulty == "")
	assert(contract.selected_biome == "")
	assert(contract.allowed_biomes.is_empty())
	assert(contract.biome_table_version == "")
	assert(contract.runtime_monster_generator_version == "")
	assert(contract.runtime_monster_archetype_library_version == "")
	assert(contract.route_settings.is_empty())
	assert(contract.route_notices.is_empty())
	for node in _collect_nodes(contract.offer_node):
		_assert_authored_node_uses_legacy_fields(node)


func _assert_authored_node_uses_legacy_fields(node: ContractRouteNode) -> void:
	assert(node.generated_node_id == "")
	assert(node.depth == -1)
	assert(node.lane == -1)
	assert(node.outgoing_node_ids.is_empty())
	assert(node.biome == "")
	assert(node.monster_presentation_type == "")
	assert(node.route_preview.is_empty())
	assert(node.generated_encounter_payload.is_empty())
	assert(node.combat_preview.is_empty())
	assert(node.debug_preview.is_empty())
	assert(node.generation_notices.is_empty())
	assert(not node.has_generated_state())
	assert(node.id.begins_with("route.gilded_serpent."))
	assert(node.display_name != "")


func _collect_nodes(start: ContractRouteNode) -> Array:
	var result := []
	_collect_nodes_recursive(start, {}, result)
	return result


func _collect_nodes_recursive(node: ContractRouteNode, visited: Dictionary, result: Array) -> void:
	if node == null or visited.has(node.id):
		return
	visited[node.id] = true
	result.append(node)
	for next_node in node.next_nodes:
		_collect_nodes_recursive(next_node, visited, result)


func _find_next(node: ContractRouteNode, id: String) -> ContractRouteNode:
	for next_node in node.next_nodes:
		if next_node.id == id:
			return next_node
	return null


func _only_next(node: ContractRouteNode) -> ContractRouteNode:
	assert(node.next_nodes.size() == 1)
	return node.next_nodes[0]
