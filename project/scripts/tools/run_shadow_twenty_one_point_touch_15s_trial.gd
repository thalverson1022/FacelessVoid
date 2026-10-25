extends SceneTree
const Consume = preload("res://scripts/resources/consume_status_effect.gd")
const Lab = preload("res://scripts/tools/balance_lab.gd")
const OUT = "res://reports/balance/shadow_twenty_one_point_touch_15s_trial"
const CASES := [
 {"tree":"shadow","ranks":{"talent.shadow.snake_oil":4,"talent.shadow.coated_weapons":1,"talent.shadow.deception":5,"talent.shadow.death_touch":3,"talent.shadow.death_pact":2,"talent.shadow.shadow_mastery":2,"talent.shadow.dusk_strike":1,"talent.shadow.death_blade":2,"talent.umbral_pressure":1},"rotation":["toxic_flurry","distilled_corruption","killers_mark","toxic_flurry","distilled_corruption","killers_mark","touch_of_darkness","beguiling_presence"],"principal":["stab","killers_mark","touch_of_darkness","beguiling_presence","toxic_flurry","distilled_corruption"]}
]
var stats: PlayerStats
var skills := {}
var enemy: Monster
var candidates := {}
var rng := RandomNumberGenerator.new()
func _initialize() -> void:
 SaveSystem.save_path=OUT+"/isolated_save.json"
 PracticeSaveSystem.save_path=OUT+"/isolated_practice.json"
 PracticeSaveSystem.core_save_path=OUT+"/isolated_core.json"
 call_deferred("run")
func score(ids: Array, start: int, count: int) -> Dictionary:
 var rotation: Array[Skill] = []
 for id in ids:
  assert(skills.has(id))
  rotation.append(skills[id])
 var values := []
 for seed in range(start,start+count):
  var result := CombatResolver.resolve(rotation,stats,enemy,30000,seed)
  assert(result.is_valid and result.duration_ms==30000)
  values.append(result.dps)
 return {"rotation":ids.duplicate(),"dps":Lab._distribution(values),"seed_start":start}
func add(ids: Array) -> void:
 # Repeated copies of an identical cycle are the same macro.
 for period in range(1,ids.size()):
  if ids.size()%period!=0: continue
  var repeats := true
  for n in range(ids.size()):
   if ids[n]!=ids[n%period]: repeats=false
  if repeats: return
 var key := JSON.stringify(ids)
 if not candidates.has(key): candidates[key]=score(ids,1,5)
func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 var registry := BuildContentRegistry.test_mode()
 var rows := []
 for entry in CASES:
  var model := RankedBuild.new()
  assert(model.configure(registry.trees["tree."+entry.tree],null,21,entry.ranks))
  var gear: Array[GearItem] = [load("res://data/gear/crude_dagger.tres")]
  var content := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],model,gear,0)
  assert(content.error=="")
  stats=content.stats
  skills={}
  for skill in content.skills: skills[skill.id.trim_prefix("skill.")]=skill
  enemy=load("res://data/monsters/training_dummy.tres").duplicate(true)
  enemy.hp=100000000
  assert(skills["beguiling_presence"].cooldown_ms == 30000)
  var macros := [
   {"name":"Prior optimized ten-slot", "ids":["toxic_flurry","distilled_corruption","distilled_corruption","toxic_flurry","killers_mark","distilled_corruption","killers_mark","killers_mark","touch_of_darkness","distilled_corruption"]},
   {"name":"Short six-slot", "ids":["toxic_flurry","distilled_corruption","touch_of_darkness","killers_mark","distilled_corruption","killers_mark"]}
  ]
  var baselines := []
  for macro in macros: baselines.append(score(macro.ids,1,200))
  assert(is_equal_approx(baselines[0].dps.mean,134.897333333333))
  var touch: Skill = skills["touch_of_darkness"].duplicate(true)
  assert(touch.cooldown_ms == 30000)
  touch.cooldown_ms = 15000
  skills["touch_of_darkness"] = touch
  for index in range(macros.size()):
   var trial := score(macros[index].ids,1,200)
   var heldout := score(macros[index].ids,201,200)
   var row := {"name":macros[index].name,"baseline":baselines[index],"trial":trial,"heldout":heldout,"increase":trial.dps.mean-baselines[index].dps.mean,"percent_increase":100*(trial.dps.mean/baselines[index].dps.mean-1)}
   rows.append(row)
   print(JSON.stringify(row))
  SaveSystem.write_json(OUT+"/comparison.json",{"rows":rows,"touch_cooldown_ms":15000,"presence_cooldown_ms":30000,"live_content_changed":false,"duration_ms":30000,"seed_count":200})
 quit()
