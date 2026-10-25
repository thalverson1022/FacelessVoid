extends "res://scripts/tools/run_m6_tavern_1023.gd"

func run() -> void:
	registry = BuildContentRegistry.test_mode()
	protocol = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/subclass_protocol.json"))
	var rows := []
	for tree in ["bladedancer", "thief", "assassin", "shadow"]:
		for variant in ["p6_m6_t4_three_points", "p6_m6_tavern_1023"]:
			var fixtures: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://reports/%s/%s/fixtures.json" % [variant, tree]))
			var seen := {}
			for snapshot in fixtures.snapshots:
				if snapshot.policy != "typical" or snapshot.checkpoint not in ["T0", "T1", "T2", "T3", "C1"] or seen.has(snapshot.checkpoint): continue
				seen[snapshot.checkpoint] = true
				var content := content_for(snapshot, 35)
				var ids: Array = content.skills.map(func(skill): return skill.id)
				rows.append({"main": tree, "variant": variant, "checkpoint": snapshot.checkpoint, "budget": snapshot.budget, "skills": ids})
	SaveSystem.write_json(OUT + "/unlock_comparison.json", {"rows": rows, "checks": checks})
	print("Tavern unlock comparison PASS; checks=", checks)
	quit(0)
