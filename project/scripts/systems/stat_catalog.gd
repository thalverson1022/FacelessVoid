class_name StatCatalog
extends RefCounted

const CATEGORY_BASIC := "basic"
const CATEGORY_RARE := "rare"
const CATEGORY_SPECIAL := "special"
const CATEGORY_COMPATIBILITY := "compatibility"

const VALUE_FLAT := "flat"
const VALUE_PERCENT := "percent"
const VALUE_CHANCE := "chance"
const VALUE_STACKS := "stacks"
const VALUE_BINARY := "binary"
const VALUE_MULTIPLIER := "multiplier"

const AGGREGATE_ADDITIVE := "additive"
const AGGREGATE_BINARY := "binary"
const AGGREGATE_COMPATIBILITY := "compatibility"

const CAP_NONE := -1.0
const CAP_CHANCE := 1.0
const FLOOR_NONE := -INF
const FLOOR_ZERO := 0.0
const DEFAULT_POOL_WEIGHT := 1

const BASE_DAMAGE := "base_damage"
const PERCENT_PHYSICAL_DAMAGE := "percent_physical_damage"
const INCREASED_ATTACK_SPEED := "increased_attack_speed"
const CRIT_CHANCE := "crit_chance"
const CRIT_DAMAGE := "crit_damage"
const BASE_ELEMENTAL_DAMAGE := "base_elemental_damage"
const PERCENT_ELEMENTAL_DAMAGE := "percent_elemental_damage"
const INCREASED_SHRED_STACKS := "increased_shred_stacks"
const INCREASED_DECAY_STACKS := "increased_decay_stacks"
const INCREASED_ELEMENTAL_STACKS := "increased_elemental_stacks"
const INCREASED_ALL_STACKS := "increased_all_stacks"
const SHRED_VALUE := "shred_value"
const BONUS_SHRED_STACKS := "bonus_shred_stacks"
const DECAY_VALUE := "decay_value"
const INCREASED_GOLD := "increased_gold"
const SHOP_DISCOUNT := "shop_discount"
const INCREASED_MAGIC_FIND := "increased_magic_find"

const CHANCE_FOR_RETRIGGER := "chance_for_retrigger"
const CHANCE_TO_SHRED := "chance_to_shred"
const CHANCE_TO_DECAY := "chance_to_decay"
const CRIT_APPLIES_ELEMENT := "crit_applies_element"

const DISABLE_ENEMY_DODGE := "disable_enemy_dodge"
const DISABLE_ENEMY_BLOCK := "disable_enemy_block"
const DISABLE_ENEMY_ABSORB := "disable_enemy_absorb"
const DISABLE_ENEMY_SUPPRESS := "disable_enemy_suppress"
const DISABLE_ENEMY_CLEANSE := "disable_enemy_cleanse"
const IGNORE_ARMOR_NO_SHRED := "ignore_armor_no_shred"
const IGNORE_RESISTANCE_PHYSICAL_PENALTY := "ignore_resistance_physical_penalty"
const DOUBLE_APPLIED_STACKS := "double_applied_stacks"
const CONVERT_DAMAGE_TO_PHYSICAL := "convert_damage_to_physical"
const CONVERT_DAMAGE_TO_MAGICAL := "convert_damage_to_magical"
const ALL_STATS_INCREASED := "all_stats_increased"
const IMMUNE_TO_STUN := "immune_to_stun"
const IMMUNE_TO_SLOW := "immune_to_slow"
const IMMUNE_TO_INTERRUPT := "immune_to_interrupt"
const DECAY_APPLIES_SHRED := "decay_applies_shred"
const POISON_STACK_CAP_40 := "poison_stack_cap_40"

const LEGACY_POISON_TICK_INTERVAL := "legacy_poison_tick_interval"
const LEGACY_CRIT_CHANCE_PER_STOLEN_GOLD := "legacy_crit_chance_per_stolen_gold"
const LEGACY_CRIT_DAMAGE_PER_CURRENT_GOLD := "legacy_crit_damage_per_current_gold"

const BASIC_STAT_IDS: Array[String] = [
	BASE_DAMAGE,
	PERCENT_PHYSICAL_DAMAGE,
	INCREASED_ATTACK_SPEED,
	CRIT_CHANCE,
	CRIT_DAMAGE,
	BASE_ELEMENTAL_DAMAGE,
	PERCENT_ELEMENTAL_DAMAGE,
	INCREASED_ALL_STACKS,
	SHRED_VALUE,
	BONUS_SHRED_STACKS,
	INCREASED_GOLD,
	SHOP_DISCOUNT,
	INCREASED_MAGIC_FIND,
]

const RARE_STAT_IDS: Array[String] = [
	CHANCE_FOR_RETRIGGER,
	CHANCE_TO_SHRED,
	CHANCE_TO_DECAY,
	CRIT_APPLIES_ELEMENT,
	INCREASED_GOLD,
	SHOP_DISCOUNT,
	INCREASED_MAGIC_FIND,
]

const SPECIAL_STAT_IDS: Array[String] = [
	DISABLE_ENEMY_DODGE,
	DISABLE_ENEMY_BLOCK,
	DISABLE_ENEMY_ABSORB,
	DISABLE_ENEMY_SUPPRESS,
	DISABLE_ENEMY_CLEANSE,
	IGNORE_ARMOR_NO_SHRED,
	IGNORE_RESISTANCE_PHYSICAL_PENALTY,
	DOUBLE_APPLIED_STACKS,
	CONVERT_DAMAGE_TO_PHYSICAL,
	CONVERT_DAMAGE_TO_MAGICAL,
	ALL_STATS_INCREASED,
	IMMUNE_TO_STUN,
	IMMUNE_TO_SLOW,
	IMMUNE_TO_INTERRUPT,
	DECAY_APPLIES_SHRED,
	POISON_STACK_CAP_40,
]

