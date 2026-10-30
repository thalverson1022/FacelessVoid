extends RefCounted
## A legal depth-12 / value-scale-1 high-roll endpoint, not a searched optimum.
## No player stat overrides, carried items, gold, or Alchemist upgrades are used.
## Sources: docs/P6M8_T3_Gear_Stat_Implementation_Specification.md, slot tables
## and generation rules; GearGenerator._affixes_for_rolls / unique_roll_plan /
## chaos_roll_plan / max_rolled_value_for_stat_id; StatCatalog slot/category pools.
## Unique: 3 distinct Basic + 1 Rare + 1 Special. Chaos: 4 independently selected
## Basic-positive / Rare-positive / Basic-drawback outcomes (weights 5/4/5).
## These two Chaos outcomes contain 4 Rare positives and 0 drawbacks each.
## Duplicate Chaos IDs are genuinely generatable: every selection uses an empty
## used-ID set. Four Rare positives therefore do not require a synthetic shape.
## Values are exact rounded generator endpoints, not claimed RNG seed witnesses.

const Generator = preload("res://scripts/systems/gear_generator.gd")
const Catalog = preload("res://scripts/systems/stat_catalog.gd")
const DEPTH := 12
const VALUE_SCALE := 1.0


static func items() -> Array[GearItem]:
	var result: Array[GearItem] = [load("res://data/gear/nightkiss_kitana.tres")]
	# Unique multiplier 2 * depth multiplier 1.35 = 2.7.
	# Basic maxima: 2 stacks -> 5; .12 IAS -> .32; .08 crit -> .22.
	# Rare .08 CDR -> .22. Binary Special remains exactly 1.
	result.append(_endpoint_item(GearItem.SlotType.HELM, GearItem.Tier.UNIQUE, [
		_roll(Catalog.CATEGORY_BASIC, Catalog.INCREASED_ALL_STACKS),
		_roll(Catalog.CATEGORY_BASIC, Catalog.INCREASED_ATTACK_SPEED),
		_roll(Catalog.CATEGORY_BASIC, Catalog.CRIT_CHANCE),
		_roll(Catalog.CATEGORY_RARE, Catalog.COOLDOWN_REDUCTION),
		_roll(Catalog.CATEGORY_SPECIAL, Catalog.DOUBLE_APPLIED_STACKS),
	], "helm"))
	# Basic maxima: 2 stacks -> 5; .04 crit -> .11; .30 gold -> .81.
	# Rare .10 Shred chance -> .27; binary All Stats remains 1.
	result.append(_endpoint_item(GearItem.SlotType.ARMOR, GearItem.Tier.UNIQUE, [
		_roll(Catalog.CATEGORY_BASIC, Catalog.INCREASED_ALL_STACKS),
		_roll(Catalog.CATEGORY_BASIC, Catalog.CRIT_CHANCE),
		_roll(Catalog.CATEGORY_BASIC, Catalog.INCREASED_GOLD),
		_roll(Catalog.CATEGORY_RARE, Catalog.CHANCE_TO_SHRED),
		_roll(Catalog.CATEGORY_SPECIAL, Catalog.ALL_STATS_INCREASED),
	], "armor"))
	# Chaos multiplier 3 * 1.35 = 4.05: .06 Retrigger -> .24 per roll.
	var repeats: Array = []
	var cooldowns: Array = []
	for index in 4:
		repeats.append(_roll(Catalog.CATEGORY_RARE, Catalog.CHANCE_FOR_RETRIGGER))
		# Charm Rare .10 CDR * 4.05 -> .41 per roll.
		cooldowns.append(_roll(Catalog.CATEGORY_RARE, Catalog.COOLDOWN_REDUCTION))
	result.append(_endpoint_item(GearItem.SlotType.TRINKET, GearItem.Tier.CHAOS, repeats, "trinket"))
	result.append(_endpoint_item(GearItem.SlotType.CHARM, GearItem.Tier.CHAOS, cooldowns, "charm"))
	return result


static func _roll(category: String, stat_id: String) -> Dictionary:
	return {"category": category, "is_drawback": false, "forced_stat_id": stat_id}


static func _endpoint_item(slot: GearItem.SlotType, tier: GearItem.Tier, rolls: Array, suffix: String) -> GearItem:
	var rng := RandomNumberGenerator.new()
	rng.seed = 241024
	# This production path validates membership, category, duplicate eligibility,
	# modifier operation/sign and the complete requested roll plan before values.
	var generated := Generator._affixes_for_rolls(slot, tier, rolls, rng, VALUE_SCALE, DEPTH)
	assert(generated.errors.is_empty(), str(generated.errors))
	var affixes: Array[StatModifier] = generated.affixes
	for index in affixes.size():
		var modifier: StatModifier = affixes[index]
		if Catalog.is_binary(modifier.stat_id):
			assert(modifier.value == 1.0)
			continue
		var endpoint := Generator.max_rolled_value_for_stat_id(modifier.stat_id, slot, false, tier, VALUE_SCALE, DEPTH, rolls[index].category)
		assert(endpoint.ok, str(endpoint))
		modifier.value = float(endpoint.value)
	var request := Generator._normalized_generation_request({
		"tier": tier, "slot": slot, "rng": rng,
		"id": "gear.fixture.exsanguinate_top." + suffix,
		"deterministic_key": "exsanguinate_top_endpoint:" + suffix,
		"source_context": "balance_fixture_depth12_high_roll_endpoint",
		"source_seed": 0, "value_scale": VALUE_SCALE, "contract_depth": DEPTH,
	})
	assert(Generator._generation_request_errors(request).is_empty())
	return Generator._generate_item_unchecked(request, affixes)


## Read-only checks through production serialization, domain validation and load.
## SaveSystem validation alone does not establish generation eligibility; the
## actual generator plan/pool checks above supply that separate evidence.
static func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var gear := items()
	var slots := {}
	for item in gear:
		if item == null:
			errors.append("Missing fixture item.")
			continue
		if slots.has(item.slot):
			errors.append("Duplicate equipment slot: " + item.id)
		slots[item.slot] = true
		var payload: Variant = SaveSystem._gear_entry_to_data(item)
		var error := SaveSystem.gear_payload_error(payload, true)
		if error != "":
			errors.append(item.id + ": " + error)
		var restored: GearItem = SaveSystem._gear_from_save_entry(payload, "exsanguinate_top_fixture")
		if restored == null or restored.id != item.id or restored.affixes.size() != item.affixes.size():
			errors.append("Gear save round-trip failed: " + item.id)
		elif JSON.stringify(SaveSystem._gear_entry_to_data(restored)) != JSON.stringify(payload):
			errors.append("Gear save round-trip changed payload: " + item.id)
	if slots.size() != 5:
		errors.append("Expected exactly five different equipment slots.")
	return errors
