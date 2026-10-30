class_name SaveSystem
extends RefCounted
## Version-5 seven-slot Adventure envelope. Older envelopes cannot restore.
## The shared epoch boundary retires old gameplay envelopes. Current saves
## decode on a detached candidate; malformed/future data is never overwritten.
## Gear and generated-contract value encodings retain their inherited policies.

const LEGACY_SAVE_PATH := "user://save.json"
const SAVE_PATH := "user://adventure_p6_m6.json"
const SAVE_VERSION := 5
const T3_STAT_IDS := ["cooldown_reduction", "increased_buff_duration", "crit_applies_penetration", "crit_applies_potency", "inventory_economy_stats"]
const GENERATED_CONTRACT_SAVE_SCHEMA_VERSION := 1
const ContractRouteGeneratorScript := preload("res://scripts/systems/contract_route_generator/contract_route_generator.gd")
const RuntimeMonsterGeneratorScript := preload("res://scripts/systems/runtime_monster_generator/runtime_monster_generator.gd")
const RuntimeArchetypeLibraryLoaderScript := preload("res://scripts/systems/runtime_monster_generator/runtime_archetype_library_loader.gd")
const StatCatalog := preload("res://scripts/systems/stat_catalog.gd")

static var save_path := SAVE_PATH
## Test Mode is memory-only. Guard every Adventure persistence entry point.
static var session_only := false
static var last_generated_load_notices := PackedStringArray()
static var last_gear_load_notices := PackedStringArray()


static func has_save() -> bool:
	if session_only or not SevenSlotSaveBoundary.ensure_ready(save_path):
		return false
	if not FileAccess.file_exists(save_path): return false
	var parsed := StrictSaveJson.read(FileAccess.get_file_as_string(save_path))
	return parsed.error == "" and typeof(parsed.data) == TYPE_DICTIONARY and parsed.data.get("save_version") == SAVE_VERSION and _valid_run_shapes(parsed.data) and _valid_build_shape(parsed.data.get("build"))


## Used for explicit replacement confirmation, including unreadable/future files.
static func has_saved_file() -> bool:
	return not session_only and SevenSlotSaveBoundary.ensure_ready(save_path) and FileAccess.file_exists(save_path)


static func delete_save() -> bool:
	if session_only: return true
	if not SevenSlotSaveBoundary.ensure_ready(save_path):
		last_error = SevenSlotSaveBoundary.last_error
		return false
	for path in [save_path + ".tmp", save_path]:
		if FileAccess.file_exists(path):
			var error: int = SevenSlotSaveBoundary.remove_override.call(path) if SevenSlotSaveBoundary.remove_override.is_valid() else DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
			if error != OK:
				last_error = "Could not remove Adventure save; the current run was retained."
				return false
	return true


## Normal temp-file replacement. This does not claim power-loss durability.
static var registry_override: BuildContentRegistry = null
static var last_load_result: Dictionary = {}
static var last_error := ""

static func registry() -> BuildContentRegistry:
	return registry_override if registry_override != null else BuildContentRegistry.adventure()

