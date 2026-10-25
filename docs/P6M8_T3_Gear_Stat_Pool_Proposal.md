# P6M8-T3 — Gear stat pool proposal

**Current implementation authority (2026-10-22):** [T3 implementation specification](P6M8_T3_Gear_Stat_Implementation_Specification.md), prepared under D007. It consolidates the user pool and confirmed decisions below with reconciled weights, aggregation, ownership, save versions and validation rules. This proposal remains the discussion/history record; conflicting earlier defaults are superseded. Implementation and focused verification are complete under D008; see the [closeout](P6M8_T3_Closeout_And_Verification.md).

## Current decisions — 2026-10-22

The user supplied a replacement full five-slot pool in this chat and clarified its rules. **That pool and these confirmed rules supersede the earlier proposed slot/range tables, additive CDR, 30% CDR cap, and exclusion of Penetration/Potency from duration scaling below.** The remaining older proposal is retained as review history, not an implementation authority for those superseded details. The approved implementation is complete; later historical proposal sections remain superseded.

- User ranges are baseline affix values, scaled with existing rarity/depth rules. Rare-category stats remain restricted to rarities that actually roll Rare affixes.
- Cooldown reduction combines **per contribution multiplicatively**: `CDR = 1 - product(1 - c_i)`. User explicitly accepts near-zero cooldowns; **no aggregate CDR hard cap** is required. Keep positive authored cooldowns at least one simulation millisecond and preserve cast-time/resource/deadline rules.
- Increased Buff Duration combines **additively**. It affects timed self-buffs and timed passive buffs, explicitly including **Footwork, Penetration and Potency**. Apply Penetration/Potency duration scaling to their existing `3000 + 1000 * Death Pact rank` milliseconds, preserving refresh, stack-cap, cleanse and consumption rules. Untimed charges gain no invented timer. The earlier proposed 30% duration cap was never approved; its final policy must not be inferred from acceptance of multiplicative CDR.
- Existing All Stacks behavior is retained, including Footwork, Bypass, Poison, Shred, Decay, Penetration and Potency.
- The user's interrupted crit-trigger explanation is interpreted as matching existing Crits apply Poison: conditional chance per connected direct-attack critical contribution; tick crits excluded. This interpretation has been stated in chat; do not invent a separate elemental-damage trigger.

### User-specified replacement pool

Percent Damage maps to physical damage; Increased Rarity maps to Magic Find. Weapon Rare economy values without percent signs are interpreted as percentages. Chest maps to the existing Armor slot. Grouped effects are separate affixes: Penetration and Potency each have the listed range; each denial/immunity is separate. Stack aliases retain the existing single All Stacks identity. These normalizations preserve existing identity conventions.

| Slot | Basic affix baseline ranges | Rare affix baseline ranges | Specials |
| --- | --- | --- | --- |
| Weapon / Dagger | Base Damage +2–5; Physical Damage 10–20%; Crit Damage +50–75%; Base Elemental +3–6; Elemental Damage 30–40%; Gold 20–30% | Shred 8–10%; Decay 8–10%; Retrigger 5–8%; Shop Discount 10–20%; Magic Find 10–20%; Gold 50–100%; CDR 4–6%; Buff Duration 8–14% | Physical conversion; Magical conversion; All Stats +20%; Inventory Economy |
| Helm / Hood | Physical Damage 20–25%; Crit Chance 3–8%; IAS 5–12%; Base Elemental +4–10; Elemental Damage 25–35%; All Stacks +1–2; Gold 40–50% | Shred 8–10%; Decay 8–10%; Crit Poison 20–30%; Crit Penetration 10–15%; Crit Potency 10–15%; CDR 4–8% | Double Applied Stacks; Ignore Armor / No Shred; Ignore Resistance / −50% Physical Damage |
| Armor / Doublet | Physical Damage 10–20%; Crit Chance 2–4%; Elemental Damage 30–40%; Gold 20–30%; All Stacks +1–2 | Shred 8–10%; Decay 8–10%; Crit Poison 10–20%; Crit Penetration 10–15%; Crit Potency 10–15%; Buff Duration 10–20% | All Stats +20%; separate Dodge/Block/Absorb/Suppress/Cleanse denial; separate Stun/Slow/Interrupt immunity; Inventory Economy |
| Trinket / Ring | Base Damage +4–6; Physical Damage 15–25%; Crit Chance 4–6%; IAS 8–10%; Base Elemental +5–8; Elemental Damage 20–30%; Gold 10–20% | Retrigger 3–6%; Shred 8–10%; Decay 8–10%; Crit Poison 10–15%; Crit Penetration 10–15%; Crit Potency 10–15%; Buff Duration 10–12% | Double Applied Stacks; separate Dodge/Block/Absorb/Suppress/Cleanse denial; Physical conversion; Magical conversion |
| Charm / Necklace | Physical Damage 15–25%; Crit Chance 6–8%; IAS 10–15%; Crit Damage +40–60%; Base Elemental +6–10; Elemental Damage 30–40%; Gold 15–30%; All Stacks +1–2 | Shred 8–10%; Decay 8–10%; Crit Poison 12–18%; Crit Penetration 10–15%; Crit Potency 10–15%; CDR 6–10% | Ignore Armor / No Shred; Ignore Resistance / −50% Physical Damage; Double Applied Stacks; separate Dodge/Block/Absorb/Suppress/Cleanse denial |

