extends SceneTree
const BUDGETS := [0, 1, 5, 10, 15, 20, 25, 30, 35, 40, 45]
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	SaveSystem.save_path = "res://reports/three_point_adoption/foundation_adventure.json"
	PracticeSaveSystem.save_path = "res://reports/three_point_adoption/foundation_practice.json"
	PracticeSaveSystem.core_save_path = "res://reports/three_point_adoption/foundation_core.json"
	assert(ProjectSettings.get_setting("application/config/name") == "FacelessVoid")
	assert(OS.get_user_data_dir().replace("\\", "/").ends_with("/FacelessVoid"))
	var registry := _registry()
	SaveSystem.registry_override = registry
	var state = root.get_node("BuildState")
	var rogue: ClassDef = registry.classes.values()[0]
	for primary in rogue.trees:
		for secondary in [null] + rogue.trees:
			if secondary == primary:
				continue
			for budget in BUDGETS:
				state.reset()
				state.set_class(rogue)
				state.add_talent_points(budget)
				state.active_contract = load("res://data/contracts/the_gilded_serpent.tres")
				state.completed_contract_count = 1
				assert(state.configure_ranked_build(primary, secondary))
				for tree in state.selected_trees:
					for talent in tree.talents:
						while state.ranked_build.unspent_points() > 0 and state.ranked_build.rank_of(talent.id) < talent.max_ranks:
							assert(state.select_talent(talent), state.last_build_error)
				var skills: Array[Skill] = state.unlocked_skills()
				var rotation: Array[Skill] = [skills[-1], skills[-1]]
				state.set_rotation(rotation)
				var ranks: Dictionary = state.ranked_build.rank_map()
				var damage: float = state.current_player_stats().bonus_physical_damage
				assert(SaveSystem.save_run(state), SaveSystem.last_error)
				state.reset()
				assert(SaveSystem.load_run_result(state).status == "loaded", str(SaveSystem.last_load_result))
				assert(state.ranked_build.primary_tree() == primary and state.ranked_build.secondary_tree() == secondary)
				assert(state.ranked_build.rank_map() == ranks and state.earned_talent_points == budget)
				assert(is_equal_approx(state.current_player_stats().bonus_physical_damage, damage))
				assert(state.rotation.size() == 2 and state.rotation[0].id == state.rotation[1].id)
				if state.ranked_build.points_spent() > 0:
					assert(not state.refund_all_talents())
				state.active_contract = null
				state.run_phase = state.RunPhase.CONTRACT_OFFER
				assert(state.refund_all_talents())
				assert(state.earned_talent_points == budget and state.ranked_build.points_spent() == 0)
				assert(SaveSystem.save_run(state))
				assert(SaveSystem.load_run_result(state).status == "loaded")
				if budget > 0:
					assert(state.select_talent(primary.talents[0]))
				checks += 1
	_check_retained_gate(state, rogue)
	_check_unlock_refund(rogue)
	SaveSystem.registry_override = null
	_check_reward_resume(state)
	state.reset()
	print("P6 integrated lifecycle: PASS (%d single/mixed progression checkpoints, retained gate, unlock refunds, isolated saves)" % checks)
	quit()

func _registry() -> BuildContentRegistry:
	var registry := BuildContentRegistry.new()
	registry.mode = "ranked"
	registry.revision = "test.integration.1"
	registry.compatible = [registry.revision]
	var rogue := load("res://data/classes/rogue.tres").duplicate(false) as ClassDef
	rogue.trees = []
	for index in 4:
		var tree := SubclassTree.new()
		tree.id = "tree.integration%d" % index
		tree.display_name = "Synthetic integration tree %d" % index
		tree.ranked_content_ready = true
		tree.innate_modifiers = [_modifier(float(index + 1))]
		tree.primary_point_modifiers = [_modifier(0.1 * (index + 1))]
		for slot in 2:
			var talent := Talent.new()
			talent.id = tree.id + ".talent%d" % slot
			talent.max_ranks = 20 if slot == 0 else 5
			talent.required_tree_points = 0 if slot == 0 else 5
			if slot == 1:
				talent.prerequisite_ids = [tree.talents[0].id]
			for rank in talent.max_ranks:
				var effects := TalentRank.new()
				effects.stat_modifiers = [_modifier(float(rank + 1))]
				talent.ranks.append(effects)
			tree.talents.append(talent)
			registry.talents[talent.id] = talent
		for threshold in [1, 3, 6, 9, 12]:
			var unlock := TreeSkillUnlock.new()
			unlock.required_points = threshold
			if threshold != 9:
				unlock.skill = rogue.base_skills[0].duplicate(true)
				unlock.skill.id = tree.id + ".skill%d" % threshold
			tree.automatic_unlocks.append(unlock)
		registry.trees[tree.id] = tree
		rogue.trees.append(tree)
	registry.classes[rogue.id] = rogue
	assert(registry.validate_ranked() == "")
	return registry