static func write_json(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t", true, true))
	file.flush()
	var result := file.get_error()
	file.close()
	if result != OK:
		return false
	var dir := DirAccess.open(path.get_base_dir())
	if dir == null:
		return false
	if dir.file_exists(path.get_file()) and dir.remove(path.get_file()) != OK:
		return false
	return dir.rename(path.get_file() + ".tmp", path.get_file()) == OK

static func save_run(state) -> bool:
	last_error = ""
	if session_only:
		return true
	if not SevenSlotSaveBoundary.ensure_ready(save_path):
		last_error = SevenSlotSaveBoundary.last_error
		return false
	if FileAccess.file_exists(save_path + ".tmp"):
		last_error = "An uncommitted Adventure temporary save was preserved; explicitly start a New Adventure to replace it."
		return false
	if FileAccess.file_exists(save_path):
		var existing = state.get_script().new()
		var outcome := load_run_result(existing)
		existing.free()
		if outcome.status != "loaded":
			last_error = "Existing Adventure save could not be validated; start a confirmed New Adventure to replace it. " + String(outcome.message)
			return false
	var build := BuildSaveCodec.encode(state, registry())
	var decoded := BuildSaveCodec.decode(build, registry())
	if decoded.error != "":
		last_error = decoded.error
		return false
	var data := _serialize(state)
	if not _valid_run_shapes(data):
		last_error = "Invalid Adventure run data."
		return false
	last_error = gear_payload_error(data, true)
	if last_error != "":
		return false
	var stats: PlayerStats = state.current_player_stats()
	if stats.derivation_error != "":
		last_error = stats.derivation_error
		return false
	if not write_json(save_path, data):
		last_error = "Could not write Adventure save."
		return false
	return true

## Compatibility boolean; UI uses the detailed outcome to distinguish reset/failure.
static func load_run(state) -> bool:
	return load_run_result(state).status == "loaded"

static func _outcome(status: String, message: String = "", persisted: bool = false) -> Dictionary:
	last_load_result = {"status": status, "message": message, "persisted": persisted}
	return last_load_result

static func load_run_result(state) -> Dictionary:
	if session_only:
		return _outcome("failed", "Test Mode does not load Adventure saves.")
	if not SevenSlotSaveBoundary.ensure_ready(save_path):
		return _outcome("failed", SevenSlotSaveBoundary.last_error)
	if not FileAccess.file_exists(save_path):
		return _outcome("missing")
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return _outcome("failed", "Could not read Adventure save.")
	var parsed := StrictSaveJson.read(file.get_as_text())
	file.close()
	if parsed.error != "" or typeof(parsed.data) != TYPE_DICTIONARY:
		return _outcome("failed", "Invalid save JSON: " + parsed.error)
	var data: Dictionary = parsed.data
	if typeof(data.get("save_version")) != TYPE_INT:
		return _outcome("failed", "Invalid save version.")
	if data.save_version != SAVE_VERSION:
		return _outcome("failed", "Unsupported save version: seven-slot Adventure requires version 5.")
	if not _valid_run_shapes(data) or not _valid_build_shape(data.get("build")):
		return _outcome("failed", "Invalid Adventure run data.")
	var preflight_error := gear_payload_error(data, true)
	if preflight_error != "":
		return _outcome("failed", preflight_error)
	for obsolete_field in ["selected_class", "selected_trees", "selected_talents", "rotation_skill_ids", "earned_talent_points"]:
		if data.has(obsolete_field):
			return _outcome("failed", "Duplicate legacy build fields in version-2 save.")
	var decoded := BuildSaveCodec.decode(data.get("build"), registry())
	if decoded.error != "":
		return _outcome("failed", decoded.error)
	# Decode all inherited gear/route data on a detached candidate. No failed load
	# can partially change live state, its signals or disk data.
	var candidate = state.get_script().new()
	var legacy := data.duplicate(true)
	legacy["selected_class"] = null
	legacy["selected_trees"] = []
	legacy["selected_talents"] = []
	legacy["rotation_skill_ids"] = []
	legacy["earned_talent_points"] = decoded.budget
	if not _valid_run_shapes(legacy) or not _deserialize(legacy, candidate):
		candidate.free()
		return _outcome("failed", "Invalid Adventure run data.")
	if decoded.trees.size() > 1 and candidate.active_contract == null and candidate.completed_contract_count == 0:
		candidate.free()
		return _outcome("failed", "Secondary tree is unavailable at this Adventure checkpoint.")
	BuildSaveCodec.apply(decoded, candidate)
	var candidate_stats: PlayerStats = candidate.current_player_stats()
	if candidate_stats.derivation_error != "":
		candidate.free()
		return _outcome("failed", candidate_stats.derivation_error)
	if not candidate.secondary_subclass_offer_ids.is_empty():
		var seen: Array[String] = []
		for id in candidate.secondary_subclass_offer_ids:
			if decoded.trees.is_empty() or seen.has(id) or not registry().trees.has(id) or id == decoded.trees[0].id:
				candidate.free()
				return _outcome("failed", "Invalid secondary subclass offers.")
			seen.append(id)
		if seen.size() != 2:
			candidate.free()
			return _outcome("failed", "Invalid secondary subclass offers.")
	copy_state(candidate, state)
	candidate.free()
	state.build_changed.emit()
	state.run_state_changed.emit()
	state.lock_changed.emit()
	return _outcome("loaded")

static func copy_state(candidate, state) -> void:
	for property in candidate.get_script().get_script_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			state.set(property.name, candidate.get(property.name))

## The reset branch cannot resolve old IDs against today's registry. It can
## still reject malformed codec primitives before replacing an old file.
static func _valid_build_shape(value: Variant) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		return false
	for field in ["build_schema_version", "content_revision", "allocation_mode", "class_id", "primary_tree_id", "secondary_tree_id", "earned_talent_points", "talent_ranks", "rotation_skill_ids"]:
		if not value.has(field):
			return false
	for field in ["build_schema_version", "earned_talent_points"]:
		if typeof(value[field]) != TYPE_INT:
			return false
	if value.build_schema_version != 1:
		return false
	for field in ["content_revision", "allocation_mode"]:
		if typeof(value[field]) != TYPE_STRING:
			return false
	for field in ["class_id", "primary_tree_id", "secondary_tree_id"]:
		if value[field] != null and typeof(value[field]) != TYPE_STRING:
			return false
	if typeof(value.talent_ranks) != TYPE_DICTIONARY or typeof(value.rotation_skill_ids) != TYPE_ARRAY:
		return false
	for id in value.talent_ranks:
		if typeof(id) != TYPE_STRING or typeof(value.talent_ranks[id]) != TYPE_INT:
			return false
	for id in value.rotation_skill_ids:
		if typeof(id) != TYPE_STRING:
			return false
	return true

static func _valid_run_shapes(data: Dictionary) -> bool:
	if gear_payload_error(data, true) != "": return false
	if data.has("mysterious_coin_unlocked") and typeof(data.mysterious_coin_unlocked) != TYPE_BOOL:
		return false
	if data.get("run_phase", 0) not in [0, 1, 2, 3, 4, 5] or data.get("run_outcome", 0) not in [0, 1, 2, 3, 4, 5, 6]:
		return false
	for field in ["inventory", "claimed_reward_encounter_indices", "shop_offers", "pending_reward_choices", "pending_contract_offers", "claimed_route_reward_ids", "run_encounter_history", "defeated_generated_boss_ids", "secondary_subclass_offer_ids"]:
		if typeof(data.get(field, [])) != TYPE_ARRAY:
			return false
	# These are gear contexts even when an entry contains only a stable ID or
	# resource path. Canonical fixed-resource lookup must not skip shape checks.
	for field in ["inventory", "shop_offers", "pending_reward_choices"]:
		for entry in data.get(field, []):
			if typeof(entry) == TYPE_DICTIONARY and _gear_shape_error(entry) != "":
				return false
	for field in ["equipped_weapon", "equipped_helm", "equipped_armor", "equipped_trinket", "equipped_charm", "equipped_legs", "equipped_hands"]:
		if not data.has(field): return false
		var entry: Variant = data.get(field)
		if entry != null and typeof(entry) != TYPE_DICTIONARY: return false
		if typeof(entry) == TYPE_DICTIONARY:
			if _gear_shape_error(entry) != "": return false
			var item := _gear_from_entry(entry)
			if item == null or not _is_valid_slot(item.slot): return false
			var expected: int = {"equipped_weapon": 0, "equipped_trinket": 1, "equipped_charm": 2, "equipped_helm": 3, "equipped_armor": 4, "equipped_legs": 5, "equipped_hands": 6}[field]
			if item.slot != expected: return false
	for id in data.get("secondary_subclass_offer_ids", []):
		if typeof(id) != TYPE_STRING:
			return false
	for field in ["claimed_route_reward_ids", "defeated_generated_boss_ids"]:
		for id in data.get(field, []):
			if typeof(id) != TYPE_STRING:
				return false
	for index in data.get("claimed_reward_encounter_indices", []):
		if typeof(index) != TYPE_INT or index < 0:
			return false
	for field in ["encounter_failure_counts", "encounter_retry_counts"]:
		if typeof(data.get(field, {})) != TYPE_DICTIONARY:
			return false
		for count in data.get(field, {}).values():
			if typeof(count) != TYPE_INT or count < 0:
				return false
	if typeof(data.get("highest_run_dps", 0.0)) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(data.get("highest_run_dps", 0.0))):
		return false
	for field in ["active_contract", "current_route_node"]:
		if data.get(field) != null and typeof(data[field]) != TYPE_STRING:
			return false
	for offer in data.get("pending_contract_offers", []):
		if typeof(offer) != TYPE_DICTIONARY or typeof(offer.get("kind", "")) != TYPE_STRING:
			return false
		if offer.get("kind") == "authored" and typeof(offer.get("resource_path")) != TYPE_STRING:
			return false
	for row in data.get("run_encounter_history", []):
		if typeof(row) != TYPE_DICTIONARY:
			return false
		for key in ["fight_number", "contract_count", "enemy_hp", "duration_ms"]:
			if row.has(key) and typeof(row[key]) != TYPE_INT:
				return false
		for key in ["contract_name", "enemy_name", "enemy_role", "enemy_color"]:
			if row.has(key) and typeof(row[key]) != TYPE_STRING:
				return false
		for key in ["total_damage", "player_dps", "required_dps", "dps_difference"]:
			if row.has(key) and (typeof(row[key]) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(row[key]))):
				return false
		if row.has("is_win") and typeof(row.is_win) != TYPE_BOOL:
			return false
	for field in ["adventure_seed", "gold", "completed_contract_count", "current_encounter_index", "run_phase", "run_outcome", "shop_round_index", "contract_offer_index", "shop_reroll_count", "shop_reroll_cost"]:
		if typeof(data.get(field, 0)) != TYPE_INT or data.get(field, 0) < 0:
			return false
	for field in ["shop_unlocked", "shop_round_pending", "shop_reroll_used", "last_fight_won", "tavern_map_choice_made"]:
		if typeof(data.get(field, false)) != TYPE_BOOL:
			return false
	if data.has("reward_result_basis"):
		var basis = data.reward_result_basis
		if typeof(basis) != TYPE_DICTIONARY or typeof(basis.get("is_valid")) != TYPE_BOOL or typeof(basis.get("is_win")) != TYPE_BOOL:
			return false
		if typeof(basis.get("overkill_damage")) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(basis.overkill_damage)) or float(basis.overkill_damage) < 0.0:
			return false
	return true

