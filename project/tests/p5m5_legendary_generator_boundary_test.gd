extends SceneTree
## Focused P5M5-T10 check for the Legendary fixed-catalog generator boundary.


func _initialize() -> void:
	var build_state = root.get_node("BuildState")
	build_state.reset(true)
	print("-- P5M5 Legendary generator boundary --")
	_check_legendary_is_not_procedural()
	_check_fixed_legendary_catalog_integrity()
	_check_shop_legendary_path_uses_catalog(build_state)
	_check_owned_shop_legendary_falls_back_to_generated_cursed(build_state)
	_check_generated_offers_do_not_roll_legendary()
	_check_legendary_reward_choices_use_fixed_pool(build_state)
	_check_generated_reward_upgrades_do_not_roll_legendary(build_state)
	build_state.reset(true)
	print("P5M5 Legendary generator boundary check: OK")
	quit(0)


func _check_legendary_is_not_procedural() -> void:
	_require(not GearGenerator.is_procedural_tier(GearItem.Tier.LEGENDARY), "Expected Legendary outside active procedural tiers.")
	_require(GearGenerator.requires_fixed_catalog(GearItem.Tier.LEGENDARY), "Expected Legendary to require fixed catalog.")
	_require(not GearGenerator.rarity_roll_plan(GearItem.Tier.LEGENDARY)["ok"], "Expected Legendary roll plan to be unsupported.")
	var rng := RandomNumberGenerator.new()
	rng.seed = 10010
	var result := GearGenerator.generate_from_request({
		"tier": GearItem.Tier.LEGENDARY,
		"slot": GearItem.SlotType.WEAPON,
		"rng": rng,
		"id": "gear.test.p5m5.t10.direct",
		"deterministic_key": "p5m5:t10:direct",
		"source_context": "p5m5_t10",
	})
	_require(not result["ok"], "Expected procedural Legendary request to fail.")
	_require(result["item"] == null, "Expected procedural Legendary request not to return an item.")
	_require((result["errors"] as PackedStringArray).has("legendary_requires_fixed_catalog"), "Expected fixed-catalog error.")

	var generated := GearGenerator.generate(GearItem.Tier.LEGENDARY, GearItem.SlotType.WEAPON, rng, "gear.test.p5m5.t10.legacy")
	_require(generated == null, "Expected legacy generate(LEGENDARY) not to produce a random item.")


func _check_fixed_legendary_catalog_integrity() -> void:
	var paths := LegendaryCatalog.all_paths()
	# Integrated M9 T8 roster: retained sixteen plus four new fixed identities.
	var expected_slots := {"gear.legendary.wyvern_kriss": 0, "gear.legendary.mithril_karambit": 0, "gear.legendary.bandit_blade": 0, "gear.legendary.umbral_stiletto": 0, "gear.legendary.bejeweled_push_dagger": 0, "gear.legendary.decrepit_blade": 0, "gear.legendary.nightkiss_kitana": 0, "gear.legendary.crown_of_concertation": 3, "gear.legendary.helm_of_the_samurai": 3, "gear.legendary.cloak_of_speed": 4, "gear.legendary.deaths_door": 4, "gear.legendary.signet_of_the_old_kings": 2, "gear.legendary.lolzorzs_locket": 2, "gear.legendary.serpents_coil": 1, "gear.legendary.wingjammer": 1, "gear.legendary.mysterious_lucky_coin": 1}
	expected_slots.merge({"gear.legendary.serpents_scales": 5, "gear.legendary.golden_greeves": 5, "gear.legendary.arctic_mittens": 6, "gear.legendary.hands_of_the_lightning_lord": 6})
	_require(paths.size() == 20, "Expected integrated twenty-item Legendary catalog.")
	var ids := {}
	for path in paths:
		var item: GearItem = load(path)
		_require(item != null, "Expected Legendary catalog path to load: %s." % path)
		_require(item.tier == GearItem.Tier.LEGENDARY, "Expected catalog item to stay Legendary tier: %s." % item.display_name)
		_require(item.source_kind == GearItem.SourceKind.LEGENDARY, "Expected catalog item to use LEGENDARY source kind: %s." % item.display_name)
		_require(expected_slots.has(item.id) and item.slot == expected_slots.get(item.id), "Expected exact retained Legendary identity/slot: %s." % item.display_name)
		_require(item.id.begins_with("gear.legendary."), "Expected catalog Legendary ID namespace: %s." % item.id)
		_require(not ids.has(item.id), "Expected Legendary catalog IDs to be unique: %s." % item.id)
		_require(LegendaryCatalog.effect_text(item) != "", "Expected fixed Legendary effect text for %s." % item.display_name)
		ids[item.id] = true


