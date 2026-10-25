class_name BalanceLab
extends RefCounted

const VERSION := "0.1.0"
const PROJECT_NAME := "FacelessVoid"
const TOOL_NAME := "Balance Lab"
const DEFAULT_SEED_COUNT := 200
const GENERATED_SAMPLE_SEED_COUNT := 40
const IMPORTED_SCENARIO_DIR := "res://data/balance_lab/imported"
const EncounterPreviewFormatterScript := preload("res://scripts/systems/runtime_monster_generator/encounter_preview_formatter.gd")
const ContractRouteGeneratorScript := preload("res://scripts/systems/contract_route_generator/contract_route_generator.gd")
const GENERATED_ROUTE_FORBIDDEN_PREVIEW_KEYS := [
	"source_seed",
	"budget_metadata",
	"pressure_metadata",
	"route_pressure_scale",
	"route_pressure_axes",
	"defense_overrides",
	"selected_mechanics",
	"combat_preview",
	"debug_preview",
	"route_modifier_ids",
	"node_modifier_ids",
	"elite_variant_id",
	"elite_variant_model_version",
	"boss_variant_id",
	"boss_variant_model_version",
]
const GENERATED_ROUTE_BLOCKING_NOTICE_PREFIXES := [
	"pressure_scale_",
	"reward_gear_ahead_of_pressure",
	"early_talent_without_pressure",
	"elite_gold_outpaces_pressure",
	"boss_gold_outpaces_pressure",
	"pressure_axis_",
	"branch_pressure_axis_not_distinct",
	"all_paths_pressure_axis_dominated",
	"low_reward_shortest_path",
]
const STATUS_SEMANTICS := {
	"pass": "Expected mechanics checks or scenario thresholds are within accepted bounds.",
	"warn": "Balance-review signal, usually threshold drift, not necessarily a broken test.",
	"fail": "Mechanics, resource, runner, or hard correctness failure that needs investigation.",
}


static func run_suite() -> Dictionary:
	var report := {
		"version": VERSION,
		"project": PROJECT_NAME,
		"tool": TOOL_NAME,
		"generated_at": Time.get_datetime_string_from_system(),
		"status_semantics": STATUS_SEMANTICS,
		"source": {
			"runner_script": "res://scripts/tools/run_balance_suite.gd",
			"report_writer": "res://scripts/tools/balance_lab.gd",
			"source_command": "godot --headless --path project -s res://scripts/tools/run_balance_suite.gd",
		},
		"mechanics": _run_mechanics_checks(),
		"scenarios": [],
	}
	for spec in _scenario_specs():
		report["scenarios"].append(_run_scenario(spec))
	_finalize_report_metadata(report)
	return report


static func _finalize_report_metadata(report: Dictionary) -> void:
	var counts := status_counts(report)
	var scenario_count: int = report.get("scenarios", []).size()
	var mechanics_count: int = report.get("mechanics", []).size()
	var seed_count := 0
	for scenario in report.get("scenarios", []):
		seed_count += int(scenario.get("seed_count", 0))
	var overall_status := "pass"
	if int(counts.get("fail", 0)) > 0:
		overall_status = "fail"
	elif int(counts.get("not_ready", 0)) > 0:
		overall_status = "not_ready"
	elif int(counts.get("warn", 0)) > 0:
		overall_status = "warn"
	report["status"] = overall_status
	report["status_counts"] = counts
	report["scenario_count"] = scenario_count
	report["mechanics_count"] = mechanics_count
	report["seed_count"] = seed_count
	report["metadata"] = {
		"project": PROJECT_NAME,
		"tool": TOOL_NAME,
		"version": VERSION,
		"generated_at": report.get("generated_at", ""),
		"status": overall_status,
		"status_counts": counts,
		"scenario_count": scenario_count,
		"mechanics_count": mechanics_count,
		"seed_count": seed_count,
		"status_semantics": STATUS_SEMANTICS,
		"source": report.get("source", {}),
	}


static func write_report(report: Dictionary, output_dir: String) -> bool:
	DirAccess.make_dir_recursive_absolute(output_dir)
	var json_path := output_dir + "/results.json"
	var csv_path := output_dir + "/scenario_summary.csv"
	var html_path := output_dir + "/index.html"
	return (
		_write_text(json_path, JSON.stringify(report, "\t"))
		and _write_text(csv_path, _scenario_csv(report))
		and _write_text(html_path, _dashboard_html(report))
	)


static func status_counts(report: Dictionary) -> Dictionary:
	var counts := {"pass": 0, "warn": 0, "fail": 0}
	for mechanic in report.get("mechanics", []):
		counts[mechanic.get("status", "fail")] = counts.get(mechanic.get("status", "fail"), 0) + 1
	for scenario in report.get("scenarios", []):
		counts[scenario.get("status", "fail")] = counts.get(scenario.get("status", "fail"), 0) + 1
	return counts


static func run_scenario_spec(spec: Dictionary, registry: BuildContentRegistry = null) -> Dictionary:
	return _run_scenario(spec, registry)


## Each Legendary's checks are gated behind their own resource-load guard, so
## one missing/renamed .tres reports as a single failed check for that item
## instead of crashing the whole suite -- the exact regression Balance Lab
## exists to catch.
static func _run_mechanics_checks() -> Array:
	var rogue: ClassDef = load("res://data/classes/rogue.tres")
	if rogue == null:
		return [_check_result("rogue_resource", "Rogue class resource loads", "fail", "Missing res://data/classes/rogue.tres", {})]

	var results := []
	results.append_array(_bandit_blade_checks(rogue))
	results.append_array(_wyvern_kriss_checks(rogue))
	results.append_array(_mithril_karambit_checks(rogue))
	results.append_array(_umbral_stiletto_checks(rogue))
	results.append_array(_bejeweled_push_dagger_checks(rogue))
	results.append_array(_enemy_defense_checks())
	results.append_array(_generated_route_economy_checks())
	return results


static func _bandit_blade_checks(rogue: ClassDef) -> Array:
	var bandit: GearItem = load("res://data/gear/bandit_blade.tres")
	if bandit == null:
		return [_missing_resource_check("bandit_blade_resource", "Bandit Blade resource loads", "res://data/gear/bandit_blade.tres")]
	var bandit_stats := BuildResolver.resolve_stats(rogue, [], [], [bandit], 100)
	return [
		_numeric_check("bandit_physical_multiplier", "Bandit Blade fixed physical multiplier", bandit_stats.gear_physical_damage_multiplier, 1.2, 0.001),
		_numeric_check("bandit_crit_chance", "Bandit Blade fixed crit chance", bandit_stats.crit_chance, 0.17, 0.001),
		_numeric_check("bandit_gold_rewards", "Bandit Blade fixed gold reward multiplier", bandit_stats.gold_reward_multiplier, 1.3, 0.001),
		_numeric_check("bandit_gold_scaling", "Bandit Blade gold scaling at 100g", bandit_stats.bonus_physical_damage, 10.0, 0.001),
	]


static func _wyvern_kriss_checks(rogue: ClassDef) -> Array:
	var wyvern: GearItem = load("res://data/gear/wyvern_kriss.tres")
	if wyvern == null:
		return [_missing_resource_check("wyvern_kriss_resource", "Wyvern Kriss resource loads", "res://data/gear/wyvern_kriss.tres")]
	var wyvern_stats := BuildResolver.resolve_stats(rogue, [], [], [wyvern])
	return [
		_numeric_check("wyvern_base_elemental_damage", "Wyvern Kriss fixed base elemental damage", wyvern_stats.bonus_base_elemental_damage, 8.0, 0.001),
		_numeric_check("wyvern_elemental_multiplier", "Wyvern Kriss fixed elemental multiplier", wyvern_stats.gear_elemental_damage_multiplier, 1.4, 0.001),
		_numeric_check("wyvern_decay_chance", "Wyvern Kriss fixed decay chance", wyvern_stats.decay_chance, 0.12, 0.001),
		_numeric_check("wyvern_tick_interval", "Wyvern Kriss poison tick interval", wyvern_stats.poison_tick_interval_multiplier, 0.5, 0.001),
	]


static func _mithril_karambit_checks(rogue: ClassDef) -> Array:
	var mithril: GearItem = load("res://data/gear/mithril_karambit.tres")
	if mithril == null:
		return [_missing_resource_check("mithril_karambit_resource", "Mithril Karambit resource loads", "res://data/gear/mithril_karambit.tres")]
	var mithril_stats := BuildResolver.resolve_stats(rogue, [], [], [mithril])
	var results := [
		_numeric_check("mithril_attack_speed", "Mithril Karambit fixed attack speed", mithril_stats.attack_speed, 0.15, 0.001),
		_numeric_check("mithril_crit_chance", "Mithril Karambit fixed crit chance", mithril_stats.crit_chance, 0.20, 0.001),
		_numeric_check("mithril_shred_chance", "Mithril Karambit fixed shred chance", mithril_stats.shred_chance, 0.20, 0.001),
		_numeric_check("mithril_trigger_count", "Mithril Karambit trigger count", float(mithril_stats.triggered_skill_effects.size()), 2.0, 0.001),
	]
	if mithril_stats.triggered_skill_effects.size() >= 2:
		results.append(_numeric_check("mithril_trigger_chance_stab", "Mithril Karambit Stab retrigger chance", mithril_stats.triggered_skill_effects[0].chance, 0.5, 0.001))
		results.append(_numeric_check("mithril_trigger_chance_heavy", "Mithril Karambit Heavy Slash retrigger chance", mithril_stats.triggered_skill_effects[1].chance, 0.5, 0.001))
	return results


static func _umbral_stiletto_checks(rogue: ClassDef) -> Array:
	var umbral: GearItem = load("res://data/gear/umbral_stiletto.tres")
	if umbral == null:
		return [_missing_resource_check("umbral_stiletto_resource", "Umbral Stiletto resource loads", "res://data/gear/umbral_stiletto.tres")]
	var umbral_stats := BuildResolver.resolve_stats(rogue, [], [], [umbral])
	var umbral_skills := BuildResolver.resolve_unlocked_skills(rogue, [], [], [umbral])
	var unlocks_death_strike := false
	for skill in umbral_skills:
		if skill.id == CombatResolver.DEATH_STRIKE_SKILL_ID:
			unlocks_death_strike = true
	return [
		_numeric_check("umbral_crit_chance", "Umbral Stiletto fixed crit chance", umbral_stats.crit_chance, 0.15, 0.001),
		_numeric_check("umbral_crit_multiplier", "Umbral Stiletto fixed crit multiplier", umbral_stats.crit_multiplier, 3.0, 0.001),
		_numeric_check("umbral_elemental_proc_chance", "Umbral Stiletto fixed elemental proc chance", umbral_stats.elemental_proc_chance, 1.0, 0.001),
		_boolean_check("umbral_unlocks_death_strike", "Umbral Stiletto unlocks Death Strike", unlocks_death_strike),
	]


static func _bejeweled_push_dagger_checks(rogue: ClassDef) -> Array:
	var bejeweled: GearItem = load("res://data/gear/bejeweled_push_dagger.tres")
	if bejeweled == null:
		return [_missing_resource_check("bejeweled_push_dagger_resource", "Bejeweled Push Dagger resource loads", "res://data/gear/bejeweled_push_dagger.tres")]
	var bejeweled_stats := BuildResolver.resolve_stats(rogue, [], [], [bejeweled])
	return [
		_numeric_check("bejeweled_base_damage", "Bejeweled Push Dagger fixed base damage", bejeweled_stats.bonus_physical_damage, 8.0, 0.001),
		_numeric_check("bejeweled_physical_multiplier", "Bejeweled Push Dagger fixed physical multiplier", bejeweled_stats.gear_physical_damage_multiplier, 1.2, 0.001),
		_numeric_check("bejeweled_crit_chance", "Bejeweled Push Dagger fixed crit chance", bejeweled_stats.crit_chance, 0.15, 0.001),
		_numeric_check("bejeweled_min_cast_proc", "Bejeweled Push Dagger min-cast proc chance", bejeweled_stats.min_cast_time_proc_chance, 0.2, 0.001),
	]


