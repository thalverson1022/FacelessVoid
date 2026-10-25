extends SceneTree
## T4 fixture acquisition and diagnostic matrix. No gameplay tuning.
const OUT := "res://reports/p6_m6_tavern_1023"
const Gen = preload("res://scripts/systems/contract_route_generator/contract_route_generator.gd")
const Lab = preload("res://scripts/tools/balance_lab.gd")
var config: Dictionary
var protocol: Dictionary
var registry: BuildContentRegistry
var state: Node
var main_name := "bladedancer"
var phase := "fixtures"
var snapshots := []
var ledger := []
var results := []
var raw_samples := []
var encounters := []
var checks := 0

func require(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		printerr("T4 FAILED: " + message)
		quit(1)
		assert(ok, message)

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tree="): main_name = arg.trim_prefix("--tree=")
		if arg.begins_with("--phase="): phase = arg.trim_prefix("--phase=")
	DirAccess.make_dir_recursive_absolute(OUT + "/" + main_name)
	SaveSystem.save_path = OUT + "/" + main_name + "/isolated_save.json"
	PracticeSaveSystem.save_path = OUT + "/" + main_name + "/isolated_practice.json"
	PracticeSaveSystem.core_save_path = OUT + "/" + main_name + "/isolated_core.json"
	call_deferred("run")

func path_for(name: String) -> String:
	return OUT + "/" + main_name + "/" + name + ".json"

func run() -> void:
	require(BuildProgression.CONTRACT_POINTS == 3 and BuildProgression.TAVERN_POINTS == [1, 0, 2, 3], "Live progression policy")
	config = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/m6_tavern_1023_protocol.json"))
	for index in config.contract_checkpoints.size(): config.contract_checkpoints[index] = int(config.contract_checkpoints[index])
	protocol = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/subclass_protocol.json"))
	registry = BuildContentRegistry.test_mode()
	require(registry.error == "", registry.error)
	var invalid := RankedBuild.new()
	require(not invalid.configure(registry.trees["tree.bladedancer"], null, 46), "Reject budget overflow")
	require(not invalid.configure(registry.trees["tree.bladedancer"], registry.trees["tree.bladedancer"], 45), "Reject duplicate roles")
	state = root.get_node("BuildState")
	if phase == "fixtures":
		for secondary in config.trees:
			if secondary == main_name: continue
			for policy in config.policies:
				acquire(secondary, policy)
				print("Fixtures ", main_name, "/", secondary, " ", policy)
		require(snapshots.size() == 144, "All checkpoint and shopping snapshots")
		SaveSystem.write_json(path_for("fixtures"), {"complete": true, "snapshots": snapshots, "ledger": ledger, "checks": checks})
	else:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path_for("fixtures")))
		require(data.complete, "Incomplete fixtures")
		snapshots = data.snapshots
		require(snapshots.size() == 144, "Fixture checkpoint coverage")
		build_encounters()
		matrix()
	state.reset()
	print("T4 ", main_name, " ", phase, " PASS; checks=", checks)
	quit(0)

func allocate(primary: String, secondary: String, budget: int, family: int = 35) -> RankedBuild:
	var model := RankedBuild.new()
	require(model.configure(registry.trees["tree." + primary], registry.trees.get("tree." + secondary), budget), "Configure roles")
	var primary_points := mini(family, budget)
	var secondary_points := budget - primary_points
	for pair in [[primary, primary_points], [secondary, secondary_points]]:
		if pair[1] == 0: continue
		var tree: SubclassTree = registry.trees["tree." + pair[0]]
		var priorities := []
		for target_points in [1, 10, 21, 35]:
			for entry in protocol.cases:
				if entry.tree != pair[0] or int(entry.points) != target_points: continue
				for id in entry.talent_ranks:
					for rank in int(entry.talent_ranks[id]): priorities.append([id, rank + 1])
		for talent in tree.talents:
			for rank in talent.max_ranks: priorities.append([talent.id, rank + 1])
		for repeat in range(40):
			for target in priorities:
				if model.tree_points(tree) >= int(pair[1]): break
				if model.rank_of(target[0]) < int(target[1]): model.buy(target[0])
		require(model.tree_points(tree) == int(pair[1]), "Exact tree budget " + pair[0])
	require(model.points_spent() == budget, "All earned points allocated")
	return model

func set_model(secondary: String) -> void:
	var selected := secondary if state.active_contract != null else ""
	state.ranked_build = allocate(main_name, selected, state.earned_talent_points)
	state.selected_trees = state.ranked_build.trees()

