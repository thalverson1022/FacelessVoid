class_name StatSheet
extends Resource

const StatCatalog := preload("res://scripts/systems/stat_catalog.gd")

@export var raw_values: Dictionary = {}
@export var values: Dictionary = {}
@export var modifier_counts: Dictionary = {}
@export var special_stat_ids: Array[String] = []
@export var legacy_poison_damage_multiplier: float = 1.0
@export var legacy_poison_tick_interval_multiplier: float = 1.0


## Raw sums are inspection only for CDR; cooldown_factor is the scheduler input.
@export var cooldown_contributions: Array[Dictionary] = []
@export var contribution_sources: Array[Dictionary] = []
@export var cooldown_factor: float = 1.0
var validation_error: String = ""
var _dirty := true


func add_gear_collection(equipped_gear: Array) -> void:
	# Display equipment order, independent of caller array order. Do not deduplicate
	# resources: each authoritative collection occurrence is an owned copy.
	var ordered := equipped_gear.duplicate()
	ordered.sort_custom(func(a, b): return a != null and (b == null or GearItem.universal_slot_order().find(a.slot) < GearItem.universal_slot_order().find(b.slot)))
	for gear in ordered:
		add_gear(gear)


func add_gear(gear: GearItem, source_kind: String = "equipped", source_index: int = -1, economy_only: bool = false) -> void:
	if gear == null:
		return
	for index in range(gear.affixes.size()):
		var modifier: StatModifier = gear.affixes[index]
		if modifier == null:
			continue
		var id := StatCatalog.canonical_id_for_modifier(modifier)
		if economy_only and id not in [StatCatalog.INCREASED_GOLD, StatCatalog.SHOP_DISCOUNT, StatCatalog.INCREASED_MAGIC_FIND]:
			continue
		add_modifier(modifier, {"source_kind": source_kind, "source_slot": gear.slot,
			"source_item": gear.id, "source_index": source_index, "affix_index": index})


func add_carried_economy(carried_gear: Array) -> void:
	for index in range(carried_gear.size()):
		var gear: GearItem = carried_gear[index]
		if gear == null:
			continue
		# Domain validity belongs to owned gear even when its stats are inactive.
		for modifier in gear.affixes:
			var problem := StatCatalog.modifier_validation_error(modifier)
			if problem != "":
				validation_error = problem
				return
		if has_special(StatCatalog.INVENTORY_ECONOMY_STATS):
			add_gear(gear, "carried", index, true)


func add_modifier(modifier: StatModifier, source: Dictionary = {}) -> void:
	if modifier == null or validation_error != "":
		return
	validation_error = StatCatalog.modifier_validation_error(modifier)
	if validation_error != "":
		return
	var stat_id := StatCatalog.canonical_id_for_modifier(modifier)
	if stat_id == "" or not StatCatalog.has_stat(stat_id):
		return
	_dirty = true
	if StatCatalog.is_binary(stat_id):
		if not special_stat_ids.has(stat_id):
			special_stat_ids.append(stat_id)
		modifier_counts[stat_id] = count_for(stat_id) + 1
		return
	if not StatCatalog.is_numeric(stat_id):
		return
	if not is_finite(modifier.value):
		validation_error = "Non-finite gear contribution: " + stat_id
		return
	if _is_legacy_poison_damage_multiplier(modifier):
		legacy_poison_damage_multiplier *= modifier.value
		if not is_finite(legacy_poison_damage_multiplier):
			validation_error = "Non-finite legacy Poison multiplier."
		modifier_counts[stat_id] = count_for(stat_id) + 1
		return
	if _is_legacy_poison_tick_interval_multiplier(modifier):
		legacy_poison_tick_interval_multiplier *= modifier.value
		if not is_finite(legacy_poison_tick_interval_multiplier):
			validation_error = "Non-finite legacy Poison interval."
		modifier_counts[stat_id] = count_for(stat_id) + 1
		return
	var contribution := _modifier_contribution(modifier)
	var raw_sum := value_for_raw(stat_id) + contribution
	if not is_finite(raw_sum):
		validation_error = "Non-finite raw stat sum: " + stat_id
		return
	raw_values[stat_id] = raw_sum
	modifier_counts[stat_id] = count_for(stat_id) + 1
	var record := source.duplicate(true)
	record.merge({"stat_id": stat_id, "raw_value": contribution, "operation": modifier.operation}, true)
	contribution_sources.append(record)
	if stat_id == StatCatalog.COOLDOWN_REDUCTION:
		cooldown_contributions.append(record.duplicate(true))
	values.clear()


