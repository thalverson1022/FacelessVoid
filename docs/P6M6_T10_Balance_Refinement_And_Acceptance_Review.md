# T10 balance refinement — measured proposal and playtest review

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

**2026-10-08 — T10 Complete by user acceptance (D015).** The user accepts the retained milestone scope and existing evidence, keeps current item/enemy values and intentional hard counters, and will revisit balance during substantial playtesting alongside next milestone’s icon/UI feedback. Legendary Item refinement remains assigned to the separate next-phase remake. No experimental Bandit curve is adopted; no numerical approval remains pending. This records milestone acceptance and deferred hands-on validation, not a claim that the future playtesting has already occurred. T1–T10 Complete; T11 regression/closeout/handoff remains Not started. Earlier entries below are historical.

See [T10 accepted closeout](archive/m6/P6M6_T10_Accepted_Closeout.md).

**2026-10-08 — User scope decision: Legendary Item remake next phase.** Defer Legendary-specific balance changes, including the isolated Bandit Blade curve, to that remake. No Bandit numerical approval or candidate playtest is required for M6-T10. Retain live item and enemy values; carry the measured excess-power and progression tradeoffs into the next phase. T10 remains Pending input for human difficulty acceptance of the current milestone scope, with Legendary balance explicitly deferred; T11 Not started. Earlier candidate recommendations below are historical.

See [next-phase Legendary handoff](P6_Legendary_Remake_Next_Phase_Handoff.md).

2026-10-08. **T10 Pending input; no live balance adoption.** T1–T9 remain Complete. Adventure remains enabled. This report supersedes the flat-coefficient candidates as the preferred direction, but does not declare final difficulty acceptance.

## Recommendation and approval boundary

Review **diminishing returns for Bandit Blade's gold-derived physical damage**. Retain enemy values, the 14-second encounter windows, intentional Poison/control counters, Steal's approved timing and Drunk Buddy's approved armor. Gold should reward planning and synergy without eventually replacing the need for a useful sequence.

The concrete candidate changes Bandit Blade's contribution from `0.1 × gold` to **`100 × gold / (1000 + gold)`**. It remains increasing and approaches +100; this limit applies only to the item's gold-derived base physical bonus. It does not cap total damage, talent bonuses, crit scaling or other gear. The +20% physical, +12% crit and +30% gold affixes remain intact.

| Current gold | Current bonus | Proposed bonus |
|---:|---:|---:|
| 100 | 10.00 | 9.09 |
| 1,000 | 100.00 | 50.00 |
| 10,000 | 1,000.00 | 90.91 |
| 100,000 | 10,000.00 | 99.01 |

The isolated implementation includes an optional soft-cap field (zero retains the existing linear mechanic), accurate source diagnostics, a concise tooltip, updated authored-value expectations and a new curve/serialization test. The exact proposed patch is supplied separately. No production source/data/test/scene files were changed: **all 1,115 protected live files match their starting hashes**.

**Recommendation:** diminishing returns is a better refinement direction than the tested flat cuts. The +100 asymptote is a concrete playtest candidate, not an accepted final balance target. I recommend your paired playtest before approving live adoption, particularly because none of these bounded-policy candidate runs completed the full catalog. This may be acceptable for a hard game, but automation cannot establish that the experience rewards sufficiently good human play.

The milestone tracker explicitly requires **“Review concrete changes before implementation.”** Approval would authorize this exact Bandit Blade curve and its supporting code/text/test updates. It would not approve enemy nerfs or close T10's human difficulty acceptance. No approval is requested for any of the rejected flat cuts.

## Evidence and interpretation

There are **133 victory-dependent journeys**, **5,393 actual combat attempts** and **91,765 independent ledger/progression/decision checks**. The core matched cohort uses all twelve ordered pairs, two new world seeds (246001–246002), 24 informed journeys and eight each of coherent and weak controls per arm. Current balance, flat 0.001 and diminishing returns each have 40 journeys. Flat 0.003 has five adaptively selected affected histories. Eight additional runs compare current and diminishing balance across four cyclic pairs at fresh root 248001 after freezing the candidate.

All rewards, gold, gear, purchases, retries, respecs and route commitments use real progression APIs. No injected equipment, free points, synthetic victories or mid-contract refunds enter these journeys. Normal encounters allow two attempts; the production first-Tavern unlimited-retry exception is retained. Run endpoints are real defeat or the 30-boss ending.

