extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state = root.get_node("BuildState")
	_check_json()
	_check_content()
	_check_reset_and_failure(state)
	_check_ranked(state)
	_check_practice(state)
	SaveSystem.registry_override = null
	state.reset()
	print("P6 persistence: PASS (strict parsing, resets, ranked round trips, Practice isolation)")
	quit()

func _check_content() -> void:
	var registry := _fixture_registry()
	var original: SubclassTree = registry.trees["tree.bladedancer"]
	var broken := original.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as SubclassTree
	registry.trees[broken.id] = broken
	broken.talents[0].ranks[0].stat_modifiers[0].stat_id = "unsupported.stat"
	assert(registry.validate_ranked() != "")
	broken = original.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as SubclassTree
	registry.trees[broken.id] = broken
	broken.talents[0].prerequisite_ids = [broken.talents[0].id]
	assert(registry.validate_ranked() != "")
	broken = original.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as SubclassTree
	registry.trees[broken.id] = broken
	broken.talents[0].ranks.remove_at(0)
	assert(registry.validate_ranked() != "")
	assert(_fixture_registry().validate_ranked() == "")

func _check_json() -> void:
	for text in ['{"a":1,"a":2}', '{"a":{"b":1,"b":2}}', '{"x":1,}', '[1,]', '{"a":1e999}', '{"a":9223372036854775808}', '{"a":1} trailing', '{"a":01}', '{"a":.5}']:
		assert(StrictSaveJson.read(text).error != "", text)
	var parsed := StrictSaveJson.read('{"a":[1,2.5,null,true,"escaped\\text"],"b":-2}')
	assert(parsed.error == "")
	assert(typeof(parsed.data.b) == TYPE_INT)
	assert(typeof(parsed.data.a[1]) == TYPE_FLOAT)

func _write(data: Dictionary) -> void:
	assert(SaveSystem.write_json(SaveSystem.save_path, data))

func _check_reset_and_failure(state) -> void:
	# Historical compatibility reset contract; current Adventure rejects old files.
	SaveSystem.registry_override = BuildContentRegistry.current()
	for checkpoint in [0, 3, 4, 8]:
		state.reset()
		state.gold = 999
		state.earned_talent_points = 45
		state.current_encounter_index = checkpoint
		state.inventory.append(load("res://data/gear/lucky_coin.tres"))
		state.completed_contract_count = 12
		state.encounter_retry_counts[1] = 3
		state.claimed_reward_encounter_indices.append(0)
		# Bogus legacy resource paths must never be resolved before reset.
		_write({"save_version": 1, "selected_class": "res://no_such_resource.gd", "gold": 999, "current_encounter_index": checkpoint})
		var outcome := SaveSystem.load_run_result(state)
		assert(outcome.status == "reset-incompatible" and outcome.persisted)
		var clean = state.get_script().new()
		clean.reset()
		assert(SaveSystem._serialize(state) == SaveSystem._serialize(clean))
		clean.free()
		assert(SaveSystem.load_run_result(state).status == "loaded")
	state.gold = 37
	var good := SaveSystem._serialize(state)
	for mode in ["future", "bad_build", "bad_run"]:
		var bad := good.duplicate(true)
		if mode == "future":
			bad.save_version = 999
		elif mode == "bad_build":
			bad.build.earned_talent_points = 3.5
		else:
			bad.inventory = "bad"
		_write(bad)
		var bytes := FileAccess.get_file_as_bytes(SaveSystem.save_path)
		assert(SaveSystem.load_run_result(state).status == "failed")
		assert(state.gold == 37)
		assert(FileAccess.get_file_as_bytes(SaveSystem.save_path) == bytes)
	# A directory at the temporary filename forces a write error after reset.
	_write({"save_version": 1})
	var temporary := ProjectSettings.globalize_path(SaveSystem.save_path + ".tmp")
	assert(DirAccess.make_dir_absolute(temporary) == OK)
	var failed_write := SaveSystem.load_run_result(state)
	assert(failed_write.status == "reset-incompatible" and not failed_write.persisted)
	assert(state.gold == 0 and failed_write.message.contains("could not be written"))
	assert(DirAccess.remove_absolute(temporary) == OK)
	assert(SaveSystem.load_run_result(state).status == "reset-incompatible")

