extends SceneTree

var checks: Array[String] = []
var witness := {}
func _initialize() -> void:
	call_deferred("_run")
func ck(ok: bool, name: String) -> void:
	assert(ok, name)
	checks.append(name)
func _run() -> void:
	var s = root.get_node("BuildState")
	s.reset()
	s.set_class(load("res://data/classes/rogue.tres"))
	var coin: GearItem = load("res://data/gear/lucky_coin.tres")
	var dd: GearItem = load("res://data/gear/deaths_door.tres")
	var mystery: GearItem = load("res://data/gear/mysterious_lucky_coin.tres")
	var samurai: GearItem = load("res://data/gear/helm_of_the_samurai.tres")
	var locket: GearItem = load("res://data/gear/lolzorzs_locket.tres")
	var dagger: GearItem = load("res://data/gear/umbral_stiletto.tres")
	ck(not s._legendary_claim_eligible(mystery), "coin initially gated")
	s.inventory.append(coin)
	ck(s.sell_inventory_item(coin) and not s.mysterious_coin_unlocked, "sale does not unlock")
	s.equipped_trinket = coin
	s.unequip(GearItem.SlotType.TRINKET)
	ck(not s.mysterious_coin_unlocked, "unequip does not unlock")
	var before: int = s.inventory.size()
	ck(s.destroy_inventory_item(coin), "inventory destruction succeeds")
	ck(s.mysterious_coin_unlocked and s.inventory.size() == before - 1 and not s.inventory.has(mystery), "inventory destruction unlocks without granting")
	s.mysterious_coin_unlocked = false
	s.equipped_trinket = coin
	ck(s.destroy_equipped_item(GearItem.SlotType.TRINKET) and s.mysterious_coin_unlocked and s.equipped_trinket == null, "equipped destruction independently unlocks")
	ck(s._legendary_claim_eligible(mystery), "coin becomes eligible")
	s.inventory.append(coin)
	ck(s.destroy_inventory_item(coin) and s.mysterious_coin_unlocked and not s.destroy_inventory_item(coin), "repeat destroy is idempotent and absent item rejected")
	s.shop_round_pending = true
	s.shop_offers.assign([mystery])
	s.gold = 5000
	s.mysterious_coin_unlocked = false
	ck(not s.buy_shop_offer(mystery) and s.gold == 5000 and s.shop_offers.has(mystery), "stale gate rejects without payment or offer loss")
	s.mysterious_coin_unlocked = true

	s.equipped_armor = dd
	s.inventory.append(samurai)
	ck(not s._legendary_claim_eligible(dd) and not s._legendary_claim_eligible(samurai), "owned exclusion covers equipped and inventory IDs")
	ck(s.sell_inventory_item(samurai) and s._legendary_claim_eligible(samurai), "actual sale restores Legendary eligibility")
	s.inventory.append(samurai)
	ck(s.destroy_equipped_item(GearItem.SlotType.ARMOR) and s._legendary_claim_eligible(dd), "actual destruction restores Legendary eligibility")
	s.equipped_armor = dd
	var rng := RandomNumberGenerator.new()
	rng.seed = 61824
	var counts := {}
	for i in 7000:
		var selected: GearItem = s._shop_offer_for_tier(GearItem.Tier.LEGENDARY, GearItem.SlotType.WEAPON, rng, "t7.sample")
		counts[selected.id] = int(counts.get(selected.id, 0)) + 1
	ck(counts.size() == 14, "uniform sample covers all fourteen eligible identities")
	for n in counts.values(): ck(n > 350 and n < 650, "uniform eligible-ID frequencies within fixed-seed tolerance")
	witness["uniform_counts"] = counts
	# Pending offers are identities: unrelated changes leave references stable.
	s.shop_round_pending = true
	s.gold = 5000
	s.shop_offers.assign([locket])
	var old_gold: int = s.gold
	s.inventory.append(locket)
	ck(not s.buy_shop_offer(locket) and s.gold == old_gold and s.shop_offers.has(locket), "stale shop ownership rejects without payment or offer loss")
	s.pending_reward_choices.assign([mystery])
	s.inventory.append(mystery)
	ck(not s.choose_pending_reward_gear(mystery) and s.pending_reward_choices.has(mystery), "stale reward rejects without reward loss")
	s.inventory.clear()
	s.equipped_armor = null
	for path in s.shop_legendary_paths(): s.inventory.append(load(path))
	var fallback: GearItem = s._shop_offer_for_tier(GearItem.Tier.LEGENDARY, GearItem.SlotType.CHARM, rng, "t7.empty")
	ck(fallback.tier == GearItem.Tier.CURSED, "empty eligible pool uses Cursed fallback")
	s.inventory.clear()
	s.shop_offers.clear()
	s.pending_reward_choices.clear()
	s.equipped_weapon = dagger
	s.equipped_armor = dd
	s.equipped_helm = samurai
	s.equipped_charm = locket
	s.equipped_trinket = mystery
	var ordinary: GearItem = load("res://data/gear/placeholder_dagger.tres")
	s.inventory.append(ordinary)
	ck(SaveSystem.save_run(s), "save snapshot with five slots and ordinary gear: " + SaveSystem.last_error)
	var data: Dictionary = StrictSaveJson.read(FileAccess.get_file_as_string(SaveSystem.save_path)).data
	var bytes := FileAccess.get_file_as_bytes(SaveSystem.save_path)
	s.reset()
	ck(not s.mysterious_coin_unlocked, "new run resets unlock")
	ck(SaveSystem.load_run(s) and s.mysterious_coin_unlocked, "save resume retains same-run unlock")
	ck(s.equipped_armor == dd and s.equipped_trinket == mystery and s.equipped_weapon == dagger and s.inventory[0].id == ordinary.id, "authored fixed reload preserves five-slot identities and unrelated gear")
	ck(s.equipped_armor.affixes[0].value == .35 and s.equipped_weapon.unlocked_skills.size() > 0, "fixed stats and skill signature reload intact")
	var invalid := data.duplicate(true)
	invalid.mysterious_coin_unlocked = "yes"
	ck(SaveSystem.write_json(SaveSystem.save_path, invalid), "write isolated malformed fixture")
	var malformed_bytes := FileAccess.get_file_as_bytes(SaveSystem.save_path)
	var live_gold: int = s.gold
	ck(not SaveSystem.load_run(s) and s.mysterious_coin_unlocked and s.gold == live_gold and FileAccess.get_file_as_bytes(SaveSystem.save_path) == malformed_bytes, "malformed flag fails atomically preserving live state and bytes")
	data["save_version"] = 3
	data.erase("mysterious_coin_unlocked")
	ck(SaveSystem.write_json(SaveSystem.save_path, data) and SaveSystem.load_run(s) and not s.mysterious_coin_unlocked, "supported old envelope defaults locked")
	ck(bytes.size() > 0, "isolated snapshot bytes exist")
	var practice := TrainingRoomState.new()
	for item in [dagger, samurai, dd, locket, mystery]: practice.equip_legendary(item)
	ck(practice.equipped_gear().size() == 5 and practice.equipped_armor == dd and practice.equipped_trinket == mystery, "Practice fixed equip routes five correct slots")
	var old_affix: float = dd.affixes[0].value
	practice.set_affix_stat(dd, 0, "crit_chance")
	practice.set_slot_rarity(dd, GearItem.Tier.BASIC)
	practice.clear_slot(dd)
	ck(dd.affixes[0].value == old_affix and dd.tier == GearItem.Tier.LEGENDARY and practice.equipped_armor == dd, "Practice fixed editor APIs read-only")
	practice.legendary_missing_attempts = 3
	ck(maxi(1, 2 * practice.legendary_missing_attempts) == 6 and not s.mysterious_coin_unlocked, "controlled Practice attempts independent of Adventure unlock")
	s.reset()
	ck(descriptor(s).multiplier == 1 and s.is_unlimited_retry_encounter(), "fresh unlimited opening x1")
	s.finish_fight(false)
	ck(descriptor(s).multiplier == 1 and s.is_unlimited_retry_encounter(), "opening unlimited remains x1 after loss")
	for i in 5: s.finish_fight(false)
	ck(descriptor(s).multiplier == 1, "opening unlimited stays x1 after repeated losses")
	s.current_encounter_index = 1
	ck(descriptor(s).multiplier == 1, "next encounter naturally resets multiplier")
	s.finish_fight(false)
	ck(descriptor(s).multiplier == 2, "limited encounter actual first failure x2")
	s.current_encounter_index = 2
	ck(descriptor(s).multiplier == 1, "next limited encounter resets x1")
	var rows := []
	for i in 4:
		s.encounter_failure_counts[s._current_fight_key()] = i
		rows.append(descriptor(s))
	ck(rows[0].multiplier == 1 and rows[1].multiplier == 2 and rows[2].multiplier == 4 and rows[3].multiplier == 6, "Death Door numeric descriptor x1 x2 x4 x6")
	s.encounter_failure_counts[s._current_fight_key()] = 1
	s.finish_fight(false)
	ck(s.run_phase == s.RunPhase.RUN_ENDED and not s.start_fight(), "terminal encounter cannot start another fight")
	witness["death_door"] = rows
	witness["checks"] = checks
	witness["count"] = checks.size()
	witness["limitations"] = ["T8 retains broad acquisition and old-reader qualification; T9 final UI acceptance"]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports"))
	var file := FileAccess.open("res://reports/t7_state_witness.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(witness, "\t"))
	print("PASS T7 state witnesses: ", checks.size())
	quit()



func descriptor(s) -> Dictionary:
	var missing: int = 0 if s.is_unlimited_retry_encounter() else s.failure_count_for_current_encounter()
	return {"missing_attempts": missing, "multiplier": maxi(1, 2 * missing), "terminal": s.run_phase == s.RunPhase.RUN_ENDED}
