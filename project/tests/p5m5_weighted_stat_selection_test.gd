extends SceneTree
## Focused P5M5-T4 check for slot-aware weighted stat selection.

const StatCatalog := preload("res://scripts/systems/stat_catalog.gd")


func _initialize() -> void:
	print("-- P5M5 weighted stat selection --")
	_check_documented_weights()
	_check_basic_picker_is_uniform_after_exclusions()
	_check_weighted_picker_bias()
	_check_disabled_and_used_entries_are_excluded()
	_check_generated_items_use_enabled_slot_category_pools()
	print("P5M5 weighted stat selection check: OK")
	quit(0)


func _check_documented_weights() -> void:
	_require_weight(GearItem.SlotType.WEAPON, StatCatalog.CATEGORY_BASIC, StatCatalog.BASE_DAMAGE, 1)
	_require_weight(GearItem.SlotType.WEAPON, StatCatalog.CATEGORY_BASIC, StatCatalog.INCREASED_GOLD, 1)
	_require_weight(GearItem.SlotType.WEAPON, StatCatalog.CATEGORY_BASIC, StatCatalog.SHOP_DISCOUNT, 0)
	_require_weight(GearItem.SlotType.WEAPON, StatCatalog.CATEGORY_BASIC, StatCatalog.INCREASED_MAGIC_FIND, 0)
	_require_weight(GearItem.SlotType.WEAPON, StatCatalog.CATEGORY_RARE, StatCatalog.CHANCE_TO_SHRED, 15)
	_require_weight(GearItem.SlotType.WEAPON, StatCatalog.CATEGORY_RARE, StatCatalog.INCREASED_GOLD, 5)
	_require_weight(GearItem.SlotType.WEAPON, StatCatalog.CATEGORY_RARE, StatCatalog.SHOP_DISCOUNT, 5)
	_require_weight(GearItem.SlotType.WEAPON, StatCatalog.CATEGORY_RARE, StatCatalog.INCREASED_MAGIC_FIND, 5)
	_require_weight(GearItem.SlotType.WEAPON, StatCatalog.CATEGORY_SPECIAL, StatCatalog.ALL_STATS_INCREASED, 5)
	_require_weight(GearItem.SlotType.WEAPON, StatCatalog.CATEGORY_BASIC, StatCatalog.CRIT_CHANCE, 0)

	_require_weight(GearItem.SlotType.HELM, StatCatalog.CATEGORY_BASIC, StatCatalog.CRIT_CHANCE, 1)
	_require_weight(GearItem.SlotType.HELM, StatCatalog.CATEGORY_BASIC, StatCatalog.INCREASED_GOLD, 1)
	_require_weight(GearItem.SlotType.HELM, StatCatalog.CATEGORY_SPECIAL, StatCatalog.DOUBLE_APPLIED_STACKS, 5)

	_require_weight(GearItem.SlotType.ARMOR, StatCatalog.CATEGORY_BASIC, StatCatalog.PERCENT_PHYSICAL_DAMAGE, 1)
	_require_weight(GearItem.SlotType.ARMOR, StatCatalog.CATEGORY_BASIC, StatCatalog.INCREASED_GOLD, 1)
	_require_weight(GearItem.SlotType.ARMOR, StatCatalog.CATEGORY_SPECIAL, StatCatalog.DISABLE_ENEMY_DODGE, 10)
	_require_weight(GearItem.SlotType.ARMOR, StatCatalog.CATEGORY_SPECIAL, StatCatalog.IMMUNE_TO_INTERRUPT, 5)

	_require_weight(GearItem.SlotType.TRINKET, StatCatalog.CATEGORY_BASIC, StatCatalog.BASE_DAMAGE, 1)
	_require_weight(GearItem.SlotType.TRINKET, StatCatalog.CATEGORY_RARE, StatCatalog.CHANCE_FOR_RETRIGGER, 15)
	_require_weight(GearItem.SlotType.TRINKET, StatCatalog.CATEGORY_SPECIAL, StatCatalog.CONVERT_DAMAGE_TO_PHYSICAL, 5)

	_require_weight(GearItem.SlotType.CHARM, StatCatalog.CATEGORY_BASIC, StatCatalog.CRIT_CHANCE, 1)
	_require_weight(GearItem.SlotType.CHARM, StatCatalog.CATEGORY_RARE, StatCatalog.CRIT_APPLIES_ELEMENT, 15)
	_require_weight(GearItem.SlotType.CHARM, StatCatalog.CATEGORY_SPECIAL, StatCatalog.DISABLE_ENEMY_CLEANSE, 10)


