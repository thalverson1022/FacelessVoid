extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await process_frame
	assert(SaveSystem.write_json(SaveSystem.save_path, {"save_version": 1, "gold": 999}))
	var legacy_bytes := FileAccess.get_file_as_bytes(SaveSystem.save_path)
	game._on_continue_pressed()
	await process_frame
	var state = root.get_node("BuildState")
	assert(state.gold == 0 and state.selected_class == null)
	assert(game._current_screen.scene_file_path == "res://scenes/title/title.tscn")
	assert(SaveSystem.last_load_result.status == "failed")
	assert(FileAccess.get_file_as_bytes(SaveSystem.save_path) == legacy_bytes)
	for child in game.get_children():
		if child is AcceptDialog:
			child.queue_free()
	await process_frame
	assert(SaveSystem.write_json(SaveSystem.save_path, {"save_version": 999}))
	var original := FileAccess.get_file_as_bytes(SaveSystem.save_path)
	game._on_continue_pressed()
	await process_frame
	assert(FileAccess.get_file_as_bytes(SaveSystem.save_path) == original)
	game.queue_free()
	await process_frame
	# Actual Practice scene saves successful edits, restores them and keeps Adventure unchanged.
	var practice = load("res://scenes/training_room/training_room.tscn").instantiate()
	root.add_child(practice)
	await process_frame
	practice._state.set_practice_gold(321)
	practice._state.set_fight_seed(7654)
	await process_frame
	await process_frame
	assert(FileAccess.file_exists(practice._state.practice_save_path))
	practice.queue_free()
	await process_frame
	practice = load("res://scenes/training_room/training_room.tscn").instantiate()
	root.add_child(practice)
	await process_frame
	assert(practice._state.gold == 321 and practice._state.fight_seed == 7654)
	assert(FileAccess.get_file_as_bytes(SaveSystem.save_path) == original)
	practice.queue_free()
	await process_frame
	# The shared talent panels consume actual ranks instead of binary selected_talents.
	SaveSystem.registry_override = preload("res://tests/fixtures/p6/registry.gd").make()
	var sandbox := TrainingRoomState.new()
	var rogue: ClassDef = SaveSystem.registry().classes.values()[0]
	sandbox.set_class(rogue)
	assert(sandbox.set_primary_tree(rogue.trees[0]))
	var panel = load("res://scenes/combat/talent_panel.tscn").instantiate()
	panel.state = sandbox
	root.add_child(panel)
	await process_frame
	var add: Button = panel._ranked_view.actions["buy:talent.bladedancer.wet_stone"]
	assert(add != null)
	add.pressed.emit()
	await process_frame
	await process_frame
	assert(sandbox.ranked_build.rank_of("talent.bladedancer.wet_stone") == 1)
	var refund: Button = panel._ranked_view.actions["buy:talent.bladedancer.wet_stone"]
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	refund.gui_input.emit(event)
	await process_frame
	assert(sandbox.ranked_build.points_spent() == 0)
	panel.queue_free()
	SaveSystem.registry_override = null
	state.reset()
	print("P6 persistence UI: PASS (Continue reset/failure, Practice reopen, rank controls)")
	quit()
