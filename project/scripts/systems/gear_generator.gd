class_name GearGenerator
extends RefCounted
## Procedural gear generation. P5M5 owns the request/result contract, rarity
## roll shapes, slot-aware pool selection, duplicate validation, value rolling,
## drawbacks, Chaos, Unique Specials, and Legendary boundaries.

const StatCatalog := preload("res://scripts/systems/stat_catalog.gd")

const AFFIX_POOL: Array[StatModifier.StatType] = [
	StatModifier.StatType.ATTACK_SPEED,
	StatModifier.StatType.CRIT_CHANCE,
	StatModifier.StatType.CRIT_MULTIPLIER,
	StatModifier.StatType.POISON_DAMAGE,
	StatModifier.StatType.PHYSICAL_DAMAGE,
	StatModifier.StatType.POISON_STACKS_APPLIED,
	StatModifier.StatType.ARMOR_REDUCTION,
]

const DOWNSIDE_POOL: Array[StatModifier.StatType] = [
	StatModifier.StatType.ATTACK_SPEED,
	StatModifier.StatType.CRIT_CHANCE,
	StatModifier.StatType.CRIT_MULTIPLIER,
	StatModifier.StatType.POISON_DAMAGE,
	StatModifier.StatType.PHYSICAL_DAMAGE,
	StatModifier.StatType.POISON_STACKS_APPLIED,
]

const OPERATION := {
	StatModifier.StatType.ATTACK_SPEED: StatModifier.OperationType.ADD,
	StatModifier.StatType.CRIT_CHANCE: StatModifier.OperationType.ADD,
	StatModifier.StatType.CRIT_MULTIPLIER: StatModifier.OperationType.ADD,
	StatModifier.StatType.POISON_DAMAGE: StatModifier.OperationType.ADD,
	StatModifier.StatType.PHYSICAL_DAMAGE: StatModifier.OperationType.MULTIPLY,
	StatModifier.StatType.POISON_STACKS_APPLIED: StatModifier.OperationType.ADD,
	StatModifier.StatType.ARMOR_REDUCTION: StatModifier.OperationType.ADD,
}

const BASIC_VALUE := {
	StatModifier.StatType.ATTACK_SPEED: 0.08,
	StatModifier.StatType.CRIT_CHANCE: 0.05,
	StatModifier.StatType.CRIT_MULTIPLIER: 0.20,
	StatModifier.StatType.POISON_DAMAGE: 4.0,
	StatModifier.StatType.PHYSICAL_DAMAGE: 1.08,
	StatModifier.StatType.POISON_STACKS_APPLIED: 1.0,
	StatModifier.StatType.ARMOR_REDUCTION: 10.0,
}

const MASTER_VALUE := {
	StatModifier.StatType.ATTACK_SPEED: 0.10,
	StatModifier.StatType.CRIT_CHANCE: 0.06,
	StatModifier.StatType.CRIT_MULTIPLIER: 0.25,
	StatModifier.StatType.POISON_DAMAGE: 6.0,
	StatModifier.StatType.PHYSICAL_DAMAGE: 1.10,
	StatModifier.StatType.POISON_STACKS_APPLIED: 1.0,
	StatModifier.StatType.ARMOR_REDUCTION: 15.0,
}

const CURSED_AMPLIFIED_VALUE := {
	StatModifier.StatType.ATTACK_SPEED: 0.20,
	StatModifier.StatType.CRIT_CHANCE: 0.12,
	StatModifier.StatType.CRIT_MULTIPLIER: 0.50,
	StatModifier.StatType.POISON_DAMAGE: 12.0,
	StatModifier.StatType.PHYSICAL_DAMAGE: 1.20,
	StatModifier.StatType.POISON_STACKS_APPLIED: 2.0,
	StatModifier.StatType.ARMOR_REDUCTION: 30.0,
}

const CURSED_DOWNSIDE_VALUE := {
	StatModifier.StatType.ATTACK_SPEED: -0.08,
	StatModifier.StatType.CRIT_CHANCE: -0.05,
	StatModifier.StatType.CRIT_MULTIPLIER: -0.20,
	StatModifier.StatType.POISON_DAMAGE: -4.0,
	StatModifier.StatType.PHYSICAL_DAMAGE: 0.92,
	StatModifier.StatType.POISON_STACKS_APPLIED: -1.0,
}

const PRICE_BY_TIER := {
	GearItem.Tier.CRUDE: 0,
	GearItem.Tier.BASIC: 18,
	GearItem.Tier.MASTER: 32,
	GearItem.Tier.EPIC: 46,
	GearItem.Tier.CURSED: 40,
	GearItem.Tier.CHAOS: 55,
	GearItem.Tier.UNIQUE: 70,
	GearItem.Tier.LEGENDARY: 80,
}

const TIER_NAMES := {
	GearItem.Tier.CRUDE: "Crude",
	GearItem.Tier.BASIC: "Basic",
	GearItem.Tier.MASTER: "Master",
	GearItem.Tier.EPIC: "Epic",
	GearItem.Tier.CURSED: "Cursed",
	GearItem.Tier.CHAOS: "Chaos",
	GearItem.Tier.UNIQUE: "Unique",
	GearItem.Tier.LEGENDARY: "Legendary",
}

