# M7-T11 — Closeout and M8 Handoff

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

> Current roadmap update (2026-10-17, [P6M8-D001](archive/m8/P6M8_Decision_And_Execution_History.md#decision-log)): Legendary Item Revamp and Expansion is now Phase 6 M8. Former M8 integrated playtest/refinement is M9; former M9 regression/closeout is M10. The historical record below retains its original numbering and deferrals; the next-phase Legendary deferral is superseded. M9 owns inherited fixture/signature reconciliation; M10 owns broad regression and engine/export qualification. No item design or experimental Bandit curve is adopted by this update.

2026-10-17. **Complete under D053. M7 Complete, T1–T11 Complete.** Final presentation acceptance remains the user’s explicit D052 approval, including its recorded limits. T11 completes scoped regression, exception triage, asset/source reconciliation and handoff. M8 and M9 remain Not started.

## Retained playable baseline

All four Rogue trees remain playable: 44 talents / 140 ranks and 23 skills. Adventure uses `p6.adventure.1`; Practice/Test internals use their established ranked content. Current values, hard counters, finite prototype progression and separate Legendary-remake ownership remain intact.

Retain the accepted original tree backgrounds and artwork; Flat charcoal icons and category treatments; minimal skill/talent hovers with gold scaling values and cyan named Buff references; shared Active Talents; compact temporary-effect groups and independent active/held inspection. Combat uses anchored main actors and faded follow-up ghosts, lighter impact labels, paced contacts, up to sixteen visible strikes including opener, bounded outcome/Poison lanes and cancelled stale exit audio. D046 listening acceptance remains valid; T11 audio checks use Dummy routing rather than a new human listening session.

Adventure retains hidden main-menu Test Mode and map Archetype guide, Tavern-planning refunds, and automatic Talent Trees before first/later offers after reward/shop progression. Intermediate Tavern shops keep their normal next-encounter path. Active-contract refunds stay locked; earned secondary selection and save/load flow remain. Test Mode exists internally for verification. No new global text-size/reduced-motion setting or experimental combat-log adoption is implied.

## Final verification

[Consolidated summary](../project/reports/p6_m7_t11_closeout/summary.json) and [selected checks](../project/reports/p6_m7_t11_closeout/selected_checks.json) identify **27 distinct passing current suites and three retained legacy failing suites**. This is not an entirely green historical suite. Earlier failures and diagnostic attempts are preserved; successful retries supersede only their matching setup/test cases.

| Coverage | Result / evidence |
| --- | --- |
| Ranked allocation/progression/refund, replay/presentation/effect/audio routing | Selected affected checks pass. Ranked suite includes 121 fixture/boundary/resolution/rotation cases. [Regression](../project/reports/p6_m7_t11_regression/summary.json), [ranked retry](../project/reports/p6_m7_t11_ranked_retry/summary.json), [final popup rerun](../project/reports/p6_m7_t11_popup_final/summary.json). |
| Persistence and isolation | Scalar/current save/load, malformed payload rejection, Practice isolation, UI/boundary, Adventure preparation and secondary selection pass. [Persistence retry](../project/reports/p6_m7_t11_persistence_retry/summary.json), [flow/save UI render](../project/reports/p6_m7_t11_rendered/summary.json). |
| Real Fight autosave before playback | Ten checks pass using a valid current ranked Adventure build and controlled target. Playback remains active while resolved result/history is saved; that envelope reloads successfully. [Companion test](../project/reports/p6_m7_t11_current_autosave_pass/summary.json), [saved outcome evidence](../project/reports/p6_m7_t11_current_autosave_pass/p6_m7_t11_current_autosave_test/current_autosave.json). |
| Final integrated UI | Three modes × three physical sizes × normal/diagnostic125%: 900 checks pass. Footer supplement: 216 checks pass. Rendered icon assignment also passes; **222 PNGs** in the final guarded-layout batch. [Final rendered run](../project/reports/p6_m7_t11_rendered_final/summary.json). |
| Asset/tooling coverage | All 93 identities / 84 live texture paths match installed hashes: 44 talents, 23 skills, ten buffs, five statuses and eleven defenses. Icon Lab fresh at 93 identities / 585 library assets; all seventeen model/catalog checks pass. Library count includes retained art and framed assets, not 585 live identities. [Asset reconciliation](../work/t11_before/asset_reconciliation.json), [tooling](../work/t11_before/tooling_validation.json). |

The final integrated/footer frames supersede affected earlier popup frames. Other unchanged flow/save surfaces retain their earlier T11 evidence; no identical whole-source revision is claimed for every image. Parent independently inspected final Adventure HUD, internal Test resolver playback, Practice diagnostic125% footer and the post-shop talent step. Worker inspected additional tree/header/inspector views. Dense effects/special outcomes include disclosed fixtures; these are not new human playtests or balance trajectories.

## Bounded repairs and exception triage

T11 found a repeated Godot metadata error: shared Adventure/Test popup layers lack Practice’s optional `footer_row`. A one-line `has_meta` guard preserves placement and removes those diagnostics. Three affected focused suites and the final integrated/footer/icon run pass; final consoles contain zero missing-footer errors. [Exact runtime diff](../work/t11_before/runtime_change.diff).

The scalar persistence fixture predated D024 and tried to grant an Adventure secondary through a now-forbidden player API. The test now explicitly models an already-earned secondary in its two-tree compatibility registry. Original serialization, invalid-rank, rotation and rejection assertions remain; production guards are unchanged. [Fixture diff](../work/t11_before/persistence_fixture.diff). Initial ranked failure was a missing isolated docs-fixture dependency; copying only those required fixture inputs resolves it.

[Explicit exception register](../project/reports/p6_m7_t11_closeout/exceptions.json):

| Exception | Diagnosis and owner |
| --- | --- |
| `combat_playback_test` autosave assertion | Raw legacy Rogue fixture encodes `allocation_mode=legacy` against a ranked Adventure registry; current validator correctly returns `Invalid build payload`. [Probe](../project/reports/p6_m7_t11_legacy_probe/p6_m7_t11_legacy_probe/legacy_probe.json). Original suite remains failed; the current real-Fight autosave companion passes. M8 test-fixture modernization, tracked into M9 regression. |
| `p6_combat_ordering_test` / `p6_status_completion_test` | Each reproduces the same six inherited pre-T2 signature mismatches: seeds 1, 103, 11, 23, 42 and 7; no additional assertion failures found. Earlier original-script [baseline reproduction](../work/t6_before/status_completion_baseline/summary.json) remains. No goldens or mechanics changed to hide failures. M8 compatibility/expectation reconciliation, tracked into M9 regression. |
| Certificate-store and resource/ObjectDB shutdown diagnostics | Retained M9 engine/environment/clean-teardown/export qualification. No power-loss durability or export certification claimed by M7. |

## Preservation and reproducibility

[Repository checkpoint](P6M7_T11_Repository_Checkpoint.json) records branch `phase-6-skill-tree-redesign`, HEAD and the inherited dirty state. **Git HEAD alone is not this playable revision.** [Manifest](../project/reports/p6_m7_t11_closeout/manifest.json) records 2,820 source/asset/test/tooling paths. Of 2,818 task-start paths, 2,816 remain unchanged: only the popup helper and persistence fixture changed; two bounded test scripts were added. Original art, data, combat calculations and player configurations were not edited. No commit, publication, export or sibling-Enigma change was performed.

Every engine run records scratch APPDATA/LOCALAPPDATA and redirected Adventure/Practice save paths. No real userdata was read, copied or written; concurrent player activity is not asserted unchanged. [Worker commands, source maps, isolation and samples](../work/t11_regression/evidence.json) plus parent reconciliation accompany the results. Final worker source hashes and compared scratch sources match current files.

Reproduce with fresh report names through `tools/p6/run_retrigger_checks.py`; exact engine commands are in each selected summary. Ranked fixture checks also require their recorded docs JSON dependencies in scratch. A bounded current check is:

```powershell
python tools/p6/run_retrigger_checks.py --report-name p6_m7_review_autosave_fresh --tests p6_m7_t11_current_autosave_test
python tools/p6/run_retrigger_checks.py --report-name p6_m7_review_visual_fresh --visual --tests p6_m7_t8_integrated_test p6_m7_t8_footer_visual icon_assignment_test
```

## M8 handoff and retained limits

M8 should first agree a representative full-run/unusual-build checklist, then collect actual earned build/ranks, gear/gold, macro, seed/checkpoint, route/tag choices and retry outcomes. Assess preparation friction, pacing, surprising losses and informed counters; distinguish unclear information, defects and balance concerns before tuning. No unresolved user-reported M7 refinement remains.

M8 also owns the legacy test-fixture/signature reconciliation above and any future reduced-motion discoverability/global-accessibility UX work. Current reduced motion remains inspector-accessed, session-only and unavailable from the hidden no-effect row. T8/T11 125% is diagnostic stress, not a shipping global text setting. Detailed complementary/all-mode human sessions remain unspecified under accepted T9 limits. Screen-reader/controller/all-color-vision certification is not supplied.

Legendary power/Bandit hoarding remains in the [separate remake handoff](P6_Legendary_Remake_Next_Phase_Handoff.md). M9 owns broad Phase 6 regression, environment/exports and optional packaging. M8 is next for planning; this closeout does not automatically start it or add unrequested balance changes.
