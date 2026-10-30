extends SceneTree
const Consume = preload("res://scripts/resources/consume_status_effect.gd")
const Lab = preload("res://scripts/tools/balance_lab.gd")
const OUT = "res://reports/balance/shadow_twenty_one_point_presence_trial_probe"
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
  var current_ids: Array = ["toxic_flurry","distilled_corruption","distilled_corruption","toxic_flurry","killers_mark","distilled_corruption","killers_mark","killers_mark","touch_of_darkness","distilled_corruption"]
  var live_control := score(current_ids,1,200)
  assert(is_equal_approx(live_control.dps.mean,134.897333333333),"Live D020 baseline reproduced")
  var presence: Skill = skills["beguiling_presence"].duplicate(true)
  assert(presence.cooldown_ms == 30000)
  presence.cooldown_ms = 15000
  var adjusted := 0
  for effect in presence.effects:
   if effect is Consume:
    assert(effect.elemental_per_consumed == 1.0)
    effect.elemental_per_consumed = 2.0
    adjusted += 1
  assert(adjusted == 1)
  skills["beguiling_presence"] = presence
  var probe: Array[Skill] = [skills["toxic_flurry"],presence]
  var probe_result := CombatResolver.resolve(probe,stats,enemy,2200,1,true)
  assert(probe_result.is_valid)
  var grants := []
  for record in probe_result.trace.records:
   if record.get("type", "") == "effect_lifecycle": grants.append(record)
  var presence_cast: CombatResolver.CastEvent
  for event in probe_result.cast_events:
   if event.skill.id == "skill.beguiling_presence": presence_cast = event
  assert(presence_cast != null)
  assert(presence_cast.cooldown_available_at_ms == presence_cast.time_ms + 15000,"Cooldown begins at completion and lasts fifteen seconds")
  var instance := {}
  for record in probe_result.trace.records:
   if record.kind == "effect_lifecycle" and record.lifecycle_reason == "granted" and record.payload.effect_id == "beguiling_presence":
    instance = record.payload.after
    break
  assert(not instance.is_empty())
  assert(instance.units == 10 and instance.magnitude == 20 and instance.expires_at_ms == presence_cast.time_ms + 10000,"Actual consumed count, doubled magnitude, and unchanged ten-second duration")
  SaveSystem.write_json(OUT+"/verification.json",{"passed":true,"consumed_decay":instance.units,"elemental_base_granted":instance.magnitude,"buff_duration_ms":10000,"cooldown_ms":15000,"live_content_changed":false})
  print("Presence trial probe PASS: 10 consumed, +20 base elemental, 10s buff, 15s cooldown")
 quit()
