extends SceneTree
const OUT := "res://reports/m9_t7_visual/"
var geometry := {}
var state: Node
func _initialize() -> void:
	SaveSystem.save_path = OUT + "adventure.json"
	PracticeSaveSystem.save_path = OUT + "practice.json"
	PracticeSaveSystem.core_save_path = OUT + "core.json"
	SevenSlotSaveBoundary.legacy_path = OUT + "legacy.json"
	SevenSlotSaveBoundary.marker_path = OUT + "marker.json"
	for path in SevenSlotSaveBoundary.paths().values():
		for candidate in [path, path + ".tmp"]:
			if FileAccess.file_exists(candidate): DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))
	call_deferred("run")
func capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(OUT + label + ".png") == OK)
func item(slot: int) -> GearItem:
	var rng := RandomNumberGenerator.new()
	rng.seed = 100 + slot
	return GearGenerator.generate(GearItem.Tier.MASTER, slot, rng)
func record(label: String, slots: Array) -> void:
	var rects := []
	for node: Control in slots:
		var rect := node.get_global_rect()
		assert(Rect2(0, 0, 1600, 900).encloses(rect), "Slot outside viewport")
		for previous: Control in slots:
			if previous != node: assert(not rect.intersects(previous.get_global_rect()), "Equipment overlaps")
		rects.append({"x":rect.position.x,"y":rect.position.y,"w":rect.size.x,"h":rect.size.y,"tooltip":node.tooltip_text})
	assert(slots[5].get_global_rect().position.y >= slots[2].get_global_rect().end.y, "Pants below chest")
	assert(slots[6].get_global_rect().position.y >= slots[0].get_global_rect().end.y, "Gloves below weapon")
	assert(slots[5].size.x > slots[6].size.x, "Pants larger than gloves")
	assert(slots[1].get_global_rect().end.y <= slots[2].get_global_rect().position.y, "Helm above chest")
	assert(slots[4].get_global_rect().end.y <= slots[3].get_global_rect().position.y, "Charm above trinket")
	var panel_rect := (slots[0].get_parent().get_parent().get_parent().get_parent() as Control).get_global_rect()
	geometry[label] = {"viewport":[1600,900],"equipment_overlap":false,"slots":rects,"ancestor_rect":str(panel_rect)}
	if label.begins_with("adventure") or label.begins_with("test"):
		var panel: Control = slots[0].get_parent().get_parent().get_parent().get_parent()
		geometry[label]["gear_panel_rect"] = str(panel.get_global_rect())
		assert(Rect2(0,0,1600,900).encloses(panel.get_global_rect()), "Gear panel outside viewport")
		assert(Rect2(0,0,1600,900).encloses(panel._inventory_grid.get_global_rect()), "Inventory outside viewport")
		var major_panels := {}
		for node in panel.get_tree().root.find_children("*", "PanelContainer", true, false):
			if node.name in ["ActiveTalentsPanel", "SkillBuildPanel", "CharacterStatsPanel"] and node.is_visible_in_tree():
				major_panels[node.name] = str(node.get_global_rect())
				assert(Rect2(0,0,1600,900).encloses(node.get_global_rect()), "Dashboard panel outside viewport")
		geometry[label]["dashboard_panels"] = major_panels
		geometry[label]["inventory_rect"] = str(panel._inventory_grid.get_global_rect())
		print(label, " GEAR ",panel.get_global_rect()," INV ",panel._inventory_grid.get_global_rect())
func dismiss(screen: Node) -> void:
	for field in ["_contract_overlay", "_map_overlay", "_story_overlay", "_talent_overlay", "_secondary_subclass_overlay"]:
		var overlay = screen.get(field)
		if overlay != null: overlay.hide()
func slots(panel: Node) -> Array:
	var result := []
	for slot in GearItem.universal_slot_order(): result.append(panel._equipped_panel_for_slot(slot))
	return result
