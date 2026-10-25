extends SceneTree
const Full = preload("res://tests/p6_full_thief_test.gd")
var failed := false
var checks := 0
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:
		failed=true
		printerr("FAILED: "+label)
func signatures(state, items: Array[GearItem]) -> Array:
	var result := []
	for item in items: result.append(state._shop_offer_signature(item))
	return result
func _run() -> void:
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._on_contract_test_pressed(7,45)
	await process_frame
	var state = root.get_node("BuildState")
	check(state.accept_contract_offer(),"Actual contract access")
	var thief: SubclassTree = state.selected_class.trees.filter(func(t):return t.id=="tree.thief")[0]
	check(state.choose_secondary_tree(thief),"Supported Thief secondary choice")
	for pair in Full.PURCHASES:
		for i in pair[1]: check(state.select_talent(RankedBuild._talent(thief,pair[0])),"Actual Test Mode rank")
	check(state.ranked_build.points_spent()==35,"Complete Thief in Test Mode")
	# Controller harness: establish a shop round without fabricating combat wins.
	state.shop_round_pending=true
	state.gold=499
	var offer := GearItem.new()
	offer.id="gear.test.thief.offer"
	offer.slot=GearItem.SlotType.WEAPON
	offer.tier=GearItem.Tier.BASIC
	state.shop_offers.assign([offer])
	var price: int = state.shop_purchase_price_for(offer)
	check(price==floori(GearGenerator.price_for_tier(offer.tier)*.7),"Charisma three actual price flooring")
	state.gold=price-1
	check(not state.buy_shop_offer(offer) and state.shop_offers.has(offer),"Insufficient gold atomic")
	state.gold=499
	check(state.buy_shop_offer(offer) and state.gold==499-price and not state.shop_offers.has(offer),"Purchase debits exact discounted cost")
	var live := preload("res://scripts/systems/combat_gold.gd").crit_values(state.current_player_stats(),state.gold,0)
	check(is_equal_approx(live.gilded_crit_bonus,state.gold*.01),"Spending updates allocated Gilded")
	check(not state.buy_shop_offer(offer),"Cannot buy same offer twice")
	var gear := GearItem.new()
	gear.id="gear.test.thief.discount"
	gear.slot=GearItem.SlotType.CHARM
	var mod := StatModifier.new()
	mod.stat_id="shop_discount"
	mod.value=.2
	mod.category=StatModifier.StatCategory.BASIC
	gear.affixes.assign([mod])
	state.equipped_charm=gear
	check(state.shop_purchase_price_for(offer)==floori(GearGenerator.price_for_tier(offer.tier)*.5),"Charisma and gear add")
	mod.value=1.0
	check(state.shop_purchase_price_for(offer)==1,"Positive-price floor survives excessive discount")
	state.equipped_charm=null
	var reward := EncounterReward.new()
	reward.generated_gear_choice_count=3
	reward.generated_gear_tier=GearItem.Tier.BASIC
	var baseline := {}
	var changed_shop := false
	var mf_upgrades := false
	# Remove Loaded Dice only; other ranks remain legal and consumer inputs rebuild.
	for i in 3: check(state.deselect_talent(RankedBuild._talent(thief,"talent.thief.load_dice")),"Loaded Dice refund")
	for rank in range(4):
		if rank: check(state.select_talent(RankedBuild._talent(thief,"talent.thief.load_dice")),"Loaded Dice rebuy")
		check(is_equal_approx(state.current_magic_find(),float(rank)),"Live consumer sees allocated rank")
		check(state._scaled_reward_upgrade_chance_bp(1000,1,state.current_magic_find())==1000*(1+rank),"Exact depth-one chance scaling")
		for seed_value in range(1,31):
			state.adventure_seed=seed_value
			var offers: Array[GearItem] = state._generate_tavern_shop_offers(0,false)
			var again: Array[GearItem] = state._generate_tavern_shop_offers(0,false)
			check(signatures(state,offers)==signatures(state,again),"Actual shop generation reproducible")
			if rank==0: baseline[seed_value]=signatures(state,offers)
			else: changed_shop=changed_shop or signatures(state,offers)!=baseline[seed_value]
			var choices: Array[GearItem] = state._gear_choices_for_reward(reward)
			check(choices.size()==3 and signatures(state,choices)==signatures(state,state._gear_choices_for_reward(reward)),"Actual reward generation reproducible; no extra drops")
			for item in choices: mf_upgrades=mf_upgrades or item.reward_magic_find_upgraded
	check(changed_shop and mf_upgrades,"Allocated Loaded Dice changes real shop/reward quality outcomes")
	var preserved: Array[GearItem] = state._generate_tavern_shop_offers(0,false)
	state.shop_offers=preserved.duplicate()
	var before := signatures(state,state.shop_offers)
	for i in 3: state.deselect_talent(RankedBuild._talent(thief,"talent.thief.load_dice"))
	check(signatures(state,state.shop_offers)==before,"Refund does not reroll existing offers")
	for rank in range(3,-1,-1):
		check(state.shop_purchase_price_for(offer)==maxi(1,floori(GearGenerator.price_for_tier(offer.tier)*(1-.1*rank))),"Every Charisma rank updates live price")
		if rank: check(state.deselect_talent(RankedBuild._talent(thief,"talent.thief.charisma")),"Charisma refunds after prerequisite cleared")
	game.queue_free()
	await process_frame
	state.reset()
	print("Thief economy: %d checks %s" % [checks,"FAIL" if failed else "PASS"])
	quit(1 if failed else 0)
