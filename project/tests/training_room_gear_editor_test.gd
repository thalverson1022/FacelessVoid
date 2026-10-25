extends SceneTree
## Headless check for the Practice Room paper-doll gear editor: clicking an
## equipment slot opens that slot's focused Rarity/stat popup, choosing a
## slot's Rarity fixes a real Phase 5 affix shape, picking a stat per slot
## auto-fills a real tier value while staying editable, the weapon slot can
## swap to Legendary (showing a Legendary-name dropdown instead of affix rows)
## and back, and none of it ever touches the real BuildState singleton. Run
## with:
##   godot --headless -s res://tests/training_room_gear_editor_test.gd


func _initialize() -> void:
	var build_state = root.get_node("BuildState")

	var game_root_scene: PackedScene = load("res://scenes/game_root.tscn")
	var game_root = game_root_scene.instantiate()
	root.add_child(game_root)
	await process_frame

	# Real Adventure gear, set after game_root's own startup reset (see
	# training_room_entry_test.gd for why this must happen after, not
	# before).
	var rogue: ClassDef = load("res://data/classes/rogue.tres")
	build_state.set_class(rogue)
	var real_equipped_weapon_before: GearItem = build_state.equipped_weapon
	var real_inventory_before: Array[GearItem] = build_state.inventory.duplicate()

	var title = game_root._current_screen
	title.training_room_pressed.emit()
	await process_frame
	var training_room = game_root._current_screen

	var character_stats_panel = training_room.find_child("CharacterStatsPanel", true, false)
	assert(character_stats_panel != null)

	# -- Entering Practice Room starts with no gear equipped. Rarity-first
	# defaults are applied only after the player chooses Basic/Master/Cursed. --
	print("Practice Room starts with no equipped items (expect true): %s" % (
		training_room._state.equipped_gear().is_empty()
	))
	assert(training_room._state.equipped_weapon == null)
	assert(training_room._state.equipped_helm == null)
	assert(training_room._state.equipped_armor == null)
	assert(training_room._state.equipped_trinket == null)
	assert(training_room._state.equipped_charm == null)
	assert(training_room._state.equipped_gear().is_empty())
	assert(training_room._state.practice_weapon.affixes.is_empty())
	assert(training_room._state.practice_helm.affixes.is_empty())
	assert(training_room._state.practice_armor.affixes.is_empty())
	assert(training_room._state.practice_trinket.affixes.is_empty())
	assert(training_room._state.practice_charm.affixes.is_empty())
	assert(training_room._weapon_slot_button.tooltip_text == "Weapon: Empty")
	assert(training_room._helm_slot_button.tooltip_text == "Helm: Empty")
	assert(training_room._armor_slot_button.tooltip_text == "Armor: Empty")
	assert(not training_room._helm_slot_button.disabled)
	assert(not training_room._armor_slot_button.disabled)
	assert(training_room._trinket_slot_button.tooltip_text == "Trinket: Empty")
	assert(training_room._charm_slot_button.tooltip_text == "Charm: Empty")
	var practice_doll := training_room._helm_slot_button.get_parent() as VBoxContainer
	assert(practice_doll != null)
	var practice_middle_row := practice_doll.get_child(1) as HBoxContainer
	assert(practice_middle_row != null and practice_middle_row.get_child_count() == 3)
	var practice_right_stack := practice_middle_row.get_child(2) as VBoxContainer
	assert(practice_right_stack != null and practice_right_stack.get_child_count() == 2)
	assert(practice_right_stack.get_child(0) == training_room._charm_slot_button)
	assert(practice_right_stack.get_child(1) == training_room._trinket_slot_button)
	assert(not training_room._state.is_weapon_legendary())

	training_room._show_gear_slot_editor("Weapon", training_room._state.practice_weapon, true)
	await process_frame
	assert(training_room._gear_editor_overlay.visible)
	assert(training_room._gear_editor_title.text == "Weapon Gear")
	assert(training_room._gear_rarity_option.get_selected_id() == training_room.NONE_RARITY_ID)
	assert(_rarity_ids(training_room) == [
		training_room.NONE_RARITY_ID,
		GearItem.Tier.CRUDE,
		GearItem.Tier.BASIC,
		GearItem.Tier.MASTER,
		GearItem.Tier.EPIC,
		GearItem.Tier.CURSED,
		GearItem.Tier.CHAOS,
		GearItem.Tier.UNIQUE,
		GearItem.Tier.LEGENDARY,
	])
	_select_rarity(training_room, GearItem.Tier.CRUDE)
	await process_frame
	assert(training_room._state.equipped_weapon == training_room._state.practice_weapon)
	assert(training_room._state.practice_weapon.tier == GearItem.Tier.CRUDE)
	assert(training_room._state.practice_weapon.affixes.is_empty())
	assert(character_stats_panel._stats_label.text.contains("Weapon Damage: 16-20"))

	# -- Rarity -> Master resizes to 2 affixes --
	_select_rarity(training_room, GearItem.Tier.MASTER)
	await process_frame
	print("weapon affixes after Master=%d (expect 2)" % training_room._state.practice_weapon.affixes.size())
	assert(training_room._state.equipped_weapon == training_room._state.practice_weapon)
	assert(training_room._state.practice_weapon.affixes.size() == 2)
	assert(training_room._weapon_slot_button.get_node("Icon").texture == GearIcons.MASTER_WEAPON_ICON)
	assert(training_room._weapon_slot_button.tooltip_text.contains("Custom Weapon"))
	var weapon_slot_tooltip_button := training_room._weapon_slot_button as GearCompareButton
	assert(weapon_slot_tooltip_button != null)
	var rich_master_tooltip: Control = weapon_slot_tooltip_button._make_custom_tooltip("")
	var rich_master_text := _rich_tooltip_text(rich_master_tooltip)
	print("Practice Room rich weapon tooltip: %s" % rich_master_text)
	assert(rich_master_text.contains("[font_size=%d][b][color=#%s]" % [
		CardStyle.TOOLTIP_RICH_MAX_ROLL_FONT_SIZE,
		CardStyle.STAT_COLOR_BASIC.to_html(false),
	]))
	rich_master_tooltip.free()
	var default_base_modifier: StatModifier = training_room._state.practice_weapon.affixes[0]
	var default_percent_modifier: StatModifier = training_room._state.practice_weapon.affixes[1]
	assert(default_base_modifier.stat_id == StatCatalog.BASE_DAMAGE)
	assert(is_equal_approx(default_base_modifier.value, _max_value(
		StatCatalog.BASE_DAMAGE, GearItem.SlotType.WEAPON, GearItem.Tier.MASTER
	)))
	assert(default_percent_modifier.stat_id == StatCatalog.PERCENT_PHYSICAL_DAMAGE)
	assert(is_equal_approx(default_percent_modifier.value, _max_value(
		StatCatalog.PERCENT_PHYSICAL_DAMAGE, GearItem.SlotType.WEAPON, GearItem.Tier.MASTER
	)))
	var default_base_affix_row := training_room._gear_affix_column.get_child(0) as HBoxContainer
	var default_base_value_spin := default_base_affix_row.get_child(1) as SpinBox
	assert(default_base_value_spin.rounded)
	assert(is_equal_approx(default_base_value_spin.step, 1.0))
	assert(is_equal_approx(default_base_value_spin.value, 9.0))

	# -- Picking a stat auto-fills the max real Master value for that stat --
	var modifier: StatModifier = training_room._state.practice_weapon.affixes[0]
	var stats_text_before_edit: String = character_stats_panel._stats_label.text
	var stat_option := _make_stat_option_button(GearGenerator.AFFIX_POOL)
	stat_option.select(stat_option.get_item_index(StatModifier.StatType.PHYSICAL_DAMAGE))
	training_room._on_affix_stat_selected(stat_option.get_selected(), training_room._state.practice_weapon, 0, stat_option)
	await process_frame
	print("auto-filled stat_id=%s category=%d op=%d value=%.2f (expect %s, %d, %d, %.2f)" % [
		modifier.stat_id, modifier.category, modifier.operation, modifier.value,
		StatCatalog.PERCENT_PHYSICAL_DAMAGE, StatModifier.StatCategory.BASIC,
		StatModifier.OperationType.ADD, _max_value(StatCatalog.PERCENT_PHYSICAL_DAMAGE, GearItem.SlotType.WEAPON, GearItem.Tier.MASTER),
	])
	assert(modifier.stat_id == StatCatalog.PERCENT_PHYSICAL_DAMAGE)
	assert(modifier.category == StatModifier.StatCategory.BASIC)
	assert(modifier.operation == StatModifier.OperationType.ADD)
	assert(is_equal_approx(modifier.value, _max_value(StatCatalog.PERCENT_PHYSICAL_DAMAGE, GearItem.SlotType.WEAPON, GearItem.Tier.MASTER)))
	var first_affix_row := training_room._gear_affix_column.get_child(0) as HBoxContainer
	var first_value_spin := first_affix_row.get_child(1) as SpinBox
	assert(not first_value_spin.rounded)
	assert(is_equal_approx(first_value_spin.step, 0.0001))
	assert(is_equal_approx(first_value_spin.value, modifier.value * 100.0))
	assert(character_stats_panel._stats_label.text != stats_text_before_edit)

	# -- The auto-filled value stays freely editable afterward (the raw
	# editor's original magnitude-testing power, preserved on top of the new
	# rarity-first defaults) --
	training_room._on_affix_value_changed(50.0, modifier)
	await process_frame
	_select_affix_stat(training_room, training_room._state.practice_weapon, 1, StatCatalog.BASE_ELEMENTAL_DAMAGE)
	await process_frame
	var base_elemental_modifier: StatModifier = training_room._state.practice_weapon.affixes[1]
	assert(is_equal_approx(base_elemental_modifier.value, _max_value(
		StatCatalog.BASE_ELEMENTAL_DAMAGE, GearItem.SlotType.WEAPON, GearItem.Tier.MASTER
	)))
	var base_elemental_affix_row := training_room._gear_affix_column.get_child(1) as HBoxContainer
	var base_elemental_value_spin := base_elemental_affix_row.get_child(1) as SpinBox
	assert(base_elemental_value_spin.rounded)
	assert(is_equal_approx(base_elemental_value_spin.step, 1.0))
	assert(is_equal_approx(base_elemental_value_spin.value, round(base_elemental_modifier.value)))
	var resolved := BuildResolver.resolve_stats(
		training_room._state.selected_class, training_room._state.selected_trees,
		training_room._state.selected_talents, training_room._state.equipped_gear()
	)
	var expected_physical_multiplier := 1.0 + _sum_stat_value(training_room._state.practice_weapon, StatCatalog.PERCENT_PHYSICAL_DAMAGE)
	print("resolved physical_damage_multiplier after hand-edit=%.2f (expect %.2f)" % [
		resolved.physical_damage_multiplier,
		expected_physical_multiplier,
	])
	assert(is_equal_approx(resolved.physical_damage_multiplier, expected_physical_multiplier))

	# -- New Phase 5 rarities are available and create their expected shapes --
	_select_rarity(training_room, GearItem.Tier.EPIC)
	await process_frame
	print("weapon affixes after Epic=%d (expect 3)" % training_room._state.practice_weapon.affixes.size())
	assert(training_room._state.practice_weapon.affixes.size() == 3)
	assert(_count_category(training_room._state.practice_weapon, StatModifier.StatCategory.BASIC) == 2)
	assert(_count_category(training_room._state.practice_weapon, StatModifier.StatCategory.RARE) == 1)
	var rare_modifier: StatModifier = training_room._state.practice_weapon.affixes[2]
	assert(rare_modifier.category == StatModifier.StatCategory.RARE)
	assert(is_equal_approx(rare_modifier.value, _max_value(
		rare_modifier.stat_id, GearItem.SlotType.WEAPON, GearItem.Tier.EPIC, false, StatCatalog.CATEGORY_RARE
	)))
	assert(_icon_path(training_room._state.practice_weapon) == "res://assets/Items/Rogue/Generated/rogue_dagger_epic.png")

	_select_rarity(training_room, GearItem.Tier.CURSED)
	await process_frame
	print("weapon affixes after Cursed=%d (expect 4)" % training_room._state.practice_weapon.affixes.size())
	assert(training_room._state.practice_weapon.affixes.size() == 4)
	var downside_modifier: StatModifier = training_room._state.practice_weapon.affixes[3]
	print("cursed downside stat in drawback pool (expect true): %s" % StatCatalog.drawback_stat_ids_for_slot(GearItem.SlotType.WEAPON).has(downside_modifier.stat_id))
	assert(StatCatalog.drawback_stat_ids_for_slot(GearItem.SlotType.WEAPON).has(downside_modifier.stat_id))
	assert(downside_modifier.category == StatModifier.StatCategory.DRAWBACK)
	assert(downside_modifier.value < 0.0)
	assert(is_equal_approx(downside_modifier.value, _max_value(
		downside_modifier.stat_id, GearItem.SlotType.WEAPON, GearItem.Tier.CURSED, true
	)))

	_select_rarity(training_room, GearItem.Tier.CHAOS)
	await process_frame
	print("weapon affixes after Chaos=%d (expect %d)" % [training_room._state.practice_weapon.affixes.size(), GearGenerator.CHAOS_ROLL_COUNT])
	assert(training_room._state.practice_weapon.affixes.size() == GearGenerator.CHAOS_ROLL_COUNT)
	assert(_count_category(training_room._state.practice_weapon, StatModifier.StatCategory.DRAWBACK) == 1)
	_assert_chaos_dropdowns_expose_all_slot_stats(training_room, training_room._state.practice_weapon)
	assert(_icon_path(training_room._state.practice_weapon) == "res://assets/Items/Rogue/Generated/rogue_dagger_chaos.png")

	_select_rarity(training_room, GearItem.Tier.UNIQUE)
	await process_frame
	print("weapon affixes after Unique=%d (expect 5)" % training_room._state.practice_weapon.affixes.size())
	assert(training_room._state.practice_weapon.affixes.size() == 5)
	assert(_count_category(training_room._state.practice_weapon, StatModifier.StatCategory.SPECIAL) == 1)
	assert(_icon_path(training_room._state.practice_weapon) == "res://assets/Items/Rogue/Generated/rogue_dagger_unique.png")

	# -- Rarity -> Legendary: affix rows disappear, Legendary dropdown shows,
	# equipping picks a real catalog item --
	var wyvern: GearItem = load("res://data/gear/wyvern_kriss.tres")
	var legendary_index := LegendaryCatalog.all_items().find(wyvern)
	assert(legendary_index >= 0)
	_select_rarity(training_room, GearItem.Tier.LEGENDARY)
	await process_frame
	training_room._gear_legendary_option.select(legendary_index)
	training_room._on_weapon_legendary_selected(legendary_index)
	await process_frame
	assert(training_room._state.is_weapon_legendary())
	assert(training_room._state.equipped_weapon == wyvern)
	print("weapon affix rows hidden while Legendary equipped (expect true): %s" % (not training_room._gear_affix_column.visible))
	assert(not training_room._gear_affix_column.visible)
	assert(training_room._gear_legendary_option.visible)
	assert(training_room._weapon_slot_button.get_node("Icon").texture == GearIcons.WYVERN_KRISS_ICON)
	_assert_all_legendary_dropdown_options(training_room)
	for i in LegendaryCatalog.all_items().size():
		var legendary_item: GearItem = LegendaryCatalog.all_items()[i]
		training_room._gear_legendary_option.select(i)
		training_room._on_weapon_legendary_selected(i)
		await process_frame
		assert(training_room._state.is_weapon_legendary())
		assert(training_room._state.equipped_weapon == legendary_item)
		assert(training_room._gear_legendary_option.visible)
		assert(not training_room._gear_affix_column.visible)
		assert(training_room._gear_legendary_option.get_item_text(i) == legendary_item.display_name)
		assert(training_room._gear_legendary_option.tooltip_text.contains(legendary_item.display_name))
		assert(training_room._gear_legendary_option.tooltip_text.contains("Legendary Weapon / Dagger"))
		assert(training_room._gear_legendary_option.tooltip_text.contains(LegendaryCatalog.effect_text(legendary_item)))
		assert(training_room._weapon_slot_button.tooltip_text.contains(legendary_item.display_name))
		assert(training_room._weapon_slot_button.tooltip_text.contains(LegendaryCatalog.effect_text(legendary_item)))
		assert(training_room._weapon_slot_button.get_node("Icon").texture == GearIcons.icon_for(legendary_item))
	# Bug fix: the rarity dropdown must stay enabled even in Legendary mode --
	# it's the only way back to Basic/Master/Cursed since the old separate
	# "Custom Weapon" button was removed.
	assert(not training_room._gear_rarity_option.disabled)

	# -- Rarity -> Basic switches back out of Legendary mode and re-sizes the
	# practice item fresh --
	_select_rarity(training_room, GearItem.Tier.BASIC)
	await process_frame
	assert(not training_room._state.is_weapon_legendary())
	print("weapon back to Basic with 1 affix (expect true): %s" % (
		training_room._state.practice_weapon.tier == GearItem.Tier.BASIC
		and training_room._state.practice_weapon.affixes.size() == 1
	))
	assert(training_room._state.equipped_weapon == training_room._state.practice_weapon)
	assert(training_room._state.practice_weapon.tier == GearItem.Tier.BASIC)
	assert(training_room._state.practice_weapon.affixes.size() == 1)

	# -- Helm/armor/trinket/charm slots have no Legendary option and are always
	# the rarity-driven editor, independent of the weapon slot --
	training_room._show_gear_slot_editor("Helm", training_room._state.practice_helm, false)
	await process_frame
	assert(_rarity_ids(training_room) == [
		training_room.NONE_RARITY_ID,
		GearItem.Tier.BASIC,
		GearItem.Tier.MASTER,
		GearItem.Tier.EPIC,
		GearItem.Tier.CURSED,
		GearItem.Tier.CHAOS,
		GearItem.Tier.UNIQUE,
	])
	_select_rarity(training_room, GearItem.Tier.MASTER)
	await process_frame
	assert(training_room._state.equipped_helm == training_room._state.practice_helm)
	assert(training_room._state.practice_helm.affixes.size() == 2)
	assert(training_room._helm_slot_button.get_node("Icon").texture != null)

	training_room._show_gear_slot_editor("Armor", training_room._state.practice_armor, false)
	await process_frame
	assert(training_room._gear_rarity_option.item_count == 7)
	_select_rarity(training_room, GearItem.Tier.BASIC)
	await process_frame
	assert(training_room._state.equipped_armor == training_room._state.practice_armor)
	assert(training_room._state.practice_armor.affixes.size() == 1)
	assert(training_room._armor_slot_button.get_node("Icon").texture != null)

	training_room._show_gear_slot_editor("Charm", training_room._state.practice_charm, false)
	await process_frame
	_select_rarity(training_room, GearItem.Tier.EPIC)
	await process_frame
	_select_affix_stat(training_room, training_room._state.practice_charm, 0, StatCatalog.INCREASED_GOLD)
	await process_frame
	_select_affix_stat(training_room, training_room._state.practice_charm, 1, StatCatalog.CRIT_DAMAGE)
	await process_frame
	_select_affix_stat(training_room, training_room._state.practice_charm, 2, StatCatalog.CRIT_APPLIES_POTENCY)
	await process_frame
	var gold_modifier: StatModifier = training_room._state.practice_charm.affixes[0]
	var crit_modifier: StatModifier = training_room._state.practice_charm.affixes[1]
	var potency_modifier: StatModifier = training_room._state.practice_charm.affixes[2]
	assert(is_equal_approx(gold_modifier.value, _max_value(
		StatCatalog.INCREASED_GOLD, GearItem.SlotType.CHARM, GearItem.Tier.EPIC
	)))
	assert(is_equal_approx(crit_modifier.value, _max_value(
		StatCatalog.CRIT_DAMAGE, GearItem.SlotType.CHARM, GearItem.Tier.EPIC
	)))
	assert(is_equal_approx(potency_modifier.value, _max_value(
		StatCatalog.CRIT_APPLIES_POTENCY, GearItem.SlotType.CHARM, GearItem.Tier.EPIC, false, StatCatalog.CATEGORY_RARE
	)))
	var practice_stats_text: String = character_stats_panel._stats_label.text
	assert(practice_stats_text.contains("Increased Gold:"))
	assert(practice_stats_text.contains("Crit to Potency: %.2f%%" % (potency_modifier.value * 100.0)))

	training_room._show_gear_slot_editor("Trinket", training_room._state.practice_trinket, false)
	await process_frame
	assert(training_room._gear_rarity_option.item_count == 7)
	_select_rarity(training_room, GearItem.Tier.MASTER)
	await process_frame
	print("trinket affixes after Master=%d (expect 2)" % training_room._state.practice_trinket.affixes.size())
	assert(training_room._state.equipped_trinket == training_room._state.practice_trinket)
	assert(training_room._state.practice_trinket.affixes.size() == 2)
	assert(training_room._trinket_slot_button.get_node("Icon").texture == GearIcons.MASTER_TRINKET_ICON)
	assert(training_room._state.practice_trinket.display_name == "Custom Ring")
	assert(training_room._state.practice_charm.display_name == "Custom Necklace")

	# -- Rarity -> None (user-requested) empties the slot entirely and the
	# dropdown reflects "None" selected --
	_select_rarity(training_room, training_room.NONE_RARITY_ID)
	await process_frame
	print("trinket affixes after None=%d (expect 0)" % training_room._state.practice_trinket.affixes.size())
	assert(training_room._state.equipped_trinket == null)
	assert(training_room._state.practice_trinket.affixes.is_empty())
	print("trinket rarity dropdown shows None selected (expect true): %s" % (
		training_room._gear_rarity_option.get_selected_id() == training_room.NONE_RARITY_ID
	))
	assert(training_room._gear_rarity_option.get_selected_id() == training_room.NONE_RARITY_ID)

	# -- Original overflow case: every current slot can be Cursed with four
	# affixes, but the right-panel gear card stays compact because only the
	# selected slot's controls live in the popup. --
	training_room._show_gear_slot_editor("Weapon", training_room._state.practice_weapon, true)
	_select_rarity(training_room, GearItem.Tier.CURSED)
	await process_frame
	training_room._show_gear_slot_editor("Helm", training_room._state.practice_helm, false)
	_select_rarity(training_room, GearItem.Tier.CURSED)
	await process_frame
	training_room._show_gear_slot_editor("Armor", training_room._state.practice_armor, false)
	_select_rarity(training_room, GearItem.Tier.CURSED)
	await process_frame
	training_room._show_gear_slot_editor("Trinket", training_room._state.practice_trinket, false)
	_select_rarity(training_room, GearItem.Tier.CURSED)
	await process_frame
	training_room._show_gear_slot_editor("Charm", training_room._state.practice_charm, false)
	_select_rarity(training_room, GearItem.Tier.CURSED)
	await process_frame
	assert(training_room._state.equipped_gear().size() == 5)
	assert(training_room._state.practice_weapon.affixes.size() == 4)
	assert(training_room._state.practice_helm.affixes.size() == 4)
	assert(training_room._state.practice_armor.affixes.size() == 4)
	assert(training_room._state.practice_trinket.affixes.size() == 4)
	assert(training_room._state.practice_charm.affixes.size() == 4)
	assert(training_room._gear_affix_column.get_child_count() == 4)
	var gear_panel: Control = training_room.find_child("PracticeGearPanel", true, false)
	var viewport_rect := Rect2(Vector2.ZERO, training_room.get_viewport().get_visible_rect().size)
	assert(_rect_contains(viewport_rect, gear_panel.get_global_rect()))
	assert(_rect_contains(viewport_rect, training_room._gear_affix_column.get_global_rect()))

	# -- Isolation: none of this touched the real BuildState's gear --
	print("real equipped weapon unchanged (expect true): %s" % (build_state.equipped_weapon == real_equipped_weapon_before))
	assert(build_state.equipped_weapon == real_equipped_weapon_before)
	assert(build_state.inventory == real_inventory_before)

	print("")
	print("Practice Room gear editor check: OK")
	quit()