const LEGACY_STAT_ID_BY_TYPE := {
	StatModifier.StatType.ATTACK_SPEED: INCREASED_ATTACK_SPEED,
	StatModifier.StatType.CRIT_CHANCE: CRIT_CHANCE,
	StatModifier.StatType.CRIT_MULTIPLIER: CRIT_DAMAGE,
	StatModifier.StatType.POISON_DAMAGE: BASE_ELEMENTAL_DAMAGE,
	StatModifier.StatType.PHYSICAL_DAMAGE: PERCENT_PHYSICAL_DAMAGE,
	StatModifier.StatType.POISON_STACKS_APPLIED: INCREASED_ALL_STACKS,
	StatModifier.StatType.ARMOR_REDUCTION: INCREASED_ALL_STACKS,
	StatModifier.StatType.GOLD_REWARDS: INCREASED_GOLD,
	StatModifier.StatType.POISON_TICK_INTERVAL: LEGACY_POISON_TICK_INTERVAL,
	StatModifier.StatType.CRIT_CHANCE_PER_STOLEN_GOLD: LEGACY_CRIT_CHANCE_PER_STOLEN_GOLD,
	StatModifier.StatType.CRIT_MULTIPLIER_PER_CURRENT_GOLD: LEGACY_CRIT_DAMAGE_PER_CURRENT_GOLD,
}

const STAT_ID_ALIASES := {
	"attack_speed": INCREASED_ATTACK_SPEED,
	"crit_multiplier": CRIT_DAMAGE,
	"poison_damage": BASE_ELEMENTAL_DAMAGE,
	"physical_damage": PERCENT_PHYSICAL_DAMAGE,
	"poison_stacks_applied": INCREASED_ALL_STACKS,
	"armor_reduction": INCREASED_ALL_STACKS,
	INCREASED_SHRED_STACKS: INCREASED_ALL_STACKS,
	INCREASED_DECAY_STACKS: INCREASED_ALL_STACKS,
	INCREASED_ELEMENTAL_STACKS: INCREASED_ALL_STACKS,
	"shred": SHRED_VALUE,
	"bonus_shred_stacks": BONUS_SHRED_STACKS,
	"bonus_resist_decay": DECAY_VALUE,
	"gold_rewards": INCREASED_GOLD,
	"purchase_discount": SHOP_DISCOUNT,
	"magic_find": INCREASED_MAGIC_FIND,
	"poison_tick_interval": LEGACY_POISON_TICK_INTERVAL,
	"crit_chance_per_stolen_gold": LEGACY_CRIT_CHANCE_PER_STOLEN_GOLD,
	"crit_multiplier_per_current_gold": LEGACY_CRIT_DAMAGE_PER_CURRENT_GOLD,
}

