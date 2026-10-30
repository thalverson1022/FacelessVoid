extends "res://scripts/tools/run_m6_t5_search.gd"
## Isolated Steal timing sweep; no content resources or source values changed.
var timing := 1300
var trials := []

func run() -> void:
	config = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/m6_tavern_1023_protocol.json"))
	protocol = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/subclass_protocol.json"))
	registry = BuildContentRegistry.test_mode()
	main_name = "thief"
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT + "/thief/fixtures.json"))
	snapshots = base.snapshots
	encounters = JSON.parse_string(FileAccess.get_file_as_string(OUT + "/thief/encounters.json")).encounters
	var searched: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DEST + "/thief.json"))
	for stage in ["T1","T2","T3","C1","C10","C15","C20"]:
		for policy in ["weak","typical","strong"]:
			var s := fixture(stage,policy)
			var ranks: Dictionary = searched.winners.get("T1" if stage=="T2" else stage,{}).get("ranks",s.ranks) if stage.begins_with("T") else s.ranks
			for e in encounters:
				if e.checkpoint != stage or e.get("template_extra",false) or e.role not in ["TAVERN","BOSS","CAPTAIN"]: continue
				for value in [1300,1150,1100,1000]:
					timing=value
					test(s,e,ranks)
		print("Steal trial ",stage," rows=",trials.size())
		SaveSystem.write_json(DEST+"/steal_timing.json",{"complete":false,"trials":trials,"checks":checks})
	# Secondary Thief controls retain majority investment in each other primary.
	for primary in ["bladedancer","assassin","shadow"]:
		main_name=primary
		base=JSON.parse_string(FileAccess.get_file_as_string(OUT+"/"+primary+"/fixtures.json"))
		for s in base.snapshots:
			if s.checkpoint!="C15" or s.secondary!="thief" or s.policy!="typical": continue
			var ranks: Dictionary=allocate(primary,"thief",45,24).rank_map()
			for e in encounters:
				if e.checkpoint!="C15" or e.get("template_extra",false) or e.role!="BOSS":continue
				for value in [1300,1150,1100,1000]:
					timing=value
					test(s,e,ranks)
	SaveSystem.write_json(DEST+"/steal_timing.json",{"complete":true,"trials":trials,"checks":checks})
	print("Steal timing sweep PASS checks=",checks)
	quit(0)

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
	for seed_root in range(97001,97061):
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
	trials.append({"main":main_name,"secondary":s.secondary,"stage":s.checkpoint,"policy":s.policy,"snapshot":s.id,"ranks":ranks,"encounter":e.id,"role":e.role,"base_execution_ms":timing,"macro":ids,"wins":wins,"within_two":both,"count":60,"mean_damage":damage/60.0,"mean_gold_stolen":gold/60.0,"mean_margin":damage/60.0/enemy.hp-1.0,"max_trigger_candidates":max_triggers,"samples":samples})