func finalize() -> void:
	values.clear()
	cooldown_factor = 1.0
	if validation_error != "":
		return
	var multiplier := all_stats_multiplier()
	for id in raw_values.keys():
		var stat_id := String(id)
		if stat_id == StatCatalog.COOLDOWN_REDUCTION:
			continue
		var final_value := float(raw_values[stat_id])
		var floor_value := StatCatalog.floor_for(stat_id)
		if floor_value != StatCatalog.FLOOR_NONE:
			final_value = maxf(final_value, floor_value)
		if multiplier != 1.0 and StatCatalog.scales_with_all_stats(stat_id):
			final_value *= multiplier
		if not is_finite(final_value):
			validation_error = "Non-finite effective stat: " + stat_id
			return
		var cap_value := StatCatalog.cap_for(stat_id)
		if cap_value != StatCatalog.CAP_NONE:
			final_value = minf(final_value, cap_value)
		values[stat_id] = final_value
	for entry in cooldown_contributions:
		var raw: float = entry.raw_value
		# Compare first so arbitrarily large finite raw inputs cannot overflow.
		var effective := 1.0 if raw >= 1.0 / multiplier else raw * multiplier
		entry["all_stats_multiplier"] = multiplier
		entry["effective_reduction"] = effective
		entry["retained_factor"] = 1.0 - effective
		cooldown_factor *= 1.0 - effective
	values[StatCatalog.COOLDOWN_REDUCTION] = 1.0 - cooldown_factor
	special_stat_ids.sort()
	_dirty = false


func value_for(stat_id: String, default_value: float = 0.0) -> float:
	_ensure_finalized()
	var canonical_id := StatCatalog.canonicalize_stat_id(stat_id)
	return float(values.get(canonical_id, default_value))


func value_for_raw(stat_id: String, default_value: float = 0.0) -> float:
	var canonical_id := StatCatalog.canonicalize_stat_id(stat_id)
	return float(raw_values.get(canonical_id, default_value))


func count_for(stat_id: String) -> int:
	var canonical_id := StatCatalog.canonicalize_stat_id(stat_id)
	return int(modifier_counts.get(canonical_id, 0))


func has_special(stat_id: String) -> bool:
	return special_stat_ids.has(StatCatalog.canonicalize_stat_id(stat_id))


func active_specials() -> Array[String]:
	return special_stat_ids.duplicate()


func special_effect_summary() -> Dictionary:
	return {
		"enemy_denial": {
			"dodge": denies_enemy_dodge(),
			"block": denies_enemy_block(),
			"absorb": denies_enemy_absorb(),
			"suppress": denies_enemy_suppress(),
			"cleanse": denies_enemy_cleanse(),
		},
		"ignore_armor_no_shred": ignores_armor_without_shred(),
		"ignore_resistance_physical_penalty": ignores_resistance_with_physical_penalty(),
		"physical_damage_penalty": physical_damage_penalty(),
		"double_applied_stacks": doubles_applied_stacks(),
		"damage_conversion": {
			"physical": converts_damage_to_physical(),
			"magical": converts_damage_to_magical(),
		},
		"all_stats_increased": has_all_stats_increased(),
		"inventory_economy_stats": has_special(StatCatalog.INVENTORY_ECONOMY_STATS),
		"all_stats_multiplier": all_stats_multiplier(),
		"immunities": {
			"stun": immune_to_stun(),
			"slow": immune_to_slow(),
			"interrupt": immune_to_interrupt(),
		},
		"decay_applies_shred": decay_applies_shred(),
		"poison_stack_cap": poison_stack_cap(),
	}


