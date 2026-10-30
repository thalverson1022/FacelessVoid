extends "res://tests/combat_playback_test.gd"
func _initialize() -> void:
	await _check_live_playback_win()
	var state = root.get_node("BuildState")
	SaveSystem.write_json("res://reports/legacy_probe.json", {
		"last_error": SaveSystem.last_error,
		"save_exists": SaveSystem.has_save(),
		"session_only": SaveSystem.session_only,
		"is_test_mode": state.is_test_mode,
		"build": BuildSaveCodec.encode(state, SaveSystem.registry()),
		"registry_mode": SaveSystem.registry().mode,
		"decode": BuildSaveCodec.decode(BuildSaveCodec.encode(state, SaveSystem.registry()), SaveSystem.registry()).error
	})
	print("Legacy autosave diagnostic: ", SaveSystem.last_error)
	quit(1 if _failed else 0)
