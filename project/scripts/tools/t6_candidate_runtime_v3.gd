extends RefCounted

const GENERATOR_VERSION := "p4m3.t10.v1"
const RNG_CONTEXT := "runtime_monster_generator"
const DEFAULT_SECONDARY_SCALE := 1.0
const OVERLAP_EMPHASIS_BONUS := 0.2

const SCALING_PROFILES := {
	"flat": {"growth": 0.0, "exponent": 1.0},
	"gentle": {"growth": 0.35, "exponent": 1.0},
	"standard": {"growth": 1.0, "exponent": 1.0},
	"steep": {"growth": 3.0, "exponent": 1.8},
}

const KIND_MULTIPLIERS := {
	"normal": {"hp": 1.12, "budget": 1.0, "duration": 1.0, "target_dps": 1.0, "extra_mechanics": 0},
	"captain": {"hp": 1.18, "budget": 1.1, "duration": 1.02, "target_dps": 1.04, "extra_mechanics": 0},
	"elite": {"hp": 1.28, "budget": 1.2, "duration": 1.05, "target_dps": 1.08, "extra_mechanics": 1},
	"boss": {"hp": 1.32, "budget": 1.48, "duration": 1.16, "target_dps": 1.16, "extra_mechanics": 2},
	"bespoke": {"hp": 1.0, "budget": 1.0, "duration": 1.0, "target_dps": 1.0, "extra_mechanics": 0},
}

const TEMPO_PROFILES := {
	"burst": {"name": "Burst", "duration_range": [11, 16]},
	"standard": {"name": "Standard", "duration_range": [18, 24]},
	"extended": {"name": "Extended", "duration_range": [26, 34]},
	"endurance": {"name": "Endurance", "duration_range": [38, 52]},
}


static func generate(
	input: RuntimeGenerationInput,
	library: RuntimeArchetypeLibrary = null,
	mechanic_library: RuntimeMechanicLibrary = null,
	difficulty_library: RuntimeDifficultyLibrary = null
) -> GeneratedMonsterDraft:
	var active_library: RuntimeArchetypeLibrary = library if library != null else RuntimeArchetypeLibraryLoader.load_default()
	var active_mechanics: RuntimeMechanicLibrary = mechanic_library if mechanic_library != null else RuntimeMechanicLibrary.built_in()
	var active_difficulties: RuntimeDifficultyLibrary = difficulty_library if difficulty_library != null else RuntimeDifficultyLibrary.built_in()
	var source_input := _normalized_source_input(input, active_library)
	var draft := GeneratedMonsterDraft.new()
	draft.source_input = source_input
	draft.source_seed = source_input.seed
	draft.monster_kind = source_input.monster_kind
	draft.budget_metadata = {
		"generator_version": GENERATOR_VERSION,
		"task_scope": "hp_budget_and_pressure",
	}
	draft.pressure_metadata = {
		"status": "pending",
	}

	if active_library == null:
		draft.add_notice(
			RuntimeMonsterNotice.SEVERITY_ERROR,
			"library_missing",
			"Runtime monster generation requires an archetype library."
		)
		return draft

	for notice in active_library.notices:
		draft.notices.append(notice)
	if active_library.has_errors():
		return draft
	for notice in active_mechanics.notices:
		draft.notices.append(notice)
	if active_mechanics.has_errors():
		return draft

	_validate_input_contract(source_input, active_library, active_difficulties, draft)
	var archetype_a := active_library.get_archetype(source_input.archetype_a_id)
	var archetype_b := active_library.get_archetype(source_input.archetype_b_id) if source_input.archetype_b_id != "" else null
	if draft.has_errors():
		return draft

	var archetypes: Array[RuntimeArchetypeDef] = [archetype_a]
	if archetype_b != null:
		archetypes.append(archetype_b)

	var rng := _rng_for_input(source_input)
	draft.id = _stable_generated_id(source_input)
	draft.display_name = _generated_name(rng, archetypes)
	draft.archetype_ids = _archetype_ids(archetypes)
	draft.tags = _combined_tags(archetypes)
	var band := active_difficulties.get_band(source_input.difficulty_id)
	var selected := _select_mechanics(rng, archetypes, band, source_input.monster_kind, source_input, active_mechanics, draft)
	draft.selected_mechanics = _create_mechanic_values(rng, selected, band, active_difficulties, active_mechanics, draft)
	_apply_contract_block_scaling(draft.selected_mechanics, source_input, active_mechanics)
	_apply_contract_absorb_scaling(draft.selected_mechanics, source_input, active_mechanics)
	_apply_mechanic_guardrails(draft.selected_mechanics, source_input, active_mechanics)
	_apply_contract_armor_scaling(draft.selected_mechanics, source_input, active_mechanics)
	draft.defense_overrides = _monster_overrides(draft.selected_mechanics)
	_apply_pressure_model(rng, draft, archetypes, band, source_input, active_mechanics)
	validate_draft_output(draft, band, active_mechanics)
	return draft


static func validate_draft_output(draft: GeneratedMonsterDraft, band: RuntimeDifficultyBand, mechanic_library: RuntimeMechanicLibrary = null) -> void:
	if draft.id == "":
		draft.add_notice(RuntimeMonsterNotice.SEVERITY_ERROR, "output_missing_id", "Generated monster output is missing a stable ID.")
	if draft.display_name == "":
		draft.add_notice(RuntimeMonsterNotice.SEVERITY_ERROR, "output_missing_name", "Generated monster output is missing a display name.")
	if draft.hp <= 0:
		draft.add_notice(RuntimeMonsterNotice.SEVERITY_ERROR, "output_missing_hp", "Generated monster output must include positive HP.", {"hp": draft.hp})
	if draft.duration_ms <= 0:
		draft.add_notice(RuntimeMonsterNotice.SEVERITY_ERROR, "output_missing_duration", "Generated monster output must include a positive combat duration.", {"duration_ms": draft.duration_ms})
	if draft.selected_mechanics.is_empty():
		draft.add_notice(RuntimeMonsterNotice.SEVERITY_ERROR, "output_no_combat_mechanics", "Generated monster output must include at least one combat-usable mechanic.")
	if draft.defense_overrides.is_empty():
		draft.add_notice(RuntimeMonsterNotice.SEVERITY_ERROR, "output_no_defense_overrides", "Generated monster output must include Monster-compatible defense overrides.")

	_validate_budget_metadata(draft, band)
	_validate_pressure_metadata(draft)
	_validate_selected_mechanics(draft, mechanic_library)


