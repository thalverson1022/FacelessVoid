extends SceneTree

const StatCatalog := preload("res://scripts/systems/stat_catalog.gd")
const GearItem := preload("res://scripts/resources/gear_item.gd")


func _init() -> void:
	_test_exact_slot_pools()
	_test_invalid_slot_category_combinations()
	_test_enemy_denial_expansion()
	_test_drawback_pools_are_basic_only()
	_test_pool_entry_shape_and_aliases()
	print("P5M3 slot stat eligibility tests passed")
	quit(0)


func _test_exact_slot_pools() -> void:
	_assert_ids_equal(StatCatalog.stat_ids_for_slot(GearItem.SlotType.WEAPON, StatCatalog.CATEGORY_BASIC), [StatCatalog.BASE_DAMAGE, StatCatalog.PERCENT_PHYSICAL_DAMAGE, StatCatalog.CRIT_DAMAGE, StatCatalog.BASE_ELEMENTAL_DAMAGE, StatCatalog.PERCENT_ELEMENTAL_DAMAGE, StatCatalog.INCREASED_GOLD], "Weapon Basic pool")
	_assert_ids_equal(StatCatalog.stat_ids_for_slot(GearItem.SlotType.WEAPON, StatCatalog.CATEGORY_RARE), [StatCatalog.CHANCE_TO_SHRED, StatCatalog.CHANCE_TO_DECAY, StatCatalog.CHANCE_FOR_RETRIGGER, StatCatalog.SHOP_DISCOUNT, StatCatalog.INCREASED_MAGIC_FIND, StatCatalog.INCREASED_GOLD, StatCatalog.COOLDOWN_REDUCTION, StatCatalog.INCREASED_BUFF_DURATION], "Weapon Rare pool")
	_assert_ids_equal(StatCatalog.stat_ids_for_slot(GearItem.SlotType.WEAPON, StatCatalog.CATEGORY_SPECIAL), [StatCatalog.CONVERT_DAMAGE_TO_PHYSICAL, StatCatalog.CONVERT_DAMAGE_TO_MAGICAL, StatCatalog.ALL_STATS_INCREASED, StatCatalog.INVENTORY_ECONOMY_STATS], "Weapon Special pool")

	_assert_ids_equal(StatCatalog.stat_ids_for_slot(GearItem.SlotType.HELM, StatCatalog.CATEGORY_BASIC), [StatCatalog.PERCENT_PHYSICAL_DAMAGE, StatCatalog.CRIT_CHANCE, StatCatalog.INCREASED_ATTACK_SPEED, StatCatalog.BASE_ELEMENTAL_DAMAGE, StatCatalog.PERCENT_ELEMENTAL_DAMAGE, StatCatalog.INCREASED_ALL_STACKS, StatCatalog.INCREASED_GOLD], "Helm Basic pool")
	_assert_ids_equal(StatCatalog.stat_ids_for_slot(GearItem.SlotType.HELM, StatCatalog.CATEGORY_RARE), [StatCatalog.CHANCE_TO_SHRED, StatCatalog.CHANCE_TO_DECAY, StatCatalog.CRIT_APPLIES_ELEMENT, StatCatalog.CRIT_APPLIES_PENETRATION, StatCatalog.CRIT_APPLIES_POTENCY, StatCatalog.COOLDOWN_REDUCTION], "Helm Rare pool")
	_assert_ids_equal(StatCatalog.stat_ids_for_slot(GearItem.SlotType.HELM, StatCatalog.CATEGORY_SPECIAL), [StatCatalog.DOUBLE_APPLIED_STACKS, StatCatalog.IGNORE_ARMOR_NO_SHRED, StatCatalog.IGNORE_RESISTANCE_PHYSICAL_PENALTY], "Helm Special pool")

	_assert_ids_equal(StatCatalog.stat_ids_for_slot(GearItem.SlotType.ARMOR, StatCatalog.CATEGORY_BASIC), [StatCatalog.PERCENT_PHYSICAL_DAMAGE, StatCatalog.CRIT_CHANCE, StatCatalog.PERCENT_ELEMENTAL_DAMAGE, StatCatalog.INCREASED_GOLD, StatCatalog.INCREASED_ALL_STACKS], "Armor Basic pool")
	_assert_ids_equal(StatCatalog.stat_ids_for_slot(GearItem.SlotType.ARMOR, StatCatalog.CATEGORY_RARE), [StatCatalog.CHANCE_TO_SHRED, StatCatalog.CHANCE_TO_DECAY, StatCatalog.CRIT_APPLIES_ELEMENT, StatCatalog.CRIT_APPLIES_PENETRATION, StatCatalog.CRIT_APPLIES_POTENCY, StatCatalog.INCREASED_BUFF_DURATION], "Armor Rare pool")
	_assert_ids_equal(StatCatalog.stat_ids_for_slot(GearItem.SlotType.ARMOR, StatCatalog.CATEGORY_SPECIAL), [StatCatalog.ALL_STATS_INCREASED, StatCatalog.DISABLE_ENEMY_DODGE, StatCatalog.DISABLE_ENEMY_BLOCK, StatCatalog.DISABLE_ENEMY_ABSORB, StatCatalog.DISABLE_ENEMY_SUPPRESS, StatCatalog.DISABLE_ENEMY_CLEANSE, StatCatalog.IMMUNE_TO_STUN, StatCatalog.IMMUNE_TO_SLOW, StatCatalog.IMMUNE_TO_INTERRUPT, StatCatalog.INVENTORY_ECONOMY_STATS], "Armor Special pool")

	_assert_ids_equal(StatCatalog.stat_ids_for_slot(GearItem.SlotType.TRINKET, StatCatalog.CATEGORY_BASIC), [StatCatalog.BASE_DAMAGE, StatCatalog.PERCENT_PHYSICAL_DAMAGE, StatCatalog.CRIT_CHANCE, StatCatalog.INCREASED_ATTACK_SPEED, StatCatalog.BASE_ELEMENTAL_DAMAGE, StatCatalog.PERCENT_ELEMENTAL_DAMAGE, StatCatalog.INCREASED_GOLD], "Trinket Basic pool")
	_assert_ids_equal(StatCatalog.stat_ids_for_slot(GearItem.SlotType.TRINKET, StatCatalog.CATEGORY_RARE), [StatCatalog.CHANCE_FOR_RETRIGGER, StatCatalog.CHANCE_TO_SHRED, StatCatalog.CHANCE_TO_DECAY, StatCatalog.CRIT_APPLIES_ELEMENT, StatCatalog.CRIT_APPLIES_PENETRATION, StatCatalog.CRIT_APPLIES_POTENCY, StatCatalog.INCREASED_BUFF_DURATION], "Trinket Rare pool")
	_assert_ids_equal(StatCatalog.stat_ids_for_slot(GearItem.SlotType.TRINKET, StatCatalog.CATEGORY_SPECIAL), [StatCatalog.DOUBLE_APPLIED_STACKS, StatCatalog.DISABLE_ENEMY_DODGE, StatCatalog.DISABLE_ENEMY_BLOCK, StatCatalog.DISABLE_ENEMY_ABSORB, StatCatalog.DISABLE_ENEMY_SUPPRESS, StatCatalog.DISABLE_ENEMY_CLEANSE, StatCatalog.CONVERT_DAMAGE_TO_PHYSICAL, StatCatalog.CONVERT_DAMAGE_TO_MAGICAL], "Trinket Special pool")

	_assert_ids_equal(StatCatalog.stat_ids_for_slot(GearItem.SlotType.CHARM, StatCatalog.CATEGORY_BASIC), [StatCatalog.PERCENT_PHYSICAL_DAMAGE, StatCatalog.CRIT_CHANCE, StatCatalog.INCREASED_ATTACK_SPEED, StatCatalog.CRIT_DAMAGE, StatCatalog.BASE_ELEMENTAL_DAMAGE, StatCatalog.PERCENT_ELEMENTAL_DAMAGE, StatCatalog.INCREASED_GOLD, StatCatalog.INCREASED_ALL_STACKS], "Charm Basic pool")
	_assert_ids_equal(StatCatalog.stat_ids_for_slot(GearItem.SlotType.CHARM, StatCatalog.CATEGORY_RARE), [StatCatalog.CHANCE_TO_SHRED, StatCatalog.CHANCE_TO_DECAY, StatCatalog.CRIT_APPLIES_ELEMENT, StatCatalog.CRIT_APPLIES_PENETRATION, StatCatalog.CRIT_APPLIES_POTENCY, StatCatalog.COOLDOWN_REDUCTION], "Charm Rare pool")
	_assert_ids_equal(StatCatalog.stat_ids_for_slot(GearItem.SlotType.CHARM, StatCatalog.CATEGORY_SPECIAL), [StatCatalog.IGNORE_ARMOR_NO_SHRED, StatCatalog.IGNORE_RESISTANCE_PHYSICAL_PENALTY, StatCatalog.DOUBLE_APPLIED_STACKS, StatCatalog.DISABLE_ENEMY_DODGE, StatCatalog.DISABLE_ENEMY_BLOCK, StatCatalog.DISABLE_ENEMY_ABSORB, StatCatalog.DISABLE_ENEMY_SUPPRESS, StatCatalog.DISABLE_ENEMY_CLEANSE], "Charm Special pool")


