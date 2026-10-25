extends SceneTree
## Read-only baseline probe. Fixed diagnostic builds are not full Adventure runs.
const OUT := "res://reports/p6_m6_t3"
const Gen = preload("res://scripts/systems/contract_route_generator/contract_route_generator.gd")
const Lab = preload("res://scripts/tools/balance_lab.gd")
const STAGES := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 15, 20, 25, 30, 31, 40, 60]
var registry: BuildContentRegistry
var protocol: Dictionary
var rows := []
var samples := []
var routes := []

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	SaveSystem.save_path = OUT + "/isolated_save.json"
	PracticeSaveSystem.save_path = OUT + "/isolated_practice.json"
	PracticeSaveSystem.core_save_path = OUT + "/isolated_core.json"
	call_deferred("run")

func nodes_from(node: ContractRouteNode, seen: Dictionary, result: Array) -> void:
	if node == null or seen.has(node.id): return
	seen[node.id] = true
	result.append(node)
	for child in node.next_nodes: nodes_from(child, seen, result)

func paths_from(node: ContractRouteNode, fights: int = 0, gold: int = 0, elites: int = 0) -> Array:
	if node.monster != null:
		fights += 1
		gold += node.reward.gold_amount if node.reward != null else 0
		if node.node_type == ContractRouteNode.NodeType.ELITE: elites += 1
	if node.next_nodes.is_empty(): return [{"fights": fights, "base_gold": gold, "elites": elites}]
	var paths := []
	for child in node.next_nodes: paths.append_array(paths_from(child, fights, gold, elites))
	return paths

func monster_data(monster: Monster) -> Dictionary:
	var data := {}
	for key in ["id", "display_name", "hp", "armor", "poison_resistance", "block", "absorb", "dodge_chance", "crit_negation", "cleanse_threshold", "suppress", "slow", "stun_duration_ms", "interrupt_skip_count"]:
		data[key] = monster.get(key)
	return data

func measure(monster: Monster, duration: int, context: Dictionary, points: int) -> void:
	for entry in protocol.cases:
		if int(entry.points) != points: continue
		var ranks: Dictionary = entry.talent_ranks.duplicate(true)
		if entry.full_tree:
			for talent in registry.trees["tree." + entry.tree].talents: ranks[talent.id] = talent.max_ranks
		for id in ranks: ranks[id] = int(ranks[id])
		var model := RankedBuild.new()
		assert(model.configure(registry.trees["tree." + entry.tree], null, points, ranks), model.last_error)
		for weapon in ["crude_dagger", "bandit_blade"]:
			var gear: Array[GearItem] = [load("res://data/gear/" + weapon + ".tres")]
			var content := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"], model, gear, 0)
			assert(content.error == "", str(content.error))
			var ids: Array = entry.reference_optimized_rotations["30"]
			var rotation: Array[Skill] = []
			for id in ids:
				for skill in content.skills:
					if skill.id == "skill." + id: rotation.append(skill)
			assert(rotation.size() == ids.size())
			var damage := []
			var wins := 0
			for seed in range(201, 221):
				var result := CombatResolver.resolve(rotation, content.stats, monster, duration, seed)
				assert(result.is_valid, "Invalid simulation")
				wins += int(result.is_win)
				damage.append(result.total_damage)
				samples.append({"case": rows.size(), "seed": seed, "damage": result.total_damage, "win": result.is_win})
			var distribution := Lab._distribution(damage)
			rows.append({"context": context, "tree": entry.tree, "fixture": entry.id, "points_spent": points, "weapon": weapon, "gold": 0, "ranks": ranks, "macro": ids, "duration_ms": duration, "monster": monster_data(monster), "wins": wins, "count": 20, "damage": distribution, "mean_margin": distribution.mean / monster.hp - 1.0})

