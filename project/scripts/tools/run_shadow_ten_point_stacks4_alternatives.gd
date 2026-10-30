extends SceneTree
const Lab = preload("res://scripts/tools/balance_lab.gd")
const OUT = "res://reports/balance/shadow_ten_point_stacks4_search_d018"
const CASES := [
 {"tree":"shadow","ranks":{"talent.shadow.snake_oil":4,"talent.shadow.coated_weapons":1,"talent.shadow.blind_spot":5},"rotation":["stab"],"principal":["stab","heavy_slash","toxic_flurry","distilled_corruption"]}
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
 if ids.size()>1:
  var same := true
  for id in ids:
   if id!=ids[0]: same=false
  if same: return
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
  for slot in [GearItem.SlotType.HELM,GearItem.SlotType.ARMOR]:
   var item := GearItem.new()
   item.id="balance.stack_bonus."+str(slot)
   item.display_name="Basic +2 stacks"
   item.slot=slot
   item.tier=GearItem.Tier.BASIC
   var modifier := StatModifier.new()
   modifier.stat_id=StatCatalog.INCREASED_ALL_STACKS
   modifier.value=2
   item.affixes.append(modifier)
   gear.append(item)
  var content := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],model,gear,0)
  assert(content.error=="")
  stats=content.stats
  assert(stats.bonus_poison_stacks==4 and stats.bonus_decay_stacks==4)
  skills={}
  for skill in content.skills: skills[skill.id.trim_prefix("skill.")]=skill
  enemy=load("res://data/monsters/training_dummy.tres").duplicate(true)
  enemy.hp=100000000
  var alternatives := []
  for ids in [["stab"],["heavy_slash"],["stab","heavy_slash"],["stab","killers_mark"],["toxic_flurry","distilled_corruption"],["stab","touch_of_darkness"],["stab","stab","stab","touch_of_darkness"],["stab","stab","stab","stab","stab","touch_of_darkness"],["stab","stab","stab","stab","stab","stab","stab","stab","stab","touch_of_darkness"]]:
   alternatives.append(score(ids,1,200))
  SaveSystem.write_json(OUT+"/alternatives.json",{"rows":alternatives})
  print(JSON.stringify(alternatives))
  quit()
  return