func _test_invalid_slot_category_combinations() -> void:
	_require(not StatCatalog.is_stat_valid_for_slot(GearItem.SlotType.HELM, StatCatalog.CATEGORY_BASIC, StatCatalog.BASE_DAMAGE), "Helm should not allow flat base damage")
	_require(not StatCatalog.is_stat_valid_for_slot(GearItem.SlotType.ARMOR, StatCatalog.CATEGORY_BASIC, StatCatalog.BASE_DAMAGE), "Armor should not allow flat base damage")
	_require(not StatCatalog.is_stat_valid_for_slot(GearItem.SlotType.CHARM, StatCatalog.CATEGORY_BASIC, StatCatalog.BASE_DAMAGE), "Charm should not allow flat base damage")
	_require(not StatCatalog.is_stat_valid_for_slot(GearItem.SlotType.WEAPON, StatCatalog.CATEGORY_BASIC, StatCatalog.CRIT_CHANCE), "Weapon should not allow crit chance")
	_require(not StatCatalog.is_stat_valid_for_slot(GearItem.SlotType.HELM, StatCatalog.CATEGORY_RARE, StatCatalog.CHANCE_FOR_RETRIGGER), "Helm should not allow retrigger chance")
	_require(not StatCatalog.is_stat_valid_for_slot(GearItem.SlotType.ARMOR, StatCatalog.CATEGORY_RARE, StatCatalog.CHANCE_FOR_RETRIGGER), "Armor should not allow retrigger chance")
	_require(not StatCatalog.is_stat_valid_for_slot(GearItem.SlotType.CHARM, StatCatalog.CATEGORY_RARE, StatCatalog.CHANCE_FOR_RETRIGGER), "Charm should not allow retrigger chance")
	_require(not StatCatalog.is_stat_valid_for_slot(GearItem.SlotType.WEAPON, StatCatalog.CATEGORY_SPECIAL, StatCatalog.IGNORE_ARMOR_NO_SHRED), "Weapon should not allow ignore armor without Shred")
	_require(not StatCatalog.is_stat_valid_for_slot(GearItem.SlotType.HELM, StatCatalog.CATEGORY_SPECIAL, StatCatalog.ALL_STATS_INCREASED), "Helm should not allow all stats increased")
	_require(not StatCatalog.is_stat_valid_for_slot(GearItem.SlotType.TRINKET, StatCatalog.CATEGORY_SPECIAL, StatCatalog.ALL_STATS_INCREASED), "Trinket should not allow all stats increased")
	_require(not StatCatalog.is_stat_valid_for_slot(GearItem.SlotType.CHARM, StatCatalog.CATEGORY_SPECIAL, StatCatalog.ALL_STATS_INCREASED), "Charm should not allow all stats increased")


