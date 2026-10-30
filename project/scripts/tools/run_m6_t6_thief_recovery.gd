extends "res://scripts/tools/run_m6_t6.gd"
func run() -> void:
	main_name="thief"
	registry=BuildContentRegistry.test_mode()
	state=root.get_node("BuildState")
	config=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/m6_tavern_1023_protocol.json"))
	protocol=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/subclass_protocol.json"))
	encounters=JSON.parse_string(FileAccess.get_file_as_string(REPORT+"/encounters.json")).encounters
	var targets:=[]
	for e in encounters:
		if e.id=="C1_7001_route.generated_503030985.toll_fight" or e.id=="C1_85016_route.generated_360937729.boss": targets.append(e)
	require(targets.size()==2,"Two known timing encounters")
	var all_search:=[]
	for acquisition in [84001,84002,84003]:
		history=acquisition
		snapshots=JSON.parse_string(FileAccess.get_file_as_string(REPORT+"/fixtures_thief_%d.json"%history)).snapshots
		var s:=fixture("C1","typical").duplicate(true)
		s.secondary=""
		var layer: Array=[{}]
		for point in 6:
			var next:=[]
			var seen:={}
			for ranks in layer:
				for talent in registry.trees["tree.thief"].talents:
					var model:=model_for(s,ranks)
					if model.buy(talent.id):
						var key:=signature(model.rank_map())
						if not seen.has(key): seen[key]=true; next.append(model.rank_map())
			layer=next
		var best:={"score":-1.0}
		for ranks in layer:
			var c:=resolved(s,ranks)
			var skills:=[]
			for skill in c.skills:
				if skill.id!="skill.hold": skills.append(skill.id.trim_prefix("skill."))
			var pool:=[]
			for a in skills:
				pool.append([a])
				for b in skills:
					pool.append([a,b])
					for cc in skills: pool.append([a,b,cc])
			var score:=INF
			var selected:={}
			for e in targets:
				var top:=-1.0
				var ids:=[]
				for macro in pool:
					var damage:=0.0
					for seed in [551,552,553]: damage+=simulate(macro,c,enemy_for(e),int(e.duration),seed).total_damage
					if damage>top: top=damage; ids=macro
				score=minf(score,top/3.0/float(enemy_for(e).hp))
				selected[e.id]=ids
			all_search.append({"history":history,"ranks":ranks,"score":score,"macros":selected,"legal_allocations":layer.size()})
			if score>best.score: best={"score":score,"ranks":ranks,"macros":selected}
		for e in targets:
			rows.append(measure(s,e,best.ranks,best.macros[e.id],best.macros[e.id],"primary_recovery",106001,100,enemy_for(e)))
		print("Thief recovery ",history," best=",best," allocations=",layer.size())
		SaveSystem.write_json(REPORT+"/thief_recovery.json",{"complete":false,"rows":rows,"search":all_search,"checks":checks})
	SaveSystem.write_json(REPORT+"/thief_recovery.json",{"complete":true,"rows":rows,"search":all_search,"checks":checks})
	print("T6 RECOVERY PASS")
	quit(0)
