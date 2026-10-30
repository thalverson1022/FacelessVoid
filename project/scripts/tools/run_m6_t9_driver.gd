extends "res://scripts/tools/run_m6_t7.gd"
## Post-hoc matched diagnostics; never changes run decisions or product resources.
func _initialize() -> void:
	SaveSystem.session_only=true
	call_deferred("run")
func run() -> void:
	registry=BuildContentRegistry.adventure()
	state=root.get_node("BuildState")
	var records:=[]
	for file in DirAccess.get_files_at("res://reports/p6_m6_t9/runs"):
		if not file.contains("_informed_23300") or not file.ends_with(".json"):continue
		var d: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://reports/p6_m6_t9/runs/"+file))
		main_name=d.primary
		for f in d.fights:
			if int(f.attempt)!=0 or f.stage not in ["C6","C10","C20","C30"]:continue
			var s:={"secondary":d.secondary,"budget":int(f.points),"gold":int(f.gold),"gear":f.gear}
			var c:=resolved(s,f.ranks)
			var altered: Array[GearItem]=[]
			var removed:=[]
			for gear in c.gear:
				var copy: GearItem=gear.duplicate(true)
				if copy.physical_damage_per_gold!=0.0:removed.append({"id":copy.id,"coefficient":copy.physical_damage_per_gold})
				copy.physical_damage_per_gold=0.0
				altered.append(copy)
			if removed.is_empty():continue
			var enemy:=Monster.new()
			for key in f.enemy:enemy.set(key,f.enemy[key])
			var replay=simulate(f.macro,c,enemy,int(f.duration),int(f.seed))
			require(is_equal_approx(replay.total_damage,float(f.damage)) and replay.is_win==f.win,"Exact held-out fight replay")
			var control:=BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],c.model,altered,int(f.gold))
			var result=simulate(f.macro,control,enemy,int(f.duration),int(f.seed))
			records.append({"run":file,"primary":main_name,"secondary":d.secondary,"stage":f.stage,"key":f.key,"gold":f.gold,"removed":removed,"baseline_damage":replay.total_damage,"baseline_win":replay.is_win,"control_damage":result.total_damage,"control_win":result.is_win,"hp":enemy.hp,"baseline_bonus_physical":c.stats.bonus_physical_damage,"control_bonus_physical":control.stats.bonus_physical_damage})
	SaveSystem.write_json("res://reports/p6_m6_t9/driver.json",{"passed":not t7_failed,"checks":checks,"rows":records,"post_hoc_only":true,"no_run_recomputed":true})
	print("T9 DRIVER ","FAIL" if t7_failed else "PASS"," rows=",records.size()," checks=",checks)
	quit(1 if t7_failed else 0)
