extends "res://tests/p6_m7_retrigger_flurry_visual.gd"
## Category selection, gain/pitch bounds, actual playback surfaces and lifecycle.

func category_cast(category: int) -> CombatResolver.CastEvent:
	var cast := CombatResolver.CastEvent.new()
	cast.skill = Skill.new()
	cast.skill.id = "skill.audio_fixture"
	cast.skill.display_name = "Audio fixture"
	cast.skill.category = category
	cast.time_ms = 1000
	return cast

func dispatch(view, mode: String, cast: CombatResolver.CastEvent, chain: bool = false) -> void:
	var event := CombatPlayback.PlaybackEvent.new()
	event.cast = cast
	# Inject at the fresh playback frontier so the real timeline can then drain
	# forward on Skip without rewinding the presentation-state model.
	event.time_ms = 0
	if chain:
		event.chain_count = 2
		event.chain_index = 2
		event.visual_beat = false
	if mode == "practice": view._on_playback_event(event)
	else: view._on_event(event)

func run() -> void:
	var audio = root.get_node("AudioManager")
	await process_frame
	for category in [Skill.Category.SELF_BUFF, Skill.Category.DEBUFF]:
		check(audio._category_sfx_streams[category] != null,"Prepared category stream loads")
		check(not audio._category_sfx_streams[category].loop,"Category clip does not loop")
		var cast := category_cast(category)
		var pitches: Array = []
		var levels: Array = []
		for speed in [0.5,1.0,2.0,4.0]:
			for duration in [100,900,4000]:
				cast.cast_start_ms = cast.time_ms - duration
				check(audio.play_skill_sfx_for_cast(cast,speed) == 1,"Zero damage category activation plays once")
				check(audio.last_category_sfx_category == category,"Current category selects its stream")
				var pitch: float = audio.last_category_sfx_pitch_scale
				var gain: float = db_to_linear(audio.last_category_sfx_volume_db)
				check(pitch >= 0.96 and pitch <= 1.04,"Category pitch stays within four percent at every duration/speed")
				check(gain >= 0.5999 and gain <= 0.6801,"Small category gain variation")
				pitches.append(pitch)
				levels.append(gain)
				var player = audio._attack_sfx_players[posmod(audio._attack_sfx_player_index-1,audio.ATTACK_SFX_POOL_SIZE)]
				check(player.bus == "Effects" and player.stream == audio._category_sfx_streams[category],"Actual shared player uses category stream and Effects bus")
		check(pitches.min() != pitches.max() and levels.min() != levels.max(),"Pitch and level vary between casts")
		var before: int = audio.category_sfx_play_count
		for flag in ["was_interrupted","interrupt_skipped","cooldown_blocked","resource_unavailable","was_dodged"]:
			cast.set(flag,true)
			check(audio.play_skill_sfx_for_cast(cast,1.0) == 0,"Failed activation is silent: " + flag)
			cast.set(flag,false)
		check(audio.play_skill_sfx_for_cast(cast,1.0,true) == 0,"Suppressed category activation is silent")
		cast.skill.id = "skill.hold"
		check(audio.play_skill_sfx_for_cast(cast,1.0) == 0,"Hold is silent")
		cast.skill.id = "skill.audio_fixture"
		check(audio.category_sfx_play_count == before,"Invalid casts increment no category counter")
		var attacks: int = audio.attack_sfx_play_count
		cast.physical_damage = 50.0
		cast.damage_contributions = [{"kind":"cast","damage":20.0},{"kind":"proc","damage":30.0}]
		check(audio.play_skill_sfx_for_cast(cast,4.0) == 1,"Damaging category cast plays one cue despite passive procs")
		check(audio.play_skill_sfx_for_cast(cast,4.0,false,true,false) == 1,"Actual repeated category cast plays independently of attack visual beats")
		await create_timer(0.2).timeout
		check(audio.category_sfx_play_count == before+2 and audio.attack_sfx_play_count == attacks,"Category cast schedules no sword/proc echoes")
	var attack := category_cast(Skill.Category.ATTACK)
	attack.physical_damage = 30.0
	attack.damage_contributions = [{"kind":"proc","damage":10.0}]
	var before_attack: int = audio.attack_sfx_play_count
	check(audio.play_skill_sfx_for_cast(attack,1.0) == 2,"Normal attack preserves cast plus proc audio")
	await create_timer(0.2).timeout
	check(audio.attack_sfx_play_count == before_attack+2,"Normal attack delayed proc plays")
	before_attack = audio.attack_sfx_play_count
	audio.play_skill_sfx_for_cast(attack,1.0)
	audio.cancel_combat_sfx()
	await create_timer(0.2).timeout
	check(audio.attack_sfx_play_count == before_attack+1,"Generation cancellation suppresses delayed attack echoes")
	audio.set_effects_volume(0.0,false)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")),"Effects zero mutes shared category bus")
	audio.set_effects_volume(0.8,false)
	await scene_checks(audio)
	print("Buff/debuff category audio PASS" if not failed else "Buff/debuff category audio FAILED")
	quit(1 if failed else 0)

