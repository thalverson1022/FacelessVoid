extends "res://tests/m9_t7_visual.gd"
## Isolated full-dashboard render checks through both live tick event handlers.
const OUTPUT := "res://reports/m9_poison_crits/"
var evidence := {}

func _initialize() -> void:
	SaveSystem.save_path = OUTPUT + "adventure.json"
	PracticeSaveSystem.save_path = OUTPUT + "practice.json"
	PracticeSaveSystem.core_save_path = OUTPUT + "core.json"
	SevenSlotSaveBoundary.legacy_path = OUTPUT + "legacy.json"
	SevenSlotSaveBoundary.marker_path = OUTPUT + "marker.json"
	for path in SevenSlotSaveBoundary.paths().values():
		assert(path.begins_with(OUTPUT), "All save paths isolated before game entry")
		for candidate in [path, path + ".tmp"]:
			if FileAccess.file_exists(candidate):
				assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate)) == OK)
	call_deferred("run")

func settle() -> void:
	for i in 6: await process_frame

func tick_event(critical: bool, active: bool = true) -> CombatPlayback.PlaybackEvent:
	var event := CombatPlayback.PlaybackEvent.new()
	event.is_tick = true
	event.chain_count = 1
	event.damage = 128.0 if active else 0.0
	event.tick = CombatResolver.TickEvent.new()
	event.tick.damage = event.damage
	event.tick.had_active_stack = active
	event.tick.stacks_remaining = 4 if active else 0
	event.tick.is_crit = critical
	return event

func visible_popups(layer: Control) -> Array[Label]:
	var result: Array[Label] = []
	for child in layer.get_children():
		if child is Label and child.visible and not child.is_queued_for_deletion(): result.append(child)
	return result

func deliver(screen: Node, mode: String, event: CombatPlayback.PlaybackEvent) -> void:
	if mode == "adventure": screen._playback_presenter._on_event(event)
	else: screen._on_playback_event(event)

func sample(screen: Node, mode: String, critical: bool, wyvern: bool) -> Dictionary:
	var layer: Control = screen._popup_layer
	for old in layer.get_children(): old.hide()
	if mode == "adventure": layer.wyvern_tick_font_active = wyvern
	else: screen._wyvern_kriss_effect_active = wyvern
	deliver(screen, mode, tick_event(critical))
	var labels := visible_popups(layer)
	assert(labels.size() == 1, "One active-stack tick creates exactly one visible popup")
	var label := labels[0]
	assert(label.get_theme_color("font_color") == UIColors.TEXT_POISON, "Critical Poison stays green")
	assert(label.text.ends_with("!") == critical, "Only critical Poison has exclamation")
	assert(bool(label.get_meta("critical_poison", false)) == critical, "Critical tick layout metadata")
	var expected := 20 if wyvern else 26
	if mode == "practice": expected = 14 if wyvern else 18
	if critical: expected = roundi(expected * 1.5)
	assert(label.get_theme_font_size("font_size") == expected, "Normal tick unchanged, critical tick 1.5x")
	var initial_scale := label.scale.x
	# Advance the actual animation beyond its punch and compare the stable fit.
	for tween in get_processed_tweens():
		if tween.is_valid():
			tween.play()
			tween.custom_step(0.18)
			tween.pause()
	assert(initial_scale > label.scale.x if critical else initial_scale < label.scale.x, "Critical punch versus ordinary grow-in")
	var rect := label.get_global_rect()
	assert(Rect2(0,0,1600,900).encloses(rect), "Poison popup stays in viewport")
	assert(screen._combat_stage.play_area_global_rect().grow(1).encloses(rect), "Poison popup stays in combat stage")
	if mode == "practice":
		assert(rect.get_center().distance_to(screen._combat_stage.enemy_popup_global_position()) < 180, "Poison remains close to target")
	var key := mode + ("_wyvern" if wyvern else "") + ("_critical" if critical else "_normal")
	await settle()
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(OUTPUT + key + ".png") == OK)
	var result := {"text":label.text,"font_size":expected,"initial_scale":initial_scale,"settled_scale":label.scale.x,"rendered_width":rect.size.x,"rendered_height":rect.size.y,"rect":str(rect),"green":true}
	evidence[key] = result
	return result

func check_mode(screen: Node, mode: String) -> void:
	for wyvern in [false, true]:
		var normal := await sample(screen,mode,false,wyvern)
		var critical := await sample(screen,mode,true,wyvern)
		assert(critical.rendered_height > normal.rendered_height * 1.25, "Critical tick remains visibly taller after lane fitting")
		assert(critical.rendered_width > normal.rendered_width * 1.25, "Critical tick remains visibly wider after lane fitting")
	assert(evidence[mode+"_wyvern_normal"].rendered_height < evidence[mode+"_normal"].rendered_height, "Wyvern ordinary tick stays smaller")
	assert(evidence[mode+"_wyvern_critical"].rendered_height < evidence[mode+"_critical"].rendered_height, "Wyvern critical tick stays relatively smaller")
	var layer: Control = screen._popup_layer
	for old in layer.get_children(): old.hide()
	deliver(screen,mode,tick_event(true,false))
	assert(visible_popups(layer).is_empty(), "Empty cadence produces no popup")
	CombatEffectIcons.reduced_motion = true
	deliver(screen,mode,tick_event(true))
	assert(visible_popups(layer).is_empty(), "Reduced motion suppresses critical Poison")
	CombatEffectIcons.reduced_motion = false
	if mode == "adventure": layer.skip_active = true
	else: screen._playback_skipping = true
	deliver(screen,mode,tick_event(true))
	assert(visible_popups(layer).is_empty(), "Skip suppresses critical Poison")
	if mode == "adventure": layer.skip_active = false
	else: screen._playback_skipping = false
	evidence[mode+"_suppression"] = {"empty_stack":true,"reduced_motion":true,"skip":true}

func run() -> void:
	root.size = Vector2i(1600,900)
	root.gui_embed_subwindows = true
	CombatEffectIcons.reduced_motion = false
	state = root.get_node("BuildState")
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_new_game_pressed(1928)
	state.set_class(BuildContentRegistry.adventure().classes["class.rogue"])
	assert(state.configure_ranked_build(BuildContentRegistry.adventure().trees["tree.bladedancer"]))
	game._show_combat_screen()
	await settle()
	var screen: Node = game._current_screen
	screen._playback_presenter._monster = Monster.new()
	screen._playback_presenter._monster.hp = 10000
	screen._playback_presenter._hp = 10000.0
	dismiss(screen)
	await settle()
	await check_mode(screen,"adventure")
	game.queue_free()
	await settle()
	state.reset()
	var room = load("res://scenes/training_room/training_room.tscn").instantiate()
	root.add_child(room)
	await settle()
	room._setup_autosave = false
	await check_mode(room._combat_view,"practice")
	SaveSystem.write_json(OUTPUT+"geometry.json",evidence)
	room.queue_free()
	await settle()
	state.reset()
	print("M9 POISON CRIT PRESENTATION PASS")
	quit()
