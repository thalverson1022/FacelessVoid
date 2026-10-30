extends "res://tests/p6_t10_usability_test.gd"
const Full = preload("res://tests/p6_full_thief_test.gd")

func _initialize() -> void:
	super._initialize()

func allocate_full(view, state) -> void:
	for pair in Full.PURCHASES:
		for rank in pair[1]: await press_rank(view,"buy:"+pair[0])
	check(state.ranked_build.points_spent()==35, "All 35 points purchased through actual UI")
	for pair in Full.PURCHASES:
		check(view.actions.has("buy:"+pair[0]) and not view.actions.has("preview:"+pair[0]), "Promoted talent has playable control")

func _run() -> void:
	report = "res://reports/p6_m5_t6_journey"
	visual = "--visual" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(report)
	SaveSystem.save_path = report+"/adventure.json"
	PracticeSaveSystem.save_path = report+"/legacy.json"
	PracticeSaveSystem.core_save_path = report+"/practice.json"
	if FileAccess.file_exists(PracticeSaveSystem.core_save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(PracticeSaveSystem.core_save_path))
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	var title = game._current_screen
	check(title.selected_test_points()==6, "Title defaults to six-point Tavern exit")
	title._test_points.select(1)
	check(title.selected_test_points()==45, "Title offers full-tree budget")
	await capture("title-budget")
	title.contract_test_pressed.emit()
	await settle()
	var state = root.get_node("BuildState")
	check(state.earned_talent_points==45, "Title selection starts 45-point Test Mode")
	var screen = game._current_screen
	var view = screen._talent_overlay._talent_panel._ranked_view
	screen._contract_overlay.accept_requested.emit("")
	await settle()
	await press_rank(view,"secondary:tree.thief")
	await allocate_full(view,state)
	screen._map_overlay.route_node_pressed.emit(state.current_route_node.next_nodes[0])
	await settle()
	screen._contract_overlay.hide()
	screen._map_overlay.hide()
	screen._talent_overlay.show()
	await capture("test-full-tree")
	screen._talent_overlay.hide()
	for id in ["skill.pick_pocket","skill.steal","skill.mug","skill.big_score","skill.stab"]: await add_skill(available_panel(screen),id)
	screen._skill_build_panel._lock_button.pressed.emit()
	screen._on_fight_pressed()
	screen.set_process(false)
	check(state.last_combat_result != null and state.last_combat_result.is_valid, "Full allocated Test Mode combat resolves")
	screen._on_playback_skip_pressed()
	game._on_adventure_restart_pressed()
	await settle()
	check(state.earned_talent_points==45 and state.ranked_build.points_spent()==0, "Restart keeps selected budget and clears ranks")
	game._on_main_menu_pressed()
	await settle()
	game._show_training_room()
	await settle()
	var practice = game._current_screen
	var p = practice._state
	practice._show_talent_overlay()
	await settle()
	view = practice._talent_panel._ranked_view
	view.actions["PrimaryTreeOption"].select(2)
	view.actions["PrimaryTreeOption"].item_selected.emit(2)
	await settle()
	check(p.ranked_build.primary_tree().id=="tree.thief","Practice selects primary Thief")
	await allocate_full(view,p)
	check(await tab_to(view,"buy:talent.thief.load_dice"), "Keyboard reaches capstone")
	await key(KEY_F1)
	var navigation = practice._talent_overlay.get_node("TalentKeyboardNavigation")
	check(navigation.details.visible and "300" in navigation.details.dialog_text and "Loaded Dice" in navigation.details.dialog_text, "Keyboard shows actual capstone description")
	await capture("capstone-details")
	await key(KEY_ESCAPE,false,navigation.details)
	scale_text(practice._talent_overlay)
	await settle()
	geometry(view,"Full tree 125% text")
	await capture("practice-full-tree-125")
	practice._talent_overlay.hide()
	for id in ["skill.pick_pocket","skill.steal","skill.mug","skill.big_score","skill.stab","skill.mug"]: await add_skill(available_panel(practice),id)
	practice._on_practice_gold_changed(499)
	practice._on_fight_seed_changed(7)
	practice._on_random_fight_seed_toggled(false)
	practice._skill_build_panel._lock_button.pressed.emit()
	practice._fight_button.pressed.emit()
	practice._combat_view.set_process(false)
	check(p.last_result != null and p.last_result.is_valid, "Complete Practice allocation fights")
	if visual:
		practice._combat_view.set_process(true)
		await create_timer(2.0).timeout
		practice._combat_view.set_process(false)
	else:
		practice._combat_view._process(2.0)
	await capture("practice-full-playing")
	practice._combat_view._skip()
	var damage: float = p.last_result.total_damage
	practice._fight_button.pressed.emit()
	practice._combat_view.set_process(false)
	check(p.last_result.total_damage==damage,"Full Practice fixed-seed retry repeats")
	practice._combat_view._skip()
	check(PracticeSaveSystem.save_setup(p),"Full UI setup saves")
	var saved_ids := ids(p.rotation)
	game._on_main_menu_pressed()
	await settle()
	game._show_training_room()
	await settle()
	practice = game._current_screen
	p = practice._state
	check(p.ranked_build.points_spent()==35 and ids(p.rotation)==saved_ids,"Full tree and duplicate rotation reload")
	view = practice._talent_panel._ranked_view
	await press_rank(view,"reset:tree.thief")
	check(p.ranked_build.points_spent()==0 and ids(p.rotation)==["skill.stab"],"Reset prunes tree skills and keeps base skill")
	game.queue_free()
	await settle()
	state.reset()
	SaveSystem.write_json(report+("/visual-checks.json" if visual else "/checks.json"),{"passed":not failed,"count":checks,"evidence":evidence})
	print("Full Thief journeys: %d checks %s" % [checks,"FAIL" if failed else "PASS"])
	quit(1 if failed else 0)
