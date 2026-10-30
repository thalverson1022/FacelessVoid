class_name SevenSlotSaveBoundary
extends RefCounted
## The release boundary owns only these four gameplay envelopes and their temps.
## No autoload startup calls this: test wrappers install paths before first use.
const MARKER_PATH := "user://seven_slot_epoch.json"
static var marker_path := MARKER_PATH
static var legacy_path := "user://save.json"
static var remove_override: Callable
static var marker_write_override: Callable
static var last_error := ""
static var last_reset_count := 0

static func paths() -> Dictionary:
	var adventure := SaveSystem.save_path
	var practice := PracticeSaveSystem.save_path
	var core := PracticeSaveSystem.core_save_path
	var legacy := legacy_path
	var marker := marker_path
	# All three active API paths must be explicitly redirected together. Only
	# ancillary legacy/marker defaults may derive from that isolated directory.
	var overridden := adventure != SaveSystem.SAVE_PATH or practice != PracticeSaveSystem.DEFAULT_PATH or core != PracticeSaveSystem.CORE_PATH or legacy != "user://save.json" or marker != MARKER_PATH
	if overridden:
		if adventure == SaveSystem.SAVE_PATH or practice == PracticeSaveSystem.DEFAULT_PATH or core == PracticeSaveSystem.CORE_PATH:
			return {}
		var directory := adventure.get_base_dir()
		if legacy == "user://save.json": legacy = directory.path_join("save.json")
		if marker == MARKER_PATH: marker = directory.path_join("seven_slot_epoch.json")
		for path in [adventure, practice, core, legacy, marker]:
			if ProjectSettings.globalize_path(path.get_base_dir()).simplify_path() != ProjectSettings.globalize_path(directory).simplify_path():
				return {}
	var seen := {}
	for path in [adventure, practice, core, legacy, marker]:
		var absolute := ProjectSettings.globalize_path(path).simplify_path().to_lower()
		if seen.has(absolute) or absolute.ends_with(".tmp"): return {}
		seen[absolute] = true
	return {"adventure": adventure, "practice": practice, "core": core, "legacy": legacy, "marker": marker}

static func ensure_ready(requested_path: String = "") -> bool:
	last_error = ""
	last_reset_count = 0
	if SaveSystem.session_only:
		return true
	var owned := paths()
	if owned.is_empty():
		last_error = "Save paths must share an isolated namespace."
		return false
	if requested_path != "" and requested_path.get_base_dir() != String(owned.adventure).get_base_dir():
		last_error = "Persistence path is outside the configured save namespace."
		return false
	if FileAccess.file_exists(owned.marker):
		var marker := StrictSaveJson.read(FileAccess.get_file_as_string(owned.marker))
		if marker.error == "" and typeof(marker.data) == TYPE_DICTIONARY and typeof(marker.data.get("seven_slot_epoch")) == TYPE_INT and marker.data.seven_slot_epoch == 1:
			return true
		last_error = "Invalid seven-slot reset marker; files were preserved."
		return false
	var pending: Array[String] = []
	# Preflight every envelope before deleting anything. Unknown/malformed data
	# cannot prove an old version. Current/future versions are never reset.
	for kind in ["adventure", "practice", "core", "legacy"]:
		var path: String = owned[kind]
		var minimum := 5 if kind in ["adventure", "legacy"] else 4
		var version_field := "save_version" if kind in ["adventure", "legacy"] else "practice_version"
		for candidate in [path, path + ".tmp"]:
			if not FileAccess.file_exists(candidate): continue
			var parsed := StrictSaveJson.read(FileAccess.get_file_as_string(candidate))
			if kind == "legacy" and parsed.error == "" and typeof(parsed.data) == TYPE_DICTIONARY and not parsed.data.has(version_field):
				pending.append(candidate)
				continue
			if parsed.error != "" or typeof(parsed.data) != TYPE_DICTIONARY or typeof(parsed.data.get(version_field)) != TYPE_INT or parsed.data[version_field] < 1:
				last_error = "Cannot identify save epoch: " + candidate + ". Files were preserved."
				return false
			if parsed.data[version_field] < minimum:
				pending.append(candidate)
	for path in pending:
		var error: int = remove_override.call(path) if remove_override.is_valid() else DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		if error != OK:
			last_error = "Seven-slot reset could not remove " + path + ". Retry before loading or saving."
			return false
		last_reset_count += 1
	var marked: bool = marker_write_override.call(owned.marker) if marker_write_override.is_valid() else SaveSystem.write_json(owned.marker, {"seven_slot_epoch": 1})
	if not marked:
		last_error = "Seven-slot reset marker could not be saved. Retry before loading or saving."
		return false
	return true
