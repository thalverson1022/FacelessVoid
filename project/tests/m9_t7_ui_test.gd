extends SceneTree
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	assert(ok, label)
func item(slot: int, seed_value: int = 71) -> GearItem:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return GearGenerator.generate(GearItem.Tier.MASTER, slot, rng)
func run() -> void:
	var state = root.get_node("BuildState")
	state.reset()
	state.set_class(load("res://data/classes/rogue.tres"))
	var panel = load("res://scenes/combat/gear_panel.tscn").instantiate()
	root.add_child(panel)
	await process_frame
	for slot in [GearItem.SlotType.LEGS, GearItem.SlotType.HANDS]:
		var target: Control = panel._equipped_panel_for_slot(slot)
		check(target != null and target.tooltip_text.ends_with(": Empty"), "new empty label")
		check(target.get_node("SlotTypeBackground").texture == GearIcons.slot_background_for(slot), "correct gray silhouette")
		var first := item(slot)
		state.add_inventory_item(first)
		panel._on_inventory_slot_pressed(first)
		await create_timer(0.3).timeout
		check(state.equipped_item_for_slot(slot) == first and target.get_node("Icon").texture == GearIcons.icon_for(first), "equip + supplied ordinary artwork")
		check(target.has_meta("sell_click_connected"), "action click connected")
		var replacement := item(slot, 77)
		state.add_inventory_item(replacement)
		panel._on_inventory_slot_pressed(replacement)
		await create_timer(0.3).timeout
		check(state.equipped_item_for_slot(slot) == replacement and state.inventory.has(first), "swap returns original")
		while state.inventory.size() < state.INVENTORY_CAPACITY: state.add_inventory_item(item(GearItem.SlotType.WEAPON, 81 + state.inventory.size()))
		panel._show_equipped_action_menu(slot)
		check(panel._equipped_action_menu.is_item_disabled(panel._equipped_action_menu.get_item_index(panel.ACTION_UNEQUIP_ID)), "full inventory disables unequip")
		panel._equipped_action_menu.hide()
		panel._unequip_to_inventory_with_animation(slot)
		check(state.equipped_item_for_slot(slot) == replacement, "full inventory keeps equipped")
		state.inventory.clear()
		state.build_changed.emit()
		state.add_inventory_item(first)
		state.build_locked = true
		panel._on_inventory_slot_pressed(first)
		check(state.equipped_item_for_slot(slot) == replacement and state.inventory.has(first), "combat locks direct inventory click")
		state.shop_round_pending = true
		panel._show_equipped_action_menu(slot)
		for action in [panel.ACTION_UNEQUIP_ID, panel.ACTION_SELL_ID, panel.ACTION_DESTROY_ID]:
			check(panel._equipped_action_menu.is_item_disabled(panel._equipped_action_menu.get_item_index(action)), "combat locks every equipped action")
		panel._on_equipped_action_selected(panel.ACTION_DESTROY_ID)
		check(state.equipped_item_for_slot(slot) == replacement, "locked stale action rejected")
		panel._equipped_action_menu.hide()
		state.build_locked = false
		panel._unequip_to_inventory_with_animation(slot)
		await create_timer(0.3).timeout
		check(state.equipped_item_for_slot(slot) == null and state.inventory.has(replacement), "unequip animation reaches inventory")
		panel._on_inventory_slot_pressed(replacement)
		await create_timer(0.3).timeout
		var gold: int = state.gold
		var price: int = state.sell_value_for(replacement)
		panel._confirm_sell_equipped_item(slot)
		panel._on_sell_confirmed()
		await create_timer(0.4).timeout
		check(state.equipped_item_for_slot(slot) == null and state.gold == gold + price, "sell new slot exact gold")
		state.equip(first)
		panel._confirm_destroy_equipped_item(slot)
		panel._on_destroy_confirmed()
		check(state.equipped_item_for_slot(slot) == null, "destroy new slot")
	panel.queue_free()
	await process_frame
	state.reset()
	var room = load("res://scenes/training_room/training_room.tscn").instantiate()
	root.add_child(room)
	await process_frame
	for slot in [GearItem.SlotType.LEGS, GearItem.SlotType.HANDS]:
		var button: Button = room._gear_slot_buttons[slot]
		button.pressed.emit()
		var shell: GearItem = room._editing_gear_item
		check(shell.slot == slot and room._equipped_editor_item() == null, "correct empty editor")
		check(room._gear_rarity_option.get_item_index(GearItem.Tier.CRUDE) == -1 and room._gear_rarity_option.get_item_index(GearItem.Tier.LEGENDARY) >= 0, "Crude absent and authored Legendary available")
		for tier in room.PRACTICE_CUSTOM_TIERS:
			room._on_editor_rarity_selected(room._gear_rarity_option.get_item_index(tier))
			check(room._equipped_editor_item() == shell and shell.tier == tier, "rarity applies current new slot")
			for index in shell.affixes.size():
				var pool: Array = room._stat_ids_for_affix_slot(shell, index)
				check(not pool.is_empty(), "new slot category pool available")
				check(pool.has(shell.affixes[index].stat_id), "current new-slot stat in valid pool")
		room._on_editor_rarity_selected(room._gear_rarity_option.get_item_index(room.NONE_RARITY_ID))
		check(room._equipped_editor_item() == null, "None clears new slot")
		room._on_editor_rarity_selected(room._gear_rarity_option.get_item_index(GearItem.Tier.MASTER))
		check(PracticeSaveSystem.save_setup(room._state, true), PracticeSaveSystem.last_error)
		var old := shell
		check(PracticeSaveSystem.load_setup(room._state).get("status") == "loaded", "reload setup")
		button.pressed.emit()
		check(room._editing_gear_item != old and room._editing_gear_item == room._state.get("practice_" + GearItem.SlotType.keys()[slot].to_lower()), "reload click resolves live shell")
		room._on_editor_rarity_selected(room._gear_rarity_option.get_item_index(GearItem.Tier.BASIC))
		check(room._equipped_editor_item() == room._editing_gear_item, "loaded editor edits loaded item")
	var existing_carried: GearItem = room._state.add_carried_item()
	var fixed: GearItem = LegendaryCatalog.all_items()[0]
	room._state.equip_legendary(fixed)
	room._state.set_carried_slot(existing_carried, fixed.slot)
	room._show_gear_slot_editor("Carried existing", existing_carried, false)
	check(room._gear_affix_column.visible and not room._gear_legendary_option.visible, "carried custom affixes visible beside equipped Legendary")
	check(room._gear_rarity_option.get_item_index(GearItem.Tier.LEGENDARY) == -1, "custom carried cannot select equip Legendary")
	room._on_editor_rarity_selected(room._gear_rarity_option.get_item_index(GearItem.Tier.UNIQUE))
	check(room._state.equipped_gear().has(fixed) and existing_carried.affixes.size() == 5, "carried rarity preserves equipped Legendary")
	room._state.remove_carried_item(0)
	var carried: GearItem = room._state.add_carried_item()
	room._show_gear_slot_editor("Carried 1", carried, false)
	for slot in [GearItem.SlotType.LEGS, GearItem.SlotType.HANDS]:
		room._carried_slot_option.item_selected.emit(room._carried_slot_option.get_item_index(slot))
		check(carried.slot == slot and room._carried_slot_option.get_selected_id() == slot, "carried selector IDs")
		check(room._gear_rarity_option.get_item_index(GearItem.Tier.LEGENDARY) == -1, "carried empty Legendary absent after slot change")
		room._on_editor_rarity_selected(room._gear_rarity_option.get_item_index(GearItem.Tier.UNIQUE))
		check(carried.affixes.size() == 5 and room._state.carried_items.has(carried), "carried new slot editor preserves carrying")
	room.queue_free()
	await process_frame
	state.reset()
	print("M9 T7 UI PASS (%d checks)" % checks)
	quit()

