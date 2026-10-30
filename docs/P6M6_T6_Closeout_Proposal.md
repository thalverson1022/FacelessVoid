# T6 closeout proposal

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

**2026-10-08 — T6 focused review Complete:** [Optimization and counterplay reassessment](archive/m6/P6M6_T6_Optimization_And_Counterplay_Review.md) retains current enemy values and rejects the three prior nerfs. Matched build/skill-omission trials, tag-only offer comparisons, route commitment checks and nine regressions support the decision. No numerical approval is pending. T1–T7 Complete; T8–T11 Not started; Adventure disabled. Full-run difficulty, optimized-play tension and hands-on acceptance remain T9/T10.

**2026-10-08 — Difficulty direction clarified:** [User direction and reassessment criteria](archive/m6/P6M6_T6_Difficulty_Direction_Clarification.md) require a hard game where optimization, synergy and informed matchup avoidance matter; heavy build counters are acceptable. The three-change recommendation is withdrawn pending weak/coherent/optimized comparisons and routing review. T6 In progress; no numerical approval currently requested. Live values unchanged; Adventure disabled.

2026-10-08. **T6 is ready for numerical approval. The implementation is tested in an isolated copy; live gameplay files are unchanged.** Approval, adoption and verification of the adopted baseline are the remaining closeout steps. T7 remains Complete. Adventure remains disabled.

## Approval requested

Approve these three scoped generator changes together:

1. **C1–C3 short-fight HP budgeting:** remove the 18-second minimum HP-budget window. Use the actual generated fight duration; the fight timer itself does not change. Apply the same floor setting in Practice. C4–C10 retain 22 seconds, C11–C20 retain 26, and C21 onward retain 30.
2. **C1 bosses combining Slow and Interrupt:** multiply the boss HP coefficient by **0.85** before rounding and contract scaling. Keep both mechanics, target-DPS selection, rewards, and duration rules. Bosses without both mechanics, other monster roles, and C2 onward do not receive this compensation.
3. **C4–C6 bosses combining Poison resistance, suppression and cleanse:** require a cleanse threshold of **at least six attacks** and multiply the boss HP coefficient by **0.80**. Retain all three mechanics. Other roles, bosses without the complete combination, and C7 onward are unaffected by this rule.

The exact three-file implementation is in `candidate.diff`: contract-route generation, runtime-monster generation and the Practice HP-budget helper. These factors modify HP construction; they do not promise a flat final-HP reduction for a seed. The original pressure-retry selection is retained, then the selected input is regenerated with the compensation. Selected rolls, durations and non-cleanse defenses remain unchanged. An initial candidate that changed selected rolls was rejected after it introduced early Interrupt walls.

No further change is proposed to Drunk Buddy armor 140, Steal timing, point rewards, loot, shop prices, player talents, Bladedancer C10 enemies, or the late-stage scaling curves. The Shadow adjustment is restricted to the three-counter boss combination; it is not a blanket Shadow C6 nerf.

## Why these rules

The original Thief toll fight lasts 14 seconds but budgets HP for 18. Correcting the actual generation pipeline removes that excess pressure without extending the fight. The flagged C1 boss combines boss HP and target-DPS premiums with Slow and Interrupt; its cleanse threshold was not responsible for the Thief failure. The 15% compensation addresses this specific combination rather than reducing every C1 boss.

The flagged Shadow C4 boss combines Poison resistance, suppression, cleanse and Slow immediately after the early guardrails end. A bounded search of legal builds and macros on the same earned gear improves 196/320 to 236/320 wins within two attempts, but its two weakest histories still record 7/40 and 0/40. This is insufficient evidence to dismiss the issue as player allocation alone.

Separate defense-removal probes record 81/160 baseline, 116/160 without Poison resistance, 123/160 without suppression, 146/160 without cleanse and 127/160 without Slow. A fixed-HP probe combining 20% less HP with cleanse six reaches 151/160. These probes identify overlapping counter pressure; the recommended implementation preserves the mechanics and has been tested through actual regeneration, with the original selected roll preserved.

## Regenerated targeted results

All figures below are victories within two attempts. Each source build uses gear actually earned in T7. There are seven reached Thief C1 histories and eight reached Shadow C4 histories; Shadow uses the previously tested optimized allocations, legally available at the incoming contract offer.

