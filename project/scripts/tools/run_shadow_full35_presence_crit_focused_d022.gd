extends SceneTree
const Lab = preload("res://scripts/tools/balance_lab.gd")
const OUT = "res://reports/balance/shadow_full35_presence_crit_focused_d022"
const CASES := [
 {"tree":"shadow","ranks":{"talent.shadow.snake_oil":1,"talent.shadow.coated_weapons":1,"talent.shadow.blind_spot":5,"talent.shadow.deception":1,"talent.shadow.death_from_the_shadows":4,"talent.shadow.death_touch":3,"talent.shadow.death_pact":2,"talent.shadow.shadow_mastery":2,"talent.shadow.dusk_strike":1},"rotation":["toxic_flurry","distilled_corruption","touch_of_darkness","distilled_corruption","killers_mark"],"principal":["stab","killers_mark","touch_of_darkness","beguiling_presence","toxic_flurry","distilled_corruption"]}
]
const Trial = preload("res://scripts/tools/shadow_presence_crit_trial_resolver.gd")
const TrialBuffs = preload("res://scripts/tools/shadow_presence_crit_trial_self_buffs.gd")
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
 if not candidates.has(key): candidates[key]=score(ids,1,10)
func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 var registry := BuildContentRegistry.test_mode()
 var rows := []
 for entry in CASES.duplicate(true):
  var model := RankedBuild.new()
  var full_ranks := {}
  var total_points := 0
  for talent in registry.trees["tree.shadow"].talents:
   full_ranks[talent.id]=talent.max_ranks
   total_points+=talent.max_ranks
  assert(total_points==35)
  assert(model.configure(registry.trees["tree.shadow"],null,35,full_ranks))
  var gear: Array[GearItem] = [load("res://data/gear/crude_dagger.tres")]
  var content := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],model,gear,0)
  assert(content.error=="")
  stats=content.stats
  skills={}
  for skill in content.skills: skills[skill.id.trim_prefix("skill.")]=skill
  enemy=load("res://data/monsters/training_dummy.tres").duplicate(true)
  enemy.hp=100000000
  assert(stats.shred_value == 20)
  assert(skills["touch_of_darkness"].cooldown_ms == 30000 and skills["beguiling_presence"].cooldown_ms == 30000)
  var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://reports/balance/shadow_full35_rotation_search_d021/shadow.json"))
  entry.rotation = old.finalists[0].rotation
  var live_control := score(entry.rotation,1,1)
  assert(is_equal_approx(live_control.dps.mean,288.1))
  engine = Trial
  TrialBuffs.presence_crit_per_stack = 0.0
  var engine_control := score(entry.rotation,1,1)
  assert(is_equal_approx(engine_control.dps.mean,live_control.dps.mean))
  TrialBuffs.presence_crit_per_stack = 0.01
  candidates = {}
  for position in range(entry.rotation.size()):
   var ids: Array = entry.rotation.duplicate()
   ids[position] = "beguiling_presence"
   add(ids)
  for setup in range(1,5):
   for deaths in range(1,4):
    var ids: Array = []
    for n in range(setup): ids.append("toxic_flurry")
    ids.append_array(["beguiling_presence","toxic_flurry","distilled_corruption","touch_of_darkness","distilled_corruption"])
    for n in range(deaths): ids.append("killers_mark")
    if ids.size() <= 10: add(ids)
  for ids in [
   ["toxic_flurry","distilled_corruption","distilled_corruption","toxic_flurry","beguiling_presence","killers_mark","killers_mark","killers_mark","touch_of_darkness"],
   ["toxic_flurry","distilled_corruption","distilled_corruption","toxic_flurry","beguiling_presence","distilled_corruption","killers_mark","killers_mark","touch_of_darkness"],
   ["toxic_flurry","distilled_corruption","touch_of_darkness","beguiling_presence","toxic_flurry","distilled_corruption","killers_mark","killers_mark"],
   ["toxic_flurry","distilled_corruption","touch_of_darkness","beguiling_presence","toxic_flurry","distilled_corruption","killers_mark","killers_mark","killers_mark"]
  ]: add(ids)
  var ranked: Array = candidates.values()
  ranked.sort_custom(func(a,b):return a.dps.mean>b.dps.mean)
  var finalists := []
  for row in ranked.slice(0,3):finalists.append(score(row.rotation,1,200))
  finalists.sort_custom(func(a,b):return a.dps.mean>b.dps.mean)
  var heldout := score(finalists[0].rotation,201,200)
  var winner: Array[Skill] = []
  for id in finalists[0].rotation:winner.append(skills[id])
  var sample = engine.resolve(winner,stats,enemy,30000,1,true)
  var verified := false
  for event in sample.cast_events:
   if event.stat_snapshot.has("self_buffs") and event.stat_snapshot.self_buffs.crit_chance > 0:
    assert(is_equal_approx(event.stat_snapshot.effective_crit_chance,clampf(stats.crit_chance+event.stat_snapshot.self_buffs.crit_chance,0.0,1.0)))
    verified = true
  assert(verified,"Presence crit bonus applies to actual attack rolls")
  var result := {"candidates":candidates.size(),"finalists":finalists,"heldout":heldout,"combat_crit_verified":true,"live_content_changed":false}
  SaveSystem.write_json(OUT+"/comparison.json",result)
  print(JSON.stringify(result))
 quit()
