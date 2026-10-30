extends "res://tests/p6_core_journey_test.gd"
## T9 production registry + actual UI controllers, isolated from user saves.
const Mixed = preload("res://tests/fixtures/p6/mixed_build.gd")

func _initialize() -> void:
	super._initialize()

func select_secondary(view) -> void:
	view.actions["SecondaryTreeOption"].select(2)
	view.actions["SecondaryTreeOption"].item_selected.emit(2)
	await settle()

func verify_stats(state, reversed_roles: bool) -> void:
	var stats: PlayerStats = state.current_player_stats()
	check(is_equal_approx(stats.retrigger_chance, 0.05 if reversed_roles else 0.08), "Primary-only retrigger scaling")
	check(is_equal_approx(stats.gold_reward_multiplier, 1.2 if reversed_roles else 1.1), "Primary-only additive gold scaling")
	check(stats.footwork_rank == 5 and stats.readiness_enabled and stats.dance_duration_ms == 5000, "All three lifecycles bind from production unlocks")
	check(state.unlocked_skills().size() == 10 and state.ranked_build.rank_map() == Mixed.RANKS, "Exact mixed ranks and ten skills")

func production_parity() -> void:
	var registry := BuildContentRegistry.test_mode()
	check(registry.error == "" and registry.trees.size() == 4 and registry.talents.size() == 44, "Complete four-tree registry validates")
	var fixture := Mixed.registry()
	for reverse in [false, true]:
		var live := Mixed.build(registry, reverse)
		var expected := Mixed.build(fixture, reverse)
		var actual := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"], live)
		var baseline := BuildResolver.resolve_ranked_build(fixture.classes["class.rogue"], expected)
		check(actual.error == "" and baseline.error == "", "Production and reviewed fixture resolve")
		var live_rotation: Array[Skill] = []
		var expected_rotation: Array[Skill] = []
		for id in Mixed.ROTATION:
			for skill in actual.skills:
				if skill.id == id: live_rotation.append(skill)
			for skill in baseline.skills:
				if skill.id == id: expected_rotation.append(skill)
		var monster := Monster.new()
		monster.hp = 1000000
		for gold in [0, 100, 499, 500, 501, 10000]:
			actual.stats.current_gold = gold
			baseline.stats.current_gold = gold
			for seed in [7, 19, 42]:
				var a := CombatResolver.resolve(live_rotation, actual.stats, monster, 30000, seed, true)
				var b := CombatResolver.resolve(expected_rotation, baseline.stats, monster, 30000, seed, true)
				check(a.is_valid and a.trace.records == b.trace.records and a.rng_final_state == b.rng_final_state, "Production/fixture trace parity roles=%s gold=%d seed=%d" % [reverse, gold, seed])
	# Old core payloads stay compatible; unreleased fixtures remain rejected.
	var payload := Mixed.payload()
	check(BuildSaveCodec.decode(payload, registry).error != "", "Test-only revision cannot enter production saves")
	payload.content_revision = "p6.playable.bladedancer_core.1"
	payload.secondary_tree_id = null
	payload.earned_talent_points = 10
	payload.talent_ranks = Core.RANKS.duplicate()
	payload.rotation_skill_ids = Core.ROTATION.duplicate()
	check(BuildSaveCodec.decode(payload, registry).error == "", "Existing core setup remains readable")
	# Production skill descriptors at gold/cooldown boundaries; stress stats are test-only.
	var built := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"], Mixed.build(registry))
	var skills := {}
	for skill in built.skills: skills[skill.id] = skill
	var stress: PlayerStats = built.stats.duplicate(true)
	stress.crit_chance = 1.0
	stress.retrigger_chance = 0.0
	stress.current_gold = 10000
	var target := Monster.new()
	target.hp = 1000000
	var capped_rotation: Array[Skill] = [skills["skill.steal"], skills["skill.mug"]]
	for credited in [1, 2, 3, 49, 50, 51, 99, 100, 101, 199, 200, 201]:
		stress.gold_reward_multiplier = (credited + 0.1) / 3.0
		var result := CombatResolver.resolve(capped_rotation, stress, target, 2800, 7, true)
		check(result.gold_stolen == credited and result.cast_events[1].stat_snapshot.stolen_gold_base_damage == mini(credited, 50), "Production Mug boundary credited=%d" % credited)
	var mug_only: Array[Skill] = [skills["skill.mug"]]
	var empty := CombatResolver.resolve(mug_only, stress, target, 1500, 7, true)
	check(empty.cast_events[0].stat_snapshot.stolen_gold_base_damage == 0, "Production Mug ignores large starting stash")
	var duplicate: Array[Skill] = [skills["skill.dance_of_death"], skills["skill.dance_of_death"]]
	var cooldown := CombatResolver.resolve(duplicate, stress, target, 21000, 7, true)
	var activations := 0
	var skips := 0
	var skip_durations_valid := true
	for event in cooldown.cast_events:
		if event.cooldown_blocked:
			skips += 1
			skip_durations_valid = skip_durations_valid and event.time_ms - event.cast_start_ms == 100
		else: activations += 1
	check(activations == 2 and skips > 0, "Production Dance copies share twenty-second cooldown")
	check(skip_durations_valid, "Every duplicate Dance cooldown skip spends 100ms")

