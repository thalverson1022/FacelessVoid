extends SceneTree
const Lab = preload("res://scripts/tools/balance_lab.gd")
const OUT := "res://reports/balance/full35_isolated_mechanics_d018"
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
 {"tree": "shadow", "rotation": ["toxic_flurry", "distilled_corruption", "touch_of_darkness", "distilled_corruption", "killers_mark"]}
]

func _initialize() -> void:
 SaveSystem.save_path = OUT + "/isolated_save.json"
 PracticeSaveSystem.save_path = OUT + "/isolated_practice.json"
 PracticeSaveSystem.core_save_path = OUT + "/isolated_core.json"
 call_deferred("run")
func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 var registry := BuildContentRegistry.test_mode()
 var bosses: Array = JSON.parse_string(FileAccess.get_file_as_string("res://reports/balance/full35_random_bosses_d018/isolated_mechanics.json")).bosses
 SaveSystem.write_json(OUT+"/bosses.json",{"bosses":bosses})
 var rows := []
 for index in range(bosses.size()+1):
  for entry in CASES:
   var ranks := {}
   var points := 0
   for talent in registry.trees["tree."+entry.tree].talents:
    ranks[talent.id] = talent.max_ranks
    points += talent.max_ranks
   assert(points == 35)
   var ids := []
   for key in entry.rotation: ids.append("skill."+key)
   var payload := {"build_schema_version":1,"content_revision":registry.revision,"allocation_mode":"ranked","class_id":"class.rogue","primary_tree_id":"tree."+entry.tree,"secondary_tree_id":null,"earned_talent_points":35,"talent_ranks":ranks,"rotation_skill_ids":ids}
   var spec := {"id":"%02d_%s"%[index,entry.tree],"label":"35-point / Crude Dagger / random Ultra boss / 30 seconds","ranked_build":payload,"gear":["res://data/gear/crude_dagger.tres"],"gold":0,"duration_ms":30000,"seed_start":1,"seed_count":100}
   if index == 0:
    spec.monster = "res://data/monsters/training_dummy.tres"
    spec.monster_overrides = {"hp":791}
   else:
    spec.generated_monster = bosses[index-1].draft
   var result := Lab.run_scenario_spec(spec,registry)
   if result.status != "pass":
    printerr(JSON.stringify(result))
    quit(1)
    return
   SaveSystem.write_json(OUT+"/"+spec.id+".json",result)
   rows.append({"boss_index":index-1,"tree":entry.tree,"rotation":result.rotation,"aggregate":result.aggregate})
  SaveSystem.write_json(OUT+"/summary.json",{"content_revision":registry.revision,"seed_count":100,"duration_ms":30000,"rows":rows,"bosses":bosses,"complete":index==bosses.size()})
  print("Completed encounter %d/%d"%[index,bosses.size()])
 quit(0)
func make_boss(index: int, a: String, b: String, library: RuntimeArchetypeLibrary) -> Dictionary:
 var input := RuntimeGenerationInput.from_dictionary({"seed":351001+index,"archetype_a_id":a,"archetype_b_id":b,"difficulty_id":4,"monster_kind":"boss","tempo_profile":"extended"})
 var draft := RuntimeMonsterGenerator.generate(input,library)
 assert(not draft.has_errors(),JSON.stringify(draft.to_dictionary()))
 return {"index":index,"archetype_a":a,"archetype_b":b,"input":input.to_dictionary(),"draft":draft.to_dictionary()}