static func _normalized_source_input(input: RuntimeGenerationInput, library: RuntimeArchetypeLibrary) -> RuntimeGenerationInput:
	var data := input.to_dictionary() if input != null else {}
	var normalized := RuntimeGenerationInput.from_dictionary(data)
	if normalized.generator_version == "":
		normalized.generator_version = GENERATOR_VERSION
	if normalized.library_schema == "" and library != null:
		normalized.library_schema = library.schema
	return normalized


static func _validate_input_contract(input: RuntimeGenerationInput, library: RuntimeArchetypeLibrary, difficulty_library: RuntimeDifficultyLibrary, draft: GeneratedMonsterDraft) -> void:
	if input.generator_version != GENERATOR_VERSION:
		draft.add_notice(
			RuntimeMonsterNotice.SEVERITY_ERROR,
			"generator_version_mismatch",
			"Runtime generation input uses an unsupported generator version.",
			{"expected": GENERATOR_VERSION, "actual": input.generator_version}
		)
	if input.library_schema != "" and input.library_schema != library.schema:
		draft.add_notice(
			RuntimeMonsterNotice.SEVERITY_ERROR,
			"library_schema_mismatch",
			"Runtime generation input uses an unsupported archetype library schema.",
			{"expected": library.schema, "actual": input.library_schema}
		)
	if input.seed < 0:
		draft.add_notice(
			RuntimeMonsterNotice.SEVERITY_ERROR,
			"seed_invalid",
			"Runtime generation seed must be non-negative.",
			{"seed": input.seed}
		)
	if input.difficulty_id <= 0 or not difficulty_library.has_band(input.difficulty_id):
		draft.add_notice(
			RuntimeMonsterNotice.SEVERITY_ERROR,
			"difficulty_invalid",
			"Runtime generation difficulty is not supported.",
			{"difficulty": input.difficulty_id}
		)
	if input.monster_kind == "":
		draft.add_notice(
			RuntimeMonsterNotice.SEVERITY_ERROR,
			"monster_kind_missing",
			"Runtime generation input must include a monster kind."
		)
	elif not KIND_MULTIPLIERS.has(input.monster_kind):
		draft.add_notice(
			RuntimeMonsterNotice.SEVERITY_ERROR,
			"monster_kind_invalid",
			"Runtime generation input uses an unsupported monster kind.",
			{"kind": input.monster_kind}
		)
	if input.archetype_a_id == "":
		draft.add_notice(
			RuntimeMonsterNotice.SEVERITY_ERROR,
			"archetype_a_missing",
			"Runtime generation input must include a primary archetype."
		)
	elif not library.has_archetype(input.archetype_a_id):
		draft.add_notice(
			RuntimeMonsterNotice.SEVERITY_ERROR,
			"archetype_a_unknown",
			"Runtime generation input references an unknown primary archetype.",
			{"id": input.archetype_a_id}
		)
	if input.archetype_b_id != "" and not library.has_archetype(input.archetype_b_id):
		draft.add_notice(
			RuntimeMonsterNotice.SEVERITY_ERROR,
			"archetype_b_unknown",
			"Runtime generation input references an unknown secondary archetype.",
			{"id": input.archetype_b_id}
		)

	if draft.has_errors():
		return

	_validate_archetype_availability(library.get_archetype(input.archetype_a_id), input, "archetype_a_unavailable", draft)
	if input.archetype_b_id != "":
		_validate_archetype_availability(library.get_archetype(input.archetype_b_id), input, "archetype_b_unavailable", draft)


static func _validate_archetype_availability(archetype: RuntimeArchetypeDef, input: RuntimeGenerationInput, code: String, draft: GeneratedMonsterDraft) -> void:
	if archetype.unlock_difficulty > input.difficulty_id:
		draft.add_notice(
			RuntimeMonsterNotice.SEVERITY_ERROR,
			code,
			"Runtime generation archetype is locked for this difficulty.",
			{"id": archetype.id, "unlock_difficulty": archetype.unlock_difficulty, "difficulty": input.difficulty_id}
		)
	var effective_kind := "normal" if input.monster_kind == "captain" else input.monster_kind
	if not archetype.allowed_kinds.has(effective_kind):
		draft.add_notice(
			RuntimeMonsterNotice.SEVERITY_ERROR,
			code,
			"Runtime generation archetype does not support this monster kind.",
			{"id": archetype.id, "kind": input.monster_kind}
		)


static func _select_mechanics(
	rng: RandomNumberGenerator,
	archetypes: Array[RuntimeArchetypeDef],
	band: RuntimeDifficultyBand,
	monster_kind: String,
	input: RuntimeGenerationInput,
	mechanic_library: RuntimeMechanicLibrary,
	draft: GeneratedMonsterDraft
) -> Array:
	var selected := []
	var selected_ids := {}
	var required_ids := _required_mechanic_ids(archetypes)
	for mechanic_id in required_ids:
		var mechanic := mechanic_library.get_mechanic(mechanic_id)
		if mechanic == null:
			draft.add_notice(RuntimeMonsterNotice.SEVERITY_ERROR, "required_mechanic_unknown", "Required runtime mechanic is not defined.", {"id": mechanic_id})
			continue
		if not mechanic.runtime_supported:
			draft.add_notice(RuntimeMonsterNotice.SEVERITY_ERROR, "required_mechanic_unsupported", "Required runtime mechanic is not supported.", {"id": mechanic_id})
			continue
		var config := _merged_mechanic_config(mechanic_id, archetypes, input, mechanic_library)
		if config == null:
			draft.add_notice(RuntimeMonsterNotice.SEVERITY_ERROR, "required_mechanic_config_missing", "Required runtime mechanic is missing an enabled config.", {"id": mechanic_id})
			continue
		selected.append({"id": mechanic_id, "config": config})
		selected_ids[mechanic_id] = true
	if draft.has_errors():
		return selected

	var target_count := _target_mechanic_count(rng, band, monster_kind)
	target_count = maxi(target_count, selected.size())
	var weights := _combined_mechanic_weights(archetypes, input)
	var remaining := []
	for mechanic_id in weights:
		if selected_ids.has(mechanic_id):
			continue
		var mechanic := mechanic_library.get_mechanic(mechanic_id)
		if mechanic == null:
			draft.add_notice(RuntimeMonsterNotice.SEVERITY_WARNING, "mechanic_unknown", "Archetype references an unknown runtime mechanic; excluding it.", {"id": mechanic_id})
			continue
		if not mechanic.runtime_supported:
			draft.add_notice(RuntimeMonsterNotice.SEVERITY_WARNING, "mechanic_unsupported", "Archetype references an unsupported runtime mechanic; excluding it.", {"id": mechanic_id})
			continue
		if float(weights[mechanic_id]) <= 0.0:
			continue
		remaining.append(mechanic_id)

	while selected.size() < target_count and not remaining.is_empty():
		var picked := _pick_weighted_id(remaining, weights, rng)
		if picked == "":
			break
		var config := _merged_mechanic_config(picked, archetypes, input, mechanic_library)
		selected.append({"id": picked, "config": config})
		remaining.erase(picked)
	return selected


