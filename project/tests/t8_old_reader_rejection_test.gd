extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	assert(SaveSystem.SAVE_VERSION == 3, "Use pinned pre-T7 Adventure reader")
	var s = root.get_node("BuildState")
	s.reset()
	s.gold = 719
	assert(SaveSystem.write_json(SaveSystem.save_path,{"save_version":4}))
	var bytes := FileAccess.get_file_as_bytes(SaveSystem.save_path)
	assert(SaveSystem.load_run_result(s).status == "failed")
	assert(s.gold == 719 and bytes == FileAccess.get_file_as_bytes(SaveSystem.save_path))
	var practice := TrainingRoomState.new()
	practice.configured_gold = 513
	practice.legendary_missing_attempts = 7
	assert(SaveSystem.write_json(PracticeSaveSystem.save_path,{"practice_version":3}))
	bytes = FileAccess.get_file_as_bytes(PracticeSaveSystem.save_path)
	assert(PracticeSaveSystem.load_setup(practice).status == "failed")
	assert(practice.configured_gold == 513 and practice.legendary_missing_attempts == 7 and bytes == FileAccess.get_file_as_bytes(PracticeSaveSystem.save_path))
	print("PASS T8 pinned readers reject Adventure4 and Practice3 without mutation")
	quit()
