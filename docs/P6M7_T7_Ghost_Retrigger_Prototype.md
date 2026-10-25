# M7-T7 — Ghost retrigger prototype

2026-10-15. **Historical implementation record through D045; user accepted the treatment. T7 completed under [D046 closeout](P6M7_T7_Combat_Cues_And_Audio_Verification.md).** The user requested this revision after testing the [D042 flurry](P6M7_T7_Retrigger_Flurry_Presentation.md). T7 remains In progress; T6 remains accepted and complete under D041.

## Requested revision

The user found the chain/combo text difficult to see and unnecessary, disliked the main character jumping during retriggers and the X-shaped effect, and found the flurry too fast at 4×. The authorized prototype keeps the main character anchored during follow-ups, uses semi-transparent ghost copies for extra attacks, removes the chain text and X effect, and slows retrigger animation further.

## Implementation boundaries

- Retain the normal opening attack. During retriggers the main character remains at its home position; an existing-art ghost performs the additional strikes.
- Use one readable faded echo at a time, with restrained alternate positions and a short fade. Remove the chain total/count and crossed slash, without introducing replacement combo labels.
- Give the ghost contacts a minimum real-time viewing duration at high playback speeds. Animation, audio, health and temporary-effect state still follow the same paced sequence.
- Retain bounded presentation beats and exact resolver outcomes/order, damage, RNG, consumption, expiry, cooldowns and rewards. No numerical balance or original-art changes.
- Preserve dodge/interruption/resource-failure meaning, reduced motion and skip/retry/speed/finish/exit cleanup in Adventure, Test Mode and Practice.

## Implemented treatment

The normal opening attack retains its authored animation. Each additional visible strike uses one reusable copy of the original Rogue art, starting at its contact/recovery frames beside the target. The main actor remains at home during follow-ups. The echo peaks at 48% opacity with mild desaturation, holds briefly, then fades; small alternating offsets distinguish strikes. The chain/combo label and crossed-slash effect are removed. Dodge/interruption and unsuccessful attempts retain their outcome meanings.

Contacts use authored gaps of 260/230/210/190/180/180/230 ms, with a 140 ms real-time minimum at higher playback speeds. Each ghost lasts 160 ms at 1× and at least 125 ms at higher speeds. A root ends with 200 ms of recovery (at least 125 ms real time); deadline dwell is 260 ms authored, at least 180 ms real time. At most eight visual/audio beats are retained per root. Large chains therefore stay bounded while individual echoes remain visible at 4×. Ordinary attack playback still follows the selected speed.

Playback integrates real time through pause boundaries, including mid-chain speed changes. Health, effects, timers and audio follow the same ordered presentation. Recovery holds the observation frontier before the next macro's earliest record, including consumption that precedes its explicit start. This keeps post-chain grants visible until the next attack begins. No resolver, damage, RNG, cooldown, reward or balance changes are introduced.

Reduced motion suppresses ghost movement and copies. Skip, retry, speed changes, normal finish and exit clear the active echo and pending sound work. The shared treatment applies to Adventure, Test Mode and Practice.

## Review and verification

[Eight focused suites pass](../project/reports/p6_m7_ghost_verified/summary.json): retrigger pacing/state, combat presentation, Dance recast display, effect lifecycle, Practice combat view, attack audio routing, stage visual reset, and T6 effect display regression. Coverage includes 1×/2×/4× and mid-chain speed changes, large deltas, main-actor anchoring, opacity/fade, cleanup and real Quick Cut → Plunge/Parry resource-consumption frontiers.

Rendered motion and preservation records are linked below. Sound checks use the Dummy driver and verify scheduling/cancellation; audible acceptance remains a user playtest. Existing autosave and historical status-signature failures retain their prior disposition under D042; this prototype does not change mechanics to alter those baselines.

This is a presentation prototype for user playtesting. Full T7 popup/audio acceptance and T8–T11 remain downstream; prior historical test failures keep their recorded disposition.


