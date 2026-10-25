extends SceneTree
## Focused smoke test for randomized sword attack SFX routing and timing.


func _initialize() -> void:
	var audio_manager = root.get_node("AudioManager")
	_require(audio_manager != null, "Expected AudioManager autoload.")
	await process_frame

	_require(AudioServer.get_bus_index("Effects") >= 0, "Expected Effects audio bus.")
	_require(audio_manager._attack_sfx_streams.size() == 5, "Expected five sword hit SFX streams.")
	_require(not audio_manager.ATTACK_SFX_PATHS.has(audio_manager.DODGE_SFX_PATH), "Sword Swing is reserved for dodges.")
	_require(audio_manager._dodge_sfx_stream != null, "Expected dedicated Sword Swing dodge stream.")
	_require(audio_manager._attack_sfx_players.size() == audio_manager.ATTACK_SFX_POOL_SIZE, "Expected attack SFX player pool.")
	for player in audio_manager._attack_sfx_players:
		_require(player.bus == "Effects", "Expected attack SFX players to route through Effects.")

	_require(audio_manager._button_press_stream != null, "Expected button press SFX stream to load.")
	_require(audio_manager._button_sfx_players.size() == audio_manager.BUTTON_PRESS_SFX_POOL_SIZE, "Expected button press SFX player pool.")
	for player in audio_manager._button_sfx_players:
		_require(player.bus == "Effects", "Expected button press SFX players to route through Effects.")
	_require(audio_manager._shop_change_stream != null, "Expected shop change SFX stream to load.")
	_require(audio_manager._shop_change_player != null, "Expected shop change SFX player.")
	_require(audio_manager._shop_change_player.bus == "Effects", "Expected shop change SFX player to route through Effects.")
	_require(audio_manager._footsteps_stream != null, "Expected footsteps SFX stream to load.")
	_require(audio_manager._footsteps_player != null, "Expected footsteps SFX player.")
	_require(audio_manager._footsteps_player.bus == "Effects", "Expected footsteps SFX player to route through Effects.")

	var before_button_count: int = audio_manager.button_press_sfx_play_count
	var direct_button_sfx: bool = audio_manager.play_button_press_sfx()
	_require(direct_button_sfx, "Expected direct button press SFX to play.")
	_require(audio_manager.button_press_sfx_play_count == before_button_count + 1, "Expected direct button press SFX count to increment.")

	var test_button := Button.new()
	test_button.text = "Audio Test"
	root.add_child(test_button)
	await process_frame
	before_button_count = audio_manager.button_press_sfx_play_count
	test_button.button_down.emit()
	await process_frame
	test_button.pressed.emit()
	_require(audio_manager.button_press_sfx_play_count == before_button_count + 1, "Expected mouse button press SFX to play once on press, not again on release.")
	test_button.button_up.emit()
	await process_frame
	before_button_count = audio_manager.button_press_sfx_play_count
	test_button.pressed.emit()
	_require(audio_manager.button_press_sfx_play_count == before_button_count + 1, "Expected keyboard/programmatic button activation to still play click SFX after the mouse press cycle clears.")
	test_button.queue_free()

	var self_hiding_button := Button.new()
	self_hiding_button.text = "Self Hiding"
	self_hiding_button.pressed.connect(func() -> void: self_hiding_button.visible = false)
	root.add_child(self_hiding_button)
	await process_frame
	before_button_count = audio_manager.button_press_sfx_play_count
	self_hiding_button.pressed.emit()
	_require(audio_manager.button_press_sfx_play_count == before_button_count + 1, "Expected buttons that hide during pressed handlers to still play click SFX.")
	self_hiding_button.queue_free()

	var before_shop_count: int = audio_manager.shop_change_sfx_play_count
	var shop_change_played: bool = audio_manager.play_shop_change_sfx()
	_require(shop_change_played, "Expected shop change SFX to play.")
	_require(audio_manager.shop_change_sfx_play_count == before_shop_count + 1, "Expected shop change SFX count to increment.")
	_require(absf(audio_manager.last_shop_change_pitch_scale - audio_manager.SHOP_CHANGE_SFX_PITCH_SCALE) < 0.001, "Expected shop change pitch diagnostic to match mix setting.")
	_require(audio_manager.last_shop_change_pitch_scale < 1.0, "Expected shop change SFX to be pitched down.")

	var before_footsteps_count: int = audio_manager.footsteps_sfx_play_count
	var footsteps_played: bool = audio_manager.play_footsteps_sfx(0.08)
	_require(footsteps_played, "Expected footsteps SFX to play.")
	_require(audio_manager.footsteps_sfx_play_count == before_footsteps_count + 1, "Expected footsteps SFX count to increment.")
	_require(audio_manager._footsteps_player.playing, "Expected footsteps SFX player to be active during its duration.")
	_require(absf(audio_manager.last_footsteps_duration_sec - 0.08) < 0.001, "Expected footsteps duration diagnostic to match the requested run duration.")
	await create_timer(0.12).timeout
	_require(not audio_manager._footsteps_player.playing, "Expected footsteps SFX player to stop after the requested duration.")

	var before_count: int = audio_manager.attack_sfx_play_count
	var played_slow: bool = audio_manager.play_random_attack_sfx(1.0, 1200, false)
	_require(played_slow, "Expected slow attack SFX to play.")
	_require(audio_manager.attack_sfx_play_count == before_count + 1, "Expected attack SFX play count to increment.")
	var slow_pitch: float = audio_manager.last_attack_sfx_pitch_scale
	_require(audio_manager.last_attack_sfx_cast_duration_ms == 1200, "Expected slow cast duration to be recorded.")
	_require(audio_manager.last_attack_sfx_playback_speed == 1.0, "Expected normal playback speed to be recorded.")

	var played_fast: bool = audio_manager.play_random_attack_sfx(2.0, 450, false)
	_require(played_fast, "Expected fast attack SFX to play.")
	var fast_pitch: float = audio_manager.last_attack_sfx_pitch_scale
	_require(fast_pitch > slow_pitch, "Expected faster skill/playback timing to produce a higher pitch scale.")
	_require(audio_manager.last_attack_sfx_cast_duration_ms == 450, "Expected fast cast duration to be recorded.")
	_require(audio_manager.last_attack_sfx_playback_speed == 2.0, "Expected fast playback speed to be recorded.")

	before_count = audio_manager.attack_sfx_play_count
	var suppressed: bool = audio_manager.play_random_attack_sfx(4.0, 250, true)
	_require(not suppressed, "Expected suppressed attack SFX call to return false.")
	_require(audio_manager.attack_sfx_play_count == before_count, "Expected suppressed attack SFX not to increment play count.")

	var proc_cast := CombatResolver.CastEvent.new()
	proc_cast.cast_start_ms = 0
	proc_cast.time_ms = 900
	proc_cast.physical_damage = 54.0
	proc_cast.damage_contributions = [
		{"kind": "cast", "damage": 18.0},
		{"kind": "proc", "damage": 18.0},
		{"kind": "proc", "damage": 18.0},
		{"kind": "proc", "damage": 0.0},
	]
	before_count = audio_manager.attack_sfx_play_count
	var scheduled_count: int = audio_manager.play_attack_sfx_for_cast(proc_cast, 1.0, false)
	_require(scheduled_count == 3, "Expected base hit plus two damaging procs to schedule three sword SFX.")
	_require(audio_manager.last_attack_sfx_hit_count == 3, "Expected AudioManager to record three cast/proc hits.")
	_require(audio_manager.last_attack_sfx_proc_hit_count == 2, "Expected AudioManager to record two proc hits.")
	_require(audio_manager.attack_sfx_play_count == before_count + 1, "Expected the base cast SFX to play immediately.")
	await create_timer(0.2).timeout
	_require(audio_manager.attack_sfx_play_count == before_count + 3, "Expected the two proc SFX to play after their short offsets.")

	before_count = audio_manager.attack_sfx_play_count
	var suppressed_proc_count: int = audio_manager.play_attack_sfx_for_cast(proc_cast, 1.0, true)
	_require(suppressed_proc_count == 0, "Expected suppressed proc-aware attack SFX call to return 0.")
	_require(audio_manager.last_attack_sfx_hit_count == 3, "Expected suppressed proc-aware calls to still count the cast hits for diagnostics.")
	await create_timer(0.2).timeout
	_require(audio_manager.attack_sfx_play_count == before_count, "Expected suppressed proc-aware attack SFX not to schedule delayed hits.")

	var blocked_cast := CombatResolver.CastEvent.new()
	blocked_cast.cast_start_ms = 0
	blocked_cast.time_ms = 900
	blocked_cast.physical_damage = 0.0
	blocked_cast.blocked_amount = 10.0
	before_count = audio_manager.attack_sfx_play_count
	var blocked_count: int = audio_manager.play_attack_sfx_for_cast(blocked_cast, 1.0, false)
	_require(blocked_count == 1, "Expected a fully blocked physical hit to still schedule one attack SFX.")
	_require(audio_manager.last_attack_sfx_hit_count == 1, "Expected fully blocked physical hit to count as one hit for diagnostics.")
	_require(audio_manager.attack_sfx_play_count == before_count + 1, "Expected fully blocked physical hit to play attack SFX.")

	var dodged_cast := CombatResolver.CastEvent.new()
	dodged_cast.was_dodged = true
	dodged_cast.time_ms = 900
	before_count = audio_manager.attack_sfx_play_count
	var before_dodge_count: int = audio_manager.dodge_sfx_play_count
	_require(audio_manager.play_attack_sfx_for_cast(dodged_cast, 1.0) == 1, "Zero-damage dodge plays one sound.")
	_require(audio_manager.dodge_sfx_play_count == before_dodge_count + 1, "Dodge counter increments once.")
	var player_index: int = posmod(audio_manager._attack_sfx_player_index - 1, audio_manager._attack_sfx_players.size())
	_require(audio_manager._attack_sfx_players[player_index].stream == audio_manager._dodge_sfx_stream, "Dodge selects Sword Swing only.")
	var dodge_pitch: float = audio_manager.last_attack_sfx_pitch_scale
	_require(audio_manager.play_dodge_sfx(2.0, 450), "Fast dodge plays.")
	_require(audio_manager.last_attack_sfx_pitch_scale > dodge_pitch, "Dodge keeps timing/speed pitch processing.")
	await create_timer(0.2).timeout
	_require(audio_manager.attack_sfx_play_count == before_count, "Dodge schedules no random hit sounds.")
	before_dodge_count = audio_manager.dodge_sfx_play_count
	_require(audio_manager.play_attack_sfx_for_cast(dodged_cast, 1.0, true) == 0, "Skipped dodge is silent.")
	_require(audio_manager.dodge_sfx_play_count == before_dodge_count, "Suppression does not play dodge.")
	# Defensive routing: dodge takes priority even with stale hit/proc fields.
	proc_cast.was_dodged = true
	_require(audio_manager.play_attack_sfx_for_cast(proc_cast, 1.0) == 1, "Dodge never schedules proc hit sounds.")
	await create_timer(0.2).timeout
	_require(audio_manager.attack_sfx_play_count == before_count and audio_manager.dodge_sfx_play_count == before_dodge_count + 1, "Exactly one dodge sound, no delayed hit sounds.")
	print("Attack SFX audio check: OK")
	quit()


func _require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
