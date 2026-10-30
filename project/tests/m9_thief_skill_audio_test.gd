extends "res://tests/m9_exsanguinate_audio_test.gd"
const Assassin = preload("res://scripts/systems/playable_assassin_content.gd")
const Thief = preload("res://scripts/systems/p6_thief_contracts.gd")

func run() -> void:
	var audio = root.get_node("AudioManager")
	await process_frame
	var pitches := []
	for skill: Skill in [Assassin.skill("poison_vile"), Assassin.skill("blinding_powder"), Thief.skill("pick_pocket")]:
		var cast := CombatResolver.CastEvent.new()
		cast.skill = skill
		var before: int = audio.category_sfx_play_count
		for speed in [1.0, 2.0, 4.0]:
			for i in 8:
				check(audio.play_skill_sfx_for_cast(cast, speed) == 1, "Dedicated cue: " + skill.id)
				var player = audio._attack_sfx_players[posmod(audio._attack_sfx_player_index-1, audio.ATTACK_SFX_POOL_SIZE)]
				check(player.stream == audio._skill_sfx_streams[skill.id] and player.bus == "Effects", "Correct named stream")
				check(player.pitch_scale >= 0.96 and player.pitch_scale <= 1.04, "Named pitch variation independent of speed")
				pitches.append(player.pitch_scale)
		check(audio.category_sfx_play_count == before, "Named cue replaces generic category cue")
		cast.cooldown_blocked = true
		check(audio.play_skill_sfx_for_cast(cast, 1.0) == 0, "Blocked named skill silent")
	check(pitches.min() != pitches.max(), "Named cues vary")
	var theft := CombatResolver.CastEvent.new()
	theft.skill = load("res://data/skills/stab.tres")
	theft.gold_stolen = 5
	var before: int = audio.gold_steal_sfx_play_count
	check(audio.play_skill_sfx_for_cast(theft, 4.0, false, true, false) == 1, "Passive theft plays even without an attack visual beat")
	check(audio.gold_steal_sfx_play_count == before + 1, "One receipt cue per credited cast")
	var player = audio._attack_sfx_players[posmod(audio._attack_sfx_player_index-1, audio.ATTACK_SFX_POOL_SIZE)]
	check(player.stream == audio._gold_steal_sfx_stream, "Gold receipt uses gold clip")
	check(db_to_linear(float(player.volume_db)) >= 0.3699 and db_to_linear(float(player.volume_db)) <= 0.4301, "Gold cue stays quiet")
	theft.gold_stolen = 0
	check(audio.play_skill_sfx_for_cast(theft, 1.0) == 0, "Zero stolen gold emits no coin cue")
	theft.gold_stolen = 5
	check(audio.play_skill_sfx_for_cast(theft, 1.0, true) == 0, "Suppressed theft silent")
	audio.cancel_combat_sfx()
	await thief_scene_checks(audio)
	await super.run()

func thief_scene_checks(audio) -> void:
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_contract_test_pressed(4422, 45, "tree.thief", "tree.assassin")
	var state = root.get_node("BuildState")
	var enemy := Monster.new()
	enemy.hp = 100000
	enemy.display_name = "Mouthy Drunk"
	var stats := PlayerStats.new()
	stats.assassin_tree_points = 10
	var rotation: Array[Skill] = [Assassin.skill("poison_vile"), Assassin.skill("blinding_powder"), Thief.skill("pick_pocket"), Thief.skill("steal")]
	var result := CombatResolver.resolve(rotation, stats, enemy, 10000, 31, true)
	check(result.is_valid, "Real mixed skill fixture valid")
	var expected_gold := 0
	var expected := {}
	for cast in result.cast_events:
		if cast.was_interrupted or cast.interrupt_skipped or cast.cooldown_blocked or cast.resource_unavailable or cast.was_dodged: continue
		if cast.gold_stolen > 0: expected_gold += 1
		if audio.SKILL_SFX_PATHS.has(cast.skill.id): expected[cast.skill.id] = int(expected.get(cast.skill.id, 0)) + 1
	check(expected.size() == 3 and expected_gold > 0, "Actual named activations and credited theft witnessed")
	for mode in ["adventure", "practice"]:
		if mode == "practice": game._show_training_room()
		else:
			state.is_test_mode = false
			game._show_combat_screen()
		await settle()
		var screen = game._current_screen
		var view = screen._combat_view if mode == "practice" else screen._playback_presenter
		if mode == "adventure":
			view.finished.disconnect(screen._on_playback_finished)
			screen._contract_overlay.hide()
			screen._map_overlay.hide()
			state.run_phase = state.RunPhase.FIGHTING
		for speed in [1.0, 2.0, 4.0]:
			begin(screen, view, mode, result, enemy, speed)
			var before_counts: Dictionary = audio.skill_sfx_play_counts.duplicate()
			var gold_before: int = audio.gold_steal_sfx_play_count
			for step in 200:
				if view._playback == null: break
				drive(screen, view, mode, 0.1)
			for id in expected:
				check(int(audio.skill_sfx_play_counts.get(id, 0)) == int(before_counts.get(id, 0)) + expected[id], mode + " actual named cue count: " + id)
			check(audio.gold_steal_sfx_play_count == gold_before + expected_gold, mode + " actual theft cue count")
			begin(screen, view, mode, result, enemy, speed)
			gold_before = audio.gold_steal_sfx_play_count
			before_counts = audio.skill_sfx_play_counts.duplicate()
			if mode == "practice": view._skip()
			else: view.skip()
			check(audio.gold_steal_sfx_play_count == gold_before and audio.skill_sfx_play_counts == before_counts, mode + " skip suppresses new cues")
		game._on_main_menu_pressed()
		await settle()
	game.queue_free()
	await settle()