## Evidence and replay

[Exact implementation fingerprints and tuning](../project/reports/p6_m7_ghost_evidence/implementation.json), [protected-file/save verification](../work/t7_ghost_before/verification.json), and [parent review](../work/t7_ghost_before/parent_review.json) record the final scope. All 83 captured real save files, original artwork, mechanics and data remain unchanged.

- [Actual cross-mode rendered checks](../project/reports/p6_m7_ghost_evidence/summary.json), with [measured frame/anchor/opacity data](../project/reports/p6_m7_ghost_evidence/p6_m7_retrigger_flurry_visual/ghost_motion/measurements.json).
- Test Mode: [1× motion](../project/reports/p6_m7_ghost_evidence/p6_m7_retrigger_flurry_visual/ghost_motion/test_1x_ghost.gif), [4× motion](../project/reports/p6_m7_ghost_evidence/p6_m7_retrigger_flurry_visual/ghost_motion/test_4x_ghost.gif).
- Adventure: [1× motion](../project/reports/p6_m7_ghost_evidence/p6_m7_retrigger_flurry_visual/ghost_motion/adventure_1x_ghost.gif), [4× motion](../project/reports/p6_m7_ghost_evidence/p6_m7_retrigger_flurry_visual/ghost_motion/adventure_4x_ghost.gif).
- Practice: [1× motion](../project/reports/p6_m7_ghost_evidence/p6_m7_retrigger_flurry_visual/ghost_motion/practice_1x_ghost.gif), [4× motion](../project/reports/p6_m7_ghost_evidence/p6_m7_retrigger_flurry_visual/ghost_motion/practice_4x_ghost.gif).

These movies use the existing diagnostic resolver fixture (100 weapon damage, guaranteed retrigger, Poison 10, Readiness, Venom Jab/Poison Strike, seed 7, 4000 ms window), injected into each mode's actual playback surface. It is not an earned Adventure build. The fixture resolves 51 casts, 21 ticks and 2359 damage; captions/stats outside the playback surface need not describe the injected build. PNG encoding is deferred until after timed capture, and GIF frame durations follow measured real deltas.

To reproduce without real saves, use the isolated runner:

```powershell
python tools/p6/run_retrigger_checks.py --report-name ghost_recheck --tests p6_m7_retrigger_flurry_test p6_combat_presentation_test
python tools/p6/run_retrigger_checks.py --report-name ghost_motion_recheck --visual --tests p6_m7_retrigger_flurry_visual
```

For user acceptance, restart the game and try the same high-retrigger setup at 1× and 4×, including Skip and retry. Assess ghost visibility, contact rhythm and audible pacing. Further timing/opacity tuning can follow that playtest; this record does not close T7.


## D044 — Lighter retrigger impact labels

The user preferred the ghost treatment but found that removing follow-up attack text reduced its sense of impact. They authorized restoring each visible ghost strike's skill name and damage with less visual weight: 75% of the original font size, 65% opacity, a shorter fade and less upward travel, retaining existing colors and readable outlines. Opening attacks retain their normal treatment. Labels should use a consistent target-relative position offset from the opening label; the existing visible-beat bound still applies. No combo totals or X effect return. Apply across Adventure, Test and Practice, with the existing playback pacing, outcome meaning and lifecycle cleanup preserved. The labels peak at 65% opacity applied once to the whole label. They retain a 2 px outline, have no punch/scale animation, rise 18 px in Adventure/Test (6 px in Practice) and last 240 ms (70 ms hold, 170 ms fade). Two fixed target-relative lanes separate adjacent strikes; at most two retrigger labels remain live globally, retiring the oldest if a large frame delta delivers more. Existing full-weight opening labels are unchanged. Shared Adventure/Test keeps its integer damage convention; Practice retains one decimal. Critical/proc colors remain, negated crits show the actual resolved damage, and actual stolen gold can appear in the same compact label. Held/unavailable attempts retain the no-hit convention; dodge and interruption labels describe their outcomes. Suppressed logical beats and folded proc names do not create additional popup bursts.

