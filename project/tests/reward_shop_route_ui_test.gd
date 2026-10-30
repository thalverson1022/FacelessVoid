extends SceneTree
## Reward-claim, shop offer affordability/details and route-choice checks.
## Gear hovers retain the item's own details and action/cost hints while
## hiding projected equip deltas and equipped-reference boxes in all modes.


func _initialize() -> void:
	var build_state = root.get_node("BuildState")
	build_state.reset()

	var combat_scene: PackedScene = load("res://scenes/combat/combat_screen.tscn")
	var combat_screen = combat_scene.instantiate()
	root.add_child(combat_screen)
	await process_frame
	await _wait_for_reveals(combat_screen)

	var rogue: ClassDef = load("res://data/classes/rogue.tres")
	build_state.set_class(rogue)
	build_state.select_tree(rogue.trees[1])

	# -- Shop offer rendering: known gold, affordable vs. unaffordable tiers --
	print("shop offer tier/slot/affix/afford-state checks")
	build_state.gold = 20
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var unaffordable_offer := GearGenerator.generate(GearItem.Tier.MASTER, GearItem.SlotType.WEAPON, rng, "test.shop.master_weapon")
	var affordable_offer := GearGenerator.generate(GearItem.Tier.BASIC, GearItem.SlotType.TRINKET, rng, "test.shop.basic_trinket")
	var offers: Array[GearItem] = [unaffordable_offer, affordable_offer]
	build_state.shop_round_pending = true
	build_state.shop_offers = offers
	build_state.build_changed.emit()
	combat_screen._shop_overlay.refresh()
	await process_frame
	await _wait_for_reveals(combat_screen)

	_require(combat_screen._shop_overlay._shopkeeper_image != null, "Expected the shopkeeper image node to exist.")
	_require(combat_screen._shop_overlay._shopkeeper_image.texture != null, "Expected the shopkeeper image texture to be loaded.")
	_require(combat_screen._shop_overlay.z_index > combat_screen._combat_stage.player_actor_anchor.z_index, "Expected the shop overlay to render above combat actor sprites.")
	_require(combat_screen._shop_overlay.z_index > combat_screen.COMBAT_BUTTON_ROW_Z_INDEX, "Expected the shop overlay to render above the raised combat button row.")
	_require(combat_screen.find_child("GearPanel", true, false)._gold_label.text == "20g", "Expected the Gear panel to be the primary gold stash readout.")
	_require(combat_screen._shop_overlay._shop_reroll_button.text == "Reroll 5g", "Expected reroll to show its current gold cost.")
	_require(not combat_screen._shop_overlay._shop_reroll_button.disabled, "Expected 20g to afford the initial 5g reroll.")
	_require(combat_screen._shop_overlay._shop_reroll_button.tooltip_text.contains("Spend 5g"), "Expected reroll tooltip to explain the gold spend.")
	var found_shop_gold_label := false
	for label in combat_screen._shop_overlay.find_children("*", "Label", true, false):
		if label.text == "Gold: 20g":
			found_shop_gold_label = true
	_require(not found_shop_gold_label, "Expected the shop overlay to avoid a duplicate Gold row.")
	_require(combat_screen._shop_overlay._shop_offers_box.get_child_count() == 2, "Expected two shop offer boxes.")

	var unaffordable_button: Button = combat_screen._shop_overlay._shop_offers_box.get_child(0)
	_require(unaffordable_button.disabled, "Expected the 32g Master offer to be disabled at 20 gold.")
	_require(unaffordable_button.find_child("PriceBadge", true, false) != null, "Expected the unaffordable offer to show an always-visible price badge.")
	_require(unaffordable_button.find_child("PriceLabel", true, false).text == "32g", "Expected the unaffordable offer price badge to show 32g.")
	_require(unaffordable_button.find_child("PriceLabel", true, false).get_theme_font_size("font_size") == 16, "Expected the price badge value font to be larger.")
	_require(unaffordable_button.find_child("GoldIcon", true, false).custom_minimum_size == Vector2(11, 11), "Expected the price badge gold icon to be smaller.")
	# The offer box's icon lives in a child TextureRect (P2:R7 gear-art pass)
	# -- see CardStyle.build_gear_box_content(). The caption text it used to
	# carry alongside the icon was dropped as redundant once the icon art +
	# tier-colored background conveyed slot/tier on their own.
	var unaffordable_icon: TextureRect = unaffordable_button.get_node("Icon")
	_require(unaffordable_icon.texture == GearIcons.MASTER_WEAPON_ICON, "Expected the unaffordable offer box to show the generic Master Weapon icon.")
	var unaffordable_tooltip: String = unaffordable_button.tooltip_text
	_require(unaffordable_tooltip.contains("Master Weapon / Dagger"), "Expected the tier/slot/family line in the tooltip, got: %s" % unaffordable_tooltip)
	_require(unaffordable_tooltip.contains("Weapon Damage:"), "Expected the weapon damage line in the tooltip, got: %s" % unaffordable_tooltip)
	_require(unaffordable_tooltip.contains("Master"), "Expected the tier name in the tooltip, got: %s" % unaffordable_tooltip)
	_require(unaffordable_tooltip.contains("Price: 32g"), "Expected the price in the tooltip, got: %s" % unaffordable_tooltip)
	_require(unaffordable_tooltip.contains("Not enough gold."), "Expected an explicit afford-state hint, got: %s" % unaffordable_tooltip)

	var affordable_button: Button = combat_screen._shop_overlay._shop_offers_box.get_child(1)
	_require(not affordable_button.disabled, "Expected the 18g Basic offer to be affordable at 20 gold.")
	_require(affordable_button.find_child("PriceBadge", true, false) != null, "Expected the affordable offer to show an always-visible price badge.")
	_require(affordable_button.find_child("PriceLabel", true, false).text == "18g", "Expected the affordable offer price badge to show 18g.")
	_require(affordable_button.find_child("PriceLabel", true, false).get_theme_font_size("font_size") == 16, "Expected the affordable price badge value font to be larger.")
	var affordable_tooltip: String = affordable_button.tooltip_text
	_require(affordable_tooltip.contains("Click to buy."), "Expected an explicit buy hint on an affordable offer, got: %s" % affordable_tooltip)
	_require(not affordable_tooltip.contains("vs. equipped"), "Expected no stat-diff comparison text in the tooltip anymore, got: %s" % affordable_tooltip)
	_require(not affordable_tooltip.contains("Upgrade --"), "Expected no upgrade-comparison text in the tooltip anymore, got: %s" % affordable_tooltip)

	# Empty-slot offers still have a single item card.
	print("single item gear tooltip checks")
	var tooltip_control: Control = affordable_button._make_custom_tooltip("")
	_require(tooltip_control is HBoxContainer and tooltip_control.get_child_count() == 1, "Expected one item tooltip box.")
	var item_box: Control = tooltip_control.get_child(0)
	_require(item_box is PanelContainer, "Expected a tooltip-styled item panel.")
	var item_box_text: String = _labels_text(item_box)
	_require(item_box_text.contains(affordable_tooltip), "Item details and purchase hint retained.")
	_require(not item_box_text.contains("Equipped") and not item_box_text.contains("Nothing equipped.") and not item_box_text.contains("On equip:"), "Empty-slot references and equip deltas hidden.")
	tooltip_control.free()

	var equipped_weapon := GearItem.new()
	equipped_weapon.id = "test.equipped.weapon"
	equipped_weapon.display_name = "Test Equipped Dagger"
	equipped_weapon.slot = GearItem.SlotType.WEAPON
	equipped_weapon.tier = GearItem.Tier.BASIC
	var equipped_mod := StatModifier.new()
	equipped_mod.stat = StatModifier.StatType.ATTACK_SPEED
	equipped_mod.operation = StatModifier.OperationType.ADD
	equipped_mod.value = 0.05
	equipped_weapon.affixes = [equipped_mod]

	var candidate_weapon := GearItem.new()
	candidate_weapon.id = "test.candidate.weapon"
	candidate_weapon.display_name = "Test Candidate Dagger"
	candidate_weapon.slot = GearItem.SlotType.WEAPON
	candidate_weapon.tier = GearItem.Tier.MASTER
	var candidate_mod := StatModifier.new()
	candidate_mod.stat = StatModifier.StatType.ATTACK_SPEED
	candidate_mod.operation = StatModifier.OperationType.ADD
	candidate_mod.value = 0.10
	candidate_weapon.affixes = [candidate_mod]

	# A meaningful same-slot replacement cannot reveal comparisons in either mode.
	build_state.equipped_weapon = equipped_weapon
	var candidate_row: Button = combat_screen._shop_overlay._make_shop_offer_row(candidate_weapon)
	_require(not CardStyle.gear_comparison_lines(candidate_weapon, combat_screen._shop_overlay).is_empty(), "Fixture exercises a meaningful equip comparison.")
	for test_mode in [false, true]:
		build_state.is_test_mode = test_mode
		var candidate_tooltip: Control = candidate_row._make_custom_tooltip("")
		_require(candidate_tooltip.get_child_count() == 1, "Shop has one tooltip card in Adventure and Test.")
		var body := _labels_text(candidate_tooltip)
		_require(body.contains(candidate_weapon.display_name) and body.contains("Attack Speed") and body.contains("Price:"), "Shop retains candidate stats and price.")
		_require(not body.contains(equipped_weapon.display_name) and not body.contains("Equipped") and not body.contains("On equip:") and not body.contains(" -> "), "Shop hides all replacement comparison text.")
		candidate_tooltip.free()
	build_state.is_test_mode = false
	candidate_row.free()
	build_state.equipped_weapon = null

	build_state.gold = 4
	combat_screen._shop_overlay.refresh()
	await process_frame
	await _wait_for_reveals(combat_screen)
	_require(combat_screen._shop_overlay._shop_reroll_button.disabled, "Expected reroll to disable below its current gold cost.")
	_require(combat_screen._shop_overlay._shop_reroll_button.tooltip_text.contains("Need 5g"), "Expected reroll tooltip to explain the unaffordable cost.")
	combat_screen._on_shop_reroll_pressed()
	await process_frame
	await _wait_for_reveals(combat_screen)
	_require(combat_screen._shop_overlay._shop_status_label.text == "Not enough gold.", "Expected blocked reroll to explain the gold shortfall.")
	_require(combat_screen._shop_overlay._shop_reroll_button.get_meta("reroll_blocked_pulse") == true, "Expected blocked reroll to pulse the reroll action.")
	build_state.gold = 20
	combat_screen._shop_overlay.refresh()
	await process_frame
	await _wait_for_reveals(combat_screen)

	await _check_phase5_shop_offer_rarity_rendering(combat_screen, build_state)
	_check_phase5_reward_visual_helpers(combat_screen)
	await _check_mixed_rarity_reward_choice_rendering(combat_screen, build_state)

	# -- Route tradeoff text: differs between two real Gilded Serpent branch
	# pairs, derived from real Monster/EncounterReward data. --
	print("route tradeoff text checks")
	var contract: ContractDef = load("res://data/contracts/the_gilded_serpent.tres")
	var door_guard := _find_route_node(contract.offer_node, "route.gilded_serpent.door_guard")
	var portly_cook := _find_route_node(contract.offer_node, "route.gilded_serpent.portly_cook")
	var sleeping := _find_route_node(contract.offer_node, "route.gilded_serpent.sleeping_henchman")
	var cloaked := _find_route_node(contract.offer_node, "route.gilded_serpent.cloaked_watchmen")
	_require(door_guard != null and portly_cook != null and sleeping != null and cloaked != null, "Expected to find all four route nodes.")

	var opener_tradeoff: String = combat_screen._map_overlay._route_tradeoff_text(door_guard, portly_cook)
	print(opener_tradeoff)
	_require(
		opener_tradeoff == "Door Guard is the harder branch. Door Guard reward: Master -- Portly Cook reward: Basic.",
		"Expected the opener tradeoff sentence, got: %s" % opener_tradeoff
	)

	var second_layer_tradeoff: String = combat_screen._map_overlay._route_tradeoff_text(sleeping, cloaked)
	print(second_layer_tradeoff)
	_require(
		second_layer_tradeoff == "Cloaked Watchmen is the harder branch. Sleeping Henchman reward: Basic -- Cloaked Watchmen reward: Cursed.",
		"Expected the second-layer tradeoff sentence, got: %s" % second_layer_tradeoff
	)
	_require(opener_tradeoff != second_layer_tradeoff, "Expected the tradeoff text to differ between two different Gilded Serpent branch pairs.")

	# -- Live scene check: the route map's story text now prefers authored
	# flavor at the real opener-choice state. --
	# A second selected tree is required so BuildState.needs_secondary_subclass_
	# choice() reads false at the door_guard/portly_cook branch node (its
	# parent node's node_type is SUBCLASS_CHOICE) -- appended directly rather
	# than driving the full choice-overlay click flow, matching how
	# route_reward_choice_ui_test.gd sets route state directly.
	build_state.selected_trees.append(rogue.trees[0])
	build_state.active_contract = contract
	build_state.current_route_node = contract.offer_node.next_nodes[0]
	build_state.run_phase = BuildState.RunPhase.CONTRACT_ROUTE
	build_state.run_state_changed.emit()
	await process_frame
	await _wait_for_reveals(combat_screen)
	print(combat_screen._map_overlay._map_story_label.text)
	_require(combat_screen._map_overlay._map_story_label.text.contains("Gilded Serpent's hideout"), "Expected the live route map story text to use the authored opener flavor.")

	print("contract reward-row summary checks")
	build_state.current_route_node = door_guard
	build_state.run_phase = BuildState.RunPhase.RESULT
	build_state.last_fight_won = true
	build_state.run_state_changed.emit()
	combat_screen._populate_reward_row()
	await process_frame
	await _wait_for_reveals(combat_screen)
	var door_reward_row_text := _reward_row_text(combat_screen)
	print(door_reward_row_text)
	_require(door_reward_row_text.contains("Choice of Master Gear"), "Expected Door Guard result reward row to show the compact generated-gear label.")
	_require(door_reward_row_text.contains(": 22g"), "Expected Door Guard result reward row to show the gold icon value.")
	_require(not door_reward_row_text.contains("weapon or ring"), "Expected Door Guard result reward row to omit route-preview slot copy.")
	_require(not door_reward_row_text.contains("22g and"), "Expected Door Guard result reward row not to duplicate gold in prose.")
	_require(_reward_row_icon_count(combat_screen) == 1, "Expected Door Guard reward row to show only the gold icon.")

	# -- Reward-claim UI: Legendary reward tier/slot/affix rendering, using
	# Knives' real authored gear_choice_rewards. --
	print("Legendary reward-claim tier/slot/affix checks")
	var wyvern: GearItem = load("res://data/gear/wyvern_kriss.tres")
	var reward_text: String = combat_screen._reward_choice_text(wyvern)
	print(reward_text)
	_require(reward_text.begins_with("Wyvern Kriss"), "Expected the item name to start the reward text, got: %s" % reward_text)
	_require(reward_text.contains("Legendary Weapon / Dagger"), "Expected the tier/slot/family line, got: %s" % reward_text)
	_require(reward_text.contains("Weapon Damage: 21-27"), "Expected the Legendary weapon damage range, got: %s" % reward_text)
	_require(reward_text.contains("Poison"), "Expected an affix line, got: %s" % reward_text)
	_require(reward_text.contains("Poison ticks twice as fast"), "Expected Wyvern Kriss Legendary flavor text, got: %s" % reward_text)
	_require(not reward_text.contains("Poison Tick Interval"), "Expected Wyvern's tick-rate mechanic to be flavor text, not a raw interval affix, got: %s" % reward_text)
	_require(not reward_text.contains("Upgrade --"), "Expected no upgrade-comparison line anymore (removed in the P2:R7 second playtest-feedback pass), got: %s" % reward_text)
	_require(reward_text.contains("Click to choose."), "Expected an explicit choose hint, got: %s" % reward_text)

	print("")
	print("Reward/shop/route UI check: OK")
	quit()


