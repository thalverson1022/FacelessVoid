class_name GearItem
extends Resource

enum SlotType {
	WEAPON,
	TRINKET,
	CHARM,
	HELM,
	ARMOR,
	LEGS = 5,
	HANDS = 6,
}

enum Tier {
	BASIC,
	MASTER,
	CURSED,
	LEGENDARY,
	CRUDE,
	EPIC,
	CHAOS,
	UNIQUE,
}

enum ClassFamily {
	NONE,
	ROGUE,
}

enum SourceKind {
	UNKNOWN,
	GENERATED,
	FIXED,
	LEGENDARY,
	COMPATIBILITY,
}

@export var id: String = ""
@export var display_name: String = ""
## Stable signature identity, separate from ordinary numeric affixes.
@export var legendary_effect_id: String = ""
@export var slot: SlotType = SlotType.WEAPON
@export var tier: Tier = Tier.BASIC
@export var item_family: String = ""
@export var class_family: ClassFamily = ClassFamily.ROGUE
@export var source_kind: SourceKind = SourceKind.UNKNOWN
@export var source_context: String = ""
@export var source_seed: int = 0
@export var deterministic_key: String = ""
@export var generation_value_scale: float = 1.0
@export var generation_contract_depth: int = 0
@export var reward_base_tier: int = -1
@export var reward_tier_steps: Array[int] = []
@export var reward_magic_find_upgraded: bool = false
@export var affixes: Array[StatModifier] = []
@export var triggered_skill_effects: Array[TriggeredSkillEffect] = []
@export var unlocked_skills: Array[Skill] = []
@export var physical_damage_per_gold: float = 0.0
@export var min_cast_time_proc_chance: float = 0.0
@export var is_unidentified: bool = false


static func universal_slot_order() -> Array[SlotType]:
	return [
		SlotType.WEAPON,
		SlotType.HELM,
		SlotType.ARMOR,
		SlotType.TRINKET,
		SlotType.CHARM,
		SlotType.LEGS,
		SlotType.HANDS,
	]


static func rarity_order() -> Array[Tier]:
	return [
		Tier.CRUDE,
		Tier.BASIC,
		Tier.MASTER,
		Tier.EPIC,
		Tier.CURSED,
		Tier.CHAOS,
		Tier.UNIQUE,
		Tier.LEGENDARY,
	]
