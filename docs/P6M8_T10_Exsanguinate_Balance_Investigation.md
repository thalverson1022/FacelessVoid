# T10 focused Exsanguinate Balance Lab investigation

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

2026-10-24, D086. User requested low/mid/top simulations after observing about 64,000 health removal in 30 seconds with 35 Bladedancer / 10 Thief and Nightkiss only. This is a focused T10 investigation; no balance change or overall T10 completion is adopted.

## Result

The reported result is reproduced in scale: the matching rotation has median **64,750**, mean **67,919**, and 5th–95th percentile range **36,260–110,260** health removed in 30 seconds. Ordinary damage averages 17,949 separately. Exsanguinate contributes 79.1% of combined health loss.

| Tested profile | Mean removal / 30s | Removal /second | 5th–95th percentile / 30s |
| --- | ---: | ---: | ---: |
| Nightkiss, no talents | 2,070 | 69 | 720–3,600 |
| 35 BD, no secondary | 38,554 | 1,285 | 18,130–65,120 |
| Your rotation: 35 BD / 10 Thief | 67,919 | 2,264 | 36,260–110,260 |
| Nightkiss only, focused rotation | 106,381 | 3,546 | 69,560–155,770 |
| Five Legendaries, focused rotation | 321,267 | 10,709 | 199,430–482,850 |
| Depth-12 max-roll gear, focused rotation | 84,823,732 | 2,827,458 | 84,147,620–84,915,000 |

![Measured Exsanguinate range](../project/reports/balance/exsanguinate_study_review/overview.png)

These are sampled build profiles, not progression percentiles or proof of a global optimum. The last row is a deliberately extreme but generator-validated max-roll endpoint, not a normal earned build or an observed drop seed. The zero-fuel floor is 0. Damage/DPS retain their existing meanings; health removal and combined health-loss rate are separate measurements.

## Reproduction and method

- Actual `BalanceLab.run_scenario_spec` with current ranked registry and CombatResolver, full 30-second windows. All final profiles use combat seeds 1–200, zero starting gold, five-slot ownership limits and no stat overrides. The empty dummy has zero defenses; HP is raised to 1 billion solely to keep an endurance target. These are output measurements, not calibrated time-to-kill or earned-run win rates.
- User rotation mapped to current skill names: Dance of Death → Quick Cut → Heavy Slash → Parry Strike → Leaping Plunge → Exsanguinate. All 35 BD ranks are maxed. The unspecified 10 Thief allocation is assumed to be the existing protocol baseline: Sticky Fingers 5 / Fast Hands 5. Therefore this is a closely matching reproduction, not an exact saved-setup replay.
- Nightkiss-only comparisons use no other gear. A control removes Exsanguinate from the same build/weapon rotation, avoiding a weapon-base-damage confound.
- Matched weapon references add 3×200 windows. Mithril Karambit with the same five ordinary skills averages 24,811 damage; with the prior protocol rotation it averages 23,821. Nightkiss without Exsanguinate on that protocol averages 17,054. Your Exsanguinate rotation averages 85,868 combined health loss. This supports the concern against a relevant Bladedancer weapon reference, without claiming every weapon/build was optimized.
- Native current-rule profiles: 24×200=4,800 windows. Copied-runtime Dance diagnostics: 11×200=2,200. Bounded rotation search: 50×12=600. Final candidate rotations are re-evaluated on 200 seeds; search is not exhaustive. Pilot runs are retained separately and excluded from these headline totals.
- All selected native scenarios are valid across their complete seed sets. Candidate overflow remains invalid, and the 1024-candidate /depth 16 rules are unchanged. A pass status here means successful execution, not balanced gameplay.
- Balance Lab now exposes health removal, combined loss, consumed Shred and original/repeated activations. Cooldown-blocked attempts are counted separately: a zero-retrigger cooldown fixture produces 292 attempts but only 4 actual roots in 30 seconds. Existing damage/DPS and native invalid-result handling are unchanged. The focused measurement test passes 53 checks; the existing Balance Lab import regression also passes.

## Why it scales

