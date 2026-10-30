extends "res://scripts/tools/run_exsanguinate_study.gd"
## Current ranked content only. No trial resolver, player-stat override or save reads.
## --phase=profiles: representative 200-seed comparisons (default).
## --phase=search --seeds=12: bounded allocation/rotation screening.
## --validate-only resolves ranks, equipment and skill availability without combat.
var validate_only := false

func _initialize() -> void:
	out = "res://reports/balance/exsanguinate_shadow_study"
	for arg in OS.get_cmdline_user_args():
		if arg == "--validate-only": validate_only = true
	super._initialize()

func full_tree(tree_id: String) -> Dictionary:
	var ranks := {}
	for talent in registry.trees["tree." + tree_id].talents:
		ranks[talent.id] = talent.max_ranks
	return ranks

func blade_package(kind: String) -> Dictionary:
	match kind:
		"weak_wet": return {"talent.bladedancer.weakness":5,"talent.bladedancer.wet_stone":5}
		"weak_foot": return {"talent.bladedancer.weakness":5,"talent.bladedancer.fancy_footwork":5}
		"wet_foot": return {"talent.bladedancer.wet_stone":5,"talent.bladedancer.fancy_footwork":5}
		"dance12": return {"talent.bladedancer.weakness":5,"talent.bladedancer.wet_stone":5,"talent.bladedancer.rending_slash":1,"talent.bladedancer.precision_attacks":1}
	var ranks := full_tree("bladedancer")
	if kind in ["bd32","bd29"]:
		ranks.erase("talent.bladedancer.weapon_master")
		ranks.erase("talent.bladedancer.side_step")
	if kind == "bd29": ranks["talent.bladedancer.sharpened_edge"] = 2
	return ranks

func shadow_package(kind: String) -> Dictionary:
	if kind == "sh10": return {"talent.shadow.blind_spot":5,"talent.shadow.snake_oil":4,"talent.shadow.coated_weapons":1}
	if kind == "sh13":
		var ranks := shadow_package("sh10")
		ranks["talent.shadow.death_touch"] = 3
		return ranks
	if kind == "sh16":
		var ranks := shadow_package("sh13")
		ranks["talent.shadow.deception"] = 2
		ranks["talent.shadow.dusk_strike"] = 1
		return ranks
	var ranks := full_tree("shadow")
	if kind == "sh33": ranks.erase("talent.shadow.death_blade")
	return ranks

func ranked_case(id: String, primary: String, secondary: String, first: Dictionary, second: Dictionary, rotation: Array, gear: String = "solo") -> Dictionary:
	var spec := scenario(id,0,0,rotation,gear)
	var ranks := first.duplicate()
	ranks.merge(second,true)
	spec.ranked_build.primary_tree_id = "tree." + primary
	spec.ranked_build.secondary_tree_id = "tree." + secondary
	spec.ranked_build.earned_talent_points = 45
	spec.ranked_build.talent_ranks = ranks
	return spec

func shadow_case(id: String, rotation: Array, gear: String = "solo", blade: String = "weak_wet", shadow: String = "sh35") -> Dictionary:
	return ranked_case(id,"shadow","bladedancer",shadow_package(shadow),blade_package(blade),rotation,gear)

func hybrid_case(id: String, blade: String, shadow: String, rotation: Array, gear: String = "solo") -> Dictionary:
	return ranked_case(id,"bladedancer","shadow",blade_package(blade),shadow_package(shadow),rotation,gear)