func base_damage() -> float:
	return value_for(StatCatalog.BASE_DAMAGE)


func percent_physical_damage() -> float:
	return value_for(StatCatalog.PERCENT_PHYSICAL_DAMAGE)


func increased_attack_speed() -> float:
	return value_for(StatCatalog.INCREASED_ATTACK_SPEED)


func crit_chance() -> float:
	return value_for(StatCatalog.CRIT_CHANCE)


func crit_damage() -> float:
	return value_for(StatCatalog.CRIT_DAMAGE)


func base_elemental_damage() -> float:
	return value_for(StatCatalog.BASE_ELEMENTAL_DAMAGE)


func percent_elemental_damage() -> float:
	return value_for(StatCatalog.PERCENT_ELEMENTAL_DAMAGE)


func increased_all_stacks() -> int:
	return int(round(value_for(StatCatalog.INCREASED_ALL_STACKS)))


func shred_value() -> int:
	return int(round(value_for(StatCatalog.SHRED_VALUE)))


func bonus_shred_stacks() -> int:
	return int(round(value_for(StatCatalog.BONUS_SHRED_STACKS)))


func decay_value() -> float:
	return value_for(StatCatalog.DECAY_VALUE)


func increased_shred_stacks() -> int:
	return increased_all_stacks()


func increased_decay_stacks() -> int:
	return increased_all_stacks()


func increased_elemental_stacks() -> int:
	return increased_all_stacks()


func increased_gold() -> float:
	return value_for(StatCatalog.INCREASED_GOLD)


func shop_discount() -> float:
	return value_for(StatCatalog.SHOP_DISCOUNT)


func increased_magic_find() -> float:
	return value_for(StatCatalog.INCREASED_MAGIC_FIND)


func chance_for_retrigger() -> float:
	return value_for(StatCatalog.CHANCE_FOR_RETRIGGER)


func chance_to_shred() -> float:
	return value_for(StatCatalog.CHANCE_TO_SHRED)


func chance_to_decay() -> float:
	return value_for(StatCatalog.CHANCE_TO_DECAY)


func crit_applies_element() -> float:
	return value_for(StatCatalog.CRIT_APPLIES_ELEMENT)


func denies_enemy_dodge() -> bool:
	return has_special(StatCatalog.DISABLE_ENEMY_DODGE)


func denies_enemy_block() -> bool:
	return has_special(StatCatalog.DISABLE_ENEMY_BLOCK)


func denies_enemy_absorb() -> bool:
	return has_special(StatCatalog.DISABLE_ENEMY_ABSORB)


func denies_enemy_suppress() -> bool:
	return has_special(StatCatalog.DISABLE_ENEMY_SUPPRESS)


func denies_enemy_cleanse() -> bool:
	return has_special(StatCatalog.DISABLE_ENEMY_CLEANSE)


func ignores_armor_without_shred() -> bool:
	return has_special(StatCatalog.IGNORE_ARMOR_NO_SHRED)


func ignores_resistance_with_physical_penalty() -> bool:
	return has_special(StatCatalog.IGNORE_RESISTANCE_PHYSICAL_PENALTY)


func physical_damage_penalty() -> float:
	if not ignores_resistance_with_physical_penalty():
		return 1.0
	var def := StatCatalog.definition(StatCatalog.IGNORE_RESISTANCE_PHYSICAL_PENALTY)
	return float((def.get("fixed_constants", {}) as Dictionary).get("physical_damage_penalty", 1.0))


func doubles_applied_stacks() -> bool:
	return has_special(StatCatalog.DOUBLE_APPLIED_STACKS)