static func _enemy_defense_checks() -> Array:
	var checks := []

	var block_result := CombatResolver.resolve([_test_physical_skill(10.0, 1000)], _test_player(), _test_monster({"block": 25.0}), 1000, 1)
	checks.append(_numeric_check("enemy_block_clamps_damage", "Enemy Block clamps physical damage", block_result.cast_events[0].physical_damage, 0.0, 0.001))
	checks.append(_numeric_check("enemy_block_records_prevented_damage", "Enemy Block records prevented damage", block_result.cast_events[0].blocked_amount, 10.0, 0.001))

	var crit_player := _test_player()
	crit_player.crit_chance = 1.0
	crit_player.crit_multiplier = 2.0
	var crit_result := CombatResolver.resolve([_test_physical_skill(100.0, 1000)], crit_player, _test_monster({"crit_negation": 0.5}), 1000, 1)
	checks.append(_boolean_check("enemy_crit_negation_keeps_crit", "Enemy Crit Negation preserves crit event", crit_result.cast_events[0].is_crit))
	checks.append(_numeric_check("enemy_crit_negation_reduces_damage", "Enemy Crit Negation reduces crit damage", crit_result.cast_events[0].physical_damage, 100.0, 0.001))

	var dodge_skill := _test_physical_skill(100.0, 500)
	var dodge_poison := PoisonDamageEffect.new()
	dodge_poison.stacks_applied = 1
	dodge_skill.effects.append(dodge_poison)
	var dodge_result := CombatResolver.resolve([dodge_skill], _test_player(), _test_monster({"dodge_chance": 1.0}), 500, 1)
	checks.append(_boolean_check("enemy_dodge_marks_cast", "Enemy Dodge marks dodged casts", dodge_result.cast_events[0].was_dodged))
	checks.append(_numeric_check("enemy_dodge_blocks_attached_poison", "Enemy Dodge prevents attached poison stacks", float(dodge_result.cast_events[0].poison_stacks_applied), 0.0, 0.001))

	var absorb_player := _test_player()
	absorb_player.poison_damage_per_tick = 10.0
	var absorb_result := CombatResolver.resolve([_test_poison_skill(1, 500)], absorb_player, _test_monster({"poison_resistance": 0.5, "absorb": 3.0}), 1000, 1)
	checks.append(_numeric_check("enemy_absorb_after_resistance", "Enemy Absorb reduces magical damage after resistance", absorb_result.tick_events[0].damage, 2.0, 0.001))
	checks.append(_numeric_check("enemy_absorb_records_prevented_damage", "Enemy Absorb records prevented damage", absorb_result.tick_events[0].absorbed_amount, 3.0, 0.001))

	var suppress_player := _test_player()
	suppress_player.poison_damage_per_tick = 10.0
	var suppress_result := CombatResolver.resolve([_test_poison_skill(1, 500)], suppress_player, _test_monster({"suppress": 0.5}), 3100, 1)
	checks.append(_numeric_check("enemy_suppress_tick_interval", "Enemy Suppress increases DOT tick interval", float(suppress_result.tick_events[0].tick_interval_ms), 1500.0, 0.001))
	checks.append(_numeric_check("enemy_suppress_tick_count", "Enemy Suppress reduces DOT tick count", float(suppress_result.tick_events.size()), 2.0, 0.001))

	var cleanse_skill := _test_poison_skill(1, 500)
	var shred := ArmorReductionEffect.new()
	shred.amount = 10
	cleanse_skill.effects.append(shred)
	var cleanse_result := CombatResolver.resolve([cleanse_skill], _test_player(), _test_monster({"armor": 50, "cleanse_threshold": 2}), 1000, 1)
	checks.append(_boolean_check("enemy_cleanse_triggers_on_threshold", "Enemy Cleanse triggers on threshold", cleanse_result.cast_events[1].cleanse_triggered))
	checks.append(_numeric_check("enemy_cleanse_counter_resets", "Enemy Cleanse counter resets after trigger", float(cleanse_result.cast_events[1].cleanse_counter), 0.0, 0.001))

	var normal := CombatResolver.resolve([_test_physical_skill(1.0, 1000)], _test_player(), _test_monster({}), 3000, 1)
	var slowed := CombatResolver.resolve([_test_physical_skill(1.0, 1000)], _test_player(), _test_monster({"slow": 0.5}), 3000, 1)
	checks.append(_numeric_check("enemy_slow_reduces_cast_count", "Enemy Slow reduces player cast count", float(slowed.cast_events.size()), 2.0, 0.001))
	checks.append(_numeric_check("enemy_slow_preserves_unslowed_baseline", "Enemy Slow baseline comparison", float(normal.cast_events.size()), 3.0, 0.001))
	return checks


static func _generated_route_economy_checks() -> Array:
	var checks := []
	var summaries := []
	var blocking_notices := []
	var preview_leaks := []
	var missing_rewards := []
	var pressure_overflow_seen := false
	var completed_pressure_changed := false
	var all_templates := {}
	var all_archetypes := {}
	var all_axes := {}
	var all_route_modifiers := {}
	var all_node_modifiers := {}
	var all_elite_variants := {}
	var all_boss_variants := {}
	var captain_node_seen := false
	var safe_intent_seen := false
	var risky_intent_seen := false
	var high_reward_intent_seen := false
	var elite_detour_intent_seen := false
	var pressure_gauntlet_intent_seen := false
	var captain_heavy_path_seen := false
	var wide_matchup_choice_seen := false
	var fork_rejoin_seen := false
	var boss_approach_seen := false
	var safe_boss_approach_seen := false
	var captain_boss_approach_seen := false
	var elite_boss_approach_seen := false
	var boss_content_promotion_seen := false
	var elite_content_promotion_seen := false
	var captain_content_promotion_seen := false
	var full_hard_band_seen := false
	var nightmare_overcap_seen := false

	for case in _generated_route_economy_cases():
		for seed in case["seeds"]:
			var contract: ContractDef = ContractRouteGeneratorScript.generate(int(seed), case["settings"])
			var notices: PackedStringArray = ContractRouteGeneratorScript.validate(contract)
			var summary := _generated_route_economy_summary(String(case["id"]), int(seed), contract, notices)
			if case.has("baseline_settings"):
				var baseline: ContractDef = ContractRouteGeneratorScript.generate(int(seed), case["baseline_settings"])
				summary["completed_pressure_changed"] = ContractRouteGeneratorScript.graph_signature(contract) != ContractRouteGeneratorScript.graph_signature(baseline)
			summaries.append(summary)
			pressure_overflow_seen = pressure_overflow_seen or int(summary["max_contract_pressure_tier"]) > 0
			completed_pressure_changed = completed_pressure_changed or bool(summary["completed_pressure_changed"])
			all_templates[String(summary["template_id"])] = true
			for archetype_id in summary["archetypes"]:
				all_archetypes[String(archetype_id)] = true
			for axis in summary["pressure_axes"]:
				all_axes[String(axis)] = true
			for modifier_id in summary["route_modifiers"]:
				all_route_modifiers[String(modifier_id)] = true
			for modifier_id in summary["node_modifiers"]:
				all_node_modifiers[String(modifier_id)] = true
			captain_node_seen = captain_node_seen or int(summary["captain_node_count"]) > 0
			safe_intent_seen = safe_intent_seen or int(summary["safe_intent_node_count"]) > 0
			risky_intent_seen = risky_intent_seen or int(summary["risky_intent_node_count"]) > 0
			high_reward_intent_seen = high_reward_intent_seen or int(summary["high_reward_intent_node_count"]) > 0
			elite_detour_intent_seen = elite_detour_intent_seen or int(summary["elite_detour_node_count"]) > 0
			pressure_gauntlet_intent_seen = pressure_gauntlet_intent_seen or int(summary["pressure_gauntlet_node_count"]) > 0
			captain_heavy_path_seen = captain_heavy_path_seen or bool(summary["captain_heavy_path_seen"])
			wide_matchup_choice_seen = wide_matchup_choice_seen or int(summary["wide_matchup_choice_node_count"]) >= 3
			fork_rejoin_seen = fork_rejoin_seen or bool(summary["fork_rejoin_seen"])
			boss_approach_seen = boss_approach_seen or bool(summary["boss_approach_lane_variation_seen"])
			safe_boss_approach_seen = safe_boss_approach_seen or bool(summary["safe_boss_approach_seen"])
			captain_boss_approach_seen = captain_boss_approach_seen or bool(summary["captain_boss_approach_seen"])
			elite_boss_approach_seen = elite_boss_approach_seen or bool(summary["elite_boss_approach_seen"])
			boss_content_promotion_seen = boss_content_promotion_seen or bool(summary["boss_content_promotion_seen"])
			elite_content_promotion_seen = elite_content_promotion_seen or bool(summary["elite_content_promotion_seen"])
			captain_content_promotion_seen = captain_content_promotion_seen or bool(summary["captain_content_promotion_seen"])
			full_hard_band_seen = full_hard_band_seen or bool(summary["full_hard_band_seen"])
			nightmare_overcap_seen = nightmare_overcap_seen or bool(summary["nightmare_overcap_seen"])
			for variant_id in summary["elite_variants"]:
				all_elite_variants[String(variant_id)] = true
			for variant_id in summary["boss_variants"]:
				all_boss_variants[String(variant_id)] = true
			for notice in notices:
				if _is_generated_route_blocking_notice(String(notice)):
					blocking_notices.append("%s:%d:%s" % [case["id"], int(seed), String(notice)])
			for leak in summary["preview_leaks"]:
				preview_leaks.append("%s:%d:%s" % [case["id"], int(seed), String(leak)])
			if int(summary["missing_reward_count"]) > 0:
				missing_rewards.append("%s:%d:%d" % [case["id"], int(seed), int(summary["missing_reward_count"])])

	checks.append(_check_result(
		"generated_route_economy_notices",
		"Generated route economy samples avoid blocking notices",
		"pass" if blocking_notices.is_empty() else "fail",
		"" if blocking_notices.is_empty() else "; ".join(blocking_notices),
		{"sample_count": summaries.size(), "blocking_notices": blocking_notices, "summaries": summaries}
	))
	checks.append(_check_result(
		"generated_route_preview_sparse",
		"Generated route previews hide debug economy metadata",
		"pass" if preview_leaks.is_empty() else "fail",
		"" if preview_leaks.is_empty() else "; ".join(preview_leaks),
		{"sample_count": summaries.size(), "preview_leaks": preview_leaks}
	))
	checks.append(_check_result(
		"generated_route_rewards_present",
		"Generated combat route nodes have materialized rewards",
		"pass" if missing_rewards.is_empty() else "fail",
		"" if missing_rewards.is_empty() else "; ".join(missing_rewards),
		{"sample_count": summaries.size(), "missing_rewards": missing_rewards}
	))
	checks.append(_check_result(
		"generated_route_pressure_overflow",
		"Generated nightmare/later-contract samples preserve overflow pressure",
		"pass" if pressure_overflow_seen else "fail",
		"" if pressure_overflow_seen else "Expected at least one sampled route with Contract Pressure overflow.",
		{"sample_count": summaries.size(), "overflow_seen": pressure_overflow_seen}
	))
	checks.append(_check_result(
		"generated_route_completed_pressure_changes",
		"Completed-contract pressure changes generated route economy state",
		"pass" if completed_pressure_changed else "fail",
		"" if completed_pressure_changed else "Expected completed-contract pressure comparison to change materialized difficulty or rewards.",
		{"sample_count": summaries.size(), "completed_pressure_changed": completed_pressure_changed}
	))
	checks.append(_check_result(
		"generated_route_axis_diversity",
		"Generated route samples cover every pressure axis",
		"pass" if _contains_all_ids(all_axes, ContractRouteGeneratorScript.PRESSURE_AXIS_LABELS.keys()) else "fail",
		"" if _contains_all_ids(all_axes, ContractRouteGeneratorScript.PRESSURE_AXIS_LABELS.keys()) else "Expected every pressure axis across generated route samples.",
		{"axis_count": all_axes.size(), "axes": all_axes.keys(), "missing_axes": _missing_ids(all_axes, ContractRouteGeneratorScript.PRESSURE_AXIS_LABELS.keys())}
	))
	checks.append(_check_result(
		"generated_route_template_coverage",
		"Generated route samples cover every route template",
		"pass" if all_templates.size() >= ContractRouteGeneratorScript.TEMPLATES.size() else "fail",
		"" if all_templates.size() >= ContractRouteGeneratorScript.TEMPLATES.size() else "Expected every route template across generated route samples.",
		{"template_count": all_templates.size(), "templates": all_templates.keys()}
	))
	checks.append(_check_result(
		"generated_route_captain_node_coverage",
		"Generated route samples include Captain combat nodes",
		"pass" if captain_node_seen else "fail",
		"" if captain_node_seen else "Expected at least one generated route sample with a Captain node.",
		{"sample_count": summaries.size(), "captain_node_seen": captain_node_seen}
	))
	checks.append(_check_result(
		"generated_route_branch_intent_coverage",
		"Generated route samples include safe, risky, and reward-weighted branch intent",
		"pass" if safe_intent_seen and risky_intent_seen and high_reward_intent_seen else "fail",
		"" if safe_intent_seen and risky_intent_seen and high_reward_intent_seen else "Expected sampled generated routes to include safe, risky, and high-reward branch intent.",
		{
			"sample_count": summaries.size(),
			"safe_intent_seen": safe_intent_seen,
			"risky_intent_seen": risky_intent_seen,
			"high_reward_intent_seen": high_reward_intent_seen,
		}
	))
	checks.append(_check_result(
		"generated_route_t5_detour_gauntlet_coverage",
		"Generated route samples include optional elite detours and Captain-heavy pressure gauntlets",
		"pass" if elite_detour_intent_seen and pressure_gauntlet_intent_seen and captain_heavy_path_seen else "fail",
		"" if elite_detour_intent_seen and pressure_gauntlet_intent_seen and captain_heavy_path_seen else "Expected sampled generated routes to include elite detour intent, pressure gauntlet intent, and a Captain-heavy path.",
		{
			"sample_count": summaries.size(),
			"elite_detour_intent_seen": elite_detour_intent_seen,
			"pressure_gauntlet_intent_seen": pressure_gauntlet_intent_seen,
			"captain_heavy_path_seen": captain_heavy_path_seen,
		}
	))
	checks.append(_check_result(
		"generated_route_t6_wide_fork_coverage",
		"Generated route samples include wide matchup choices and fork-rejoin shapes",
		"pass" if wide_matchup_choice_seen and fork_rejoin_seen else "fail",
		"" if wide_matchup_choice_seen and fork_rejoin_seen else "Expected sampled generated routes to include a three-plus wide matchup choice and a structural fork/rejoin.",
		{
			"sample_count": summaries.size(),
			"wide_matchup_choice_seen": wide_matchup_choice_seen,
			"fork_rejoin_seen": fork_rejoin_seen,
		}
	))
	checks.append(_check_result(
		"generated_route_t7_boss_approach_coverage",
		"Generated route samples include distinct boss approach lane variation",
		"pass" if boss_approach_seen and safe_boss_approach_seen and captain_boss_approach_seen and elite_boss_approach_seen else "fail",
		"" if boss_approach_seen and safe_boss_approach_seen and captain_boss_approach_seen and elite_boss_approach_seen else "Expected sampled generated routes to include safe, captain, and elite boss approach lanes.",
		{
			"sample_count": summaries.size(),
			"boss_approach_seen": boss_approach_seen,
			"safe_boss_approach_seen": safe_boss_approach_seen,
			"captain_boss_approach_seen": captain_boss_approach_seen,
			"elite_boss_approach_seen": elite_boss_approach_seen,
		}
	))
	checks.append(_check_result(
		"generated_route_blended_progression",
		"Generated route scaling blends next-band content by boss, elite, and captain roles",
		"pass" if boss_content_promotion_seen and elite_content_promotion_seen and captain_content_promotion_seen and full_hard_band_seen and nightmare_overcap_seen else "fail",
		"" if boss_content_promotion_seen and elite_content_promotion_seen and captain_content_promotion_seen and full_hard_band_seen and nightmare_overcap_seen else "Expected boss, elite, captain, hard-band, and Nightmare-overcap progression samples.",
		{
			"sample_count": summaries.size(),
			"boss_content_promotion_seen": boss_content_promotion_seen,
			"elite_content_promotion_seen": elite_content_promotion_seen,
			"captain_content_promotion_seen": captain_content_promotion_seen,
			"full_hard_band_seen": full_hard_band_seen,
			"nightmare_overcap_seen": nightmare_overcap_seen,
		}
	))
	checks.append(_check_result(
		"generated_route_archetype_coverage",
		"Generated route samples cover expanded archetype identities",
		"pass" if _contains_all_ids(all_archetypes, ["aegis", "nullify", "spiteful", "riftbound"]) else "fail",
		"" if _contains_all_ids(all_archetypes, ["aegis", "nullify", "spiteful", "riftbound"]) else "Expected all P4M8 expanded archetypes across generated route samples.",
		{"archetype_count": all_archetypes.size(), "archetypes": all_archetypes.keys(), "missing_archetypes": _missing_ids(all_archetypes, ["aegis", "nullify", "spiteful", "riftbound"])}
	))
	checks.append(_check_result(
		"generated_route_modifier_coverage",
		"Generated route samples cover every generated modifier",
		"pass" if _contains_all_ids(all_route_modifiers, _catalog_ids(ContractRouteGeneratorScript.MODIFIER_CATALOG)) else "fail",
		"" if _contains_all_ids(all_route_modifiers, _catalog_ids(ContractRouteGeneratorScript.MODIFIER_CATALOG)) else "Expected every generated modifier across generated route samples.",
		{"modifier_count": all_route_modifiers.size(), "route_modifiers": all_route_modifiers.keys(), "node_modifiers": all_node_modifiers.keys(), "missing_modifiers": _missing_ids(all_route_modifiers, _catalog_ids(ContractRouteGeneratorScript.MODIFIER_CATALOG))}
	))
	checks.append(_check_result(
		"generated_route_elite_variant_coverage",
		"Generated route samples cover every elite variant",
		"pass" if _contains_all_ids(all_elite_variants, _catalog_ids(ContractRouteGeneratorScript.ELITE_VARIANT_CATALOG)) else "fail",
		"" if _contains_all_ids(all_elite_variants, _catalog_ids(ContractRouteGeneratorScript.ELITE_VARIANT_CATALOG)) else "Expected every elite variant across generated route samples.",
		{"variant_count": all_elite_variants.size(), "elite_variants": all_elite_variants.keys(), "missing_elite_variants": _missing_ids(all_elite_variants, _catalog_ids(ContractRouteGeneratorScript.ELITE_VARIANT_CATALOG))}
	))
	checks.append(_check_result(
		"generated_route_boss_variant_coverage",
		"Generated route samples cover every boss variant",
		"pass" if _contains_all_ids(all_boss_variants, _catalog_ids(ContractRouteGeneratorScript.BOSS_VARIANT_CATALOG)) else "fail",
		"" if _contains_all_ids(all_boss_variants, _catalog_ids(ContractRouteGeneratorScript.BOSS_VARIANT_CATALOG)) else "Expected every boss variant across generated route samples.",
		{"variant_count": all_boss_variants.size(), "boss_variants": all_boss_variants.keys(), "missing_boss_variants": _missing_ids(all_boss_variants, _catalog_ids(ContractRouteGeneratorScript.BOSS_VARIANT_CATALOG))}
	))
	return checks


