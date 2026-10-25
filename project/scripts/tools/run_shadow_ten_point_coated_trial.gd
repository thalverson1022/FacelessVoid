extends SceneTree
const Lab = preload("res://scripts/tools/balance_lab.gd")
const OUT := "res://reports/balance/shadow_ten_point_coated_2_trial"
func _initialize() -> void:
 SaveSystem.save_path = OUT+"/isolated_save.json"
 PracticeSaveSystem.save_path = OUT+"/isolated_practice.json"
 PracticeSaveSystem.core_save_path = OUT+"/isolated_core.json"
 call_deferred("run")
func run() -> void:
 DirAccess.make_dir_recursive_absolute(OUT)
 var registry := BuildContentRegistry.test_mode()
 var ranks := {"talent.shadow.snake_oil":4,"talent.shadow.coated_weapons":1,"talent.shadow.blind_spot":5}
 var payload := {"build_schema_version":1,"content_revision":registry.revision,"allocation_mode":"ranked","class_id":"class.rogue","primary_tree_id":"tree.shadow","secondary_tree_id":null,"earned_talent_points":10,"talent_ranks":ranks,"rotation_skill_ids":["skill.stab"]}
 var spec := {"id":"baseline","label":"10 Shadow / Stab / Coated Weapons 1 stack","ranked_build":payload,"monster":"res://data/monsters/training_dummy.tres","monster_overrides":{"hp":100000000},"gear":["res://data/gear/crude_dagger.tres"],"gold":0,"duration_ms":30000,"seed_start":1,"seed_count":200}
 var native := Lab.run_scenario_spec(spec,registry)
 assert(native.status == "pass")
 SaveSystem.write_json(OUT+"/baseline_native.json",native)
 var decoded := BuildSaveCodec.decode(payload,registry)
 assert(decoded.error == "")
 var gear: Array[GearItem] = [load("res://data/gear/crude_dagger.tres")]
 var resolved := BuildResolver.resolve_ranked_build(decoded["class"],decoded.model,gear,0)
 assert(resolved.error == "")
 var stab: Skill
 for skill in resolved.skills:
  if skill.id == "skill.stab": stab = skill
 assert(stab != null and stab.poison_stacks_applied == 1)
 var monster: Monster = load(spec.monster).duplicate(true)
 monster.hp = 100000000
 var rows := []
 for stacks in [1,2]:
  # Clone only the resolved skill. This changes Coated Weapons' Poison application,
  # not Increased All Stacks or Shadow's separate intrinsic crit application.
  var trial: Skill = stab.duplicate(true)
  trial.poison_stacks_applied = stacks
  var effect_count := 0
  for effect in trial.effects:
   if effect is PoisonDamageEffect:
    assert(effect.stacks_applied == 1)
    effect.stacks_applied = stacks
    effect_count += 1
  assert(effect_count == 1)
  var rotation: Array[Skill] = [trial]
  var samples := []
  var dps := []
  var direct := []
  var poison := []
  var ticks := []
  var applications := []
  for seed in range(1,201):
   var result := CombatResolver.resolve(rotation,resolved.stats,monster,30000,seed)
   assert(result.is_valid and result.duration_ms == 30000)
   var summary := Lab._combat_summary(seed,result)
   if stacks == 1 and seed <= native.samples.size():
    assert(is_equal_approx(summary.dps,float(native.samples[seed-1].dps)))
   samples.append(summary)
   dps.append(summary.dps)
   direct.append(summary.physical_damage/30.0)
   poison.append(summary.poison_damage/30.0)
   ticks.append(summary.poison_damage_ticks)
   applications.append(summary.poison_stacks_applied)
  var row := {"coated_weapon_stacks":stacks,"dps":Lab._distribution(dps),"direct_dps":Lab._distribution(direct),"poison_dps":Lab._distribution(poison),"poison_damage_ticks":Lab._distribution(ticks),"poison_stacks_applied":Lab._distribution(applications),"samples":samples}
  if stacks == 1: assert(is_equal_approx(row.dps.mean,float(native.aggregate.dps.mean)))
  rows.append(row)
  print("Coated Weapons ",stacks," stacks: DPS ",row.dps.mean," direct ",row.direct_dps.mean," poison ",row.poison_dps.mean," ticks ",row.poison_damage_ticks.mean)
 var delta: float = rows[1].dps.mean-rows[0].dps.mean
 SaveSystem.write_json(OUT+"/summary.json",{"content_revision":registry.revision,"live_content_changed":false,"build":payload,"duration_ms":30000,"seed_start":1,"seed_count":200,"rows":rows,"dps_change":delta,"relative_change":delta/rows[0].dps.mean,"baseline_native_parity":true})
 print("DPS change: ",delta," / ",100.0*delta/rows[0].dps.mean," percent")
 quit()
