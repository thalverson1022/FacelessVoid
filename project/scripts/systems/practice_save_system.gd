class_name PracticeSaveSystem
extends RefCounted
const DEFAULT_PATH := "user://practice_build.json"
const CORE_PATH := "user://practice_bladedancer_core.json"
static var core_save_path := CORE_PATH
const SAVE_VERSION := 4
const ITEMS := ["weapon", "helm", "armor", "trinket", "charm", "legs", "hands"]
const SETUP_FIELDS := ["duration_ms", "fight_seed", "random_fight_seed_enabled", "generated_monster_difficulty_id", "generated_contract_level", "legendary_missing_attempts"]
static var save_path := DEFAULT_PATH
static var last_error := ""

static func _registry(state: TrainingRoomState) -> BuildContentRegistry:
	return state.content_registry if state.content_registry != null else SaveSystem.registry()

static func _path(state: TrainingRoomState) -> String:
	return state.practice_save_path if state.practice_save_path != "" else save_path

static func save_setup(state: TrainingRoomState, replace_existing: bool = false) -> bool:
	if SaveSystem.session_only: return true
	if not SevenSlotSaveBoundary.ensure_ready(_path(state)):
		last_error = SevenSlotSaveBoundary.last_error
		return false
	if not replace_existing and FileAccess.file_exists(_path(state) + ".tmp"):
		last_error = "An uncommitted Practice temporary save was preserved; explicitly use Save Setup to replace it."
		return false
	if not replace_existing and FileAccess.file_exists(_path(state)):
		var existing := TrainingRoomState.new()
		existing.content_registry = state.content_registry
		existing.practice_save_path = state.practice_save_path
		var outcome := load_setup(existing)
		if outcome.status != "loaded":
			last_error = "Existing Practice setup could not be validated; explicitly use Save Setup to replace it. " + String(outcome.message)
			return false
	if state.legendary_missing_attempts < 0 or state.legendary_missing_attempts > 99:
		last_error = "Practice missing attempts outside supported range."
		return false
	var build := BuildSaveCodec.encode(state, _registry(state))
	var decoded := BuildSaveCodec.decode(build, _registry(state))
	if decoded.error != "":
		last_error = decoded.error
		return false
	if state.carried_items.size() > 3 or state.carried_items.has(null):
		last_error = "Practice requires zero to three carried items."
		return false
	var data := {"practice_version": SAVE_VERSION, "build": build, "gold": state.configured_gold,
		"carried_items": SaveSystem._gear_list_to_data(state.carried_items),
		"target": {}, "items": {}, "equipment": {}, "setup": {},
		"generated_target": state.generated_monster_draft.to_dictionary() if state.generated_monster_draft != null else null}
	for field in SETUP_FIELDS:
		data.setup[field] = state.get(field)
	for property in state.selected_target.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.usage & PROPERTY_USAGE_STORAGE:
			data.target[property.name] = state.selected_target.get(property.name)
	for slot in ITEMS:
		var custom: GearItem = state.get("practice_" + slot)
		data.items[slot] = SaveSystem._gear_entry_to_data(custom)
		var equipped: GearItem = state.get("equipped_" + slot)
		data.equipment[slot] = {"custom": slot} if equipped == custom else SaveSystem._gear_entry_to_data(equipped)
	if not _valid_owned_entries(data):
		last_error = "Invalid owned Practice gear shape."
		return false
	last_error = SaveSystem.gear_payload_error(data, true)
	if last_error != "":
		return false
	var stats := state.current_player_stats()
	if stats.derivation_error != "":
		last_error = stats.derivation_error
		return false
	if not SaveSystem.write_json(_path(state), data):
		last_error = "Could not write Practice setup."
		return false
	last_error = ""
	return true