func gear_score(gear: Array[GearItem], gold: int) -> float:
	var resolved := BuildResolver.resolve_ranked_build(state.selected_class, state.ranked_build, gear, gold)
	require(resolved.error == "", "Gear scoring resolution")
	var stats: PlayerStats = resolved.stats
	var physical := (stats.weapon_damage_min + stats.weapon_damage_max) * 0.5 * stats.physical_damage_multiplier + stats.bonus_physical_damage
	var elemental := (stats.base_poison_damage + stats.bonus_base_elemental_damage) * stats.elemental_damage_multiplier
	var weight := 3.0 if main_name == "assassin" else 1.5 if main_name == "shadow" else 0.5
	return (physical + weight * elemental) * (1.0 + stats.attack_speed) * (1.0 + stats.crit_chance * (stats.crit_multiplier - 1.0))

func replacement_score(item: GearItem, gold: int) -> float:
	var gear: Array[GearItem] = []
	for equipped in state.equipped_gear():
		if equipped.slot != item.slot: gear.append(equipped)
	gear.append(item)
	return gear_score(gear, gold)

func sell_inventory() -> void:
	for item in state.inventory.duplicate():
		var before: int = state.gold
		require(state.sell_inventory_item(item), "Legal inventory sale")
		ledger.append({"action": "sell", "item": SaveSystem._gear_entry_to_data(item), "gold_before": before, "gold_after": state.gold})

func equip_best_inventory() -> void:
	for item in state.inventory.duplicate():
		if replacement_score(item, state.gold) > gear_score(state.equipped_gear(), state.gold):
			require(state.equip_from_inventory(item), "Equip acquired item")
			ledger.append({"action": "equip", "item": SaveSystem._gear_entry_to_data(item)})
	sell_inventory()

func capture(checkpoint: String, secondary: String, policy: String) -> void:
	var model: RankedBuild = state.ranked_build
	var gear := SaveSystem._gear_list_to_data(state.equipped_gear())
	var restored := SaveSystem._gear_list_from_data(gear)
	require(restored.size() == state.equipped_gear().size(), "Gear round trip")
	var a := BuildResolver.resolve_ranked_build(state.selected_class, model, state.equipped_gear(), state.gold)
	var b := BuildResolver.resolve_ranked_build(state.selected_class, model, restored, state.gold)
	require(is_equal_approx(a.stats.crit_chance, b.stats.crit_chance) and a.stats.weapon_damage_min == b.stats.weapon_damage_min, "Gear parity")
	snapshots.append({"id": "%s_%s_%s_%s" % [main_name, secondary, policy, checkpoint], "checkpoint": checkpoint, "primary": main_name, "secondary": secondary if model.secondary_tree() != null else "", "trajectory_secondary": secondary, "policy": policy, "budget": state.earned_talent_points, "ranks": model.rank_map(), "gear": gear, "gold": state.gold, "acquisition_seed": int(config.acquisition_seed), "ledger_end": ledger.size(), "conditional_victories": true, "unlocked_skills": a.skills.map(func(skill): return skill.id)})

func reward(secondary: String, policy: String, label: String) -> void:
	var before: int = state.gold
	state.finish_fight(true) # Conditional acquisition only; never counted as a combat win.
	require(state.claim_current_reward(), "Claim real reward")
	ledger.append({"action": "conditional_reward", "label": label, "gold_before": before, "gold_after": state.gold, "points": state.earned_talent_points, "choices": SaveSystem._gear_list_to_data(state.pending_reward_choices)})
	set_model(secondary)
	equip_best_inventory()
	var best: GearItem = null
	var best_score := gear_score(state.equipped_gear(), state.gold)
	for item in state.pending_reward_choices:
		if item.is_unidentified: continue
		var score := replacement_score(item, state.gold)
		if score > best_score:
			best = item
			best_score = score
			if policy == "weak": break
	if best != null:
		require(state.choose_pending_reward_gear(best), "Obtain offered loot")
		ledger.append({"action": "choose_loot", "item": SaveSystem._gear_entry_to_data(best)})
		equip_best_inventory()
	elif state.has_pending_reward_choice(): state.skip_pending_reward_gear()
	if state.should_open_shop_after_current_reward():
		require(state.open_shop_round(), "Open eligible shop")
		ledger.append({"action": "shop_offers", "label": label, "gold": state.gold, "offers": SaveSystem._gear_list_to_data(state.shop_offers)})
		if label in ["C9", "C10"]: capture(label + "_pre_shop", secondary, policy)
		var cap := 0 if policy == "weak" else 1 if policy == "typical" else 6
		for purchase in cap:
			best = null
			best_score = gear_score(state.equipped_gear(), state.gold)
			for item in state.shop_offers:
				if item.is_unidentified: continue
				var price: int = state.shop_purchase_price_for(item)
				if price > state.gold: continue
				var score := replacement_score(item, state.gold - price)
				if score > best_score:
					best = item
					best_score = score
			if best == null: break
			var price: int = state.shop_purchase_price_for(best)
			before = state.gold
			require(state.buy_shop_offer(best), "Affordable real purchase")
			require(state.gold == before - price and state.gold >= 0, "Purchase accounting")
			ledger.append({"action": "buy", "item": SaveSystem._gear_entry_to_data(best), "price": price, "gold_before": before, "gold_after": state.gold})
			equip_best_inventory()
		if label in ["C9", "C10"]: capture(label + "_post_shop", secondary, policy)
		require(state.close_shop_round(), "Close shop")
	require(state.continue_after_win(), "Continue conditional progression")

