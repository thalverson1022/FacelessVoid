extends "res://scripts/tools/run_assassin_balance_inquiry.gd"
## Diagnostic-only primary-point scaling comparison under selected talent coefficients.
func run() -> void:
	for points in [35,10,20,25]:
		var control := {}
		for per_point in [1.0,0.5]:
			registry = BuildContentRegistry.test_mode()
			var tree: SubclassTree = registry.trees["tree.assassin"]
			for modifier in tree.primary_point_modifiers:
				if modifier.stat_id == StatCatalog.BASE_ELEMENTAL_DAMAGE: modifier.value = per_point
			var content := build(points)
			var echo: int = content.stats.echoing_toxin_rank
			var resonance: int = content.stats.resonance_rank
			var toxic: int = content.payload.talent_ranks.get("talent.assassin.toxic_tradeoff",0)
			var old_factor := (1.0+0.1*echo)*(1.0+0.2*resonance)
			var proposed_factor := (1.0+0.05*echo)*(1.0+0.05*resonance)*(1.0+0.1*toxic)
			field(content.stats,"poison_tick_damage_multiplier",proposed_factor/old_factor)
			require(is_equal_approx(content.stats.bonus_base_elemental_damage,5.0+points*per_point),"primary coefficient resolves exactly, innate unchanged")
			require(content.stats.assassin_tree_points==points,"Powder investment unchanged")
			var id := "primary_scale_%d_%s" % [points,"one" if per_point==1.0 else "half"]
			var row := cohort(id,content)
			row["primary_elemental_per_point"] = per_point
			row["resolved_bonus_base_elemental"] = content.stats.bonus_base_elemental_damage
			if control.is_empty(): control = row
			for i in row.samples.size():
				for key in ["physical_damage","casts","poison_damage_ticks","stacks_consumed","empty_ticks","poison_crits"]:
					require(control.samples[i][key]==row.samples[i][key],"same-seed non-damage behavior " + key)
			var trace: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT+"/"+id+"_trace.json"))
			for tick in trace.ticks:
				require(is_equal_approx(tick.payload.talent_multiplier,proposed_factor),"selected rank coefficients reach live ticks")
	write("primary_scaling_comparison.json",{"pass":not bad,"checks":checks,"scenarios":rows,"proposal":"Primary Assassin elemental damage per point 1.0 versus 0.5. Echoing/Resonance 5% each, separate factors; Toxic +10% Poison/-10% physical per rank. Innate +5 and Powder investment unchanged. Lower budgets are reference allocations, not user's original builds. Diagnostic copies only."})
	quit(1 if bad else 0)