static func _serialize(state) -> Dictionary:
	var data := _serialize_run_fields(state)
	for field in ["selected_class", "selected_trees", "selected_talents", "rotation_skill_ids", "earned_talent_points"]:
		data.erase(field)
	data["build"] = BuildSaveCodec.encode(state, registry())
	return data

static func _serialize_run_fields(state) -> Dictionary:
	state.secondary_subclass_choices()
	var active_generated_contract: bool = (
		state.active_contract != null
		and state.active_contract.has_generated_route_state()
	)
	return {
		"save_version": SAVE_VERSION,
		"mysterious_coin_unlocked": state.mysterious_coin_unlocked,
		"selected_class": _resource_path_or_null(state.selected_class),
		"selected_trees": _resource_paths(state.selected_trees),
		"selected_talents": _resource_paths(state.selected_talents),
		"rotation_skill_ids": _skill_ids(state.rotation),
		"adventure_seed": state.adventure_seed,
		"gold": state.gold,
		"earned_talent_points": state.earned_talent_points,
		"inventory": _gear_list_to_data(state.inventory),
		"claimed_reward_encounter_indices": state.claimed_reward_encounter_indices.duplicate(),
		"shop_unlocked": state.shop_unlocked,
		"shop_round_pending": state.shop_round_pending,
		"shop_reroll_used": state.shop_reroll_used,
		"shop_reroll_count": state.shop_reroll_count,
		"shop_reroll_cost": state.shop_reroll_cost,
		"shop_round_index": state.shop_round_index,
		"shop_offers": _gear_list_to_data(state.shop_offers),
		"pending_reward_choices": _gear_list_to_data(state.pending_reward_choices),
		"equipped_weapon": _gear_entry_to_data(state.equipped_weapon),
		"equipped_helm": _gear_entry_to_data(state.equipped_helm),
		"equipped_armor": _gear_entry_to_data(state.equipped_armor),
		"equipped_trinket": _gear_entry_to_data(state.equipped_trinket),
		"equipped_charm": _gear_entry_to_data(state.equipped_charm),
		"equipped_legs": _gear_entry_to_data(state.equipped_legs),
		"equipped_hands": _gear_entry_to_data(state.equipped_hands),
		"pending_contract_offers": _pending_contract_offers_to_data(state.pending_contract_offers),
		"active_contract": null if active_generated_contract else _resource_path_or_null(state.active_contract),
		"current_route_node": null if active_generated_contract else _resource_path_or_null(state.current_route_node),
		"generated_active_contract": (
			_generated_active_contract_to_data(state.active_contract, state.current_route_node, state.claimed_route_reward_ids)
			if active_generated_contract
			else null
		),
		"claimed_route_reward_ids": state.claimed_route_reward_ids.duplicate(),
		"completed_contract_count": state.completed_contract_count,
		"secondary_subclass_offer_ids": state.secondary_subclass_offer_ids.duplicate(),
		"highest_run_dps": state.highest_run_dps,
		"run_encounter_history": _run_encounter_history_to_data(state.run_encounter_history),
		"contract_offer_index": state.contract_offer_index,
		"defeated_generated_boss_ids": state.defeated_generated_boss_ids.duplicate(),
		"current_encounter_index": state.current_encounter_index,
		"encounter_failure_counts": state.encounter_failure_counts.duplicate(),
		"encounter_retry_counts": state.encounter_retry_counts.duplicate(),
		# A mid-fight save can only happen from a hard crash/quit -- combat
		# resolves synchronously with no persisted tick state, so it's never
		# meaningful to resume mid-FIGHTING. Normalize it back to PLANNING.
		"run_phase": (
			state.RunPhase.PLANNING
			if state.run_phase == state.RunPhase.FIGHTING
			else state.run_phase
		),
		"run_outcome": state.run_outcome,
		"last_fight_won": state.last_fight_won,
		# Original result basis only: reward-time equipment derives its component afresh.
		"reward_result_basis": {"is_valid": state.last_combat_result.is_valid if state.last_combat_result != null else bool(state.reward_result_basis.get("is_valid", false)),
			"is_win": state.last_combat_result.is_win if state.last_combat_result != null else bool(state.reward_result_basis.get("is_win", false)),
			"overkill_damage": state.last_combat_result.overkill_damage if state.last_combat_result != null else float(state.reward_result_basis.get("overkill_damage", 0.0))},
		"tavern_map_choice_made": state.tavern_map_choice_made,
		# build_locked is intentionally not persisted -- any load should
		# require re-confirming the build lock before fighting again.
	}


