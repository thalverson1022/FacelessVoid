extends SceneTree

const BalanceLab = preload("res://scripts/tools/balance_lab.gd")


func _initialize() -> void:
	var report := BalanceLab.run_suite()
	var output_dir := ProjectSettings.globalize_path("res://reports/balance/latest")
	if not BalanceLab.write_report(report, output_dir):
		push_error("Balance Lab report write failed.")
		quit(1)
		return

	var counts := BalanceLab.status_counts(report)
	print("FacelessVoid Balance Lab report: %s" % output_dir)
	print("Status: %s | Scenarios: %s | Mechanics: %s | Seeds: %s" % [
		report.get("status", "unknown"),
		report.get("scenario_count", 0),
		report.get("mechanics_count", 0),
		report.get("seed_count", 0),
	])
	print("Checks: %s pass, %s warn, %s fail" % [counts["pass"], counts["warn"], counts["fail"]])
	for scenario in report["scenarios"]:
		var dps: float = scenario["aggregate"]["dps"]["mean"]
		var win_rate: float = scenario["aggregate"]["win_rate"]
		print("%s: %s | mean DPS %.2f | win rate %.1f%%" % [
			scenario["status"].to_upper(),
			scenario["label"],
			dps,
			win_rate * 100.0,
		])
	quit(0)
