extends SceneTree
## Measurement-only checks against the real resolver; never accesses player saves.

const Lab = preload("res://scripts/tools/balance_lab.gd")
var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("FAILED: " + message)


func setup_skill() -> Skill:
	var skill := Skill.new()
	skill.id = "fixture.shred"
	skill.category = Skill.Category.DEBUFF
	skill.base_execution_ms = 300
	skill.min_execution_ms = 300
	var shred := ArmorReductionEffect.new()
	shred.amount = 3
	skill.effects = [shred]
	return skill


func removal_metrics() -> void:
	var player := PlayerStats.new()
	player.retrigger_chance = 1.0
	player.shred_value = 60
	var target := Monster.new()
	target.hp = 999999999
	target.armor = 100
	var ex: Skill = load("res://data/skills/exsanguinate.tres")
	var result := CombatResolver.resolve([setup_skill(), ex], player, target, 600, 22, true)
	check(result.is_valid, "Shred and production Exsanguinate resolve validly")
	var summary := Lab._combat_summary(22, result)
	check(summary.total_health_removed == 180.0, "three Shred at value60 remove180 once even at100 percent Retrigger")
	check(summary.exsanguinate_casts == 1 and summary.exsanguinate_original_casts == 1 and summary.exsanguinate_repeat_casts == 0, "only the original Exsanguinate is counted; repeat field remains zero")
	check(summary.exsanguinate_stacks_consumed == 3, "one cast consumes three Shred")
	check(summary.exsanguinate_original_health_removed == 180.0 and summary.exsanguinate_repeated_health_removed == 0.0, "native repeated removal field remains zero")
	check(summary.total_damage == 0.0 and summary.dps == 0.0 and summary.physical_damage == 0.0 and summary.poison_damage == 0.0, "health removal never inflates ordinary damage or DPS")
	check(summary.total_health_loss == result.total_health_loss() and summary.total_health_loss == summary.total_health_removed, "health loss uses resolver total")
	check(is_equal_approx(summary.health_removed_per_second, 300.0) and is_equal_approx(summary.health_loss_per_second, 300.0), "removal rates use the complete fixed simulation window")
	var consumed := 0
	for event in result.cast_events:
		for transaction in event.status_transactions:
			if transaction.get("reason", "") == "exsanguinate_consumed":
				consumed += int(transaction.get("consumed", 0))
	check(consumed == summary.exsanguinate_stacks_consumed, "stack metric agrees with actual status transactions")
	check(result.cast_events.back().status_snapshot.shred == 0 and result.cast_events.back().status_snapshot.armor == 100, "spent Shred restores target armor")
	var empty := CombatResolver.resolve([ex], player, target, 300, 22)
	var zero := Lab._combat_summary(22, empty)
	check(empty.is_valid and zero.exsanguinate_casts == 1 and zero.exsanguinate_repeat_casts == 0, "zero-Shred Exsanguinate casts once without repeats")
	check(zero.total_health_removed == 0.0 and zero.health_removed_per_second == 0.0 and zero.exsanguinate_stacks_consumed == 0 and zero.exsanguinate_original_health_removed == 0.0 and zero.exsanguinate_repeated_health_removed == 0.0, "zero-Shred measurements stay zero")
	var zero_duration := Lab._combat_summary(1, CombatResolver.resolve([ex], player, target, 0, 1))
	check(zero_duration.health_removed_per_second == 0.0 and zero_duration.health_loss_per_second == 0.0, "empty duration rates remain finite zero")
	player.retrigger_chance = 0.0
	var cooldown_result := CombatResolver.resolve([ex], player, target, 30000, 22)
	var cooldown := Lab._combat_summary(22, cooldown_result)
	var execution_times := []
	var blocked_attempts := 0
	for event in cooldown_result.cast_events:
		if event.health_removal_captured:
			execution_times.append(event.time_ms)
		if event.cooldown_blocked:
			blocked_attempts += 1
	check(cooldown_result.is_valid and execution_times == [300, 8600, 16900, 25200], "Exsanguinate alone executes four times in30sec under its real8sec cooldown")
	check(cooldown.exsanguinate_casts == 4 and cooldown.exsanguinate_original_casts == 4 and cooldown.exsanguinate_repeat_casts == 0, "actual casts exclude cooldown-blocked macro attempts")
	check(cooldown.exsanguinate_attempts == 292 and cooldown.exsanguinate_attempts == cooldown_result.cast_events.size() and cooldown.exsanguinate_attempts == cooldown.exsanguinate_casts + blocked_attempts, "attempts retain292 authoritative macro records separately from four actual casts")


