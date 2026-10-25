# M6 T6 enemy investigation and tuning review

**2026-10-08 — T6 focused review Complete:** [Optimization and counterplay reassessment](P6M6_T6_Optimization_And_Counterplay_Review.md) retains current enemy values and rejects the three prior nerfs. Matched build/skill-omission trials, tag-only offer comparisons, route commitment checks and nine regressions support the decision. No numerical approval is pending. T1–T7 Complete; T8–T11 Not started; Adventure disabled. Full-run difficulty, optimized-play tension and hands-on acceptance remain T9/T10.

**2026-10-08 — Difficulty direction clarified:** [User direction and reassessment criteria](P6M6_T6_Difficulty_Direction_Clarification.md) require a hard game where optimization, synergy and informed matchup avoidance matter; heavy build counters are acceptable. The three-change recommendation is withdrawn pending weak/coherent/optimized comparisons and routing review. T6 In progress; no numerical approval currently requested. Live values unchanged; Adventure disabled.

**2026-10-08 — T6 numerical proposal ready:** The [tested closeout proposal](P6M6_T6_Closeout_Proposal.md) recommends C1–C3 actual-window HP budgeting, C1 Slow+Interrupt boss HP compensation (0.85), and C4–C6 triple Poison-counter boss compensation (HP 0.80; cleanse minimum six). Original selected rolls and durations are preserved. Seven regressions pass; twelve matched trajectories have no earlier endpoint. Live values remain unchanged. **T6 Pending input for numerical approval; T7 Complete; Adventure disabled.**

**2026-10-08 — T6 revisited after T7:** [Fresh acquired-build trials](P6M6_T6_Reassessment_After_T7.md) retain Bladedancer C10 enemy values and deprioritize a broad Shadow C6 nerf. Thief C1 short-window HP budgeting and boss pressure, plus Shadow C4 gear/defense interactions, are the focused remaining work. 4,640 first attempts and 1,319 retries; no gameplay changes or numerical approval requested. T6 remains In progress; T7 Complete; Adventure disabled.

**2026-10-07 — M6-T7 assessment complete:** The [rewards, gear and economy assessment](P6M6_T7_Rewards_Gear_And_Economy_Assessment.md) records 128 victory-dependent trajectories, actual spending and gold ledgers, Shadow armor-income controls and acquired-build T6 matchup checks. No new numerical changes are proposed; no approval is pending. T6 remains In progress; T8–T11 remain Not started. Adventure remains disabled.

Date: 2026-10-07. Status: **In progress. D008 armor change approved, implemented and verified; no approval pending. T6 is not complete.**

The user approved **Drunk Buddy armor from 160 to 140** under P6M6-D008; the live change is implemented and verified. Keep HP 155, Poison resistance 10%, the 18-second window, and all rewards unchanged. The fresh 100-root confirmation improved Bladedancer from 87 to 100 wins within two attempts with Rending Thrust / Quick Cut and one rank in Rending Slash. The other three primaries remained at 100/100. The historical proposed patch remains in the investigation evidence. [Adoption verification](../project/reports/p6_m6_t6_adoption/results.md) reproduces 688 live Tavern candidate/control samples and records four passing regressions. The evidence below describes the pre-adoption investigation.

Generated encounters need further joint enemy and acquisition work before T6 can close. Bladedancer C10 varies sharply by obtainable gear history; Thief C1 and Shadow C4/C6 retain weak cohorts. The existing scaling curve remains the baseline. No remaining wall is accepted as a balance exception by this investigation.

## Pre adoption confirmation

All rows use a fresh cohort of roots 105001–105100. Macros were fixed before this cohort. These are paired encounter outcomes, not independent full runs. Tavern gear before Drunk Buddy is identical across the three acquisition histories, so only one history and policy are counted here.

| Primary | First at 160 | First at 140 | Within two at 160 | Within two at 140 | Fixed macro |
| --- | --- | --- | --- | --- | --- |
| bladedancer | 71/100 | 92/100 | 87/100 | 100/100 | rending_thrust / quick_cut |
| thief | 100/100 | 100/100 | 100/100 | 100/100 | steal |
| assassin | 100/100 | 100/100 | 100/100 | 100/100 | venom_jab / heavy_slash |
| shadow | 100/100 | 100/100 | 100/100 | 100/100 | stab / heavy_slash / heavy_slash |