func acquire(secondary: String, policy: String) -> void:
	state.reset()
	SaveSystem.session_only = true
	state.set_adventure_seed(int(config.acquisition_seed))
	state.set_class(registry.classes["class.rogue"])
	ledger.append({"action": "trajectory_start", "primary": main_name, "secondary": secondary, "policy": policy, "seed": int(config.acquisition_seed)})
	for index in range(4):
		set_model("")
		capture("T" + str(index), secondary, policy)
		reward("", policy, "T" + str(index))
	for stage in range(1, 21):
		require(state.completed_contract_count == stage - 1, "Incoming contract")
		require(state.earned_talent_points == mini(45, 6 + 3 * (stage - 1)), "Live incoming budget")
		require(state.accept_contract_offer(), "Accept first legal offer")
		set_model(secondary)
		if stage in config.contract_checkpoints: capture("C" + str(stage), secondary, policy)
		var done := false
		while not done:
			var choices: Array = state.current_route_node.next_nodes
			require(not choices.is_empty(), "Next route node")
			require(state.choose_contract_route_node(choices[0]), "Choose first connected node")
			done = state.current_route_node.next_nodes.is_empty()
			reward(secondary, policy, "C" + str(stage) if done else "C%d/%s" % [stage, state.current_route_node.id])

func gather(node: ContractRouteNode, seen: Dictionary, nodes: Array) -> void:
	if node == null or seen.has(node.id): return
	seen[node.id] = true
	nodes.append(node)
	for child in node.next_nodes: gather(child, seen, nodes)

func all_paths(node: ContractRouteNode) -> Array:
	if node.next_nodes.is_empty(): return [[node.id]]
	var found := []
	for child in node.next_nodes:
		for path in all_paths(child): found.append([node.id] + path)
	return found

func build_encounters() -> void:
	var templates := {}
	for seed in range(85001, 85201):
		var settings := Gen.DEFAULT_SETTINGS.duplicate(true)
		var template: Dictionary = Gen._select_template(seed, settings)
		if not templates.has(template.id): templates[template.id] = seed
		if templates.size() == Gen.TEMPLATES.size(): break
	require(templates.size() == 6, "All route templates")
	var index := 0
	for template in templates:
		var stage: int = config.contract_checkpoints[index % config.contract_checkpoints.size()]
		add_route(stage, templates[template], true)
		index += 1
	for stage in config.contract_checkpoints: add_route(int(stage), 7001, false)
	for i in range(4):
		var encounter := RunFlow.load_encounter(i)
		encounters.append({"id": "T" + str(i), "checkpoint": "T" + str(i), "monster_path": RunFlow.ENCOUNTER_PATHS[i], "duration": encounter.duration_ms, "role": "TAVERN", "mandatory": true, "fight_key": "encounter:%d" % i})
	encounters.append({"id": "watchmen", "checkpoint": "C1", "monster_path": "res://data/monsters/cloaked_watchmen.tres", "duration": 26000, "role": "WATCHMEN", "mandatory": false, "fight_key": "watchmen"})
	SaveSystem.write_json(path_for("encounters"), {"templates": templates, "encounters": encounters})