## Equal Basic likelihood is an exact uniform-index mapping, including after
## item-level exclusions. Compare actual picks to an independent uniform oracle,
## rather than estimating frequencies or trusting catalog weight constants alone.
func _check_basic_picker_is_uniform_after_exclusions() -> void:
	for slot in GearItem.universal_slot_order():
		var basic_ids := StatCatalog.stat_ids_for_slot(slot, StatCatalog.CATEGORY_BASIC)
		for pool in [StatCatalog.pool_for_slot(slot, StatCatalog.CATEGORY_BASIC), StatCatalog.drawback_pool_for_slot(slot)]:
			for exclude_ends in [false, true]:
				var used := {}
				if exclude_ends:
					used[basic_ids.front()] = true
					used[basic_ids.back()] = true
				var eligible: Array[String] = []
				for id in basic_ids:
					if not used.has(id):
						eligible.append(id)
				var picker_rng := RandomNumberGenerator.new()
				var uniform_rng := RandomNumberGenerator.new()
				picker_rng.seed = 90008 + slot
				uniform_rng.seed = picker_rng.seed
				var seen := {}
				for draw in 64:
					var expected := eligible[uniform_rng.randi_range(1, eligible.size()) - 1]
					var actual := GearGenerator._pick_stat_id_from_pool(pool, used, picker_rng)
					_require(actual == expected, "Expected uniform Basic/drawback selection among remaining IDs for slot %d, draw %d." % [slot, draw])
					seen[actual] = true
				_require(seen.size() == eligible.size(), "Expected each remaining Basic/drawback ID to be reachable.")


func _check_weighted_picker_bias() -> void:
	var pool: Array[Dictionary] = [
		{"stat_id": "low_weight", "weight": 1},
		{"stat_id": "high_weight", "weight": 99},
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 40404
	var high_count := 0
	var low_count := 0
	for i in 500:
		var picked := GearGenerator._pick_stat_id_from_pool(pool, {}, rng)
		if picked == "high_weight":
			high_count += 1
		elif picked == "low_weight":
			low_count += 1
	print("weighted picker high=%d low=%d (expect high dominance)" % [high_count, low_count])
	_require(high_count > 450, "Expected high-weight entry to dominate repeated deterministic picks.")
	_require(low_count > 0, "Expected low-weight entry to remain selectable when weight is positive.")


func _check_disabled_and_used_entries_are_excluded() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 51515
	var pool: Array[Dictionary] = [
		{"stat_id": "disabled", "weight": 0},
		{"stat_id": "used", "weight": 100},
		{"stat_id": "available", "weight": 1},
	]
	for i in 50:
		var picked := GearGenerator._pick_stat_id_from_pool(pool, {"used": true}, rng)
		_require(picked == "available", "Expected picker to skip disabled and already-used entries.")

	var empty := GearGenerator._pick_stat_id_from_pool([
		{"stat_id": "disabled", "weight": 0},
		{"stat_id": "negative", "weight": -10},
	], {}, rng)
	_require(empty == "", "Expected zero-total weighted pool to fail loudly through empty selection.")


func _check_generated_items_use_enabled_slot_category_pools() -> void:
	var seed := 9200
	for slot in GearItem.universal_slot_order():
		for tier in GearGenerator.ACTIVE_GENERATED_TIERS:
			var rng := RandomNumberGenerator.new()
			rng.seed = seed
			seed += 31
			var result := GearGenerator.generate_from_request({
				"tier": tier,
				"slot": slot,
				"rng": rng,
				"id": "gear.test.p5m5.t4.%d.%d" % [tier, slot],
				"deterministic_key": "p5m5:t4:%d:%d" % [tier, slot],
				"source_context": "p5m5_t4",
				"source_seed": seed,
			})
			_require(result["ok"], "Expected generated item to satisfy weighted pools: %s." % str(result["errors"]))
			var item: GearItem = result["item"]
			for modifier in item.affixes:
				_require(_modifier_uses_enabled_pool(item.slot, modifier), "Expected %s to use enabled %s pool for %s." % [
					modifier.stat_id,
					_category_name(modifier),
					GearGenerator.universal_slot_label(item.slot),
				])


func _modifier_uses_enabled_pool(slot: GearItem.SlotType, modifier: StatModifier) -> bool:
	var stat_id := StatCatalog.canonical_id_for_modifier(modifier)
	if modifier.category == StatModifier.StatCategory.DRAWBACK:
		for entry in StatCatalog.drawback_pool_for_slot(slot):
			if String(entry.get("stat_id", "")) == stat_id and int(entry.get("weight", 0)) > 0:
				return true
		return false
	if modifier.category == StatModifier.StatCategory.BASIC:
		return StatCatalog.is_stat_enabled_for_slot(slot, StatCatalog.CATEGORY_BASIC, stat_id)
	if modifier.category == StatModifier.StatCategory.RARE:
		return StatCatalog.is_stat_enabled_for_slot(slot, StatCatalog.CATEGORY_RARE, stat_id)
	if modifier.category == StatModifier.StatCategory.SPECIAL:
		return StatCatalog.is_stat_enabled_for_slot(slot, StatCatalog.CATEGORY_SPECIAL, stat_id)
	return false


func _category_name(modifier: StatModifier) -> String:
	if modifier.category == StatModifier.StatCategory.DRAWBACK:
		return "drawback"
	if modifier.category == StatModifier.StatCategory.BASIC:
		return StatCatalog.CATEGORY_BASIC
	if modifier.category == StatModifier.StatCategory.RARE:
		return StatCatalog.CATEGORY_RARE
	if modifier.category == StatModifier.StatCategory.SPECIAL:
		return StatCatalog.CATEGORY_SPECIAL
	return "unknown"


func _require_weight(slot: GearItem.SlotType, category: String, stat_id: String, expected: int) -> void:
	var actual := StatCatalog.weight_for_slot(slot, category, stat_id)
	_require(actual == expected, "Expected %s %s %s weight %d, got %d." % [
		GearGenerator.universal_slot_label(slot),
		category,
		stat_id,
		expected,
		actual,
	])


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	assert(false, message)
