extends SceneTree
var state
var screen
var failed := false
var checks := 0
var visual := false
func _initialize() -> void:
	visual = "--visual" in OS.get_cmdline_user_args()
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error("FAILED: " + label)
func settle() -> void:
	for i in 5: await process_frame
func capture(label: String) -> void:
	if not visual: return
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/t9_flow/" + label + ".png")
func dismiss(mode: String) -> void:
	if mode == "escape":
		var key := InputEventKey.new()
		key.keycode = KEY_ESCAPE
		key.pressed = true
		Input.parse_input_event(key)
	elif mode == "outside":
		screen._talent_overlay.get_child(0).pressed.emit()
	else:
		for button in screen._talent_overlay.find_children("*", "Button", true, false):
			if button.text == "Close": button.pressed.emit(); break
	await settle()
func make_screen() -> void:
	if is_instance_valid(screen):
		screen.queue_free()
		await settle()
	screen = load("res://scenes/combat/combat_screen.tscn").instantiate()
	root.add_child(screen)
	await settle()
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/t9_flow")
	state = root.get_node("BuildState")
	state.reset()
	var title = load("res://scenes/title/title.tscn").instantiate()
	root.add_child(title)
	await settle()
	for name in ["TestModeButton", "TestPointBudget", "TestMainTree", "TestSecondaryTree"]:
		check(not title.find_child(name, true, false).is_visible_in_tree(), name + " hidden")
	await capture("title")
	title.queue_free()
	var registry := BuildContentRegistry.adventure()
	state.set_class(registry.classes["class.rogue"])
	state.select_tree(registry.trees["tree.bladedancer"])
	state.add_talent_points(6)
	var talent: Talent = state.ranked_build.primary_tree().talents[0]
	check(state.select_talent(talent), "Tavern purchase")
	check(state.can_respec() and state.deselect_talent(talent), "Tavern single refund")
	check(state.select_talent(talent) and state.refund_tree_talents("tree.bladedancer"), "Tavern tree reset")
	check(state.select_talent(talent) and state.refund_all_talents(), "Tavern full reset")
	for phase in [state.RunPhase.FIGHTING, state.RunPhase.RESULT, state.RunPhase.RUN_ENDED]:
		state.run_phase = phase
		check(not state.can_respec() and not state.refund_all_talents(), "Blocked outside Tavern planning: " + str(phase))
	state.run_phase = state.RunPhase.PLANNING
	await make_screen()
	screen._story_overlay.hide()
	screen._show_talent_overlay()
	await settle()
	var view = screen._talent_overlay._talent_panel._ranked_view
	view.transact("buy", talent.id, "buy:" + talent.id)
	await settle()
	check(state.ranked_build.rank_of(talent.id) == 1, "Tavern tree widget purchase")
	view.transact("refund", talent.id, "buy:" + talent.id)
	await settle()
	check(state.ranked_build.rank_of(talent.id) == 0, "Tavern tree widget refund")
	view.transact("buy", talent.id, "buy:" + talent.id)
	await settle()
	check(not view.actions["reset:tree.bladedancer"].disabled, "Tavern reset widget enabled")
	view.actions["reset:tree.bladedancer"].pressed.emit()
	await settle()
	check(state.ranked_build.points_spent() == 0, "Tavern reset widget clears ranks")
	await capture("tavern_refunds")
	await dismiss("close")
	# Intermediate Tavern shop still advances directly to the next map.
	state.current_encounter_index = 1
	state.run_phase = state.RunPhase.RESULT
	state.last_fight_won = true
	state.shop_round_pending = true
	screen._shop_overlay.show()
	screen._on_shop_continue_pressed()
	await settle()
	check(state.current_encounter_index == 2 and screen._map_overlay.visible and not screen._talent_overlay.visible, "Intermediate shop keeps next Tavern map")
	check(not screen._map_overlay.find_child("ArchetypeGuideButton", true, false).visible, "Glossary hidden on Tavern map")
	# First contract uses the existing final-Tavern no-shop transition.
	screen._map_overlay.close()
	state.current_encounter_index = RunFlow.tavern_encounter_count() - 1
	state.run_phase = state.RunPhase.RESULT
	state.last_fight_won = true
	screen._advance_after_reward_or_shop()
	await settle()
	check(state.pending_contract_offer() and screen._talent_overlay.visible and not screen._contract_overlay.visible, "First offer waits for talents")
	check(state.can_respec(), "First auto-open tree permits refunds")
	await capture("first_talents")
	await dismiss("close")
	check(screen._contract_overlay.visible and not screen._talent_overlay.visible, "Close proceeds to first contract")
	await capture("first_contract")
	# Manual opens/dismissals must not re-trigger contract preparation.
	screen._contract_overlay.hide()
	screen._show_talent_overlay()
	await dismiss("outside")
	check(not screen._contract_overlay.visible, "Manual close has no pending continuation")
	# Use the real accepted contract and its terminal node, synthetic win only.
	check(state.accept_contract_offer(), "Accept generated route")
	var node: ContractRouteNode = state.current_route_node
	while not node.next_nodes.is_empty(): node = node.next_nodes[0]
	check(state._prepare_contract_route_node_for_combat(node), "Prepare actual terminal monster")
	state.current_route_node = node
	state.run_phase = state.RunPhase.PLANNING
	check(not state.can_respec() and not state.refund_all_talents(), "Active contract planning still blocks reset")
	state.run_phase = state.RunPhase.RESULT
	state.last_fight_won = true
	state.shop_round_pending = true
	screen._map_overlay.close()
	screen._shop_overlay.show()
	screen._on_shop_continue_pressed()
	await settle()
	check(state.completed_contract_count == 1 and screen._talent_overlay.visible, "Terminal Leave Shop opens talents")
	check(not screen._secondary_subclass_overlay.visible and not screen._contract_overlay.visible, "No stacked decision modals")
	await capture("between_talents")
	var shop_index: int = state.shop_round_index
	screen._on_shop_continue_pressed()
	check(state.shop_round_index == shop_index and screen._talent_overlay.visible, "Duplicate Leave Shop ignored")
	# Reload at auto-open checkpoint reconstructs the existing subclass/offer flow.
	check(SaveSystem.save_run(state), "Save preparation checkpoint")
	var snapshot := FileAccess.get_file_as_bytes(SaveSystem.save_path)
	var offered: Array[SubclassTree] = state.secondary_subclass_choices()
	view = screen._talent_overlay._talent_panel._ranked_view
	view.actions["secondary:" + offered[0].id].pressed.emit()
	await settle()
	check(state.ranked_build.secondary_tree().id == offered[0].id and screen._talent_overlay.visible, "Choose earned secondary inside auto-open tree")
	await capture("secondary_in_tree")
	await dismiss("close")
	check(screen._contract_overlay.visible and not screen._secondary_subclass_overlay.visible and not screen._talent_overlay.visible, "Tree secondary choice proceeds directly to offer")
	# Restore the isolated pre-choice checkpoint for the alternate resume path.
	var file := FileAccess.open(SaveSystem.save_path, FileAccess.WRITE)
	file.store_buffer(snapshot)
	file.close()
	state.reset()
	check(SaveSystem.load_run_result(state).status == "loaded", "Load preparation checkpoint")
	await make_screen()
	check(not screen._talent_overlay.visible and screen._secondary_subclass_overlay.visible, "Resume reconstructs one subclass decision")
	check(FileAccess.get_file_as_bytes(SaveSystem.save_path) == snapshot, "Resume does not rewrite save")
	# Recreate pending talent step to test Esc resumes required subclass choice.
	screen._secondary_subclass_overlay.hide()
	screen._contract_offer_after_talents = true
	screen._show_talent_overlay()
	await dismiss("escape")
	check(screen._secondary_subclass_overlay.visible and not screen._contract_overlay.visible and not screen._talent_overlay.visible, "Escape proceeds to required subclass choice")
	await capture("secondary_choice")
	var choices: Array[SubclassTree] = state.secondary_subclass_choices()
	screen._on_secondary_tree_pressed(choices[0])
	await settle()
	check(screen._contract_overlay.visible and not screen._talent_overlay.visible and not screen._secondary_subclass_overlay.visible, "Subclass choice proceeds once to offers")
	await capture("between_contract")
	# Without a required subclass decision, outside dismissal goes directly to offers.
	screen._contract_overlay.hide()
	screen._contract_offer_after_talents = true
	screen._show_talent_overlay()
	await dismiss("outside")
	check(screen._contract_overlay.visible and not screen._talent_overlay.visible, "Outside dismissal proceeds directly to offers")
	check(state.accept_contract_offer(), "Inspect next route")
	screen._contract_overlay.hide()
	screen._show_map_overlay(false)
	check(not screen._map_overlay.find_child("ArchetypeGuideButton", true, false).visible, "Glossary hidden on contract map")
	await capture("route")
	check(state.choose_contract_route_node(state.current_route_node.next_nodes[0]), "Commit real route node")
	state.run_phase = state.RunPhase.RESULT
	state.last_fight_won = true
	state.shop_round_pending = true
	screen._map_overlay.close()
	screen._shop_overlay.show()
	screen._on_shop_continue_pressed()
	await settle()
	check(state.run_phase == state.RunPhase.CONTRACT_ROUTE and screen._map_overlay.visible and not screen._talent_overlay.visible, "Midcontract shop keeps route map")
	# Hidden title entry retains the existing Test Mode continuation behavior.
	state.reset()
	state.is_test_mode = true
	SaveSystem.session_only = true
	state.set_class(registry.classes["class.rogue"])
	state.select_tree(registry.trees["tree.bladedancer"])
	state.current_encounter_index = RunFlow.tavern_encounter_count() - 1
	state.run_phase = state.RunPhase.RESULT
	state.last_fight_won = true
	screen._map_overlay.close()
	screen._advance_after_reward_or_shop()
	await settle()
	check(not screen._talent_overlay.visible and not screen._contract_offer_after_talents, "Test Mode continuation unchanged")
	SaveSystem.write_json("res://reports/t9_flow/result.json", {"pass":not failed,"checks":checks,"visual":visual,"synthetic_outcomes":true})
	screen.queue_free()
	await settle()
	if failed: quit(1); return
	print("T9 FLOW PASS ", checks)
	quit(0)