func add_route(stage: int, seed: int, template_extra: bool) -> void:
	var contract := Gen.generate(seed, {"route_difficulty": "medium", "completed_contract_count": stage - 1, "earned_talent_points": mini(45, 6 + 3 * (stage - 1))})
	require(Gen.validate(contract).is_empty(), "Generated graph valid")
	var nodes := []
	gather(contract.offer_node, {}, nodes)
	var paths := all_paths(contract.offer_node)
	var roles := {}
	for node: ContractRouteNode in nodes:
		if node.generated_encounter_payload.is_empty(): continue
		var role: String = ContractRouteNode.NodeType.keys()[node.node_type]
		if roles.has(role): continue
		roles[role] = true
		var mandatory := true
		for path in paths:
			if not path.has(node.id): mandatory = false
		var payload: Dictionary = node.generated_encounter_payload
		encounters.append({"id": "C%d_%d_%s" % [stage, seed, node.id], "checkpoint": "C" + str(stage), "role": role, "mandatory": mandatory, "template": contract.template_id, "template_extra": template_extra, "route_seed": seed, "node": node.id, "fight_key": node.id, "payload": payload, "duration": int(payload.duration_ms)})

func content_for(snapshot: Dictionary, family: int) -> Dictionary:
	var model := allocate(snapshot.primary, snapshot.secondary, int(snapshot.budget), family)
	var gear := SaveSystem._gear_list_from_data(snapshot.gear)
	var content := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"], model, gear, int(snapshot.gold))
	require(content.error == "", "Fixture resolves")
	content["model"] = model
	content["gear"] = gear
	return content

func legal_ids(raw: Array, content: Dictionary) -> Array:
	var ids := []
	for id in raw:
		for skill in content.skills:
			if skill.id == "skill." + id: ids.append(id)
	if ids.is_empty(): ids = ["stab"]
	return ids.slice(0, 10)

func rotation(ids: Array, content: Dictionary) -> Array[Skill]:
	var skills: Array[Skill] = []
	for id in ids:
		for skill in content.skills:
			if skill.id == "skill." + id: skills.append(skill)
	require(skills.size() == ids.size(), "No locked macro skills")
	return skills

func enemy_for(encounter: Dictionary) -> Monster:
	if encounter.has("payload"): return GeneratedMonsterDraft.from_dictionary(encounter.payload).to_monster()
	var resource = load(encounter.monster_path)
	return resource.monster if resource is Encounter else resource

func simulate(ids: Array, content: Dictionary, enemy: Monster, duration: int, seed: int):
	var result := CombatResolver.resolve(rotation(ids, content), content.stats, enemy, duration, seed)
	require(result.is_valid, "Valid resolver output")
	return result

func candidates(reasonable: Array, content: Dictionary) -> Array:
	var found := [reasonable]
	for entry in protocol.cases:
		if entry.tree != main_name: continue
		for duration in ["30", "120"]:
			var ids := legal_ids(entry.reference_optimized_rotations[duration], content)
			if not found.has(ids): found.append(ids)
	for raw in [["stab", "heavy_slash"], ["blinding_powder", "stab", "heavy_slash"], ["rending_slash", "quick_cut", "leaping_plunge"], ["beguiling_strike", "stab", "heavy_slash"], ["virulent_poison", "poison_strike", "poison_strike"], ["pick_pocket", "steal", "mug", "big_score"]]:
		var ids := legal_ids(raw, content)
		if not found.has(ids): found.append(ids)
	return found