func _test_enemy_denial_expansion() -> void:
	var denial_ids := [StatCatalog.DISABLE_ENEMY_DODGE, StatCatalog.DISABLE_ENEMY_BLOCK, StatCatalog.DISABLE_ENEMY_ABSORB, StatCatalog.DISABLE_ENEMY_SUPPRESS, StatCatalog.DISABLE_ENEMY_CLEANSE]
	for stat_id in denial_ids:
		_require(StatCatalog.is_stat_valid_for_slot(GearItem.SlotType.ARMOR, StatCatalog.CATEGORY_SPECIAL, stat_id), "Armor should include enemy denial stat %s" % stat_id)
		_require(StatCatalog.is_stat_valid_for_slot(GearItem.SlotType.TRINKET, StatCatalog.CATEGORY_SPECIAL, stat_id), "Trinket should include enemy denial stat %s" % stat_id)
		_require(StatCatalog.is_stat_valid_for_slot(GearItem.SlotType.CHARM, StatCatalog.CATEGORY_SPECIAL, stat_id), "Charm should include enemy denial stat %s" % stat_id)
		_require(not StatCatalog.is_stat_valid_for_slot(GearItem.SlotType.WEAPON, StatCatalog.CATEGORY_SPECIAL, stat_id), "Weapon should not include enemy denial stat %s" % stat_id)
		_require(not StatCatalog.is_stat_valid_for_slot(GearItem.SlotType.HELM, StatCatalog.CATEGORY_SPECIAL, stat_id), "Helm should not include enemy denial stat %s" % stat_id)


