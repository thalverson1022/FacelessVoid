extends SceneTree
## User's exact 35-point builds; current live content, no balance overrides.
const Lab = preload("res://scripts/tools/balance_lab.gd")
const OUT := "res://reports/balance/full35_comparison_d021_live"
const CASES := [
  {
    "tree": "bladedancer",
    "rotation": ["dance_of_death","quick_cut","stab","quick_cut","parry_strike","quick_cut","leaping_plunge"]
  },
  {
    "tree": "thief",
    "rotation": [
      "pick_pocket",
      "steal",
      "big_score",
      "big_score",
      "mug",
      "big_score"
    ]
  },
  {
    "tree": "assassin",
    "rotation": [
      "virulent_poison",
      "poison_vile",
      "poison_strike",
      "poison_strike"
    ]
  },
 {"tree": "shadow", "rotation": ["toxic_flurry", "distilled_corruption", "distilled_corruption", "toxic_flurry", "distilled_corruption", "distilled_corruption", "killers_mark", "killers_mark", "killers_mark", "touch_of_darkness"]}
]
var failed := false
func _initialize() -> void:
	SaveSystem.save_path = OUT + "/isolated_save.json"
	PracticeSaveSystem.save_path = OUT + "/isolated_practice.json"
	PracticeSaveSystem.core_save_path = OUT + "/isolated_core.json"
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		printerr(message)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var registry := BuildContentRegistry.test_mode()
	var rows := []
	for entry in CASES:
		var ranks := {}
		var points := 0
		for talent in registry.trees["tree."+entry.tree].talents:
			ranks[talent.id] = talent.max_ranks
			points += talent.max_ranks
		check(points == 35,"Full tree has exactly 35 ranks")
		var ids := []
		for key in entry.rotation:
			var skill_id: String = "skill." + key
			if key == "rending_slash": skill_id = "skill.rending_thrust"
			if key == "parrying_strike": skill_id = "skill.parry_strike"
			ids.append(skill_id)
		var payload := {"build_schema_version":1,"content_revision":registry.revision,"allocation_mode":"ranked","class_id":"class.rogue","primary_tree_id":"tree."+entry.tree,"secondary_tree_id":null,"earned_talent_points":35,"talent_ranks":ranks,"rotation_skill_ids":ids}
		var spec := {"id":entry.tree,"label":"Exact user 35-point build / Crude Dagger / 30 seconds","ranked_build":payload,"monster":"res://data/monsters/training_dummy.tres","monster_overrides":{"hp":100000000},"gear":["res://data/gear/crude_dagger.tres"],"gold":0,"duration_ms":30000,"seed_start":1,"seed_count":200}
		var result := Lab.run_scenario_spec(spec,registry)
		check(result.status=="pass", "Lab failed: " + JSON.stringify(result))
		if result.status!="pass": continue
		SaveSystem.write_json(OUT+"/"+entry.tree+".json",result)
		var decoded := BuildSaveCodec.decode(payload,registry)
		var practice := TrainingRoomState.new()
		practice.content_registry = registry
		practice.selected_class = registry.classes["class.rogue"]
		practice.ranked_build = decoded.model
		practice.selected_trees = decoded.model.trees()
		practice.earned_talent_points = 35
		practice.equipped_weapon = load("res://data/gear/crude_dagger.tres")
		var rotation: Array[Skill] = []
		for id in ids:
			for skill in practice.unlocked_skills():
				if skill.id==id: rotation.append(skill)
		practice.set_practice_gold(int(spec.gold))
		practice.set_rotation(rotation)
		practice.set_duration_ms(30000)
		practice.set_fight_seed(1)
		practice.set_locked(true)
		practice.run_fight()
		check(practice.last_result!=null,"Practice produced result")
		if practice.last_result==null: continue
		var summary := Lab._combat_summary(1,practice.last_result)
		check(practice.last_result.duration_ms==30000,"Full 30-second window")
		check(is_equal_approx(summary.dps,result.samples[0].dps),"Practice and Lab seed-1 parity")
		var row := {"tree":entry.tree,"seed_1":summary,"dps":result.aggregate.dps,"mean_direct_dps":result.aggregate.physical_damage.mean/30.0,"mean_poison_dps":result.aggregate.poison_damage.mean/30.0,"spec":spec}
		rows.append(row)
		print(JSON.stringify(row))
	SaveSystem.write_json(OUT+"/summary.json",{"passed":not failed,"content_revision":registry.revision,"rows":rows})
	quit(1 if failed else 0)
