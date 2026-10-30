extends "res://tests/m9_t7_visual.gd"
## Scoped playtest presentation checks and actual-size review images.
const OUTPUT := "res://reports/m9_character_sheet_polish/"
var evidence := {}

func _initialize() -> void:
	SaveSystem.save_path = OUTPUT + "adventure.json"
	PracticeSaveSystem.save_path = OUTPUT + "practice.json"
	PracticeSaveSystem.core_save_path = OUTPUT + "core.json"
	SevenSlotSaveBoundary.legacy_path = OUTPUT + "legacy.json"
	SevenSlotSaveBoundary.marker_path = OUTPUT + "marker.json"
	for path in SevenSlotSaveBoundary.paths().values():
		assert(path.begins_with(OUTPUT), "All save writes stay isolated")
		for candidate in [path, path + ".tmp"]:
			if FileAccess.file_exists(candidate): assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate)) == OK)
	call_deferred("run")

func settle() -> void:
	for i in 6: await process_frame

func capture(label: String) -> void:
	await settle()
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(OUTPUT + label + ".png") == OK)

func text_of(node: Node) -> String:
	var result := ""
	if node is RichTextLabel: result += node.get_parsed_text() + "\n"
	elif node is Label: result += node.text + "\n"
	for child in node.get_children(): result += text_of(child)
	return result

func check_panels(screen: Node, mode: String, secondary: bool) -> float:
	await settle()
	var subclass: Control = screen.find_child("ActiveTalentsPanel", true, false)
	var stats: Control = screen.find_child("CharacterStatsPanel", true, false)
	assert(subclass != null and stats != null)
	var text := text_of(subclass)
	assert(text.contains("Subclass") and not text.contains("Active Talents"), "Renamed card")
	assert(not text.contains("Intrinsic:") and not text.contains(" talents selected") and not text.contains(" Talents\n"), "Subclass names only")
	assert(text.contains("none") != secondary, "Missing secondary has none placeholder")
	assert(subclass._talents_box is HBoxContainer, "One subclass line")
	assert(subclass._talents_box.get_child_count() == 3, "Two subclasses and divider")
	var primary: Control = subclass.find_child("PrimarySubclass",true,false)
	var second: Control = subclass.find_child("SecondarySubclass",true,false)
	assert(is_equal_approx(primary.global_position.y,second.global_position.y), "Subclass icons share line")
	assert(primary.get_global_rect().end.x < second.global_position.x, "Inline subclass groups do not overlap")
	assert(subclass.get_global_rect().encloses(subclass._talents_box.get_global_rect()), "Full names fit card")
	assert(subclass._open_button.text == "Talent Trees", "Talent access retained")
	if not secondary:
		var row: Node = subclass.find_child("SecondarySubclass", true, false)
		assert(row != null and row.get_child(0) is ColorRect, "Gray square placeholder")
		var color: Color = row.get_child(0).color
		assert(is_equal_approx(color.r, color.g) and is_equal_approx(color.g, color.b), "Neutral gray")
	for panel in [subclass, stats]:
		assert(Rect2(0,0,1600,900).encloses(panel.get_global_rect()), "Panel viewport fit")
	assert(stats.size.y > subclass.size.y * 2.0, "Freed space belongs to character sheet")
	assert(not stats.get_global_rect().intersects(subclass.get_global_rect()), "Panels do not overlap")
	var stat_text: String = stats._stats_label.get_parsed_text()
	for label in ["Weapon Damage", "Crit Chance", "Cooldown Reduction", "Increased Buff Duration", "Crits Apply Penetration", "Crits Apply Potency", "Magic Find"]:
		assert(stat_text.contains(label), "Retained stat: " + label)
	var expected := ["Physical Damage", "Weapon Damage", "Bonus Physical Damage", "Physical Damage Increase", "Attack Speed", "Crit Chance", "Crit Damage", "Retrigger Chance", "Crits Apply Penetration", "Shred Chance", "Shred Value", "Elemental Damage", "Elemental Damage Increase", "Base Poison Damage", "Base Tick Rate", "Poison Stack Cap", "Crits Apply Poison", "Crits Apply Potency", "Decay Chance", "Decay Value", "Utility", "Increased Stacks", "Cooldown Reduction", "Increased Buff Duration", "Rewards", "Increased Gold", "Magic Find", "Shop Discount"]
	var actual := stat_text.split("\n", false)
	assert(actual.size() == expected.size(), "Exactly requested stats and sections")
	for index in expected.size():
		assert(actual[index].split(":")[0] == expected[index], "Stat order: " + expected[index])
	await capture(mode + ("_two_subclasses" if secondary else "_one_subclass"))
	var bar: VScrollBar = stats._stats_label.get_v_scroll_bar()
	bar.value = bar.max_value
	await settle()
	if bar.visible:
		assert(is_equal_approx(bar.value, bar.max_value - bar.page), "Character sheet reaches final stat")
		await capture(mode + "_stats_bottom")
	evidence[mode + str(secondary)] = {"subclass": str(subclass.get_global_rect()), "character_stats": str(stats.get_global_rect()), "subclass_text": text, "stats_text": stat_text, "stats_scroll_max": bar.max_value, "stats_scroll_page": bar.page}
	bar.value = 0
	return subclass.size.y

