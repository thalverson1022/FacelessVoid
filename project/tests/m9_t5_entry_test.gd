extends SceneTree
var checks := 0
func _initialize() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
	checks += 1
	assert(ok, label)
func erase(path: String) -> void:
	if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
func _run() -> void:
	var state = root.get_node("BuildState")
	state.reset()
	var owned := SevenSlotSaveBoundary.paths()
	check(not owned.is_empty() and String(owned.adventure).begins_with("res://reports/"), "isolated UI namespace")
	for path in owned.values():
		erase(path)
		erase(path + ".tmp")
	check(SaveSystem.write_json(owned.adventure, {"save_version": 4}), "old UI fixture")
	check(SaveSystem.write_json(owned.legacy, {"selected_class": null}), "retired unversioned legacy fixture")
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(FileAccess.file_exists(owned.marker) and not FileAccess.file_exists(owned.adventure) and not FileAccess.file_exists(owned.legacy), "actual Title shared reset")
	game._on_new_game_pressed(2468)
	await process_frame
	check(state.adventure_seed == 2468 and state.selected_class == null, "New Adventure enters class selection")
	state.set_class(load("res://data/classes/rogue.tres"))
	check(state.equipped_gear().size() == 1 and state.equipped_weapon.id == "gear.crude_dagger" and state.equipped_legs == null and state.equipped_hands == null, "class selection crude only")
	check(SaveSystem.save_run(state), SaveSystem.last_error)
	var original_screen: Node = game._current_screen
	SevenSlotSaveBoundary.remove_override = func(_path: String) -> int: return ERR_FILE_NO_PERMISSION
	game._on_new_game_pressed(999)
	check(game._current_screen == original_screen and state.adventure_seed == 2468 and state.selected_class != null, "failed deletion blocks New Adventure before mutation")
	for child in game.get_children():
		if child is AcceptDialog:
			child.hide()
			child.queue_free()
	await process_frame
	game._on_adventure_restart_pressed()
	check(game._current_screen == original_screen and state.selected_class != null, "failed deletion blocks restart")
	for child in game.get_children():
		if child is AcceptDialog:
			child.hide()
			child.queue_free()
	await process_frame
	SevenSlotSaveBoundary.remove_override = Callable()
	game._on_adventure_restart_pressed()
	await process_frame
	check(state.selected_class == null and state.adventure_seed == 2468 and not FileAccess.file_exists(owned.adventure), "successful restart clears save preserves seed")
	# Malformed and future files still require explicit replacement confirmation.
	check(SaveSystem.write_json(owned.adventure, {"save_version": 6}), "future UI fixture")
	game._show_title(false)
	await process_frame
	check(not SaveSystem.has_save() and SaveSystem.has_saved_file(), "future is not resumable but requires replacement confirmation")
	game._current_screen._on_adventure_button_pressed()
	check(game._current_screen._new_game_confirm_dialog.visible, "future file confirmation visible")
	game._current_screen._new_game_confirm_dialog.hide()
	# Test entry and restart do not touch any envelope or invoke reset cleanup.
	game._on_contract_test_pressed(4242, 10)
	await process_frame
	check(state.is_test_mode and SaveSystem.session_only and state.gold == 100, "Test Mode baseline")
	check(state.equipped_gear().size() == 1 and state.equipped_weapon.id == "gear.legendary.bandit_blade" and state.equipped_legs == null and state.equipped_hands == null, "Test Bandit only, new slots empty")
	var bytes := FileAccess.get_file_as_bytes(owned.adventure)
	erase(owned.marker)
	game._on_adventure_restart_pressed()
	await process_frame
	check(state.is_test_mode and SaveSystem.session_only and state.gold == 100 and state.adventure_seed == 4242, "Test restart remains memory only")
	check(FileAccess.get_file_as_bytes(owned.adventure) == bytes and not FileAccess.file_exists(owned.marker), "Test restart no reset read/write/delete")
	game._current_screen._autosave()
	check(FileAccess.get_file_as_bytes(owned.adventure) == bytes and not FileAccess.file_exists(owned.marker), "Test autosave bypass")
	game.queue_free()
	await process_frame
	state.reset()
	print("M9 T5 entry PASS (%d checks)" % checks)
	quit()
