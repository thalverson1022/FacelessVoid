extends SceneTree
## Focused P5M5-T9 check for Unique-only Special stat generation.

const StatCatalog := preload("res://scripts/systems/stat_catalog.gd")


func _initialize() -> void:
	print("-- P5M5 Unique Special rolls --")
	_check_unique_roll_plan()
	_check_generated_unique_items_for_all_slots()
	_check_unique_special_picker_reaches_enabled_slot_specials()
	_check_unique_specials_bridge_to_stat_sheet()
	_check_unique_specials_are_deterministic()
	_check_impossible_unique_special_plans_fail_cleanly()
	print("P5M5 Unique Special rolls check: OK")
	quit(0)


func _check_unique_roll_plan() -> void:
	var expected := [
		GearGenerator._roll_spec(StatCatalog.CATEGORY_BASIC),
		GearGenerator._roll_spec(StatCatalog.CATEGORY_BASIC),
		GearGenerator._roll_spec(StatCatalog.CATEGORY_BASIC),
		GearGenerator._roll_spec(StatCatalog.CATEGORY_RARE),
		GearGenerator._roll_spec(StatCatalog.CATEGORY_SPECIAL),
	]
	_require(GearGenerator.unique_roll_plan() == expected, "Expected named Unique plan to be 3 Basic, 1 Rare, 1 Special.")
	var plan := GearGenerator.rarity_roll_plan(GearItem.Tier.UNIQUE)
	_require(plan["ok"], "Expected Unique rarity plan to be supported.")
	_require(plan["rolls"] == expected, "Expected rarity_roll_plan(Unique) to delegate to the named Unique plan.")


func _check_generated_unique_items_for_all_slots() -> void:
	var seed := 99009
	for slot in GearItem.universal_slot_order():
		for sample in 100:
			var rng := RandomNumberGenerator.new()
			rng.seed = seed
			seed += 47
			var result := GearGenerator.generate_from_request({
				"tier": GearItem.Tier.UNIQUE,
				"slot": slot,
				"rng": rng,
				"id": "gear.test.p5m5.t9.%d.%d" % [slot, sample],
				"deterministic_key": "p5m5:t9:%d:%d" % [slot, sample],
				"source_context": "p5m5_t9",
				"source_seed": seed,
			})
			_require(result["ok"], "Expected Unique generation to succeed: %s." % str(result["errors"]))
			var item: GearItem = result["item"]
			_require(item.affixes.size() == 5, "Expected Unique item to have five affixes.")
			_require(_count_category(item, StatModifier.StatCategory.BASIC) == 3, "Expected Unique item to have three Basic affixes.")
			_require(_count_category(item, StatModifier.StatCategory.RARE) == 1, "Expected Unique item to have one Rare affix.")
			_require(_count_category(item, StatModifier.StatCategory.SPECIAL) == 1, "Expected Unique item to have exactly one Special affix.")
			_require(_count_category(item, StatModifier.StatCategory.DRAWBACK) == 0, "Expected Unique item not to roll drawbacks.")
			_require(_all_stats_are_valid_for_slot(item), "Expected Unique affixes to be slot/category eligible.")
			_require(_has_unique_stat_ids(item), "Expected Unique item to avoid duplicate stat IDs.")
			var special := _special_modifier(item)
			_require(special != null, "Expected Unique item to carry a Special modifier.")
			_require(StatCatalog.is_special(special.stat_id), "Expected Unique Special to use a Special stat ID.")
			_require(StatCatalog.is_binary(special.stat_id), "Expected Unique Special to use a binary stat ID.")
			_require(is_equal_approx(special.value, GearGenerator.PLACEHOLDER_BINARY_VALUE), "Expected Unique Special value to stay binary.")
			_require(not special.is_drawback, "Expected Unique Special not to be a drawback.")


func _check_unique_special_picker_reaches_enabled_slot_specials() -> void:
	var seed := 109009
	for slot in GearItem.universal_slot_order():
		var seen := {}
		for sample in 500:
			var rng := RandomNumberGenerator.new()
			rng.seed = seed
			seed += 53
			var item := GearGenerator.generate(GearItem.Tier.UNIQUE, slot, rng, "gear.test.p5m5.t9.coverage")
			var special := _special_modifier(item)
			_require(special != null, "Expected Unique coverage item to have a Special.")
			seen[special.stat_id] = true
		for stat_id in StatCatalog.stat_ids_for_slot(slot, StatCatalog.CATEGORY_SPECIAL):
			if StatCatalog.weight_for_slot(slot, StatCatalog.CATEGORY_SPECIAL, stat_id) <= 0:
				continue
			_require(seen.has(stat_id), "Expected Unique Special picker to reach enabled %s Special %s." % [
				GearGenerator.universal_slot_label(slot),
				stat_id,
			])


