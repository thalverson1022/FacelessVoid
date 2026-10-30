extends "res://scripts/tools/run_m6_t7.gd"
func _initialize() -> void:
	SaveSystem.session_only=true
	call_deferred("run")
func choose_macro(c: Dictionary,e: Dictionary,broad: bool) -> Dictionary:
	var best:={"score":-1.0,"macro":[]}
	for ids in macros(c,broad):
		var score:=0.0
		for seed in [3101,3102]: score+=simulate(ids,c,enemy_for(e),int(e.duration),seed).total_damage
		if score>float(best.score): best={"score":score,"macro":ids}
	return best
func run() -> void:
	config=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/m6_tavern_1023_protocol.json"))
	protocol=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/subclass_protocol.json"))
	registry=BuildContentRegistry.test_mode()
	state=root.get_node("BuildState")
	main_name="shadow"
	var prior: Array=JSON.parse_string(FileAccess.get_file_as_string("res://reports/p6_m6_t7/shadow_builds.json")).rows
	var e: Dictionary={}
	for target in JSON.parse_string(FileAccess.get_file_as_string(REPORT+"/encounters.json")).encounters:
		if target.id=="C4_7001_route.generated_503030985.boss": e=target; break
	var output:=[]
	for row in prior:
		if row.stage!="C4": continue
		var raw: Dictionary=row.snapshot
		var s:={"secondary":"bladedancer","budget":int(raw.points),"ranks":raw.ranks,"gold":int(raw.gold),"gear":raw.gear}
		var original:=resolved(s,s.ranks)
		var macro_best:=choose_macro(original,e,true)
		var ranked:=[]
		for ranks in rank_candidates(s):
			var c:=resolved(s,ranks)
			if c.model.tree_points(registry.trees["tree.shadow"])<10: continue
			var candidate:=choose_macro(c,e,false)
			candidate["ranks"]=ranks
			ranked.append(candidate)
		ranked.sort_custom(func(a,b):return a.score>b.score)
		var winner:={"score":macro_best.score,"macro":macro_best.macro,"ranks":s.ranks}
		for candidate in ranked.slice(0,3):
			var final:=choose_macro(resolved(s,candidate.ranks),e,true)
			if final.score>winner.score: winner={"score":final.score,"macro":final.macro,"ranks":candidate.ranks}
		for arm in [{"id":"baseline","macro":row.macro,"ranks":s.ranks},{"id":"macro_recovery","macro":macro_best.macro,"ranks":s.ranks},{"id":"build_recovery","macro":winner.macro,"ranks":winner.ranks}]:
			var c:=resolved(s,arm.ranks)
			var samples:=[]
			for seed in range(210001,210041):
				var first=simulate(arm.macro,c,enemy_for(e),int(e.duration),RunRng.seed_for_context(seed,RunRng.CONTEXT_COMBAT,[e.fight_key,0]))
				var won: bool=first.is_win
				var retry_damage:=-1.0
				if not won:
					var retry=simulate(arm.macro,resolved(s,arm.ranks,first.gold_stolen),enemy_for(e),int(e.duration),RunRng.seed_for_context(seed,RunRng.CONTEXT_COMBAT,[e.fight_key,1]))
					won=retry.is_win
					retry_damage=retry.total_damage
				samples.append({"root":seed,"damage":first.total_damage,"win":first.is_win,"retry_damage":retry_damage,"within_two":won})
			output.append({"source":row.source,"snapshot":s,"arm":arm,"enemy":stat_record(enemy_for(e)),"samples":samples})
		print("Shadow recovery ",row.source)
	if t7_failed: quit(1); return
	DirAccess.make_dir_recursive_absolute("res://reports/p6_m6_t6_closeout")
	SaveSystem.write_json("res://reports/p6_m6_t6_closeout/shadow_recovery.json",{"complete":true,"checks":checks,"rows":output})
	print("SHADOW RECOVERY PASS ",checks)
	quit(0)
