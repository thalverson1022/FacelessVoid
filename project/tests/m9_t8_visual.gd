extends "res://tests/m9_t7_visual.gd"
const OUTPUT := "res://reports/m9_t8_visual/"
var evidence := {}
func _initialize() -> void:
	SaveSystem.save_path = OUTPUT + "adventure.json"
	PracticeSaveSystem.save_path = OUTPUT + "practice.json"
	PracticeSaveSystem.core_save_path = OUTPUT + "core.json"
	SevenSlotSaveBoundary.legacy_path = OUTPUT + "legacy.json"
	SevenSlotSaveBoundary.marker_path = OUTPUT + "marker.json"
	for path in SevenSlotSaveBoundary.paths().values():
		for candidate in [path,path+".tmp"]:
			if FileAccess.file_exists(candidate): DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate))
	call_deferred("run")
func capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(OUTPUT+label+".png") == OK)
func show_cards(owner: Control, label: String) -> void:
	var cards := []
	for index in range(16,20):
		var card := CardStyle.build_gear_tooltip(owner,LegendaryCatalog.all_items()[index])
		card.z_index = 100
		owner.add_child(card)
		card.position = Vector2(10+(index-16)*396,545)
		cards.append(card)
	await capture(label)
	for card in cards:
		assert(Rect2(0,0,1600,900).encloses(card.get_global_rect()), "Item card viewport fit")
		card.queue_free()
	await process_frame
func arctic_result(stats: PlayerStats) -> CombatResolver.CombatResult:
	var monster := Monster.new()
	monster.display_name = "Arctic Timer Review"
	monster.hp = 1000
	var rotation: Array[Skill] = [load("res://data/skills/stab.tres")]
	return CombatResolver.resolve(rotation,stats,monster,20000,88)
func screen_clock(screen: Node, mode: String) -> void:
	state.equip(load("res://data/gear/arctic_mittens.tres"))
	var rotation: Array[Skill] = [load("res://data/skills/stab.tres")]
	state.set_rotation(rotation)
	var result := arctic_result(state.current_player_stats())
	var monster := Monster.new()
	monster.display_name = "Arctic Timer Review"
	monster.hp = 1000
	screen.instant_playback = false
	screen._begin_playback(result,monster)
	screen.set_process(false)
	var presenter = screen._playback_presenter
	presenter._intro_remaining_sec = 0
	presenter.set_speed(0)
	for time in [0,10000,20000,26667]:
		# Drive the recorded simulation clock through ordinary advance; UI does
		# no fresh resolve and reads only the result frozen before this loop.
		var clock: CombatPlayback = presenter._playback
		clock.speed = 1
		if time == 26667:
			# Disconnect outcome reveal only in this render fixture to retain HUD.
			clock.finished_callback = Callable()
		while clock.elapsed_ms() < time:
			clock.advance(maxf(0.001,(time-clock.elapsed_ms())/1000.0))
		clock.speed = 0
		screen._update_playback_time_label()
		var text: String = screen._fight_timer_label.text
		assert(text == {0:"20.0s",10000:"12.5s",20000:"5.0s",26667:"0.0s"}[time])
		evidence[mode+"_"+str(time)] = {"elapsed_ms":clock.elapsed_ms(),"nominal_ms":result.nominal_duration_ms,"effective_ms":result.duration_ms,"countdown_text":text,"rate":result.countdown_rate}
		await capture(mode+"_arctic_"+str(time))
	screen._playback_active = false
	presenter._playback = null