const SLOT_NAMES := {
	GearItem.SlotType.WEAPON: "Dagger",
	GearItem.SlotType.HELM: "Hood",
	GearItem.SlotType.ARMOR: "Doublet",
	GearItem.SlotType.TRINKET: "Ring",
	GearItem.SlotType.CHARM: "Necklace",
	GearItem.SlotType.LEGS: "Pants",
	GearItem.SlotType.HANDS: "Gloves",
}

const SLOT_TAGS := {
	GearItem.SlotType.WEAPON: "Weapon",
	GearItem.SlotType.HELM: "Helm",
	GearItem.SlotType.ARMOR: "Armor",
	GearItem.SlotType.TRINKET: "Trinket",
	GearItem.SlotType.CHARM: "Charm",
	GearItem.SlotType.LEGS: "Legs",
	GearItem.SlotType.HANDS: "Hands",
}

const PREFIX_BY_STAT := {
	StatModifier.StatType.ATTACK_SPEED: "Swift",
	StatModifier.StatType.CRIT_CHANCE: "Sharp",
	StatModifier.StatType.CRIT_MULTIPLIER: "Savage",
	StatModifier.StatType.POISON_DAMAGE: "Lethal",
	StatModifier.StatType.PHYSICAL_DAMAGE: "Brutal",
	StatModifier.StatType.POISON_STACKS_APPLIED: "Poison",
	StatModifier.StatType.ARMOR_REDUCTION: "Bloody",
	StatModifier.StatType.GOLD_REWARDS: "Greedy",
}

const SUFFIX_BY_STAT := {
	StatModifier.StatType.ATTACK_SPEED: "of Speed",
	StatModifier.StatType.CRIT_CHANCE: "of Sharpness",
	StatModifier.StatType.CRIT_MULTIPLIER: "of Savagery",
	StatModifier.StatType.POISON_DAMAGE: "of Lethality",
	StatModifier.StatType.PHYSICAL_DAMAGE: "of Brutality",
	StatModifier.StatType.POISON_STACKS_APPLIED: "of Poisoning",
	StatModifier.StatType.ARMOR_REDUCTION: "of Rending",
	StatModifier.StatType.GOLD_REWARDS: "of Avarice",
}

const PREFIX_BY_CANONICAL_STAT := {
	StatCatalog.COOLDOWN_REDUCTION: "Hastened",
	StatCatalog.INCREASED_BUFF_DURATION: "Enduring",
	StatCatalog.CRIT_APPLIES_PENETRATION: "Piercing",
	StatCatalog.CRIT_APPLIES_POTENCY: "Potent",
	StatCatalog.INVENTORY_ECONOMY_STATS: "Prosperous",
	StatCatalog.CHANCE_FOR_RETRIGGER: "Echoing",
	StatCatalog.CHANCE_TO_SHRED: "Rending",
	StatCatalog.CHANCE_TO_DECAY: "Decaying",
	StatCatalog.CRIT_APPLIES_ELEMENT: "Venomous",
}
const SUFFIX_BY_CANONICAL_STAT := {
	StatCatalog.COOLDOWN_REDUCTION: "of Readiness",
	StatCatalog.INCREASED_BUFF_DURATION: "of Endurance",
	StatCatalog.CRIT_APPLIES_PENETRATION: "of Penetration",
	StatCatalog.CRIT_APPLIES_POTENCY: "of Potency",
	StatCatalog.INVENTORY_ECONOMY_STATS: "of Prosperity",
	StatCatalog.CHANCE_FOR_RETRIGGER: "of Echoes",
	StatCatalog.CHANCE_TO_SHRED: "of Rending",
	StatCatalog.CHANCE_TO_DECAY: "of Decay",
	StatCatalog.CRIT_APPLIES_ELEMENT: "of Venom",
}

const ALL_SLOTS: Array[GearItem.SlotType] = [
	GearItem.SlotType.WEAPON,
	GearItem.SlotType.HELM,
	GearItem.SlotType.ARMOR,
	GearItem.SlotType.TRINKET,
	GearItem.SlotType.CHARM,
	GearItem.SlotType.LEGS,
	GearItem.SlotType.HANDS,
]

# P5M5 procedural rolling excludes Crude starter gear and fixed Legendary gear.
const ACTIVE_GENERATED_TIERS: Array[GearItem.Tier] = [
	GearItem.Tier.BASIC,
	GearItem.Tier.MASTER,
	GearItem.Tier.EPIC,
	GearItem.Tier.CURSED,
	GearItem.Tier.CHAOS,
	GearItem.Tier.UNIQUE,
]

