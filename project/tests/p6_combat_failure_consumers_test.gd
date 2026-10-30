extends SceneTree
const Lab = preload("res://scripts/tools/balance_lab.gd")

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state = root.get_node("BuildState")
	state.reset()
	var rogue: ClassDef = load("res://data/classes/rogue.tres")
	var stab: Skill = load("res://data/skills/stab.tres")
	var rotation: Array[Skill] = [stab]
	var weapon: GearItem = load("res://data/gear/crude_dagger.tres").duplicate(true)
	var trigger := TriggeredSkillEffect.new()
	trigger.skill = stab
	trigger.source_skill_ids = PackedStringArray(["test.never_matches"])
	trigger.chance = 1.0
	for i in 1025:
		weapon.triggered_skill_effects.append(trigger)
	state.set_class(rogue)
	state.select_tree(rogue.trees[0])
	state.equipped_weapon = weapon
	state.set_rotation(rotation)
	state.set_locked(true)
	state.choose_current_tavern_encounter()
	state.gold = 71
	var failures: Dictionary = state.encounter_failure_counts.duplicate(true)
	var retries: Dictionary = state.encounter_retry_counts.duplicate(true)
	var screen = load("res://scenes/combat/combat_screen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	# Exercise both instant and animated callers; neither may commit or play failure.
	for instant in [true, false]:
		screen.instant_playback = instant
		assert(state.can_start_current_fight())
		screen._on_fight_pressed()
		assert(state.run_phase == state.RunPhase.PLANNING and state.can_start_current_fight())
		assert(state.gold == 71 and state.combat_stolen_gold == 0)
		assert(state.encounter_failure_counts == failures and state.encounter_retry_counts == retries)
		assert(state.run_encounter_history.is_empty() and state.last_combat_result == null)
		assert(not screen._playback_active and not screen._view_log_button.disabled)
		assert(screen._status_label.text.contains("Simulation stopped"))
	screen.queue_free()
	await process_frame
	var room = load("res://scenes/training_room/training_room.tscn").instantiate()
	root.add_child(room)
	await process_frame
	room._state.set_class(rogue)
	room._state.equipped_weapon = weapon
	room._state.set_rotation(rotation)
	room._state.set_locked(true)
	room._state.run_fight()
	assert(room._state.last_result != null and not room._state.last_result.is_valid)
	assert(room._result_log.text.contains("Simulation stopped") and not room._view_log_button.disabled)
	var labels: Array[String] = []
	# The shared log summary is reparented into the overlay above the tabs.
	for label in room._log_overlay.find_children("*", "Label", true, false):
		labels.append(label.text)
	assert(labels.has("Invalid simulation") and not labels.has("Practice") and not labels.has("Defeat"))
	assert(state.gold == 71 and state.encounter_failure_counts == failures)
	room.queue_free()
	await process_frame
	var weapon_path := "res://reports/p6_m3_t2/branching_test_weapon.tres"
	assert(ResourceSaver.save(weapon, weapon_path) == OK)
	var spec := {"id": "t2_invalid_chain", "label": "T2 invalid chain",
		"class": "res://data/classes/rogue.tres", "monster": "res://data/monsters/mouthy_drunk.tres",
		"skills": ["res://data/skills/stab.tres"], "gear": [weapon_path],
		"duration_ms": 3000, "seed_start": 1, "seed_count": 3}
	var report := Lab.run_scenario_spec(spec)
	assert(report.status == "fail" and report.seed_count == 0 and report.samples.is_empty())
	assert(str(report.notes).contains("trigger_candidate_limit"))
	state.reset()
	print("P6 T2 invalid-result consumers: PASS (Adventure instant/animated, Practice, Balance Lab)")
	quit()