| Matchup | Actual regenerated HP, baseline → candidate | Wins within two | Weakest history |
| --- | ---: | ---: | ---: |
| Thief C1 toll | 278 → 216 | 157/280 → 280/280 | 7/40 → 40/40 |
| Thief C1 boss | 1109 → 943 | 127/280 → 269/280 | 3/40 → 35/40 |
| Shadow C4 boss | 2377 → 1881 | 182/320 → 301/320 | 1/40 → 29/40 |

For the Shadow C4 example, cleanse rises from four to six and HP changes from 2,377 to 1,881. Poison resistance remains 34%, Slow 26%, suppression 62%, and duration 37 seconds. The table uses fresh validation roots 214001–214040, separate from screening and macro training. The full fresh confirmation contains 41 paired cases / 3,280 newly executed first attempts, including previously regressing cases.

## Cross-primary and scope checks

The early matrix regenerates 108 graphs: 12 route seeds at C1, C2, C3, C4, C6, C10, C15, C20 and C30. The midgame matrix regenerates 84 graphs at C4, C5, C6, C7, C10, C20 and C30. The route seeds are 7001, 85001–85004, 85016, 85022 and fresh roots 95101–95105. Route topology and node identities are preserved. The final matrices retain **87,944 paired first-attempt records and 2,881 retry records**. Of those first attempts, 43,972 baseline and 28,368 identical unchanged-candidate records are reused from the measured controls; 15,604 changed-candidate first attempts were newly executed. Fresh confirmation adds 3,280 new first attempts. These counts exclude training, Shadow probes and trajectories.

| Matrix | Primary | Baseline wins within two | Candidate wins within two |
| --- | --- | ---: | ---: |
| C1–C3 | Bladedancer | 9677/10260 | 9695/10260 |
| C1–C3 | Thief | 10367/10748 | 10658/10748 |
| C1–C3 | Assassin | 10130/10260 | 10178/10260 |
| C1–C3 | Shadow | 10185/10260 | 10188/10260 |
| C4–C6 affected bosses | Bladedancer | 539/540 | 540/540 |
| C4–C6 affected bosses | Thief | 540/540 | 540/540 |
| C4–C6 affected bosses | Assassin | 540/540 | 540/540 |
| C4–C6 affected bosses | Shadow | 621/824 | 812/824 |

The early cohort includes unchanged combat controls: lowering floor metadata does not change HP when the actual duration already exceeds the old floor. Do not interpret the aggregate as an effect size for only changed monsters. Three first-reached typical gear histories per primary/stage are used for general controls, and all available histories for the two Thief targets and Shadow C4 target. This is representative coverage, not exhaustive build balance.

Macros are selected against baseline enemies using training seeds 3101–3102, then frozen across candidate arms. Early validation roots start at 209001 and midgame roots at 212001: 12 per general control and 40 per flagged target. Retry theft is retained; ranks and gear remain fixed. Roots are reused across histories and arms, so sample counts are not independent-run counts.

The final graph audits find zero changed selected rolls, preserve durations and all non-cleanse defenses, and leave C7 onward payloads identical. The combined candidate also affects qualifying C4–C6 bosses included as graph-only controls in the early matrix. A native-generator check verifies the implementation against the screened candidate on 120 graphs, tests Adventure/Practice floor boundaries and boss-rule scope, and passes **2,830 checks**. The independent outcome/pair verifier passes **309,054 checks**.

The early paired results gain 360 wins within two attempts with no losses. The midgame results gain 196 and lose four individual-root wins. One aggregate Shadow C5 case (route seed 95103, gear history 84002) changes from 11/12 to 10/12; this limited regression remains visible for T9/T10. Aggregate results improve or hold for every primary. This evidence does not prove every individual fight improves.

## Cumulative progression and economy

Twelve matched typical-policy trajectories use the full combined candidate, actual victories, rewards, gear choices, theft, shops and legal retries through failure or C20. Their ledgers pass 8,950 checks across 550 attempts. Ten runs complete the same number of contracts; two improve; none ends earlier in this cohort.

