# M6-T7 — Rewards, gear and economy assessment

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. [Current context](../../P6_Project_Onboarding_Context.md).

2026-10-07. **T7 assessment complete; no new numerical change proposed or applied. T6 remains In progress.** This completes the requested economy investigation and returns concrete matchup evidence to T6. Adventure remains disabled. This is automated assessment, not T9 hands-on validation or T10 balance acceptance.

## What was measured

The current D007 Steal and D008 armor baseline was exercised through actual combat and BuildState progression. There are **128 seeded trajectories, 5,189 combat attempts, 139 retries and 4,942 victories** in the primary evidence. Runs stop at actual failure or completion of C20. Rewards require victories; stolen gold survives losses and retries; reward claims are checked against duplication. No later gear or points are borrowed from assumed victories.

The matched cohort is four primaries × three spending policies × eight roots (84001–84008). Representative pairs are Bladedancer/Thief, Thief/Assassin, Assassin/Shadow and Shadow/Bladedancer. Another 32 typical-policy runs cover the other eight ordered pairs using 94001–94004. These are role-pair controls; secondary talent investment occurs only when the primary-first policy exceeds 35 points. Surviving runs are a selected subset, not an unbiased sample of late-game performance.

Policies are deliberately fixed and are **not population percentiles**:

- **Weak:** accept improving earned loot; no shop purchases or rerolls.
- **Typical:** at most one affordable, proxy-scored improvement per shop; no rerolls.
- **Strong:** up to six shop decision steps, buying affordable improvements and allowing one reroll when no affordable improvement remains, with at least 18 gold left after its cost. A reroll uses one decision step.

All policies sell rejected inventory, use visible identified items and the same documented gear-scoring proxy inherited from T4. The proxy is not exact skill-specific DPS and does not model saving gear for future builds. Shop item scores account for gold spent. Routes use the first legal offered contract and first connected route choice, without selecting routes by hidden enemy statistics.

Tavern allocations follow the previously tested monotonic T5 paths. At legal contract offers, builds respec to the protocol's primary-first allocation; C1 uses the established Wet Stone 5/Precision Attacks 1 Bladedancer and Sticky Fingers 5/Fast Hands 1 Thief controls. Allocation never refunds inside a contract. Macros are chosen from a bounded shortlist using independent training seeds 1101–1102, including the reviewed Tavern rotation and Thief permutations. Actual fights use the Adventure RNG seed and retry API. This simulation-informed policy is not a claim about ordinary player behavior or the optimal build.

## Progression and affordability

| Primary | Policy | Cleared C1 | Cleared C10 | Cleared C20 | Median ending gold |
| --- | --- | ---: | ---: | ---: | ---: |
| Bladedancer | weak | 5/8 | 1/8 | 0/8 | 368 |
| Bladedancer | typical | 8/8 | 4/8 | 1/8 | 2,367 |
| Bladedancer | strong | 8/8 | 5/8 | 2/8 | 4,295 |
| Thief | weak | 0/8 | 0/8 | 0/8 | 86 |
| Thief | typical | 6/8 | 5/8 | 2/8 | 63,340 |
| Thief | strong | 7/8 | 6/8 | 6/8 | 131,811 |
| Assassin | weak | 5/8 | 5/8 | 1/8 | 4,723 |
| Assassin | typical | 8/8 | 8/8 | 3/8 | 6,886 |
| Assassin | strong | 8/8 | 8/8 | 2/8 | 6,982 |
| Shadow | weak | 6/8 | 1/8 | 0/8 | 964 |
| Shadow | typical | 8/8 | 1/8 | 0/8 | 1,627 |
| Shadow | strong | 8/8 | 0/8 | 0/8 | 1,761 |

Ending balances combine different run lengths and must not be compared as equal-duration income rates. Exact purchases, prices, sales, rerolls, reward credits, theft, starting gear, ranks and fight outcomes are retained in each JSON ledger. Talent milestones remain 1/0/2/3 in the Tavern, six at C1, three per completed contract, and 45 after C13. Every recorded contract fight checks its earned budget, and surviving runs exercise the cap.

