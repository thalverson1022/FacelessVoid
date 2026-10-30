# T10 Exsanguinate 1× coefficient experiment

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. [Current context](../../P6_Project_Onboarding_Context.md).

**D091 follow-up:** User adopted **1× with no retriggers**. [Current production rule and verification](P6M8_T10_Exsanguinate_Adopted_Balance.md). The comparisons and dated decision state below are retained as historical evidence.

**Historical baseline:** D090 subsequently removed Exsanguinate retriggers. This report retains the earlier repeat-enabled measurements; [current no-retrigger implementation and DPS comparison](P6M8_T10_Exsanguinate_No_Retrigger_Comparison.md).

2026-10-25, D089. User requested testing 1× Armor Shred Value instead of 2× and rerunning the same simulations, including Shadow hybrids, before deciding. **This is an isolated experiment, not an adopted balance change. Production remains at 2× and the current item/skill wording remains accurate for production.** T10 remains In progress; T9 overall review remains Pending input.

## Result

All 130 matched scenario evaluations complete: 11,600 final windows plus 864 screening windows, **12,464 new valid windows** in total. Final profiles use 200 seeds each. All reported removal magnitudes (means, percentiles and bounds) are exactly halved. Ordinary damage and the unaffected cast/retrigger/stack-consumption distributions remain identical; the retained paired samples also match those unaffected fields. Combined damage falls by the share contributed by Exsanguinate, rather than universally falling by 50%.

| Build / rotation | Exsanguinate at 2× / 30s | Exsanguinate at 1× / 30s | Combined DPS at 2× | Combined DPS at 1× |
| --- | ---: | ---: | ---: | ---: |
| Nightkiss, no talents | 2,070 | 1,035 | 88 | 54 |
| User rotation: 35 BD / 10 Thief | 44,905 | 22,453 | 2,095 | 1,347 |
| 35 BD / 10 Thief, focused, Nightkiss only | 102,538 | 51,269 | 3,607 | 1,898 |
| 35 Shadow / 10 BD, Nightkiss only | 62,059 | 31,029 | 2,098 | 1,064 |
| 32 BD / 13 Shadow, Nightkiss only | 164,256 | 82,128 | 5,573 | 2,835 |
| 29 BD / 16 Shadow, Nightkiss only | 205,713 | 102,857 | 6,910 | 3,481 |
| 35 BD / 10 Thief, five Legendaries, focused | 231,644 | 115,822 | 9,479 | 5,618 |
| 32 BD / 13 Shadow, five Legendaries | 389,129 | 194,564 | 13,641 | 7,155 |
| 29 BD / 16 Shadow, five Legendaries | 397,063 | 198,531 | 13,611 | 6,993 |
| User rotation, five Legendaries with Signet | 139,660 | 69,830 | 10,753 | 8,425 |
| Same Nightkiss/build, Exsanguinate omitted | 0 | 0 | 677 | 677 |
| Generator-validated max-roll endpoint, focused | 84,845,684 | 42,422,842 | 2,839,889 | 1,425,794 |

Numbers are means against the empty endurance dummy; the displayed Exsanguinate columns are its contribution only. Combined DPS includes ordinary damage plus removal, matching the D088 Combat Log presentation. Native Balance Lab ordinary damage/DPS retain their existing separate definitions. Full precision and removal min/5th/median/95th/max are in the CSV/JSON below.

![1× versus 2× Exsanguinate and combined damage](../../../project/reports/balance/exsanguinate_one_x_review/overview.png)

## What this changes for the balance discussion

- **User setup:** Exsanguinate averages 22,453 at 1×; median 19,980 and 5th–95th percentile range 12,210–39,405. Combined damage becomes 40,401 in 30 seconds, a 35.7% reduction. The same-gear no-Exsanguinate control stays at 20,310; the tested skill rotation therefore retains 1.99× that control’s combined output, down from 3.09×.
- **Shadow synergy survives:** Death Touch, Dusk Strike, Rending/Opportunity and Virulent Corruption retain the same fuel generation, Shred Value, consumption and cleanse behavior. The 1× test reduces the payoff per stack, not the identity of the hybrid. Full Shadow/BD10 still cannot use Dance; the legal 33 Shadow/12 BD comparison remains in the same profiles.
- **Compare whole builds:** the 29 BD/16 Shadow five-Legendary build falls to 6,993 combined DPS, versus 5,618 for the tested BD-focused five-Legendary rotation. That is 24.5% higher combined output, much less dramatic than comparing their Exsanguinate contributions alone. The Signet five-Legendary user rotation reaches 8,425 combined DPS, showing that the highest removal build is not necessarily the highest total-output build.
- **Extreme repeat/CDR scaling remains:** the max-roll endpoint still averages 42,422,842 Exsanguinate removal per 30 seconds. At 185 Shred Value and the 500-stack cap, a 1× root can remove 92,500 health; 100% numeric Retrigger Chance gives 17 full-value activations, or 1,572,500 per capped root. The finite depth/stack limits remain. This endpoint is not a normal earned loadout, an observed drop seed or a demonstrated global maximum.
- **Interpretation:** 1× is a useful candidate for playtesting normal builds. These fixed-window results do not establish earned-run balance or solve the extreme repeated-burst/cooldown case. No additional cap, cooldown, retrigger, item-stat or acquisition change is part of this experiment.

