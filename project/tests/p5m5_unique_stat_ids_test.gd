extends SceneTree
## Focused P5M5-T5 check for same-item unique stat IDs.

const StatCatalog := preload("res://scripts/systems/stat_catalog.gd")


func _initialize() -> void:
	print("-- P5M5 unique stat IDs --")
	_check_generated_items_never_duplicate_stat_ids()
	_check_cursed_and_chaos_drawbacks_do_not_collide()
	_check_unique_special_does_not_duplicate_normal_stats()
	_check_impossible_roll_plans_fail_before_affixes()
	_check_picker_canonicalizes_used_ids()
	print("P5M5 unique stat IDs check: OK")
	quit(0)


func _check_generated_items_never_duplicate_stat_ids() -> void:
	var seed := 12005
	for slot in GearItem.universal_slot_order():
		for tier in GearGenerator.ACTIVE_GENERATED_TIERS:
			if tier == GearItem.Tier.CHAOS:
				continue
			for sample in 20:
				var rng := RandomNumberGenerator.new()
				rng.seed = seed
				seed += 37
				var result := GearGenerator.generate_from_request({
					"tier": tier,
					"slot": slot,
					"rng": rng,
					"id": "gear.test.p5m5.t5.%d.%d.%d" % [tier, slot, sample],
					"deterministic_key": "p5m5:t5:%d:%d:%d" % [tier, slot, sample],
					"source_context": "p5m5_t5",
					"source_seed": seed,
				})
				_require(result["ok"], "Expected valid generation to succeed: %s." % str(result["errors"]))
				_require(_duplicate_stat_ids(result["item"]).is_empty(), "Expected no duplicate stat IDs on generated item.")


func _check_cursed_and_chaos_drawbacks_do_not_collide() -> void:
	var seed := 22005
	for tier in [GearItem.Tier.CURSED]:
		for slot in GearItem.universal_slot_order():
			for sample in 20:
				var rng := RandomNumberGenerator.new()
				rng.seed = seed
				seed += 41
				var item: GearItem = GearGenerator.generate(tier, slot, rng, "gear.test.p5m5.t5.drawback")
				_require(item != null, "Expected drawback rarity item to generate.")
				var positive_ids := {}
				var drawback_ids := {}
				for modifier in item.affixes:
					var stat_id := StatCatalog.canonical_id_for_modifier(modifier)
					if modifier.is_drawback:
						drawback_ids[stat_id] = true
					else:
						positive_ids[stat_id] = true
				for stat_id in drawback_ids.keys():
					_require(not positive_ids.has(stat_id), "Expected drawback stat %s not to collide with positive stat." % stat_id)


func _check_unique_special_does_not_duplicate_normal_stats() -> void:
	var seed := 32005
	for slot in GearItem.universal_slot_order():
		for sample in 20:
			var rng := RandomNumberGenerator.new()
			rng.seed = seed
			seed += 43
			var item := GearGenerator.generate(GearItem.Tier.UNIQUE, slot, rng, "gear.test.p5m5.t5.unique")
			_require(item != null, "Expected Unique item to generate.")
			_require(_count_category(item, StatModifier.StatCategory.SPECIAL) == 1, "Expected exactly one Unique Special.")
			_require(_duplicate_stat_ids(item).is_empty(), "Expected Unique Special not to duplicate another stat ID.")


func _check_impossible_roll_plans_fail_before_affixes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42005
	var too_many_specials: Array[Dictionary] = [
		{"category": StatCatalog.CATEGORY_SPECIAL, "is_drawback": false},
		{"category": StatCatalog.CATEGORY_SPECIAL, "is_drawback": false},
		{"category": StatCatalog.CATEGORY_SPECIAL, "is_drawback": false},
		{"category": StatCatalog.CATEGORY_SPECIAL, "is_drawback": false},
	]
	# Weapon now has four Specials; five distinct rolls are impossible.
	too_many_specials.append({"category": StatCatalog.CATEGORY_SPECIAL, "is_drawback": false})
	var weapon_special_result := GearGenerator._affixes_for_rolls(GearItem.SlotType.WEAPON, GearItem.Tier.UNIQUE, too_many_specials, rng)
	_require((weapon_special_result["affixes"] as Array).is_empty(), "Expected impossible Special plan to return no partial affixes.")
	_require((weapon_special_result["errors"] as PackedStringArray).has("insufficient_special_pool:Weapon"), "Expected impossible Special plan to fail loudly.")

	var invalid_category_result := GearGenerator._affixes_for_rolls(GearItem.SlotType.ARMOR, GearItem.Tier.BASIC, [
		{"category": "missing_category", "is_drawback": false},
	], rng)
	_require((invalid_category_result["affixes"] as Array).is_empty(), "Expected invalid category plan to return no partial affixes.")
	_require((invalid_category_result["errors"] as PackedStringArray).has("insufficient_missing_category_pool:Armor"), "Expected invalid category plan to name missing category.")

	var zero_pool_result := GearGenerator._affixes_for_rolls(GearItem.SlotType.CHARM, GearItem.Tier.BASIC, [
		{"category": StatCatalog.CATEGORY_BASIC, "is_drawback": false},
	], rng)
	_require(not (zero_pool_result["errors"] as PackedStringArray).has("insufficient_basic_pool:Charm"), "Expected normal Charm Basic pool to be satisfiable.")


func _check_picker_canonicalizes_used_ids() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 52005
	var pool: Array[Dictionary] = [
		{"stat_id": "physical_damage", "weight": 100},
		{"stat_id": StatCatalog.CRIT_CHANCE, "weight": 1},
	]
	for i in 20:
		var picked := GearGenerator._pick_stat_id_from_pool(pool, {StatCatalog.PERCENT_PHYSICAL_DAMAGE: true}, rng)
		_require(picked == StatCatalog.CRIT_CHANCE, "Expected picker to treat physical_damage alias as already-used canonical stat.")


func _duplicate_stat_ids(item: GearItem) -> Array[String]:
	var seen := {}
	var duplicates: Array[String] = []
	for modifier in item.affixes:
		var stat_id := StatCatalog.canonical_id_for_modifier(modifier)
		if seen.has(stat_id) and not duplicates.has(stat_id):
			duplicates.append(stat_id)
		seen[stat_id] = true
	return duplicates


func _count_category(item: GearItem, category: StatModifier.StatCategory) -> int:
	var count := 0
	for modifier in item.affixes:
		if modifier.category == category:
			count += 1
	return count


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	assert(false, message)