static func _deserialize(data: Dictionary, state) -> bool:
	state.mysterious_coin_unlocked = data.get("mysterious_coin_unlocked", false)
	last_generated_load_notices = PackedStringArray()
	last_gear_load_notices = PackedStringArray()
	var resolved_class: ClassDef = null
	if data.get("selected_class") != null:
		resolved_class = _load_or_null(data.get("selected_class"))
		if resolved_class == null:
			return false

	var resolved_trees: Array[SubclassTree] = []
	for path in data.get("selected_trees", []):
		var tree: SubclassTree = _load_or_null(path)
		if tree == null:
			return false
		resolved_trees.append(tree)

	var resolved_talents: Array[Talent] = []
	for path in data.get("selected_talents", []):
		var talent: Talent = _load_or_null(path)
		if talent == null:
			return false
		resolved_talents.append(talent)

	var generated_notices := PackedStringArray()
	var generated_active_data: Dictionary = _generated_active_contract_from_data(data.get("generated_active_contract"), generated_notices)
	var resolved_active_contract: ContractDef = null
	var resolved_route_node: ContractRouteNode = null
	var resolved_generated_claimed_ids: Array[String] = []
	if not generated_active_data.is_empty():
		resolved_active_contract = generated_active_data["contract"]
		resolved_route_node = generated_active_data["current_route_node"]
		resolved_generated_claimed_ids = generated_active_data["claimed_route_reward_ids"]
	elif data.get("generated_active_contract") != null:
		return false
	elif data.get("active_contract") != null:
		resolved_active_contract = _load_or_null(data.get("active_contract")) as ContractDef
		if resolved_active_contract == null:
			return false

	if resolved_route_node == null and data.get("current_route_node") != null:
		resolved_route_node = _load_or_null(data.get("current_route_node")) as ContractRouteNode
		if resolved_route_node == null:
			return false

	var pending_contract_result: Dictionary = _pending_contract_offers_from_data(data.get("pending_contract_offers"), generated_notices)
	if not bool(pending_contract_result.get("ok", false)):
		return false
	var resolved_pending_contract_offers: Array[ContractDef] = pending_contract_result.get("offers", [])
	if resolved_active_contract != null and resolved_active_contract.has_generated_route_state() and not resolved_pending_contract_offers.is_empty():
		resolved_pending_contract_offers = _pending_contracts_with_active_instance(
			resolved_pending_contract_offers,
			resolved_active_contract
		)

	state.selected_class = resolved_class
	state.selected_trees = resolved_trees
	state.selected_talents = resolved_talents
	state.adventure_seed = int(data.get("adventure_seed", 1))
	state.gold = int(data.get("gold", 0))
	state.earned_talent_points = int(data.get("earned_talent_points", 0))
	state.inventory = _gear_list_from_save_data(data.get("inventory", []), "inventory")
	state.claimed_reward_encounter_indices = _int_array(data.get("claimed_reward_encounter_indices", []))
	state.shop_unlocked = bool(data.get("shop_unlocked", false))
	state.shop_round_pending = bool(data.get("shop_round_pending", false))
	state.shop_reroll_used = bool(data.get("shop_reroll_used", false))
	state.shop_reroll_count = int(data.get("shop_reroll_count", 1 if state.shop_reroll_used else 0))
	state.shop_reroll_cost = int(data.get(
		"shop_reroll_cost",
		state.SHOP_REROLL_INITIAL_COST + (state.shop_reroll_count * state.SHOP_REROLL_COST_STEP)
	))
	state.shop_round_index = int(data.get("shop_round_index", 0))
	state.shop_offers = _gear_list_from_save_data(data.get("shop_offers", []), "shop_offers")
	state.pending_reward_choices = _gear_list_from_save_data(data.get("pending_reward_choices", []), "pending_reward_choices")
	var resolved_equipped := _equipped_gear_from_save_data(data)
	state.equipped_weapon = resolved_equipped.get(GearItem.SlotType.WEAPON)
	state.equipped_helm = resolved_equipped.get(GearItem.SlotType.HELM)
	state.equipped_armor = resolved_equipped.get(GearItem.SlotType.ARMOR)
	state.equipped_trinket = resolved_equipped.get(GearItem.SlotType.TRINKET)
	state.equipped_charm = resolved_equipped.get(GearItem.SlotType.CHARM)
	state.equipped_legs = resolved_equipped.get(GearItem.SlotType.LEGS)
	state.equipped_hands = resolved_equipped.get(GearItem.SlotType.HANDS)
	state.pending_contract_offers = resolved_pending_contract_offers
	state.active_contract = resolved_active_contract
	state.current_route_node = resolved_route_node
	state.claimed_route_reward_ids = (
		resolved_generated_claimed_ids
		if not generated_active_data.is_empty()
		else _string_array(data.get("claimed_route_reward_ids", []))
	)
	state.completed_contract_count = int(data.get("completed_contract_count", 0))
	state.secondary_subclass_offer_ids.assign(data.get("secondary_subclass_offer_ids", []))
	state.highest_run_dps = maxf(0.0, float(data.get("highest_run_dps", 0.0)))
	state.run_encounter_history = _run_encounter_history_from_data(data.get("run_encounter_history", []))
	state.contract_offer_index = int(data.get("contract_offer_index", 0))
	state.defeated_generated_boss_ids = _unique_string_array(data.get("defeated_generated_boss_ids", []))
	state.current_encounter_index = int(data.get("current_encounter_index", 0))
	state.encounter_failure_counts = _int_dictionary(data.get("encounter_failure_counts", {}))
	state.encounter_retry_counts = _int_dictionary(data.get("encounter_retry_counts", {}))
	var saved_phase := int(data.get("run_phase", state.RunPhase.PLANNING))
	state.run_phase = state.RunPhase.PLANNING if saved_phase == state.RunPhase.FIGHTING else saved_phase
	state.run_outcome = int(data.get("run_outcome", state.RunOutcome.NONE))
	state.last_fight_won = bool(data.get("last_fight_won", false))
	state.last_combat_result = null
	# This basis is reward-only. No combat timeline, duration or DPS is restored.
	state.reward_result_basis = data.get("reward_result_basis", {}).duplicate(true)
	state.tavern_map_choice_made = bool(data.get("tavern_map_choice_made", false))
	state.build_locked = false

	# Rotation depends on unlocked_skills(), which reads selected_class/
	# selected_trees/selected_talents -- resolve it last, now that those are
	# committed.
	var unlocked: Array[Skill] = state.unlocked_skills()
	var resolved_rotation: Array[Skill] = []
	for skill_id in data.get("rotation_skill_ids", []):
		var skill := _find_skill_by_id(unlocked, str(skill_id))
		if skill != null:
			resolved_rotation.append(skill)
	state.rotation = resolved_rotation
	last_generated_load_notices = generated_notices

	state.build_changed.emit()
	state.run_state_changed.emit()
	state.lock_changed.emit()
	return true


static func _gear_entry_to_data(item: GearItem) -> Variant:
	if item == null:
		return null
	if item.resource_path != "":
		return {"resource_path": item.resource_path}
	var affixes := []
	for modifier in item.affixes:
		affixes.append({
			"stat_id": StatCatalog.canonicalize_stat_id(modifier.stat_id) if modifier.stat_id.strip_edges() != "" else StatCatalog.canonical_id_for_modifier(modifier),
			"stat": modifier.stat,
			"category": modifier.category,
			"operation": modifier.operation,
			"value": modifier.value,
			"is_drawback": modifier.is_drawback,
			"display_label": modifier.display_label,
		})
	return {
		"id": item.id,
		"display_name": item.display_name,
		"slot": item.slot,
		"tier": item.tier,
		"item_family": item.item_family,
		"class_family": item.class_family,
		"source_kind": item.source_kind,
		"source_context": item.source_context,
		"source_seed": item.source_seed,
		"deterministic_key": item.deterministic_key,
		"generation_value_scale": item.generation_value_scale,
		"generation_contract_depth": item.generation_contract_depth,
		"reward_base_tier": item.reward_base_tier,
		"reward_tier_steps": item.reward_tier_steps.duplicate(),
		"reward_magic_find_upgraded": item.reward_magic_find_upgraded,
		"affixes": affixes,
		"is_unidentified": item.is_unidentified,
	}


static func _gear_list_to_data(items: Array[GearItem]) -> Array:
	var out := []
	for item in items:
		out.append(_gear_entry_to_data(item))
	return out


