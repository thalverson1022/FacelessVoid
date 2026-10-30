extends "res://scripts/tools/run_m6_t7.gd"
const Proposed=preload("res://scripts/tools/t6_candidate_contracts_v3.gd")
const REVIEW_OUT="res://reports/p6_m6_t6_optimization"
var records:=[]
var routes:=[]
func _initialize() -> void:
	SaveSystem.session_only=true
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tree="): main_name=arg.trim_prefix("--tree=")
	DirAccess.make_dir_recursive_absolute(REVIEW_OUT)
	call_deferred("run")
func select_macro(c: Dictionary,e: Monster,duration: int,broad: bool=false) -> Dictionary:
	var best:={"score":-1.0,"macro":[]}
	for ids in macros(c,broad):
		var score:=0.0
		for seed in [3201,3202]: score+=simulate(ids,c,e,duration,seed).total_damage
		if score>float(best.score): best={"score":score,"macro":ids}
	return best
func measure_quality(s: Dictionary,arm: Dictionary,e: Monster,duration: int,key: String) -> Array:
	var c:=resolved(s,arm.ranks)
	require(c.model.points_spent()==int(s.budget),"Equal full budget")
	var samples:=[]
	for seed in range(215001,215041):
		var f=simulate(arm.macro,c,e,duration,RunRng.seed_for_context(seed,RunRng.CONTEXT_COMBAT,[key,0]))
		var rd:=-1.0
		var won: bool=f.is_win
		if not won:
			var retry=simulate(arm.macro,resolved(s,arm.ranks,f.gold_stolen),e,duration,RunRng.seed_for_context(seed,RunRng.CONTEXT_COMBAT,[key,1]))
			rd=retry.total_damage;won=retry.is_win
		samples.append({"root":seed,"damage":f.total_damage,"win":f.is_win,"stolen":f.gold_stolen,"retry_damage":rd,"within_two":won})
	return samples
func investigate_quality(s: Dictionary,n: ContractRouteNode,p: ContractRouteNode,stage: int,seed: int,source: String) -> void:
	var enemy:=GeneratedMonsterDraft.from_dictionary(n.generated_encounter_payload).to_monster()
	var duration:=int(n.generated_encounter_payload.duration_ms)
	var original:=resolved(s,s.ranks)
	var reasonable:=legal_ids(config.reasonable_macros[main_name],original)
	var macro_best:=select_macro(original,enemy,duration,true)
	var pool:=rank_candidates(s)
	var eligible:=[]
	for ranks in pool:
		var model:=model_for(s,ranks)
		if model.tree_points(registry.trees["tree."+main_name])>=ceili(float(s.budget)*2.0/3.0): eligible.append(ranks)
	var ranked:=[]
	for ranks in eligible:
		var item:=select_macro(resolved(s,ranks),enemy,duration)
		item["ranks"]=ranks;ranked.append(item)
	ranked.sort_custom(func(a,b):return a.score>b.score)
	var best:={"score":macro_best.score,"macro":macro_best.macro,"ranks":s.ranks}
	for item in ranked.slice(0,3):
		var final:=select_macro(resolved(s,item.ranks),enemy,duration,true)
		if final.score>best.score: best={"score":final.score,"macro":final.macro,"ranks":item.ranks}
	# An unplanned allocation is selected independently of fight outcome, not the worst search result.
	var unplanned: Dictionary=eligible[1] if eligible.size()>1 else s.ranks
	var uc:=resolved(s,unplanned)
	var arms:=[{"id":"unplanned","ranks":unplanned,"macro":legal_ids(config.reasonable_macros[main_name],uc)},
		{"id":"coherent","ranks":s.ranks,"macro":reasonable},
		{"id":"macro_optimized","ranks":s.ranks,"macro":macro_best.macro},
		{"id":"build_optimized","ranks":best.ranks,"macro":best.macro}]
	# Hold the optimized allocation fixed; omit one used skill, selected on training roots only.
	var bc:=resolved(s,best.ranks)
	var altered: Array=[]
	var lowest:=INF
	var removed:=""
	for id in best.macro:
		var ids: Array=best.macro.filter(func(x):return x!=id)
		if ids.is_empty(): ids=legal_ids(["stab"],bc)
		if ids==best.macro: continue
		var score:=0.0
		for root_seed in [3201,3202]: score+=simulate(ids,bc,enemy,duration,root_seed).total_damage
		if score<lowest: lowest=score;altered=ids;removed=str(id)
	if altered.is_empty(): altered=legal_ids(["stab"],bc)
	arms.append({"id":"skill_omitted","ranks":best.ranks,"macro":altered,"removed":removed})
	var candidate:=GeneratedMonsterDraft.from_dictionary(p.generated_encounter_payload).to_monster()
	var changed: bool=enemy.hp!=candidate.hp or enemy.cleanse_threshold!=candidate.cleanse_threshold
	for arm in arms:
		for version in (["baseline","candidate"] if changed else ["baseline"]):
			var e: Monster=enemy if version=="baseline" else candidate
			records.append({"primary":main_name,"stage":stage,"seed":seed,"source":source,"node":n.id,"role":int(n.node_type),"tags":n.route_preview.get("archetype_tags",[]),"snapshot":s,"arm":arm,"version":version,"enemy":stat_record(e),"duration":duration,"search_allocations":eligible.size(),"samples":measure_quality(s,arm,e,duration,n.id)})
