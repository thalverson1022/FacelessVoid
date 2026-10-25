# T6 reassessment after T7

2026-10-08. **Reassessment complete; T6 remains In progress. No gameplay values changed and no approval is pending.** D008 Drunk Buddy armor 140 is retained.

T7 materially changes the priority of the remaining enemy work. Hold Bladedancer C10 enemy values, deprioritize a broad Shadow C6 nerf, and focus the next generator-level investigation on Thief C1 and the unresolved Shadow C4 gear/matchup interaction.

## Fresh controlled results

This pass uses actual earned gear from T7, the seven reached Thief C1 builds, eight Shadow C4 builds, six Shadow C6 builds, and four Bladedancer C10 builds. Shadow uses T5's optimized checkpoint allocations as reconstructed in T7's same-gear controls. Macros are frozen from those earlier controls, selected on independent training roots 1101–1102. Validation uses fresh roots 208001–208040 with actual fight-key retry seeding, retained theft and no retry respec or equipment change.

There are **4,640 first attempts and 1,319 retries**, 11,982 harness checks, and 9,280 independent outcome checks. Roots are paired across arms and reused across gear histories; these are controlled comparisons, not 4,640 independent runs. Candidate monsters are duplicated in memory. No generated or authored resource is saved with candidate values.

| Matchup | Candidate | HP | Wins within two | Worst acquired build |
| --- | --- | ---: | ---: | ---: |
| Bladedancer C10 boss | baseline | 14067 | 160/160 | 40/40 |
| Shadow C4 boss | baseline | 2377 | 192/320 | 0/40 |
| Shadow C4 boss | hp90 | 2139 | 244/320 | 7/40 |
| Shadow C4 boss | hp80 | 1902 | 270/320 | 10/40 |
| Shadow C4 boss | cleanse6 | 2377 | 237/320 | 8/40 |
| Shadow C6 boss | baseline | 4190 | 216/240 | 27/40 |
| Shadow C6 boss | hp90 | 3771 | 236/240 | 37/40 |
| Shadow C6 boss | hp80 | 3352 | 240/240 | 40/40 |
| Shadow C6 boss | cleanse6 | 4190 | 227/240 | 33/40 |
| Thief C1 toll | baseline | 278 | 160/280 | 6/40 |
| Thief C1 toll | hp90 | 250 | 239/280 | 27/40 |
| Thief C1 toll | hp80 | 222 | 277/280 | 37/40 |
| Thief C1 toll | duration_floor | 216 | 280/280 | 40/40 |
| Thief C1 boss | baseline | 1109 | 119/280 | 5/40 |
| Thief C1 boss | hp90 | 998 | 238/280 | 26/40 |
| Thief C1 boss | hp80 | 887 | 279/280 | 39/40 |
| Thief C1 boss | cleanse6 | 1109 | 119/280 | 5/40 |

`hp90` and `hp80` retain 90% and 80% of baseline HP, rounded. `cleanse6` changes an existing cleanse threshold from four to six; it does not add cleanse to enemies without it. `duration_floor` scales the toll monster's HP from 278 to 216 using its actual 14-second window divided by its 18-second HP-budget window. It is a proportional diagnostic, not a regenerated contract.

## Disposition and recommendation

1. **Bladedancer C10: retain enemy values.** All four actually reached typical builds win all 160 fresh trials. The original weak conditional history remains a gear/recovery warning, not evidence for reducing this boss's HP. Earlier failed runs never reach this control; this does not establish universal C10 viability. Carry poor-gear recovery into T9/T10 rather than select an enemy nerf from survivor-only results.
2. **Shadow C6: no broad nerf selected.** Optimized allocations yield 216/240 within two attempts, with the weakest build at 27/40. A 10% HP cut improves this to 236/240, but that improvement alone does not justify tuning to a percentage. The earlier severe baseline weakness was substantially allocation-dependent. Retain this matchup as a secondary validation control while resolving C4 and checking ordinary build choices.
3. **Thief C1 toll: leading candidate is correcting short-window HP budgeting.** The floor-aligned diagnostic reaches 280/280, versus 160/280 baseline. A 20% cut reaches 277/280. The generator currently budgets at least 18 seconds for C1–C3 even where the actual fight lasts 14 seconds. Investigate a narrowly bounded rule for short early fights; do not hard-code this generated node's HP or change all stage floors from this one sample. Regeneration can differ from proportional HP scaling because of pressure adjustment and rounding.
4. **Thief C1 boss: HP pressure is implicated; cleanse is not.** Baseline is 119/280, a 10% HP reduction reaches 238/280, and 20% reaches 279/280. Cleanse six leaves the result exactly unchanged. The 20% arm is a useful upper comparison, not approval for a blanket C1 boss nerf. Determine the specific generated pressure/profile contribution and test other primaries before selecting a rule.
5. **Shadow C4: remains unresolved.** Baseline is 192/320. A 20% HP reduction reaches 270/320 but the weakest gear history still wins only 10/40. Cleanse six reaches 237/320. Neither intervention establishes a consistent remedy across acquired builds, so a blanket HP or cleanse change is not selected. Inspect these weak histories' weapon/skill fit and the boss's combined defenses before expanding enemy tuning.

## Next concrete T6 gate

The next implementation-ready proposal should define an actual generator rule, regenerate a representative early-route set, and compare all four primaries with retained late-stage controls. For the toll issue, test the true short-window HP-budget correction rather than only the 278→216 proxy. For the C1 boss, isolate the responsible pressure term before choosing a blanket HP multiplier. Recheck Shadow C4 with gear-sensitive macro/build recovery on the weakest acquired histories. These checks are needed to decide scope and side effects; no additional permission is needed to investigate.

No numerical adoption is requested from this report. The existing project requirement to review concrete balance changes before implementation still applies once a scoped proposal is ready. T6 is not closed by this reassessment. T7 remains Complete; Adventure remains disabled; T9/T10 still own hands-on acceptance and poor-gear recovery.

## Evidence and reproduction

`project/reports/p6_m6_t6_revisit/trials.json` retains each exact acquired snapshot, macro, candidate/baseline monster, and paired outcome. `summary.json` contains aggregate and worst-build results. Run Godot 4.7 against an isolated current project copy with the T6/T7 report dependencies: `--headless --path <copy> --log-file <absolute log> -s res://scripts/tools/run_m6_t6_revisit.gd`. Use isolated APPDATA; the harness sets session-only saves.

The current baseline matches all 1,088 source/data/test/scene fingerprints retained before T7. No gameplay implementation changed, so the relevant passing T7 regressions remain baseline evidence; this pass adds candidate-combat and independent outcome checks, not a new gameplay regression claim. Accepted execution has no script/assertion errors; existing certificate-store and shutdown resource warnings remain.
