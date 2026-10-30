extends "res://scripts/tools/run_m6_t5_search.gd"
## Replay the reviewed Tavern cohort against live, unmodified skill resources.
func _initialize() -> void:
	SaveSystem.save_path = "res://reports/p6_m6_t5_adoption/adventure.json"
	PracticeSaveSystem.save_path = "res://reports/p6_m6_t5_adoption/practice.json"
	PracticeSaveSystem.core_save_path = "res://reports/p6_m6_t5_adoption/core.json"
	call_deferred("run")

func run() -> void:
	registry = BuildContentRegistry.test_mode()
	var steal: Skill = load("res://data/skills/steal.tres")
	require(steal.base_execution_ms == 1100 and steal.min_execution_ms == 650, "Approved live timing")
	var evidence: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DEST + "/tavern_paths.json"))
	var rows := []
	var failures := 0
	for trial in evidence.trials:
		if trial.main == "thief" and int(trial.base_execution_ms) != 1100: continue
		main_name = trial.main
		var snapshot: Dictionary = {}
		for candidate in evidence.snapshots:
			if candidate.id == trial.snapshot: snapshot = candidate; break
		require(not snapshot.is_empty(), "Reviewed snapshot exists")
		var c := resolved(snapshot, trial.ranks)
		var native := RunFlow.load_encounter(int(str(trial.stage).trim_prefix("T")))
		var wins := 0
		var both := 0
		for sample in trial.samples:
			var context := "encounter:" + str(int(str(trial.stage).trim_prefix("T")))
			var first = simulate(trial.macro, c, native.monster, native.duration_ms, RunRng.seed_for_context(int(sample.root), RunRng.CONTEXT_COMBAT, [context, 0]))
			var won: bool = first.is_win
			if not won:
				var retry = simulate(trial.macro, resolved(snapshot, trial.ranks, first.gold_stolen), native.monster, native.duration_ms, RunRng.seed_for_context(int(sample.root), RunRng.CONTEXT_COMBAT, [context, 1]))
				won = retry.is_win
			wins += int(first.is_win)
			both += int(won)
			if first.is_win != sample.win or won != sample.within_two or not is_equal_approx(first.total_damage, float(sample.damage)) or first.gold_stolen != int(sample.stolen):
				failures += 1
		rows.append({"main": main_name, "policy": trial.policy, "stage": trial.stage, "wins": wins, "within_two": both, "count": 100})
	SaveSystem.write_json("res://reports/p6_m6_t5_adoption/live_tavern.json", {"passed": failures == 0, "mismatches": failures, "checks": checks, "rows": rows})
	print("T5 live adoption ", "PASS" if failures == 0 else "FAIL", " rows=", rows.size(), " mismatches=", failures)
	quit(0 if failures == 0 else 1)