func _find_route_node(node: ContractRouteNode, id: String, visited: Array[String] = []) -> ContractRouteNode:
	if node == null or visited.has(node.id):
		return null
	if node.id == id:
		return node
	visited.append(node.id)
	for child in node.next_nodes:
		var found := _find_route_node(child, id, visited)
		if found != null:
			return found
	return null


func _reward_row_text(combat_screen) -> String:
	var parts: PackedStringArray = []
	for child in combat_screen._victory_reward_row.get_children():
		if child is Label:
			parts.append(child.text)
	return " ".join(parts)


func _reward_row_icon_count(combat_screen) -> int:
	var count := 0
	for child in combat_screen._victory_reward_row.get_children():
		if child is TextureRect:
			count += 1
	return count


func _check_phase5_reward_visual_helpers(combat_screen) -> void:
	for tier in GearItem.rarity_order():
		var map_icon: Texture2D = combat_screen._map_overlay._gear_drop_icon_for_tier(tier)
		var contract_icon: Texture2D = combat_screen._contract_overlay._gear_drop_icon_for_tier(tier)
		_require(map_icon != null, "Expected map overlay gear-drop icon for %s." % GearGenerator.tier_name(tier))
		_require(contract_icon != null, "Expected contract overlay gear-drop icon for %s." % GearGenerator.tier_name(tier))
		_require(map_icon.resource_name != "", "Expected map overlay icon resource name for %s." % GearGenerator.tier_name(tier))
		_require(contract_icon.resource_name != "", "Expected contract overlay icon resource name for %s." % GearGenerator.tier_name(tier))
		_require(combat_screen._map_overlay._tier_color_for_map_reward(tier) == GearGenerator.tier_color(tier), "Expected map overlay tier color for %s." % GearGenerator.tier_name(tier))
		_require(combat_screen._contract_overlay._tier_color_for_contract_reward(tier) == GearGenerator.tier_color(tier), "Expected contract overlay tier color for %s." % GearGenerator.tier_name(tier))


