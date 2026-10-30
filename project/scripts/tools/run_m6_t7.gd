extends "res://scripts/tools/run_m6_t6.gd"
## Victory-dependent economy investigation; never enables Adventure in the product.
const T7_OUT := "res://reports/p6_m6_t7/final"
var spend_policy := "typical"
var run_seed := 84001
var horizon := 20
var partner := ""
var events := []
var fights := []
var stage_label := ""
var t7_failed := false

func require(ok: bool,message: String) -> void:
	checks+=1
	if not ok:
		t7_failed=true
		push_error("T7 FAILED: "+message)

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tree="): main_name=arg.trim_prefix("--tree=")
		if arg.begins_with("--policy="): spend_policy=arg.trim_prefix("--policy=")
		if arg.begins_with("--seed="): run_seed=int(arg.trim_prefix("--seed="))
		if arg.begins_with("--horizon="): horizon=int(arg.trim_prefix("--horizon="))
		if arg.begins_with("--secondary="): partner=arg.trim_prefix("--secondary=")
	SaveSystem.session_only=true
	DirAccess.make_dir_recursive_absolute(T7_OUT)
	call_deferred("run")

func run() -> void:
	config=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/m6_tavern_1023_protocol.json"))
	protocol=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/subclass_protocol.json"))
	registry=BuildContentRegistry.test_mode()
	require(registry.error=="",registry.error)
	state=root.get_node("BuildState")
	state.reset()
	state.set_adventure_seed(run_seed)
	state.set_class(registry.classes["class.rogue"])
	require(state.configure_ranked_build(registry.trees["tree."+main_name]),"Ranked primary")
	if partner=="": partner=TREES[(TREES.find(main_name)+1)%4]
	var alive:=true
	for index in 4:
		stage_label="T"+str(index)
		spend_points(false)
		require(state.choose_current_tavern_encounter(),"Choose Tavern")
		if not actual_fight():
			alive=false
			break
		actual_reward()
	if alive:
		for stage in range(1,horizon+1):
			stage_label="C"+str(stage)
			require(state.earned_talent_points==mini(45,6+3*(stage-1)),"Earned budget")
			spend_points(true)
			require(state.accept_contract_offer(),"Accept offer")
			if state.needs_secondary_subclass_choice(): require(state.choose_secondary_tree(registry.trees["tree."+partner]),"Secondary")
			spend_points(false)
			var done:=false
			while not done:
				var choices: Array=state.current_route_node.next_nodes
				require(not choices.is_empty(),"Connected route")
				require(state.choose_contract_route_node(choices[0]),"First visible route choice")
				done=state.current_route_node.next_nodes.is_empty()
				if not actual_fight():
					alive=false
					break
				actual_reward()
			if not alive: break
	if t7_failed:
		quit(1)
		return
	var report:={"complete":true,"primary":main_name,"secondary":partner,"policy":spend_policy,"seed":run_seed,"horizon":horizon,"survived":alive,"completed_contracts":state.completed_contract_count,"last_stage":stage_label,"ending_gold":state.gold,"points":state.earned_talent_points,"events":events,"fights":fights,"checks":checks}
	SaveSystem.write_json(T7_OUT+"/%s_%s_%s_%d.json"%[main_name,partner,spend_policy,run_seed],report)
	print("T7 PASS ",main_name," ",spend_policy," ",run_seed," completed=",state.completed_contract_count," fights=",fights.size()," checks=",checks)
	state.reset()
	quit(0)

func spend_points(respec: bool) -> void:
	if respec: require(state.refund_all_talents(),"Respec at offer only")
	var desired: Dictionary={}
	if stage_label.begins_with("T"):
		var paths: Array=JSON.parse_string(FileAccess.get_file_as_string(DEST+"/tavern_paths.json")).paths
		for entry in paths:
			if entry.main==main_name: desired=entry.three_points if state.earned_talent_points>=3 else entry.one_point if state.earned_talent_points>=1 else {}
	else:
		var secondary: String=partner if state.ranked_build.secondary_tree()!=null else ""
		desired=allocate(main_name,secondary,state.earned_talent_points).rank_map()
		if main_name=="bladedancer" and state.earned_talent_points==6: desired={"talent.bladedancer.wet_stone":5,"talent.bladedancer.precision_attacks":1}
		if main_name=="thief" and state.earned_talent_points==6: desired={"talent.sticky_fingers":5,"talent.thief.fast_hands":1}
	for repeat in 45:
		for tree in state.ranked_build.trees():
			for talent in tree.talents:
				if state.ranked_build.rank_of(talent.id)<int(desired.get(talent.id,0)): state.select_talent(talent)
	require(state.ranked_build.points_spent()==state.earned_talent_points,"Spend legal earned points")

func account(action: String,before: int,extra: Dictionary={}) -> void:
	var event:={"action":action,"stage":stage_label,"before":before,"after":state.gold,"delta":state.gold-before}
	event.merge(extra)
	events.append(event)
	require(state.gold>=0,"Nonnegative balance")

