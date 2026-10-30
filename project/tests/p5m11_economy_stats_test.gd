extends SceneTree

const StatCatalog := preload("res://scripts/systems/stat_catalog.gd")

var build_state: Node


func _initialize() -> void:
	build_state = root.get_node("BuildState")
	print("-- P5M11 economy stats --")
	_check_replacement_economy_pools()
	_check_basic_and_rare_economy_ranges()
	_check_economy_stats_resolve_to_player_stats()
	_check_shop_discount_affects_purchase_price_only()
	_check_magic_find_scales_upgrade_chances()
	print("P5M11 economy stats check: OK")
	quit(0)


func _check_replacement_economy_pools() -> void:
	for slot in GearItem.universal_slot_order():
		for stat_id in [StatCatalog.SHOP_DISCOUNT, StatCatalog.INCREASED_MAGIC_FIND]:
			_require(not StatCatalog.is_stat_valid_for_slot(slot, StatCatalog.CATEGORY_BASIC, stat_id), "Expected %s absent from new Basic pool for %s." % [stat_id, GearGenerator.universal_slot_label(slot)])
			_require(StatCatalog.is_stat_valid_for_slot(slot, StatCatalog.CATEGORY_RARE, stat_id) == (slot == GearItem.SlotType.WEAPON), "Expected Rare %s only on Weapon." % stat_id)
		_require(StatCatalog.is_stat_valid_for_slot(slot, StatCatalog.CATEGORY_BASIC, StatCatalog.INCREASED_GOLD), "Expected Basic Increased Gold on every slot.")
		_require(StatCatalog.is_stat_valid_for_slot(slot, StatCatalog.CATEGORY_RARE, StatCatalog.INCREASED_GOLD) == (slot == GearItem.SlotType.WEAPON), "Expected Rare Increased Gold only on Weapon.")
		_require(StatCatalog.is_stat_valid_for_slot(slot, StatCatalog.CATEGORY_SPECIAL, StatCatalog.INVENTORY_ECONOMY_STATS) == (slot in [GearItem.SlotType.WEAPON, GearItem.SlotType.ARMOR]), "Expected Inventory Economy Special only on Weapon/Armor.")


func _check_basic_and_rare_economy_ranges() -> void:
	_assert_range(GearItem.SlotType.WEAPON, StatCatalog.CATEGORY_BASIC, StatCatalog.INCREASED_GOLD, .20, .30)
	_assert_range(GearItem.SlotType.HELM, StatCatalog.CATEGORY_BASIC, StatCatalog.INCREASED_GOLD, .40, .50)
	_assert_range(GearItem.SlotType.ARMOR, StatCatalog.CATEGORY_BASIC, StatCatalog.INCREASED_GOLD, .20, .30)
	_assert_range(GearItem.SlotType.TRINKET, StatCatalog.CATEGORY_BASIC, StatCatalog.INCREASED_GOLD, .10, .20)
	_assert_range(GearItem.SlotType.CHARM, StatCatalog.CATEGORY_BASIC, StatCatalog.INCREASED_GOLD, .15, .30)
	_assert_range(GearItem.SlotType.WEAPON, StatCatalog.CATEGORY_RARE, StatCatalog.INCREASED_GOLD, .50, 1.00)
	_assert_range(GearItem.SlotType.WEAPON, StatCatalog.CATEGORY_RARE, StatCatalog.SHOP_DISCOUNT, .10, .20)
	_assert_range(GearItem.SlotType.WEAPON, StatCatalog.CATEGORY_RARE, StatCatalog.INCREASED_MAGIC_FIND, .10, .20)


func _check_economy_stats_resolve_to_player_stats() -> void:
	var economy_gear := _gear_with_affixes([
		_modifier(StatCatalog.SHOP_DISCOUNT, 0.12),
		_modifier(StatCatalog.INCREASED_MAGIC_FIND, 0.18),
	])
	var stats := BuildResolver.resolve_stats(null, [], [], [economy_gear], 0)
	_require(is_equal_approx(stats.shop_discount, 0.12), "Expected Shop Discount to resolve onto PlayerStats.")
	_require(is_equal_approx(stats.magic_find, 0.18), "Expected Magic Find to resolve onto PlayerStats.")

	var drawback_gear := _gear_with_affixes([
		_modifier(StatCatalog.SHOP_DISCOUNT, -0.25, StatModifier.StatCategory.DRAWBACK, true),
		_modifier(StatCatalog.INCREASED_MAGIC_FIND, -0.25, StatModifier.StatCategory.DRAWBACK, true),
	])
	var floored_stats := BuildResolver.resolve_stats(null, [], [], [drawback_gear], 0)
	_require(is_equal_approx(floored_stats.shop_discount, 0.0), "Expected negative Shop Discount totals to floor at zero.")
	_require(is_equal_approx(floored_stats.magic_find, 0.0), "Expected negative Magic Find totals to floor at zero.")


