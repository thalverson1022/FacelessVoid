extends "res://tests/t8_acquisition_test.gd"
## Combined legal seven-slot ownership/economy, with retained transaction helpers.
var serial := 0
var evidence := {}

func _run() -> void:
	var s = root.get_node("BuildState")
	ck(LegendaryCatalog.all_items().size() == 20, "final catalog twenty")
	_test_all_item_transactions(s)
	_test_coin_unlock_and_stale_offers(s)
	_test_fixed_reward_atomicity(s)
	_test_explicit_choice_identity_filter(s)
	_check_full_seven_economy(s)
	s.reset()
	SaveSystem.write_json(SaveSystem.save_path.get_base_dir().path_join("ownership_evidence.json"), evidence)
	print("M9 T9 ownership/economy PASS (%d checks)" % checks.size())
	quit()

func legal_item(slot: int, tier: int, ids: Array, categories: Array, negative: Array = []) -> GearItem:
	serial += 1
	var rng := RandomNumberGenerator.new()
	rng.seed = 9100 + serial
	var rolls := []
	for i in ids.size():
		rolls.append({"category":categories[i], "forced_stat_id":ids[i], "is_drawback":i in negative})
	var result := GearGenerator._affixes_for_rolls(slot,tier,rolls,rng,1.0,12)
	ck(result.errors.is_empty(), "legal slot/category and canonical uniqueness")
	ck(result.affixes.size() == (5 if tier == GearItem.Tier.UNIQUE else 4), "complete ordinary rarity shape")
	for i in ids.size():
		var modifier: StatModifier = result.affixes[i]
		ck(modifier.stat_id == ids[i], "requested legal pool identity")
		if categories[i] != "special":
			var maximum := GearGenerator.max_rolled_value_for_stat_id(ids[i],slot,i in negative,tier,1.0,12,categories[i])
			ck(maximum.ok, "attainable rounded endpoint")
			modifier.value = maximum.value
		ck(StatCatalog.modifier_validation_error(modifier) == "", "valid affix domain")
	var request := GearGenerator._normalized_generation_request({"slot":slot,"tier":tier,"rng":rng,"id":"m9.t9.legal.%d" % serial,"contract_depth":12,"value_scale":1.0,"source_context":"m9_t9_legal_endpoints"})
	var item := GearGenerator._generate_item_unchecked(request,result.affixes)
	ck(SaveSystem.gear_payload_error(SaveSystem._gear_entry_to_data(item),true) == "", "valid generated envelope")
	return item

func unique_item(slot: int, ids: Array) -> GearItem:
	return legal_item(slot,GearItem.Tier.UNIQUE,ids,["basic","basic","basic","rare","special"])

func raw_total(items: Array, id: String) -> float:
	var total := 0.0
	for item: GearItem in items:
		for modifier: StatModifier in item.affixes:
			if modifier.stat_id == id: total += modifier.value
	return total

func check_economy(s, label: String, active: bool = true) -> void:
	var equipped: Array = s.equipped_gear()
	var items: Array = equipped.duplicate()
	if active: items.append_array(s.inventory)
	var stats: PlayerStats = s.current_player_stats()
	ck(stats.derivation_error == "", label + " resolved")
	for pair in [["increased_gold",stats.gold_reward_multiplier-1.0],["shop_discount",stats.shop_discount],["increased_magic_find",stats.magic_find]]:
		var expected := maxf(0.0,raw_total(items,pair[0])) * 1.2
		ck(is_equal_approx(pair[1],expected), label + " raw signed occurrences -> floor -> All Stats once: " + pair[0])
	evidence[label] = {"equipped":equipped.size(),"carried":s.inventory.size(),"gold":stats.gold_reward_multiplier,"discount":stats.shop_discount,"magic_find":stats.magic_find}

