# M9 T12 — Regression and M10 handoff

2026-10-29. **T12 and M9 Complete under D057.** The user authorized the scoped T12 plan after explicit T11 playtest acceptance under D056. The animation correction, scoped regression/legacy-test triage and this handoff are complete. The [M9 tracker](P6M9_Gear_Slot_Expansion_And_Progression_Pacing_Tracker.md) owns status; M10/M11 remain Not started.

## Accepted baseline

- Seven stable gear slots, including Pants below Chest and Gloves below Weapon. Approved equal Basic-stat weights and new-slot pools remain; no new rarity, reward-frequency, gold or enemy tuning.
- Twenty authored Legendary identities, including Arctic Mittens, Hands of the Lightning Lord, Golden Greeves and Serpent's Scales. Original artwork and the accepted four signatures remain.
- Adventure v5 / Practice v4 and shared epoch1 reset policy remain. Fresh Adventures start with only Crude Dagger. Test Mode remains session-only and Practice remains separate from Adventure.
- T11 user playtesting is accepted under D056. Current presentation includes character-stat sections, minimal Subclass summary, typed/indented combat events, category feedback/audio, focus backdrops below the system bar, sequential shop reveals, stronger shared shop/reward shimmer and a compact raised-dark/recessed-gold skip toggle. Skip defaults OFF on each launch and retains the selection between shops within that session. Gear hovers show only their own item details everywhere; equipped comparisons are hidden under D055.
- [T9](P6M9_T9_Mechanics_And_Reset_Verification.md) supplies combined mechanics/reset evidence; [T10](P6M9_T10_Focused_Progression_Review.md) supplies twelve progression paths/262 attempts. These are historical scoped results, not new T12 executions or global balance certification.

## Known animation defect and correction

The user rotation is Virulent Poison → Venom Jab → Blinding Powder ×2. Continuous rendered diagnosis found that a following weapon windup cancels the buff's returning F2/F1 in the same update, before those frames render. A subsequent blocked attempt can cancel the prior successful release; consecutive buffs at4× can mask the next raise. Resolver activation is on time.

The fix separates successful release ownership from the next windup. Failed attempts do not clear their predecessor's release; progress updates cannot restart an already-activated gesture. The pose-only clock advances at most one lowering interval per rendered process, including accelerated-tail scaling. Consecutive category raises fit into their remaining windup. An incoming weapon reserves the brief release, then follows authoritative playback progress for its art/lunge until impact; normal attack paths retain their timing. This also handles playback slowing after handoff without early idle. The owned impact selects the correct attack/contact frame, and skip/reduced motion/finish clear both pending and active ownership and restore idle appropriately. No resolver/damage/audio deadlines move.

Independent read-only review identified the scaled-step, post-handoff slowdown and cancellation/slow-frame contact edges during implementation. All were addressed; the final bounded source re-review reports no remaining blockers. Runtime verification is recorded below. Individual frames at arbitrary extreme speeds or low frame rates cannot all be guaranteed; a following cast can still supersede a weapon contact in the same playback update without moving gameplay deadlines.

## Regression and legacy-test triage

Run isolated checks proportional to seven-slot ownership/persistence and the accepted presentation changes. Record actual commands, source revisions, contributing passes and unresolved failures separately. Use disposable project copies and redirected APPDATA/LOCALAPPDATA plus explicit save paths; do not load/reset real profiles or sibling Enigma data. No live-save durability or export qualification follows.

The initial T12 snapshot is `work/m9_t12/before.json`, covering1055 runtime/content/art files. The [source audit](../project/reports/m9_t12_final/source_audit.json) finds exactly four changed presentation scripts: shared stage, category-preview controller, Adventure presenter and Practice view. No runtime files were added/removed; all data and artwork hashes remain unchanged. Core combat, economy, item generation and save-version/reset code are unchanged. Final contributing evidence is reconciled at closeout.

Legacy-test triage separates current defects from old assumptions:

- `reward_shop_route_ui_test` now awaits the actual visible shop/reward rollout before testing final state. `t9_item_presentation_test` now explicitly checks20 Legendary identities and seven slots, retaining item stats/effects and candidate-only tooltip checks. These are test repairs, not production-rule changes.
- The historical `combat_playback_test` build uses legacy allocation with the current ranked Adventure registry and is rejected with `Invalid build payload.` A directed compatibility check reproduces that rejection, then runs a current ranked Fight and verifies authoritative autosave plus validated reload. No current autosave defect was reproduced.
- `combat_hud_test` and `training_room_combat_view_test` are synchronous headless fixtures. Their visual invocations checked results before animated delivery; their intended headless runs pass. Actual rendered timing is covered by the new animation suite and current visual controls.
- `build_panels_test` retains obsolete two-card inventory comparisons and pre-seven-slot hierarchy expectations. Current gear/tooltip/talent/focus suites supply scoped coverage instead of rewriting its whole historical journey. Whole legacy playback and intermittent skipped-loss death-frame requalification remain M11 follow-ups; they are not claimed as passing.
- The copied-project runner now bounds failed-test termination and falls back to terminating only the captured process tree it launched, avoiding hangs after assertion failures.