func converts_damage_to_physical() -> bool:
	return has_special(StatCatalog.CONVERT_DAMAGE_TO_PHYSICAL)


func converts_damage_to_magical() -> bool:
	return has_special(StatCatalog.CONVERT_DAMAGE_TO_MAGICAL)


func has_all_stats_increased() -> bool:
	return has_special(StatCatalog.ALL_STATS_INCREASED)


func all_stats_multiplier() -> float:
	if not has_all_stats_increased():
		return 1.0
	var def := StatCatalog.definition(StatCatalog.ALL_STATS_INCREASED)
	return float((def.get("fixed_constants", {}) as Dictionary).get("stat_sheet_multiplier", 1.0))


func immune_to_stun() -> bool:
	return has_special(StatCatalog.IMMUNE_TO_STUN)


func immune_to_slow() -> bool:
	return has_special(StatCatalog.IMMUNE_TO_SLOW)


func immune_to_interrupt() -> bool:
	return has_special(StatCatalog.IMMUNE_TO_INTERRUPT)


func decay_applies_shred() -> bool:
	return has_special(StatCatalog.DECAY_APPLIES_SHRED)


func poison_stack_cap() -> int:
	if not has_special(StatCatalog.POISON_STACK_CAP_40):
		return 20
	var def := StatCatalog.definition(StatCatalog.POISON_STACK_CAP_40)
	return int((def.get("fixed_constants", {}) as Dictionary).get("poison_stack_cap", 40))


