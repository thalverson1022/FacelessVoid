extends SceneTree
const Consume = preload("res://scripts/resources/consume_status_effect.gd")
const Lab = preload("res://scripts/tools/balance_lab.gd")
const OUT = "res://reports/balance/shadow_twenty_one_point_presence_winner_comparison"
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
  var source: Skill = skills["beguiling_presence"]
  var ids: Array = ["toxic_flurry","toxic_flurry","beguiling_presence","toxic_flurry","distilled_corruption","touch_of_darkness","distilled_corruption","killers_mark"]
  var comparisons := []
  for variant in [{"damage":1.0,"cooldown":30000},{"damage":2.0,"cooldown":15000}]:
   var presence: Skill = source.duplicate(true)
   presence.cooldown_ms = variant.cooldown
   for effect in presence.effects:
    if effect is Consume: effect.elemental_per_consumed = variant.damage
   skills["beguiling_presence"] = presence
   var row := score(ids,1,200)
   row["heldout"] = score(ids,201,200)
   row["per_consumed_stack"] = variant.damage
   row["cooldown_ms"] = variant.cooldown
   comparisons.append(row)
   print(JSON.stringify(row))
  SaveSystem.write_json(OUT+"/comparison.json",{"rows":comparisons,"live_content_changed":false})
 quit()