static func _create_mechanic_values(
	rng: RandomNumberGenerator,
	selected: Array,
	band: RuntimeDifficultyBand,
	difficulty_library: RuntimeDifficultyLibrary,
	mechanic_library: RuntimeMechanicLibrary,
	draft: GeneratedMonsterDraft
) -> Array:
	var values := []
	for entry in selected:
		var mechanic := mechanic_library.get_mechanic(String(entry["id"]))
		if mechanic == null:
			continue
		var config: RuntimeMechanicConfig = entry.get("config", null) as RuntimeMechanicConfig
		var range := _scaled_range(config, mechanic, band, difficulty_library)
		if range[0] > range[1]:
			draft.add_notice(RuntimeMonsterNotice.SEVERITY_ERROR, "mechanic_range_invalid", "Runtime mechanic range is malformed.", {"id": mechanic.id, "range": range})
			continue
		var raw_value := _random_int(rng, range[0], range[1])
		var exported_value := mechanic.export_value(float(raw_value))
		var tag_values := []
		for tag in mechanic.tags:
			tag_values.append(tag)
		values.append({
			"id": mechanic.id,
			"name": mechanic.name,
			"short_name": mechanic.short_name,
			"godot_field": mechanic.godot_field,
			"value": raw_value,
			"godot_value": exported_value,
			"cost": _score_mechanic_cost(mechanic, raw_value),
			"range": range,
			"scaling": config.scaling if config != null else "built-in",
			"value_label": mechanic.value_label,
			"extras": config.extras.duplicate(true) if config != null else {},
			"tags": tag_values,
			"required": config.required if config != null else false,
			"required_by": config.extras.get("required_by", []) if config != null else [],
		})
	return values


static func _monster_overrides(selected_mechanics: Array) -> Dictionary:
	var overrides := {}
	for entry in selected_mechanics:
		var field := String(entry.get("godot_field", ""))
		if field == "":
			continue
		overrides[field] = entry.get("godot_value", entry.get("value", 0))
	return overrides


static func _apply_mechanic_guardrails(selected_mechanics: Array, input: RuntimeGenerationInput, mechanic_library: RuntimeMechanicLibrary) -> void:
	var guardrails: Dictionary = input.overrides.get("mechanic_guardrails", {}) as Dictionary
	var stage := int((input.overrides.get("contract_dps_scaling", {}) as Dictionary).get("contract_number", 0))
	var ids := _selected_mechanic_id_set(selected_mechanics)
	if not bool(input.overrides.get("defer_contract_balance", false)) and stage >= 4 and stage <= 6 and input.monster_kind == "boss" and ids.has("cleanse_threshold") and ids.has("suppress") and ids.has("poison_resistance"):
		guardrails = guardrails.duplicate(true)
		guardrails["id"] = "mid_poison_boss_c4_c6"
		var caps: Dictionary = guardrails.get("caps", {}).duplicate(true)
		caps["cleanse_threshold"] = {"min": 6}
		guardrails["caps"] = caps
	if guardrails.is_empty():
		return
	var rules: Dictionary = guardrails.get("combo_rules", {}) as Dictionary
	if bool(rules.get("avoid_poison_triple", false)):
		_remove_if_all_present(selected_mechanics, ["cleanse_threshold", "suppress", "poison_resistance"], "poison_resistance")
	if bool(rules.get("avoid_physical_triple", false)):
		_remove_if_all_present(selected_mechanics, ["armor", "block", "crit_negation"], "crit_negation")
	if bool(rules.get("avoid_timing_triple", false)):
		_remove_if_all_present(selected_mechanics, ["slow", "stun_duration_ms", "interrupt_skip_count"], "stun_duration_ms")
	_limit_hard_counter_count(selected_mechanics, int(guardrails.get("max_hard_counters", 0)))
	_apply_mechanic_caps(selected_mechanics, guardrails, mechanic_library)


static func _remove_if_all_present(selected_mechanics: Array, required_ids: Array, remove_id: String) -> void:
	var ids := _selected_mechanic_id_set(selected_mechanics)
	for id in required_ids:
		if not ids.has(String(id)):
			return
	for index in range(selected_mechanics.size() - 1, -1, -1):
		if String((selected_mechanics[index] as Dictionary).get("id", "")) == remove_id:
			selected_mechanics.remove_at(index)
			return


static func _limit_hard_counter_count(selected_mechanics: Array, max_count: int) -> void:
	if max_count <= 0:
		return
	var hard_ids := {
		"cleanse_threshold": true,
		"suppress": true,
		"poison_resistance": true,
		"block": true,
		"absorb": true,
		"crit_negation": true,
		"dodge_chance": true,
		"slow": true,
		"stun_duration_ms": true,
		"interrupt_skip_count": true,
	}
	var removal_priority := [
		"poison_resistance",
		"crit_negation",
		"stun_duration_ms",
		"slow",
		"suppress",
		"absorb",
		"block",
		"dodge_chance",
		"interrupt_skip_count",
		"cleanse_threshold",
	]
	while _hard_counter_count(selected_mechanics, hard_ids) > max_count:
		var removed := false
		for remove_id in removal_priority:
			for index in range(selected_mechanics.size() - 1, -1, -1):
				var entry: Dictionary = selected_mechanics[index]
				if String(entry.get("id", "")) == remove_id and not bool(entry.get("required", false)):
					selected_mechanics.remove_at(index)
					removed = true
					break
			if removed:
				break
		if not removed:
			return


static func _hard_counter_count(selected_mechanics: Array, hard_ids: Dictionary) -> int:
	var count := 0
	for entry in selected_mechanics:
		if hard_ids.has(String((entry as Dictionary).get("id", ""))):
			count += 1
	return count