func _check_shop_legendary_path_uses_catalog(build_state) -> void:
	build_state.reset(true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20010
	var offer: GearItem = build_state._shop_offer_for_tier(GearItem.Tier.LEGENDARY, GearItem.SlotType.CHARM, rng, "gear.test.p5m5.t10.shop")
	_require(offer != null, "Expected shop Legendary offer to return a catalog item.")
	_require(offer.tier == GearItem.Tier.LEGENDARY, "Expected shop Legendary offer to stay Legendary tier.")
	_require(offer.source_kind == GearItem.SourceKind.LEGENDARY, "Expected shop Legendary offer to use fixed Legendary source kind.")
	_require(LegendaryCatalog.all_items().any(func(item): return item.id == offer.id), "Expected shop Legendary offer to come from LegendaryCatalog.")
	_require(offer.id != "gear.test.p5m5.t10.shop", "Expected fixed Legendary shop offer not to use generated stable ID.")


func _check_owned_shop_legendary_falls_back_to_generated_cursed(build_state) -> void:
	build_state.reset(true)
	for item in LegendaryCatalog.all_items():
		build_state.inventory.append(item)
	var rng := RandomNumberGenerator.new()
	rng.seed = 30010
	var offer: GearItem = build_state._shop_offer_for_tier(GearItem.Tier.LEGENDARY, GearItem.SlotType.WEAPON, rng, "gear.test.p5m5.t10.fallback")
	_require(offer != null, "Expected owned-Legendary shop fallback to return an item.")
	_require(offer.tier == GearItem.Tier.CURSED, "Expected fully owned Legendary shop pool to fall back to generated Cursed.")
	_require(offer.source_kind == GearItem.SourceKind.GENERATED, "Expected Legendary fallback to use generated source kind.")
	_require(offer.id == "gear.test.p5m5.t10.fallback", "Expected generated fallback to use stable generated ID.")
	_require(not offer.id.begins_with("gear.legendary."), "Expected generated fallback not to masquerade as catalog Legendary.")
	build_state.reset(true)


func _check_generated_offers_do_not_roll_legendary() -> void:
	for seed in range(1, 40):
		var offers := GearGenerator.generate_offers(12, seed)
		for offer in offers:
			_require(offer != null, "Expected generated offer to produce an item.")
			_require(GearGenerator.is_procedural_tier(offer.tier), "Expected generated offers to use active procedural tiers only.")
			_require(offer.tier != GearItem.Tier.LEGENDARY, "Expected generated offers not to roll Legendary.")
			_require(offer.source_kind == GearItem.SourceKind.GENERATED, "Expected generated offers to use generated source kind.")


func _check_legendary_reward_choices_use_fixed_pool(build_state) -> void:
	build_state.reset(true)
	build_state.adventure_seed = 40010
	var reward := EncounterReward.new()
	reward.legendary_choice_count = 2
	reward.legendary_choice_pool = LegendaryCatalog.all_items()
	var choices: Array[GearItem] = build_state._gear_choices_for_reward(reward)
	_require(choices.size() == 2, "Expected fixed Legendary reward pool to return two choices.")
	var ids := {}
	for choice in choices:
		_require(choice.tier == GearItem.Tier.LEGENDARY, "Expected Legendary reward choice to stay Legendary tier.")
		_require(choice.source_kind == GearItem.SourceKind.LEGENDARY, "Expected Legendary reward choice to use fixed Legendary source kind.")
		_require(LegendaryCatalog.all_items().any(func(item): return item.id == choice.id), "Expected Legendary reward choice to come from catalog.")
		_require(not ids.has(choice.id), "Expected Legendary reward choices to be distinct.")
		ids[choice.id] = true
	build_state.reset(true)


func _check_generated_reward_upgrades_do_not_roll_legendary(build_state) -> void:
	build_state.reset(true)
	_require(not build_state._reward_upgrade_high_tier_options().has(GearItem.Tier.LEGENDARY), "Expected generated reward high-tier upgrades to exclude Legendary.")
	_require(not build_state._reward_upgrade_high_tier_options().has(GearItem.Tier.CRUDE), "Expected generated reward high-tier upgrades to exclude Crude.")
	for seed in range(1, 5000):
		build_state.adventure_seed = seed
		for choice_index in range(0, 3):
			var tier: GearItem.Tier = build_state._upgraded_reward_tier(GearItem.Tier.EPIC, "legendary_boundary", choice_index)
			_require(tier != GearItem.Tier.LEGENDARY, "Expected generated reward upgrade not to produce Legendary.")
			_require(tier != GearItem.Tier.CRUDE, "Expected generated reward upgrade not to produce Crude.")
			if tier != GearItem.Tier.EPIC:
				_require(build_state._is_reward_upgrade_high_tier(tier), "Expected upgraded high-tier reward to use the P5M7 high-tier option list.")
	build_state.reset(true)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	assert(false, message)
