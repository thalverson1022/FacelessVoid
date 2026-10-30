extends SceneTree
const Lab = preload("res://scripts/tools/balance_lab.gd")
const OUT = "res://reports/balance/shadow_twenty_one_point_screenshot_rotation_search_d019"
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
  rng.seed=180010
  candidates={}
  var baseline := score(entry.rotation,1,200)
  print("User macro baseline DPS: ",baseline.dps.mean)
  SaveSystem.write_json(OUT+"/baseline.json",baseline)
  add(entry.rotation)
  for ids in [
   ["toxic_flurry","distilled_corruption","touch_of_darkness","distilled_corruption","killers_mark"],
   ["toxic_flurry","distilled_corruption","beguiling_presence","toxic_flurry","killers_mark","distilled_corruption","killers_mark","killers_mark","touch_of_darkness","distilled_corruption"],
   ["toxic_flurry","distilled_corruption","toxic_flurry","killers_mark","distilled_corruption","killers_mark","touch_of_darkness","distilled_corruption"],
   ["toxic_flurry","distilled_corruption","killers_mark"],
   ["toxic_flurry","distilled_corruption","touch_of_darkness","killers_mark"],
   ["stab","heavy_slash","heavy_slash"]
  ]: add(ids)
  var pool: Array=skills.keys()
  print("Unlocked Shadow skills: ",pool)
  var principal: Array=[]
  for id in entry.principal:
   if skills.has(id): principal.append(id)
  # Exhaust principal sequences through four/five slots and every legal skill through three.
  for config in [[principal,4],[pool,3]]:
   var frontier: Array=[[]]
   for length in range(1,int(config[1])+1):
    var next: Array=[]
    for parent in frontier:
     for id in config[0]:
      var ids: Array=parent.duplicate()
      ids.append(id)
      add(ids)
      next.append(ids)
    frontier=next
  for trial in range(400):
   var ids := []
   for n in range(rng.randi_range(4,10)): ids.append(pool[rng.randi_range(0,pool.size()-1)])
   add(ids)
  for generation in range(2):
   var ranked: Array=candidates.values()
   ranked.sort_custom(func(a,b):return a.dps.mean>b.dps.mean)
   for parent in ranked.slice(0,8):
    for trial in range(25):
     var ids: Array=parent.rotation.duplicate()
     var pos:=rng.randi_range(0,ids.size()-1)
     var op:=rng.randi_range(0,2)
     var chosen=pool[rng.randi_range(0,pool.size()-1)]
     if op==0: ids[pos]=chosen
     elif op==1 and ids.size()<10: ids.insert(pos,chosen)
     elif ids.size()>1: ids.remove_at(pos)
     add(ids)
  print(entry.tree," candidates: ",candidates.size())
  var ranked: Array=candidates.values()
  ranked.sort_custom(func(a,b):return a.dps.mean>b.dps.mean)
  var screened := []
  for row in ranked.slice(0,50): screened.append(score(row.rotation,1,30))
  screened.sort_custom(func(a,b):return a.dps.mean>b.dps.mean)
  var finalists := []
  for row in screened.slice(0,15): finalists.append(score(row.rotation,1,200))
  finalists.sort_custom(func(a,b):return a.dps.mean>b.dps.mean)
  var heldout:=[]
  for row in finalists.slice(0,5): heldout.append(score(row.rotation,201,200))
  heldout.append(score(entry.rotation,201,200))
  var practice := TrainingRoomState.new()
  practice.content_registry=registry
  practice.selected_class=registry.classes["class.rogue"]
  practice.ranked_build=model
  practice.selected_trees=model.trees()
  practice.earned_talent_points=21
  practice.equipped_weapon=gear[0]
  practice.set_practice_gold(0)
  var winner: Array[Skill]=[]
  for id in finalists[0].rotation: winner.append(skills[id])
  practice.set_rotation(winner)
  practice.set_duration_ms(30000)
  practice.set_fight_seed(1)
  practice.set_locked(true)
  practice.run_fight()
  var direct := CombatResolver.resolve(winner,stats,enemy,30000,1)
  assert(practice.last_result!=null and is_equal_approx(practice.last_result.dps,direct.dps))
  var simple := []
  for row in screened:
   if row.rotation.size() <= 5:
    simple.append(score(row.rotation,1,200))
    if simple.size() == 5: break
  simple.sort_custom(func(a,b):return a.dps.mean>b.dps.mean)
  if not simple.is_empty(): heldout.append(score(simple[0].rotation,201,200))
  var report: Dictionary={"tree":entry.tree,"ranks":entry.ranks,"unlocked_skills":pool,"candidates":candidates.size(),"baseline":baseline,"finalists":finalists,"simple_finalists":simple,"heldout":heldout,"practice_seed1_parity":true,"practice_seed1_dps":direct.dps}
  SaveSystem.write_json(OUT+"/"+entry.tree+".json",report)
  rows.append(report)
  print(JSON.stringify({"tree":entry.tree,"baseline":baseline,"top":finalists.slice(0,5),"heldout":heldout}))
 SaveSystem.write_json(OUT+"/summary.json",{"rows":rows,"scope":"Fixed user screenshot 21-point allocation, live D019, 30s zero-defense dummy, Crude Dagger only, zero stash. Heuristic rotation search, not proof of global optimum."})
 quit()
