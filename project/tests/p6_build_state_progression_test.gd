extends SceneTree

func _initialize() -> void:
	SaveSystem.save_path = "res://reports/three_point_progression_isolated.json"
	call_deferred("_run")

func _run() -> void:
	var state = root.get_node("BuildState")
	var rogue: ClassDef = load("res://data/classes/rogue.tres")
	_check_state(state, rogue)
	_check_rewards(state, rogue)
	state.reset()
	print("P6 state/progression: PASS (Adventure, Practice, rewards, single claims)")
	quit()

func _ready_tree(id: String) -> SubclassTree:
	var tree := SubclassTree.new()
	tree.id = id
	tree.ranked_content_ready = true
	var talent := Talent.new()
	talent.id = id + ".talent"
	talent.max_ranks = 5
	for i in 5:
		var rank := TalentRank.new()
		var modifier := StatModifier.new()
		modifier.stat_id = StatCatalog.CRIT_CHANCE
		modifier.value = (i + 1) * 0.01
		rank.stat_modifiers.append(modifier)
		talent.ranks.append(rank)
	var skill := Skill.new()
	skill.id = id + ".skill"
	talent.unlocked_skills = [skill]
	tree.talents = [talent]
	return tree

func _check_state(state, rogue: ClassDef) -> void:
	state.reset()
	state.set_class(rogue)
	state.add_talent_points(10)
	assert(not state.configure_ranked_build(rogue.trees[0])) # No silent draft activation.
	var a := _ready_tree("test.a")
	var b := _ready_tree("test.b")
	# Declare the synthetic content on an isolated class, just as playable registries do.
	state.selected_class = rogue.duplicate(true)
	var fixture_trees: Array[SubclassTree] = [a, b]
	state.selected_class.trees = fixture_trees
	assert(state.configure_ranked_build(a))
	assert(state.select_talent(a.talents[0]))
	assert(state.select_talent(a.talents[0]))
	assert(state.ranked_build.rank_of(a.talents[0].id) == 2)
	assert(is_equal_approx(state.current_player_stats().crit_chance, rogue.base_stats.crit_chance + 0.02))
	var macro: Array[Skill] = [a.talents[0].unlocked_skills[0], a.talents[0].unlocked_skills[0]]
	state.set_rotation(macro)
	state.set_locked(true)
	state.run_phase = state.RunPhase.FIGHTING
	assert(not state.deselect_talent(a.talents[0])) # Combat still blocks refunds.
	assert(state.build_locked)
	state.run_phase = state.RunPhase.CONTRACT_OFFER
	assert(state.deselect_talent(a.talents[0]))
	assert(not state.build_locked)
	assert(state.rotation.size() == 2)
	assert(state.deselect_talent(a.talents[0]))
	assert(state.rotation.is_empty())
	assert(state.rotation_changes["removed"].size() == 2)
	assert(state.select_talent(a.talents[0]))
	assert(state.rotation.is_empty()) # Re-unlock never restores a removed macro.
	state.completed_contract_count = 1
	state.active_contract = ContractDef.new()
	state.run_phase = state.RunPhase.PLANNING
	var broken := _ready_tree("test.broken")
	broken.talents[0].ranks.clear()
	assert(not state.choose_secondary_tree(broken))
	assert(state.ranked_build.secondary_tree() == null)
	assert(state.choose_secondary_tree(b))
	assert(not state.choose_secondary_tree(a))
	assert(not state.refund_all_talents())
	state.run_phase = state.RunPhase.FIGHTING
	assert(not state.select_talent(a.talents[0]))
	state.run_phase = state.RunPhase.PLANNING
	assert(not state.toggle_tree(b))
	state.select_tree(b)
	assert(state.ranked_build.primary_tree() == a)
	assert(state.start_contract_offer())
	assert(state.active_contract != null) # Preview assigned during the respec window.
	assert(state.can_respec())
	assert(state.refund_all_talents())
	assert(state.ranked_build.primary_tree() == a and state.ranked_build.secondary_tree() == b)
	assert(state.earned_talent_points == 10)
	# Until T7 supplies v2, ranked state cannot be silently written in binary v1.
	var original_save_path := SaveSystem.save_path
	SaveSystem.save_path = "res://reports/p6_should_not_write.json"
	assert(not SaveSystem.save_run(state))
	assert(not FileAccess.file_exists(SaveSystem.save_path))
	SaveSystem.save_path = original_save_path
	var practice := TrainingRoomState.new()
	practice.set_class(rogue)
	assert(practice.set_talent_budget(10))
	assert(practice.configure_ranked_build(a, b))
	assert(not practice.set_secondary_tree(broken))
	assert(practice.ranked_build.secondary_tree() == b)
	assert(practice.select_talent(a.talents[0]))
	assert(practice.select_talent(a.talents[0]))
	assert(not practice.set_talent_budget(1))
	assert(not practice.set_talent_budget(3.5))
	assert(practice.set_talent_budget(2))
	assert(practice.deselect_talent(a.talents[0]))
	assert(practice.set_primary_tree(null))
	assert(practice.ranked_build.primary_tree() == null)
	assert(practice.ranked_build.secondary_tree() == null)
	assert(state.ranked_build.primary_tree() == a) # Practice did not alter Adventure.
	assert(state.earned_talent_points == 10)
	assert(practice.refund_all_talents())

func _check_rewards(state, rogue: ClassDef) -> void:
	state.reset()
	state.set_class(rogue)
	for index in 4:
		state.current_encounter_index = index
		state.run_phase = state.RunPhase.RESULT
		state.last_fight_won = true
		var points_before: int = state.earned_talent_points
		assert(state.claim_current_reward(true)) # Animation cannot defer the points.
		assert(state.earned_talent_points == points_before + BuildProgression.TAVERN_POINTS[index])
		assert(not state.claim_current_reward(true))
	assert(state.earned_talent_points == 6)
	state.pending_reward_choices.clear()
	state.inventory.clear()
	# The existing boss node is the one completion-payout container, not a second award.
	for contract_index in 14:
		state.active_contract = ContractDef.new()
		var boss := ContractRouteNode.new()
		boss.id = "test.boss%d" % contract_index
		boss.node_type = ContractRouteNode.NodeType.BOSS
		boss.monster = Monster.new()
		boss.reward = EncounterReward.new()
		boss.reward.gold_amount = 1
		boss.reward.talent_points = 999 # Current policy ignores obsolete embedded point amounts.
		state.current_route_node = boss
		state.run_phase = state.RunPhase.RESULT
		state.last_fight_won = true
		assert(state.claim_current_reward())
		assert(state.earned_talent_points == mini(45, 9 + contract_index * 3))
		assert(not state.claim_current_reward())
		assert(state.gold == contract_index + 1)
	state.earned_talent_points = 43
	state.current_route_node.id = "test.partial"
	assert(state.current_reward().talent_points == 2)
	assert(state.claim_current_reward())
	assert(state.earned_talent_points == 45)
	state.add_talent_points(-100)
	assert(state.earned_talent_points == 45)
	state.earned_talent_points = 10
	state.current_route_node.id = "test.elite"
	state.current_route_node.node_type = ContractRouteNode.NodeType.ELITE
	assert(state.current_reward().talent_points == 0)
	assert(state.claim_current_reward())
	assert(state.earned_talent_points == 10)
