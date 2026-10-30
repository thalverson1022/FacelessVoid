extends SceneTree
const Consume = preload("res://scripts/resources/consume_status_effect.gd")
const Lab = preload("res://scripts/tools/balance_lab.gd")
const OUT = "res://reports/balance/shadow_twenty_one_point_touch_physical_05_trial"
const CASES := [
 {"tree":"shadow","ranks":{"talent.shadow.snake_oil":4,"talent.shadow.coated_weapons":1,"talent.shadow.deception":5,"talent.shadow.death_touch":3,"talent.shadow.death_pact":2,"talent.shadow.shadow_mastery":2,"talent.shadow.dusk_strike":1,"talent.shadow.death_blade":2,"talent.umbral_pressure":1},"rotation":["toxic_flurry","distilled_corruption","killers_mark","toxic_flurry","distilled_corruption","killers_mark","touch_of_darkness","beguiling_presence"],"principal":["stab","killers_mark","touch_of_darkness","beguiling_presence","toxic_flurry","distilled_corruption"]}
]
const Trial = preload("res://scripts/tools/shadow_touch_physical_trial_resolver.gd")
var engine = CombatResolver
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
  var result := engine.resolve(rotation,stats,enemy,30000,seed)
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
  assert(skills["touch_of_darkness"].cooldown_ms == 30000)
  assert(stats.shred_value == 10)
  stats.shred_value += 10
  if stats.derivation_base != null: stats.derivation_base.shred_value += 10
  var baseline := score(entry.rotation,1,200)
  assert(is_equal_approx(baseline.dps.mean,111.155333333333))
  engine = Trial
  var control := score(entry.rotation,1,200)
  assert(is_equal_approx(control.dps.mean,baseline.dps.mean),"Trial engine reproduces live damage before override")
  stats.special_effects["trial_touch_physical_per_stack"] = 0.5
  if stats.derivation_base != null: stats.derivation_base.special_effects["trial_touch_physical_per_stack"] = 0.5
  var trial := score(entry.rotation,1,200)
  var heldout := score(entry.rotation,201,200)
  var rotation: Array[Skill] = []
  for id in entry.rotation: rotation.append(skills[id])
  var sample := engine.resolve(rotation,stats,enemy,30000,1,true)
  assert(sample.is_valid)
  var row := {"baseline":baseline,"engine_control":control,"trial":trial,"heldout":heldout,"increase":trial.dps.mean-baseline.dps.mean,"percent_increase":100*(trial.dps.mean/baseline.dps.mean-1),"touch_cooldown_ms":30000,"presence_cooldown_ms":30000,"shred_value":20,"touch_physical_per_consumed":0.5,"touch_duration_ms":8000,"live_content_changed":false}
  SaveSystem.write_json(OUT+"/comparison.json",row)
  print(JSON.stringify(row))
 quit()
