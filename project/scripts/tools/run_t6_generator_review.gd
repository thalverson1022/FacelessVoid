extends "res://scripts/tools/run_m6_t7.gd"
const CandidateGen=preload("res://scripts/tools/t6_candidate_contracts.gd")
const CLOSEOUT="res://reports/p6_m6_t6_closeout"
func _initialize() -> void:
	SaveSystem.session_only=true
	DirAccess.make_dir_recursive_absolute(CLOSEOUT)
	call_deferred("run")
func run() -> void:
	config=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/m6_tavern_1023_protocol.json"))
	protocol=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/subclass_protocol.json"))
	registry=BuildContentRegistry.test_mode()
	state=root.get_node("BuildState")
	var acquired:=[]
	for file in DirAccess.get_files_at(T7_OUT):
		if not file.ends_with(".json"): continue
		var d: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(T7_OUT+"/"+file))
		if d.policy!="typical" or int(d.seed)<84001 or int(d.seed)>84008: continue
		for stage in [1,2,3]:
			for f in d.fights:
				if f.stage=="C"+str(stage):
					acquired.append({"file":file,"primary":d.primary,"secondary":d.secondary,"stage":stage,"snapshot":f})
					break
	var graphs_out:=[]
	var output:=[]
	for stage in [1,2,3,4,6,10,15,20,30]:
		for seed in [7001,85001,85002,85003,85004,85016,85022,95101,95102,95103,95104,95105]:
			var settings:={"route_difficulty":"medium","completed_contract_count":stage-1,"earned_talent_points":mini(45,6+3*(stage-1))}
			var base=Gen.generate(seed,settings)
			var candidate=CandidateGen.generate(seed,settings)
			require(Gen.validate(base).is_empty() and CandidateGen.validate(candidate).is_empty(),"Valid paired graphs")
			require(all_paths(base.offer_node)==all_paths(candidate.offer_node),"Identical route topology")
			var left:=[]
			var right:=[]
			gather(base.offer_node,{},left)
			gather(candidate.offer_node,{},right)
			var nodes_out:=[]
			for i in left.size():
				var a: ContractRouteNode=left[i]
				var b: ContractRouteNode=right[i]
				require(a.id==b.id,"Same node identity")
				if a.generated_encounter_payload.is_empty(): continue
				var pa: Dictionary=a.generated_encounter_payload
				var pb: Dictionary=b.generated_encounter_payload
				var same: bool=JSON.stringify(pa)==JSON.stringify(pb)
				if stage>=4: require(same,"C4+ byte-identical generated payload")
				nodes_out.append({"node":a.id,"same":same,"baseline":pa,"candidate":pb})
				if stage>=4 or (same and not (stage==1 and a.node_type==ContractRouteNode.NodeType.BOSS)): continue
				var counts:={}
				for entry in acquired:
					if int(entry.stage)!=stage: continue
					main_name=entry.primary
					var focused: bool=main_name=="thief" and stage==1 and ((seed==7001 and a.id.ends_with("toll_fight")) or (seed==85016 and a.node_type==ContractRouteNode.NodeType.BOSS))
					if int(counts.get(main_name,0))>=(8 if focused else 3): continue
					counts[main_name]=int(counts.get(main_name,0))+1
					var raw: Dictionary=entry.snapshot
					var s:={"secondary":entry.secondary,"budget":int(raw.points),"ranks":raw.ranks,"gold":int(raw.gold),"gear":raw.gear}
					var c:=resolved(s,s.ranks)
					var ea:=GeneratedMonsterDraft.from_dictionary(pa).to_monster()
					var eb:=GeneratedMonsterDraft.from_dictionary(pb).to_monster()
					var pool:=candidates(legal_ids(config.reasonable_macros[main_name],c),c)
					for skill in c.skills:
						if skill.id!="skill.hold": pool.append([skill.id.trim_prefix("skill.")])
					for raw_ids in [["mug","steal","pick_pocket"],["steal","mug","pick_pocket"],["pick_pocket","steal","mug"],["rending_thrust","quick_cut"]]: pool.append(legal_ids(raw_ids,c))
					var best: Array=pool[0]
					var best_score:=-1.0
					for ids in pool:
						var score:=0.0
						for root_seed in [3101,3102]: score+=simulate(ids,c,ea,int(pa.duration_ms),root_seed).total_damage
						if score>best_score: best_score=score;best=ids
					for arm in ["baseline","candidate"]:
						var enemy: Monster=ea if arm=="baseline" else eb
						var duration: int=int(pa.duration_ms) if arm=="baseline" else int(pb.duration_ms)
						var samples:=[]
						for root_seed in range(209001,209001+(40 if focused else 12)):
							var first=simulate(best,c,enemy,duration,RunRng.seed_for_context(root_seed,RunRng.CONTEXT_COMBAT,[a.id,0]))
							var won: bool=first.is_win
							var retry_damage:=-1.0
							if not won:
								var retry=simulate(best,resolved(s,s.ranks,first.gold_stolen),enemy,duration,RunRng.seed_for_context(root_seed,RunRng.CONTEXT_COMBAT,[a.id,1]))
								won=retry.is_win;retry_damage=retry.total_damage
							samples.append({"root":root_seed,"damage":first.total_damage,"win":first.is_win,"stolen":first.gold_stolen,"retry_damage":retry_damage,"within_two":won})
						output.append({"stage":stage,"route_seed":seed,"node":a.id,"primary":main_name,"source":entry.file,"snapshot":s,"macro":best,"arm":arm,"enemy":stat_record(enemy),"duration":duration,"samples":samples})
			graphs_out.append({"stage":stage,"seed":seed,"template":base.template_id,"nodes":nodes_out})
			print("Generator review C",stage," seed ",seed," rows=",output.size())
	if t7_failed: quit(1);return
	SaveSystem.write_json(CLOSEOUT+"/generator_review.json",{"complete":true,"checks":checks,"graphs":graphs_out,"rows":output})
	print("GENERATOR REVIEW PASS ",checks)
	quit(0)