func run() -> void:
	registry = BuildContentRegistry.test_mode()
	assert(registry.error == "")
	protocol = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/subclass_protocol.json"))
	var extras := []
	for entry in protocol.cases:
		if int(entry.points) != 1: continue
		var zero: Dictionary = entry.duplicate(true)
		zero.id = entry.tree + "_0_starter"
		zero.points = 0
		zero.talent_ranks = {}
		zero.reference_optimized_rotations = {"30": ["stab"]}
		extras.append(zero)
		var five: Dictionary = entry.duplicate(true)
		five.id = entry.tree + "_5_prefix"
		five.points = 5
		var model := RankedBuild.new()
		assert(model.configure(registry.trees["tree." + entry.tree], null, 5))
		for target in protocol.cases:
			if target.tree != entry.tree or int(target.points) != 10: continue
			for repeat in range(5):
				for id in target.talent_ranks:
					if model.rank_of(id) < int(target.talent_ranks[id]) and model.points_spent() < 5: model.buy(id)
		assert(model.points_spent() == 5)
		five.talent_ranks = model.rank_map()
		extras.append(five)
	protocol.cases.append_array(extras)
	var inventory := []
	var scaling := []
	for stage in STAGES:
		scaling.append({"contract": stage, "hp": Gen._contract_hp_multiplier_for_number(stage), "dps": Gen._contract_dps_multiplier_for_number(stage), "armor": Gen._contract_armor_multiplier_for_number(stage), "block": Gen._contract_block_multiplier_for_number(stage), "absorb": Gen._contract_absorb_multiplier_for_number(stage), "progression": Gen._progression_for("medium", stage - 1)})
		for seed in range(7001, 7006):
			var contract := Gen.generate(seed, {"route_difficulty": "medium", "completed_contract_count": stage - 1, "earned_talent_points": mini(45, 10 + (stage - 1) * 5)})
			assert(Gen.validate(contract).is_empty(), "Invalid route")
			var nodes := []
			nodes_from(contract.offer_node, {}, nodes)
			for node: ContractRouteNode in nodes:
				if not node.generated_encounter_payload.is_empty():
					var draft := GeneratedMonsterDraft.from_dictionary(node.generated_encounter_payload)
					assert(not draft.has_errors())
					node.monster = draft.to_monster()
					node.duration_ms = draft.duration_ms
			routes.append({"contract": stage, "seed": seed, "template": contract.template_id, "paths": paths_from(contract.offer_node)})
			var measured_roles := {}
			for node: ContractRouteNode in nodes:
				if node.monster == null: continue
				var role: String = ContractRouteNode.NodeType.keys()[node.node_type]
				var context := {"contract": stage, "route_seed": seed, "node": node.id, "role": role}
				inventory.append({"context": context, "duration_ms": node.duration_ms, "monster": monster_data(node.monster), "payload": node.generated_encounter_payload, "preview": node.debug_preview, "reward_gold": node.reward.gold_amount, "reward_points": node.reward.talent_points, "reward_gear_tier": node.reward.generated_gear_tier, "reward_gear_choices": node.reward.generated_gear_choice_count, "next": Array(node.outgoing_node_ids)})
				if seed == 7001 and stage in [1, 4, 6, 10, 11, 20, 31] and not measured_roles.has(role):
					measured_roles[role] = true
					measure(node.monster, node.duration_ms, context, 10 if stage == 1 else 21 if stage == 4 else 35)
		print("Audited C", stage)
		SaveSystem.write_json(OUT + "/probe.json", {"complete": false, "scaling": scaling, "routes": routes, "inventory": inventory, "measurements": rows, "samples": samples})
	var tavern := []
	for index in range(4):
		var encounter := RunFlow.load_encounter(index)
		tavern.append({"index": index, "duration_ms": encounter.duration_ms, "monster": monster_data(encounter.monster), "gold": encounter.reward.gold_amount, "points": encounter.reward.talent_points, "shop": encounter.reward.unlocks_shop})
		var budget: int = [0, 1, 1, 5][index]
		measure(encounter.monster, encounter.duration_ms, {"tavern": index, "incoming_budget": budget}, budget)
	measure(load("res://data/monsters/cloaked_watchmen.tres"), 26000, {"watchmen": "current_content_control"}, 10)
	var historical := {}
	for spec in Lab._scenario_specs():
		if spec.id == "bladedancer_contract_watchmen":
			spec.seed_count = 200
			historical = Lab.run_scenario_spec(spec)
	SaveSystem.write_json(OUT + "/watchmen_legacy.json", historical)
	var state = root.get_node("BuildState")
	SaveSystem.write_json(OUT + "/probe.json", {"complete": true, "scaling": scaling, "routes": routes, "inventory": inventory, "measurements": rows, "samples": samples, "tavern": tavern, "boss_catalog": state.generated_boss_catalog(), "shop_curve": state.CONTRACT_SHOP_RARITY_CURVE, "shop_prices": GearGenerator.PRICE_BY_TIER, "protocol_sha256": FileAccess.get_sha256("res://data/balance_lab/subclass_protocol.json")})
	assert(inventory.size() > 0 and rows.size() > 32, "Generated coverage missing")
	print("T3 audit complete: ", inventory.size(), " enemies, ", rows.size(), " diagnostic cases, ", samples.size(), " combat samples")
	quit(0)
