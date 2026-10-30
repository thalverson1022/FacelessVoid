extends SceneTree
## D024: cross the actual Adventure menu/save/Fight boundary before checking
## controlled positive ranks and both roles. Never run against player saves.

var failed := false
var checks := 0
var evidence: Array[Dictionary] = []
var isolated_paths: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed = true
		printerr("FAILED: " + label)

func find_skill(skills: Array[Skill], id: String) -> Skill:
	for skill in skills:
		if skill.id == id:
			return skill
	return null

func skill_ids(skills: Array[Skill]) -> Array[String]:
	var result: Array[String] = []
	for skill in skills:
		result.append(skill.id)
	return result

func assert_isolation() -> void:
	var current: Array[String] = [SaveSystem.save_path, PracticeSaveSystem.save_path, PracticeSaveSystem.core_save_path, SevenSlotSaveBoundary.legacy_path, SevenSlotSaveBoundary.marker_path]
	assert(current == isolated_paths, "All five isolated persistence paths must remain unchanged")
	for path in current:
		assert(path.begins_with("res://reports/"), "Run through isolated validation wrapper")

func _run() -> void:
	isolated_paths.assign([SaveSystem.save_path, PracticeSaveSystem.save_path, PracticeSaveSystem.core_save_path, SevenSlotSaveBoundary.legacy_path, SevenSlotSaveBoundary.marker_path])
	assert_isolation()
	print("D024 isolated persistence paths: " + str(isolated_paths))
	for id in ["tree.assassin", "tree.bladedancer", "tree.thief"]:
		await _live_adventure(id)
	_check_roles_and_first_points()
	assert_isolation()
	var report := FileAccess.open("res://reports/p6_other_subclass_intrinsic_audit.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"pass": not failed, "checks": checks, "isolated_paths": isolated_paths, "cases": evidence}, "\t"))
	report.close()
	print("P6 other subclass intrinsic audit: %s (%d checks)" % ["FAIL" if failed else "PASS", checks])
	quit(1 if failed else 0)

func _live_adventure(id: String) -> void:
	var state = root.get_node("BuildState")
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._current_screen.adventure_pressed.emit()
	await process_frame
	game._current_screen._card_box.get_child(0).find_children("*", "Button", true, false)[0].pressed.emit()
	await process_frame
	var index := -1
	for i in state.selected_class.trees.size():
		if state.selected_class.trees[i].id == id:
			index = i
	check(index >= 0, id + " available in normal Adventure menu")
	game._current_screen._card_box.get_child(index).find_children("*", "Button", true, false)[0].pressed.emit()
	await process_frame
	var screen = game._current_screen
	screen.instant_playback = true
	check(not state.is_test_mode and state.ranked_build != null and state.selected_trees[0].ranked_content_ready, id + " menu selects ranked Adventure")
	check(state.ranked_build.points_spent() == 0 and state.earned_talent_points == 0, id + " fresh zero-point build")
	check(state.equipped_gear().size() == 1 and state.equipped_weapon.id == "gear.crude_dagger", id + " only Crude Dagger")
	_check_zero_stats(state, id)
	screen._story_overlay.find_child("StoryProceedButton", true, false).pressed.emit()
	await process_frame
	screen._map_overlay._map_node_buttons[0].pressed.emit()
	screen._map_overlay._map_proceed_button.pressed.emit()
	await process_frame
	state.set_adventure_seed(1)
	var rotation: Array[Skill] = [find_skill(state.unlocked_skills(), "skill.stab")]
	state.set_rotation(rotation)
	assert_isolation()
	check(SaveSystem.save_run(state), id + " saves isolated zero-point run")
	check(SaveSystem.load_run_result(state).status == "loaded", id + " resumes isolated run")
	assert_isolation()
	check(state.ranked_build != null and state.ranked_build.points_spent() == 0 and state.selected_trees[0].id == id, id + " resumes current ranked tree")
	_check_zero_stats(state, id)
	var before: PlayerStats = state.current_player_stats()
	state.set_locked(true)
	check(not screen._enemy_panel.fight_button().disabled, id + " actual Fight enabled")
	screen._enemy_panel.fight_button().pressed.emit()
	assert_isolation()
	var result: CombatResolver.CombatResult = state.last_combat_result
	check(result != null and result.is_valid and result.cast_events.size() >= 2, id + " actual Fight valid with multiple casts")
	var repeats := 0
	for event in result.cast_events:
		check(event.skill.id == "skill.stab", id + " actual Fight has no obsolete free skill")
		check(event.poison_stacks_applied == 0 and event.poison_applications.is_empty(), id + " zero-point Stab has no Poison source")
		check(event.gold_stolen == 0, id + " zero-point Stab steals no gold")
		if event.origin_kind == "random_repeat":
			repeats += 1
	check(result.gold_stolen == 0, id + " fight has no free Steal effect")
	var row := {"case": "live_menu_resume_fight", "tree": id, "skills": skill_ids(state.unlocked_skills()), "poison_damage_per_tick": before.poison_damage_per_tick, "elemental_multiplier": before.elemental_damage_multiplier, "retrigger_chance": before.retrigger_chance, "gold_multiplier": before.gold_reward_multiplier, "sources": before.stat_sources, "cast_count": result.cast_events.size(), "random_repeats": repeats, "gold_stolen": result.gold_stolen}
	evidence.append(row)
	print("Live Adventure: " + JSON.stringify(row))
	state.reset()
	game.queue_free()
	await process_frame

func _check_zero_stats(state, id: String) -> void:
	var stats: PlayerStats = state.current_player_stats()
	check(stats.derivation_error == "", id + " stats valid")
	var expected_poison := 13.0 if id == "tree.assassin" else 8.0
	check(is_equal_approx(stats.poison_damage_per_tick, expected_poison), id + " approved elemental base")
	check(is_equal_approx(stats.elemental_damage_multiplier, 1.0) and is_equal_approx(stats.talent_elemental_damage_multiplier, 1.0), id + " no old Assassin x1.2 multiplier")
	check(is_equal_approx(stats.retrigger_chance, 0.05 if id == "tree.bladedancer" else 0.0), id + " approved retrigger intrinsic")
	check(is_equal_approx(stats.gold_reward_multiplier, 1.1 if id == "tree.thief" else 1.0), id + " approved gold intrinsic")
	check(state.modified_gold_reward(100) == (110 if id == "tree.thief" else 100), id + " current intrinsic reaches reward calculation")
	var ids := skill_ids(state.unlocked_skills())
	check(ids.size() == 3 and ids.has("skill.hold") and ids.has("skill.stab") and ids.has("skill.heavy_slash"), id + " only three class skills at zero points")
	check(not ids.has("skill.quick_cut") and not ids.has("skill.steal") and not ids.has("skill.venom_jab"), id + " no legacy free skill unlocks")
	for source in stats.stat_sources:
		check(source.get("source_kind") != "talent", id + " zero-point sources contain no talents")
		if source.get("source_kind") == "intrinsic":
			check(source.source_id == id and source.operation == StatModifier.OperationType.ADD, id + " intrinsic source is current additive selected tree")

func _check_roles_and_first_points() -> void:
	var registry := BuildContentRegistry.adventure()
	var state = root.get_node("BuildState")
	var enemy := Monster.new()
	enemy.hp = 1000000
	for id in ["tree.assassin", "tree.bladedancer", "tree.thief"]:
		for secondary in [false, true]:
			state.reset()
			state.set_class(registry.classes["class.rogue"])
			check(state.configure_ranked_build(registry.trees["tree.shadow"] if secondary else registry.trees[id]), "Configure " + id)
			if secondary:
				state.completed_contract_count = 1
				state.run_phase = state.RunPhase.CONTRACT_OFFER
				var offers: Array[String] = [id, "tree.thief" if id != "tree.thief" else "tree.assassin"]
				state.secondary_subclass_offer_ids = offers
				check(state.choose_secondary_tree(registry.trees[id]), "Earn secondary " + id)
			var before: PlayerStats = state.current_player_stats()
			check(is_equal_approx(before.poison_damage_per_tick, 13.0 if id == "tree.assassin" else 8.0), id + " zero role elemental intrinsic")
			check(is_equal_approx(before.retrigger_chance, 0.05 if id == "tree.bladedancer" else 0.0), id + " zero role retrigger intrinsic")
			check(is_equal_approx(before.gold_reward_multiplier, 1.1 if id == "tree.thief" else 1.0), id + " zero role gold intrinsic")
			check(find_skill(state.unlocked_skills(), "skill.quick_cut") == null and find_skill(state.unlocked_skills(), "skill.steal") == null, id + " role has no free legacy skill")
			if id == "tree.bladedancer":
				before.crit_chance = 0
				_check_retriggers(before, find_skill(state.unlocked_skills(), "skill.stab"), enemy, "zero_point secondary=%s" % secondary)
			state.add_talent_points(1)
			var talent_id: String = {"tree.assassin": "talent.assassin.quick_hands", "tree.bladedancer": "talent.bladedancer.wet_stone", "tree.thief": "talent.keen_eye"}[id]
			check(state.select_talent(registry.talents[talent_id]), id + " buys first rank")
			var stats: PlayerStats = state.current_player_stats()
			var unlock_id: String = {"tree.assassin": "skill.venom_jab", "tree.bladedancer": "skill.quick_cut", "tree.thief": "skill.steal"}[id]
			var unlocked: Skill = find_skill(state.unlocked_skills(), unlock_id)
			check(unlocked != null, id + " first point unlocks " + unlock_id)
			if id == "tree.assassin":
				check(is_equal_approx(stats.poison_damage_per_tick, 13.0 if secondary else 13.5) and is_equal_approx(stats.elemental_damage_multiplier, 1.0), "Assassin primary-only +0.5 elemental per point")
			elif id == "tree.bladedancer":
				check(is_equal_approx(stats.retrigger_chance, 0.05 if secondary else 0.052), "Bladedancer primary-only +0.2 percent per point")
			else:
				check(is_equal_approx(stats.gold_reward_multiplier, 1.1 if secondary else 1.12), "Thief primary-only +2 percent gold per point")
			# Steal explicitly steals on critical hits. Other controlled casts
			# disable criticals to isolate their audited source from Shadow.
			stats.crit_chance = 1.0 if id == "tree.thief" else 0.0
			var rotation: Array[Skill] = [unlocked]
			var result := CombatResolver.resolve(rotation, stats, enemy, 3000, 7)
			check(result.is_valid and not result.cast_events.is_empty(), id + " unlocked skill resolves")
			if id == "tree.assassin":
				check(result.cast_events[0].poison_stacks_applied == 5 and result.cast_events[0].poison_applications[0].source == "skill", "Current Venom Jab applies five stacks from skill")
				var live_ticks := 0
				for tick in result.tick_events:
					if tick.had_active_stack:
						live_ticks += 1
						check(is_equal_approx(tick.raw_damage, 13.0 if secondary else 13.5), "Current Assassin Poison tick excludes legacy multiplier")
				check(live_ticks > 0, "Current Assassin tick observed")
			elif id == "tree.thief":
				check(result.gold_stolen > 0, "Current one-point Steal produces gold")
			else:
				_check_retriggers(stats, unlocked, enemy, "first_point secondary=%s" % secondary)
			var row := {"case": "first_point_role", "tree": id, "secondary": secondary, "skills": skill_ids(state.unlocked_skills()), "poison_damage_per_tick": stats.poison_damage_per_tick, "elemental_multiplier": stats.elemental_damage_multiplier, "retrigger_chance": stats.retrigger_chance, "gold_multiplier": stats.gold_reward_multiplier, "sources": stats.stat_sources}
			evidence.append(row)
			print("Controlled role: " + JSON.stringify(row))
	state.reset()

func _check_retriggers(stats: PlayerStats, skill: Skill, enemy: Monster, label: String) -> void:
	var repeats := 0
	var nonrepeat_runs := 0
	var rotation: Array[Skill] = [skill]
	for seed_value in range(1, 129):
		var sample := CombatResolver.resolve(rotation, stats, enemy, skill.base_execution_ms, seed_value)
		var found := false
		for event in sample.cast_events:
			if event.origin_kind == "random_repeat":
				repeats += 1
				found = true
				check(event.skill.id == skill.id and event.poison_applications.is_empty(), "Bladedancer repeat retains current skill without legacy Poison")
		if not found:
			nonrepeat_runs += 1
	check(repeats > 0 and nonrepeat_runs > 0, "Real Bladedancer retrigger chance has successes and failures: " + label)
	var row := {"case": "controlled_retrigger", "label": label, "skill": skill.id, "chance": stats.retrigger_chance, "seeds": 128, "repeats": repeats, "nonrepeat_runs": nonrepeat_runs}
	evidence.append(row)
	print("Bladedancer controlled: " + JSON.stringify(row))
