extends SceneTree
## Synthetic owned-gear stress case, not an earned-run balance measurement.
func _initialize() -> void:
	call_deferred("_run")

func _gear(id: String, values: Array, slot: int, tier: int) -> GearItem:
	var item := GearItem.new()
	item.id = "t3.economy." + id
	item.slot = slot
	item.tier = tier
	item.source_kind = GearItem.SourceKind.GENERATED
	for value in values:
		var modifier := StatModifier.new()
		modifier.stat_id = id
		modifier.value = value
		item.affixes.append(modifier)
	return item

func _run() -> void:
	var state = root.get_node("BuildState")
	state.reset()
	state.set_class(load("res://data/classes/rogue.tres"))
	state.equipped_armor = _gear("inventory_economy_stats", [1.0], GearItem.SlotType.ARMOR, GearItem.Tier.UNIQUE)
	state.gold = 100
	state.shop_round_pending = true
	var discount := _gear("shop_discount", [.81, .81], GearItem.SlotType.WEAPON, GearItem.Tier.CHAOS)
	state.shop_offers.assign([discount])
	var base := GearGenerator.price_for_tier(discount.tier)
	assert(state.shop_purchase_price_for(discount) == base, "An unowned discount offer cannot discount itself.")
	assert(state.buy_shop_offer(discount))
	assert(state.gold == 100 - base and is_equal_approx(state.current_shop_discount(), 1.62))
	var before: int = state.gold
	var legendary := load("res://data/gear/bandit_blade.tres") as GearItem
	assert(legendary.tier == GearItem.Tier.LEGENDARY)
	state.shop_offers.assign([legendary])
	assert(state.shop_purchase_price_for(legendary) == 1)
	assert(state.buy_shop_offer(legendary))
	assert(state.sell_inventory_item(legendary))
	var profit: int = state.gold - before
	assert(profit == state.sell_value_for(legendary) - 1 and profit > 0)
	var gold_before_reroll: int = state.gold
	var reroll_cost: int = state.shop_reroll_cost
	assert(state.reroll_shop_offers())
	assert(state.gold == gold_before_reroll - reroll_cost)
	assert(state.shop_reroll_cost > reroll_cost)
	var snapshots: Array = []
	for offer in state.shop_offers:
		snapshots.append(SaveSystem._gear_entry_to_data(offer))
	assert(state.sell_inventory_item(discount))
	assert(state.current_shop_discount() == 0.0)
	for i in state.shop_offers.size():
		assert(SaveSystem._gear_entry_to_data(state.shop_offers[i]) == snapshots[i], "Removing gear must not reroll pending offers.")
	# Capacity rejection must neither charge gold nor transfer ownership.
	while state.inventory.size() < 3:
		assert(state.add_inventory_item(_gear("increased_gold", [.10], GearItem.SlotType.TRINKET, GearItem.Tier.BASIC)))
	var unowned := _gear("shop_discount", [.20], GearItem.SlotType.WEAPON, GearItem.Tier.UNIQUE)
	state.shop_offers.assign([unowned])
	before = state.gold
	assert(not state.buy_shop_offer(unowned))
	assert(state.gold == before and state.shop_offers.has(unowned))
	assert(SaveSystem.write_json("res://reports/economy_trajectory.json", {
		"scenario": "Synthetic carried Chaos discount; one purchase/resale and paid reroll",
		"discount": 1.62, "legendary_purchase": 1, "legendary_sale": state.sell_value_for(legendary),
		"purchase_sale_profit": profit, "reroll_paid": reroll_cost, "next_reroll_cost": state.shop_reroll_cost,
		"finding": "Individual resale profit reproduced; escalating reroll costs and finite offers prevent claiming an unbounded loop from this witness.",
		"unchanged_policy": "No price, resale, discount or talent coefficient nerfs. Balance review belongs to T10."
	}))
	state.reset()
	print("T3 economy trajectory: PASS")
	quit()
