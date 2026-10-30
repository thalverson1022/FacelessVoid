extends SceneTree

const RunRngSystem := preload("res://scripts/systems/run_rng.gd")

var failures: Array[String] = []
var state: Node

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

# Frozen pre-change algorithm, including its original contextual RNG draw.
func legacy_roll(context: String, index: int, base_tier: int, depth: int, step: String, chance: int, magic_find: float) -> bool:
	var rng := RunRngSystem.rng_for_context(state.adventure_seed, RunRngSystem.CONTEXT_SHOP_OFFER,
		[context, "rarity_upgrade", index, base_tier, state._reward_upgrade_contract_depth(depth), step])
	return rng.randi_range(1, state.REWARD_UPGRADE_BP_DENOMINATOR) <= state._scaled_reward_upgrade_chance_bp(chance, depth, magic_find)

func legacy_tier(base_tier: int, context: String, index: int, depth: int, magic_find: float) -> int:
	var tier := base_tier
	if tier == GearItem.Tier.LEGENDARY or state._is_reward_upgrade_high_tier(tier): return tier
	if tier == GearItem.Tier.BASIC and legacy_roll(context, index, base_tier, depth, "basic_to_master", state.REWARD_UPGRADE_BASIC_TO_MASTER_BP, magic_find): tier = GearItem.Tier.MASTER
	if tier == GearItem.Tier.MASTER and legacy_roll(context, index, base_tier, depth, "master_to_epic", state.REWARD_UPGRADE_MASTER_TO_EPIC_BP, magic_find): tier = GearItem.Tier.EPIC
	if tier == GearItem.Tier.EPIC and legacy_roll(context, index, base_tier, depth, "epic_to_high_tier", state.REWARD_UPGRADE_EPIC_TO_HIGH_TIER_BP, magic_find): tier = state._shop_high_tier_roll(context, index, base_tier, depth)
	return tier

func legacy_offer(rng: RandomNumberGenerator, stable_id: String, depth: int, seen: Dictionary, magic_find: float) -> GearItem:
	var fallback: GearItem
	var fallback_signature := ""
	var slot: int = GearGenerator.ALL_SLOTS[rng.randi_range(0, GearGenerator.ALL_SLOTS.size() - 1)]
	for attempt in state.SHOP_UNIQUE_ROLL_ATTEMPTS:
		var tier := legacy_tier(state._shop_tier_for_current_phase(rng, depth), stable_id, attempt, depth, magic_find)
		var offer: GearItem = state._shop_offer_for_tier(tier, slot, rng, stable_id, depth)
		var signature: String = state._shop_offer_signature(offer)
		if fallback == null:
			fallback = offer
			fallback_signature = signature
		if not seen.has(signature):
			seen[signature] = true
			return offer
	seen[fallback_signature] = true
	return fallback

func gameplay_payload(gear: GearItem) -> Dictionary:
	var payload: Dictionary = SaveSystem._gear_entry_to_data(gear)
	for key in ["reward_base_tier", "reward_tier_steps", "reward_magic_find_upgraded"]: payload.erase(key)
	return payload