func profiles() -> Array:
	var specs := []
	for gear in ["solo","full_coil"]:
		# Full roster and short macro controls match the earlier native study.
		specs.append(scenario("bd35_thief10_user_"+gear,35,10,USER_ROTATION,gear))
		specs.append(scenario("bd35_thief10_short_"+gear,35,10,["dance_of_death","quick_cut","exsanguinate"],gear))
		specs.append(shadow_case("sh35_bd10_decay_"+gear,["toxic_flurry","exsanguinate"],gear))
		specs.append(shadow_case("sh35_bd10_mixed_"+gear,["quick_cut","toxic_flurry","exsanguinate"],gear))
		# Display names Beguiling Strike / Death Strike retain these stable IDs.
		specs.append(shadow_case("sh35_bd10_roster_"+gear,["stab","heavy_slash","toxic_flurry","killers_mark","distilled_corruption","touch_of_darkness","beguiling_presence","quick_cut","exsanguinate"],gear))
		specs.append(shadow_case("sh35_bd10_no_exsang_"+gear,["quick_cut","toxic_flurry"],gear))
		specs.append(shadow_case("sh35_bd10_footwork_"+gear,["parry_strike","toxic_flurry","exsanguinate"],gear,"weak_foot"))
		specs.append(shadow_case("sh33_bd12_dance_"+gear,["dance_of_death","toxic_flurry","quick_cut","exsanguinate"],gear,"dance12","sh33"))
		specs.append(hybrid_case("bd32_sh13_"+gear,"bd32","sh13",["dance_of_death","quick_cut","exsanguinate"],gear))
		specs.append(hybrid_case("bd29_sh16_"+gear,"bd29","sh16",["dance_of_death","toxic_flurry","quick_cut","exsanguinate"],gear))
	return specs

func search() -> Array:
	var specs := profiles()
	var rotations := [
		["quick_cut","exsanguinate"],
		["toxic_flurry","toxic_flurry","exsanguinate"],
		["parry_strike","quick_cut","toxic_flurry","exsanguinate"],
		["toxic_flurry","beguiling_presence","heavy_slash","exsanguinate"],
		["toxic_flurry","touch_of_darkness","quick_cut","exsanguinate"],
		["quick_cut","quick_cut","quick_cut","toxic_flurry","exsanguinate"],
	]
	for gear in ["solo","full_coil"]:
		for blade in ["weak_wet","weak_foot","wet_foot"]:
			for index in rotations.size():
				specs.append(shadow_case("search_sh35_%s_%02d_%s" % [blade,index,gear],rotations[index],gear,blade))
		for pair in [["bd35","sh10"],["bd32","sh13"],["bd29","sh16"]]:
			for index in 2:
				var rotation := ["dance_of_death","toxic_flurry","exsanguinate"] if index == 0 else ["dance_of_death","quick_cut","quick_cut","parry_strike","exsanguinate"]
				specs.append(hybrid_case("search_%s_%s_%d_%s" % [pair[0],pair[1],index,gear],pair[0],pair[1],rotation,gear))
		# Other trees offer generation or cast speed, not additional Shred Value.
		var assassin10 := {"talent.assassin.quick_hands":5,"talent.assassin.precision":5}
		specs.append(ranked_case("other_bd35_assassin10_"+gear,"bladedancer","assassin",blade_package("bd35"),assassin10,["dance_of_death","quick_cut","exsanguinate"],gear))
		specs.append(ranked_case("other_thief35_bd10_"+gear,"thief","bladedancer",full_tree("thief"),blade_package("weak_wet"),["pick_pocket","steal","mug","quick_cut","exsanguinate"],gear))
	return specs

