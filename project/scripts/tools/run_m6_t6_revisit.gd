extends "res://scripts/tools/run_m6_t7.gd"
const REVISIT := "res://reports/p6_m6_t6_revisit"
func _initialize() -> void:
	SaveSystem.session_only=true
	DirAccess.make_dir_recursive_absolute(REVISIT)
	call_deferred("run")

func run() -> void:
	registry=BuildContentRegistry.test_mode()
	state=root.get_node("BuildState")
	var old: Array=JSON.parse_string(FileAccess.get_file_as_string("res://reports/p6_m6_t7/matchups.json")).rows
	var optimized: Array=JSON.parse_string(FileAccess.get_file_as_string("res://reports/p6_m6_t7/shadow_builds.json")).rows
	var targets: Array=JSON.parse_string(FileAccess.get_file_as_string(REPORT+"/encounters.json")).encounters
	var output:=[]
	for original in old:
		if original.encounter.ends_with("main_road") or original.encounter.ends_with("pressure_fight"): continue
		var prior: Dictionary=original
		for alternative in optimized:
			if alternative.source==original.source and alternative.encounter==original.encounter: prior=alternative; break
		main_name=str(prior.source).split("_")[0]
		var trajectory: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(T7_OUT+"/"+prior.source))
		var s: Dictionary=prior.snapshot
		var normalized:={}
		for id in s.ranks: normalized[id]=int(s.ranks[id])
		var model:=RankedBuild.new()
		require(model.configure(registry.trees["tree."+main_name],registry.trees["tree."+trajectory.secondary],int(s.points),normalized),"Legal frozen allocation")
		var gear:=SaveSystem._gear_list_from_data(s.gear)
		var c:=BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],model,gear,int(s.gold))
		var e: Dictionary={}
		for candidate in targets:
			if candidate.id==prior.encounter: e=candidate; break
		require(not e.is_empty(),"Exact original encounter")
		var base:=enemy_for(e)
		var arms: Array=["baseline"] if main_name=="bladedancer" else ["baseline","hp90","hp80","cleanse6"]
		if str(e.id).ends_with("toll_fight"): arms=["baseline","hp90","hp80","duration_floor"]
		for arm in arms:
			var enemy: Monster=base.duplicate(true)
			if arm=="hp90": enemy.hp=roundi(base.hp*0.9)
			if arm=="hp80": enemy.hp=roundi(base.hp*0.8)
			if arm=="cleanse6" and enemy.cleanse_threshold>0: enemy.cleanse_threshold=maxi(enemy.cleanse_threshold,6)
			if arm=="duration_floor": enemy.hp=roundi(base.hp*minf(1.0,float(e.duration)/1000.0/float(e.payload.pressure_metadata.hp_budget_duration_sec)))
			var samples:=[]
			for seed in range(208001,208041):
				var first=simulate(prior.macro,c,enemy,int(e.duration),RunRng.seed_for_context(seed,RunRng.CONTEXT_COMBAT,[e.fight_key,0]))
				var won: bool=first.is_win
				var retry_damage:=-1.0
				if not won:
					var rc:=BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],model,gear,int(s.gold)+first.gold_stolen)
					var retry=simulate(prior.macro,rc,enemy,int(e.duration),RunRng.seed_for_context(seed,RunRng.CONTEXT_COMBAT,[e.fight_key,1]))
					won=retry.is_win
					retry_damage=retry.total_damage
				samples.append({"root":seed,"damage":first.total_damage,"win":first.is_win,"stolen":first.gold_stolen,"retry_damage":retry_damage,"within_two":won})
			output.append({"source":prior.source,"stage":prior.stage,"primary":main_name,"encounter":e.id,"arm":arm,"snapshot":s,"macro":prior.macro,"enemy":stat_record(enemy),"baseline_enemy":stat_record(base),"samples":samples})
	if t7_failed: quit(1); return
	SaveSystem.write_json(REVISIT+"/trials.json",{"complete":true,"checks":checks,"rows":output})
	print("T6 REVISIT PASS rows=",output.size()," checks=",checks)
	quit(0)