func evaluate(snapshot: Dictionary, encounter: Dictionary, family: int = 35) -> void:
	var content := content_for(snapshot, family)
	var enemy := enemy_for(encounter)
	var reasonable := legal_ids(config.reasonable_macros[main_name], content)
	var winner := reasonable
	var best := -1.0
	var search := []
	for ids in candidates(reasonable, content):
		var total := 0.0
		for seed in config.search_seeds: total += simulate(ids, content, enemy, int(encounter.duration), int(seed)).total_damage
		search.append({"macro": ids, "mean_damage": total / config.search_seeds.size()})
		if total > best:
			best = total
			winner = ids
	var case_id := "%s_%s_%d" % [snapshot.id, encounter.id, family]
	# Freeze selected macro before validation. Save exact search inputs/results in final case.
	var measurements := []
	for kind in ["reasonable", "searched"]:
		var ids: Array = reasonable if kind == "reasonable" else winner
		var damage := []
		var wins := 0
		var retry_wins := 0
		for cohort_seed in config.validation_roots:
			var first_seed := RunRng.seed_for_context(int(cohort_seed), RunRng.CONTEXT_COMBAT, [encounter.fight_key, 0])
			var retry_seed := RunRng.seed_for_context(int(cohort_seed), RunRng.CONTEXT_COMBAT, [encounter.fight_key, 1])
			var first = simulate(ids, content, enemy, int(encounter.duration), first_seed)
			var won: bool = first.is_win
			wins += int(won)
			damage.append(first.total_damage)
			var retry_damage := -1.0
			if not won:
				var retry_content := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"], content.model, content.gear, int(snapshot.gold) + first.gold_stolen)
				require(retry_content.error == "", "Retry stash resolution")
				var retry = simulate(winner, retry_content, enemy, int(encounter.duration), retry_seed)
				retry_damage = retry.total_damage
				won = retry.is_win
			# Macro-only retry: same ranks/gear, retained theft, no free respec.
			retry_wins += int(won)
			raw_samples.append({"case": case_id, "kind": kind, "root_seed": cohort_seed, "first_seed": first_seed, "retry_seed": retry_seed, "first_damage": first.total_damage, "first_win": first.is_win, "retained_theft": first.gold_stolen, "casts": first.cast_events.size(), "poison_ticks": first.tick_events.size(), "trigger_candidates": first.trigger_candidates_evaluated, "retry_damage": retry_damage, "within_two": won})
		measurements.append({"kind": kind, "macro": ids, "wins": wins, "within_two": retry_wins, "count": config.validation_roots.size(), "damage": Lab._distribution(damage), "mean_margin": Lab._distribution(damage).mean / enemy.hp - 1.0})
	var replay = simulate(winner, content, enemy, int(encounter.duration), 101)
	var repeat_result = simulate(winner, content, enemy, int(encounter.duration), 101)
	require(replay.total_damage == repeat_result.total_damage and replay.cast_events.size() == repeat_result.cast_events.size() and replay.rng_final_state == repeat_result.rng_final_state, "Deterministic replay")
	var practice := TrainingRoomState.new()
	practice.content_registry = registry
	practice.selected_class = registry.classes["class.rogue"]
	practice.ranked_build = content.model
	practice.selected_trees = content.model.trees()
	practice.earned_talent_points = int(snapshot.budget)
	for slot in ["equipped_weapon", "equipped_helm", "equipped_armor", "equipped_trinket", "equipped_charm"]: practice.set(slot, null)
	for item in content.gear:
		practice.set(["equipped_weapon", "equipped_helm", "equipped_armor", "equipped_trinket", "equipped_charm"][item.slot], item)
	practice.selected_target = enemy
	practice.set_practice_gold(int(snapshot.gold))
	practice.set_rotation(rotation(winner, content))
	practice.set_duration_ms(int(encounter.duration))
	practice.set_random_fight_seed_enabled(false)
	practice.set_fight_seed(101)
	practice.set_locked(true)
	practice.run_fight()
	require(practice.last_result != null and practice.last_result.total_damage == replay.total_damage, "Practice/native parity")
	results.append({"id": case_id, "snapshot": snapshot.id, "checkpoint": snapshot.checkpoint, "primary": main_name, "secondary": snapshot.secondary, "policy": snapshot.policy, "budget": snapshot.budget, "family": family, "ranks": content.model.rank_map(), "encounter": encounter.id, "role": encounter.role, "mandatory": encounter.mandatory, "duration_ms": encounter.duration, "hp": enemy.hp, "search": search, "selected": winner, "measurements": measurements, "replay_pass": true, "practice_parity": true})

func matrix() -> void:
	var primary_index: int = config.trees.find(main_name)
	var representative: String = config.trees[(primary_index + 1) % 4]
	for snapshot in snapshots:
		var main_trajectory: bool = snapshot.trajectory_secondary == representative
		if "shop" in snapshot.checkpoint:
			if main_trajectory:
				var next_checkpoint := "C10" if snapshot.checkpoint.begins_with("C9_") else "C11"
				for encounter in encounters:
					if encounter.checkpoint == next_checkpoint and encounter.role in ["FIGHT", "BOSS"] and not encounter.get("template_extra", false): evaluate(snapshot, encounter)
			continue
		for encounter in encounters:
			if encounter.checkpoint != snapshot.checkpoint: continue
			if main_trajectory:
				if encounter.get("template_extra", false) and snapshot.policy != "typical": continue
				evaluate(snapshot, encounter)
			elif snapshot.checkpoint == "C10" and encounter.role in ["FIGHT", "BOSS"] and not encounter.get("template_extra", false):
				evaluate(snapshot, encounter)
			if snapshot.checkpoint == "C10" and snapshot.policy == "typical" and encounter.role in ["FIGHT", "BOSS"] and not encounter.get("template_extra", false):
				for family in [33, 24]: evaluate(snapshot, encounter, family)
		print("Scored ", snapshot.id, " cases=", results.size())
		SaveSystem.write_json(path_for("matrix"), {"complete": false, "results": results, "samples": raw_samples, "checks": checks})
	require(results.size() > 100, "Contract matrix coverage")
	SaveSystem.write_json(path_for("matrix"), {"complete": true, "results": results, "samples": raw_samples, "checks": checks})