func run() -> void:
	root.size = Vector2i(1600,900)
	root.gui_embed_subwindows = true
	state = root.get_node("BuildState")
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._on_new_game_pressed(1928)
	state.set_class(load("res://data/classes/rogue.tres"))
	assert(state.configure_ranked_build(BuildContentRegistry.adventure().trees["tree.bladedancer"]))
	game._show_combat_screen()
	await process_frame
	var screen = game._current_screen
	dismiss(screen)
	var panel = screen.find_child("GearPanel",true,false)
	await capture("adventure_empty")
	for slot in GearItem.universal_slot_order(): state.equip(item(slot))
	await capture("adventure_ordinary")
	record("adventure_ordinary",slots(panel))
	for pants in ["serpents_scales","golden_greeves"]:
		for gloves in ["arctic_mittens","hands_of_the_lightning_lord"]:
			state.equip(load("res://data/gear/"+pants+".tres"))
			state.equip(load("res://data/gear/"+gloves+".tres"))
			await capture("adventure_"+pants+"_"+gloves)
	await show_cards(screen,"adventure_four_cards")
	await screen_clock(screen,"adventure")
	game._on_contract_test_pressed(424242,10)
	await process_frame
	screen = game._current_screen
	dismiss(screen)
	panel = screen.find_child("GearPanel",true,false)
	for slot in GearItem.universal_slot_order():
		if slot != GearItem.SlotType.WEAPON: state.equip(item(slot))
	state.equip(load("res://data/gear/golden_greeves.tres"))
	state.equip(load("res://data/gear/arctic_mittens.tres"))
	await capture("test_legendary")
	record("test_legendary",slots(panel))
	await show_cards(screen,"test_four_cards")
	await screen_clock(screen,"test")
	game.queue_free()
	await process_frame
	state.reset()
	var room = load("res://scenes/training_room/training_room.tscn").instantiate()
	root.add_child(room)
	await capture("practice_empty")
	for slot in GearItem.universal_slot_order():
		var custom: GearItem = room._state.get("practice_"+GearItem.SlotType.keys()[slot].to_lower())
		room._state.set_slot_rarity(custom,GearItem.Tier.MASTER)
	room._state.equip_legendary(load("res://data/gear/serpents_scales.tres"))
	room._state.equip_legendary(load("res://data/gear/arctic_mittens.tres"))
	await capture("practice_legendary")
	var practice_slots := []
	for slot in GearItem.universal_slot_order(): practice_slots.append(room._gear_slot_buttons[slot])
	record("practice_legendary",practice_slots)
	await show_cards(room,"practice_four_cards")
	for slot in [GearItem.SlotType.LEGS,GearItem.SlotType.HANDS]:
		room._gear_slot_buttons[slot].pressed.emit()
		await capture("practice_"+str(slot)+"_fixed_details")
		room._gear_legendary_option.show_popup()
		await capture("practice_"+str(slot)+"_picker")
		room._gear_legendary_option.get_popup().hide()
		room._gear_editor_overlay.hide()
	var rotation: Array[Skill] = [load("res://data/skills/stab.tres")]
	room._state.set_rotation(rotation)
	var result := arctic_result(room._state.current_player_stats())
	var view = room._combat_view
	view._instant_playback = false
	var equipped: Array[GearItem] = [load("res://data/gear/arctic_mittens.tres")]
	view.play(result,room._state.selected_target,equipped)
	view.set_process(false)
	view._playback_intro_remaining_sec = 0
	for time in [0,10000,20000,26667]:
		var clock: CombatPlayback = view._playback
		if time == 26667: clock.finished_callback = Callable()
		clock.speed = 1
		while clock.elapsed_ms() < time:
			clock.advance(maxf(0.001,(time-clock.elapsed_ms())/1000.0))
		clock.speed = 0
		view._update_time_label()
		var text: String = view._fight_timer_label.text
		assert(text == {0:"20.0s",10000:"12.5s",20000:"5.0s",26667:"0.0s"}[time])
		evidence["practice_"+str(time)] = {"elapsed_ms":clock.elapsed_ms(),"countdown_text":text,"nominal_ms":result.nominal_duration_ms,"effective_ms":result.duration_ms}
		await capture("practice_arctic_"+str(time))
	room._state.last_result = result
	room._on_combat_view_finished()
	room._log_overlay.show()
	await capture("practice_arctic_combat_log")
	room._log_overlay.hide()
	room.queue_free()
	await process_frame
	var contact := Panel.new()
	contact.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(contact)
	# Native Godot texture preview; every source PNG remains byte exact.
	for i in 16:
		var row := VBoxContainer.new()
		row.position = Vector2(20+(i%8)*196,40+(i/8)*385)
		row.size = Vector2(188,350)
		contact.add_child(row)
		var fixed: GearItem
		if i < 12:
			fixed = GearItem.new()
			fixed.slot = GearItem.SlotType.LEGS if i < 6 else GearItem.SlotType.HANDS
			fixed.tier = [GearItem.Tier.BASIC,GearItem.Tier.MASTER,GearItem.Tier.EPIC,GearItem.Tier.CURSED,GearItem.Tier.CHAOS,GearItem.Tier.UNIQUE][i%6]
		else: fixed = LegendaryCatalog.all_items()[i+4]
		var icon := TextureRect.new()
		icon.texture = GearIcons.icon_for(fixed)
		icon.custom_minimum_size = Vector2(160,160)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		row.add_child(icon)
		var label := Label.new()
		label.custom_minimum_size = Vector2(188,0)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = fixed.display_name if i >= 12 else GearGenerator.tier_name(fixed.tier)+" "+GearGenerator.item_family_for(fixed)
		row.add_child(label)
	await capture("art_contact_sheet")
	contact.queue_free()
	SaveSystem.write_json(OUTPUT+"geometry.json",geometry)
	SaveSystem.write_json(OUTPUT+"countdown_evidence.json",evidence)
	state.reset()
	print("M9 T8 VISUAL PASS")
	quit()
