extends SceneTree
## Exercises the Adventure screen boundary, where the legacy export fallback
## used to add unconditional Poison after the ranked resolver had finished.

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if not ok:
		failed = true
		printerr("FAILED: " + label)

func find_skill(skills: Array[Skill], id: String) -> Skill:
	for skill in skills:
		if skill.id == id:
			return skill
	return null

func _run() -> void:
	assert(SaveSystem.save_path.begins_with("res://reports/"), "Run through isolated validation wrapper")
	var isolated_path := SaveSystem.save_path
	print("Isolated Adventure save: " + isolated_path)
	var state = root.get_node("BuildState")
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._current_screen.adventure_pressed.emit()
	await process_frame
	# Press the actual menu buttons so the selected class/trees come from the
	# live Adventure registry, rather than injecting a registry into the state.
	game._current_screen._card_box.get_child(0).find_children("*", "Button", true, false)[0].pressed.emit()
	await process_frame
	var selection = game._current_screen
	var index := -1
	for i in state.selected_class.trees.size():
		if state.selected_class.trees[i].id == "tree.shadow":
			index = i
	check(index >= 0, "Shadow appears in the normal subclass menu")
	selection._card_box.get_child(index).find_children("*", "Button", true, false)[0].pressed.emit()
	await process_frame
	var screen = game._current_screen
	screen.instant_playback = true
	check(state.ranked_build != null and state.selected_trees[0].ranked_content_ready, "Normal menus select ranked Shadow")
	check(state.ranked_build.points_spent() == 0 and state.earned_talent_points == 0, "Fresh Shadow has zero talent points")
	check(state.equipped_gear().size() == 1 and state.equipped_weapon.id == "gear.crude_dagger", "Fresh Adventure has only Crude Dagger")
	check(is_equal_approx(state.current_player_stats().elemental_proc_chance, 0.2), "Zero-point Shadow retains approved 20 percent crit proc")
	screen._story_overlay.find_child("StoryProceedButton", true, false).pressed.emit()
	await process_frame
	screen._map_overlay._map_node_buttons[0].pressed.emit()
	screen._map_overlay._map_proceed_button.pressed.emit()
	await process_frame
	state.set_adventure_seed(1)
	var rotation: Array[Skill] = [find_skill(state.unlocked_skills(), "skill.stab")]
	state.set_rotation(rotation)
	# Resume the exact fresh build before exercising the actual Fight handler.
	assert(SaveSystem.save_path == isolated_path)
	check(SaveSystem.save_run(state), "Fresh ranked Shadow saves to isolated path")
	check(SaveSystem.load_run_result(state).status == "loaded", "Fresh ranked Shadow resumes")
	assert(SaveSystem.save_path == isolated_path)
	check(state.ranked_build != null and state.ranked_build.points_spent() == 0, "Resume retains zero-point ranked Shadow")
	state.set_locked(true)
	check(not screen._enemy_panel.fight_button().disabled, "Fresh Shadow can press Fight")
	screen._enemy_panel.fight_button().pressed.emit()
	assert(SaveSystem.save_path == isolated_path)
	print("Fight autosave retained isolated path: " + SaveSystem.save_path)
	var result: CombatResolver.CombatResult = state.last_combat_result
	check(result != null and result.is_valid, "Actual Adventure Fight returns a valid result")
	var noncrits := 0
	var invalid_poison := 0
	for event in result.cast_events:
		if not event.is_crit and not event.was_dodged and not event.was_interrupted:
			noncrits += 1
			if event.poison_stacks_applied != 0:
				invalid_poison += 1
		print("Fresh live cast: time=%d crit=%s damage=%.1f poison=%d sources=%s" % [event.time_ms, event.is_crit, event.physical_damage, event.poison_stacks_applied, event.poison_applications])
	check(noncrits >= 2, "Fresh live fight includes multiple noncritical Stabs")
	check(invalid_poison == 0, "Fresh live noncritical Stabs apply no Poison")
	print("Fresh live result: noncrits=%d noncrits_with_poison=%d" % [noncrits, invalid_poison])
	_check_roles_and_augments(state, screen)
	state.reset()
	game.queue_free()
	await process_frame
	print("P6 Shadow combat intrinsic: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)

func _check_roles_and_augments(state, screen) -> void:
	var registry := BuildContentRegistry.adventure()
	var enemy := Monster.new()
	enemy.hp = 1000000
	for secondary in [false, true]:
		state.reset()
		state.set_class(registry.classes["class.rogue"])
		check(state.configure_ranked_build(registry.trees["tree.assassin"] if secondary else registry.trees["tree.shadow"]), "Configure primary role")
		if secondary:
			state.completed_contract_count = 1
			state.run_phase = state.RunPhase.CONTRACT_OFFER
			var offers: Array[String] = ["tree.shadow", "tree.thief"]
			state.secondary_subclass_offer_ids = offers
			check(state.choose_secondary_tree(registry.trees["tree.shadow"]), "Earn and choose secondary Shadow")
		for id in ["skill.stab", "skill.heavy_slash"]:
			var skills: Array[Skill] = [find_skill(state.unlocked_skills(), id)]
			screen._apply_shadow_export_fallback(skills)
			var stats: PlayerStats = state.current_player_stats()
			stats.crit_chance = 0
			var noncrit := CombatResolver.resolve(skills, stats, enemy, skills[0].base_execution_ms, 7)
			check(noncrit.is_valid and noncrit.cast_events[0].poison_stacks_applied == 0, "Zero-point %s secondary=%s has no noncrit Poison" % [id, secondary])
			# Keep the intrinsic at its real 20% and force only critical hits.
			stats.crit_chance = 1
			var procs := 0
			var misses := 0
			for seed_value in range(1, 65):
				var crit := CombatResolver.resolve(skills, stats, enemy, skills[0].base_execution_ms, seed_value)
				var event = crit.cast_events[0]
				check(event.is_crit, "Controlled critical attack")
				for application in event.poison_applications:
					check(application.source == "critical_proc", "Zero-point crit Poison comes only from approved intrinsic")
				if event.poison_stacks_applied > 0:
					procs += 1
				else:
					misses += 1
			check(procs > 0 and misses > 0, "20 percent crit proc has successes and failures")
			print("Controlled role secondary=%s %s crit-procs=%d misses=%d" % [secondary, id, procs, misses])
	# Coated Weapons remains the intentional noncritical Poison source.
	state.reset()
	state.set_class(registry.classes["class.rogue"])
	state.add_talent_points(1)
	check(state.configure_ranked_build(registry.trees["tree.shadow"]), "Configure Coated build")
	check(state.select_talent(registry.talents["talent.shadow.coated_weapons"]), "Buy Coated Weapons")
	check(is_equal_approx(state.current_player_stats().elemental_proc_chance, 0.22), "Primary point retains two percent crit proc scaling")
	for id in ["skill.stab", "skill.heavy_slash"]:
		var skills: Array[Skill] = [find_skill(state.unlocked_skills(), id)]
		screen._apply_shadow_export_fallback(skills)
		var stats: PlayerStats = state.current_player_stats()
		stats.crit_chance = 0
		var result := CombatResolver.resolve(skills, stats, enemy, skills[0].base_execution_ms, 7)
		check(result.cast_events[0].poison_stacks_applied == 2, "Coated Weapons retains two Poison on noncritical " + id)
	# Legacy fixtures still use their old fallback when nested export arrays
	# fail to materialize. They do not supply the current ranked intrinsic.
	state.reset()
	state.set_class(load("res://data/classes/rogue.tres"))
	state.select_tree(load("res://data/subclass_trees/shadow.tres"))
	var legacy: Array[Skill] = [load("res://data/skills/stab.tres").duplicate(true)]
	screen._apply_shadow_export_fallback(legacy)
	check(state.ranked_build == null and legacy[0].poison_stacks_applied == 1, "Legacy Shadow export fallback remains compatible")
