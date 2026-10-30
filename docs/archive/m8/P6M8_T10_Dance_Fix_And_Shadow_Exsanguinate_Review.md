# T10 Dance correction and Shadow Exsanguinate review

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. [Current context](../../P6_Project_Onboarding_Context.md).

**Historical baseline:** D090 subsequently removed Exsanguinate retriggers. This report retains the earlier repeat-enabled measurements; [current no-retrigger implementation and DPS comparison](P6M8_T10_Exsanguinate_No_Retrigger_Comparison.md).

2026-10-24, D087. User authorized fixing Dance's attack eligibility, rerunning Exsanguinate and exploring other trees, especially 35 Shadow / 10 Bladedancer. Exsanguinate tuning remains unchanged. This supersedes D086's copied-only Dance diagnostic with a production fix and corrected-runtime measurements; the [earlier report](../../P6M8_T10_Exsanguinate_Balance_Investigation.md) remains the historical before-fix evidence. Broader T10 is In progress; T9 remains Pending input.

## Dance fix

The shared resolver now passes its existing actual-attack classification to the Bladedancer lifecycle. Dance requires that classification and a macro origin. Connected physical/stack-scaling attacks retain the guarantee, including fully blocked hits; dodges and nonattacks do not produce a guaranteed repeat. Exsanguinate remains a Debuff with ordinary numeric retriggers. Its repeats retain the captured removal and do not consume Shred again. Triggered attacks do not acquire a separate macro-only Dance guarantee.

Only two existing runtime files changed in this task: `bladedancer_effect_lifecycle.gd` and its caller in `combat_resolver.gd`. No item values, Exsanguinate coefficient, loot rules, save implementation/schema or artwork changed. The existing direct lifecycle test supplies the new explicit classification.

## Corrected results

Every final row below uses 200 seeds and a full 30-second endurance window. Numbers are mean **Exsanguinate health removal**, excluding ordinary damage. They are sampled build outputs, not earned-progression percentiles or a global maximum.

| Build / rotation | Before fix | After fix | Ordinary damage after fix |
| --- | ---: | ---: | ---: |
| Nightkiss, no talents: Stab / Exsanguinate | 2,070 | 2,070 | 580 |
| User rotation: 35 BD / 10 Thief | 67,919 | 44,905 | 17,949 |
| 35 BD / 10 Thief, Nightkiss, focused rotation | 106,381 | 102,538 | 5,664 |
| 35 BD / 10 Thief, five Legendaries, focused rotation | 321,267 | 231,644 | 52,720 |
| Generator-validated max-roll endpoint, focused rotation | 84,823,732 | 84,845,684 | 350,973 |

The user rotation is Dance → Quick Cut → Heavy Slash → Parry Strike → Leaping Plunge → Exsanguinate. The unspecified Thief ranks remain Sticky Fingers 5 / Fast Hands 5. Nightkiss-only focused rotation is Dance / Quick Cut / Exsanguinate; the five-Legendary row adds another Quick Cut and Parry Strike before Exsanguinate.

The user-like result falls **33.9%**. Its corrected median is **39,960**, with 5th–95th percentiles **24,420–78,810**. It averages 3 original casts, 0.37 repeats and 106.94 consumed Shred stacks. Combined ordinary damage plus removal is 62,854, versus 20,310 for the same weapon/build with Exsanguinate omitted from the rotation: about **3.09×** combined health loss in this comparison.

The extreme endpoint remains enormous because its numeric Retrigger Chance is 100%. One captured root still produces 17 activations at the retained depth-16 limit. Its 393ms Exsanguinate cooldown, doubled stack applications and high stack bonuses remain accepted rules. It is a legal generator-endpoint fixture, not an observed drop seed or normal earned build. The small before/after increase is not evidence of a buff: changing guarantee eligibility changes repeat classification/RNG consumption, while numeric full-burst repeats remain available. No claim of paired downstream RNG equality is made.

![Corrected Exsanguinate profiles](../../../project/reports/balance/exsanguinate_corrected_review/overview.png)

## Other trees: value versus stack generation

The active ranked resources have only these talent sources of Shred Value; legacy, unpromoted talent files are excluded from this audit.

