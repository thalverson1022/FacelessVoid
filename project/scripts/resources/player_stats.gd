class_name PlayerStats
extends Resource

@export var cooldown_factor: float = 1.0
@export var cooldown_reduction: float = 0.0
@export var increased_buff_duration: float = 0.0
@export var crit_applies_penetration: float = 0.0
@export var crit_applies_potency: float = 0.0

@export var attack_speed: float = 0.0
@export var crit_chance: float = 0.0
@export var crit_multiplier: float = 2.0
@export var poison_tick_damage_multiplier: float = 1.0
@export var poison_damage_per_tick: float = 0.0
@export var base_poison_damage: float = 0.0
@export var bonus_base_elemental_damage: float = 0.0
@export var elemental_damage_multiplier: float = 1.0
@export var gear_elemental_damage_multiplier: float = 1.0
@export var talent_elemental_damage_multiplier: float = 1.0
@export var physical_damage_multiplier: float = 1.0
@export var gear_physical_damage_multiplier: float = 1.0
@export var talent_physical_damage_multiplier: float = 1.0
@export var physical_damage_uses_buckets: bool = false
@export var bonus_poison_stacks: int = 0
@export var bonus_armor_reduction: int = 0
@export var shred_value: int = 10
@export var bonus_shred_stacks: int = 0
@export var bonus_decay_stacks: int = 0
@export var decay_value: float = 0.2
@export var poison_stack_cap: int = 20
@export var poison_tick_interval_multiplier: float = 1.0
## T9 reviewed Poison descriptors; absent from compatibility content.
@export_range(0, 5) var hastened_poison_rank: int = 0
@export_range(0, 5) var accelerant_rank: int = 0
@export_range(0, 3) var echoing_toxin_rank: int = 0
@export_range(0, 4) var resonance_rank: int = 0
@export var critical_poison_enabled: bool = false
@export var triggered_skill_effects: Array[TriggeredSkillEffect] = []
@export var bonus_physical_damage: float = 0.0
@export var min_cast_time_proc_chance: float = 0.0
@export var retrigger_chance: float = 0.0
@export var shred_chance: float = 0.0
@export var decay_chance: float = 0.0
@export var elemental_proc_chance: float = 0.0
@export var gold_reward_multiplier: float = 1.0
@export var shop_discount: float = 0.0
@export var magic_find: float = 0.0
@export var current_gold: int = 0
@export var crit_chance_per_stolen_gold: float = 0.0
@export var crit_multiplier_per_current_gold: float = 0.0
## Reviewed Gilded Blade; its own contribution is capped, independent of gear.
@export var gilded_blade_enabled: bool = false
@export_range(0, 3) var silvered_edge_rank: int = 0
@export var special_stat_ids: Array[String] = []
@export var special_effects: Dictionary = {}
@export var weapon_damage_min: int = 16
@export var weapon_damage_max: int = 20
@export var weapon_damage_tier: int = GearItem.Tier.CRUDE
@export var weapon_damage_weapon_id: String = ""
@export var weapon_damage_uses_fallback: bool = true
@export var weapon_damage_fallback_reason: String = "missing_weapon"

## T4 opt-in core lifecycle inputs. Compatibility content leaves these disabled.
## Shared Bonus Stacks mapping is implemented; content promotion remains M4/M5.
@export var footwork_rank: int = 0
@export var bonus_footwork_stacks: int = 0
@export var riposte_rank: int = 0
@export var bypass_enabled: bool = false
@export var bonus_bypass_stacks: int = 0
@export var readiness_enabled: bool = false
## Opt-in T6 fixtures; content promotion and unresolved lifetime settings stay gated.
## Zero disables; -1 is untimed; positive values are explicit milliseconds.
@export var precision_duration_ms: int = 0
@export var dance_duration_ms: int = 0
@export var side_step_enabled: bool = false
@export var death_blade_enabled: bool = false
@export_range(0.0, 1.0) var death_blade_chance: float = 0.0
## T7 opt-in resolved build inputs; redesigned content promotion remains downstream.
@export_range(0, 2) var finders_keepers_rank: int = 0
@export_range(0, 3) var death_pact_rank: int = 0
@export var assassin_tree_points: int = 0
@export var bonus_penetration_stacks: int = 0
@export var bonus_potency_stacks: int = 0
@export var shred_cleanse_immune: bool = false
@export var independent_decay_shred: bool = false
@export var bribery_base_stacks: int = 0

## T3 value-only provenance. Source resources never become mutable fight state.
@export var stat_sources: Array[Dictionary] = []
@export var stat_derivations: Array[Dictionary] = []
@export var derivation_details: Array[Dictionary] = []
@export var skill_damage_multipliers: Dictionary = {}
@export var temporary_physical_multiplier: float = 1.0
@export var temporary_elemental_multiplier: float = 1.0
@export var derived_physical_multiplier: float = 1.0
@export var derived_elemental_multiplier: float = 1.0
## Runtime-only unmodified input for rebuilding temporary sources; no back-reference.
var derivation_base: PlayerStats = null
var derivation_error: String = ""

const MIN_DAMAGE_BASE := 1.0
const MIN_DAMAGE_MULTIPLIER := 0.05


func weapon_damage_range() -> Dictionary:
	return {
		"min": weapon_damage_min,
		"max": weapon_damage_max,
		"tier": weapon_damage_tier,
		"weapon_id": weapon_damage_weapon_id,
		"uses_fallback": weapon_damage_uses_fallback,
		"fallback_reason": weapon_damage_fallback_reason,
	}


func physical_damage_buckets() -> Dictionary:
	if physical_damage_uses_buckets:
		return {
			"legacy": 1.0,
			"gear": gear_physical_damage_multiplier,
			"talent": talent_physical_damage_multiplier * temporary_physical_multiplier * derived_physical_multiplier,
		}
	return {
		"legacy": physical_damage_multiplier,
		"gear": 1.0,
		"talent": temporary_physical_multiplier * derived_physical_multiplier,
	}


func sync_physical_damage_multiplier() -> void:
	physical_damage_multiplier = maxf(MIN_DAMAGE_MULTIPLIER, gear_physical_damage_multiplier * talent_physical_damage_multiplier * temporary_physical_multiplier * derived_physical_multiplier)


func sync_elemental_damage_multiplier() -> void:
	elemental_damage_multiplier = maxf(MIN_DAMAGE_MULTIPLIER, gear_elemental_damage_multiplier * talent_elemental_damage_multiplier * temporary_elemental_multiplier * derived_elemental_multiplier)


func sync_poison_damage_per_tick() -> void:
	var base_damage := base_poison_damage + bonus_base_elemental_damage
	if base_poison_damage > 0.0 or bonus_base_elemental_damage != 0.0:
		base_damage = maxf(MIN_DAMAGE_BASE, base_damage)
	poison_damage_per_tick = maxf(0.0, base_damage * elemental_damage_multiplier)

# Build-resolved Legendary descriptors and replaceable live contributions.
@export var legendary_signet := false
@export var legendary_crown := false
@export var legendary_coin := false
@export var legendary_bandit := false
@export var legendary_coin_applied := false
@export var legendary_added_ias := 0.0
@export var legendary_added_physical := 0.0
@export var legendary_added_flat := 0.0

@export var legendary_serpents_scales := false
@export var legendary_golden_greeves := false
@export var legendary_arctic_mittens := false
@export var legendary_hands_of_the_lightning_lord := false
