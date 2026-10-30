extends "res://tests/t8_acquisition_test.gd"
## Deliberately assembled legal diagnostic gear; NOT an earned-run frequency sample.

func _run() -> void:
	var s = root.get_node("BuildState")
	s.reset()
	s.set_class(load("res://data/classes/rogue.tres"))
	var registry := BuildContentRegistry.adventure()
	ck(s.configure_ranked_build(registry.trees["tree.bladedancer"]), "ranked diagnostic")
	var epic := find_discount(GearItem.Tier.EPIC, 0.20, 512)
	var chaos := find_discount(GearItem.Tier.CHAOS, 0.51, 4096)
	var greeves: GearItem = load("res://data/gear/golden_greeves.tres")
	s.equip(greeves)
	s.inventory.clear()
	var control := transaction(s, "greeves_only")
	ck(control.discount < 0.5 and control.profit <= 0, "40 percent alone not profitable")
	s.equip(epic)
	s.inventory.clear()
	var combined := transaction(s, "greeves_plus_generated_epic")
	ck(combined.discount >= 0.6 and combined.profit > 0, "two legal items permit profit")
	s.unequip(GearItem.SlotType.LEGS)
	s.inventory.clear()
	s.equip(chaos)
	s.inventory.clear()
	var old_slots := transaction(s, "generated_chaos_weapon_only")
	ck(old_slots.discount > 0.5 and old_slots.profit > 0, "old slot avenue also profitable")
	var report := {"diagnostic_not_earned":true, "generated_epic":_item_witness(epic),
		"generated_chaos":_item_witness(chaos), "transactions":[control,combined,old_slots],
		"checks":checks, "count":checks.size()}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/m9_t10_risk"))
	var f := FileAccess.open("res://reports/m9_t10_risk/evidence.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"\t"))
	print("PASS T10 risk review: ", checks.size())
	quit()

func find_discount(tier: GearItem.Tier, minimum: float, limit: int) -> GearItem:
	for seed_value in range(1,limit+1):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var item := GearGenerator.generate(tier,GearItem.SlotType.WEAPON,rng,"m9.t10.diagnostic.%d.%d" % [tier,seed_value])
		var discount := 0.0
		for affix: StatModifier in item.affixes:
			if affix.stat_id == "shop_discount": discount += affix.value
		if discount >= minimum:
			ck(SaveSystem.gear_payload_error(SaveSystem._gear_entry_to_data(item),true) == "", "generated legal envelope")
			return item
	ck(false,"bounded diagnostic found discount witness")
	return null

func transaction(s, label: String) -> Dictionary:
	s.gold = 100
	s.shop_round_pending = true
	s.shop_reroll_count = 0
	s.shop_reroll_cost = 5
	var item := _ordinary(GearItem.SlotType.ARMOR,"m9.t10."+label)
	s.shop_offers.assign([item])
	var price: int = s.shop_purchase_price_for(item)
	var resale: int = s.sell_value_for(item)
	var discount: float = s.current_player_stats().shop_discount
	ck(s.buy_shop_offer(item),"buy diagnostic offer")
	ck(not s.shop_offers.has(item) and not s.buy_shop_offer(item),"offer consumed once")
	ck(s.sell_inventory_item(item),"resell once")
	ck(not s.sell_inventory_item(item),"cannot sell absent occurrence twice")
	ck(s.gold == 100-price+resale,"actual gold reconciles")
	return {"label":label,"discount":discount,"buy":price,"resale":resale,"profit":s.gold-100,
		"initial_reroll_cost":s.shop_reroll_cost,"offers_remaining":s.shop_offers.size()}

