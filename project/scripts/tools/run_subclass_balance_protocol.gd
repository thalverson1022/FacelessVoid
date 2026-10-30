extends SceneTree
const Lab = preload("res://scripts/tools/balance_lab.gd")
var protocol_path := "res://data/balance_lab/subclass_protocol.json"
const OUT_ROOT := "res://reports/balance/subclass_protocol_d023"
var tree_name := ""
var protocol := {}
var registry: BuildContentRegistry
var stats: PlayerStats
var skills := {}
var model: RankedBuild
var gear: Array[GearItem] = []
var enemy: Monster
var duration_ms := 30000
var candidates := {}
var cache := {}
var rng := RandomNumberGenerator.new()
var config := {}
func _initialize() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--tree="): tree_name=arg.trim_prefix("--tree=")
  if arg.begins_with("--protocol="): protocol_path=arg.trim_prefix("--protocol=")
 assert(tree_name in ["bladedancer","thief","assassin","shadow"])
 var out := OUT_ROOT+"/"+tree_name
 DirAccess.make_dir_recursive_absolute(out)
 SaveSystem.save_path=out+"/isolated_save.json"
 PracticeSaveSystem.save_path=out+"/isolated_practice.json"
 PracticeSaveSystem.core_save_path=out+"/isolated_core.json"
 call_deferred("run")
func score(ids: Array, start: int, count: int) -> Dictionary:
 var key := JSON.stringify([duration_ms,ids,start,count])
 if cache.has(key): return cache[key]
 var rotation: Array[Skill] = []
 for id in ids:
  assert(skills.has(id),"Locked skill "+str(id))
  rotation.append(skills[id])
 var values := []
 var direct := []
 var poison := []
 for seed in range(start,start+count):
  var result := CombatResolver.resolve(rotation,stats,enemy,duration_ms,seed)
  assert(result.is_valid and result.duration_ms==duration_ms)
  values.append(result.dps)
  if count==200:
   var elemental := 0.0
   for tick in result.tick_events: elemental+=tick.damage
   poison.append(elemental*1000.0/duration_ms)
   direct.append((result.total_damage-elemental)*1000.0/duration_ms)
 var row := {"rotation":ids.duplicate(),"dps":Lab._distribution(values),"seed_start":start,"duration_ms":duration_ms}
 if count==200:
  row["direct_dps"]=Lab._distribution(direct)
  row["poison_dps"]=Lab._distribution(poison)
 cache[key]=row
 return row
func add(raw: Array) -> void:
 if raw.is_empty() or raw.size()>int(config.max_macro_slots): return
 for id in raw:
  if not skills.has(id): return
 var ids: Array=raw.duplicate()
 for period in range(1,ids.size()):
  if ids.size()%period!=0: continue
  var repeated := true
  for n in range(ids.size()):
   if ids[n]!=ids[n%period]: repeated=false
  if repeated:
   ids=ids.slice(0,period)
   break
 var key := JSON.stringify(ids)
 if not candidates.has(key): candidates[key]=score(ids,1,int(config.screen_seed_count))
func rank_rows(rows: Array) -> void:
 rows.sort_custom(func(a,b):return a.dps.mean>b.dps.mean)
func patterns(entry: Dictionary) -> void:
 for n in range(1,7):
  var quick := []
  var heavy := []
  var poison := []
  var score_macro := []
  var mug_macro := []
  for repeat in range(n):
   quick.append("quick_cut")
   heavy.append("heavy_slash")
   poison.append("poison_strike")
   score_macro.append("big_score")
   mug_macro.append("mug")
  add(["dance_of_death"]+quick+["leaping_plunge"])
  add(["dance_of_death"]+quick+["stab","leaping_plunge"])
  add(["dance_of_death"]+quick+["parry_strike","leaping_plunge"])
  add(["venom_jab"]+heavy)
  add(["virulent_poison","poison_vile"]+poison)
  add(["poison_vile","virulent_poison"]+poison)
  add(["pick_pocket"]+score_macro)
  add(["pick_pocket","steal"]+score_macro)
  add(["pick_pocket","steal"]+score_macro+["mug"])
  add(["steal"]+score_macro)
  add(["pick_pocket"]+mug_macro)
  add(["stab"]+heavy)
 for setup in range(1,4):
  for deaths in range(1,5):
   for conversions in [1,2]:
    var prefix := []
    for n in range(setup):
     prefix.append("toxic_flurry")
     for conversion in range(conversions):prefix.append("distilled_corruption")
    var finish := []
    for n in range(deaths): finish.append("killers_mark")
    add(prefix+finish+["touch_of_darkness"])
    add(prefix+["touch_of_darkness","distilled_corruption"]+finish)
    add(prefix+["beguiling_presence"]+finish+["touch_of_darkness"])
 for setup in range(1,5):
  for deaths in range(1,4):
   var ids := []
   for n in range(setup):ids.append("toxic_flurry")
   ids.append_array(["beguiling_presence","toxic_flurry","distilled_corruption","touch_of_darkness","distilled_corruption"])
   for n in range(deaths):ids.append("killers_mark")
   add(ids)