func _test_drawback_pools_are_basic_only() -> void:
	var weapon_drawbacks := StatCatalog.drawback_stat_ids_for_slot(GearItem.SlotType.WEAPON)
	_require(weapon_drawbacks.has(StatCatalog.BASE_DAMAGE), "Weapon drawback pool should include Basic base damage")
	_require(weapon_drawbacks.has(StatCatalog.PERCENT_PHYSICAL_DAMAGE), "Weapon drawback pool should include Basic physical damage")
	_require(not weapon_drawbacks.has(StatCatalog.CHANCE_TO_SHRED), "Weapon drawback pool should exclude Rare stats")
	_require(not weapon_drawbacks.has(StatCatalog.ALL_STATS_INCREASED), "Weapon drawback pool should exclude Special stats")

	var armor_drawbacks := StatCatalog.drawback_stat_ids_for_slot(GearItem.SlotType.ARMOR)
	_require(not armor_drawbacks.has(StatCatalog.BASE_DAMAGE), "Armor drawback pool should not include off-slot Basic stats")
	_require(armor_drawbacks.has(StatCatalog.CRIT_CHANCE), "Armor drawback pool should include eligible Basic stats")
	_require(not armor_drawbacks.has(StatCatalog.CRIT_APPLIES_ELEMENT), "Armor drawback pool should exclude Rare stats")


func _test_pool_entry_shape_and_aliases() -> void:
	for slot in [GearItem.SlotType.WEAPON, GearItem.SlotType.HELM, GearItem.SlotType.ARMOR, GearItem.SlotType.TRINKET, GearItem.SlotType.CHARM]:
		for category in [StatCatalog.CATEGORY_BASIC, StatCatalog.CATEGORY_RARE, StatCatalog.CATEGORY_SPECIAL]:
			for entry in StatCatalog.pool_for_slot(slot, category):
				_require(entry.has("stat_id"), "Pool entries should expose stat_id")
				_require(entry.has("weight"), "Pool entries should expose weight")
				_require(StatCatalog.has_stat(String(entry["stat_id"])), "Pool stat IDs should be cataloged")
				_require(int(entry["weight"]) > 0, "Current pool entries should be enabled")
				_require(StatCatalog.is_stat_enabled_for_slot(slot, category, String(entry["stat_id"])), "Positive-weight entries should be enabled")

	_require(StatCatalog.is_stat_valid_for_slot(GearItem.SlotType.WEAPON, StatCatalog.CATEGORY_BASIC, "physical_damage"), "Legacy string aliases should resolve in pool queries")
	_require(StatCatalog.weight_for_slot(GearItem.SlotType.WEAPON, StatCatalog.CATEGORY_BASIC, "not_a_stat") == 0, "Unknown stats should report zero weight")
	_require(not StatCatalog.is_stat_enabled_for_slot(GearItem.SlotType.WEAPON, StatCatalog.CATEGORY_BASIC, "not_a_stat"), "Unknown stats should not be enabled")


func _assert_ids_equal(actual: Array[String], expected: Array, message: String) -> void:
	_require(actual.size() == expected.size(), "%s should contain %d IDs, got %d (%s)" % [message, expected.size(), actual.size(), str(actual)])
	for index in expected.size():
		_require(actual[index] == expected[index], "%s expected %s at index %d, got %s" % [message, expected[index], index, actual[index]])


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
