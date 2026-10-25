# M7-T7 — Retrigger flurry presentation

2026-10-15. **Historical D042 implementation; revised by the [ghost retrigger prototype](P6M7_T7_Ghost_Retrigger_Prototype.md) after user feedback. T7 remains In progress.** T6 remains user-accepted and complete under D041. This delivers the authorized retrigger-feedback portion of T7; it does not close the full combat-cue, popup and audio review.

## User observation and requested direction

During buff testing, the user reported enjoying Retrigger but finding a large chain's instant explosion of events jarring. The user requested implementation of the discussed direction: readable opening impact, staggered and accelerating follow-up hits, continuous flurry animation, a compact chain count/damage total, restrained audio rhythm and a finishing accent. Huge chains need bounded added viewing time. The discussed 100–150ms opening spacing is a tuning starting point.

## Implementation constraints

- Preserve resolved damage, RNG, cast order, consumption, expiration, cooldowns, rewards and persistence. Changes belong to replay/presentation.
- Drive animation, sound, health, counters and temporary effects from the same presented sequence; delaying a popup alone would leave the HUD ahead of the hit.
- Keep Adventure, Test Mode and Practice consistent. Retain established floating text, original artwork and T5/T6 accepted conventions.
- Handle 1×/2×/4×, reduced motion, skip, retries, exit and large frame deltas without stale callbacks, lingering feedback or unbounded queued playback.
- Use isolated saves and disposable projects for checks. Distinguish actual resolved mixed builds, synthetic stress fixtures, static captures, motion review and human/audible review.

## Implementation and evidence

The shared playback controller now schedules presentation beats for a resolved root's cast chain. Adventure, Test Mode and Practice use this pacing and the shared stage treatment.

Current tuning gives at most eight visible contact beats per root: opening, three distinct follow-ups, three compressed middle beats and the actual last contact. Gaps are 130/105/85/65/55/55/105ms at 1×, for at most 600ms extra flurry time. A chain ending exactly at the fight window gets a 220ms finishing dwell before normal completion; Skip remains immediate. These are presentation delays and scale with playback speed. They do not alter DPS-window duration or resolved mechanics.

The running `Chain xN -damage` text replaces the per-child damage/name spray, while the opening skill retains its established popup. Forced Poison ticks remain ordered within the root and contribute damage without inflating the attack count. Misses and resource failures retain explicit outcomes and do not generate a successful impact accent. Reduced motion retains readable totals and bounded contact audio while suppressing new trails and movement. Original installed art is retained; slash trails are drawn by the stage.

The implementation separates viewing time from simulation time: retrigger flurries gain short presentation beats while the simulation clock waits. Ordered resolver observations must be consumed only through the presented hit, including consumption before a child cast and grants deferred until a subtree finishes. This prevents tied timestamps from revealing a whole chain's effects at the first impact.

Review must establish:

| Case | Required result |
| --- | --- |
| Ordinary casts and small chains | Opening attack remains readable; follow-up beats accelerate without repeatedly returning to idle. |
| Large chain | Added viewing time and visible/audible beats are bounded; every logical event is still accounted for in order and the final displayed total is exact. |
| Mixed Poison/proc/resource events | Health, status counts, buff consumption and post-subtree grants follow the presented event frontier; neither ticks nor grants leak ahead. |
| Speed and frame rate | 1×/2×/4× preserve final totals and sequence; uneven/large frame deltas cannot lose or duplicate events. |
| Reduced motion | No added trails/flashes/lunges; useful chain count/damage remains available. |
| Skip/retry/exit | No delayed attack audio, popup, chain total or actor offset crosses the lifecycle boundary. |
| Cross-mode integration | Adventure, Test Mode and Practice use the same pacing and chain treatment at supported sizes. |

## Verification and review evidence

The [six final focused suites](../project/reports/p6_m7_flurry_verified_checks/summary.json) pass: `p6_m7_retrigger_flurry_test`, `p6_combat_presentation_test`, `p6_dance_recast_display_test`, `p6_effect_lifecycle_test`, `training_room_combat_view_test` and `attack_sfx_audio_test`. Tests cover ordinary and huge synthetic chains, exact damage/order, speed changes, frozen simulation time, skip, actual forced/natural Poison snapshots, delayed Readiness grants, zero/blocked/missed outcomes and audio cancellation. The synthetic 200-event chain is a presentation stress fixture, not a newly supported combat build or a change to recursion limits.

A subsequent diff review tightened Practice Skip so it cannot schedule fresh visual callbacks while draining the remaining events. [Three final affected checks](../project/reports/p6_m7_flurry_skip_verified/summary.json) pass for flurry, Practice combat and audio. The Practice test now proves a normally presented hit reacts, then asserts that Skip adds no reactions; its former expectation of animations during Skip was superseded. The motion captures precede only this guard/test change; actor position, timing and visuals are identical.

