# Buff and debuff combat audio

2026-10-27. Implemented under P6M9-D031, following the user's sound-editing/integration request. This is a presentation amendment after T9; T10 remains Not started. Technical checks pass; subjective listening acceptance remains with the user.

## Prepared assets

Original files remain unchanged in `F:\Data\Junk\DPS Game\Sounds`. The new game assets are separate copies:

| Cue | Supplied duration | Prepared duration | Game asset |
| --- | ---: | ---: | --- |
| Self buff | 2.880s | 1.325s | [self_buff.mp3](../project/assets/audio/fx/skills/self_buff.mp3) |
| Debuff | 1.320s | 0.890s | [debuff.mp3](../project/assets/audio/fx/skills/debuff.mp3) |

Self buff retains source0.025–1.350s; debuff retains0.160–1.050s. The edits remove leading padding and excess quiet tail while retaining a faded natural decay. A3ms fade-in and80ms/45ms fade-outs avoid abrupt boundaries. Measurements use decoded PCM, rather than MP3 container-duration estimates.

Both selected cues are lowered **three semitones** using Rubber Band with tempo1, preserving the edited duration rather than slowing playback. A gentle3.2kHz EQ cut (−2.5dB),6.5kHz low-pass and70/90Hz high-pass soften brightness and remove low rumble. No new reverb is added. Stereo channels are processed together. Exports are48kHz stereo,192kbps MP3.

The processing target is −23dBFS RMS with a −3dBFS peak ceiling. Decoded final RMS is about −23.26dBFS for both cues; peaks are −3.49dBFS for self buff and −7.20dBFS for debuff. No decoded samples clip. RMS matching is a technical starting point, not a claim of perceptually identical loudness in every scene.

[Processing manifest](../project/reports/m9_buff_debuff_audio/processing.json) records source/output hashes, exact filters/gains, durations, activity and spectral measurements. [Reproducible pipeline](../tools/p6/prepare_buff_debuff_audio.py) reads the originals without modifying them. Its build-time dependency is NumPy plus FFmpeg with Rubber Band/libmp3lame; the task used a workspace-local `imageio-ffmpeg` package under `work/buff_debuff_audio/dependencies`. The game requires none of these authoring dependencies.

Two-, three- and four-semitone variants are retained in the [preview folder](../project/reports/m9_buff_debuff_audio/previews/). The comparisons play a loudness-matched, trimmed original, a short silent gap, then the selected treatment:

- [Self buff comparison](../project/reports/m9_buff_debuff_audio/previews/self_buff_comparison.wav).
- [Debuff comparison](../project/reports/m9_buff_debuff_audio/previews/debuff_comparison.wav).

These previews support user listening. No human listening or final tonal preference is claimed by the automated checks.

## Combat routing and variation

`AudioManager.play_skill_sfx_for_cast()` dispatches by `Skill.Category`. A successful SELF_BUFF or DEBUFF activation plays one corresponding cue, including zero-damage activations. A damaging Debuff uses the Debuff cue rather than layering an attack cue for each damage contribution. Successful repeated cast events receive their own cue; passive Poison ticks and damage/proc contributions do not create extra category sounds.

Interrupted, skipped, cooldown-blocked, resource-unavailable, dodged category activations and Hold are silent. Playback callbacks in Adventure/shared Test and Practice dispatch at the resolved activation event. Skip/instant drains suppress sounds. No resolver, cooldown, damage, talent or reward rules changed.

Each cue uses pitch0.96–1.04 and gain0.60–0.68 (base0.64±0.04). This is presentation RNG only. Category pitch does **not** inherit attack cast-duration or playback-speed multipliers;1×/2×/4× changes cast cadence without raising the cue's pitch. The existing eight-player Effects pool bounds overlap and uses the existing cancellation lifecycle. Existing attack/dodge routines and their timing/variation remain available unchanged.

## Verification

[Consolidated audit](../project/reports/m9_buff_debuff_audio/verification.json) reconciles source/media hashes, final test-source hashes, independent PCM measurements and protected files.

| Check | Result |
| --- | --- |
| [Category behavior suite](../project/reports/m9_buff_debuff_audio_verified/summary.json) | Pass: stream selection/Effects routing, pitch/gain ranges and variation, exclusions, repeat/proc semantics, cancellation and actual resolver playback in Adventure/Practice at1×/2×/4×. |
| [Existing attack SFX suite](../project/reports/m9_buff_debuff_audio_checks/summary.json) | The `attack_sfx_audio_test` row passes; the earlier category row in that report is an excluded fixture iteration. |
| [WASAPI engine recording](../project/reports/m9_buff_debuff_audio_wasapi_capture/summary.json) | Pass: actual decoded48kHz stereo output. Ordinary cues and eight overlapping repeat contacts peak at0.466 (−6.64dBFS), with no clipping in this witness. |
| Effects zero | Captured final mix is exactly silent. |
| Cancellation | Captured tail from0.5s is exactly silent after the cue cancellation at about0.25s. |
| Source/protected files | Both supplied MP3 hashes unchanged; all164 protected profile/sibling identity files unchanged. |

The [engine sequence](../project/reports/m9_buff_debuff_audio_wasapi_capture/m9_buff_debuff_audio_record/buff_debuff_audio/ordinary_and_repeats.wav) plays self buff, debuff, then alternating rapid repeats. [Measurements](../project/reports/m9_buff_debuff_audio_wasapi_capture/m9_buff_debuff_audio_record/buff_debuff_audio/measurements.json) and the PCM audit distinguish final Master-bus capture from Effects input: category players route through Effects, and Master recording includes the Effects fader/mute. This verifies mixer output, not physical speaker hardware.

All engine checks used copied projects, distinct five-path save namespaces and redirected per-suite application-data directories. A first category fixture injected presentation timestamps out of order; that fixture was corrected and rerun without further runtime changes. An initial Dummy-driver recording also produced valid decoded PCM, but the WASAPI run is the final driver evidence. Certificate-store and shutdown resource/ObjectDB diagnostics remain recorded; no broad engine qualification is claimed.

The only runtime/content changes after the T9 checkpoint are AudioManager, the two playback handlers and the two new assets. T9's earlier source-immutability evidence remains a historical checkpoint. T10 progression/economy scope is unchanged.

## Reproduction

```text
python tools/p6/prepare_buff_debuff_audio.py
python tools/p6/run_retrigger_checks.py --report-name buff_audio_recheck --tests m9_buff_debuff_audio_test attack_sfx_audio_test
python tools/p6/run_retrigger_checks.py --report-name buff_audio_capture_recheck --visual --audio-driver WASAPI --tests m9_buff_debuff_audio_record
python tools/p6/check_buff_debuff_audio.py
```

Use fresh report names. The final audit reconciles this task's frozen reports and baseline; new runs have their own summaries and source hashes.