Omitted old normal-pool entries are removed in this replacement design, not silently retained: Basic Discount/Magic Find are absent everywhere; Rare economy affixes occur only on Weapon. No fixed Legendary resource change is implied. Retained-entry selection weights can be preserved as a proposed default, but weights for new entries/removals and resulting category distributions still need reconciliation. The current runtime still uses the earlier pool.

### CDR arithmetic reviewed by the user

Under normal `value_scale=1`, maximum depth scale 1.35, current rarity multipliers/rounding, and four duplicate Rare affixes per eligible Chaos item:

| Equipped CDR configuration | Effective CDR |
| --- | --- |
| One maximum Epic/Unique roll on Weapon, Helm and Charm, plus All Stats | 59.7991% |
| One maximum Cursed roll on those slots, plus All Stats | 69.5854% |
| Four maximum Chaos rolls on each of Weapon, Helm and Charm | 99.1356% |
| Same Chaos setup plus All Stats on Unique Armor | 99.7536% |

Maximum rounded Chaos rolls are Weapon .24, Helm .32, Charm .41. The All Stats example scales **each affix** by 1.2 before combination: `1 - (.712^4 * .616^4 * .508^4)`. A 10,000ms authored cooldown then rounds up to 25ms. Do not multiply the final combined CDR percentage by 1.2; that can exceed 100%. This per-affix All Stats treatment is the interpretation used for the reviewed calculation. Bounds assume the specified generated ranges, not arbitrarily enlarged Practice/request-scale values. Validate each individual contribution so malformed values cannot produce negative cooldown factors; no additional aggregate balance cap is implied.

These are analytical maxima, not simulated drop likelihoods or evidence of item balance. User acceptance explicitly includes the near-zero endpoint; later tests should verify it works, not silently restore a rejected cap. Timer growth, multiple concurrent buff instances and finite fight/runtime limits still need focused implementation evidence.

### Remaining T3 work

Reconcile selection weights, source-specific multiplicative CDR aggregation, per-affix All Stats, additive duration handling at all eight eligible effect families (the six prior player families plus Penetration/Potency), detailed inventory-economy propagation/compatibility and validation. No extra questions are required to record the two decisions just confirmed. T3 remains a design/implementation task, not Complete; no runtime change is authorized merely by this documentation entry.

## Earlier proposal — superseded where noted above

2026-10-17 revision. **User-selected scope: four Rare stats—Cooldown reduction, Increased Buff Duration, Crits apply penetration, Crits apply potency—and one Special—Economy Stats work in your inventory.** The values, eligible slots, weights and detailed semantics below are **proposals for review, not approved implementation**. This replaces the earlier recovery/Basic/Decay package; Decay activation and cooldown recovery are no longer proposed. T3 remains at design review. No runtime, resource, test or save changes have been made for this proposal.

## Recommended ranges and slots

Ranges below are **base affix ranges before rarity, depth and request scaling**. They are not final displayed rolls. Numeric values are stored as decimals: `.06` = 6%.