func _check_shop_discount_affects_purchase_price_only() -> void:
	build_state.reset()
	build_state.gold = 100
	build_state.shop_round_pending = true
	build_state.equipped_charm = _gear_with_affixes([_modifier(StatCatalog.SHOP_DISCOUNT, 0.25)])
	var offer := GearItem.new()
	offer.tier = GearItem.Tier.BASIC
	offer.slot = GearItem.SlotType.WEAPON
	_require(build_state.shop_purchase_price_for(offer) == 13, "Expected 25% Shop Discount to reduce an 18g Basic item to 13g.")
	_require(build_state.shop_reroll_cost == build_state.SHOP_REROLL_INITIAL_COST, "Expected Shop Discount not to change reroll cost.")
	_require(build_state.can_reroll_shop_offers(), "Expected reroll affordability to use the unchanged reroll cost.")
	build_state.reset()


func _check_magic_find_scales_upgrade_chances() -> void:
	_require(build_state._scaled_reward_upgrade_chance_bp(1000, 1, 0.0) == 1000, "Expected zero Magic Find to leave upgrade chance unchanged.")
	_require(build_state._scaled_reward_upgrade_chance_bp(1000, 1, 0.50) == 1500, "Expected 50% Magic Find to multiply upgrade chance by 1.5.")
	_require(build_state._scaled_reward_upgrade_chance_bp(9000, 1, 1.0) == build_state.REWARD_UPGRADE_BP_DENOMINATOR, "Expected high Magic Find to clamp upgrade chance.")
	_require(build_state._upgraded_shop_tier(GearItem.Tier.LEGENDARY, "p5m11", 0, 1, 99.0) == GearItem.Tier.LEGENDARY, "Expected Magic Find not to upgrade Legendary shop rolls.")
	var forced_upgrade = build_state._upgraded_shop_tier(GearItem.Tier.BASIC, "p5m11", 1, 1, 99.0)
	_require(build_state._is_reward_upgrade_high_tier(forced_upgrade), "Expected extreme Magic Find to force the Basic -> high-tier shop upgrade chain.")


func _assert_range(slot: GearItem.SlotType, category: String, stat_id: String, expected_min: float, expected_max: float) -> void:
	var range := StatCatalog.value_range_for_slot_category(slot, category, stat_id)
	_require(bool(range.get("ok", false)), "Expected range for %s %s %s." % [GearGenerator.universal_slot_label(slot), category, stat_id])
	_require(is_equal_approx(float(range["min"]), expected_min), "Expected %s min %.2f, got %.2f." % [stat_id, expected_min, float(range["min"])])
	_require(is_equal_approx(float(range["max"]), expected_max), "Expected %s max %.2f, got %.2f." % [stat_id, expected_max, float(range["max"])])


func _gear_with_affixes(affixes: Array) -> GearItem:
	var gear := GearItem.new()
	gear.id = "gear.test.p5m11.economy"
	gear.slot = GearItem.SlotType.CHARM
	gear.tier = GearItem.Tier.BASIC
	for affix in affixes:
		gear.affixes.append(affix)
	return gear


func _modifier(stat_id: String, value: float, category: StatModifier.StatCategory = StatModifier.StatCategory.BASIC, is_drawback: bool = false) -> StatModifier:
	var modifier := StatModifier.new()
	modifier.stat_id = stat_id
	modifier.stat = StatModifier.StatType.GOLD_REWARDS
	modifier.category = category
	modifier.operation = StatModifier.OperationType.ADD
	modifier.value = value
	modifier.is_drawback = is_drawback
	modifier.display_label = StatCatalog.label_for(stat_id)
	return modifier


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	assert(false, message)