func capture_tooltip(button, label: String) -> void:
	if not visual: return
	var tooltip: Control = button._make_custom_tooltip(button._get_tooltip(Vector2.ZERO))
	var layer := CanvasLayer.new()
	layer.layer = 100
	root.add_child(layer)
	layer.add_child(tooltip)
	tooltip.position = Vector2(380, 340)
	await capture(label)
	layer.queue_free()
	await settle()

func _run() -> void:
	report = "res://reports/p6_m4_t9_journey"
	visual = "--visual" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(report)
	SaveSystem.save_path = report + "/adventure.json"
	PracticeSaveSystem.save_path = report + "/legacy-practice.json"
	PracticeSaveSystem.core_save_path = report + "/mixed-practice.json"
	if FileAccess.file_exists(PracticeSaveSystem.core_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PracticeSaveSystem.core_save_path))
	SaveSystem.write_json(SaveSystem.save_path, {"sentinel": "Adventure"})
	SaveSystem.write_json(PracticeSaveSystem.save_path, {"sentinel": "Legacy Practice"})
	var adventure := FileAccess.get_file_as_bytes(SaveSystem.save_path)
	var legacy := FileAccess.get_file_as_bytes(PracticeSaveSystem.save_path)
	production_parity()
	CombatEffectIcons.reduced_motion = true
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._show_training_room()
	await settle()
	var practice = game._current_screen
	var p = practice._state
	var view = practice._talent_panel._ranked_view
	check(p.set_talent_budget(20), "Set isolated mixed-budget model fixture")
	await settle()
	await select_secondary(view)
	check(p.selected_trees.size() == 2 and is_equal_approx(p.current_player_stats().gold_reward_multiplier, 1.1), "Zero-point Thief grants base intrinsic")
	check(not ids(p.unlocked_skills()).has("skill.steal") and not ids(p.unlocked_skills()).has("skill.mug"), "Zero-point Thief grants no skills")
	for id in Mixed.RANKS:
		for rank in Mixed.RANKS[id]: await press_rank(view, "buy:" + id)
	verify_stats(p, false)
	for skill in p.unlocked_skills():
		check(skill.icon != null, "Assigned playable skill icon " + skill.id)
	for id in Mixed.RANKS:
		var talent: Talent = p.content_registry.talents[id]
		check(talent.icon != null and not talent.display_name.is_empty(), "Named talent icon " + id)
	check("30%" in view.talent_tooltip(p.content_registry.talents["talent.bladedancer.opportunity"]), "Opportunity tooltip explains current chance")
	for id in Mixed.ROTATION: await add_skill(available_panel(practice), id)
	check(ids(p.rotation) == Mixed.ROTATION, "Exact eight-slot rotation built through icon controls")
	var dance: Skill = p.rotation[0]
	var mug: Skill = p.rotation[7]
	check("5.0s" in SkillTooltipFormatter.compact_tooltip(dance, p) and "20.0s" in SkillTooltipFormatter.compact_tooltip(dance, p), "Dance hover explains effect and shared cooldown")
	check("max +50" in SkillTooltipFormatter.compact_tooltip(mug, p) and "Starting stash" in SkillTooltipFormatter.conditions_for(mug, p), "Mug hover explains cap and eligible gold")
	practice._talent_overlay.show()
	await capture("mixed-talents")
	practice._talent_overlay_scroll.scroll_vertical = 10000
	await capture("mixed-thief-talents")
	practice._talent_overlay.hide()
	practice._on_fight_seed_changed(8)
	practice._on_random_fight_seed_toggled(false)
	practice._on_practice_gold_changed(499)
	p.set_duration_ms(30000)
	await settle()
	for reverse in [false, true]:
		if reverse:
			check(p.swap_tree_roles(), "Swap isolated model roles for reverse-build coverage")
			await settle()
		verify_stats(p, reverse)
		check(ids(p.rotation) == Mixed.ROTATION, "Role swap preserves ordered duplicate rotation")
		await capture("mixed-reversed-ready" if reverse else "mixed-ready")
		var combat = practice._combat_view
		combat._instant_playback = false
		combat._skip_playback_on_fight = false
		practice._skill_build_panel._lock_button.pressed.emit()
		practice._fight_button.pressed.emit()
		combat.set_process(false)
		check(p.last_result != null and p.last_result.is_valid and p.allocation_locked, "Actual mixed Practice fight resolves and locks edits")
		check(not p.swap_tree_roles(), "Role swap rejected during playback")
		var result = p.last_result
		evidence.append({"practice_role_reversed": reverse, "seed": p.fight_seed, "damage": result.total_damage, "gold_stolen": result.gold_stolen})
		check(result.gold_stolen > 0, "Actual mixed Practice fight includes credited theft")
		var has_repeat := false
		var has_mug := false
		for event in result.cast_events:
			if event.origin_kind == "guaranteed_repeat": has_repeat = true
			if event.skill.id == mug.id: has_mug = true
		check(has_repeat and has_mug, "Actual rotation includes repeats and Mug")
		combat._process(0.8)
		check(combat._effect_icons.model.display_effects().any(func(item): return item.id == "buff.dance"), "Dance is visible during live playback")
		await capture("mixed-reversed-playing" if reverse else "mixed-playing")
		combat._process(24.0)
		check("Live stash:" in SkillTooltipFormatter.compact_tooltip(mug, p), "Mug hover shows live counted benefit")
		await capture_tooltip(practice._skill_build_panel._slot_buttons[7], "mixed-reversed-mug" if reverse else "mixed-mug")
		combat._skip()
		check(not p.allocation_locked and p.gold == 499 + result.gold_stolen and p.combat_stolen_gold == result.gold_stolen, "Playback credits theft exactly once")
		check(combat._effect_icons.active.is_empty(), "Completion clears mixed effects")
		practice._fight_button.pressed.emit()
		combat.set_process(false)
		check(p.gold == 499 and p.combat_stolen_gold == 0 and p.last_result.total_damage == result.total_damage and p.last_result.gold_stolen == result.gold_stolen, "Retry restores configured stash and deterministic outcome")
		combat._skip()
		# Unlock macro editing before the next role transaction.
		p.set_locked(false)
		await settle()
	check(PracticeSaveSystem.save_setup(p), "Mixed setup saves")
	var saved := FileAccess.get_file_as_bytes(p.practice_save_path)
	game._on_main_menu_pressed()
	await settle()
	game._show_training_room()
	await settle()
	practice = game._current_screen
	p = practice._state
	verify_stats(p, true)
	check(ids(p.rotation) == Mixed.ROTATION and p.configured_gold == 499 and p.gold == 499 and p.combat_stolen_gold == 0 and p.last_result == null, "Reopen restores reversed setup without fight residue")
	await capture("mixed-restored")
	# Refund a Thief unlock boundary, then reallocate without restoring pruned slots.
	view = practice._talent_panel._ranked_view
	for i in 3: view.transact("refund", "talent.keen_eye", "buy:talent.keen_eye")
	await settle()
	check(not ids(p.rotation).has("skill.mug") and ids(p.rotation).has("skill.steal") and "Mug" in view.feedback, "Refund below three Thief points removes and names Mug")
	for i in 3: await press_rank(view, "buy:talent.keen_eye")
	check(not ids(p.rotation).has("skill.mug"), "Reunlocking does not restore removed rotation slots")
	# Restore saved bytes for the Test Mode isolation comparison.
	var file := FileAccess.open(p.practice_save_path, FileAccess.WRITE)
	file.store_buffer(saved)
	file.close()
	game._on_main_menu_pressed()
	await settle()
	game._on_contract_test_pressed(7, 10)
	await settle()
	var state = root.get_node("BuildState")
	fresh(state)
	var screen = game._current_screen
	view = screen._talent_overlay._talent_panel._ranked_view
	check(not view.actions.has("secondary:tree.thief"), "Secondary unavailable before contract acceptance")
	screen._contract_overlay.accept_requested.emit("")
	await settle()
	check(view.actions.has("secondary:tree.thief"), "Contract acceptance exposes supported secondary control")
	view.actions["secondary:tree.thief"].pressed.emit()
	await settle()
	check(state.selected_trees.size() == 2 and state.selected_trees[1].id == "tree.thief", "Test Mode selects Thief through ranked UI")
	check(not state.choose_secondary_tree(BuildContentRegistry.test_mode().trees["tree.thief"]), "Foreign tree resource rejected")
	# Progress four contracts from the explicit ten-point preset; Practice above uses real combat.
	var steps := 0
	while state.completed_contract_count < 4 and steps < 140:
		if state.run_phase == state.RunPhase.CONTRACT_OFFER: state.accept_contract_offer()
		check(state.choose_contract_route_node(state.current_route_node.next_nodes[0]), "Progression route accepts node")
		state.finish_fight(true)
		check(state.claim_current_reward(), "Progression grants reward")
		state.continue_after_win()
		steps += 1
	check(state.earned_talent_points == 22, "Four three-point contract rewards take the ten-point preset to twenty-two points")
	await settle()
	for id in Mixed.RANKS:
		for rank in Mixed.RANKS[id]: await press_rank(view, "buy:" + id)
	check(state.ranked_build.rank_map() == Mixed.RANKS, "Test Mode progression supports exact mixed allocation")
	for id in Mixed.ROTATION: await add_skill(available_panel(screen), id)
	state.accept_contract_offer()
	state.choose_contract_route_node(state.current_route_node.next_nodes[0])
	state.set_locked(true)
	screen._on_fight_pressed()
	check(state.last_combat_result != null and state.last_combat_result.is_valid, "Actual Test Mode mixed fight resolves")
	screen._on_playback_skip_pressed()
	screen._autosave()
	game._on_main_menu_pressed()
	await settle()
	check(FileAccess.get_file_as_bytes(PracticeSaveSystem.core_save_path) == saved, "Test Mode preserves mixed Practice bytes")
	check(FileAccess.get_file_as_bytes(SaveSystem.save_path) == adventure and FileAccess.get_file_as_bytes(PracticeSaveSystem.save_path) == legacy, "Journeys preserve Adventure and legacy Practice")
	game.queue_free()
	await settle()
	state.reset()
	CombatEffectIcons.reduced_motion = false
	SaveSystem.write_json(report + ("/visual-checks.json" if visual else "/checks.json"), {"passed": not failed, "count": checks, "evidence": evidence})
	print("T9 mixed journeys: %d checks %s" % [checks, "FAIL" if failed else "PASS"])
	quit(1 if failed else 0)

