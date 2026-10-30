extends SceneTree
const Resolver = preload("res://reports/balance/thief_guaranteed_crit_comparison/resolver.gd")
const Lab = preload("res://scripts/tools/balance_lab.gd")
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var registry := BuildContentRegistry.test_mode()
 var model := RankedBuild.new()
 var ranks := {}
 for talent in registry.trees["tree.thief"].talents: ranks[talent.id]=talent.max_ranks
 assert(model.configure(registry.trees["tree.thief"],null,35,ranks))
 var gear: Array[GearItem] = [load("res://data/gear/crude_dagger.tres")]
 var content := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],model,gear,0)
 var stats: PlayerStats=content.stats
 stats.crit_chance=1.0
 var enemy: Monster=load("res://data/monsters/training_dummy.tres").duplicate(true)
 enemy.hp=100000000
 var rows := []
 for id in ["skill.mug","skill.big_score"]:
  var skill: Skill
  for item in content.skills:
   if item.id==id: skill=item.duplicate(true)
  if id=="skill.big_score": skill.critical_damage_factor=6.0
  var rotation: Array[Skill]=[skill]
  var values := []
  var casts := []
  var first := {}
  for seed in range(1,201):
   var result := Resolver.resolve(rotation,stats,enemy,30000,seed)
   assert(result.is_valid and result.duration_ms==30000)
   values.append(result.dps)
   casts.append(result.cast_events.size())
   if seed==1:
    first={"damage":result.cast_events[0].physical_damage,"execution_ms":result.cast_events[0].time_ms-result.cast_events[0].cast_start_ms,"snapshot":result.cast_events[0].stat_snapshot}
  rows.append({"skill":id,"dps":Lab._distribution(values),"casts":Lab._distribution(casts),"first":first})
 var summary := {"rows":rows,"stats":{"crit_multiplier":stats.crit_multiplier,"attack_speed":stats.attack_speed,"bonus_physical_damage":stats.bonus_physical_damage},"scope":"full35, zero stash, guaranteed crit, Mug forced +50, Big Score factor6, 30s crude dagger blank dummy"}
 SaveSystem.write_json("res://reports/balance/thief_guaranteed_crit_comparison/summary.json",summary)
 print(JSON.stringify(summary))
 quit()
