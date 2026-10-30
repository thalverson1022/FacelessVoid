# T10 adopted Exsanguinate balance

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. [Current context](../../P6_Project_Onboarding_Context.md).

2026-10-25, D091. User approved **1× Armor Shred Value with no retriggers**, requested applying it to the game and updating tooltips/specification. This is now the production rule; the earlier 1× experimental status and 2× coefficient are superseded.

## Adopted behavior and copy

- Consume all actual Shred once. Remove `resolved Shred Value × actual stacks consumed` health. Zero stacks removes zero health.
- Exsanguinate cannot Retrigger, including at 100%/overcap chance or through guarantees. No repeat chance trial or repeat-based Meditation grant. Other eligible attack/Poison retriggers retain their rules.
- Retain Debuff classification, 300 ms base/minimum cast, 8s base cooldown, ordinary CDR/timing, mitigation bypass, no crit/damage-bonus scaling, armor restoration and Death Pact exclusion.
- Nightkiss effect: **Grants: Exsanguinate** / **Consume all Shred to remove 1x the Armor Shred value in health.**
- Skill effect: **Removes <value> health per stack of Shred consumed** / **Cannot Retrigger**. Both compact hover and detailed effect summary resolve `<value>` once from the current Shred Value. At Shred Value 60, the tooltip reads 60 and consuming three stacks removes 180 health.
- Combat Log continues to include Exsanguinate in Damage/DPS and Damage By Skill. Native metrics retain separate internal removal fields and zero repeat fields.

## Verification

Fresh isolated `exsang_adopted_1x` project, redirected saves/userdata; no production Godot launch or real-save access. Seven focused suites pass **942 checks**: T7 combat 119, Dance 52, native metrics 53, combat feedback 130, mixed Combat Log 22, skill presentation 110 and item presentation 456. Balance Lab import regression also passes. A finite-target boundary verifies that ten Shred at value 60 remove 600 health and cannot defeat a 601-HP target, despite large damage bonuses and full Retrigger Chance. The actual Nightkiss fixture consumes six stacks for 360 and restores armor.

Actual-size 1280×720 renders pass 135 additional UI checks (skill hover 63, actual UI 72). Inspected [skill hover](../../../work/m8_t9_presentation/exsang_adopted_1x/project/reports/t9_skill_hover/exsanguinate_nightkiss.png) and [Nightkiss item panel](../../../work/m8_t9_presentation/exsang_adopted_1x/project/reports/t9_ui_review/practice_nightkiss_kitana.png): resolved amount, Cannot Retrigger, 1x item copy and wrapping fit the existing surfaces.

The production resolver is identical to the previously tested D090 1×/no-retrigger resolver. Its 12,464 valid study windows therefore describe the adopted mechanics; no new full DPS rerun is claimed. [D090 comparison and complete data](P6M8_T10_Exsanguinate_No_Retrigger_Comparison.md). Selected mean combined DPS over 30s, 200 seeds:

| Build | Adopted DPS |
| --- | ---: |
| User 35 BD / 10 Thief rotation | 1,251 |
| 35 Shadow / 10 BD, Nightkiss only | 1,004 |
| 29 BD / 16 Shadow, Nightkiss only | 3,107 |
| BD-focused five Legendaries | 4,709 |
| 29 BD / 16 Shadow, five Legendaries | 5,634 |

[Verification manifest](../../../work/m8_t9_presentation/d091_verification.json) records source hashes, isolation, exact tested-resolver parity, executed checks and the protected project-file audit. No item affixes, artwork, acquisition/loot rules or save schemas change.

## Corrections to previous notes

D090's six production suites total **485**, not 585: 118+52+53+130+22+110. Its 75 candidate checks remain correct; the combined D090 total is 560, not 660. Pass statuses and native results are unchanged. The report, tracker and manifest are corrected.

Nightkiss has no Retrigger Chance affix. Its supplied stats remain +50 Shred Value, +5 All Stacks and 20% Shred Chance. The 12% cited for the 35-BD fixture is a resolved build stat from its tree setup, not the weapon. Previous notes attributing it to Nightkiss are corrected; serialized scenario stats and measured results remain unchanged.

T10 remains In progress for the broader balance/exploit work. T9 overall presentation review remains Pending input; this adoption does not claim earned-run balance or final export acceptance.
