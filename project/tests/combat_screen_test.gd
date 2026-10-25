extends SceneTree
## Headless check for the new UI restructure. Drives the real scene tree the
## same way real clicks would: title -> New Adventure -> class select
## (Rogue) -> subclass select (Bladedancer) -> spend real talent points in
## talent_panel -> add real skills to the macro in skill_macro_panel ->
## press FIGHT -> confirm the combat log renders and character_stats_panel
## reflects the selected talents. Run with:
##   godot --headless -s res://tests/combat_screen_test.gd
## Same headless-only caveat as every prior UI milestone -- no rendered
## click-through available in this environment.



func _initialize() -> void:
	var build_state = root.get_node("BuildState")
	var audio_manager = root.get_node("AudioManager")

	var game_root_scene: PackedScene = load("res://scenes/game_root.tscn")
	var game_root = game_root_scene.instantiate()
	root.add_child(game_root)
	await process_frame

	# -- Title -> New Adventure --
	var title = game_root._current_screen
	# Legacy Adventure regression uses its controller directly; the M4 title disables entry.
	game_root._on_new_game_pressed()
	await process_frame

	# -- Class select: only Rogue is real; Mage/Crusader must be disabled --
	var class_select = game_root._current_screen
	var disabled_count := 0
	for child in class_select.find_children("*", "Button", true, false):
		if child.disabled:
			disabled_count += 1
	print("class select disabled buttons (expect 2, Mage+Crusader): %d" % disabled_count)
	assert(disabled_count == 2)

	var rogue: ClassDef = load("res://data/classes/rogue.tres")
	class_select._on_class_selected(rogue)
	print("selected class=%s" % build_state.selected_class.display_name)
	assert(build_state.selected_class == rogue)
	class_select.advanced.emit()
	await process_frame

	# -- Subclass select: Assassin, Bladedancer, Shadow, and Thief are real Rogue trees. --
	var subclass_select = game_root._current_screen
	disabled_count = 0
	for child in subclass_select.find_children("*", "Button", true, false):
		if child.disabled:
			disabled_count += 1
	print("subclass select disabled buttons (expect 0): %d" % disabled_count)
	assert(disabled_count == 0)
	assert(subclass_select.find_children("Icon", "TextureRect", true, false).size() == 4)

	var bladedancer: SubclassTree = rogue.trees[1]
	assert(bladedancer.display_name == "Bladedancer")
	subclass_select._on_tree_selected(bladedancer)
	print("selected trees=%d (%s)" % [build_state.selected_trees.size(), build_state.selected_trees[0].display_name])
	assert(build_state.selected_trees.size() == 1)
	assert(build_state.selected_trees[0] == bladedancer)
	subclass_select.advanced.emit()
	await process_frame

	# -- Story pass: the intro story overlay gates the very first Tavern
	# choice, before the map ever appears. --
	var combat_screen = game_root._current_screen
	print("story overlay visible right after subclass select (expect true): %s" % combat_screen._story_overlay.visible)
	assert(combat_screen._story_overlay.visible)
	assert(not combat_screen._map_overlay.visible)
	assert(combat_screen._story_overlay._story_label.text == combat_screen._story_overlay.INTRO_STORY_TEXT)
	var story_proceed_button: Button = combat_screen._story_overlay.find_child("StoryProceedButton", true, false)
	assert(story_proceed_button != null)
	var button_sfx_before: int = audio_manager.button_press_sfx_play_count
	story_proceed_button.pressed.emit()
	await process_frame
	assert(not combat_screen._story_overlay.visible)
	assert(combat_screen._map_overlay.visible)
	assert(audio_manager.button_press_sfx_play_count == button_sfx_before + 1)
	assert(combat_screen._tavern_background.visible)
	assert(combat_screen._tavern_background.texture == combat_screen.TAVERN_BACKGROUND_TEXTURE)
	assert(combat_screen._tavern_fireplace_overlay != null)
	assert(combat_screen._tavern_fireplace_overlay.visible)
	assert(combat_screen._contract_moon_bat_overlay != null)
	assert(not combat_screen._contract_moon_bat_overlay.visible)
	assert(combat_screen._tavern_fireplace_overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(combat_screen._tavern_background.get_index() < combat_screen._tavern_fireplace_overlay.get_index())
	assert(combat_screen._tavern_fireplace_overlay.get_index() < combat_screen._tavern_background_tint.get_index())

	# -- Combat dashboard: Adventure starts with 0 talent points. --
	var talent_panel = combat_screen.find_child("TalentPanel", true, false)
	var active_talents_panel = combat_screen.find_child("ActiveTalentsPanel", true, false)
	var available_skills_panel = combat_screen.find_child("AvailableSkillsPanel", true, false)
	var skill_build_panel = combat_screen.find_child("SkillBuildPanel", true, false)
	var character_stats_panel = combat_screen.find_child("CharacterStatsPanel", true, false)
	var gear_panel = combat_screen.find_child("GearPanel", true, false)
	assert(talent_panel != null and available_skills_panel != null and skill_build_panel != null and character_stats_panel != null and gear_panel != null)
	await process_frame
	assert(combat_screen._combat_stage.get_node_or_null("StageFloor") == null)
	assert(not combat_screen._combat_stage.player_actor_anchor.visible)
	assert(not combat_screen._combat_stage.enemy_actor_anchor.visible)
	assert(not combat_screen._combat_stage._player_actor_card.visible)
	assert(not combat_screen._combat_stage._enemy_actor_card.visible)
	assert(combat_screen._fight_button_row.get_parent() == combat_screen._combat_content)
	assert(combat_screen._fight_button_row.get_global_rect().position.y >= combat_screen._combat_stage.play_area_global_rect().end.y - 1.0)
	assert(absf(available_skills_panel.get_global_rect().position.y - combat_screen._combat_window.get_global_rect().end.y - combat_screen.PANEL_SEPARATION) < 1.5)
	assert(combat_screen._combat_stage._player_contact_shadow != null)
	assert(combat_screen._combat_stage._enemy_contact_shadow != null)
	assert(combat_screen._combat_stage._player_contact_shadow.visible == combat_screen._combat_stage._player_sprite.visible)
	assert(combat_screen._combat_stage._enemy_contact_shadow.visible == combat_screen._combat_stage._enemy_sprite.visible)
	assert(combat_screen._combat_stage._player_contact_shadow.z_index < combat_screen._combat_stage._player_sprite.z_index)
	assert(combat_screen._combat_stage._enemy_contact_shadow.z_index < combat_screen._combat_stage._enemy_sprite.z_index)
	assert(combat_screen._view_log_button.text == "Combat Log")
	assert(combat_screen._view_log_button.custom_minimum_size.x == combat_screen._enemy_panel.fight_button().custom_minimum_size.x)
	assert(build_state.adventure_seed >= 0)
	assert(build_state.adventure_seed <= 2147483647)
	assert(combat_screen._seed_label.text == "Seed: %d" % build_state.adventure_seed)
	build_state.set_adventure_seed(37)
	await process_frame
	assert(combat_screen._seed_label.text == "Seed: 37")
	assert(combat_screen._map_overlay.visible)
	assert(combat_screen._map_overlay._map_node_buttons.size() == RunFlow.tavern_encounter_count())
	assert(combat_screen._map_overlay._map_node_buttons[0].text == "Mouthy Drunk")
	assert(not combat_screen._map_overlay._map_node_buttons[0].disabled)
	assert(combat_screen._map_overlay._map_node_buttons[1].text == "Unknown")
	assert(combat_screen._map_overlay._map_node_buttons[1].disabled)
	assert(not combat_screen._map_overlay._map_close_button.visible)

	# -- Clicking a node only previews its flavor text; Proceed commits it.
	# The current node is highlighted as available before the click, then
	# receives the stronger selected border once previewed. Proceed remains
	# visible while a choice is pending, just disabled until preview. --
	assert(combat_screen._map_overlay._map_proceed_button.visible)
	assert(combat_screen._map_overlay._map_proceed_button.disabled)
	var tavern_schematic := combat_screen._map_overlay.find_child("TavernMapSchematic", true, false) as Control
	assert(tavern_schematic != null)
	assert(tavern_schematic.custom_minimum_size == combat_screen._map_overlay.TAVERN_MAP_SIZE)
	var tavern_edges := tavern_schematic.find_children("TavernRouteEdge", "Line2D", true, false)
	assert(tavern_edges.size() > 0)
	assert(tavern_edges[0].get_meta("edge_kind") == "tavern_path")
	assert(tavern_edges[0].get_meta("trail_dash_length") == combat_screen._map_overlay.GENERATED_EDGE_TRAIL_DASH_LENGTH)
	var mouthy_drunk_style_before: StyleBoxFlat = combat_screen._map_overlay._map_node_buttons[0].get_theme_stylebox("normal")
	assert(mouthy_drunk_style_before.bg_color == UIColors.TRANSPARENT)
	assert(mouthy_drunk_style_before.border_color == UIColors.TRANSPARENT)
	assert(combat_screen._map_overlay._map_node_buttons[0].get_meta("tavern_visual_state") == "available")
	assert(combat_screen._map_overlay._map_node_buttons[0].position.y != combat_screen._map_overlay._map_node_buttons[1].position.y)
	assert(not combat_screen._map_overlay._map_node_buttons[0].clip_contents)
	var tavern_frame: TextureRect = combat_screen._map_overlay._map_node_buttons[0].find_child("TavernBiomeFrame", true, false)
	var tavern_glow: TextureRect = combat_screen._map_overlay._map_node_buttons[0].find_child("TavernBiomeGlow", true, false)
	var tavern_text_block: RichTextLabel = combat_screen._map_overlay._map_node_buttons[0].find_child("MapTextBlock", true, false)
	var tavern_reward_stack: VBoxContainer = combat_screen._map_overlay._map_node_buttons[0].find_child("TavernRewardStack", true, false)
	assert(tavern_frame != null and tavern_frame.get_meta("texture_path") == combat_screen._map_overlay.TAVERN_NODE_FRAME_TEXTURE_PATH)
	assert(tavern_glow != null and tavern_glow.get_meta("highlight_style") == "gray_silhouette_texture")
	assert(tavern_glow.get_meta("texture_path") == combat_screen._map_overlay.TAVERN_NODE_HIGHLIGHT_TEXTURE_PATH)
	assert((tavern_glow.material as ShaderMaterial) != null)
	assert(combat_screen._map_overlay._map_node_buttons[0].find_child("MapActorMarker", true, false) == null)
	assert(combat_screen._map_overlay._map_node_buttons[0].find_child("MapRewardIconRow", true, false) == null)
	assert(tavern_text_block != null and tavern_text_block.bbcode_enabled)
	assert(tavern_text_block.text.contains("[center]"))
	assert(tavern_text_block.text.contains("Mouthy Drunk"))
	assert(tavern_reward_stack != null and tavern_reward_stack.get_child_count() == 2)
	assert(tavern_reward_stack.find_child("GeneratedTalentReward", true, false) != null)
	assert(tavern_reward_stack.find_child("GeneratedGoldReward", true, false) != null)
	var tagged_tavern_monster := Monster.new()
	tagged_tavern_monster.armor = 12
	tagged_tavern_monster.poison_resistance = 0.25
	assert(combat_screen._map_overlay._tavern_archetype_tags(tagged_tavern_monster) == ["armored", "resistant"])
	assert(combat_screen._map_overlay._map_node_buttons[0].get_theme_color("font_hover_color") == UIColors.TRANSPARENT)
	assert(combat_screen._map_overlay._map_node_buttons[0].get_theme_color("font_focus_color") == UIColors.TRANSPARENT)
	assert(combat_screen._map_overlay._map_node_buttons[0].find_child("TavernAvailablePulse", true, false) == null)
	assert(combat_screen._map_overlay._map_node_buttons[0].find_child("TavernDefeatedMarker", true, false) == null)
	combat_screen._map_overlay._map_node_buttons[0].pressed.emit()
	await process_frame
	assert(combat_screen._map_overlay.visible)
	assert(not build_state.tavern_map_choice_made)
	assert(combat_screen._map_overlay._map_proceed_button.visible)
	assert(not combat_screen._map_overlay._map_proceed_button.disabled)
	var mouthy_drunk_style_after: StyleBoxFlat = combat_screen._map_overlay._map_node_buttons[0].get_theme_stylebox("normal")
	assert(mouthy_drunk_style_after.border_color == UIColors.TRANSPARENT)
	assert(combat_screen._map_overlay._map_node_buttons[0].get_meta("tavern_visual_state") == "selected")
	print("previewed flavor text (expect Mouthy Drunk's): %s" % combat_screen._map_overlay._map_story_label.text)
	assert(combat_screen._map_overlay._map_story_label.text == "A red-faced patron decides your quiet corner is somehow his business.")
	combat_screen._map_overlay._map_node_buttons[0].pressed.emit()
	await process_frame
	assert(combat_screen._map_overlay._map_proceed_button.disabled)
	var mouthy_drunk_style_deselected: StyleBoxFlat = combat_screen._map_overlay._map_node_buttons[0].get_theme_stylebox("normal")
	assert(mouthy_drunk_style_deselected.bg_color == UIColors.TRANSPARENT)
	assert(combat_screen._map_overlay._map_node_buttons[0].get_meta("tavern_visual_state") == "available")
	assert(combat_screen._map_overlay._map_node_buttons[0].find_child("TavernAvailablePulse", true, false) == null)
	combat_screen._map_overlay._map_node_buttons[0].pressed.emit()
	await process_frame
	assert(not combat_screen._map_overlay._map_proceed_button.disabled)
	button_sfx_before = audio_manager.button_press_sfx_play_count
	combat_screen._map_overlay._map_proceed_button.pressed.emit()
	await process_frame
	assert(not combat_screen._map_overlay.visible)
	assert(build_state.tavern_map_choice_made)
	assert(audio_manager.button_press_sfx_play_count == button_sfx_before + 1)
	assert(combat_screen._combat_stage.player_actor_anchor.visible)
	assert(combat_screen._combat_stage.enemy_actor_anchor.visible)
	assert(not combat_screen._combat_stage._player_actor_card.visible)
	assert(not combat_screen._combat_stage._enemy_actor_card.visible)
	var player_anchor_point: Vector2 = combat_screen._combat_stage._sprite_anchor_point(combat_screen._combat_stage.player_actor_anchor, combat_screen._combat_stage._player_sprite, combat_screen._combat_stage._player_current_anchor_point)
	var enemy_anchor_point: Vector2 = combat_screen._combat_stage._sprite_anchor_point(combat_screen._combat_stage.enemy_actor_anchor, combat_screen._combat_stage._enemy_sprite, combat_screen._combat_stage.PEASANT_ANCHOR_POINT)
	assert(absf(player_anchor_point.x - (combat_screen._combat_stage._stage_point_for_grid(combat_screen._combat_stage.PLAYER_STAGE_GRID).x + combat_screen._combat_stage.ACTOR_GROUP_STAGE_OFFSET_PX.x)) < 1.5)
	assert(absf(enemy_anchor_point.x - (combat_screen._combat_stage._stage_point_for_grid(combat_screen._combat_stage.ENEMY_STAGE_GRID).x + combat_screen._combat_stage.ACTOR_GROUP_STAGE_OFFSET_PX.x)) < 1.5)

	# -- Character/Enemy Stats and the modal talent panel shrink to content;
	# Gear absorbs the leftover side-column height. --
	print("character stats size_flags_vertical (expect not expand-fill): %d" % character_stats_panel.size_flags_vertical)
	assert(character_stats_panel.size_flags_vertical != Control.SIZE_EXPAND_FILL)
	assert(talent_panel.size_flags_vertical == Control.SIZE_SHRINK_BEGIN)
	var enemy_panel_node = combat_screen.find_child("EnemyPanel", true, false)
	print("enemy stats size_flags_vertical (expect not expand-fill): %d" % enemy_panel_node.size_flags_vertical)
	assert(enemy_panel_node.size_flags_vertical != Control.SIZE_EXPAND_FILL)
	assert(gear_panel.size_flags_vertical == Control.SIZE_EXPAND_FILL)

	# -- Gear: Adventure starts with a crude dagger equipped, but inventory
	# still starts empty. --
	print("equipped gear on entry (expect 1): %d" % build_state.equipped_gear().size())
	assert(build_state.equipped_gear().size() == 1)
	assert(build_state.equipped_weapon != null and build_state.equipped_weapon.id == "gear.crude_dagger")
	print("weapon slot tooltip (expect Crude Dagger): %s" % gear_panel._weapon_slot.tooltip_text)
	assert(gear_panel._weapon_slot.tooltip_text.contains("Crude Dagger"))
	print("hood slot tooltip (expect Hood: Empty): %s" % gear_panel._helm_slot.tooltip_text)
	assert(gear_panel._helm_slot.tooltip_text == "Hood: Empty")
	assert(gear_panel._armor_slot.tooltip_text == "Doublet: Empty")
	assert(build_state.inventory.is_empty())
	assert(gear_panel._inventory_grid.get_child_count() == build_state.INVENTORY_CAPACITY)
	assert(gear_panel._inventory_grid.get_child(0).disabled)
	assert(gear_panel._inventory_grid.get_child(0).tooltip_text == "Empty inventory slot")
	assert(gear_panel._inventory_grid.get_child(0).custom_minimum_size == Vector2(88, 88))
	assert(gear_panel._gold_label.text == "0g")
	assert(gear_panel._gold_row.find_child("Icon", true, false) != null)
	var inventory_header: Label = null
	for label in gear_panel.find_children("*", "Label", true, false):
		if label.text == "Inventory":
			inventory_header = label
			break
	assert(inventory_header != null)
	assert(inventory_header.text == "Inventory")
	for child in gear_panel.find_children("*", "Button", true, false):
		assert(child.text != "Reroll Gear")

	# -- Talents panel: no redundant inner title; each framed column carries
	# its role, tree name, and intrinsic in the tree section. --
	var talents_title_found := false
	var primary_role_found := false
	var secondary_role_found := false
	var bladedancer_section_found := false
	var bladedancer_intrinsic_found := false
	for label in talent_panel.find_children("*", "Label", true, false):
		if label.text == "Talents":
			talents_title_found = true
		elif label.text == "Primary":
			primary_role_found = true
		elif label.text == "Secondary":
			secondary_role_found = true
		elif label.text == "Bladedancer":
			bladedancer_section_found = true
		elif label.text.contains("Intrinsic: Unlocks Quick Cut"):
			bladedancer_intrinsic_found = true
	assert(not talents_title_found)
	assert(primary_role_found)
	assert(secondary_role_found)
	assert(bladedancer_section_found)
	assert(bladedancer_intrinsic_found)
	print("assassin intrinsic (expect x20%% Poison Damage): %s" % talent_panel._intrinsic_description(rogue.trees[0]))
	assert(talent_panel._intrinsic_description(rogue.trees[0]) == "x20% Poison Damage")

	# -- Points badge: star icon + "spent/earned" budget readout now lives in
	# Active Talents, not the full Talent Trees overlay footer.
	print("points label (expect : 0/0): %s" % active_talents_panel._points_label.text)
	assert(active_talents_panel._points_label.text == ": 0/0")
	assert(active_talents_panel._points_badge != null)
	assert(active_talents_panel._points_label.get_parent().find_child("Icon", true, false) != null)

	# -- Tree structure: base tier has the two no-prereq talents side by
	# side; deeper talents (Sunder) start disabled/dimmed until their
	# prerequisite chain is satisfied. --
	await process_frame
	var node_buttons := {}
	for node in talent_panel.find_children("*", "Button", true, false):
		if node.has_meta("talent_id"):
			node_buttons[node.get_meta("talent_id")] = node
	print("talent nodes rendered (expect 5): %d" % node_buttons.size())
	assert(node_buttons.size() == 5)
	assert(node_buttons["talent.quick_hands"].get_parent() == node_buttons["talent.piercing_blades"].get_parent())
	print("sunder disabled before prereqs (expect true): %s" % node_buttons["talent.sunder"].disabled)
	assert(node_buttons["talent.sunder"].disabled)
	assert(node_buttons["talent.sunder"].tooltip_text.contains("+20 Bonus Armor Shred"))
	# The retained legacy talent has unrestricted source skill eligibility.
	assert(bladedancer.talents.filter(func(t): return t.id == "talent.opportunity_strikes")[0].triggered_skill_effects[0].source_skill_ids.is_empty())
	assert(node_buttons["talent.opportunity_strikes"].tooltip_text.contains("20% chance to trigger Rending Slash"))

	var piercing_blades: Talent = bladedancer.talents[1]
	assert(piercing_blades.display_name == "Piercing Blades")
	talent_panel._on_node_pressed(piercing_blades)
	print("selected talents with 0 points (expect 0): %d" % build_state.selected_talents.size())
	assert(build_state.selected_talents.size() == 0)

	# -- Talent tooltip reflects the actual cost and stat modifier --
	await process_frame
	for node in talent_panel.find_children("*", "Button", true, false):
		if node.has_meta("talent_id") and node.get_meta("talent_id") == "talent.piercing_blades":
			print("Piercing Blades tooltip: %s" % node.tooltip_text)
			assert(node.tooltip_text.contains("Cost: 1"))
			assert(node.tooltip_text.contains("+20 Bonus Armor Shred"))

	# 3 base skills (Hold, Stab, Heavy Slash) + Quick Cut (granted by the Bladedancer
	# tree itself). Rending Slash arrives after the first earned talent point.
	var unlocked: Array[Skill] = build_state.unlocked_skills()
	print("unlocked skills=%d: %s" % [unlocked.size(), unlocked.map(func(s): return s.display_name)])
	assert(unlocked.size() == 4)
	assert(unlocked.map(func(skill: Skill): return skill.display_name) == ["Hold", "Stab", "Heavy Slash", "Quick Cut"])
	assert(unlocked.any(func(skill: Skill) -> bool: return skill.id == "skill.hold"))
	assert(unlocked.any(func(skill: Skill) -> bool: return skill.id == "skill.quick_cut"))

	for skill in unlocked:
		available_skills_panel._on_skill_pressed(skill)
	print("rotation size=%d" % build_state.rotation.size())
	assert(build_state.rotation.size() == 4)

	# -- Available Skills buttons must report a real minimum width, or the
	# parent HBoxContainer collapses them all to ~0 width and every skill's
	# label renders stacked on top of the others. Yield first so the
	# deferred queue_free()s from the rapid-fire build_changed emissions
	# above (4 skill adds, no awaits between them) actually
	# flush -- same benign artifact seen with talent_panel's checkboxes
	# earlier, not a real duplication bug. --
	await process_frame
	var skills_box: Container = available_skills_panel._skills_box
	print("available skill buttons=%d" % skills_box.get_child_count())
	assert(skills_box.get_child_count() == unlocked.size())
	for button in skills_box.get_children():
		var min_width: float = button.get_combined_minimum_size().x
		print("skill button min width: %.1f (expect > 20)" % min_width)
		assert(min_width > 20.0)

	# -- Skill Build strip: assigned skills render icons; clicking one
	# selects it; Remove performs the edit. The text glyph stays empty for icon-backed slots so the
	# compact macro doesn't double-render icon + letter, while iconless skills
	# still fall back to their authored letter. --
	await process_frame
	var icon_slot_texts: Array = []
	var icon_slots := 0
	for child in skill_build_panel._slots_box.get_children():
		if child is Button:
			icon_slot_texts.append(child.text)
			if child.get_node_or_null("SkillIcon") != null:
				icon_slots += 1
	print("icon-backed slot texts (expect empty strings): %s" % str(icon_slot_texts))
	print("icon-backed slot count (expect 4): %d" % icon_slots)
	assert(icon_slot_texts == ["", "", "", ""])
	assert(icon_slots == 4)
	var iconless_skill := Skill.new()
	iconless_skill.display_name = "Fallback Test"
	iconless_skill.icon_letter = "Z"
	assert(skill_build_panel._glyph_for(iconless_skill) == "Z")

	var first_before: Skill = build_state.rotation[0]
	skill_build_panel._on_slot_pressed(0)
	assert(build_state.rotation.size() == 4)
	skill_build_panel._remove_selected()
	print("rotation size after explicit removal (expect 3): %d" % build_state.rotation.size())
	assert(build_state.rotation.size() == 3)
	assert(not build_state.rotation.has(first_before))
	available_skills_panel._on_skill_pressed(first_before)
	assert(build_state.rotation.size() == 4)

	# -- Character stats panel should reflect Piercing Blades' physical
	# damage multiplier, displayed as bonus above a 0% baseline (x1.08 ->
	# "8%", no leading "+" since it's a multiplicative modifier, not an
	# additive bonus -- P2:R7 playtest-feedback fix, 2026-07-19), with crit
	# multiplier as a percentage. --
	var stats_text: String = character_stats_panel._stats_label.text
	print("")
	print("-- Character stats panel text --")
	print(stats_text)
	assert(stats_text.contains("Weapon Damage: 16-20"))
	assert(stats_text.contains("Physical Damage Increase: +0%"))
	assert(stats_text.contains("Crit Damage: 2.0x"))
	assert(stats_text.find("Retrigger Chance: 0%") < stats_text.find("Shred Chance: 0%"))
	assert(stats_text.find("Shred Chance: 0%") < stats_text.find("Decay Chance: 0%"))
	assert(stats_text.find("Decay Chance: 0%") < stats_text.find("Poison Proc Chance: 0%"))
	assert(stats_text.contains("Bonus Stacks: +0"))
	assert(stats_text.find("Bonus Stacks: +0") < stats_text.find("Base Poison Damage: 8.0"))
	assert(stats_text.find("Base Poison Damage: 8.0") < stats_text.find("Poison Damage Increase: +0%"))
	assert(not stats_text.contains("Elemental Damage Increase:"))
	assert(not stats_text.contains("Elemental Proc Chance:"))
	var damaging_rotation: Array[Skill] = []
	for skill in unlocked:
		if skill.id == "skill.heavy_slash":
			damaging_rotation = [skill, skill, skill]
			break
	build_state.set_rotation(damaging_rotation)
	await process_frame

	# -- Lock/ready flow: FIGHT is gated on locking the build --
	var enemy_panel = combat_screen.find_child("EnemyPanel", true, false)
	print("-- Initial enemy panel --")
	print(enemy_panel._info_label.text)
	assert(enemy_panel._title_label.text == "Mouthy Drunk")
	assert(not enemy_panel._info_label.text.contains("Encounter:"))
	assert(not enemy_panel._info_label.text.contains("Target:"))
	assert(not enemy_panel._info_label.text.contains("Damage Goal:"))
	assert(enemy_panel._info_label.text.contains("HP: 145"))
	assert(enemy_panel._info_label.text.contains("Fight Window: 12s"))
	assert(enemy_panel._info_label.text.contains("Armor: 0"))
	assert(enemy_panel._info_label.text.contains("Resistance: 0%"))
	assert(not enemy_panel._info_label.text.contains("Block:"))
	assert(not enemy_panel._info_label.text.contains("Dodge:"))
	assert(not enemy_panel._info_label.text.contains("Crit Negation:"))
	assert(not enemy_panel._info_label.text.contains("Slow:"))
	assert(not enemy_panel._info_label.text.contains("Absorb:"))
	assert(not enemy_panel._info_label.text.contains("Suppress:"))
	assert(not enemy_panel._info_label.text.contains("Cleanse:"))
	assert(not enemy_panel._info_label.text.contains("Stun:"))
	assert(not enemy_panel._info_label.text.contains("Interrupt:"))
	assert(not enemy_panel._info_label.text.contains("Reward:"))
	assert(not enemy_panel._info_label.text.contains("Pressure:"))
	print("fight button disabled before lock (expect true): %s" % enemy_panel._fight_button.disabled)
	assert(enemy_panel._fight_button.disabled)

	# Fight attempt without lock must be a no-op (guard in combat_screen).
	enemy_panel.fight_pressed.emit()
	assert(not combat_screen._log_overlay._log_label.text.contains("VICTORY"))
	assert(not combat_screen._log_overlay._log_label.text.contains("DEFEAT"))

	skill_build_panel._on_lock_pressed()
	print("build locked (expect true): %s" % build_state.build_locked)
	assert(build_state.build_locked)
	assert(not enemy_panel._fight_button.disabled)
	# Each available-skills child is a bare Button again (P2:R7 playtest-
	# feedback pass removed T4's always-visible effect-summary caption, so
	# there's no longer a wrapping VBoxContainer around it).
	for child in available_skills_panel._skills_box.get_children():
		assert(not child.disabled) # Inspection remains available while edits are locked.
	for child in skill_build_panel._slots_box.get_children():
		assert(not child.disabled) # Inspection remains available while edits are locked.
	var locked_rotation_size: int = build_state.rotation.size()
	available_skills_panel._on_skill_pressed(build_state.unlocked_skills()[0])
	skill_build_panel._on_slot_pressed(0)
	assert(build_state.rotation.size() == locked_rotation_size)

	# -- Log overlay: hidden and gated until a fight has actually happened --
	print("log overlay hidden before any fight (expect true): %s" % (not combat_screen._log_overlay.visible))
	assert(not combat_screen._log_overlay.visible)
	print("view log button disabled before any fight (expect true): %s" % combat_screen._view_log_button.disabled)
	assert(combat_screen._view_log_button.disabled)

	# -- Fight --
	var expected_stats := BuildResolver.resolve_stats(
		build_state.selected_class, build_state.selected_trees, build_state.selected_talents, build_state.equipped_gear()
	)
	var expected_rotation := BuildResolver.resolve_rotation(build_state.rotation, build_state.unlocked_skills())
	var expected_monster: Monster = enemy_panel.monster()
	var expected_duration_ms: int = enemy_panel.duration_ms()
	var expected_result: CombatResolver.CombatResult = CombatResolver.resolve(
		expected_rotation, expected_stats, expected_monster, expected_duration_ms, build_state.current_combat_rng_seed()
	)
	var expected_log := CombatResultFormatter.format(expected_result, expected_monster)
	button_sfx_before = audio_manager.button_press_sfx_play_count
	enemy_panel.fight_button().button_down.emit()
	enemy_panel.fight_button().pressed.emit()
	await process_frame
	assert(audio_manager.button_press_sfx_play_count == button_sfx_before + 1)

	print("")
	print("-- Combat log text --")
	print(combat_screen._log_overlay._log_label.text)
	assert(not combat_screen._log_overlay._log_label.text.contains("[DIAG"))
	assert(combat_screen._log_overlay._log_label.text == expected_log)
	assert(combat_screen._log_overlay._log_label.text.contains("VICTORY!"))
	assert(combat_screen._log_overlay._log_label.text.contains("DPS"))
	assert(combat_screen._log_overlay._inspector.visible)
	assert(combat_screen._log_overlay._inspector._timeline_chart._rows.size() > 0)
	assert(combat_screen._log_overlay._inspector._damage_chart._rows.size() > 0)
	assert(combat_screen._log_overlay._inspector._timeline_chart._time_marks(18.0) == [0.0, 5.0, 10.0, 15.0, 18.0])
	combat_screen._log_overlay._inspector._timeline_chart._max_event_damage = 100.0
	assert(is_equal_approx(combat_screen._log_overlay._inspector._timeline_chart._bar_height(0.0), combat_screen._log_overlay._inspector._timeline_chart.MIN_BAR_H))
	assert(is_equal_approx(combat_screen._log_overlay._inspector._timeline_chart._bar_height(100.0), combat_screen._log_overlay._inspector._timeline_chart.MAX_BAR_H))
	assert(combat_screen._log_overlay._inspector._timeline_chart._bar_height(50.0) > combat_screen._log_overlay._inspector._timeline_chart.MIN_BAR_H)
	assert(is_equal_approx(combat_screen._log_overlay._inspector._timeline_chart._dot_radius(100.0), combat_screen._log_overlay._inspector._timeline_chart.MAX_DOT_RADIUS))
	assert(build_state.run_encounter_history.size() == 1)
	var history_entry: Dictionary = build_state.run_encounter_history[0]
	assert(int(history_entry["fight_number"]) == 1)
	assert(String(history_entry["contract_name"]) == "Tavern")
	assert(String(history_entry["enemy_name"]) == expected_monster.display_name)
	assert(String(history_entry["enemy_role"]) == "Normal")
	assert(is_equal_approx(float(history_entry["player_dps"]), expected_result.dps))
	assert(combat_screen._log_overlay._run_chart._rows.size() == 1)
	assert(combat_screen._log_overlay._run_list.get_child_count() >= 2)
	var history_header = combat_screen._log_overlay._run_list.get_child(0)
	assert((history_header.get_child(0) as Label).text == "Fight Number")
	assert((history_header.get_child(0) as Label).custom_minimum_size.x >= 112.0)
	var enemy_history_cell: RichTextLabel = combat_screen._log_overlay._enemy_cell(history_entry)
	assert(enemy_history_cell.text == "[color=#%s]%s[/color]" % [UIColors.TEXT_POISON.to_html(false), expected_monster.display_name])
	enemy_history_cell.free()
	print("status label: %s" % combat_screen._status_label.text)
	assert(combat_screen._status_label.text.begins_with("Fight complete:"))
	assert(not combat_screen._status_label.visible)
	assert(not combat_screen._view_log_button.disabled)

	# -- Victory banner: auto-shown on win, with recap numbers. This fight
	# is all direct casts (no poison skills in the rotation), so the damage
	# split is exactly 100/0. --
	print("victory overlay visible after win (expect true): %s" % combat_screen._victory_overlay.visible)
	assert(combat_screen._victory_overlay.visible)
	# Victory now resolves inside the combat window: a transparent full-screen
	# click blocker preserves modal behavior, while the visible dim/content
	# are constrained to the combat window so the defeated stage remains
	# visible behind the recap.
	var victory_stack = combat_screen._victory_overlay.find_child("VictoryStack", true, false)
	assert(victory_stack != null)
	assert(victory_stack.get_child_count() == 6)
	var click_blocker = combat_screen._victory_overlay.find_child("VictoryClickBlocker", true, false)
	assert(click_blocker != null)
	assert(click_blocker.color.a == 0.0)
	var combat_dim = combat_screen._victory_overlay.find_child("VictoryCombatDim", true, false)
	assert(combat_dim != null)
	assert(combat_dim.get_parent() == combat_screen._victory_center)
	assert(combat_screen._victory_center.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(combat_screen._victory_overlay.find_child("VictoryContentCenter", true, false).mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(victory_stack.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(combat_screen._victory_center.get_global_rect().position.distance_to(combat_screen._combat_window.get_global_rect().position) < 1.0)
	assert(combat_screen._victory_center.size.distance_to(combat_screen._combat_window.size) < 1.0)
	var victory_center_rect: Rect2 = combat_screen._victory_center.get_global_rect()
	var combat_window_rect: Rect2 = combat_screen._combat_window.get_global_rect()
	assert(victory_center_rect.end.distance_to(combat_window_rect.end) < 1.0)
	assert(combat_dim.get_global_rect().position.distance_to(combat_window_rect.position) < 1.0)
	assert(combat_dim.get_global_rect().end.distance_to(combat_window_rect.end) < 1.0)
	assert(click_blocker.get_global_rect().size.distance_to(combat_screen.get_global_rect().size) < 1.0)
	assert(combat_screen._fight_button_row.z_index > combat_screen._victory_overlay.z_index)
	assert(combat_screen._combat_stage.visible)
	assert(combat_screen._combat_stage.outcome_pose == "victory")
	assert(combat_screen._view_log_button.visible)
	assert(build_state.run_phase == BuildState.RunPhase.RESULT)
	assert(build_state.last_fight_won)
	var recap_text: String = combat_screen._victory_recap_label.text
	print("-- Victory recap --")
	print(recap_text)
	assert(recap_text.contains("Total Damage:"))
	assert(recap_text.contains("(needed %d)" % expected_monster.hp))
	assert(recap_text.contains("Biggest Hit:"))
	assert(recap_text.contains("(100%) / Poison: 0 (0%)"))
	assert(not recap_text.contains("DPS:"))
	assert(not recap_text.contains("Crits:"))
	assert(not recap_text.contains("Armor reduced"))
	assert(not recap_text.contains("ticks"))
	print("reward after first win: %s" % combat_screen._reward_label.text)
	assert(not _reward_row_text(combat_screen).contains("Rewards:"))
	assert(_reward_row_text(combat_screen).contains(": 12g"))
	assert(_reward_row_text(combat_screen).contains("x 1"))
	assert(_reward_row_text(combat_screen).find("x 1") < _reward_row_text(combat_screen).find(": 12g"))
	assert(_reward_row_icon_count(combat_screen) >= 2)
	assert(_reward_row_icon_size(combat_screen) == Vector2(34, 34))
	assert(_reward_row_font_size(combat_screen) == 24)
	var reward_title_found := false
	for node in combat_screen._victory_overlay.find_children("*", "Label", true, false):
		if node.text == "Rewards":
			reward_title_found = true
	assert(not reward_title_found)
	assert(build_state.gold == 0)
	assert(build_state.earned_talent_points == 0)

	var banner_claim = null
	for node in combat_screen._victory_overlay.find_children("*", "Button", true, false):
		if node.text == "Claim Rewards":
			banner_claim = node
	assert(banner_claim != null)
	assert(banner_claim.get_global_rect().end.y < combat_screen._fight_button_row.get_global_rect().position.y)
	for node in combat_screen._victory_overlay.find_children("*", "Button", true, false):
		assert(node.text != "View Combat Log")

	# -- Log overlay: Combat Log remains accessible while the result overlay is visible;
	# Close and backdrop-click both dismiss it without dismissing the result overlay. --
	assert(combat_screen._victory_overlay.visible)
	assert(combat_screen._view_log_button.visible)
	assert(not combat_screen._view_log_button.disabled)
	combat_screen._view_log_button.pressed.emit()
	print("log overlay visible after View Combat Log (expect true): %s" % combat_screen._log_overlay.visible)
	assert(combat_screen._log_overlay.visible)
	assert(combat_screen._log_overlay.z_index > combat_screen._map_overlay.z_index)

	var close_button = null
	for node in combat_screen._log_overlay.find_children("*", "Button", true, false):
		if node.text == "Close":
			close_button = node
	assert(close_button != null)
	close_button.pressed.emit()
	print("log overlay visible after Close (expect false): %s" % combat_screen._log_overlay.visible)
	assert(not combat_screen._log_overlay.visible)
	assert(combat_screen._victory_overlay.visible)

	combat_screen._view_log_button.pressed.emit()
	assert(combat_screen._log_overlay.visible)
	var backdrop = null
	for node in combat_screen._log_overlay.find_children("*", "Button", true, false):
		if node.text == "":
			backdrop = node
	assert(backdrop != null)
	backdrop.pressed.emit()
	print("log overlay visible after backdrop click (expect false): %s" % combat_screen._log_overlay.visible)
	assert(not combat_screen._log_overlay.visible)

	# -- Victory banner Claim Rewards grants authored rewards, advances to
	# the next Tavern encounter, and clears the build lock so the player
	# returns to planning. --
	banner_claim.pressed.emit()
	await process_frame
	assert(build_state.gold == 0)
	# Talent points commit at claim; the flight only presents that deposit.
	assert(build_state.earned_talent_points == 1)
	await _wait_reward_gold_flight()
	print("victory overlay visible after Claim Rewards (expect false): %s" % combat_screen._victory_overlay.visible)
	assert(not combat_screen._victory_overlay.visible)
	assert(build_state.gold == 12)
	assert(build_state.earned_talent_points == 1)
	assert(build_state.claimed_reward_encounter_indices == [0])
	assert(not build_state.claim_current_reward())
	assert(build_state.gold == 12)
	print("current encounter after Continue (expect 1): %d" % build_state.current_encounter_index)
	assert(build_state.current_encounter_index == 1)
	assert(build_state.run_phase == BuildState.RunPhase.PLANNING)
	assert(not build_state.build_locked)
	assert(not build_state.tavern_map_choice_made)
	assert(combat_screen._map_overlay.visible)
	assert(combat_screen._map_overlay._map_node_buttons[0].disabled)
	assert(combat_screen._map_overlay._map_node_buttons[1].text == "Drunk Buddy")
	assert(not combat_screen._map_overlay._map_node_buttons[1].disabled)
	print("-- Enemy panel after Continue --")
	print(enemy_panel._info_label.text)
	assert(enemy_panel._title_label.text == "Choose Encounter")
	assert(enemy_panel._info_label.text.contains("Choose the current Tavern encounter on the map."))
	assert(enemy_panel._fight_button.disabled)
	# -- Returning to the map after a win shows that encounter's Victory
	# Text, not the intro line again, until the next node is previewed. --
	print("map story text after Mouthy Drunk win (expect his Victory Text): %s" % combat_screen._map_overlay._map_story_label.text)
	assert(combat_screen._map_overlay._map_story_label.text == "You easily dispatch him with a few well-placed strikes. He falls into a heap on the floor. However, this has caused quite the commotion.")
	var defeated_mouthy_button: Button = combat_screen._map_overlay._map_node_buttons[0]
	var next_drunk_buddy_button: Button = combat_screen._map_overlay._map_node_buttons[1]
	assert(defeated_mouthy_button.disabled)
	var defeated_marker: Label = defeated_mouthy_button.find_child("TavernDefeatedMarker", true, false)
	assert(defeated_marker != null)
	assert(defeated_mouthy_button.find_child("MapActorMarker", true, false) == null)
	assert(defeated_marker.size == combat_screen._map_overlay.MAP_ACTOR_MARKER_SIZE)
	assert(defeated_mouthy_button.tooltip_text == "")
	assert(not next_drunk_buddy_button.disabled)
	assert(next_drunk_buddy_button.find_child("TavernDefeatedMarker", true, false) == null)
	var next_drunk_buddy_style_before: StyleBoxFlat = next_drunk_buddy_button.get_theme_stylebox("normal")
	assert(next_drunk_buddy_style_before.bg_color == UIColors.TRANSPARENT)
	assert(next_drunk_buddy_button.get_meta("tavern_visual_state") == "available")
	assert(next_drunk_buddy_button.find_child("TavernAvailablePulse", true, false) == null)
	assert(combat_screen._map_overlay._map_proceed_button.disabled)
	combat_screen._map_overlay._map_node_buttons[1].pressed.emit()
	await process_frame
	var next_drunk_buddy_style_after: StyleBoxFlat = combat_screen._map_overlay._map_node_buttons[1].get_theme_stylebox("normal")
	assert(next_drunk_buddy_style_after.border_color == UIColors.TRANSPARENT)
	assert(combat_screen._map_overlay._map_node_buttons[1].get_meta("tavern_visual_state") == "selected")
	assert(not combat_screen._map_overlay._map_proceed_button.disabled)
	combat_screen._map_overlay._map_node_buttons[1].pressed.emit()
	await process_frame
	assert(combat_screen._map_overlay._map_proceed_button.disabled)
	assert(combat_screen._map_overlay._map_node_buttons[1].find_child("TavernAvailablePulse", true, false) == null)
	combat_screen._map_overlay._map_node_buttons[1].pressed.emit()
	await process_frame
	assert(not combat_screen._map_overlay._map_proceed_button.disabled)
	print("previewed flavor text (expect Drunk Buddy's): %s" % combat_screen._map_overlay._map_story_label.text)
	assert(combat_screen._map_overlay._map_story_label.text == "Leaping to his fallen companion's aid, another drunk patron wants to try his hand.")
	combat_screen._map_overlay._map_proceed_button.pressed.emit()
	await process_frame
	assert(not combat_screen._map_overlay.visible)
	assert(build_state.tavern_map_choice_made)
	assert(enemy_panel._title_label.text == "Drunk Buddy")
	assert(not enemy_panel._info_label.text.contains("Encounter:"))
	assert(not enemy_panel._info_label.text.contains("Target:"))
	var planning_map_button = null
	for child in combat_screen.find_children("*", "Button", true, false):
		if child.name == "MapButton":
			planning_map_button = child
	assert(planning_map_button != null)
	planning_map_button.pressed.emit()
	await process_frame
	assert(combat_screen._map_overlay.visible)
	assert(combat_screen._map_overlay._map_close_button.visible)
	assert(combat_screen._map_overlay._map_node_buttons[1].disabled)
	var current_map_style: StyleBoxFlat = combat_screen._map_overlay._map_node_buttons[1].get_theme_stylebox("normal")
	assert(current_map_style.border_color == UIColors.TRANSPARENT)
	assert(combat_screen._map_overlay._map_node_buttons[1].get_meta("tavern_visual_state") == "selected")
	combat_screen._map_overlay._map_close_button.pressed.emit()
	await process_frame
	assert(not combat_screen._map_overlay.visible)

	# Spend the first earned Tavern talent point before the second fight.
	talent_panel._on_node_pressed(piercing_blades)
	await process_frame
	assert(build_state.selected_talents.size() == 1)
	assert(active_talents_panel._points_label.text == ": 1/1")
	unlocked = build_state.unlocked_skills()
	assert(unlocked.size() == 5)
	var empty_rotation: Array[Skill] = []
	build_state.set_rotation(empty_rotation)
	for skill in unlocked:
		if not build_state.rotation.any(func(existing: Skill) -> bool: return existing.id == skill.id):
			available_skills_panel._on_skill_pressed(skill)
	assert(build_state.rotation.size() == unlocked.size())
	assert(build_state.rotation.any(func(skill: Skill) -> bool: return skill.display_name == "Rending Slash"))
	var found_rending_tooltip := false
	for node in available_skills_panel.find_children("*", "Button", true, false):
		if node.tooltip_text.contains("Applies 2 Stacks of Shred"):
			found_rending_tooltip = true
			break
	assert(found_rending_tooltip, "Expected Rending Slash tooltip to distinguish a Stack of Shred from Bonus Armor Shred.")
	talent_panel._on_node_pressed(piercing_blades)
	await process_frame
	assert(not build_state.selected_talents.has(piercing_blades))
	assert(not build_state.unlocked_skills().any(func(skill: Skill) -> bool: return skill.display_name == "Rending Slash"))
	assert(not build_state.rotation.any(func(skill: Skill) -> bool: return skill.display_name == "Rending Slash"))
	talent_panel._on_node_pressed(piercing_blades)
	await process_frame
	unlocked = build_state.unlocked_skills()
	for skill in unlocked:
		if not build_state.rotation.any(func(existing: Skill) -> bool: return existing.id == skill.id):
			available_skills_panel._on_skill_pressed(skill)
	assert(build_state.rotation.size() == unlocked.size())
	stats_text = character_stats_panel._stats_label.text
	assert(stats_text.contains("Shred Chance: 0%"))
	assert(not stats_text.contains("Shred: 30"))
	assert(combat_screen._shred_status_tooltip() == "Shred: Each stack reduces armor by 30")

	# Relock and resolve a second, different encounter from the same active
	# dashboard. This is the core P2:R2 reconnection contract.
	skill_build_panel._on_lock_pressed()
	assert(build_state.build_locked)
	assert(not enemy_panel._fight_button.disabled)
	# This screen-level progression check needs a deterministic second win
	# so it can verify Drunk Buddy's authored reward/shop handoff while
	# balance values continue to move independently.
	var drunk_buddy_fixture: Monster = enemy_panel.monster()
	drunk_buddy_fixture.hp = 100
	drunk_buddy_fixture.armor = 0
	enemy_panel.fight_pressed.emit()
	await process_frame
	assert(combat_screen._victory_overlay.visible)
	assert(combat_screen._log_overlay._log_label.text.contains("Drunk Buddy"))
	print("reward after second win: %s" % _reward_row_text(combat_screen))
	assert(_reward_row_text(combat_screen).contains(": 18g"))
	assert(_reward_row_text(combat_screen).contains("Lucky Coin"))
	assert(_reward_row_text(combat_screen).contains("shop access"))
	assert(not _reward_row_text(combat_screen).contains("Rewards:"))
	assert(_reward_row_text(combat_screen).find("Lucky Coin") < _reward_row_text(combat_screen).find(": 18g"))
	assert(build_state.gold == 12)
	assert(build_state.current_encounter_index == 1)
	assert(build_state.run_phase == BuildState.RunPhase.RESULT)
	var inventory_count_before_buddy_claim: int = build_state.inventory.size()
	var lucky_coin: GearItem = load("res://data/gear/lucky_coin.tres")
	banner_claim.pressed.emit()
	await _wait_reward_gold_flight()
	print("victory overlay visible after second Claim Rewards (expect false): %s" % combat_screen._victory_overlay.visible)
	assert(not combat_screen._victory_overlay.visible)
	assert(build_state.gold == 30)
	assert(build_state.earned_talent_points == 1)
	assert(build_state.inventory.size() == inventory_count_before_buddy_claim + 1)
	assert(build_state.has_inventory_item(lucky_coin))
	await process_frame
	assert(gear_panel._inventory_grid.get_child_count() == build_state.INVENTORY_CAPACITY)
	assert(not gear_panel._inventory_grid.get_child(0).disabled)
	assert(not gear_panel._inventory_grid.get_child(0).tooltip_text.contains("Left-click to equip"))
	assert(not gear_panel._inventory_grid.get_child(0).tooltip_text.contains("Sell available in shop"))
	assert(build_state.shop_unlocked)
	assert(build_state.claimed_reward_encounter_indices == [0, 1])
	assert(build_state.current_encounter_index == 1)
	assert(build_state.run_phase == BuildState.RunPhase.RESULT)
	assert(build_state.shop_round_pending)
	assert(combat_screen._shop_overlay.visible)
	assert(not combat_screen._status_label.visible)
	assert(not combat_screen._view_log_button.visible)
	assert(build_state.shop_offers.size() == 6)
	for offer in build_state.shop_offers:
		assert(BuildState.SHOP_ROLL_TIERS.has(offer.tier))
	assert(combat_screen._shop_overlay._shop_offers_box.columns == 2)
	assert(combat_screen._shop_overlay._shop_offers_box.get_child_count() == 6)

	var first_offer: GearItem = build_state.shop_offers[0]
	var first_offer_id := first_offer.id
	print("first shop offer: %s" % combat_screen._shop_overlay._shop_offer_text(first_offer))
	var expected_first_offer_price: int = build_state.shop_purchase_price_for(first_offer)
	assert(combat_screen._shop_overlay._shop_offer_text(first_offer).contains("Price: %dg" % expected_first_offer_price))
	assert(combat_screen._shop_overlay._shop_offer_text(first_offer).begins_with(first_offer.display_name))
	assert(combat_screen._shop_overlay._shop_offer_text(first_offer).contains("%s %s / %s" % [GearGenerator.tier_name(first_offer.tier), GearGenerator.universal_slot_label(first_offer.slot), GearGenerator.item_family_for(first_offer)]))
	assert(build_state.shop_reroll_cost == 5)
	assert(combat_screen._shop_overlay._shop_reroll_button.text == "Reroll 5g")
	assert(not combat_screen._shop_overlay._shop_reroll_button.disabled)
	assert(combat_screen._shop_overlay._shop_reroll_button.tooltip_text.contains("Spend 5g"))

	var offers_before_reroll: Array[String] = []
	for offer in build_state.shop_offers:
		offers_before_reroll.append(offer.id)
	var gold_before_reroll: int = build_state.gold
	combat_screen._shop_overlay._shop_reroll_button.pressed.emit()
	await create_timer(1.0).timeout
	assert(build_state.shop_reroll_used)
	assert(build_state.shop_reroll_count == 1)
	assert(build_state.shop_reroll_cost == 10)
	assert(build_state.gold == gold_before_reroll - 5)
	var offers_after_reroll: Array[String] = []
	for offer in build_state.shop_offers:
		offers_after_reroll.append(offer.id)
	print("shop offers changed after reroll (expect true): %s" % (offers_before_reroll != offers_after_reroll))
	assert(offers_before_reroll != offers_after_reroll)
	combat_screen._shop_overlay.refresh()
	await process_frame
	assert(not combat_screen._shop_overlay._shop_reroll_button.disabled)
	assert(combat_screen._shop_overlay._shop_reroll_button.text == "Reroll 10g")

	var bought_offer: GearItem = build_state.shop_offers[0]
	var inventory_before_purchase: int = build_state.inventory.size()
	var gold_before_purchase: int = build_state.gold
	var stats_before_purchase := BuildResolver.resolve_stats(
		build_state.selected_class, build_state.selected_trees, build_state.selected_talents, build_state.equipped_gear()
	)
	var first_offer_button: Button = combat_screen._shop_overlay._shop_offers_box.get_child(0)
	assert(first_offer_button.custom_minimum_size == Vector2(88, 88))
	assert(first_offer_button.tooltip_text.contains(bought_offer.display_name))
	assert(first_offer_button.tooltip_text.begins_with(bought_offer.display_name))
	assert(first_offer_button.tooltip_text.contains("%s %s / %s" % [GearGenerator.tier_name(bought_offer.tier), GearGenerator.universal_slot_label(bought_offer.slot), GearGenerator.item_family_for(bought_offer)]))
	assert(first_offer_button.find_child("PriceLabel", true, false).text == "18g")
	assert(first_offer_button.find_child("PriceLabel", true, false).get_theme_font_size("font_size") == 16)
	var shop_change_before_buy: int = audio_manager.shop_change_sfx_play_count
	first_offer_button.pressed.emit()
	assert(build_state.gold == gold_before_purchase - 18)
	assert(build_state.inventory.size() == inventory_before_purchase + 1)
	assert(build_state.has_inventory_item(bought_offer))
	assert(not build_state.shop_offers.has(bought_offer))
	assert(audio_manager.shop_change_sfx_play_count == shop_change_before_buy + 1)
	assert(first_offer_id != "")
	var stats_after_purchase := BuildResolver.resolve_stats(
		build_state.selected_class, build_state.selected_trees, build_state.selected_talents, build_state.equipped_gear()
	)

	# Fill inventory to prove shop buying is capacity-gated, then sell a
	# stored item during the open shop round to free a slot.
	var fill_rng := RandomNumberGenerator.new()
	fill_rng.seed = 72
	while build_state.inventory.size() < build_state.INVENTORY_CAPACITY:
		assert(build_state.add_inventory_item(GearGenerator.generate(GearItem.Tier.BASIC, GearItem.SlotType.CHARM, fill_rng)))
	assert(not build_state.can_add_inventory_item())
	assert(build_state.shop_offers.size() > 0)
	var blocked_offer: GearItem = build_state.shop_offers[0]
	build_state.gold = max(build_state.gold, GearGenerator.price_for_tier(blocked_offer.tier))
	var gold_before_blocked_buy: int = build_state.gold
	combat_screen._shop_overlay.refresh()
	await process_frame
	var blocked_offer_button: Button = combat_screen._shop_overlay._shop_offers_box.get_child(0)
	assert(not blocked_offer_button.disabled)
	assert(blocked_offer_button.tooltip_text.contains("Inventory full -- make space first."))
	var shop_change_before_blocked_buy: int = audio_manager.shop_change_sfx_play_count
	blocked_offer_button.pressed.emit()
	assert(combat_screen._last_inventory_blocked_source == blocked_offer_button)
	assert(blocked_offer_button.get_meta("inventory_blocked_pulse") == true)
	await process_frame
	assert(build_state.gold == gold_before_blocked_buy)
	assert(build_state.shop_offers.has(blocked_offer))
	assert(audio_manager.shop_change_sfx_play_count == shop_change_before_blocked_buy)
	assert(not build_state.buy_shop_offer(blocked_offer))
	assert(build_state.gold == gold_before_blocked_buy)
	assert(build_state.shop_offers.has(blocked_offer))
	var sold_during_shop: GearItem = build_state.inventory[build_state.inventory.size() - 1]
	var sale_value: int = build_state.sell_value_for(sold_during_shop)
	var shop_right_click_event := InputEventMouseButton.new()
	shop_right_click_event.button_index = MOUSE_BUTTON_RIGHT
	shop_right_click_event.pressed = true
	gear_panel._on_inventory_slot_gui_input(shop_right_click_event, sold_during_shop)
	await process_frame
	assert(gear_panel._pending_inventory_action_item == sold_during_shop)
	assert(gear_panel._inventory_action_menu.get_item_text(gear_panel._inventory_action_menu.get_item_index(gear_panel.ACTION_SELL_ID)) == "Sell for %dg" % sale_value)
	assert(not gear_panel._inventory_action_menu.is_item_disabled(gear_panel._inventory_action_menu.get_item_index(gear_panel.ACTION_SELL_ID)))
	gear_panel._on_inventory_action_selected(gear_panel.ACTION_SELL_ID)
	await process_frame
	assert(gear_panel._sell_dialog.visible)
	var shop_change_before_inventory_sale: int = audio_manager.shop_change_sfx_play_count
	gear_panel._on_sell_confirmed()
	await process_frame
	assert(not build_state.has_inventory_item(sold_during_shop))
	assert(build_state.gold == gold_before_blocked_buy + sale_value)
	assert(build_state.can_add_inventory_item())
	assert(audio_manager.shop_change_sfx_play_count == shop_change_before_inventory_sale + 1)

	var purchased_gear_changed_stats := (
		stats_before_purchase.attack_speed != stats_after_purchase.attack_speed
		or stats_before_purchase.crit_chance != stats_after_purchase.crit_chance
		or stats_before_purchase.crit_multiplier != stats_after_purchase.crit_multiplier
		or stats_before_purchase.poison_damage_per_tick != stats_after_purchase.poison_damage_per_tick
		or stats_before_purchase.physical_damage_multiplier != stats_after_purchase.physical_damage_multiplier
		or stats_before_purchase.bonus_poison_stacks != stats_after_purchase.bonus_poison_stacks
		or stats_before_purchase.bonus_armor_reduction != stats_after_purchase.bonus_armor_reduction
	)
	print("inventory purchase leaves stats unchanged (expect false): %s" % purchased_gear_changed_stats)
	assert(not purchased_gear_changed_stats)

	assert(build_state.has_inventory_item(bought_offer))
	gear_panel._on_inventory_slot_pressed(bought_offer)
	await process_frame
	assert(build_state.equipped_item_for_slot(bought_offer.slot) == bought_offer)
	assert(not build_state.has_inventory_item(bought_offer))

	var replacement_offer: GearItem = null
	for item in build_state.inventory:
		if item != null and item != lucky_coin and item.slot == bought_offer.slot:
			replacement_offer = item
			break
	if replacement_offer != null:
		assert(build_state.shop_round_pending)
		gear_panel._on_inventory_slot_pressed(replacement_offer)
		await process_frame
		assert(build_state.equipped_item_for_slot(replacement_offer.slot) == replacement_offer)

	var equipped_sale_slot: GearItem.SlotType = bought_offer.slot
	var equipped_item_for_sale: GearItem = build_state.equipped_item_for_slot(equipped_sale_slot)
	var gold_before_equipped_left_click: int = build_state.gold
	var equipped_left_click_event := InputEventMouseButton.new()
	equipped_left_click_event.button_index = MOUSE_BUTTON_LEFT
	equipped_left_click_event.pressed = true
	gear_panel._on_equipped_slot_gui_input(equipped_left_click_event, equipped_sale_slot)
	await process_frame
	assert(build_state.has_open_equipment_slot(equipped_sale_slot))
	assert(build_state.has_inventory_item(equipped_item_for_sale))
	assert(build_state.gold == gold_before_equipped_left_click)
	gear_panel._on_inventory_slot_pressed(equipped_item_for_sale)
	await process_frame
	assert(build_state.equipped_item_for_slot(equipped_sale_slot) == equipped_item_for_sale)

	var equipped_sale_value: int = build_state.sell_value_for(equipped_item_for_sale)
	var equipped_right_click_event := InputEventMouseButton.new()
	equipped_right_click_event.button_index = MOUSE_BUTTON_RIGHT
	equipped_right_click_event.pressed = true
	gear_panel._on_equipped_slot_gui_input(equipped_right_click_event, equipped_sale_slot)
	await process_frame
	assert(gear_panel._pending_equipped_action_slot == equipped_sale_slot)
	assert(gear_panel._equipped_action_menu.get_item_text(gear_panel._equipped_action_menu.get_item_index(gear_panel.ACTION_SELL_ID)) == "Sell for %dg" % equipped_sale_value)
	assert(not gear_panel._equipped_action_menu.is_item_disabled(gear_panel._equipped_action_menu.get_item_index(gear_panel.ACTION_UNEQUIP_ID)))
	assert(not gear_panel._equipped_action_menu.is_item_disabled(gear_panel._equipped_action_menu.get_item_index(gear_panel.ACTION_SELL_ID)))
	gear_panel._on_equipped_action_selected(gear_panel.ACTION_SELL_ID)
	await process_frame
	assert(gear_panel._sell_dialog.visible)
	var gold_before_equipped_sale: int = build_state.gold
	var shop_change_before_equipped_sale: int = audio_manager.shop_change_sfx_play_count
	gear_panel._on_sell_confirmed()
	await process_frame
	assert(build_state.gold == gold_before_equipped_sale + equipped_sale_value)
	assert(build_state.has_open_equipment_slot(equipped_sale_slot))
	assert(audio_manager.shop_change_sfx_play_count == shop_change_before_equipped_sale + 1)

	combat_screen._on_shop_continue_pressed()
	await process_frame
	assert(not combat_screen._shop_overlay.visible)
	assert(not build_state.shop_round_pending)
	assert(build_state.shop_round_index == 1)
	assert(build_state.current_encounter_index == 2)
	assert(build_state.run_phase == BuildState.RunPhase.PLANNING)
	assert(enemy_panel._title_label.text == "Choose Encounter")
	assert(combat_screen._map_overlay.visible)
	assert(combat_screen._map_overlay._map_node_buttons[2].text == "Tavern Bouncer")
	print("map story text after Drunk Buddy win (expect his Victory Text): %s" % combat_screen._map_overlay._map_story_label.text)
	assert(combat_screen._map_overlay._map_story_label.text == "He lands with a thud atop the fallen body of his companion, but now the tavern is abuzz with action. You have made your pressence known; however you are not sure that was the best idea.")
	combat_screen._map_overlay._map_node_buttons[2].pressed.emit()
	await process_frame
	print("previewed flavor text (expect Tavern Bouncer's): %s" % combat_screen._map_overlay._map_story_label.text)
	assert(combat_screen._map_overlay._map_story_label.text == "The burley bouncer grabs you to politely show you the door.")
	combat_screen._map_overlay._map_proceed_button.pressed.emit()
	await process_frame
	assert(build_state.tavern_map_choice_made)
	assert(enemy_panel._title_label.text == "Tavern Bouncer")

	# -- Earned inventory equip: Lucky Coin came from the Drunk Buddy reward,
	# not a free reroll, and equipping it from the panel is a build change. --
	skill_build_panel._on_lock_pressed()
	assert(build_state.build_locked)
	gear_panel._on_inventory_slot_pressed(lucky_coin)
	await process_frame
	assert(build_state.equipped_trinket == lucky_coin)
	assert(not build_state.has_inventory_item(lucky_coin))
	assert(gear_panel._trinket_slot.tooltip_text.begins_with("Lucky Coin"))
	assert(gear_panel._trinket_slot.tooltip_text.contains("Basic Trinket / Ring"))
	print("build unlocked after earned gear equip (expect false): %s" % build_state.build_locked)
	assert(not build_state.build_locked)
	assert(enemy_panel._fight_button.disabled)

	# -- Contract offer transition: after Hired Goon, the shop is skipped and
	# Ghit Gudd's Contract Window introduces generated biome contract work
	# instead of surfacing the authored Vyra contract for now.
	build_state.current_encounter_index = RunFlow.tavern_encounter_count() - 1
	build_state.run_phase = BuildState.RunPhase.RESULT
	build_state.last_fight_won = true
	build_state.run_state_changed.emit()
	assert(build_state.claim_current_reward())
	combat_screen._advance_after_reward_or_shop()
	await process_frame
	print("run phase after Hired Goon Continue (expect CONTRACT_OFFER): %d" % build_state.run_phase)
	assert(build_state.run_phase == BuildState.RunPhase.CONTRACT_OFFER)
	assert(build_state.active_contract != null)
	assert(build_state.active_contract.has_generated_route_state())
	assert(build_state.pending_contract_offers.size() == 3)
	assert(not combat_screen._shop_overlay.visible)
	assert(combat_screen._contract_overlay.visible)
	assert(combat_screen._contract_overlay._contract_body_label.text == combat_screen._contract_overlay.CONTRACT_GREETING_TEXT)
	assert(combat_screen._contract_overlay._contract_action_button.text == "Hear Him Out")
	assert(enemy_panel._title_label.text == "Contract Offer")
	var top_bar := combat_screen.find_child("TopActionBar", true, false) as HBoxContainer
	assert(top_bar != null)
	assert(top_bar.z_index == combat_screen.TOP_BAR_CHROME_Z_INDEX)
	assert(top_bar.z_index > combat_screen._contract_overlay.z_index)
	assert(combat_screen._map_overlay.z_index > top_bar.z_index)
	assert(combat_screen._monster_manual_overlay.z_index > combat_screen._map_overlay.z_index)
	assert(combat_screen._contract_overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	var contract_backdrop := combat_screen._contract_overlay.get_child(0) as Control
	assert(contract_backdrop != null)
	assert(contract_backdrop.mouse_filter == Control.MOUSE_FILTER_STOP)
	assert(contract_backdrop.offset_top == combat_screen._contract_overlay.TOP_CHROME_CLICKTHROUGH_CLEARANCE)
	var contract_menu_button = null
	var contract_map_button = null
	var contract_manual_button = null
	var contract_save_quit_button = null
	for child in combat_screen.find_children("*", "Button", true, false):
		if child.name == "AbandonRunButton":
			contract_menu_button = child
		elif child.name == "MapButton":
			contract_map_button = child
		elif child.name == "MonsterManualButton":
			contract_manual_button = child
		elif child.name == "SaveQuitButton":
			contract_save_quit_button = child
	assert(contract_menu_button != null and not contract_menu_button.disabled)
	assert(contract_map_button != null and not contract_map_button.disabled)
	assert(contract_manual_button != null and not contract_manual_button.disabled)
	assert(contract_save_quit_button != null and not contract_save_quit_button.disabled)
	contract_manual_button.pressed.emit()
	await process_frame
	assert(combat_screen._monster_manual_overlay.visible)
	assert(combat_screen._contract_overlay.visible)
	combat_screen._monster_manual_overlay.visible = false

	combat_screen._contract_overlay._contract_action_button.pressed.emit()
	await process_frame
	assert(combat_screen._contract_overlay._contract_body_label.text == combat_screen._contract_overlay.CONTRACT_PITCH_TEXT)
	assert(combat_screen._contract_overlay._contract_body_label.text.contains("valuable... materials"))
	assert(combat_screen._contract_overlay._contract_action_button.text == "Accept Contract Work")

	combat_screen._contract_overlay._contract_action_button.pressed.emit()
	await process_frame
	assert(combat_screen._contract_overlay.visible)
	assert(not combat_screen._secondary_subclass_overlay.visible)
	assert(build_state.run_phase == BuildState.RunPhase.CONTRACT_OFFER)
	assert(combat_screen._contract_overlay._contract_options_box.get_child_count() == 3)
	assert(combat_screen._contract_overlay._contract_title_label.text == "Choose a Contract")
	assert(not combat_screen._contract_overlay._contract_title_icon.visible)
	assert(not combat_screen._contract_overlay._contract_body_label.visible)
	var generated_offer_button: Button = combat_screen._contract_overlay._contract_options_box.get_child(0)
	assert(generated_offer_button.name == "GeneratedContractOfferButton")
	assert(generated_offer_button.text == "")
	assert(_card_label_text(generated_offer_button, "ContractBossNameLabel") != "")
	assert(_card_label_text(generated_offer_button, "ContractBossNameLabel") != "Vyra")
	assert(_card_label_text(generated_offer_button, "ContractLocationLabel").begins_with("Location:"))
	assert(_contract_card_icon(generated_offer_button).custom_minimum_size == Vector2(64, 64))
	assert(_card_label_font_size(generated_offer_button, "ContractBossNameLabel") > _card_label_font_size(generated_offer_button, "ContractLocationLabel"))
	assert(combat_screen._contract_overlay._contract_action_button.disabled)
	assert(combat_screen._contract_overlay._contract_action_button.text == "Preview")
	assert(generated_offer_button.find_child("ContractChoicePulse", true, false) != null)
	generated_offer_button.pressed.emit()
	await process_frame
	generated_offer_button = combat_screen._contract_overlay._contract_options_box.get_child(0)
	assert(not combat_screen._contract_overlay._contract_action_button.disabled)
	assert(generated_offer_button.find_child("ContractChoicePulse", true, false) == null)
	combat_screen._contract_overlay._contract_action_button.pressed.emit()
	await process_frame
	assert(not combat_screen._contract_overlay.visible)
	assert(not combat_screen._talent_overlay.visible)
	assert(combat_screen._map_overlay.visible)
	assert(build_state.run_phase == BuildState.RunPhase.CONTRACT_ROUTE)
	assert(build_state.active_contract.has_generated_route_state())
	assert(combat_screen._map_overlay._map_contract_back_button.visible)
	combat_screen._map_overlay._map_contract_back_button.pressed.emit()
	await process_frame
	assert(combat_screen._contract_overlay.visible)
	assert(combat_screen._contract_overlay._contract_title_label.text == "Choose a Contract")
	assert(not combat_screen._contract_overlay._contract_title_icon.visible)
	assert(not combat_screen._contract_overlay._contract_body_label.visible)
	assert(combat_screen._contract_overlay._contract_options_box.get_child_count() == 3)
	assert(combat_screen._contract_overlay._contract_action_button.text == "Preview")
	assert(combat_screen._contract_overlay._contract_action_button.disabled)
	generated_offer_button = combat_screen._contract_overlay._contract_options_box.get_child(0)
	generated_offer_button.pressed.emit()
	await process_frame
	combat_screen._contract_overlay._contract_action_button.pressed.emit()
	await process_frame
	assert(not combat_screen._contract_overlay.visible)
	assert(combat_screen._map_overlay.visible)
	assert(build_state.run_phase == BuildState.RunPhase.CONTRACT_ROUTE)
	assert(combat_screen._map_overlay._map_contract_back_button.visible)
	assert(combat_screen._map_overlay._map_node_buttons.size() > build_state.current_route_node.next_nodes.size())
	assert(enemy_panel._title_label.text == "Choose Route")
	assert(enemy_panel._info_label.text.contains("Choose the next contract route on the map."))
	assert(combat_screen._map_overlay._map_proceed_button.visible)
	assert(combat_screen._map_overlay._map_proceed_button.disabled)

	var generated_route_node: ContractRouteNode = build_state.current_route_node.next_nodes[0]
	var generated_route_name := generated_route_node.display_name
	combat_screen._map_overlay._map_node_buttons[0].pressed.emit()
	await process_frame
	assert(build_state.run_phase == BuildState.RunPhase.CONTRACT_ROUTE)
	assert(not combat_screen._map_overlay._map_proceed_button.disabled)
	combat_screen.instant_playback = false
	combat_screen._map_overlay._map_proceed_button.pressed.emit()
	await process_frame
	assert(build_state.run_phase == BuildState.RunPhase.PLANNING)
	assert(build_state.current_route_node == generated_route_node)
	var generated_route_duration: int = build_state.current_target_duration_ms() / 1000
	assert(combat_screen._status_label.text.contains(generated_route_name))
	assert(not combat_screen._status_label.visible)
	assert(enemy_panel._title_label.text == generated_route_name)
	assert(enemy_panel._info_label.text.contains("Fight Window: %ds" % generated_route_duration))
	assert(not enemy_panel._info_label.text.contains("Contract:"))
	assert(not enemy_panel._info_label.text.contains("Damage Goal:"))
	assert(enemy_panel._info_label.text.contains("HP:"))
	assert(enemy_panel._info_label.text.contains("Armor:"))
	assert(enemy_panel._info_label.text.contains("Resistance:"))
	assert(not enemy_panel._info_label.text.contains("Cleanse:"))
	assert(not enemy_panel._info_label.text.contains("Stun:"))
	assert(not enemy_panel._info_label.text.contains("Interrupt:"))
	assert(not enemy_panel._info_label.text.contains("Pressure:"))
	assert(not enemy_panel._info_label.text.contains("Reward:"))
	assert(combat_screen._combat_stage.enemy_actor_anchor.visible)
	assert(combat_screen._combat_stage.player_actor_anchor.visible)
	assert(combat_screen._combat_stage.player_run_in_count == 1)
	assert(combat_screen._combat_stage.last_player_animation_key == "walk")
	assert(combat_screen._combat_stage.player_actor_anchor.position.x < 0.0)
	assert(audio_manager.footsteps_sfx_play_count > 0)
	assert(is_equal_approx(audio_manager.last_footsteps_duration_sec, combat_screen._combat_stage.CONTRACT_RUN_IN_DELAY_SEC + combat_screen._combat_stage.CONTRACT_RUN_IN_SEC))
	await create_timer(combat_screen._combat_stage.CONTRACT_RUN_IN_DELAY_SEC + combat_screen._combat_stage.CONTRACT_RUN_IN_SEC + 0.05).timeout
	assert(is_equal_approx(combat_screen._combat_stage.player_actor_anchor.position.x, combat_screen._combat_stage._player_base_position.x))
	combat_screen.instant_playback = true
	assert(enemy_panel._fight_button.disabled)
	assert(not build_state.needs_secondary_subclass_choice())
	combat_screen._show_talent_overlay()
	await process_frame
	var talent_scroll: ScrollContainer = combat_screen._talent_overlay.find_child("TalentTreeScroll", true, false)
	assert(talent_scroll != null)
	assert(talent_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED)
	var talent_close_button: Button = null
	for node in combat_screen._talent_overlay.find_children("*", "Button", true, false):
		if node.text == "Close":
			talent_close_button = node
	assert(talent_close_button != null)
	button_sfx_before = audio_manager.button_press_sfx_play_count
	talent_close_button.pressed.emit()
	await process_frame
	assert(not combat_screen._talent_overlay.visible)
	assert(audio_manager.button_press_sfx_play_count == button_sfx_before + 1)
	assert(combat_screen._combat_stage.player_actor_anchor.visible)
	assert(is_equal_approx(combat_screen._combat_stage.player_actor_anchor.position.x, combat_screen._combat_stage._player_base_position.x))
	combat_screen._show_talent_overlay()
	await process_frame
	# Earned-choice UI fixture: ordinary contract acceptance remains locked.
	build_state.completed_contract_count = 1
	combat_screen._talent_overlay._talent_panel.refresh_panel()
	await process_frame
	var secondary_choices: VBoxContainer = combat_screen._talent_overlay.find_child("SecondaryTreeChoices", true, false)
	assert(secondary_choices != null)
	assert(secondary_choices.get_child_count() == 2)
	var secondary_card_0_vbox: VBoxContainer = secondary_choices.get_child(0).get_child(0)
	var secondary_card_1_vbox: VBoxContainer = secondary_choices.get_child(1).get_child(0)
	var secondary_title_0: String = secondary_card_0_vbox.find_child("Title", true, false).text
	var secondary_title_1: String = secondary_card_1_vbox.find_child("Title", true, false).text
	assert(secondary_title_0 != secondary_title_1)
	assert(not secondary_title_0.contains("Bladedancer"))
	assert(not secondary_title_1.contains("Bladedancer"))
	assert(secondary_card_0_vbox.find_child("Icon", true, false) != null)
	assert(secondary_card_1_vbox.find_child("Icon", true, false) != null)
	assert(secondary_card_0_vbox.get_child(2) is Button)
	assert(secondary_card_0_vbox.get_child(2).text == "Choose")
	secondary_card_0_vbox.get_child(2).pressed.emit()
	await process_frame
	assert(build_state.selected_trees.size() == 2)
	assert(combat_screen._talent_overlay.visible)
	assert(combat_screen._status_label.text.contains("Second tree chosen"))
	assert(not combat_screen._status_label.visible)
	combat_screen._talent_overlay.visible = false
	build_state.set_locked(true)
	await process_frame
	assert(not enemy_panel._fight_button.disabled)
	enemy_panel._fight_button.pressed.emit()
	await process_frame
	print("route fight phase after generated route node: %d" % build_state.run_phase)
	print("route fight log contains generated node (expect true): %s" % combat_screen._log_overlay._log_label.text.contains(generated_route_name))
	assert(combat_screen._log_overlay._log_label.text.contains(generated_route_name))
	assert(combat_screen._view_log_button.disabled == false)
	# This regression is about the post-contract-reward shop transition, not
	# route balance for the broad dashboard build assembled above. Contract
	# losses now correctly end as CONTRACT_FAILED, so restore a winning result
	# surface before driving the reward/shop branch.
	if build_state.run_outcome == BuildState.RunOutcome.CONTRACT_FAILED:
		assert(build_state.run_phase == BuildState.RunPhase.RUN_ENDED)
		assert(enemy_panel._title_label.text == generated_route_name)
		assert(enemy_panel._info_label.text.contains("HP:"))
		assert(not enemy_panel._info_label.text.contains("This Adventure has ended."))
		assert(combat_screen._tavern_background.visible)
		assert(not combat_screen._tavern_fireplace_overlay.visible)
		build_state.run_phase = BuildState.RunPhase.RESULT
		build_state.run_outcome = BuildState.RunOutcome.FIGHT_WIN
	build_state.last_fight_won = true
	combat_screen._on_continue_pressed()
	await _wait_reward_gold_flight()
	assert(combat_screen._reward_choice_overlay.visible)
	assert(build_state.has_pending_reward_choice())
	var contract_reward_button: Button = combat_screen._reward_choice_overlay.options_container().get_child(0)
	contract_reward_button.pressed.emit()
	await process_frame
	assert(not combat_screen._shop_overlay.visible)
	assert(combat_screen._fight_button_row.z_index == combat_screen.COMBAT_BUTTON_ROW_DEFAULT_Z_INDEX)
	assert(not build_state.shop_round_pending)
	assert(not combat_screen._shop_overlay.visible)
	assert(build_state.run_phase == BuildState.RunPhase.CONTRACT_ROUTE)

	# -- Abandon Run requires confirmation, doesn't fire immediately --
	# GDScript lambdas capture local variables by value, not by reference, so
	# a bare `bool` wouldn't observe the lambda's mutation -- use a 1-element
	# Array as a mutable box instead.
	var main_menu_fired := [false]
	combat_screen.main_menu_pressed.connect(func(): main_menu_fired[0] = true)
	# The icon-only button lives nested inside the top bar.
	var menu_button = null
	for child in combat_screen.find_children("*", "Button", true, false):
		if child.name == "AbandonRunButton":
			menu_button = child
	assert(menu_button != null)
	var map_button = null
	for child in combat_screen.find_children("*", "Button", true, false):
		if child.name == "MapButton":
			map_button = child
	assert(map_button != null)
	var save_quit_button = null
	for child in combat_screen.find_children("*", "Button", true, false):
		if child.name == "SaveQuitButton":
			save_quit_button = child
	assert(save_quit_button != null)
	top_bar = combat_screen.find_child("TopActionBar", true, false) as HBoxContainer
	assert(top_bar != null)
	assert(top_bar.z_index == combat_screen.TOP_BAR_CHROME_Z_INDEX)
	assert(combat_screen._map_overlay.z_index > top_bar.z_index)
	map_button.pressed.emit()
	await process_frame
	assert(combat_screen._map_overlay.visible)
	var map_backdrop = combat_screen._map_overlay.get_child(0) as Control
	var map_center = combat_screen._map_overlay.get_child(1) as Control
	assert(map_backdrop != null)
	assert(map_center != null)
	assert(map_backdrop.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(is_equal_approx(map_backdrop.offset_top, combat_screen._map_overlay.TOP_CHROME_CLICKTHROUGH_CLEARANCE))
	assert(is_equal_approx(map_center.offset_top, 0.0))
	assert(not map_button.disabled)
	assert(not save_quit_button.disabled)
	assert(not menu_button.disabled)
	assert(combat_screen._map_overlay._map_close_button.visible)
	combat_screen._map_overlay.visible = false
	menu_button.pressed.emit()
	print("main menu fired before confirmation (expect false): %s" % main_menu_fired[0])
	assert(not main_menu_fired[0])
	assert(combat_screen._confirm_dialog.visible)

	combat_screen._confirm_dialog.confirmed.emit()
	print("main menu fired after confirmation (expect true): %s" % main_menu_fired[0])
	assert(main_menu_fired[0])

	print("")
	print("P2 UI restructure end-to-end check: OK")
	quit()


func _wait_reward_gold_flight() -> void:
	await create_timer(1.05).timeout
	await process_frame


func _reward_row_text(combat_screen) -> String:
	var parts: PackedStringArray = []
	for child in combat_screen._victory_reward_row.get_children():
		if child is Label:
			parts.append(child.text)
	return " ".join(parts)


func _reward_row_icon_count(combat_screen) -> int:
	var count := 0
	for child in combat_screen._victory_reward_row.get_children():
		if child is TextureRect:
			count += 1
	return count


func _reward_row_icon_size(combat_screen) -> Vector2:
	for child in combat_screen._victory_reward_row.get_children():
		if child is TextureRect:
			return child.custom_minimum_size
	return Vector2.ZERO


func _reward_row_font_size(combat_screen) -> int:
	for child in combat_screen._victory_reward_row.get_children():
		if child is Label:
			return child.get_theme_font_size("font_size")
	return 0


func _card_label_text(card: Button, label_name: String) -> String:
	var label: Label = card.find_child(label_name, true, false)
	assert(label != null)
	return label.text


func _card_label_font_size(card: Button, label_name: String) -> int:
	var label: Label = card.find_child(label_name, true, false)
	assert(label != null)
	return label.get_theme_font_size("font_size")


func _contract_card_icon(card: Button) -> TextureRect:
	var content: HBoxContainer = card.find_child("ContractOfferContent", true, false)
	assert(content != null)
	var icon: TextureRect = content.find_child("Icon", true, false)
	assert(icon != null)
	return icon


func _contract_reward_amount_texts(card: Button) -> Array[String]:
	var stack: BoxContainer = card.find_child("ContractRewardStack", true, false)
	assert(stack != null)
	var texts: Array[String] = []
	for label in stack.find_children("ContractRewardAmount", "Label", true, false):
		texts.append((label as Label).text)
	return texts