static func _apply_mechanic_caps(selected_mechanics: Array, guardrails: Dictionary, mechanic_library: RuntimeMechanicLibrary) -> void:
	var caps: Dictionary = guardrails.get("caps", {}) as Dictionary
	var guardrail_id := String(guardrails.get("id", "early_contract"))
	for entry in selected_mechanics:
		var data: Dictionary = entry
		var id := String(data.get("id", ""))
		if not caps.has(id):
			continue
		var cap: Dictionary = caps[id]
		var raw_value := int(data.get("value", 0))
		var capped_value := raw_value
		if cap.has("min"):
			capped_value = maxi(capped_value, int(cap["min"]))
		if cap.has("max"):
			capped_value = mini(capped_value, int(cap["max"]))
		if capped_value == raw_value:
			continue
		var mechanic := mechanic_library.get_mechanic(id)
		if mechanic == null:
			continue
		var extras: Dictionary = data.get("extras", {}) as Dictionary
		extras["guardrail_original_value"] = raw_value
		extras["guardrail_id"] = guardrail_id
		data["extras"] = extras
		data["value"] = capped_value
		data["godot_value"] = mechanic.export_value(float(capped_value))
		data["cost"] = _score_mechanic_cost(mechanic, capped_value)


static func _apply_contract_armor_scaling(selected_mechanics: Array, input: RuntimeGenerationInput, mechanic_library: RuntimeMechanicLibrary) -> void:
	var scaling: Dictionary = input.overrides.get("contract_armor_scaling", {}) as Dictionary
	if scaling.is_empty():
		return
	var multiplier := maxf(0.1, float(scaling.get("multiplier", 1.0)))
	if is_equal_approx(multiplier, 1.0):
		return
	var mechanic := mechanic_library.get_mechanic("armor")
	if mechanic == null:
		return
	for entry in selected_mechanics:
		var data: Dictionary = entry
		if String(data.get("id", "")) != "armor":
			continue
		var raw_value := int(data.get("value", 0))
		var scaled_value := maxi(0, roundi(float(raw_value) * multiplier))
		var extras: Dictionary = data.get("extras", {}) as Dictionary
		extras["contract_armor_original_value"] = raw_value
		extras["contract_armor_multiplier"] = multiplier
		extras["contract_armor_scaling_id"] = String(scaling.get("id", "contract_armor_curve"))
		data["extras"] = extras
		data["value"] = scaled_value
		data["godot_value"] = mechanic.export_value(float(scaled_value))
		data["cost"] = _score_mechanic_cost(mechanic, scaled_value)


static func _apply_contract_block_scaling(selected_mechanics: Array, input: RuntimeGenerationInput, mechanic_library: RuntimeMechanicLibrary) -> void:
	var scaling: Dictionary = input.overrides.get("contract_block_scaling", {}) as Dictionary
	if scaling.is_empty():
		return
	var multiplier := maxf(0.1, float(scaling.get("multiplier", 1.0)))
	if is_equal_approx(multiplier, 1.0):
		return
	var mechanic := mechanic_library.get_mechanic("block")
	if mechanic == null:
		return
	for entry in selected_mechanics:
		var data: Dictionary = entry
		if String(data.get("id", "")) != "block":
			continue
		var raw_value := int(data.get("value", 0))
		var scaled_value := maxi(0, roundi(float(raw_value) * multiplier))
		var extras: Dictionary = data.get("extras", {}) as Dictionary
		extras["contract_block_original_value"] = raw_value
		extras["contract_block_multiplier"] = multiplier
		extras["contract_block_scaling_id"] = String(scaling.get("id", "contract_block_curve"))
		data["extras"] = extras
		data["value"] = scaled_value
		data["godot_value"] = mechanic.export_value(float(scaled_value))
		data["cost"] = _score_mechanic_cost(mechanic, scaled_value)


static func _apply_contract_absorb_scaling(selected_mechanics: Array, input: RuntimeGenerationInput, mechanic_library: RuntimeMechanicLibrary) -> void:
	var scaling: Dictionary = input.overrides.get("contract_absorb_scaling", {}) as Dictionary
	if scaling.is_empty():
		return
	var multiplier := maxf(0.1, float(scaling.get("multiplier", 1.0)))
	if is_equal_approx(multiplier, 1.0):
		return
	var mechanic := mechanic_library.get_mechanic("absorb")
	if mechanic == null:
		return
	for entry in selected_mechanics:
		var data: Dictionary = entry
		if String(data.get("id", "")) != "absorb":
			continue
		var raw_value := int(data.get("value", 0))
		var scaled_value := maxi(0, roundi(float(raw_value) * multiplier))
		var extras: Dictionary = data.get("extras", {}) as Dictionary
		extras["contract_absorb_original_value"] = raw_value
		extras["contract_absorb_multiplier"] = multiplier
		extras["contract_absorb_scaling_id"] = String(scaling.get("id", "contract_absorb_curve"))
		data["extras"] = extras
		data["value"] = scaled_value
		data["godot_value"] = mechanic.export_value(float(scaled_value))
		data["cost"] = _score_mechanic_cost(mechanic, scaled_value)


static func _selected_mechanic_id_set(selected_mechanics: Array) -> Dictionary:
	var ids := {}
	for entry in selected_mechanics:
		ids[String((entry as Dictionary).get("id", ""))] = true
	return ids


static func _score_mechanic_cost(mechanic: RuntimeMechanicDef, value: int) -> int:
	if mechanic.invert_cost:
		return roundi(mechanic.base_cost + (mechanic.max_value - float(value) + 1.0) * mechanic.cost_per_value)
	return roundi(mechanic.base_cost + float(value) * mechanic.cost_per_value)


