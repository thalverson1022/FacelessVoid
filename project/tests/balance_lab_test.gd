extends SceneTree

const BalanceLab = preload("res://scripts/tools/balance_lab.gd")


func _initialize() -> void:
	var report := BalanceLab.run_suite()
	assert(report["project"] == "FacelessVoid")
	assert(report["tool"] == "Balance Lab")
	assert(["pass", "warn"].has(report["status"]))
	assert(report["status_counts"]["pass"] >= 24)
	assert(report["status_counts"]["fail"] == 0)
	assert(report["scenario_count"] >= 11)
	assert(report["mechanics_count"] >= 30)
	assert(report["seed_count"] >= 1400)
	assert(report["status_semantics"].has("pass"))
	assert(report["status_semantics"].has("warn"))
	assert(report["status_semantics"].has("fail"))
	assert(report["mechanics"].size() >= 10)
	assert(report["scenarios"].size() >= 6)
	var mechanic_ids := []
	for mechanic in report["mechanics"]:
		mechanic_ids.append(mechanic["id"])
		assert(mechanic["status"] == "pass")
	assert(mechanic_ids.has("generated_route_economy_notices"))
	assert(mechanic_ids.has("generated_route_preview_sparse"))
	assert(mechanic_ids.has("generated_route_rewards_present"))
	assert(mechanic_ids.has("generated_route_pressure_overflow"))
	assert(mechanic_ids.has("generated_route_completed_pressure_changes"))
	assert(mechanic_ids.has("generated_route_axis_diversity"))
	assert(mechanic_ids.has("generated_route_template_coverage"))
	assert(mechanic_ids.has("generated_route_captain_node_coverage"))
	assert(mechanic_ids.has("generated_route_branch_intent_coverage"))
	assert(mechanic_ids.has("generated_route_t5_detour_gauntlet_coverage"))
	assert(mechanic_ids.has("generated_route_t6_wide_fork_coverage"))
	assert(mechanic_ids.has("generated_route_t7_boss_approach_coverage"))
	assert(mechanic_ids.has("generated_route_blended_progression"))
	assert(mechanic_ids.has("generated_route_archetype_coverage"))
	assert(mechanic_ids.has("generated_route_modifier_coverage"))
	assert(mechanic_ids.has("generated_route_elite_variant_coverage"))
	assert(mechanic_ids.has("generated_route_boss_variant_coverage"))
	for id in [
		"wyvern_base_elemental_damage",
		"wyvern_elemental_multiplier",
		"wyvern_decay_chance",
		"wyvern_tick_interval",
		"bandit_physical_multiplier",
		"bandit_crit_chance",
		"bandit_gold_rewards",
		"bandit_gold_scaling",
		"umbral_crit_chance",
		"umbral_crit_multiplier",
		"umbral_elemental_proc_chance",
		"umbral_unlocks_death_strike",
		"mithril_attack_speed",
		"mithril_crit_chance",
		"mithril_shred_chance",
		"mithril_trigger_count",
		"mithril_trigger_chance_stab",
		"mithril_trigger_chance_heavy",
		"bejeweled_base_damage",
		"bejeweled_physical_multiplier",
		"bejeweled_crit_chance",
		"bejeweled_min_cast_proc",
	]:
		assert(mechanic_ids.has(id))

	var scenario_ids := []
	var zero_damage_showcases := {
		"defense_block_stab": true,
		"generated_easy_fortified_normal": true,
	}
	var accepted_warn_scenarios := {
		"bladedancer_contract_watchmen": "M6 T3/T6 retain the legacy Watchmen comparison as diagnostic, not a win-rate gate.",
		"shadow_intrinsic_stab_mouthy": "Legacy unranked Shadow fixture has no Poison fuel; current ranked coverage is p6_full_shadow_test.",
		"shadow_wyvern_poison_mouthy": "Legacy unranked Shadow/Wyvern fixture has no Poison fuel; current gear coverage is p6_mixed_gear_integration_test.",
		"defense_absorb_suppress_poison": "Legacy no-fuel fixture cannot witness Poison absorption; p6_status_interactions_test covers current mitigation.",
	}
	for scenario in report["scenarios"]:
		scenario_ids.append(scenario["id"])
		if scenario["status"] == "warn":
			assert(accepted_warn_scenarios.has(String(scenario["id"])), "Unreviewed diagnostic warning: " + String(scenario["id"]))
			if String(scenario["id"]) in ["shadow_intrinsic_stab_mouthy", "shadow_wyvern_poison_mouthy", "defense_absorb_suppress_poison"]:
				assert(scenario["aggregate"]["poison_damage"]["mean"] == 0.0)
		else:
			assert(scenario["status"] == "pass")
		assert(scenario["aggregate"]["dps"]["count"] == scenario["seed_count"])
		assert(scenario["aggregate"]["dps"]["mean"] > 0.0 or zero_damage_showcases.has(String(scenario["id"])))
		assert(scenario["samples"].size() > 0)
	assert(report["status_counts"]["warn"] == accepted_warn_scenarios.size())
	assert(scenario_ids.has("shadow_intrinsic_stab_mouthy"))
	assert(scenario_ids.has("bejeweled_proc_rate_training_dummy"))
	assert(scenario_ids.has("generated_easy_fortified_normal"))
	assert(scenario_ids.has("generated_medium_warded_normal"))
	assert(scenario_ids.has("generated_hard_nimble_elite"))
	assert(scenario_ids.has("generated_ultra_hexed_devious"))
	assert(scenario_ids.has("generated_nightmare_devious_fortified"))
	for scenario in report["scenarios"]:
		if String(scenario["id"]).begins_with("generated_"):
			_assert_generated_preview_preserved(scenario)

	var output_dir := ProjectSettings.globalize_path("res://reports/balance/test")
	assert(BalanceLab.write_report(report, output_dir))
	assert(FileAccess.file_exists(output_dir + "/results.json"))
	assert(FileAccess.file_exists(output_dir + "/scenario_summary.csv"))
	assert(FileAccess.file_exists(output_dir + "/index.html"))
	var written_report = JSON.parse_string(FileAccess.get_file_as_string(output_dir + "/results.json"))
	assert(typeof(written_report) == TYPE_DICTIONARY)
	for scenario in written_report["scenarios"]:
		if String(scenario["id"]).begins_with("generated_"):
			_assert_generated_preview_preserved(scenario)
	print("Balance Lab test: OK")
	quit()


