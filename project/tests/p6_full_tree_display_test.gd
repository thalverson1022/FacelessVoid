extends "res://tests/p6_core_journey_test.gd"
const Mixed = preload("res://tests/fixtures/p6/mixed_build.gd")
const Display = preload("res://scripts/ui/full_tree_display.gd")

func _initialize() -> void:
	super._initialize()

func _run() -> void:
	report = "res://reports/p6_t10_full_tree_preview"
	visual = "--visual" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(report)
	SaveSystem.save_path = report + "/adventure.json"
	PracticeSaveSystem.save_path = report + "/legacy.json"
	PracticeSaveSystem.core_save_path = report + "/preview-practice.json"
	if FileAccess.file_exists(PracticeSaveSystem.core_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PracticeSaveSystem.core_save_path))
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._show_training_room()
	await settle()
	var scene = game._current_screen
	var state = scene._state
	state.set_talent_budget(20)
	scene._talent_overlay.show()
	await settle()
	var initial_view = scene._talent_panel._ranked_view
	var primary_rect: Rect2 = initial_view.find_child("PrimaryTreePanel", true, false).get_global_rect()
	var secondary_rect: Rect2 = initial_view.find_child("SecondaryTreePanel", true, false).get_global_rect()
	check(absf(primary_rect.size.x - secondary_rect.size.x) <= 1, "Unselected secondary reserves half the tree area")
	await capture("panels-primary-only")
	check(initial_view.find_child("SecondaryChoice_tree_thief", true, false) != null, "Secondary selection uses a subclass card")
	initial_view.actions["secondary:tree.thief"].pressed.emit()
	check(state.ranked_build.secondary_tree().id == "tree.thief", "Secondary card Choose selects Thief")
	for id in Mixed.RANKS:
		for rank in Mixed.RANKS[id]: state.select_talent(state.content_registry.talents[id])
	await settle()
	var view = scene._talent_panel._ranked_view
	var selected_primary: Rect2 = view.find_child("PrimaryTreePanel", true, false).get_global_rect()
	check(absf(primary_rect.size.x - selected_primary.size.x) <= 1, "Selecting secondary preserves primary panel width")
	var ranks: Dictionary = state.ranked_build.rank_map()
	var before: Dictionary = BuildSaveCodec.encode(state, state.content_registry)
	var preview_count := 0
	for tree in state.selected_trees:
		var display := Display.tree_for(tree)
		check(display.talents.size() == (13 if tree.id == "tree.bladedancer" else 10), "Complete tree talent coverage " + tree.id)
		check(display.automatic_unlocks.size() == 5, "Five authored skill positions " + tree.id)
		for talent in display.talents:
			if not talent.get_meta("display_only", false): continue
			preview_count += 1
			check(view.actions.has("preview:" + talent.id) and not view.actions.has("buy:" + talent.id), "Preview has no purchase control " + talent.id)
			view.actions["preview:" + talent.id].pressed.emit()
			await settle()
			check(state.ranked_build.rank_map() == ranks, "Preview activation cannot allocate " + talent.id)
			check(not state.select_talent(talent), "State rejects display-only talent " + talent.id)
			var forged := before.duplicate(true)
			forged.talent_ranks[talent.id] = 1
			check(BuildSaveCodec.decode(forged, state.content_registry).error != "", "Save rejects preview rank " + talent.id)
	check(preview_count == 0 and state.content_registry.talents.size() == 44 and state.unlocked_skills().size() == 10, "No remaining previews; forty-four playable talents preserve exact mixed ten skills")
	check(BuildSaveCodec.encode(state, state.content_registry) == before, "All preview interactions preserve encoded build")
	var edges := 0
	for tree in state.selected_trees: edges += view.find_child("TalentGraph_" + tree.id.replace(".", "_"), true, false).edges.size()
	check(edges == 4, "All four mapped dependencies are visible")
	view.feedback = ""
	view.refresh()
	scene._talent_overlay.show()
	scene._talent_overlay_scroll.scroll_vertical = 0
	await settle()
	check_layout(view)
	check(not scene._talent_overlay_scroll.get_v_scroll_bar().visible, "Practice fits without unnecessary vertical scrolling")
	check(view.find_child("PrimaryTreePanel", true, false).is_ancestor_of(view.actions["PrimaryTreeOption"]), "Practice primary selector is inside its tree panel")
	var practice_height: float = scene._talent_overlay_content.size.y
	await capture("compact-grid-trees")
	view.actions["reset:tree.bladedancer"].pressed.emit()
	await settle()
	check(state.ranked_build.tree_points(state.ranked_build.primary_tree()) == 0, "Primary reset clears all primary ranks atomically")
	check(state.ranked_build.rank_of("talent.keen_eye") == 5, "Primary reset preserves secondary ranks")
	check(state.ranked_build.secondary_tree().id == "tree.thief" and state.ranked_build.unspent_points() == 15, "Primary reset retains roles and refunds only its points")
	await capture("available-tree-nodes")
	view.actions["reset:tree.thief"].pressed.emit()
	await settle()
	check(state.ranked_build.points_spent() == 0 and state.ranked_build.unspent_points() == 20, "Secondary reset refunds remaining points")
	game._on_contract_test_pressed(7, 10)
	await settle()
	var combat = game._current_screen
	combat._talent_overlay.show_overlay()
	await settle()
	await settle()
	check(not combat._talent_overlay._scroll.get_v_scroll_bar().visible, "Test Mode fits without unnecessary vertical scrolling")
	check(combat._talent_overlay._content.size.y < practice_height, "Test Mode height excludes Practice-only controls")
	await capture("test-mode-content-fit")
	game.queue_free()
	await settle()
	SaveSystem.write_json(report + ("/visual-checks.json" if visual else "/checks.json"), {"passed": not failed, "count": checks, "evidence": evidence})
	print("Full-tree preview: %d checks %s" % [checks, "FAIL" if failed else "PASS"])
	quit(1 if failed else 0)