const DEFINITIONS := {
	BASE_DAMAGE: {"label": "Base Damage", "category": CATEGORY_BASIC, "value_kind": VALUE_FLAT, "aggregation": AGGREGATE_ADDITIVE, "floor": FLOOR_NONE, "cap": CAP_NONE, "is_numeric": true, "is_binary": false, "drawback_allowed": true, "scales_with_all_stats": false},
	PERCENT_PHYSICAL_DAMAGE: {"label": "Percent Physical Damage", "category": CATEGORY_BASIC, "value_kind": VALUE_PERCENT, "aggregation": AGGREGATE_ADDITIVE, "floor": FLOOR_NONE, "cap": CAP_NONE, "is_numeric": true, "is_binary": false, "drawback_allowed": true, "scales_with_all_stats": true},
	INCREASED_ATTACK_SPEED: {"label": "Increased Attack Speed", "category": CATEGORY_BASIC, "value_kind": VALUE_PERCENT, "aggregation": AGGREGATE_ADDITIVE, "floor": FLOOR_NONE, "cap": CAP_NONE, "is_numeric": true, "is_binary": false, "drawback_allowed": true, "scales_with_all_stats": true},
	CRIT_CHANCE: {"label": "Crit Chance", "category": CATEGORY_BASIC, "value_kind": VALUE_CHANCE, "aggregation": AGGREGATE_ADDITIVE, "floor": FLOOR_ZERO, "cap": CAP_CHANCE, "is_numeric": true, "is_binary": false, "drawback_allowed": true, "scales_with_all_stats": true},
	CRIT_DAMAGE: {"label": "Crit Damage", "category": CATEGORY_BASIC, "value_kind": VALUE_PERCENT, "aggregation": AGGREGATE_ADDITIVE, "floor": FLOOR_NONE, "cap": CAP_NONE, "is_numeric": true, "is_binary": false, "drawback_allowed": true, "scales_with_all_stats": true},
	BASE_ELEMENTAL_DAMAGE: {"label": "Base Elemental Damage", "category": CATEGORY_BASIC, "value_kind": VALUE_FLAT, "aggregation": AGGREGATE_ADDITIVE, "floor": FLOOR_NONE, "cap": CAP_NONE, "is_numeric": true, "is_binary": false, "drawback_allowed": true, "scales_with_all_stats": true},
	PERCENT_ELEMENTAL_DAMAGE: {"label": "Percent Elemental Damage", "category": CATEGORY_BASIC, "value_kind": VALUE_PERCENT, "aggregation": AGGREGATE_ADDITIVE, "floor": FLOOR_NONE, "cap": CAP_NONE, "is_numeric": true, "is_binary": false, "drawback_allowed": true, "scales_with_all_stats": true},
	INCREASED_SHRED_STACKS: {"label": "Increased Shred Stacks", "category": CATEGORY_BASIC, "value_kind": VALUE_STACKS, "aggregation": AGGREGATE_ADDITIVE, "floor": FLOOR_ZERO, "cap": CAP_NONE, "is_numeric": true, "is_binary": false, "drawback_allowed": true, "scales_with_all_stats": true},
	INCREASED_DECAY_STACKS: {"label": "Increased Decay Stacks", "category": CATEGORY_BASIC, "value_kind": VALUE_STACKS, "aggregation": AGGREGATE_ADDITIVE, "floor": FLOOR_ZERO, "cap": CAP_NONE, "is_numeric": true, "is_binary": false, "drawback_allowed": true, "scales_with_all_stats": true},
	INCREASED_ELEMENTAL_STACKS: {"label": "Increased Elemental Stacks", "category": CATEGORY_BASIC, "value_kind": VALUE_STACKS, "aggregation": AGGREGATE_ADDITIVE, "floor": FLOOR_ZERO, "cap": CAP_NONE, "is_numeric": true, "is_binary": false, "drawback_allowed": true, "scales_with_all_stats": true},
	INCREASED_ALL_STACKS: {"label": "Increased All Stacks", "category": CATEGORY_BASIC, "value_kind": VALUE_STACKS, "aggregation": AGGREGATE_ADDITIVE, "floor": FLOOR_ZERO, "cap": CAP_NONE, "is_numeric": true, "is_binary": false, "drawback_allowed": true, "scales_with_all_stats": true},
	SHRED_VALUE: {"label": "Shred", "category": CATEGORY_BASIC, "value_kind": VALUE_FLAT, "aggregation": AGGREGATE_ADDITIVE, "floor": FLOOR_ZERO, "cap": CAP_NONE, "is_numeric": true, "is_binary": false, "drawback_allowed": true, "scales_with_all_stats": false},
	BONUS_SHRED_STACKS: {"label": "Shred Stacks", "category": CATEGORY_BASIC, "value_kind": VALUE_STACKS, "aggregation": AGGREGATE_ADDITIVE, "floor": FLOOR_ZERO, "cap": CAP_NONE, "is_numeric": true, "is_binary": false, "drawback_allowed": true, "scales_with_all_stats": true},
	DECAY_VALUE: {"label": "Bonus Resist Decay", "category": CATEGORY_BASIC, "value_kind": VALUE_PERCENT, "aggregation": AGGREGATE_ADDITIVE, "floor": FLOOR_ZERO, "cap": CAP_NONE, "is_numeric": true, "is_binary": false, "drawback_allowed": true, "scales_with_all_stats": false},
	INCREASED_GOLD: {"label": "Increased Gold", "category": CATEGORY_BASIC, "value_kind": VALUE_PERCENT, "aggregation": AGGREGATE_ADDITIVE, "floor": FLOOR_ZERO, "cap": CAP_NONE, "is_numeric": true, "is_binary": false, "drawback_allowed": true, "scales_with_all_stats": true},
	SHOP_DISCOUNT: {"label": "Shop Discount", "category": CATEGORY_BASIC, "value_kind": VALUE_PERCENT, "aggregation": AGGREGATE_ADDITIVE, "floor": FLOOR_ZERO, "cap": CAP_NONE, "is_numeric": true, "is_binary": false, "drawback_allowed": true, "scales_with_all_stats": true},
	INCREASED_MAGIC_FIND: {"label": "Increased Magic Find", "category": CATEGORY_BASIC, "value_kind": VALUE_PERCENT, "aggregation": AGGREGATE_ADDITIVE, "floor": FLOOR_ZERO, "cap": CAP_NONE, "is_numeric": true, "is_binary": false, "drawback_allowed": true, "scales_with_all_stats": true},

	CHANCE_FOR_RETRIGGER: {"label": "Chance for Retrigger", "category": CATEGORY_RARE, "value_kind": VALUE_CHANCE, "aggregation": AGGREGATE_ADDITIVE, "floor": FLOOR_ZERO, "cap": CAP_CHANCE, "is_numeric": true, "is_binary": false, "drawback_allowed": false, "scales_with_all_stats": true},
	CHANCE_TO_SHRED: {"label": "Chance to Shred", "category": CATEGORY_RARE, "value_kind": VALUE_CHANCE, "aggregation": AGGREGATE_ADDITIVE, "floor": FLOOR_ZERO, "cap": CAP_CHANCE, "is_numeric": true, "is_binary": false, "drawback_allowed": false, "scales_with_all_stats": true},
	CHANCE_TO_DECAY: {"label": "Chance to Decay", "category": CATEGORY_RARE, "value_kind": VALUE_CHANCE, "aggregation": AGGREGATE_ADDITIVE, "floor": FLOOR_ZERO, "cap": CAP_CHANCE, "is_numeric": true, "is_binary": false, "drawback_allowed": false, "scales_with_all_stats": true},
	CRIT_APPLIES_ELEMENT: {"label": "Chance for Crits to Apply Poison", "category": CATEGORY_RARE, "value_kind": VALUE_CHANCE, "aggregation": AGGREGATE_ADDITIVE, "floor": FLOOR_ZERO, "cap": CAP_CHANCE, "is_numeric": true, "is_binary": false, "drawback_allowed": false, "scales_with_all_stats": true},

	DISABLE_ENEMY_DODGE: {"label": "Enemies can no longer dodge", "category": CATEGORY_SPECIAL, "value_kind": VALUE_BINARY, "aggregation": AGGREGATE_BINARY, "floor": FLOOR_NONE, "cap": CAP_NONE, "is_numeric": false, "is_binary": true, "drawback_allowed": false, "scales_with_all_stats": false},
	DISABLE_ENEMY_BLOCK: {"label": "Enemies can no longer block", "category": CATEGORY_SPECIAL, "value_kind": VALUE_BINARY, "aggregation": AGGREGATE_BINARY, "floor": FLOOR_NONE, "cap": CAP_NONE, "is_numeric": false, "is_binary": true, "drawback_allowed": false, "scales_with_all_stats": false},
	DISABLE_ENEMY_ABSORB: {"label": "Enemies can no longer absorb", "category": CATEGORY_SPECIAL, "value_kind": VALUE_BINARY, "aggregation": AGGREGATE_BINARY, "floor": FLOOR_NONE, "cap": CAP_NONE, "is_numeric": false, "is_binary": true, "drawback_allowed": false, "scales_with_all_stats": false},
	DISABLE_ENEMY_SUPPRESS: {"label": "Enemies can no longer suppress", "category": CATEGORY_SPECIAL, "value_kind": VALUE_BINARY, "aggregation": AGGREGATE_BINARY, "floor": FLOOR_NONE, "cap": CAP_NONE, "is_numeric": false, "is_binary": true, "drawback_allowed": false, "scales_with_all_stats": false},
	DISABLE_ENEMY_CLEANSE: {"label": "Enemies can no longer cleanse", "category": CATEGORY_SPECIAL, "value_kind": VALUE_BINARY, "aggregation": AGGREGATE_BINARY, "floor": FLOOR_NONE, "cap": CAP_NONE, "is_numeric": false, "is_binary": true, "drawback_allowed": false, "scales_with_all_stats": false},
	IGNORE_ARMOR_NO_SHRED: {"label": "You ignore armor, but can no longer apply shred", "category": CATEGORY_SPECIAL, "value_kind": VALUE_BINARY, "aggregation": AGGREGATE_BINARY, "floor": FLOOR_NONE, "cap": CAP_NONE, "is_numeric": false, "is_binary": true, "drawback_allowed": false, "scales_with_all_stats": false},
	IGNORE_RESISTANCE_PHYSICAL_PENALTY: {"label": "You ignore resistance, but your physical damage is reduced by 50%", "category": CATEGORY_SPECIAL, "value_kind": VALUE_BINARY, "aggregation": AGGREGATE_BINARY, "floor": FLOOR_NONE, "cap": CAP_NONE, "is_numeric": false, "is_binary": true, "drawback_allowed": false, "scales_with_all_stats": false, "fixed_constants": {"physical_damage_penalty": 0.5}},
	DOUBLE_APPLIED_STACKS: {"label": "Stacks you apply are doubled", "category": CATEGORY_SPECIAL, "value_kind": VALUE_BINARY, "aggregation": AGGREGATE_BINARY, "floor": FLOOR_NONE, "cap": CAP_NONE, "is_numeric": false, "is_binary": true, "drawback_allowed": false, "scales_with_all_stats": false},
	CONVERT_DAMAGE_TO_PHYSICAL: {"label": "All of your damage is now physical", "category": CATEGORY_SPECIAL, "value_kind": VALUE_BINARY, "aggregation": AGGREGATE_BINARY, "floor": FLOOR_NONE, "cap": CAP_NONE, "is_numeric": false, "is_binary": true, "drawback_allowed": false, "scales_with_all_stats": false},
	CONVERT_DAMAGE_TO_MAGICAL: {"label": "All of your damage is now magical", "category": CATEGORY_SPECIAL, "value_kind": VALUE_BINARY, "aggregation": AGGREGATE_BINARY, "floor": FLOOR_NONE, "cap": CAP_NONE, "is_numeric": false, "is_binary": true, "drawback_allowed": false, "scales_with_all_stats": false},
	ALL_STATS_INCREASED: {"label": "All stats are increased by 20%", "category": CATEGORY_SPECIAL, "value_kind": VALUE_BINARY, "aggregation": AGGREGATE_BINARY, "floor": FLOOR_NONE, "cap": CAP_NONE, "is_numeric": false, "is_binary": true, "drawback_allowed": false, "scales_with_all_stats": false, "fixed_constants": {"stat_sheet_multiplier": 1.2}},
	IMMUNE_TO_STUN: {"label": "You are immune to stun", "category": CATEGORY_SPECIAL, "value_kind": VALUE_BINARY, "aggregation": AGGREGATE_BINARY, "floor": FLOOR_NONE, "cap": CAP_NONE, "is_numeric": false, "is_binary": true, "drawback_allowed": false, "scales_with_all_stats": false},
	IMMUNE_TO_SLOW: {"label": "You are immune to slow", "category": CATEGORY_SPECIAL, "value_kind": VALUE_BINARY, "aggregation": AGGREGATE_BINARY, "floor": FLOOR_NONE, "cap": CAP_NONE, "is_numeric": false, "is_binary": true, "drawback_allowed": false, "scales_with_all_stats": false},
	IMMUNE_TO_INTERRUPT: {"label": "You are immune to interrupt", "category": CATEGORY_SPECIAL, "value_kind": VALUE_BINARY, "aggregation": AGGREGATE_BINARY, "floor": FLOOR_NONE, "cap": CAP_NONE, "is_numeric": false, "is_binary": true, "drawback_allowed": false, "scales_with_all_stats": false},
	DECAY_APPLIES_SHRED: {"label": "Applying Decay also applies Shred", "category": CATEGORY_SPECIAL, "value_kind": VALUE_BINARY, "aggregation": AGGREGATE_BINARY, "floor": FLOOR_NONE, "cap": CAP_NONE, "is_numeric": false, "is_binary": true, "drawback_allowed": false, "scales_with_all_stats": false},
	POISON_STACK_CAP_40: {"label": "Poison Stack Cap Increased to 40", "category": CATEGORY_SPECIAL, "value_kind": VALUE_BINARY, "aggregation": AGGREGATE_BINARY, "floor": FLOOR_NONE, "cap": CAP_NONE, "is_numeric": false, "is_binary": true, "drawback_allowed": false, "scales_with_all_stats": false, "fixed_constants": {"poison_stack_cap": 40}},

	LEGACY_POISON_TICK_INTERVAL: {"label": "Poison Tick Interval", "category": CATEGORY_COMPATIBILITY, "value_kind": VALUE_MULTIPLIER, "aggregation": AGGREGATE_COMPATIBILITY, "floor": 0.05, "cap": CAP_NONE, "is_numeric": true, "is_binary": false, "drawback_allowed": false, "scales_with_all_stats": false},
	LEGACY_CRIT_CHANCE_PER_STOLEN_GOLD: {"label": "Crit Chance per Stolen Gold", "category": CATEGORY_COMPATIBILITY, "value_kind": VALUE_CHANCE, "aggregation": AGGREGATE_COMPATIBILITY, "floor": FLOOR_ZERO, "cap": CAP_CHANCE, "is_numeric": true, "is_binary": false, "drawback_allowed": false, "scales_with_all_stats": false},
	LEGACY_CRIT_DAMAGE_PER_CURRENT_GOLD: {"label": "Crit Damage per Current Gold", "category": CATEGORY_COMPATIBILITY, "value_kind": VALUE_PERCENT, "aggregation": AGGREGATE_COMPATIBILITY, "floor": FLOOR_ZERO, "cap": CAP_NONE, "is_numeric": true, "is_binary": false, "drawback_allowed": false, "scales_with_all_stats": false},
}