func ordinary_damage_metrics() -> void:
	var player := PlayerStats.new()
	player.poison_damage_per_tick = 10.0
	var target := Monster.new()
	target.hp = 999999999
	var skill := setup_skill()
	skill.id = "fixture.ordinary_damage"
	skill.category = Skill.Category.ATTACK
	var hit := PhysicalDamageEffect.new()
	hit.amount = 25.0
	var poison := PoisonDamageEffect.new()
	poison.stacks_applied = 2
	skill.effects = [hit, poison]
	var result := CombatResolver.resolve([skill], player, target, 2000, 19)
	var summary := Lab._combat_summary(19, result)
	var physical := 0.0
	var poison_damage := 0.0
	for event in result.cast_events:
		physical += event.physical_damage
	for tick in result.tick_events:
		poison_damage += tick.damage
	check(result.is_valid and physical > 0.0 and poison_damage > 0.0, "ordinary fixture resolves physical and Poison damage")
	check(summary.total_damage == result.total_damage and summary.dps == result.dps and summary.physical_damage == physical and summary.poison_damage == poison_damage, "existing ordinary metrics retain authoritative damage meanings")
	check(summary.total_health_loss == summary.total_damage and summary.health_loss_per_second == summary.dps, "without removal combined health loss equals ordinary damage and DPS")
	for metric in ["total_health_removed", "health_removed_per_second", "exsanguinate_attempts", "exsanguinate_casts", "exsanguinate_original_casts", "exsanguinate_repeat_casts", "exsanguinate_stacks_consumed", "exsanguinate_original_health_removed", "exsanguinate_repeated_health_removed"]:
		check(summary[metric] == 0, "non-Exsanguinate scenario has zero " + metric)


func scenario_distributions() -> void:
	var spec := {
		"id": "exsanguinate_measurement", "label": "Exsanguinate measurement",
		"class": "res://data/classes/rogue.tres", "monster": "res://data/monsters/training_dummy.tres",
		"gear": ["res://data/gear/nightkiss_kitana.tres"],
		"skills": ["res://data/skills/stab.tres", "res://data/skills/exsanguinate.tres"],
		"monster_overrides": {"hp": 999999999}, "duration_ms": 30000, "seed_count": 4,
	}
	var report := Lab.run_scenario_spec(spec)
	check(report.status == "pass" and report.seed_count == 4 and report.samples.size() == 4, "native scenario runner produces four valid samples")
	check(report.aggregate.total_health_removed.mean > 0.0 and report.aggregate.dps.mean > 0.0, "native Nightkiss scenario witnesses both damage and health removal")
	for metric in Lab.HEALTH_LOSS_METRICS:
		var values := []
		for sample in report.samples:
			values.append(sample[metric])
		check(report.aggregate[metric] == Lab._distribution(values), "native aggregation preserves each sample for " + metric)
	var unavailable := spec.duplicate(true)
	unavailable.ranked_build = {}
	var failed := Lab.run_scenario_spec(unavailable, BuildContentRegistry.test_mode())
	check(failed.status == "fail" and failed.samples.is_empty() and failed.seed_count == 0, "invalid scenario remains failed with no samples")
	for metric in Lab.HEALTH_LOSS_METRICS:
		check(failed.aggregate[metric].count == 0, "failed scenario reports no valid distribution for " + metric)


func run() -> void:
	removal_metrics()
	ordinary_damage_metrics()
	scenario_distributions()
	print("Exsanguinate Balance Lab metrics: %s (%d checks)" % ["PASS" if failures.is_empty() else "FAILED", checks])
	quit(0 if failures.is_empty() else 1)
