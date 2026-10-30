extends SceneTree
const Accent = preload("res://scripts/ui/skill_category_icon_accent.gd")
var failed := false
func _initialize() -> void: call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		printerr("FAILED: " + message)
func accents(node: Node) -> Array:
	var result := []
	for child in node.get_children():
		if child.get_script() == Accent: result.append(child)
		result.append_array(accents(child))
	return result
func shot(name: String) -> void:
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://reports/icon_accents/" + name + ".png")
func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/icon_accents")
	var state = root.get_node("BuildState")
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._on_contract_test_pressed(1234,45,"tree.assassin","tree.shadow")
	await process_frame
	var screen = game._current_screen
	check(state.ranked_build.configure(state.selected_trees[0],state.selected_trees[1],45,{"talent.assassin.quick_hands":5,"talent.assassin.precision":5,"talent.assassin.hastened_poison":2,"talent.assassin.poison_strike":1}),"Legal representative unlocks")
	state._finish_rank_edit(true)
	state.rotation.assign(state.unlocked_skills().filter(func(skill): return preload("res://scripts/ui/skill_category_preview_style.gd").icon_selected(skill)))
	state.build_changed.emit()
	screen._contract_overlay.hide()
	screen._map_overlay.hide()
	await process_frame
	var selector = screen.find_child("CategoryIconStyle",true,false)
	check(selector != null, "Test-only comparison available")
	check(selector.selected == 1, "Available Skills defaults to bottom edge")
	check(int(state.get_meta("category_tree_icon_style",2)) == 2, "Tree defaults independently to filled box")
	check(accents(screen._skill_build_panel).size() == state.rotation.size(), "Every macro skill gets an accent")
	var original_sizes := {}
	for accent in accents(screen):
		check(accent.mouse_filter == Control.MOUSE_FILTER_IGNORE,"Accent cannot intercept input")
		original_sizes[accent] = accent.get_parent().get_combined_minimum_size()
	for width in [1280,1600,1920]:
		root.size = Vector2i(width,width*9/16)
		for mode in [0,1,2,3]:
			selector.select(mode)
			selector.item_selected.emit(mode)
			await shot("palette-%d-%d" % [width,mode])
			for accent in original_sizes:
				if is_instance_valid(accent): check(accent.get_parent().get_combined_minimum_size()==original_sizes[accent],"Treatment preserves button dimensions")
			screen._show_talent_overlay()
			var tree_selector = screen._talent_overlay.find_child("CategoryTreeIconStyle", true, false)
			tree_selector.select(mode)
			tree_selector.item_selected.emit(mode)
			await shot("tree-%d-%d" % [width,mode])
			for accent in accents(screen._talent_overlay):
				var art: TextureRect = accent.get_parent().get_node("Icon")
				check(not accent.get_parent() is IconTooltipButton or art.size == Vector2(24,24) or accent.skill.id == "skill.poison_strike", "Unlock artwork fits dedicated space above point label")
				check(accent.size == accent.get_parent().size, "Category border spans button bounding box")
			check_tree_coverage(screen._talent_overlay, state)
			screen._talent_overlay.hide()
	check(state.refund_tree_talents("tree.assassin"), "Reset allocated tree")
	await process_frame
	await process_frame
	check_tree_coverage(screen._talent_overlay, state)
	# Exercise the remaining trees through the actual Test Mode entry point.
	state.set_meta("category_tree_icon_style", 2)
	state.set_meta("category_icon_style", 1)
	game._on_contract_test_pressed(1234,45,"tree.bladedancer","tree.thief")
	await process_frame
	screen = game._current_screen
	screen._contract_overlay.hide()
	screen._map_overlay.hide()
	screen._show_talent_overlay()
	await process_frame
	await shot("bladedancer-thief-filled")
	check_tree_coverage(screen._talent_overlay, state)
	state.is_test_mode = false
	game._show_combat_screen()
	await process_frame
	check(game._current_screen.find_child("CategoryIconStyle",true,false)==null and not accents(game._current_screen).is_empty(),"Adventure has accents without comparison selector")
	check(game._current_screen.find_child("TreePointCounter",true,false)!=null,"Adventure has per-tree counters")
	check(game._current_screen.find_child("PointSummary",true,false)==null,"Redundant points subtitle removed")
	game._current_screen._show_talent_overlay()
	await shot("adventure-tree-counters")
	game._show_training_room()
	await process_frame
	await process_frame
	var practice_screen = game._current_screen
	practice_screen._talent_overlay.show()
	await shot("practice-tree-counters")
	check(practice_screen.find_child("TreePointCounter",true,false)!=null,"Practice has per-tree counters")
	check(practice_screen.find_child("PointSummary",true,false)==null,"Practice removes redundant points subtitle")
	check(not accents(practice_screen).is_empty(),"Practice has category icon accents")
	game.queue_free()
	await process_frame
	state.reset()
	print("Icon accents: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)

func check_tree_coverage(overlay: Node, state) -> void:
	var expected := {}
	for tree in state.selected_trees:
		var column = overlay.find_child("TreeColumn_" + tree.id.replace(".", "_"), true, false)
		var counter = column.find_child("TreePoints", true, false)
		check(counter != null and counter.text == "%d/35" % state.ranked_build.tree_points(tree), "Live point count for " + tree.id)
		var display = preload("res://scripts/ui/full_tree_display.gd").tree_for(tree)
		for unlock in display.automatic_unlocks:
			if unlock.skill != null: expected[unlock.skill.id] = true
		for talent in display.talents:
			for skill in talent.unlocked_skills:
				expected[skill.id] = true
	var actual := {}
	for accent in accents(overlay):
		actual[accent.skill.id] = true
		check(accent.tree_unlock, "Tree skills use tree fill treatment")
	check(actual.size() == expected.size(), "All tree skill boxes accented; passives untouched")
	for id in expected:
		check(actual.has(id), "Tree accent exists for " + id)
