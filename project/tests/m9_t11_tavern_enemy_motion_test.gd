extends "res://tests/m9_t11_gold_enemy_motion_test.gd"
## Actual Adventure Fight path and every rendered frame, all four Tavern art sets.
const TAVERN_OUT := "res://reports/tavern_enemy_motion"
func run() -> void:
	var capture_out := TAVERN_OUT
	if get_script().resource_path.begins_with("res://reports/"):
		capture_out = get_script().resource_path.get_base_dir() + "/tavern_enemy_motion"
	DirAccess.make_dir_recursive_absolute(capture_out)
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	var state = root.get_node("BuildState")
	var registry := BuildContentRegistry.test_mode()
	var ranks := {"talent.keen_eye":5,"talent.sticky_fingers":5,"talent.thief.fast_hands":5,"talent.thief.bribery":3,"talent.thief.silvered_edge":3,"talent.thief.finders_keepers":2}
	var thief = preload("res://scripts/systems/p6_thief_contracts.gd")
	for encounter_index in 4:
		if OS.get_environment("FV_TAVERN_SINGLE_ENEMY") != "" and encounter_index != int(OS.get_environment("FV_TAVERN_SINGLE_ENEMY")): continue
		for speed in [1.0,4.0]:
			if OS.get_environment("FV_TAVERN_SINGLE_SPEED") != "" and speed != float(OS.get_environment("FV_TAVERN_SINGLE_SPEED")): continue
			game._on_main_menu_pressed()
			await settle()
			state.reset()
			state.set_class(registry.classes["class.rogue"])
			state.earned_talent_points = 23
			state.select_tree(registry.trees["tree.thief"])
			check(state.ranked_build.configure(registry.trees["tree.thief"],null,23,ranks),"Explicit diagnostic Thief build")
			state.current_encounter_index = encounter_index
			state.tavern_map_choice_made = true
			state.gold = 100
			state.rotation.assign([thief.skill("pick_pocket"),thief.skill("mug"),thief.skill("steal"),load("res://data/skills/stab.tres")])
			if OS.get_environment("FV_TAVERN_STEAL_CRIT") == "1":
				state.rotation.assign([thief.skill("steal")])
				# Choose a normal combat seed that witnesses both a critical theft
				# and a noncritical Steal inside the sampled live Fight window.
				var found := false
				for seed in range(1,201):
					state.adventure_seed = seed
					var candidate := CombatResolver.resolve(state.rotation,state.current_player_stats(),state.current_target_monster(),state.current_target_duration_ms(),state.current_combat_rng_seed())
					var crit := candidate.cast_events.any(func(c): return c.time_ms <= 5500 and c.skill.id == "skill.steal" and c.is_crit and c.gold_stolen > 0)
					var ordinary := candidate.cast_events.any(func(c): return c.time_ms <= 5500 and c.skill.id == "skill.steal" and not c.is_crit)
					if crit and ordinary:
						found = true
						break
				check(found,"Actual ranked stats and combat seed witness critical theft and noncritical Steal")
			state._finish_rank_edit(true)
			game._show_combat_screen()
			await settle()
			var screen = game._current_screen
			if screen._story_overlay.visible: screen._story_overlay._on_proceed_pressed()
			screen._contract_overlay.hide()
			screen._map_overlay.hide()
			state.set_locked(true)
			check(not state.is_test_mode and state.current_route_node == null and state.active_contract == null,"Actual Adventure Tavern context")
			var name: String = state.current_target_monster().display_name
			screen.instant_playback = false
			screen._skip_playback_on_fight = false
			screen._on_fight_pressed()
			screen.set_process(false)
			var view = screen._playback_presenter
			check(view._playback != null,"Actual Fight creates playback")
			if view._playback == null: continue
			var stage = view._combat_stage
			var clock = view._playback
			var result: CombatResolver.CombatResult = state.last_combat_result
			var records := JSON.stringify(result.trace.presentation_records)
			if OS.get_environment("FV_TAVERN_STEAL_CRIT") == "1":
				check(result.cast_events.any(func(c): return c.time_ms <= 5500 and c.skill.id == "skill.steal" and c.is_crit and c.gold_stolen > 0),"Live normal Fight retains critical Steal witness")
			screen._set_playback_speed(speed)
			var original: Callable = clock.event_callback
			clock.event_callback = func(event):
				var before := sample(stage,name,speed,-1,clock)
				original.call(event)
				var after := sample(stage,name,speed,-1,clock)
				rows.append({"event":"tick" if event.is_tick else event.cast.skill.id,"crit":false if event.is_tick else event.cast.is_crit,"gold_stolen":0 if event.is_tick else event.cast.gold_stolen,"before":before,"after":after})
			var previous := Time.get_ticks_usec()
			var frame := 0
			var max_recoil_x := 0.0
			while view._playback != null and clock.elapsed_ms() < 5500:
				await process_frame
				var now := Time.get_ticks_usec()
				view.advance((now-previous)/1000000.0)
				previous = now
				rows.append(sample(stage,name,speed,frame,clock))
				if DisplayServer.get_name() != "headless":
					await RenderingServer.frame_post_draw
					var rendered := sample(stage,name,speed,frame,clock)
					rendered["after_render"] = true
					rows.append(rendered)
					max_recoil_x = maxf(max_recoil_x,absf(stage.enemy_actor_anchor.position.x-stage._enemy_base_position.x))
					if OS.get_environment("FV_TAVERN_REQUIRE_ANCHORED") == "1":
						check(absf(rendered.enemy_y-rendered.base_y)<0.1,"Tavern enemy stays on latest layout baseline through intro and theft")
					if frame % 3 == 0:
						root.get_texture().get_image().save_png(capture_out + "/%d_%dx_%03d.png" % [encounter_index,speed,frame])
				frame += 1
			check(JSON.stringify(result.trace.presentation_records) == records,"Tavern presentation leaves actual resolver records unchanged")
			if DisplayServer.get_name() != "headless":
				check(max_recoil_x > 1.0 and max_recoil_x <= maxf(stage.RECOIL_DISTANCE_PX,stage.CRIT_RECOIL_DISTANCE_PX)+0.1,"Intended horizontal recoil remains visible and bounded")
			rows.append({"max_recoil_x":max_recoil_x,"mode":name,"speed":speed,"seed":state.adventure_seed})
			view.skip()
	SaveSystem.write_json(capture_out + "/motion.json",{"rows":rows,"fixture":"Actual Adventure Fight path; diagnostic 23-point single-role Thief injected to exercise theft during each Tavern encounter; every process/render frame sampled."})
	game.queue_free()
	await settle()
	print("Tavern enemy motion capture PASS" if not failed else "Tavern enemy motion capture FAILED")
	quit(1 if failed else 0)
