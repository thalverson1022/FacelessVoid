extends "res://tests/m9_buff_debuff_audio_record.gd"
## Capture the real Master mix of named Thief cues and credited theft.
const THIEF_AUDIO_OUT := "res://reports/thief_skill_audio"
const AssassinAudioFixture = preload("res://scripts/systems/playable_assassin_content.gd")
const ThiefAudioFixture = preload("res://scripts/systems/p6_thief_contracts.gd")

func finish_clip(name: String, tail_start: float = -1.0) -> Dictionary:
	recorder.set_recording_active(false)
	var recording := recorder.get_recording()
	check(recording != null and recording.data.size() > 1000, "Decoded PCM exists: " + name)
	check(recording.save_to_wav(THIEF_AUDIO_OUT + "/" + name + ".wav") == OK, "WAV saved: " + name)
	var row := metrics(recording)
	row["file"] = name + ".wav"
	row["sample_rate"] = recording.mix_rate
	row["stereo"] = recording.stereo
	row["seconds"] = recording.get_length()
	if tail_start >= 0.0: row["tail"] = metrics(recording, tail_start)
	recordings.append(row)
	return row

func run() -> void:
	DirAccess.make_dir_recursive_absolute(THIEF_AUDIO_OUT)
	audio = root.get_node("AudioManager")
	await process_frame
	audio.set_master_volume(0.8, false)
	audio.set_effects_volume(0.8, false)
	var bus := AudioServer.get_bus_index("Master")
	recorder = AudioEffectRecord.new()
	recorder.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(bus, recorder)
	await create_timer(0.2).timeout
	var casts: Array[CombatResolver.CastEvent] = []
	for skill: Skill in [AssassinAudioFixture.skill("poison_vile"), AssassinAudioFixture.skill("blinding_powder"), ThiefAudioFixture.skill("pick_pocket"), load("res://data/skills/stab.tres")]:
		var cast := CombatResolver.CastEvent.new()
		cast.skill = skill
		cast.time_ms = 700
		if skill.id == "skill.pick_pocket" or skill.id == "skill.stab": cast.gold_stolen = 10
		if skill.id == "skill.stab": cast.physical_damage = 30.0
		casts.append(cast)
	# Separate ordinary casts provide individual audibility checks and natural pitch/gain variation.
	for cast in casts:
		recorder.set_recording_active(true)
		await create_timer(0.1).timeout
		for i in 3:
			audio.play_skill_sfx_for_cast(cast, 1.0)
			await create_timer(0.8).timeout
		var ordinary := finish_clip("thief_ordinary_" + cast.skill.id.replace("skill.", ""))
		check(ordinary.peak > 0.005 and ordinary.rms > 0.0001, "Audible actual PCM: " + cast.skill.id)
		check(ordinary.peak < 0.98, "Ordinary mix has headroom: " + cast.skill.id)
	recorder.set_recording_active(true)
	for i in 16:
		audio.play_skill_sfx_for_cast(casts[i % casts.size()], 4.0, false, true, true)
		await create_timer(0.1).timeout
	await create_timer(1.0).timeout
	var repeated := finish_clip("thief_repeats_speed4")
	check(repeated.peak > 0.005 and repeated.rms > 0.0001, "Repeated cues produce audible decoded PCM")
	check(repeated.peak < 0.98, "Repeated overlapping mix has clipping headroom")
	check(audio._attack_sfx_players.size() == audio.ATTACK_SFX_POOL_SIZE, "Repeated cues retain bounded player pool")
	audio.cancel_combat_sfx()
	await create_timer(0.25).timeout
	audio.set_effects_volume(0.0, false)
	recorder.set_recording_active(true)
	for cast in casts: audio.play_skill_sfx_for_cast(cast, 4.0)
	await create_timer(0.8).timeout
	var muted := finish_clip("thief_effects_zero")
	check(muted.peak < 0.0001, "Effects zero silences named, theft and attack cues")
	audio.cancel_combat_sfx()
	audio.set_effects_volume(0.8, false)
	await create_timer(0.25).timeout
	recorder.set_recording_active(true)
	for cast in casts: audio.play_skill_sfx_for_cast(cast, 4.0)
	await create_timer(0.15).timeout
	audio.cancel_combat_sfx()
	await create_timer(0.85).timeout
	var cancelled := finish_clip("thief_cancel_tail", 0.5)
	check(cancelled.peak > 0.005, "Cancellation reference starts with audible PCM")
	check(cancelled.peak < 0.98, "Concurrent cancellation reference has clipping headroom")
	check(cancelled.tail.peak < 0.0001, "Cancelled cues leave silent tail after buffer grace")
	AudioServer.remove_bus_effect(bus, AudioServer.get_bus_effect_count(bus) - 1)
	SaveSystem.write_json(THIEF_AUDIO_OUT + "/measurements.json", {"driver":AudioServer.get_driver_name(), "capture_bus":"Master via Effects", "rows":recordings, "disclosure":"Actual decoded Godot PCM: varied ordinary cues, overlapping repeated speed4 casts, credited Pick Pocket and Stab gold, Effects zero and cancellation. No human listening acceptance claimed."})
	print("Thief skill audio recording PASS" if not failed else "Thief skill audio recording FAILED")
	quit(1 if failed else 0)