Armor 140 is the smallest tested armor reduction that cleared the fixed two-skill Bladedancer cohort reliably: the focused pilot was 35/40 at 160, 40/40 at 140 and 120, and 39/40 with HP 145 instead. This is not proof of an optimal armor breakpoint. A separate mean-damage-selected six-slot macro was less reliable (19/20 at armor 140); the proposed change supports a simple viable response, not every possible rotation.

The change can alter derived reward income. Applying the existing raw overkill formula to the fresh first-attempt samples gives Shadow mean overkill gold of 2.9 before and 4.7 after; 18/100 samples cross one extra ten-gold step. The other three tested macros have unchanged mean raw overkill gold. These are before applicable reward multipliers. T7 must include this effect in cumulative shop and reward analysis.

## Baseline and coverage

The isolated copy starts from D007 Steal at 1100 ms with its 650 ms minimum, Tavern rewards 1/0/2/3, three points per contract and the 45-point cap. Original gameplay files and historical reports were not edited. The project already had substantial uncommitted and untracked work; no reset, checkout, commit or cleanup of that work was performed.

Seventy generated route-stage graphs cover all six templates: seven route seeds at C1, C3, C4, C5, C6, C8, C10, C11, C15 and C20. The inventory contains 550 generated combat nodes, all four Tavern fights and a separate current-content Watchmen control. Every generated combat node is retained; mandatory status is checked against all paths, not inferred from enemy role.

Combat screening covers all four primaries at C1/C4/C6/C10/C11/C15/C20, with 12 held-out roots per arm. C3/C5/C8 are inventory transition probes, not additional combat cohorts. Three acquisition seeds (84001–84003), each with weak/typical/strong shopping policies, supply 36 conditional gear histories. The policies mean no shop purchases, at most one purchase per shop, and up to six respectively; they are not population percentiles.

The focused enemy comparisons use three route seeds and three gear histories. The original low-HP Thief toll captain and an additional weak C1 boss were tested separately: selecting only the highest-HP captain would miss the original timing problem. Selected T5 primary-focused allocations are retained where applicable; a T5 winner that spends all six Thief C1 points in Assassin is not treated as proof of Thief health.

## Generated encounter findings

Screening with the second typical gear history and the selected short macro gives these boss results within two attempts. Seven bosses per stage contribute 84 first attempts; this table is a diagnostic sample, not a success-rate requirement.

| Primary | C1 | C4 | C6 | C10 | C11 | C15 | C20 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| bladedancer | 83/84 | 82/84 | 84/84 | 84/84 | 84/84 | 84/84 | 84/84 |
| thief | 70/84 | 76/84 | 84/84 | 84/84 | 84/84 | 84/84 | 84/84 |
| assassin | 84/84 | 84/84 | 84/84 | 84/84 | 84/84 | 84/84 | 78/84 |
| shadow | 84/84 | 41/84 | 76/84 | 84/84 | 84/84 | 84/84 | 28/84 |

**Bladedancer C10:** The second gear history clears every sampled C10 node, while the original typical history fails the three trial bosses. A 30% HP reduction still fails those original-history bosses. Removing cleanse entirely in the diagnostic arm also fails them. A broad enemy HP or cleanse change would substantially ease already-successful histories without solving the weak one. Investigate the weapon/affix acquisition and build fit jointly with T7 before selecting a global curve change.

**Thief C1:** The original toll captain is a 14-second fight with HP 278 budgeted using an 18-second minimum. Removing that floor in a post-generation diagnostic changes HP to 216 and helps, but is not an exact rerun of generator pressure selection. Interruption cap 2→1 does not help the tested diverse rotations, because they avoid its repeated-skill trigger. The additional route-85016 boss remains difficult despite a longer window, so the short-window floor is not the sole cause.

