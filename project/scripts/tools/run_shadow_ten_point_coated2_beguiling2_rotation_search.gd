extends SceneTree
const Lab = preload("res://scripts/tools/balance_lab.gd")
const OUT = "res://reports/balance/shadow_ten_point_coated2_beguiling2_rotation_search"
const CASES := [
 {"tree":"shadow","ranks":{"talent.shadow.snake_oil":4,"talent.shadow.coated_weapons":1,"talent.shadow.blind_spot":5},"rotation":["stab"],"principal":["stab","heavy_slash","toxic_flurry","distilled_corruption","killers_mark","touch_of_darkness"]}
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
 if ids.is_empty(): return
 for period in range(1,ids.size()):
  if ids.size() % period != 0: continue
  var repeated := true
  for index in range(ids.size()):
   if ids[index] != ids[index % period]: repeated = false
  if repeated: return
 var key := JSON.stringify(ids)
 if not candidates.has(key): candidates[key]=score(ids,1,5)
func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 var registry := BuildContentRegistry.test_mode()
 var rows := []
 for entry in CASES:
  var model := RankedBuild.new()
  assert(model.configure(registry.trees["tree."+entry.tree],null,10,entry.ranks))
  var gear: Array[GearItem] = [load("res://data/gear/crude_dagger.tres")]
  var content := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],model,gear,0)
  assert(content.error=="")
  stats=content.stats
  skills={}
  for skill in content.skills:
   var trial: Skill = skill.duplicate(true)
   if trial.id in ["skill.stab","skill.heavy_slash"]:
    assert(trial.poison_stacks_applied == 1)
    trial.poison_stacks_applied = 2
    var count := 0
    for effect in trial.effects:
     if effect is PoisonDamageEffect:
      assert(effect.stacks_applied == 1)
      effect.stacks_applied = 2
      count += 1
    assert(count == 1)
   if trial.id == "skill.toxic_flurry":
    var decay_effect: PoisonResistanceReductionEffect
    var count := 0
    for effect in trial.effects:
     if effect is PoisonResistanceReductionEffect:
      decay_effect = effect
      count += 1
    assert(count == 1)
    # Resolver sums one Decay stack per reduction effect, then applies stack bonuses once.
    # A second cloned carrier therefore changes only this skill's base Decay from 1 to 2.
    trial.effects.append(decay_effect.duplicate(true))
   skills[trial.id.trim_prefix("skill.")] = trial
  enemy=load("res://data/monsters/training_dummy.tres").duplicate(true)
  enemy.hp=100000000
  var probe_rotation: Array[Skill] = [skills["toxic_flurry"]]
  var probe := CombatResolver.resolve(probe_rotation,stats,enemy,30000,1)
  assert(probe.is_valid and probe.cast_events[0].decay_stacks_applied == 2)
  rng.seed=180010
  candidates={}
  add(entry.rotation)
  for ids in [["heavy_slash"],["stab","heavy_slash"],["stab","killers_mark"],["stab","touch_of_darkness"],["stab","stab","stab","touch_of_darkness"],["stab","stab","stab","stab","stab","touch_of_darkness"],["stab","killers_mark","stab","touch_of_darkness","killers_mark"]]: add(ids)
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
  for trial in range(300):
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
  var screen_ids := {}
  for row in ranked.slice(0,50):
   screened.append(score(row.rotation,1,30))
   screen_ids[JSON.stringify(row.rotation)] = true
  var beguiling_added := 0
  for row in ranked:
   if "toxic_flurry" in row.rotation and not screen_ids.has(JSON.stringify(row.rotation)):
    screened.append(score(row.rotation,1,30))
    beguiling_added += 1
    if beguiling_added == 10: break
  screened.sort_custom(func(a,b):return a.dps.mean>b.dps.mean)
  var finalists := []
  for row in screened.slice(0,15): finalists.append(score(row.rotation,1,200))
  var best_beguiling := 0
  var finalist_ids := {}
  for row in finalists: finalist_ids[JSON.stringify(row.rotation)] = true
  for row in screened:
   if "toxic_flurry" in row.rotation:
    if not finalist_ids.has(JSON.stringify(row.rotation)): finalists.append(score(row.rotation,1,200))
    best_beguiling += 1
    if best_beguiling == 5: break
  var old_winner := score(["stab","heavy_slash","heavy_slash"],1,200)
  if not finalist_ids.has(JSON.stringify(old_winner.rotation)): finalists.append(old_winner)
  finalists.sort_custom(func(a,b):return a.dps.mean>b.dps.mean)
  var baseline:=score(entry.rotation,1,200)
  var heldout:=[]
  for row in finalists.slice(0,5): heldout.append(score(row.rotation,201,200))
  heldout.append(score(entry.rotation,201,200))
  for row in finalists:
   if "toxic_flurry" in row.rotation:
    heldout.append(score(row.rotation,201,200))
    break
  assert(is_equal_approx(baseline.dps.mean,29.2395),"Two-stack baseline agrees with prior trial")
  var report: Dictionary={"tree":entry.tree,"ranks":entry.ranks,"unlocked_skills":pool,"candidates":candidates.size(),"baseline":baseline,"finalists":finalists,"heldout":heldout,"coated_weapons_stacks":2,"beguiling_strike_decay_stacks":2,"decay_probe_passed":true,"live_content_changed":false}
  SaveSystem.write_json(OUT+"/"+entry.tree+".json",report)
  rows.append(report)
  print(JSON.stringify({"tree":entry.tree,"baseline":baseline,"top":finalists.slice(0,5),"heldout":heldout}))
 SaveSystem.write_json(OUT+"/summary.json",{"rows":rows,"scope":"Fixed user 10-point allocations, live D018 with resolved-skill-only Coated Weapons 2 Poison / Beguiling Strike 2 Decay trial, 30s zero-defense dummy, Crude Dagger only, zero stash. Heuristic rotation search, not proof of global optimum."})
 quit()