func check_layout(view: Control) -> void:
	var blade = view.find_child("TalentGraph_tree_bladedancer", true, false)
	var thief = view.find_child("TalentGraph_tree_thief", true, false)
	check(is_equal_approx(blade.global_position.y, thief.global_position.y) and blade.get_global_rect().end.x < thief.global_position.x, "Primary and secondary are side by side with aligned tiers")
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Display.CATALOG))
	for tree_data in catalog.trees:
		if tree_data.id not in ["tree.bladedancer", "tree.thief"]: continue
		var graph = blade if tree_data.id == "tree.bladedancer" else thief
		for entry in tree_data.talents:
			var node: Control = graph.nodes[entry.id]
			check(is_equal_approx((node.position.x + node.size.x / 2) / graph.size.x, float(entry.position.x)), "Authored horizontal coordinate: " + entry.id)
			check(is_equal_approx(node.position.y, (5 - int(entry.tier)) * 68.0), "Authored tier: " + entry.id)
			var clear := true
			for other in graph.nodes:
				if other != entry.id and node.get_rect().intersects(graph.nodes[other].get_rect()): clear = false
			check(clear, "Authored nodes do not overlap: " + entry.id)
	for graph in [blade, thief]:
		for edge in graph.edges:
			var source: Rect2 = graph.nodes[edge[0]].get_global_rect()
			var target: Rect2 = graph.nodes[edge[1]].get_global_rect()
			check(is_equal_approx(source.get_center().x, target.get_center().x) and target.end.y < source.position.y, "Dependency uses aligned top-to-bottom anchors: " + edge[1])
			var corridor := Rect2(Vector2(source.get_center().x - 1, target.end.y), Vector2(2, source.position.y - target.end.y))
			var clear := true
			for id in graph.nodes:
				if id not in edge and corridor.intersects(graph.nodes[id].get_global_rect()): clear = false
			check(clear, "Dependency avoids unrelated nodes: " + edge[1])
	check(root.get_visible_rect().encloses(view.actions["reset:tree.bladedancer"].get_global_rect()), "Reset points is visible without scrolling")

