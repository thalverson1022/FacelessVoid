extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func run() -> void:
	await process_frame
	var audio = root.get_node("AudioManager")
	check(audio._magic_find_stream != null and audio._magic_find_stream.get_length() > 2.0, "Supplied Magic Find clip decodes")
	var count_before: int = audio.magic_find_sfx_play_count
	var attack_count: int = audio.attack_sfx_play_count
	var pitches := []
	var gains := []
	for i in 20:
		check(audio.play_magic_find_sfx(), "Visible upgrade cue plays")
		var player: AudioStreamPlayer = audio._magic_find_sfx_players[posmod(audio._magic_find_sfx_player_index - 1, audio.MAGIC_FIND_SFX_POOL_SIZE)]
		check(player.stream == audio._magic_find_stream and player.bus == "Effects", "Magic Find uses its own stream and Effects controls")
		check(player.pitch_scale >= 0.96 and player.pitch_scale <= 1.04, "Small pitch variation")
		var gain := db_to_linear(player.volume_db)
		check(gain >= 0.3199 and gain <= 0.4001, "Small gain variation with staggered-upgrade headroom")
		pitches.append(player.pitch_scale)
		gains.append(gain)
	check(audio.magic_find_sfx_play_count == count_before + 20, "Each upgrade emits exactly one cue")
	check(pitches.min() < pitches.max() and gains.min() < gains.max(), "Pitch and gain both vary")
	check(audio.attack_sfx_play_count == attack_count, "UI upgrade never triggers weapon sounds")
	check(audio._magic_find_sfx_players.size() == 8, "Rapid tier beats use a bounded pool")
	check(audio._magic_find_sfx_players[0].playing and audio._magic_find_sfx_players[1].playing, "Consecutive beats may overlap")
	audio.cancel_combat_sfx()
	check(audio._magic_find_sfx_players[0].playing, "Combat cancellation does not steal reveal tails")
	audio.set_effects_volume(0.0, false)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")), "Effects zero mutes the upgrade cue")
	audio.cancel_magic_find_sfx()
	for player in audio._magic_find_sfx_players:
		check(not player.playing, "Reveal cancellation stops every active tail")
	audio.set_effects_volume(0.8, false)
	check(audio.play_magic_find_sfx(), "A new reveal can play after cancellation")
	audio.cancel_magic_find_sfx()
	if failures.is_empty():
		print("PASS: Magic Find decoded stream, per-beat playback, variation, bounded overlap, Effects mute and cancellation")
	else:
		print("FAILED: ", failures)
	quit(0 if failures.is_empty() else 1)
