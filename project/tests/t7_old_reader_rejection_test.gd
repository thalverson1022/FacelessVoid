extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	assert(SaveSystem.SAVE_VERSION == 3, "Pinned pre-T7 reader only")
	var s = root.get_node("BuildState")
	s.reset()
	s.gold = 719
	assert(SaveSystem.write_json(SaveSystem.save_path, {"save_version":4}))
	var bytes := FileAccess.get_file_as_bytes(SaveSystem.save_path)
	assert(SaveSystem.load_run_result(s).status == "failed")
	assert(s.gold == 719 and bytes == FileAccess.get_file_as_bytes(SaveSystem.save_path))
	print("PASS pre-T7 reader rejects version4 without mutation")
	quit()
