extends SceneTree
## M4 playable Test Mode entry, generated offers and route selection.



func _initialize() -> void:
	var build_state = root.get_node("BuildState")
	SaveSystem.save_path = "res://.test_contract_test_entry_save.json"
	SaveSystem.delete_save()
	build_state.reset()

	var game_root_scene: PackedScene = load("res://scenes/game_root.tscn")
	var game_root = game_root_scene.instantiate()
	root.add_child(game_root)
	await process_frame

	var title = game_root._current_screen
	var contract_test_button := _find_button(title, "Test Mode")
	_require(contract_test_button != null and not contract_test_button.disabled, "Expected Test Mode to be available.")

	title._random_seed_check_box.button_pressed = false
	title._on_random_seed_toggled(false)
	title._seed_spin_box.value = 424242
	title.contract_test_pressed.emit()
	await process_frame
	await process_frame

	var combat_screen = game_root._current_screen
	_require(combat_screen != null, "Expected Contract Test to open the combat screen.")
	_require(combat_screen != title, "Expected Contract Test to skip the title screen.")
	_require(combat_screen.get_script().resource_path == "res://scenes/combat/combat_screen.gd", "Expected Contract Test to open the real combat screen.")
	_require(build_state.adventure_seed == 424242, "Expected Contract Test to use the selected menu seed.")
	_require(build_state.selected_class != null and build_state.selected_class.id == "class.rogue", "Expected Contract Test to choose Rogue.")
	_require(build_state.selected_trees.size() == 1, "Expected Contract Test to start with one Rogue tree.")
	_require(build_state.selected_trees[0].display_name == "Bladedancer", "Expected Bladedancer as the primary Contract Test tree.")
	_require(build_state.selected_talents.is_empty(), "Expected Contract Test to start with no talents spent.")
	_require(build_state.earned_talent_points == 6, "Expected Contract Test to start with six unspent talent points.")
	_require(build_state.gold == 100, "Expected Contract Test to start with 100 gold.")
	_require(build_state.equipped_weapon != null, "Expected Contract Test to start with an equipped weapon.")
	_require(build_state.equipped_weapon.id == "gear.legendary.bandit_blade", "Expected Contract Test to start with Bandit Blade equipped.")
	_require(build_state.inventory.is_empty(), "Expected Contract Test Bandit Blade to be equipped, not carried in inventory.")
	_require(build_state.rotation.is_empty(), "Expected Contract Test to start with an empty skill macro.")
	_require(not build_state.needs_tavern_map_choice(), "Expected Contract Test to skip Tavern map setup.")
	_require(build_state.active_contract != null, "Expected Contract Test to load an active contract.")
	_require(build_state.active_contract.has_generated_route_state(), "Expected Contract Test to start with generated offers only.")
	_require(build_state.pending_contract_offers.size() == 3, "Expected Contract Test to offer three generated contracts.")
	for index in range(0, build_state.pending_contract_offers.size()):
		var offer: ContractDef = build_state.pending_contract_offers[index]
		_require(offer.has_generated_route_state(), "Expected every Contract Test offer to be generated.")
	_require(build_state.run_phase == BuildState.RunPhase.CONTRACT_OFFER, "Expected Contract Test to land at generated contract offer choice.")
	_require(build_state.current_route_node != null, "Expected Contract Test to have a current route node.")
	_require(not build_state.needs_secondary_subclass_choice(), "Expected Assassin + Bladedancer to satisfy the secondary subclass slot.")
	_require(combat_screen._contract_overlay.visible, "Expected Contract Test to show Ghit Gudd's Contract Window.")
	_require(combat_screen._contract_overlay._contract_options_box.get_child_count() == 3, "Expected three generated contract options.")
	_require(combat_screen._contract_overlay._contract_title_label.text == "Choose a Contract", "Expected Contract Test picker header to invite contract choice.")
	_require(combat_screen._contract_overlay._contract_body_label.visible and "core only" in combat_screen._contract_overlay._contract_body_label.text, "Expected Test Mode content boundary to be explained.")
	var generated_card_count := 0
	for index in range(0, combat_screen._contract_overlay._contract_options_box.get_child_count()):
		var child: Node = combat_screen._contract_overlay._contract_options_box.get_child(index)
		var button := child as Button
		_require(button != null, "Expected Contract Test option to be a button.")
		_require(button.text == "", "Expected generated contract card to use composed labels instead of button text.")
		_require(_card_label_text(button, "ContractBossNameLabel") != "", "Expected generated contract card to show boss name.")
		_require(_card_label_text(button, "ContractLocationLabel").begins_with("Location: "), "Expected generated contract card to show biome location.")
		var reward_amounts := _contract_reward_amount_texts(button)
		_require(_reward_amounts_contain_suffix(reward_amounts, "g"), "Expected generated contract card to show gold reward as an icon row.")
		_require(reward_amounts.has("x %d" % BuildProgression.CONTRACT_POINTS), "Expected generated contract card to show the approved contract talent-point reward.")
		_require(_contract_card_icon(button).custom_minimum_size == Vector2(64, 64), "Expected generated contract card icon to be larger.")
		_require(_card_label_font_size(button, "ContractBossNameLabel") > _card_label_font_size(button, "ContractLocationLabel"), "Expected boss name to use a larger font than card details.")
		generated_card_count += 1
	_require(generated_card_count == 3, "Expected exactly three generated contract cards.")
	_require(combat_screen._contract_overlay._contract_action_button.disabled, "Expected Proceed to wait for a contract selection.")
	_require(not combat_screen._story_overlay.visible, "Expected Contract Test to skip the Tavern intro story.")
	_require(not combat_screen._map_overlay.visible, "Expected Contract Test to wait in the generated contract picker before route selection.")

	var first_offer_button: Button = combat_screen._contract_overlay._contract_options_box.get_child(0)
	first_offer_button.pressed.emit()
	await process_frame
	_require(not combat_screen._contract_overlay._contract_action_button.disabled, "Expected Proceed enabled after selecting a generated contract.")
	combat_screen._contract_overlay._contract_action_button.pressed.emit()
	await process_frame
	_require(build_state.run_phase == BuildState.RunPhase.CONTRACT_ROUTE, "Expected generated contract preview to open route flow.")
	_require(build_state.pending_contract_offers.size() == 3, "Expected generated offers to remain pending while previewing the route map.")
	_require(combat_screen._map_overlay.visible, "Expected generated route map after choosing a generated contract.")
	_require(combat_screen._map_overlay._map_contract_back_button.visible, "Expected accepted contract route choice map to allow returning to contract offers before route commit.")
	_require(
		combat_screen._map_overlay._map_node_buttons.size() > build_state.current_route_node.next_nodes.size(),
		"Expected generated route preview to show the full route graph."
	)

	var first_route_button: Button = combat_screen._map_overlay._map_node_buttons[0]
	first_route_button.pressed.emit()
	await process_frame
	_require(not combat_screen._map_overlay._map_proceed_button.disabled, "Expected Proceed enabled after selecting a first route node.")
	combat_screen._map_overlay._map_proceed_button.pressed.emit()
	await process_frame
	_require(build_state.run_phase == BuildState.RunPhase.PLANNING, "Expected first route node to enter planning before combat.")
	_require(build_state.pending_contract_offers.size() == 3, "Expected generated offers to remain pending before first combat starts.")
	combat_screen._show_map_overlay(true)
	await process_frame
	_require(not combat_screen._map_overlay._map_contract_back_button.visible, "Expected combat map review to prevent returning to contract offers.")
	combat_screen._map_overlay._map_contract_back_button.pressed.emit()
	await process_frame
	_require(build_state.run_phase == BuildState.RunPhase.PLANNING, "Expected Back to Contracts press to be ignored after contract acceptance.")

	print("Contract Test entry check: OK")
	SaveSystem.delete_save()
	SaveSystem.save_path = SaveSystem.SAVE_PATH
	quit()


