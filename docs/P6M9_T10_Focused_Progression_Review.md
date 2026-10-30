# M9 T10 — Focused progression review

Date: 2026-10-28. Status: **Complete within the approved focused-review scope, P6M9-D043.** No balance tuning applied. Next: T11 user playtesting/refinement.

The sample supports retaining current gold, loot frequency and rarity rules for user playtesting. New slots fill through ordinary acquisition and contribute meaningful power, but outcomes remain build/seed dependent. Discount/resale profitability is confirmed, including quoted opportunities in earned historical play. The sampled current proc budget is small; existing endpoint risk remains unresolved.

## Scope and comparison

The user authorized the proposed focused review before any tuning. Gold amounts, reward frequency, rarity rules, enemy tuning and Legendary effects remain unchanged. This is a bounded earned-Adventure observation, not the deferred D099 expanded balance matrix or M10 acceptance.

The five-slot comparison uses the recovered full accepted M8 snapshot at `work/m8_t9_presentation/crown_meditation_d097/project`. It contains the adopted Exsanguinate, Signet, Wingjammer and all-damage Crown values. The [baseline source audit](../work/m9_t10/baseline_audit.json) records provenance and hashes. Git HEAD predates the final accepted working-tree changes and is not substituted for that baseline.

Both versions start with Crude Dagger only. The comparison includes M9's seven slots, uniform Basic weights under D008 and expanded Legendary catalog (16→20). Matching seeds controls initial contexts, not identical loot or a causal slot-only experiment. Current-gear slot removal replays are conditional diagnostics, not a second historical baseline.

## Method and validity

- Two fixed seeds, 101 and 307, for Bladedancer and Assassin in both versions: eight initial paths, with a C13/45-point maximum horizon.
- One declared Assassin sensitivity replaces its Poison-only rotation with unlocked skills from `[Venom Jab, Stab, Heavy Slash]`, applied to both seeds and versions. No further rotation search, free wins, injected currency, items or talent points.
- Actual BuildState reward, inventory, shop, encounter, retry and talent APIs; first offered secondary and first connected route. Fixed legal talent priorities, no respec. Stop on terminal loss or the two-attempt probe cap; distinguish them in raw results.
- Gear policy accepts strict immediate health-loss improvement against the current enemy using evaluation seed 701. It is deliberately myopic, does not identify hidden reward items, and does not represent expert human optimization. Hypothetical swaps omit a displaced item's possible carried-economy contribution; actual acquisitions/swaps use authoritative state APIs.
- Shop policy inspects offers sequentially, buying affordable improvements; at most one reroll per shop with an 18-gold reserve. Affordability is measured at each inspection, after earlier purchases/sales. It never buys for resale profit.
- Each actual fight is replayed with the same inputs and seed, with detailed tracing enabled on the second resolve. Damage, outcome and final RNG state must match. Maximum root budget consumption comes from rich trace payloads, not the last root's counter or the whole-fight count.
- Checkpoint combat figures describe the last completed fight **before** its reward/preparation. Checkpoint bank/equipment describe the subsequent preparation. These are separate observations.
- Isolated source copies, redirected gameplay paths and isolated APPDATA/LOCALAPPDATA protect real profiles. Production sources and profile hashes are reconciled separately.

An independent audit caught a probe-only flow error: earlier attempts opened the Hired Goon shop through the state API, while normal UI deliberately skips it. All earlier `earned_v1`, `historical_verified`, `formal_evidence`, `poison_sensitivity`, `historical_poison_sensitivity` and `trace_replay` progression outputs are superseded. Only corrected `cadence_verified` and `cadence_mixed_sensitivity` outputs may support the final observations. A historical CombatResult-field incompatibility was also corrected in the harness; script-error outputs are excluded.

## Acquisition and replacement

The corrected evidence contains 12 paths and 262 actual combat attempts (237 victories), each replayed once. This is two seeds and two initial policies plus one declared Assassin recovery policy, **not 12 independent seeds**. All currency reconciles and every actual replay matches; no talent budget, item-ownership or resolver validity failure occurred.

