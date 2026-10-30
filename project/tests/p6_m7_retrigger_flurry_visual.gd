extends SceneTree
const OUT := "res://reports/ghost_motion"
var rows: Array = []
var failed := false
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in 5: await process_frame
	if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		printerr("FAILED: " + message)
func ghost_clear(stage) -> bool:
	return not is_instance_valid(stage._retrigger_ghost) or not stage._retrigger_ghost.visible
func begin(screen, view, mode, result, enemy, speed) -> void:
	if mode == "practice":
		screen._state.last_result = result
		screen._state.selected_target = enemy
		view._instant_playback = false
		view.play(result,enemy)
		view.set_process(false)
		view._playback_intro_remaining_sec = 0
		view._set_speed(speed)
	else:
		screen._skip_playback_on_fight = false
		screen._begin_playback(result,enemy)
		screen.set_process(false)
		view._intro_remaining_sec = 0
		screen._set_playback_speed(speed)
func drive(screen, view, mode, delta) -> void:
	if mode == "practice": view._process(delta)
	else:
		view.advance(delta)
		screen._update_playback_time_label()
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_contract_test_pressed(1234,45,"tree.assassin","tree.shadow")
	var state = root.get_node("BuildState")
	var stats := PlayerStats.new()
	stats.weapon_damage_min = 100
	stats.weapon_damage_max = 100
	stats.retrigger_chance = 1.0
	stats.poison_damage_per_tick = 10
	stats.readiness_enabled = true
	var enemy := Monster.new()
	enemy.display_name = "Mouthy Drunk"
	enemy.hp = 100000
	var rotation: Array[Skill] = [load("res://data/skills/venom_jab.tres"),preload("res://scripts/systems/p6_poison_contracts.gd").poison_strike()]
	var result := CombatResolver.resolve(rotation,stats,enemy,4000,7,true)
	var original := JSON.stringify(result.trace.presentation_records)
	for mode in (["practice"] if OS.get_environment("FACELESSVOID_CAPTURE_MODES") == "practice" else ["test","adventure","practice"]):
		if mode == "practice": game._show_training_room()
		else:
			state.is_test_mode = mode == "test"
			game._show_combat_screen()
		await settle()
		var screen = game._current_screen
		var view = screen._combat_view if mode == "practice" else screen._playback_presenter
		if mode != "practice":
			if screen._story_overlay.visible: screen._story_overlay._on_proceed_pressed()
			screen._contract_overlay.hide()
			screen._map_overlay.hide()
			state.run_phase = state.RunPhase.FIGHTING
		for speed in [1.0,4.0]:
			begin(screen,view,mode,result,enemy,speed)
			var stage = view._combat_stage
			check(stage._enemy_sprite.texture != null and stage._player_sprite.texture != null,mode + ": actual actors visible")
			drive(screen,view,mode,0.94/speed)
			var captures: Array[Image] = []
			var previous := Time.get_ticks_usec()
			var visible_samples := 0
			for frame in 100:
				await create_timer(1.0/40.0).timeout
				var now := Time.get_ticks_usec()
				var delta := (now-previous)/1000000.0
				previous = now
				drive(screen,view,mode,delta)
				await RenderingServer.frame_post_draw
				captures.append(root.get_texture().get_image())
				var clock = view._playback
				var ghost = stage._retrigger_ghost
				var visible: bool = is_instance_valid(ghost) and ghost.visible
				if visible: visible_samples += 1
				var anchored: bool = stage.player_actor_anchor.position.distance_to(stage._player_base_position) < 0.01
				if visible: check(anchored,mode + ": main stays home through all visible echoes")
				var labels: Array = view._popup_layer.get_children().filter(func(n): return n.has_meta("retrigger_hit") and not n.is_queued_for_deletion())
				check(labels.size() <= 2, mode + ": compact label cap")
				var label_data: Array = []
				for label in labels:
					label_data.append({"text":label.text,"font_size":label.get_theme_font_size("font_size"),"alpha":label.modulate.a,"global_x":label.global_position.x,"global_y":label.global_position.y})
				rows.append({"labels":label_data,"mode":mode,"speed":speed,"frame":frame,"delta_ms":delta*1000,"resolver_ms":clock.elapsed_ms() if clock != null else 4000,"damage":clock.damage_dealt() if clock != null else result.total_damage,"ghost_visible":visible,"ghost_alpha":ghost.modulate.a if is_instance_valid(ghost) else 0,"main_anchored":anchored,"main_x":stage.player_actor_anchor.position.x,"home_x":stage._player_base_position.x,"events":clock.events_fired() if clock != null else 72})
				if clock != null and clock.elapsed_ms() > 1300: break
			check(visible_samples >= 7,mode + ": real-time ghost samples at %dx" % speed)
			for frame in captures.size(): captures[frame].save_png(OUT + "/%s_%dx_%03d.png" % [mode,speed,frame])
			captures.clear()
			check(stage.find_child("RetriggerChainTotal",true,false) == null and stage.find_child("RetriggerSlash",true,false) == null,mode + ": no combo badge or X effect")
			# Skip is a state drain with no leftover ghost or callbacks.
			if mode == "practice": view._skip()
			else: view.skip()
			check(ghost_clear(stage),mode + ": Skip clears ghost")
			for label in view._popup_layer.get_children():
				if label.has_meta("retrigger_hit"): check(not label.visible, mode + ": Skip hides echo text")
			await settle()
		# Mid-chain speed and motion changes must cancel the active copy.
		begin(screen,view,mode,result,enemy,1.0)
		drive(screen,view,mode,1.261)
		var stage = view._combat_stage
		check(not ghost_clear(stage),mode + ": retry reaches ghost contact")
		if mode == "practice": view._set_speed(4.0)
		else: screen._set_playback_speed(4.0)
		check(ghost_clear(stage),mode + ": speed change clears old ghost")
		drive(screen,view,mode,0.141)
		check(not ghost_clear(stage),mode + ": changed speed resumes ordered ghost contacts")
		CombatEffectIcons.reduced_motion = true
		await settle()
		check(ghost_clear(stage),mode + ": reduced motion clears pending ghost")
		drive(screen,view,mode,0.3)
		check(ghost_clear(stage),mode + ": reduced motion creates no copies")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT + "/" + mode + "_reduced.png")
		if mode == "practice": view._skip()
		else: view.skip()
		CombatEffectIcons.reduced_motion = false
		# Normal finish without Skip also clears the final ghost.
		begin(screen,view,mode,result,enemy,4.0)
		drive(screen,view,mode,20.0)
		check(view._playback == null and ghost_clear(stage),mode + ": normal finish has no orphan")
		# Exit while a copy is active; no delayed sounds survive disposal.
		begin(screen,view,mode,result,enemy,1.0)
		drive(screen,view,mode,1.261)
		game._on_main_menu_pressed()
		await settle()
		var sound = root.get_node("AudioManager")
		var count: int = sound.attack_sfx_play_count + sound.dodge_sfx_play_count
		await create_timer(0.25).timeout
		check(sound.attack_sfx_play_count + sound.dodge_sfx_play_count == count,mode + ": exit cancels delayed audio")
	check(JSON.stringify(result.trace.presentation_records) == original,"All modes leave resolver records unchanged")
	var f := FileAccess.open(OUT + "/measurements.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"rows":rows,"cast_count":result.cast_events.size(),"tick_count":result.tick_events.size(),"total_damage":result.total_damage,"rng_final_state":result.rng_final_state},"\t"))
	print("Cross-mode ghost retrigger motion PASS" if not failed else "Cross-mode ghost retrigger motion FAILED")
	game.queue_free()
	await settle()
	quit(1 if failed else 0)