The [additional regression report](../project/reports/p6_m7_flurry_regression/summary.json) passes `p6_m7_t6_effect_display_test`. `combat_playback_test` retains its previously documented autosave assertion failure; its controller-ordering/timing checks do not introduce a new failure. The separate `p6_repeat_contracts_test` execution retains the six inherited pre-T2 signature failures already reproduced with the original code during T6. It inherits the same compatibility check from `p6_combat_ordering_test`; no frozen signatures or mechanics were changed to hide them.

The [final rendered motion suite](../project/reports/p6_m7_flurry_evidence/summary.json) passes across Adventure, Test Mode and Practice. Each mode has 83 actual captured viewport frames, assembled into a GIF using measured frame durations. Captures use a real resolver result with diagnostic 100% Retrigger Chance and known target artwork; the surrounding planning loadout is not an earned Adventure run. The samples include a 17-cast chain and ordered forced/natural Poison activity. Long outcome/count totals are synthetic layout stress at 1280×720, 1600×900 and 1920×1080. Reduced motion, a last-hit-at-window boundary, mid-chain skip and exit have separate checks.

The parent reviewed actual final Test/Adventure frames and the Practice contact sheet, plus the long 1280-wide Practice total. The chain count/total progresses while the displayed combat clock waits, slashes cross the visible target body, and the Practice total clears the Fight/Combat Log footer. Contact points account for transparent sprite margins. Earlier captures with absent enemy artwork, a stale test-harness countdown, or HUD/footer interference were superseded; they are not the final visual evidence. The separate deadline still demonstrates the final accent, not countdown accuracy; the main motion sequence provides the countdown evidence.

Motion previews:

- [Practice flurry](../project/reports/p6_m7_flurry_evidence/p6_m7_retrigger_flurry_visual/flurry_motion/practice_flurry.gif)
- [Adventure flurry](../project/reports/p6_m7_flurry_evidence/p6_m7_retrigger_flurry_visual/flurry_motion/adventure_flurry.gif)
- [Test Mode flurry](../project/reports/p6_m7_flurry_evidence/p6_m7_retrigger_flurry_visual/flurry_motion/test_flurry.gif)
- [Practice contact sheet](../project/reports/p6_m7_flurry_evidence/p6_m7_retrigger_flurry_visual/flurry_motion/practice_contact_sheet.png)

The test audio driver is Dummy. Audio-event counts/cancellation are verified, but these runs do not certify audible rhythm, mix or subjective feel. User playtesting of those qualities remains necessary. General certificate/resource-at-exit warnings remain with M9.

## Changed sources and preservation

Runtime changes are limited to `combat_playback.gd`, `combat_playback_presenter.gd`, `combat_presentation_state.gd`, `combat_effect_icons.gd`, `combat_stage.gd`, `training_room_combat_view.gd` and `audio_manager.gd`. Presentation observations now accept a sequence frontier; generic exact-deadline expiry waits for complete tied-record consumption. The stage owns the compact total and trails. Audio generation cancellation prevents old delayed hits crossing skip/retry/speed/exit boundaries; skipped Practice casts cannot create fresh delayed visual callbacks.

Added focused/motion tests and `tools/p6/run_retrigger_checks.py`; the existing presentation speed test now advances to the same simulation timestamp rather than assuming viewing time equals simulation time during a flurry. The runner uses disposable project copies, hidden windows and isolated APPDATA/LOCALAPPDATA. Its optional scratch reuse avoids copying old reports repeatedly.

[Preservation/fingerprints](../work/t7_before/verification.json) record the seven intentional runtime edits, unchanged original art/mechanics/data and 83 unchanged captured user-data files. Full diffs are retained beside that record. No commit, publication, new artwork or numerical tuning occurred.

[Final implementation manifest](../project/reports/p6_m7_flurry_evidence/implementation.json) consolidates exact source/test/runner fingerprints, fixture totals, report pointers and limitations. The captured real resolver fixture has 51 casts, 21 ticks and 2,359 damage; the displayed 17-cast chain is one root within that diagnostic result. [Parent review](../work/t7_before/parent_review.json) records final source/link/evidence checks separately from the worker handoff.

Reproduce with fresh report names:

```powershell
python tools/p6/run_retrigger_checks.py --report-name p6_m7_flurry_fresh --tests p6_m7_retrigger_flurry_test p6_combat_presentation_test p6_dance_recast_display_test p6_effect_lifecycle_test training_room_combat_view_test attack_sfx_audio_test
python tools/p6/run_retrigger_checks.py --report-name p6_m7_flurry_visual_fresh --visual --tests p6_m7_retrigger_flurry_visual
```

Restart a running game before playtesting to load the changed scripts. Review short and long chains at 1×/2×/4×, reduced motion, mixed Poison chains, intentional counters and skip/retry. Exact pacing values remain adjustable through user feedback; implementation authorization is distinct from final presentation acceptance.

## Remaining T7 scope

The known dense Assassin/Shadow popup overlap and player-facing delayed audio lifecycle require their own evidence. This retrigger deliverable may address related paths, but does not automatically establish full T7 acceptance. T8 integrated accessibility, T9 user playtesting, T10 refinement and T11 milestone regression remain downstream. General engine/certificate/shader/teardown qualification stays M9.
