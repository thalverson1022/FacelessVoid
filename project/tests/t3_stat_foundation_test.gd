extends SceneTree
const Sheet = preload("res://scripts/resources/stat_sheet.gd")
const State = preload("res://scripts/systems/combat_stat_state.gd")
# Independent pool witness; Basic weights superseded by P6M9-D008, other fields retained.
const EXPECTED = {"WEAPON":{"basic":[{"id":"base_damage","min":2,"max":5,"weight":1},{"id":"percent_physical_damage","min":0.1,"max":0.2,"weight":1},{"id":"crit_damage","min":0.5,"max":0.75,"weight":1},{"id":"base_elemental_damage","min":3,"max":6,"weight":1},{"id":"percent_elemental_damage","min":0.3,"max":0.4,"weight":1},{"id":"increased_gold","min":0.2,"max":0.3,"weight":1}],"rare":[{"id":"chance_to_shred","min":0.08,"max":0.1,"weight":15},{"id":"chance_to_decay","min":0.08,"max":0.1,"weight":10},{"id":"chance_for_retrigger","min":0.05,"max":0.08,"weight":10},{"id":"shop_discount","min":0.1,"max":0.2,"weight":5},{"id":"increased_magic_find","min":0.1,"max":0.2,"weight":5},{"id":"increased_gold","min":0.5,"max":1.0,"weight":5},{"id":"cooldown_reduction","min":0.04,"max":0.06,"weight":8},{"id":"increased_buff_duration","min":0.08,"max":0.14,"weight":8}],"special":[{"id":"convert_damage_to_physical","value":1,"weight":5},{"id":"convert_damage_to_magical","value":1,"weight":5},{"id":"all_stats_increased","value":1,"weight":5},{"id":"inventory_economy_stats","value":1,"weight":5}]},"HELM":{"basic":[{"id":"percent_physical_damage","min":0.2,"max":0.25,"weight":1},{"id":"crit_chance","min":0.03,"max":0.08,"weight":1},{"id":"increased_attack_speed","min":0.05,"max":0.12,"weight":1},{"id":"base_elemental_damage","min":4,"max":10,"weight":1},{"id":"percent_elemental_damage","min":0.25,"max":0.35,"weight":1},{"id":"increased_all_stacks","min":1,"max":2,"weight":1},{"id":"increased_gold","min":0.4,"max":0.5,"weight":1}],"rare":[{"id":"chance_to_shred","min":0.08,"max":0.1,"weight":10},{"id":"chance_to_decay","min":0.08,"max":0.1,"weight":10},{"id":"crit_applies_element","min":0.2,"max":0.3,"weight":10},{"id":"crit_applies_penetration","min":0.1,"max":0.15,"weight":10},{"id":"crit_applies_potency","min":0.1,"max":0.15,"weight":10},{"id":"cooldown_reduction","min":0.04,"max":0.08,"weight":8}],"special":[{"id":"double_applied_stacks","value":1,"weight":5},{"id":"ignore_armor_no_shred","value":1,"weight":5},{"id":"ignore_resistance_physical_penalty","value":1,"weight":5}]},"ARMOR":{"basic":[{"id":"percent_physical_damage","min":0.1,"max":0.2,"weight":1},{"id":"crit_chance","min":0.02,"max":0.04,"weight":1},{"id":"percent_elemental_damage","min":0.3,"max":0.4,"weight":1},{"id":"increased_gold","min":0.2,"max":0.3,"weight":1},{"id":"increased_all_stacks","min":1,"max":2,"weight":1}],"rare":[{"id":"chance_to_shred","min":0.08,"max":0.1,"weight":10},{"id":"chance_to_decay","min":0.08,"max":0.1,"weight":10},{"id":"crit_applies_element","min":0.1,"max":0.2,"weight":10},{"id":"crit_applies_penetration","min":0.1,"max":0.15,"weight":10},{"id":"crit_applies_potency","min":0.1,"max":0.15,"weight":10},{"id":"increased_buff_duration","min":0.1,"max":0.2,"weight":8}],"special":[{"id":"all_stats_increased","value":1,"weight":5},{"id":"disable_enemy_dodge","value":1,"weight":10},{"id":"disable_enemy_block","value":1,"weight":10},{"id":"disable_enemy_absorb","value":1,"weight":10},{"id":"disable_enemy_suppress","value":1,"weight":10},{"id":"disable_enemy_cleanse","value":1,"weight":10},{"id":"immune_to_stun","value":1,"weight":5},{"id":"immune_to_slow","value":1,"weight":5},{"id":"immune_to_interrupt","value":1,"weight":5},{"id":"inventory_economy_stats","value":1,"weight":5}]},"TRINKET":{"basic":[{"id":"base_damage","min":4,"max":6,"weight":1},{"id":"percent_physical_damage","min":0.15,"max":0.25,"weight":1},{"id":"crit_chance","min":0.04,"max":0.06,"weight":1},{"id":"increased_attack_speed","min":0.08,"max":0.1,"weight":1},{"id":"base_elemental_damage","min":5,"max":8,"weight":1},{"id":"percent_elemental_damage","min":0.2,"max":0.3,"weight":1},{"id":"increased_gold","min":0.1,"max":0.2,"weight":1}],"rare":[{"id":"chance_for_retrigger","min":0.03,"max":0.06,"weight":15},{"id":"chance_to_shred","min":0.08,"max":0.1,"weight":10},{"id":"chance_to_decay","min":0.08,"max":0.1,"weight":10},{"id":"crit_applies_element","min":0.1,"max":0.15,"weight":10},{"id":"crit_applies_penetration","min":0.1,"max":0.15,"weight":10},{"id":"crit_applies_potency","min":0.1,"max":0.15,"weight":10},{"id":"increased_buff_duration","min":0.1,"max":0.12,"weight":8}],"special":[{"id":"double_applied_stacks","value":1,"weight":5},{"id":"disable_enemy_dodge","value":1,"weight":10},{"id":"disable_enemy_block","value":1,"weight":10},{"id":"disable_enemy_absorb","value":1,"weight":10},{"id":"disable_enemy_suppress","value":1,"weight":10},{"id":"disable_enemy_cleanse","value":1,"weight":10},{"id":"convert_damage_to_physical","value":1,"weight":5},{"id":"convert_damage_to_magical","value":1,"weight":5}]},"CHARM":{"basic":[{"id":"percent_physical_damage","min":0.15,"max":0.25,"weight":1},{"id":"crit_chance","min":0.06,"max":0.08,"weight":1},{"id":"increased_attack_speed","min":0.1,"max":0.15,"weight":1},{"id":"crit_damage","min":0.4,"max":0.6,"weight":1},{"id":"base_elemental_damage","min":6,"max":10,"weight":1},{"id":"percent_elemental_damage","min":0.3,"max":0.4,"weight":1},{"id":"increased_gold","min":0.15,"max":0.3,"weight":1},{"id":"increased_all_stacks","min":1,"max":2,"weight":1}],"rare":[{"id":"chance_to_shred","min":0.08,"max":0.1,"weight":10},{"id":"chance_to_decay","min":0.08,"max":0.1,"weight":10},{"id":"crit_applies_element","min":0.12,"max":0.18,"weight":15},{"id":"crit_applies_penetration","min":0.1,"max":0.15,"weight":10},{"id":"crit_applies_potency","min":0.1,"max":0.15,"weight":10},{"id":"cooldown_reduction","min":0.06,"max":0.1,"weight":8}],"special":[{"id":"ignore_armor_no_shred","value":1,"weight":5},{"id":"ignore_resistance_physical_penalty","value":1,"weight":5},{"id":"double_applied_stacks","value":1,"weight":5},{"id":"disable_enemy_dodge","value":1,"weight":10},{"id":"disable_enemy_block","value":1,"weight":10},{"id":"disable_enemy_absorb","value":1,"weight":10},{"id":"disable_enemy_suppress","value":1,"weight":10},{"id":"disable_enemy_cleanse","value":1,"weight":10}]}}
var checks := 0

