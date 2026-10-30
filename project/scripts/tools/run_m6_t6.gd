extends "res://scripts/tools/run_m6_t5_search.gd"
## Isolated enemy-side investigation. Inherits acquisition and combat APIs, not output paths.
const REPORT := "res://reports/p6_m6_t6"
const ROUTES := [7001,85001,85002,85003,85004,85016,85022]
const STAGES := [1,3,4,5,6,8,10,11,15,20]
var mode := "fixtures"
var history := 84002
var rows := []
var graphs := []
var chosen_ranks := {}

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tree="): main_name=arg.trim_prefix("--tree=")
		if arg.begins_with("--mode="): mode=arg.trim_prefix("--mode=")
		if arg.begins_with("--history="): history=int(arg.trim_prefix("--history="))
	DirAccess.make_dir_recursive_absolute(REPORT)
	SaveSystem.save_path=REPORT+"/"+main_name+"_save.json"
	PracticeSaveSystem.save_path=REPORT+"/"+main_name+"_practice.json"
	PracticeSaveSystem.core_save_path=REPORT+"/"+main_name+"_core.json"
	SaveSystem.session_only=true
	call_deferred("run")

func run() -> void:
	config=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/m6_tavern_1023_protocol.json"))
	config.contract_checkpoints=STAGES
	config.acquisition_seed=history
	protocol=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/subclass_protocol.json"))
	registry=BuildContentRegistry.test_mode()
	require(registry.error=="",registry.error)
	require(BuildProgression.CONTRACT_POINTS==3 and BuildProgression.TAVERN_POINTS==[1,0,2,3],"Current rewards")
	state=root.get_node("BuildState")
	var secondary: String=TREES[(TREES.find(main_name)+1)%4]
	if mode=="path":
		acquire(secondary,"typical")
		SaveSystem.write_json(REPORT+"/path_%s_%d.json"%[main_name,history],{"complete":true,"rows":rows,"snapshots":snapshots,"ledger":ledger,"checks":checks})
	elif mode=="fixtures":
		for policy in ["weak","typical","strong"]: acquire(secondary,policy)
		SaveSystem.write_json(REPORT+"/fixtures_%s_%d.json"%[main_name,history],{"complete":true,"snapshots":snapshots,"ledger":ledger,"checks":checks})
	else:
		snapshots=JSON.parse_string(FileAccess.get_file_as_string(REPORT+"/fixtures_%s_%d.json"%[main_name,history])).snapshots
		var prior_path:=DEST+"/"+main_name+("_primary" if main_name in ["bladedancer","shadow"] else "")+".json"
		chosen_ranks=JSON.parse_string(FileAccess.get_file_as_string(prior_path)).winners
		for stage in STAGES:
			for seed in ROUTES: full_route(stage,seed)
		for index in 4:
			var enc:=RunFlow.load_encounter(index)
			encounters.append({"id":"T"+str(index),"checkpoint":"T"+str(index),"monster_path":RunFlow.ENCOUNTER_PATHS[index],"duration":enc.duration_ms,"role":"TAVERN","mandatory":true,"fight_key":"encounter:%d"%index})
		encounters.append({"id":"watchmen","checkpoint":"C1","monster_path":"res://data/monsters/cloaked_watchmen.tres","duration":26000,"role":"WATCHMEN","mandatory":false,"fight_key":"watchmen"})
		if main_name=="bladedancer": SaveSystem.write_json(REPORT+"/encounters.json",{"encounters":encounters,"graphs":graphs})
		if mode=="screen": screen()
		elif mode in ["trial","confirm","focused"]: trial()
	state.reset()
	print("T6 PASS ",main_name," ",mode," ",history," rows=",rows.size()," checks=",checks)
	quit(0)

