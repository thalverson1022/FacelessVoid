extends SceneTree
func _initialize() -> void:
 var protocol: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/subclass_protocol.json"))
 assert(protocol.durations_ms.size()==2 and int(protocol.durations_ms[0])==30000 and int(protocol.durations_ms[1])==120000)
 assert(protocol.seed_count == 200 and protocol.validation_seed_start == 201)
 var registry := BuildContentRegistry.test_mode()
 var ids := {}
 for entry in protocol.cases:
  assert(not ids.has(entry.id))
  ids[entry.id]=true
  var ranks: Dictionary=entry.talent_ranks.duplicate(true)
  if entry.full_tree:
   for talent in registry.trees["tree."+entry.tree].talents:ranks[talent.id]=talent.max_ranks
  var total := 0
  for id in ranks:
   ranks[id]=int(ranks[id])
   total+=ranks[id]
  assert(total==int(entry.points))
  var build := RankedBuild.new()
  assert(build.configure(registry.trees["tree."+entry.tree],null,int(entry.points),ranks))
  var gear: Array[GearItem]=[load("res://data/gear/crude_dagger.tres")]
  var content:=BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],build,gear,0)
  assert(content.error=="")
  var skills := {}
  for skill in content.skills:skills[skill.id.trim_prefix("skill.")]=true
  for id in entry.baseline_rotation:assert(skills.has(id),"Locked baseline skill: "+entry.id+"/"+id)
  assert(entry.baseline_rotation.size()<=10)
 print("PASS subclass protocol: ",ids.size()," exact allocations, legal baseline macros, 30/120s and 200+200 seed settings")
 quit()
