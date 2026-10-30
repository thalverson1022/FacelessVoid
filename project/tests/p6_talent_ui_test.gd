extends SceneTree
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		printerr("FAILED: " + message)

func settle() -> void:
	await process_frame
	await process_frame
	await process_frame

func press(view, key: String) -> void:
	var actual := key.replace("refund:", "buy:")
	check(view.actions.has(actual), "Action exists: " + key)
	if view.actions.has(actual):
		view.actions[actual].grab_focus()
		if key.begins_with("refund:"):
			var event := InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_RIGHT
			event.pressed = true
			view.actions[actual].gui_input.emit(event)
		else:
			view.actions[actual].pressed.emit()
	await settle()

func _run() -> void:
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_contract_test_pressed(7, 10)
	await settle()
	var state = root.get_node("BuildState")
	var screen = game._current_screen
	var view = screen._talent_overlay._talent_panel._ranked_view
	var before: Dictionary = state.ranked_build.rank_map()
	await press(view, "buy:talent.bladedancer.fancy_footwork")
	check(state.ranked_build.rank_map() == before and view.feedback == "", "Gate rejects silently without mutation")
	check(root.gui_get_focus_owner() == view.actions["buy:talent.bladedancer.fancy_footwork"], "Rejected action preserves focus")
	for i in 4:
		await press(view, "buy:talent.bladedancer.wet_stone")
	await press(view, "buy:talent.bladedancer.rending_slash")
	for i in 5:
		await press(view, "buy:talent.bladedancer.fancy_footwork")
	check(state.ranked_build.points_spent() == 10 and state.unlocked_skills().size() == 7, "Actual rank buttons allocate core and unlock skills")
	check(view.find_child("PointSummary", true, false) == null and view.find_child("TreePoints", true, false) != null, "Per-tree counts replace points subtitle")
	var supported: Dictionary = state.ranked_build.rank_map()
	await press(view, "refund:talent.bladedancer.wet_stone")
	check(state.ranked_build.rank_map()==supported and view.feedback == "","Lower-tier refund blocked silently")
	var macro: Array[Skill] = []
	for skill in state.unlocked_skills():
		if skill.id == "skill.parry_strike":
			macro.append(skill)
	state.set_rotation(macro)
	await settle()
	for i in 5:
		await press(view, "refund:talent.bladedancer.fancy_footwork")
	check(state.rotation.is_empty(), "Refund prunes locked skill")
	# The final refund updates feedback; check removal at the crossing separately.
	await press(view, "buy:talent.bladedancer.fancy_footwork")
	state.set_rotation(macro)
	await settle()
	await press(view, "refund:talent.bladedancer.fancy_footwork")
	check(view.feedback == "Allocation updated.", "Refund keeps rotation removal status silent")
	await press(view, "buy:talent.bladedancer.fancy_footwork")
	check(state.rotation.is_empty(), "Reunlock does not restore rotation")
	state.accept_contract_offer()
	await settle()
	check(not view.actions["reset:tree.bladedancer"].disabled and not view.get_node("ResetPointsNotice").visible, "Test Mode allows reset inside accepted contract")
	await press(view, "reset:tree.bladedancer")
	check(state.ranked_build.points_spent() == 0 and state.ranked_build.unspent_points() == 10 and state.selected_trees[0].id == "tree.bladedancer", "Test Mode reset refunds points and retains tree")
	await press(view, "buy:talent.bladedancer.wet_stone")
	before = state.ranked_build.rank_map()
	for phase in [state.RunPhase.FIGHTING, state.RunPhase.RESULT]:
		state.run_phase = phase
		state.run_state_changed.emit()
		await settle()
		check(view.actions["reset:tree.bladedancer"].disabled and view.get_node("ResetPointsNotice").visible, "Combat/result reset restriction is visible beside disabled button")
		check(not state.refund_all_talents() and state.ranked_build.rank_map() == before, "State rejects combat/result reset without mutation")
	state.run_phase = state.RunPhase.PLANNING
	state.run_state_changed.emit()
	await settle()
	check(not view.actions["reset:tree.bladedancer"].disabled, "Reset re-enables for next fight planning")
	await press(view, "reset:tree.bladedancer")
	check(state.ranked_build.points_spent() == 0, "Reset works during in-contract fight planning")
	game._on_main_menu_pressed()
	await settle()
	SaveSystem.write_json(PracticeSaveSystem.save_path, {"legacy_practice": "preserve"})
	var legacy_practice := FileAccess.get_file_as_bytes(PracticeSaveSystem.save_path)
	game._show_training_room()
	await settle()
	var practice = game._current_screen
	var p: TrainingRoomState = practice._state
	p.practice_save_path = PracticeSaveSystem.core_save_path
	p.refund_all_talents()
	p.set_talent_budget(10)
	await settle()
	view = practice._talent_panel._ranked_view
	await press(view, "buy:talent.bladedancer.wet_stone")
	check(p.ranked_build.points_spent() == 1, "Practice uses ranked core")
	check(PracticeSaveSystem.save_setup(p), "Scoped Practice save")
	check(FileAccess.get_file_as_bytes(PracticeSaveSystem.save_path) == legacy_practice, "Existing Practice save preserved")
	var restored := TrainingRoomState.new()
	restored.content_registry = BuildContentRegistry.test_mode()
	restored.practice_save_path = p.practice_save_path
	check(PracticeSaveSystem.load_setup(restored).status == "loaded", "Scoped Practice load")
	check(restored.ranked_build.points_spent() == 1 and restored.earned_talent_points == 10 and restored.content_registry != null, "Practice ranks/budget/registry retained")
	p.allocation_locked = true
	p.lock_changed.emit()
	await settle()
	await press(view, "buy:talent.bladedancer.wet_stone")
	check(p.ranked_build.points_spent() == 1 and view.feedback == "", "Playback blocks allocation")
	p.allocation_locked = false
	check(p.set_primary_tree(null), "Practice can clear primary")
	await settle()
	check(p.selected_trees.is_empty() and p.ranked_build.points_spent() == 0, "Removing primary clears roles and ranks")
	check(p.set_primary_tree(p.selected_class.trees[0]), "Practice can reselect primary")
	check(not p.set_secondary_tree(p.selected_class.trees[0]), "Duplicate role rejected")
	# Synthetic dependency exercises connectors and refund rejection without promoting content.
	var tree: SubclassTree = p.selected_class.trees[0].duplicate(true)
	tree.talents[1].prerequisite_ids = [tree.talents[0].id]
	p.selected_class.trees = [tree]
	p.ranked_build.configure(tree, null, 10)
	p.selected_trees = [tree]
	p.build_changed.emit()
	await settle()
	await press(view, "buy:" + tree.talents[0].id)
	await press(view, "buy:" + tree.talents[1].id)
	await press(view, "refund:" + tree.talents[0].id)
	check(p.ranked_build.points_spent() == 2 and view.feedback == "", "Dependent refund stays blocked silently")
	check(view.find_child("TalentGraph_tree_bladedancer", true, false).edges.has([tree.talents[0].id, tree.talents[1].id]), "Prerequisite connector recorded")
	await press(view, "reset:tree.bladedancer")
	check(p.set_talent_budget(0), "Zero-point Practice supported")
	await settle()
	await press(view, "buy:" + tree.talents[0].id)
	check(p.ranked_build.points_spent() == 0 and view.feedback == "", "Zero budget rejects purchase")
	var fixture = preload("res://tests/fixtures/p6/registry.gd").make()
	var roles := TrainingRoomState.new()
	roles.set_class(fixture.classes["class.rogue"])
	roles.set_primary_tree(fixture.trees["tree.bladedancer"])
	roles.set_secondary_tree(fixture.trees["tree.thief"])
	roles.select_talent(fixture.talents["talent.bladedancer.wet_stone"])
	var ranks := roles.ranked_build.rank_map()
	check(roles.swap_tree_roles() and roles.ranked_build.primary_tree().id == "tree.thief" and roles.ranked_build.rank_map() == ranks, "Supported role swap retains ranks")
	game.queue_free()
	await settle()
	print("T5 allocation UI checks: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
