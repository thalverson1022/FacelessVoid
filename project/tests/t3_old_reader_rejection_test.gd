extends SceneTree
## Run ONLY with the pinned pre-T3 readers installed in an isolated copy.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state = root.get_node("BuildState")
	state.reset()
	state.gold = 719
	assert(SaveSystem.SAVE_VERSION == 2, "This witness requires the pre-T3 loader.")
	assert(SaveSystem.write_json(SaveSystem.save_path, {"save_version": 3}))
	var bytes := FileAccess.get_file_as_bytes(SaveSystem.save_path)
	assert(SaveSystem.load_run_result(state).status == "failed")
	assert(state.gold == 719 and FileAccess.get_file_as_bytes(SaveSystem.save_path) == bytes)
	var practice := TrainingRoomState.new()
	practice.configured_gold = 513
	assert(SaveSystem.write_json(PracticeSaveSystem.save_path, {"practice_version": 2}))
	bytes = FileAccess.get_file_as_bytes(PracticeSaveSystem.save_path)
	assert(PracticeSaveSystem.load_setup(practice).status == "failed")
	assert(practice.configured_gold == 513 and FileAccess.get_file_as_bytes(PracticeSaveSystem.save_path) == bytes)
	print("T3 old-reader version rejection: PASS")
	quit()