func run() -> void:
	root.size = Vector2i(1600,900)
	root.gui_embed_subwindows = true
	state = root.get_node("BuildState")
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._on_new_game_pressed(1928)
	state.set_class(load("res://data/classes/rogue.tres"))
	var registry := BuildContentRegistry.adventure()
	assert(state.configure_ranked_build(registry.trees["tree.bladedancer"]))
	game._show_combat_screen()
	await process_frame
	var screen: Node = game._current_screen
	dismiss(screen)
	var panel: Node = screen.find_child("GearPanel",true,false)
	assert(panel != null)
	await capture("adventure_fresh")
	record("adventure_fresh",slots(panel))
	for slot in GearItem.universal_slot_order(): state.equip(item(slot))
	await capture("adventure_populated")
	record("adventure_populated",slots(panel))
	var carried := item(GearItem.SlotType.LEGS)
	state.add_inventory_item(carried)
	await process_frame
	var inventory_button: Control = panel._inventory_button_for_item(carried)
	var hover: Control = inventory_button.tooltip_builder.call()
	screen.add_child(hover)
	hover.position = Vector2(930,360)
	await capture("adventure_pants_comparison")
	hover.queue_free()
	panel._show_equipped_action_menu(GearItem.SlotType.HANDS)
	panel._equipped_action_menu.position = Vector2i(1220,480)
	await capture("adventure_gloves_actions")
	panel._equipped_action_menu.hide()
	game._on_contract_test_pressed(424242,10)
	await process_frame
	screen = game._current_screen
	dismiss(screen)
	panel = screen.find_child("GearPanel",true,false)
	await capture("test_fresh")
	record("test_fresh",slots(panel))
	for slot in GearItem.universal_slot_order():
		if slot != GearItem.SlotType.WEAPON: state.equip(item(slot))
	await capture("test_populated")
	record("test_populated",slots(panel))
	game.queue_free()
	await process_frame
	state.reset()
	var room = load("res://scenes/training_room/training_room.tscn").instantiate()
	root.add_child(room)
	await capture("practice_fresh")
	var practice_slots := []
	for slot in GearItem.universal_slot_order(): practice_slots.append(room._gear_slot_buttons[slot])
	record("practice_fresh",practice_slots)
	for slot in GearItem.universal_slot_order():
		var custom: GearItem = room._state.get("practice_" + GearItem.SlotType.keys()[slot].to_lower())
		room._state.set_slot_rarity(custom,GearItem.Tier.MASTER)
	await capture("practice_populated")
	record("practice_populated",practice_slots)
	room._legs_slot_button.pressed.emit()
	room._on_editor_rarity_selected(room._gear_rarity_option.get_item_index(GearItem.Tier.UNIQUE))
	await capture("practice_pants_editor")
	room._hands_slot_button.pressed.emit()
	room._on_editor_rarity_selected(room._gear_rarity_option.get_item_index(GearItem.Tier.CURSED))
	await capture("practice_gloves_editor")
	room._gear_editor_overlay.hide()
	var custom_carried: GearItem = room._state.add_carried_item()
	room._state.set_carried_slot(custom_carried, GearItem.SlotType.HANDS)
	room._state.set_slot_rarity(custom_carried,GearItem.Tier.UNIQUE)
	room._show_gear_slot_editor("Carried 1",custom_carried,false)
	await capture("practice_carried_gloves_editor")
	room._carried_slot_option.show_popup()
	await capture("practice_carried_slot_selector")
	room._carried_slot_option.get_popup().hide()
	room._gear_editor_overlay.hide()
	var practice_hover: Control = room._hands_slot_button.tooltip_builder.call()
	room.add_child(practice_hover)
	practice_hover.position = Vector2(900,330)
	await capture("practice_gloves_hover")
	practice_hover.queue_free()
	SaveSystem.write_json(OUT+"geometry.json",geometry)
	room.queue_free()
	await process_frame
	state.reset()
	print("M9 T7 VISUAL PASS")
	quit()