static func _generated_route_economy_cases() -> Array:
	return [
		{
			"id": "route_default_medium",
			"settings": {"route_difficulty": "medium"},
			"seeds": range(4301, 4311),
		},
		{
			"id": "route_hard_later_contract",
			"settings": {"route_difficulty": "hard", "completed_contract_count": 3, "allowed_biomes": ["Cave", "Graveyard"]},
			"seeds": range(4311, 4321),
		},
		{
			"id": "route_nightmare_overflow",
			"settings": {"route_difficulty": "nightmare", "completed_contract_count": 3, "allowed_biomes": ["Haunted Forest", "Ruined Keep", "Ancient Ruins"]},
			"seeds": range(4321, 4331),
		},
		{
			"id": "route_swamp_biome_skew",
			"settings": {"route_difficulty": "medium", "allowed_biomes": ["Swamp"]},
			"seeds": range(4331, 4341),
		},
		{
			"id": "route_completed_pressure_compare",
			"settings": {"route_difficulty": "medium", "completed_contract_count": 3, "allowed_biomes": ["Swamp", "Cave"]},
			"baseline_settings": {"route_difficulty": "medium", "completed_contract_count": 0, "allowed_biomes": ["Swamp", "Cave"]},
			"seeds": [4341],
		},
		{
			"id": "route_medium_stage_five_blend",
			"settings": {"route_difficulty": "medium", "completed_contract_count": 4, "allowed_biomes": ["Swamp", "Cave"]},
			"seeds": range(4342, 4348),
		},
		{
			"id": "route_medium_to_hard_band",
			"settings": {"route_difficulty": "medium", "completed_contract_count": 5, "allowed_biomes": ["Cave", "Graveyard"]},
			"seeds": range(4348, 4354),
		},
	]


