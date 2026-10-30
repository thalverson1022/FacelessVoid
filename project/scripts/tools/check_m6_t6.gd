extends "res://scripts/tools/run_m6_t6.gd"
## Replay and Practice parity for recorded enemy trials, plus immutable legacy comparison.
func run() -> void:
	registry=BuildContentRegistry.test_mode()
	state=root.get_node("BuildState")
	var evidence:=[]
	for tree in TREES:
		main_name=tree
		var fixtures: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(REPORT+"/fixtures_%s_84002.json"%tree))
		var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(REPORT+"/trial_%s_84002.json"%tree))
		require(data.complete,"Finished trial")
		var visited:={}
		for row in data.rows:
			if row.policy!="typical": continue
			var key: String=row.stage+"_"+row.arm
			if visited.has(key): continue
			visited[key]=true
			var snapshot: Dictionary={}
			for s in fixtures.snapshots:
				if s.id==row.snapshot: snapshot=s; break
			require(not snapshot.is_empty(),"Recorded snapshot")
			var c:=resolved(snapshot,row.ranks)
			var enemy:=Monster.new()
			for field in row.enemy: enemy.set(field,row.enemy[field])
			var ids: Array=row.macro
			var first=simulate(ids,c,enemy,int(row.duration),107001)
			var repeat_result=simulate(ids,c,enemy,int(row.duration),107001)
			require(first.total_damage==repeat_result.total_damage and first.rng_final_state==repeat_result.rng_final_state,"Deterministic trial replay")
			var practice:=TrainingRoomState.new()
			practice.content_registry=registry
			practice.selected_class=registry.classes["class.rogue"]
			practice.ranked_build=c.model
			practice.selected_trees=c.model.trees()
			practice.earned_talent_points=int(snapshot.budget)
			for slot in ["equipped_weapon","equipped_helm","equipped_armor","equipped_trinket","equipped_charm"]: practice.set(slot,null)
			for item in c.gear: practice.set(["equipped_weapon","equipped_helm","equipped_armor","equipped_trinket","equipped_charm"][item.slot],item)
			practice.selected_target=enemy
			practice.set_practice_gold(int(snapshot.gold))
			practice.set_rotation(rotation(ids,c))
			practice.set_duration_ms(int(row.duration))
			practice.set_random_fight_seed_enabled(false)
			practice.set_fight_seed(107001)
			practice.set_locked(true)
			practice.run_fight()
			require(practice.last_result!=null and practice.last_result.total_damage==first.total_damage,"Trial Practice parity")
			evidence.append({"tree":tree,"stage":row.stage,"arm":row.arm,"damage":first.total_damage,"replay":true,"practice":true})
	var legacy:={}
	for spec in Lab._scenario_specs():
		if spec.id=="bladedancer_contract_watchmen":
			spec.seed_count=200
			legacy=Lab.run_scenario_spec(spec)
	SaveSystem.write_json(REPORT+"/parity_and_watchmen.json",{"complete":true,"checks":checks,"parity":evidence,"legacy_watchmen":legacy})
	print("T6 PARITY PASS cases=",evidence.size()," checks=",checks)
	quit(0)
