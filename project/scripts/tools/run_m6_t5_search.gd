extends "res://scripts/tools/run_m6_tavern_1023.gd"
## T5 bounded build/macro search; live content is never mutated.
const DEST := "res://reports/p6_m6_t5"
const TREES := ["bladedancer", "thief", "assassin", "shadow"]
var search_log := []
var measurements := []
var winners := {}
var rng := RandomNumberGenerator.new()
var fixed_rng := RandomNumberGenerator.new()

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tree="): main_name = arg.trim_prefix("--tree=")
	DirAccess.make_dir_recursive_absolute(DEST)
	SaveSystem.save_path = DEST + "/" + main_name + "_save.json"
	PracticeSaveSystem.save_path = DEST + "/" + main_name + "_practice.json"
	PracticeSaveSystem.core_save_path = DEST + "/" + main_name + "_core.json"
	call_deferred("run")

func run() -> void:
	config = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/m6_tavern_1023_protocol.json"))
	protocol = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/subclass_protocol.json"))
	registry = BuildContentRegistry.test_mode()
	require(registry.error == "", registry.error)
	state = root.get_node("BuildState")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT + "/" + main_name + "/fixtures.json"))
	snapshots = data.snapshots
	encounters = JSON.parse_string(FileAccess.get_file_as_string(OUT + "/" + main_name + "/encounters.json")).encounters
	var stages := ["T0", "T1", "T3", "C1", "C10", "C15"]
	if main_name == "bladedancer": stages.insert(4, "C4")
	if main_name == "shadow": stages = ["T0", "T1", "T3", "C1", "C4", "C6", "C8", "C10", "C15"]
	if main_name == "assassin": stages.insert(4, "C6")
	for stage in stages:
		investigate(stage)
		write_report(false)
		print("T5 ", main_name, " ", stage, " complete; measurements=", measurements.size())
	write_report(true)
	print("T5 search PASS ", main_name, " checks=", checks)
	quit(0)

func write_report(complete: bool) -> void:
	SaveSystem.write_json(DEST + "/" + main_name + ".json", {"complete": complete, "tree": main_name, "search": search_log, "winners": winners, "measurements": measurements, "checks": checks})

func fixture(stage: String, policy: String) -> Dictionary:
	var secondary: String = TREES[(TREES.find(main_name) + 1) % 4]
	for item in snapshots:
		if item.checkpoint == stage and item.policy == policy and item.trajectory_secondary == secondary: return item
	return {}

func model_for(s: Dictionary, ranks: Dictionary) -> RankedBuild:
	var normalized := {}
	for id in ranks: normalized[id] = int(ranks[id])
	var m := RankedBuild.new()
	require(m.configure(registry.trees["tree." + main_name], registry.trees.get("tree." + str(s.secondary)), int(s.budget), normalized), "Legal alternative allocation: " + m.last_error)
	return m

func resolved(s: Dictionary, ranks: Dictionary, gold_delta: int = 0) -> Dictionary:
	var m := model_for(s, ranks)
	var gear := SaveSystem._gear_list_from_data(s.gear)
	var c := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"], m, gear, int(s.gold) + gold_delta)
	require(c.error == "", "Resolved alternative")
	c["model"] = m
	c["gear"] = gear
	return c

func signature(ranks: Dictionary) -> String:
	var keys := ranks.keys()
	keys.sort()
	var parts := []
	for key in keys: parts.append(str(key) + ":" + str(ranks[key]))
	return ",".join(parts)

func rank_candidates(s: Dictionary) -> Array:
	var found := [s.ranks]
	var seen := {signature(s.ranks): true}
	# Exhaustive legal purchase states at the small Tavern budgets.
	if int(s.budget) <= 3:
		var layer := [{}]
		for point in int(s.budget):
			var next := []
			var unique := {}
			for ranks in layer:
				for talent in registry.trees["tree." + main_name].talents:
					var m := model_for(s, ranks)
					if m.buy(talent.id):
						var key := signature(m.rank_map())
						if not unique.has(key):
							unique[key] = true
							next.append(m.rank_map())
			layer = next
		for ranks in layer:
			if not seen.has(signature(ranks)): found.append(ranks)
		return found
	rng.seed = 5501 + int(s.budget) * 17 + TREES.find(main_name)
	for attempt in 64:
		var m := model_for(s, {})
		var priorities := []
		for tree in m.trees():
			for talent in tree.talents:
				var weight := rng.randf()
				if tree == m.secondary_tree(): weight *= 0.35 if attempt % 3 != 0 else 1.0
				priorities.append({"id": talent.id, "weight": weight})
		priorities.sort_custom(func(a,b): return a.weight > b.weight)
		for point in int(s.budget):
			for entry in priorities:
				if m.buy(entry.id): break
		if m.points_spent() == int(s.budget) and not seen.has(signature(m.rank_map())):
			seen[signature(m.rank_map())] = true
			found.append(m.rank_map())
		if found.size() >= 24: break
	return found

