extends "res://tests/m9_buff_debuff_audio_test.gd"
## Actual decoded Godot mix. Master capture includes Effects fader/mute;
## only category players run, with music/UI absent in this standalone harness.
const AUDIO_OUT := "res://reports/buff_debuff_audio"
var recordings: Array = []
var recorder: AudioEffectRecord
var audio

func metrics(recording: AudioStreamWAV, start_seconds: float = 0.0) -> Dictionary:
	var first := int(start_seconds * recording.mix_rate) * (2 if recording.stereo else 1) * 2
	var peak := 0.0
	var square_sum := 0.0
	var samples := 0
	for offset in range(first,recording.data.size()-1,2):
		var sample := float(recording.data.decode_s16(offset)) / 32768.0
		peak = maxf(peak,absf(sample))
		square_sum += sample * sample
		samples += 1
	return {"peak":peak,"rms":sqrt(square_sum/maxi(samples,1)),"samples":samples}

func finish_clip(name: String, tail_start: float = -1.0) -> Dictionary:
	recorder.set_recording_active(false)
	var recording := recorder.get_recording()
	check(recording != null and recording.data.size() > 1000,"Decoded PCM recording exists: " + name)
	check(recording.save_to_wav(AUDIO_OUT + "/" + name + ".wav") == OK,"WAV saved: " + name)
	var row := metrics(recording)
	row["file"] = name + ".wav"
	row["sample_rate"] = recording.mix_rate
	row["stereo"] = recording.stereo
	row["seconds"] = recording.get_length()
	if tail_start >= 0.0: row["tail"] = metrics(recording,tail_start)
	recordings.append(row)
	return row

func run() -> void:
	DirAccess.make_dir_recursive_absolute(AUDIO_OUT)
	audio = root.get_node("AudioManager")
	await process_frame
	audio.set_master_volume(0.8,false)
	audio.set_effects_volume(0.8,false)
	var bus := AudioServer.get_bus_index("Master")
	recorder = AudioEffectRecord.new()
	recorder.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(bus,recorder)
	await create_timer(0.2).timeout
	var buff := category_cast(Skill.Category.SELF_BUFF)
	var debuff := category_cast(Skill.Category.DEBUFF)
	recorder.set_recording_active(true)
	await create_timer(0.2).timeout
	audio.play_skill_sfx_for_cast(buff,1.0)
	await create_timer(1.3).timeout
	audio.play_skill_sfx_for_cast(debuff,1.0)
	await create_timer(1.3).timeout
	# Actual-repeat dispatch uses the same bounded pool; speed4 does not
	# multiply pitch. Alternating contacts exercise overlapping category clips.
	for i in 8:
		audio.play_skill_sfx_for_cast(buff if i % 2 == 0 else debuff,4.0,false,true,false)
		await create_timer(0.12).timeout
	await create_timer(1.5).timeout
	var reference := finish_clip("ordinary_and_repeats")
	check(reference.peak > 0.005 and reference.rms > 0.0001,"Actual engine decodes audible category PCM")
	check(reference.peak < 0.98,"Ordinary/overlapping category mix has clipping headroom")
	audio.cancel_combat_sfx()
	await create_timer(0.25).timeout
	audio.set_effects_volume(0.0,false)
	recorder.set_recording_active(true)
	audio.play_skill_sfx_for_cast(buff,1.0)
	audio.play_skill_sfx_for_cast(debuff,1.0)
	await create_timer(0.8).timeout
	var muted := finish_clip("effects_zero")
	check(muted.peak < 0.0001,"Effects zero produces silent final mix")
	audio.cancel_combat_sfx()
	audio.set_effects_volume(0.8,false)
	await create_timer(0.25).timeout
	recorder.set_recording_active(true)
	audio.play_skill_sfx_for_cast(buff,4.0)
	audio.play_skill_sfx_for_cast(debuff,4.0)
	await create_timer(0.25).timeout
	audio.cancel_combat_sfx()
	await create_timer(0.75).timeout
	var cancelled := finish_clip("cancel_tail",0.5)
	check(cancelled.peak > 0.005,"Cancellation reference starts with decoded cues")
	check(cancelled.tail.peak < 0.0001,"Cancelled cues leave a silent tail after audio-buffer grace")
	AudioServer.remove_bus_effect(bus,AudioServer.get_bus_effect_count(bus)-1)
	SaveSystem.write_json(AUDIO_OUT + "/measurements.json",{"driver":AudioServer.get_driver_name(),"capture_bus":"Master (category players routed via Effects)","rows":recordings,"disclosure":"Actual Godot decoded PCM, standalone category dispatch ordinary/repeated casts. No human listening performed. Scene integration is checked separately by m9_buff_debuff_audio_test."})
	print("Buff/debuff audio recording PASS" if not failed else "Buff/debuff audio recording FAILED")
	quit(1 if failed else 0)