const PHASE5_ALL_SLOTS: Array[GearItem.SlotType] = [
	GearItem.SlotType.WEAPON,
	GearItem.SlotType.HELM,
	GearItem.SlotType.ARMOR,
	GearItem.SlotType.TRINKET,
	GearItem.SlotType.CHARM,
	GearItem.SlotType.LEGS,
	GearItem.SlotType.HANDS,
]
const PHASE5_ALL_TIERS: Array[GearItem.Tier] = [
	GearItem.Tier.CRUDE,
	GearItem.Tier.BASIC,
	GearItem.Tier.MASTER,
	GearItem.Tier.EPIC,
	GearItem.Tier.CURSED,
	GearItem.Tier.CHAOS,
	GearItem.Tier.UNIQUE,
	GearItem.Tier.LEGENDARY,
]

const DEFAULT_GENERATED_SOURCE_CONTEXT := "procedural"
const PLACEHOLDER_BINARY_VALUE := 1.0
const CONTRACT_DEPTH_VALUE_MIN := 1
const CONTRACT_DEPTH_VALUE_MAX := 12
const CONTRACT_DEPTH_VALUE_MAX_BONUS := 0.35
const CHAOS_ROLL_COUNT := 4
const CHAOS_OUTCOME_BASIC := "basic_positive"
const CHAOS_OUTCOME_RARE := "rare_positive"
const CHAOS_OUTCOME_DRAWBACK := "basic_drawback"
const CHAOS_OUTCOME_WEIGHTS := [
	{"outcome": CHAOS_OUTCOME_BASIC, "weight": 5},
	{"outcome": CHAOS_OUTCOME_RARE, "weight": 4},
	{"outcome": CHAOS_OUTCOME_DRAWBACK, "weight": 5},
]


static func price_for_tier(tier: GearItem.Tier) -> int:
	return PRICE_BY_TIER.get(tier, PRICE_BY_TIER[GearItem.Tier.BASIC])


static func tier_name(tier: int) -> String:
	return TIER_NAMES.get(tier, "Gear")


static func tier_color(tier: int) -> Color:
	match tier:
		GearItem.Tier.CRUDE:
			return UIColors.TIER_CRUDE
		GearItem.Tier.BASIC:
			return UIColors.TIER_BASIC
		GearItem.Tier.MASTER:
			return UIColors.TIER_MASTER
		GearItem.Tier.EPIC:
			return UIColors.TIER_EPIC
		GearItem.Tier.CURSED:
			return UIColors.TIER_CURSED
		GearItem.Tier.CHAOS:
			return UIColors.TIER_CHAOS
		GearItem.Tier.UNIQUE:
			return UIColors.TIER_UNIQUE
		GearItem.Tier.LEGENDARY:
			return UIColors.TIER_LEGENDARY
	return UIColors.TIER_BASIC


static func is_procedural_tier(tier: int) -> bool:
	return ACTIVE_GENERATED_TIERS.has(tier)


static func requires_fixed_catalog(tier: int) -> bool:
	return tier == GearItem.Tier.LEGENDARY


static func universal_slot_label(slot: GearItem.SlotType) -> String:
	return SLOT_TAGS.get(slot, "Unknown Slot")


static func rogue_item_family_for_slot(slot: GearItem.SlotType) -> String:
	return SLOT_NAMES.get(slot, universal_slot_label(slot))


static func item_family_for(item: GearItem) -> String:
	if item == null:
		return ""
	if item.item_family != "":
		return item.item_family
	if item.class_family == GearItem.ClassFamily.ROGUE:
		return rogue_item_family_for_slot(item.slot)
	return universal_slot_label(item.slot)


static func generate(tier: GearItem.Tier, slot: GearItem.SlotType, rng: RandomNumberGenerator, stable_id: String = "") -> GearItem:
	var result := generate_from_request({
		"tier": tier,
		"slot": slot,
		"rng": rng,
		"deterministic_key": stable_id,
		"id": stable_id,
		"source_context": "legacy_generate",
		"source_seed": int(rng.seed) if rng != null else 0,
	})
	return result.get("item")


static func generate_from_request(request: Dictionary) -> Dictionary:
	var normalized := _normalized_generation_request(request)
	var errors := _generation_request_errors(normalized)
	if not errors.is_empty():
		return _generation_result(null, errors, normalized)

	var rng: RandomNumberGenerator = normalized["rng"]
	var affix_result := _affixes_for_tier(
		int(normalized["tier"]),
		int(normalized["slot"]),
		rng,
		float(normalized["value_scale"]),
		int(normalized["contract_depth"])
	)
	var affix_errors: PackedStringArray = affix_result["errors"]
	if not affix_errors.is_empty():
		return _generation_result(null, affix_errors, normalized)
	var item := _generate_item_unchecked(normalized, affix_result["affixes"])
	return _generation_result(item, [], normalized)


static func stat_roll_key(deterministic_key: String, roll_index: int, purpose: String = "stat") -> String:
	return "%s|%s|%d" % [deterministic_key, purpose, roll_index]