func _fixture_registry() -> BuildContentRegistry:
	return preload("res://tests/fixtures/p6/registry.gd").make()

func _check_ranked(state) -> void:
	var registry := _fixture_registry()
	SaveSystem.registry_override = registry
	var rogue: ClassDef = registry.classes.values()[0]
	state.reset()
	state.set_class(rogue)
	state.add_talent_points(45)
	state.active_contract = load("res://data/contracts/the_gilded_serpent.tres")
	assert(state.configure_ranked_build(rogue.trees[0]))
	# This two-tree compatibility registry models an already-earned secondary.
	# It cannot generate the two offers required by the four-tree live registry;
	# install the earned model role directly, retaining Adventure serialization.
	state.completed_contract_count = 1
	assert(state._finish_rank_edit(state.ranked_build.choose_secondary(rogue.trees[1], true)))
	for i in 4:
		assert(state.select_talent(rogue.trees[0].talents[0]))
	for i in 3:
		assert(state.select_talent(rogue.trees[1].talents[0]))
	var rotation: Array[Skill] = [rogue.base_skills[0], rogue.base_skills[0]]
	state.set_rotation(rotation)
	state.set_locked(true)
	var before: Dictionary = state.ranked_build.rank_map()
	assert(SaveSystem.save_run(state), SaveSystem.last_error)
	var data: Dictionary = StrictSaveJson.read(FileAccess.get_file_as_string(SaveSystem.save_path)).data
	assert(not data.has("earned_talent_points") and not data.has("selected_talents"))
	state.reset()
	assert(SaveSystem.load_run_result(state).status == "loaded", str(SaveSystem.last_load_result))
	assert(state.ranked_build.rank_map() == before)
	assert(state.ranked_build.primary_tree() == rogue.trees[0])
	assert(state.rotation.size() == 2 and not state.build_locked)
	assert(is_equal_approx(state.current_player_stats().bonus_physical_damage, 4))
	for bad_rank in [-1, 0, 6, 1.5, "2"]:
		var bad := data.duplicate(true)
		bad.build.talent_ranks["talent.bladedancer.wet_stone"] = bad_rank
		_write(bad)
		assert(SaveSystem.load_run_result(state).status == "failed")
		assert(state.ranked_build.rank_map() == before)
	var overflowing := data.duplicate(true)
	overflowing.build.rotation_skill_ids = ["missing"]
	for i in 12:
		overflowing.build.rotation_skill_ids.append(rogue.base_skills[0].id)
	_write(overflowing)
	assert(SaveSystem.load_run_result(state).status == "loaded")
	assert(state.rotation.size() == 10)
	assert(state.rotation_changes.removed == ["missing"] and state.rotation_changes.overflow.size() == 2)
	# Reversed explicit roles are preserved on compatible revisions.
	registry.compatible.append("p6.test.scalars.previous")
	data.build.content_revision = "p6.test.scalars.previous"
	data.build.primary_tree_id = "tree.thief"
	data.build.secondary_tree_id = "tree.bladedancer"
	_write(data)
	assert(SaveSystem.load_run_result(state).status == "loaded")
	assert(state.ranked_build.primary_tree().id == "tree.thief")
	registry.incompatible.append("p6.test.scalars.previous")
	assert(SaveSystem.load_run_result(state).status == "reset-incompatible")
	# The fresh preselection state must also be writable in a ranked registry.
	assert(SaveSystem.last_load_result.persisted)
	assert(SaveSystem.load_run_result(state).status == "loaded")
	assert(state.ranked_build == null)
	state.set_class(rogue)
	assert(state.selected_class == rogue)

