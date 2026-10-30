extends SceneTree

var checks := 0
var signals_seen := 0
const DIR := "res://reports/t8_future_build_schema_saves"

func _initialize() -> void:
	call_deferred("_run")

func ck(ok: bool, label: String) -> void:
	assert(ok, label)
	checks += 1

func _signal_seen() -> void:
	signals_seen += 1

func _snapshot(state) -> Dictionary:
	var values := {}
	for property in state.get_script().get_script_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var value: Variant = state.get(property.name)
			values[property.name] = value.duplicate(true) if typeof(value) in [TYPE_ARRAY, TYPE_DICTIONARY] else value
	return values

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	SaveSystem.save_path = DIR + "/adventure.json"
	SaveSystem.registry_override = null
	var adventure = root.get_node("BuildState")
	adventure.reset()
	adventure.set_class(load("res://data/classes/rogue.tres"))
	adventure.gold = 731
	adventure.mysterious_coin_unlocked = true
	adventure.build_changed.connect(_signal_seen)
	adventure.run_state_changed.connect(_signal_seen)
	adventure.lock_changed.connect(_signal_seen)
	var baseline := SaveSystem._serialize(adventure)
	ck(SaveSystem._valid_build_shape(baseline.build), "known build schema1 remains valid")
	var registry := BuildContentRegistry.adventure()
	registry.incompatible.append("t8.old.incompatible")
	SaveSystem.registry_override = registry
	for version in [2, 3, 4]:
		for incompatible in [false, true]:
			var data := baseline.duplicate(true)
			data.save_version = version
			data.build.build_schema_version = 99
			if incompatible: data.build.content_revision = "t8.old.incompatible"
			var label := "Adventure v%d future build incompatible=%s" % [version, str(incompatible)]
			ck(SaveSystem.write_json(SaveSystem.save_path, data), label + " fixture")
			var bytes := FileAccess.get_file_as_bytes(SaveSystem.save_path)
			var live := _snapshot(adventure)
			var before := signals_seen
			ck(SaveSystem.load_run_result(adventure).status == "failed", label + " rejects")
			ck(_snapshot(adventure) == live and signals_seen == before, label + " preserves all live script fields/signals")
			ck(FileAccess.get_file_as_bytes(SaveSystem.save_path) == bytes, label + " preserves bytes")
	SaveSystem.registry_override = null
	var practice := TrainingRoomState.new()
	practice.content_registry = BuildContentRegistry.test_mode()
	practice.content_registry.incompatible.append("t8.old.incompatible")
	practice.practice_save_path = DIR + "/practice.json"
	practice.set_class(load("res://data/classes/rogue.tres"))
	practice.legendary_missing_attempts = 7
	practice.set_practice_gold(619)
	practice.build_changed.connect(_signal_seen)
	practice.lock_changed.connect(_signal_seen)
	practice.fight_setup_changed.connect(_signal_seen)
	ck(PracticeSaveSystem.save_setup(practice), "create current Practice fixture")
	var practice_baseline: Dictionary = StrictSaveJson.read(FileAccess.get_file_as_string(practice.practice_save_path)).data
	for version in [1, 2, 3]:
		for incompatible in [false, true]:
			var data := practice_baseline.duplicate(true)
			data.practice_version = version
			data.build.build_schema_version = 99
			if incompatible: data.build.content_revision = "t8.old.incompatible"
			var label := "Practice v%d future build incompatible=%s" % [version, str(incompatible)]
			ck(SaveSystem.write_json(practice.practice_save_path, data), label + " fixture")
			var bytes := FileAccess.get_file_as_bytes(practice.practice_save_path)
			var live := _snapshot(practice)
			var before := signals_seen
			ck(PracticeSaveSystem.load_setup(practice).status == "failed", label + " rejects")
			ck(_snapshot(practice) == live and signals_seen == before, label + " preserves all live script fields/signals")
			ck(FileAccess.get_file_as_bytes(practice.practice_save_path) == bytes, label + " preserves bytes")
	var report := FileAccess.open("res://reports/t8_future_build_schema_witness.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks": checks, "build_schema_version": 99, "result": "rejected without state/signal/file mutation in supported Adventure and Practice envelopes, including injected incompatible revision"}, "\t"))
	report.close()
	print("PASS T8 future nested build schema: ", checks)
	quit()
