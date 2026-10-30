extends SceneTree
## Focused P5M2-T3 check: Helm and Armor are real equipment slots in
## Adventure state, generated pools, save/load, and Practice Room state.


func _initialize() -> void:
	var build_state = root.get_node("BuildState")
	build_state.reset()
	SaveSystem.save_path = get_script().resource_path.get_base_dir().path_join("p5m2_five_slot_equipment_save.json")
	SaveSystem.delete_save()

	print("-- P5M2 five-slot equipment --")
	_check_active_slot_pool()
	_check_build_state_slots(build_state)
	_check_save_load_slots(build_state)
	_check_training_room_state_slots()

	SaveSystem.delete_save()
	SaveSystem.save_path = SaveSystem.SAVE_PATH
	build_state.reset()
	print("P5M2 five-slot equipment check: OK")
	quit(0)


func _check_active_slot_pool() -> void:
	_require(GearGenerator.ALL_SLOTS == GearItem.universal_slot_order(), "Expected active generated gear slots to use all five universal slots.")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3301
	var helm := GearGenerator.generate(GearItem.Tier.BASIC, GearItem.SlotType.HELM, rng, "gear.test.active_helm")
	var armor := GearGenerator.generate(GearItem.Tier.MASTER, GearItem.SlotType.ARMOR, rng, "gear.test.active_armor")
	_require(helm.slot == GearItem.SlotType.HELM, "Expected generated Helm item.")
	_require(armor.slot == GearItem.SlotType.ARMOR, "Expected generated Armor item.")


func _check_build_state_slots(build_state) -> void:
	var items := {
		GearItem.SlotType.WEAPON: _make_item("gear.test.weapon", GearItem.SlotType.WEAPON),
		GearItem.SlotType.HELM: _make_item("gear.test.helm", GearItem.SlotType.HELM),
		GearItem.SlotType.ARMOR: _make_item("gear.test.armor", GearItem.SlotType.ARMOR),
		GearItem.SlotType.TRINKET: _make_item("gear.test.trinket", GearItem.SlotType.TRINKET),
		GearItem.SlotType.CHARM: _make_item("gear.test.charm", GearItem.SlotType.CHARM),
	}
	for slot in GearItem.universal_slot_order():
		build_state.equip(items[slot])
		_require(build_state.equipped_item_for_slot(slot) == items[slot], "Expected slot %s to equip." % slot)
	_require(build_state.equipped_gear().size() == 5, "Expected all five equipped gear entries.")
	_require(build_state.equipped_gear()[1] == items[GearItem.SlotType.HELM], "Expected Helm in universal order.")
	_require(build_state.equipped_gear()[2] == items[GearItem.SlotType.ARMOR], "Expected Armor in universal order.")

	var replacement_helm := _make_item("gear.test.replacement_helm", GearItem.SlotType.HELM)
	build_state.equip(replacement_helm)
	_require(build_state.equipped_helm == replacement_helm, "Expected Helm replacement to equip.")
	_require(build_state.has_inventory_item(items[GearItem.SlotType.HELM]), "Expected replaced Helm to move to inventory.")

	build_state.unequip(GearItem.SlotType.ARMOR)
	_require(build_state.equipped_armor == null, "Expected Armor unequip to clear slot.")
	_require(build_state.has_inventory_item(items[GearItem.SlotType.ARMOR]), "Expected unequipped Armor to move to inventory.")

	var gold_before_sale: int = build_state.gold
	_require(build_state.sell_equipped_item(GearItem.SlotType.HELM), "Expected equipped Helm sale to succeed.")
	_require(build_state.equipped_helm == null, "Expected sold Helm slot to clear.")
	_require(build_state.gold > gold_before_sale, "Expected equipped Helm sale to add gold.")


func _check_save_load_slots(build_state) -> void:
	build_state.reset()
	var items := {
		GearItem.SlotType.WEAPON: _make_item("gear.test.saved_weapon", GearItem.SlotType.WEAPON),
		GearItem.SlotType.HELM: _make_item("gear.test.saved_helm", GearItem.SlotType.HELM),
		GearItem.SlotType.ARMOR: _make_item("gear.test.saved_armor", GearItem.SlotType.ARMOR),
		GearItem.SlotType.TRINKET: _make_item("gear.test.saved_trinket", GearItem.SlotType.TRINKET),
		GearItem.SlotType.CHARM: _make_item("gear.test.saved_charm", GearItem.SlotType.CHARM),
	}
	for slot in GearItem.universal_slot_order():
		build_state.equip(items[slot])
	_require(SaveSystem.save_run(build_state), "Expected five-slot save to write.")
	build_state.reset()
	_require(SaveSystem.load_run(build_state), "Expected five-slot save to load.")
	for slot in GearItem.universal_slot_order():
		var loaded: GearItem = build_state.equipped_item_for_slot(slot)
		_require(loaded != null, "Expected loaded slot %s." % slot)
		_require(loaded.id == items[slot].id, "Expected loaded slot %s id to roundtrip." % slot)
		_require(loaded.slot == slot, "Expected loaded slot %s slot to roundtrip." % slot)
		_require(loaded.item_family == GearGenerator.rogue_item_family_for_slot(slot), "Expected loaded slot %s family metadata." % slot)


func _check_training_room_state_slots() -> void:
	var state := TrainingRoomState.new()
	_require(state.practice_helm != null, "Expected Practice Room Helm item.")
	_require(state.practice_armor != null, "Expected Practice Room Armor item.")
	state.set_slot_rarity(state.practice_helm, GearItem.Tier.BASIC)
	state.set_slot_rarity(state.practice_armor, GearItem.Tier.MASTER)
	state.set_slot_rarity(state.practice_weapon, GearItem.Tier.CURSED)
	state.set_slot_rarity(state.practice_trinket, GearItem.Tier.BASIC)
	state.set_slot_rarity(state.practice_charm, GearItem.Tier.MASTER)
	_require(state.equipped_helm == state.practice_helm, "Expected Practice Room Helm equip.")
	_require(state.equipped_armor == state.practice_armor, "Expected Practice Room Armor equip.")
	_require(state.equipped_gear().size() == 5, "Expected Practice Room five equipped items.")
	_require(state.practice_weapon.affixes.size() == 4 and state.practice_weapon.affixes[3].is_drawback, "Expected Cursed practice drawback metadata.")


func _make_item(id: String, slot: GearItem.SlotType) -> GearItem:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	return GearGenerator.generate(GearItem.Tier.BASIC, slot, rng, id)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	assert(false, message)
