extends SceneTree
## Headless P2:R10:T3 check: Practice Room's freeform tree/talent/rotation/
## Legendary controls actually work through the real parameterized panels,
## and none of it ever touches the real BuildState singleton. Run with:
##   godot --headless -s res://tests/training_room_build_test.gd


func _initialize() -> void:
	var build_state = root.get_node("BuildState")

	var game_root_scene: PackedScene = load("res://scenes/game_root.tscn")
	var game_root = game_root_scene.instantiate()
	root.add_child(game_root)
	await process_frame

	# Give the real Adventure state some real values *after* game_root's own
	# startup reset, so we can prove Practice Room never disturbs them (see
	# P2:R10:T1/T2's test for why this must happen after, not before).
	var rogue: ClassDef = load("res://data/classes/rogue.tres")
	build_state.set_class(rogue)
	build_state.select_tree(rogue.trees[0])
	build_state.gold = 555
	build_state.set_adventure_seed(4242)
	var real_trees_before: Array[SubclassTree] = build_state.selected_trees.duplicate()
	var real_talents_before: Array[Talent] = build_state.selected_talents.duplicate()
	var real_rotation_before: Array[Skill] = build_state.rotation.duplicate()
	var real_weapon_before: GearItem = build_state.equipped_weapon
	var real_gold_before: int = build_state.gold
	var real_seed_before: int = build_state.adventure_seed

	var title = game_root._current_screen
	title.training_room_pressed.emit()
	await process_frame
	var training_room = game_root._current_screen
	assert(training_room != null)

	var talent_panel = training_room.find_child("TalentPanel", true, false)
	var available_skills_panel = training_room.find_child("AvailableSkillsPanel", true, false)
	var skill_build_panel = training_room.find_child("SkillBuildPanel", true, false)
	var character_stats_panel = training_room.find_child("CharacterStatsPanel", true, false)
	var active_talents_panel = training_room.find_child("ActiveTalentsPanel", true, false)
	assert(talent_panel != null)
	assert(available_skills_panel != null)
	assert(skill_build_panel != null)
	assert(character_stats_panel != null)
	assert(active_talents_panel != null)
	# The parameterized panels must be pointed at Practice Room's own state,
	# never the real BuildState singleton.
	assert(talent_panel.state != build_state)
	assert(available_skills_panel.state != build_state)
	assert(skill_build_panel.state != build_state)
	assert(character_stats_panel.state != build_state)
	assert(active_talents_panel.state != build_state)
	assert(not active_talents_panel.enable_open_button_attention)
	assert(active_talents_panel._button_blink_tween == null)
	assert(training_room._state.earned_talent_points == BuildProgression.POINT_CAP)
	assert(active_talents_panel._points_label.text == ": 0/45")
	assert(skill_build_panel._slot_count_label.text == "Slots: 0/10")
	assert(skill_build_panel._lock_button.disabled)
	assert(skill_build_panel._lock_button.tooltip_text.contains("Slot at least one skill"))
	assert(not skill_build_panel._lock_button.tooltip_text.contains("Adventure"))
	assert(not skill_build_panel._lock_button.tooltip_text.contains("reward"))
	training_room._state.set_locked(true)
	await process_frame
	assert(not training_room._state.build_locked)
	assert(skill_build_panel._lock_button.disabled)
	training_room._talent_overlay.visible = true
	await process_frame
	var talent_scroll: ScrollContainer = training_room._talent_overlay.find_child("TalentTreeScroll", true, false)
	assert(talent_scroll != null)
	assert(talent_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED)
	assert(training_room._talent_overlay.find_child("TreeDropdowns", true, false) == null)
	assert(talent_panel._ranked_view != null)
	assert(talent_panel.find_child("PrimaryTreeOption", true, false) is OptionButton)
	assert(talent_panel.find_child("SecondaryTreeOption", true, false) is OptionButton)
	assert(not _talent_panel_text(talent_panel).contains("No subclass selected."))
	assert(not _talent_panel_text(talent_panel).contains("Unlocks later in the Adventure."))
	training_room._talent_overlay.visible = false
	assert(training_room._state.equipped_weapon == null)
	assert(training_room._state.equipped_trinket == null)
	assert(training_room._state.equipped_charm == null)
	assert(training_room._state.equipped_gear().is_empty())

	# -- The shipped Practice UI uses the scoped ranked core, not legacy trees. --
	var core_tree: SubclassTree = training_room._state.selected_class.trees[0]
	assert(core_tree.id == "tree.bladedancer")
	assert(training_room._state.selected_class.trees.size() == 4)
	assert(not training_room._state.set_secondary_tree(core_tree))
	talent_panel._ranked_view.transact("buy", "talent.bladedancer.wet_stone", "buy:talent.bladedancer.wet_stone")
	await process_frame
	await process_frame
	assert(training_room._state.ranked_build.rank_of("talent.bladedancer.wet_stone") == 1)

	# -- Rotation: add a skill via available_skills_panel, confirm
	# skill_build_panel (a different panel instance) sees the same state --
	var unlocked: Array[Skill] = training_room._state.unlocked_skills()
	assert(not unlocked.is_empty())
	available_skills_panel._on_skill_pressed(unlocked[0])
	await process_frame
	print("practice rotation size=%d (expect 1)" % training_room._state.rotation.size())
	assert(training_room._state.rotation.size() == 1)
	assert(skill_build_panel._slots_box.get_child_count() == 1)
	assert(skill_build_panel._slot_count_label.text == "Slots: 1/10")
	assert(not skill_build_panel._lock_button.disabled)
	assert(skill_build_panel._lock_button.tooltip_text == "Lock this skill macro so you can start the fight")
	training_room._state.set_locked(true)
	await process_frame
	assert(training_room._state.build_locked)
	assert(skill_build_panel._lock_button.tooltip_text == "Unlock your skill macro so you can edit it")

	# -- Direct Legendary equip --
	var wyvern: GearItem = load("res://data/gear/wyvern_kriss.tres")
	var stats_text_before_equip: String = character_stats_panel._stats_label.text
	training_room._state.equip_legendary(wyvern)
	await process_frame
	print("practice equipped weapon (expect Wyvern Kriss): %s" % [
		training_room._state.equipped_weapon.display_name if training_room._state.equipped_weapon != null else "null"
	])
	assert(training_room._state.equipped_weapon == wyvern)
	# character_stats_panel (parameterized to the same state) should reflect
	# the equip immediately -- a before/after diff rather than an exact
	# expected number, since the resolved poison-stack value here also
	# depends on whichever trees/talents are active from the steps above.
	assert(character_stats_panel._stats_label.text != stats_text_before_equip)
	assert(character_stats_panel._stats_label.text.contains("Bonus Stacks"))

	# -- Isolation: the real BuildState must be completely untouched by any
	# of the above -- same class/trees/talents/rotation/weapon/gold/seed as
	# right before Practice Room was entered. --
	print("real gold after Practice Room use=%d (expect %d), seed=%d (expect %d)" % [
		build_state.gold, real_gold_before, build_state.adventure_seed, real_seed_before
	])
	assert(build_state.gold == real_gold_before)
	assert(build_state.adventure_seed == real_seed_before)
	assert(build_state.selected_trees == real_trees_before)
	assert(build_state.selected_talents == real_talents_before)
	assert(build_state.rotation == real_rotation_before)
	assert(build_state.equipped_weapon == real_weapon_before)

	# -- Back to Title must not touch real state either --
	var back_button: Button = training_room.find_child("BackButton", true, false)
	back_button.pressed.emit()
	await process_frame
	assert(game_root._current_screen != training_room)
	assert(build_state.gold == real_gold_before)
	assert(build_state.selected_trees == real_trees_before)

	print("")
	print("Practice Room build controls check: OK")
	quit()


func _find_talent(tree: SubclassTree, talent_id: String) -> Talent:
	for talent in tree.talents:
		if talent.id == talent_id:
			return talent
	return null


func _talent_panel_text(talent_panel) -> String:
	var parts: PackedStringArray = []
	for label in talent_panel.find_children("*", "Label", true, false):
		parts.append(label.text)
	return "\n".join(parts)