All 23 legal pure-Thief six-point allocations were enumerated. Every legal one-, two- and three-slot macro was searched against both flagged fights on training seeds 551–553, choosing one allocation for both encounters per gear history. This exhaustive statement applies only to those allocation and macro-length bounds; it is not a global optimum over longer rotations or mixed trees. Fresh roots 106001–106100 confirm remaining weaknesses:

| Acquisition seed | Toll captain within two | Route 85016 boss within two |
| --- | --- | --- |
| 84001 | 29/100 | 15/100 |
| 84002 | 46/100 | 25/100 |
| 84003 | 100/100 | 81/100 |

These allocations are legal entrance respecs against fixed obtainable gear. Their gear was not retroactively reacquired with the alternative talents. Cumulative theft, victory-dependent purchases and allocation-dependent income remain T7 work.

**Shadow C4/C6:** Primary-focused builds remain sensitive to cleanse, timing and gear. The table below compares the same selected macro and gear against copied enemies across three route seeds and all three typical gear histories. The no-cleanse arm is a causal diagnostic, not a proposal to remove encounter identity.

| Arm | C4 bosses within two | C6 bosses within two |
| --- | --- | --- |
| baseline | 151/180 | 155/180 |
| hp90 | 168/180 | 180/180 |
| hp80 | 177/180 | 180/180 |
| hp70 | 179/180 | 180/180 |
| cleanse6 | 161/180 | 176/180 |
| suppress45 | 150/180 | 167/180 |
| no_cleanse_diagnostic | 174/180 | 180/180 |

The tested arms mean HP ×0.9/0.8/0.7; raise an existing cleanse threshold to at least six connected attacks; cap existing suppression at 45%; or set cleanse to zero. All other fields and fight durations stay fixed. Suppression alone is not a reliable general remedy. Enemy HP reductions and less frequent cleanse help selected cohorts, but these isolated results do not select a universal C4–C10 rule. T6 retains this tuning issue for the acquisition-informed return pass.

## Rewards acquired within routes

A separate conditional traversal selects connected nodes and collects their real rewards/shop offers before later encounters, addressing the conservative contract-entry gear snapshots. The following boss outcomes use 20 held-out roots for each of three histories. Each fight starts from the recorded incoming state; simulated outcomes do not decide whether the acquisition traversal advances. These are not complete successful runs, and conditional reward acquisition omits combat theft and overkill income.

| Primary | C1 | C4 | C6 | C10 | C11 | C15 | C20 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| bladedancer | 20/60 | 60/60 | 60/60 | 58/60 | 40/60 | 40/60 | 40/60 |
| thief | 41/60 | 40/60 | 60/60 | 60/60 | 60/60 | 60/60 | 60/60 |
| assassin | 60/60 | 60/60 | 60/60 | 60/60 | 60/60 | 60/60 | 40/60 |
| shadow | 60/60 | 58/60 | 45/60 | 60/60 | 60/60 | 60/60 | 41/60 |

Within-route builds use the protocol allocation path and a trained macro. In particular, Bladedancer C1 here uses Wet Stone 3 / Weakness 3, not the stronger T5 Wet Stone 5 / Precision Attacks 1 entrance allocation; its losses do not establish a new unavoidable C1 wall. They are a separate acquisition check, not a paired estimate of the effect of gear alone relative to the T5-respec screen. Some later histories fail while others remain very strong; this does not justify prescribing one universal failure contract. All twelve ordered tree pairs and three allocation families remain covered by the inherited T4 matrix; the new T6 histories use four representative ordered pairs, not a fresh twelve-pair matrix.

## Timing and Watchmen

Across the seven sampled route seeds, boss HP ranges from 1,841–4,137 at C4 to 12,773–21,790 at C10. Thirteen of 55 C10 nodes and 32 of 55 C11 nodes use HP budget durations longer than their actual combat windows. C4 removes early mechanic guardrails; C6 and C11 change difficulty bands. These are documented causes to inspect jointly with build and gear outcomes, not automatic reasons to flatten the curve.

