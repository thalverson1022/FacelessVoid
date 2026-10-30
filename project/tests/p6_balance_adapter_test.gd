extends SceneTree
const Lab := preload("res://scripts/tools/balance_lab.gd")

func _initialize() -> void:
	var registry: BuildContentRegistry = preload("res://tests/fixtures/p6/registry.gd").make()
	var sandbox := TrainingRoomState.new()
	var rogue: ClassDef = registry.classes.values()[0]
	sandbox.set_class(rogue)
	assert(sandbox.configure_ranked_build(rogue.trees[0], rogue.trees[1]))
	assert(sandbox.select_talent(rogue.trees[0].talents[0]))
	var rotation: Array[Skill] = [rogue.base_skills[0], rogue.base_skills[0]]
	sandbox.set_rotation(rotation)
	var spec := {"id": "t8_scalar_diagnostic", "label": "Test-only scalar diagnostic", "ranked_build": BuildSaveCodec.encode(sandbox, registry),
		"monster": "res://data/monsters/mouthy_drunk.tres", "monster_overrides": {"hp": 1000000, "armor": 0, "poison_resistance": 0},
		"gear": ["res://data/gear/crude_dagger.tres"], "duration_ms": 30000, "seed_start": 1, "seed_count": 20}
	var unavailable := Lab.run_scenario_spec(spec)
	assert(unavailable.status == "not_ready" and unavailable.seed_count == 0)
	var first := Lab.run_scenario_spec(spec, registry)
	assert(first.status == "pass", str(first.notes))
	var second := Lab.run_scenario_spec(spec, registry)
	assert(first.samples == second.samples and first.aggregate == second.aggregate)
	assert(first.seed_count == 20 and first.foundation_snapshot.build == spec.ranked_build)
	assert(first.foundation_snapshot.trees.size() == 2 and first.foundation_snapshot.gear.size() == 1)
	assert(first.foundation_snapshot.monster.hp == 1000000)
	var bad := spec.duplicate(true)
	bad.ranked_build.talent_ranks["talent.bladedancer.wet_stone"] = 99
	assert(Lab.run_scenario_spec(bad, registry).status == "fail")
	bad = spec.duplicate(true)
	bad.ranked_build.rotation_skill_ids = ["unavailable"]
	assert(Lab.run_scenario_spec(bad, registry).status == "fail")
	var report := {"scope": "Synthetic/scalar correctness only; not redesigned tree balance acceptance", "scenarios": [first, unavailable]}
	Lab._finalize_report_metadata(report)
	assert(report.status == "not_ready")
	assert(report.status_counts.not_ready == 1)
	assert(SaveSystem.write_json("res://reports/p6_t8/ranked_balance_diagnostics.json", report))
	print("P6 Balance Lab adapter: PASS (20-seed repeatability, exact snapshots, explicit not-ready and invalid-build outcomes)")
	quit()
