extends SceneTree
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state = root.get_node("BuildState")
	state.reset()
	state.gold = 73
	var baseline := SaveSystem._serialize(state)
	for field in ["run_phase", "run_outcome"]:
		var corrupt := baseline.duplicate(true)
		corrupt[field] = 999
		assert(SaveSystem.write_json(SaveSystem.save_path, corrupt))
		var bytes := FileAccess.get_file_as_bytes(SaveSystem.save_path)
		assert(SaveSystem.load_run_result(state).status == "failed")
		assert(SaveSystem._serialize(state) == baseline)
		assert(FileAccess.get_file_as_bytes(SaveSystem.save_path) == bytes)
	# Stable IDs restore through replacement resources, not their old file paths/names.
	var registry: BuildContentRegistry = preload("res://tests/fixtures/p6/registry.gd").make()
	SaveSystem.registry_override = registry
	var rogue: ClassDef = registry.classes.values()[0]
	state.reset()
	state.set_class(rogue)
	state.add_talent_points(10)
	state.select_tree(rogue.trees[0])
	assert(state.select_talent(rogue.trees[0].talents[0]))
	assert(SaveSystem.save_run(state))
	var replacement := rogue.trees[0].duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as SubclassTree
	replacement.display_name = "Renamed test content"
	assert(replacement.resource_path == "")
	rogue.trees[0] = replacement
	registry.trees[replacement.id] = replacement
	assert(SaveSystem.load_run_result(state).status == "loaded")
	assert(state.ranked_build.primary_tree() == replacement)
	assert(state.ranked_build.rank_of("talent.bladedancer.wet_stone") == 1)
	# An invalid Practice restore must not overwrite its file on ordinary edits.
	SaveSystem.registry_override = null
	var invalid := '{"practice_version":1,"build":{"bad":true}}'
	var file := FileAccess.open(PracticeSaveSystem.core_save_path, FileAccess.WRITE)
	file.store_string(invalid)
	file.close()
	var room = load("res://scenes/training_room/training_room.tscn").instantiate()
	root.add_child(room)
	await process_frame
	assert(not room._setup_autosave)
	room._state.set_practice_gold(12)
	await process_frame
	await process_frame
	assert(FileAccess.get_file_as_string(PracticeSaveSystem.core_save_path) == invalid)
	assert(room._persistence_notice.text != "")
	room.queue_free()
	await process_frame
	state.reset()
	print("P6 boundary integration: PASS (unknown run phases, stable IDs after resource replacement, invalid Practice file protection)")
	quit()
