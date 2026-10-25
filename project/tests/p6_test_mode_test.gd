extends SceneTree
const Core = preload("res://tests/fixtures/p6/bladedancer_core/core.gd")
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if not ok:
		failed = true
		printerr("FAILED: " + label)

func _run() -> void:
	var state = root.get_node("BuildState")
	state.reset()
	SaveSystem.save_path = "res://reports/t4_adventure_sentinel.json"
	PracticeSaveSystem.save_path = "res://reports/t4_practice_sentinel.json"
	SaveSystem.write_json(SaveSystem.save_path, {"preserve": "Adventure"})
	SaveSystem.write_json(PracticeSaveSystem.save_path, {"preserve": "Practice"})
	var adventure := FileAccess.get_file_as_bytes(SaveSystem.save_path)
	var practice := FileAccess.get_file_as_bytes(PracticeSaveSystem.save_path)
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var title = game._current_screen
	var disabled := 0
	for button in title.find_children("*", "Button", true, false):
		if "Adventure" in button.text:
			check(not button.disabled, "Adventure entry available with saved slot")
			disabled += 1
	check(disabled == 2, "Both Adventure entries visible")
	check(not title.adventure_pressed.get_connections().is_empty() and not title.continue_pressed.get_connections().is_empty(), "Adventure entry signals connected")
	game._on_contract_test_pressed(424242, 10)
	await process_frame
	check(state.is_test_mode and SaveSystem.session_only, "Memory-only session")
	check(state.earned_talent_points == 10 and state.rotation.is_empty() and state.ranked_build.points_spent() == 0, "Fresh ten-point empty build")
	check(state.selected_trees.size() == 1 and state.selected_class.trees.size() == 4, "Core starts selected; mixed extension available")
	var registry := BuildContentRegistry.test_mode()
	check(registry.error == "" and registry.revision == "p6.playable.shadow.1", "Reviewed playable registry")
	check(SaveSystem.registry().revision == "p6.adventure.1", "Adventure registry promoted; Test Mode remains separate")
	for id in Core.RANKS:
		for rank in Core.RANKS[id]:
			check(state.select_talent(registry.talents[id]), "Core allocation " + id)
	check(state.ranked_build.rank_map() == Core.RANKS, "Exact approved allocation")
	var stats: PlayerStats = state.current_player_stats()
	check(stats.footwork_rank == 5 and stats.readiness_enabled and is_equal_approx(stats.retrigger_chance, 0.07), "Core effects active")
	var skills: Array[Skill] = state.unlocked_skills()
	check(skills.size() == 7, "Core skill coverage")
	state.set_rotation(Core.rotation(skills))
	check(state.rotation.size() == 5, "Editable approved rotation")
	check(state.accept_contract_offer(), "Contract acceptance")
	check(state.needs_secondary_subclass_choice(), "Supported secondary offered at contract transition")
	check(not state.choose_secondary_tree(load("res://data/subclass_trees/assassin.tres")), "Secondary selection rejected")
	check(state.choose_contract_route_node(state.current_route_node.next_nodes[0]), "Generated enemy committed")
	var screen = game._current_screen
	state.set_locked(true)
	screen._on_fight_pressed()
	check(state.last_combat_result != null and state.last_combat_result.is_valid, "Actual UI fight resolves")
	screen._autosave()
	SaveSystem.delete_save()
	check(SaveSystem.load_run_result(state).status == "failed", "Adventure load blocked in Test Mode")
	check(FileAccess.get_file_as_bytes(SaveSystem.save_path) == adventure, "Combat/autosave/delete preserved Adventure")
	check(FileAccess.get_file_as_bytes(PracticeSaveSystem.save_path) == practice, "Combat preserved Practice")
	game._on_adventure_restart_pressed()
	await process_frame
	check(state.is_test_mode and state.adventure_seed == 424242 and state.earned_talent_points == 10 and state.rotation.is_empty() and state.ranked_build.points_spent() == 0, "Restart is fresh Test Mode with same seed")
	# Exercise retry and terminal failure separately from the actual resolver above.
	var retry_rotation: Array[Skill] = [state.unlocked_skills()[1]]
	state.set_rotation(retry_rotation)
	state.accept_contract_offer()
	state.choose_contract_route_node(state.current_route_node.next_nodes[0])
	state.set_locked(true)
	check(state.start_fight(), "Retry setup starts")
	state.finish_fight(false)
	game._current_screen._autosave()
	check(state.retry_current_encounter(), "Standard retry remains available")
	state.set_locked(true)
	check(state.start_fight(), "Second attempt starts")
	state.finish_fight(false)
	check(state.run_outcome == state.RunOutcome.CONTRACT_FAILED, "Second loss ends contract")
	check(game._current_screen._outcome_presentation(state.run_outcome).restart_text == "Restart Test Mode", "Terminal action names Test Mode")
	game._on_adventure_restart_pressed()
	await process_frame
	# Walk the route with synthetic wins to exercise rewards and next-contract persistence.
	state.accept_contract_offer()
	var steps := 0
	while state.completed_contract_count == 0 and steps < 30:
		check(state.choose_contract_route_node(state.current_route_node.next_nodes[0]), "Reward route node")
		state.finish_fight(true)
		check(state.claim_current_reward(), "Reward claim")
		game._current_screen._autosave()
		state.continue_after_win()
		steps += 1
	check(state.completed_contract_count == 1 and state.earned_talent_points == 13, "Contract loop grants three-point reward")
	check(state.pending_contract_offers.size() == 3 and not state.needs_secondary_subclass_choice(), "Next offers retain scoped content")
	for offer in state.pending_contract_offers:
		check(offer.route_difficulty == "medium", "Contract loop retains medium difficulty")
	check(FileAccess.get_file_as_bytes(SaveSystem.save_path) == adventure, "Retry/reward/next-contract preserve Adventure")
	game._current_screen._on_save_and_quit_pressed()
	await process_frame
	check(not state.is_test_mode and not SaveSystem.session_only and state.selected_class == null, "Exit clears transient state")
	game._on_contract_test_pressed(7)
	await process_frame
	game._current_screen._on_abandon_confirmed()
	await process_frame
	check(not state.is_test_mode and FileAccess.get_file_as_bytes(SaveSystem.save_path) == adventure, "Abandon preserves save and clears session")
	check(FileAccess.get_file_as_bytes(PracticeSaveSystem.save_path) == practice, "All paths preserve Practice")
	game.queue_free()
	await process_frame
	print("M4 Test Mode safety/core checks: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)