| Policy / seed | Accepted five-slot result | Current seven-slot result |
| --- | --- | --- |
| Physical /101 | C9 complete; terminal loss at C10 | C13 complete,45 points |
| Physical /307 | Terminal Tavern loss at Drunk Buddy | Same |
| Poison-only /101 and 307 | Terminal Tavern loss at Bouncer | Same |
| Mixed Poison /101 | C13 complete,45 points | C13 complete,45 points |
| Mixed Poison /307 | C3 complete; terminal loss at C4 | C5 complete; terminal loss at C6 |

All non-horizon stops here are actual non-retryable game losses; none is merely the probe's two-attempt cap. This does not prove a human player could not avoid those outcomes through different preparation. Bouncer's 65% Poison resistance and the unlocked Poison-only rotation explain why that policy is a poor early generalist; the one mixed-rotation sensitivity demonstrates a legal recovery without a balance edit.

| Current path | Pants first equipped | Gloves first equipped | Subsequent Pants / Gloves replacements |
| --- | --- | --- | ---: |
| Physical 101 | Reward 7, C1 | Reward 3, Bouncer | 3 /4 |
| Mixed Poison 101 | Reward 3, Bouncer | Reward 3, Bouncer | 4 /8 |
| Mixed Poison 307 | Reward 7, C1 | Reward 7, C1 | 3 /2 |

Reward numbers count earned victories from Tavern onward, not minutes. The physical path saw Pants offered at reward 2 but did not equip them until 7. The policy requires immediate combat improvement, so an offer is not a guaranteed fill. Physical 101 filled all five old slots by C1 in the baseline; its seven-slot loadout became full in C2. Original-slot timing varied: Helm filled earlier (reward 2 versus 7), while Trinket filled later (9 versus 5). The new slots were not persistently empty in these progressing paths.

Replacement is uneven: physical Pants went 12,17 and 4 earned rewards between replacements; Gloves had gaps 0,16,4 and 3. Zero means two accepted upgrades in the same preparation round. These are policy/seed observations, not population upgrade rates. Complete first fills, source offers and replacement gaps are in the two `slot_timing.csv` files linked below; automatic equipment changes and initial Dagger are included.

Equal eligible-slot selection changes a single uniform slot draw's chance for a particular original slot from 1/5 to 1/7. Its geometric mean waiting time changes from 5 to 7 draws (40% longer), under that narrow model. This is not a prediction of upgrade waiting time: stats, rarity, multiple offers, deliberate selection and multi-slot boss/Elite pools matter. A boss offering candidates from all slots still lets the player claim one item.

## Spending and combat strength

At the common C6 checkpoint, physical purchase spending was 333 gold for five slots versus 524 for seven; prepared banks were 4,226 versus 1,486. Mixed Poison spent 258 versus 644, with banks 2,037 versus 1,306. Extra spending is visible, but reward income also differs with earned economy gear and Overkill; the bank difference cannot be assigned solely to extra slots.

The two matched C13 Poison paths provide equal-horizon totals: five slots made 15 purchases for 448 gold and ended with 4,120; seven made 29 purchases for 998 and ended with 3,504. Rerolls cost 70 versus 65, and sales returned 358 versus 643. The physical comparison has unequal horizons: five ended at C10 after 17 purchases/414 gold; seven completed C13 after 28/920. Do not compare those as equal-length spending rates.

Across all twelve paths, every inspected contract-shop offer was affordable at that moment. Tavern cash was tighter: for example physical 101 found 3/18 inspected offers unaffordable in five slots versus 4/12 in seven; mixed Poison 101 found 7/18 versus 4/12. Sequential purchases change the bank, and rerolls change the number of observations. This supports **no general gold increase from this sample**, not a claim that saving never matters. The policy buys strict upgrades and saves when it sees none; it does not evaluate speculative future purchases like a person.