func full_route(stage: int,seed: int) -> void:
	var contract:=Gen.generate(seed,{"route_difficulty":"medium","completed_contract_count":stage-1,"earned_talent_points":mini(45,6+3*(stage-1))})
	require(Gen.validate(contract).is_empty(),"Valid full graph")
	var nodes:=[]
	gather(contract.offer_node,{},nodes)
	var paths:=all_paths(contract.offer_node)
	graphs.append({"stage":"C"+str(stage),"seed":seed,"template":contract.template_id,"paths":paths})
	for node: ContractRouteNode in nodes:
		if node.generated_encounter_payload.is_empty(): continue
		var mandatory:=true
		for path in paths:
			if not path.has(node.id): mandatory=false
		encounters.append({"id":"C%d_%d_%s"%[stage,seed,node.id],"checkpoint":"C"+str(stage),"role":ContractRouteNode.NodeType.keys()[node.node_type],"mandatory":mandatory,"template":contract.template_id,"route_seed":seed,"node":node.id,"fight_key":node.id,"payload":node.generated_encounter_payload,"duration":int(node.generated_encounter_payload.duration_ms)})

func ranks_for(s: Dictionary) -> Dictionary:
	if chosen_ranks.has(s.checkpoint):
		var r: Dictionary=chosen_ranks[s.checkpoint].ranks
		# A T5 all-secondary winner is not a primary-health control.
		var main_points:=0
		for talent in registry.trees["tree."+main_name].talents: main_points+=int(r.get(talent.id,0))
		if main_points>=mini(int(s.budget),21): return r
	return s.ranks

func short_train(c: Dictionary,e: Dictionary) -> Array:
	var pool:=candidates(legal_ids(config.reasonable_macros[main_name],c),c)
	for skill in c.skills:
		if skill.id!="skill.hold":
			var one: Array=[skill.id.trim_prefix("skill.")]
			if not pool.has(one): pool.append(one)
	var best:=-1.0
	var winner: Array=pool[0]
	for ids in pool:
		var score:=0.0
		for seed in [521,522,523]: score+=simulate(ids,c,enemy_for(e),int(e.duration),seed).total_damage
		if score>best:
			best=score
			winner=ids
	return winner

func stat_record(enemy: Monster) -> Dictionary:
	var d:={}
	for key in ["hp","armor","block","absorb","poison_resistance","cleanse_threshold","suppress","dodge_chance","crit_negation","slow","stun_duration_ms","interrupt_skip_count"]: d[key]=enemy.get(key)
	return d

func measure(s: Dictionary,e: Dictionary,ranks: Dictionary,ids: Array,retry_ids: Array,arm: String,root_start: int,count: int,enemy: Monster) -> Dictionary:
	var c:=resolved(s,ranks)
	var samples:=[]
	var wins:=0
	var both:=0
	var damage:=0.0
	var ticks:=0.0
	for seed_root in range(root_start,root_start+count):
		var first=simulate(ids,c,enemy,int(e.duration),RunRng.seed_for_context(seed_root,RunRng.CONTEXT_COMBAT,[e.fight_key,0]))
		wins+=int(first.is_win)
		var won: bool=first.is_win
		var retry_damage:=-1.0
		if not won:
			var retry=simulate(retry_ids,resolved(s,ranks,first.gold_stolen),enemy,int(e.duration),RunRng.seed_for_context(seed_root,RunRng.CONTEXT_COMBAT,[e.fight_key,1]))
			won=retry.is_win
			retry_damage=retry.total_damage
		both+=int(won)
		damage+=first.total_damage
		ticks+=first.tick_events.size()
		samples.append({"root":seed_root,"damage":first.total_damage,"win":first.is_win,"retry_damage":retry_damage,"within_two":won,"stolen":first.gold_stolen})
	return {"main":main_name,"stage":s.checkpoint,"history":history,"policy":s.policy,"snapshot":s.id,"encounter":e.id,"role":e.role,"mandatory":e.mandatory,"route_seed":e.get("route_seed",0),"arm":arm,"ranks":ranks,"macro":ids,"retry_macro":retry_ids,"enemy":stat_record(enemy),"duration":e.duration,"count":count,"wins":wins,"within_two":both,"mean_damage":damage/count,"mean_margin":damage/count/enemy.hp-1.0,"mean_ticks":ticks/count,"samples":samples}