func _modifier(amount: float) -> StatModifier:
	var modifier := StatModifier.new()
	modifier.stat_id = StatCatalog.BASE_DAMAGE
	modifier.value = amount
	return modifier

func _check_retained_gate(state, rogue: ClassDef) -> void:
	state.reset()
	state.set_class(rogue)
	state.add_talent_points(6)
	var tree := rogue.trees[0]
	assert(state.configure_ranked_build(tree))
	assert(not state.ranked_build.configure(tree, null, 5, {tree.talents[0].id: 4, tree.talents[1].id: 1}))
	assert(state.ranked_build.configure(tree, null, 6, {tree.talents[0].id: 5, tree.talents[1].id: 1}))
	assert(SaveSystem.save_run(state))
	assert(SaveSystem.load_run_result(state).status == "loaded")
	assert(state.ranked_build.rank_of(tree.talents[0].id) == 5)
	state.run_phase = state.RunPhase.CONTRACT_OFFER
	assert(not state.deselect_talent(tree.talents[0]))
	assert(state.ranked_build.points_spent() == 6)
	assert(state.deselect_talent(tree.talents[1]))
	assert(SaveSystem.save_run(state))
	assert(SaveSystem.load_run_result(state).status == "loaded")
	assert(state.ranked_build.points_spent() == 5)

func _check_unlock_refund(rogue: ClassDef) -> void:
	var sandbox := TrainingRoomState.new()
	sandbox.set_class(rogue)
	var tree := rogue.trees[0]
	assert(sandbox.configure_ranked_build(tree, rogue.trees[1]))
	for threshold in [1, 3, 6, 12]:
		assert(sandbox.refund_all_talents())
		for i in threshold:
			assert(sandbox.select_talent(tree.talents[0]))
		var id := tree.id + ".skill%d" % threshold
		var skill: Skill
		for available in sandbox.unlocked_skills():
			if available.id == id:
				skill = available
		assert(skill != null)
		var rotation: Array[Skill] = [skill, skill]
		sandbox.set_rotation(rotation)
		assert(PracticeSaveSystem.save_setup(sandbox))
		assert(PracticeSaveSystem.load_setup(sandbox).status == "loaded")
		assert(sandbox.deselect_talent(tree.talents[0]))
		assert(sandbox.rotation.is_empty() and sandbox.rotation_changes.removed.size() == 2)
		sandbox.set_locked(true)
		assert(not sandbox.build_locked and not sandbox.can_run_fight())
		assert(sandbox.select_talent(tree.talents[0]))
		assert(sandbox.rotation.is_empty())
		assert(PracticeSaveSystem.save_setup(sandbox))
		assert(PracticeSaveSystem.load_setup(sandbox).status == "loaded")
		assert(sandbox.rotation.is_empty())
	assert(sandbox.set_primary_tree(null))
	assert(sandbox.ranked_build.secondary_tree() == null)
	assert(PracticeSaveSystem.save_setup(sandbox))
	assert(PracticeSaveSystem.load_setup(sandbox).status == "loaded")
	assert(sandbox.selected_trees.is_empty())

func _check_reward_resume(state) -> void:
	state.reset()
	for index in 4:
		state.current_encounter_index = index
		state.run_phase = state.RunPhase.RESULT
		state.last_fight_won = true
		assert(state.claim_current_reward(true))
		assert(state.earned_talent_points == [1, 1, 3, 6][index])
		assert(SaveSystem.save_run(state))
		assert(SaveSystem.load_run_result(state).status == "loaded")
		assert(not state.claim_current_reward())
	state.pending_reward_choices.clear()
	for completed in 14:
		state.inventory.clear()
		state.pending_reward_choices.clear()
		state.claimed_route_reward_ids.clear()
		state.active_contract = load("res://data/contracts/the_gilded_serpent.tres")
		state.current_route_node = load("res://data/contract_routes/gilded_serpent/vyra.tres")
		state.completed_contract_count = completed
		state.run_phase = state.RunPhase.RESULT
		state.last_fight_won = true
		assert(state.claim_current_reward(true))
		assert(state.earned_talent_points == mini(45, 9 + completed * 3))
		assert(SaveSystem.save_run(state))
		assert(SaveSystem.load_run_result(state).status == "loaded")
		assert(not state.claim_current_reward())