## Envelope validation happens before decoding a detached candidate. Generation
## eligibility is deliberately not a load filter: old rolls keep their values.
static func gear_payload_error(payload: Variant, new_envelope: bool) -> String:
	if typeof(payload) == TYPE_ARRAY:
		for value in payload:
			var error := gear_payload_error(value, new_envelope)
			if error != "":
				return error
	elif typeof(payload) == TYPE_DICTIONARY:
		if payload.has("resource_path") and typeof(payload.resource_path) != TYPE_STRING:
			return "Invalid saved resource path."
		if payload.has("affixes") or payload.has("source_kind") or payload.has("slot") or payload.has("tier"):
			var shape_error := _gear_shape_error(payload)
			if shape_error != "":
				return shape_error
		if payload.has("affixes"):
			if typeof(payload.affixes) != TYPE_ARRAY:
				return "Invalid saved gear affix list."
			for raw in payload.affixes:
				if typeof(raw) != TYPE_DICTIONARY:
					if new_envelope:
						return "Invalid saved modifier."
					continue
				for field in ["stat", "category", "operation"]:
					if raw.has(field) and typeof(raw[field]) != TYPE_INT:
						return "Invalid saved modifier integer: " + field
				if raw.has("value") and (typeof(raw.value) not in [TYPE_FLOAT, TYPE_INT] or not is_finite(float(raw.value))):
					return "Invalid saved modifier value."
				if raw.has("is_drawback") and typeof(raw.is_drawback) != TYPE_BOOL:
					return "Invalid saved modifier sign."
				var identity := StatCatalog.canonicalize_stat_id(str(raw.get("stat_id", "")))
				if not new_envelope and identity in T3_STAT_IDS:
					return "New gear stats require the current save version."
				if not new_envelope:
					continue
				if typeof(raw.get("stat_id", "")) != TYPE_STRING:
					return "Invalid saved canonical stat ID."
				if identity != "" and not StatCatalog.has_stat(identity):
					return "Unknown saved canonical stat ID: " + identity
				var legacy: Variant = raw.get("stat", 0)
				if typeof(legacy) != TYPE_INT or (identity == "" and StatCatalog.legacy_stat_id(legacy) == ""):
					return "Invalid legacy stat identity."
				if typeof(raw.get("value")) not in [TYPE_FLOAT, TYPE_INT] or not is_finite(float(raw.value)):
					return "Invalid saved modifier value."
				if typeof(raw.get("operation", 0)) != TYPE_INT or raw.get("operation", 0) not in [StatModifier.OperationType.ADD, StatModifier.OperationType.MULTIPLY]:
					return "Invalid saved modifier operation."
				if typeof(raw.get("is_drawback", false)) != TYPE_BOOL:
					return "Invalid saved modifier sign."
				if typeof(raw.get("category", StatModifier.StatCategory.COMPATIBILITY)) != TYPE_INT or raw.get("category", StatModifier.StatCategory.COMPATIBILITY) not in StatModifier.StatCategory.values():
					return "Invalid saved modifier category."
				var modifier := StatModifier.new()
				modifier.stat_id = identity
				modifier.stat = legacy
				modifier.category = raw.get("category", StatModifier.StatCategory.COMPATIBILITY)
				modifier.operation = raw.get("operation", 0)
				modifier.value = float(raw.value)
				modifier.is_drawback = raw.get("is_drawback", false)
				var domain_error := StatCatalog.modifier_validation_error(modifier)
				if domain_error != "":
					return domain_error
		for key in payload:
			if key == "affixes":
				continue
			var error := gear_payload_error(payload[key], new_envelope)
			if error != "":
				return error
	return ""


## Preserve old enum/drop policies, but never coerce malformed JSON into a slot
## or pass a container to an int/float/String constructor in the gear decoder.
static func _gear_shape_error(entry: Dictionary) -> String:
	for field in ["id", "display_name", "item_family", "source_context", "deterministic_key"]:
		if entry.has(field) and typeof(entry[field]) != TYPE_STRING:
			return "Invalid saved gear text: " + field
	for field in ["slot", "tier", "class_family", "source_kind", "source_seed", "generation_contract_depth", "reward_base_tier"]:
		if entry.has(field) and typeof(entry[field]) != TYPE_INT:
			return "Invalid saved gear integer: " + field
	for field in ["reward_magic_find_upgraded", "is_unidentified"]:
		if entry.has(field) and typeof(entry[field]) != TYPE_BOOL:
			return "Invalid saved gear flag: " + field
	if entry.has("generation_value_scale") and (typeof(entry.generation_value_scale) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(entry.generation_value_scale))):
		return "Invalid saved gear generation scale."
	if entry.has("reward_tier_steps"):
		if typeof(entry.reward_tier_steps) != TYPE_ARRAY:
			return "Invalid saved gear tier steps."
		for tier in entry.reward_tier_steps:
			if typeof(tier) != TYPE_INT:
				return "Invalid saved gear tier step."
	return ""


static func _gear_from_entry(entry) -> GearItem:
	if typeof(entry) != TYPE_DICTIONARY:
		return null
	if entry.has("resource_path"):
		return _load_or_null(entry["resource_path"]) as GearItem
	var item := GearItem.new()
	item.id = str(entry.get("id", ""))
	item.display_name = str(entry.get("display_name", ""))
	item.slot = int(entry.get("slot", GearItem.SlotType.WEAPON))
	item.tier = int(entry.get("tier", GearItem.Tier.BASIC))
	item.item_family = str(entry.get("item_family", ""))
	item.class_family = int(entry.get("class_family", GearItem.ClassFamily.ROGUE))
	item.source_kind = int(entry.get("source_kind", GearItem.SourceKind.COMPATIBILITY))
	item.source_context = str(entry.get("source_context", ""))
	item.source_seed = int(entry.get("source_seed", 0))
	item.deterministic_key = str(entry.get("deterministic_key", ""))
	item.generation_value_scale = float(entry.get("generation_value_scale", 1.0))
	item.generation_contract_depth = int(entry.get("generation_contract_depth", 0))
	item.reward_base_tier = int(entry.get("reward_base_tier", -1))
	item.reward_tier_steps = _int_array(entry.get("reward_tier_steps", []))
	item.reward_magic_find_upgraded = bool(entry.get("reward_magic_find_upgraded", false))
	item.is_unidentified = bool(entry.get("is_unidentified", false))
	if item.item_family == "" and item.class_family == GearItem.ClassFamily.ROGUE:
		item.item_family = GearGenerator.rogue_item_family_for_slot(item.slot)
	var affixes: Array[StatModifier] = []
	for affix_data in entry.get("affixes", []):
		if typeof(affix_data) != TYPE_DICTIONARY:
			continue
		var modifier := StatModifier.new()
		modifier.stat_id = StatCatalog.canonicalize_stat_id(str(affix_data.get("stat_id", "")))
		modifier.stat = int(affix_data.get("stat", 0))
		modifier.category = int(affix_data.get("category", StatModifier.StatCategory.COMPATIBILITY))
		modifier.operation = int(affix_data.get("operation", 0))
		modifier.value = float(affix_data.get("value", 0.0))
		modifier.is_drawback = bool(affix_data.get("is_drawback", modifier.value < 0.0))
		modifier.display_label = str(affix_data.get("display_label", ""))
		affixes.append(modifier)
	item.affixes = affixes
	return item