The spending policies materially affect acquisition and survival, but buying more does not guarantee a better result on every seed. Bladedancer typical clears C10 on four roots and strong on five; strong also loses earlier than typical on some roots. The same proxy can favor different gear sequences after purchases or rerolls. This does not prove that a player should avoid upgrades.

The evidence does **not** support a blanket reward increase as the remedy for early walls. Some failed runs have substantial unspent funds. Conversely, the no-shopping control is deliberately restrictive and cannot establish ordinary affordability. Late survivors accumulate much more gold than these limited shop policies spend; price pressure and useful item availability should be assessed separately in hands-on T9/T10 work before proposing a price increase or new sink.

## Thief and gold feedback

Across the matched Thief runs, theft credits total 421,673; 7,573 of those credits occur on losses and remain available. These totals span different run lengths. Typical Thief reaches C20 on two roots, strong on six, while the weak control stops in the Tavern on all eight. This identifies a strong acquisition dependence rather than resolving every C1 matchup.

As an isolated diagnostic, each real fight was replayed with the same gear, ranks, macro and RNG seed but zero starting bank. Among 367 matched Thief attempts at C10 or later, damage changes in 363, and 84 actual victories become losses. This shows that carried gold matters; it is not an alternative run or an estimate of the effect of a particular purchase. Gear can create gold-dependent damage in other primaries too. The gold-contract regression separately checks the existing Gilded counted-stash cap of 500, Silvered Edge contribution caps, transaction flooring, Increased Gold and separation of carried versus fight-stolen gold. No cap or theft value is changed.

## Adopted armor and Shadow income

Eight matched typical Shadow trajectories compare current armor 140 with historical armor 160 on an in-memory retained encounter resource. All other inputs and policies are fixed. Historical controls are kept separate and do not alter a saved resource.

| Root | Buddy raw overkill gold, old → current | Buddy credited reward | Contracts completed | Purchase sequence |
| --- | ---: | ---: | ---: | --- |
| 84001 | 0 → 0 | 18 → 18 | 6 → 6 | Same |
| 84002 | 0 → 0 | 18 → 18 | 6 → 6 | Same |
| 84003 | 0 → 0 | 18 → 18 | 5 → 5 | Same |
| 84004 | 10 → 10 | 28 → 28 | 3 → 3 | Same |
| 84005 | 0 → 0 | 18 → 18 | 6 → 6 | Same |
| 84006 | 0 → 0 | 18 → 18 | 6 → 6 | Same |
| 84007 | 0 → 10 | 18 → 28 | 11 → 11 | Same |
| 84008 | 0 → 0 | 18 → 18 | 3 → 3 | Same |

This is the cumulative follow-up to T6's +1.8 mean raw overkill-gold observation in its different 100-root cohort. These eight roots do not replace that estimate or establish an economy-wide rate. Any unchanged trajectories are evidence only for these fixed policies and roots.

## T6 matchup handoff

The following controls take the **first actually reached** C1/C4/C6/C10 build from typical-policy trajectories and replay the original flagged T6 enemies. Selection uses training seeds 1101–1102, followed by 20 fresh roots 207001–207020 per acquired build. Retries retain theft and do not change gear or ranks. These crossed encounters are diagnostics, not additional victories in the source trajectories.

| Primary / stage | Original T6 encounter | Acquired builds | First wins | Wins within two |
| --- | --- | ---: | ---: | ---: |
| Thief C1 | `C1_7001_route.generated_503030985.main_road` | 7 | 140/140 | 140/140 |
| Thief C1 | `C1_7001_route.generated_503030985.pressure_fight` | 7 | 140/140 | 140/140 |
| Thief C1 | `C1_7001_route.generated_503030985.toll_fight` | 7 | 67/140 | 85/140 |
| Thief C1 | `C1_85016_route.generated_360937729.boss` | 7 | 37/140 | 64/140 |
| Shadow C4 | `C4_7001_route.generated_503030985.boss` | 8 | 87/160 | 92/160 |
| Shadow C6 | `C6_7001_route.generated_503030985.boss` | 6 | 28/120 | 29/120 |
| Bladedancer C10 | `C10_7001_route.generated_503030985.boss` | 4 | 80/80 | 80/80 |

