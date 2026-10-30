# T10 Exsanguinate cannot-Retrigger implementation and DPS comparison

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. [Current context](../../P6_Project_Onboarding_Context.md).

**D091 follow-up:** User adopted **1× with no retriggers**. [Current production rule and verification](P6M8_T10_Exsanguinate_Adopted_Balance.md). The comparisons and dated decision state below are retained as historical evidence.

2026-10-25, D090. User requested removing Exsanguinate retriggers and rerunning DPS numbers. **Exsanguinate cannot Retrigger in production. Its adopted coefficient remains 2× Shred Value; 1× remains an isolated experimental alternative.** Both coefficients were simulated with no retriggers so the coefficient decision is not inferred from the new request. T10 remains In progress; T9 overall review remains Pending input.

## Implementation

Removed Exsanguinate’s exception to the shared direct-attack self-repeat and recursive-follow-up eligibility. Numeric chance, including 100%/overcap values, and guaranteed-repeat metadata cannot make the Debuff self-repeat. No Exsanguinate repeat chance trial/RNG draw or phantom repeat Meditation grant remains. Each scheduled cast consumes all actual Shred once. Zero Shred removes zero health. Timing, mitigation/crit/damage-bonus exclusions, Death Pact exclusion and root health calculation remain unchanged.

Global Retrigger Chance from other build sources remains available to eligible attacks; Poison retains its existing Coil rules. Other attack/Poison retriggers, Meditation grants, Cloak/Locket interactions, chance clamp, depth-16 limit and candidate-overflow policy remain. Native repeated-Exsanguinate metric fields are retained and report zero. Compact item/skill effect wording stays as requested in D088; detailed reference conditions now state Cannot Retrigger.

## Whole-build DPS

All figures below are mean **combined DPS**: ordinary damage plus Exsanguinate health removal, matching the Combat Log. Each final profile uses seeds 1–200 and a full 30-second zero-defense endurance window. The earlier 2× baseline already includes the Dance fix.

| Build / rotation | 2× with retriggers | 2× without retriggers — live rules | 1× with retriggers | 1× without retriggers — experimental |
| --- | ---: | ---: | ---: | ---: |
| Nightkiss, no talents | 88 | 85 | 54 | 52 |
| User rotation: 35 BD / 10 Thief | 2,095 | 1,905 | 1,347 | 1,251 |
| 35 BD / 10 Thief, focused, Nightkiss only | 3,607 | 3,291 | 1,898 | 1,741 |
| 35 Shadow / 10 BD, Nightkiss only | 2,098 | 1,977 | 1,064 | 1,004 |
| 32 BD / 13 Shadow, Nightkiss only | 5,573 | 5,095 | 2,835 | 2,596 |
| 29 BD / 16 Shadow, Nightkiss only | 6,910 | 6,161 | 3,481 | 3,107 |
| 35 BD / 10 Thief, five Legendaries, focused | 9,479 | 7,676 | 5,618 | 4,709 |
| 32 BD / 13 Shadow, five Legendaries | 13,641 | 10,716 | 7,155 | 5,690 |
| 29 BD / 16 Shadow, five Legendaries | 13,611 | 10,894 | 6,993 | 5,634 |
| User rotation, five Legendaries with Signet | 10,753 | 10,405 | 8,425 | 8,261 |
| Same Nightkiss/build, Exsanguinate omitted | 677 | 677 | 677 | 677 |
| Generator-validated max-roll endpoint, focused | 2,839,889 | 178,089 | 1,425,794 | 94,937 |

![Retrigger removal at both coefficients](../../../project/reports/balance/exsanguinate_no_repeat_review/overview.png)

## Exsanguinate contribution

| Build | Previous 2× / 30s | New 2× / 30s | Previous 1× / 30s | New 1× / 30s |
| --- | ---: | ---: | ---: | ---: |
| User rotation | 44,905 | 39,285 | 22,453 | 19,642 |
| 35 Shadow / 10 BD, Nightkiss only | 62,059 | 58,396 | 31,029 | 29,198 |
| 29 BD / 16 Shadow, Nightkiss only | 205,713 | 183,234 | 102,857 | 91,617 |
| 29 BD / 16 Shadow, five Legendaries | 397,063 | 315,582 | 198,531 | 157,791 |
| Max-roll endpoint | 84,845,684 | 4,989,106 | 42,422,842 | 2,494,553 |

Exsanguinate columns are its contribution alone, not whole-build damage. Full precision, ordinary contributions, cast counts, actual Shred consumption and all four modes are retained in CSV/JSON.

## Findings