| User-selected stat | Category | Proposed eligible slots | Base range | Weight per eligible slot | Proposed aggregate limit |
| --- | --- | --- | --- | --- | --- |
| Cooldown reduction | Rare | Trinket, Charm | **4–6%** (`.04–.06`) | 8 | 30% |
| Increased Buff Duration | Rare | Helm, Armor | **4–6%** (`.04–.06`) | 8 | 30% |
| Crits apply penetration | Rare | Weapon, Trinket | **8–12% chance per qualifying crit** (`.08–.12`) | 10 | 100% chance |
| Crits apply potency | Rare | Helm, Charm | **8–12% chance per qualifying crit** (`.08–.12`) | 10 | 100% chance |
| Economy Stats work in your inventory | Special | Armor, Charm | **Fixed binary effect**, value `1` | 5 | Non-stacking on/off |

The crit stats grant **one base stack on a successful chance roll**, then existing stack bonuses/doubling/caps apply. Their roll value is a chance, not a number of stacks. The Special activates while **equipped**, allowing qualifying stats on carried, unequipped items to contribute.

Trinket/Charm timing competes with existing Rare damage/proc/economy choices; Helm/Armor duration gives alternatives to direct offense. Weapon/Trinket Penetration and Helm/Charm Potency support physical/elemental preparation without making both affixes universal on every item. Armor/Charm Special availability supports a fixed Legendary weapon while competing with current defense-denial/stacking Specials. These are recommendations, not constraints supplied by the user.

The base chances are intentionally below existing high Helm crit-to-Poison ranges: Penetration/Potency can refresh a full debuff and affect negative defense. A 30% timing cap still creates substantial power, quantified below. No new Basic entries, Decay caps, changes to existing stat ranges, rarity shapes, prices, inventory capacity, Legendary effects or enemy compensation are proposed.

## Stable contracts and generation

| Proposed canonical ID | Type / operation | Aggregate floor / cap | All Stats | Generated drawback? |
| --- | --- | --- | --- | --- |
| `cooldown_reduction` | Percent / ADD | 0 / .30 | Yes, once before cap | No |
| `increased_buff_duration` | Percent / ADD | 0 / .30 | Yes, once before cap | No |
| `crit_applies_penetration` | Chance / ADD | 0 / 1 | Yes, once before cap | No |
| `crit_applies_potency` | Chance / ADD | 0 / 1 | Yes, once before cap | No |
| `inventory_economy_stats` | Binary Special | Set membership | No numeric scaling | No |

Follow [StatSheet](../project/scripts/resources/stat_sheet.gd)'s order: canonicalize → sum signed gear contributions → floor at zero → apply equipped All Stats ×1.2 once where eligible → cap. Keep post-All-Stats fractions, e.g. `.07×1.2=.084`; do not round the final bucket to whole percentage points. Compatibility MULTIPLY contributions retain `value−1` handling, but newly generated numeric affixes use ADD. New Rare stats do not enter Basic drawback pools. Manually authored negative values, if allowed by existing validation, still cancel before flooring; do not create a new random drawback path.

All Stats remains a deduplicated Special. Chance caps limit trigger probability, not status stacks. Timing fields are build-static resolved values with default zero; keep them through temporary rebuilds without putting them into attack-speed or unrelated derivation buckets. The Special defaults off. New canonical IDs are authoritative; retain existing enum values/aliases and add canonical naming/formatting so the legacy Attack Speed fallback does not misname new items.

Append the eight Rare entries and two Special entries to [StatCatalog](../project/scripts/systems/stat_catalog.gd). Existing category totals are Weapon Rare 50, Helm 45, Armor 45, Trinket 60, Charm 50. Proposed Rare totals are **60, 63, 53, 78, 68** respectively. Armor Special rises **70→75**, Charm **65→70**. Weight is relative, not percentage; used-ID exclusions renormalize later picks. This dilutes existing Rare economy/proc choices and existing eligible Specials; preserve all old weights and document the resulting tradeoff.

Rare affixes occur on Epic, Cursed, Unique and Chaos. Basic/Master have no Rare roll. Only **Unique** currently rolls a Special; Chaos has four Basic/Rare/Basic-drawback outcomes and cannot naturally roll this Special. Crude/fixed Legendary resources remain authored. Keep ordinary canonical-ID uniqueness, including across Basic/Rare economy overlaps; Chaos retains duplicate Rare rolls. No extra affix slots or rarity probability changes.

