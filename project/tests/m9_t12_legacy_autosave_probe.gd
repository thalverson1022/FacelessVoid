extends "res://tests/p6_m7_t11_current_autosave_test.gd"
## Retained playback fixture compatibility, followed by the real current Fight.
func run() -> void:
	var state = root.get_node("BuildState")
	state.reset()
	var rogue: ClassDef = load("res://data/classes/rogue.tres")
	state.set_class(rogue)
	state.select_tree(rogue.trees[1])
	state.choose_current_tavern_encounter()
	var legacy_rotation: Array[Skill] = [load("res://data/skills/quick_cut.tres")]
	state.rotation = legacy_rotation
	check(SaveSystem.delete_save(), "isolated compatibility fixture starts without a save")
	var accepted := SaveSystem.save_run(state)
	var error := SaveSystem.last_error
	print("LEGACY_PLAYBACK_AUTOSAVE_ACCEPTED=", accepted, " ERROR=", error)
	check(not accepted and not error.is_empty(), "historical playback build is rejected explicitly by current Adventure codec")
	SaveSystem.write_json("res://reports/legacy_autosave_compatibility.json", {"accepted":accepted,"error":error,"build":BuildSaveCodec.encode(state,SaveSystem.registry())})
	await super.run()