## M10 integrated review checklist

These are handoff candidates for an agreed M10 plan, not additional T12 simulations:

1. Review representative full Adventures and unusual legal builds across the four Rogue trees, including primary/secondary combinations. Assess preparation, counters, meaningful replacements and late surplus against the accepted hard-game baseline.
2. Revisit discount/resale policy deliberately. T10 demonstrates legal positive buy/sell spreads because resale ignores price paid; this predates the slot expansion, and Golden Greeves supplies another route. Distinguish quoted opportunities, realized profit and reroll costs. Do not silently cap discounts or change ownership/save rules.
3. Assess earned-build exposure to the retained1024 per-root trigger budget and depth16 guard. T9 endpoint fixtures can exhaust it; small T10 observed maxima do not prove global headroom. Keep fail-closed handling and guards until an explicit design decision.
4. Check combined combat readability at high speed and in large chains, including category/attack transitions, poison critical/preservation feedback, Legendary ghosts, event ancestry and audio density. Animation-frame visibility at arbitrary low frame rates is not guaranteed by ordinary1×/4× checks.
5. Record any new findings with a concrete build/rotation/seed/mode and agree targeted changes. T11 acceptance should not be replaced by an automatic repeat playtest campaign.

M11 retains broader regression and engine/environment/export qualification, including Windows certificate-store and shutdown ObjectDB/resource diagnostics, validated packaging if requested, and crash/power-loss durability limits. Deferred M8-D099 expanded balance work stays deferred.

## Closeout

[Parent closeout verification](../project/reports/m9_t12_final/verification.json) reconciles the contributing reports, current source hashes, original1055-file snapshot and independent review. The [regression summary](../project/reports/m9_t12_regression_final/summary.json) selects **21 passing suites**, with all selected test hashes matching current sources:

| Area | Passing suites | Coverage |
| --- | ---: | --- |
| Mechanics, ownership and persistence | 6 | Combined seven-slot mechanics, four signatures, ownership/economy, current save validation, isolated reset and normal entry. |
| Current gear and presentation | 7 | Seven-slot UI, own-item-only inventory/shop/reward/Practice tooltips, shop reveal/skip/reroll, Chaos editor, focus/backdrops and full Practice talent-tree fit. |
| Repaired catalog and route fixtures | 2 |20 fixed identities/seven slots and real sequential shop/reward final-state assertions. |
| Autosave compatibility/current Fight | 1 | Rejected historical legacy allocation and current ranked authoritative save/load. |
| Synchronous headless controls | 2 | Combat HUD and Practice playback fixtures in their intended execution mode. |
| Final rendered combat controls | 3 | Retrigger flurries, all Debuff feedback and Self Buff feedback against the final frozen presentation revision. |

The [animation verification](../project/reports/m9_t12_animation_capture_verified/verification.json) records **28 continuous rendered cases plus the9-skill/36-case category matrix**, including the user's complete four-slot rotation, physical/Poison transitions, blocked attempts, consecutive buffs and speed changes. Two final cleanup corrections followed that full matrix: reserved ownership cancellation and correct impact art when no progress callback intervenes. The final revision passes8 targeted cases,4 complete user-rotation capture cases and2 scaled-tail API stress cases. Each contributing revision and executed test source is recorded explicitly; this is not a claim that every matrix was rerun after every narrow edit. Capture readbacks ran during playback; PNG encoding/writes occurred after each case. The failed earlier synchronous-PNG instrumentation is excluded. The API8× stress is beyond the selected1×/4× UI scope.

Parent inspected actual F2→F1 release images and the second Powder release at4×. The rendered Adventure-labelled fixture uses the shared Adventure/Test presenter, rather than a fresh full Adventure playthrough. Independent final source review has [no remaining blockers](../project/reports/m9_t12_final/independent_review.json). Final integrated combat controls and targeted animation runs share the same stage hash; the final1893-file copied runtime manifest matches the workspace. Earlier core/UI runs predate animation freeze and establish their unchanged component behavior, not final animation coverage.

[Legacy triage](../project/reports/m9_t12_regression_final/legacy_triage.json) and [all attempted regression rows](../project/reports/m9_t12_regression_final/all_attempts.json) retain failures and superseding evidence. No unexpected script/render diagnostics remain in selected passing checks. Windows certificate-store and shutdown ObjectDB/resource diagnostics remain as documented environment/qualification limits.

No real player profile or sibling Enigma data was a validation target; tests used isolated paths and user-data directories. No whole-profile hash comparison, full-run balance rerun, export qualification or crash/power-loss guarantee is claimed. No additional user acceptance gate is needed for these authorized fixes/checks; T11 acceptance remains explicit. **T12 and M9 are Complete. M10 and M11 are Not started.**