| Source | Shred Value | Other relevant behavior |
| --- | ---: | --- |
| Base player + Nightkiss | 10 + 50 | Nightkiss also supplies +5 All Stacks and 20% Shred Chance; the tested BD build’s 12% Retrigger Chance comes from its tree setup |
| BD Weakness, ranks 1–5 | +5 / 10 / 15 / 20 / 25 | Available at the start of the tree |
| BD Virulent Corruption, rank 1 | +100 | Gate 20; +2 Shred stacks and Shred cleanse immunity |
| Shadow Dusk Strike, rank 1 | +10 | Gate 15; a Decay application also applies an independent `1 + bonus Shred stacks` packet, subject to normal stack modifiers |

Shadow **Death Touch** supplies +3 / +6 / +9 All Stacks at ranks 1–3 (gate 10). This increases both Shred and Decay application sizes. Dusk's independent Shred packet does not multiply by every individual Decay stack. Shadow Mastery increases ordinary damage/flat damage, which does not scale Exsanguinate's health removal.

Thief and Assassin have no current Shred Value talent. Thief's **Bribery** supplies 2 / 4 / 6 base Shred per credited theft, plus bonus Shred stacks; it can provide fuel without an attack connecting. Fast Hands can increase cast throughput through increased-gold scaling. Assassin Quick Hands provides attack speed; its critical bonuses do not make Exsanguinate crit. Current gear's general damage/All Stats multipliers do not multiply Shred Value.

## Shadow and hybrid results

| Allocation / rotation | Shred Value | Bonus Shred stacks | Nightkiss only: removal / 30s | Five Legendaries: removal / 30s |
| --- | ---: | ---: | ---: | ---: |
| 35 Shadow / 10 BD: Beguiling Strike / Exsanguinate | 95 | 14 | 62,059 | 99,935 |
| 35 Shadow / 10 BD: Quick Cut / Beguiling Strike / Exsanguinate | 95 | 14 | 41,339 | 76,408 |
| 32 BD / 13 Shadow: Dance / Quick Cut / Exsanguinate | 185 | 16 | 164,256 | 389,129 |
| 29 BD / 16 Shadow: Dance / Beguiling Strike / Quick Cut / Exsanguinate | 195 | 16 | 205,713 | 397,063 |

The five-Legendary set is Nightkiss, Crown of Concentration, Cloak of Speed, Lolzorz's Locket and Serpent's Coil. Full-roster and alternate 10-BD allocations are included in the raw results. Full Shadow does not unlock Dance with only 10 BD points; Dance requires 12. A legal 33 Shadow / 12 BD comparison is included, explicitly dropping Death Blade rather than pretending the full 35-point tree can also take Dance.

The 29/16 hybrid is the strongest **tested fixed-Legendary** candidate in this exploration. It retains Weakness, Virulent Corruption, Dance, Precision and Opportunity/Rending, and adds Death Touch 3 and Dusk Strike. Normal Shred packets become 17 stacks, Rending's authored packet becomes 18, and Decay can add an independent 17-stack Shred packet. This is a larger gain from generation than from Dusk's +10 value. At 195 value, Exsanguinate removes 390 health per consumed stack. The Nightkiss-only hybrid consumes 464.4 stacks across four roots on average, plus ordinary numeric repeats. Its 5th–95th percentile removal is 146,640–293,670; the five-Legendary counterpart is 267,930–592,410.

Exact hybrid ranks: all BD ranks maxed except Weapon Master 0, Side Step 0 and Sharpened Edge 2; Shadow Blind Spot 5, Snake Oil 4, Coated Weapons 1, Death Touch 3, Deception 2, Dusk Strike 1. Full Shadow/BD10 uses all 35 Shadow ranks plus Weakness 5 / Whetstone 5. Full Shadow's Death Blade suppresses Stab Poison applications, not Shred or Exsanguinate.

The bounded 72-case search screened allocations/rotations on 12 seeds; selected additional Shadow rotations and other-tree comparisons were rerun on 200 seeds. The leading hybrid rotations were already in the 200-seed representative set. Additional Shadow screening winners did not exceed the two-skill Beguiling Strike baseline after confirmation. Other-tree confirmed Nightkiss-only means: 35 BD / 10 Assassin 87,398; 35 Thief / 10 BD 23,305. Their corresponding five-Legendary means are 206,118 and 44,469. These are rotation fixtures, not optimized ceilings for those trees.