| Last completed seed 101 fight | Physical five DPS | Physical seven DPS | Mixed Poison five DPS | Mixed Poison seven DPS |
| --- | ---: | ---: | ---: | ---: |
| Tavern final | 14.7 | 13.6 | 25.7 | 31.6 |
| C1 boss | 24.1 | 20.1 | 34.0 | 56.9 |
| C3 boss | 85.3 | 62.1 | 156.2 | 202.6 |
| C6 boss | 1,542.6 | 953.2 | 334.2 | 667.0 |
| C10 boss | Not completed | 1,072.8 | 1,107.9 | 745.1 |
| C13 boss | Not reached | 4,759.5 | 1,635.3 | 5,787.1 |

DPS is actual recorded damage over the resolver's encounter duration, including Overkill. The historical physical C10 final attempt dealt 12,533 against 16,574HP (338.7DPS,4,041 short). Current seven passed that boss. This is evidence of changed progression, not proof that slots alone caused it. The current Poison path is genuinely Poison driven: ticks supply 73.5% of damage at Tavern completion,97.1% at C6 and 99.9% at C13. Seven-slot power is not uniformly greater at every checkpoint, and seed 307 remains fallible.

Conditional same-input ablations demonstrate contribution: removing physical 101's Gloves from the final Tavern fight changes 408 damage/win into 357/loss against 360HP. At C13, removing its Pants reduces 214,179 damage to 153,903; removing Gloves reduces it to 106,080, with either remaining loadout still winning. Removing an item can change RNG branches and occasionally increase damage (for example Poison Pants at C10); marginal deltas are neither additive nor a clean statistical causal estimate. Late surplus merits user playtesting rather than an automatic global enemy buff.

## Discount/resale risk

The legal discount/resale risk is reproduced independently of earned-run incidence. The [passing isolated diagnostic](../project/reports/m9_t10_risk_review_fixed/summary.json) uses normally generated items selected by a bounded seed scan, an authored Golden Greeves, and an explicitly assembled 100-gold bank. It is **not** a claim that these combinations were earned in ordinary play. Its 21 checks cover actual purchase/sale accounting and one-time ownership.

| Deliberately assembled loadout | Discount | Basic item buy | Resale | Net before reroll |
| --- | ---: | ---: | ---: | ---: |
| Golden Greeves alone | 40% | 10 | 9 | −1 |
| Greeves + generated Epic Weapon (23% discount) | 63% | 6 | 9 | +3 |
| Generated Chaos Weapon alone | 54% | 8 | 9 | +1 |

The Epic witness is generated seed 56; Chaos seed 13. Both pass strict generated-envelope validation without editing affix values. Chaos uses an original slot, so the loophole predates the slot expansion. Greeves adds a straightforward two-item route. See [raw diagnostic evidence](../project/reports/m9_t10_risk_review_fixed/m9_t10_risk_review/m9_t10_risk/evidence.json).

Purchase price is `max(1, floor(base × max(0, 1 − discount)))`; resale is `max(1, floor(base × 0.5))`, independent of price paid. Strict profit begins above 50% total discount for even-base tiers; Chaos base 55 needs more than 28/55≈50.91%. The one-gold floor bounds individual purchase cost, not profitability.

Offers are finite and consumed on purchase, carried capacity is three, and rerolls cost 5,10,15,… within a shop. The demonstrated+3 per Basic sale does not establish an unlimited money loop or a profitable reroll strategy. T9's injected+39 Legendary endpoint remains a diagnostic, not an earned-run frequency estimate.

The corrected earned historical physical 101 path exposed **60 profitable quoted offers beginning at C5**, all affordable at inspection. The price-spread analysis does not reconstruct carried capacity/eligibility for each offer and does not count realized arbitrage profit; the policy never deliberately cycles purchases for profit. No profitable quoted offer was observed in the six current paths. That absence in a small sample does not make the current economy safe: the separate current diagnostic above proves the avenue remains legal. [Derived offer-time metrics](../project/reports/m9_t10/review_metrics.json).

## Proc-budget risk

Current maximum root consumption is **10/1,024** in physical 101; physical 307 reaches 1, mixed Poison 101 reaches 4 and mixed Poison 307 reaches 3. Poison-only paths have no candidates. Maximum observed current ancestry depth is 4 against the retained depth 16 guard. No sampled current fight is invalid or budget exhausted.