static func _equipped_gear_from_save_data(data: Dictionary) -> Dictionary:
	var equipped := {}
	for slot in GearItem.universal_slot_order():
		equipped[slot] = null
	var field_slots := [
		["equipped_weapon", GearItem.SlotType.WEAPON],
		["equipped_helm", GearItem.SlotType.HELM],
		["equipped_armor", GearItem.SlotType.ARMOR],
		["equipped_charm", GearItem.SlotType.CHARM],
		["equipped_legs", GearItem.SlotType.LEGS],
		["equipped_hands", GearItem.SlotType.HANDS],
		["equipped_trinket", GearItem.SlotType.TRINKET],
	]
	for field in field_slots:
		var key := String(field[0])
		if not data.has(key):
			continue
		var expected_slot: int = field[1]
		var item := _gear_from_save_entry(data.get(key), key)
		if item == null:
			continue
		if not _is_valid_slot(item.slot):
			_record_gear_notice("dropped_invalid_slot:%s:%s" % [key, item.id])
			continue
		if item.slot != expected_slot:
			_record_gear_notice("migrated_equipped_slot:%s:%s:%s->%s" % [
				key,
				item.id,
				GearGenerator.universal_slot_label(expected_slot),
				GearGenerator.universal_slot_label(item.slot),
			])
		if equipped[item.slot] != null:
			_record_gear_notice("dropped_duplicate_equipped:%s:%s" % [key, item.id])
			continue
		equipped[item.slot] = item
	return equipped


static func _gear_from_save_entry(entry, context: String = "gear") -> GearItem:
	if typeof(entry) != TYPE_DICTIONARY:
		return null
	var canonical := _canonical_authored_gear_from_entry(entry)
	if canonical != null:
		return canonical
	if _is_obsolete_runtime_gear_entry(entry):
		_record_gear_notice("dropped_obsolete_runtime_gear:%s:%s" % [context, str(entry.get("id", ""))])
		return null
	var item := _gear_from_entry(entry)
	if item == null:
		return null
	if not _is_valid_slot(item.slot):
		_record_gear_notice("dropped_invalid_slot:%s:%s" % [context, item.id])
		return null
	if not _is_valid_tier(item.tier):
		_record_gear_notice("dropped_invalid_tier:%s:%s" % [context, item.id])
		return null
	if not _is_valid_source_kind(item.source_kind):
		_record_gear_notice("dropped_invalid_source_kind:%s:%s" % [context, item.id])
		return null
	if item.source_kind == GearItem.SourceKind.GENERATED and item.deterministic_key == "":
		item.deterministic_key = item.id
	return item


static func _canonical_authored_gear_from_entry(entry: Dictionary) -> GearItem:
	var id := str(entry.get("id", ""))
	if entry.has("resource_path"):
		var loaded := _load_or_null(entry.get("resource_path")) as GearItem
		if loaded != null:
			id = loaded.id
	var path := _canonical_authored_gear_path_for_id(id)
	return _load_or_null(path) if path != "" else null


static func _canonical_authored_gear_path_for_id(id: String) -> String:
	match id:
		"gear.lucky_coin":
			return "res://data/gear/lucky_coin.tres"
		"gear.placeholder_dagger":
			return "res://data/gear/placeholder_dagger.tres"
	for path in LegendaryCatalog.all_paths():
		var item: GearItem = load(path)
		if item != null and item.id == id:
			return path
	return ""


static func _is_obsolete_runtime_gear_entry(entry: Dictionary) -> bool:
	return not entry.has("resource_path") and not entry.has("source_kind")


static func _is_valid_slot(slot: int) -> bool:
	return GearItem.universal_slot_order().has(slot)


static func _is_valid_tier(tier: int) -> bool:
	return GearItem.rarity_order().has(tier)


static func _is_valid_source_kind(source_kind: int) -> bool:
	return source_kind in [
		GearItem.SourceKind.UNKNOWN,
		GearItem.SourceKind.GENERATED,
		GearItem.SourceKind.FIXED,
		GearItem.SourceKind.LEGENDARY,
		GearItem.SourceKind.COMPATIBILITY,
	]


static func _record_gear_notice(notice: String) -> void:
	last_gear_load_notices.append(notice)


## Drops entries that fail to resolve (e.g. a deleted authored .tres) rather
## than failing the whole load -- see the class-level doc comment.
static func _gear_list_from_data(list) -> Array[GearItem]:
	var out: Array[GearItem] = []
	if typeof(list) != TYPE_ARRAY:
		return out
	for entry in list:
		var item := _gear_from_entry(entry)
		if item != null:
			out.append(item)
	return out


static func _gear_list_from_save_data(list, context: String = "gear_list") -> Array[GearItem]:
	var out: Array[GearItem] = []
	if typeof(list) != TYPE_ARRAY:
		return out
	for i in list.size():
		var item := _gear_from_save_entry(list[i], "%s[%d]" % [context, i])
		if item != null:
			out.append(item)
	return out


static func _pending_contract_offers_to_data(offers: Array[ContractDef]) -> Array:
	var out := []
	for contract in offers:
		if contract == null:
			continue
		if contract.has_generated_route_state():
			out.append({
				"kind": "generated",
				"contract": _generated_contract_to_data(contract),
			})
		elif contract.resource_path != "":
			out.append({
				"kind": "authored",
				"resource_path": contract.resource_path,
			})
	return out


static func _pending_contract_offers_from_data(list, notices: PackedStringArray) -> Dictionary:
	var out: Array[ContractDef] = []
	if list == null:
		return {"ok": true, "offers": out}
	if typeof(list) != TYPE_ARRAY:
		return {"ok": false, "offers": out}
	for entry in list:
		if typeof(entry) != TYPE_DICTIONARY:
			return {"ok": false, "offers": out}
		var kind := String(entry.get("kind", ""))
		if kind == "authored":
			var authored: ContractDef = _load_or_null(entry.get("resource_path")) as ContractDef
			if authored == null:
				return {"ok": false, "offers": out}
			out.append(authored)
		elif kind == "generated":
			var generated := _generated_contract_from_data(entry.get("contract"), notices)
			if generated == null:
				return {"ok": false, "offers": out}
			out.append(generated)
		else:
			return {"ok": false, "offers": out}
	return {"ok": true, "offers": out}


static func _pending_contracts_with_active_instance(offers: Array[ContractDef], active: ContractDef) -> Array[ContractDef]:
	var out: Array[ContractDef] = []
	var replaced := false
	var active_key := _contract_key(active)
	for offer in offers:
		if offer != null and _contract_key(offer) == active_key:
			out.append(active)
			replaced = true
		else:
			out.append(offer)
	if not replaced:
		out.append(active)
	return out


static func _generated_active_contract_to_data(
	contract: ContractDef,
	current_node: ContractRouteNode,
	claimed_ids: Array[String]
) -> Dictionary:
	return {
		"schema_version": GENERATED_CONTRACT_SAVE_SCHEMA_VERSION,
		"contract": _generated_contract_to_data(contract),
		"current_route_node_id": _route_node_save_id(current_node),
		"claimed_route_reward_ids": claimed_ids.duplicate(),
	}


static func _generated_active_contract_from_data(value, notices: PackedStringArray) -> Dictionary:
	if value == null:
		return {}
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var schema_version := int(value.get("schema_version", -1))
	if schema_version < 1 or schema_version > GENERATED_CONTRACT_SAVE_SCHEMA_VERSION:
		return {}
	var contract: ContractDef = _generated_contract_from_data(value.get("contract"), notices)
	if contract == null:
		return {}
	var current_id := String(value.get("current_route_node_id", ""))
	if current_id == "":
		return {}
	var current_node := _find_generated_route_node(contract.offer_node, current_id)
	if current_node == null:
		return {}
	if not _restore_current_generated_combat_node(current_node):
		return {}
	return {
		"contract": contract,
		"current_route_node": current_node,
		"claimed_route_reward_ids": _string_array(value.get("claimed_route_reward_ids", [])),
	}