func resolved_fields(spec: Dictionary) -> Dictionary:
	var decoded := BuildSaveCodec.decode(spec.ranked_build,registry)
	if decoded.get("error","") != "": return {"error":decoded.error}
	var gear: Array[GearItem] = []
	for path in spec.gear: gear.append(load(path))
	var resolved := BuildResolver.resolve_ranked_build(decoded["class"],decoded.model,gear,0)
	if resolved.error != "": return {"error":resolved.error}
	var requested: Array[Skill] = []
	for id in decoded.rotation_ids:
		var skill := Skill.new()
		skill.id = id
		requested.append(skill)
	var normalized := BuildResolver.normalize_rotation(requested,resolved.skills)
	if not normalized.removed.is_empty() or not normalized.overflow.is_empty() or normalized.rotation.is_empty():
		return {"error":"Unavailable or invalid rotation","removed":normalized.removed,"overflow":normalized.overflow}
	var p: PlayerStats = resolved.stats
	var tree_points := {}
	for tree in decoded.trees: tree_points[tree.id] = decoded.model.tree_points(tree)
	return {"error":"","tree_points":tree_points,"unspent_points":decoded.model.unspent_points(),
		"shred_value":p.shred_value,"bonus_shred_stacks":p.bonus_shred_stacks,"shred_chance":p.shred_chance,
		"bonus_decay_stacks":p.bonus_decay_stacks,"decay_chance":p.decay_chance,"independent_decay_shred":p.independent_decay_shred,
		"death_blade_enabled":p.death_blade_enabled,"death_blade_chance":p.death_blade_chance,
		"death_pact_rank":p.death_pact_rank,"shred_cleanse_immune":p.shred_cleanse_immune,
		"retrigger_chance":p.retrigger_chance,"attack_speed":p.attack_speed,"crit_chance":p.crit_chance,
		"cooldown_factor":p.cooldown_factor,"buff_duration":p.increased_buff_duration,
		"bribery_base_stacks":p.bribery_base_stacks,"stat_sources":p.stat_sources,"derivation_details":p.derivation_details}

func defenses() -> Array:
	var specs := []
	for entry in [
		{"id":"armor_block_resist","values":{"armor":1000,"block":100,"poison_resistance":0.9}},
		{"id":"dodge100","values":{"dodge_chance":1.0}},
		{"id":"slow50","values":{"slow":0.5}},
		{"id":"cleanse","values":{"cleanse_threshold":3}},
	]:
		var shadow := shadow_case("defense_sh35_"+entry.id,["toxic_flurry","exsanguinate"])
		var hybrid := hybrid_case("defense_bd29_sh16_"+entry.id,"bd29","sh16",["dance_of_death","toxic_flurry","quick_cut","exsanguinate"])
		for spec in [shadow,hybrid]:
			spec.monster_overrides.merge(entry.values,true)
			specs.append(spec)
	return specs

func run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	registry = BuildContentRegistry.test_mode()
	var specs := search() if phase == "search" else (defenses() if phase == "defenses" else profiles())
	var invalid := 0
	for spec in specs:
		if only != "" and not spec.id.contains(only): continue
		var fields := resolved_fields(spec)
		var result: Dictionary
		if validate_only:
			result = {"id":spec.id,"status":"validated" if fields.get("error","") == "" else "invalid","notes":[fields.get("error","")]}
		else:
			result = Lab.run_scenario_spec(spec,registry)
		result["study_spec"] = spec
		result["resolved_fields"] = fields
		SaveSystem.write_json(out+"/"+spec.id+".json",result)
		rows.append(result)
		if result.status not in ["pass","validated"] or fields.get("error","") != "":
			invalid += 1
			print("INVALID ROW ",spec.id," ",result.notes," ",fields.get("error",""))
		elif validate_only:
			print("VALIDATED ",spec.id," points=",fields.tree_points," shred_value=",fields.shred_value," bonus_shred=",fields.bonus_shred_stacks)
		else:
			print("ROW ",spec.id," removal=",result.aggregate.total_health_removed.mean," ordinary=",result.aggregate.total_damage.mean)
		SaveSystem.write_json(out+"/summary.json",{"duration_ms":30000,"seed_count":seeds,"phase":phase,"validation_only":validate_only,"complete":false,"invalid_scenarios":invalid,"rows":rows})
	SaveSystem.write_json(out+"/summary.json",{"duration_ms":30000,"seed_count":seeds,"phase":phase,"validation_only":validate_only,"complete":true,"invalid_scenarios":invalid,"rows":rows})
	print("PASS Exsanguinate Shadow study execution rows=",rows.size()," invalid_scenarios=",invalid," validation_only=",validate_only)
	quit(0 if invalid == 0 else 1)