func _check_phase5_shop_offer_rarity_rendering(combat_screen, build_state) -> void:
	print("Phase 5 shop offer rarity compatibility checks")
	var rng := RandomNumberGenerator.new()
	rng.seed = 557
	var offers: Array[GearItem] = []
	for tier in [
		GearItem.Tier.BASIC,
		GearItem.Tier.MASTER,
		GearItem.Tier.EPIC,
		GearItem.Tier.CURSED,
		GearItem.Tier.CHAOS,
		GearItem.Tier.UNIQUE,
	]:
		var offer := GearGenerator.generate(tier, GearItem.SlotType.WEAPON, rng, "test.shop.phase5.%d" % tier)
		_require(offer != null, "Expected generated shop offer for %s." % GearGenerator.tier_name(tier))
		offers.append(offer)

	build_state.gold = 999
	build_state.shop_round_pending = true
	build_state.shop_offers = offers
	combat_screen._shop_overlay.refresh()
	await combat_screen.get_tree().process_frame
	await _wait_for_reveals(combat_screen)
	_require(combat_screen._shop_overlay._shop_offers_box.get_child_count() == offers.size(), "Expected one shop box for each Phase 5 shop rarity.")
	for i in offers.size():
		var offer: GearItem = offers[i]
		var button: Button = combat_screen._shop_overlay._shop_offers_box.get_child(i)
		_require(not button.disabled, "Expected high-gold Phase 5 shop offer to be affordable: %s." % GearGenerator.tier_name(offer.tier))
		_require(button.tooltip_text.contains(GearGenerator.tier_name(offer.tier)), "Expected shop tooltip tier for %s, got: %s" % [GearGenerator.tier_name(offer.tier), button.tooltip_text])
		_require(button.tooltip_text.contains("Price: %dg" % GearGenerator.price_for_tier(offer.tier)), "Expected shop tooltip price for %s." % GearGenerator.tier_name(offer.tier))
		_require(button.find_child("PriceBadge", true, false) != null, "Expected price badge for %s shop offer." % GearGenerator.tier_name(offer.tier))
		_require(button.find_child("PriceLabel", true, false).text == "%dg" % GearGenerator.price_for_tier(offer.tier), "Expected visible price for %s shop offer." % GearGenerator.tier_name(offer.tier))
		var icon: TextureRect = button.get_node("Icon")
		_require(icon.texture != null, "Expected gear icon for %s shop offer." % GearGenerator.tier_name(offer.tier))
		var style := button.get_theme_stylebox("normal") as StyleBoxFlat
		_require(style != null and style.bg_color == GearGenerator.tier_color(offer.tier).darkened(0.08), "Expected shop box color for %s." % GearGenerator.tier_name(offer.tier))
		if offer.tier == GearItem.Tier.EPIC:
			_require(style.border_color == UIColors.PANEL_EDGE_LIGHT, "Expected Epic shop offer to use a distinct bright border.")
			_require(style.border_width_top > 1, "Expected Epic shop offer to keep a stronger border treatment.")