static func load_setup(state: TrainingRoomState) -> Dictionary:
	if SaveSystem.session_only: return _failed("Test Mode does not load Practice saves.")
	if not SevenSlotSaveBoundary.ensure_ready(_path(state)): return _failed(SevenSlotSaveBoundary.last_error)
	if not FileAccess.file_exists(_path(state)):
		return {"status": "missing", "message": ""}
	var parsed := StrictSaveJson.read(FileAccess.get_file_as_string(_path(state)))
	if parsed.error != "" or typeof(parsed.data) != TYPE_DICTIONARY:
		return _failed("Invalid Practice JSON: " + parsed.error)
	var data: Dictionary = parsed.data
	if not SaveSystem._valid_build_shape(data.get("build")):
		return _failed("Invalid Practice build shape.")
	if typeof(data.get("practice_version")) != TYPE_INT or data.practice_version != SAVE_VERSION:
		return _failed("Unsupported Practice version.")
	var gear_error := SaveSystem.gear_payload_error(data, data.practice_version >= 2)
	if gear_error != "":
		return _failed(gear_error)
	if data.practice_version >= 2 and (typeof(data.get("carried_items")) != TYPE_ARRAY or data.carried_items.size() > 3):
		return _failed("Practice requires zero to three carried items.")
	for field in ["target", "items", "equipment", "setup"]:
		if typeof(data.get(field)) != TYPE_DICTIONARY:
			return _failed("Incomplete Practice setup.")
	if data.practice_version >= 2 and not _valid_owned_entries(data):
		return _failed("Invalid owned Practice gear shape.")
	if typeof(data.get("gold")) != TYPE_INT or data.gold < 0:
		return _failed("Invalid configured Practice gold.")
	var candidate := TrainingRoomState.new()
	candidate.content_registry = state.content_registry
	candidate.practice_save_path = state.practice_save_path
	if data.practice_version >= 2:
		for entry in data.carried_items:
			if not _valid_carried_entry(entry):
				return _failed("Invalid carried Practice item shape.")
			var item := SaveSystem._gear_from_entry(entry)
			if item == null or not SaveSystem._is_valid_slot(item.slot) or not SaveSystem._is_valid_tier(item.tier):
				return _failed("Invalid carried Practice item.")
			# Mutable ordinary carried gear must never alias cached Adventure resources.
			if item.tier != GearItem.Tier.LEGENDARY:
				item = item.duplicate(true) as GearItem
			candidate.carried_items.append(item)
	for field in SETUP_FIELDS:
		if field == "legendary_missing_attempts" and data.practice_version < 3 and not data.setup.has(field):
			candidate.legendary_missing_attempts = 0
			continue
		if not data.setup.has(field) or typeof(data.setup[field]) != typeof(candidate.get(field)):
			return _failed("Invalid Practice setting: " + field)
		candidate.set(field, data.setup[field])
	if candidate.legendary_missing_attempts < 0 or candidate.legendary_missing_attempts > 99 or candidate.duration_ms < 1000 or candidate.fight_seed < 0 or candidate.fight_seed > 2147483647 or candidate.generated_contract_level < 1 or candidate.generated_contract_level > 30 or candidate.generated_monster_difficulty_id not in [0, 1, 2]:
		return _failed("Practice setting outside supported range.")
	for property in candidate.selected_target.get_property_list():
		if not (property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.usage & PROPERTY_USAGE_STORAGE):
			continue
		var field: String = property.name
		if not data.target.has(field):
			return _failed("Incomplete target snapshot.")
		var value: Variant = data.target[field]
		if property.type == TYPE_FLOAT:
			if typeof(value) not in [TYPE_FLOAT, TYPE_INT] or not is_finite(float(value)) or value < 0:
				return _failed("Invalid target defense.")
		elif typeof(value) != property.type:
			return _failed("Invalid target field.")
		elif property.type == TYPE_INT and value < 0:
			return _failed("Negative target field.")
		candidate.selected_target.set(field, value)
	for slot in ITEMS:
		if not data.items.has(slot) or not data.equipment.has(slot):
			return _failed("Incomplete Practice equipment.")
		if typeof(data.items[slot]) != TYPE_DICTIONARY or SaveSystem._gear_shape_error(data.items[slot]) != "":
			return _failed("Invalid Practice item metadata.")
		var custom := SaveSystem._gear_from_entry(data.items[slot])
		var expected: GearItem = candidate.get("practice_" + slot)
		if custom == null or custom.slot != expected.slot or custom.tier == GearItem.Tier.LEGENDARY:
			return _failed("Invalid Practice item.")
		custom = custom.duplicate(true) as GearItem
		candidate.set("practice_" + slot, custom)
		var entry: Variant = data.equipment[slot]
		if entry != null:
			if typeof(entry) != TYPE_DICTIONARY or SaveSystem._gear_shape_error(entry) != "":
				return _failed("Invalid equipped Practice metadata.")
			if entry.has("custom") and (entry.size() != 1 or entry.custom != slot):
				return _failed("Invalid custom Practice reference.")
		var equipped: GearItem
		if typeof(entry) == TYPE_DICTIONARY and entry.get("custom") == slot:
			equipped = custom
		elif entry != null:
			equipped = SaveSystem._gear_from_entry(entry)
			if equipped == null or equipped.slot != expected.slot:
				return _failed("Invalid equipped Practice item.")
		candidate.set("equipped_" + slot, equipped)
	if data.get("generated_target") != null:
		if typeof(data.generated_target) != TYPE_DICTIONARY:
			return _failed("Invalid generated target metadata.")
		candidate.generated_monster_draft = GeneratedMonsterDraft.from_dictionary(data.generated_target)
		if candidate.generated_monster_draft == null:
			return _failed("Invalid generated target metadata.")
	candidate.configured_gold = data.gold
	candidate.gold = data.gold
	var decoded := BuildSaveCodec.decode(data.get("build"), _registry(state))
	if decoded.error != "":
		return _failed(decoded.error)
	BuildSaveCodec.apply(decoded, candidate)
	var stats := candidate.current_player_stats()
	if stats.derivation_error != "":
		return _failed(stats.derivation_error)
	SaveSystem.copy_state(candidate, state)
	return {"status": "loaded", "message": ""}