func _make_stat_option_button(pool: Array[StatModifier.StatType]) -> OptionButton:
	var option := OptionButton.new()
	for stat_type in pool:
		option.add_item(StatModifierFormatter.STAT_NAMES[stat_type], stat_type)
		option.set_item_metadata(option.item_count - 1, StatCatalog.legacy_stat_id(stat_type))
	return option


func _select_rarity(training_room: Control, tier_id: int) -> void:
	var index: int = training_room._gear_rarity_option.get_item_index(tier_id)
	assert(index >= 0)
	training_room._gear_rarity_option.select(index)
	training_room._on_editor_rarity_selected(index)


func _select_affix_stat(training_room: Control, item: GearItem, affix_index: int, stat_id: String) -> void:
	var row := training_room._gear_affix_column.get_child(affix_index) as HBoxContainer
	assert(row != null)
	var stat_option := row.get_child(0) as OptionButton
	assert(stat_option != null)
	for i in stat_option.item_count:
		if String(stat_option.get_item_metadata(i)) == stat_id:
			stat_option.select(i)
			training_room._on_affix_stat_selected(i, item, affix_index, stat_option)
			return
	assert(false, "Expected stat option for %s." % stat_id)


func _rarity_ids(training_room: Control) -> Array[int]:
	var ids: Array[int] = []
	for i in training_room._gear_rarity_option.item_count:
		ids.append(training_room._gear_rarity_option.get_item_id(i))
	return ids


