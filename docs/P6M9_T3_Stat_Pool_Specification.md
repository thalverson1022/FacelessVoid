# M9-T3 — Pants and Gloves stat-pool specification

**Runtime update — D016:** T6 now implements these approved pools and equal eligible-slot acquisition. See [T6 verification](P6M9_T6_Stat_Pools_And_Acquisition_Verification.md). The original T3 specification/review record below retains its historical approval boundaries.

2026-10-25. **Approved under P6M9-D007, amended by P6M9-D008; T3 Complete.** D008 explicitly replaces all Basic weights with equal weight 1 across every slot; approved Rare/Special weights and category pool order remain unchanged. This is a documentation specification, not implemented seven-slot behavior or a gameplay/balance pass.

## Authority and approval boundary

The [M9 tracker](P6M9_Gear_Slot_Expansion_And_Progression_Pacing_Tracker.md#confirmed-pool-inputs) is the single confirmed source for new-slot membership, categories and base ranges. This document translates those inputs to canonical IDs and retained mechanics from the [T2 audit](P6M9_T2_Gear_System_And_Pacing_Audit.md) and [M8 specification](P6M8_T3_Gear_Stat_Implementation_Specification.md). Current source governs retained behavior: [catalog](../project/scripts/systems/stat_catalog.gd), [generator](../project/scripts/systems/gear_generator.gd), [StatSheet](../project/scripts/resources/stat_sheet.gd), [damage calculation](../project/scripts/systems/damage_calculator.gd).

**P6M9-D008 — user-directed equal Basic probability:** every Basic row below has weight **1**. This supersedes D007's source-analogue Basic weights, including Basic Magic Find. Rare/Special rows retain their D007-approved source-analogue weights. Equal Basic weights also apply to the five existing runtime slots; their membership, ranges and Rare/Special weights are unchanged. Historical pre-D008 specification/JSON snapshots are retained under `work/m9_equal_basic_weights/`.

Weight 1 means each currently eligible Basic ID has probability `1 / remaining Basic IDs` on that Basic draw. Ordinary canonical-ID uniqueness still excludes previously selected IDs and renormalizes; Chaos still permits duplicates. Basic-derived drawbacks use the same equal weights over their remaining eligible IDs. This does not equalize Rare/Special pools or change Chaos's 5/4/5 category odds.

Tables define deterministic category row order for the approved new pools, matching confirmed input order. Rare/Special source analogues identify retained weights, not replacement ranges; Basic weights follow D008. All numeric modifiers serialize operation **ADD**; decimal `.10` means 10%, flat values are damage units. All Specials are binary, ADD, stored value **1**, including All Stats whose effect is fixed **20%**, not a numeric `.20` affix. Every Basic row supplies a drawback with its same range and weight; Rare/Special rows do not. The [machine-readable counterpart](../work/m9_t3_spec/expected_new_pool.json) records these distinctions.

## Complete approved pools

### Legs / Pants

| Category | Canonical ID | Min | Max | Approved weight | Weight source analogue |
| --- | --- | ---: | ---: | ---: | --- |
| Basic | `percent_physical_damage` | .10 | .20 | 1 | D008 equal Basic weights |
| Basic | `crit_damage` | .50 | .75 | 1 | D008 equal Basic weights |
| Basic | `base_elemental_damage` | 3 | 6 | 1 | D008 equal Basic weights |
| Basic | `percent_elemental_damage` | .30 | .40 | 1 | D008 equal Basic weights |
| Basic | `increased_gold` | .20 | .30 | 1 | D008 equal Basic weights |
| Basic | `increased_magic_find` | .15 | .30 | 1 | D008 equal Basic weights |
| Rare | `chance_for_retrigger` | .03 | .06 | 15 | Trinket Rare |
| Rare | `crit_applies_element` | .10 | .20 | 10 | Armor Rare |
| Rare | `crit_applies_potency` | .10 | .15 | 10 | Armor Rare |
| Rare | `crit_applies_penetration` | .10 | .15 | 10 | Armor Rare |
| Rare | `increased_buff_duration` | .10 | .20 | 8 | Armor Rare |
| Rare | `cooldown_reduction` | .06 | .10 | 8 | Charm Rare |
| Rare | `shop_discount` | .10 | .20 | 5 | Weapon Rare |
| Rare | `increased_magic_find` | .10 | .20 | 5 | Weapon Rare |
| Rare | `increased_gold` | .50 | 1.00 | 5 | Weapon Rare |
| Special | `all_stats_increased` | 1 | 1 | 5 | Armor Special |
| Special | `disable_enemy_dodge` | 1 | 1 | 10 | Armor Special |
| Special | `disable_enemy_block` | 1 | 1 | 10 | Armor Special |
| Special | `disable_enemy_absorb` | 1 | 1 | 10 | Armor Special |
| Special | `disable_enemy_suppress` | 1 | 1 | 10 | Armor Special |
| Special | `disable_enemy_cleanse` | 1 | 1 | 10 | Armor Special |
| Special | `immune_to_stun` | 1 | 1 | 5 | Armor Special |
| Special | `immune_to_slow` | 1 | 1 | 5 | Armor Special |
| Special | `immune_to_interrupt` | 1 | 1 | 5 | Armor Special |
| Special | `inventory_economy_stats` | 1 | 1 | 5 | Armor Special |

### Hands / Gloves

| Category | Canonical ID | Min | Max | Approved weight | Weight source analogue |
| --- | --- | ---: | ---: | ---: | --- |
| Basic | `base_damage` | 2 | 5 | 1 | D008 equal Basic weights |
| Basic | `percent_physical_damage` | .15 | .25 | 1 | D008 equal Basic weights |
| Basic | `crit_chance` | .06 | .08 | 1 | D008 equal Basic weights |
| Basic | `crit_damage` | .50 | .75 | 1 | D008 equal Basic weights |
| Basic | `base_elemental_damage` | 3 | 6 | 1 | D008 equal Basic weights |
| Basic | `percent_elemental_damage` | .30 | .40 | 1 | D008 equal Basic weights |
| Basic | `increased_gold` | .15 | .30 | 1 | D008 equal Basic weights |
| Basic | `increased_magic_find` | .10 | .20 | 1 | D008 equal Basic weights |
| Rare | `chance_for_retrigger` | .03 | .06 | 15 | Trinket Rare |
| Rare | `chance_to_shred` | .08 | .10 | 10 | Helm Rare |
| Rare | `chance_to_decay` | .08 | .10 | 10 | Weapon Rare |
| Rare | `crit_applies_element` | .12 | .18 | 15 | Charm Rare |
| Rare | `increased_buff_duration` | .08 | .14 | 8 | Weapon Rare |
| Rare | `cooldown_reduction` | .06 | .10 | 8 | Charm Rare |
| Special | `convert_damage_to_physical` | 1 | 1 | 5 | Weapon Special |
| Special | `convert_damage_to_magical` | 1 | 1 | 5 | Weapon Special |
| Special | `ignore_armor_no_shred` | 1 | 1 | 5 | Charm Special |
| Special | `ignore_resistance_physical_penalty` | 1 | 1 | 5 | Charm Special |
| Special | `double_applied_stacks` | 1 | 1 | 5 | Charm Special |
| Special | `disable_enemy_dodge` | 1 | 1 | 10 | Armor Special |
| Special | `disable_enemy_block` | 1 | 1 | 10 | Armor Special |
| Special | `disable_enemy_absorb` | 1 | 1 | 10 | Armor Special |
| Special | `disable_enemy_suppress` | 1 | 1 | 10 | Armor Special |
| Special | `disable_enemy_cleanse` | 1 | 1 | 10 | Armor Special |

### Totals, eligibility and exhaustion

| Pool | Basic rows / weight | Rare rows / weight | Special rows / weight | Total rows / weight | Drawback rows / weight |
| --- | --- | --- | --- | --- | --- |
| Pants | 6 / 6 | 9 / 76 | 10 / 75 | 25 / 157 | 6 / 6 |
| Gloves | 8 / 8 | 6 / 66 | 10 / 75 | 24 / 149 | 8 / 8 |
| Added | 14 / 14 | 15 / 142 | 20 / 150 | 49 / 306 | 14 / 14 |

Added positive rows comprise **29 numeric + 20 binary** rows; drawback projections add 14 signed numeric rows, not extra positive membership. The retained 99-entry pool becomes **148 positive entries**, with retained 33 drawbacks becoming **47**. Counts are slot/category occurrences, not globally distinct IDs. Pants has 23 unique canonical IDs across its 25 rows (gold and Magic Find overlap); Gloves has 24. All approved weights are positive; every unlisted new-slot/category ID is absent/disabled, not an enabled default-weight fallback.

The confirmed new-slot inputs supersede M8's historical blanket removal of Basic Magic Find and restriction of Rare economy to Weapon **for these two new slots only**. They do not alter old-slot membership or ranges. D008 separately and explicitly changes Basic weights in all seven slots.

Explicit exclusions: Pants has no physical base damage, Crit Chance, attack speed, Shred/Decay chance, stack bonus, conversion, bypass or doubled-stack Special. Gloves has no attack speed, stack bonus, discount, Rare gold/Magic Find, crit-Penetration/Potency, All Stats, immunity or inventory-economy Special. Neither has Decay-applies-Shred or Poison-cap Special. Gloves has exactly one elemental-base row, **3–6**, never 6–10; `base_damage` 2–5 remains distinct. Percent Damage is `percent_physical_damage`.

Drawbacks are derived only from that slot's **Basic membership** plus global drawback permission. Thus Pants/Gloves Basic Magic Find is eligible; Pants Rare discount/Magic Find/gold are not drawback rows even though their global definitions permit drawbacks. Drawbacks use the Basic category range, carry DRAWBACK metadata/flag and a negative numeric value. There are no negative timing/proc/Special rows or separate drawback strength rule.

Ordinary selection uses one canonical used-ID set across the whole item, categories and signs. Selecting Pants Basic gold excludes Rare gold and negative gold; Basic Magic Find excludes Rare Magic Find and its drawback, and vice versa. Category-specific ranges are mandatory: Pants gold `.20–.30` Basic versus `.50–1.00` Rare, Magic Find `.15–.30` Basic versus `.10–.20` Rare. Use explicit category overrides; a single generic range cannot encode both. The catalog's global category label must not override pool membership for Basic Magic Find.

Retain ordered shapes: Basic **B**; Master **BB**; Epic **BBR**; Cursed **BBR + Basic drawback**; Unique **BBBR + S**. Crude starter and fixed Legendary generation stay outside these plans. Exhaustion cannot occur: after the maximum three Basic choices Pants Rare has at least `9−2=7` remaining (only gold/Magic Find overlap), Gloves Rare all 6. Cursed Pants drawback has at least `6−2−1=3` remaining; Gloves at least `8−2=6`. Earlier Basic/Master/Epic/Unique Basic draws need at most 3 from 6/8; Specials share no numeric IDs and retain all 10. Every surviving row has positive weight.

Chaos retains **four independent category selections with replacement**, Basic-positive/Rare-positive/Basic-drawback weights **5/4/5**. Each roll then selects a stat by that pool's weights with an empty used-ID set. Both slots have all three pools, so category probabilities remain 5/14, 4/14, 5/14 on every roll. Duplicate IDs across categories/signs are allowed; no Special outcome. Four negative rolls, four identical Rare rolls, and opposing-sign copies are legal. Nothing about the four-roll shape guarantees at least one positive affix.

## Value scaling and deterministic interface

For a uniformly drawn base value `b`, retain generator order `v = ((b × rarity) × request_scale) × depth_factor`, where `depth_factor = 1 + .35 × (clamp(depth,1,12)−1)/11`. Rarity multipliers are Basic 1, Master 1.75, Epic 2, Cursed ±2.5, Chaos ±3, Unique 2; the minus sign applies only to drawbacks. Normal requests use scale 1; positive finite custom/request scales remain valid, not silently clamped. Reject nonpositive/nonfinite request scale and nonfinite products/results.

Round percent/chance values using Godot `round(v×100)/100`, flat/stack values with `round(v)` (positive stack minimum 1 remains existing behavior). Godot halfway rounding is away from zero, not Python's banker rounding. Binary Specials always return 1 and consume no numeric-value draw. Scaling changes magnitude, never selection weight or Special strength. Preserve existing request/provenance and weighted cumulative integer-draw semantics; do not promise old seeded item signatures after expanding pools/slot sampling.

The table/JSON array order is the approved category pool order; do not sort it alphabetically during implementation. **T5 must specify stable serialized Legs/Hands IDs and deterministic universal aggregation order**, preserving old numeric identities and coherent authored resources. Recommendation for review: append new IDs rather than insert them, and explicitly extend the current order with Legs then Hands; the screenshot UI coordinates remain independent. This is a recommendation, not an adopted enum/order change. T6 must use the reviewed order consistently; acquisition slot-subset policy remains T6. T3 does not adopt seven-slot acquisition odds, fresh gear, reset version, roster or UI/art integration decisions owned by T4–T8.

## Aggregation and seven-slot interaction contract

Seven equipped slots contribute through the same authoritative collection; physical-base Gloves is additive bonus damage, never a second weapon range/signature. Canonical numeric buckets sum signed contributions (legacy MULTIPLY contributes `value−1` through existing exceptions), then existing floors, a single eligible All Stats ×1.2 and caps. Chance buckets retain [0,1] limits; gold/discount/Magic Find have zero floors and no new upper cap. Preserve talent buckets, derived outputs and original-type damage scaling.

All Stats, doubled stacks, enemy denial and immunity retain set/OR semantics: multiple copies do not compound. All Stats stores 1 and applies ×1.2 once; doubled stacks doubles once after ordinary bonuses, with existing status caps/Consume exceptions. Ignore armor still forbids Shred; ignore resistance still applies the fixed 0.5 physical penalty at its current original-physical stage. Both conversions together use **physical then magical mitigation**, independent of equip order; neither last-equipped precedence nor repeated conversion is allowed. Seven slots allow more coexistence, not stronger per-copy binary effects.

**Retained source behavior and documentation correction:** current `StatCatalog.DEFINITIONS` sets `base_elemental_damage.scales_with_all_stats=true`, and StatSheet applies it. Therefore retain elemental base ×1.2; flat physical `base_damage` does not scale. The T2 sentence excluding both flat types has been corrected during this review as a documentation error; no balance change is proposed.

CDR stays per-affix `factor = product(1−min(1,raw_i×A))`, `A=1.2` if equipped All Stats else 1. Preserve deterministic reviewed slot/affix order, ledger entries and finite validation; raw sums are inspection only. No aggregate hard cap; individually saturated 100% factors and positive authored cooldown's **1ms minimum** remain. Buff duration is `d = max(0,sum(raw_i))×A` with no hard cap; existing timers use `ceil(base_ms×(1+d))`, with Death Pact modification first where applicable. Preserve existing affected timed buffs/Penetration/Potency, refresh/expiry, representability guards and build-static derivation, avoiding repeated amplification on rebuild.

Crit Element retains its existing direct-critical-contribution check. Crit Penetration/Potency retain independent local critical direct-contribution trials, Penetration then Potency after existing damage/procs and before finalize; ticks excluded, connected zero-damage rolled crits eligible. Success grants base 1 via normal bonus/doubling/cap50 semantics. Triggering damage receives no retroactive benefit; finalize/cleanse precedes descendants. More available chances must not create an extra crit roll or alter chance-zero RNG behavior.

Only an **equipped** inventory-economy Special activates import of exactly `increased_gold`, `shop_discount`, `increased_magic_find` from owned carried gear (normal acquisition capacity **3**, retaining existing handling of legacy/API occurrences). Import each authoritative carried index once, including negative Chaos copies; no pointer/ID deduplication. No inventory combat stat, timer/proc, All Stats, weapon range, unlock or Legendary signature contributes. Carried Special cannot self-activate/chain. Combine carried/equipped raw economy before floors/All Stats once; equip/swap must move one owned occurrence, and acquire/sell/remove/load rebuild. Preserve pre-purchase discount and persisted offer/reward Magic Find snapshots, existing prices/resale and derived economy-to-combat outputs.

Retain root-subtree depth16/candidate budget1024 and finite arithmetic guards. Budget exhaustion or overflow yields **invalid simulation**, never winning DPS or a silently truncated successful result. Seven-slot proc density and discount/resale behavior remain risks for bounded T9 witnesses and focused T10 review; this spec does not claim their balance is verified or authorize tuning.

## Worked analytical witnesses

These are legal structural/mathematical witnesses, not measured drop frequency, earned-run strength or gameplay passes. Unmentioned affixes on normal items must be filled with distinct eligible IDs; empty remaining equipment slots are legal.

| Witness | Calculation and expected result |
| --- | --- |
| Ordinary weight and collision | First Pants Basic gold probability `1/6`. If first two Basic IDs are gold and Magic Find, Rare total becomes `76−5−5=66`, excluding both IDs; CDR probability on that Rare draw is `8/66`. |
| Basic Magic Find scaling | Pants Basic max `.30`, Master/depth12/scale1: `.30×1.75×1.35=.70875 → .71`; Rare max `.20` on Unique/depth12: `.20×2×1.35=.54`. They cannot coexist on one ordinary item. |
| Rounding ties and drawback | Gloves base-damage base5 on Master/depth1: `5×1.75=8.75 → 9`; Cursed drawback base5: `−12.5 → −13`. Percent base `.10` Cursed/depth1 is `.25`; its drawback is `−.25`. |
| Request/depth clamps | Gloves base-damage base2, Basic/scale1.5/depth0: `2×1×1.5×1=3`; depth99 uses1.35: `4.05→4`. Scale0/NaN fails; All Stats Special remains1 at any valid scale/depth. |
| Opposite Chaos ranges | Pants Chaos/depth1 with Basic MF base `.30` and negative Basic MF base `.15` yields `.90−.45=.45`; two other independent rolls may duplicate either. Rare MF base `.20` is `.60`, not the Basic `.90` maximum. |
| Two timing slots plus All Stats | Unique Pants and Gloves, each max CDR at depth12: `.10×2×1.35=.27`; Pants Special All Stats gives each `.324`, retained factor `.676²=.456976`, effective CDR `.543024`; authored10s becomes `ceil(4569.76)=4570ms`. These two items legally coexist. |
| Seven-slot high-CDR extension | Chaos Weapon `.24`×4, Helm `.32`×4, Charm `.41`×4, Pants `.41`×4, Gloves `.41`×4; Unique Armor supplies All Stats and Trinket can hold any retained item without CDR; leaving it empty produces the same factor. Factor `.712^4×.616^4×.508^12 ≈ .0000109296781`;10s cooldown becomes1ms after ceil/minimum. Each new `.41` is rounded `.10×3×1.35=.405`; do not use banker `.40`. |
| Additive duration with repeated All Stats | Unique Pants duration `.20×2×1.35=.54`, Gloves `.14×2×1.35=.378→.38`; Pants All Stats plus Armor All Stats still `(.54+.38)×1.2=1.104`, a1000ms base timer lasts2104ms. Gloves physical base `5×2×1.35=13.5→14` stays14, while elemental base `6×2×1.35=16.2→16` becomes19.2 through All Stats. |
| Economy activation/sign/floor | Equipped Unique Pants inventory-economy plus equipped Unique Armor All Stats; equipped gold `.30`, carried gold `+.50` and `−.90` gives raw `−.10`, floored0 then ×1.2=0. Without negative copy raw `.80` gives `.96`; removing Pants Special removes all carried imports. Carried All Stats never adds a factor. |
| Binary coexistence/conversion | Unique Weapon physical conversion and Unique Gloves magical conversion may coexist with Pants All Stats and Armor inventory-economy. A100 original-physical packet, neutral scaling/no crit, armor0/block10/resistance.20/absorb5 gives `(100−10)×.8−5=67`; reverse equip order gives67. Duplicate denial/immunity/doubling remains one effect. |

## Required verification and review checkpoint

Completed static review: [verification report](../work/m9_t3_spec/verification.json) and [reproducible verifier](../work/m9_t3_spec/verify_spec.py) reconcile all 49 confirmed rows, their weight policy, units and approved order, plus exact-decimal worked arithmetic. Exhaustive canonical-identity selection finds no dead ends for either slot in any ordinary rarity; all 81 Chaos category shapes per slot have nonempty pools. That original review recorded 2,408 unchanged source/resource/art/test files. D008 subsequently changes only the Basic-weight runtime constants and affected tests; its focused engine evidence is recorded in the tracker. The static checks are not game executions.

Before implementation, retain this review contract: independently compare all49 rows to the tracker; validate canonical IDs/units/ADD operation, exact confirmed ranges, D008 equal Basic weights, retained Rare/Special analogue weights and row order; recalculate counts/weight sums and all14 drawback projections; prove ordinary exhaustion bounds, Chaos duplicate rules and every exclusion. Check local links and source immutability. A machine-readable table is evidence for review, not a runtime pass.

After review, T6/T9 extend existing catalog/slot-eligibility, weighted-selection, rarity-count, uniqueness and scaling fixtures to all seven slots. Include every active rarity, category override, negative Basic Magic Find, Rare-only drawback exclusion, depth clamps/scales/rounding, reproducibility/provenance and fixed-catalog boundaries. Compare old-five-slot membership/ranges/Rare/Special weights exactly and require all Basic weights 1 under D008; expected new total148/47 does not excuse unrelated changes.

T5/T9 verify complete authoritative seven-slot ownership/rebuild/order, equip/swap/sell/destroy and isolated new-save/reset boundaries. Mechanics witnesses must cover separate CDR factors and1ms floor, duration/Pact/overflow, multi-copy Specials, both conversions/original-type penalty, elemental-versus-physical All Stats, proc order/invalid budget consumers, all three carried economy IDs/signs/occurrences and snapshot timing. No live FacelessVoid or sibling Enigma saves are touched by this specification.

**Review completed — P6M9-D007:** the user explicitly approved the proposed per-row weights and deterministic category pool order. **D008 supersedes Basic weights only: all are now 1**, including Basic Magic Find; Rare/Special weights and pool order remain approved unchanged. T3 is Complete. The elemental-base All Stats clarification retains current source behavior and is not a proposed mechanic change. Stable slot IDs/aggregation order remain an explicit T5 interface; acquisition, reset/start gear, Legendaries and artwork remain their assigned tasks. The approval is recorded in M9; T3 completion does not complete any downstream implementation task. Original T3 approval was documentation-only. D008 runtime weight changes and focused engine checks are recorded separately in the tracker; no broad gameplay/balance qualification is claimed.