func run() -> void:
	config=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/m6_tavern_1023_protocol.json"))
	protocol=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/subclass_protocol.json"))
	registry=BuildContentRegistry.test_mode();state=root.get_node("BuildState")
	var acquired:=[]
	for file in DirAccess.get_files_at(T7_OUT):
		if not file.ends_with(".json"): continue
		var d: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(T7_OUT+"/"+file))
		if d.primary!=main_name or d.policy!="typical" or int(d.seed)<84001 or int(d.seed)>84008: continue
		for stage in [1,4,6,10]:
			for f in d.fights:
				if f.stage=="C"+str(stage):
					acquired.append({"source":file,"stage":stage,"snapshot":{"secondary":d.secondary,"budget":int(f.points),"ranks":f.ranks,"gold":int(f.gold),"gear":f.gear}});break
	for stage in [1,4,6,10]:
		var entries: Array=acquired.filter(func(x):return x.stage==stage).slice(0,2)
		for seed in [7001,85016]:
			var settings:={"route_difficulty":"medium","completed_contract_count":stage-1,"earned_talent_points":mini(45,6+3*(stage-1))}
			var graph=Gen.generate(seed,settings);var proposed=Proposed.generate(seed,settings)
			require(Gen.validate(graph).is_empty(),"Valid unchanged route")
			var nodes:=[];var other:=[];gather(graph.offer_node,{},nodes);gather(proposed.offer_node,{},other)
			var paths:=all_paths(graph.offer_node)
			var route_nodes:=[]
			var selected:=[]
			for n in nodes:
				if n.generated_encounter_payload.is_empty(): continue
				var count:=0
				for path in paths:
					if path.has(n.id): count+=1
				route_nodes.append({"id":n.id,"role":int(n.node_type),"preview":n.route_preview,"paths_containing":count,"payload":n.generated_encounter_payload})
				if n.node_type==ContractRouteNode.NodeType.BOSS or selected.is_empty() or n.id.ends_with("toll_fight"): selected.append(n)
			routes.append({"stage":stage,"seed":seed,"paths":paths,"nodes":route_nodes})
			for entry in entries:
				for n in selected:
					var matches: Array=other.filter(func(x):return x.id==n.id)
					investigate_quality(entry.snapshot,n,matches[0],stage,seed,entry.source)
				print("Optimization ",main_name," C",stage," ",seed," ",entry.source," rows=",records.size())
				SaveSystem.write_json(REVIEW_OUT+"/"+main_name+".json",{"complete":false,"rows":records,"routes":routes,"checks":checks})
	if t7_failed: quit(1);return
	SaveSystem.write_json(REVIEW_OUT+"/"+main_name+".json",{"complete":true,"rows":records,"routes":routes,"checks":checks})
	print("OPTIMIZATION PASS ",main_name," ",checks);quit(0)


