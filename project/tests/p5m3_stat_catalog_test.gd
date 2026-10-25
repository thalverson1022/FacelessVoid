extends SceneTree
## Focused P5M3-T3 check for the canonical Phase 5 stat vocabulary.

const StatCatalog := preload("res://scripts/systems/stat_catalog.gd")


func _init() -> void:
	print("-- P5M3 stat catalog --")
	_check_required_stat_ids()
	_check_metadata_rules()
	_check_legacy_modifier_mapping()
	_check_display_helpers()
	print("P5M3 stat catalog check: OK")
	quit(0)


func _check_required_stat_ids() -> void:
	var required: Array[String] = []
	required.append_array([
		StatCatalog.BASE_DAMAGE,
		StatCatalog.PERCENT_PHYSICAL_DAMAGE,
		StatCatalog.INCREASED_ATTACK_SPEED,
		StatCatalog.CRIT_CHANCE,
		StatCatalog.CRIT_DAMAGE,
		StatCatalog.BASE_ELEMENTAL_DAMAGE,
		StatCatalog.PERCENT_ELEMENTAL_DAMAGE,
		StatCatalog.INCREASED_ALL_STACKS,
		StatCatalog.SHRED_VALUE,
		StatCatalog.BONUS_SHRED_STACKS,
		StatCatalog.INCREASED_GOLD,
		StatCatalog.SHOP_DISCOUNT,
		StatCatalog.INCREASED_MAGIC_FIND,
	])
	required.append_array([
		StatCatalog.CHANCE_FOR_RETRIGGER,
		StatCatalog.CHANCE_TO_SHRED,
		StatCatalog.CHANCE_TO_DECAY,
		StatCatalog.CRIT_APPLIES_ELEMENT,
	])
	required.append_array([
		StatCatalog.DISABLE_ENEMY_DODGE,
		StatCatalog.DISABLE_ENEMY_BLOCK,
		StatCatalog.DISABLE_ENEMY_ABSORB,
		StatCatalog.DISABLE_ENEMY_SUPPRESS,
		StatCatalog.DISABLE_ENEMY_CLEANSE,
		StatCatalog.IGNORE_ARMOR_NO_SHRED,
		StatCatalog.IGNORE_RESISTANCE_PHYSICAL_PENALTY,
		StatCatalog.DOUBLE_APPLIED_STACKS,
		StatCatalog.CONVERT_DAMAGE_TO_PHYSICAL,
		StatCatalog.CONVERT_DAMAGE_TO_MAGICAL,
		StatCatalog.ALL_STATS_INCREASED,
		StatCatalog.IMMUNE_TO_STUN,
		StatCatalog.IMMUNE_TO_SLOW,
		StatCatalog.IMMUNE_TO_INTERRUPT,
		StatCatalog.DECAY_APPLIES_SHRED,
		StatCatalog.POISON_STACK_CAP_40,
	])
	for stat_id in required:
		_require(StatCatalog.has_stat(stat_id), "Expected canonical stat id: %s." % stat_id)
		_require(StatCatalog.label_for(stat_id) != "", "Expected label for stat id: %s." % stat_id)

	_require(StatCatalog.ids_for_category(StatCatalog.CATEGORY_BASIC).size() == 13, "Expected 13 Basic stat ids.")
	_require(StatCatalog.ids_for_category(StatCatalog.CATEGORY_RARE).size() == 11, "Expected 11 Rare stat ids.")
	_require(StatCatalog.ids_for_category(StatCatalog.CATEGORY_SPECIAL).size() == 17, "Expected 17 Special stat ids.")