static func _generated_route_economy_summary(case_id: String, seed: int, contract: ContractDef, notices: PackedStringArray) -> Dictionary:
	var nodes := _route_nodes(contract.offer_node)
	var max_raw_difficulty := 0
	var max_contract_pressure := 0
	var total_gold := 0
	var min_gold := 999999
	var max_gold := 0
	var highest_gear_tier := 0
	var talent_points := 0
	var missing_reward_count := 0
	var preview_leaks := []
	var archetypes := {}
	var axes := {}
	var route_modifiers := {}
	var node_modifiers := {}
	var elite_variants := {}
	var boss_variants := {}
	var captain_node_count := 0
	var safe_intent_node_count := 0
	var risky_intent_node_count := 0
	var high_reward_intent_node_count := 0
	var elite_detour_node_count := 0
	var pressure_gauntlet_node_count := 0
	var wide_matchup_choice_node_count := 0
	var fork_rejoin_node_count := 0
	var boss_approach_node_count := 0
	var safe_boss_approach_seen := false
	var captain_boss_approach_seen := false
	var elite_boss_approach_seen := false
	var boss_content_promotion_seen := false
	var elite_content_promotion_seen := false
	var captain_content_promotion_seen := false
	var full_hard_band_seen := false
	var nightmare_overcap_seen := false
	for modifier_id in contract.generated_modifier_ids:
		route_modifiers[String(modifier_id)] = true
	for node in nodes:
		if node.node_type == ContractRouteNode.NodeType.START:
			continue
		for key in GENERATED_ROUTE_FORBIDDEN_PREVIEW_KEYS:
			if node.route_preview.has(String(key)):
				preview_leaks.append("%s:%s" % [node.generated_node_id, String(key)])
		if node.reward == null:
			missing_reward_count += 1
		else:
			total_gold += node.reward.gold_amount
			min_gold = mini(min_gold, node.reward.gold_amount)
			max_gold = maxi(max_gold, node.reward.gold_amount)
			highest_gear_tier = maxi(highest_gear_tier, int(node.reward.generated_gear_tier))
			talent_points += node.reward.talent_points
		var scale: Dictionary = node.generated_encounter_payload.get("route_pressure_scale", {})
		max_raw_difficulty = maxi(max_raw_difficulty, int(scale.get("raw_difficulty_id", 0)))
		max_contract_pressure = maxi(max_contract_pressure, int(scale.get("contract_pressure_tier", 0)))
		var promotion_reason := String(scale.get("content_promotion_reason", ""))
		boss_content_promotion_seen = boss_content_promotion_seen or promotion_reason == "stage_3_boss_next_band"
		elite_content_promotion_seen = elite_content_promotion_seen or promotion_reason == "stage_4_elite_next_band"
		captain_content_promotion_seen = captain_content_promotion_seen or promotion_reason == "stage_5_captain_next_band"
		full_hard_band_seen = full_hard_band_seen or (
			int(scale.get("effective_contract_difficulty_id", 0)) >= 3
			and int(scale.get("contract_progression_stage", 0)) == 1
			and int(scale.get("content_difficulty_id", 0)) >= 3
		)
		nightmare_overcap_seen = nightmare_overcap_seen or (
			String(scale.get("effective_contract_difficulty_label", "")) == "nightmare"
			and int(scale.get("overcap_pressure", 0)) > 0
		)
		var profile: Dictionary = node.generated_encounter_payload.get("route_pressure_axes", {})
		for axis in profile.get("axes", []):
			axes[String(axis)] = true
		for archetype_id in node.generated_encounter_payload.get("archetype_ids", []):
			archetypes[String(archetype_id)] = true
		for modifier_id in node.generated_modifier_ids:
			node_modifiers[String(modifier_id)] = true
		if node.node_type == ContractRouteNode.NodeType.CAPTAIN:
			captain_node_count += 1
		if node.branch_intent_tags.has("safe"):
			safe_intent_node_count += 1
		if node.branch_intent_tags.has("risky"):
			risky_intent_node_count += 1
		if node.branch_intent_tags.has("high_reward"):
			high_reward_intent_node_count += 1
		if node.branch_intent_tags.has("elite_detour"):
			elite_detour_node_count += 1
		if node.branch_intent_tags.has("pressure_gauntlet"):
			pressure_gauntlet_node_count += 1
		if node.branch_intent_tags.has("wide_matchup_choice"):
			wide_matchup_choice_node_count += 1
		if node.branch_intent_tags.has("fork_rejoin"):
			fork_rejoin_node_count += 1
		if node.branch_intent_tags.has("boss_approach"):
			boss_approach_node_count += 1
		safe_boss_approach_seen = safe_boss_approach_seen or node.branch_intent_tags.has("safe_boss_approach")
		captain_boss_approach_seen = captain_boss_approach_seen or node.branch_intent_tags.has("captain_boss_approach")
		elite_boss_approach_seen = elite_boss_approach_seen or node.branch_intent_tags.has("elite_boss_approach")
		if node.node_type == ContractRouteNode.NodeType.ELITE:
			elite_variants[node.elite_variant_id] = true
		if node.node_type == ContractRouteNode.NodeType.BOSS:
			boss_variants[node.boss_variant_id] = true
	if min_gold == 999999:
		min_gold = 0
	return {
		"case_id": case_id,
		"seed": seed,
		"notice_count": notices.size(),
		"notices": Array(notices),
		"max_raw_difficulty": max_raw_difficulty,
		"max_contract_pressure_tier": max_contract_pressure,
		"total_gold": total_gold,
		"min_gold": min_gold,
		"max_gold": max_gold,
		"highest_gear_tier": highest_gear_tier,
		"talent_points": talent_points,
		"template_id": String(contract.route_settings.get("template_id", "")),
		"template_display_label": contract.template_display_label,
		"template_width_summary": contract.template_width_summary.duplicate(true),
		"captain_node_count": captain_node_count,
		"safe_intent_node_count": safe_intent_node_count,
		"risky_intent_node_count": risky_intent_node_count,
		"high_reward_intent_node_count": high_reward_intent_node_count,
		"elite_detour_node_count": elite_detour_node_count,
		"pressure_gauntlet_node_count": pressure_gauntlet_node_count,
		"wide_matchup_choice_node_count": wide_matchup_choice_node_count,
		"fork_rejoin_node_count": fork_rejoin_node_count,
		"boss_approach_node_count": boss_approach_node_count,
		"boss_approach_lane_variation_seen": _boss_approach_lane_variation_seen(contract),
		"safe_boss_approach_seen": safe_boss_approach_seen,
		"captain_boss_approach_seen": captain_boss_approach_seen,
		"elite_boss_approach_seen": elite_boss_approach_seen,
		"boss_content_promotion_seen": boss_content_promotion_seen,
		"elite_content_promotion_seen": elite_content_promotion_seen,
		"captain_content_promotion_seen": captain_content_promotion_seen,
		"full_hard_band_seen": full_hard_band_seen,
		"nightmare_overcap_seen": nightmare_overcap_seen,
		"captain_heavy_path_seen": _captain_heavy_path_seen(contract),
		"fork_rejoin_seen": _fork_rejoin_seen(contract),
		"archetypes": archetypes.keys(),
		"pressure_axes": axes.keys(),
		"route_modifiers": route_modifiers.keys(),
		"node_modifiers": node_modifiers.keys(),
		"elite_variants": elite_variants.keys(),
		"boss_variants": boss_variants.keys(),
		"missing_reward_count": missing_reward_count,
		"preview_leaks": preview_leaks,
		"completed_pressure_changed": false,
	}


static func _is_generated_route_blocking_notice(notice: String) -> bool:
	for prefix in GENERATED_ROUTE_BLOCKING_NOTICE_PREFIXES:
		if notice.begins_with(String(prefix)):
			return true
	return false


static func _catalog_ids(catalog: Array) -> Array:
	var ids := []
	for entry in catalog:
		ids.append(String((entry as Dictionary).get("id", "")))
	return ids


static func _contains_all_ids(seen: Dictionary, expected: Array) -> bool:
	return _missing_ids(seen, expected).is_empty()


static func _missing_ids(seen: Dictionary, expected: Array) -> Array:
	var missing := []
	for id in expected:
		if not seen.has(String(id)):
			missing.append(String(id))
	return missing


static func _captain_heavy_path_seen(contract: ContractDef) -> bool:
	if contract == null or contract.offer_node == null:
		return false
	var nodes := _route_nodes(contract.offer_node)
	if nodes.is_empty():
		return false
	var paths := _route_paths_from(contract.offer_node, nodes[nodes.size() - 1], {}, [])
	for path in paths:
		if _path_captain_count(path) >= 2:
			return true
	return false


static func _fork_rejoin_seen(contract: ContractDef) -> bool:
	if contract == null or contract.offer_node == null:
		return false
	var nodes := _route_nodes(contract.offer_node)
	if nodes.is_empty():
		return false
	var boss: ContractRouteNode = nodes[nodes.size() - 1]
	for node in nodes:
		if node.next_nodes.size() < 2:
			continue
		var branch_reach_sets := []
		for next_node in node.next_nodes:
			branch_reach_sets.append(_reachable_route_node_ids_before_boss(next_node, boss))
		for i in range(branch_reach_sets.size()):
			for j in range(i + 1, branch_reach_sets.size()):
				for reached_id in branch_reach_sets[i]:
					if reached_id != boss.generated_node_id and (branch_reach_sets[j] as Dictionary).has(reached_id):
						return true
	return false


static func _boss_approach_lane_variation_seen(contract: ContractDef) -> bool:
	if contract == null or contract.offer_node == null:
		return false
	var nodes := _route_nodes(contract.offer_node)
	if nodes.is_empty():
		return false
	var boss: ContractRouteNode = nodes[nodes.size() - 1]
	var approach_count := 0
	var roles := {}
	for node in nodes:
		if node == null or not node.branch_intent_tags.has("boss_approach"):
			continue
		if not node.next_nodes.has(boss):
			continue
		approach_count += 1
		if node.branch_intent_tags.has("safe_boss_approach"):
			roles["safe"] = true
		if node.branch_intent_tags.has("captain_boss_approach"):
			roles["captain"] = true
		if node.branch_intent_tags.has("elite_boss_approach"):
			roles["elite"] = true
	return approach_count >= 2 and roles.size() >= 2


static func _reachable_route_node_ids_before_boss(start: ContractRouteNode, boss: ContractRouteNode) -> Dictionary:
	var reached := {}
	_collect_reachable_route_node_ids_before_boss(start, boss, {}, reached)
	return reached


static func _collect_reachable_route_node_ids_before_boss(
	node: ContractRouteNode,
	boss: ContractRouteNode,
	visited: Dictionary,
	reached: Dictionary
) -> void:
	if node == null or visited.has(node.generated_node_id):
		return
	visited[node.generated_node_id] = true
	reached[node.generated_node_id] = true
	if node == boss:
		return
	for next_node in node.next_nodes:
		_collect_reachable_route_node_ids_before_boss(next_node, boss, visited, reached)


static func _route_paths_from(node: ContractRouteNode, boss: ContractRouteNode, visited: Dictionary, path: Array) -> Array:
	if node == null or visited.has(node.generated_node_id):
		return []
	var next_path := path.duplicate()
	next_path.append(node)
	if node == boss:
		return [next_path]
	var next_visited := visited.duplicate()
	next_visited[node.generated_node_id] = true
	var paths := []
	for next_node in node.next_nodes:
		paths.append_array(_route_paths_from(next_node, boss, next_visited, next_path))
	return paths


static func _path_captain_count(path: Array) -> int:
	var count := 0
	for node in path:
		if node != null and node.node_type == ContractRouteNode.NodeType.CAPTAIN:
			count += 1
	return count


static func _route_nodes(start: ContractRouteNode) -> Array[ContractRouteNode]:
	var result: Array[ContractRouteNode] = []
	_collect_route_nodes(start, {}, result)
	result.sort_custom(func(a: ContractRouteNode, b: ContractRouteNode): return a.depth < b.depth if a.depth != b.depth else a.lane < b.lane)
	return result


static func _collect_route_nodes(node: ContractRouteNode, visited: Dictionary, result: Array[ContractRouteNode]) -> void:
	if node == null or visited.has(node.generated_node_id):
		return
	visited[node.generated_node_id] = true
	result.append(node)
	for next_node in node.next_nodes:
		_collect_route_nodes(next_node, visited, result)