func check_talents(screen: Node, mode: String) -> void:
	var panel = screen.find_child("ActiveTalentsPanel", true, false)
	panel._open_button.pressed.emit()
	await settle()
	assert(screen._talent_overlay != null and screen._talent_overlay.visible, "Talent Trees button opens tree")
	if mode == "practice":
		var secondary_panel: Control = screen.find_child("SecondaryTreePanel",true,false)
		assert(secondary_panel != null and text_of(secondary_panel).contains("Choose a secondary subclass"), "Practice secondary prompt")
		assert(secondary_panel.find_child("SecondaryTreeOption",true,false) != null, "Dropdown retained")
		assert(secondary_panel.find_children("SecondaryChoice_*","",true,false).is_empty(), "Duplicate choice cards removed")
	await capture(mode + "_talent_tree")
	screen._talent_overlay.hide()

func check_practice_gear(room: Node) -> void:
	assert(not text_of(room.find_child("PracticeGearPanel",true,false)).contains("Equipment"), "Equipment heading removed")
	for slot in GearItem.universal_slot_order():
		var source: GearItem = null
		for candidate in LegendaryCatalog.all_items():
			if candidate.slot == slot:
				source = candidate
				break
		assert(source != null, "Slot has Legendary fixture")
		room._state.equip_legendary(source)
		await settle()
		var button: Button = room._gear_slot_buttons[slot]
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_RIGHT
		click.pressed = true
		room._state.allocation_locked = true
		button.gui_input.emit(click)
		assert(room._state.equipped_gear().has(source), "Playback lock preserves gear")
		room._state.allocation_locked = false
		button.gui_input.emit(click)
		await settle()
		assert(room._state.get("equipped_" + GearItem.SlotType.keys()[slot].to_lower()) == null, "Right click clears Legendary slot")
		assert(not room._gear_editor_overlay.visible, "Right click does not open editor")
		var shell: GearItem = room._state.get("practice_" + GearItem.SlotType.keys()[slot].to_lower())
		room._state.set_slot_rarity(shell, GearItem.Tier.MASTER)
		button.gui_input.emit(click)
		await settle()
		assert(room._state.get("equipped_" + GearItem.SlotType.keys()[slot].to_lower()) == null, "Right click clears custom slot")
	room._weapon_slot_button.pressed.emit()
	assert(room._gear_editor_title.text == "Weapon", "Weapon title simplified")
	room._on_editor_rarity_selected(room._gear_rarity_option.get_item_index(GearItem.Tier.LEGENDARY))
	await settle()
	assert(room._legendary_details.visible and not text_of(room._legendary_details).contains("Fixed Legendary stats"), "Legendary details keep stats only")
	assert(room._legendary_details.find_children("*","TextureRect",true,false).is_empty(), "Duplicate Legendary icon removed")
	assert(text_of(room._legendary_details).length() > 10, "Legendary stats retained")
	await capture("practice_weapon_legendary")
	room._gear_editor_overlay.hide()
	await capture("practice_gear")

