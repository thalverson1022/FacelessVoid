# M7-T7 — Mixed combat cues and audio lifecycle verification

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

**Complete under D046 (2026-10-15).** The user accepted the [ghost/retrigger/proc treatment](P6M7_T7_Ghost_Retrigger_Prototype.md) through D045, requested the remaining verification/fixes, and accepted both actual listening clips. The scoped G06/G10 repairs, rendered review and affected regression are complete. T1–T7 Complete; T8–T11 Not started; M7 remains In progress.

## Scope

- G06: dense Assassin/Shadow playback plus mixed Poison ticks, ordinary/critical/crit-negated hits, gold theft, dodge and interruption alongside ghost attacks. Check Adventure, Test and Practice at 1×/2×/4× and reduced motion. Preserve the accepted original-art ghost and lighter labels, sixteen-strike cap, ordered state and damage.
- G10: pending multi-hit sound must not leak across Skip, retry/new combat, speed changes or exit. Check event scheduling/cancellation and actual mixed-audio output. Dummy-driver event counts alone do not establish audible quality.
- Fix reproduced presentation/lifecycle defects, run affected regression, record final source/evidence and remaining acceptance. No mechanics/balance changes; broader sizes/accessibility remain T8. General engine certificate/resource teardown qualification remains M9.

## Verification status

Implementation, isolated checks and parent source/visual review are complete. The evidence below distinguishes actual resolver playback, injected special-cue diagnostics, PCM recording and the user's listening acceptance. Protected baseline hashes confirm original art, data, systems, resources and all 1,170 captured real userdata files remain unchanged.


## Reproduced findings

- **G06:** valid mixed-cue playback reproduces collisions among normal damage, negated crit, gold, dodge and interruption text. The review distinguishes actual resolver-built Assassin/Shadow density from injected special-outcome cases.
- **G10:** real WASAPI Effects-bus recording and callback counters reproduce delayed proc sounds after exiting each of Test, Adventure and Practice. The outgoing screen remains alive during the 160 ms crossfade, so `_exit_tree()` cancellation happens too late. The scoped fix stops outgoing screen processing and cancels combat sound at transition start while the game-root-owned fade completes. Final waveform/event evidence and incoming-screen checks pass.


## Real-audio evidence

[WASAPI lifecycle run](../project/reports/p6_m7_audio_final2/summary.json) passes all 18 cases: three modes × reference/Skip/retry/speed-2×/speed-4×/exit. [Recorded events and driver metadata](../project/reports/p6_m7_audio_final2/p6_m7_audio_lifecycle_record/audio_lifecycle/measurements.json) use a disclosed synthetic multi-proc cast sent through each real playback surface. Reference cases produce all five sounds; transition cases prevent pending callbacks. Retry/speed cases hold the new timeline while checking for stale callbacks, so a separate check must establish that fresh playback resumes.

[Parent PCM analysis](../work/t7_remaining_before/parent_audio_review.json) independently verifies that all 15 cancellation cases have zero additional callbacks after the action and exactly silent Effects-bus samples from 150 ms after the action to recording end. This margin allows capture/mixer buffering; it is not an assertion of zero-latency device output. Reference recordings retain delayed hits and nonzero PCM. These are Effects-bus captures, not operating-system loopback or recordings of the listener's speakers.

Actual resolver ghost chains were also recorded for listening: [1×, 5.003 s](../project/reports/p6_m7_audio_final2/p6_m7_audio_lifecycle_record/audio_lifecycle/ghost_1x.wav) and [4×, 3.808 s](../project/reports/p6_m7_audio_final2/p6_m7_audio_lifecycle_record/audio_lifecycle/ghost_4x.wav). Parent sample analysis finds no clipped 16-bit samples in either clip (peaks approximately 0.888 and 0.796). The synthetic five-hit reference has a small saturated-sample fraction; it is not the accepted ghost pacing fixture. The user listened to the two clips and replied **“Both sound good.”** This records human acceptance of the current 1×/4× ghost-chain mix; the automated lifecycle/cancellation findings remain supported separately by PCM and callback evidence. Final affected regression and visual review also pass.


## Implemented presentation repair