const SLOT_CATEGORY_POOLS := {
	GearItem.SlotType.WEAPON: {
		CATEGORY_BASIC: [
			{"stat_id": BASE_DAMAGE, "weight": 20},
			{"stat_id": PERCENT_PHYSICAL_DAMAGE, "weight": 15},
			{"stat_id": CRIT_DAMAGE, "weight": 15},
			{"stat_id": BASE_ELEMENTAL_DAMAGE, "weight": 10},
			{"stat_id": PERCENT_ELEMENTAL_DAMAGE, "weight": 10},
			{"stat_id": INCREASED_GOLD, "weight": 5},
			{"stat_id": SHOP_DISCOUNT, "weight": 5},
			{"stat_id": INCREASED_MAGIC_FIND, "weight": 5},
		],
		CATEGORY_RARE: [
			{"stat_id": CHANCE_TO_SHRED, "weight": 15},
			{"stat_id": CHANCE_TO_DECAY, "weight": 10},
			{"stat_id": CHANCE_FOR_RETRIGGER, "weight": 10},
			{"stat_id": INCREASED_GOLD, "weight": 5},
			{"stat_id": SHOP_DISCOUNT, "weight": 5},
			{"stat_id": INCREASED_MAGIC_FIND, "weight": 5},
		],
		CATEGORY_SPECIAL: [
			{"stat_id": CONVERT_DAMAGE_TO_PHYSICAL, "weight": 5},
			{"stat_id": CONVERT_DAMAGE_TO_MAGICAL, "weight": 5},
			{"stat_id": ALL_STATS_INCREASED, "weight": 5},
		],
	},
	GearItem.SlotType.HELM: {
		CATEGORY_BASIC: [
			{"stat_id": PERCENT_PHYSICAL_DAMAGE, "weight": 10},
			{"stat_id": CRIT_CHANCE, "weight": 15},
			{"stat_id": INCREASED_ATTACK_SPEED, "weight": 15},
			{"stat_id": BASE_ELEMENTAL_DAMAGE, "weight": 10},
			{"stat_id": PERCENT_ELEMENTAL_DAMAGE, "weight": 10},
			{"stat_id": INCREASED_ALL_STACKS, "weight": 30},
			{"stat_id": INCREASED_GOLD, "weight": 5},
			{"stat_id": SHOP_DISCOUNT, "weight": 5},
			{"stat_id": INCREASED_MAGIC_FIND, "weight": 5},
		],
		CATEGORY_RARE: [
			{"stat_id": CHANCE_TO_SHRED, "weight": 10},
			{"stat_id": CHANCE_TO_DECAY, "weight": 10},
			{"stat_id": CRIT_APPLIES_ELEMENT, "weight": 10},
			{"stat_id": INCREASED_GOLD, "weight": 5},
			{"stat_id": SHOP_DISCOUNT, "weight": 5},
			{"stat_id": INCREASED_MAGIC_FIND, "weight": 5},
		],
		CATEGORY_SPECIAL: [
			{"stat_id": DOUBLE_APPLIED_STACKS, "weight": 5},
			{"stat_id": IGNORE_ARMOR_NO_SHRED, "weight": 5},
			{"stat_id": IGNORE_RESISTANCE_PHYSICAL_PENALTY, "weight": 5},
		],
	},
	GearItem.SlotType.ARMOR: {
		CATEGORY_BASIC: [
			{"stat_id": PERCENT_PHYSICAL_DAMAGE, "weight": 15},
			{"stat_id": CRIT_CHANCE, "weight": 10},
			{"stat_id": PERCENT_ELEMENTAL_DAMAGE, "weight": 10},
			{"stat_id": INCREASED_GOLD, "weight": 15},
			{"stat_id": INCREASED_ALL_STACKS, "weight": 30},
			{"stat_id": SHOP_DISCOUNT, "weight": 5},
			{"stat_id": INCREASED_MAGIC_FIND, "weight": 5},
		],
		CATEGORY_RARE: [
			{"stat_id": CHANCE_TO_SHRED, "weight": 10},
			{"stat_id": CHANCE_TO_DECAY, "weight": 10},
			{"stat_id": CRIT_APPLIES_ELEMENT, "weight": 10},
			{"stat_id": INCREASED_GOLD, "weight": 5},
			{"stat_id": SHOP_DISCOUNT, "weight": 5},
			{"stat_id": INCREASED_MAGIC_FIND, "weight": 5},
		],
		CATEGORY_SPECIAL: [
			{"stat_id": ALL_STATS_INCREASED, "weight": 5},
			{"stat_id": DISABLE_ENEMY_DODGE, "weight": 10},
			{"stat_id": DISABLE_ENEMY_BLOCK, "weight": 10},
			{"stat_id": DISABLE_ENEMY_ABSORB, "weight": 10},
			{"stat_id": DISABLE_ENEMY_SUPPRESS, "weight": 10},
			{"stat_id": DISABLE_ENEMY_CLEANSE, "weight": 10},
			{"stat_id": IMMUNE_TO_STUN, "weight": 5},
			{"stat_id": IMMUNE_TO_SLOW, "weight": 5},
			{"stat_id": IMMUNE_TO_INTERRUPT, "weight": 5},
		],
	},
	GearItem.SlotType.TRINKET: {
		CATEGORY_BASIC: [
			{"stat_id": BASE_DAMAGE, "weight": 15},
			{"stat_id": PERCENT_PHYSICAL_DAMAGE, "weight": 15},
			{"stat_id": CRIT_CHANCE, "weight": 15},
			{"stat_id": INCREASED_ATTACK_SPEED, "weight": 15},
			{"stat_id": BASE_ELEMENTAL_DAMAGE, "weight": 10},
			{"stat_id": PERCENT_ELEMENTAL_DAMAGE, "weight": 10},
			{"stat_id": INCREASED_GOLD, "weight": 5},
			{"stat_id": SHOP_DISCOUNT, "weight": 5},
			{"stat_id": INCREASED_MAGIC_FIND, "weight": 5},
		],
		CATEGORY_RARE: [
			{"stat_id": CHANCE_FOR_RETRIGGER, "weight": 15},
			{"stat_id": CHANCE_TO_SHRED, "weight": 10},
			{"stat_id": CHANCE_TO_DECAY, "weight": 10},
			{"stat_id": CRIT_APPLIES_ELEMENT, "weight": 10},
			{"stat_id": INCREASED_GOLD, "weight": 5},
			{"stat_id": SHOP_DISCOUNT, "weight": 5},
			{"stat_id": INCREASED_MAGIC_FIND, "weight": 5},
		],
		CATEGORY_SPECIAL: [
			{"stat_id": DOUBLE_APPLIED_STACKS, "weight": 5},
			{"stat_id": DISABLE_ENEMY_DODGE, "weight": 10},
			{"stat_id": DISABLE_ENEMY_BLOCK, "weight": 10},
			{"stat_id": DISABLE_ENEMY_ABSORB, "weight": 10},
			{"stat_id": DISABLE_ENEMY_SUPPRESS, "weight": 10},
			{"stat_id": DISABLE_ENEMY_CLEANSE, "weight": 10},
			{"stat_id": CONVERT_DAMAGE_TO_PHYSICAL, "weight": 5},
			{"stat_id": CONVERT_DAMAGE_TO_MAGICAL, "weight": 5},
		],
	},
	GearItem.SlotType.CHARM: {
		CATEGORY_BASIC: [
			{"stat_id": PERCENT_PHYSICAL_DAMAGE, "weight": 10},
			{"stat_id": CRIT_CHANCE, "weight": 20},
			{"stat_id": INCREASED_ATTACK_SPEED, "weight": 15},
			{"stat_id": CRIT_DAMAGE, "weight": 15},
			{"stat_id": BASE_ELEMENTAL_DAMAGE, "weight": 10},
			{"stat_id": PERCENT_ELEMENTAL_DAMAGE, "weight": 10},
			{"stat_id": INCREASED_GOLD, "weight": 5},
			{"stat_id": INCREASED_ALL_STACKS, "weight": 30},
			{"stat_id": SHOP_DISCOUNT, "weight": 5},
			{"stat_id": INCREASED_MAGIC_FIND, "weight": 5},
		],
		CATEGORY_RARE: [
			{"stat_id": CHANCE_TO_SHRED, "weight": 10},
			{"stat_id": CHANCE_TO_DECAY, "weight": 10},
			{"stat_id": CRIT_APPLIES_ELEMENT, "weight": 15},
			{"stat_id": INCREASED_GOLD, "weight": 5},
			{"stat_id": SHOP_DISCOUNT, "weight": 5},
			{"stat_id": INCREASED_MAGIC_FIND, "weight": 5},
		],
		CATEGORY_SPECIAL: [
			{"stat_id": IGNORE_ARMOR_NO_SHRED, "weight": 5},
			{"stat_id": IGNORE_RESISTANCE_PHYSICAL_PENALTY, "weight": 5},
			{"stat_id": DOUBLE_APPLIED_STACKS, "weight": 5},
			{"stat_id": DISABLE_ENEMY_DODGE, "weight": 10},
			{"stat_id": DISABLE_ENEMY_BLOCK, "weight": 10},
			{"stat_id": DISABLE_ENEMY_ABSORB, "weight": 10},
			{"stat_id": DISABLE_ENEMY_SUPPRESS, "weight": 10},
			{"stat_id": DISABLE_ENEMY_CLEANSE, "weight": 10},
		],
	},
}