func run() -> void:
	root.size = Vector2i(1600,900)
	root.gui_embed_subwindows = true
	state = root.get_node("BuildState")
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_new_game_pressed(1928)
	var registry := BuildContentRegistry.adventure()
	state.set_class(registry.classes["class.rogue"])
	assert(state.configure_ranked_build(registry.trees["tree.bladedancer"]))
	game._show_combat_screen()
	await settle()
	var screen: Node = game._current_screen
	dismiss(screen)
	var one_height := await check_panels(screen,"adventure",false)
	await check_talents(screen,"adventure")
	state.completed_contract_count = 1
	state.run_phase = state.RunPhase.CONTRACT_OFFER
	var choices: Array[SubclassTree] = state.secondary_subclass_choices()
	assert(not choices.is_empty(), "Earned subclass choices present")
	assert(state.choose_secondary_tree(choices[0]), "Choose secondary: " + state.last_build_error)
	dismiss(screen)
	var two_height := await check_panels(screen,"adventure",true)
	assert(is_equal_approx(one_height,two_height), "Subclass height independent of second role")
	game._on_contract_test_pressed(424242,45,"tree.assassin","tree.shadow")
	await settle()
	screen = game._current_screen
	dismiss(screen)
	state.equip(load("res://data/gear/arctic_mittens.tres"))
	state.equip(load("res://data/gear/golden_greeves.tres"))
	await check_panels(screen,"test",true)
	var dense_stats: String = screen.find_child("CharacterStatsPanel",true,false)._stats_label.get_parsed_text()
	for label in ["Cooldown Reduction: 20%", "Increased Buff Duration: +25%"]:
		assert(dense_stats.contains(label), "Equipped stat/effect visible: " + label)
	game.queue_free()
	await settle()
	state.reset()
	var room = load("res://scenes/training_room/training_room.tscn").instantiate()
	root.add_child(room)
	await settle()
	room._setup_autosave = false
	var room_text := text_of(room)
	assert(not room_text.contains("Generated Target") and not room_text.contains("Generate Target"), "Redundant heading removed")
	for node in room.find_children("*", "Button", true, false):
		assert(not node.text.begins_with("Carried Gear"), "Carried Gear button removed")
	assert(room.find_child("PracticeLogo",true,false) == null, "Practice corner logo removed")
	one_height = await check_panels(room,"practice",false)
	await check_talents(room,"practice")
	assert(room._state.set_secondary_tree(room._state.content_registry.trees["tree.thief"]))
	two_height = await check_panels(room,"practice",true)
	assert(is_equal_approx(one_height,two_height), "Practice Subclass height fixed")
	await check_practice_gear(room)
	var view = room._combat_view
	var tick: Label = view._spawn_text_popup("Poison 128.0",UIColors.TEXT_POISON,view._poison_tick_font_size(),false,0.8,true)
	var target: Vector2 = view._combat_stage.enemy_popup_global_position()
	var popup: Rect2 = tick.get_global_rect()
	assert(popup.get_center().distance_to(target) < 180, "Poison tick close to target")
	assert(popup.position.y < room._fight_button.global_position.y - 80, "Poison tick above action footer")
	assert(Rect2(0,0,1600,900).encloses(popup), "Poison popup viewport fit")
	evidence["poison"] = {"popup":str(popup),"target":str(target),"footer":str(room._fight_button.get_global_rect())}
	# Stop only this fixture's animation so the review image shows its initial placement.
	for tween in get_processed_tweens():
		if tween.is_valid(): tween.pause()
	await capture("practice_poison_tick")
	SaveSystem.write_json(OUTPUT + "geometry.json",evidence)
	room.queue_free()
	await settle()
	state.reset()
	print("M9 PLAYTEST LAYOUT PASS")
	quit()
