extends "res://tests/m9_t7_visual.gd"
## Scoped review: real refund/destruction/reward handlers and overflowing target UI.
const OUTPUT := "res://reports/m9_ui_cleanup/"
var evidence := {}
func _initialize() -> void:
	SaveSystem.save_path = OUTPUT + "adventure.json"
	PracticeSaveSystem.save_path = OUTPUT + "practice.json"
	PracticeSaveSystem.core_save_path = OUTPUT + "core.json"
	SevenSlotSaveBoundary.legacy_path = OUTPUT + "legacy.json"
	SevenSlotSaveBoundary.marker_path = OUTPUT + "marker.json"
	for path in SevenSlotSaveBoundary.paths().values():
		for candidate in [path,path+".tmp"]:
			if FileAccess.file_exists(candidate): assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate)) == OK)
	call_deferred("run")
func capture(label: String) -> void:
	await settle()
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(OUTPUT+label+".png") == OK)
func settle() -> void:
	for i in 4: await process_frame
func press(view: Control, key: String) -> void:
	view.actions[key].pressed.emit()
	await settle()
func text_of(node: Node) -> String:
	var result := ""
	if node is RichTextLabel: result += node.get_parsed_text()+"\n"
	elif node is Label: result += node.text+"\n"
	for child in node.get_children(): result += text_of(child)
	return result
func dense_target() -> Monster:
	var enemy := Monster.new()
	enemy.display_name = "Dense target with a deliberately long title that clips before attempts"
	enemy.hp = 123456
	enemy.armor = 250
	enemy.poison_resistance = 0.4
	enemy.block = 30
	enemy.dodge_chance = 0.25
	enemy.crit_negation = 0.2
	enemy.slow = 0.15
	enemy.absorb = 20
	enemy.suppress = 0.3
	enemy.cleanse_threshold = 5
	enemy.stun_duration_ms = 1500
	enemy.interrupt_skip_count = 2
	return enemy
func check_enemy(screen: Node, mode: String) -> void:
	var enemy: Control = screen._enemy_panel
	var gear: Control = screen._gear_panel
	enemy.show_presented_target(dense_target(),20000)
	await settle()
	var info: RichTextLabel = enemy._info_label
	var bar := info.get_v_scroll_bar()
	assert(is_equal_approx(enemy.size.y,230),"Fixed target height")
	assert(bar.visible and bar.max_value > bar.page,"Dense target overflows in scrollbar")
	assert(enemy.get_global_rect().encloses(info.get_global_rect()),"Stats viewport inside target")
	assert(enemy._title_label.clip_text and enemy._attempts_badge.visible,"Clipped title and attempts retained")
	assert(screen._enemy_panel.fight_button().is_inside_tree(),"Fight button still attached")
	assert(Rect2(0,0,1600,900).encloses(gear.get_global_rect()),"Whole Gear panel stays in dashboard")
	assert(is_equal_approx(gear.get_global_rect().end.y,884),"Dashboard bottom remains 884")
	for panel_name in ["CharacterStatsPanel","ActiveTalentsPanel","SkillBuildPanel"]:
		var panel: Control = screen.find_child(panel_name,true,false)
		if panel != null and panel.is_visible_in_tree(): assert(Rect2(0,0,1600,900).encloses(panel.get_global_rect()),"Dashboard bounds")
	bar.value = 0
	await capture(mode+"_enemy_top")
	bar.value = bar.max_value
	await settle()
	assert(is_equal_approx(bar.value,bar.max_value-bar.page),"Scroll reaches final stats")
	await capture(mode+"_enemy_bottom")
	evidence[mode] = {"enemy":str(enemy.get_global_rect()),"stats_viewport":str(info.get_global_rect()),"gear":str(gear.get_global_rect()),"scroll_max":bar.max_value,"scroll_page":bar.page,"scroll_bottom":bar.value,"stats":info.get_parsed_text()}
	enemy._set_empty_state("No Target","Choose the next target.")
	await settle()
	assert(not bar.visible and is_equal_approx(enemy.size.y,230),"Short content hides scrollbar and retains panel height")
	enemy.clear_presented_target()