static func _validate_budget_metadata(draft: GeneratedMonsterDraft, band: RuntimeDifficultyBand) -> void:
	var required_keys := ["budget", "total_cost", "budget_delta", "major_defense_count", "max_major_defenses", "major_defense_cost"]
	for key in required_keys:
		if not draft.budget_metadata.has(key):
			draft.add_notice(RuntimeMonsterNotice.SEVERITY_ERROR, "output_missing_budget_metadata", "Generated monster output is missing required budget metadata.", {"key": key})

	if not draft.budget_metadata.has("budget") or not draft.budget_metadata.has("total_cost"):
		return

	var budget := int(draft.budget_metadata.get("budget", band.budget))
	var total_cost := int(draft.budget_metadata.get("total_cost", 0))
	var budget_delta := int(draft.budget_metadata.get("budget_delta", total_cost - budget))
	if total_cost > roundi(float(budget) * 1.12):
		draft.add_notice(
			RuntimeMonsterNotice.SEVERITY_WARNING,
			"budget_over",
			"Generated monster exceeds the selected band's structural budget window.",
			{"budget": budget, "total_cost": total_cost, "budget_delta": budget_delta}
		)

	var major_count := int(draft.budget_metadata.get("major_defense_count", 0))
	var max_major := int(draft.budget_metadata.get("max_major_defenses", band.max_major_defenses))
	if major_count > max_major:
		draft.add_notice(
			RuntimeMonsterNotice.SEVERITY_WARNING,
			"major_defenses_over",
			"Generated monster exceeds the selected band's major-defense readability limit.",
			{"major_defense_count": major_count, "max_major_defenses": max_major}
		)

	if draft.monster_kind == "normal" and draft.selected_mechanics.size() >= 4:
		draft.add_notice(
			RuntimeMonsterNotice.SEVERITY_WARNING,
			"normal_readability_busy",
			"Generated normal monster has many simultaneous mechanics and may be harder to preview.",
			{"mechanic_count": draft.selected_mechanics.size(), "kind": draft.monster_kind}
		)


static func _validate_pressure_metadata(draft: GeneratedMonsterDraft) -> void:
	var required_keys := ["status", "target_dps", "required_dps", "effective_hp", "target_dps_range"]
	for key in required_keys:
		if not draft.pressure_metadata.has(key):
			draft.add_notice(RuntimeMonsterNotice.SEVERITY_ERROR, "output_missing_pressure_metadata", "Generated monster output is missing required pressure metadata.", {"key": key})

	var status := String(draft.pressure_metadata.get("status", ""))
	if status == "over_band" or status == "slightly_over":
		draft.add_notice(
			RuntimeMonsterNotice.SEVERITY_WARNING,
			"pressure_high",
			"Generated monster required DPS is above the selected pressure window.",
			{"status": status, "required_dps": draft.pressure_metadata.get("required_dps", 0.0), "target_dps": draft.target_dps}
		)
	elif status == "under_band" or status == "slightly_under":
		draft.add_notice(
			RuntimeMonsterNotice.SEVERITY_WARNING,
			"pressure_low",
			"Generated monster required DPS is below the selected pressure window.",
			{"status": status, "required_dps": draft.pressure_metadata.get("required_dps", 0.0), "target_dps": draft.target_dps}
		)


static func _validate_selected_mechanics(draft: GeneratedMonsterDraft, mechanic_library: RuntimeMechanicLibrary) -> void:
	for entry in draft.selected_mechanics:
		var mechanic_id := String(entry.get("id", ""))
		var field := String(entry.get("godot_field", ""))
		if field == "" or not GeneratedMonsterDraft.MONSTER_DEFENSE_FIELDS.has(field):
			draft.add_notice(
				RuntimeMonsterNotice.SEVERITY_ERROR,
				"output_mechanic_not_combat_usable",
				"Generated mechanic does not map to a Monster-compatible defense field.",
				{"id": mechanic_id, "field": field}
			)
		if not entry.has("cost"):
			draft.add_notice(
				RuntimeMonsterNotice.SEVERITY_WARNING,
				"mechanic_cost_missing",
				"Generated mechanic is missing structural budget cost metadata.",
				{"id": mechanic_id}
			)
		if mechanic_library == null:
			continue
		var mechanic := mechanic_library.get_mechanic(mechanic_id)
		if mechanic != null and mechanic.preview_only:
			draft.add_notice(
				RuntimeMonsterNotice.SEVERITY_WARNING,
				"preview_only_mechanic",
				"Generated mechanic is still marked preview-only in runtime metadata.",
				{"id": mechanic_id}
			)


static func _target_mechanic_count(rng: RandomNumberGenerator, band: RuntimeDifficultyBand, monster_kind: String) -> int:
	var extra := int(KIND_MULTIPLIERS.get(monster_kind, KIND_MULTIPLIERS["normal"]).get("extra_mechanics", 0))
	return _random_int(rng, band.mechanic_count[0], band.mechanic_count[1]) + extra