static func _generate_item_unchecked(request: Dictionary, affixes: Array[StatModifier]) -> GearItem:
	var rng: RandomNumberGenerator = request["rng"]
	var stable_id := String(request["id"])
	var deterministic_key := String(request["deterministic_key"])
	var slot := int(request["slot"])
	var item := GearItem.new()
	item.id = stable_id if stable_id != "" else "gear.generated_%d" % rng.randi()
	item.slot = slot
	item.tier = int(request["tier"])
	item.item_family = rogue_item_family_for_slot(slot)
	item.class_family = GearItem.ClassFamily.ROGUE
	item.source_kind = GearItem.SourceKind.GENERATED
	item.source_context = String(request["source_context"])
	item.source_seed = int(request["source_seed"])
	item.deterministic_key = deterministic_key if deterministic_key != "" else stable_id
	item.generation_value_scale = float(request.get("value_scale", 1.0))
	item.generation_contract_depth = int(request.get("contract_depth", 0))
	item.affixes = affixes
	item.display_name = _display_name_for(item)
	return item


static func _normalized_generation_request(request: Dictionary) -> Dictionary:
	var normalized := request.duplicate(true)
	if not normalized.has("rarity") and normalized.has("tier"):
		normalized["rarity"] = int(normalized["tier"])
	if not normalized.has("tier") and normalized.has("rarity"):
		normalized["tier"] = int(normalized["rarity"])
	if not normalized.has("source_kind"):
		normalized["source_kind"] = GearItem.SourceKind.GENERATED
	if not normalized.has("source_context"):
		normalized["source_context"] = DEFAULT_GENERATED_SOURCE_CONTEXT
	if not normalized.has("source_seed"):
		normalized["source_seed"] = 0
	if not normalized.has("contract_depth"):
		normalized["contract_depth"] = 0
	if not normalized.has("value_scale"):
		normalized["value_scale"] = 1.0
	if not normalized.has("deterministic_key"):
		normalized["deterministic_key"] = String(normalized.get("id", ""))
	if not normalized.has("id"):
		normalized["id"] = String(normalized.get("deterministic_key", ""))
	if not normalized.has("rng"):
		var rng := RandomNumberGenerator.new()
		rng.seed = int(normalized.get("seed", normalized.get("source_seed", 0)))
		normalized["rng"] = rng
	return normalized