func _check_full_seven_economy(s) -> void:
	s.reset()
	var registry := BuildContentRegistry.adventure()
	s.set_class(registry.classes["class.rogue"])
	ck(s.configure_ranked_build(registry.trees["tree.bladedancer"]),"current ranked Adventure fixture")
	var gear: Array[GearItem] = [
		unique_item(0,["base_damage","percent_physical_damage","crit_damage","shop_discount","all_stats_increased"]),
		unique_item(3,["crit_chance","increased_attack_speed","base_elemental_damage","crit_applies_penetration","ignore_armor_no_shred"]),
		unique_item(4,["percent_physical_damage","crit_chance","percent_elemental_damage","increased_buff_duration","all_stats_increased"]),
		unique_item(1,["base_damage","crit_chance","increased_attack_speed","crit_applies_potency","disable_enemy_block"]),
		unique_item(2,["crit_chance","increased_attack_speed","base_elemental_damage","cooldown_reduction","disable_enemy_absorb"]),
		unique_item(5,["percent_physical_damage","crit_damage","increased_magic_find","increased_gold","inventory_economy_stats"]),
		unique_item(6,["base_damage","crit_chance","base_elemental_damage","increased_buff_duration","convert_damage_to_magical"])
	]
	for item in gear: s.equip(item)
	ck(s.equipped_gear().size() == 7,"full legal seven-slot loadout")
	s.inventory.clear() # Remove the displaced starter from this three-carried fixture.
	var positive := legal_item(0,GearItem.Tier.CHAOS,["increased_gold","shop_discount","increased_magic_find","base_damage"],["rare","rare","rare","basic"])
	var negative_mf := legal_item(6,GearItem.Tier.CHAOS,["increased_magic_find","increased_magic_find","increased_magic_find","increased_magic_find"],["basic","basic","basic","basic"],[0,1,2,3])
	ck(s.add_inventory_item(positive) and s.add_inventory_item(positive) and s.add_inventory_item(negative_mf),"three legal carried occurrences including duplicate ordinary pointer")
	check_economy(s,"full_seven_signed_occurrences")
	var stats: PlayerStats = s.current_player_stats()
	var eq_only := BuildResolver.resolve_ranked_build(s.selected_class,s.ranked_build,s.equipped_gear(),s.gold,[]).stats as PlayerStats
	ck(stats.bonus_physical_damage == eq_only.bonus_physical_damage,"carried physical base never imports")
	ck(is_equal_approx(stats.cooldown_factor,eq_only.cooldown_factor),"carried timers never import")
	ck(stats.magic_find == 0.0 and stats.shop_discount > 1.0,"legal negative MF floors and uncapped positive discount")
	var offer := _ordinary(GearItem.SlotType.HANDS,"seven.offer")
	s.shop_round_pending = true
	s.shop_offers.assign([offer])
	var reward := EncounterReward.new()
	reward.generated_gear_choice_count = 3
	reward.generated_gear_tier = GearItem.Tier.CURSED
	s.pending_reward_choices.assign(s._gear_choices_for_reward(reward))
	var pending := JSON.stringify(SaveSystem._gear_list_to_data(s.pending_reward_choices))
	var offers := JSON.stringify(SaveSystem._gear_list_to_data(s.shop_offers))
	var before: PlayerStats = s.current_player_stats()
	ck(SaveSystem.save_run(s),SaveSystem.last_error)
	s.reset()
	ck(SaveSystem.load_run_result(s).status == "loaded","full seven + duplicate carried round trip")
	ck(s.inventory[0] != s.inventory[1],"decoded occurrences detached despite equal saved ID")
	check_economy(s,"loaded_occurrences")
	ck(is_equal_approx(s.current_player_stats().shop_discount,before.shop_discount),"load preserves aggregate without double amplification")
	ck(JSON.stringify(SaveSystem._gear_list_to_data(s.pending_reward_choices)) == pending,"pending reward values/MF provenance frozen")
	ck(JSON.stringify(SaveSystem._gear_list_to_data(s.shop_offers)) == offers,"shop values/provenance frozen")
	ck(s.equip_from_inventory(s.inventory[0]) and s.inventory.size() == 3,"one carried occurrence equips and displaced gear remains owned")
	check_economy(s,"after_occurrence_swap")
	ck(s.sell_inventory_item(s.inventory[0]),"one carried occurrence sold")
	check_economy(s,"after_occurrence_sale")
	ck(JSON.stringify(SaveSystem._gear_list_to_data(s.pending_reward_choices)) == pending and JSON.stringify(SaveSystem._gear_list_to_data(s.shop_offers)) == offers,"ownership changes never reroll pending snapshots")
	# A purchase uses the pre-purchase aggregate; inventory cap rejection is atomic.
	var loaded_offer: GearItem = s.shop_offers[0]
	var price: int = s.shop_purchase_price_for(loaded_offer)
	var gold: int = s.gold
	ck(s.buy_shop_offer(loaded_offer) and s.gold == gold-price,"pre-purchase discounted charge exactly once")
	var second := _ordinary(5,"blocked.offer")
	s.shop_offers.assign([second])
	gold = s.gold
	ck(not s.buy_shop_offer(second) and s.gold == gold and s.shop_offers.has(second),"full carried storage rejects purchase atomically")
	# Independent legal negative-gold witness, with no carried positive gold.
	s.inventory.clear()
	s.equip(gear[0])
	s.inventory.clear()
	var negative_gold := legal_item(5,GearItem.Tier.CHAOS,["increased_gold","increased_gold","increased_gold","increased_gold"],["basic","basic","basic","basic"],[0,1,2,3])
	s.add_inventory_item(negative_gold)
	s.add_inventory_item(negative_mf)
	check_economy(s,"legal_negative_gold_and_mf")
	ck(s.current_player_stats().gold_reward_multiplier == 1.0 and s.current_player_stats().magic_find == 0.0,"negative aggregate floors before one All Stats factor")
	s.unequip(GearItem.SlotType.LEGS)
	check_economy(s,"carried_activator_cannot_self_activate",false)
	ck(not s.current_player_stats().special_effects.get("inventory_economy_stats",false),"activator in inventory stays inactive")
	# Known profitability is retained policy, not a tuning claim or earned-run pace.
	s.inventory.clear()
	s.equip(gear[5])
	s.inventory.clear()
	s.add_inventory_item(positive)
	s.add_inventory_item(positive)
	s.shop_offers.assign([load("res://data/gear/golden_greeves.tres")])
	s.shop_round_pending = true
	s.gold = 1000
	var greeves: GearItem = s.shop_offers[0]
	ck(s.shop_purchase_price_for(greeves) == 1,"legal high discount retains one-gold floor")
	gold = s.gold
	ck(s.buy_shop_offer(greeves) and s.sell_inventory_item(greeves),"actual buy/resale witness")
	ck(s.gold-gold == s.sell_value_for(greeves)-1 and s.gold > gold,"retained discount/resale profitability recorded for T10")
	evidence["retained_profit"] = {"legal_endpoint_fixture":true,"gold_delta":s.gold-gold,"buy_price":1,"resale":s.sell_value_for(greeves),"balance_tuning":false}
