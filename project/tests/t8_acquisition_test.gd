extends SceneTree
## Run only in the T8 disposable project with isolated userdata.
## -- --t8-rng-only captures the unchanged baseline before acquisition fixes.

var checks: Array[String] = []
var witness := {}

func _initialize() -> void:
	call_deferred("_run")

func ck(ok: bool, name: String) -> void:
	assert(ok, name)
	checks.append(name)

func _run() -> void:
	var s = root.get_node("BuildState")
	witness["rolls"] = _roll_witness(s)
	if not OS.get_cmdline_user_args().has("--t8-rng-only"):
		_test_acquisition(s)
	witness["checks"] = checks
	witness["count"] = checks.size()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	var file := FileAccess.open("res://reports/t8_acquisition_witness.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(witness, "\t"))
	print("PASS T8 acquisition: ", checks.size())
	quit()

func _roll_witness(s) -> Array:
	var rows := []
	for seed_value in [1, 61824, 73149, 900719]:
		for depth in [1, 6, 12]:
			s.reset()
			s.set_class(load("res://data/classes/rogue.tres"))
			s.set_adventure_seed(seed_value)
			s.completed_contract_count = depth - 1
			var row := {"seed": seed_value, "depth": depth, "shops": [], "rewards": [], "upgrade_stories": []}
			for reroll_index in [0, 1, 2]:
				var offers := []
				for item in s._generate_tavern_shop_offers(2, reroll_index):
					offers.append(_item_witness(item))
				row.shops.append(offers)
			for tier in [GearItem.Tier.BASIC, GearItem.Tier.MASTER, GearItem.Tier.EPIC]:
				var reward := EncounterReward.new()
				reward.generated_gear_choice_count = 5
				reward.generated_gear_tier = tier
				var generated := []
				for item in s._gear_choices_for_reward(reward):
					generated.append(_item_witness(item))
				row.rewards.append(generated)
				for magic_find in [0.0, 0.5, 2.0]:
					for choice in 5:
						row.upgrade_stories.append(s._reward_tier_upgrade_story(tier, "t8.frozen", choice, depth, magic_find))
			rows.append(row)
	return rows

func _item_witness(item: GearItem) -> Dictionary:
	var affixes := []
	for affix in item.affixes:
		affixes.append({"id": affix.stat_id, "value": affix.value})
	return {"id": item.id, "tier": item.tier, "slot": item.slot, "affixes": affixes, "unidentified": item.is_unidentified, "base_tier": item.reward_base_tier, "steps": item.reward_tier_steps, "mf_upgraded": item.reward_magic_find_upgraded}

func _test_acquisition(s) -> void:
	_test_uniform_identity_pool(s)
	_test_all_item_transactions(s)
	_test_coin_unlock_and_stale_offers(s)
	_test_fixed_reward_atomicity(s)
	_test_explicit_choice_identity_filter(s)
	_test_shop_replay_and_prices(s)
	s.reset()

func _fresh(s) -> void:
	s.reset()
	s.set_class(load("res://data/classes/rogue.tres"))
	s.equipped_weapon = null
	s.gold = 5000
	s.mysterious_coin_unlocked = true

func _ordinary(slot: int, key: String) -> GearItem:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8007
	return GearGenerator.generate_from_request({"tier": GearItem.Tier.BASIC, "slot": slot, "rng": rng, "id": "gear.generated.t8." + key, "deterministic_key": key, "source_context": "t8", "source_seed": 8007, "contract_depth": 1}).get("item")

func _fill_inventory(s, count: int) -> void:
	for i in count:
		ck(s.add_inventory_item(_ordinary(GearItem.SlotType.WEAPON, "filler.%d.%d" % [s.inventory.size(), i])), "capacity fixture acquired ordinary item")

func _test_uniform_identity_pool(s) -> void:
	_fresh(s)
	ck(s.shop_legendary_paths().size() == 16 and s._unowned_shop_legendary_paths().size() == 16, "uniform_identity_pool: all sixteen eligible after unlock")
	s.mysterious_coin_unlocked = false
	ck(s._unowned_shop_legendary_paths().size() == 15, "uniform_identity_pool: exactly fifteen before unlock")
	s.mysterious_coin_unlocked = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 648120
	var counts := {}
	for i in 16000:
		var selected: GearItem = s._shop_offer_for_tier(GearItem.Tier.LEGENDARY, GearGenerator.ALL_SLOTS[i % 5], rng, "t8.uniform")
		counts[selected.id] = int(counts.get(selected.id, 0)) + 1
	ck(counts.size() == 16, "uniform_identity_pool: sample covers all sixteen identities across requested slots")
	for id in counts:
		ck(counts[id] >= 840 and counts[id] <= 1160, "uniform_identity_pool: equal item weight frequency " + id)
	witness["uniform_counts"] = counts
	# Exhaustion is a synthetic guardrail: legal storage holds only eight items.
	s.inventory.assign(LegendaryCatalog.all_items())
	var fallback: GearItem = s._shop_offer_for_tier(GearItem.Tier.LEGENDARY, GearItem.SlotType.CHARM, rng, "gear.generated.t8.fallback")
	ck(fallback != null and fallback.tier == GearItem.Tier.CURSED and fallback.slot == GearItem.SlotType.CHARM, "uniform_identity_pool: exhausted synthetic pool retains Cursed fallback")

func _test_all_item_transactions(s) -> void:
	for item in LegendaryCatalog.all_items():
		_fresh(s)
		var label := "all_item_transactions: " + item.id
		s.shop_round_pending = true
		s.shop_offers.assign([item])
		var price: int = s.shop_purchase_price_for(item)
		ck(s.buy_shop_offer(item) and s.inventory.has(item) and s.equipped_item_for_slot(item.slot) == null and s.gold == 5000 - price and s.shop_offers.is_empty(), label + " purchase enters inventory and pays once")
		ck(not s.buy_shop_offer(item) and not s.add_inventory_item(item.duplicate(true)) and not s.grant_gear(item.duplicate(true), true), label + " all new acquisition APIs reject an owned ID")
		ck(s.equip_from_inventory(item) and s.inventory.is_empty() and s.equipped_item_for_slot(item.slot) == item, label + " equip transfers owned item")
		var replacement := _ordinary(item.slot, "replacement.%d" % item.slot)
		ck(s.add_inventory_item(replacement), label + " acquire legal generated alternative")
		_fill_inventory(s, s.INVENTORY_CAPACITY - s.inventory.size())
		var old_gold: int = s.gold
		ck(s.equip_from_inventory(replacement) and s.inventory.size() == s.INVENTORY_CAPACITY and s.inventory.has(item) and s.gold == old_gold, label + " full carried swap preserves displaced Legendary")
		ck(s.sell_inventory_item(item) and s._legendary_claim_eligible(item) and s.gold == old_gold + s.sell_value_for(item), label + " inventory sale restores eligibility")
		s.shop_offers.assign([item])
		ck(s.buy_shop_offer(item) and s.equip_from_inventory(item), label + " sold identity can be repurchased and equipped")
		old_gold = s.gold
		ck(s.sell_equipped_item(item.slot) and s._legendary_claim_eligible(item) and s.gold == old_gold + s.sell_value_for(item), label + " equipped sale restores eligibility")
		# Reward Legendary auto-equip retains the accepted overflow resale.
		s.equip(replacement)
		_fill_inventory(s, s.INVENTORY_CAPACITY - s.inventory.size())
		s.pending_reward_choices.assign([item])
		old_gold = s.gold
		ck(s.choose_pending_reward_gear(item) and s.equipped_item_for_slot(item.slot) == item and s.inventory.size() == s.INVENTORY_CAPACITY and s.gold == old_gold + s.sell_value_for(replacement) and s.pending_reward_choices.is_empty(), label + " full reward auto-equip sells displaced ordinary gear")
		s.unequip(item.slot)
		ck(s.inventory.size() == s.INVENTORY_CAPACITY and s.equipped_item_for_slot(item.slot) == item, label + " full unequip preserves slot and capacity")
		ck(s.sell_inventory_item(s.inventory[0]), label + " free storage through actual sale")
		s.unequip(item.slot)
		ck(s.equipped_item_for_slot(item.slot) == null and s.inventory.has(item) and not s._legendary_claim_eligible(item), label + " unequip transfers without restoring eligibility")
		ck(s.destroy_inventory_item(item) and s._legendary_claim_eligible(item), label + " inventory destruction restores eligibility")
		ck(s.grant_gear(item, true) and s.destroy_equipped_item(item.slot) and s._legendary_claim_eligible(item), label + " equipped destruction restores eligibility")
	# Five concurrent slots have no extra Legendary limit.
	_fresh(s)
	var slots := {}
	for item in LegendaryCatalog.all_items():
		if not slots.has(item.slot):
			ck(s.grant_gear(item, true), "all_item_transactions: concurrent slot acquisition %d" % item.slot)
			slots[item.slot] = true
	ck(s.equipped_gear().size() == 5 and s.inventory.is_empty(), "all_item_transactions: five concurrent Legendary slots")
	var displaced: GearItem = s.equipped_weapon
	var incoming: GearItem = load("res://data/gear/mithril_karambit.tres")
	_fill_inventory(s, s.INVENTORY_CAPACITY)
	s.pending_reward_choices.assign([incoming])
	var overflow_gold_before: int = s.gold
	ck(s.choose_pending_reward_gear(incoming) and s.equipped_weapon == incoming and s.inventory.size() == s.INVENTORY_CAPACITY and s._legendary_claim_eligible(displaced) and s.gold == overflow_gold_before + s.sell_value_for(displaced), "all_item_transactions: full Legendary replacement resells displaced identity and restores eligibility")
	_fresh(s)
	_fill_inventory(s, s.INVENTORY_CAPACITY)
	s.pending_reward_choices.assign([incoming])
	ck(s.choose_pending_reward_gear(incoming) and s.equipped_weapon == incoming and s.inventory.size() == s.INVENTORY_CAPACITY and s.gold == 5000, "all_item_transactions: full inventory still allows reward into empty equipment slot")

func _test_coin_unlock_and_stale_offers(s) -> void:
	_fresh(s)
	s.mysterious_coin_unlocked = false
	var coin: GearItem = load("res://data/gear/lucky_coin.tres")
	var mystery: GearItem = load("res://data/gear/mysterious_lucky_coin.tres")
	s.shop_round_pending = true
	s.shop_offers.assign([mystery])
	s.pending_reward_choices.assign([mystery])
	ck(not s.buy_shop_offer(mystery) and not s.choose_pending_reward_gear(mystery) and not s.grant_gear(mystery, true) and not s.add_inventory_item(mystery), "coin_unlock_and_stale_offers: locked Coin rejected by every acquisition entry")
	ck(s.gold == 5000 and s.inventory.is_empty() and s.shop_offers == [mystery] and s.pending_reward_choices == [mystery], "coin_unlock_and_stale_offers: stale gate keeps money and choices")
	ck(s.add_inventory_item(coin) and s.sell_inventory_item(coin) and not s.mysterious_coin_unlocked, "coin_unlock_and_stale_offers: sale does not unlock")
	ck(s.grant_gear(coin, true), "coin_unlock_and_stale_offers: ordinary Coin equips")
	s.unequip(coin.slot)
	ck(s.inventory.has(coin) and not s.mysterious_coin_unlocked, "coin_unlock_and_stale_offers: unequip does not unlock")
	ck(s.destroy_inventory_item(coin) and s.mysterious_coin_unlocked and not s.inventory.has(mystery) and s.equipped_item_for_slot(mystery.slot) == null, "coin_unlock_and_stale_offers: inventory destruction unlocks without grant")
	ck(s.buy_shop_offer(mystery), "coin_unlock_and_stale_offers: existing offer eligible after unlock")
	var gold_before: int = s.gold
	ck(not s.choose_pending_reward_gear(mystery) and s.pending_reward_choices == [mystery] and s.gold == gold_before, "coin_unlock_and_stale_offers: stale reward ownership preserves choices")
	ck(s.sell_inventory_item(mystery) and s.choose_pending_reward_gear(mystery), "coin_unlock_and_stale_offers: sale restores stale reward eligibility")
	s.reset()
	s.set_class(load("res://data/classes/rogue.tres"))
	ck(not s.mysterious_coin_unlocked, "coin_unlock_and_stale_offers: new run resets gate")
	ck(s.grant_gear(coin, true) and s.destroy_equipped_item(coin.slot) and s.mysterious_coin_unlocked and not s.destroy_equipped_item(coin.slot), "coin_unlock_and_stale_offers: equipped destruction independently unlocks once")
	_fresh(s)
	var item: GearItem = load("res://data/gear/deaths_door.tres")
	s.shop_round_pending = true
	s.shop_offers.assign([item])
	_fill_inventory(s, s.INVENTORY_CAPACITY)
	ck(not s.buy_shop_offer(item) and s.gold == 5000 and s.shop_offers == [item] and s.inventory.size() == s.INVENTORY_CAPACITY, "coin_unlock_and_stale_offers: capacity purchase rejection is atomic")
	ck(s.sell_inventory_item(s.inventory[0]), "coin_unlock_and_stale_offers: free capacity")
	s.gold = 0
	ck(not s.buy_shop_offer(item) and s.shop_offers == [item] and s.gold == 0, "coin_unlock_and_stale_offers: unaffordable purchase preserves offer")
	s.gold = 5000
	ck(s.grant_gear(item.duplicate(true), true), "coin_unlock_and_stale_offers: own cloned authored identity")
	ck(not s.buy_shop_offer(item) and s.shop_offers == [item] and s.gold == 5000, "coin_unlock_and_stale_offers: stale shop ID rejects without charging")
	var ordinary := _ordinary(GearItem.SlotType.CHARM, "capacity.choice")
	s.pending_reward_choices.assign([ordinary])
	_fill_inventory(s, s.INVENTORY_CAPACITY - s.inventory.size())
	ck(not s.choose_pending_reward_gear(ordinary) and s.pending_reward_choices == [ordinary], "coin_unlock_and_stale_offers: ordinary reward capacity rejection preserves choice")

func _set_reward(s, reward: EncounterReward) -> void:
	var route := ContractRouteNode.new()
	route.id = "route.t8.reward"
	route.monster = s.current_encounter().monster
	route.reward = reward
	s.active_contract = ContractDef.new()
	s.active_contract.id = "contract.t8.reward"
	s.current_route_node = route
	s.run_phase = s.RunPhase.RESULT
	s.last_fight_won = true

func _test_fixed_reward_atomicity(s) -> void:
	_fresh(s)
	var item: GearItem = load("res://data/gear/deaths_door.tres")
	var second: GearItem = load("res://data/gear/helm_of_the_samurai.tres")
	var mystery: GearItem = load("res://data/gear/mysterious_lucky_coin.tres")
	var ordinary := _ordinary(GearItem.SlotType.CHARM, "fixed")
	var reward := EncounterReward.new()
	reward.gold_amount = 23
	reward.fixed_gear_rewards.assign([ordinary, item, second])
	_set_reward(s, reward)
	_fill_inventory(s, 1)
	ck(not s.claim_current_reward() and s.gold == 5000 and not s.has_claimed_current_reward() and s.earned_talent_points == 0 and s.inventory.size() == 1, "fixed_reward_atomicity: capacity preflight preserves entire reward")
	s.inventory.clear()
	ck(s.claim_current_reward() and s.gold == 5023 and s.inventory.size() == 3 and s.inventory.has(item) and s.inventory.has(second), "fixed_reward_atomicity: legal fixed batch commits all gear and currency")
	ck(not s.claim_current_reward() and s.gold == 5023 and s.inventory.size() == 3, "fixed_reward_atomicity: fixed batch claim cannot repeat")
	for mode in ["owned", "duplicate", "locked"]:
		_fresh(s)
		reward = EncounterReward.new()
		reward.gold_amount = 23
		reward.unlocks_shop = true
		reward.fixed_gear_rewards.assign([ordinary, item])
		if mode == "owned":
			ck(s.grant_gear(item.duplicate(true), true), "fixed_reward_atomicity: equipped cloned ID setup")
		elif mode == "duplicate":
			reward.fixed_gear_rewards.append(item.duplicate(true))
		else:
			s.mysterious_coin_unlocked = false
			reward.fixed_gear_rewards.assign([ordinary, mystery])
		_set_reward(s, reward)
		ck(not s.can_claim_current_reward() and not s.claim_current_reward() and s.gold == 5000 and s.inventory.is_empty() and s.earned_talent_points == 0 and not s.shop_unlocked and not s.has_claimed_current_reward(), "fixed_reward_atomicity: " + mode + " Legendary rejects before all side effects")

func _ids(items: Array[GearItem]) -> Array[String]:
	var ids: Array[String] = []
	for item in items:
		ids.append(item.id)
	return ids

func _test_explicit_choice_identity_filter(s) -> void:
	_fresh(s)
	s.set_adventure_seed(74129)
	var reward := EncounterReward.new()
	var item: GearItem = load("res://data/gear/deaths_door.tres")
	var owned: GearItem = load("res://data/gear/helm_of_the_samurai.tres")
	var mystery: GearItem = load("res://data/gear/mysterious_lucky_coin.tres")
	ck(s.grant_gear(owned.duplicate(true), true), "explicit_choice_identity_filter: owned cloned ID setup")
	s.mysterious_coin_unlocked = false
	reward.gear_choice_rewards.assign([item, item.duplicate(true), owned, mystery])
	reward.legendary_choice_pool.assign(LegendaryCatalog.all_items())
	reward.legendary_choice_pool.append(item.duplicate(true))
	reward.legendary_choice_count = 16
	var choices: Array[GearItem] = s._gear_choices_for_reward(reward)
	var ids := _ids(choices)
	var unique := {}
	for id in ids: unique[id] = true
	ck(ids.size() == 14 and unique.size() == 14 and not ids.has(owned.id) and not ids.has(mystery.id), "explicit_choice_identity_filter: direct plus sampled pools contain distinct eligible IDs")
	ck(_ids(s._gear_choices_for_reward(reward)) == ids, "explicit_choice_identity_filter: exact seeded replay")
	s.pending_reward_choices.assign(choices)
	ck(s.choose_pending_reward_gear(item) and s.pending_reward_choices.is_empty() and s.equipped_item_for_slot(item.slot) == item, "explicit_choice_identity_filter: actual choice grants one and clears alternatives")
	_fresh(s)
	var pool_reward: EncounterReward = load("res://data/contract_routes/gilded_serpent/knives.tres").reward
	var original_ids := _ids(pool_reward.legendary_choice_pool)
	ck(s.grant_gear(pool_reward.legendary_choice_pool[0], true), "explicit_choice_identity_filter: actual Knives pool owned item")
	var actual := _ids(s._gear_choices_for_reward(pool_reward))
	ck(actual.size() == pool_reward.legendary_choice_count and not actual.has(original_ids[0]) and _ids(pool_reward.legendary_choice_pool) == original_ids, "explicit_choice_identity_filter: actual authored reward excludes owned without mutating source")

func _test_shop_replay_and_prices(s) -> void:
	_fresh(s)
	s.set_adventure_seed(63892)
	s.shop_unlocked = true
	ck(s.open_shop_round(), "shop_replay_and_prices: actual shop open")
	var initial := []
	for item in s.shop_offers: initial.append(_item_witness(item))
	var offer_refs: Array[GearItem] = s.shop_offers.duplicate()
	s.add_gold(7)
	ck(s.shop_offers == offer_refs, "shop_replay_and_prices: unrelated build change retains pending references")
	var gold_before: int = s.gold
	ck(s.reroll_shop_offers() and s.gold == gold_before - 5 and s.shop_reroll_count == 1 and s.shop_reroll_cost == 10, "shop_replay_and_prices: first real reroll retains cost formula")
	var rerolled := []
	for item in s.shop_offers: rerolled.append(_item_witness(item))
	gold_before = s.gold
	ck(s.reroll_shop_offers() and s.gold == gold_before - 10 and s.shop_reroll_count == 2 and s.shop_reroll_cost == 15, "shop_replay_and_prices: second real reroll retains cost formula")
	_fresh(s)
	s.set_adventure_seed(63892)
	s.shop_unlocked = true
	ck(s.open_shop_round(), "shop_replay_and_prices: repeated run opens shop")
	var replay := []
	for item in s.shop_offers: replay.append(_item_witness(item))
	ck(replay == initial and s.reroll_shop_offers(), "shop_replay_and_prices: exact initial repeated-run replay")
	replay = []
	for item in s.shop_offers: replay.append(_item_witness(item))
	ck(replay == rerolled, "shop_replay_and_prices: exact actual reroll replay")
	witness["limitations"] = ["Pool exhaustion uses a synthetic over-capacity ownership fixture; legal storage holds eight items.", "Fixed Legendary batches use authored resource shapes; current shipped fixed reward is ordinary Lucky Coin.", "No generated enemy Legendary outcome added; D068 deferral retained."]