func check_item_hover(host: Control, source: Button, candidate: GearItem, equipped: GearItem, label: String) -> void:
	var hover: Control = source._make_custom_tooltip("")
	host.add_child(hover)
	hover.position = Vector2(820,320)
	hover.z_index = 120
	await settle()
	var body := text_of(hover)
	assert(hover is PanelContainer or (hover is HBoxContainer and hover.get_child_count() == 1), "One hovered item box")
	assert(body.contains(candidate.display_name) and body.contains(LegendaryCatalog.effect_text(candidate)), "Own Legendary identity and effect retained")
	for line in CardStyle.gear_tooltip_lines(candidate): assert(body.contains(line), "Own item stats retained")
	assert(not body.contains(equipped.display_name) and not body.contains("Equipped") and not body.contains("Nothing equipped.") and not body.contains("On equip:") and not body.contains(" -> "), "All gear comparisons hidden")
	assert(Rect2(0,0,1600,900).encloses(hover.get_global_rect()), "Item hover fits viewport")
	evidence[label] = {"body":body,"rect":str(hover.get_global_rect()),"item_boxes":1}
	await capture(label)
	hover.queue_free()
	await settle()
func check_gear_hovers(screen: Control, mode: String) -> void:
	var candidate: GearItem = load("res://data/gear/nightkiss_kitana.tres")
	var equipped: GearItem = load("res://data/gear/mithril_karambit.tres")
	state.equipped_weapon = equipped
	assert(state.add_inventory_item(candidate))
	state.build_changed.emit()
	await settle()
	var before_gear: Array = state.equipped_gear().duplicate()
	var before_gold: int = state.gold
	assert(not CardStyle.gear_comparison_lines(candidate,screen).is_empty(), "Fixture has real equip differences")
	var inventory_button: Button = screen._gear_panel._inventory_button_for_item(candidate)
	await check_item_hover(screen,inventory_button,candidate,equipped,mode+"_inventory_item_hover")
	var shop_row: Button = screen._shop_overlay._make_shop_offer_row(candidate)
	var shop_hover: Control = shop_row._make_custom_tooltip("")
	for footer_line in screen._shop_overlay._shop_offer_footer_lines(candidate):
		assert(text_of(shop_hover).contains(footer_line), "Shop cost and current action hint retained")
	shop_hover.free()
	await check_item_hover(screen,shop_row,candidate,equipped,mode+"_shop_item_hover")
	shop_row.free()
	# Hidden Chaos keeps both its affixes and identity concealed.
	var chaos := item(GearItem.SlotType.WEAPON)
	chaos.tier = GearItem.Tier.CHAOS
	chaos.is_unidentified = true
	chaos.display_name = "Secret Chaos Dagger"
	var chaos_button: Button = screen._gear_panel._make_inventory_slot(chaos)
	var chaos_hover: Control = chaos_button._make_custom_tooltip("")
	var chaos_body := text_of(chaos_hover)
	assert(chaos_body.contains("Unidentified") and not chaos_body.contains(chaos.display_name) and not chaos_body.contains("On equip:") and not chaos_body.contains("Equipped"), "Hidden Chaos remains concealed")
	chaos_hover.free()
	chaos_button.free()
	assert(state.equipped_gear() == before_gear and state.gold == before_gold, "Hovers do not equip or spend gold")
	state.inventory.erase(candidate)
	state.build_changed.emit()
	await settle()