func apply_to_player_stats(stats: PlayerStats) -> void:
	if stats == null:
		return
	_ensure_finalized()
	if validation_error != "":
		stats.derivation_error = validation_error
		return
	stats.cooldown_factor = cooldown_factor
	stats.cooldown_reduction = value_for(StatCatalog.COOLDOWN_REDUCTION)
	stats.increased_buff_duration = value_for(StatCatalog.INCREASED_BUFF_DURATION)
	stats.crit_applies_penetration = value_for(StatCatalog.CRIT_APPLIES_PENETRATION)
	stats.crit_applies_potency = value_for(StatCatalog.CRIT_APPLIES_POTENCY)
	stats.bonus_physical_damage += base_damage()
	stats.gear_physical_damage_multiplier = stats.gear_physical_damage_multiplier + percent_physical_damage()
	stats.physical_damage_uses_buckets = true
	stats.sync_physical_damage_multiplier()
	stats.attack_speed = stats.attack_speed + increased_attack_speed()
	stats.crit_chance = maxf(0.0, stats.crit_chance + value_for_raw(StatCatalog.CRIT_CHANCE) * all_stats_multiplier()) if stats.legendary_signet else clampf(stats.crit_chance + crit_chance(), 0.0, 1.0)
	stats.crit_multiplier = maxf(1.0, stats.crit_multiplier + crit_damage())
	stats.gear_elemental_damage_multiplier = stats.gear_elemental_damage_multiplier + percent_elemental_damage()
	stats.sync_elemental_damage_multiplier()
	stats.bonus_base_elemental_damage = stats.bonus_base_elemental_damage + base_elemental_damage()
	stats.base_poison_damage = maxf(0.0, stats.base_poison_damage * legacy_poison_damage_multiplier)
	stats.sync_poison_damage_per_tick()
	stats.poison_tick_interval_multiplier = maxf(0.05, stats.poison_tick_interval_multiplier * legacy_poison_tick_interval_multiplier)
	var stack_bonus := increased_all_stacks()
	stats.bonus_footwork_stacks = max(0, stats.bonus_footwork_stacks + stack_bonus)
	stats.bonus_bypass_stacks = max(0, stats.bonus_bypass_stacks + stack_bonus)
	stats.bonus_armor_reduction = max(0, stats.bonus_armor_reduction + stack_bonus)
	stats.bonus_poison_stacks = max(0, stats.bonus_poison_stacks + stack_bonus)
	stats.bonus_decay_stacks = max(0, stats.bonus_decay_stacks + stack_bonus)
	stats.bonus_penetration_stacks = max(0, stats.bonus_penetration_stacks + stack_bonus)
	stats.bonus_potency_stacks = max(0, stats.bonus_potency_stacks + stack_bonus)
	stats.bonus_shred_stacks = max(0, stats.bonus_shred_stacks + stack_bonus)
	stats.shred_value = max(0, stats.shred_value + shred_value())
	stats.bonus_shred_stacks = max(0, stats.bonus_shred_stacks + bonus_shred_stacks())
	stats.decay_value = maxf(0.0, stats.decay_value + decay_value())
	stats.retrigger_chance = clampf(stats.retrigger_chance + chance_for_retrigger(), 0.0, 1.0)
	stats.shred_chance = clampf(stats.shred_chance + chance_to_shred(), 0.0, 1.0)
	stats.decay_chance = clampf(stats.decay_chance + chance_to_decay(), 0.0, 1.0)
	stats.elemental_proc_chance = clampf(stats.elemental_proc_chance + crit_applies_element(), 0.0, 1.0)
	stats.gold_reward_multiplier = maxf(0.0, stats.gold_reward_multiplier + increased_gold())
	stats.shop_discount = maxf(0.0, stats.shop_discount + shop_discount())
	stats.magic_find = maxf(0.0, stats.magic_find + increased_magic_find())
	stats.poison_tick_interval_multiplier = maxf(0.05, stats.poison_tick_interval_multiplier + value_for(StatCatalog.LEGACY_POISON_TICK_INTERVAL))
	stats.crit_chance_per_stolen_gold = clampf(stats.crit_chance_per_stolen_gold + value_for(StatCatalog.LEGACY_CRIT_CHANCE_PER_STOLEN_GOLD), 0.0, 1.0)
	stats.crit_multiplier_per_current_gold = maxf(0.0, stats.crit_multiplier_per_current_gold + value_for(StatCatalog.LEGACY_CRIT_DAMAGE_PER_CURRENT_GOLD))
	var merged_special_ids := stats.special_stat_ids.duplicate()
	for stat_id in active_specials():
		if not merged_special_ids.has(stat_id):
			merged_special_ids.append(stat_id)
	stats.special_stat_ids = merged_special_ids
	var merged_specials := stats.special_effects.duplicate(true)
	_merge_special_summary(merged_specials, special_effect_summary())
	stats.special_effects = merged_specials
	stats.poison_stack_cap = maxi(stats.poison_stack_cap, poison_stack_cap())


func _merge_special_summary(target: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		var source_value = source[key]
		if source_value is Dictionary:
			var target_value: Dictionary = target.get(key, {})
			if not (target_value is Dictionary):
				target_value = {}
			_merge_special_summary(target_value, source_value)
			target[key] = target_value
		elif source_value is bool:
			target[key] = bool(target.get(key, false)) or bool(source_value)
		elif key == "poison_stack_cap":
			target[key] = maxi(int(target.get(key, 20)), int(source_value))
		else:
			target[key] = source_value


func _modifier_contribution(modifier: StatModifier) -> float:
	if modifier.operation == StatModifier.OperationType.MULTIPLY:
		return modifier.value - 1.0
	return modifier.value


func _is_legacy_poison_damage_multiplier(modifier: StatModifier) -> bool:
	return (
		modifier.stat_id.strip_edges() == ""
		and modifier.stat == StatModifier.StatType.POISON_DAMAGE
		and modifier.operation == StatModifier.OperationType.MULTIPLY
	)


func _is_legacy_poison_tick_interval_multiplier(modifier: StatModifier) -> bool:
	return (
		modifier.stat_id.strip_edges() == ""
		and modifier.stat == StatModifier.StatType.POISON_TICK_INTERVAL
		and modifier.operation == StatModifier.OperationType.MULTIPLY
	)


func _ensure_finalized() -> void:
	if _dirty:
		finalize()