The exact legacy Watchmen scenario rerun remains 199/200 wins (99.5%), above its unchanged historical 95% upper threshold; its status correctly remains `warn`. It uses legacy content and Wyvern Kriss. The current six-point ranked Watchmen controls are separately labeled in the T6 screen. Neither control warrants silently changing the historical threshold or tuning the generated route system to satisfy it.

## Verification and limitations

Recorded investigation measurements contain **57,932 first attempts and 9,049 actual retries**, excluding macro-training simulations, replay/Practice checks and the 200 legacy Watchmen samples. This execution count includes repeated Tavern controls with identical starting gear; it must not be described as that many independent samples. The data verifier passed 148,840 checks and confirmed 1,120 original source/data/test/scene/project/save fingerprints unchanged.


Forty-seven sampled trial configurations pass deterministic replay and Practice/native damage parity. The runtime monster generator, contract route generator, full Thief and mixed-journey suites pass on the baseline copy. These runs validate the investigation baseline and tools. Subsequent D008 adoption verification records the separate live replay and post-change regressions. Existing certificate-store and shutdown resource warnings remain. An initial launch used an invalid `res://` log-file argument and crashed before the harness ran; all recorded accepted runs use absolute log paths.

Detailed samples, exact ranks/macros, gear ledgers, route graphs, candidate field changes and cohorts are retained beside this report. Training uses 521–523 for short screening, 531–533 for broader recovery, and 551–553 for the bounded Thief search. Held-out cohorts are 100001–100012 (screen), 101001–101020 (candidate trials), 103001–103020 (within-route), 104001–104040 (focused follow-up), 105001–105100 (Drunk Buddy confirmation), and 106001–106100 (Thief recovery). Roots are paired across candidate arms; retry seeds use the actual fight key and attempt index, retaining stolen gold without reallocating talents between attempts.

The screen's contract gear and enemy route seeds are deliberately crossed. Gear histories assume earlier victories. No fresh-run success percentage, hands-on fun acceptance, Adventure access approval, economy acceptance or exhaustive legal-build balance claim is made. The C30 plateau, finite boss catalog and future Road/endless scope remain unchanged.

## Review and remaining work

1. D008 armor adoption is approved, implemented and verified. No additional approval is pending.
2. Continue the T6/T7 acquisition and enemy investigation within the existing scope: weak Bladedancer C10 gear history, Thief C1 timing/boss walls, Shadow C4/C6, and the adopted change's Shadow overkill/shop-income effect.
3. Present any further proposed numerical changes with measured evidence before implementation. No generated HP, cleanse, suppression or scaling change has been approved or applied.
4. Close T6 only after the remaining generated-matchup disposition is recorded. T9/T10 own complete runs, hands-on observations and final exception acceptance. Adventure remains disabled.

The M6 tracker's numerical-review requirement is satisfied for Drunk Buddy armor. Further investigation requires no new approval; any additional balance change will receive its own concrete review.

## Reproduction

Use an isolated copy of `project`, with its existing T5 and Tavern-1023 report fixtures. Set APPDATA to an isolated directory before invoking the Windows Godot executable. Run Godot 4.7 headless with `--path <copy> --log-file <absolute unique log> -s res://scripts/tools/run_m6_t6.gd -- --tree=<tree> --mode=<mode> --history=<seed>`.

For each primary, generate `fixtures` for seeds 84001–84003, then `screen` for 84002. Use the saved `trial_plan.json` for `trial` and `focused_plan.json` for `focused` (Bladedancer/Thief only), each across the three histories. Run `path` across all four primaries and histories. Run `confirm` using the saved plan, history 84002 only. Then run `run_m6_t6_thief_recovery.gd`, `check_m6_t6.gd` and the four regression suites listed in `regressions.json`. `tools/p6/verify_m6_t6.py` verifies the saved evidence and original pre-adoption manifest against the pre-adoption baseline. D008 intentionally changes one protected resource; use the separate adoption verification for the current live baseline and do not rewrite the historical manifest.

Candidate trials mutate duplicated Monster resources in memory after generation. They do not regenerate or approve a new global generator policy. The duration-floor experiment is an approximate proportional HP probe; pressure retries and rounding can make a true generator change differ.
