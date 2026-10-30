extends SceneTree
## Native Balance Lab scenarios; no gameplay tuning or player-save reads.
const Lab = preload("res://scripts/tools/balance_lab.gd")
const USER_ROTATION := ["dance_of_death","quick_cut","heavy_slash","parry_strike","leaping_plunge","exsanguinate"]
var out := "res://reports/balance/exsanguinate_study"
var seeds := 200
var phase := "profiles"
var only := ""
var rows: Array = []
var registry: BuildContentRegistry

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="): seeds = int(arg.trim_prefix("--seeds="))
		if arg.begins_with("--phase="): phase = arg.trim_prefix("--phase=")
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg.begins_with("--only="): only = arg.trim_prefix("--only=")
	SaveSystem.save_path = out + "/unused_adventure_save.json"
	PracticeSaveSystem.save_path = out + "/unused_practice_save.json"
	PracticeSaveSystem.core_save_path = out + "/unused_core_save.json"
	call_deferred("run")

func ranks_for(points: int = 35, thief: int = 10) -> Dictionary:
	var ranks := {}
	if points == 35 or points == 32:
		for talent in registry.trees["tree.bladedancer"].talents: ranks[talent.id] = talent.max_ranks
		if points == 32:
			ranks.erase("talent.bladedancer.weapon_master")
			ranks.erase("talent.bladedancer.side_step")
	elif points == 10:
		ranks = {"talent.bladedancer.weakness":5,"talent.bladedancer.wet_stone":5}
	if thief > 0:
		ranks["talent.sticky_fingers"] = 5
		ranks["talent.thief.fast_hands"] = 5
	if thief == 13: ranks["talent.thief.bribery"] = 3
	return ranks

func gear_paths(variant: String) -> Array:
	if variant == "generated_endpoint":
		var fixture = load("res://tests/fixtures/exsanguinate_top_gear.gd")
		assert(fixture.validation_errors().is_empty(),str(fixture.validation_errors()))
		var paths := []
		var index := 0
		for item in fixture.items():
			var path := "%s/endpoint_%d.tres" % [out,index]
			assert(ResourceSaver.save(item,path) == OK)
			paths.append(path)
			index += 1
		return paths
	var names := ["nightkiss_kitana"]
	match variant:
		"crown": names.append("crown_of_concertation")
		"full_wing": names.append_array(["crown_of_concertation","cloak_of_speed","lolzorzs_locket","wingjammer"])
		"full_coin": names.append_array(["crown_of_concertation","cloak_of_speed","lolzorzs_locket","mysterious_lucky_coin"])
		"full_coil": names.append_array(["crown_of_concertation","cloak_of_speed","lolzorzs_locket","serpents_coil"])
		"signet_coin": names.append_array(["crown_of_concertation","cloak_of_speed","signet_of_the_old_kings","mysterious_lucky_coin"])
	var paths := []
	for name in names: paths.append("res://data/gear/%s.tres" % name)
	return paths

func scenario(id: String, points: int, thief: int, rotation: Array, gear: String = "solo", defense: Dictionary = {}) -> Dictionary:
	var ids := []
	for key in rotation: ids.append("skill."+key)
	var payload := {"build_schema_version":1,"content_revision":registry.revision,"allocation_mode":"ranked","class_id":"class.rogue","primary_tree_id":"tree.bladedancer","secondary_tree_id":"tree.thief" if thief > 0 else null,"earned_talent_points":points+thief,"talent_ranks":ranks_for(points,thief),"rotation_skill_ids":ids}
	var overrides := {"hp":1000000000}
	overrides.merge(defense,true)
	return {"id":id,"label":id,"class":"res://data/classes/rogue.tres","monster":"res://data/monsters/training_dummy.tres","monster_overrides":overrides,"ranked_build":payload,"gear":gear_paths(gear),"gold":0,"duration_ms":30000,"seed_start":1,"seed_count":seeds,"thresholds":{}}

