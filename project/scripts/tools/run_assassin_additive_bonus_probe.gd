extends "res://scripts/tools/run_assassin_balance_inquiry.gd"
## Diagnostic-only equivalent scaling: Echoing and Resonance are separate scalar factors
## in the Poison tick product. Fold their proposed ratio into a copied Poison-only factor.
## Released ranks, effects, resources and the production resolver remain unchanged.

func run() -> void:
	registry = BuildContentRegistry.test_mode()
	var content := build(35)
	var original := cohort("additive_probe_control", content)
	var proposals := [
		{"id":"five_five_multiplicative","echo":0.05,"resonance":0.05,"additive":false},
		{"id":"five_five_additive","echo":0.05,"resonance":0.05,"additive":true},
		{"id":"five_ten_additive","echo":0.05,"resonance":0.10,"additive":true},
		{"id":"ten_twenty_additive","echo":0.10,"resonance":0.20,"additive":true},
	]
	for proposal in proposals:
		var prepared := variant(content, [])
		var candidate := content.duplicate()
		candidate.stats = prepared.stats
		var old_factor: float = (1.0 + 0.1 * candidate.stats.echoing_toxin_rank) * (1.0 + 0.2 * candidate.stats.resonance_rank)
		var new_factor: float = (1.0 + proposal.echo * candidate.stats.echoing_toxin_rank) * (1.0 + proposal.resonance * candidate.stats.resonance_rank)
		if proposal.additive:
			new_factor = 1.0 + proposal.echo * candidate.stats.echoing_toxin_rank + proposal.resonance * candidate.stats.resonance_rank
		field(candidate.stats, "poison_tick_damage_multiplier", content.stats.poison_tick_damage_multiplier * new_factor / old_factor)
		var row := cohort(proposal.id, candidate)
		row["proposal"] = proposal
		row["equivalent_poison_factor"] = candidate.stats.poison_tick_damage_multiplier
		row["poison_damage_ratio_before_rounding"] = new_factor / old_factor
		for i in row.samples.size():
			var a: Dictionary = original.samples[i]
			var b: Dictionary = row.samples[i]
			for key in ["physical_damage","casts","poison_damage_ticks","stacks_consumed","empty_ticks","poison_crits"]:
				require(a[key] == b[key], "same seed retains scheduling/fuel/crit/direct damage: " + key)
		var trace: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT + "/" + proposal.id + "_trace.json"))
		for tick in trace.ticks:
			require(is_equal_approx(tick.payload.talent_multiplier, new_factor * 2.0), "proposed multiplier reaches live ticks including Bypass rebuilds")
	write("additive_bonus_comparison.json", {"pass":not bad,"checks":checks,"scenarios":rows,"method":"Equivalent Poison-only multiplier on diagnostic copies. Echoing/Resonance stack consumption and every other stat unchanged. 200 matched seeds each. No released code/data changes."})
	quit(1 if bad else 0)
