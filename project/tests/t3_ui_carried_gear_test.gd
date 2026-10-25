extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var adventure = root.get_node("BuildState")
	var inventory_before: Array = adventure.inventory.duplicate()
	game._current_screen.training_room_pressed.emit()
	await process_frame
	var screen = game._current_screen
	var state: TrainingRoomState = screen._state
	assert(state.carried_items.is_empty())
	var first := state.add_carried_item()
	assert(first != null and state.equipped_gear().is_empty())
	assert(state.set_carried_slot(first, GearItem.SlotType.ARMOR))
	state.set_slot_rarity(first, GearItem.Tier.UNIQUE)
	assert(state.equipped_gear().is_empty() and first.affixes.size() == 5)
	# Chaos numeric choices seed their actual category range, never a zero placeholder.
	var chaos := state.add_carried_item()
	assert(chaos != null)
	state.set_slot_rarity(chaos, GearItem.Tier.CHAOS)
	state.set_affix_stat(chaos, 0, "cooldown_reduction")
	assert(chaos.affixes[0].value > 0.0 and chaos.affixes[0].category == StatModifier.StatCategory.RARE)
	assert(not screen._stat_ids_for_affix_slot(chaos, 2).has("cooldown_reduction"))
	assert(state.add_carried_item() != null)
	assert(state.add_carried_item() == null and state.carried_items.size() == 3)
	screen._show_carried_editor()
	await process_frame
	assert(screen._carried_rows.get_child_count() == 4)
	assert(screen._carried_rows.get_child(3).disabled)
	screen._show_gear_slot_editor("Carried 1", first, false)
	await process_frame
	assert(screen._carried_slot_row.visible)
	assert(screen._gear_rarity_option.get_item_index(screen.NONE_RARITY_ID) == -1)
	# Existing removed pool affix stays visible as legacy without reentering pool.
	var legacy := StatModifier.new()
	legacy.stat_id = "increased_attack_speed"
	legacy.value = 0.1234
	legacy.category = StatModifier.StatCategory.RARE
	first.affixes[3] = legacy
	state.notify_gear_edited()
	await process_frame
	var option: OptionButton = screen._gear_affix_column.get_child(3).get_child(0)
	assert(option.get_item_text(option.selected).begins_with("Legacy:"))
	assert(is_equal_approx(legacy.value, 0.1234))
	var duration := StatModifier.new()
	duration.stat_id = "increased_buff_duration"
	duration.category = StatModifier.StatCategory.RARE
	duration.value = -0.1
	first.affixes[3] = duration
	state.notify_gear_edited()
	await process_frame
	assert(screen._gear_validation_label.visible)
	screen._on_affix_value_changed(12.3456, duration)
	assert(is_equal_approx(duration.value, 0.123456))
	assert(not screen._gear_validation_label.visible)
	assert(StatModifierFormatter.format(duration).contains("additive"))
	assert(state.remove_carried_item(1))
	assert(state.carried_items.size() == 2)
	assert(adventure.inventory == inventory_before)
	# Loss of the equipped Special removes carried import in a full-state preview.
	var special := GearItem.new()
	special.slot = GearItem.SlotType.ARMOR
	special.id = "test.inventory_economy"
	special.display_name = "Inventory Economy"
	var enabled := StatModifier.new()
	enabled.stat_id = "inventory_economy_stats"
	enabled.value = 1.0
	enabled.category = StatModifier.StatCategory.SPECIAL
	special.affixes.append(enabled)
	state.equipped_armor = special
	var economy := StatModifier.new()
	economy.stat_id = "increased_gold"
	economy.value = 0.5
	state.carried_items[1].affixes = [economy]
	var weapon := GearItem.new()
	weapon.slot = GearItem.SlotType.WEAPON
	weapon.id = "test.timing_preview"
	for pair in [["cooldown_reduction", 0.2], ["cooldown_reduction", 0.3], ["increased_buff_duration", 0.5], ["crit_applies_penetration", 0.2], ["crit_applies_potency", 0.4]]:
		var modifier := StatModifier.new()
		modifier.stat_id = pair[0]
		modifier.value = pair[1]
		weapon.affixes.append(modifier)
	state.equipped_weapon = weapon
	state.notify_gear_edited()
	await process_frame
	var stats_panel = screen.find_child("CharacterStatsPanel", true, false)
	var comparison := CardStyle.gear_comparison_lines(first, stats_panel)
	assert("\n".join(comparison).contains("Gold Reward Multiplier: 1.5000 -> 1.0000"))
	assert(state.carried_items.size() == 2 and state.equipped_armor == special)
	var stats := state.current_player_stats()
	var detail: String = load("res://scenes/combat/character_stats_panel.gd").stat_detail_text(stats)
	assert(detail.contains("minimum 1ms") and detail.contains("base 1 stack") and detail.contains("Pact"))
	assert(detail.contains("carried index 1") and detail.contains("retained factor 0.800000000"))
	assert(is_equal_approx(stats.cooldown_reduction, 0.44))
	assert(stats_panel._stats_label.text.contains("Cooldown Reduction: 44.0000%"))
	var fixed: GearItem = LegendaryCatalog.all_items()[0]
	state.carried_items.append(fixed)
	screen._show_gear_slot_editor("Carried Legendary", fixed, false)
	await process_frame
	assert(screen._gear_rarity_option.disabled and screen._carried_slot_option.disabled)
	assert(screen._gear_affix_column.get_child_count() == 1 and screen._gear_affix_column.get_child(0) is Label)
	assert(not state.set_carried_slot(fixed, GearItem.SlotType.ARMOR))
	state.set_slot_rarity(fixed, GearItem.Tier.BASIC)
	assert(fixed.tier == GearItem.Tier.LEGENDARY)
	state.remove_carried_item(2)
	screen._gear_editor_overlay.hide()
	screen._carried_overlay.hide()
	if "--visual" in OS.get_cmdline_user_args():
		await _capture("practice")
		var details: Control = stats_panel._show_stat_details()
		await _capture("details")
		details.hide()
		await process_frame
		screen._show_carried_editor()
		await _capture("carried")
		screen._show_gear_slot_editor("Carried 1", first, false)
		await _capture("affixes")
	print("PASS T3 UI carried gear, legacy editing, precision, validation and isolation")
	quit()

func _capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://reports/t3_ui_visual")
	root.get_texture().get_image().save_png("res://reports/t3_ui_visual/" + label + ".png")
