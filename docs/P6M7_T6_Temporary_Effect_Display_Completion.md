# M7-T6 — Temporary-effect display completion

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

2026-10-15. **Complete under user acceptance P6M7-D041.** The user tested the buffs, accepted the T6 changes and explicitly requested closeout. M7 remains In progress; T1–T6 Complete, T7–T11 Not started. The user requested the T6 audit, display/overflow improvements, lifecycle verification, cross-mode rendered checks and review. T5 remains complete under D039; T7 popup/audio work remains separate.

## Scope and current-state audit

The shared `CombatEffectIcons` control is used by Adventure/Test Mode combat and Practice. Its read-only presentation model observes ordered resolver events; display work must preserve combat calculations and authoritative consumption timing.

| Area | Starting behavior / concrete issue |
| --- | --- |
| Buff summary | Four 52px icon groups, stack totals and nearest-expiry radial timers. Independent instances are grouped; untimed stacks have no timer. Preserve installed artwork and the compact baseline. |
| Overflow (G07) | Additional groups are available through inspection, but the shrink-sized, clipped `+N` button can render without readable text. Every instance must remain reachable by mouse and keyboard. |
| Active versus spent display | Authoritative resources are spent at cast start. Display-only spent units remain until that cast resolves, including interruption. The starting inspector lists only active state and omits these held entries, creating a mismatch with visible chips. |
| Lifecycle | The model resets on begin/clear and clears effects on finish, but an open dialog needs explicit cleanup when a fight restarts or finishes. Focus should survive timer updates and recover when a focused effect disappears. |
| Timed defenses and statuses | Penetration/Potency retain their fixed HUD positions, inactive state and timers. Poison/Shred/Decay remain their existing counters. Validate relevant presentation without changing mechanics. |
| Text and assets | T5 effect wording is retained. No new effect identity is required for Riposte or Death Pact. |

## Accepted presentation

The shared control retains the existing four-icon row. Its overflow button now fits explicit `+N more` text rather than clipping a shrink-wrapped count; N counts additional effect types, while the inspector exposes every independent instance. This is a conservative repair of existing interaction, not adoption of the withdrawn T3 package or a permanent Effects button.

The inspector now includes active and display-only spent entries, numbered separately by effect type. Held entries say `Spent - held until impact`; their radial timer is suppressed because their visibility ends at resolution rather than the old buff deadline. When active and held entries coexist, the nearest-expiry clock follows active state. Dance and Master of Poisons chips count activations rather than interpreting a zero internal charge field as inactivity.

Begin, finish/skip and reset close an open inspector. Closing inspection restores the originating chip or overflow button where available, with a remaining-chip fallback if the effect disappeared. Timer-only updates preserve focus. The inspector uses the existing body font; rules, artwork and combat calculations remain unchanged. The user accepted this implemented treatment under D041. This does not adopt unrelated parts of the withdrawn T3 package.

## Verification and completion

The [final rendered T6 suite](../project/reports/p6_m7_t6_rendered_final/summary.json) passes, with unchanged source isolation and disposable per-suite save environments. It covers 54 combinations: Adventure/Test Mode/Practice × 1280×720/1600×900/1920×1080 × normal/125% effect-inspector and overflow text × 5/10/12 distinct groups. There are **114 PNGs**: 108 HUD/inspector pairs, three scrolled inspector views and three real resolver playback integration examples. The 125% stress applies to the changed overflow and inspector text; it is not a claim of full-screen text accessibility qualification.

The overflow matrix injects explicit test fixtures into real mode controls; the last two groups in the twelve-group fixture are synthetic and have no production artwork. These are not earned Adventure builds. Real resolver examples use the existing Bladedancer Core fixture, with one visible Footwork effect at the sampled time; dense coverage is synthetic. Independent same-kind timers, refresh, partial consumption, interruption/new grants and exact-deadline behavior are additionally checked by the existing presentation suite.

Four existing focused suites pass in the [focused final report](../project/reports/p6_m7_t6_focused_final/summary.json): `p6_combat_presentation_test`, `p6_dance_recast_display_test`, `p6_effect_lifecycle_test` and `training_room_combat_view_test`. That report's new T6 test failed an incomplete Practice fixture setup; use the later final rendered T6 pass for that test, not the failed focused result. Keyboard Enter/Escape opens and closes chip/overflow inspection with return focus; focused-effect expiry, held inspection after authoritative expiry, retry/reset, integrated skips and destruction on mode exit pass in the final T6 suite. Existing presentation checks cover simulation-time equivalence at 1×/2×/4×.