func optimize(entry: Dictionary, prior: Array) -> Dictionary:
 candidates={}
 rng.seed=230000+int(entry.points)*100+duration_ms+int(tree_name.hash()%100)
 var baseline := score(entry.baseline_rotation,1,200)
 add(entry.baseline_rotation)
 if not prior.is_empty():add(prior)
 for ids in protocol.seed_rotations[tree_name]:add(ids)
 patterns(entry)
 var pool: Array = skills.keys()
 pool.sort()
 var frontier: Array=[[]]
 var exhaustive_length := 4 if int(entry.points)==1 else 3
 for length in range(1,exhaustive_length+1):
  var next := []
  for parent in frontier:
   for id in pool:
    var ids: Array=parent.duplicate()
    ids.append(id)
    add(ids)
    next.append(ids)
  frontier=next
 for trial in range(int(config.random_candidates)):
  var ids := []
  for n in range(rng.randi_range(4,10)):ids.append(pool[rng.randi_range(0,pool.size()-1)])
  add(ids)
 for generation in range(int(config.mutation_generations)):
  var ranked: Array=candidates.values()
  rank_rows(ranked)
  for parent in ranked.slice(0,int(config.parents_per_generation)):
   for trial in range(int(config.mutations_per_parent)):
    var ids: Array=parent.rotation.duplicate()
    var position:=rng.randi_range(0,ids.size()-1)
    var operation:=rng.randi_range(0,3)
    var chosen=pool[rng.randi_range(0,pool.size()-1)]
    if operation==0:ids[position]=chosen
    elif operation==1 and ids.size()<10:ids.insert(position,chosen)
    elif operation==2 and ids.size()>1:ids.remove_at(position)
    elif ids.size()>1:
     var second:=rng.randi_range(0,ids.size()-1)
     var swap=ids[position]
     ids[position]=ids[second]
     ids[second]=swap
    add(ids)
  print(entry.id," ",duration_ms/1000,"s mutation round ",generation+1,"; candidates ",candidates.size())
 var ranked: Array=candidates.values()
 rank_rows(ranked)
 var screened := []
 for row in ranked.slice(0,int(config.shortlist_count)):screened.append(score(row.rotation,1,int(config.shortlist_seed_count)))
 rank_rows(screened)
 var final_by_key := {}
 final_by_key[JSON.stringify(baseline.rotation)]=baseline
 if not prior.is_empty():final_by_key[JSON.stringify(prior)]=score(prior,1,200)
 for row in screened.slice(0,int(config.finalist_count)):final_by_key[JSON.stringify(row.rotation)]=score(row.rotation,1,200)
 var finalists: Array=final_by_key.values()
 rank_rows(finalists)
 var winner: Dictionary=finalists[0]
 var heldout:=score(winner.rotation,201,200)
 # Verify native search against the standard Balance Lab adapter and Practice.
 var ids := []
 var rotation: Array[Skill]=[]
 for id in winner.rotation:
  ids.append("skill."+id)
  rotation.append(skills[id])
 var payload := {"build_schema_version":1,"content_revision":registry.revision,"allocation_mode":"ranked","class_id":"class.rogue","primary_tree_id":"tree."+tree_name,"secondary_tree_id":null,"earned_talent_points":int(entry.points),"talent_ranks":model.rank_map(),"rotation_skill_ids":ids}
 var spec := {"id":entry.id,"label":"Subclass balance protocol","ranked_build":payload,"monster":protocol.monster,"monster_overrides":{"hp":int(protocol.monster_hp)},"gear":protocol.gear,"gold":0,"duration_ms":duration_ms,"seed_start":1,"seed_count":1}
 var lab := Lab.run_scenario_spec(spec,registry)
 if lab.status!="pass":printerr(JSON.stringify(lab))
 assert(lab.status=="pass")
 var native := CombatResolver.resolve(rotation,stats,enemy,duration_ms,1)
 assert(is_equal_approx(lab.samples[0].dps,native.dps))
 var practice := TrainingRoomState.new()
 practice.content_registry=registry
 practice.selected_class=registry.classes["class.rogue"]
 practice.ranked_build=model
 practice.selected_trees=model.trees()
 practice.earned_talent_points=int(entry.points)
 practice.equipped_weapon=gear[0]
 practice.set_practice_gold(0)
 practice.set_rotation(rotation)
 practice.set_duration_ms(duration_ms)
 practice.set_fight_seed(1)
 practice.set_locked(true)
 practice.run_fight()
 assert(practice.last_result!=null and is_equal_approx(practice.last_result.dps,native.dps))
 var result := {"id":entry.id,"tree":tree_name,"points":entry.points,"variant":entry.variant,"talent_ranks":model.rank_map(),"duration_ms":duration_ms,"candidate_count":candidates.size(),"baseline":baseline,"finalists":finalists,"winner":winner,"validation":heldout,"practice_lab_native_seed1_parity":true,"spec":spec,"search_seed":rng.seed,"source_balance_authority":protocol.source_balance_authority,"release_manifest_sha256":FileAccess.get_sha256("res://data/p6/shadow_release_manifest.json")}
 var out: String = OUT_ROOT+"/"+tree_name+"/"+str(entry.id)+"_"+str(duration_ms/1000)+"s.json"
 SaveSystem.write_json(out,result)
 print("DONE ",entry.id," ",duration_ms/1000,"s: baseline ",snappedf(baseline.dps.mean,0.01)," -> optimized ",snappedf(winner.dps.mean,0.01),"; validation ",snappedf(heldout.dps.mean,0.01),"; ",winner.rotation)
 return result
