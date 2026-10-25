extends SceneTree
var failed := false
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error("FAILED: " + label)
func run() -> void:
	var state = root.get_node("BuildState")
	state.reset()
	var registry := BuildContentRegistry.adventure()
	state.set_class(registry.classes["class.rogue"])
	state.select_tree(registry.trees["tree.bladedancer"])
	state.choose_current_tavern_encounter()
	var rotation: Array[Skill] = [load("res://data/skills/stab.tres")]
	state.rotation = rotation
	var screen = load("res://scenes/combat/combat_screen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	screen.instant_playback = false
	state.set_locked(true)
	screen._enemy_panel.monster().hp = 1
	SaveSystem.delete_save()
	check(not SaveSystem.has_save(), "isolated save cleared before fight")
	screen._enemy_panel.fight_pressed.emit()
	check(screen._playback_active, "presentation active immediately after real Fight")
	check(not screen._victory_overlay.visible, "victory presentation deferred")
	check(state.last_fight_won and state.run_phase != state.RunPhase.FIGHTING, "authoritative winning result already applied")
	check(SaveSystem.has_save(), "real Fight autosaved before playback advances")
	check(SaveSystem.last_error.is_empty(), "current Adventure autosave accepted")
	var data: Dictionary = StrictSaveJson.read(FileAccess.get_file_as_string(SaveSystem.save_path)).data
	check(data.build.allocation_mode == "ranked" and data.build.content_revision == "p6.adventure.1", "current ranked Adventure envelope")
	check(data.last_fight_won == state.last_fight_won and data.run_phase == state.run_phase and data.run_encounter_history.size() == state.run_encounter_history.size(), "autosave includes authoritative outcome and encounter history")
	var status := SaveSystem.load_run_result(state)
	check(status.status == "loaded", "Fight autosave loads through current validator")
	check(state.last_fight_won and not state.build_locked, "winning result survives load with required reconfirmation")
	SaveSystem.write_json("res://reports/current_autosave.json", {"checks":checks,"pass":not failed,"build":data.build,"saved_phase":data.run_phase,"last_fight_won":data.last_fight_won,"history_count":data.run_encounter_history.size(),"load_status":status})
	screen.queue_free()
	await process_frame
	print("Current ranked combat autosave: ", "FAIL" if failed else "PASS", " (", checks, " checks)")
	quit(1 if failed else 0)