static func _generation_request_errors(request: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if not request.has("slot"):
		errors.append("missing_slot")
	# Acquisition follows the stable seven-slot order.
	elif not ALL_SLOTS.has(int(request["slot"])):
		errors.append("invalid_slot:%s" % str(request["slot"]))
	if not request.has("tier"):
		errors.append("missing_rarity")
	elif not GearItem.rarity_order().has(int(request["tier"])):
		errors.append("invalid_rarity:%s" % str(request["tier"]))
	elif int(request["tier"]) == GearItem.Tier.CRUDE:
		errors.append("crude_is_starter_only")
	elif requires_fixed_catalog(int(request["tier"])):
		errors.append("legendary_requires_fixed_catalog")
	if int(request.get("source_kind", GearItem.SourceKind.GENERATED)) != GearItem.SourceKind.GENERATED:
		errors.append("procedural_source_kind_required")
	if not request.get("rng") is RandomNumberGenerator:
		errors.append("missing_rng")
	if not is_finite(float(request.get("value_scale", 1.0))) or float(request.get("value_scale", 1.0)) <= 0.0:
		errors.append("invalid_value_scale")
	return errors


static func _generation_result(item: GearItem, errors: PackedStringArray, request: Dictionary) -> Dictionary:
	return {
		"ok": item != null and errors.is_empty(),
		"item": item,
		"errors": errors,
		"request": request,
	}


static func rarity_roll_plan(tier: int) -> Dictionary:
	var rolls: Array[Dictionary] = []
	match tier:
		GearItem.Tier.BASIC:
			rolls = [_roll_spec(StatCatalog.CATEGORY_BASIC)]
		GearItem.Tier.MASTER:
			rolls = [_roll_spec(StatCatalog.CATEGORY_BASIC), _roll_spec(StatCatalog.CATEGORY_BASIC)]
		GearItem.Tier.EPIC:
			rolls = [
				_roll_spec(StatCatalog.CATEGORY_BASIC),
				_roll_spec(StatCatalog.CATEGORY_BASIC),
				_roll_spec(StatCatalog.CATEGORY_RARE),
			]
		GearItem.Tier.CURSED:
			rolls = cursed_roll_plan()
		GearItem.Tier.CHAOS:
			return {
				"ok": true,
				"errors": PackedStringArray(),
				"rolls": rolls,
				"variable": true,
				"roll_count": CHAOS_ROLL_COUNT,
				"outcomes": chaos_outcome_weights(),
			}
		GearItem.Tier.UNIQUE:
			rolls = unique_roll_plan()
		_:
			return {"ok": false, "errors": PackedStringArray(["unsupported_procedural_rarity:%s" % tier]), "rolls": rolls}
	return {"ok": true, "errors": PackedStringArray(), "rolls": rolls}


static func cursed_roll_plan() -> Array[Dictionary]:
	return [
		_roll_spec(StatCatalog.CATEGORY_BASIC),
		_roll_spec(StatCatalog.CATEGORY_BASIC),
		_roll_spec(StatCatalog.CATEGORY_RARE),
		_roll_spec(StatCatalog.CATEGORY_BASIC, true),
	]


static func unique_roll_plan() -> Array[Dictionary]:
	return [
		_roll_spec(StatCatalog.CATEGORY_BASIC),
		_roll_spec(StatCatalog.CATEGORY_BASIC),
		_roll_spec(StatCatalog.CATEGORY_BASIC),
		_roll_spec(StatCatalog.CATEGORY_RARE),
		_roll_spec(StatCatalog.CATEGORY_SPECIAL),
	]


static func chaos_roll_plan(slot: GearItem.SlotType, rng: RandomNumberGenerator) -> Dictionary:
	var rolls: Array[Dictionary] = []
	for i in CHAOS_ROLL_COUNT:
		var eligible_outcomes := _eligible_chaos_outcomes_for_slot(slot, {})
		if eligible_outcomes.is_empty():
			return {"ok": false, "errors": PackedStringArray(["insufficient_chaos_pool:%s" % universal_slot_label(slot)]), "rolls": rolls}
		var outcome := _pick_chaos_outcome(eligible_outcomes, rng)
		var roll := _roll_spec_for_chaos_outcome(outcome)
		var pool := _pool_for_roll_spec(slot, roll)
		var stat_id := _pick_stat_id_from_pool(pool, {}, rng)
		if stat_id == "":
			return {
				"ok": false,
				"errors": PackedStringArray(["insufficient_%s_pool:%s" % [_pool_error_category(String(roll.get("category", "")), bool(roll.get("is_drawback", false))), universal_slot_label(slot)]]),
				"rolls": rolls,
			}
		roll["forced_stat_id"] = stat_id
		rolls.append(roll)
	return {"ok": true, "errors": PackedStringArray(), "rolls": rolls}


static func chaos_outcome_weights() -> Array[Dictionary]:
	return CHAOS_OUTCOME_WEIGHTS.duplicate(true)


static func _roll_spec(category: String, is_drawback: bool = false) -> Dictionary:
	return {"category": category, "is_drawback": is_drawback}


## Generates a fixed-size, seeded batch of shop offers across random
## slots/tiers -- mirrors Current_Mechanics_Reference.md's "generated shop
## gear is seeded" convention (simplified: no run/route/context seeding
## since there's no branching route in P2:M5).
static func generate_offers(count: int, rng_seed: int) -> Array[GearItem]:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var offers: Array[GearItem] = []
	for i in count:
		var slot: GearItem.SlotType = ALL_SLOTS[rng.randi_range(0, ALL_SLOTS.size() - 1)]
		var tier: GearItem.Tier = ACTIVE_GENERATED_TIERS[rng.randi_range(0, ACTIVE_GENERATED_TIERS.size() - 1)]
		var stable_id := "gear.generated.offer_%d_%d" % [rng_seed, i]
		offers.append(generate_from_request({
			"tier": tier,
			"slot": slot,
			"rng": rng,
			"id": stable_id,
			"deterministic_key": stable_id,
			"source_context": "standalone_offer",
			"source_seed": rng_seed,
		}).get("item"))
	return offers


static func _affixes_for_tier(
	tier: GearItem.Tier,
	slot: GearItem.SlotType,
	rng: RandomNumberGenerator,
	value_scale: float = 1.0,
	contract_depth: int = 0
) -> Dictionary:
	var plan := chaos_roll_plan(slot, rng) if tier == GearItem.Tier.CHAOS else rarity_roll_plan(tier)
	if not bool(plan.get("ok", false)):
		return {"affixes": [] as Array[StatModifier], "errors": plan.get("errors", PackedStringArray())}
	return _affixes_for_rolls(slot, tier, plan["rolls"], rng, value_scale, contract_depth)


static func _affixes_for_rolls(
	slot: GearItem.SlotType,
	tier: GearItem.Tier,
	rolls: Array,
	rng: RandomNumberGenerator,
	value_scale: float = 1.0,
	contract_depth: int = 0
) -> Dictionary:
	var affixes: Array[StatModifier] = []
	var errors := PackedStringArray()
	var allow_duplicates := tier == GearItem.Tier.CHAOS
	errors.append_array(_validate_roll_plan_for_slot(slot, rolls, allow_duplicates))
	if not errors.is_empty():
		return {"affixes": affixes, "errors": errors}
	var used_stat_ids := {}
	for roll in rolls:
		var category := String(roll.get("category", ""))
		var is_drawback := bool(roll.get("is_drawback", false))
		var pool := _pool_for_roll_spec(slot, roll)
		var stat_id := _forced_stat_id_for_roll(roll, pool, {} if allow_duplicates else used_stat_ids)
		if stat_id == "":
			stat_id = _pick_stat_id_from_pool(pool, {} if allow_duplicates else used_stat_ids, rng)
		if stat_id == "":
			errors.append("insufficient_%s_pool:%s" % ["drawback" if is_drawback else category, universal_slot_label(slot)])
			continue
		if not allow_duplicates:
			used_stat_ids[stat_id] = true
		var modifier_result := _make_modifier_from_stat_id(
			stat_id,
			category,
			is_drawback,
			tier,
			slot,
			rng,
			value_scale,
			contract_depth
		)
		if not bool(modifier_result.get("ok", false)):
			errors.append(String(modifier_result.get("error", "invalid_modifier_value")))
			continue
		affixes.append(modifier_result["modifier"])
	return {"affixes": affixes, "errors": errors}


static func _validate_roll_plan_for_slot(slot: GearItem.SlotType, rolls: Array, allow_duplicates: bool = false) -> PackedStringArray:
	var errors := PackedStringArray()
	var reserved_stat_ids := {}
	for roll in rolls:
		var category := String(roll.get("category", ""))
		var is_drawback := bool(roll.get("is_drawback", false))
		var pool := _pool_for_roll_spec(slot, roll)
		if roll.has("forced_stat_id"):
			var forced_id := _forced_stat_id_for_roll(roll, pool, {} if allow_duplicates else reserved_stat_ids)
			if forced_id == "":
				errors.append("insufficient_%s_pool:%s" % [_pool_error_category(category, is_drawback), universal_slot_label(slot)])
				continue
			if not allow_duplicates:
				reserved_stat_ids[forced_id] = true
			continue
		var candidate_ids := _eligible_stat_ids_from_pool(pool, {} if allow_duplicates else reserved_stat_ids)
		if candidate_ids.is_empty():
			errors.append("insufficient_%s_pool:%s" % [_pool_error_category(category, is_drawback), universal_slot_label(slot)])
			continue
		if not allow_duplicates:
			reserved_stat_ids[candidate_ids[0]] = true
	return errors


static func _pool_for_roll_spec(slot: GearItem.SlotType, roll: Dictionary) -> Array[Dictionary]:
	var category := String(roll.get("category", ""))
	var is_drawback := bool(roll.get("is_drawback", false))
	return StatCatalog.drawback_pool_for_slot(slot) if is_drawback else StatCatalog.pool_for_slot(slot, category)


static func _forced_stat_id_for_roll(roll: Dictionary, pool: Array[Dictionary], used_stat_ids: Dictionary) -> String:
	if not roll.has("forced_stat_id"):
		return ""
	var forced_id := StatCatalog.canonicalize_stat_id(String(roll.get("forced_stat_id", "")))
	if forced_id == "" or used_stat_ids.has(forced_id):
		return ""
	var candidate_ids := _eligible_stat_ids_from_pool(pool, used_stat_ids)
	if not candidate_ids.has(forced_id):
		return ""
	return forced_id


static func _eligible_chaos_outcomes_for_slot(slot: GearItem.SlotType, used_stat_ids: Dictionary) -> Array[Dictionary]:
	var outcomes: Array[Dictionary] = []
	for entry in CHAOS_OUTCOME_WEIGHTS:
		var outcome := String(entry.get("outcome", ""))
		var roll := _roll_spec_for_chaos_outcome(outcome)
		if roll.is_empty():
			continue
		if _eligible_stat_ids_from_pool(_pool_for_roll_spec(slot, roll), used_stat_ids).is_empty():
			continue
		outcomes.append({"outcome": outcome, "weight": int(entry.get("weight", 0))})
	return outcomes


static func _pick_chaos_outcome(outcomes: Array[Dictionary], rng: RandomNumberGenerator) -> String:
	var total_weight := 0
	for entry in outcomes:
		total_weight += int(entry.get("weight", 0))
	if total_weight <= 0:
		return String(outcomes.front().get("outcome", ""))
	var roll := rng.randi_range(1, total_weight)
	var cumulative := 0
	for entry in outcomes:
		cumulative += int(entry.get("weight", 0))
		if roll <= cumulative:
			return String(entry.get("outcome", ""))
	return String(outcomes.back().get("outcome", ""))


static func _roll_spec_for_chaos_outcome(outcome: String) -> Dictionary:
	match outcome:
		CHAOS_OUTCOME_BASIC:
			return _roll_spec(StatCatalog.CATEGORY_BASIC)
		CHAOS_OUTCOME_RARE:
			return _roll_spec(StatCatalog.CATEGORY_RARE)
		CHAOS_OUTCOME_DRAWBACK:
			return _roll_spec(StatCatalog.CATEGORY_BASIC, true)
	return {}


static func _pick_stat_id_from_pool(pool: Array[Dictionary], used_stat_ids: Dictionary, rng: RandomNumberGenerator) -> String:
	var candidates: Array[Dictionary] = []
	var total_weight := 0
	for entry in pool:
		var stat_id := StatCatalog.canonicalize_stat_id(String(entry.get("stat_id", "")))
		if stat_id == "" or used_stat_ids.has(stat_id):
			continue
		var weight := int(entry.get("weight", 0))
		if weight <= 0:
			continue
		total_weight += weight
		candidates.append({"stat_id": stat_id, "weight": weight})
	if candidates.is_empty():
		return ""
	var roll := rng.randi_range(1, total_weight)
	var cumulative := 0
	for candidate in candidates:
		cumulative += int(candidate["weight"])
		if roll <= cumulative:
			return String(candidate["stat_id"])
	return String(candidates.back()["stat_id"])


static func _eligible_stat_ids_from_pool(pool: Array[Dictionary], used_stat_ids: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for entry in pool:
		var stat_id := StatCatalog.canonicalize_stat_id(String(entry.get("stat_id", "")))
		if stat_id == "" or used_stat_ids.has(stat_id):
			continue
		if int(entry.get("weight", 0)) <= 0:
			continue
		if not ids.has(stat_id):
			ids.append(stat_id)
	return ids


static func _pool_error_category(category: String, is_drawback: bool) -> String:
	if is_drawback:
		return "drawback"
	return category


static func _pick_distinct(pool: Array[StatModifier.StatType], count: int, rng: RandomNumberGenerator) -> Array[StatModifier.StatType]:
	var remaining: Array[StatModifier.StatType] = pool.duplicate()
	var picked: Array[StatModifier.StatType] = []
	while picked.size() < count and not remaining.is_empty():
		var index: int = rng.randi_range(0, remaining.size() - 1)
		picked.append(remaining[index])
		remaining.remove_at(index)
	return picked


static func _make_modifier(
	stat: StatModifier.StatType,
	value: float,
	category: StatModifier.StatCategory = StatModifier.StatCategory.COMPATIBILITY,
	is_drawback: bool = false
) -> StatModifier:
	var modifier := StatModifier.new()
	modifier.stat_id = StatCatalog.legacy_stat_id(stat)
	modifier.stat = stat
	modifier.category = category
	modifier.operation = OPERATION[stat]
	modifier.value = value
	modifier.is_drawback = is_drawback
	return modifier


static func _make_modifier_from_stat_id(
	stat_id: String,
	category: String,
	is_drawback: bool,
	tier: int,
	slot: GearItem.SlotType,
	rng: RandomNumberGenerator,
	value_scale: float,
	contract_depth: int
) -> Dictionary:
	var value_result := _roll_value_for_stat_id(stat_id, slot, is_drawback, tier, rng, value_scale, contract_depth, category)
	if not bool(value_result.get("ok", false)):
		return {"ok": false, "modifier": null, "error": String(value_result.get("error", "missing_value"))}
	var modifier := StatModifier.new()
	modifier.stat_id = stat_id
	modifier.stat = _legacy_stat_for_stat_id(stat_id)
	modifier.category = _modifier_category_for(category, is_drawback)
	modifier.operation = StatModifier.OperationType.ADD
	modifier.value = float(value_result["value"])
	modifier.is_drawback = is_drawback
	modifier.display_label = StatCatalog.label_for(stat_id)
	return {"ok": true, "modifier": modifier, "error": ""}


static func _legacy_stat_for_stat_id(stat_id: String) -> StatModifier.StatType:
	match StatCatalog.canonicalize_stat_id(stat_id):
		StatCatalog.BASE_DAMAGE:
			return StatModifier.StatType.PHYSICAL_DAMAGE
		StatCatalog.PERCENT_PHYSICAL_DAMAGE:
			return StatModifier.StatType.PHYSICAL_DAMAGE
		StatCatalog.INCREASED_ATTACK_SPEED:
			return StatModifier.StatType.ATTACK_SPEED
		StatCatalog.CRIT_CHANCE:
			return StatModifier.StatType.CRIT_CHANCE
		StatCatalog.CRIT_DAMAGE:
			return StatModifier.StatType.CRIT_MULTIPLIER
		StatCatalog.BASE_ELEMENTAL_DAMAGE:
			return StatModifier.StatType.POISON_DAMAGE
		StatCatalog.PERCENT_ELEMENTAL_DAMAGE:
			return StatModifier.StatType.POISON_DAMAGE
		StatCatalog.INCREASED_ALL_STACKS:
			return StatModifier.StatType.ARMOR_REDUCTION
		StatCatalog.INCREASED_GOLD:
			return StatModifier.StatType.GOLD_REWARDS
		StatCatalog.SHOP_DISCOUNT:
			return StatModifier.StatType.GOLD_REWARDS
		StatCatalog.INCREASED_MAGIC_FIND:
			return StatModifier.StatType.GOLD_REWARDS
	return StatModifier.StatType.ATTACK_SPEED


static func _modifier_category_for(category: String, is_drawback: bool) -> StatModifier.StatCategory:
	if is_drawback:
		return StatModifier.StatCategory.DRAWBACK
	match category:
		StatCatalog.CATEGORY_BASIC:
			return StatModifier.StatCategory.BASIC
		StatCatalog.CATEGORY_RARE:
			return StatModifier.StatCategory.RARE
		StatCatalog.CATEGORY_SPECIAL:
			return StatModifier.StatCategory.SPECIAL
	return StatModifier.StatCategory.COMPATIBILITY


static func _roll_value_for_stat_id(
	stat_id: String,
	slot: GearItem.SlotType,
	is_drawback: bool,
	tier: int,
	rng: RandomNumberGenerator,
	value_scale: float = 1.0,
	contract_depth: int = 0,
	category: String = StatCatalog.CATEGORY_BASIC
) -> Dictionary:
	if not is_finite(value_scale) or value_scale <= 0.0:
		return {"ok": false, "error": "invalid_value_scale"}
	if StatCatalog.is_binary(stat_id):
		return {"ok": true, "value": PLACEHOLDER_BINARY_VALUE, "error": ""}
	var range := StatCatalog.value_range_for_slot_category(slot, category, stat_id)
	if not bool(range.get("ok", false)):
		return {
			"ok": false,
			"value": 0.0,
			"error": "missing_value_range:%s:%s" % [universal_slot_label(slot), StatCatalog.canonicalize_stat_id(stat_id)],
		}
	var value := rng.randf_range(float(range["min"]), float(range["max"]))
	value *= _rarity_value_multiplier(tier, is_drawback)
	value *= value_scale
	value *= _contract_depth_value_scale(contract_depth)
	if not is_finite(value):
		return {"ok": false, "error": "non_finite_modifier_value"}
	var rounded := _round_value_for_stat_id(stat_id, value, is_drawback)
	if not is_finite(rounded):
		return {"ok": false, "error": "non_finite_modifier_value"}
	return {"ok": true, "value": rounded, "error": ""}


static func max_rolled_value_for_stat_id(
	stat_id: String,
	slot: GearItem.SlotType,
	is_drawback: bool,
	tier: int,
	value_scale: float = 1.0,
	contract_depth: int = 0,
	category: String = StatCatalog.CATEGORY_BASIC
) -> Dictionary:
	if not is_finite(value_scale) or value_scale <= 0.0:
		return {"ok": false, "value": 0.0, "error": "invalid_value_scale"}
	var canonical_id := StatCatalog.canonicalize_stat_id(stat_id)
	if StatCatalog.is_binary(canonical_id):
		return {"ok": false, "value": 0.0}
	var range := StatCatalog.value_range_for_slot_category(slot, category, canonical_id)
	if not bool(range.get("ok", false)):
		return {"ok": false, "value": 0.0}
	var magnitude := float(range["max"])
	magnitude *= absf(_rarity_value_multiplier(tier, is_drawback))
	magnitude *= value_scale
	magnitude *= _contract_depth_value_scale(contract_depth)
	var value := -magnitude if is_drawback else magnitude
	if not is_finite(value):
		return {"ok": false, "value": 0.0, "error": "non_finite_modifier_value"}
	var rounded := _round_value_for_stat_id(canonical_id, value, is_drawback)
	return {"ok": is_finite(rounded), "value": rounded if is_finite(rounded) else 0.0, "error": "" if is_finite(rounded) else "non_finite_modifier_value"}


static func _rarity_value_multiplier(tier: int, is_drawback: bool) -> float:
	match tier:
		GearItem.Tier.BASIC:
			return 1.0
		GearItem.Tier.MASTER:
			return 1.75
		GearItem.Tier.EPIC:
			return 2.0
		GearItem.Tier.CURSED:
			return -2.5 if is_drawback else 2.5
		GearItem.Tier.CHAOS:
			return -3.0 if is_drawback else 3.0
		GearItem.Tier.UNIQUE:
			return 2.0
	return 1.0


static func _contract_depth_value_scale(contract_depth: int) -> float:
	var depth := clampi(contract_depth, CONTRACT_DEPTH_VALUE_MIN, CONTRACT_DEPTH_VALUE_MAX)
	var depth_progress := float(depth - CONTRACT_DEPTH_VALUE_MIN) / float(CONTRACT_DEPTH_VALUE_MAX - CONTRACT_DEPTH_VALUE_MIN)
	return 1.0 + CONTRACT_DEPTH_VALUE_MAX_BONUS * depth_progress


static func _round_value_for_stat_id(stat_id: String, value: float, is_drawback: bool) -> float:
	var kind := StatCatalog.value_kind_for(stat_id)
	match kind:
		StatCatalog.VALUE_PERCENT, StatCatalog.VALUE_CHANCE:
			return round(value * 100.0) / 100.0
		StatCatalog.VALUE_FLAT, StatCatalog.VALUE_STACKS:
			var rounded: float = round(value)
			if not is_drawback and kind == StatCatalog.VALUE_STACKS:
				rounded = maxf(1.0, rounded)
			return rounded
	return value


static func _display_name_for(item: GearItem) -> String:
	var base_name := item_family_for(item)
	if item.affixes.is_empty():
		return "%s %s" % [tier_name(item.tier), base_name]
	var first_id := StatCatalog.canonical_id_for_modifier(item.affixes[0])
	var prefix: String = PREFIX_BY_CANONICAL_STAT.get(first_id, PREFIX_BY_STAT.get(item.affixes[0].stat, tier_name(item.tier)))
	if item.affixes.size() == 1:
		return "%s %s" % [prefix, base_name]
	var second_id := StatCatalog.canonical_id_for_modifier(item.affixes[1])
	var suffix: String = SUFFIX_BY_CANONICAL_STAT.get(second_id, SUFFIX_BY_STAT.get(item.affixes[1].stat, ""))
	return "%s %s %s" % [prefix, base_name, suffix]