func scene_checks(audio) -> void:
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_contract_test_pressed(1234,45,"tree.assassin","tree.shadow")
	var state = root.get_node("BuildState")
	var enemy := Monster.new()
	enemy.hp = 100000
	enemy.display_name = "Mouthy Drunk"
	var contracts = preload("res://scripts/systems/p6_status_skill_contracts.gd")
	var rotation: Array[Skill] = [contracts.skill("master_of_poisons"),contracts.skill("poison_vile"),load("res://data/skills/exsanguinate.tres"),load("res://data/skills/stab.tres")]
	var result := CombatResolver.resolve(rotation,PlayerStats.new(),enemy,10000,7,true)
	check(result.is_valid,"Actual resolver category rotation is valid")
	var expected := 0
	var expected_exsanguinate := 0
	for cast in result.cast_events:
		if cast.skill.id == "skill.exsanguinate" and not cast.was_interrupted and not cast.interrupt_skipped and not cast.cooldown_blocked and not cast.resource_unavailable and not cast.was_dodged:
			expected_exsanguinate += 1
		if cast.skill.category != Skill.Category.ATTACK and cast.skill.id != "skill.exsanguinate" and not audio.SKILL_SFX_PATHS.has(cast.skill.id) and not cast.was_interrupted and not cast.interrupt_skipped and not cast.cooldown_blocked and not cast.resource_unavailable and not cast.was_dodged:
			expected += 1
	check(expected >= 1,"Actual rotation contains successful generic category activations")
	check(expected_exsanguinate > 0,"Actual rotation contains successful dedicated Exsanguinate casts")
	for mode in ["adventure","practice"]:
		if mode == "practice": game._show_training_room()
		else:
			state.is_test_mode = false
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
		for speed in [1.0,2.0,4.0]:
			begin(screen,view,mode,result,enemy,speed)
			var timeline_before: int = audio.category_sfx_play_count
			var exsanguinate_before: int = audio.exsanguinate_sfx_play_count
			for step in 200:
				if view._playback == null: break
				drive(screen,view,mode,0.1)
			check(audio.category_sfx_play_count == timeline_before+expected,mode+": actual resolver category count follows playback at %dx" % speed)
			check(audio.exsanguinate_sfx_play_count == exsanguinate_before+expected_exsanguinate,mode+": dedicated Exsanguinate cue follows actual casts at %dx" % speed)
			begin(screen,view,mode,result,enemy,speed)
			var before: int = audio.category_sfx_play_count
			for category in [Skill.Category.SELF_BUFF,Skill.Category.DEBUFF]:
				dispatch(view,mode,category_cast(category))
			check(audio.category_sfx_play_count == before+2,mode+": both zero damage categories play at %dx" % speed)
			var tick := CombatPlayback.PlaybackEvent.new()
			tick.is_tick = true
			tick.tick = CombatResolver.TickEvent.new()
			if mode == "practice": view._on_playback_event(tick)
			else: view._on_event(tick)
			check(audio.category_sfx_play_count == before+2,mode+": passive poison tick produces no category cue")
			if mode == "practice": view._skip()
			else: view.skip()
			var at_skip: int = audio.category_sfx_play_count
			await create_timer(0.2).timeout
			check(audio.category_sfx_play_count == at_skip,mode+": skip fastflush emits no additional category cues")
			for player in audio._attack_sfx_players: check(not player.playing,mode+": skip stops category pool")
		begin(screen,view,mode,result,enemy,1.0)
		var before: int = audio.category_sfx_play_count
		if mode == "practice": view._instant_playback = true
		else: view.skipping = true
		dispatch(view,mode,category_cast(Skill.Category.SELF_BUFF))
		check(audio.category_sfx_play_count == before,mode+": instant/skipping callback is silent")
		audio.cancel_combat_sfx()
		game._on_main_menu_pressed()
		await settle()
	game.queue_free()
	await settle()
