extends "res://tests/m9_buff_debuff_audio_test.gd"

func run() -> void:
	var audio = root.get_node("AudioManager")
	await process_frame
	check(audio._exsanguinate_sfx_stream != null, "Dedicated Exsanguinate stream loads")
	check(not audio._exsanguinate_sfx_stream.loop, "Exsanguinate cue does not loop")
	var cast := CombatResolver.CastEvent.new()
	cast.skill = load("res://data/skills/exsanguinate.tres")
	cast.health_removed = 100
	cast.health_removal_captured = true
	var category_before: int = audio.category_sfx_play_count
	var attack_before: int = audio.attack_sfx_play_count
	var pitches := []
	var volumes := []
	for speed in [1.0, 2.0, 4.0]:
		for i in 12:
			check(audio.play_skill_sfx_for_cast(cast, speed) == 1, "One dedicated cue per successful Exsanguinate")
			var player = audio._attack_sfx_players[posmod(audio._attack_sfx_player_index - 1, audio.ATTACK_SFX_POOL_SIZE)]
			check(player.stream == audio._exsanguinate_sfx_stream and player.bus == "Effects", "Correct clip on Effects bus")
			check(player.pitch_scale >= 0.96 and player.pitch_scale <= 1.04, "Subtle pitch independent of playback speed")
			var gain := db_to_linear(float(player.volume_db))
			check(gain >= 0.5999 and gain <= 0.6801, "Subtle gain variation")
			pitches.append(player.pitch_scale)
			volumes.append(gain)
	check(pitches.min() != pitches.max() and volumes.min() != volumes.max(), "Repeated cues vary")
	check(audio.category_sfx_play_count == category_before and audio.attack_sfx_play_count == attack_before, "Dedicated cue replaces generic debuff/attack cue")
	var before: int = audio.exsanguinate_sfx_play_count
	for flag in ["was_interrupted", "interrupt_skipped", "cooldown_blocked", "resource_unavailable", "was_dodged"]:
		cast.set(flag, true)
		check(audio.play_skill_sfx_for_cast(cast, 1.0) == 0, "No dedicated cue on failed cast: " + flag)
		cast.set(flag, false)
	check(audio.play_skill_sfx_for_cast(cast, 1.0, true) == 0, "Suppressed cue stays silent")
	check(audio.exsanguinate_sfx_play_count == before, "Failure increments no play counter")
	audio.cancel_combat_sfx()
	await super.run()