func run() -> void:
 protocol=JSON.parse_string(FileAccess.get_file_as_string(protocol_path))
 config=protocol.search
 var release: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/p6/shadow_release_manifest.json"))
 assert(release.balance_authority==protocol.source_balance_authority)
 registry=BuildContentRegistry.test_mode()
 gear=[load(protocol.gear[0])]
 var rows := []
 for entry in protocol.cases:
  if entry.tree!=tree_name:continue
  var ranks: Dictionary=entry.talent_ranks.duplicate(true)
  if entry.full_tree:
   for talent in registry.trees["tree."+tree_name].talents:ranks[talent.id]=talent.max_ranks
  for id in ranks:ranks[id]=int(ranks[id])
  var total:=0
  for amount in ranks.values():total+=int(amount)
  assert(total==int(entry.points),"Exact point count "+entry.id)
  model=RankedBuild.new()
  assert(model.configure(registry.trees["tree."+tree_name],null,int(entry.points),ranks),model.last_error)
  var content:=BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],model,gear,0)
  assert(content.error=="")
  stats=content.stats
  skills={}
  for skill in content.skills:skills[skill.id.trim_prefix("skill.")]=skill
  for id in entry.baseline_rotation:assert(skills.has(id),"Baseline skill must be unlocked "+entry.id+"/"+id)
  enemy=load(protocol.monster).duplicate(true)
  enemy.hp=int(protocol.monster_hp)
  cache={}
  var prior := []
  for duration in protocol.durations_ms:
   duration_ms=int(duration)
   print("START ",entry.id," ",duration_ms/1000,"s; legal skills ",skills.keys())
   var result:=optimize(entry,prior)
   rows.append(result)
   prior=result.winner.rotation
   SaveSystem.write_json(OUT_ROOT+"/"+tree_name+"/summary.json",{"passed":true,"complete":false,"rows":rows})
 SaveSystem.write_json(OUT_ROOT+"/"+tree_name+"/summary.json",{"passed":true,"complete":true,"rows":rows})
 print("WORKER COMPLETE ",tree_name)
 quit()