static func _generated_contract_to_data(contract: ContractDef) -> Dictionary:
	var nodes := _collect_route_nodes(contract.offer_node)
	var node_data := []
	for node in nodes:
		node_data.append(_generated_route_node_to_data(node))
	return {
		"schema_version": GENERATED_CONTRACT_SAVE_SCHEMA_VERSION,
		"id": contract.id,
		"display_name": contract.display_name,
		"target_display_name": contract.target_display_name,
		"offer_text": contract.offer_text,
		"generated_route_state": contract.generated_route_state(),
		"offer_node_id": _route_node_save_id(contract.offer_node),
		"nodes": node_data,
		"versions": {
			"route_generator_version": contract.generator_version,
			"presentation_table_version": contract.biome_table_version,
			"runtime_monster_generator_version": contract.runtime_monster_generator_version,
			"archetype_library_schema": contract.runtime_monster_archetype_library_version,
		},
	}


static func _generated_contract_from_data(value, notices: PackedStringArray) -> ContractDef:
	if typeof(value) != TYPE_DICTIONARY:
		return null
	var schema_version := int(value.get("schema_version", -1))
	if schema_version < 1 or schema_version > GENERATED_CONTRACT_SAVE_SCHEMA_VERSION:
		return null
	var node_entries = value.get("nodes", [])
	if typeof(node_entries) != TYPE_ARRAY or node_entries.is_empty():
		return null

	var contract := ContractDef.new()
	contract.id = String(value.get("id", ""))
	contract.display_name = String(value.get("display_name", ""))
	contract.target_display_name = String(value.get("target_display_name", ""))
	contract.offer_text = String(value.get("offer_text", ""))
	if typeof(value.get("generated_route_state", {})) != TYPE_DICTIONARY:
		return null
	contract.apply_generated_route_state(value.get("generated_route_state", {}))
	if not contract.has_generated_route_state():
		return null

	var node_by_id := {}
	var pending_edges := {}
	for node_data in node_entries:
		var node := _generated_route_node_from_data(node_data)
		if node == null:
			return null
		var node_id := _route_node_save_id(node)
		if node_id == "" or node_by_id.has(node_id):
			return null
		node_by_id[node_id] = node
		pending_edges[node_id] = _string_array((node_data as Dictionary).get("outgoing_node_ids", []))
		if not _generated_route_node_payload_is_supported(node):
			return null

	for node_id in pending_edges.keys():
		var node: ContractRouteNode = node_by_id[node_id]
		for outgoing_id in pending_edges[node_id]:
			if not node_by_id.has(outgoing_id):
				return null
			node.next_nodes.append(node_by_id[outgoing_id])

	var offer_node_id := String(value.get("offer_node_id", ""))
	if offer_node_id == "" or not node_by_id.has(offer_node_id):
		return null
	contract.offer_node = node_by_id[offer_node_id]
	_append_generated_version_mismatch_notices(contract, notices)
	return contract


static func _generated_route_node_to_data(node: ContractRouteNode) -> Dictionary:
	return {
		"id": node.id,
		"display_name": node.display_name,
		"node_type": node.node_type,
		"duration_ms": node.duration_ms,
		"reward": _reward_to_data(node.reward),
		"difficulty_label": node.difficulty_label,
		"reward_quality_label": node.reward_quality_label,
		"summary_text": node.summary_text,
		"reward_summary": node.reward_summary,
		"before_selection_text": node.before_selection_text,
		"selected_text": node.selected_text,
		"generated_state": node.generated_state(),
		"outgoing_node_ids": Array(node.outgoing_node_ids),
	}


static func _generated_route_node_from_data(value) -> ContractRouteNode:
	if typeof(value) != TYPE_DICTIONARY:
		return null
	var state = value.get("generated_state", {})
	if typeof(state) != TYPE_DICTIONARY:
		return null
	var node := ContractRouteNode.new()
	node.id = String(value.get("id", ""))
	node.display_name = String(value.get("display_name", ""))
	node.node_type = int(value.get("node_type", ContractRouteNode.NodeType.FIGHT))
	node.duration_ms = int(value.get("duration_ms", 0))
	node.reward = _reward_from_data(value.get("reward"))
	node.difficulty_label = String(value.get("difficulty_label", ""))
	node.reward_quality_label = String(value.get("reward_quality_label", ""))
	node.summary_text = String(value.get("summary_text", ""))
	node.reward_summary = String(value.get("reward_summary", ""))
	node.before_selection_text = String(value.get("before_selection_text", ""))
	node.selected_text = String(value.get("selected_text", ""))
	node.apply_generated_state(state)
	return node


static func _generated_route_node_payload_is_supported(node: ContractRouteNode) -> bool:
	if not (node.node_type in [
		ContractRouteNode.NodeType.FIGHT,
		ContractRouteNode.NodeType.CAPTAIN,
		ContractRouteNode.NodeType.ELITE,
		ContractRouteNode.NodeType.BOSS,
	]):
		return true
	if node.generated_encounter_payload.is_empty():
		return false
	var draft := GeneratedMonsterDraft.from_dictionary(node.generated_encounter_payload)
	return draft != null and draft.hp > 0 and draft.duration_ms > 0


static func _restore_current_generated_combat_node(node: ContractRouteNode) -> bool:
	if not (node.node_type in [
		ContractRouteNode.NodeType.FIGHT,
		ContractRouteNode.NodeType.CAPTAIN,
		ContractRouteNode.NodeType.ELITE,
		ContractRouteNode.NodeType.BOSS,
	]):
		return true
	if node.generated_encounter_payload.is_empty():
		return false
	var draft := GeneratedMonsterDraft.from_dictionary(node.generated_encounter_payload)
	if draft == null or draft.hp <= 0 or draft.duration_ms <= 0:
		return false
	node.monster = draft.to_monster()
	var combat_name := String(node.combat_preview.get("monster_name", ""))
	var route_name := String(node.route_preview.get("monster_name", ""))
	if combat_name != "":
		node.monster.display_name = combat_name
	elif route_name != "":
		node.monster.display_name = route_name
	node.duration_ms = draft.duration_ms
	return true


static func _append_generated_version_mismatch_notices(contract: ContractDef, notices: PackedStringArray) -> void:
	_record_generated_mismatch(
		contract,
		notices,
		"route_generator_version",
		contract.generator_version,
		ContractRouteGeneratorScript.GENERATOR_VERSION
	)
	_record_generated_mismatch(
		contract,
		notices,
		"presentation_table_version",
		contract.biome_table_version,
		ContractRouteGeneratorScript.PRESENTATION_TABLE_VERSION
	)
	_record_generated_mismatch(
		contract,
		notices,
		"runtime_monster_generator_version",
		contract.runtime_monster_generator_version,
		RuntimeMonsterGeneratorScript.GENERATOR_VERSION
	)
	_record_generated_mismatch(
		contract,
		notices,
		"archetype_library_schema",
		contract.runtime_monster_archetype_library_version,
		RuntimeArchetypeLibraryLoaderScript.EXPECTED_SCHEMA
	)