The five-slot historical resolver lacks `budget_consumed` rich-trace fields. Its per-root maximum is reported as unavailable (`null`) when candidates occurred; whole-fight counts remain available only as upper bounds. Its observed zero-candidate Poison 101 path genuinely has maximum 0. Do not compare historical whole-fight totals to current per-root maxima.

The existing guard and T9's legal endpoint/custom-skill exhaustion remain retained risks. This sample did not construct the endpoint combination. A maximum observed in a small earned sample cannot establish global headroom or authorize raising the guard.

## Recommendation and follow-up

1. **Retain current gold amounts, reward frequency, rarity rules and slot pools for T11.** The sample shows early constraints, later surplus, ordinary new-slot fills and varied outcomes. It does not establish a general scarcity problem or justify blanket compensation for two extra slots.
2. **Review resale policy before an economy buff or release qualification.** The independent-of-paid-price resale rule is the direct mechanism. A narrow purchase-discount cap at 50% would prevent positive spreads but weaken high-discount builds; per-item resale capped by acquisition cost would retain discounts but require a paid-cost persistence/ownership rule. These are proposals, not approved implementations. Decide the desired behavior explicitly rather than silently nerfing Greeves or gold rewards.
3. **Keep trigger guards unchanged.** Sampled earned builds have room, but preserve the known endpoint risk for M10's unusual-build review. No broader matrix was restarted and no global safety claim is made.
4. **Use T11 to assess feel:** Pants/Gloves usefulness before C2, time between meaningful replacements, Tavern spending/saving decisions, physical/Poison preparation against counters, and whether late surplus is fun or excessive. Human feedback may justify a specific change; the two-seed automated sample cannot supply subjective acceptance.

T10 is complete as an evidence review, not user approval of balance or a certification of full-run performance. T11 remains Not started; T12 owns regression and M10 handoff. M10 retains wider unusual-build and economy review; M11 retains engine/export qualification.

## Evidence and reproducibility

- [Final evidence reconciliation](../project/reports/m9_t10/verification.json).
- [Authoritative evidence index](../project/reports/m9_t10/evidence_index.json), including superseded outputs and final harness hash.
- [Eight fixed paths and runtime/source manifests](../project/reports/m9_t10/cadence_verified/summary.json), [analysis](../project/reports/m9_t10/cadence_verified/analysis.json), [slot timing](../project/reports/m9_t10/cadence_verified/slot_timing.csv).
- [Four matched Poison sensitivity paths](../project/reports/m9_t10/cadence_mixed_sensitivity/summary.json), [analysis](../project/reports/m9_t10/cadence_mixed_sensitivity/analysis.json), [slot timing](../project/reports/m9_t10/cadence_mixed_sensitivity/slot_timing.csv).
- [Probe](../project/tests/m9_t10_progression_probe.gd), [disposable runner](../tools/p6/m9_t10_progression_probe.py), [analysis](../tools/p6/m9_t10_analyze_progression.py), [offer-time metric derivation](../tools/p6/build_m9_t10_review_metrics.py).
- [Current legal economy diagnostic](../project/tests/m9_t10_risk_review.gd) and [passing result](../project/reports/m9_t10_risk_review_fixed/summary.json). The first diagnostic attempt had a harness enum-name parse error; the corrected run is authoritative.
- [Runtime/profile integrity](../work/m9_t10/review_integrity.json):1,052 runtime/art/resource files and 162 protected files unchanged during the recorded parent-review interval. That snapshot began after initial probes; runner manifests separately document isolated directories and save paths for every run. No real profile was loaded, reset or intentionally written by this review.

Independent review checked historical provenance, normal UI shop cadence, reward/secondary timing, complete equipment transitions, sequential affordability, trace-counter semantics and the 60 observed historical price spreads. No remaining material issue required another run. Console certificate/resource teardown warnings remain in evidence; this is not engine, export or power-loss durability qualification.
