extends "res://scripts/tools/run_assassin_balance_inquiry.gd"
## Read-only in-memory balance proposal. Never saves changed talent resources.

func run() -> void:
	var proposals := [
		{"id":"toxic_probe_control","poison":2.0,"physical_penalty_per_rank":0.1},
		{"id":"toxic_poison10_only","poison":1.5,"physical_penalty_per_rank":0.1},
		{"id":"toxic_physical20_only","poison":2.0,"physical_penalty_per_rank":0.2},
		{"id":"toxic_poison10_physical20","poison":1.5,"physical_penalty_per_rank":0.2},
	]
	var original := {}
	for proposal in proposals:
		registry = BuildContentRegistry.test_mode()
		# Registry resources are private deep copies. Re-resolve the build to preserve
		# canonical buckets and temporary-stat provenance for the physical penalty.
		var talent: Talent = registry.talents["talent.assassin.toxic_tradeoff"]
		for i in talent.ranks.size():
			for modifier in talent.ranks[i].stat_modifiers:
				if modifier.stat_id == "percent_physical_damage": modifier.value = -proposal.physical_penalty_per_rank * (i+1)
		var content := build(35)
		var prepared := variant(content, [])
		content.stats = prepared.stats
		# Equivalent product for Echoing 5% x3 and Resonance 5% x4; separate factors.
		field(content.stats, "poison_tick_damage_multiplier", proposal.poison * (1.15 * 1.20) / (1.30 * 1.80))
		var row := cohort(proposal.id, content)
		row["proposal"] = proposal
		row["physical_buckets"] = content.stats.physical_damage_buckets()
		row["display_physical_multiplier"] = content.stats.physical_damage_multiplier
		if original.is_empty(): original = row
		for i in row.samples.size():
			for key in ["casts","poison_damage_ticks","stacks_consumed","empty_ticks","poison_crits"]:
				require(original.samples[i][key] == row.samples[i][key], "same-seed timing/fuel/crits " + key)
		var trace: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT + "/" + proposal.id + "_trace.json"))
		for tick in trace.ticks:
			require(is_equal_approx(tick.payload.talent_multiplier, 1.15 * 1.20 * proposal.poison), "candidate tick multiplier")
	write("toxic_proposal_comparison.json", {"pass":not bad,"checks":checks,"scenarios":rows,"method":"Private rank resource copies for physical penalties; equivalent Poison scalar for proposed coefficients; production resolver and all shipped resources unchanged. Echoing and Resonance each 5% per rank, separate multipliers."})
	quit(1 if bad else 0)