func _initialize() -> void:
	_check_pool()
	_check_cooldowns()
	_check_additive()
	_check_inventory()
	_check_invalid()
	_check_generation()
	print("T3 stat foundation PASS (%d checks)" % checks)
	quit()

func require(value: bool, message: String) -> void:
	checks += 1
	assert(value, message)

func modifier(id: String, value: float) -> StatModifier:
	var m := StatModifier.new()
	m.stat_id = id
	m.value = value
	m.operation = StatModifier.OperationType.ADD
	m.category = StatModifier.StatCategory.RARE
	return m

func item(slot: int, mods: Array) -> GearItem:
	var g := GearItem.new()
	g.id = "same.saved.id"
	g.slot = slot
	for m in mods:
		g.affixes.append(m)
	return g

func _check_pool() -> void:
	var count := 0
	var drawbacks := 0
	for slot in range(5):
		var key: String = ["WEAPON", "TRINKET", "CHARM", "HELM", "ARMOR"][slot]
		for category in ["basic", "rare", "special"]:
			var actual := StatCatalog.pool_for_slot(slot, category)
			var rows: Array = EXPECTED[key][category]
			require(actual.size() == rows.size(), "Exact category size")
			for index in range(rows.size()):
				var row: Dictionary = rows[index]
				require(actual[index].stat_id == row.id and actual[index].weight == row.weight, "Exact pool order, IDs, weights")
				if category != "special":
					var bounds := StatCatalog.value_range_for_slot_category(slot, category, row.id)
					require(bounds.ok and bounds.min == float(row.min) and bounds.max == float(row.max), "Exact numeric range")
			count += rows.size()
		var drawback := StatCatalog.drawback_pool_for_slot(slot)
		require(drawback == StatCatalog.pool_for_slot(slot, "basic"), "All Basic rows and only Basic rows are drawbacks")
		drawbacks += drawback.size()
	require(count == 99 and drawbacks == 33, "99 positive, 33 drawbacks")

