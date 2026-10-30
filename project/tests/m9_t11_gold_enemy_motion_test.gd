extends SceneTree
## Full live theft replay: enemy transform, layout, frame bounds, and gold HUD.
const OUT := "res://reports/gold_enemy_motion"
var rows: Array = []
var failed := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		printerr("FAILED: " + message)
func settle() -> void:
	for i in 5: await process_frame
func sample(stage, mode: String, speed: float, frame: int, clock) -> Dictionary:
	var sprite: TextureRect = stage._enemy_sprite
	var image: Image = sprite.texture.get_image()
	var bounds := image.get_used_rect()
	var transform := sprite.get_global_transform()
	var top: Vector2 = transform * Vector2(bounds.position)
	var foot: Vector2 = transform * Vector2(bounds.end)
	return {"mode":mode,"speed":speed,"frame":frame,"time_ms":clock.elapsed_ms(),"enemy_x":stage.enemy_actor_anchor.position.x,"enemy_y":stage.enemy_actor_anchor.position.y,"base_y":stage._enemy_base_position.y,"global_top_y":top.y,"global_foot_y":foot.y,"sprite_y":sprite.position.y,"sprite_size":str(sprite.size),"texture_size":str(sprite.texture.get_size()),"bounds":str(bounds),"animation":stage.last_enemy_animation_key,"stage_global_y":stage.global_position.y,"stage_size":str(stage.size),"gold":root.get_node("BuildState").gold}
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_contract_test_pressed(1234,45,"tree.thief","tree.bladedancer")
	var state = root.get_node("BuildState")
	var ranks := {"talent.keen_eye":5,"talent.sticky_fingers":5,"talent.thief.fast_hands":5,"talent.thief.bribery":3,"talent.thief.silvered_edge":3,"talent.thief.finders_keepers":2}
	check(state.ranked_build.configure(state.selected_trees[0],state.selected_trees[1],45,ranks),"Legal Thief ranks with gold-scaled live stats")
	state._finish_rank_edit(true)
	var thief = preload("res://scripts/systems/p6_thief_contracts.gd")
	var rotation: Array[Skill] = [thief.skill("pick_pocket"),thief.skill("mug"),thief.skill("steal")]
	for mode in ["adventure", "practice"]:
		if mode == "practice": game._show_training_room()
		else:
			state.is_test_mode = false
			game._show_combat_screen()
		await settle()
		var screen = game._current_screen
		var view = screen._combat_view if mode == "practice" else screen._playback_presenter
		if mode == "adventure":
			if screen._story_overlay.visible: screen._story_overlay._on_proceed_pressed()
			screen._contract_overlay.hide()
			screen._map_overlay.hide()
			state.run_phase = state.RunPhase.FIGHTING
		for speed in [1.0,4.0]:
			var resolved := BuildResolver.resolve_ranked_build(state.selected_class,state.ranked_build,[load("res://data/gear/crude_dagger.tres")],state.gold)
			var stats: PlayerStats = resolved.stats
			stats.crit_chance = 0.0 if OS.get_environment("FV_GOLD_ENEMY_NO_CRIT") == "1" else 1.0
			stats.weapon_damage_min = 100
			stats.weapon_damage_max = 100
			var enemy := Monster.new()
			enemy.display_name = OS.get_environment("FV_GOLD_ENEMY_TARGET") if OS.get_environment("FV_GOLD_ENEMY_TARGET") != "" else "Mouthy Drunk"
			enemy.hp = 100000
			var result := CombatResolver.resolve(rotation,stats,enemy,5000,7,true)
			check(result.gold_stolen > 0,"Actual thief obtains gold")
			var records := JSON.stringify(result.trace.presentation_records)
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
			stage.set_bandit_blade_effect_active(true)
			var clock = view._playback
			var original_callback: Callable = clock.event_callback
			clock.event_callback = func(event):
				var before := sample(stage,mode,speed,-1,clock)
				original_callback.call(event)
				var after := sample(stage,mode,speed,-1,clock)
				rows.append({"event":"tick" if event.is_tick else event.cast.skill.id,"gold_stolen":0 if event.is_tick else event.cast.gold_stolen,"before":before,"after":after})
			var previous := Time.get_ticks_usec()
			var frame := 0
			while view._playback != null:
				await create_timer(1.0/60.0).timeout
				var now := Time.get_ticks_usec()
				var delta := (now-previous)/1000000.0
				previous = now
				if mode == "practice": view._process(delta)
				else: view.advance(delta)
				rows.append(sample(stage,mode,speed,frame,clock))
				if DisplayServer.get_name() != "headless" and frame % 3 == 0:
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png(OUT + "/%s_%dx_%03d.png" % [mode,speed,frame])
				frame += 1
			check(JSON.stringify(result.trace.presentation_records) == records,"Playback leaves resolver records unchanged")
	SaveSystem.write_json(OUT + "/motion.json",{"rows":rows})
	game.queue_free()
	await settle()
	print("Gold enemy motion PASS" if not failed else "Gold enemy motion FAILED")
	quit(1 if failed else 0)