The preparation policy remains frozen from T9: bounded legal talent search, tag-only future-route inspection, and current-enemy sequence preparation using player-visible rounded defenses on separate training seeds. It is **not proof of a globally optimal build**. The two world seeds are shared across tree pairs; these are not forty independent players. The fresh confirmation has one additional shared world seed and is intentionally small.

### Why the item needs attention

262 previously earned Bandit snapshots at C6/C10/C20/C30 were replayed against four separate combat roots. Ranks, gear, gold and enemy values are held fixed. The comparison has 1,048 conditional trials per curve; it does not assume a candidate could reach every original snapshot. The no-gold-effect arm is diagnostic only.

| Gold coefficient / curve | Prepared sequence wins | Stab-only wins | Median full-window damage / HP |
|---|---:|---:|---:|
| 0.1 per gold | 1048/1048 | 988/1048 | 54.56 |
| 0.01 per gold | 945/1048 | 714/1048 | 10.59 |
| 0.003 per gold | 859/1048 | 521/1048 | 5.98 |
| 0.001 per gold | 799/1048 | 288/1048 | 3.42 |
| 0 per gold | 566/1048 | 228/1048 | 1.22 |
| Proposed diminishing returns | 853/1048 | 428/1048 | 4.28 |

Stab-only still benefits from earned talents and equipment; it is a simpler-sequence control, not a complete weak-build population. It need not lose every matchup. The important finding is that the current item often erases much of the cost of sequence simplification, while the candidate restores substantially more separation. These success figures are measurements, not target percentages.

For the **853 same trials won by the diminishing candidate**, median time to accumulate required damage moves from **6.9% to 22.5% of the timer**. This is threshold crossing, not a claim the production full-window simulation stops early. All **210 snapshots without Bandit**, each checked at four roots, retain identical damage.

### Whole-run cost is real

In the main matched cohort, current balance finishes 4/24 informed journeys and 1/8 coherent journeys; diminishing returns finishes 0/24 and 0/8. Weak controls finish 0/8 in both arms and fail before leaving the Tavern. Five of forty candidate journeys end earlier; the other 35 retain their completed-contract count. Identical endpoints do not imply identical decisions or damage.

Completed contracts for the five affected histories:

| Pair / policy / seed | Current | Flat 0.001 | Flat 0.003 | Diminishing returns |
|---|---:|---:|---:|---:|
| bladedancer/thief · informed · 246002 | 30 | 10 | 16 | 26 |
| bladedancer/assassin · informed · 246001 | 30 | 17 | 17 | 24 |
| bladedancer/assassin · informed · 246002 | 30 | 10 | 10 | 21 |
| shadow/thief · informed · 246002 | 30 | 5 | 5 | 12 |
| thief/assassin · coherent · 246001 | 30 | 18 | 18 | 18 |

The flat reductions weaken early Bandit usefulness as well as the excessive late scaling. Diminishing returns preserves considerably more progression for the affected Bladedancers and Shadow. The smaller flat candidate also failed to restore their original endpoints. None is being judged successful merely because fewer runs win.

Fresh confirmation, frozen before those outcomes:

| Pair / fresh seed 248001 | Current completed contracts | Candidate completed contracts |
|---|---:|---:|
| assassin/shadow | 19 | 25 |
| bladedancer/thief | 30 | 23 |
| shadow/bladedancer | 10 | 10 |
| thief/assassin | 30 | 12 |

The Assassin case improves after changed gear/build/route decisions; this is a cumulative policy outcome, not a direct damage buff. The remaining losses show why the numerical candidate still needs hands-on review. A finished C30 fight loaded from an old earned checkpoint is not evidence of a full candidate journey reaching C30.

### Keep severe counters

All ten recorded T9 informed Shadow terminal losses had a visible offered path avoiding that loss's Poison-counter or control-tag family. This establishes a readable alternative, **not a guaranteed win on that route**. A whole-path risk sum can still choose a disastrous boss matchup; the agent's heuristic is not the player's ceiling.

With the same locked talents and earned gear, broader legal sequence preparation against current visible defenses improves Shadow's first-attempt held-out counter trials from **30/200 to 136/200** across ten snapshots. Across all 29 terminal snapshots the comparison is 100/580 to 318/580. Search uses four preparation seeds and twenty separate evaluation roots per snapshot. It does not spend points, invent gear, inspect future hidden defenses or grant extra attempts. Some alternatives generalize poorly; no universal rescue is claimed.