Both popup implementations use the same bounded placement helper. Two left-side outcome lanes replace random stacking; Poison ticks use a separate lower-right target-side band. Wide composite crit-negation and gold messages fit their available width including punch scale. Normal rise is reduced to 24 px. New messages retire older messages in the same lane, and hidden retired nodes no longer exhaust the visible-message cap. Labels draw above actors so damage values are not covered by a sprite. The accepted ghost/text treatment and sixteen-strike cap remain.

The old Practice assertion requiring Poison text within 48 px of the target center conflicts with the reproduced icon/ghost/footer collision. The scoped presentation expectation changes to a contained target-side band with explicit clearance from ghost labels, status values and footer buttons. Poison timing, damage, stacks and smaller Wyvern text are unchanged.

The mixed visual harness covers three modes × 1×/2×/4× × motion/reduced motion. The legal 45-point Assassin/Shadow build and guaranteed-retrigger diagnostic use real resolver results; crit-negation, gold, dodge and interruption edge cases are identified injections on the actual screen surfaces. Dense-phase stepping intentionally accelerates event delivery for layout stress, rather than claiming a real-time movie at the labeled speed. A later mixed phase advances actual ghost playback between special outcomes to cover ghost/text coexistence. Reduced motion retains the existing suppression behavior. This is the scoped 1280×720 T7 review; the full multi-size/125%-text matrix stays with T8.

## Closeout and handoff

Final affected regressions, matched-source rendered frames and preservation fingerprints have been reconciled. T7 is Complete under D046. User acceptance covers the ghost/proc presentation through D045 and the actual 1×/4× listening clips. General engine certificate/resource-at-exit diagnostics remain M9 qualification; known historical signature/autosave exceptions retain their prior dispositions. No balance or mechanics changes are part of this work. T8 receives the combined UI/accessibility matrix; T9/T10 retain milestone-wide playtesting/refinement.


## Final evidence

- [Consolidated six passing focused suites](../project/reports/p6_m7_t7_evidence/focused_passes.json): retrigger labels, retrigger playback/state, shared presentation, Practice combat view, attack audio and stage visual reset. After the final Poison-band change, only affected label/presentation/Practice checks were repeated. Earlier failed diagnostic/fixture reports remain preserved and explicitly superseded; mechanics expectations were not altered.
- [Final rendered run](../project/reports/p6_m7_t7_band_rendered/summary.json): 126 captures across three modes × 1×/2×/4× × normal/reduced motion. Nine captured cases show live ghosts and Poison together. [Coverage and fixture details](../project/reports/p6_m7_t7_evidence/verification.json).
- [Final WASAPI lifecycle/navigation run](../project/reports/p6_m7_t7_pcm_verified/summary.json) and [PCM analysis](../project/reports/p6_m7_t7_pcm_verified/p6_m7_audio_lifecycle_record/audio_lifecycle/pcm_analysis.json): 15 cancellation cases, three uncancelled references and two real-resolver ghost clips. Incoming fades complete, outgoing nodes are freed, the incoming screen processes and fresh combat SFX remain available. User listening acceptance refers to the earlier equivalent 1×/4× clips linked above; the production sound implementation/assets remain unchanged.
- [Exact final source hashes and repair scope](../project/reports/p6_m7_t7_evidence/implementation.json), [protected baseline proof](../work/t7_remaining_before/verification.json), [parent reconciliation](../work/t7_remaining_before/parent_review.json). Parent rechecked current source against both manifest and isolated scratch source, and independently rehashed protected files and all 1,170 captured real userdata files.

Parent-reviewed matching final frames: [Test live ghost + mixed cues](../project/reports/p6_m7_t7_band_rendered/p6_m7_mixed_cues_visual/mixed_cues/test_1x_mixed.png), [Test 4× resolver damage/ticks](../project/reports/p6_m7_t7_band_rendered/p6_m7_mixed_cues_visual/mixed_cues/test_4x_resolver.png), [Adventure wide negated crit](../project/reports/p6_m7_t7_band_rendered/p6_m7_mixed_cues_visual/mixed_cues/adventure_2x_special1.png), and [Practice 4× mixed feedback](../project/reports/p6_m7_t7_band_rendered/p6_m7_mixed_cues_visual/mixed_cues/practice_4x_mixed.png).

T8 is next: integrated UI/accessibility review across supported sizes and supported enlarged text, including the final cue lanes, all relevant tree roles and dense mixed builds. No T8 work or milestone-wide acceptance is implied by this scoped closeout. No commit or publication was requested or performed.