Practice's popup layer sits below the stage in its layout, so its target anchor and top clearance are transformed from stage coordinates into popup coordinates. Practice uses small horizontal offsets in a band below its taller status display and above the target. This keeps follow-up text out of the status icons rather than near the target's feet. Reduced motion retains existing popup suppression; skip, retry/reset, finish and exit clear transient labels. Ghost animation and playback timing are unchanged from D043. T7 remains In progress.


D044 verification:

- [Four focused suites pass](../project/reports/p6_m7_label_verified/summary.json): label content/outcomes, bounded density/fading/event gating/cleanup, shared combat presentation, Practice combat view and existing retrigger playback behavior.
- [Adventure/Test 1×/4× rendered run](../project/reports/p6_m7_label_evidence/summary.json). Its earlier Practice frames are superseded by the [final Practice-only rendered check](../project/reports/p6_m7_label_practice_final/summary.json), which corrects status-icon clearance. Default capture still covers all modes; `FACELESSVOID_CAPTURE_MODES=practice` selects only Practice for targeted visual checks.

D043 movies and fingerprints above remain historical evidence for that revision; use D044's final implementation manifest and captures for current label behavior. User playtesting and audible acceptance remain open; no T7 closeout is implied.


[Final D044 implementation hashes/tuning](../project/reports/p6_m7_label_evidence/implementation.json), [project preservation record](../work/t7_label_before/verification.json), and [parent source/visual review](../work/t7_label_before/parent_review.json). Original artwork, data, mechanics and D043 ghost pacing sources match the task-start baseline. Runs used isolated user-data/save paths. There is no task-start real-save snapshot for D044; comparing against D043's older save baseline reflects intervening changes and cannot prove same-task save equality. Audio used the Dummy driver; audible acceptance remains pending.


## D045 — Sixteen visible strikes per chain

The user requested increasing the presentation cap from eight to sixteen to let rare large chains feel more powerful. Current playback shows up to **16 visible/audio strikes per root**, including the opening attack (up to 15 ghosts). Chains beyond 16 still group excess events; all resolved damage and event order are retained. This visual count is separate from the resolver's depth-16 safeguard, which permits 17 attacks along a straight branch including its opener.

The authored contact gaps are 260/230/210/190 ms, then ten 180 ms middle gaps, then 230 ms for the sixteenth contact. Maximum authored contact spread is 2920 ms, plus existing 200 ms recovery. The minimum real-time contact gap remains 140 ms at high speeds. Ghost styling and the two-label live limit from D044 are unchanged. D043/D044 eight-beat statements and manifests above describe their historical versions; D045 supersedes that cap.

[Two affected suites pass](../project/reports/p6_m7_16_strikes_verified/summary.json): playback cases include 2/4/8/16/17/200 attacks, exact visible count, retained damage/order, 1×/2×/4× timing, speed changes, recovery and skip; label behavior remains covered by the label suite. This is a scheduling/count change, with no new artwork or layout changes. Prior rendered D044 evidence remains the appearance reference. T7 remains In progress.


## User acceptance of retrigger/proc presentation

The user confirmed the D045 result looks good and makes retriggers/procs visually distinct and impactful without requiring guesswork. This accepts the scoped ghost/retrigger presentation, including lighter labels and the sixteen-strike visual limit. It does not close all of T7. Remaining T7 work is the G06 mixed-cue/dense-popup review (including Poison ticks, crit-negated hits and gold hits at 1×/2×/4× and reduced motion across shared/Practice playback), plus G10 audible lifecycle checks for stale sound after skip/exit/retry/speed changes, proportional fixes/regression, and scoped closeout. Broader display-size/accessibility coverage remains T8; milestone-wide playtesting/refinement remains T9/T10.