Use the current [generator](../project/scripts/systems/gear_generator.gd) formula:

`value = round(uniform(base_min,base_max) × rarity_multiplier × value_scale × depth_scale × 100) / 100`

`depth_scale = 1 + .35 × (clamp(depth,1,12)−1)/11`.

Numeric Rare multipliers: Epic/Unique 2, Cursed 2.5, Chaos 3. `value_scale` remains the caller's positive scale, default 1; no new global cap. Specials remain binary 1 regardless of rarity/depth. Percent/chance rolls use existing Godot .01 rounding, not a uniform draw from displayed percentages.

| Final positive roll at scale 1 | Timing base 4–6% | Crit-proc base 8–12% |
| --- | --- | --- |
| Epic/Unique, depth 1 | 8–12% | 16–24% |
| Cursed, depth 1 | 10–15% | 20–30% |
| Chaos, depth 1 | 12–18% | 24–36% |
| Epic/Unique, depth 12 | 11–16% | 22–32% |
| Cursed, depth 12 | 14–20% | 27–41% |
| Chaos, depth 12 | 16–24% | 32–49% |

These are rounded range endpoints; a raw roll can exceed its eventual effective bucket after other equipment. Store/show raw rolls and expose capped effective totals separately. Depth outside 1–12 uses the existing clamp.

## Cooldown reduction and Increased Buff Duration

**Cooldown reduction is true subtractive percentage reduction:** `effective_cooldown_ms = max(1,ceil(authored_cooldown_ms×(1−c)))` for positive authored cooldowns. Authored zero stays zero. At cap, 10 seconds becomes **7 seconds**, not the previous recovery proposal's 7.693 seconds.

Preserve [scheduler](../project/scripts/systems/combat_macro_scheduler.gd) and [resolver](../project/scripts/systems/combat_resolver.gd) ownership: start cooldown at completed eligible macro windup, including dodged/interrupted attempts; resource-failed/clipped casts still start none. Snapshot the effective interval then; do not edit authored resources, repeatedly scale a rounded value or recalculate an existing deadline. Same-ID macro slots share deadlines; exact deadline is ready; blocked slots still cost 100ms. Proc children retain their current immediate execution/cooldown bypass and never start/reset macro cooldowns. CDR creates no extra trigger, charge or resource. Calculation adds no RNG draw, but changed casts/timing can change subsequent seeded results. Bejeweled's minimum-cast effect still cannot bypass a cooldown.

**Increased Buff Duration** uses `effective_duration_ms = max(1,ceil(authored_duration_ms×(1+d)))` for the current timed **player** buffs: **Footwork, Bypass, Dance of Death, Master of Poisons, Touch of Darkness and Beguiling Presence**. This broader scope reflects the user's “Buff Duration” label rather than restricting the stat to active self-buff skills. It extends time, not magnitude or capacity.

Footwork/Bypass keep their shared refreshed timers and caps 5/3; refresh uses the increased full duration, partial consumption keeps the existing deadline, and no extension replenishes consumed stacks. Dance/Master/Touch/Presence retain independent-instance/consumption rules and current grant timestamps. Snapshot duration at each grant; an unrelated stat rebuild never extends an existing instance. Preserve each existing expiry/boundary rule, including Footwork's cast-start-inclusive deadline; do not replace those rules with one generic expiry ordering. Precision and Readiness are untimed charges in current playable content; Virulent Poison has five untimed charges. All remain unchanged, including negative/zero sentinel durations. Do not enable hypothetical timed Precision through this change. Enemy Poison/Decay/Shred, Penetration/Potency, stun and other enemy effects are excluded; this stat does not extend Death Pact debuffs.

Grant sites: [self buffs](../project/scripts/systems/combat_self_buffs.gd), [talent buffs](../project/scripts/systems/combat_talent_buffs.gd), and [Bladedancer lifecycle](../project/scripts/systems/bladedancer_effect_lifecycle.gd). Default zero must reproduce current duration exactly, with one application of scaling.

