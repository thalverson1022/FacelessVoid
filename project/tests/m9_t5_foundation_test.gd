extends SceneTree
var checks := 0
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	checks += 1
	assert(value, message)
func gear(slot: int, id: String, mods: Array = []) -> GearItem:
	var item := GearItem.new()
	item.slot = slot
	item.id = id
	item.display_name = id
	item.item_family = GearGenerator.rogue_item_family_for_slot(slot)
	item.source_kind = GearItem.SourceKind.COMPATIBILITY
	for entry in mods:
		var modifier := StatModifier.new()
		modifier.stat_id = entry[0]
		modifier.value = entry[1]
		modifier.category = StatModifier.StatCategory.SPECIAL if entry[0] == "inventory_economy_stats" else StatModifier.StatCategory.BASIC
		item.affixes.append(modifier)
	return item
func _run() -> void:
	var state = root.get_node("BuildState")
	state.reset()
	check(SaveSystem.delete_save(), "clear isolated previous fixture")
	check(GearItem.SlotType.values() == [0, 1, 2, 3, 4, 5, 6], "stable IDs")
	check(GearItem.universal_slot_order() == [0, 3, 4, 1, 2, 5, 6], "stable aggregation order")
	check(GearGenerator.ALL_SLOTS.size() == 7 and GearGenerator.PHASE5_ALL_SLOTS.size() == 7, "T6 acquisition supports seven slots")
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for slot in [5, 6]:
		for tier in GearItem.rarity_order():
			check(GearGenerator.generate_from_request({"slot": slot, "tier": tier, "rng": rng}).ok == GearGenerator.is_procedural_tier(tier), "T6 ordinary generation; starter/catalog boundaries retained")
	check(GearGenerator.universal_slot_label(5) == "Legs" and GearGenerator.rogue_item_family_for_slot(6) == "Gloves", "labels")
	state.set_class(load("res://data/classes/rogue.tres"))
	check(state.equipped_gear().size() == 1 and state.equipped_weapon.id == "gear.crude_dagger", "fresh Adventure crude only")
	check(state.equipped_legs == null and state.equipped_hands == null, "fresh new slots empty")
	var fresh_stats: PlayerStats = state.current_player_stats()
	var legs := gear(5, "legs", [["increased_gold", .25]])
	var hands := gear(6, "hands", [["increased_attack_speed", .12]])
	state.equip(legs)
	state.equip(hands)
	check(state.equipped_item_for_slot(5) == legs and state.equipped_item_for_slot(6) == hands, "equip lookup")
	check(state.current_player_stats().derivation_error == "", "canonical legal affixes")
	check(is_equal_approx(state.current_player_stats().gold_reward_multiplier, fresh_stats.gold_reward_multiplier + .25) and is_equal_approx(state.current_player_stats().attack_speed, fresh_stats.attack_speed + .12), "Pants and Gloves each contribute exactly once")
	state.build_locked = true
	var replacement := gear(5, "replacement")
	state.equip(replacement)
	check(not state.build_locked and state.inventory.has(legs), "swap unlock/displacement")
	state.unequip(6)
	check(state.inventory.has(hands) and state.equipped_hands == null, "unequip owned")
	check(state.equip_from_inventory(hands), "equip from inventory")
	check(state.sell_equipped_item(6) and state.equipped_hands == null, "sell hands")
	check(state.destroy_equipped_item(5) and state.equipped_legs == null, "destroy legs")
	# Full inventory keeps the established swap/sell and blocked-unequip rules.
	state.inventory.clear()
	state.equip(legs)
	for index in 3: state.add_inventory_item(gear(6, "full_%d" % index))
	var before_gold: int = state.gold
	var sale: int = state.sell_value_for(legs)
	state.equip(replacement)
	check(state.inventory.size() == 3 and state.gold == before_gold + sale, "full inventory displaced sale")
	state.unequip(5)
	check(state.equipped_legs == replacement and state.inventory.size() == 3, "full inventory unequip blocked")
	state.reset()
	state.set_class(load("res://data/classes/rogue.tres"))
	var activation := gear(5, "activation", [["inventory_economy_stats", 1]])
	var economy := gear(6, "economy", [["increased_gold", .25], ["base_damage", 999]])
	state.add_inventory_item(economy)
	check(state.current_player_stats().gold_reward_multiplier == 1, "carried new slot inactive")
	state.equip(activation)
	check(is_equal_approx(state.current_player_stats().gold_reward_multiplier, 1.25), "new equipped activator imports owned economy")
	check(state.current_player_stats().bonus_physical_damage < 999, "carried combat affix excluded")
	state.destroy_inventory_item(economy)
	check(state.current_player_stats().gold_reward_multiplier == 1, "destroy removes imported economy")
	state.add_inventory_item(economy)
	state.sell_equipped_item(5)
	check(state.current_player_stats().gold_reward_multiplier == 1, "sell deactivates inventory economy")
	# Every field participates in serialization, even when the item has no affixes.
	state.reset()
	state.set_class(load("res://data/classes/rogue.tres"))
	for slot in GearItem.universal_slot_order(): state.equip(gear(slot, "slot_%d" % slot))
	check(SaveSystem.save_run(state), SaveSystem.last_error)
	state.reset()
	check(SaveSystem.load_run_result(state).status == "loaded", "Adventure roundtrip")
	check(state.equipped_gear().size() == 7, "all seven restored")
	for slot in GearItem.universal_slot_order(): check(state.equipped_item_for_slot(slot).id == "slot_%d" % slot, "slot identity")
	var data := SaveSystem._serialize(state)
	for field in ["equipped_legs", "equipped_hands"]:
		var invalid := data.duplicate(true)
		invalid.erase(field)
		check(SaveSystem.write_json(SaveSystem.save_path, invalid), "write invalid fixture")
		check(SaveSystem.load_run_result(state).status == "failed" and state.equipped_gear().size() == 7, "missing slot atomic rejection")
	var wrong := data.duplicate(true)
	wrong.equipped_hands = wrong.equipped_legs
	check(SaveSystem.write_json(SaveSystem.save_path, wrong), "wrong slot fixture")
	check(SaveSystem.load_run_result(state).status == "failed", "wrong slot rejected")
	for fault in ["negative_slot", "huge_slot", "bad_affixes", "bad_operation"]:
		var invalid := data.duplicate(true)
		match fault:
			"negative_slot": invalid.equipped_hands.slot = -1
			"huge_slot": invalid.equipped_hands.slot = 999
			"bad_affixes": invalid.equipped_hands.affixes = "bad"
			"bad_operation": invalid.equipped_hands.affixes = [{"stat_id": "crit_chance", "value": .1, "operation": {}}]
		check(SaveSystem.write_json(SaveSystem.save_path, invalid), "malformed fixture")
		check(SaveSystem.load_run_result(state).status == "failed", "malformed gear rejected: " + fault)
	check(SaveSystem.write_json(SaveSystem.save_path, data), "restore valid fixture")
	var room := TrainingRoomState.new()
	room.content_registry = BuildContentRegistry.test_mode()
	room.set_class(load("res://data/classes/rogue.tres"))
	check(room.equipped_gear().is_empty() and room.practice_legs.affixes.is_empty() and room.practice_hands.affixes.is_empty(), "Practice starts empty shells")
	room.practice_legs.affixes = gear(5, "legal", [["increased_gold", .25]]).affixes
	room.practice_hands.affixes = gear(6, "legal", [["increased_attack_speed", .12]]).affixes
	room._equip_practice_item(room.practice_legs)
	room._equip_practice_item(room.practice_hands)
	check(PracticeSaveSystem.save_setup(room), PracticeSaveSystem.last_error)
	var restored := TrainingRoomState.new()
	restored.content_registry = room.content_registry
	check(PracticeSaveSystem.load_setup(restored).status == "loaded", "Practice roundtrip")
	check(restored.equipped_legs == restored.practice_legs and restored.equipped_hands == restored.practice_hands, "Practice custom references")
	check(restored.practice_legs != room.practice_legs and restored.practice_legs.affixes[0] != room.practice_legs.affixes[0], "custom resources independent after reload")
	check(is_equal_approx(restored.practice_legs.affixes[0].value, .25), "custom numeric affix restored")
	check(LegendaryCatalog.all_items().size() == 20, "final M9 roster has twenty Legendaries")
	for item in LegendaryCatalog.all_items():
		var original := item.id
		room.set("equipped_" + GearItem.SlotType.keys()[item.slot].to_lower(), item)
		check(PracticeSaveSystem.save_setup(room), "authored save " + original)
		check(PracticeSaveSystem.load_setup(restored).status == "loaded", "authored reload " + original)
		check(restored.get("equipped_" + GearItem.SlotType.keys()[item.slot].to_lower()).id == original, "authored identity " + original)
	state.reset()
	print("M9 T5 foundation PASS (%d checks)" % checks)
	quit()
