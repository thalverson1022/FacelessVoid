extends "res://tests/p6_m7_retrigger_flurry_visual.gd"
# Effects-bus PCM evidence. Uses the selected real audio driver; no human listening claim.
var evidence: Array = []
func event() -> CombatPlayback.PlaybackEvent:
	var e := CombatPlayback.PlaybackEvent.new()
	e.cast = CombatResolver.CastEvent.new()
	e.cast.skill = load("res://data/skills/stab.tres")
	e.cast.time_ms = 1000
	e.cast.cast_start_ms = 0
	e.cast.physical_damage = 37.4
	e.cast.triggered_skill_names = ["Diagnostic proc 1","Diagnostic proc 2","Diagnostic proc 3","Diagnostic proc 4"]
	for i in 4: e.cast.damage_contributions.append({"kind":"proc","damage":1.0})
	e.damage = 37.4
	return e
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/audio_lifecycle")
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_contract_test_pressed(1234,45,"tree.assassin","tree.shadow")
	var state = root.get_node("BuildState")
	var enemy := Monster.new()
	enemy.display_name = "Mouthy Drunk"
	enemy.hp = 100000
	var stats := PlayerStats.new()
	var rotation: Array[Skill] = [load("res://data/skills/stab.tres")]
	var result := CombatResolver.resolve(rotation,stats,enemy,4000,7,true)
	var sound = root.get_node("AudioManager")
	var bus := AudioServer.get_bus_index("Effects")
	AudioServer.set_bus_mute(bus,false)
	AudioServer.set_bus_volume_db(bus,-8)
	var recorder := AudioEffectRecord.new()
	recorder.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(bus,recorder)
	for mode in ["test","adventure","practice"]:
		for action in ["reference","skip","retry","speed2","speed4","exit"]:
			if mode == "practice": game._show_training_room()
			else:
				state.is_test_mode = mode == "test"
				game._show_combat_screen()
			await settle()
			var screen = game._current_screen
			var view = screen._combat_view if mode == "practice" else screen._playback_presenter
			if mode != "practice":
				view.finished.disconnect(screen._on_playback_finished)
				if screen._story_overlay.visible: screen._story_overlay._on_proceed_pressed()
				screen._contract_overlay.hide()
				screen._map_overlay.hide()
				state.run_phase = state.RunPhase.FIGHTING
			begin(screen,view,mode,result,enemy,1.0)
			sound.cancel_combat_sfx()
			await create_timer(0.25).timeout
			recorder.set_recording_active(true)
			var start := Time.get_ticks_usec()
			await create_timer(0.12).timeout
			var before: int = sound.attack_sfx_play_count
			if mode == "practice": view._on_playback_event(event())
			else: view._on_event(event())
			await create_timer(0.03).timeout
			var action_at := (Time.get_ticks_usec()-start)/1000000.0
			match action:
				"skip":
					if mode == "practice": view._skip()
					else: view.skip()
				"retry": begin(screen,view,mode,result,enemy,1.0)
				"speed2","speed4":
					var speed := 2.0 if action == "speed2" else 4.0
					if mode == "practice": view._set_speed(speed)
					else: screen._set_playback_speed(speed)
				"exit": game._on_main_menu_pressed()
			var count_at_action: int = sound.attack_sfx_play_count
			await create_timer(0.65).timeout
			var after: int = sound.attack_sfx_play_count
			if action == "exit":
				check(game._current_screen.process_mode != Node.PROCESS_MODE_DISABLED and is_equal_approx(game._current_screen.modulate.a,1.0),mode + ": incoming screen processes and crossfade completes")
				check(not is_instance_valid(screen),mode + ": old screen freed after fade")
			if action != "reference": check(after == count_at_action,mode + " " + action + ": no delayed proc crosses lifecycle boundary")
			else: check(after >= before+5,mode + ": uncancelled multi-hit reference has five sounds")
			recorder.set_recording_active(false)
			var recording: AudioStreamWAV = recorder.get_recording()
			var file := "%s_%s.wav" % [mode,action]
			var err := recording.save_to_wav("res://reports/audio_lifecycle/"+file)
			check(err == OK and recording.data.size() > 1000,mode+": WAV recorded")
			evidence.append({"mode":mode,"action":action,"file":file,"action_at_sec":action_at,"count_before":before,"count_at_action":count_at_action,"count_after":after,"sample_rate":recording.mix_rate,"bytes":recording.data.size(),"driver":AudioServer.get_driver_name()})
			sound.cancel_combat_sfx()
			check(sound.play_random_attack_sfx(1.0,1000),mode + ": fresh audio remains enabled after lifecycle action")
			sound.cancel_combat_sfx()
			if action != "exit":
				if mode == "practice": view._skip()
				else: view.skip()
			game._on_main_menu_pressed()
			await settle()
	# Two real resolver ghost-chain clips for listening to contact rhythm.
	for speed in [1.0,4.0]:
		game._show_training_room()
		await settle()
		var screen = game._current_screen
		var view = screen._combat_view
		var ghost_stats := PlayerStats.new()
		ghost_stats.weapon_damage_min = 100
		ghost_stats.weapon_damage_max = 100
		ghost_stats.retrigger_chance = 1.0
		var ghost_result := CombatResolver.resolve(rotation,ghost_stats,enemy,2000,7,true)
		begin(screen,view,"practice",ghost_result,enemy,speed)
		await create_timer(0.25).timeout
		recorder.set_recording_active(true)
		var start := Time.get_ticks_usec()
		var previous := start
		while (Time.get_ticks_usec()-start)/1000000.0 < (5.0 if speed == 1.0 else 3.8):
			await process_frame
			var now := Time.get_ticks_usec()
			drive(screen,view,"practice",(now-previous)/1000000.0)
			previous = now
		recorder.set_recording_active(false)
		var recording := recorder.get_recording()
		recording.save_to_wav("res://reports/audio_lifecycle/ghost_%dx.wav" % speed)
		evidence.append({"action":"real_resolver_ghost","speed":speed,"file":"ghost_%dx.wav" % speed,"casts":ghost_result.cast_events.size(),"driver":AudioServer.get_driver_name()})
		view._skip()
		game._on_main_menu_pressed()
		await create_timer(0.25).timeout
	AudioServer.remove_bus_effect(bus,AudioServer.get_bus_effect_count(bus)-1)
	SaveSystem.write_json("res://reports/audio_lifecycle/measurements.json",{"rows":evidence,"driver":AudioServer.get_driver_name(),"disclosure":"Recorded actual Godot Effects bus PCM through real driver, synthetic multi-proc cast dispatched through each actual playback surface. No human listening performed. Retry/speed recordings intentionally do not advance new timeline until stale-callback observation finishes."})
	game.queue_free()
	await settle()
	print("Audio lifecycle recording PASS" if not failed else "Audio lifecycle recording FAILED")
	quit(1 if failed else 0)
