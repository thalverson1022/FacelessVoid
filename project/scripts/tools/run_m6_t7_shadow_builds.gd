extends "res://scripts/tools/run_m6_t7.gd"
## Frozen actual-acquisition controls, not additional progression wins.
func _initialize() -> void:
	SaveSystem.session_only=true
	call_deferred("run")

func run() -> void:
	config=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/m6_tavern_1023_protocol.json"))
	protocol=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/subclass_protocol.json"))
	registry=BuildContentRegistry.test_mode()
	state=root.get_node("BuildState")
	var targets: Array=JSON.parse_string(FileAccess.get_file_as_string(REPORT+"/encounters.json")).encounters
	var output:=[]
	for file in DirAccess.get_files_at(T7_OUT):
		if not file.ends_with(".json"): continue
		var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(T7_OUT+"/"+file))
		if data.policy!="typical" or int(data.seed)<84001 or int(data.seed)>84008: continue
		main_name=data.primary
		if main_name!="shadow": continue
		var wanted: Array=["C1"] if main_name=="thief" else ["C4","C6"] if main_name=="shadow" else ["C10"] if main_name=="bladedancer" else []
		for stage in wanted:
			var snapshot: Dictionary={}
			for f in data.fights:
				if f.stage==stage: snapshot=f; break
			if snapshot.is_empty(): continue
			snapshot=snapshot.duplicate(true)
			var prior: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DEST+"/shadow_primary.json")).winners
			snapshot.ranks=prior[stage].ranks
			var model:=RankedBuild.new()
			var ranks:={}
			for id in snapshot.ranks: ranks[id]=int(snapshot.ranks[id])
			require(model.configure(registry.trees["tree."+main_name],registry.trees["tree."+data.secondary],int(snapshot.points),ranks),"Acquired ranked snapshot")
			var gear:=SaveSystem._gear_list_from_data(snapshot.gear)
			var c:=BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],model,gear,int(snapshot.gold))
			for e in targets:
				if e.checkpoint!=stage: continue
				var chosen: bool=(main_name=="thief" and ((int(e.get("route_seed",0))==7001 and e.role=="CAPTAIN") or (int(e.get("route_seed",0))==85016 and e.role=="BOSS"))) or (main_name!="thief" and int(e.get("route_seed",0))==7001 and e.role=="BOSS")
				if not chosen: continue
				var enemy:=enemy_for(e)
				var pool:=candidates(legal_ids(config.reasonable_macros[main_name],c),c)
				for skill in c.skills:
					if skill.id!="skill.hold": pool.append([skill.id.trim_prefix("skill.")])
				for raw in [["rending_thrust","quick_cut"],["mug","steal","pick_pocket"],["mug","pick_pocket","steal"],["steal","mug","pick_pocket"],["steal","pick_pocket","mug"],["pick_pocket","mug","steal"],["pick_pocket","steal","mug"]]: pool.append(legal_ids(raw,c))
				var best: Array=pool[0]
				var score:=-1.0
				for ids in pool:
					var value:=0.0
					for seed in [1101,1102]: value+=simulate(ids,c,enemy,int(e.duration),seed).total_damage
					if value>score: score=value; best=ids
				var samples:=[]
				for seed in range(207001,207021):
					var first=simulate(best,c,enemy,int(e.duration),RunRng.seed_for_context(seed,RunRng.CONTEXT_COMBAT,[e.fight_key,0]))
					var won: bool=first.is_win
					var retry_damage:=-1.0
					if not won:
						var rc:=BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],model,gear,int(snapshot.gold)+first.gold_stolen)
						var retry=simulate(best,rc,enemy,int(e.duration),RunRng.seed_for_context(seed,RunRng.CONTEXT_COMBAT,[e.fight_key,1]))
						won=retry.is_win
						retry_damage=retry.total_damage
					samples.append({"root":seed,"damage":first.total_damage,"first_win":first.is_win,"theft":first.gold_stolen,"retry_damage":retry_damage,"within_two":won})
				output.append({"source":file,"stage":stage,"encounter":e.id,"macro":best,"snapshot":snapshot,"samples":samples})
	if t7_failed: quit(1); return
	SaveSystem.write_json("res://reports/p6_m6_t7/shadow_builds.json",{"complete":true,"checks":checks,"rows":output})
	print("T7 SHADOW BUILDS PASS rows=",output.size()," checks=",checks)
	quit(0)