The three Shadow C6 Poison-counter cases reach 19/20 or 20/20 with a more physical sequence. Two Shadow C11 control cases still reach 0/20, and some late Assassin counter cases also resist the search. Retain these enemies: severe counters and costly route/build commitments are consistent with your direction. The evidence does not support reviving the rejected T6 nerfs.

### Remaining acceptance risks

- The candidate reduces automatic damage but does not establish satisfying tension in every optimized matchup. Thief/Big Score and non-Bandit synergy can still produce large margins; those existing approved mechanics are retained in this proposal.
- No candidate journey in this sample finishes all thirty bosses. This is a material tradeoff, not hidden behind the snapshot wins. We have not proven the game unwinnable, nor proven that expert human play can reliably finish it.
- The early two-seed sample exposes a shared Thief Tavern failure at one root, before Bandit has any effect. It cannot be blamed on this curve or used as grounds for an automatic enemy nerf.
- The finite 30-boss catalog eventually limits avoidance options. The C30 scaling plateau and lack of true endless progression remain prototype constraints.

## Validation

Fourteen candidate suites pass: Adventure lifecycle/UI, gold contracts, full Thief, mixed gear integration (342,282 checks / 576 scenarios), persistence, Legendary combat/reward/mechanics, Practice gold updates, equipped/reward tooltips, Legendary presentation, and the new 22-check curve/codec test. Adventure lifecycle covers 2,692 checks and 360 roundtrips. Final tooltip-specific checks were rerun after visual refinement.

Four earned checkpoints were rendered through the actual Adventure UI; the candidate UI combat results match direct candidate resolution. Route/guide access and return-to-offer preparation pass. The longer tooltip was shortened after visual review. These are agent-run UI checks, **not a human playtest**. The review launcher passes syntax and startup smoke checks and uses separate APPDATA/save paths.

An additional old `p5m3_existing_gear_wiring_test` fails on stale crit/Wyvern/save-envelope assumptions in both the unchanged baseline and candidate. It is explicitly excluded from the fourteen passes and recorded as existing test debt; its Bandit numeric expectation is updated in the proposal. Existing certificate-store and shutdown resource warnings also remain. Rejected preliminary harness/test expectations are not counted as accepted passes.

## Your playtest and remaining T10 steps

Open **T10_Playtest.cmd** from the delivered outputs. Choose current balance or diminishing returns, then an earned checkpoint. Each checkpoint launch restarts its separate review save; it never loads or overwrites your live save. Close one review window before opening the comparison.

1. **Bladedancer/Thief C30:** compare the same earned gear, 93,100 stash gold and sequence. Judge whether the candidate victory retains a satisfying margin and whether a worse sequence has a meaningful cost. This is an old-history conditional checkpoint.
2. **Thief/Assassin C10:** compare sequence setup and payoff. Decide whether the synergy still feels rewarding, and whether the candidate remains too forgiving. This is also an old-history conditional checkpoint.
3. **Shadow/Assassin C6 counter, seed 233003:** inspect Spiteful/Hexed. Keep earned gear/ranks and try `Heavy Slash → Touch of Darkness → Heavy Slash → Killer's Mark → Heavy Slash → Touch of Darkness → Distilled Corruption`. The sequence was selected without evaluation-seed access; the game still uses its normal retry rules.
4. **The same Shadow C6 offer:** inspect the route tags and return to offers before commitment. Judge whether the dangerous combination is readable enough to avoid. Fresh Adventure is also available in its own review save.

Please report whether optimized wins feel earned, whether losing choices are understandable, and whether the Bandit curve is too severe, too generous or about right. Then approve or adjust the exact curve. After approval I can apply the reviewed patch, verify live/candidate parity and regressions, and record your hands-on difficulty decision. **T10 remains Pending input; T11 has not started.**

## Reproduction and audit

Evidence is saved under `project/reports/p6_m6_t10`: accepted run JSON by arm, independent verification, snapshot/counter/route diagnostics, regression logs, rendered checks, earned playtest saves, protected-file audit, proposed patch and candidate source files. The stored candidate source/patch is authoritative; intermediate setup scripts describe exploratory stages and must not be treated as adopted values.

Recreate a disposable project from the protected baseline, apply `proposed_changes.patch` there, import with Godot 4.7, and use the saved T9 policy plus the exact job manifests. Give every worker its own APPDATA. The scripts record training/evaluation seeds and natural-endpoint rules; the unchanged T9 raw histories provide conditional snapshot inputs. Never run investigative save/export tools against a player's live save directory.
