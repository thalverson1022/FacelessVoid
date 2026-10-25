extends SceneTree
const Lab = preload("res://scripts/tools/balance_lab.gd")
const Sim = preload("res://scripts/tools/shadow_death_blade_trial_resolver.gd")
const Previous = preload("res://scripts/tools/shadow_death_strike_trial_2_resolver.gd")
const OUT := "res://reports/balance/shadow_twenty_one_point_death_blade_trial"
const CASES := [
 {"tree":"shadow","ranks":{"talent.shadow.snake_oil":4,"talent.shadow.coated_weapons":1,"talent.shadow.deception":5,"talent.shadow.death_touch":3,"talent.shadow.death_pact":2,"talent.shadow.shadow_mastery":2,"talent.shadow.dusk_strike":1,"talent.shadow.death_blade":2,"talent.umbral_pressure":1},"rotation":["toxic_flurry","distilled_corruption","killers_mark","toxic_flurry","distilled_corruption","killers_mark","touch_of_darkness","beguiling_presence"],"principal":["stab","killers_mark","touch_of_darkness","beguiling_presence","toxic_flurry","distilled_corruption"]}
]

func _initialize() -> void:
 SaveSystem.save_path = OUT+"/isolated_save.json"
 PracticeSaveSystem.save_path = OUT+"/isolated_practice.json"
 PracticeSaveSystem.core_save_path = OUT+"/isolated_core.json"
 call_deferred("run")
func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 var registry := BuildContentRegistry.test_mode()
 var entry: Dictionary = CASES[0]
 var model := RankedBuild.new()
 assert(model.configure(registry.trees["tree.shadow"],null,21,entry.ranks))
 var gear: Array[GearItem] = [load("res://data/gear/crude_dagger.tres")]
 var content := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],model,gear,0)
 assert(content.error == "")
 var previous_report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://reports/balance/shadow_twenty_one_point_death_strike_2_rotation_search/shadow.json"))
 var ids: Array = previous_report.finalists[0].rotation
 var rotation: Array[Skill] = []
 for id in ids:
  for skill in content.skills:
   if skill.id == "skill."+id: rotation.append(skill)
 assert(rotation.size() == ids.size())
 var enemy: Monster = load("res://data/monsters/training_dummy.tres").duplicate(true)
 enemy.hp = 100000000
 var rows := []
 for variant in [{"name":"Previous Death Blade","chance":0.2,"stab_crit_bonus":0.0},{"name":"40% trigger per rank only","chance":0.8,"stab_crit_bonus":0.0},{"name":"40% trigger + 10pp Stab crit per rank","chance":0.8,"stab_crit_bonus":0.2}]:
  var fresh := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],model,gear,0)
  assert(fresh.error == "")
  var stats: PlayerStats = fresh.stats
  assert(is_equal_approx(stats.crit_chance,0.05))
  stats.death_blade_chance = variant.chance
  stats.special_effects["trial_death_blade_stab_crit_bonus"] = variant.stab_crit_bonus
  if stats.derivation_base != null:
   stats.derivation_base.death_blade_chance = variant.chance
   stats.derivation_base.special_effects["trial_death_blade_stab_crit_bonus"] = variant.stab_crit_bonus
  var row := evaluate(rotation,stats,enemy,1,200,variant)
  row["heldout"] = evaluate(rotation,stats,enemy,201,200,variant)
  if variant.chance == 0.2: assert(is_equal_approx(row.dps.mean,103.4055),"Previous optimized trial DPS reproduced")
  rows.append(row)
  print(JSON.stringify(row))
 SaveSystem.write_json(OUT+"/summary.json",{"rows":rows,"rotation":ids,"ranks":entry.ranks,"death_strike_damage_per_poison_stack":2,"live_content_changed":false,"duration_ms":30000,"gear":"Crude Dagger only","gold":0,"control_engine_parity":true})
 quit()
func evaluate(rotation: Array[Skill], stats: PlayerStats, enemy: Monster, start: int, count: int, variant: Dictionary) -> Dictionary:
 var dps := []
 var direct := []
 var poison := []
 var stabs := []
 var stab_damage := []
 var crits := []
 for seed in range(start,start+count):
  var result := Sim.resolve(rotation,stats,enemy,30000,seed)
  assert(result.is_valid and result.duration_ms == 30000)
  if variant.chance == 0.2 and seed <= 200:
   var control := Previous.resolve(rotation,stats,enemy,30000,seed)
   assert(control.total_damage == result.total_damage and control.rng_final_state == result.rng_final_state)
  var stab_count := 0
  var stab_total := 0.0
  var stab_crits := 0
  for event in result.cast_events:
   if event.skill.id == "skill.stab":
    stab_count += 1
    stab_total += event.physical_damage
    if event.is_crit: stab_crits += 1
    assert(event.poison_stacks_applied == 0,"Death Blade still suppresses all Stab Poison")
    if event.stat_snapshot.has("effective_crit_chance"):
     assert(is_equal_approx(event.stat_snapshot.effective_crit_chance,0.05+variant.stab_crit_bonus),"Stab-only crit bonus")
   elif event.stat_snapshot.has("effective_crit_chance"):
    assert(is_equal_approx(event.stat_snapshot.effective_crit_chance,0.05),"Other skills retain original crit chance")
  var summary := Lab._combat_summary(seed,result)
  dps.append(result.dps)
  direct.append(summary.physical_damage/30.0)
  poison.append(summary.poison_damage/30.0)
  stabs.append(stab_count)
  stab_damage.append(stab_total/30.0)
  crits.append(stab_crits)
 return {"name":variant.name,"seed_start":start,"seed_count":count,"death_blade_chance":variant.chance,"stab_crit_bonus":variant.stab_crit_bonus,"dps":Lab._distribution(dps),"direct_dps":Lab._distribution(direct),"poison_dps":Lab._distribution(poison),"stab_procs":Lab._distribution(stabs),"stab_dps":Lab._distribution(stab_damage),"stab_crits":Lab._distribution(crits)}