At both proposed caps, no slow and immediate recast scheduling (see the [current analytical record](../work/m8_t3_user_stats_proposal/analytical_examples.json)):

| Buff | Current duration / cooldown | Proposed duration / cooldown | Minimum expiry-to-next-completion gap, including 500ms windup |
| --- | --- | --- | --- |
| Master | 5s / 10s | 6.5s / 7s | **1s** |
| Dance | 5s / 20s | 6.5s / 14s | 8s |
| Touch | 12s / 30s | 15.6s / 21s | 5.9s |
| Presence | 10s / 30s | 13s / 21s | 8.5s |
| Footwork / Bypass | 3s refreshed timer | 3.9s refreshed timer | No cooldown-based gap; continued grants can maintain them. |

Master's ideal long-run coverage rises from `5/10.5≈47.62%` to `6.5/7.5≈86.67%`. The gap survives, but this is a major improvement against resistance; short fights can lie entirely inside one window. Macro scheduling/100ms skips/slow may widen gaps. Longer Footwork/Bypass supports stack retention and indirectly improves Plunge/elemental output; quantify that benefit instead of treating duration as cosmetic.

CDR includes **Virulent Poison and Pick Pocket**. Empty-fuel Virulent stockpiling has first grant at 500ms, then minimum 7,500ms spacing at cap versus 10,500ms baseline. Through 30/60/120 seconds, baseline instance counts are **3/6/12**, versus **4/8/16** at cap. Every active instance multiplies Poison by 2, so first-fueled factors are **8/64/4,096×** versus **16/256/65,536×**. Those are finite-window stockpile bounds, not proof that the later damaging tick fits the window or that waiting wins. Each instance still has five charges; fueled ticks spend one from every instance; empty ticks spend none; fight cleanup clears all. Duration does not increase these charges. Assassin fuel/crit/cadence and Master can amplify the eventual burst further. No Virulent nerf/cap is silently added to this proposal.

Pick Pocket changes 8s→5.6s cooldown. At its 800ms minimum windup, 60 seconds permits at most **7→10** completed uses under ideal scheduling: up to 30 extra base theft before gold modifiers and opportunity cost. Ordinary 1,800ms windup changes the thresholds. Steal/Mug/Big Score have zero cooldown. Credited theft still floors per effect and can trigger Bribery; Bandit retains its current resolved stash snapshot behavior. These interactions require focused balance review.

## Crits apply penetration / potency

Proposed trigger eligibility matches the existing crit-to-Poison hook's **connected direct-attack contribution**, using its local `contribution_crit`, not the event's cumulative `is_crit`. Once per eligible contribution, independently roll each equipped stat with positive chance. Multiple damage effects within one contribution do not multiply rolls; each genuinely separate proc/repeat child may qualify under existing direct-attack rules. No roll on dodge, interruption, missing resources, cooldown skip, noncrit, Self Buff or Debuff. Critical natural/forced Poison ticks are **excluded**, including converted ticks; they are not direct attack contributions. Including tick crits is an alternative requiring explicit review, not an accidental extension.

Use the existing crit result: mitigation or crit negation does not erase `is_crit`, so a connected crit reduced to zero damage still qualifies. This preserves the current crit-to-Poison criterion; it does not undo prevented damage or remove crit-negation. No additional crit roll and no requirement to deal positive damage. At chance zero draw nothing; at positive chance draw once per stat, including 100%, following current chance-proc conventions. Fixed new-check order: Penetration, then Potency, after the existing direct-hit status/proc checks and before that contribution returns. Existing checks retain their relative order; adding positive new proc chances legitimately changes later RNG consumption.

On success call the existing [defense-debuff grant](../project/scripts/systems/combat_defense_debuffs.gd) with base 1, ordinary grant semantics: `(1 + resolved_bonus_for_that_status) × (2 if Double Applied Stacks else 1)`, then capacity **50** per status. All Stacks/Death Touch contribute through their existing bonus fields. This is not a Consume grant: Death Pact's no-bonus conversion exception does not apply. Shared timer remains `3 seconds + 1 second × Death Pact rank`, independent for each debuff. Positive grants refresh at cap; zero grants do not. Cleanse/expiry and existing denial effects remain.