func _find_button(root_node: Node, text: String) -> Button:
	for child in root_node.find_children("*", "Button", true, false):
		if child.text == text:
			return child
	return null


func _card_label_text(card: Button, label_name: String) -> String:
	var label: Label = card.find_child(label_name, true, false)
	_require(label != null, "Expected contract card label %s." % label_name)
	return label.text


func _card_label_font_size(card: Button, label_name: String) -> int:
	var label: Label = card.find_child(label_name, true, false)
	_require(label != null, "Expected contract card label %s." % label_name)
	return label.get_theme_font_size("font_size")


func _contract_card_icon(card: Button) -> TextureRect:
	var content: HBoxContainer = card.find_child("ContractOfferContent", true, false)
	_require(content != null, "Expected composed contract card content.")
	var icon: TextureRect = content.find_child("Icon", true, false)
	_require(icon != null, "Expected contract card icon.")
	return icon


func _contract_reward_amount_texts(card: Button) -> Array[String]:
	var stack: BoxContainer = card.find_child("ContractRewardStack", true, false)
	_require(stack != null, "Expected contract card reward icon stack.")
	var texts: Array[String] = []
	for label in stack.find_children("ContractRewardAmount", "Label", true, false):
		texts.append((label as Label).text)
	return texts


func _reward_amounts_contain_suffix(texts: Array[String], suffix: String) -> bool:
	for text in texts:
		if text.ends_with(suffix):
			return true
	return false


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	SaveSystem.delete_save()
	SaveSystem.save_path = SaveSystem.SAVE_PATH
	quit(1)
