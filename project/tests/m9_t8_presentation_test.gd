extends SceneTree
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	assert(ok, label)
func run() -> void:
	var state = root.get_node("BuildState")
	state.reset()
	state.set_class(load("res://data/classes/rogue.tres"))
	var registry := BuildContentRegistry.adventure()
	check(state.configure_ranked_build(registry.trees["tree.bladedancer"]), "legal build")
	var catalog := LegendaryCatalog.all_items()
	check(catalog.size() == 20, "twenty fixed identities")
	var expected_text := {"serpents_scales": "Poison ticks have a 20% chance to not consume Poison stacks", "golden_greeves": "Overkill gold is doubled", "hands_of_the_lightning_lord": "Critical hits have a 20% chance to Retrigger"}
	for effect_id in expected_text:
		check(LegendaryCatalog.effect_text(load("res://data/gear/" + effect_id + ".tres")) == expected_text[effect_id], "exact approved compact effect text")
	check(state._unowned_shop_legendary_paths().size() == 19, "coin remains gated")
	state.mysterious_coin_unlocked = true
	check(state._unowned_shop_legendary_paths().size() == 20, "coin unlock adds only coin")
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	var counts := {}
	for i in 6000:
		var offer: GearItem = state._shop_offer_for_tier(GearItem.Tier.LEGENDARY, GearItem.SlotType.WEAPON, rng, "test:%d" % i)
		counts[offer.id] = int(counts.get(offer.id, 0)) + 1
	check(counts.size() == 20, "all IDs reachable conditional on Legendary")
	for count in counts.values(): check(count > 220 and count < 380, "uniform identity sampling witness")
	for fixed in catalog:
		check(SaveSystem._gear_from_save_entry(SaveSystem._gear_entry_to_data(fixed)) == fixed, "canonical path identity")
		var inline: GearItem = fixed.duplicate(true)
		inline.resource_path = ""
		check(SaveSystem._gear_from_save_entry(SaveSystem._gear_entry_to_data(inline)) == fixed, "canonical inline identity")
		state.inventory.assign([fixed])
		check(not state._unowned_shop_legendary_paths().has(fixed.resource_path), "carried owned filter")
		state.inventory.clear()
		state.equip(fixed)
		check(not state._unowned_shop_legendary_paths().has(fixed.resource_path), "equipped owned filter")
		state.unequip(fixed.slot)
	for index in range(16,20):
		var fixed := catalog[index]
		state.reset()
		state.set_class(load("res://data/classes/rogue.tres"))
		check(state.configure_ranked_build(registry.trees["tree.bladedancer"]), "save fixture legal build")
		state.equip(fixed)
		var carried := catalog[16+(index-15)%4]
		var shop := catalog[16+(index-14)%4]
		var pending := catalog[16+(index-13)%4]
		state.inventory.assign([carried])
		state.shop_offers.assign([shop])
		state.pending_reward_choices.assign([pending])
		check(SaveSystem.save_run(state), SaveSystem.last_error)
		state.inventory.clear()
		state.shop_offers.clear()
		state.pending_reward_choices.clear()
		state.unequip(fixed.slot)
		check(SaveSystem.load_run(state), "Adventure file envelope reload: " + str(SaveSystem.last_load_result))
		check(state.inventory.size() == 1 and state.inventory[0] == carried and state.shop_offers.size() == 1 and state.shop_offers[0] == shop and state.pending_reward_choices.size() == 1 and state.pending_reward_choices[0] == pending and state.equipped_gear().has(fixed), "equipped/inventory/shop/pending canonical identity")
		check(fixed.affixes.size() == 3 and fixed.legendary_effect_id != "", "new fixed stats + signature")
		check(GearIcons.icon_for(fixed).resource_path.ends_with(fixed.legendary_effect_id + ".png"), "named icon")
		check(LegendaryCatalog.tooltip_lines(fixed).size() >= 8, "full fixed item details")
	for slot in [GearItem.SlotType.LEGS, GearItem.SlotType.HANDS]:
		for tier in [GearItem.Tier.BASIC,GearItem.Tier.MASTER,GearItem.Tier.EPIC,GearItem.Tier.CURSED,GearItem.Tier.CHAOS,GearItem.Tier.UNIQUE]:
			var item := GearGenerator.generate(tier, slot, rng)
			check(GearIcons.icon_for(item) != GearIcons.slot_background_for(slot), "ordinary art replaces provisional silhouette")
	var room = load("res://scenes/training_room/training_room.tscn").instantiate()
	root.add_child(room)
	await process_frame
	for fixed in catalog:
		room._state.equip_legendary(fixed)
		var shell: GearItem = room._state.get("practice_" + GearItem.SlotType.keys()[fixed.slot].to_lower())
		room._show_gear_slot_editor("Fixed",shell,false)
		check(room._legendary_items_for_editor().has(fixed), "correct-slot Practice catalog")
		check(not room._gear_affix_column.visible and room._legendary_details.visible, "read-only authored values")
		room._state.set_duration_ms(20000)
		room._state.carried_items.assign([fixed])
		check(PracticeSaveSystem.save_setup(room._state,true), PracticeSaveSystem.last_error)
		check(PracticeSaveSystem.load_setup(room._state).status == "loaded", "Practice canonical round trip")
		check(room._state.equipped_gear().has(fixed) and room._state.carried_items[0] == fixed, "Practice fixed identity in slot and carried")
		check(room._state.duration_ms == 20000, "saved nominal unchanged")
	room._gear_editor_overlay.hide()
	var carried: GearItem = room._state.add_carried_item()
	room._state.set_carried_slot(carried,GearItem.SlotType.HANDS)
	room._show_gear_slot_editor("Carried",carried,false)
	check(room._gear_affix_column.visible and not room._gear_legendary_option.visible, "custom carried stays separate")
	var player := PlayerStats.new()
	player.legendary_arctic_mittens = true
	var target := Monster.new()
	target.hp = 1000
	var rotation: Array[Skill] = []
	var result := CombatResolver.resolve(rotation,player,target,20000)
	check(result.is_valid and result.duration_ms == 26667 and result.nominal_duration_ms == 20000, "Arctic result budgets")
	var playback := CombatPlayback.new()
	playback.start(result)
	check(playback.countdown_remaining_ms() == 20000, "nominal countdown start")
	playback.advance(10)
	check(playback.elapsed_ms() == 10000 and playback.countdown_remaining_ms() == 12500, "ten-second witness")
	playback.speed = 0
	playback.advance(9)
	check(playback.elapsed_ms() == 10000 and playback.countdown_remaining_ms() == 12500, "pause freezes both clocks")
	player.legendary_arctic_mittens = false
	playback.speed = 2
	playback.advance(5)
	check(playback.elapsed_ms() == 20000 and playback.countdown_remaining_ms() == 5000, "speed + equipment toggle preserve frozen clock")
	playback.skip()
	check(playback.is_finished() and playback.elapsed_ms() == 26667 and playback.countdown_remaining_ms() == 0, "skip exact end")
	playback.start(result)
	check(playback.window_ms() == 26667 and playback.countdown_remaining_ms() == 20000, "replay no compounding")
	var summary := CombatRecap.summarize(result,target)
	check(is_equal_approx(summary.required_dps,1000.0/26.667), "required DPS actual denominator")
	check(CombatResultFormatter.format_practice(result,target).contains("26.667s") and CombatResultFormatter.format(result,target).contains("20s at 75%"), "precise actual and nominal log context")
	var preserved := CombatResolver.TickEvent.new()
	preserved.had_active_stack = true
	preserved.stacks_preserved = true
	preserved.legendary_fuel = 5
	preserved.stacks_remaining = 5
	check(CombatResultFormatter._tick_line(preserved).contains("Scales preserved 5 Poison"), "Scales source shown in log")
	preserved.stacks_preserved = false
	preserved.origin_kind = "lightning_poison_repeat"
	check(CombatResultFormatter._tick_line(preserved).contains("Hands of the Lightning Lord"), "Lightning free Poison source shown in log")
	room.queue_free()
	await process_frame
	state.reset()
	print("M9 T8 PRESENTATION PASS (%d checks)" % checks)
	quit()