func run() -> void:
	root.size = Vector2i(1600,900)
	root.gui_embed_subwindows = true
	state = root.get_node("BuildState")
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_new_game_pressed(1928)
	state.set_class(load("res://data/classes/rogue.tres"))
	assert(state.configure_ranked_build(BuildContentRegistry.adventure().trees["tree.bladedancer"]))
	game._show_combat_screen()
	await settle()
	var screen = game._current_screen
	dismiss(screen)
	await check_enemy(screen,"adventure")
	await check_gear_hovers(screen,"adventure")
	game._on_contract_test_pressed(424242,10)
	await settle()
	screen = game._current_screen
	dismiss(screen)
	await check_enemy(screen,"test")
	await check_gear_hovers(screen,"test")
	var view = screen._talent_overlay._talent_panel._ranked_view
	screen._talent_overlay.show()
	for i in 4: await press(view,"buy:talent.bladedancer.wet_stone")
	await press(view,"buy:talent.bladedancer.rending_slash")
	await press(view,"buy:talent.bladedancer.fancy_footwork")
	var macro: Array[Skill] = []
	for skill in state.unlocked_skills():
		if skill.id == "skill.parry_strike": macro.append(skill)
	assert(macro.size() == 1)
	state.set_rotation(macro)
	await press(view,"reset:tree.bladedancer")
	assert(state.rotation.is_empty() and state.ranked_build.points_spent() == 0,"Actual refund prunes macro and restores points")
	assert(not view.find_child("AllocationFeedback",true,false).visible,"Refund has no top status")
	await capture("talent_refunded")
	screen._talent_overlay.hide()
	var coin: GearItem = load("res://data/gear/lucky_coin.tres")
	assert(state.add_inventory_item(coin))
	var panel = screen._gear_panel
	panel._pending_destroy_inventory_item = coin
	panel._on_destroy_confirmed()
	await settle()
	assert(state.mysterious_coin_unlocked and not state.inventory.has(coin),"Coin destroyed and mystery unlock retained")
	assert(panel.find_child("LegendaryDiscoveryNotice",true,false) == null,"Coin destruction has no status")
	await capture("coin_destroyed")
	var reward := item(GearItem.SlotType.LEGS)
	var choices: Array[GearItem] = [reward]
	state.pending_reward_choices = choices
	state.run_phase = state.RunPhase.RESULT
	var button = screen._make_reward_choice_placeholder()
	screen._populate_reward_choice_button(button,reward)
	screen.add_child(button)
	button.position = Vector2(680,360)
	var tooltip: Control = button._make_custom_tooltip("")
	screen.add_child(tooltip)
	tooltip.position = Vector2(810,300)
	tooltip.z_index = 120
	await settle()
	var body := text_of(tooltip)
	assert(tooltip is PanelContainer and body.contains(reward.display_name) and body.contains("Click to choose."),"Single reward item card retains own details and footer")
	assert(not body.contains("Equipped") and not body.contains("On equip:"),"Reward comparison hidden")
	assert(Rect2(0,0,1600,900).encloses(tooltip.get_global_rect()),"Reward card bounds")
	await capture("reward_item_hover")
	while state.can_add_inventory_item(): assert(state.add_inventory_item(item(GearItem.SlotType.HANDS)))
	var full_tooltip: Control = button._make_custom_tooltip("")
	assert(text_of(full_tooltip).contains("Inventory full -- make space before choosing."),"Single card retains capacity hint")
	full_tooltip.free()
	var blocked_inventory: Array = state.inventory.duplicate()
	button.pressed.emit()
	await settle()
	assert(state.inventory == blocked_inventory and state.pending_reward_choices.has(reward),"Full inventory blocks actual reward transaction")
	state.inventory.clear()
	var comparison := CardStyle.build_gear_compare_tooltip(screen, "\n".join(CardStyle.gear_tooltip_lines(reward)),load("res://data/gear/crude_dagger.tres"),reward)
	assert(comparison is HBoxContainer and comparison.get_child_count() == 1 and text_of(comparison).contains(reward.display_name) and not text_of(comparison).contains("Equipped"),"Shared legacy caller retains one item card")
	comparison.free()
	tooltip.queue_free()
	button.pressed.emit()
	await settle()
	assert(state.inventory.has(reward) and state.pending_reward_choices.is_empty(),"Real reward choice handler still transfers item")
	evidence["reward"] = {"body":body,"inventory_transfer":true}
	game.queue_free()
	await settle()
	var room = load("res://scenes/training_room/training_room.tscn").instantiate()
	root.add_child(room)
	await settle()
	var practice_candidate: GearItem = load("res://data/gear/nightkiss_kitana.tres")
	room._state.equip_legendary(practice_candidate)
	await settle()
	await check_item_hover(room,room._weapon_slot_button,practice_candidate,load("res://data/gear/mithril_karambit.tres"),"practice_item_hover")
	room.queue_free()
	await settle()
	var file := FileAccess.open(OUTPUT+"geometry.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(evidence,"\t"))
	file.close()
	print("M9 UI CLEANUP PASS")
	quit()