func profiles() -> Array:
	var specs := [
		scenario("zero_fuel",0,0,["exsanguinate"]),
		scenario("low_0pt_stab_exsang",0,0,["stab","exsanguinate"]),
		scenario("low_10pt",10,0,["quick_cut","heavy_slash","exsanguinate"]),
		scenario("full35_only",35,0,USER_ROTATION),
		scenario("user_35bd_10thief",35,10,USER_ROTATION),
		scenario("control_same_weapon_no_exsang",35,10,USER_ROTATION.slice(0,5)),
		scenario("crown_only_added",35,10,USER_ROTATION,"crown"),
		scenario("five_legendaries_wing",35,10,USER_ROTATION,"full_wing"),
		scenario("five_legendaries_coin",35,10,USER_ROTATION,"full_coin"),
		scenario("five_legendaries_coil",35,10,USER_ROTATION,"full_coil"),
		scenario("five_legendaries_signet",35,10,USER_ROTATION,"signet_coin"),
		scenario("generated_endpoint_user_rotation",35,10,USER_ROTATION,"generated_endpoint"),
		scenario("generated_endpoint_short_rotation",35,10,["dance_of_death","quick_cut","exsanguinate"],"generated_endpoint"),
		scenario("optimized_solo",35,10,["dance_of_death","quick_cut","exsanguinate"]),
		scenario("optimized_full_coil",35,10,["dance_of_death","quick_cut","quick_cut","parry_strike","exsanguinate"],"full_coil"),
		scenario("optimized_full_coin",35,10,["dance_of_death","quick_cut","exsanguinate"],"full_coin"),
		scenario("optimized_signet_coin",35,10,["dance_of_death","quick_cut","exsanguinate"],"signet_coin"),
	]
	for defense in [
		{"id":"armor_block_resist","values":{"armor":1000,"block":100,"poison_resistance":0.9}},
		{"id":"dodge50","values":{"dodge_chance":0.5}},
		{"id":"dodge100","values":{"dodge_chance":1.0}},
		{"id":"slow50","values":{"slow":0.5}},
		{"id":"cleanse","values":{"cleanse_threshold":3}},
	]:
		specs.append(scenario("user_"+defense.id,35,10,USER_ROTATION,"solo",defense.values))
	var theft := ["dance_of_death","pick_pocket","steal","quick_cut","heavy_slash","parry_strike","leaping_plunge","exsanguinate"]
	specs.append(scenario("bribery_32bd_13thief",32,13,theft,"full_coin"))
	specs.append(scenario("bribery_dodge100",32,13,theft,"full_coin",{"dodge_chance":1.0}))
	return specs

func search() -> Array:
	var specs := []
	var rotations := [USER_ROTATION,
		["dance_of_death","quick_cut","exsanguinate"],
		["dance_of_death","quick_cut","heavy_slash","exsanguinate"],
		["dance_of_death","quick_cut","parry_strike","exsanguinate"],
		["dance_of_death","quick_cut","quick_cut","parry_strike","exsanguinate"],
		["dance_of_death","quick_cut","parry_strike","leaping_plunge","exsanguinate"],
		["dance_of_death","quick_cut","heavy_slash","parry_strike","exsanguinate"],
		["dance_of_death","quick_cut","heavy_slash","parry_strike","exsanguinate","leaping_plunge","exsanguinate"],
		["dance_of_death","quick_cut","heavy_slash","parry_strike","leaping_plunge","exsanguinate","exsanguinate"],
		["dance_of_death","exsanguinate","quick_cut","heavy_slash","parry_strike","leaping_plunge"],
	]
	for gear in ["solo","full_wing","full_coin","full_coil","signet_coin"]:
		for i in rotations.size(): specs.append(scenario("search_%s_%02d" % [gear,i],35,10,rotations[i],gear))
	return specs

func resolved_fields(spec: Dictionary) -> Dictionary:
	var decoded := BuildSaveCodec.decode(spec.ranked_build,registry)
	if decoded.get("error","") != "": return {"error":decoded.error}
	var gear: Array[GearItem] = []
	for path in spec.gear: gear.append(load(path))
	var resolved := BuildResolver.resolve_ranked_build(decoded["class"],decoded.model,gear,0)
	if resolved.error != "": return {"error":resolved.error}
	var p: PlayerStats = resolved.stats
	return {"shred_value":p.shred_value,"bonus_shred_stacks":p.bonus_shred_stacks,"shred_chance":p.shred_chance,"retrigger_chance":p.retrigger_chance,"attack_speed":p.attack_speed,"crit_chance":p.crit_chance,"cooldown_factor":p.cooldown_factor,"buff_duration":p.increased_buff_duration}

func run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	registry = BuildContentRegistry.test_mode()
	var specs := search() if phase == "search" else profiles()
	var invalid := 0
	for spec in specs:
		if only != "" and not spec.id.contains(only): continue
		var result := Lab.run_scenario_spec(spec,registry)
		result["study_spec"] = spec
		result["resolved_fields"] = resolved_fields(spec)
		SaveSystem.write_json(out+"/"+spec.id+".json",result)
		rows.append(result)
		if result.status == "pass":
			print("ROW ",spec.id," removal=",result.aggregate.total_health_removed.mean," ordinary=",result.aggregate.total_damage.mean)
		else:
			invalid += 1
			print("INVALID ROW ",spec.id," ",result.notes)
		SaveSystem.write_json(out+"/summary.json",{"duration_ms":30000,"seed_count":seeds,"phase":phase,"complete":false,"invalid_scenarios":invalid,"rows":rows})
	SaveSystem.write_json(out+"/summary.json",{"duration_ms":30000,"seed_count":seeds,"phase":phase,"complete":true,"invalid_scenarios":invalid,"rows":rows})
	print("PASS Exsanguinate study execution rows=",rows.size()," invalid_scenarios=",invalid)
	quit()