func _assert_all_legendary_dropdown_options(training_room: Control) -> void:
	var items := LegendaryCatalog.all_items()
	assert(items.size() == 5)
	assert(training_room._gear_legendary_option.item_count == items.size())
	for i in items.size():
		var item: GearItem = items[i]
		assert(training_room._gear_legendary_option.get_item_text(i) == item.display_name)
		assert(item.slot == GearItem.SlotType.WEAPON)
		assert(item.tier == GearItem.Tier.LEGENDARY)
		assert(item.source_kind == GearItem.SourceKind.LEGENDARY)


func _count_category(item: GearItem, category: StatModifier.StatCategory) -> int:
	var count := 0
	for modifier in item.affixes:
		if modifier.category == category:
			count += 1
	return count


func _assert_chaos_dropdowns_expose_all_slot_stats(training_room: Control, item: GearItem) -> void:
	for i in item.affixes.size():
		var expected := StatCatalog.drawback_stat_ids_for_slot(item.slot) if item.affixes[i].category == StatModifier.StatCategory.DRAWBACK else _chaos_stat_ids_for_slot(item.slot)
		var row := training_room._gear_affix_column.get_child(i) as HBoxContainer
		assert(row != null)
		var option := row.get_child(0) as OptionButton
		assert(option != null)
		assert(_stat_option_metadata(option) == expected)
		assert(training_room._stat_ids_for_affix_slot(item, i) == expected)


