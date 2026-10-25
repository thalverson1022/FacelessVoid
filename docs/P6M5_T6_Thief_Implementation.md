# P6M5-T6 — Complete Thief implementation

Status: **Complete** · 2026-10-03 · Authority: **P6M5-D004** and the user's instruction to implement T6.

The [approved T5 specification](P6M5_T5_Thief_Design_Review.md) is now playable in Test Mode and Practice: ten talents, all 35 ranks, four automatic skills, and an intentionally empty nine-point slot. T7 Assassin design review is next. Numerical balance remains M6; final full-content presentation remains M7.

## Refund fix and Dance cooldown verification — P6M5-D007

Talent gates now require sufficient points in strictly lower tiers of the same tree. Five lower-tier plus five upper-tier points cannot be reduced by refunding the lower tier first. Same-tier peers cannot support each other. Buy/refund/restore validation uses the same rule; full-tree resets remain allowed. This supersedes the original M2 total-tree retained-gate rule. Previously saved unsupported allocations are rejected by existing invalid-save handling; supported saves retain their existing content revisions.

The talent UI names the upper talent blocking a refund and leaves the build unchanged. Tests cover both roles, same-tier circular support, resets, real UI refund gestures, existing full-tree rank cases and persistence. Dance of Death needed no runtime fix: cooldown attempts take 100 ms, do not activate/refresh its five-second buff, and do not alter numeric retrigger chance. A still-active buff from the original successful cast continues to grant repeats; attacks started after expiry receive no Dance guarantee.

Evidence: [allocation suites](../project/reports/p6_refund_initial/summary.json), [Dance and player journeys](../project/reports/p6_refund_dance/summary.json), [UI refund feedback](../project/reports/p6_refund_ui_verified/summary.json), [updated foundation/save roundtrip](../project/reports/p6_refund_foundation_verified/summary.json). An intermediate run caught an old retained-gate assertion and a test variable type inference error; both fixtures were corrected. The intermediate and final foundation runs’ protected-save audits observed a changed live Practice file despite isolated test save paths; the final foundation behavioral assertions passed. No restoration or overwrite of that live file was attempted. Verified UI and Dance runs have unchanged protected-save fingerprints.

## Greed combat indicator

Added at the user’s request: Greed displays the credited stolen-gold total as stacks alongside player buffs in both combat views. Uses the supplied Rpg Icon Pack / Misc. Items / 2.png, copied unchanged into the project. It has no independent gameplay modifiers or timer; counts are not limited by Mug or Silvered caps. Resets with combat playback. [Focused evidence](../project/reports/p6_greed_fixed/summary.json); icon, presentation, Readiness and Thief journey suites also pass in [integration evidence](../project/reports/p6_greed/summary.json) (initial Greed test fixture omitted a timestamp; corrected in the focused rerun).

## Current tuning — P6M5-D008

Mug now adds **min(50, credited fight stolen gold)** bonus physical base damage. The cap is reached at 50 stolen gold; Greed remains an uncapped theft counter. Runtime, tooltips and the combat inspector use the skill descriptor. [Validation](../project/reports/p6_mug_cap50/summary.json).

## Historical tuning — P6M5-D006 (cap superseded by D008)

Mug is restored to **min(100, credited fight stolen gold)** bonus physical base damage. Pick Pocket remains **1.80 seconds / ten raw gold**. Runtime and live displays share this calculation. [Focused rerun](../project/reports/p6_mug_restore/summary.json).

## Historical post-T6 tuning — P6M5-D005 (Mug superseded by D006)

The user subsequently changed Pick Pocket to **1.80 seconds / ten raw gold** (minimum 0.80 seconds retained). Mug now adds **min(100, floor(credited fight theft / 2))** base damage: one gold gives zero; three gives one. Tooltips and combat presentation share the same calculation. These values supersede T5 examples and the original T6 evidence below. No save-schema or allocation changes are needed. Focused rerun evidence: [tuning tests](../project/reports/p6_thief_tuning/summary.json).

## Implementation

Nine explicit [Thief resources](../project/data/p6/thief/) supplement the existing Keen Eye resource. The [registry extension](../project/scripts/systems/playable_thief_content.gd) adds these resources and Pick Pocket at six points, the empty nine-point slot, and Big Score at twelve. Steal and Mug retain their one/three-point unlocks. All nodes are playable; no Thief preview nodes remain.

Ranked allocation copies validated Bribery and Finders Keepers fields into resolved passives. Existing derivation and gold systems implement Sticky Fingers, Fast Hands, Fill Your Pockets, Silvered Edge, Gilded Blade, Charisma and Loaded Dice. Tooltips describe current/next rank effects, source caps, eligible loot quality, price flooring, and the skill-specific category/critical rules. The stable `talent.thief.load_dice` ID is retained with the approved **Loaded Dice** name.