The parent inspected actual Test 1280/125% inspector and Practice 1280/125% inspector, then final Adventure 1280/125% HUD, Adventure 1600 normal inspector and Practice 1920/125% HUD. Overflow counts and text fit; scrolled content remains accessible. Initial Adventure captures were obscured by the story introduction despite passing geometry checks; the final fixture uses Proceed and asserts the introduction is closed before capturing. The superseded first rendered report is not final Adventure presentation evidence.

Example review captures: [Adventure overflow](../project/reports/p6_m7_t6_rendered_final/p6_m7_t6_effect_display_test/t6_effects/adventure_1280_12_hud_125.png), [Adventure inspector](../project/reports/p6_m7_t6_rendered_final/p6_m7_t6_effect_display_test/t6_effects/adventure_1600_10_inspector_100.png), [Practice overflow](../project/reports/p6_m7_t6_rendered_final/p6_m7_t6_effect_display_test/t6_effects/practice_1920_12_hud_125.png).

Use disposable project copies and isolated saves. Record focused results, actual renders inspected, source/protected-mechanics fingerprints and limitations here. Automated/rendered checks remain distinct from the user acceptance recorded above and do not establish the full T8–T9 accessibility/comprehension matrix. T8 owns full integrated accessibility review; T9 owns user playtesting; T7 owns damage-popup overlap and audio lifecycle.

The retained inspector refreshes at simulation-time 100ms buckets; chip/model updates occur on each playback advance. Full dense real-build comprehension and integrated accessibility remain T8–T9 work. Next: T7 combat cues and popup readability, including the user-reported jarring bursts during large retrigger chains and applicable audio lifecycle work. The suggested staggered/accelerating flurry, chain totals and finishing accents are discussion options; no timing values, design or mechanics change has been approved or implemented.

[Final fingerprint reconciliation](../work/t6_before/final_verification.json) confirms that the existing focused passes and final rendered pass used the current runtime script. Only `combat_effect_icons.gd` changed among captured preexisting project sources; the new T6 test supplies the additional coverage. All 1,341 captured protected mechanics/resource/autoload/data/art paths and 83 captured real user-data files are unchanged. Documentation updates are separate from that source snapshot. The runner uses a copied project and isolated APPDATA/LOCALAPPDATA; no commit or publication was performed. Existing certificate and teardown warnings retain their M9 owner.

Reproduce from the repository root with a fresh report name:

```powershell
python tools/p6/run_m6_closeout.py --report-name p6_m7_t6_review_fresh --visual --tests p6_m7_t6_effect_display_test
python tools/p6/run_m6_closeout.py --report-name p6_m7_t6_checks_fresh --tests p6_combat_presentation_test p6_dance_recast_display_test p6_effect_lifecycle_test training_room_combat_view_test
```

### Preliminary failures and retained test debt

Initial runs caught a Windows text-encoding error and an inferred-type compile error in the edited script; these were corrected before final validation. A new integration fixture also required complete Practice result/target setup. Preliminary reports remain evidence of failed attempts, not accepted passes.

`p6_status_completion_test` fails six inherited `pre-T2 signature` comparisons (seeds 1, 103, 11, 23, 42 and 7). The parent independently reproduced exactly these failures in a disposable project with the original pre-T6 effect script restored. [Baseline reproduction](../work/t6_before/status_completion_baseline/summary.json) and [console output](../work/t6_before/status_completion_baseline/console.txt). Neither combat values nor frozen signatures were changed to conceal this existing failure.


## D041 closeout and T7 handoff

2026-10-15: the user stated they are satisfied with the T6 results, accept the changes and want T6 closed. G07 overflow/inspection repairs and scoped G08 live-display validation are complete with the evidence above. The retained 100ms inspector refresh, synthetic dense coverage and inherited six signature failures remain explicitly documented; acceptance does not convert them into broader regression or real dense-build playtest evidence.

User feedback during buff testing: retriggers are enjoyable, but large chains produce a jarring instant explosion of events. Carry this to T7 as a presentation observation. The user suggested slower animation and requested design thoughts; the discussed pacing/flurry ideas remain proposals for later review. Popup overlap, audio lifecycle, integrated accessibility and broader player feedback keep their existing downstream owners. T7 has not started.

This closeout changes documentation only. Existing passing reports/fingerprints are rechecked rather than rerunning gameplay suites. See the [documentation closeout verification](../work/t6_before/d041_closeout_verification.json).
