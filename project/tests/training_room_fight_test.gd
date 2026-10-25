extends SceneTree
## Headless P2:R10:T6 check: the Fight button actually runs a real
## CombatResolver fight against the current practice build/target/duration/
## seed, the result is deterministic per seed, target/duration/gold changes
## measurably change the outcome, CombatResultFormatter.format_practice()'s
## narrative renders into the result log, and none of it ever touches the
## real BuildState or advances any real Adventure encounter. Run with:
##   godot --headless -s res://tests/training_room_fight_test.gd


func _initialize() -> void:
	var build_state = root.get_node("BuildState")

	var game_root_scene: PackedScene = load("res://scenes/game_root.tscn")
	var game_root = game_root_scene.instantiate()
	root.add_child(game_root)
	await process_frame

	# Real Adventure state, set after game_root's own startup reset (see
	# training_room_entry_test.gd for why this must happen after, not
	# before).
	var rogue: ClassDef = load("res://data/classes/rogue.tres")
	build_state.set_class(rogue)
	build_state.select_tree(rogue.trees[0])
	build_state.gold = 42
	var real_encounter_index_before: int = build_state.current_encounter_index
	var real_run_phase_before: int = build_state.run_phase
	var real_gold_before: int = build_state.gold

	var title = game_root._current_screen
	title.training_room_pressed.emit()
	await process_frame
	var training_room = game_root._current_screen

	var fight_button: Button = training_room.find_child("FightButton", true, false)
	var result_log: RichTextLabel = training_room.find_child("ResultLog", true, false)
	var view_log_button: Button = training_room.find_child("ViewLogButton", true, false)
	var available_skills_panel = training_room.find_child("AvailableSkillsPanel", true, false)
	var skill_build_panel = training_room.find_child("SkillBuildPanel", true, false)
	var columns: HBoxContainer = training_room.find_child("Columns", true, false)
	var left_column: VBoxContainer = training_room.find_child("LeftColumn", true, false)
	var right_column_scroll: ScrollContainer = training_room.find_child("RightColumnScroll", true, false)
	var right_column: VBoxContainer = training_room.find_child("RightColumn", true, false)
	assert(fight_button != null)
	assert(result_log != null)
	assert(view_log_button != null)
	assert(available_skills_panel != null)
	assert(skill_build_panel != null)
	assert(columns != null)
	assert(left_column != null)
	assert(right_column_scroll != null)
	assert(right_column != null)

	# -- Layout regression check: Practice Room should keep Adventure-like
	# fixed side columns and modest centered action buttons, not oversized
	# ratio columns/buttons or a page-level scroll that crowd the combat view.
	assert(not (columns.get_parent() is ScrollContainer))
	assert(columns.size_flags_vertical == Control.SIZE_EXPAND_FILL)
	assert(left_column.custom_minimum_size == Vector2(training_room.SIDE_COLUMN_WIDTH, 0))
	assert(right_column_scroll.custom_minimum_size == Vector2(training_room.SIDE_COLUMN_WIDTH, 0))
	assert(right_column_scroll.size_flags_vertical == Control.SIZE_EXPAND_FILL)
	assert(right_column_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED)
	assert(right_column.custom_minimum_size == Vector2(training_room.SIDE_COLUMN_WIDTH, 0))
	assert(fight_button.custom_minimum_size == training_room.FIGHT_BUTTON_SIZE)
	assert(view_log_button.custom_minimum_size == training_room.LOG_BUTTON_SIZE)
	assert(fight_button.get_theme_font_size("font_size") == training_room.ACTION_BUTTON_FONT_SIZE)
	assert(view_log_button.get_theme_font_size("font_size") == training_room.ACTION_BUTTON_FONT_SIZE)

	# -- Empty rotation: Fight is disabled, same guard as skill_build_panel's
	# Lock button uses for the same reason (a guaranteed zero-damage loss) --
	print("fight button disabled with empty rotation (expect true): %s" % fight_button.disabled)
	assert(fight_button.disabled)
	training_room._state.set_locked(true)
	await process_frame
	assert(not training_room._state.build_locked)
	assert(fight_button.disabled)

	# Scoped Practice starts with Bladedancer. Use an explicit weapon so the
	# armor comparison is above the one-damage floor in both fixtures.
	var weapon: GearItem = load("res://data/gear/bandit_blade.tres").duplicate(true)
	training_room._state._equip_practice_item(weapon)
	training_room._state.notify_gear_edited()
	await process_frame

	var stab: Skill = null
	for skill in training_room._state.unlocked_skills():
		if skill.id == "skill.stab":
			stab = skill
	assert(stab != null)
	available_skills_panel._on_skill_pressed(stab)
	await process_frame
	print("fight button disabled with non-empty unlocked rotation (expect true): %s" % fight_button.disabled)
	assert(fight_button.disabled)
	assert(fight_button.tooltip_text.contains("Lock"))
	training_room._on_fight_button_pressed()
	await process_frame
	assert(training_room._state.last_result == null)
	assert(fight_button.get_meta("feedback_blocked_pulse") == true)

	training_room._state.set_locked(true)
	await process_frame
	print("fight button disabled with locked non-empty rotation (expect false): %s" % fight_button.disabled)
	assert(not fight_button.disabled)

	# -- Fixed setup: default 0-armor target, 10s, seed 1 --
	training_room._on_duration_changed(10.0)
	await process_frame

	# -- Run a fight, confirm it's real (matches a direct CombatResolver call
	# with the same inputs) and reproducible by seed --
	training_room._on_fight_button_pressed()
	await process_frame
	assert(training_room._state.last_result != null)
	var first_damage: float = training_room._state.last_result.total_damage

	var expected_stats: PlayerStats = training_room._state.current_player_stats()
	var expected_result := CombatResolver.resolve(
		training_room._state.rotation, expected_stats, training_room._state.selected_target, 10000, 1
	)
	print("Practice Room fight damage=%.2f, direct CombatResolver call=%.2f (expect equal)" % [
		first_damage, expected_result.total_damage
	])
	assert(is_equal_approx(first_damage, expected_result.total_damage))
	assert(training_room._log_inspector.visible)
	assert(training_room._log_inspector._timeline_chart._rows.size() > 0)
	assert(training_room._log_inspector._damage_chart._rows.size() > 0)
	assert(not view_log_button.disabled)
	assert(result_log.text.contains("Practice Target:"))
	assert(result_log.text.contains("Summary:"))
	var result_chip_text := ""
	for node in training_room._log_inspector.find_children("*", "Label", true, false):
		result_chip_text += node.text + "\n"
	assert(result_chip_text.contains("Practice"))
	assert(not result_chip_text.contains("Victory"))
	assert(not result_chip_text.contains("Defeat"))

	# -- Build edits through the shared SkillBuildPanel invalidate completed
	# practice review, so stale result logs cannot survive a rotation change.
	training_room._state.set_locked(false)
	await process_frame
	skill_build_panel._on_slot_pressed(0)
	skill_build_panel._remove_selected()
	await process_frame
	_assert_result_review_invalidated(training_room, result_log, view_log_button)
	assert(training_room._state.rotation.is_empty())
	available_skills_panel._on_skill_pressed(stab)
	training_room._state.set_locked(true)
	await process_frame
	assert(not fight_button.disabled)
	training_room._on_fight_button_pressed()
	await process_frame
	assert(training_room._state.last_result != null)
	assert(not view_log_button.disabled)

	training_room._on_fight_button_pressed()
	await process_frame
	print("same-seed rerun damage=%.2f (expect equal to %.2f)" % [
		training_room._state.last_result.total_damage, first_damage
	])
	assert(is_equal_approx(training_room._state.last_result.total_damage, first_damage))

	# -- Different seed changes the result (assuming any RNG-dependent
	# element -- crit chance is nonzero for Rogue, so this should differ at
	# least in whether crits land, even if not guaranteed to differ in every
	# possible universe; assert on the result log text changing instead,
	# which reflects the full timeline, not just total damage) --
	var log_before_seed_change: String = result_log.text
	training_room._log_overlay.visible = true
	training_room._on_fight_seed_changed(2.0)
	await process_frame
	_assert_result_review_invalidated(training_room, result_log, view_log_button)
	training_room._on_fight_button_pressed()
	await process_frame
	print("result log changed after seed change (expect true): %s" % (result_log.text != log_before_seed_change))
	assert(result_log.text != log_before_seed_change)
	assert(result_log.text.contains(training_room._state.selected_target.display_name))
	assert(result_log.text.contains("DPS"))

	# -- Raising target armor changes the outcome (mitigation alone should
	# reduce total damage for an identical build/seed/duration) --
	training_room._on_fight_seed_changed(1.0)
	training_room._on_target_armor_changed(160)
	await process_frame
	assert(training_room._state.selected_target.armor == 160)
	_assert_result_review_invalidated(training_room, result_log, view_log_button)
	training_room._on_fight_button_pressed()
	await process_frame
	print("damage vs 160 armor=%.2f (expect less than vs 0 armor %.2f)" % [
		training_room._state.last_result.total_damage, first_damage
	])
	assert(training_room._state.last_result.total_damage < first_damage)

	training_room._on_practice_gold_changed(200.0)
	await process_frame
	_assert_result_review_invalidated(training_room, result_log, view_log_button)

	# -- Isolation: none of the above ever touched the real BuildState's
	# encounter/run-phase/gold, or called finish_fight() --
	print("real encounter_index=%d (expect %d), run_phase=%d (expect %d), gold=%d (expect %d)" % [
		build_state.current_encounter_index, real_encounter_index_before,
		build_state.run_phase, real_run_phase_before,
		build_state.gold, real_gold_before,
	])
	assert(build_state.current_encounter_index == real_encounter_index_before)
	assert(build_state.run_phase == real_run_phase_before)
	assert(build_state.gold == real_gold_before)

	print("")
	print("Practice Room fight check: OK")
	quit()


func _find_talent(tree: SubclassTree, talent_id: String) -> Talent:
	for talent in tree.talents:
		if talent.id == talent_id:
			return talent
	return null


func _assert_result_review_invalidated(training_room, result_log: RichTextLabel, view_log_button: Button) -> void:
	assert(view_log_button.disabled)
	assert(not training_room._log_overlay.visible)
	assert(not training_room._log_inspector.visible)
	assert(result_log.text == "")