Sticky Fingers multiplies its own gold bucket by intrinsic and gear buckets. Fast Hands copies the final gold bonus into IAS. Fill Your Pockets uses its separate elemental multiplier, including gear Magic Find. Bribery grants stacks per positive credited theft event. Finders Keepers changes initial block; later defense changes remain independent. Silvered/Gilded retain separate source caps and live fight/stash accounting. Charisma uses existing shop rules and Loaded Dice uses existing quality-upgrade consumers.

## Access and persistence

Test Mode: choose the 45-point start, accept a contract and choose Thief as secondary. Practice: choose Thief in either role, allocate ranks, edit the macro and save the setup. Thirty-five points completes Thief, leaving ten for the other tree within the shared 45-point budget.

The new revision is `p6.playable.thief.1`; prior Bladedancer, mixed and core playable revisions remain accepted. Adventure stays disabled with `p6.compat.1`. All 79 compatibility resource hashes and original draft/identity hashes pass validation. The [release manifest](../project/data/p6/thief_release_manifest.json) fingerprints the nine resources and their binding sources. The historical Bladedancer manifest is preserved; its checker accepts the registry transition only through the fingerprinted successor and exact previous-manifest digest.

## Executed evidence

| Check | Result / evidence |
| --- | --- |
| Full Thief allocation, every rank including zero, primary/secondary roles, refunds, prerequisites, unlocks, reset, budget and malformed passive data | **2,492 checks pass**, including the additional gear/capstone composition cases; [focused report](../project/reports/p6_m5_t6_final_mechanics/summary.json), [test](../project/tests/p6_full_thief_test.gd) |
| Deterministic combat | 160 allocated mixed-build cases across both roles, 20 seeds and neutral/dodge/cleanse/crit-negation targets; repeated traces and trace-off outcome/RNG equality |
| Mixed capstones | Legal Blade 21 / Thief 24: Bribery plus Weakness/Virulent grants eight stacks at 135 each (1,080 armor reduction); extra-stack plus doubling gear grants 18 (2,430) |
| Shop and loot | **308 checks pass**; actual shop purchase, insufficient-gold rejection, additive discounts, one-gold floor, live Gilded after spending, all Loaded Dice ranks across 30 seeds, deterministic reward/shop quality and unchanged drop count; [report](../project/reports/p6_m5_t6_economy_fixed/summary.json), [test](../project/tests/p6_thief_economy_test.gd) |
| Player journey | **135 checks pass** headless and rendered: Title budget, Test Mode secondary, full tree allocation, Practice primary, macro duplicates, fight/retry, saved setup reload, reset/prune, keyboard details and 125% text geometry; [headless](../project/reports/p6_m5_t6_journey_run/summary.json), [rendered](../project/reports/p6_m5_t6_journey/visual-checks.json) |
| Regression | **65 suites pass**; core/mixed exact anchors, mechanics, persistence, UI, full Blade, Readiness macro and attack audio included; [summary](../project/reports/p6_m5_t6_regression/summary.json), [protected-save isolation](../project/reports/p6_m5_t6_regression/isolation.json) |
| Additional retained flows | Full Bladedancer journey, Phase 5 economy stats and gold-gain economy pass; [summary](../project/reports/p6_m5_t6_composition/summary.json) |
| Balance Lab | Two role configurations, 20 seeds each, repeated samples/aggregates identical; [results](../project/reports/p6_m5_t6/lab.json). Correctness evidence, not balance approval. |

The economy harness establishes a shop round through controller state; it does not claim a naturally completed contract journey into the shop. It exercises real purchase, pricing and offer/reward generation code. Shared boundary suites retain detailed zero-credit, repeat, cap, block/penetration, crit-negation and gold lifecycle cases.

Rendered captures cover 1280×720, 1600×900 and 1920×1080. Inspected the full tree, Loaded Dice details, 125% tree text and combat playback captures. New tree content and controls fit the accepted layout. Existing combat popup text can extend beyond the arena into the adjacent panel; full presentation polish remains M7. Existing certificate-store and UI teardown resource warnings remain recorded baseline limitations. No gameplay script errors occur in passing runs. An initial economy test stopped on an untyped array assignment; the harness was corrected and rerun successfully.

## Reproduction and static checks

Run `python tools/p6/run_foundation_tests.py --report-name p6_m5_t6_recheck p6_full_thief_test p6_thief_economy_test p6_full_thief_journey_test` from the repository root. The runner isolates protected saves.

Run `python tools/p6/check_thief_release.py`, `check_bladedancer_release.py`, `check_content_registry.py`, `check_bladedancer_core.py`, `check_mixed_build.py`, `check_m5_bladedancer_review.py`, `check_m5_thief_review.py`, and `build_m5_coverage_ledger.py --check` from their `tools/p6/` paths. The T5 checker keeps its original pre-promotion evidence and writes a separate post-promotion design recheck; it no longer claims unchanged gameplay after T6.

The updated [coverage ledger](P6M5_T2_Content_Coverage_Ledger.md) records 23 playable talents / 70 ranks and nine reachable planned skills. Assassin and Shadow remain assigned to T7/T8.