func screen() -> void:
	for e in encounters:
		if e.checkpoint in ["C3","C5","C8"]: continue
		var s:=fixture(e.checkpoint,"typical")
		var ranks:=ranks_for(s)
		var c:=resolved(s,ranks)
		var ids:=short_train(c,e)
		rows.append(measure(s,e,ranks,ids,ids,"short_search",100001,12,enemy_for(e)))
		if e.role in ["BOSS","TAVERN","WATCHMEN"]:
			rows.append(measure(s,e,ranks,legal_ids(config.reasonable_macros[main_name],c),ids,"reasonable",100001,12,enemy_for(e)))
		if rows.size()%50==0: print("Screen ",main_name," rows=",rows.size())
	SaveSystem.write_json(REPORT+"/screen_"+main_name+".json",{"complete":true,"rows":rows,"checks":checks})

func trial() -> void:
	var plan: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(REPORT+"/"+mode+"_plan.json"))
	var prior: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DEST+"/"+main_name+".json"))
	for spec in plan.cases:
		if spec.main!=main_name: continue
		var e: Dictionary={}
		for item in encounters:
			if item.id==spec.encounter: e=item; break
		require(not e.is_empty(),"Trial target exists")
		for policy in spec.get("policies",["weak","typical","strong"]):
			var s:=fixture(e.checkpoint,policy)
			var ranks:=ranks_for(s)
			if e.checkpoint=="T1": ranks=prior.winners.T1.ranks
			var c:=resolved(s,ranks)
			var ids: Array=spec.get("macro",[])
			if ids.is_empty():
				ids=short_train(c,e)
				# Recovery check: bounded broad search with independent training seeds.
				var best:=-1.0
				var pool:=macros(c,true)
				pool.append(ids)
				for candidate in pool:
					var score:=0.0
					for seed in [531,532,533]: score+=simulate(candidate,c,enemy_for(e),int(e.duration),seed).total_damage
					if score>best: best=score; ids=candidate
			var base:=enemy_for(e)
			for arm in spec.arms:
				var enemy: Monster=base.duplicate(true)
				if arm.has("hp_multiplier"): enemy.hp=maxi(1,roundi(enemy.hp*float(arm.hp_multiplier)))
				if arm.get("remove_duration_floor",false):
					var budget: float=e.payload.pressure_metadata.hp_budget_duration_sec
					enemy.hp=maxi(1,roundi(enemy.hp*minf(1.0,float(e.duration)/1000.0/budget)))
				for key in arm.get("caps",{}): enemy.set(key,minf(enemy.get(key),float(arm.caps[key])))
				for key in arm.get("minimums",{}):
					if enemy.get(key)>0: enemy.set(key,maxf(enemy.get(key),float(arm.minimums[key])))
				for key in arm.get("set",{}): enemy.set(key,arm["set"][key])
				var row:=measure(s,e,ranks,ids,ids,arm.id,int(plan.root_start),int(plan.count),enemy)
				row["parameters"]=arm
				row["baseline_enemy"]=stat_record(base)
				rows.append(row)
		print(mode," ",main_name," ",e.id," rows=",rows.size())
		SaveSystem.write_json(REPORT+"/%s_%s_%d.json"%[mode,main_name,history],{"complete":false,"rows":rows,"checks":checks})
	SaveSystem.write_json(REPORT+"/%s_%s_%d.json"%[mode,main_name,history],{"complete":true,"rows":rows,"checks":checks})

func reward(secondary: String,policy: String,label: String) -> void:
	if mode=="path":
		var stage: String=label.split("/")[0]
		if stage in ["C1","C4","C6","C10","C11","C15","C20"]:
			capture(stage,secondary,policy)
			var s: Dictionary=snapshots.back()
			var node: ContractRouteNode=state.current_route_node
			var e:={"id":"path_%d_%s"%[history,node.id],"checkpoint":stage,"role":ContractRouteNode.NodeType.keys()[node.node_type],"mandatory":node.next_nodes.is_empty(),"fight_key":node.id,"payload":node.generated_encounter_payload,"duration":int(node.generated_encounter_payload.duration_ms)}
			var c:=resolved(s,s.ranks)
			var ids:=short_train(c,e)
			var row:=measure(s,e,s.ranks,ids,ids,"within_route_acquisition",103001,20,enemy_for(e))
			row["mandatory"]=null # This traversal does not enumerate the alternate paths.
			row["mandatory_assessed"]=false
			row["snapshot_index"]=snapshots.size()-1
			rows.append(row)
			print("Path ",main_name," ",stage," ",e.role," ",row.within_two,"/20")
	super.reward(secondary,policy,label)
