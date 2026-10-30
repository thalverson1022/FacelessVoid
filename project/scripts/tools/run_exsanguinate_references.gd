extends SceneTree
const Lab = preload("res://scripts/tools/balance_lab.gd")
const OUT := "res://reports/balance/exsanguinate_study/weapon_references_200"
func _initialize() -> void: call_deferred("run")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://reports/balance/exsanguinate_study/profiles_200/control_same_weapon_no_exsang.json"))
	# JSON numbers become floats; restore the known typed build contract from
	# this runner's own generated scenario, without relaxing production decoding.
	source.study_spec.ranked_build.build_schema_version = int(source.study_spec.ranked_build.build_schema_version)
	source.study_spec.ranked_build.earned_talent_points = int(source.study_spec.ranked_build.earned_talent_points)
	for id in source.study_spec.ranked_build.talent_ranks:
		source.study_spec.ranked_build.talent_ranks[id] = int(source.study_spec.ranked_build.talent_ranks[id])
	var protocol := ["skill.dance_of_death","skill.quick_cut","skill.quick_cut","skill.parry_strike","skill.quick_cut","skill.stab","skill.leaping_plunge"]
	var rows := []
	var registry := BuildContentRegistry.test_mode()
	for entry in [
		{"id":"mithril_user_rotation","weapon":"mithril_karambit","rotation":source.study_spec.ranked_build.rotation_skill_ids},
		{"id":"mithril_protocol_rotation","weapon":"mithril_karambit","rotation":protocol},
		{"id":"nightkiss_protocol_no_exsang","weapon":"nightkiss_kitana","rotation":protocol},
	]:
		var spec: Dictionary = source.study_spec.duplicate(true)
		spec.id = entry.id
		spec.label = entry.id
		spec.gear = ["res://data/gear/%s.tres" % entry.weapon]
		spec.ranked_build.rotation_skill_ids = entry.rotation
		var result := Lab.run_scenario_spec(spec,registry)
		assert(result.status == "pass",str(result.notes))
		result["study_spec"] = spec
		SaveSystem.write_json(OUT+"/"+entry.id+".json",result)
		rows.append(result)
		print("REFERENCE ",entry.id," damage=",result.aggregate.total_damage.mean)
	SaveSystem.write_json(OUT+"/summary.json",{"complete":true,"rows":rows,"invalid_scenarios":0})
	print("PASS matched weapon references rows=",rows.size())
	quit()