func macros(c: Dictionary, broad: bool) -> Array:
	var reasonable := legal_ids(config.reasonable_macros[main_name], c)
	var pool := candidates(reasonable, c)
	var ids := []
	for skill in c.skills:
		if skill.id != "skill.hold": ids.append(skill.id.trim_prefix("skill."))
	for id in ids:
		if not pool.has([id]): pool.append([id])
	for raw in [["quick_cut","leaping_plunge"],["quick_cut","stab","leaping_plunge"],["steal","mug"],["venom_jab","blinding_powder"],["toxic_flurry","killers_mark"],["toxic_flurry","distilled_corruption","killers_mark"],["toxic_flurry","beguiling_presence","touch_of_darkness","killers_mark"],["rending_thrust","quick_cut","leaping_plunge"]]:
		var v := legal_ids(raw,c)
		if not pool.has(v): pool.append(v)
	fixed_rng.seed = 61231
	for attempt in (64 if broad else 8):
		var v := []
		for index in fixed_rng.randi_range(2, 7): v.append(ids[fixed_rng.randi_range(0,ids.size()-1)])
		if not pool.has(v): pool.append(v)
	return pool

func train(c: Dictionary, e: Dictionary, broad: bool) -> Dictionary:
	var enemy := enemy_for(e)
	var best := {"score": -1.0, "macro": []}
	for ids in macros(c,broad):
		var total := 0.0
		for seed in ([501,502,503,504] if broad else [501,502]): total += simulate(ids,c,enemy,int(e.duration),seed).total_damage
		var score := total / (4.0 if broad else 2.0)
		if score > best.score: best = {"score": score, "macro": ids}
	return best

func investigate(stage: String) -> void:
	var s := fixture(stage,"typical")
	var targets := []
	for e in encounters:
		if (e.checkpoint == stage or (stage == "T1" and e.checkpoint == "T2")) and not e.get("template_extra",false): targets.append(e)
	var target: Dictionary = targets[0]
	for e in targets:
		if e.role == "BOSS": target = e
	var ranked := []
	for ranks in rank_candidates(s):
		var c := resolved(s,ranks)
		var candidate := train(c,target,false)
		candidate["ranks"] = ranks
		ranked.append(candidate)
	ranked.sort_custom(func(a,b): return a.score>b.score)
	var finalists := []
	for item in ranked.slice(0,3):
		var final := train(resolved(s,item.ranks),target,true)
		final["ranks"] = item.ranks
		finalists.append(final)
	finalists.sort_custom(func(a,b): return a.score>b.score)
	var best: Dictionary = finalists[0]
	winners[stage] = best
	search_log.append({"stage":stage,"target":target.id,"gear_snapshot":s.id,"initial_candidates":ranked,"finalists":finalists})
	# One allocation selected against the stage boss; same allocation tested across roles.
	for policy in ["weak","typical","strong"]:
		for e in targets:
			var snap := fixture(e.checkpoint,policy)
			var original := resolved(snap,snap.ranks)
			var alternative := resolved(snap,best.ranks)
			var tuned_macro: Array = train(original,e,true).macro
			var alternative_macro: Array = train(alternative,e,true).macro
			validate_case(snap,e,snap.ranks,legal_ids(config.reasonable_macros[main_name],original),tuned_macro,"reference")
			validate_case(snap,e,snap.ranks,tuned_macro,tuned_macro,"macro_search")
			validate_case(snap,e,best.ranks,alternative_macro,alternative_macro,"build_search")

func validate_case(s: Dictionary, e: Dictionary, ranks: Dictionary, ids: Array, retry_ids: Array, arm: String) -> void:
	var c := resolved(s,ranks)
	var enemy := enemy_for(e)
	var samples := []
	var wins := 0
	var within_two := 0
	var total := 0.0
	var diagnostic := {}
	for root_seed in range(96001,96041):
		var seed := RunRng.seed_for_context(root_seed,RunRng.CONTEXT_COMBAT,[e.fight_key,0])
		var first = simulate(ids,c,enemy,int(e.duration),seed)
		var won: bool = first.is_win
		wins += int(won)
		total += first.total_damage
		var retry_damage := -1.0
		if not won:
			var again := resolved(s,ranks,first.gold_stolen)
			var retry_seed := RunRng.seed_for_context(root_seed,RunRng.CONTEXT_COMBAT,[e.fight_key,1])
			var retry = simulate(retry_ids,again,enemy,int(e.duration),retry_seed)
			won = retry.is_win
			retry_damage = retry.total_damage
		within_two += int(won)
		samples.append({"root":root_seed,"seed":seed,"damage":first.total_damage,"win":first.is_win,"retry_damage":retry_damage,"within_two":won,"stolen":first.gold_stolen})
		if diagnostic.is_empty():
			var physical := 0.0
			var blocked := 0.0
			var unavailable := 0
			var poison_applied := 0
			var shred_applied := 0
			for event in first.cast_events:
				physical += event.physical_damage
				blocked += event.blocked_amount
				unavailable += int(event.resource_unavailable)
				poison_applied += event.poison_stacks_applied
				shred_applied += event.shred_stacks_applied
			diagnostic = {"physical_cast_damage":physical,"blocked":blocked,"unavailable_casts":unavailable,"poison_applications":poison_applied,"shred_applications":shred_applied,"poison_ticks":first.tick_events.size(),"trigger_candidates":first.trigger_candidates_evaluated,"retrigger_chance":c.stats.retrigger_chance,"gold":s.gold}
	measurements.append({"stage":s.checkpoint,"policy":s.policy,"snapshot":s.id,"encounter":e.id,"role":e.role,"mandatory":e.mandatory,"arm":arm,"ranks":ranks,"macro":ids,"retry_macro":retry_ids,"wins":wins,"within_two":within_two,"count":40,"mean_margin":total/40.0/enemy.hp-1.0,"diagnostic":diagnostic,"samples":samples})