func _check_metadata_rules() -> void:
	for stat_id in StatCatalog.ids_for_category(StatCatalog.CATEGORY_BASIC):
		_require(StatCatalog.is_numeric(stat_id), "Expected Basic stat to be numeric: %s." % stat_id)
		_require(not StatCatalog.is_binary(stat_id), "Expected Basic stat not to be binary: %s." % stat_id)
		_require(StatCatalog.aggregation_for(stat_id) == StatCatalog.AGGREGATE_ADDITIVE, "Expected Basic additive aggregation: %s." % stat_id)
		if [
			StatCatalog.BASE_DAMAGE,
			StatCatalog.PERCENT_PHYSICAL_DAMAGE,
			StatCatalog.INCREASED_ATTACK_SPEED,
			StatCatalog.CRIT_DAMAGE,
			StatCatalog.BASE_ELEMENTAL_DAMAGE,
			StatCatalog.PERCENT_ELEMENTAL_DAMAGE,
		].has(stat_id):
			_require(StatCatalog.floor_for(stat_id) == StatCatalog.FLOOR_NONE, "Expected Basic stat to preserve negative modifier totals: %s." % stat_id)
		else:
			_require(StatCatalog.floor_for(stat_id) == StatCatalog.FLOOR_ZERO, "Expected Basic non-negative floor: %s." % stat_id)
		_require(StatCatalog.is_drawback_allowed(stat_id), "Expected Basic stat to allow drawbacks: %s." % stat_id)

	for stat_id in StatCatalog.ids_for_category(StatCatalog.CATEGORY_RARE):
		_require(StatCatalog.is_numeric(stat_id), "Expected Rare stat to be numeric: %s." % stat_id)
		if [StatCatalog.INCREASED_GOLD, StatCatalog.SHOP_DISCOUNT, StatCatalog.INCREASED_MAGIC_FIND].has(stat_id):
			_require(StatCatalog.value_kind_for(stat_id) == StatCatalog.VALUE_PERCENT, "Expected Rare economy stat to be percent-valued: %s." % stat_id)
			_require(StatCatalog.cap_for(stat_id) == StatCatalog.CAP_NONE, "Expected Rare economy stat to have no generic cap: %s." % stat_id)
			_require(StatCatalog.is_drawback_allowed(stat_id), "Expected duplicated economy stat to allow Chaos drawbacks through its Basic pool: %s." % stat_id)
		else:
			_require(StatCatalog.is_chance_stat(stat_id), "Expected Rare combat stat to be chance-valued: %s." % stat_id)
			_require(StatCatalog.cap_for(stat_id) == StatCatalog.CAP_CHANCE, "Expected Rare chance cap at 100%%: %s." % stat_id)
			_require(not StatCatalog.is_drawback_allowed(stat_id), "Expected Rare combat drawbacks to be deferred: %s." % stat_id)

	for stat_id in StatCatalog.ids_for_category(StatCatalog.CATEGORY_SPECIAL):
		_require(StatCatalog.is_special(stat_id), "Expected Special category: %s." % stat_id)
		_require(StatCatalog.is_binary(stat_id), "Expected Special to be a binary hook: %s." % stat_id)
		_require(StatCatalog.aggregation_for(stat_id) == StatCatalog.AGGREGATE_BINARY, "Expected Special binary aggregation: %s." % stat_id)
		_require(not StatCatalog.is_drawback_allowed(stat_id), "Expected Special drawbacks to be disabled: %s." % stat_id)

	_require(StatCatalog.is_chance_stat(StatCatalog.CRIT_CHANCE), "Expected Crit Chance to advertise chance value kind.")
	_require(StatCatalog.cap_for(StatCatalog.CRIT_CHANCE) == StatCatalog.CAP_CHANCE, "Expected Crit Chance cap at 100%.")
	_require(not StatCatalog.scales_with_all_stats(StatCatalog.BASE_DAMAGE), "Expected base weapon damage to opt out of all-stats scaling.")
	_require(StatCatalog.scales_with_all_stats(StatCatalog.PERCENT_PHYSICAL_DAMAGE), "Expected percent physical damage to opt into all-stats scaling.")

	var all_stats_def := StatCatalog.definition(StatCatalog.ALL_STATS_INCREASED)
	_require(float((all_stats_def["fixed_constants"] as Dictionary)["stat_sheet_multiplier"]) == 1.2, "Expected all-stats fixed multiplier.")
	var ignore_resist_def := StatCatalog.definition(StatCatalog.IGNORE_RESISTANCE_PHYSICAL_PENALTY)
	_require(float((ignore_resist_def["fixed_constants"] as Dictionary)["physical_damage_penalty"]) == 0.5, "Expected ignore-resistance fixed penalty.")


func _check_legacy_modifier_mapping() -> void:
	var modifier := StatModifier.new()
	modifier.stat = StatModifier.StatType.PHYSICAL_DAMAGE
	_require(
		StatCatalog.canonical_id_for_modifier(modifier) == StatCatalog.PERCENT_PHYSICAL_DAMAGE,
		"Expected legacy physical damage enum to map to percent physical damage."
	)

	modifier.stat = StatModifier.StatType.POISON_DAMAGE
	_require(
		StatCatalog.canonical_id_for_modifier(modifier) == StatCatalog.BASE_ELEMENTAL_DAMAGE,
		"Expected legacy poison damage enum to map to base elemental damage."
	)

	modifier.stat_id = "physical_damage"
	_require(
		StatCatalog.canonical_id_for_modifier(modifier) == StatCatalog.PERCENT_PHYSICAL_DAMAGE,
		"Expected old generated stat_id alias to map to canonical percent physical damage."
	)

	modifier.stat_id = "crit_chance"
	modifier.stat = StatModifier.StatType.ATTACK_SPEED
	_require(
		StatCatalog.canonical_id_for_modifier(modifier) == StatCatalog.CRIT_CHANCE,
		"Expected explicit canonical stat_id to win over legacy enum fallback."
	)

	var lucky_coin: GearItem = load("res://data/gear/lucky_coin.tres")
	_require(lucky_coin != null, "Expected Lucky Coin to load.")
	_require(
		StatCatalog.canonical_id_for_modifier(lucky_coin.affixes[0]) == StatCatalog.CRIT_CHANCE,
		"Expected Lucky Coin to resolve to canonical crit chance."
	)


func _check_display_helpers() -> void:
	_require(StatCatalog.label_for(StatCatalog.BASE_DAMAGE) == "Base Damage", "Expected Base Damage label.")
	_require(StatCatalog.label_for(StatCatalog.CHANCE_FOR_RETRIGGER) == "Chance for Retrigger", "Expected retrigger label.")
	_require(StatCatalog.label_for(StatCatalog.DISABLE_ENEMY_DODGE) == "Enemies can no longer dodge", "Expected denial label.")
	_require(StatCatalog.category_for(StatCatalog.CRIT_APPLIES_ELEMENT) == StatCatalog.CATEGORY_RARE, "Expected Crit Applies Element category.")
	_require(StatCatalog.value_kind_for(StatCatalog.DOUBLE_APPLIED_STACKS) == StatCatalog.VALUE_BINARY, "Expected doubled stacks binary value kind.")


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
