extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _item(id: String, value: float, slot := GearItem.SlotType.WEAPON) -> GearItem:
	var gear := GearItem.new()
	gear.id = "test.t3." + id
	gear.slot = slot
	gear.tier = GearItem.Tier.UNIQUE
	gear.source_kind = GearItem.SourceKind.GENERATED
	var modifier := StatModifier.new()
	modifier.stat_id = id
	modifier.value = value
	modifier.category = StatModifier.StatCategory.SPECIAL if StatCatalog.is_special(id) else StatModifier.StatCategory.RARE
	gear.affixes = [modifier]
	return gear

func _run() -> void:
	var state = root.get_node("BuildState")
	state.reset()
	state.set_class(load("res://data/classes/rogue.tres"))
	state.equipped_weapon = null
	var special := _item("inventory_economy_stats", 1.0, GearItem.SlotType.ARMOR)
	var economy := _item("shop_discount", 0.30)
	state.equipped_armor = special
	assert(state.add_inventory_item(economy))
	assert(state.add_inventory_item(economy)) # Same pointer, two owned occurrences.
	assert(is_equal_approx(state.current_player_stats().shop_discount, .60))
	state.equip_from_inventory(economy)
	assert(state.inventory.size() == 1)
	assert(is_equal_approx(state.current_player_stats().shop_discount, .60))
	state.equip_from_inventory(economy) # Same pointer on both sides still swaps one occurrence.
	assert(state.inventory.size() == 1)
	state.unequip(GearItem.SlotType.WEAPON)
	assert(state.inventory.size() == 2)
	assert(SaveSystem.save_run(state), SaveSystem.last_error)
	var data: Dictionary = StrictSaveJson.read(FileAccess.get_file_as_string(SaveSystem.save_path)).data
	assert(data.save_version == SaveSystem.SAVE_VERSION)
	var bytes := FileAccess.get_file_as_bytes(SaveSystem.save_path)
	state.inventory.clear()
	assert(SaveSystem.load_run_result(state).status == "loaded")
	assert(state.inventory.size() == 2)
	assert(FileAccess.get_file_as_bytes(SaveSystem.save_path) == bytes)
	assert(is_equal_approx(state.current_player_stats().shop_discount, .60))
	# Every persisted location must reject unknown explicit identities atomically.
	var unknown := _item("unknown.explicit.stat", .20)
	state.inventory.append(unknown)
	assert(not SaveSystem.save_run(state), "Writer must preserve unknown IDs until validation rejects them.")
	assert(FileAccess.get_file_as_bytes(SaveSystem.save_path) == bytes)
	state.inventory.erase(unknown)
	for location in ["inventory", "shop_offers", "pending_reward_choices", "equipped_weapon"]:
		var invalid := data.duplicate(true)
		var entry: Dictionary = SaveSystem._gear_entry_to_data(_item("cooldown_reduction", .10))
		entry.affixes[0].stat_id = "unknown.explicit.stat"
		invalid[location] = entry if location == "equipped_weapon" else [entry]
		assert(SaveSystem.write_json(SaveSystem.save_path, invalid))
		var failed_bytes := FileAccess.get_file_as_bytes(SaveSystem.save_path)
		assert(SaveSystem.load_run_result(state).status == "failed")
		assert(FileAccess.get_file_as_bytes(SaveSystem.save_path) == failed_bytes)
		assert(state.inventory.size() == 2)
	# Supported old envelope preserves removed pool affixes and exact rolls.
	var old := data.duplicate(true)
	old.save_version = 2
	old.equipped_armor = null
	old.inventory = [SaveSystem._gear_entry_to_data(_item("increased_magic_find", .371, GearItem.SlotType.HELM))]
	assert(SaveSystem.write_json(SaveSystem.save_path, old))
	bytes = FileAccess.get_file_as_bytes(SaveSystem.save_path)
	assert(SaveSystem.load_run_result(state).status == "loaded")
	assert(state.inventory[0].affixes[0].value == .371)
	assert(FileAccess.get_file_as_bytes(SaveSystem.save_path) == bytes)
	old.inventory = [SaveSystem._gear_entry_to_data(_item("cooldown_reduction", .10))]
	assert(SaveSystem.write_json(SaveSystem.save_path, old))
	assert(SaveSystem.load_run_result(state).status == "failed")
	_check_practice()
	state.reset()
	print("T3 persistence/inventory: PASS")
	quit()

func _check_practice() -> void:
	var practice := TrainingRoomState.new()
	practice.set_class(load("res://data/classes/rogue.tres"))
	practice.carried_items = [_item("increased_gold", .5), _item("increased_gold", .5)]
	assert(PracticeSaveSystem.save_setup(practice), PracticeSaveSystem.last_error)
	var data: Dictionary = StrictSaveJson.read(FileAccess.get_file_as_string(PracticeSaveSystem.save_path)).data
	assert(data.practice_version == PracticeSaveSystem.SAVE_VERSION and data.carried_items.size() == 2)
	var restored := TrainingRoomState.new()
	assert(PracticeSaveSystem.load_setup(restored).status == "loaded")
	assert(restored.carried_items.size() == 2)
	for fault in ["missing", "null", "empty_record", "invalid_source", "too_many", "negative", "multiply", "drawback", "overflow"]:
		var invalid := data.duplicate(true)
		match fault:
			"missing": invalid.erase("carried_items")
			"null": invalid.carried_items = [null]
			"empty_record": invalid.carried_items = [{}]
			"invalid_source": invalid.carried_items[0].source_kind = 999
			"too_many": invalid.carried_items = [data.carried_items[0], data.carried_items[0], data.carried_items[0], data.carried_items[0]]
			_:
				var modifier := _item("increased_buff_duration", .10)
				if fault == "negative": modifier.affixes[0].value = -.10
				if fault == "multiply": modifier.affixes[0].operation = StatModifier.OperationType.MULTIPLY
				if fault == "drawback": modifier.affixes[0].category = StatModifier.StatCategory.DRAWBACK
				if fault == "overflow": modifier.affixes[0].value = 1e100
				invalid.equipment.weapon = SaveSystem._gear_entry_to_data(modifier)
		assert(SaveSystem.write_json(PracticeSaveSystem.save_path, invalid))
		var bytes := FileAccess.get_file_as_bytes(PracticeSaveSystem.save_path)
		assert(PracticeSaveSystem.load_setup(restored).status == "failed", fault)
		assert(restored.carried_items.size() == 2)
		assert(FileAccess.get_file_as_bytes(PracticeSaveSystem.save_path) == bytes)
	data.practice_version = 1
	data.erase("carried_items")
	assert(SaveSystem.write_json(PracticeSaveSystem.save_path, data))
	var old_bytes := FileAccess.get_file_as_bytes(PracticeSaveSystem.save_path)
	assert(PracticeSaveSystem.load_setup(restored).status == "loaded")
	assert(restored.carried_items.is_empty())
	assert(FileAccess.get_file_as_bytes(PracticeSaveSystem.save_path) == old_bytes)