static func _record_generated_mismatch(
	contract: ContractDef,
	notices: PackedStringArray,
	field: String,
	saved: String,
	current: String
) -> void:
	if saved == "" or saved == current:
		return
	var notice := "generated_save_supported_mismatch:%s:%s->%s" % [field, saved, current]
	notices.append(notice)
	contract.route_notices.append(notice)


static func _reward_to_data(reward: EncounterReward) -> Variant:
	if reward == null:
		return null
	return {
		"gold_amount": reward.gold_amount,
		"talent_points": reward.talent_points,
		"fixed_gear_rewards": _gear_list_to_data(reward.fixed_gear_rewards),
		"gear_choice_rewards": _gear_list_to_data(reward.gear_choice_rewards),
		"unlocks_shop": reward.unlocks_shop,
		"generated_gear_choice_count": reward.generated_gear_choice_count,
		"generated_gear_tier": reward.generated_gear_tier,
		"generated_gear_slots": reward.generated_gear_slots.duplicate(),
		"legendary_choice_pool": _gear_list_to_data(reward.legendary_choice_pool),
		"legendary_choice_count": reward.legendary_choice_count,
	}


static func _reward_from_data(value) -> EncounterReward:
	if value == null:
		return null
	if typeof(value) != TYPE_DICTIONARY:
		return null
	var reward := EncounterReward.new()
	reward.gold_amount = int(value.get("gold_amount", 0))
	reward.talent_points = int(value.get("talent_points", 0))
	reward.fixed_gear_rewards = _gear_list_from_data(value.get("fixed_gear_rewards", []))
	reward.gear_choice_rewards = _gear_list_from_data(value.get("gear_choice_rewards", []))
	reward.unlocks_shop = bool(value.get("unlocks_shop", false))
	reward.generated_gear_choice_count = int(value.get("generated_gear_choice_count", 0))
	reward.generated_gear_tier = int(value.get("generated_gear_tier", GearItem.Tier.BASIC))
	reward.generated_gear_slots = _int_array(value.get("generated_gear_slots", []))
	reward.legendary_choice_pool = _gear_list_from_data(value.get("legendary_choice_pool", []))
	reward.legendary_choice_count = int(value.get("legendary_choice_count", 0))
	return reward


static func _collect_route_nodes(root_node: ContractRouteNode) -> Array[ContractRouteNode]:
	var out: Array[ContractRouteNode] = []
	var visited := {}
	_collect_route_nodes_recursive(root_node, visited, out)
	return out


static func _collect_route_nodes_recursive(
	node: ContractRouteNode,
	visited: Dictionary,
	out: Array[ContractRouteNode]
) -> void:
	var node_id := _route_node_save_id(node)
	if node == null or node_id == "" or visited.has(node_id):
		return
	visited[node_id] = true
	out.append(node)
	for next_node in node.next_nodes:
		_collect_route_nodes_recursive(next_node, visited, out)


static func _find_generated_route_node(root_node: ContractRouteNode, node_id: String) -> ContractRouteNode:
	for node in _collect_route_nodes(root_node):
		if _route_node_save_id(node) == node_id:
			return node
	return null


static func _route_node_save_id(node: ContractRouteNode) -> String:
	if node == null:
		return ""
	if node.generated_node_id != "":
		return node.generated_node_id
	return node.id


static func _contract_key(contract: ContractDef) -> String:
	if contract == null:
		return ""
	if contract.id != "":
		return contract.id
	if contract.generated_route_id != "":
		return contract.generated_route_id
	return "%s:%s" % [contract.display_name, contract.source_seed]


static func _resource_path_or_null(resource: Resource) -> Variant:
	return resource.resource_path if resource != null else null


static func _resource_paths(resources: Array) -> Array:
	var out := []
	for resource in resources:
		out.append(resource.resource_path)
	return out


static func _skill_ids(skills: Array[Skill]) -> Array:
	var out := []
	for skill in skills:
		out.append(skill.id)
	return out


static func _find_skill_by_id(skills: Array[Skill], skill_id: String) -> Skill:
	for skill in skills:
		if skill != null and skill.id == skill_id:
			return skill
	return null


## JSON has no int/float distinction -- Godot's JSON parser always produces
## float values for numbers, so failure counts must be explicitly re-cast to
## int on load or they'd silently become floats (harmless where callers
## already wrap reads in int(), but not a faithful restore of the field).
static func _int_dictionary(dict) -> Dictionary:
	var out := {}
	if typeof(dict) != TYPE_DICTIONARY:
		return out
	for key in dict.keys():
		out[str(key)] = int(dict[key])
	return out


static func _int_array(list) -> Array[int]:
	var out: Array[int] = []
	if typeof(list) != TYPE_ARRAY:
		return out
	for value in list:
		out.append(int(value))
	return out


static func _string_array(list) -> Array[String]:
	var out: Array[String] = []
	if typeof(list) != TYPE_ARRAY:
		return out
	for value in list:
		out.append(str(value))
	return out


static func _unique_string_array(list) -> Array[String]:
	var out: Array[String] = []
	var seen := {}
	if typeof(list) != TYPE_ARRAY:
		return out
	for value in list:
		var text := str(value)
		if text == "" or seen.has(text):
			continue
		seen[text] = true
		out.append(text)
	return out


static func _run_encounter_history_to_data(history: Array) -> Array:
	var out := []
	for value in history:
		if value is Dictionary:
			out.append((value as Dictionary).duplicate(true))
	return out


static func _run_encounter_history_from_data(list) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if typeof(list) != TYPE_ARRAY:
		return out
	for value in list:
		if not value is Dictionary:
			continue
		var row: Dictionary = value
		out.append({
			"fight_number": int(row.get("fight_number", out.size() + 1)),
			"contract_count": int(row.get("contract_count", 0)),
			"contract_name": String(row.get("contract_name", "")),
			"enemy_name": String(row.get("enemy_name", "")),
			"enemy_role": String(row.get("enemy_role", "")),
			"enemy_color": String(row.get("enemy_color", UIColors.TEXT_NORMAL.to_html(false))),
			"enemy_hp": int(row.get("enemy_hp", 0)),
			"duration_ms": int(row.get("duration_ms", 0)),
			"total_damage": maxf(0.0, float(row.get("total_damage", 0.0))),
			"player_dps": maxf(0.0, float(row.get("player_dps", 0.0))),
			"required_dps": maxf(0.0, float(row.get("required_dps", 0.0))),
			"dps_difference": float(row.get("dps_difference", 0.0)),
			"is_win": bool(row.get("is_win", false)),
		})
	return out


static func _load_or_null(path):
	if typeof(path) != TYPE_STRING or path == "":
		return null
	if not BuildContentRegistry.current().allowed_paths.has(path) and not LegendaryCatalog.all_paths().has(path):
		return null
	if not ResourceLoader.exists(path):
		return null
	return load(path)