static func _apply_pressure_model(
	rng: RandomNumberGenerator,
	draft: GeneratedMonsterDraft,
	archetypes: Array[RuntimeArchetypeDef],
	band: RuntimeDifficultyBand,
	input: RuntimeGenerationInput,
	mechanic_library: RuntimeMechanicLibrary
) -> void:
	var kind_multiplier: Dictionary = KIND_MULTIPLIERS.get(input.monster_kind, KIND_MULTIPLIERS["normal"])
	var contract_dps_scaling := _contract_dps_scaling(input)
	var contract_dps_multiplier := float(contract_dps_scaling.get("multiplier", 1.0))
	var target_dps_range := _adjusted_target_dps_range(band, kind_multiplier, contract_dps_multiplier)
	var duration_sec := _tempo_duration_seconds(rng, input.tempo_profile, kind_multiplier)
	var hp_budget_duration_sec := maxf(duration_sec, float(contract_dps_scaling.get("min_hp_budget_duration_sec", duration_sec)))
	var target_dps := _random_float(rng, target_dps_range[0], target_dps_range[1])
	var mitigation_multiplier := _mitigation_multiplier(draft.selected_mechanics, mechanic_library)
	var hp_bias := _combined_hp_bias(archetypes, input)
	var kind_hp := float(kind_multiplier.get("hp", 1.0))
	# Introductory boss compensation for combined Slow and Interrupt pressure.
	var selected_ids := _selected_mechanic_id_set(draft.selected_mechanics)
	if not bool(input.overrides.get("defer_contract_balance", false)) and int(contract_dps_scaling.get("contract_number", 0)) == 1 and input.monster_kind == "boss" and selected_ids.has("slow") and selected_ids.has("interrupt_skip_count"):
		kind_hp *= 0.85
	var contract_number := int(contract_dps_scaling.get("contract_number", 0))
	if not bool(input.overrides.get("defer_contract_balance", false)) and contract_number >= 4 and contract_number <= 6 and input.monster_kind == "boss" and selected_ids.has("cleanse_threshold") and selected_ids.has("suppress") and selected_ids.has("poison_resistance"):
		kind_hp *= 0.8
	var contract_hp_scaling := _contract_hp_scaling(input)
	var contract_hp_multiplier := float(contract_hp_scaling.get("multiplier", 1.0))
	var base_hp := maxi(1, roundi((target_dps * hp_budget_duration_sec * hp_bias * kind_hp) / maxf(0.1, mitigation_multiplier)))
	var hp := maxi(1, roundi(float(base_hp) * contract_hp_multiplier))
	var effective_hp := roundi(float(hp) * mitigation_multiplier)
	var required_dps := float(effective_hp) / maxf(0.1, float(duration_sec))
	var status := _pressure_status(required_dps, target_dps, band.dps_tolerance)
	var pressure := _pressure_scores(draft.selected_mechanics, required_dps, target_dps, mechanic_library)
	var mechanic_cost := _mechanic_cost_total(draft.selected_mechanics)
	var hp_cost := roundi(float(hp) / 8.0)
	var synergy_cost := _synergy_cost(draft.selected_mechanics)
	var total_cost := hp_cost + mechanic_cost + synergy_cost
	var budget := roundi(float(band.budget) * float(kind_multiplier.get("budget", 1.0)))
	var major_defense_count := _major_defense_count(draft.selected_mechanics, band)

	draft.hp = hp
	draft.duration_ms = duration_sec * 1000
	draft.target_dps = target_dps
	draft.budget_metadata = {
		"generator_version": GENERATOR_VERSION,
		"task_scope": "hp_budget_and_pressure",
		"budget": budget,
		"base_budget": band.budget,
		"budget_multiplier": float(kind_multiplier.get("budget", 1.0)),
		"hp_cost": hp_cost,
		"mechanic_cost": mechanic_cost,
		"synergy_cost": synergy_cost,
		"total_cost": total_cost,
		"budget_delta": total_cost - budget,
		"major_defense_count": major_defense_count,
		"max_major_defenses": band.max_major_defenses,
		"major_defense_cost": band.major_defense_cost,
	}
	draft.pressure_metadata = {
		"status": status["id"],
		"status_label": status["label"],
		"ratio": status["ratio"],
		"window_low": status["low"],
		"window_high": status["high"],
		"target_dps": target_dps,
		"target_dps_range": target_dps_range,
		"target_dps_delta": required_dps - target_dps,
		"dps_tolerance": band.dps_tolerance,
		"required_dps": required_dps,
		"effective_hp": effective_hp,
		"base_hp_before_contract_scaling": base_hp,
		"contract_hp_multiplier": contract_hp_multiplier,
		"contract_hp_scaling": contract_hp_scaling,
		"contract_dps_multiplier": contract_dps_multiplier,
		"contract_dps_scaling": contract_dps_scaling,
		"hp_budget_duration_sec": hp_budget_duration_sec,
		"min_hp_budget_duration_sec": float(contract_dps_scaling.get("min_hp_budget_duration_sec", 0.0)),
		"mitigation_multiplier": mitigation_multiplier,
		"hp_bias": hp_bias,
		"kind_hp_multiplier": kind_hp,
		"tempo_profile": input.tempo_profile,
		"duration_sec": duration_sec,
		"pressure": pressure,
	}


static func _contract_hp_scaling(input: RuntimeGenerationInput) -> Dictionary:
	var scaling: Dictionary = input.overrides.get("contract_hp_scaling", {}) as Dictionary
	if scaling.is_empty():
		return {
			"id": "none",
			"multiplier": 1.0,
		}
	var result := scaling.duplicate(true)
	result["multiplier"] = maxf(0.1, float(result.get("multiplier", 1.0)))
	return result


static func _contract_dps_scaling(input: RuntimeGenerationInput) -> Dictionary:
	var scaling: Dictionary = input.overrides.get("contract_dps_scaling", {}) as Dictionary
	if scaling.is_empty():
		return {
			"id": "none",
			"multiplier": 1.0,
			"min_hp_budget_duration_sec": 0.0,
		}
	var result := scaling.duplicate(true)
	result["multiplier"] = maxf(0.1, float(result.get("multiplier", 1.0)))
	result["min_hp_budget_duration_sec"] = maxf(0.0, float(result.get("min_hp_budget_duration_sec", 0.0)))
	return result


static func _adjusted_target_dps_range(band: RuntimeDifficultyBand, kind_multiplier: Dictionary, contract_dps_multiplier: float = 1.0) -> PackedFloat32Array:
	var multiplier := float(kind_multiplier.get("target_dps", 1.0)) * maxf(0.1, contract_dps_multiplier)
	return PackedFloat32Array([
		float(band.target_dps_range[0]) * multiplier,
		float(band.target_dps_range[1]) * multiplier,
	])


static func _tempo_duration_seconds(rng: RandomNumberGenerator, tempo_profile: String, kind_multiplier: Dictionary) -> int:
	var profile: Dictionary = TEMPO_PROFILES.get(tempo_profile, TEMPO_PROFILES["standard"])
	var range: Array = profile.get("duration_range", [18, 24])
	return roundi(float(_random_int(rng, int(range[0]), int(range[1]))) * float(kind_multiplier.get("duration", 1.0)))


static func _combined_hp_bias(archetypes: Array[RuntimeArchetypeDef], input: RuntimeGenerationInput) -> float:
	if archetypes.is_empty():
		return 1.0
	if archetypes.size() == 1:
		return archetypes[0].base_hp_bias
	var secondary := _secondary_scale(input)
	return ((archetypes[0].base_hp_bias * 1.0) + (archetypes[1].base_hp_bias * secondary)) / (1.0 + secondary)


static func _mitigation_multiplier(selected_mechanics: Array, mechanic_library: RuntimeMechanicLibrary) -> float:
	var multiplier := 1.0
	for entry in selected_mechanics:
		var mechanic := mechanic_library.get_mechanic(String(entry.get("id", "")))
		if mechanic == null:
			continue
		multiplier += mechanic.effective_hp_per_value * float(entry.get("value", 0.0))
	return maxf(0.1, multiplier)


static func _mechanic_cost_total(selected_mechanics: Array) -> int:
	var total := 0
	for entry in selected_mechanics:
		total += int(entry.get("cost", 0))
	return total


static func _major_defense_count(selected_mechanics: Array, band: RuntimeDifficultyBand) -> int:
	var count := 0
	for entry in selected_mechanics:
		if int(entry.get("cost", 0)) >= band.major_defense_cost:
			count += 1
	return count


