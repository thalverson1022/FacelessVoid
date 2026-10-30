extends "res://scripts/tools/run_m6_t7.gd"
const StableGen=preload("res://scripts/tools/t6_candidate_contracts_v3.gd")
const REVIEW="res://reports/p6_m6_t6_closeout"
func _initialize() -> void:
	SaveSystem.session_only=true
	call_deferred("run")
func samples_for(row: Dictionary,payload: Dictionary,roots: Array) -> Array:
	main_name=row.primary
	var s: Dictionary=row.snapshot
	var c:=resolved(s,s.ranks)
	var enemy:=GeneratedMonsterDraft.from_dictionary(payload).to_monster()
	var samples:=[]
	for seed in roots:
		var first=simulate(row.macro,c,enemy,int(payload.duration_ms),RunRng.seed_for_context(int(seed),RunRng.CONTEXT_COMBAT,[row.node,0]))
		var won: bool=first.is_win
		var retry_damage:=-1.0
		if not won:
			var retry=simulate(row.macro,resolved(s,s.ranks,first.gold_stolen),enemy,int(payload.duration_ms),RunRng.seed_for_context(int(seed),RunRng.CONTEXT_COMBAT,[row.node,1]))
			won=retry.is_win;retry_damage=retry.total_damage
		samples.append({"root":int(seed),"damage":first.total_damage,"win":first.is_win,"stolen":first.gold_stolen,"retry_damage":retry_damage,"within_two":won})
	return samples
func run() -> void:
	registry=BuildContentRegistry.test_mode()
	state=root.get_node("BuildState")
	var graphs_cache:={}
	var fresh:=[]
	var fresh_seen:={}
	for filename in ["generator_review","mid_generator_review"]:
		var prior: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(REVIEW+"/"+filename+".json"))
		var new_graphs:=[]
		for graph in prior.graphs:
			var key:="%d_%d"%[int(graph.stage),int(graph.seed)]
			if not graphs_cache.has(key):
				var stage:=int(graph.stage)
				var contract=StableGen.generate(int(graph.seed),{"route_difficulty":"medium","completed_contract_count":stage-1,"earned_talent_points":mini(45,6+3*(stage-1))})
				require(StableGen.validate(contract).is_empty(),"Valid stable candidate graph")
				var collected:=[]
				gather(contract.offer_node,{},collected)
				var node_map:={}
				for n in collected:
					if not n.generated_encounter_payload.is_empty(): node_map[n.id]=JSON.parse_string(JSON.stringify(n.generated_encounter_payload,"",true,true))
				graphs_cache[key]=node_map
			var ns:=[]
			for old in graph.nodes:
				var pa: Dictionary=old.baseline
				var pb: Dictionary=graphs_cache[key][old.node]
				require(pa.source_seed==pb.source_seed,"Preserve selected generation seed")
				require(pa.duration_ms==pb.duration_ms,"Preserve duration")
				require(int(pb.hp)<=int(pa.hp),"No HP increases")
				var defenses: Dictionary=pb.defense_overrides.duplicate(true)
				if defenses.has("cleanse_threshold"): defenses.cleanse_threshold=pa.defense_overrides.cleanse_threshold
				require(defenses==pa.defense_overrides,"Only permitted cleanse stat changes")
				var same: bool=JSON.stringify(pa,"",true,true)==JSON.stringify(pb,"",true,true)
				if int(graph.stage)>=7: require(same,"C7+ exact payload retention")
				ns.append({"node":old.node,"same":same,"baseline":pa,"candidate":pb})
			new_graphs.append({"stage":graph.stage,"seed":graph.seed,"template":graph.template,"nodes":ns})
		if t7_failed: quit(1);return
		var new_rows:=[]
		for i in range(0,prior.rows.size(),2):
			var old: Dictionary=prior.rows[i]
			var rejected: Dictionary=prior.rows[i+1]
			require(old.arm=="baseline" and rejected.arm=="candidate","Ordered paired source rows")
			var key:="%d_%d"%[int(old.stage),int(old.route_seed)]
			var pb: Dictionary=graphs_cache[key][old.node]
			var pa: Dictionary={}
			for graph in prior.graphs:
				if int(graph.stage)==int(old.stage) and int(graph.seed)==int(old.route_seed):
					for node in graph.nodes:
						if node.node==old.node: pa=node.baseline;break
			new_rows.append(old)
			var next: Dictionary=old.duplicate(true)
			next.arm="candidate"
			next.enemy=stat_record(GeneratedMonsterDraft.from_dictionary(pb).to_monster())
			next.duration=int(pb.duration_ms)
			var equal_combat: bool=pa.hp==pb.hp and pa.duration_ms==pb.duration_ms and pa.defense_overrides==pb.defense_overrides
			next["reused_unchanged_baseline"]=equal_combat
			if not equal_combat: next.samples=samples_for(old,pb,old.samples.map(func(s):return int(s.root)))
			new_rows.append(next)
			var focused: bool=(old.primary=="thief" and int(old.stage)==1 and ((int(old.route_seed)==7001 and str(old.node).ends_with("toll_fight")) or (int(old.route_seed)==85016 and str(old.node).ends_with("boss")))) or (old.primary=="shadow" and int(old.stage)==4 and int(old.route_seed)==7001)
			var old_wins:=0;var rejected_wins:=0
			for s in old.samples: old_wins+=int(s.within_two)
			for s in rejected.samples: rejected_wins+=int(s.within_two)
			var fresh_key:=key+"_"+str(old.node)+"_"+str(old.source)
			if (focused or rejected_wins<old_wins) and not fresh_seen.has(fresh_key):
				fresh_seen[fresh_key]=true
				for arm in ["baseline","candidate"]:
					var f: Dictionary=old.duplicate(true)
					var payload: Dictionary=pa if arm=="baseline" else pb
					f.arm=arm;f.enemy=stat_record(GeneratedMonsterDraft.from_dictionary(payload).to_monster());f.duration=payload.duration_ms
					f.samples=samples_for(old,payload,range(214001,214041))
					fresh.append(f)
			if i%400==0: print("Stable ",filename," ",i,"/",prior.rows.size())
		if t7_failed: quit(1);return
		SaveSystem.write_json(REVIEW+"/stable_"+filename+".json",{"complete":true,"checks":checks,"graphs":new_graphs,"rows":new_rows})
	if t7_failed: quit(1);return
	SaveSystem.write_json(REVIEW+"/fresh_confirmation.json",{"complete":true,"checks":checks,"rows":fresh})
	print("STABLE REVIEW PASS ",checks)
	quit(0)