## Counterplay

| Nightkiss-only target case | 35 Shadow / 10 BD at 2× | At 1× | 29 BD / 16 Shadow at 2× | At 1× |
| --- | ---: | ---: | ---: | ---: |
| Armor 1,000 / block 100 / Poison resistance 90% | 62,059 | 31,029 | 205,713 | 102,857 |
| 100% dodge | 0 | 0 | 0 | 0 |
| 50% slow | 34,713 | 17,356 | 125,026 | 62,513 |
| Cleanse every 3 counted attacks | 12,355 | 6,177 | 205,713 | 102,857 |

Values in the counterplay table are Exsanguinate contribution per 30 seconds. Mitigation still does not reduce removal. Dodge starves these attack-fed rotations; Bribery remains a distinct theft-fed path. Full Shadow remains vulnerable to cleanse, while the hybrid retains Virulent Corruption’s Shred immunity. These relationships do not change at 1×.

## Matched method and verification

- Fresh isolated project `work/m8_t9_presentation/exsang_one_x`, redirected saves/userdata, native Balance Lab/main CombatResolver. The only gameplay-code difference from current production is `event.health_removed = 1.0 * player.shred_value * consumed`, replacing `2.0` in the copy. Production code/data/art/saves are unchanged. The candidate does not alter the approved Dance fix or apply the proposed coefficient to the player’s game.
- Same D087 scenario IDs, ranked payloads, rotations, equipment paths, resolved stat/source fields, target overrides, duration, starting gold and combat seeds. All seven dataset pairs pass strict equality checks for those inputs. The baseline is the frozen Dance-corrected 2× dataset, not the older bugged Dance results. D088’s Combat Log presentation does not change native Lab metrics or simulation math.
- Target HP 1 billion solely keeps the same 30-second endurance window alive; all windows remain non-kills. Exact multiplicative behavior here does not predict a halving of kill times against real finite-HP enemies. Faster/slower kills can change the number of casts in an actual encounter.
- 24 original profiles, 20 Shadow/hybrid profiles, 8 defense profiles and 6 confirmed rotation/other-tree cases: 58×200 = 11,600 final windows. Same 72×12 = 864 bounded screening windows. **12,464 new windows / 130 evaluations**, compared against the same-sized existing baseline. Some controls overlap deliberately; no claim of 130 unique builds is made. Zero invalid seeds/scenarios; candidate overflow would remain invalid.
- All removal aggregate statistics halve; ordinary/unaffected aggregates are unchanged. 2,256 retained paired samples pass the same numeric and combined-damage checks. Combined means/sample totals/rates are reconstructed from ordinary damage plus removal. Combined quantiles are measured natively, not obtained by adding marginal quantiles.
- Copied measurement regression passes 53 checks after adapting only expected removal amounts/rates to the candidate coefficient. Original production test expectations remain at 2×. The mixed Combat Log regression passes 20 checks at 1×, including combined totals/DPS and native-counter preservation. Balance Lab import regression passes. [Verification manifest](../../../work/m8_t9_presentation/d089_verification.json) records source isolation, protected production hashes, execution results and data hashes. No production Godot launch or player-save access.
- [All matched comparisons CSV](../../../project/reports/balance/exsanguinate_one_x_review/comparison.csv), [analysis JSON](../../../project/reports/balance/exsanguinate_one_x_review/analysis.json), [comparison analyzer](../../../tools/p6/analyze_exsanguinate_one_x.py). Native scenario specs, aggregates and retained samples are saved in the isolated project under `reports/balance/exsanguinate_study` with the same seven labels as D087. [Original corrected study](P6M8_T10_Dance_Fix_And_Shadow_Exsanguinate_Review.md) records the exact representative rotations/allocations and endpoint qualifications.

**Decision state:** 1× tested and ready for user review. 2× remains adopted. T10 and the broader earned-progression/playtesting work remain open.