func _check_cooldowns() -> void:
	var a := item(0, [modifier("cooldown_reduction", .2), modifier("cooldown_reduction", .3)])
	var b := item(2, [modifier("all_stats_increased", 1.0)])
	var sheet = BuildResolver.resolve_gear_stat_sheet([b, a])
	require(is_equal_approx(sheet.cooldown_factor, .76 * .64), "Multiply separate affixes after All Stats")
	require(is_equal_approx(sheet.value_for("cooldown_reduction"), 1.0 - .76 * .64), "Value lookup is effective CDR")
	require(sheet.value_for_raw("cooldown_reduction") == .5, "Raw sum is inspection only")
	require(sheet.cooldown_contributions[0].source_slot == 0 and sheet.cooldown_contributions[1].affix_index == 1, "Ordered source ledger")
	var reversed: Array[GearItem] = []
	for slot in [GearItem.SlotType.CHARM, GearItem.SlotType.TRINKET, GearItem.SlotType.ARMOR, GearItem.SlotType.HELM, GearItem.SlotType.WEAPON]:
		reversed.append(item(slot, [modifier("cooldown_reduction", .1)]))
	var ordered = BuildResolver.resolve_gear_stat_sheet(reversed)
	for index in range(5):
		require(ordered.cooldown_contributions[index].source_slot == GearItem.universal_slot_order()[index], "Display slot order overrides numeric enum and caller order")
	var gear: Array[GearItem] = []
	for pair in [[0, .24], [1, .32], [4, .41]]:
		gear.append(item(pair[0], [modifier("cooldown_reduction", pair[1]), modifier("cooldown_reduction", pair[1]), modifier("cooldown_reduction", pair[1]), modifier("cooldown_reduction", pair[1])]))
	gear.append(b)
	var stats := BuildResolver.resolve_stats(null, [], [], gear)
	require(stats.derivation_error == "", "Accepted extreme resolves")
	require(absf(stats.cooldown_factor - pow(.712, 4) * pow(.616, 4) * pow(.508, 4)) < 1e-12, "Accepted 99.7536% endpoint")
	require(int(ceil(10000 * stats.cooldown_factor)) == 25, "10 second cooldown becomes 25 ms")
	var state := State.new(stats)
	var temporary: Array[StatModifier] = [modifier("increased_attack_speed", .1)]
	require(state.replace_source("temp", "test", temporary, 0) == "", "Temporary rebuild")
	var copy := state.snapshot()
	require(copy.cooldown_factor == stats.cooldown_factor and copy.derivation_base.cooldown_factor == stats.cooldown_factor, "Rebuild and derivation clone preserve factor exactly")
	for value in [1.0, 2.0, 1e307]:
		sheet = BuildResolver.resolve_gear_stat_sheet([item(0, [modifier("cooldown_reduction", value)]), b])
		require(sheet.validation_error == "" and sheet.cooldown_factor == 0.0, "Saturate each large finite factor without overflow")

func _check_additive() -> void:
	var gear: Array[GearItem] = [item(0, [modifier("increased_buff_duration", 4), modifier("increased_buff_duration", 3.48), modifier("crit_applies_penetration", .6), modifier("crit_applies_potency", 2)])]
	var stats := BuildResolver.resolve_stats(null, [], [], gear)
	require(is_equal_approx(stats.increased_buff_duration, 7.48), "Uncapped additive duration")
	require(stats.crit_applies_penetration == .6 and stats.crit_applies_potency == 1.0, "Independent probability caps")
	gear.append(item(2, [modifier("all_stats_increased", 1)]))
	stats = BuildResolver.resolve_stats(null, [], [], gear)
	require(is_equal_approx(stats.increased_buff_duration, 7.48 * 1.2), "All Stats applies once without second rounding")
	require(is_equal_approx(stats.crit_applies_penetration, .72), "All Stats proc probability")
	var state := State.new(stats)
	var temporary: Array[StatModifier] = [modifier("increased_attack_speed", .1)]
	require(state.replace_source("temp", "test", temporary, 0) == "", "Temporary stat source")
	var rebuilt := state.snapshot()
	require(rebuilt.increased_buff_duration == stats.increased_buff_duration and rebuilt.crit_applies_penetration == stats.crit_applies_penetration, "Static fields preserved")