func _chaos_stat_ids_for_slot(slot: GearItem.SlotType) -> Array[String]:
	var ids: Array[String] = []
	for category in [StatCatalog.CATEGORY_BASIC, StatCatalog.CATEGORY_RARE]:
		for stat_id in StatCatalog.stat_ids_for_slot(slot, category):
			if not ids.has(stat_id):
				ids.append(stat_id)
	for stat_id in StatCatalog.drawback_stat_ids_for_slot(slot):
		if not ids.has(stat_id):
			ids.append(stat_id)
	return ids


func _stat_option_metadata(option: OptionButton) -> Array[String]:
	var ids: Array[String] = []
	for i in option.item_count:
		ids.append(String(option.get_item_metadata(i)))
	return ids


func _rich_tooltip_text(root_node: Node) -> String:
	var parts: PackedStringArray = []
	for label in root_node.find_children("*", "RichTextLabel", true, false):
		parts.append((label as RichTextLabel).text)
	return "\n".join(parts)


func _sum_stat_value(item: GearItem, stat_id: String) -> float:
	var total := 0.0
	for modifier in item.affixes:
		if StatCatalog.canonical_id_for_modifier(modifier) == stat_id:
			total += modifier.value
	return total


func _max_value(
	stat_id: String,
	slot: GearItem.SlotType,
	tier: GearItem.Tier,
	is_drawback: bool = false,
	category: String = StatCatalog.CATEGORY_BASIC
) -> float:
	var max_roll := GearGenerator.max_rolled_value_for_stat_id(
		stat_id, slot, is_drawback, tier, 1.0, 0, category
	)
	assert(bool(max_roll.get("ok", false)))
	return float(max_roll["value"])


func _icon_path(item: GearItem) -> String:
	var texture := GearIcons.icon_for(item)
	assert(texture != null)
	return texture.resource_path


func _rect_contains(outer: Rect2, inner: Rect2) -> bool:
	return (
		inner.position.x >= outer.position.x
		and inner.position.y >= outer.position.y
		and inner.end.x <= outer.end.x
		and inner.end.y <= outer.end.y
	)