static func _scenario_specs() -> Array:
	var specs := [
		{
			"id": "baseline_rogue_stab_mouthy",
			"label": "Baseline Rogue Stab vs Mouthy Drunk",
			"class": "res://data/classes/rogue.tres",
			"trees": [],
			"talents": [],
			"gear": [],
			"skills": ["res://data/skills/stab.tres"],
			"monster": "res://data/monsters/mouthy_drunk.tres",
			"duration_ms": 12000,
			"seed_start": 1,
			"seed_count": DEFAULT_SEED_COUNT,
			"gold": 0,
			"thresholds": {"min_mean_dps": 0.6, "max_mean_dps": 0.8},
		},
		{
			"id": "shadow_intrinsic_stab_mouthy",
			"label": "Shadow Intrinsic Stab vs Mouthy Drunk",
			"class": "res://data/classes/rogue.tres",
			"trees": ["res://data/subclass_trees/shadow.tres"],
			"talents": [],
			"gear": [],
			"skills": ["res://data/skills/stab.tres"],
			"monster": "res://data/monsters/mouthy_drunk.tres",
			"duration_ms": 12000,
			"seed_start": 1,
			"seed_count": DEFAULT_SEED_COUNT,
			"gold": 0,
			"thresholds": {"min_mean_poison_damage": 20.0, "min_mean_poison_ticks": 2.0},
		},
		{
			"id": "shadow_wyvern_poison_mouthy",
			"label": "Shadow + Wyvern Poison vs Mouthy Drunk",
			"class": "res://data/classes/rogue.tres",
			"trees": ["res://data/subclass_trees/shadow.tres"],
			"talents": [],
			"gear": ["res://data/gear/wyvern_kriss.tres"],
			"skills": ["res://data/skills/stab.tres", "res://data/skills/heavy_slash.tres"],
			"monster": "res://data/monsters/mouthy_drunk.tres",
			"duration_ms": 12000,
			"seed_start": 1,
			"seed_count": DEFAULT_SEED_COUNT,
			"gold": 0,
			"thresholds": {"min_mean_poison_damage": 60.0, "min_win_rate": 0.95},
		},
		{
			"id": "bandit_blade_gold_scaling",
			"label": "Bandit Blade at 100g vs Mouthy Drunk",
			"class": "res://data/classes/rogue.tres",
			"trees": [],
			"talents": [],
			"gear": ["res://data/gear/bandit_blade.tres"],
			"skills": ["res://data/skills/stab.tres", "res://data/skills/heavy_slash.tres"],
			"monster": "res://data/monsters/mouthy_drunk.tres",
			"duration_ms": 12000,
			"seed_start": 1,
			"seed_count": DEFAULT_SEED_COUNT,
			"gold": 100,
			"thresholds": {"min_mean_dps": 20.0, "min_win_rate": 0.98},
		},
		{
			"id": "bejeweled_proc_rate_training_dummy",
			"label": "Bejeweled Proc Rate vs Training Dummy",
			"class": "res://data/classes/rogue.tres",
			"trees": [],
			"talents": [],
			"gear": ["res://data/gear/bejeweled_push_dagger.tres"],
			"skills": ["res://data/skills/stab.tres", "res://data/skills/heavy_slash.tres"],
			"monster": "res://data/monsters/training_dummy.tres",
			"duration_ms": 30000,
			"seed_start": 1,
			"seed_count": DEFAULT_SEED_COUNT,
			"gold": 0,
			"thresholds": {"min_proc_rate": 0.14, "max_proc_rate": 0.26},
		},
		{
			"id": "bladedancer_contract_watchmen",
			"label": "Bladedancer Contract Build vs Cloaked Watchmen",
			"class": "res://data/classes/rogue.tres",
			"trees": ["res://data/subclass_trees/shadow.tres", "res://data/subclass_trees/bladedancer.tres"],
			"talents": [
				"res://data/talents/shadow/lingering_venom.tres",
				"res://data/talents/shadow/exposed_weakness.tres",
				"res://data/talents/shadow/black_lotus.tres",
				"res://data/talents/bladedancer/piercing_blades.tres",
				"res://data/talents/bladedancer/practiced_rhythm.tres",
				"res://data/talents/bladedancer/opportunity_strikes.tres"
			],
			"gear": ["res://data/gear/wyvern_kriss.tres"],
			"skills": [
				"res://data/skills/poison_strike.tres",
				"res://data/skills/heavy_slash.tres",
				"res://data/skills/quick_cut.tres",
				"res://data/skills/rending_slash.tres"
			],
			"monster": "res://data/monsters/cloaked_watchmen.tres",
			"duration_ms": 26000,
			"seed_start": 1,
			"seed_count": DEFAULT_SEED_COUNT,
			"gold": 67,
			"thresholds": {"min_win_rate": 0.30, "max_win_rate": 0.95},
		},
		{
			"id": "defense_block_stab",
			"label": "Defense: Block vs Stab",
			"class": "res://data/classes/rogue.tres",
			"trees": [],
			"talents": [],
			"gear": [],
			"skills": ["res://data/skills/stab.tres"],
			"monster": "res://data/monsters/mouthy_drunk.tres",
			"monster_overrides": {"block": 8.0},
			"duration_ms": 12000,
			"seed_start": 1,
			"seed_count": DEFAULT_SEED_COUNT,
			"gold": 0,
			"thresholds": {"min_mean_blocked_damage": 8.0},
		},
		{
			"id": "defense_dodge_stab",
			"label": "Defense: Dodge vs Stab",
			"class": "res://data/classes/rogue.tres",
			"trees": [],
			"talents": [],
			"gear": [],
			"skills": ["res://data/skills/stab.tres"],
			"monster": "res://data/monsters/mouthy_drunk.tres",
			"monster_overrides": {"dodge_chance": 0.35},
			"duration_ms": 12000,
			"seed_start": 1,
			"seed_count": DEFAULT_SEED_COUNT,
			"gold": 0,
			"thresholds": {"min_mean_dodges": 1.5, "min_mean_dodge_rate": 0.20},
		},
		{
			"id": "defense_crit_negation_bandit",
			"label": "Defense: Crit Negation vs Bandit Blade",
			"class": "res://data/classes/rogue.tres",
			"trees": [],
			"talents": [],
			"gear": ["res://data/gear/bandit_blade.tres"],
			"skills": ["res://data/skills/stab.tres", "res://data/skills/heavy_slash.tres"],
			"monster": "res://data/monsters/mouthy_drunk.tres",
			"monster_overrides": {"crit_negation": 0.5},
			"duration_ms": 12000,
			"seed_start": 1,
			"seed_count": DEFAULT_SEED_COUNT,
			"gold": 100,
			"thresholds": {"min_mean_crit_negated_damage": 20.0},
		},
		{
			"id": "defense_absorb_suppress_poison",
			"label": "Defense: Absorb + Suppress vs Poison",
			"class": "res://data/classes/rogue.tres",
			"trees": ["res://data/subclass_trees/shadow.tres"],
			"talents": [],
			"gear": ["res://data/gear/wyvern_kriss.tres"],
			"skills": ["res://data/skills/stab.tres", "res://data/skills/heavy_slash.tres"],
			"monster": "res://data/monsters/mouthy_drunk.tres",
			"monster_overrides": {"poison_resistance": 0.25, "absorb": 2.0, "suppress": 0.5},
			"duration_ms": 12000,
			"seed_start": 1,
			"seed_count": DEFAULT_SEED_COUNT,
			"gold": 0,
			"thresholds": {"min_mean_absorbed_damage": 8.0, "min_mean_suppressed_tick_interval_ms": 750.0},
		},
		{
			"id": "defense_cleanse_poison",
			"label": "Defense: Cleanse vs Poison/Shred",
			"class": "res://data/classes/rogue.tres",
			"trees": ["res://data/subclass_trees/shadow.tres"],
			"talents": [],
			"gear": [],
			"skills": ["res://data/skills/stab.tres", "res://data/skills/heavy_slash.tres"],
			"monster": "res://data/monsters/mouthy_drunk.tres",
			"monster_overrides": {"cleanse_threshold": 2},
			"duration_ms": 12000,
			"seed_start": 1,
			"seed_count": DEFAULT_SEED_COUNT,
			"gold": 0,
			"thresholds": {"min_mean_cleanses": 2.0},
		},
		{
			"id": "defense_slow_stab",
			"label": "Defense: Slow vs Stab",
			"class": "res://data/classes/rogue.tres",
			"trees": [],
			"talents": [],
			"gear": [],
			"skills": ["res://data/skills/stab.tres"],
			"monster": "res://data/monsters/mouthy_drunk.tres",
			"monster_overrides": {"slow": 0.5},
			"duration_ms": 12000,
			"seed_start": 1,
			"seed_count": DEFAULT_SEED_COUNT,
			"gold": 0,
			"thresholds": {"max_mean_casts": 6.0},
		},
	]
	specs.append_array(_generated_monster_scenario_specs())
	specs.append_array(imported_scenario_specs_from_dir(IMPORTED_SCENARIO_DIR))
	return specs


static func _generated_monster_scenario_specs() -> Array:
	var library := RuntimeArchetypeLibraryLoader.load_default()
	if library.has_errors():
		return [_invalid_generated_monster_scenario("Runtime archetype library failed to load.")]

	var cases := [
		{
			"id": "generated_easy_fortified_normal",
			"label": "Generated Easy Fortified Normal",
			"seed": 21001,
			"archetype_a": "fortified",
			"difficulty": 1,
			"kind": "normal",
			"tempo": "standard",
			"skills": ["res://data/skills/stab.tres"],
			"trees": [],
			"talents": [],
			"gear": [],
			"gold": 0,
		},
		{
			"id": "generated_medium_warded_normal",
			"label": "Generated Medium Warded Normal",
			"seed": 21002,
			"archetype_a": "warded",
			"difficulty": 2,
			"kind": "normal",
			"tempo": "burst",
			"skills": ["res://data/skills/stab.tres", "res://data/skills/heavy_slash.tres"],
			"trees": ["res://data/subclass_trees/shadow.tres"],
			"talents": [],
			"gear": ["res://data/gear/wyvern_kriss.tres"],
			"gold": 0,
		},
		{
			"id": "generated_hard_nimble_elite",
			"label": "Generated Hard Nimble Elite",
			"seed": 21003,
			"archetype_a": "nimble",
			"difficulty": 3,
			"kind": "elite",
			"tempo": "standard",
			"skills": ["res://data/skills/stab.tres", "res://data/skills/heavy_slash.tres"],
			"trees": [],
			"talents": [],
			"gear": ["res://data/gear/bandit_blade.tres"],
			"gold": 100,
		},
		{
			"id": "generated_ultra_hexed_devious",
			"label": "Generated Ultra Hexed + Devious",
			"seed": 21004,
			"archetype_a": "hexed",
			"archetype_b": "devious",
			"difficulty": 4,
			"kind": "elite",
			"tempo": "extended",
			"skills": ["res://data/skills/poison_strike.tres", "res://data/skills/heavy_slash.tres", "res://data/skills/quick_cut.tres"],
			"trees": ["res://data/subclass_trees/shadow.tres"],
			"talents": [],
			"gear": ["res://data/gear/wyvern_kriss.tres"],
			"gold": 50,
		},
		{
			"id": "generated_nightmare_devious_fortified",
			"label": "Generated Nightmare Devious + Fortified",
			"seed": 21005,
			"archetype_a": "devious",
			"archetype_b": "fortified",
			"difficulty": 5,
			"kind": "boss",
			"tempo": "endurance",
			"skills": ["res://data/skills/poison_strike.tres", "res://data/skills/heavy_slash.tres", "res://data/skills/quick_cut.tres", "res://data/skills/rending_slash.tres"],
			"trees": ["res://data/subclass_trees/shadow.tres", "res://data/subclass_trees/bladedancer.tres"],
			"talents": [
				"res://data/talents/shadow/lingering_venom.tres",
				"res://data/talents/shadow/exposed_weakness.tres",
				"res://data/talents/shadow/black_lotus.tres",
				"res://data/talents/bladedancer/piercing_blades.tres",
				"res://data/talents/bladedancer/practiced_rhythm.tres",
				"res://data/talents/bladedancer/opportunity_strikes.tres"
			],
			"gear": ["res://data/gear/wyvern_kriss.tres"],
			"gold": 100,
		},
	]

	var specs := []
	for case in cases:
		var input := RuntimeGenerationInput.from_dictionary({
			"seed": case["seed"],
			"archetypeA": case["archetype_a"],
			"archetypeB": case.get("archetype_b", ""),
			"difficulty": case["difficulty"],
			"kind": case["kind"],
			"tempoProfile": case["tempo"],
		})
		var draft := RuntimeMonsterGenerator.generate(input, library)
		if draft.has_errors():
			specs.append(_invalid_generated_monster_scenario("Generated sample %s produced hard notices." % case["id"]))
			continue
		var encounter_preview: Dictionary = EncounterPreviewFormatterScript.format_generated(draft, {
			"biome": "Balance Lab",
			"encounter_level": case["kind"],
		})
		specs.append({
			"id": case["id"],
			"label": case["label"],
			"class": "res://data/classes/rogue.tres",
			"trees": _string_array(case.get("trees", [])),
			"talents": _string_array(case.get("talents", [])),
			"gear": _string_array(case.get("gear", [])),
			"skills": _string_array(case.get("skills", [])),
			"monster": draft.id,
			"generated_monster": draft.to_dictionary(),
			"duration_ms": draft.duration_ms,
			"seed_start": int(case["seed"]),
			"seed_count": GENERATED_SAMPLE_SEED_COUNT,
			"gold": int(case.get("gold", 0)),
			"thresholds": {},
			"source": "runtime_monster_generator",
			"source_monster_id": draft.id,
			"encounter_preview": encounter_preview.duplicate(true),
			"matchup_preview": {
				"archetype_ids": _packed_strings_to_array(draft.archetype_ids),
				"tags": _packed_strings_to_array(draft.tags),
				"selected_mechanics": draft.selected_mechanics.duplicate(true),
				"defense_overrides": draft.defense_overrides.duplicate(true),
				"pressure_metadata": draft.pressure_metadata.duplicate(true),
				"route_preview": (encounter_preview["contract_map"] as Dictionary).duplicate(true),
				"combat_preview": (encounter_preview["combat"] as Dictionary).duplicate(true),
				"debug_preview": (encounter_preview["debug"] as Dictionary).duplicate(true),
			},
			"balance_model": {
				"generator_version": RuntimeMonsterGenerator.GENERATOR_VERSION,
				"library_schema": RuntimeArchetypeLibraryLoader.EXPECTED_SCHEMA,
				"difficulty": case["difficulty"],
				"kind": case["kind"],
				"tempo": case["tempo"],
				"source_seed": draft.source_seed,
				"budget_metadata": draft.budget_metadata.duplicate(true),
			},
			"generated_monster_metadata": _generated_monster_metadata(draft, case, encounter_preview),
		})
	return specs


