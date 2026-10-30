extends SceneTree
## Real resolver timeline through the shared Adventure and Practice presenters.
const OUT := "res://reports/pick_pocket_motion"
var rows: Array = []
var failed := false
var probe := OS.get_environment("FV_PICKPOCKET_PROBE") == "1"
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		printerr("FAILED: " + message)
func settle() -> void:
	for i in 5: await process_frame
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_contract_test_pressed(1234,45,"tree.thief","tree.bladedancer")
	var state = root.get_node("BuildState")
	var stats := PlayerStats.new()
	stats.weapon_damage_min = 100
	stats.weapon_damage_max = 100
	stats.gold_reward_multiplier = 2.0
	var enemy := Monster.new()
	enemy.display_name = "Mouthy Drunk"
	enemy.hp = 100000
	var thief = preload("res://scripts/systems/p6_thief_contracts.gd")
	var rotation: Array[Skill] = [thief.skill("mug"), thief.skill("pick_pocket"), thief.skill("steal")]
	var result := CombatResolver.resolve(rotation,stats,enemy,4400,7,true)
	check(result.is_valid and result.cast_events[1].skill.id == "skill.pick_pocket", "Actual resolver Pick Pocket after Mug")
	check(result.cast_events[1].gold_stolen == 20, "Actual theft retained")
	var original := JSON.stringify(result.trace.presentation_records)
	for mode in ["adventure", "practice"]:
		if mode == "practice": game._show_training_room()
		else:
			state.is_test_mode = false
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
			var stage = view._combat_stage
			var clock = view._playback
			var onset := [0]
			var original_callback: Callable = clock.cast_start_callback
			clock.cast_start_callback = func(cast):
				var before: Vector2 = stage.player_actor_anchor.position
				original_callback.call(cast)
				var after: Vector2 = stage.player_actor_anchor.position
				if cast.skill.id == "skill.pick_pocket":
					onset[0] = Time.get_ticks_usec()
					rows.append({"mode":mode,"speed":speed,"event":"pick_pocket_start","before":str(before),"after":str(after),"jump_px":before.distance_to(after)})
					if not probe: check(before.distance_to(after) < 1.0, mode + ": Pick Pocket does not snap prior attack back home")
			var previous := Time.get_ticks_usec()
			var frame := 0
			while view._playback != null:
				await create_timer(1.0/60.0).timeout
				var now := Time.get_ticks_usec()
				var delta := (now-previous)/1000000.0
				previous = now
				if mode == "practice": view._process(delta)
				else: view.advance(delta)
				var active: CombatResolver.CastEvent = clock.active_cast()
				if not probe and active != null and active.skill.id == "skill.pick_pocket":
					var offset: Vector2 = stage.player_actor_anchor.position - stage._player_base_position
					check(offset.x >= -0.1 and offset.x <= 34.1, "Recovery stays between prior contact and home")
					check(absf(offset.y) < 0.1, "Arm raise keeps the actor vertically stationary")
					if Time.get_ticks_usec() - onset[0] > 170000:
						check(absf(offset.x) < 0.1, "Recovery finishes promptly while the arm pose stays anchored")
				rows.append({"mode":mode,"speed":speed,"frame":frame,"time_ms":clock.elapsed_ms(),"x":stage.player_actor_anchor.position.x,"y":stage.player_actor_anchor.position.y,"base_x":stage._player_base_position.x,"base_y":stage._player_base_position.y})
				if DisplayServer.get_name() != "headless" and frame % 3 == 0 and clock.elapsed_ms() >= 1350 and clock.elapsed_ms() <= 1950:
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png(OUT + "/%s_%dx_%03d.png" % [mode,speed,frame])
				frame += 1
			check(stage.player_actor_anchor.position.distance_to(stage._player_base_position) < 0.1,"Normal finish restores home")
		# A completed Self Buff color pulse must not later rewind an attack.
		var stage = view._combat_stage
		var category = view._category_preview if mode == "practice" else screen._category_preview
		var buff_result := CombatResolver.resolve([thief.skill("dance_of_death")],stats,enemy,600,7,true)
		category.show_cast(buff_result.cast_events[0])
		stage.player_actor_anchor.position = stage._player_base_position + Vector2(34,0)
		var before: Vector2 = stage.player_actor_anchor.position
		category.clear_pulse()
		check(stage.player_actor_anchor.position == before,"Clearing color-only Self Buff pulse preserves current attack position")
		category.windup(result.cast_events[1],1.0)
		check(stage.player_actor_anchor.position == before,"Pick Pocket after Self Buff and attack also starts without snapping")
		category.clear()
		check(stage.player_actor_anchor.position == stage._player_base_position,"Cancelling positional windup restores home")
	check(JSON.stringify(result.trace.presentation_records) == original,"Presentation leaves actual resolver records unchanged")
	SaveSystem.write_json(OUT + "/motion.json",{"rows":rows})
	game.queue_free()
	await settle()
	print("Pick Pocket motion PASS" if not failed else "Pick Pocket motion FAILED")
	quit(1 if failed else 0)