- **Normal build:** removing retriggers lowers the user-like setup from 2,095 to 1,905 combined DPS at 2× (9.1% lower). At 1×, it changes 1,347 → 1,251 (7.1% lower). The 2× no-retrigger rotation is 2.81× its same-gear no-Exsanguinate control; the 1× alternative is 1.85×. These are comparisons of the tested rotations, not every competing Legendary build.
- **Shadow builds retain fuel synergy:** Death Touch, Dusk Strike and BD’s Rending/Opportunity/Virulent Corruption still generate and protect Shred. The change removes free repetitions of the payoff. It does not remove the ability to build around Shred or remove other sources of global Retrigger Chance.
- **Extreme scaling is reduced substantially:** the generator-validated max-roll endpoint falls from 84,845,684 to 4,989,106 removal per 30 seconds at 2× (94.1% lower). At 1× the new result is 2,494,553. At 185 Shred Value and 500 stacks, each capped root is now one 185,000-health removal at 2× or 92,500 at 1×; no factor of 17 from Exsanguinate repeats remains. Short cooldowns and attack-fuel generation still support high sustained output.
- **RNG ordering matters:** dropping a repeat chance trial changes later random draws. Ordinary damage, cast counts, Shred generation and even original-cast totals can therefore differ from the old same-seed results. The report uses actual reruns, not the old total minus its repeated-removal field. Same seeds and inputs do not imply paired downstream RNG streams across eligibility modes.
- **Coefficient comparison remains clean:** within the new no-retrigger mode, 1× halves every removal magnitude relative to 2× and leaves ordinary/unaffected distributions identical. All new aggregate and retained-sample Exsanguinate repeat counts and repeated removal are exactly zero.
- **Balance interpretation:** disabling Exsanguinate repeats targets the high-retrigger amplification more strongly than the ordinary 12%-chance setups. It is a distinct change from the coefficient reduction. The endpoint remains an extreme generator fixture; neither its acquisition nor earned-run difficulty is established by these dummy windows. No further balance change is adopted here.

## Method, counterplay and verification

- Same seven D087/D089 dataset labels, IDs, complete ranked payloads, rotations, equipment, resolved stat/source fields, target overrides, starting gold, duration and seed IDs. Two new isolated copies: `exsang_no_repeat_2x` and `exsang_no_repeat_1x`, with redirected saves/userdata. Only the latter changes the copied root coefficient. Production remains 2×/no retrigger.

- Each new copy runs 24 original profiles,20 Shadow/hybrid profiles,8 defense profiles and6 confirmed rotation/other-tree cases (58×200=11,600 final windows), plus the same72×12=864 screening windows. **24,928 new valid windows across260 scenario evaluations**, compared with the two frozen repeat-enabled baselines. Some evaluations overlap as controls. All seeds/scenarios valid; overflow remains a failed simulation. HP1b is solely an endurance fixture, not a time-to-kill result.

- Armor/block/resistance bypass remains; full Shadow remains vulnerable to cleanse and the hybrid retains Shred cleanse immunity. Attack-fed builds lose fuel against dodge; Bribery is a separate theft-fed route. The same matched defense cases were rerun at both coefficients and are included in the full dataset.

- **485 production-rule checks pass** across T7 combat118, Dance52, Balance Lab metrics53, combat feedback130, mixed Combat Log22 and skill presentation110. These cover numeric/guaranteed exclusion, no repeat trial/RNG or phantom Meditation, actual stack consumption, ordinary attack/Poison repeats, zero fuel and combined log accounting. **75 additional candidate checks pass**: copied1×metric expectations53 and mixed-log22. Real saves/production Godot were not launched.

- [Verification manifest](../../../work/m8_t9_presentation/d090_verification.json) records the exact production file allowlist, unchanged protected resources/systems, source parity, executed results and dataset hashes. Native metric fields remain compatible and zero-valued for removed repeats.

- [All four-mode comparisons CSV](../../../project/reports/balance/exsanguinate_no_repeat_review/comparison.csv), [analysis JSON](../../../project/reports/balance/exsanguinate_no_repeat_review/analysis.json), [analyzer](../../../tools/p6/analyze_exsanguinate_no_repeat.py). [D087 build definitions](P6M8_T10_Dance_Fix_And_Shadow_Exsanguinate_Review.md) retain exact rotations/allocations/gear and endpoint qualifications; [D089](P6M8_T10_Exsanguinate_One_Times_Comparison.md) remains the historical repeat-enabled coefficient experiment.

**Decision state:** cannot Retrigger implemented at user request; 2× retained as the live coefficient. Both no-retrigger coefficient results are ready for review. Broader T10, earned progression, playtesting and final regression/export acceptance remain open.
