class_name StatModifierFormatter
extends RefCounted
## Shared human-readable formatting for a StatModifier -- used anywhere a
## talent/tree/gear affix needs to show up as text (gear slot listings,
## talent tooltips, subclass level-0 bonus tooltips). Centralized so all
## three read the same way instead of drifting.

const StatCatalog := preload("res://scripts/systems/stat_catalog.gd")

const STAT_NAMES := {
	StatModifier.StatType.ATTACK_SPEED: "Attack Speed",
	StatModifier.StatType.CRIT_CHANCE: "Crit Chance",
	StatModifier.StatType.CRIT_MULTIPLIER: "Crit Multiplier",
	StatModifier.StatType.POISON_DAMAGE: "Poison Damage",
	StatModifier.StatType.PHYSICAL_DAMAGE: "Physical Damage",
	StatModifier.StatType.POISON_STACKS_APPLIED: "Poison Stacks",
	StatModifier.StatType.ARMOR_REDUCTION: "Armor Reduction",
	StatModifier.StatType.GOLD_REWARDS: "Gold Rewards",
	StatModifier.StatType.POISON_TICK_INTERVAL: "Poison Tick Interval",
	StatModifier.StatType.CRIT_CHANCE_PER_STOLEN_GOLD: "Crit Chance per Stolen Gold",
	StatModifier.StatType.CRIT_MULTIPLIER_PER_CURRENT_GOLD: "Crit Damage per Current Gold",
}


static func format(modifier: StatModifier) -> String:
	if modifier == null:
		return ""
	var stat_id := StatCatalog.canonical_id_for_modifier(modifier)
	var stat_name: String = _display_name_for(modifier, stat_id, modifier.stat_id.strip_edges() != "")
	if stat_id in ["crit_applies_penetration", "crit_applies_potency"]:
		return "%+.4f%% chance per critical direct contribution: %s (base 1 stack)" % [modifier.value * 100.0, "Penetration" if stat_id == "crit_applies_penetration" else "Potency"]
	if stat_id == "cooldown_reduction":
		return "%+.4f%% cooldown reduction (per-affix factor %.6f)" % [modifier.value * 100.0, 1.0 - clampf(modifier.value, 0.0, 1.0)]
	if stat_id == "increased_buff_duration":
		return "%+.4f%% timed buff/debuff duration (additive)" % (modifier.value * 100.0)
	if stat_id != "" and StatCatalog.is_binary(stat_id):
		return stat_name
	if stat_id != "" and modifier.stat_id.strip_edges() != "":
		return _format_catalog_value(modifier.value, StatCatalog.value_kind_for(stat_id), stat_name)
	if modifier.operation == StatModifier.OperationType.MULTIPLY:
		return _format_multiplier_percent(modifier.value, stat_name)
	match modifier.stat:
		StatModifier.StatType.ATTACK_SPEED, StatModifier.StatType.CRIT_CHANCE:
			return "%+d%% %s" % [roundi(modifier.value * 100.0), stat_name]
		StatModifier.StatType.CRIT_CHANCE_PER_STOLEN_GOLD:
			return "%+d%% Crit Chance per gold stolen this fight" % roundi(modifier.value * 100.0)
		StatModifier.StatType.CRIT_MULTIPLIER_PER_CURRENT_GOLD:
			return "%+d%% Crit Damage per current gold" % roundi(modifier.value * 100.0)
		StatModifier.StatType.CRIT_MULTIPLIER:
			return "%+d%% Crit Damage" % roundi(modifier.value * 100.0)
		StatModifier.StatType.GOLD_REWARDS:
			return "x%d%% %s" % [roundi(modifier.value * 100.0), stat_name]
		StatModifier.StatType.ARMOR_REDUCTION:
			return "-%d armor" % roundi(absf(modifier.value))
		StatModifier.StatType.POISON_TICK_INTERVAL:
			return "x%.2f %s" % [modifier.value, stat_name]
		_:
			return "%+d %s" % [roundi(modifier.value), stat_name]


static func _format_multiplier_percent(value: float, stat_name: String) -> String:
	var delta_percent := roundi((value - 1.0) * 100.0)
	if delta_percent >= 0:
		return "x%d%% %s" % [delta_percent, stat_name]
	return "%+d%% %s" % [delta_percent, stat_name]


static func _format_catalog_value(value: float, value_kind: String, stat_name: String) -> String:
	match value_kind:
		StatCatalog.VALUE_PERCENT, StatCatalog.VALUE_CHANCE:
			return "%+d%% %s" % [roundi(value * 100.0), stat_name]
		StatCatalog.VALUE_FLAT, StatCatalog.VALUE_STACKS:
			return "%+d %s" % [roundi(value), stat_name]
		StatCatalog.VALUE_MULTIPLIER:
			return _format_multiplier_percent(value, stat_name)
	return "%+d %s" % [roundi(value), stat_name]


static func _display_name_for(modifier: StatModifier, stat_id: String, has_explicit_stat_id: bool) -> String:
	var presentation_names := {
		"base_damage": "base physical damage",
		"percent_physical_damage": "physical damage",
		"base_elemental_damage": "base elemental damage",
		"percent_elemental_damage": "elemental damage",
		"increased_all_stacks": "increased stacks",
	}
	if has_explicit_stat_id and presentation_names.has(stat_id):
		return presentation_names[stat_id]
	if has_explicit_stat_id and stat_id == StatCatalog.SHRED_VALUE:
		return "Bonus Armor Shred"
	if modifier.display_label.strip_edges() != "":
		return modifier.display_label
	if has_explicit_stat_id and stat_id != "" and StatCatalog.has_stat(stat_id):
		return StatCatalog.label_for(stat_id)
	return STAT_NAMES.get(modifier.stat, "?")