static func _invalid_generated_monster_scenario(message: String) -> Dictionary:
	return {
		"id": "generated_monster_sample_invalid",
		"label": "Generated Monster Sample Invalid",
		"class": "res://missing_generated_monster_sample.tres",
		"trees": [],
		"talents": [],
		"gear": [],
		"skills": [],
		"monster": "generated_monster_sample_invalid",
		"duration_ms": 0,
		"seed_start": 1,
		"seed_count": 0,
		"gold": 0,
		"thresholds": {},
		"source": "runtime_monster_generator",
		"import_notes": [message],
	}


static func imported_scenario_specs_from_dir(import_dir: String) -> Array:
	var dir := DirAccess.open(import_dir)
	if dir == null:
		return []
	var files := []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	files.sort()

	var specs := []
	for scenario_file in files:
		var path := import_dir.path_join(scenario_file)
		var parsed = _read_json_file(path)
		if typeof(parsed) != TYPE_DICTIONARY:
			specs.append(_invalid_imported_scenario(path, "Could not parse imported scenario JSON."))
			continue
		for spec in _normalize_imported_scenario_catalog(parsed, path):
			specs.append(spec)
	return specs


static func _read_json_file(path: String):
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed


static func _normalize_imported_scenario_catalog(catalog: Dictionary, path: String) -> Array:
	var scenarios = catalog.get("scenarios", [])
	if typeof(scenarios) != TYPE_ARRAY:
		return [_invalid_imported_scenario(path, "Imported scenario catalog is missing a scenarios array.")]
	var specs := []
	for index in range(scenarios.size()):
		var scenario = scenarios[index]
		if typeof(scenario) != TYPE_DICTIONARY:
			specs.append(_invalid_imported_scenario(path, "Imported scenario entry %d is not an object." % index))
			continue
		specs.append(_normalize_imported_scenario(scenario, catalog, path, index))
	return specs


static func _normalize_imported_scenario(scenario: Dictionary, catalog: Dictionary, path: String, index: int) -> Dictionary:
	var fallback_id := "%s_%d" % [path.get_file().get_basename().to_snake_case(), index + 1]
	var spec := {
		"id": str(scenario.get("id", fallback_id)).to_snake_case(),
		"label": str(scenario.get("label", "Imported Monster Lab Scenario")),
		"class": str(scenario.get("class", "res://data/classes/rogue.tres")),
		"trees": _string_array(scenario.get("trees", [])),
		"talents": _string_array(scenario.get("talents", [])),
		"gear": _string_array(scenario.get("gear", [])),
		"skills": _string_array(scenario.get("skills", ["res://data/skills/stab.tres"])),
		"monster": str(scenario.get("monster", "res://data/monsters/mouthy_drunk.tres")),
		"monster_overrides": _dictionary_value(scenario.get("monster_overrides", {})),
		"duration_ms": int(scenario.get("duration_ms", 12000)),
		"seed_start": int(scenario.get("seed_start", 1)),
		"seed_count": int(scenario.get("seed_count", 40)),
		"gold": int(scenario.get("gold", 0)),
		"thresholds": _dictionary_value(scenario.get("thresholds", {})),
		"source": str(scenario.get("source", catalog.get("tool", "imported"))),
		"source_file": path,
		"source_monster_id": str(scenario.get("source_monster_id", catalog.get("source_monster_id", ""))),
		"matchup_preview": _dictionary_value(scenario.get("matchup_preview", catalog.get("matchup_preview", {}))),
		"balance_model": _dictionary_value(scenario.get("balance_model", catalog.get("balance_model", {}))),
		"import_notes": _string_array(scenario.get("notes", [])),
	}
	return spec


static func _invalid_imported_scenario(path: String, message: String) -> Dictionary:
	return {
		"id": "invalid_import_%s" % path.get_file().get_basename().to_snake_case(),
		"label": "Invalid imported Balance Lab scenario",
		"class": "res://missing_imported_scenario.tres",
		"trees": [],
		"talents": [],
		"gear": [],
		"skills": [],
		"monster": "res://missing_imported_scenario.tres",
		"duration_ms": 0,
		"seed_count": 0,
		"source": "imported",
		"source_file": path,
		"import_notes": [message],
	}


static func _string_array(value) -> Array:
	if typeof(value) != TYPE_ARRAY:
		return []
	var output := []
	for entry in value:
		output.append(str(entry))
	return output


static func _dictionary_value(value) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return value
	return {}


static func _packed_strings_to_array(values: PackedStringArray) -> Array:
	var output := []
	for value in values:
		output.append(value)
	return output


static func _generated_monster_metadata(draft: GeneratedMonsterDraft, case: Dictionary, encounter_preview: Dictionary = {}) -> Dictionary:
	var notice_data := []
	for notice in draft.notices:
		notice_data.append(notice.to_dictionary())
	return {
		"id": draft.id,
		"display_name": draft.display_name,
		"source_seed": draft.source_seed,
		"source_input": draft.source_input.to_dictionary() if draft.source_input != null else {},
		"archetype_ids": _packed_strings_to_array(draft.archetype_ids),
		"tags": _packed_strings_to_array(draft.tags),
		"difficulty": case.get("difficulty", 0),
		"kind": draft.monster_kind,
		"tempo": case.get("tempo", ""),
		"selected_mechanics": draft.selected_mechanics.duplicate(true),
		"defense_overrides": draft.defense_overrides.duplicate(true),
		"budget_metadata": draft.budget_metadata.duplicate(true),
		"pressure_metadata": draft.pressure_metadata.duplicate(true),
		"notices": notice_data,
		"encounter_preview": encounter_preview.duplicate(true),
	}


static func _run_scenario(spec: Dictionary, registry: BuildContentRegistry = null) -> Dictionary:
	var decoded := {}
	if spec.has("ranked_build"):
		if registry == null:
			registry = BuildContentRegistry.current()
		if registry.mode != "ranked" or registry.validate_ranked() != "":
			var unavailable := _failed_scenario_result(spec, "Ranked content is not ready; no simulation was run.")
			unavailable["status"] = "not_ready"
			return unavailable
		decoded = BuildSaveCodec.decode(spec.ranked_build, registry)
		if decoded.error != "" or decoded.get("model") == null:
			return _failed_scenario_result(spec, "Invalid ranked build: " + decoded.get("error", "Missing primary tree."))
	var class_def: ClassDef = decoded["class"] if not decoded.is_empty() else load(spec["class"])
	var monster: Monster = null
	if spec.has("generated_monster"):
		var draft := GeneratedMonsterDraft.from_dictionary(_dictionary_value(spec["generated_monster"]))
		monster = draft.to_monster()
	else:
		monster = load(spec["monster"])
	if class_def == null or monster == null:
		var missing_path: String = spec["class"] if class_def == null else spec["monster"]
		return _failed_scenario_result(spec, "Missing resource: %s" % missing_path)
	monster = _monster_with_overrides(monster, spec.get("monster_overrides", {}))

	var trees := _load_trees(spec.get("trees", []))
	var talents := _load_talents(spec.get("talents", []))
	var gear := _load_gear(spec.get("gear", []))
	var requested_skills := _load_skills(spec.get("skills", []))
	var stats := BuildResolver.resolve_stats(class_def, trees, talents, gear, int(spec.get("gold", 0)))
	var unlocked := BuildResolver.resolve_unlocked_skills(class_def, trees, talents, gear)
	var rotation := BuildResolver.resolve_rotation(requested_skills, unlocked)
	var snapshot := {}
	if not decoded.is_empty():
		var resolved := BuildResolver.resolve_ranked_build(class_def, decoded.model, gear, int(spec.get("gold", 0)))
		if resolved.error != "":
			return _failed_scenario_result(spec, resolved.error)
		stats = resolved.stats
		unlocked = resolved.skills
		requested_skills.clear()
		for id in decoded.rotation_ids:
			var requested := Skill.new()
			requested.id = id
			requested_skills.append(requested)
		var normalized := BuildResolver.normalize_rotation(requested_skills, unlocked)
		if not normalized.removed.is_empty() or not normalized.overflow.is_empty() or normalized.rotation.is_empty():
			return _failed_scenario_result(spec, "Ranked scenario requires an available, nonempty rotation of at most ten slots.")
		rotation = normalized.rotation
		snapshot = {"build": spec.ranked_build.duplicate(true), "content_revision": registry.revision,
			"class": _resource_snapshot(class_def), "trees": [], "gear": [],
			"monster": _resource_snapshot(monster), "skills": []}
		for tree in decoded.trees:
			snapshot.trees.append(_resource_snapshot(tree))
		for item in gear:
			snapshot.gear.append(_resource_snapshot(item))
		for skill in rotation:
			snapshot.skills.append(_resource_snapshot(skill))

	var outcomes := []
	var dps_values := []
	var total_values := []
	var poison_values := []
	var physical_values := []
	var poison_tick_counts := []
	var proc_rates := []
	var cast_counts := []
	var dodge_values := []
	var dodge_rates := []
	var blocked_values := []
	var crit_negated_values := []
	var absorbed_values := []
	var cleanse_values := []
	var suppressed_tick_interval_values := []
	var win_count := 0
	var seed_start := int(spec.get("seed_start", 1))
	var seed_count := int(spec.get("seed_count", DEFAULT_SEED_COUNT))
	for offset in range(seed_count):
		var seed := seed_start + offset
		var result := CombatResolver.resolve(rotation, stats, monster, int(spec["duration_ms"]), seed)
		if not result.is_valid:
			return _failed_scenario_result(spec, "Seed %d: %s" % [seed, CombatResultFormatter.invalid_simulation_message(result)])
		var summary := _combat_summary(seed, result)
		outcomes.append(summary)
		dps_values.append(summary["dps"])
		total_values.append(summary["total_damage"])
		poison_values.append(summary["poison_damage"])
		physical_values.append(summary["physical_damage"])
		poison_tick_counts.append(summary["poison_damage_ticks"])
		proc_rates.append(summary["min_cast_proc_rate"])
		cast_counts.append(summary["casts"])
		dodge_values.append(summary["dodges"])
		dodge_rates.append(summary["dodge_rate"])
		blocked_values.append(summary["blocked_damage"])
		crit_negated_values.append(summary["crit_negated_damage"])
		absorbed_values.append(summary["absorbed_damage"])
		cleanse_values.append(summary["cleanses"])
		suppressed_tick_interval_values.append(summary["suppressed_tick_interval_ms"])
		if result.is_win:
			win_count += 1

	var aggregate := {
		"dps": _distribution(dps_values),
		"total_damage": _distribution(total_values),
		"physical_damage": _distribution(physical_values),
		"poison_damage": _distribution(poison_values),
		"poison_damage_ticks": _distribution(poison_tick_counts),
		"min_cast_proc_rate": _distribution(proc_rates),
		"casts": _distribution(cast_counts),
		"dodges": _distribution(dodge_values),
		"dodge_rate": _distribution(dodge_rates),
		"blocked_damage": _distribution(blocked_values),
		"crit_negated_damage": _distribution(crit_negated_values),
		"absorbed_damage": _distribution(absorbed_values),
		"cleanses": _distribution(cleanse_values),
		"suppressed_tick_interval_ms": _distribution(suppressed_tick_interval_values),
		"win_rate": float(win_count) / float(maxi(seed_count, 1)),
	}
	var status := _scenario_status(aggregate, spec.get("thresholds", {}))
	return {
		"id": spec["id"],
		"label": spec["label"],
		"status": status["status"],
		"notes": _string_array(spec.get("import_notes", [])) + status["notes"],
		"seed_start": seed_start,
		"seed_count": seed_count,
		"duration_ms": spec["duration_ms"],
		"gold": spec.get("gold", 0),
		"source": spec.get("source", "authored"),
		"source_file": spec.get("source_file", ""),
		"source_monster_id": spec.get("source_monster_id", ""),
		"encounter_preview": spec.get("encounter_preview", {}),
		"matchup_preview": spec.get("matchup_preview", {}),
		"balance_model": spec.get("balance_model", {}),
		"generated_monster_metadata": spec.get("generated_monster_metadata", {}),
		"monster": monster.display_name if monster != null else spec["monster"],
		"monster_overrides": spec.get("monster_overrides", {}),
		"rotation": _skill_names(rotation),
		"gear": _gear_names(gear),
		"thresholds": spec.get("thresholds", {}),
		"aggregate": aggregate,
		"samples": outcomes.slice(0, mini(outcomes.size(), 24)),
		"foundation_snapshot": snapshot,
	}


