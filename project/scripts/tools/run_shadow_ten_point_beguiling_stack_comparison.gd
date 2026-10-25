extends SceneTree
const Lab = preload("res://scripts/tools/balance_lab.gd")
const OUT = "res://reports/balance/shadow_ten_point_beguiling_stack_comparison"
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
  var extras := []
  var rotation_cases := [["stab","heavy_slash","heavy_slash"],["toxic_flurry","distilled_corruption"],["toxic_flurry","distilled_corruption","killers_mark"],["toxic_flurry","toxic_flurry","distilled_corruption","killers_mark"],["toxic_flurry","distilled_corruption","touch_of_darkness","distilled_corruption","killers_mark"]]
  var buffed: Skill = skills["toxic_flurry"]
  var original: Skill = buffed.duplicate(true)
  original.effects.remove_at(original.effects.size()-1)
  for decay in [1,2]:
   skills["toxic_flurry"] = original if decay == 1 else buffed
   for ids in rotation_cases:
    var row := score(ids,1,200)
    row["beguiling_decay_stacks"] = decay
    extras.append(row)
    print(JSON.stringify(row))
  SaveSystem.write_json(OUT+"/comparison.json",{"coated_weapon_poison_stacks":2,"rows":extras,"live_content_changed":false})
 quit()