Apply after direct damage, before subsequent descendants and existing post-hit cleanse handling: the triggering damage cannot benefit retroactively; later attacks/children or a later forced tick can use the updated defense if ordering permits. At a cleanse boundary a newly granted debuff may be removed immediately under existing policy. Do not reorder cleanse or force damage to be positive to improve item performance.

Penetration subtracts one block per stack, Potency one absorb; **negative values remain possible**. At zero starting defense and 50 stacks, existing negative-defense rules add 5 base physical or elemental damage respectively before applicable calculations. Finders Keepers/block-denial and absorb-denial can therefore combine with the procs; “already zero defense” does not automatically mean useless. Neither stat ignores armor/resistance, guarantees a crit or prevents cleanse. High crit/repeat/All Stacks builds may reach 50 very quickly; preserving counters does not imply preserving every old matchup outcome.

## Special: Economy Stats work in your inventory

**Activation proposal:** an equipped item with `inventory_economy_stats` enables it. Multiple equipped copies do not multiply it. A copy merely in inventory does not activate itself or another copy. Eligible inventory means owned, carried, unequipped gear in the existing three inventory spaces, regardless of that item's equipment slot or rarity. Shop offers, pending unowned choices, sold/destroyed gear and other save slots are excluded.

Import **exactly three canonical numeric affix IDs**: `increased_gold`, `shop_discount`, `increased_magic_find`. Include all their Basic/Rare occurrences, signed Chaos copies, categories and existing numeric operation semantics. Do not import inventory weapon damage, combat affixes, cooldown/duration/crit procs, triggers, unlocked skills, Bandit's signature stash damage, or any binary Special—including inventory All Stats and this Special itself. Recognized aliases canonicalize normally; legacy or unrelated numeric fields are not promoted just because their label sounds economic.

For each economy ID: sum equipped raw contributions plus eligible inventory raw contributions → floor combined bucket at zero → apply **equipped** All Stats once → continue existing build/talent/consumer rules. Do not finalize each item separately, floor inventory negatives away or apply All Stats twice. An equipped item's affixes already contribute normally and are never counted again as inventory.

Ownership is not the authored item ID: two distinct carried copies can share an authored/stable ID and both count. Track source as equipped slot or inventory index/instance; suppress a duplicated reference to the **same owned object** across both collections, with equipped precedence. Repeated references to one object are not extra items. Distinct persisted owned-item records remain distinct; do not deduplicate valid copies by ID, name or equal affix values, or invent a global item-ID migration. Preserve raw source attribution for inspection and save/load witnesses.

Rebuild after equip/unequip, acquisition, sale, removal and reload; toggle-off removes only imported contributions. Resolve transactions atomically: price a purchase from the pre-purchase owned state; the purchased item begins contributing only after payment/ownership transfer. A bought discount item cannot discount itself. Sale price retains its existing fixed tier rule; removing the sold item updates subsequent prices/stats. Full-inventory rules and existing overflow auto-sale remain; carried economy items consume real inventory space. Only owned records contribute; an unidentified unowned shop card never contributes. Current purchase handling identifies Chaos before granting ownership (`is_unidentified = false`); preserve that sequence.

Magic Find is read at existing shop/reward **generation** points; ownership changes affect future rolls, not already generated offers or pending rewards. Discount uses the current owned build at purchase and the displayed price must refresh with inventory changes. Gold uses the existing reward/theft timing, rounding and combat snapshot/live rules; inventory is not mutated during a resolved fight to recalculate prior events. Save the resulting ownership normally, not a second persisted copy of imported bonuses.

**These are not combat-neutral bonuses.** [CombatStatState](../project/scripts/systems/combat_stat_state.gd) derives Fast Hands IAS from `(gold_reward_multiplier−1)×rank_fraction` and Fill Your Pockets elemental multiplier from `1+magic_find×rank_fraction`. Imported economy stats feed those existing rules once, after normal gear/talent aggregation. Increased Gold also changes credited theft, Bribery and live gold-dependent talent context. Preserve those legitimate derivations and existing Bandit snapshot semantics; excluding inventory combat affixes does not exclude combat benefits derived from economy.

## Maximum stacks and economic risk

All examples are source-derived arithmetic/structural witnesses, **not simulation, reachable-drop frequency or accepted balance**. They assume depth 12, scale 1; arbitrary positive scales and editable Practice values still respect the new numeric caps.