func _check_unique_specials_bridge_to_stat_sheet() -> void:
	var class_def: ClassDef = load("res://data/classes/rogue.tres")
	var rng := RandomNumberGenerator.new()
	rng.seed = 209009
	var item := GearGenerator.generate(GearItem.Tier.UNIQUE, GearItem.SlotType.ARMOR, rng, "gear.test.p5m5.t9.bridge")
	var special := _special_modifier(item)
	_require(special != null, "Expected bridge item to have a Special.")
	var stats := BuildResolver.resolve_stats(class_def, [], [], [item])
	_require(stats.special_stat_ids.size() == 1, "Expected Unique Special to bridge to PlayerStats.")
	_require(stats.special_stat_ids.has(special.stat_id), "Expected PlayerStats to include the generated Unique Special ID.")


func _check_unique_specials_are_deterministic() -> void:
	var first := _generated_signature(309009)
	var second := _generated_signature(309009)
	_require(first == second, "Expected same Unique seed to produce identical stat IDs, categories, and values.")


func _check_impossible_unique_special_plans_fail_cleanly() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 409009
	var too_many_weapon_specials: Array[Dictionary] = [
		GearGenerator._roll_spec(StatCatalog.CATEGORY_SPECIAL),
		GearGenerator._roll_spec(StatCatalog.CATEGORY_SPECIAL),
		GearGenerator._roll_spec(StatCatalog.CATEGORY_SPECIAL),
		GearGenerator._roll_spec(StatCatalog.CATEGORY_SPECIAL),
		GearGenerator._roll_spec(StatCatalog.CATEGORY_SPECIAL),
	]
	var result := GearGenerator._affixes_for_rolls(GearItem.SlotType.WEAPON, GearItem.Tier.UNIQUE, too_many_weapon_specials, rng)
	_require((result["affixes"] as Array).is_empty(), "Expected impossible Unique Special plan to return no affixes.")
	_require((result["errors"] as PackedStringArray).has("insufficient_special_pool:Weapon"), "Expected impossible Unique Special plan to fail loudly.")

	var invalid_forced := GearGenerator._roll_spec(StatCatalog.CATEGORY_SPECIAL)
	invalid_forced["forced_stat_id"] = StatCatalog.BASE_DAMAGE
	var forced_result := GearGenerator._affixes_for_rolls(GearItem.SlotType.WEAPON, GearItem.Tier.UNIQUE, [invalid_forced], rng)
	_require((forced_result["affixes"] as Array).is_empty(), "Expected invalid forced Unique Special to return no affixes.")
	_require((forced_result["errors"] as PackedStringArray).has("insufficient_special_pool:Weapon"), "Expected invalid forced Unique Special to fail loudly.")


func _generated_signature(seed: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var result := GearGenerator.generate_from_request({
		"tier": GearItem.Tier.UNIQUE,
		"slot": GearItem.SlotType.TRINKET,
		"rng": rng,
		"id": "gear.test.p5m5.t9.deterministic",
		"deterministic_key": "p5m5:t9:deterministic",
		"source_context": "p5m5_t9",
		"source_seed": seed,
	})
	_require(result["ok"], "Expected deterministic Unique item to generate: %s." % str(result["errors"]))
	var parts: PackedStringArray = []
	for modifier in (result["item"] as GearItem).affixes:
		parts.append("%s:%d:%s:%.4f" % [
			modifier.stat_id,
			modifier.category,
			"drawback" if modifier.is_drawback else "positive",
			modifier.value,
		])
	return "|".join(parts)


func _special_modifier(item: GearItem) -> StatModifier:
	for modifier in item.affixes:
		if modifier.category == StatModifier.StatCategory.SPECIAL:
			return modifier
	return null


func _count_category(item: GearItem, category: StatModifier.StatCategory) -> int:
	var count := 0
	for modifier in item.affixes:
		if modifier.category == category:
			count += 1
	return count


func _all_stats_are_valid_for_slot(item: GearItem) -> bool:
	for modifier in item.affixes:
		var stat_id := StatCatalog.canonical_id_for_modifier(modifier)
		if stat_id == "":
			return false
		if modifier.category == StatModifier.StatCategory.SPECIAL:
			if not StatCatalog.is_stat_enabled_for_slot(item.slot, StatCatalog.CATEGORY_SPECIAL, stat_id):
				return false
		elif modifier.category == StatModifier.StatCategory.RARE:
			if not StatCatalog.is_stat_enabled_for_slot(item.slot, StatCatalog.CATEGORY_RARE, stat_id):
				return false
		elif modifier.category == StatModifier.StatCategory.BASIC:
			if not StatCatalog.is_stat_enabled_for_slot(item.slot, StatCatalog.CATEGORY_BASIC, stat_id):
				return false
		else:
			return false
	return true


func _has_unique_stat_ids(item: GearItem) -> bool:
	var used := {}
	for modifier in item.affixes:
		var stat_id := StatCatalog.canonical_id_for_modifier(modifier)
		if used.has(stat_id):
			return false
		used[stat_id] = true
	return true


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	assert(false, message)