func _check_mixed_rarity_reward_choice_rendering(combat_screen, build_state) -> void:
	print("mixed-rarity reward choice compatibility checks")
	var rng := RandomNumberGenerator.new()
	rng.seed = 991
	var basic_choice := GearGenerator.generate(GearItem.Tier.BASIC, GearItem.SlotType.WEAPON, rng, "test.reward.basic")
	var unique_choice := GearGenerator.generate(GearItem.Tier.UNIQUE, GearItem.SlotType.WEAPON, rng, "test.reward.unique")
	_require(basic_choice != null and unique_choice != null, "Expected mixed generated reward choices.")
	unique_choice.reward_base_tier = GearItem.Tier.BASIC
	unique_choice.reward_tier_steps = _tier_steps([GearItem.Tier.BASIC, GearItem.Tier.MASTER, GearItem.Tier.EPIC, GearItem.Tier.UNIQUE])
	unique_choice.reward_magic_find_upgraded = true
	var mixed_choices: Array[GearItem] = [basic_choice, unique_choice]
	build_state.pending_reward_choices = mixed_choices
	build_state.inventory.clear()
	build_state.equipped_weapon = GearGenerator.generate(GearItem.Tier.MASTER, GearItem.SlotType.WEAPON, rng, "test.reward.equipped")
	combat_screen._show_reward_choice_overlay()
	await combat_screen.get_tree().process_frame
	await _wait_for_reveals(combat_screen)

	var options: HBoxContainer = combat_screen._reward_choice_overlay.options_container()
	_require(options.get_child_count() == 2, "Expected mixed-rarity reward pair to render two buttons.")
	for i in options.get_child_count():
		var choice: GearItem = build_state.pending_reward_choices[i]
		var button: Button = options.get_child(i)
		_require(button is GearCompareButton, "Expected reward choice to use comparison tooltip button.")
		_require(button.custom_minimum_size == Vector2(112, 112), "Expected stable reward choice box size.")
		_require(button.tooltip_text.contains(GearGenerator.tier_name(choice.tier)), "Expected reward tooltip tier for %s." % GearGenerator.tier_name(choice.tier))
		_require(button.tooltip_text.contains("Click to choose."), "Expected reward choice hint.")
		var icon: TextureRect = button.get_node("Icon")
		_require(icon.texture != null, "Expected reward choice icon for %s." % GearGenerator.tier_name(choice.tier))
		var style := button.get_theme_stylebox("normal") as StyleBoxFlat
		_require(style != null and style.bg_color == GearGenerator.tier_color(choice.tier).darkened(0.08), "Expected reward choice box color for %s." % GearGenerator.tier_name(choice.tier))
		_require(not combat_screen._reward_choice_reveal_active, "Expected reward choices to be fully revealed before final-tier assertions.")
		var tooltip: Control = button._make_custom_tooltip("")
		_require(tooltip is PanelContainer, "Expected one reward item tooltip card.")
		var reward_body := _labels_text(tooltip)
		_require(reward_body.contains(choice.display_name) and reward_body.contains("Click to choose."), "Reward card retains item details and choice hint.")
		_require(not reward_body.contains("Equipped") and not reward_body.contains("On equip:"), "Reward card hides equipped references and projected stats.")
		tooltip.free()

	combat_screen._reward_choice_overlay.visible = false
	build_state.pending_reward_choices.clear()
	build_state.equipped_weapon = null

	var placeholder: Button = combat_screen._make_reward_choice_placeholder()
	combat_screen.add_child(placeholder)
	combat_screen._reveal_reward_choice_button(placeholder, unique_choice)
	var base_style := placeholder.get_theme_stylebox("normal") as StyleBoxFlat
	_require(base_style != null and base_style.bg_color == GearGenerator.tier_color(GearItem.Tier.BASIC).darkened(0.08), "Expected animated reward reveal to start at the stored base tier.")
	combat_screen._apply_reward_choice_visual_tier(placeholder, unique_choice, GearItem.Tier.MASTER)
	var master_style := placeholder.get_theme_stylebox("normal") as StyleBoxFlat
	_require(master_style != null and master_style.bg_color == GearGenerator.tier_color(GearItem.Tier.MASTER).darkened(0.08), "Expected animated reward reveal to step through intermediate tiers.")
	placeholder.queue_free()


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)


func _labels_text(root_node: Node) -> String:
	var parts: PackedStringArray = []
	_collect_label_text(root_node, parts)
	return "\n".join(parts)


func _tier_steps(values: Array) -> Array[int]:
	var result: Array[int] = []
	for value in values:
		result.append(int(value))
	return result


func _collect_label_text(root_node: Node, parts: PackedStringArray) -> void:
	if root_node is RichTextLabel:
		parts.append((root_node as RichTextLabel).get_parsed_text())
	elif root_node is Label:
		parts.append((root_node as Label).text)
	for child in root_node.get_children():
		_collect_label_text(child, parts)


func _wait_for_reveals(combat_screen) -> void:
	# D053 starts the sequential rollout only when the real shop is visible.
	if combat_screen._shop_overlay.is_busy():
		combat_screen._shop_overlay.show()
	var deadline := Time.get_ticks_msec() + 12000
	while (combat_screen._shop_overlay.is_busy() or combat_screen._reward_choice_reveal_active) and Time.get_ticks_msec() < deadline:
		await process_frame
	_require(not combat_screen._shop_overlay.is_busy() and not combat_screen._reward_choice_reveal_active, "Actual shop/reward reveal completes before final-state assertions.")