1. Full BD resolves **185 Shred Value**: base 10 + Nightkiss 50 + Weakness 25 + Virulent Corruption 100. Exsanguinate therefore removes **370 health per actual consumed stack**, bypassing damage mitigation.
2. Nightkiss+5 All Stacks and Virulent Corruption+2 turn a normal Shred proc into 8 stacks; Rending Slash applies 9 plus its separate chance proc. Shred can accumulate to 500. Virulent Corruption protects it from cleanse.
3. The user-like build consumes an average 106.94 stacks across 3.00 actual roots. Roots account for 39,568 removal; free repeats add 28,351 without consuming more Shred.
4. Numeric Retrigger Chance is 12%. Repeating the whole captured stack total multiplies the payoff; repeats preserve that capture through depth 16. The expected simple-chain multiplier outside Dance is Σ(p^k), k 0..16, about 1.136 at p=.12. At 100%, one root produces 17 full-value activations.
5. Cooldown reduction and faster fuel generation combine. The tested rare endpoint has two valid Unique items and two all-positive Chaos items at depth 12, using actual generator endpoint values and eligibility checks. Chaos legitimately permits duplicate outcomes. It resolves 100% Retrigger Chance, +20 Shred stacks, doubled applications and a 393ms Exsanguinate cooldown. It is not arbitrary player-stat inflation.

## Dance correctness finding

The [approved Dance contract](P6M5_T3_Bladedancer_Design_Review.md) requires connected macro **attacks** and explicitly excludes nonattack skills. Current tooltips still say attacks. The lifecycle currently supplies the Dance guarantee for every macro skill; M8 made Exsanguinate repeat-eligible, exposing that broad flag to a Debuff. No explicit design approval broadening Dance to Debuffs was found.

A copied-runtime diagnostic suppresses only Exsanguinate's Dance guarantee, retaining numeric retriggers, Shred, gear, cooldowns and every other rule. Your rotation's mean falls **67,919 → 44,905** (33.9% lower). It still produces 3.09× the control's combined health-loss rate. The focused five-Legendary rotation falls321,267 → 231,644; the 100%-retrigger endpoint remains enormous because numeric repeats still reproduce the capture.

This is a likely eligibility bug to correct before balance tuning. The diagnostic is not promoted to production. Same seed sets are used, but changed branching can change RNG consumption; comparisons describe distributions rather than claiming identical downstream rolls.

## Counterplay and limits

- Armor, block and Poison resistance reduce ordinary damage but do not reduce Exsanguinate removal in the matched target comparison. Cleanse does not reduce full-BD Shred because of Virulent Corruption.
- Dodge and slow reduce attack-fed Shred and total output. Exsanguinate itself does not roll an attack hit. The tested 32 BD /13 Thief Bribery branch supplies Shred through Pick Pocket and retains removal even against 100% dodge; this is a counterplay gap, not generic dodge immunity for every build.
- Maximum captured root at this185 Shred Value and500 cap is 185,000 removal;17 activations give3,145,000 per root. This is a per-root bound, not sustained output. The 300ms cast minimum gives a very loose30-second envelope, not an achievable global optimum.
- Fixed-roster high build: Nightkiss, Crown of Concentration, Cloak of Speed, Lolzorz’s Locket, Serpent’s Coil. Its searched rotation is Dance → Quick Cut → Quick Cut → Parry Strike → Exsanguinate. Other tested five-Legendary variants include Wingjammer, Mysterious Lucky Coin and Signet branches.
- Loot probability, rarity timing, gold opportunity cost and earned acquisition of extreme gear are not simulated. Full build ranks and endpoint gear are fixtures. No final T10 balance acceptance, full-run validation or export qualification follows from these tests.

## Recommendation for review

**The concern is supported by the measurements.** First correct Dance’s attack-only eligibility as a focused bug fix, then retest. That alone does not contain Exsanguinate’s ceiling. Next evaluate a constraint on full captured-value repeats, or a revised Shred-to-health conversion, with a stated target contribution for the naked Nightkiss build and an explicit desired relationship to negative-armor physical builds. A coefficient-only nerf cannot remove the 17× echo scaling. No tuning value is adopted in this investigation.

## Evidence

- Runner: `project/scripts/tools/run_exsanguinate_study.gd`; analysis: `tools/p6/analyze_exsanguinate_study.py`.
- Legal endpoint helper: `project/tests/fixtures/exsanguinate_top_gear.gd`; validated actual generation plans, endpoint values, unique slots, SaveSystem domain validation and exact payload round trips.
- [All-profile CSV](../project/reports/balance/exsanguinate_study_review/all_profiles.csv), [analysis JSON](../project/reports/balance/exsanguinate_study_review/analysis.json), [manifest](../work/m8_t9_presentation/exsanguinate_study_verification.json).
- Copied projects and redirected APPDATA/LOCALAPPDATA/save paths only. Production combat, loot, player saves, sibling project and art are unchanged. Existing certificate/resource-exit diagnostics remain. Generated reports are local evidence excluded by the checkpoint ignore policy.
