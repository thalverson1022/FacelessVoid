# M5-T8 — Complete Shadow implementation

**D023 update (2026-10-06):** Touch is restored to +2 physical base per consumed Poison. Beguiling Presence also grants +2 percentage points crit chance per consumed Decay. Existing durations and 30-second cooldowns are retained. See [current verification](P6_Shadow_Presence_Crit_And_Touch_Update.md).

**D022 update (2026-10-06):** Touch of Darkness grants +1 base physical damage per consumed Poison (superseding D021’s +2), with its 12-second duration, +10% IAS per stack and 30-second cooldown retained. See [current verification](P6_Shadow_Touch_Damage_Update.md).

**D021 update (2026-10-06):** Dusk Strike also adds +10 Shred Value; Touch of Darkness now grants +2 base physical damage alongside +10% IAS per consumed Poison, both for 12 seconds. Its cooldown remains 30 seconds. Earlier duration descriptions below are historical. See [live verification](P6_Shadow_Touch_And_Shred_Update.md).

**D020 balance update:** Death Strike +2 damage per Poison stack, Death Blade 40/80% without extra crit, Death Touch +3/6/9 stacks supersede earlier values below. See [current verification](P6_Shadow_Death_Balance_Update.md).

**D019 balance update:** Coated Weapons now applies two base Poison stacks; earlier one-stack descriptions below are historical. See [current verification](P6_Shadow_Coated_Weapons_Update.md).

**2026-10-04 follow-up:** [D012 shared combat tuning](P6_Cooldown_And_Negative_Defense_Update.md) changes cooldown start times and negative-defense damage. DPS figures below remain historical, before D012. Talent rank coefficients are unchanged.

Status: **Complete** · 2026-10-03 · Authority: **P6M5-D011**, user approval of all four proposals ("everything looks good").

The [approved specification](P6M5_T8_Shadow_Design_Review.md) is playable in Test Mode and Practice: eleven talents / 35 ranks, the role-aware intrinsic, and five automatic skills. All four Rogue trees now have their complete ranked content. T9 mixed-tree consolidation, T10 combined player flows and T11 milestone closeout remain separate tasks.

## Implementation

Eleven explicit [Shadow resources](../project/data/p6/shadow/) and the [content adapter](../project/scripts/systems/playable_shadow_content.gd) preserve canonical IDs and source drafts. The revision is `p6.playable.shadow.1`, accepting the five preceding playable revisions. Adventure retains `p6.compat.1` and remains disabled. The immutable Assassin release manifest is the predecessor; D010's coefficients and live acceptance are preserved.

The approved 22% Beguiling Strike and 111% combined-base Death Strike descriptors are retained. Distilled Corruption has explicit 100% weapon scaling and Consume/conversion. Explicit validated carriers bind Death Pact, Death Blade, independent Dusk Shred and the 80-stack cap; ordinary modifiers, augments and derivations bind the other ranks. Duplicate passive sources fail validation. Prerequisites use Godot's typed string-array resource format. Temporary stat rebuilds retain carriers and recalculate Mastery's copy once.

All rank details and five skill descriptions are available in the established UI, using the approved icons. Death Strike's summary now states the single combined formula instead of implying two hits. Skill unlocks use 1/3/6/9/12 points in either role. Refund/reset prunes unavailable skills and preserves base skills. Practice supports either role and save/reload; Test Mode offers the full tree through its 45-point start.

## Acceptance evidence