| Primary | Root | Baseline contracts completed | Candidate contracts completed |
| --- | ---: | ---: | ---: |
| Assassin | 84001 | 18 | 18 |
| Assassin | 84002 | 20 | 20 |
| Assassin | 84003 | 20 | 20 |
| Bladedancer | 84001 | 1 | 1 |
| Bladedancer | 84002 | 11 | 11 |
| Bladedancer | 84003 | 4 | 4 |
| Shadow | 84001 | 6 | 6 |
| Shadow | 84002 | 6 | 6 |
| Shadow | 84003 | 5 | 12 |
| Thief | 84001 | 0 | 20 |
| Thief | 84002 | 3 | 3 |
| Thief | 84003 | 15 | 15 |

Longer surviving runs naturally earn and spend more gold; their ending balances are not equal-duration income comparisons. Existing theft/gold caps and reward accounting are checked by regressions. These are the established T7 spending and allocation policies, not an exhaustive search or ordinary-player success estimates.

Some runs still stop at C2, C4, C5 or C7. **This proposal does not establish smooth C10 pacing or complete Adventure acceptance.** Those exact residual trajectories are retained as T9/T10 validation cases for gear choice, allocation, routing and player experience. They must not be silently counted as resolved or converted into new blanket nerfs from this small cohort.

## Remaining findings and closeout

- **Thief C1:** recommend the scoped short-window and timing-boss rules above.
- **Shadow C4:** recommend the early midgame three-counter boss compensation; macro/build recovery alone did not solve the weakest reached histories.
- **Shadow C6:** retain ordinary enemy values; only bosses satisfying the same explicit three-counter rule receive compensation. Prior optimized-build evidence remains valid as the baseline.
- **Bladedancer C10:** retain enemy values. The post-T7 earned-build control remains 160/160; poor acquisition and earlier failures stay visible in T9/T10.
- **Tavern:** retain approved D008 armor. No new Tavern tuning or approval is needed.

After approval, apply the saved patch, verify the adopted generator reproduces the reviewed candidate and rerun the affected checks, then record the decision and close T6. T8 owns Adventure integration/access and persistence handling; T9/T10 own the full-run and hands-on acceptance described above. The finite C30 prototype and future Road/endless scope remain unchanged.

The M6 tracker explicitly requires: “Review concrete tuning proposals against the agreed targets before affected implementation.” That is why this is presented for your numerical approval instead of applied automatically. No additional research approval is requested.

## Regressions, preservation and reproduction

Seven existing suites pass on the combined candidate: runtime monster generator, contract route generator, Practice fight setup, encounter rewards, gold contracts, full Thief and mixed journeys. The scope check and trajectory ledger checks pass separately. Existing Godot certificate-store and shutdown resource warnings remain; accepted executions have no script/assertion failures.

Evidence is under `project/reports/p6_m6_t6_closeout/`. **Final:** `stable_generator_review.json`, `stable_mid_generator_review.json`, `fresh_confirmation.json`, `journeys/`, `verification.json`, `regressions.json`, `candidate.diff` and `candidate/`. **Investigative:** `shadow_recovery.json` and `shadow_defenses.json`. **Rejected trial:** the unprefixed `generator_review.json`, `mid_generator_review.json`, `rejected_candidate.diff`, `rejected_verification.json` and `rejected_journeys/`. Rejected data must not be interpreted as the adoption candidate. All 1,095 existing source/data/test/scene fingerprints are checked during publication; real saves and existing gameplay files remain unchanged.

Reproduce in an isolated Godot 4.7 project with the existing T5/T6/T7 evidence and isolated APPDATA. The baseline tools `run_t6_generator_review.gd` and `run_t6_mid_generator_review.gd` produced the frozen baseline controls and rejected trials. Run `run_t6_stable_review.gd` with those saved controls for the final matrices and fresh confirmation; its final generator copies are `t6_candidate_runtime_v3.gd` and `t6_candidate_contracts_v3.gd`. Use an absolute `--log-file` path. The Shadow recovery/defense scripts reproduce the diagnostic controls. Apply `candidate.diff` only to the isolated copy for native tests and the twelve `run_m6_t7.gd -- --tree=<tree> --policy=typical --seed=<84001..84003>` journeys. The saved `candidate_scope_test.gd` requires the tool generator copies in `scripts/tools/`. Run `verify.py <evidence-folder>` and `check_t7.py <evidence-folder>/journeys` for independent checks. The proposal includes the orchestration scripts and accepted logs.
