extends RefCounted
## Legal scale-1/depth-12 endpoints, not seeded drops or earned-run claims.
## Complete production rarity shapes, pool membership and canonical uniqueness
## are validated before values are replaced with exact generator endpoints.
const Catalog = preload("res://scripts/systems/stat_catalog.gd")

static func unique(slot: int, special: String, rare: String = "", basics: Array = []) -> GearItem:
	var chosen := basics.duplicate()
	for row in Catalog.pool_for_slot(slot, "basic"):
		if chosen.size() == 3: break
		if row.stat_id != rare and not chosen.has(row.stat_id): chosen.append(row.stat_id)
	assert(chosen.size() == 3)
	if rare == "":
		for row in Catalog.pool_for_slot(slot, "rare"):
			if not chosen.has(row.stat_id):
				rare = row.stat_id
				break
	var rolls: Array = []
	for id in chosen: rolls.append(roll("basic", id))
	rolls.append(roll("rare", rare))
	rolls.append(roll("special", special))
	return endpoint(slot, GearItem.Tier.UNIQUE, rolls)

static func chaos(slot: int, id: String, category: String = "rare") -> GearItem:
	return endpoint(slot, GearItem.Tier.CHAOS, [roll(category, id), roll(category, id), roll(category, id), roll(category, id)])

static func basic(slot: int, id: String = "increased_gold") -> GearItem:
	return endpoint(slot, GearItem.Tier.BASIC, [roll("basic", id)])

static func roll(category: String, id: String) -> Dictionary:
	return {"category": category, "is_drawback": false, "forced_stat_id": id}

static func endpoint(slot: int, tier: int, rolls: Array) -> GearItem:
	var expected: Dictionary = GearGenerator.rarity_roll_plan(tier)
	assert((expected.roll_count if tier == GearItem.Tier.CHAOS else expected.rolls.size()) == rolls.size())
	for i in rolls.size():
		if tier == GearItem.Tier.CHAOS:
			assert(rolls[i].category in ["basic", "rare"])
		else:
			assert(expected.rolls[i].category == rolls[i].category)
	var rng := RandomNumberGenerator.new()
	rng.seed = 271026
	var generated := GearGenerator._affixes_for_rolls(slot, tier, rolls, rng, 1.0, 12)
	assert(generated.errors.is_empty(), str(generated.errors))
	var affixes: Array[StatModifier] = generated.affixes
	for i in affixes.size():
		var m: StatModifier = affixes[i]
		if Catalog.is_binary(m.stat_id):
			assert(m.value == 1.0)
		else:
			var maximum := GearGenerator.max_rolled_value_for_stat_id(m.stat_id, slot, false, tier, 1.0, 12, rolls[i].category)
			assert(maximum.ok, str(maximum))
			m.value = maximum.value
	var request := GearGenerator._normalized_generation_request({"slot": slot, "tier": tier, "rng": rng,
		"id": "gear.fixture.m9_t9.%s.%s" % [slot, tier], "deterministic_key": "m9_t9_endpoint",
		"value_scale": 1.0, "contract_depth": 12, "source_context": "m9_t9_legal_endpoint"})
	assert(GearGenerator._generation_request_errors(request).is_empty())
	return GearGenerator._generate_item_unchecked(request, affixes)

static func ordinary() -> Array[GearItem]:
	return [basic(0), basic(3), basic(4), basic(1), basic(2), basic(5), basic(6)]

static func put(items: Array[GearItem], item: GearItem) -> void:
	for i in items.size():
		if items[i].slot == item.slot:
			items[i] = item
			return
	assert(false, "Fixture slot absent")

static func legendary(items: Array[GearItem], name: String) -> void:
	put(items, load("res://data/gear/" + name + ".tres"))
