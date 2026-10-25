extends SceneTree

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if not ok:
		failed = true
		printerr("FAILED: " + label)

func _run() -> void:
	SaveSystem.save_path = "res://reports/test_tree_selection_adventure.json"
	PracticeSaveSystem.save_path = "res://reports/test_tree_selection_practice.json"
	var state = root.get_node("BuildState")
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var title = game._current_screen
	check(title.selected_test_main_tree() == "tree.bladedancer", "Default main")
	check(title.selected_test_secondary_tree() == "", "Optional secondary")
	check(title.selected_test_points() == 6, "Six-point Tavern exit default")
	var main: OptionButton = title._test_main_tree
	var secondary: OptionButton = title._test_secondary_tree
	for i in main.item_count:
		main.select(i)
		main.item_selected.emit(i)
		for j in range(1, secondary.item_count):
			check(secondary.is_item_disabled(j) == (secondary.get_item_metadata(j) == main.get_selected_metadata()), "Duplicate disabled")
	secondary.select(1)
	for i in main.item_count:
		if main.get_item_metadata(i) == secondary.get_selected_metadata():
			main.select(i)
			main.item_selected.emit(i)
			break
	check(secondary.selected == 0, "Changing main clears duplicate")
	if DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute("res://reports/p6_test_tree_selection")
		for size in [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]:
			root.size = size
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://reports/p6_test_tree_selection/title-%d.png" % size.x)
	# Exercise the actual title signal with a mixed build.
	secondary.select(2)
	title._test_points.select(1)
	var expected_main: String = title.selected_test_main_tree()
	var expected_secondary: String = title.selected_test_secondary_tree()
	title.contract_test_pressed.emit()
	await process_frame
	check(state.selected_trees.size() == 2 and state.selected_trees[0].id == expected_main and state.selected_trees[1].id == expected_secondary, "Title selections reach build")
	var ids := ["tree.assassin", "tree.bladedancer", "tree.shadow", "tree.thief"]
	for primary in ids:
		for second in ids:
			if primary == second:
				continue
			for budget in [6, 10, 45]:
				game._on_contract_test_pressed(1234, budget, primary, second)
				await process_frame
				check(state.selected_trees.size() == 2 and state.selected_trees[0].id == primary and state.selected_trees[1].id == second, "Ordered pair")
				check(state.earned_talent_points == budget and state.rotation.is_empty() and state.ranked_build.points_spent() == 0, "Fresh budget")
				check(state.accept_contract_offer() and not state.needs_secondary_subclass_choice(), "No repeated secondary prompt")
				game._on_adventure_restart_pressed()
				await process_frame
				check(state.selected_trees[0].id == primary and state.selected_trees[1].id == second and state.earned_talent_points == budget and state.adventure_seed == 1234, "Restart preserves options")
	var previous = state.ranked_build
	game._on_contract_test_pressed(1234, 10, "tree.shadow", "tree.shadow")
	check(state.ranked_build == previous, "Invalid duplicate leaves session intact")
	state.reset()
	var registry := BuildContentRegistry.test_mode()
	state.set_class(registry.classes["class.rogue"])
	check(not state.configure_ranked_build(registry.trees["tree.shadow"], registry.trees["tree.thief"]), "Adventure still requires transition")
	game.queue_free()
	await process_frame
	state.reset()
	print("Test Mode tree selection: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
