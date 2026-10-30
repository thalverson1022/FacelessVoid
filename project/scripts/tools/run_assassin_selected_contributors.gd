extends "res://scripts/tools/run_assassin_balance_inquiry.gd"
## Conditional contributor study for the user's selected experimental coefficients.
func run() -> void:
	registry = BuildContentRegistry.test_mode()
	var content := build(35)
	for spec in [
		{"id":"selected_candidate_baseline","off":[]},
		{"id":"selected_no_resonance","off":["no_resonance"]},
		{"id":"selected_no_echo_resonance","off":["no_echo_resonance"]},
		{"id":"selected_no_point_base","off":["no_point_base"]},
		{"id":"selected_no_virulent","off":["no_virulent"]},
		{"id":"selected_no_potency","off":["no_potency"]},
		{"id":"selected_no_bypass","off":["no_bypass"]},
	]:
		var prepared := variant(content, spec.off)
		var candidate := content.duplicate()
		candidate.stats = prepared.stats
		candidate.rotation = prepared.rotation
		var echo: int = candidate.stats.echoing_toxin_rank
		var resonance: int = candidate.stats.resonance_rank
		# Recompute equivalence for retained ranks, so removal uses the proposed
		# 5% coefficients rather than accidentally retaining a full-build ratio.
		var old_factor := (1.0 + 0.1 * echo) * (1.0 + 0.2 * resonance)
		var new_factor := (1.0 + 0.05 * echo) * (1.0 + 0.05 * resonance)
		field(candidate.stats,"poison_tick_damage_multiplier",1.5 * new_factor / old_factor)
		var row := cohort(spec.id,candidate)
		row["disabled_effects"] = spec.off
		var trace: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT + "/" + spec.id + "_trace.json"))
		for tick in trace.ticks:
			require(is_equal_approx(tick.payload.talent_multiplier,1.5*new_factor),"candidate retained-rank product")
	write("selected_candidate_contributors.json",{"pass":not bad,"checks":checks,"scenarios":rows,"proposal":"Echoing 5% and Resonance 5% per rank as separate factors; Toxic +10% Poison/-10% physical per rank. Diagnostic only; released gameplay unchanged."})
	quit(1 if bad else 0)
