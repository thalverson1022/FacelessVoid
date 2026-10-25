extends "res://scripts/tools/run_m6_t6.gd"
const ADOPTION := "res://reports/p6_m6_t6_adoption"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ADOPTION)
	SaveSystem.save_path=ADOPTION+"/adventure.json"
	PracticeSaveSystem.save_path=ADOPTION+"/practice.json"
	PracticeSaveSystem.core_save_path=ADOPTION+"/core.json"
	SaveSystem.session_only=true
	call_deferred("run")

func run() -> void:
	registry=BuildContentRegistry.test_mode()
	require(registry.error=="",registry.error)
	state=root.get_node("BuildState")
	history=84002
	var buddy:=RunFlow.load_encounter(1)
	require(buddy.monster.armor==140 and buddy.monster.hp==155 and is_equal_approx(buddy.monster.poison_resistance,0.1) and buddy.duration_ms==18000,"Approved live resource and retained fields")
	var output:=[]
	var first_attempts:=0
	for tree in TREES:
		main_name=tree
		snapshots=JSON.parse_string(FileAccess.get_file_as_string(REPORT+"/fixtures_%s_84002.json"%tree)).snapshots
		var expected:=[]
		var confirmation: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(REPORT+"/confirm_%s_84002.json"%tree))
		for row in confirmation.rows:
			if row.arm=="buddy_armor140": expected.append(row)
		var screen_data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(REPORT+"/screen_"+tree+".json"))
		for row in screen_data.rows:
			if row.stage in ["T0","T2","T3"]: expected.append(row)
		for prior in expected:
			var s: Dictionary={}
			for candidate in snapshots:
				if candidate.id==prior.snapshot: s=candidate; break
			require(not s.is_empty(),"Frozen snapshot")
			var index:=int(str(prior.stage).trim_prefix("T"))
			var native:=RunFlow.load_encounter(index)
			var e:={"id":prior.encounter,"checkpoint":prior.stage,"role":"TAVERN","mandatory":true,"fight_key":"encounter:%d"%index,"duration":native.duration_ms}
			var actual:=measure(s,e,prior.ranks,prior.macro,prior.retry_macro,"live_adoption",int(prior.samples[0].root),int(prior.count),native.monster)
			for i in prior.samples.size():
				var a: Dictionary=actual.samples[i]
				var b: Dictionary=prior.samples[i]
				for key in ["damage","win","retry_damage","within_two","stolen","root"]:
					require(a[key]==b[key],"Live candidate or unchanged control sample: "+tree+" "+prior.stage+" "+key)
			first_attempts+=int(actual.count)
			output.append(actual)
	SaveSystem.write_json(ADOPTION+"/live_tavern.json",{"complete":true,"passed":true,"checks":checks,"first_attempts":first_attempts,"rows":output})
	print("T6 live adoption PASS first_attempts=",first_attempts," checks=",checks)
	quit(0)