const SLOT_VALUE_RANGES := {
	GearItem.SlotType.WEAPON: {
		BASE_DAMAGE: [2.0, 5.0],
		PERCENT_PHYSICAL_DAMAGE: [0.06, 0.12],
		CRIT_DAMAGE: [0.30, 0.45],
		BASE_ELEMENTAL_DAMAGE: [3.0, 6.0],
		PERCENT_ELEMENTAL_DAMAGE: [0.18, 0.24],
		INCREASED_GOLD: [0.40, 0.60],
		SHOP_DISCOUNT: [0.05, 0.10],
		INCREASED_MAGIC_FIND: [0.15, 0.20],
		CHANCE_TO_SHRED: [0.08, 0.10],
		CHANCE_TO_DECAY: [0.08, 0.10],
		CHANCE_FOR_RETRIGGER: [0.05, 0.08],
	},
	GearItem.SlotType.HELM: {
		PERCENT_PHYSICAL_DAMAGE: [0.12, 0.15],
		CRIT_CHANCE: [0.018, 0.048],
		INCREASED_ATTACK_SPEED: [0.03, 0.072],
		BASE_ELEMENTAL_DAMAGE: [4.0, 10.0],
		PERCENT_ELEMENTAL_DAMAGE: [0.15, 0.21],
		INCREASED_ALL_STACKS: [1.0, 2.0],
		INCREASED_GOLD: [0.80, 1.00],
		SHOP_DISCOUNT: [0.05, 0.10],
		INCREASED_MAGIC_FIND: [0.15, 0.20],
		CHANCE_TO_SHRED: [0.08, 0.10],
		CHANCE_TO_DECAY: [0.08, 0.10],
		CRIT_APPLIES_ELEMENT: [0.20, 0.30],
	},
	GearItem.SlotType.ARMOR: {
		PERCENT_PHYSICAL_DAMAGE: [0.06, 0.12],
		CRIT_CHANCE: [0.012, 0.024],
		PERCENT_ELEMENTAL_DAMAGE: [0.18, 0.24],
		INCREASED_GOLD: [0.40, 0.60],
		INCREASED_ALL_STACKS: [1.0, 2.0],
		SHOP_DISCOUNT: [0.05, 0.10],
		INCREASED_MAGIC_FIND: [0.15, 0.20],
		CHANCE_TO_SHRED: [0.08, 0.10],
		CHANCE_TO_DECAY: [0.08, 0.10],
		CRIT_APPLIES_ELEMENT: [0.10, 0.20],
	},
	GearItem.SlotType.TRINKET: {
		BASE_DAMAGE: [4.0, 6.0],
		PERCENT_PHYSICAL_DAMAGE: [0.09, 0.15],
		CRIT_CHANCE: [0.024, 0.036],
		INCREASED_ATTACK_SPEED: [0.048, 0.06],
		BASE_ELEMENTAL_DAMAGE: [5.0, 8.0],
		PERCENT_ELEMENTAL_DAMAGE: [0.12, 0.18],
		INCREASED_GOLD: [0.20, 0.40],
		SHOP_DISCOUNT: [0.05, 0.10],
		INCREASED_MAGIC_FIND: [0.15, 0.20],
		CHANCE_FOR_RETRIGGER: [0.03, 0.06],
		CHANCE_TO_SHRED: [0.08, 0.10],
		CHANCE_TO_DECAY: [0.08, 0.10],
		CRIT_APPLIES_ELEMENT: [0.10, 0.15],
	},
	GearItem.SlotType.CHARM: {
		PERCENT_PHYSICAL_DAMAGE: [0.09, 0.15],
		CRIT_CHANCE: [0.036, 0.048],
		INCREASED_ATTACK_SPEED: [0.06, 0.09],
		CRIT_DAMAGE: [0.24, 0.36],
		BASE_ELEMENTAL_DAMAGE: [6.0, 10.0],
		PERCENT_ELEMENTAL_DAMAGE: [0.18, 0.24],
		INCREASED_GOLD: [0.30, 0.60],
		INCREASED_ALL_STACKS: [1.0, 2.0],
		SHOP_DISCOUNT: [0.05, 0.10],
		INCREASED_MAGIC_FIND: [0.15, 0.20],
		CHANCE_TO_SHRED: [0.08, 0.10],
		CHANCE_TO_DECAY: [0.08, 0.10],
		CRIT_APPLIES_ELEMENT: [0.12, 0.18],
	},
}