The detailed rows retain every acquired snapshot and per-root result. The Thief toll encounter remains 85/140 within two attempts and the flagged boss 64/140, while the two other captain controls are 140/140 each. All four Bladedancer builds that actually reach C10 beat the flagged boss (80/80); this is survivor-selected evidence and does not rescue the original weak conditional history or the four typical runs that fail earlier.

Shadow is sensitive to allocation as well as gear. The acquired baseline builds win 92/160 at C4 and 29/120 at C6 within two attempts. A separate same-gear control using T5's previously optimized checkpoint allocations records 92/160 and 106/120 respectively. Those allocations are legal alternatives at the incoming contract offer; gear was not retroactively reacquired. Therefore the low baseline C6 result alone is not a sound reason for an enemy nerf.

An adaptive follow-up reruns eight complete Shadow typical trajectories, choosing those prior T5 allocations wherever a checkpoint allocation exists. It clears C10 on two roots rather than one, retains a median of six completed contracts, and still reaches C20 on none. This is a changed build policy on reused roots, not independent confirmation or an isolated C6 effect. Its 265 combat attempts and 4,412 independent ledger checks are reported separately from the 128-run cohort.

These controls do not make the original 7001/85016 graphs occur naturally in every trajectory. Early failures censor later-stage coverage, and roots reused across policies are not independent samples. T6 must retain the Thief C1, Shadow C4/C6 and Bladedancer C10 findings until their matchup dispositions are resolved. No generated HP, timing, cleanse, suppression or scaling values are selected for adoption by this assessment.

## Verification and next owners

The independent ledger verifier passes 89,158 checks across the 128 trajectories, covering balance conservation, victory-only rewards, retry retention, unchanged retry builds, earned point budgets, overkill bounds, all twelve ordered role pairs and armor-control inputs. One complete Bladedancer trajectory reproduces exactly, including its event ledger. The targeted matchup harness passes 6,407 checks. Encounter reward, gold-contract, full-Thief and mixed-journey regression suites pass. The source-copy comparison and 1,088 current source/data/test/scene fingerprints match; existing gameplay source and historical evidence are preserved. Isolated APPDATA and session-only saves were used.

Pilot results and rejected harness runs are excluded. Harness corrections included the missing reviewed Bladedancer macro, a fully qualified Thief talent ID, and retaining the historical encounter resource so the armor control actually persists. Accepted reports are checked for their actual inputs. Existing certificate-store and shutdown resource warnings remain; accepted runs have no script/assertion failures.

- **T6:** use the acquired-build matchup evidence for remaining enemy/gear interactions; prepare a specific measured candidate before any further numerical change.
- **T8:** integrate the reviewed registry and ordinary Adventure flow, including persistence/access gates. The harness does not enable Adventure.
- **T9/T10:** test ordinary gear decisions, poor-gear recovery, useful spending choices, late reserves and player experience. The C30 prototype limit and future Road/endless scope remain unchanged.

No approval is pending because no additional balance change is proposed. T7 completion here records assessment and verification, not acceptance of smooth progression through C10.

## Reproduction

Use an isolated current project copy with the existing T5, T4 Tavern and T6 report dependencies and Godot 4.7. Set APPDATA to an isolated directory. Run `--headless --path <copy> --log-file <absolute unique log> -s res://scripts/tools/run_m6_t7.gd -- --tree=<primary> --secondary=<secondary> --policy=<weak|typical|strong> --seed=<root>`. Default horizon is 20. Cohorts and policies are recorded above and in `protocol.json`.

Run `run_m6_t7_control.gd` for the eight Shadow typical roots (historical armor), `run_m6_t7_replay.gd` for Bladedancer/Thief typical 84001, then `run_m6_t7_matchups.gd` and `run_m6_t7_shadow_builds.gd`. Use `run_m6_t7_shadow_policy.gd` for the eight Shadow typical roots to reproduce the adaptive allocation-policy follow-up. Run `python tools/p6/verify_m6_t7.py <copy>/reports/p6_m6_t7/final`; repeat with the `shadow_armor160` and `shadow_policy` folders for their separate ledgers. Run the four regression scripts named above separately against isolated saves. Reports are under `project/reports/p6_m6_t7/`; the main assessment is also retained there as `results.md`.