- Two eligible Chaos slots can hold eight copies of one new Rare stat. Timing maximum `.24×8=1.92`, or 2.304 after equipped All Stats, resolves to .30. Crit maximum `.49×8=3.92`, or 4.704 with All Stats, resolves to 1.0. Chaos has no Special; All Stats must come from a separate eligible Unique Weapon/Armor. The independent maxima are not all simultaneously equipable.
- Simultaneous timing caps are structurally possible using duplicate CDR on Chaos Trinket and duplicate duration on Chaos Helm/Armor; two .24 rolls suffice before All Stats. Chance caps can also be reached with multiple .49 rolls, but must pay the actual four-outcome Chaos and five-slot opportunity cost. A Rare stat on a normal Epic/Cursed/Unique consumes that item's one Rare slot.
- At 100% proc chance each qualifying crit guarantees its respective grant, not a crit itself. With +9 Death Touch stacks and doubling, one proc requests `(1+9)×2=20`; three successful procs reach the 50 cap from empty, even before further All Stacks. If gear/talents give at least +24 relevant bonuses with doubling, one proc can request 50. Retain cap/overflow/refresh and legal two-tree allocations; repeated attacks can maintain near-permanent capped debuffs unless interrupted/cleansed or unable to crit/connect.
- Inventory Special can combine with equipped All Stats (e.g. Special on Unique Charm, All Stats on Unique Armor), a Legendary weapon and three carried economy items. Three carried Chaos items can contain **12 positive economy affixes**, despite sharing equipment-slot type. Inventory All Stats contributes nothing. Positive/negative copies cancel in the combined bucket.
- Concrete scale-1 extreme: Rare discount base max .11 gives `.11×3×1.35→.45` per Chaos affix. Twelve copies import **5.4** raw discount (6.48 with equipped All Stats) before any equipped/talent contribution; consumer price floors at 1. Rare Helm Increased Gold max1.10 gives **4.46** per roll: twelve carried copies total **53.52**, or **64.224** after All Stats. Rare Magic Find max.22 gives **.89** per roll: twelve total **10.68**, or **12.816** after All Stats. These are separate maximum inventories, not one inventory providing all three maxima.

**Purchase/resale is a review-critical risk.** [BuildState](../project/scripts/autoload/build_state.gd) currently prices an 80-gold Legendary as `max(1,floor(80×max(0,1−discount)))`, while selling pays 40. At exactly 50% discount purchase/sale break even before reroll costs; above 50%, rounding can make each available purchase profitable. One carried Chaos item with three positive .45 discount rolls supplies **135% discount**, uses one inventory space and leaves space to buy/sell. With the Special equipped, that gives **buy1/sell40 without All Stats**, using current minimum-price rules. This is a structurally valid duplicate-Rare Chaos witness, not a measured drop rate. The Special makes high discount easier while retaining combat equipment; it does not create the underlying pricing rule.

Finite offers, ownership exclusions, free inventory space, reroll costs and removal of a sold discount item matter, so this is **not yet proof of an infinite-gold loop**. Verify complete acquisition→buy→sell→reroll trajectories. The recommendation preserves current economy formulas for the requested design review; do not secretly cap discount, weaken imported stats, raise prices or nerf Fast Hands/Fill Your Pockets. If this risk is unacceptable, request a separate explicit economy decision before completing implementation. Range approval alone must not be reported as economy balance acceptance.

## Compatibility, UI and Practice

The five selections are new canonical IDs; this revision does not change existing Decay/Shred aggregation or retrofit old items. Preserve enum values, authored resource paths/IDs, all serialized raw affixes and owned gear records. Existing items keep rolls; future generated selections change because pools changed. Determinism applies within the approved content revision/request/RNG state, not identical old seeds across revisions. Do not reroll persisted inventory, equipment, shop offers or pending rewards to add these stats.

The existing numeric/binary gear codec may suffice without a save-schema bump; verify before implementation. Inventory-derived bonuses are recalculated from normal owned records. Preserve Adventure/Practice isolation and legacy saves. Old executables can reinterpret unknown new canonical IDs through legacy-enum fallback, so downgrade is **unsupported and semantically unsafe**, not merely missing labels. If a downgrade rejection gate is required, review it explicitly rather than assuming a revision tag enforces it.