const CATEGORY_SLOT_VALUE_RANGES := {
	CATEGORY_RARE: {
		GearItem.SlotType.WEAPON: {
			INCREASED_GOLD: [0.44, 0.66],
			SHOP_DISCOUNT: [0.06, 0.11],
			INCREASED_MAGIC_FIND: [0.17, 0.22],
		},
		GearItem.SlotType.HELM: {
			INCREASED_GOLD: [0.88, 1.10],
			SHOP_DISCOUNT: [0.06, 0.11],
			INCREASED_MAGIC_FIND: [0.17, 0.22],
		},
		GearItem.SlotType.ARMOR: {
			INCREASED_GOLD: [0.44, 0.66],
			SHOP_DISCOUNT: [0.06, 0.11],
			INCREASED_MAGIC_FIND: [0.17, 0.22],
		},
		GearItem.SlotType.TRINKET: {
			INCREASED_GOLD: [0.22, 0.44],
			SHOP_DISCOUNT: [0.06, 0.11],
			INCREASED_MAGIC_FIND: [0.17, 0.22],
		},
		GearItem.SlotType.CHARM: {
			INCREASED_GOLD: [0.33, 0.66],
			SHOP_DISCOUNT: [0.06, 0.11],
			INCREASED_MAGIC_FIND: [0.17, 0.22],
		},
	},
}


