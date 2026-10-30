extends SceneTree
var checks := 0
var fail_once := true
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, message: String) -> void:
	checks += 1
	assert(value, message)
func erase(path: String) -> void:
	if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
func old_files(paths: Dictionary) -> void:
	for kind in ["adventure", "practice", "core", "legacy"]:
		var version := {"save_version": 4} if kind in ["adventure", "legacy"] else {"practice_version": 3}
		check(SaveSystem.write_json(paths[kind], version), "old base fixture")
		check(SaveSystem.write_json(paths[kind] + ".tmp", version), "old temp fixture")
func _run() -> void:
	var state = root.get_node("BuildState")
	state.reset()
	var owned := SevenSlotSaveBoundary.paths()
	check(not owned.is_empty() and owned.marker.begins_with("res://reports/"), "isolated fence")
	for path in owned.values():
		erase(path)
		erase(path + ".tmp")
	var untouched: String = owned.marker.get_base_dir().path_join("audio_preferences.json")
	check(SaveSystem.write_json(untouched, {"volume": 0.31}), "unrelated fixture")
	var audio := FileAccess.get_file_as_bytes(untouched)
	old_files(owned)
	# First-ever entry is Practice, before Adventure asks has_save.
	var practice := TrainingRoomState.new()
	check(PracticeSaveSystem.load_setup(practice).status == "missing", "Practice first triggers shared epoch")
	check(FileAccess.file_exists(owned.marker), "marker after full cleanup")
	for kind in ["adventure", "practice", "core", "legacy"]:
		check(not FileAccess.file_exists(owned[kind]) and not FileAccess.file_exists(owned[kind] + ".tmp"), "all owned paths removed")
	check(FileAccess.get_file_as_bytes(untouched) == audio, "unrelated data preserved")
	check(SevenSlotSaveBoundary.ensure_ready() and SevenSlotSaveBoundary.last_reset_count == 0, "idempotent guard")
	# Independent version gates remain after marker creation.
	check(SaveSystem.write_json(owned.adventure, {"save_version": 4}), "reintroduced old Adventure")
	check(SaveSystem.load_run_result(state).status == "failed", "old Adventure cannot restore after marker")
	check(SaveSystem.write_json(owned.practice, {"practice_version": 3}), "reintroduced old Practice")
	check(PracticeSaveSystem.load_setup(practice).status == "failed", "old Practice cannot restore after marker")
	for path in owned.values(): erase(path)
	# Preflight failure cannot delete earlier valid old envelopes.
	check(SaveSystem.write_json(owned.adventure, {"save_version": 4}), "old fixture")
	var f := FileAccess.open(owned.practice, FileAccess.WRITE)
	f.store_string("{broken")
	f.close()
	check(not SevenSlotSaveBoundary.ensure_ready(), "uncertain epoch blocked")
	check(FileAccess.file_exists(owned.adventure) and not FileAccess.file_exists(owned.marker), "preflight atomic")
	for path in owned.values(): erase(path)
	old_files(owned)
	SevenSlotSaveBoundary.remove_override = func(path: String) -> int:
		if path == owned.core and fail_once:
			fail_once = false
			return ERR_FILE_NO_PERMISSION
		return DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	state.gold = 77
	check(SaveSystem.load_run_result(state).status == "failed", "cleanup failure blocks load")
	check(state.gold == 77 and not FileAccess.file_exists(owned.marker), "no success marker or state mutation")
	SevenSlotSaveBoundary.remove_override = Callable()
	check(SevenSlotSaveBoundary.ensure_ready(), "cleanup failure retriable")
	for path in owned.values(): erase(path)
	# Marker write failure after cleanup must remain retriable and block entry.
	erase(owned.marker)
	SevenSlotSaveBoundary.marker_write_override = func(_path: String) -> bool: return false
	check(not SevenSlotSaveBoundary.ensure_ready() and not FileAccess.file_exists(owned.marker), "marker failure blocks success")
	SevenSlotSaveBoundary.marker_write_override = Callable()
	check(SevenSlotSaveBoundary.ensure_ready(), "marker write retried")
	erase(owned.marker)
	# Partial active overrides and ancillary-only overrides fail before disk I/O.
	var saved_adventure := SaveSystem.save_path
	var saved_practice := PracticeSaveSystem.save_path
	var saved_core := PracticeSaveSystem.core_save_path
	SaveSystem.save_path = SaveSystem.SAVE_PATH
	check(not SaveSystem.save_run(state), "Practice-only override cannot write default Adventure")
	SaveSystem.save_path = saved_adventure
	PracticeSaveSystem.save_path = PracticeSaveSystem.DEFAULT_PATH
	PracticeSaveSystem.core_save_path = PracticeSaveSystem.CORE_PATH
	check(not PracticeSaveSystem.save_setup(practice), "Adventure-only override cannot write default Practice")
	PracticeSaveSystem.save_path = saved_practice
	PracticeSaveSystem.core_save_path = saved_core
	var saved_legacy := SevenSlotSaveBoundary.legacy_path
	SevenSlotSaveBoundary.legacy_path = saved_adventure
	check(not SevenSlotSaveBoundary.ensure_ready(), "alias collision fails closed")
	SevenSlotSaveBoundary.legacy_path = saved_legacy
	# Marker loss must never delete current or future saves, malformed payloads included.
	for version in [5, 6]:
		check(SaveSystem.write_json(owned.adventure, {"save_version": version, "invalid": true}), "current future fixture")
		var bytes := FileAccess.get_file_as_bytes(owned.adventure)
		check(SevenSlotSaveBoundary.ensure_ready(), "epoch preserves current future")
		check(FileAccess.get_file_as_bytes(owned.adventure) == bytes, "current future bytes preserved")
		check(SaveSystem.load_run_result(state).status == "failed", "current future invalid fails")
		check(not SaveSystem.save_run(state) and FileAccess.get_file_as_bytes(owned.adventure) == bytes, "writer preserves invalid current/future")
		erase(owned.marker)
		erase(owned.adventure)
	for version in [4, 5]:
		check(SaveSystem.write_json(owned.practice, {"practice_version": version, "invalid": true}), "Practice current future fixture")
		var bytes := FileAccess.get_file_as_bytes(owned.practice)
		check(not PracticeSaveSystem.save_setup(practice), "Practice writer rejects current/future invalid")
		check(FileAccess.get_file_as_bytes(owned.practice) == bytes, "Practice invalid bytes preserved")
		erase(owned.practice)
		erase(owned.marker)
	# An orphan future/unknown temporary artifact must survive ordinary writers,
	# including an old base retired during first-epoch cleanup.
	for kind in ["adventure", "practice"]:
		for uncertain in [false, true]:
			for path in owned.values():
				erase(path)
				erase(path + ".tmp")
			var path: String = owned[kind]
			var old_version := {"save_version": 4} if kind == "adventure" else {"practice_version": 3}
			check(SaveSystem.write_json(path, old_version), "old base with protected temp")
			var future := {"save_version": 6} if kind == "adventure" else {"practice_version": 5}
			if uncertain:
				var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
				file.store_string("{unknown")
				file.close()
			else:
				check(SaveSystem.write_json(path + ".tmp", future), "future temp fixture")
			var bytes := FileAccess.get_file_as_bytes(path + ".tmp")
			check(not SaveSystem.save_run(state) if kind == "adventure" else not PracticeSaveSystem.save_setup(practice), "ordinary writer protects orphan temp")
			check(FileAccess.get_file_as_bytes(path + ".tmp") == bytes, "orphan temp bytes unchanged")
	for path in owned.values():
		erase(path)
		erase(path + ".tmp")
	# Memory-only Test Mode cannot even reset an old namespace.
	old_files(owned)
	SaveSystem.session_only = true
	var original := FileAccess.get_file_as_bytes(owned.adventure)
	check(not SaveSystem.has_save(), "Test Mode has no save")
	check(SaveSystem.save_run(state), "Test Mode write bypass")
	SaveSystem.delete_save()
	check(SaveSystem.load_run_result(state).status == "failed", "Test Mode read blocked")
	check(PracticeSaveSystem.save_setup(practice), "Test Mode Practice write bypass")
	check(PracticeSaveSystem.load_setup(practice).status == "failed", "Test Mode Practice read blocked")
	check(SevenSlotSaveBoundary.ensure_ready(), "Test Mode reset bypass")
	check(FileAccess.get_file_as_bytes(owned.adventure) == original and not FileAccess.file_exists(owned.marker), "Test Mode no disk effects")
	SaveSystem.session_only = false
	check(SevenSlotSaveBoundary.ensure_ready(), "final isolated cleanup")
	check(FileAccess.get_file_as_bytes(untouched) == audio, "unrelated survives all resets")
	print("M9 T5 reset PASS (%d checks)" % checks)
	quit()
