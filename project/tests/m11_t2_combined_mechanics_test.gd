extends "res://tests/m9_t9_combined_mechanics_test.gd"
## M11 T2 reviewed mechanics-only subset. Deliberately excludes legal_budget().
## Synthetic legal endpoint gear and bounded authored-rank carriers; no earned-run claim.
func run() -> void:
	conversions()
	binary_stacking()
	cooldowns()
	durations_and_bases()
	procs()
	legendary_combinations()
	var functions := ["conversions", "binary_stacking", "cooldowns", "durations_and_bases", "procs", "legendary_combinations"]
	FileAccess.open("res://reports/m11_t2_combined_mechanics.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": not failed, "count": checks.size(), "checks": checks, "witnesses": witnesses, "executed_functions": functions, "excluded_functions": ["legal_budget"]}, "\t"))
	print("M11 T2 combined mechanics " + ("FAIL" if failed else "PASS") + " checks=" + str(checks.size()))
	quit(1 if failed else 0)