func run() -> void:
	await process_frame
	state = root.get_node("BuildState")
	state.reset()
	var witnessed_magic_find := false
	var cases := 0
	for seed in 64:
		state.adventure_seed = seed
		for depth in [1, 8, 30]:
			for magic_find in [0.0, 0.5, 2.0]:
				for tier in [GearItem.Tier.CRUDE, GearItem.Tier.BASIC, GearItem.Tier.MASTER, GearItem.Tier.EPIC, GearItem.Tier.CURSED, GearItem.Tier.CHAOS, GearItem.Tier.UNIQUE, GearItem.Tier.LEGENDARY]:
					var story: Dictionary = state._shop_tier_upgrade_story(tier, "equivalence", 2, depth, magic_find)
					var expected := legacy_tier(tier, "equivalence", 2, depth, magic_find)
					check(story.final_tier == expected and state._upgraded_shop_tier(tier, "equivalence", 2, depth, magic_find) == expected, "Legacy tier outcome preserved")
					check(story.tier_steps[0] == tier and story.tier_steps[-1] == expected, "Story spans actual tiers")
					check(not story.magic_find_upgraded or (magic_find > 0.0 and story.tier_steps.size() > 1), "Only an actual MF upgrade receives provenance")
					witnessed_magic_find = witnessed_magic_find or story.magic_find_upgraded
					cases += 1
	check(witnessed_magic_find, "Deterministic fixtures exercise bonus-only successful rolls")
	state.active_contract = load("res://data/contracts/the_gilded_serpent.tres")
	var legendary_witnessed := false
	var bonus_offer_witnessed := false
	for seed in 100:
		state.adventure_seed = seed
		var old_rng := RandomNumberGenerator.new()
		old_rng.seed = seed
		var new_rng := RandomNumberGenerator.new()
		new_rng.seed = seed
		var old_seen := {}
		var new_seen := {}
		for i in 3:
			var stable_id := "test.shop.provenance.%d.%d" % [seed, i]
			var expected := legacy_offer(old_rng, stable_id, 30, old_seen, 2.0)
			var actual: GearItem = state._generate_unique_shop_offer(new_rng, stable_id, 30, new_seen, 2.0)
			check(gameplay_payload(expected) == gameplay_payload(actual), "Slot, rarity, affixes and identity preserved")
			check(old_rng.state == new_rng.state and old_seen == new_seen, "Offer RNG consumption and duplicate signatures preserved")
			if actual.tier != GearItem.Tier.LEGENDARY:
				check(actual.reward_tier_steps[-1] == actual.tier, "Returned offer story ends at its actual rarity")
			var restored: GearItem = SaveSystem._gear_from_save_entry(SaveSystem._gear_entry_to_data(actual))
			check(restored != null and restored.reward_tier_steps == actual.reward_tier_steps and restored.reward_magic_find_upgraded == actual.reward_magic_find_upgraded, "Existing save fields preserve provenance")
			bonus_offer_witnessed = bonus_offer_witnessed or actual.reward_magic_find_upgraded
			if actual.tier == GearItem.Tier.LEGENDARY:
				legendary_witnessed = true
				check(actual == expected and expected.reward_base_tier == -1 and expected.reward_tier_steps.is_empty(), "Authored Legendary resource and path serialization remain untouched")
	check(legendary_witnessed and bonus_offer_witnessed, "Offer fixtures cover Legendary and Magic Find paths")
	for path in state.shop_legendary_paths():
		state.inventory.append(load(path))
	var fallback_witnessed := false
	for seed in 100:
		state.adventure_seed = seed
		var old_rng := RandomNumberGenerator.new()
		old_rng.seed = seed
		var new_rng := RandomNumberGenerator.new()
		new_rng.seed = seed
		var stable_id := "test.exhausted.legendary.%d" % seed
		var expected := legacy_offer(old_rng, stable_id, 30, {}, 2.0)
		var actual: GearItem = state._generate_unique_shop_offer(new_rng, stable_id, 30, {}, 2.0)
		check(gameplay_payload(actual) == gameplay_payload(expected) and old_rng.state == new_rng.state, "Exhausted catalog preserves outcomes and RNG")
		if actual.source_context.contains("legendary_fallback"):
			fallback_witnessed = true
			check(actual.reward_tier_steps == [GearItem.Tier.CURSED] and not actual.reward_magic_find_upgraded, "Exhausted Legendary fallback never fabricates an upgrade")
	check(fallback_witnessed, "Exhausted Legendary fallback exercised")
	if failures.is_empty(): print("PASS: ", cases, " legacy tier cases and 400 unchanged offers with saved provenance, including exhausted Legendary fallback")
	else: print("FAILED: ", failures)
	quit(0 if failures.is_empty() else 1)
