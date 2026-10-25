# M5-T10 Full-content player-flow acceptance

Status: Complete. Authority: user-directed T10 execution, current P6M5-D023 content. Date: 2026-10-06.

## Scope and acceptance matrix

All four Rogue trees are playable in Test Mode and Practice under `p6.playable.shadow.1`. Adventure remains disabled under `p6.compat.1`. The existing tree layout and styling remain the baseline. This accepts functional player flows; it does not approve final balance or complete M7 presentation.

| Journey | Evidence |
| --- | --- |
| Title entry, 10/45-point starts, all four full trees, role selection, rank descriptions and capstone details | Four `p6_full_*_journey_test` suites and `p6_t10_usability_test`, freshly run headless and rendered |
| Gates, prerequisites, refunds, unlock removal/reunlock, atomic rejected edits | `p6_ranked_build_test`, `p6_refund_dance_regression_test`, `p6_skill_ui_test`, plus actual UI rank purchases in combined journey |
| Six mixed pairings, both primary/secondary orders, 45 purchased ranks per pairing | New `p6_full_content_journey_test`: 12 ordered cases; role swap preserves allocation |
| Duplicate macro slots, right-click removal, ten-slot limit, pruning on reset | Per-tree and combined journeys; `rotation_cap_test` |
| Alternate gear grants retained while another source exists; removed after last source disappears | Combined Shadow/Umbral journey and replacement/custom/rarity/clear transitions |
| Combat, editing, retries, fresh gold/effect state, Thief rewards/shop rules | Per-tree/combined fights, `p6_thief_economy_test`, `training_room_fight_test`, `training_room_fight_setup_test`, `p6_combat_presentation_test` |
| Practice save, leave, reopen, roles/ranks/macro, equipment/seed/duration/configured gold | All per-tree journeys plus all 12 combined cases; persistence, persistence UI and save-boundary suites cover legacy/revision/corrupt/future files |
| Exact seeded Practice/Balance Lab agreement | All 12 combined cases compare damage using identical rank payload, target defenses, gear, configured gold, 30-second duration and seed 7; retries also compare stolen gold |
| Keyboard traversal/actions, tooltips, 125% text, reduced motion and effect overflow inspector | Fresh usability suite plus four full-tree rendered journeys at 1280×720, 1600×900 and 1920×1080 |

## Defect fixed

Practice gear changes emitted a build refresh without normalizing the existing rotation. Replacing Umbral Stiletto after resetting Shadow could leave Death Strike usable despite losing its last unlock source. `TrainingRoomState` now prunes the rotation after legendary replacement, switching to a custom weapon, equipping a rarity-selected practice item, and clearing a slot. Independent tree grants still preserve the skill. The combined journey exercises both retention and removal, including duplicate rotation editing and save/reopen.

The new harness initially carried rotation slots between cases and passed an untyped empty array to a typed setter. Those test-only mistakes were corrected by clearing slots through the actual removal control. The subsequent last-grant failure reproduced the runtime defect above. Final reports supersede those diagnostic runs.

## Evidence and reproduction

Validation passed: **25 runtime executions across 19 distinct suites, nine static checks, and twelve ordered mixed player-flow cases**. Both combined runs pass 3,243 assertions. Real saves and protected Enigma files are unchanged.

Final aggregate: [summary](../project/reports/p6_m5_t10_final/summary.json), [protected-file fingerprints](../project/reports/p6_m5_t10_final/isolation.json), [visual inspection record](../project/reports/p6_m5_t10_final/visual_review.json).

Fresh reports:

- [13 focused regression suites](../project/reports/p6_m5_t10_contracts/summary.json)
- [Five headless journeys](../project/reports/p6_m5_t10_journeys/summary.json)
- [Five rendered journeys](../project/reports/p6_m5_t10_rendered/summary.json)
- [Combined headless journey](../project/reports/p6_m5_t10_combined_headless/summary.json)
- [Combined rendered journey](../project/reports/p6_m5_t10_combined_rendered/summary.json)

Run from repository root:

```powershell
python tools/p6/run_foundation_tests.py --report-name p6_m5_t10_contracts p6_ranked_build_test p6_persistence_test p6_persistence_ui_test p6_save_boundary_integration_test p6_refund_dance_regression_test p6_skill_ui_test rotation_cap_test p6_thief_economy_test p6_combat_presentation_test p6_full_tree_display_test training_room_fight_setup_test training_room_fight_test p6_ui_cleanup_test
python tools/p6/run_m5_t10_journeys.py --report-name p6_m5_t10_journeys p6_full_bladedancer_journey_test p6_full_thief_journey_test p6_full_assassin_journey_test p6_full_shadow_journey_test p6_t10_usability_test
python tools/p6/run_m5_t10_journeys.py --visual --report-name p6_m5_t10_rendered p6_full_bladedancer_journey_test p6_full_thief_journey_test p6_full_assassin_journey_test p6_full_shadow_journey_test p6_t10_usability_test
python tools/p6/run_m5_t10_journeys.py --report-name p6_m5_t10_combined_headless p6_full_content_journey_test
python tools/p6/run_m5_t10_journeys.py --visual --report-name p6_m5_t10_combined_rendered p6_full_content_journey_test
python tools/p6/build_m5_coverage_ledger.py
python tools/p6/check_m5_t10.py
```

The journey runner copies each test into a separate report directory and rebases its save/report paths, preserving older acceptance artifacts. Final reconciliation verifies source hashes, twelve distinct ordered pairings, passing runs, protected files and nine current static checks. Screenshots provide sampled visual inspection alongside automated geometry checks; this is not a claim that every captured frame received manual review.

## T11 and downstream handoff

T11 remains open: run milestone-wide regression, reconcile all M5 acceptance evidence and compatibility/source records, record the repository checkpoint and publish the M6/M7 handoff. T10 focused coverage does not replace that milestone-wide pass.

M6 owns balance and Adventure progression. M7 owns dense damage-popup overlap, final effects/icons, readability/accessibility completion and audio polish. Busy combat screenshots still show overlapping damage labels; the functional effects inspector remains readable and scrollable. Rendered runs also log GLES3 shader-initialization errors, despite correctly rendered sampled frames and passing interaction/geometry checks. M9 must verify rendering startup on export/target hardware. Existing engine root-certificate and ObjectDB/resource teardown warnings remain downstream diagnostic work (M7/M9); no script errors are accepted by the runner. M9 owns packaging/export verification. No balance coefficients changed in T10.