| Area | Result |
|---|---|
| Complete allocation and combat | **5,319 checks pass** in [full-tree suite](../project/reports/p6_m5_t8_final_focused/p6_full_shadow_test_console.txt): every rank bought/refunded, both roles, derived stats and rebuilds, every unlock boundary, prerequisites, budget, invalid carriers, save codec, three partners in both roles. |
| Focused boundaries | **265 checks pass** in [boundary suite](../project/reports/p6_m5_t8_final_focused/p6_shadow_boundaries_test_console.txt): one-packet Death Strike at 0/1/20/80 Poison, no Consume, Distilled fuel/doubling/cap/no-refund, full block/dodge, unequal Dusk grants, Pact source-independent expiry, both Death Blade ranks and all-source Stab suppression, temporary Mastery expiry, duplicate-source rejection. |
| Determinism | 480 mixed combat cases: three partners × both roles × twenty seeds × neutral/dodge/cleanse/crit-negation targets. Each checks replay trace equality and trace-off outcome/RNG equality. |
| Player journeys | **145 checks pass** headless and rendered: Test Mode allocation/fight/restart, Practice allocation/fight/retry, keyboard capstone details, larger text, duplicate macro save/reload, reset/pruning. [Headless](../project/reports/p6_m5_t8_journey/checks.json), [rendered](../project/reports/p6_m5_t8_journey/visual-checks.json). Captures cover 1280×720, 1600×900 and 1920×1080; inspected enlarged tree and combat captures. |
| Regression | **73 distinct suites pass.** The [reconciled final report](../project/reports/p6_m5_t8_final/summary.json) combines the existing 68-suite baseline with new focused and live balance checks, retaining the exact source run for every result. |
| Isolation | [Final isolation report](../project/reports/p6_m5_t8_final/isolation.json) retains protected-save/project fingerprints from each accepted headless batch. The rendered journey also uses its own report-local saves. |
| Static release | Shadow/Assassin/Thief/Bladedancer predecessor chain, immutable drafts and compatibility resources, display catalog, approved review and coverage ledger checked in [static summary](../project/reports/p6_m5_t8_static/summary.json). |

The initial runs exposed and corrected a real prerequisite resource-format error. Test-only corrections fixed the partner's canonical Whetstone ID, a diagnostic decode-field name, and old three-tree count assertions. No historical manifest or compatibility fixture was rewritten. Root-certificate and teardown resource warnings remain inherited; accepted runs contain no script errors.

## Balance Lab reference

Eleven cohorts × **200 seeds** (1–200), 30 seconds, crude dagger only, zero gold, basic training dummy with enough HP to survive. [Full report](../project/reports/balance/shadow_t8/summary.json). Macro: **Beguiling Strike → Distilled Corruption → Beguiling Presence → Touch of Darkness → Stab → Death Strike**. Locked skills become Stab in lower-point cohorts. Allocation follows the review's ordered purchase list, including its full-rank prerequisites; these are explicit reference builds, not a reproduction of a user's Shadow setup.

| Shadow points | Mean DPS |
|---:|---:|
| 1 | 14.04 |
| 10 | 16.94 |
| 20 | 19.58 |
| 25 | 73.47 |
| 35 | 121.42 |

Full Shadow averages **77.54 direct DPS + 43.88 Poison DPS**. Primary Shadow 35 plus ten-point Bladedancer/Thief/Assassin averages 133.51/138.45/147.53; reversing roles gives 131.13/127.50/146.13. Each scenario includes its exact allocation/macro and seed-one trace, direct skill breakdown, proc count and actual consumption diagnostics. Seed one for the single-tree build consumes 32 Decay and ten Poison and produces five proc casts. The separately preserved D010 Assassin macro remains **498.43950 DPS** across 200 seeds.

These results establish a reproducible starting point, not balance acceptance or an optimized Shadow macro. The reference spends time on both consuming self buffs and often removes fuel that could support Death Strike. Macro alternatives, talent ablations and comparative tuning belong in a follow-up inquiry/M6; no unapproved numerical tuning was applied.

## Reproduction

```powershell
python tools/p6/run_foundation_tests.py --report-name p6_m5_t8_recheck p6_full_shadow_test p6_shadow_boundaries_test p6_full_shadow_journey_test p6_shadow_balance_test p6_assassin_balance_live_test
python tools/p6/check_shadow_release.py
python tools/p6/check_assassin_release.py
python tools/p6/check_thief_release.py
python tools/p6/check_bladedancer_release.py
python tools/p6/check_content_registry.py
python tools/p6/build_tree_display_catalog.py --check
python tools/p6/build_m5_coverage_ledger.py --check
python tools/p6/check_m5_shadow_review.py
```

The rendered journey runs the same test with `-- --visual`, an absolute workspace log path and report-local saves. Release hashes describe the current promoted sources; the pre-T8 source snapshot and pre-approval static report remain historical evidence.
