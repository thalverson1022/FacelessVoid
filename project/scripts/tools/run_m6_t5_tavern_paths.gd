extends "res://scripts/tools/run_m6_t5_search.gd"
## Reacquire Tavern equipment with a monotonic selected allocation path.
var timing := 1300
var trials := []
var first_ranks := {}
var third_ranks := {}

func run() -> void:
	config = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/m6_tavern_1023_protocol.json"))
	protocol = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/subclass_protocol.json"))
	registry = BuildContentRegistry.test_mode()
	state = root.get_node("BuildState")
	var paths := []
	for tree in TREES:
		main_name=tree
		var search:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DEST+"/"+tree+".json"))
		first_ranks=search.winners.T1.ranks
		third_ranks=search.winners.T3.ranks
		var compatible:=true
		for id in first_ranks:
			if int(third_ranks.get(id,0))<int(first_ranks[id]): compatible=false
		if not compatible:
			for group in search.search:
				if group.stage!="T3":continue
				for candidate in group.initial_candidates:
					compatible=true
					for id in first_ranks:
						if int(candidate.ranks.get(id,0))<int(first_ranks[id]): compatible=false
					if compatible:
						third_ranks=candidate.ranks
						break
		require(compatible,"Monotonic Tavern investment")
		paths.append({"main":tree,"one_point":first_ranks,"three_points":third_ranks})
		for policy in ["weak","typical","strong"]:
			state.reset()
			SaveSystem.session_only=true
			state.set_adventure_seed(84001)
			state.set_class(registry.classes["class.rogue"])
			for index in 4:
				set_model("")
				capture("T"+str(index),"",policy)
				var s:Dictionary=snapshots.back()
				var native:=RunFlow.load_encounter(index)
				var e:Dictionary={"id":"T"+str(index),"role":"TAVERN","fight_key":"encounter:%d"%index,"duration":native.duration_ms,"monster_path":RunFlow.ENCOUNTER_PATHS[index]}
				for value in ([1300,1100] if tree=="thief" else [1300]):
					timing=value
					test(s,e,s.ranks)
				reward("",policy,"T"+str(index))
		print("Tavern coherent path ",tree," complete")
		SaveSystem.write_json(DEST+"/tavern_paths.json",{"complete":false,"paths":paths,"snapshots":snapshots,"ledger":ledger,"trials":trials,"checks":checks})
	SaveSystem.write_json(DEST+"/tavern_paths.json",{"complete":true,"paths":paths,"snapshots":snapshots,"ledger":ledger,"trials":trials,"checks":checks})
	state.reset()
	print("Tavern coherent paths PASS checks=",checks)
	quit(0)

func set_model(_secondary: String) -> void:
	var budget:int=state.earned_talent_points
	var ranks:Dictionary=first_ranks if budget==1 else third_ranks if budget==3 else {}
	if budget==6:
		state.ranked_build=allocate(main_name,"",6)
	else:
		state.ranked_build=model_for({"secondary":"","budget":budget},ranks)
	state.selected_trees=state.ranked_build.trees()

func resolved(s: Dictionary,ranks: Dictionary,gold_delta: int=0) -> Dictionary:
	var c := super.resolved(s,ranks,gold_delta)
	var copies: Array[Skill] = []
	for skill in c.skills:
		var copy: Skill=skill.duplicate(true)
		if copy.id=="skill.steal": copy.base_execution_ms=timing
		copies.append(copy)
	c.skills=copies
	return c

func test(s: Dictionary,e: Dictionary,ranks: Dictionary) -> void:
	var c:=resolved(s,ranks)
	var ids: Array=train(c,e,true).macro
	var enemy:=enemy_for(e)
	var wins:=0
	var both:=0
	var damage:=0.0
	var gold:=0.0
	var max_triggers:=0
	var samples:=[]
	for seed_root in range(98001,98101):
		var seed:=RunRng.seed_for_context(seed_root,RunRng.CONTEXT_COMBAT,[e.fight_key,0])
		var first=simulate(ids,c,enemy,int(e.duration),seed)
		wins+=int(first.is_win)
		var won:bool=first.is_win
		if not won:
			var retry=simulate(ids,resolved(s,ranks,first.gold_stolen),enemy,int(e.duration),RunRng.seed_for_context(seed_root,RunRng.CONTEXT_COMBAT,[e.fight_key,1]))
			won=retry.is_win
		both+=int(won)
		damage+=first.total_damage
		gold+=first.gold_stolen
		max_triggers=maxi(max_triggers,first.trigger_candidates_evaluated)
		samples.append({"root":seed_root,"damage":first.total_damage,"win":first.is_win,"within_two":won,"stolen":first.gold_stolen})
	trials.append({"main":main_name,"secondary":s.secondary,"stage":s.checkpoint,"policy":s.policy,"snapshot":s.id,"ranks":ranks,"encounter":e.id,"role":e.role,"base_execution_ms":timing,"macro":ids,"wins":wins,"within_two":both,"count":100,"mean_damage":damage/100.0,"mean_gold_stolen":gold/100.0,"mean_margin":damage/100.0/enemy.hp-1.0,"max_trigger_candidates":max_triggers,"samples":samples})