func actual_fight() -> bool:
	for attempt in 100:
		var c:=BuildResolver.resolve_ranked_build(state.selected_class,state.ranked_build,state.equipped_gear(),state.gold)
		var enemy: Monster=state.current_target_monster()
		var duration: int=state.current_target_duration_ms()
		var pool:=candidates(legal_ids(config.reasonable_macros[main_name],c),c)
		for skill in c.skills:
			if skill.id!="skill.hold":
				var ids: Array=[skill.id.trim_prefix("skill.")]
				if not pool.has(ids): pool.append(ids)
		for raw in [["rending_thrust","quick_cut"],["mug","steal","pick_pocket"],["mug","pick_pocket","steal"],["steal","mug","pick_pocket"],["steal","pick_pocket","mug"],["pick_pocket","mug","steal"],["pick_pocket","steal","mug"]]:
			var ids:=legal_ids(raw,c)
			if not pool.has(ids): pool.append(ids)
		var best: Array=pool[0]
		var score:=-1.0
		for ids in pool:
			var damage:=0.0
			for seed in [1101,1102]: damage+=simulate(ids,c,enemy,duration,seed).total_damage
			if damage>score:
				score=damage
				best=ids
		state.set_rotation(rotation(best,c))
		state.set_locked(true)
		var gold_before: int=state.gold
		var combat_seed: int=state.current_combat_rng_seed()
		require(state.start_fight(),"Start legal fight")
		var result=simulate(best,c,enemy,duration,combat_seed)
		var zero_gold:=BuildResolver.resolve_ranked_build(state.selected_class,state.ranked_build,state.equipped_gear(),0)
		var zero_result=simulate(best,zero_gold,enemy,duration,combat_seed)
		state.record_combat_stolen_gold(result.gold_stolen)
		account("theft",gold_before,{"amount":result.gold_stolen,"win":result.is_win})
		state.record_fight_result(result,enemy)
		state.finish_fight(result.is_win)
		fights.append({"stage":stage_label,"key":state._current_fight_key(),"attempt":attempt,"seed":combat_seed,"duration":duration,"gold":gold_before,"gear":SaveSystem._gear_list_to_data(state.equipped_gear()),"ranks":state.ranked_build.rank_map(),"points":state.earned_talent_points,"macro":best,"enemy":stat_record(enemy),"damage":result.total_damage,"zero_bank_damage":zero_result.total_damage,"crit_chance":c.stats.crit_chance,"zero_bank_crit":zero_gold.stats.crit_chance,"win":result.is_win,"theft":result.gold_stolen,"overkill":result.overkill_damage,"raw_overkill_gold":state.overkill_gold_for_result(result)})
		if result.is_win: return true
		require(state.gold==gold_before+result.gold_stolen,"Loss retains theft only")
		if not state.can_retry_current_encounter(): return false
		require(state.retry_current_encounter(),"Legal retry")
	require(false,"Technical retry cap; must not classify as game failure")
	return false

func tidy() -> void:
	for item in state.inventory.duplicate():
		if replacement_score(item,state.gold)>gear_score(state.equipped_gear(),state.gold):
			var before: int=state.gold
			require(state.equip_from_inventory(item),"Equip owned gear")
			account("equip",before,{"item":SaveSystem._gear_entry_to_data(item)})
	for item in state.inventory.duplicate():
		var before: int=state.gold
		var price: int=state.sell_value_for(item)
		require(state.sell_inventory_item(item),"Sell owned gear")
		require(state.gold==before+price,"Sale accounting")
		account("sale",before,{"price":price,"item":SaveSystem._gear_entry_to_data(item)})

func actual_reward() -> void:
	var before: int=state.gold
	var expected: int=state.current_modified_reward_gold()
	var raw: int=state.overkill_gold_for_result(state.last_combat_result)
	var base: int=state.current_reward().gold_amount
	require(state.claim_current_reward(),"Victory reward")
	require(state.gold==before+expected,"Reward accounting")
	require(not state.claim_current_reward(),"No duplicate reward")
	account("reward",before,{"base":base,"overkill":raw,"amount":expected,"points":state.earned_talent_points})
	tidy()
	var best: GearItem=null
	var score:=gear_score(state.equipped_gear(),state.gold)
	for item in state.pending_reward_choices:
		if item.is_unidentified: continue
		var value:=replacement_score(item,state.gold)
		if value>score:
			best=item
			score=value
	if best!=null:
		require(state.choose_pending_reward_gear(best),"Choose offered loot")
		tidy()
	elif state.has_pending_reward_choice(): state.skip_pending_reward_gear()
	if state.should_open_shop_after_current_reward():
		require(state.open_shop_round(),"Open shop")
		var cap:=0 if spend_policy=="weak" else 1 if spend_policy=="typical" else 6
		var rerolled:=false
		for purchase in cap:
			best=null
			score=gear_score(state.equipped_gear(),state.gold)
			var offers:=[]
			for item in state.shop_offers:
				var price: int=state.shop_purchase_price_for(item)
				var value:=replacement_score(item,state.gold-price) if not item.is_unidentified and price<=state.gold else -1.0
				offers.append({"item":SaveSystem._gear_entry_to_data(item),"price":price,"affordable":price<=state.gold,"score":value})
				if value>score:
					best=item
					score=value
			account("offers",state.gold,{"offers":offers})
			if best==null:
				if spend_policy=="strong" and not rerolled and state.gold>=state.shop_reroll_cost+18:
					before=state.gold
					var cost: int=state.shop_reroll_cost
					require(state.reroll_shop_offers(),"Affordable reroll")
					require(state.gold==before-cost,"Reroll accounting")
					account("reroll",before,{"price":cost})
					rerolled=true
					continue
				break
			before=state.gold
			var price: int=state.shop_purchase_price_for(best)
			require(state.buy_shop_offer(best),"Affordable purchase")
			require(state.gold==before-price,"Purchase accounting")
			account("buy",before,{"price":price,"item":SaveSystem._gear_entry_to_data(best)})
			tidy()
		require(state.close_shop_round(),"Close shop")
	require(state.continue_after_win(),"Continue real victory")