func _check_inventory() -> void:
	var activation := item(2, [modifier("inventory_economy_stats", 1), modifier("all_stats_increased", 1), modifier("increased_gold", -.4)])
	var carried := item(0, [modifier("gold_rewards", .5), modifier("shop_discount", -.1), modifier("increased_magic_find", .2), modifier("base_damage", 999), modifier("cooldown_reduction", .9), modifier("all_stats_increased", 1)])
	var copies: Array[GearItem] = [carried, carried]
	var stats := BuildResolver.resolve_stats(null, [], [], [activation], 0, copies)
	require(is_equal_approx(stats.gold_reward_multiplier, 1.72), "Raw signed contributions combine before floor and All Stats")
	require(stats.shop_discount == 0 and is_equal_approx(stats.magic_find, .48), "Economy sign/floor and cached occurrence copies")
	require(stats.bonus_physical_damage == 0 and stats.cooldown_factor == 1, "Inventory excludes combat and timing")
	var sheet = BuildResolver.resolve_gear_stat_sheet([activation], copies)
	var count := 0
	for source in sheet.contribution_sources:
		if source.source_kind == "carried":
			count += 1
	require(count == 6, "Each inventory index traversed once, three economy sources each")
	stats = BuildResolver.resolve_stats(null, [], [], [], 0, copies)
	require(stats.gold_reward_multiplier == 1 and stats.magic_find == 0 and stats.special_stat_ids.is_empty(), "Inventory cannot activate itself")
	# Legacy states above acquisition capacity remain authoritative.
	copies.append(carried)
	copies.append(carried)
	stats = BuildResolver.resolve_stats(null, [], [], [activation], 0, copies)
	require(is_equal_approx(stats.magic_find, .96), "No silent truncation above three carried occurrences")

func _check_invalid() -> void:
	for id in ["cooldown_reduction", "increased_buff_duration", "crit_applies_penetration", "crit_applies_potency", "inventory_economy_stats"]:
		for value in [-.1, NAN, INF]:
			var stats := BuildResolver.resolve_stats(null, [], [], [item(0, [modifier(id, value)])])
			require(stats.derivation_error != "", "Invalid new stat rejected")
		var carried: Array[GearItem] = [item(0, [modifier(id, -.1)])]
		var carried_stats := BuildResolver.resolve_stats(null, [], [], [], 0, carried)
		require(carried_stats.derivation_error != "", "Inactive carried new modifier still requires valid domain")
		var m := modifier(id, 1)
		m.operation = StatModifier.OperationType.MULTIPLY
		require(StatCatalog.modifier_validation_error(m) != "", "New stat ADD only")
		m.operation = StatModifier.OperationType.ADD
		m.is_drawback = true
		require(StatCatalog.modifier_validation_error(m) != "", "New stat cannot be drawback")
	require(StatCatalog.modifier_validation_error(modifier("inventory_economy_stats", 0)) != "", "New Special binary")
	var stats := BuildResolver.resolve_stats(null, [], [], [item(0, [modifier("increased_buff_duration", 1e308), modifier("increased_buff_duration", 1e308)])])
	require(stats.derivation_error != "", "Overflow raw sum fails")
	stats = BuildResolver.resolve_stats(null, [], [], [item(0, [modifier("increased_buff_duration", 1e307)])])
	require(stats.derivation_error != "", "Finite but unrepresentable timer fails preview")

func _check_generation() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 14523
	for scale in [NAN, INF, 0, -1]:
		var result := GearGenerator.generate_from_request({"tier": GearItem.Tier.EPIC, "slot": 0, "rng": rng, "value_scale": scale})
		require(not result.ok and result.errors.has("invalid_value_scale"), "Nonfinite/nonpositive scale rejected")
	var failed := GearGenerator._roll_value_for_stat_id("base_damage", 0, false, GearItem.Tier.CHAOS, rng, 1e308)
	require(not failed.ok, "Non-finite generated result fails deterministically")
	for slot in range(5):
		for category in ["basic", "rare"]:
			for row in EXPECTED[["WEAPON", "TRINKET", "CHARM", "HELM", "ARMOR"][slot]][category]:
				for depth in [1, 12]:
					var result := GearGenerator.max_rolled_value_for_stat_id(row.id, slot, false, GearItem.Tier.CHAOS, 1, depth, category)
					require(result.ok and is_finite(result.value), "Every numeric new-pool endpoint generates")