static func _failed(message: String) -> Dictionary:
	return {"status": "failed", "message": message + " The file was left unchanged; use Save Setup to replace it."}

static func _valid_carried_entry(entry: Variant) -> bool:
	if typeof(entry) != TYPE_DICTIONARY:
		return false
	if SaveSystem._gear_shape_error(entry) != "":
		return false
	if entry.has("resource_path"):
		return typeof(entry.resource_path) == TYPE_STRING and not entry.resource_path.is_empty() and SaveSystem._gear_from_entry(entry) != null
	for field in ["id", "display_name"]:
		if typeof(entry.get(field)) != TYPE_STRING:
			return false
	if entry.id.is_empty() or typeof(entry.get("affixes")) != TYPE_ARRAY:
		return false
	for field in ["slot", "tier", "source_kind"]:
		if typeof(entry.get(field)) != TYPE_INT:
			return false
	return SaveSystem._is_valid_slot(entry.slot) and SaveSystem._is_valid_tier(entry.tier) and SaveSystem._is_valid_source_kind(entry.source_kind)

static func _valid_owned_entries(data: Dictionary) -> bool:
	if typeof(data.get("items")) != TYPE_DICTIONARY or typeof(data.get("equipment")) != TYPE_DICTIONARY or data.items.size() != ITEMS.size() or data.equipment.size() != ITEMS.size(): return false
	for entry in data.carried_items:
		if not _valid_carried_entry(entry):
			return false
	var slots := {"weapon": GearItem.SlotType.WEAPON, "helm": GearItem.SlotType.HELM,
		"armor": GearItem.SlotType.ARMOR, "trinket": GearItem.SlotType.TRINKET, "charm": GearItem.SlotType.CHARM, "legs": GearItem.SlotType.LEGS, "hands": GearItem.SlotType.HANDS}
	for slot in ITEMS:
		if not _valid_carried_entry(data.items.get(slot)):
			return false
		var custom := SaveSystem._gear_from_entry(data.items[slot])
		if custom == null or custom.slot != slots[slot] or custom.tier == GearItem.Tier.LEGENDARY:
			return false
		var entry: Variant = data.equipment.get(slot)
		if entry == null:
			continue
		if typeof(entry) == TYPE_DICTIONARY and entry.get("custom") == slot:
			if entry.size() != 1: return false
			continue
		if not _valid_carried_entry(entry):
			return false
		var equipped := SaveSystem._gear_from_entry(entry)
		if equipped == null or equipped.slot != slots[slot]:
			return false
	return true