static func _combat_summary(seed: int, result: CombatResolver.CombatResult) -> Dictionary:
	var physical_damage := 0.0
	var poison_damage := 0.0
	var poison_damage_ticks := 0
	var cast_count := result.cast_events.size()
	var crit_count := 0
	var min_cast_proc_count := 0
	var trigger_count := 0
	var poison_stacks_applied := 0
	var dodges := 0
	var blocked_damage := 0.0
	var crit_negated_damage := 0.0
	var cleanses := 0
	for event in result.cast_events:
		physical_damage += event.physical_damage
		if event.is_crit:
			crit_count += 1
		if event.was_dodged:
			dodges += 1
		if event.min_cast_time_proc_applied:
			min_cast_proc_count += 1
		if event.cleanse_triggered:
			cleanses += 1
		trigger_count += event.triggered_skill_names.size()
		poison_stacks_applied += event.poison_stacks_applied
		blocked_damage += event.blocked_amount
		crit_negated_damage += event.crit_negation_applied
	var absorbed_damage := 0.0
	var suppressed_tick_interval_ms := 0.0
	for tick in result.tick_events:
		suppressed_tick_interval_ms = maxf(suppressed_tick_interval_ms, float(tick.tick_interval_ms))
		absorbed_damage += tick.absorbed_amount
		if tick.damage > 0.0:
			poison_damage += tick.damage
			poison_damage_ticks += 1
	return {
		"seed": seed,
		"win": result.is_win,
		"total_damage": result.total_damage,
		"dps": result.dps,
		"physical_damage": physical_damage,
		"poison_damage": poison_damage,
		"poison_damage_ticks": poison_damage_ticks,
		"casts": cast_count,
		"crit_rate": float(crit_count) / float(maxi(cast_count, 1)),
		"dodges": dodges,
		"dodge_rate": float(dodges) / float(maxi(cast_count, 1)),
		"blocked_damage": blocked_damage,
		"crit_negated_damage": crit_negated_damage,
		"absorbed_damage": absorbed_damage,
		"cleanses": cleanses,
		"suppressed_tick_interval_ms": suppressed_tick_interval_ms,
		"min_cast_proc_rate": float(min_cast_proc_count) / float(maxi(cast_count, 1)),
		"trigger_count": trigger_count,
		"poison_stacks_applied": poison_stacks_applied,
	}


static func _scenario_status(aggregate: Dictionary, thresholds: Dictionary) -> Dictionary:
	var notes := []
	var status := "pass"
	_apply_min_threshold(notes, aggregate["dps"]["mean"], thresholds, "min_mean_dps", "mean DPS")
	_apply_max_threshold(notes, aggregate["dps"]["mean"], thresholds, "max_mean_dps", "mean DPS")
	_apply_min_threshold(notes, aggregate["win_rate"], thresholds, "min_win_rate", "win rate")
	_apply_max_threshold(notes, aggregate["win_rate"], thresholds, "max_win_rate", "win rate")
	_apply_min_threshold(notes, aggregate["poison_damage"]["mean"], thresholds, "min_mean_poison_damage", "mean poison damage")
	_apply_min_threshold(notes, aggregate["poison_damage_ticks"]["mean"], thresholds, "min_mean_poison_ticks", "mean poison damage ticks")
	_apply_min_threshold(notes, aggregate["min_cast_proc_rate"]["mean"], thresholds, "min_proc_rate", "mean min-cast proc rate")
	_apply_max_threshold(notes, aggregate["min_cast_proc_rate"]["mean"], thresholds, "max_proc_rate", "mean min-cast proc rate")
	_apply_min_threshold(notes, aggregate["casts"]["mean"], thresholds, "min_mean_casts", "mean casts")
	_apply_max_threshold(notes, aggregate["casts"]["mean"], thresholds, "max_mean_casts", "mean casts")
	_apply_min_threshold(notes, aggregate["dodges"]["mean"], thresholds, "min_mean_dodges", "mean dodges")
	_apply_min_threshold(notes, aggregate["dodge_rate"]["mean"], thresholds, "min_mean_dodge_rate", "mean dodge rate")
	_apply_min_threshold(notes, aggregate["blocked_damage"]["mean"], thresholds, "min_mean_blocked_damage", "mean blocked damage")
	_apply_min_threshold(notes, aggregate["crit_negated_damage"]["mean"], thresholds, "min_mean_crit_negated_damage", "mean crit-negated damage")
	_apply_min_threshold(notes, aggregate["absorbed_damage"]["mean"], thresholds, "min_mean_absorbed_damage", "mean absorbed damage")
	_apply_min_threshold(notes, aggregate["cleanses"]["mean"], thresholds, "min_mean_cleanses", "mean cleanses")
	_apply_min_threshold(notes, aggregate["suppressed_tick_interval_ms"]["mean"], thresholds, "min_mean_suppressed_tick_interval_ms", "mean suppressed tick interval")
	if not notes.is_empty():
		status = "warn"
	return {"status": status, "notes": notes}


static func _apply_min_threshold(notes: Array, actual: float, thresholds: Dictionary, key: String, label: String) -> void:
	if not thresholds.has(key):
		return
	var expected := float(thresholds[key])
	if actual < expected:
		notes.append("%s %.3f is below %.3f" % [label, actual, expected])


static func _apply_max_threshold(notes: Array, actual: float, thresholds: Dictionary, key: String, label: String) -> void:
	if not thresholds.has(key):
		return
	var expected := float(thresholds[key])
	if actual > expected:
		notes.append("%s %.3f is above %.3f" % [label, actual, expected])


static func _distribution(values: Array) -> Dictionary:
	if values.is_empty():
		return {"count": 0, "mean": 0.0, "min": 0.0, "p05": 0.0, "p50": 0.0, "p95": 0.0, "max": 0.0}
	var sorted := values.duplicate()
	sorted.sort()
	var total := 0.0
	for value in sorted:
		total += float(value)
	return {
		"count": sorted.size(),
		"mean": total / float(sorted.size()),
		"min": sorted[0],
		"p05": _percentile(sorted, 0.05),
		"p50": _percentile(sorted, 0.50),
		"p95": _percentile(sorted, 0.95),
		"max": sorted[sorted.size() - 1],
	}


static func _percentile(sorted_values: Array, p: float) -> float:
	if sorted_values.is_empty():
		return 0.0
	var index := clampi(roundi(float(sorted_values.size() - 1) * p), 0, sorted_values.size() - 1)
	return float(sorted_values[index])


static func _numeric_check(id: String, label: String, actual: float, expected: float, tolerance: float) -> Dictionary:
	var passed := absf(actual - expected) <= tolerance
	return _check_result(id, label, "pass" if passed else "fail", "" if passed else "Expected %.4f, got %.4f" % [expected, actual], {
		"actual": actual,
		"expected": expected,
		"tolerance": tolerance,
	})


static func _boolean_check(id: String, label: String, passed: bool) -> Dictionary:
	return _check_result(id, label, "pass" if passed else "fail", "" if passed else "Expected true, got false", {"actual": passed, "expected": true})


static func _check_result(id: String, label: String, status: String, note: String, values: Dictionary) -> Dictionary:
	return {"id": id, "label": label, "status": status, "note": note, "values": values}


static func _missing_resource_check(id: String, label: String, path: String) -> Dictionary:
	return _check_result(id, label, "fail", "Missing %s" % path, {})


## Same dict shape _run_scenario() would otherwise return, so a missing
## class/monster resource surfaces as one reported "fail" scenario -- with a
## zeroed-out aggregate matching _distribution([])'s shape -- instead of
## crashing report generation or the CSV/HTML writers that read this shape.
static func _failed_scenario_result(spec: Dictionary, message: String) -> Dictionary:
	var empty_aggregate := {
		"dps": _distribution([]),
		"total_damage": _distribution([]),
		"physical_damage": _distribution([]),
		"poison_damage": _distribution([]),
		"poison_damage_ticks": _distribution([]),
		"min_cast_proc_rate": _distribution([]),
		"casts": _distribution([]),
		"dodges": _distribution([]),
		"dodge_rate": _distribution([]),
		"blocked_damage": _distribution([]),
		"crit_negated_damage": _distribution([]),
		"absorbed_damage": _distribution([]),
		"cleanses": _distribution([]),
		"suppressed_tick_interval_ms": _distribution([]),
		"win_rate": 0.0,
	}
	return {
		"id": spec["id"],
		"label": spec["label"],
		"status": "fail",
		"notes": _string_array(spec.get("import_notes", [])) + [message],
		"seed_start": int(spec.get("seed_start", 1)),
		"seed_count": 0,
		"duration_ms": spec.get("duration_ms", 0),
		"gold": spec.get("gold", 0),
		"source": spec.get("source", "authored"),
		"source_file": spec.get("source_file", ""),
		"source_monster_id": spec.get("source_monster_id", ""),
		"encounter_preview": spec.get("encounter_preview", {}),
		"matchup_preview": spec.get("matchup_preview", {}),
		"balance_model": spec.get("balance_model", {}),
		"generated_monster_metadata": spec.get("generated_monster_metadata", {}),
		"monster": spec.get("monster", "generated"),
		"monster_overrides": spec.get("monster_overrides", {}),
		"rotation": [],
		"gear": [],
		"thresholds": spec.get("thresholds", {}),
		"aggregate": empty_aggregate,
		"samples": [],
	}


static func _load_trees(paths: Array) -> Array[SubclassTree]:
	var resources: Array[SubclassTree] = []
	for path in paths:
		var resource: SubclassTree = load(path)
		if resource != null:
			resources.append(resource)
	return resources


static func _load_talents(paths: Array) -> Array[Talent]:
	var resources: Array[Talent] = []
	for path in paths:
		var resource: Talent = load(path)
		if resource != null:
			resources.append(resource)
	return resources


static func _load_gear(paths: Array) -> Array[GearItem]:
	var resources: Array[GearItem] = []
	for path in paths:
		var resource: GearItem = load(path)
		if resource != null:
			resources.append(resource)
	return resources


static func _load_skills(paths: Array) -> Array[Skill]:
	var resources: Array[Skill] = []
	for path in paths:
		var resource: Skill = load(path)
		if resource != null:
			resources.append(resource)
	return resources


static func _monster_with_overrides(source: Monster, overrides: Dictionary) -> Monster:
	var monster: Monster = source.duplicate(true)
	if overrides.is_empty():
		return monster
	if overrides.has("hp"):
		monster.hp = int(overrides["hp"])
	if overrides.has("armor"):
		monster.armor = int(overrides["armor"])
	if overrides.has("poison_resistance"):
		monster.poison_resistance = float(overrides["poison_resistance"])
	if overrides.has("dodge_chance"):
		monster.dodge_chance = float(overrides["dodge_chance"])
	if overrides.has("crit_negation"):
		monster.crit_negation = float(overrides["crit_negation"])
	if overrides.has("block"):
		monster.block = float(overrides["block"])
	if overrides.has("absorb"):
		monster.absorb = float(overrides["absorb"])
	if overrides.has("cleanse_threshold"):
		monster.cleanse_threshold = int(overrides["cleanse_threshold"])
	if overrides.has("suppress"):
		monster.suppress = float(overrides["suppress"])
	if overrides.has("slow"):
		monster.slow = float(overrides["slow"])
	if overrides.has("stun_duration_ms"):
		monster.stun_duration_ms = int(overrides["stun_duration_ms"])
	if overrides.has("interrupt_skip_count"):
		monster.interrupt_skip_count = int(overrides["interrupt_skip_count"])
	return monster


static func _test_physical_skill(amount: float, execution_ms: int) -> Skill:
	var skill := Skill.new()
	skill.id = "balance.test.physical"
	skill.display_name = "Balance Test Physical"
	skill.base_execution_ms = execution_ms
	skill.min_execution_ms = 100
	var damage := PhysicalDamageEffect.new()
	damage.amount = amount
	skill.effects = [damage]
	return skill