static func _synergy_cost(selected_mechanics: Array) -> int:
	var ids := {}
	for entry in selected_mechanics:
		ids[String(entry.get("id", ""))] = true
	var cost := 0
	if ids.has("armor") and ids.has("block"):
		cost += 10
	if ids.has("armor") and ids.has("poison_resistance"):
		cost += 12
	if ids.has("poison_resistance") and ids.has("cleanse_threshold"):
		cost += 16
	if ids.has("absorb") and ids.has("suppress"):
		cost += 10
	if ids.has("dodge_chance") and ids.has("block"):
		cost += 12
	if ids.has("slow") and ids.has("stun_duration_ms"):
		cost += 10
	return cost


static func _pressure_scores(selected_mechanics: Array, required_dps: float, target_dps: float, mechanic_library: RuntimeMechanicLibrary) -> Dictionary:
	var modifiers := {"poison": 0.0, "burst": 0.0, "sustained": 0.0}
	for entry in selected_mechanics:
		var mechanic := mechanic_library.get_mechanic(String(entry.get("id", "")))
		if mechanic == null:
			continue
		var scale := float(entry.get("value", 0.0)) / maxf(1.0, mechanic.max_value)
		modifiers["poison"] += mechanic.poison_modifier * scale
		modifiers["burst"] += mechanic.burst_modifier * scale
		modifiers["sustained"] += mechanic.sustained_modifier * scale
	var base_ratio := required_dps / maxf(0.1, target_dps)
	return {
		"poison": _clamp_pressure(base_ratio - float(modifiers["poison"])),
		"burst": _clamp_pressure(base_ratio - float(modifiers["burst"])),
		"sustained": _clamp_pressure(base_ratio - float(modifiers["sustained"])),
	}


static func _pressure_status(required_dps: float, target_dps: float, tolerance: float) -> Dictionary:
	var low := target_dps * (1.0 - tolerance)
	var high := target_dps * (1.0 + tolerance)
	var ratio := required_dps / maxf(0.1, target_dps)
	if required_dps < low:
		var under := ratio < 1.0 - tolerance * 2.0
		return {"id": "under_band" if under else "slightly_under", "label": "Under Band" if under else "Slightly Under", "ratio": ratio, "low": low, "high": high}
	if required_dps > high:
		var over := ratio > 1.0 + tolerance * 2.0
		return {"id": "over_band" if over else "slightly_over", "label": "Over Band" if over else "Slightly Over", "ratio": ratio, "low": low, "high": high}
	return {"id": "in_band", "label": "In Band", "ratio": ratio, "low": low, "high": high}


static func _clamp_pressure(value: float) -> float:
	return clampf(value, 0.2, 2.4)


static func _required_mechanic_ids(archetypes: Array[RuntimeArchetypeDef]) -> Array:
	var ids := []
	var seen := {}
	for archetype in archetypes:
		for mechanic_id in archetype.mechanic_configs:
			var config: RuntimeMechanicConfig = archetype.mechanic_configs[mechanic_id] as RuntimeMechanicConfig
			if not config.required or seen.has(mechanic_id):
				continue
			seen[mechanic_id] = true
			ids.append(mechanic_id)
	return ids


static func _combined_mechanic_weights(archetypes: Array[RuntimeArchetypeDef], input: RuntimeGenerationInput) -> Dictionary:
	var weights := {}
	for index in range(archetypes.size()):
		var scale := 1.0 if index == 0 else _secondary_scale(input)
		for mechanic_id in archetypes[index].mechanic_weights:
			weights[mechanic_id] = float(weights.get(mechanic_id, 0.0)) + maxf(0.0, float(archetypes[index].mechanic_weights[mechanic_id])) * scale
	return weights


static func _merged_mechanic_config(mechanic_id: String, archetypes: Array[RuntimeArchetypeDef], input: RuntimeGenerationInput, mechanic_library: RuntimeMechanicLibrary) -> RuntimeMechanicConfig:
	var configs := []
	for index in range(archetypes.size()):
		var archetype := archetypes[index]
		if not archetype.mechanic_configs.has(mechanic_id):
			continue
		var config: RuntimeMechanicConfig = archetype.mechanic_configs[mechanic_id] as RuntimeMechanicConfig
		if not config.enabled:
			continue
		configs.append({"config": config, "weight": 1.0 if index == 0 else _secondary_scale(input), "source": "A" if index == 0 else "B"})
	if configs.is_empty():
		return null

	var total_weight := 0.0
	var min_value := 0.0
	var max_value := 0.0
	var required := false
	var required_by := []
	for entry in configs:
		var weight := float(entry["weight"])
		var config: RuntimeMechanicConfig = entry["config"] as RuntimeMechanicConfig
		total_weight += weight
		min_value += config.min_value * weight
		max_value += config.max_value * weight
		required = required or config.required
		if config.required:
			required_by.append(entry["source"])

	var merged := RuntimeMechanicConfig.new()
	merged.enabled = true
	merged.required = required
	merged.weight = 0
	merged.min_value = roundf(min_value / maxf(total_weight, 1.0))
	merged.max_value = roundf(max_value / maxf(total_weight, 1.0))
	var first_config: RuntimeMechanicConfig = configs[0]["config"] as RuntimeMechanicConfig
	merged.scaling = first_config.scaling
	merged.extras = _merged_mechanic_extras(mechanic_id, configs, mechanic_library)
	merged.extras["required_by"] = required_by
	_apply_overlap_emphasis(merged, mechanic_id, configs, mechanic_library)
	return merged


static func _apply_overlap_emphasis(config: RuntimeMechanicConfig, mechanic_id: String, configs: Array, mechanic_library: RuntimeMechanicLibrary) -> void:
	if config == null or configs.size() < 2 or mechanic_library == null:
		return
	var mechanic := mechanic_library.get_mechanic(mechanic_id)
	if mechanic == null:
		return
	var multiplier := 1.0 + OVERLAP_EMPHASIS_BONUS
	if mechanic.invert_cost:
		config.min_value = roundf(clampf(config.min_value / multiplier, mechanic.min_value, mechanic.max_value))
		config.max_value = roundf(clampf(config.max_value / multiplier, mechanic.min_value, mechanic.max_value))
	else:
		config.min_value = roundf(clampf(config.min_value * multiplier, mechanic.min_value, mechanic.max_value))
		config.max_value = roundf(clampf(config.max_value * multiplier, mechanic.min_value, mechanic.max_value))
	if config.min_value > config.max_value:
		var swap := config.min_value
		config.min_value = config.max_value
		config.max_value = swap
	config.extras["overlap_emphasis_bonus"] = OVERLAP_EMPHASIS_BONUS