UI must show conditional chances, timing caps and effective totals clearly: e.g. `Critical direct attacks have a 24% chance to apply Penetration`; longer references explain base1, extras/doubling and 50 cap. Show resolved skill cooldowns/buff durations without rewriting authored data. Inventory economy cards/inspection should identify contributing carried items, raw/effective economy values, activation off/on and any indirect derived combat changes. Comparisons need to account for ownership moving between equipped/inventory pools and losing/gaining the Special, not just compare two item affix lists. Preserve accepted M7 colors, compact hovers, artwork and layout conventions.

Practice exposes new stats only in eligible **Rare** rows and the Special in eligible **Unique Special** rows; fixed Legendary editing remains read-only. Correct chance/percent units and generator-derived defaults are required. Because the Special depends on carried gear, add a minimal isolated three-item carried-gear editor/state using existing item controls rather than faking bonuses on equipped items. Its defaults must be empty and it must not read Adventure inventory. If existing Practice persistence cannot carry that list, document and review the narrow payload extension before implementation. Current fixed-shape Chaos editor is not proof of legal four-Rare rolls; use generated fixtures or clearly labeled custom stress snapshots for duplicates.

## Required implementation evidence after review

1. Catalog/generator: all eligible slots/categories and ineligible Basic/Master/Special paths; exact weights, rarity shapes, depth1/12/clamps, request scale, rounding, ordinary uniqueness, Chaos duplicates, no Rare drawbacks and binary Special behavior.
2. End-to-end gear → source aggregate → resolved stat → effect → display → isolated save/load; All Stats once, floor/cap, rebuild/removal, zero defaults and unaffected baseline gear.
3. Scheduler/grant tests: true CDR formula, shared IDs, deadlines, skips, clipped/failed/interrupted/dodged casts, children and minimum-cast effects; six buff families, shared refresh/partial consumption/independent instances, excluded charges/debuffs and exact expiry. Confirm Master gap and actual Virulent/Pick Pocket windows with legal builds.
4. Crit contracts: local contribution crit, zero-damage/negated crits, multi-effect contributions, roots/children, tick exclusion, independent trials/RNG order, postdamage-before-cleanse ordering, normal bonuses/doubling, cap50/overflow/refresh, Pact lifetime, negative defenses and conversion.
5. Inventory integration: equipped activation only; all three economy IDs including Rare variants and signed Chaos; no imported Specials/combat affixes/triggers; distinct same-ID copies, duplicate references, source ledger; equip/swap/remove/sell/buy/full/overflow/pending offers and reload; generation snapshots and derived Fast Hands/Fill Your Pockets values. Prove ownership-state pricing and round trips without bonus duplication.
6. Focused balance: ordinary early/late rolls and maximum legitimate stacks with equivalent opportunity costs; buff uptime, actual extra casts/theft, debuff time-to-cap and cleanse recovery, crit/repeat/fuel synergies, inventory-derived damage and full buy/sell/reroll trajectories. Separate synthetic limits from earned availability. Do not alter intentional hard counters or existing Legendary effects merely to secure wins.
7. Actual-size cards/comparisons/shop/reward/Practice and updated duration/proc/economy feedback, plus isolated old/current saves including new Practice inventory. No real player saves. T10 owns combined Legendary/exploit validation, T11 human acceptance, M9 integrated earned runs.

The user's five stat selections and categories are settled scope. **Review still needs to accept or revise the table's ranges/slots/weights, 30% timing caps, six-buff duration scope, chance-on-direct-crit semantics, equipped-only inventory activation and full economic propagation.** This proposal requests no runtime change before that review. Source/math/link checks are documentation evidence only; the previous proposal's analytical record is historical and does not validate true CDR or this package.

Documentation verification: current-source pool totals, timing/roll arithmetic and linked consumer contracts checked; **12 local Markdown references, zero missing targets**. No Godot execution, gameplay balance test, rendered UI inspection or save/load experiment was performed. Virulent stockpiling, proc/cleanse ordering and complete purchase/resale trajectories remain future executable witnesses, not established balance outcomes.