static func all_stat_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in DEFINITIONS.keys():
		ids.append(String(id))
	ids.sort()
	return ids


static func ids_for_category(category: String) -> Array[String]:
	match category:
		CATEGORY_BASIC:
			return BASIC_STAT_IDS.duplicate()
		CATEGORY_RARE:
			return RARE_STAT_IDS.duplicate()
		CATEGORY_SPECIAL:
			return SPECIAL_STAT_IDS.duplicate()
	var ids: Array[String] = []
	for id in all_stat_ids():
		if String(DEFINITIONS[id].get("category", "")) == category:
			ids.append(id)
	return ids


static func has_stat(stat_id: String) -> bool:
	return DEFINITIONS.has(canonicalize_stat_id(stat_id))


static func definition(stat_id: String) -> Dictionary:
	var canonical_id := canonicalize_stat_id(stat_id)
	if not DEFINITIONS.has(canonical_id):
		return {}
	return (DEFINITIONS[canonical_id] as Dictionary).duplicate(true)


static func canonicalize_stat_id(stat_id: String) -> String:
	var clean := stat_id.strip_edges()
	return String(STAT_ID_ALIASES.get(clean, clean))


static func canonical_id_for_modifier(modifier: StatModifier) -> String:
	if modifier == null:
		return ""
	if modifier.stat_id.strip_edges() != "":
		var from_text := canonicalize_stat_id(modifier.stat_id)
		if DEFINITIONS.has(from_text):
			return from_text
	return String(LEGACY_STAT_ID_BY_TYPE.get(modifier.stat, ""))