static func _test_poison_skill(stacks: int, execution_ms: int) -> Skill:
	var skill := Skill.new()
	skill.id = "balance.test.poison"
	skill.display_name = "Balance Test Poison"
	skill.base_execution_ms = execution_ms
	skill.min_execution_ms = 100
	var poison := PoisonDamageEffect.new()
	poison.stacks_applied = stacks
	skill.effects = [poison]
	return skill


static func _test_player() -> PlayerStats:
	var player := PlayerStats.new()
	player.attack_speed = 0.0
	player.crit_chance = 0.0
	player.crit_multiplier = 2.0
	player.poison_tick_interval_multiplier = 1.0
	player.physical_damage_multiplier = 1.0
	return player


static func _test_monster(values: Dictionary) -> Monster:
	var monster := Monster.new()
	monster.display_name = "Balance Test Monster"
	monster.hp = 999999
	monster.armor = int(values.get("armor", 0))
	monster.poison_resistance = float(values.get("poison_resistance", 0.0))
	monster.dodge_chance = float(values.get("dodge_chance", 0.0))
	monster.crit_negation = float(values.get("crit_negation", 0.0))
	monster.block = float(values.get("block", 0.0))
	monster.absorb = float(values.get("absorb", 0.0))
	monster.cleanse_threshold = int(values.get("cleanse_threshold", 0))
	monster.suppress = float(values.get("suppress", 0.0))
	monster.slow = float(values.get("slow", 0.0))
	return monster


static func _skill_names(skills: Array[Skill]) -> Array:
	var names := []
	for skill in skills:
		names.append(skill.display_name)
	return names


static func _gear_names(gear_items: Array[GearItem]) -> Array:
	var names := []
	for item in gear_items:
		names.append(item.display_name)
	return names


static func _write_text(path: String, contents: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(contents)
	return true


static func _scenario_csv(report: Dictionary) -> String:
	var rows := [[
		"id", "status", "seed_count", "monster", "rotation", "gear", "mean_dps", "p05_dps",
		"p50_dps", "p95_dps", "win_rate", "mean_physical_damage", "mean_poison_damage",
		"mean_poison_ticks", "mean_casts", "mean_dodges", "mean_dodge_rate",
		"mean_blocked_damage", "mean_crit_negated_damage", "mean_absorbed_damage",
		"mean_cleanses", "mean_suppressed_tick_interval_ms", "mean_min_cast_proc_rate",
		"notes"
	]]
	for scenario in report.get("scenarios", []):
		var aggregate: Dictionary = scenario["aggregate"]
		rows.append([
			scenario["id"],
			scenario["status"],
			scenario["seed_count"],
			scenario["monster"],
			" > ".join(scenario["rotation"]),
			", ".join(scenario["gear"]),
			aggregate["dps"]["mean"],
			aggregate["dps"]["p05"],
			aggregate["dps"]["p50"],
			aggregate["dps"]["p95"],
			aggregate["win_rate"],
			aggregate["physical_damage"]["mean"],
			aggregate["poison_damage"]["mean"],
			aggregate["poison_damage_ticks"]["mean"],
			aggregate["casts"]["mean"],
			aggregate["dodges"]["mean"],
			aggregate["dodge_rate"]["mean"],
			aggregate["blocked_damage"]["mean"],
			aggregate["crit_negated_damage"]["mean"],
			aggregate["absorbed_damage"]["mean"],
			aggregate["cleanses"]["mean"],
			aggregate["suppressed_tick_interval_ms"]["mean"],
			aggregate["min_cast_proc_rate"]["mean"],
			" | ".join(scenario["notes"]),
		])
	var lines := []
	for row in rows:
		var cells := []
		for cell in row:
			cells.append(_csv_cell(cell))
		lines.append(",".join(cells))
	return "\n".join(lines) + "\n"


static func _csv_cell(value) -> String:
	var text := str(value)
	if text.contains("\""):
		text = text.replace("\"", "\"\"")
	if text.contains(",") or text.contains("\n") or text.contains("\""):
		return "\"" + text + "\""
	return text


static func _dashboard_html(report: Dictionary) -> String:
	var data := JSON.stringify(report)
	var lines := [
		"<!doctype html>",
		"<html lang=\"en\">",
		"<head>",
		"<meta charset=\"utf-8\">",
		"<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
		"<title>FacelessVoid Balance Lab</title>",
		"<style>",
		":root{color-scheme:dark;--bg:#161514;--panel:#24211d;--ink:#f0e0c2;--muted:#b9aa8e;--line:#6f6047;--good:#72c05b;--warn:#d2a23e;--bad:#d85f4c;--accent:#e0a34f;}",
		"*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:14px/1.45 system-ui,Segoe UI,sans-serif;}header{padding:22px 28px;border-bottom:1px solid var(--line);background:#1d1b18;}h1{margin:0 0 4px;font-size:26px;}h2{margin:0 0 12px;font-size:18px;}main{padding:22px 28px;display:grid;gap:18px;}section{border:1px solid var(--line);background:var(--panel);border-radius:8px;padding:16px;}table{width:100%;border-collapse:collapse;}th,td{text-align:left;padding:8px 9px;border-bottom:1px solid rgba(255,255,255,.08);vertical-align:top;}th{color:var(--muted);font-weight:600}.status{font-weight:700;text-transform:uppercase}.pass{color:var(--good)}.warn{color:var(--warn)}.fail{color:var(--bad)}.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:12px}.card{border:1px solid rgba(255,255,255,.10);border-radius:8px;padding:12px;background:#1b1916}.metric{font-size:24px;font-weight:750}.muted{color:var(--muted)}.bars{display:grid;gap:10px}.bar-row{display:grid;grid-template-columns:260px 1fr 90px;gap:12px;align-items:center}.bar-track{height:14px;background:#111;border:1px solid rgba(255,255,255,.1);border-radius:3px;overflow:hidden}.bar-fill{height:100%;background:linear-gradient(90deg,var(--accent),#73bd6b)}code{color:#f5c16c}",
		"</style>",
		"</head>",
		"<body>",
		"<header><h1>FacelessVoid Balance Lab</h1><div class=\"muted\">Generated <code id=\"generated\"></code> | Version <code id=\"version\"></code></div></header>",
		"<main>",
		"<section><h2>Suite Health</h2><div class=\"cards\" id=\"health\"></div></section>",
		"<section><h2>Status Semantics</h2><table><thead><tr><th>Status</th><th>Meaning</th></tr></thead><tbody id=\"status-semantics\"></tbody></table></section>",
		"<section><h2>Scenario DPS</h2><div class=\"bars\" id=\"dps-bars\"></div></section>",
		"<section><h2>Enemy Defense Pressure</h2><table><thead><tr><th>Scenario</th><th>Dodges</th><th>Blocked</th><th>Crit Negated</th><th>Absorbed</th><th>Cleanses</th><th>DOT Interval</th><th>Casts</th></tr></thead><tbody id=\"defense-table\"></tbody></table></section>",
		"<section><h2>Scenarios</h2><table><thead><tr><th>Status</th><th>Scenario</th><th>Monster</th><th>Mean DPS</th><th>Win Rate</th><th>Poison</th><th>Notes</th></tr></thead><tbody id=\"scenario-table\"></tbody></table></section>",
		"<section><h2>Mechanics</h2><table><thead><tr><th>Status</th><th>Check</th><th>Observed</th><th>Expected</th><th>Note</th></tr></thead><tbody id=\"mechanics-table\"></tbody></table></section>",
		"</main>",
		"<script id=\"balance-data\" type=\"application/json\">" + data + "</script>",
		"<script>",
		"const report=JSON.parse(document.getElementById('balance-data').textContent);",
		"const fmt=n=>Number(n||0).toFixed(2); const pct=n=>(Number(n||0)*100).toFixed(1)+'%';",
		"document.getElementById('generated').textContent=report.generated_at; document.getElementById('version').textContent=report.version;",
		"const counts=report.status_counts||{pass:0,warn:0,fail:0}; if(!report.status_counts){[...report.mechanics,...report.scenarios].forEach(x=>counts[x.status]=(counts[x.status]||0)+1);}",
		"document.getElementById('health').innerHTML=['pass','warn','fail'].map(k=>`<div class=\"card\"><div class=\"muted\">${k.toUpperCase()}</div><div class=\"metric ${k}\">${counts[k]||0}</div></div>`).join('');",
		"document.getElementById('status-semantics').innerHTML=Object.entries(report.status_semantics||{}).map(([k,v])=>`<tr><td class=\"status ${k}\">${k}</td><td>${v}</td></tr>`).join('');",
		"const maxDps=Math.max(1,...report.scenarios.map(s=>s.aggregate.dps.mean));",
		"document.getElementById('dps-bars').innerHTML=report.scenarios.map(s=>`<div class=\"bar-row\"><div>${s.label}<div class=\"muted\">${s.seed_count} seeds</div></div><div class=\"bar-track\"><div class=\"bar-fill\" style=\"width:${Math.max(2,s.aggregate.dps.mean/maxDps*100)}%\"></div></div><div>${fmt(s.aggregate.dps.mean)}</div></div>`).join('');",
		"document.getElementById('defense-table').innerHTML=report.scenarios.map(s=>{const a=s.aggregate; return `<tr><td>${s.label}<div class=\"muted\">${Object.entries(s.monster_overrides||{}).map(([k,v])=>`${k}: ${v}`).join(' | ')||'base defenses'}</div></td><td>${fmt(a.dodges.mean)}<div class=\"muted\">${pct(a.dodge_rate.mean)}</div></td><td>${fmt(a.blocked_damage.mean)}</td><td>${fmt(a.crit_negated_damage.mean)}</td><td>${fmt(a.absorbed_damage.mean)}</td><td>${fmt(a.cleanses.mean)}</td><td>${fmt(a.suppressed_tick_interval_ms.mean)}ms</td><td>${fmt(a.casts.mean)}</td></tr>`}).join('');",
		"document.getElementById('scenario-table').innerHTML=report.scenarios.map(s=>`<tr><td class=\"status ${s.status}\">${s.status}</td><td>${s.label}<div class=\"muted\">${s.rotation.join(' > ')}</div></td><td>${s.monster}</td><td>${fmt(s.aggregate.dps.mean)}<div class=\"muted\">p05 ${fmt(s.aggregate.dps.p05)} | p95 ${fmt(s.aggregate.dps.p95)}</div></td><td>${pct(s.aggregate.win_rate)}</td><td>${fmt(s.aggregate.poison_damage.mean)} dmg<br><span class=\"muted\">${fmt(s.aggregate.poison_damage_ticks.mean)} ticks</span></td><td>${(s.notes||[]).join('<br>')||'<span class=\"muted\">Within thresholds</span>'}</td></tr>`).join('');",
		"document.getElementById('mechanics-table').innerHTML=report.mechanics.map(m=>`<tr><td class=\"status ${m.status}\">${m.status}</td><td>${m.label}</td><td>${m.values&&m.values.actual!==undefined?m.values.actual:''}</td><td>${m.values&&m.values.expected!==undefined?m.values.expected:''}</td><td>${m.note||''}</td></tr>`).join('');",
		"</script>",
		"</body></html>",
	]
	return "\n".join(lines)


## Data-only snapshot of the actual resources used; no live Resource references.
static func _resource_snapshot(value: Variant, depth: int = 0) -> Variant:
	if depth > 32:
		return "<reference-depth-limit>"
	if value is Resource:
		var result := {"resource_path": value.resource_path, "script": value.get_script().resource_path if value.get_script() != null else ""}
		for property in value.get_property_list():
			if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.usage & PROPERTY_USAGE_STORAGE:
				result[property.name] = _resource_snapshot(value.get(property.name), depth + 1)
		return result
	if value is Array or typeof(value) in [TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY]:
		var result := []
		for item in value:
			result.append(_resource_snapshot(item, depth + 1))
		return result
	if value is Dictionary:
		var result := {}
		for key in value:
			result[key] = _resource_snapshot(value[key], depth + 1)
		return result
	return value
