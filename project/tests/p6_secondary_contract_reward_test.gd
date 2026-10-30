extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state = root.get_node("BuildState")
	var registry := BuildContentRegistry.adventure()
	for primary_id in ["tree.assassin", "tree.bladedancer", "tree.shadow", "tree.thief"]:
		state.reset()
		state.set_adventure_seed(41927)
		state.set_class(registry.classes["class.rogue"])
		state.add_talent_points(6)
		assert(state.configure_ranked_build(registry.trees[primary_id]))
		var primary: SubclassTree = state.selected_trees[0]
		assert(state.select_talent(primary.talents[0]))
		var ranks: Dictionary = state.ranked_build.rank_map().duplicate()
		assert(state.start_generated_contract_loop_offer())
		assert(state.accept_contract_offer())
		assert(not state.needs_secondary_subclass_choice())
		assert(state.secondary_subclass_choices().is_empty())
		assert(not state.choose_secondary_tree(registry.trees["tree.thief"] if primary_id != "tree.thief" else registry.trees["tree.shadow"]))
		# An ordinary fight win does not grant the contract-completion reward.
		assert(state.choose_contract_route_node(state.current_route_node.next_nodes[0]))
		state.run_phase = state.RunPhase.RESULT
		state.last_fight_won = true
		assert(state.claim_current_reward())
		if state.has_pending_reward_choice(): assert(state.skip_pending_reward_gear())
		assert(state.continue_after_win())
		assert(state.completed_contract_count == 0 and not state.needs_secondary_subclass_choice())
		# Walk the actual generated route to its terminal boss.
		while not state.current_route_node.next_nodes.is_empty():
			assert(state.choose_contract_route_node(state.current_route_node.next_nodes[0]))
			if state.current_route_node.next_nodes.is_empty(): break
			state.run_phase = state.RunPhase.CONTRACT_ROUTE
		assert(state.current_route_node.node_type == ContractRouteNode.NodeType.BOSS)
		state.run_phase = state.RunPhase.RESULT
		state.last_fight_won = true
		assert(state.claim_current_reward())
		if state.has_pending_reward_choice(): assert(state.skip_pending_reward_gear())
		assert(state.open_shop_round())
		assert(not state.needs_secondary_subclass_choice())
		assert(SaveSystem.save_run(state))
		state.reset()
		assert(SaveSystem.load_run(state))
		assert(state.shop_round_pending and not state.needs_secondary_subclass_choice())
		assert(state.close_shop_round())
		assert(state.continue_after_win())
		assert(state.completed_contract_count == 1 and state.needs_secondary_subclass_choice())
		var choices: Array[SubclassTree] = state.secondary_subclass_choices()
		var ids: Array[String] = state.secondary_subclass_offer_ids.duplicate()
		assert(choices.size() == 2 and choices[0] != choices[1] and not choices.has(primary))
		assert(not state.accept_contract_offer())
		for tree in registry.trees.values():
			if not choices.has(tree): assert(not state.choose_secondary_tree(tree))
		assert(SaveSystem.save_run(state))
		state.reset()
		assert(SaveSystem.load_run(state))
		assert(state.secondary_subclass_offer_ids == ids)
		assert(state.needs_secondary_subclass_choice())
		var screen = load("res://scenes/combat/combat_screen.tscn").instantiate()
		root.add_child(screen)
		await process_frame
		await process_frame
		assert(screen._secondary_subclass_overlay.visible and not screen._contract_overlay.visible)
		assert(screen._next_action_label.text == "Next: Choose your earned second subclass.")
		assert(screen._secondary_subclass_overlay._options.get_child_count() == 2)
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://reports/secondary_reward_%s.png" % primary_id.trim_prefix("tree."))
		screen._on_secondary_tree_pressed(state.secondary_subclass_choices()[0])
		assert(not screen._secondary_subclass_overlay.visible and screen._contract_overlay.visible)
		assert(state.selected_trees[0].id == primary_id and state.selected_trees[1].id == ids[0])
		assert(state.ranked_build.rank_map() == ranks)
		assert(not state.needs_secondary_subclass_choice())
		assert(SaveSystem.save_run(state))
		state.reset()
		assert(SaveSystem.load_run(state))
		assert(state.selected_trees.size() == 2 and not state.needs_secondary_subclass_choice())
		assert(state.accept_contract_offer())
		screen.queue_free()
		await process_frame
	# Older unselected saves derive the same deterministic offer; chosen early saves remain valid.
	state.reset()
	state.set_class(registry.classes["class.rogue"])
	assert(state.configure_ranked_build(registry.trees["tree.shadow"]))
	state.completed_contract_count = 1
	assert(state.start_generated_contract_loop_offer())
	assert(SaveSystem.save_run(state))
	var data: Dictionary = StrictSaveJson.read(FileAccess.get_file_as_string(SaveSystem.save_path)).data
	var expected: Array[String] = state.secondary_subclass_offer_ids.duplicate()
	data.erase("secondary_subclass_offer_ids")
	var file := FileAccess.open(SaveSystem.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	state.reset()
	assert(SaveSystem.load_run(state))
	state.secondary_subclass_choices()
	assert(state.secondary_subclass_offer_ids == expected)
	assert(state.start_generated_contract_loop_offer())
	assert(state.choose_secondary_tree(state.secondary_subclass_choices()[0]))
	state.completed_contract_count = 0
	assert(SaveSystem.save_run(state))
	state.reset()
	assert(SaveSystem.load_run(state))
	assert(state.selected_trees.size() == 2 and not state.needs_secondary_subclass_choice())
	state.reset()
	print("Secondary contract reward: PASS")
	quit()
