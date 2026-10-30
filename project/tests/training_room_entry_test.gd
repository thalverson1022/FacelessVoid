extends SceneTree
## Headless P2:R10:T2 check: the title-screen Practice Room button is
## enabled and reachable, entering/leaving Practice Room never touches
## BuildState, and Back returns to Title. Run with:
##   godot --headless -s res://tests/training_room_entry_test.gd


func _initialize() -> void:
	# -- P2:R10:T2 -- title button + scene skeleton, isolated from BuildState --
	# game_root's own _ready() calls BuildState.reset() on instantiation, so
	# the gold/seed used to prove isolation must be set AFTER game_root is
	# already up and showing Title, not before (setting them before would
	# just get wiped by that startup reset and falsely look like Training
	# Room caused it).
	var build_state = root.get_node("BuildState")

	var game_root_scene: PackedScene = load("res://scenes/game_root.tscn")
	var game_root = game_root_scene.instantiate()
	root.add_child(game_root)
	await process_frame

	build_state.gold = 777
	build_state.set_adventure_seed(999)
	var gold_before: int = build_state.gold
	var seed_before: int = build_state.adventure_seed

	var title = game_root._current_screen
	var training_room_button: Button = null
	for child in title.find_children("*", "Button", true, false):
		if child.text == "Practice Room":
			training_room_button = child
	assert(training_room_button != null)
	print("Practice Room button disabled=%s (expect false)" % training_room_button.disabled)
	assert(not training_room_button.disabled)

	title.training_room_pressed.emit()
	await process_frame

	var training_room = game_root._current_screen
	assert(training_room != null)
	assert(training_room != title)
	var back_button: Button = training_room.find_child("BackButton", true, false)
	assert(back_button != null)
	assert(back_button.text == "")
	assert(back_button.tooltip_text == "Back to Title")
	assert(back_button.custom_minimum_size == Vector2(56, 56))
	assert(back_button.icon != null)
	var header := back_button.get_parent()
	var save_setup := header.get_child(back_button.get_index() + 1) as Button
	assert(save_setup != null and save_setup.text == "Save Setup")
	var reserved_space := header.get_child(header.get_child_count() - 1) as Control
	assert(reserved_space != null)
	assert(reserved_space.custom_minimum_size.x >= 50.0)

	# Entering Practice Room must not touch real Adventure/save state.
	print("gold after entering Practice Room=%d (expect %d), seed=%d (expect %d)" % [
		build_state.gold, gold_before, build_state.adventure_seed, seed_before
	])
	assert(build_state.gold == gold_before)
	assert(build_state.adventure_seed == seed_before)

	back_button.pressed.emit()
	await process_frame
	var back_at_title = game_root._current_screen
	assert(back_at_title != training_room)
	assert(back_at_title.has_signal("training_room_pressed"))

	# Leaving Practice Room must also leave BuildState untouched.
	assert(build_state.gold == gold_before)
	assert(build_state.adventure_seed == seed_before)

	print("Practice Room entry/exit check: OK")
	quit()