static func legacy_stat_id(stat: StatModifier.StatType) -> String:
	return String(LEGACY_STAT_ID_BY_TYPE.get(stat, ""))


static func label_for(stat_id: String) -> String:
	return String(definition(stat_id).get("label", ""))


static func category_for(stat_id: String) -> String:
	return String(definition(stat_id).get("category", ""))


static func value_kind_for(stat_id: String) -> String:
	return String(definition(stat_id).get("value_kind", ""))


static func aggregation_for(stat_id: String) -> String:
	return String(definition(stat_id).get("aggregation", ""))


static func floor_for(stat_id: String) -> float:
	return float(definition(stat_id).get("floor", FLOOR_NONE))


static func cap_for(stat_id: String) -> float:
	return float(definition(stat_id).get("cap", CAP_NONE))


static func is_chance_stat(stat_id: String) -> bool:
	return value_kind_for(stat_id) == VALUE_CHANCE


static func is_special(stat_id: String) -> bool:
	return category_for(stat_id) == CATEGORY_SPECIAL


static func is_drawback_allowed(stat_id: String) -> bool:
	return bool(definition(stat_id).get("drawback_allowed", false))


static func is_numeric(stat_id: String) -> bool:
	return bool(definition(stat_id).get("is_numeric", false))


static func is_binary(stat_id: String) -> bool:
	return bool(definition(stat_id).get("is_binary", false))


static func scales_with_all_stats(stat_id: String) -> bool:
	return bool(definition(stat_id).get("scales_with_all_stats", false))


static func value_range_for_slot(slot: GearItem.SlotType, stat_id: String) -> Dictionary:
	var canonical_id := canonicalize_stat_id(stat_id)
	var slot_ranges: Dictionary = SLOT_VALUE_RANGES.get(slot, {})
	if not slot_ranges.has(canonical_id):
		return {"ok": false, "min": 0.0, "max": 0.0}
	var range: Array = slot_ranges[canonical_id]
	if range.size() < 2:
		return {"ok": false, "min": 0.0, "max": 0.0}
	return {"ok": true, "min": float(range[0]), "max": float(range[1])}


static func value_range_for_slot_category(slot: GearItem.SlotType, category: String, stat_id: String) -> Dictionary:
	var canonical_id := canonicalize_stat_id(stat_id)
	var category_ranges: Dictionary = CATEGORY_SLOT_VALUE_RANGES.get(category, {})
	var slot_ranges: Dictionary = category_ranges.get(slot, {})
	if slot_ranges.has(canonical_id):
		var range: Array = slot_ranges[canonical_id]
		if range.size() >= 2:
			return {"ok": true, "min": float(range[0]), "max": float(range[1])}
	return value_range_for_slot(slot, canonical_id)


static var _pool_for_slot_cache: Dictionary = {}


## SLOT_CATEGORY_POOLS/DEFINITIONS are fixed constants, so the derived pool
## for a given (slot, category) is always the same -- cached instead of
## re-canonicalizing every entry on every call, since gear generation and
## weight_for_slot()/is_stat_valid_for_slot() (which each call this just to
## scan for one entry) can hit this dozens of times per item rolled.
static func pool_for_slot(slot: GearItem.SlotType, category: String) -> Array[Dictionary]:
	var cache_key := "%d:%s" % [slot, category]
	if _pool_for_slot_cache.has(cache_key):
		var cached: Array[Dictionary] = _pool_for_slot_cache[cache_key]
		return cached.duplicate()
	var slot_pools: Dictionary = SLOT_CATEGORY_POOLS.get(slot, {})
	var raw_pool: Array = slot_pools.get(category, [])
	var pool: Array[Dictionary] = []
	for entry in raw_pool:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var stat_id := canonicalize_stat_id(String(entry.get("stat_id", "")))
		if stat_id == "" or not DEFINITIONS.has(stat_id):
			continue
		pool.append({
			"stat_id": stat_id,
			"weight": max(0, int(entry.get("weight", 0))),
		})
	_pool_for_slot_cache[cache_key] = pool
	return pool.duplicate()


static func stat_ids_for_slot(slot: GearItem.SlotType, category: String) -> Array[String]:
	var ids: Array[String] = []
	for entry in pool_for_slot(slot, category):
		var stat_id := String(entry.get("stat_id", ""))
		if stat_id != "":
			ids.append(stat_id)
	return ids


static func is_stat_valid_for_slot(slot: GearItem.SlotType, category: String, stat_id: String) -> bool:
	var canonical_id := canonicalize_stat_id(stat_id)
	if canonical_id == "":
		return false
	for entry in pool_for_slot(slot, category):
		if String(entry.get("stat_id", "")) == canonical_id:
			return true
	return false


static func is_stat_enabled_for_slot(slot: GearItem.SlotType, category: String, stat_id: String) -> bool:
	return weight_for_slot(slot, category, stat_id) > 0


static func weight_for_slot(slot: GearItem.SlotType, category: String, stat_id: String) -> int:
	var canonical_id := canonicalize_stat_id(stat_id)
	if canonical_id == "":
		return 0
	for entry in pool_for_slot(slot, category):
		if String(entry.get("stat_id", "")) == canonical_id:
			return int(entry.get("weight", 0))
	return 0


static func drawback_pool_for_slot(slot: GearItem.SlotType) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for entry in pool_for_slot(slot, CATEGORY_BASIC):
		var stat_id := String(entry.get("stat_id", ""))
		if is_drawback_allowed(stat_id):
			pool.append(entry.duplicate())
	return pool


static func drawback_stat_ids_for_slot(slot: GearItem.SlotType) -> Array[String]:
	var ids: Array[String] = []
	for entry in drawback_pool_for_slot(slot):
		var stat_id := String(entry.get("stat_id", ""))
		if stat_id != "":
			ids.append(stat_id)
	return ids
