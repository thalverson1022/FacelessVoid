# Dedicated skill and theft cues

2026-10-27 — P6M9-D037. User requests dedicated Poison Vile, Blinding Powder and Pick Pocket sounds, a shorter/softer Pick Pocket, and Gold Steal whenever a Thief steals gold. Supplied originals in `F:/Data/Junk/DPS Game/Sounds` are preserved.

| Source | In-game cue | Preparation |
| --- | --- | --- |
| vile.mp3 | Poison Vile | Trim0.768s to0.360s; correct unusually low source level to decoded peak−6.26/RMS−26.59dBFS |
| powder.mp3 | Blinding Powder | Trim1.224s to0.490s, removing roughly half a second of leading silence |
| pick_pocket.mp3 | Pick Pocket activation | Shorten1.056s to0.550s; gentle compression, reduced highs, −5dB gain and short fades; decoded peak−12.43/RMS−27.16dBFS |
| gold_steal.mp3 | Actual credited combat theft | Faithful0.496s copy; use a quieter runtime gain |

All four cues use the standard ±4% runtime pitch variation independent of playback speed. Skill activations use linear gain0.60–0.68; theft receipts use0.37–0.43 so they can accompany the activation/weapon sound. The dedicated activation replaces the generic category cue. A cast with positive recorded `gold_stolen` gets one receipt cue, including passive or retrigger theft even when its attack animation is coalesced. Zero/rounded-to-zero theft emits none. No cue is attached to ordinary rewards, shops or stash changes. Pick Pocket can play both its activation and the receipt sound.

The existing eight-player Effects pool, volume controls and cancellation remain shared. Failed casts and skip/instant drains are silent. Combat calculations, gold transactions, source artwork and save formats are unchanged.

Preparation is reproducible with `tools/p6/prepare_thief_skill_audio.py`. [Processing measurements and original/asset hashes](../project/reports/m9_thief_skill_audio_assets/processing.json) verify all originals unchanged and no decoded clipping. [Pick Pocket before/after comparison](../project/reports/m9_thief_skill_audio_assets/previews/pick_pocket_comparison.wav) plays original, pause, edited version; it is not loudness matched because reduced level is part of the requested edit.

[Isolated routing verification](../project/reports/m9_thief_skill_audio/summary.json) passes: dedicated streams, pitch bounds and variation, receipt gain, zero/failed/suppressed casts, passive theft without an attack visual beat, and real resolver playback counts in Adventure and Practice at1×/2×/4×. The same suite retains Exsanguinate, generic category and attack behavior checks. Known certificate-store and shutdown resource diagnostics remain in logs. Subjective listening acceptance is not claimed; T10 remains Not started.

[Decoded mix verification](../project/reports/m9_thief_audio_pcm/summary.json) also passes, with [measurements and seven WAVs](../project/reports/m9_thief_audio_pcm/m9_thief_skill_audio_record/thief_skill_audio/measurements.json). At Master/Effects0.8, ordinary cue peaks are0.260 Vile,0.164 Powder,0.311 Pick Pocket plus gold and0.680 Stab plus gold; overlapping speed4 cues peak0.544. Effects-zero and the cancelled tail are exactly silent. Headless Godot reports the Dummy driver at44.1kHz despite requesting WASAPI; AudioEffectRecord captures actual decoded/mixed PCM, not a device loopback or human listening test. No claim about all possible simultaneous mixes or full-fader peak levels is made.