func _check_practice(state) -> void:
	SaveSystem.registry_override = _fixture_registry()
	var rogue: ClassDef = SaveSystem.registry().classes.values()[0]
	var practice := TrainingRoomState.new()
	practice.set_class(rogue)
	assert(practice.configure_ranked_build(rogue.trees[0], rogue.trees[1]))
	assert(practice.select_talent(rogue.trees[0].talents[0]))
	practice.set_practice_gold(250)
	practice.selected_target.armor = 77
	practice.set_fight_seed(123456)
	practice.set_duration_ms(23000)
	practice.equipped_weapon = practice.practice_weapon
	var adventure_before := SaveSystem._serialize(state)
	assert(PracticeSaveSystem.save_setup(practice), PracticeSaveSystem.last_error)
	practice.add_practice_combat_gold(99)
	assert(PracticeSaveSystem.save_setup(practice))
	var restored := TrainingRoomState.new()
	assert(PracticeSaveSystem.load_setup(restored).status == "loaded")
	assert(restored.gold == 250 and restored.combat_stolen_gold == 0)
	assert(restored.fight_seed == 123456 and restored.duration_ms == 23000)
	assert(restored.selected_target.armor == 77)
	assert(restored.equipped_weapon == restored.practice_weapon)
	assert(restored.ranked_build.rank_of("talent.bladedancer.wet_stone") == 1)
	assert(restored.last_result == null and not restored.build_locked)
	assert(SaveSystem._serialize(state) == adventure_before)
	for budget in [0, 10, 45]:
		assert(practice.refund_all_talents())
		assert(practice.set_talent_budget(budget))
		assert(PracticeSaveSystem.save_setup(practice))
		assert(PracticeSaveSystem.load_setup(restored).status == "loaded")
		assert(restored.earned_talent_points == budget)
	var generated := practice.roll_generated_target(1, 54321)
	assert(not generated.has_errors())
	assert(PracticeSaveSystem.save_setup(practice))
	assert(PracticeSaveSystem.load_setup(restored).status == "loaded")
	for key in generated.to_dictionary():
		assert(_equivalent(restored.generated_monster_draft.to_dictionary()[key], generated.to_dictionary()[key]), key)
	assert(restored.selected_target.hp == practice.selected_target.hp)
	assert(restored.fight_seed == 54321)
	var old: Dictionary = StrictSaveJson.read(FileAccess.get_file_as_string(PracticeSaveSystem.save_path)).data
	old.build.content_revision = "p6.test.retired"
	SaveSystem.registry().incompatible.append("p6.test.retired")
	assert(SaveSystem.write_json(PracticeSaveSystem.save_path, old))
	assert(PracticeSaveSystem.load_setup(restored).status == "reset-incompatible")
	assert(restored.gold == 0 and restored.selected_trees.is_empty())
	assert(SaveSystem._serialize(state) == adventure_before)
	var file := FileAccess.open(PracticeSaveSystem.save_path, FileAccess.WRITE)
	file.store_string('{"practice_version":999}')
	file.close()
	var bytes := FileAccess.get_file_as_bytes(PracticeSaveSystem.save_path)
	assert(PracticeSaveSystem.load_setup(restored).status == "failed")
	assert(FileAccess.get_file_as_bytes(PracticeSaveSystem.save_path) == bytes)
	assert(SaveSystem._serialize(state) == adventure_before)



func _equivalent(a: Variant, b: Variant) -> bool:
	if typeof(a) in [TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY]:
		a = Array(a)
	if typeof(b) in [TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY]:
		b = Array(b)
	if typeof(a) in [TYPE_INT, TYPE_FLOAT] and typeof(b) in [TYPE_INT, TYPE_FLOAT]:
		return is_equal_approx(float(a), float(b))
	if typeof(a) != typeof(b):
		return false
	if typeof(a) == TYPE_DICTIONARY:
		if a.size() != b.size():
			return false
		for key in a:
			if not b.has(key) or not _equivalent(a[key], b[key]):
				return false
		return true
	if typeof(a) == TYPE_ARRAY:
		if a.size() != b.size():
			return false
		for i in a.size():
			if not _equivalent(a[i], b[i]):
				return false
		return true
	return a == b
