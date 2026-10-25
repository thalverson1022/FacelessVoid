extends SceneTree
## M6: Exercise enabled Adventure with the current ranked registry and isolated save.
## Headless check for P2:R6:T4's save/load UI hooks. Drives the real
## title/game_root scene tree the same way real clicks would:
##   - No save: Resume is visible but disabled (grayed out, not hidden --
##     P2:R7 second playtest-feedback pass, item 1), and New Adventure
##     starts a fresh run with no confirmation. The menu lists New Adventure,
##     Resume, then Practice Room (P2:R10 practice mode, enabled).
##   - Save & Quit persists the run and returns to Title, where Resume is
##     now enabled.
##   - Resume loads the save and jumps straight to the combat dashboard
##     (skipping class/subclass select), restoring the saved build.
##   - New Adventure with a save present asks for discard confirmation
##     before starting a new run, and clears the old save.
##   - Abandon Run (the renamed former "Return to Main Menu" button) deletes
##     any save on confirmation.
## Run with:
##   godot --headless -s res://tests/save_load_ui_test.gd
## Same headless-only caveat as every prior UI milestone -- no rendered
## click-through available in this environment.


func _initialize() -> void:
	var build_state = root.get_node("BuildState")
	SaveSystem.save_path = "res://.test_save_load_ui_save.json"
	SaveSystem.delete_save()

	var game_root_scene: PackedScene = load("res://scenes/game_root.tscn")
	var game_root = game_root_scene.instantiate()
	root.add_child(game_root)
	await process_frame

	# -- Fresh start: Resume is present but disabled (not hidden), New
	# Adventure has no save to warn about --
	var title = game_root._current_screen
	var background := title.find_child("MainMenuBackground", true, false) as TextureRect
	assert(background != null)
	assert(background.texture != null)
	var lightning_overlay := title.find_child("TitleLightningFlashOverlay", true, false) as Control
	var main_menu_center := title.find_child("MainMenuCenter", true, false) as CenterContainer
	assert(lightning_overlay != null)
	assert(lightning_overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(main_menu_center != null)
	assert(lightning_overlay.get_index() < main_menu_center.get_index())
	var continue_button := _find_button(title, "Resume Adventure")
	assert(continue_button != null)
	print("continue button visible with no save (expect true): %s" % continue_button.visible)
	assert(continue_button.visible)
	print("continue button disabled with no save (expect true): %s" % continue_button.disabled)
	assert(continue_button.disabled)

	var adventure_button := _find_button(title, "New Adventure")
	assert(adventure_button != null)
	assert(title._random_seed_check_box is CheckBox)
	assert(title._random_seed_check_box.get_theme_stylebox("normal") is StyleBoxEmpty)
	assert(title._random_seed_check_box.get_theme_stylebox("hover_pressed") is StyleBoxEmpty)
	var seed_field_style := title._seed_spin_box.get_line_edit().get_theme_stylebox("normal") as StyleBoxFlat
	assert(seed_field_style != null)
	assert(seed_field_style.border_color == UIColors.PANEL_BORDER)
	assert(title._random_seed_check_box.get_theme_icon("checked").resource_name == "SeedRandomChecked")
	assert(title._random_seed_check_box.get_theme_icon("unchecked").resource_name == "SeedRandomUnchecked")
	assert(title.is_random_seed_enabled())
	assert(not title._seed_spin_box.editable)
	var random_seed: int = title.selected_seed()
	assert(random_seed >= 0 and random_seed <= title.RANDOM_SEED_MAX)
	title._random_seed_check_box.button_pressed = false
	title._on_random_seed_toggled(false)
	assert(not title.is_random_seed_enabled())
	assert(title._seed_spin_box.editable)
	title._seed_spin_box.value = 314159
	assert(title.selected_seed() == 314159)
	assert(_nearest_panel(title._seed_spin_box) != null)
	assert(_nearest_panel(title._seed_spin_box) != _nearest_panel(adventure_button))

	# -- Menu order: New Adventure, Resume Adventure, Practice Room --
	var practice_button := _find_button(title, "Practice Room")
	assert(practice_button != null)
	assert(not practice_button.disabled)
	assert(not practice_button.tooltip_text.is_empty())
	assert(adventure_button.get_index() < continue_button.get_index())
	assert(continue_button.get_index() < practice_button.get_index())
	adventure_button.pressed.emit()
	await process_frame
	assert(game_root._current_screen != title)
	assert(build_state.adventure_seed == 314159)

	var class_select = game_root._current_screen
	var class_background := class_select.find_child("ClassSelectBackground", true, false) as TextureRect
	assert(class_background != null)
	assert(class_background.texture != null)
	var class_lightning_overlay := class_select.find_child("ClassSelectLightningFlashOverlay", true, false) as Control
	assert(class_lightning_overlay != null)
	assert(class_lightning_overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	var rogue: ClassDef = BuildContentRegistry.adventure().classes["class.rogue"]
	class_select._on_class_selected(rogue)
	class_select.advanced.emit()
	await process_frame

	var subclass_select = game_root._current_screen
	var subclass_background := subclass_select.find_child("SubclassSelectBackground", true, false) as TextureRect
	assert(subclass_background != null)
	assert(subclass_background.texture != null)
	var subclass_lightning_overlay := subclass_select.find_child("SubclassSelectLightningFlashOverlay", true, false) as Control
	assert(subclass_lightning_overlay != null)
	assert(subclass_lightning_overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	var bladedancer: SubclassTree = rogue.trees.filter(func(t): return t.id == "tree.bladedancer")[0]
	subclass_select._on_tree_selected(bladedancer)
	subclass_select.advanced.emit()
	await process_frame

	var combat_screen = game_root._current_screen
	build_state.add_gold(35)
	# Fresh run: the intro story overlay gates the map on the very first
	# Tavern choice (see combat_screen.gd's _show_initial_map_if_needed()).
	assert(combat_screen._story_overlay.visible)
	var story_proceed_button: Button = combat_screen._story_overlay.find_child("StoryProceedButton", true, false)
	story_proceed_button.pressed.emit()
	await process_frame
	assert(combat_screen._map_overlay.visible)
	combat_screen._map_overlay._map_node_buttons[0].pressed.emit()
	await process_frame
	combat_screen._map_overlay._map_proceed_button.pressed.emit()
	await process_frame
	print("pre-save gold/seed: %d / %d" % [build_state.gold, build_state.adventure_seed])

	# -- Save & Quit persists the run and returns to Title --
	var save_quit_button := _find_button_by_name(combat_screen, "SaveQuitButton")
	assert(save_quit_button != null)
	save_quit_button.pressed.emit()
	await process_frame
	print("has_save after Save & Quit (expect true): %s" % SaveSystem.has_save())
	assert(SaveSystem.has_save())
	assert(game_root._current_screen != combat_screen)

	var title_after_save = game_root._current_screen
	var continue_button_2 := _find_button(title_after_save, "Resume Adventure")
	assert(continue_button_2 != null)
	print("M6 Resume enabled for a current Adventure save")
	assert(continue_button_2.visible)
	assert(not continue_button_2.disabled)

	# -- New Adventure now warns before discarding the save --
	var adventure_button_2 := _find_button(title_after_save, "New Adventure")
	adventure_button_2.pressed.emit()
	await process_frame
	print("new-game confirm dialog visible (expect true): %s" % title_after_save._new_game_confirm_dialog.visible)
	assert(title_after_save._new_game_confirm_dialog.visible)
	assert(game_root._current_screen == title_after_save)
	# Cancel out without confirming -- the save must survive.
	title_after_save._new_game_confirm_dialog.hide()
	assert(SaveSystem.has_save())

	# -- Resume loads the save and jumps straight to the dashboard --
	var continue_button_3 := _find_button(title_after_save, "Resume Adventure")
	continue_button_3.pressed.emit()
	await process_frame
	print("current screen after Continue is combat screen (expect true): %s" % (game_root._current_screen != title_after_save))
	assert(game_root._current_screen != title_after_save)
	var resumed_screen = game_root._current_screen
	assert(resumed_screen.has_method("_on_fight_pressed"))
	print("restored gold/seed (expect 35 / 314159): %d / %d" % [build_state.gold, build_state.adventure_seed])
	assert(build_state.gold == 35)
	assert(build_state.adventure_seed == 314159)
	assert(build_state.selected_class.id == rogue.id)
	assert(build_state.ranked_build.primary_tree().id == "tree.bladedancer")
	assert(build_state.selected_trees.size() == 1)
	assert(build_state.selected_trees[0].display_name == "Bladedancer")

	# -- Abandon Run deletes the save --
	var abandon_button := _find_button_by_name(resumed_screen, "AbandonRunButton")
	assert(abandon_button != null)
	abandon_button.pressed.emit()
	await process_frame
	assert(resumed_screen._confirm_dialog.visible)
	resumed_screen._confirm_dialog.confirmed.emit()
	await process_frame
	print("has_save after Abandon Run (expect false): %s" % SaveSystem.has_save())
	assert(not SaveSystem.has_save())
	assert(game_root._current_screen != resumed_screen)

	var final_title = game_root._current_screen
	var continue_button_4 := _find_button(final_title, "Resume Adventure")
	assert(continue_button_4 != null)
	print("continue button disabled after abandon (expect true): %s" % continue_button_4.disabled)
	assert(continue_button_4.visible)
	assert(continue_button_4.disabled)

	# -- P2:R7:T8: Restart Adventure/New Adventure from a terminal
	# RUN_ENDED state must clear the stale save that was autosaved at that
	# terminal state, the same as New Adventure/New Game already does --
	# otherwise Resume would later offer to resume the run the player just
	# explicitly left behind. Build a second fresh run, drive it to a
	# contract-failed terminal state, autosave (mirroring the real
	# _on_fight_pressed()/_advance_after_reward_or_shop() call sites), press
	# Restart Adventure, and confirm no save survives.
	var adventure_button_3 := _find_button(final_title, "New Adventure")
	adventure_button_3.pressed.emit()
	await process_frame
	assert(game_root._current_screen != final_title)

	var class_select_2 = game_root._current_screen
	var rogue_2: ClassDef = BuildContentRegistry.adventure().classes["class.rogue"]
	class_select_2._on_class_selected(rogue_2)
	class_select_2.advanced.emit()
	await process_frame

	var subclass_select_2 = game_root._current_screen
	var bladedancer_2: SubclassTree = rogue_2.trees.filter(func(t): return t.id == "tree.bladedancer")[0]
	subclass_select_2._on_tree_selected(bladedancer_2)
	subclass_select_2.advanced.emit()
	await process_frame

	var combat_screen_2 = game_root._current_screen
	build_state.run_outcome = BuildState.RunOutcome.CONTRACT_FAILED
	combat_screen_2._apply_outcome_presentation(build_state.run_outcome)
	combat_screen_2._autosave()
	await process_frame
	print("has_save before Restart Adventure (expect true): %s" % SaveSystem.has_save())
	assert(SaveSystem.has_save())

	var restart_button := _find_button(combat_screen_2, "Restart Adventure")
	assert(restart_button != null)
	assert(restart_button.visible and not restart_button.disabled)
	restart_button.pressed.emit()
	await process_frame
	print("has_save after Restart Adventure (expect false): %s" % SaveSystem.has_save())
	assert(not SaveSystem.has_save())
	assert(game_root._current_screen != combat_screen_2)

	print("")
	print("P2:R6:T4 save/load UI hooks check: OK")
	SaveSystem.delete_save()
	SaveSystem.save_path = SaveSystem.SAVE_PATH
	quit()


func _find_button(root_node: Node, text: String) -> Button:
	for child in root_node.find_children("*", "Button", true, false):
		if child.text == text:
			return child
	return null


func _find_button_by_name(root_node: Node, button_name: String) -> Button:
	return root_node.find_child(button_name, true, false) as Button


func _nearest_panel(node: Node) -> PanelContainer:
	var current := node.get_parent()
	while current != null:
		if current is PanelContainer:
			return current
		current = current.get_parent()
	return null