## Counterplay and balance implications

Matched Nightkiss-only defense cases:

| Target | 35 Shadow / 10 BD | 29 BD / 16 Shadow |
| --- | ---: | ---: |
| Empty dummy | 62,059 | 205,713 |
| Armor 1,000 / block 100 / Poison resistance 90% | 62,059 | 205,713 |
| 100% dodge | 0 | 0 |
| 50% slow | 34,713 | 125,026 |
| Cleanse every 3 counted attacks | 12,355 | 205,713 |

Exsanguinate itself bypasses mitigation and does not roll an attack hit. Dodge constrains the attack-fed fuel in these builds; it is not a universal counter because Bribery has a separate theft-fed route. Full Shadow is vulnerable to cleanse. The hybrid keeps Virulent Corruption's Shred immunity, so cleanse is not a useful Shred counter there. Death Pact remains unchanged: Exsanguinate consumption does not activate it.

**Review finding:** the Dance bug inflated the original setup, but its correction does not resolve the broader balance question. The limited number of Shred Value sources does constrain per-stack scaling; Death Touch, Rending/Opportunity, Dusk, free captured-burst repeats and cooldown reduction still create substantial scaling through fuel and cast frequency. The 500-stack cap and depth limit bound individual bursts; they do not by themselves ensure reasonable sustained output. No coefficient, cap, repeat or item-value change is adopted in D087.

## Verification and reproducibility

- Native Balance Lab and main CombatResolver in a fresh isolated project; real player saves and production runtime were not launched. Empty dummy HP is raised to 1 billion solely to keep the 30-second window alive. Starting gold 0; actual ranked allocations and fixed/generated equipment resources; no player-stat overrides.
- 24 corrected original profiles + 20 Shadow/hybrid profiles + 8 defense profiles + 6 confirmed search/other-tree profiles, each 200 seeds: **11,600 final windows**. Separate 72×12 screening adds **864**, totaling **12,464 valid windows across 130 scenario evaluations**. Some evaluations deliberately overlap as controls. All selected scenarios complete with zero invalid seeds/scenarios; candidate overflow remains invalid, not a high-output success.
- New live-resolver regression: **82 checks pass**. Restoring the old eligibility bug in an isolated copy causes 14 failures; restoring the fix passes again. Existing effect-lifecycle suite passes. Repeat/status suites each retain the same six historical pre-T2 signature mismatches in both old-guard and fixed-guard runs, with no new scoped failures. Corrected measurement test passes **53 checks**; Balance Lab import regression passes.
- [Verification manifest](../../../work/m8_t9_presentation/d087_verification.json) records runtime source parity, source hashes, completed native result hashes and unchanged existing project files outside the two runtime edits and one direct-test fixture. Known certificate/exit-resource diagnostics are retained; no unexpected engine/script errors in selected simulations.
- [All profiles CSV](../../../project/reports/balance/exsanguinate_corrected_review/profiles.csv), [machine-readable analysis](../../../project/reports/balance/exsanguinate_corrected_review/analysis.json). Regenerate aggregates/chart/manifest with `python tools/p6/analyze_exsanguinate_corrected.py` after running the native study tools. Detailed specs, allocations, rotations, equipment, seeds, aggregates and sampled events remain under `work/m8_t9_presentation/exsang_dance_fixed/project/reports/balance/exsanguinate_study`.
- Reusable scenario tools: [original corrected profiles](../../../project/scripts/tools/run_exsanguinate_study.gd) and [Shadow search/profiles/defenses](../../../project/scripts/tools/run_exsanguinate_shadow_study.gd). Import/run them through the existing isolated runner; never use live player saves. One validation-only roster alias error was fixed before final runs; that failed pilot is retained and excluded from totals.

Earned acquisition, target lifetimes, full-run difficulty and opportunity costs remain outside these endurance simulations. T10 review remains open; this work does not complete T9, T10, playtesting or final export qualification.