func _assert_generated_preview_preserved(scenario: Dictionary) -> void:
	assert(scenario["source"] == "runtime_monster_generator")
	assert(not scenario["generated_monster_metadata"].is_empty())
	assert(not scenario["matchup_preview"].is_empty())
	assert(not scenario["balance_model"].is_empty())
	assert(not scenario["encounter_preview"].is_empty())

	var metadata: Dictionary = scenario["generated_monster_metadata"]
	var matchup: Dictionary = scenario["matchup_preview"]
	var encounter_preview: Dictionary = scenario["encounter_preview"]
	assert(metadata["source_seed"] > 0)
	assert((metadata["archetype_ids"] as Array).size() > 0)
	assert((metadata["tags"] as Array).size() > 0)
	assert((metadata["selected_mechanics"] as Array).size() > 0)
	assert((metadata["defense_overrides"] as Dictionary).size() > 0)
	assert((metadata["budget_metadata"] as Dictionary).size() > 0)
	assert((metadata["pressure_metadata"] as Dictionary).size() > 0)
	assert(metadata.has("notices"))
	assert(metadata["notices"] is Array)
	assert(metadata.has("encounter_preview"))
	assert(not (metadata["encounter_preview"] as Dictionary).is_empty())

	assert((matchup["selected_mechanics"] as Array).size() > 0)
	assert((matchup["defense_overrides"] as Dictionary).size() > 0)
	assert((matchup["pressure_metadata"] as Dictionary).size() > 0)
	assert(matchup.has("route_preview"))
	assert(matchup.has("combat_preview"))
	assert(matchup.has("debug_preview"))
	assert(not (matchup["route_preview"] as Dictionary).is_empty())
	assert(not (matchup["combat_preview"] as Dictionary).is_empty())
	assert(not (matchup["debug_preview"] as Dictionary).is_empty())

	assert(encounter_preview.has("contract_map"))
	assert(encounter_preview.has("combat"))
	assert(encounter_preview.has("debug"))
	var contract_map: Dictionary = encounter_preview["contract_map"]
	var combat: Dictionary = encounter_preview["combat"]
	var debug: Dictionary = encounter_preview["debug"]
	assert(contract_map["biome"] == "Balance Lab")
	assert(String(contract_map["monster_name"]).length() > 0)
	assert(String(contract_map["encounter_level"]).length() > 0)
	assert((contract_map["archetype_tags"] as Array).size() > 0)
	assert(not contract_map.has("source_seed"))
	assert(not contract_map.has("budget_metadata"))
	assert(not contract_map.has("pressure_metadata"))
	assert(not contract_map.has("selected_mechanics"))
	assert(String(combat["monster_name"]).length() > 0)
	assert(int(combat["hp"]) > 0)
	assert(int(combat["duration_seconds"]) > 0)
	assert((combat["selected_mechanics"] as Array).size() > 0)
	assert((combat["defense_overrides"] as Dictionary).size() > 0)
	assert(int(debug["source_seed"]) == int(metadata["source_seed"]))
	assert((debug["raw_archetype_ids"] as Array).size() > 0)
	assert((debug["selected_mechanics"] as Array).size() > 0)
	assert((debug["budget_metadata"] as Dictionary).size() > 0)
	assert((debug["pressure_metadata"] as Dictionary).size() > 0)
	assert(debug.has("notices"))
	assert(debug["notices"] is Array)