static func _merged_mechanic_extras(mechanic_id: String, configs: Array, mechanic_library: RuntimeMechanicLibrary) -> Dictionary:
	var mechanic := mechanic_library.get_mechanic(mechanic_id)
	if mechanic == null or mechanic.extra_fields.is_empty():
		return {}
	var merged := {}
	var total_weight := 0.0
	for entry in configs:
		total_weight += float(entry["weight"])
	for field in mechanic.extra_fields:
		var field_id := String(field.get("id", ""))
		if field_id == "":
			continue
		var value := 0.0
		for entry in configs:
			var config: RuntimeMechanicConfig = entry["config"] as RuntimeMechanicConfig
			var normalized := _normalized_extra_value(config.extras.get(field_id, field.get("default", 0)), field)
			value += normalized * float(entry["weight"])
		merged[field_id] = roundi(clampf(value / maxf(total_weight, 1.0), float(field.get("min", 0.0)), float(field.get("max", 0.0))))
	return merged


static func _normalized_extra_value(value: Variant, field: Dictionary) -> float:
	return clampf(float(value), float(field.get("min", 0.0)), float(field.get("max", 0.0)))


static func _scaled_range(config: RuntimeMechanicConfig, mechanic: RuntimeMechanicDef, band: RuntimeDifficultyBand, difficulty_library: RuntimeDifficultyLibrary) -> PackedInt32Array:
	if config == null:
		return RuntimeMonsterDataNormalizer.int_pair(_curve_for_band(mechanic, band.id), roundi(mechanic.min_value), roundi(mechanic.max_value))

	var profile: Dictionary = SCALING_PROFILES.get(config.scaling, SCALING_PROFILES["standard"])
	var base_low := clampf(config.min_value, mechanic.min_value, mechanic.max_value)
	var base_high := clampf(config.max_value, mechanic.min_value, mechanic.max_value)
	var multiplier := _scaling_multiplier(profile, band.id, difficulty_library)
	var low := 0
	var high := 0
	if mechanic.invert_cost:
		low = maxi(roundi(mechanic.min_value), roundi(base_low / multiplier))
		high = maxi(roundi(mechanic.min_value), roundi(base_high / multiplier))
	else:
		low = roundi(base_low * multiplier)
		high = roundi(base_high * multiplier)
	low = clampi(low, roundi(mechanic.min_value), roundi(mechanic.max_value))
	high = clampi(high, roundi(mechanic.min_value), roundi(mechanic.max_value))
	return PackedInt32Array([mini(low, high), maxi(low, high)])


static func _curve_for_band(mechanic: RuntimeMechanicDef, difficulty_id: int) -> Array:
	if mechanic.curves.has(difficulty_id):
		return mechanic.curves[difficulty_id]
	var key := str(difficulty_id)
	return mechanic.curves.get(key, [mechanic.min_value, mechanic.max_value])


static func _scaling_multiplier(profile: Dictionary, difficulty_id: int, difficulty_library: RuntimeDifficultyLibrary) -> float:
	var difficulty_progress := float(difficulty_id - 1) / float(maxi(1, difficulty_library.max_band_id() - 1))
	return 1.0 + float(profile.get("growth", 1.0)) * pow(difficulty_progress, float(profile.get("exponent", 1.0)))


static func _secondary_scale(input: RuntimeGenerationInput) -> float:
	var value = input.overrides.get("secondary_scale", input.overrides.get("secondary_weight_multiplier", DEFAULT_SECONDARY_SCALE))
	return clampf(float(value), 0.1, 1.0)


static func _pick_weighted_id(ids: Array, weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for id in ids:
		total += maxf(0.0, float(weights.get(id, 0.0)))
	if total <= 0.0:
		return String(ids[0]) if not ids.is_empty() else ""
	var roll := rng.randf() * total
	for id in ids:
		roll -= maxf(0.0, float(weights.get(id, 0.0)))
		if roll <= 0.0:
			return String(id)
	return String(ids[ids.size() - 1]) if not ids.is_empty() else ""


static func _random_int(rng: RandomNumberGenerator, min_value: int, max_value: int) -> int:
	return roundi(float(min_value) + rng.randf() * float(max_value - min_value))


static func _random_float(rng: RandomNumberGenerator, min_value: float, max_value: float) -> float:
	return min_value + rng.randf() * (max_value - min_value)


static func _rng_for_input(input: RuntimeGenerationInput) -> RandomNumberGenerator:
	return RunRng.rng_for_context(
		input.seed,
		RNG_CONTEXT,
		[
			input.archetype_a_id,
			input.archetype_b_id,
			input.difficulty_id,
			input.monster_kind,
			input.tempo_profile,
			GENERATOR_VERSION,
		]
	)


static func _stable_generated_id(input: RuntimeGenerationInput) -> String:
	return RunRng.id_for_context(
		"monster.generated",
		input.seed,
		RNG_CONTEXT,
		[
			input.archetype_a_id,
			input.archetype_b_id,
			input.difficulty_id,
			input.monster_kind,
			input.tempo_profile,
			GENERATOR_VERSION,
		]
	)


static func _generated_name(rng: RandomNumberGenerator, archetypes: Array[RuntimeArchetypeDef]) -> String:
	var prefixes := []
	var nouns := []
	for archetype in archetypes:
		prefixes.append_array(RuntimeMonsterDataNormalizer.preserve_array(archetype.name_parts.get("prefixes", [])))
		nouns.append_array(RuntimeMonsterDataNormalizer.preserve_array(archetype.name_parts.get("nouns", [])))

	var prefix := String(prefixes[rng.randi_range(0, prefixes.size() - 1)]) if not prefixes.is_empty() else "Generated"
	var noun := String(nouns[rng.randi_range(0, nouns.size() - 1)]) if not nouns.is_empty() else "Monster"
	return "%s %s" % [prefix, noun]


static func _archetype_ids(archetypes: Array[RuntimeArchetypeDef]) -> PackedStringArray:
	var ids := PackedStringArray()
	for archetype in archetypes:
		ids.append(archetype.id)
	return ids


static func _combined_tags(archetypes: Array[RuntimeArchetypeDef]) -> PackedStringArray:
	var seen := {}
	var tags := PackedStringArray()
	for archetype in archetypes:
		for tag in archetype.tags:
			if seen.has(tag):
				continue
			seen[tag] = true
			tags.append(tag)
	return tags
