# Combat Mechanics Reference

Last reconciled: 2026-10-22 · Baseline: all four M5 trees, approved tuning through P6M5-D023 and implemented gear rules P6M8-D008 · Revision: 11

This is the **current rules reference for reviewed Phase 6 shared combat mechanics**. It consolidates accepted decisions through D025 and the subsequent Big Score correction. Use it to interpret interactions and author future content. Task handoffs retain decision history and test evidence; trackers retain work status. Draft prose and superseded proposals do not override these rules.

**Release boundary (2026-10-08):** M6 Complete. Adventure uses `p6.adventure.1` and the separate `user://adventure_p6_m6.json` slot; legacy `save.json` remains preserved without migration. Practice/Test Mode retain `p6.playable.shadow.1`. All four trees (44 talents / 140 ranks) are playable. Steal is 1100 ms base / 650 ms minimum; Drunk Buddy retains HP 155, armor 140, 10% Poison resistance and 18 seconds. Tavern rewards are 1/0/2/3 points; contracts grant three, capped at 45 after C13. Bandit Blade remains 0.1 physical damage per gold with no experimental curve. See [M6 closeout and M7 handoff](P6M6_T11_Closeout_And_M7_Handoff.md).

## Navigation

- [M8 gear timing, crit procs and carried economy](#m8-gear-timing-crit-procs-and-carried-economy)
- [Quick rules](#quick-rules)
- [Terms and status labels](#terms-and-status-labels)
- [Stats and damage](#stats-and-damage)
- [Skill execution and timing](#skill-execution-and-timing)
- [Buffs, charges and resources](#buffs-charges-and-resources)
- [Poison and statuses](#poison-and-statuses)
- [Triggers and event ordering](#triggers-and-event-ordering)
- [Gold and combat](#gold-and-combat)
- [Reviewed skill values](#reviewed-skill-values)
- [Alphabetical index](#alphabetical-index)
- [Open content work and reconciliation](#open-content-work-and-reconciliation)
- [Evidence and maintenance](#evidence-and-maintenance)

## M8 gear timing, crit procs and carried economy

The [T3 specification](P6M8_T3_Gear_Stat_Implementation_Specification.md) is implemented under D008; [verification and retained exceptions](P6M8_T3_Closeout_And_Verification.md) establish its scoped evidence. The following rules qualify the authored/base timer values elsewhere in this reference:

- CDR retains `product(1 - min(1, c_i × a))` of a cooldown, where `a` is 1.2 with equipped All Stats and otherwise 1. Positive authored cooldowns resolve to `max(1, ceil(base_ms × factor))`; authored zero stays zero. No aggregate CDR cap. Cooldowns start at completion of eligible root windup, remain shared by stable skill ID and are not restarted by children. Blocked macro attempts remain 100ms.
- Buff Duration sums additively, then receives equipped All Stats once; no balance cap. Multiply positive authored duration by `1 + increase` and round up to milliseconds. Eligible families are Footwork, Bypass, Dance of Death, Master of Poisons, Touch of Darkness, Beguiling Presence, Penetration and Potency. For the latter two, Death Pact's added seconds precede multiplication. Existing refresh/instance/consume/cleanse rules remain. Untimed Precision, Readiness and Virulent charges acquire no timer; Poison/Decay/Shred lifetimes and enemy controls are excluded.
- A connected critical direct contribution tries Crits apply Penetration, then Crits apply Potency, after existing hit applications and before finalize, cleanse and descendants. A successful trial grants base one through ordinary bonus-stack/doubling/cap-50 accounting. Fully mitigated rolled crits qualify. Each eligible child contributes its own trials; natural/forced Poison tick crits do not. Chance zero adds no RNG draws; positive chance including 100% draws once per stat. Newly granted Potency can affect a later forced tick in finalize before cleanse, but cannot improve the triggering direct hit retroactively.
- The Inventory Economy Special activates only while equipped. Gold, Discount and Magic Find affixes on owned unequipped carried items join equipped raw values before floors, equipped All Stats and derivations. Each inventory occurrence counts; identical IDs or cached resource pointers do not collapse copies. Other carried combat stats, Specials and signatures remain inactive. Existing Fast Hands/Fill Your Pockets can derive combat outputs from the final economy stats. Ownership changes rebuild future values without rerolling pending offers. Purchases use ownership before acquisition for their price.
- Timer overflow and non-finite damage/state yield invalid simulations rather than wrapping or imposing a hidden balance cap. Near-zero cooldowns, long-lived buffs and profitable discounted resale are recorded stress/balance surfaces; they do not waive existing hard counters or establish earned-run balance acceptance.

## Quick rules

| Question | Current answer |
| --- | --- |
| Extra stacks? | Add eligible bonuses to the base grant, double if applicable, then limit to remaining capacity. Neither raises the cap. Exceptions are explicit below. |
| Full block? | Still a connected hit; dodge and interruption prevent a hit. |
| Five Footwork? | At Fancy Footwork rank five, five stacks bring Plunge to its 0.50 s minimum. Riposte rank two gives that consuming Plunge 3x damage. |
| Touch scaling? | +10% ordinary increased attack speed (IAS) and +2 physical base per actual Poison consumed, for twelve seconds. |
| Ticks trigger Pact? | No. Natural and forced ticks **deplete** stacks. Only explicit **Consume** triggers Pact. |
| Echoing plus Resonance? | Resonance changes fuel from two to three. At maximum ranks, actual fuel × 1.20; Echoing adds 40/30/20% natural-tick suppression. |
| Precision plus Dance? | One guaranteed repeat; Precision is still spent. Neither changes numeric retrigger chance. |
| Cooling-down slot? | Exactly 100 ms with no effects, then advance; Poison and timers continue. |
| Live versus captured? | Impact/tick damage and gold-derived crit are live. Cast duration and resource/guarantee decisions are captured at start. |
| Big Score? | **90% weapon damage**; on crits, multiply the full current crit multiplier by 6. |

## Terms and status labels

- **Connected hit:** an attack that passed interruption and dodge. Zero damage due to mitigation is still a hit.
- **IAS:** increased attack speed, expressed as a fraction in formulas; +100% is `1.0`.
- **Percentage point:** an additive percentage change. +10 points changes 20% crit chance to 30%. A multiplier `1.5` means 1.5x.
- **Application:** a requested stack grant limited by capacity. Requested, actually added and overflow quantities are distinct.
- **Charge:** a discrete buff resource, such as Virulent's five charges. Stack modifiers require explicit eligibility.
- **Deplete / remove / Consume:** distinct operations. Tick depletion, cleanse, expiry and charge spending do not inherit Consume effects.
- **Macro cast:** a scheduled rotation entry. Triggered children have zero windup but retain applicable resource checks.
- **Fight-local:** fresh state per resolution/retry, cleared on completion or invalidation.
- **Rounding:** runtime time is integer milliseconds; damage keeps fractions until final packet rounding; each theft effect floors its own credit.

| Status | Meaning |
| --- | --- |
| Implemented/tested | Reviewed shared behavior has executable evidence; full tree binding may remain M5. |
| Descriptor tested | Reviewed skill values exist in an opt-in adapter or exact fixture; not release promotion. |
| Inherited baseline | Existing behavior preserved and checked; no redesign inferred. |
| Content pending — M5 | Shared mechanism exists, but full skill/rank authoring is not certified. Do not invent missing values from draft prose. |

## Stats and damage

### Aggregation and derived stats

**Status: Implemented/tested.** Gear affixes aggregate in their existing StatSheet bucket with its established floors, All Stats treatment and caps. Gear and talent physical/elemental damage multipliers remain separate multiplicative buckets. There is no universal additive damage bucket.

Ordinary IAS contributions add. Temporary scalar bonuses add to their resolved input. Physical/elemental percentage bonuses within one temporary instance combine; independent percentage sources multiply separately. Replacing an instance replaces its contribution rather than accumulating its previous value.

Derived stats rebuild from an unmodified baseline after source changes. Fill Your Pockets resolves before Shadow Mastery. Chance clamps and gold/Magic Find zero floors follow temporary aggregation. Applicable damage multiplier floors remain 0.05; base damage floors remain with their existing consumers.

| Mechanic | Current rule | Example / exception |
| --- | --- | --- |
| Bladedancer intrinsic | 5% retrigger plus 0.2 percentage points per primary Bladedancer point; additive with gear retrigger. | Ten primary points = 7%. Secondary receives the base without primary scaling. |
| Whetstone | +1 base physical damage per rank. | Adds with other base bonuses. |
| Double Dip | Copy 50%/100% of current numeric retrigger chance into crit chance. | Exclude Precision/Dance guarantees. Final crit caps at 100%. |
| Sharpened Edge | Separate physical multiplier 1.2/1.4/1.6/1.8/2 on Stab and Heavy Slash. | Before conversion/mitigation; no extra packet. Heavy Strike is the draft alias for Heavy Slash. |
| Fast Hands | Copy 10/20/30/40/50% of final Increased Gold bonus into IAS. | +200% gold at rank five gives +100% IAS; retain gold bonus. |
| Fill Your Pockets | Copy 20/40/60/80/100% of Magic Find into a separate elemental multiplier. | +150% Magic Find at rank five gives 2.5x; retain Magic Find. |
| Shadow Mastery | Copy 10/20/30/40/50% of flat elemental bonuses into physical base, and that fraction of the effective elemental percentage bonus into a separate physical multiplier. | Exclude class baseline Poison damage from flat copying; retain elemental benefits. Negative surviving bonuses reduce the copy. |
| Keen Eye | +2% physical and elemental damage per rank in established talent buckets. | Rank five gives +10% each. |
| Cloak & Dagger | +50/+100 percentage points of crit damage. | Existing crit multiplier bucket. |

**Shadow Mastery example:** gear elemental 2x and talent elemental 1.5x give 3x, a +200% bonus. Rank one copies 10% of that bonus into physical 1.2x. A separate +10 flat elemental bonus also adds +1 physical base at rank one; class baseline Poison is excluded from that flat bonus.

Evidence: [T3 formulas](P6M3_T3_Stat_Derivation_And_Temporary_Modifiers.md), [derivation tests](../project/tests/p6_stat_derivation_test.gd), [source tests](../project/tests/p6_stat_sources_test.gd).

### Approved Bladedancer content — M5-T3

**Status: Implemented/tested in M5-T4.** All 13 talents / 35 ranks are bound in the playable registry; see [T4 evidence](P6M5_T4_Bladedancer_Implementation.md).
[P6M5-D003 and the full tree specification](P6M5_T3_Bladedancer_Design_Review.md)
record the user's 2026-10-03 confirmation:

- Weakness adds +5 base Shred Value per rank, up to +25. Each stack removes
  `base Shred Value + 5 * rank` armor before other Shred Value sources.
- Virulent Corruption adds +100 base Shred Value and +2 bonus stacks per eligible
  Shred application; Shred-only cleanse immunity remains settled. With Weakness
  five, each stack removes `base Shred Value + 125`. A base one-stack application
  becomes three, removing `3 * (base + 125)` armor. Rending's base two becomes
  four, removing `4 * (base + 125)`. Add other eligible stack bonuses before
  doubling and the existing 500-stack cap. These talents do not increase the cap.
- Weapon Master ranks give 1.5x/2x originally physical damage through the existing
  talent multiplier, before conversion. It multiplies with Sharpened Edge and
  other factors: both maximum ranks give Stab/Heavy Slash 4x; with Keen Eye five,
  4.4x before remaining factors. Rank two replaces rank one rather than stacking
  with it. Originally elemental Poison does not gain this bonus simply because
  it is converted to physical.

The user explicitly accepts those interactions while reserving possible lower
numerical values for future balance work (M6). Source drafts, runtime bindings
and compatibility fixtures are unchanged by this specification closeout.

### Live values and snapshots

| Read point | Values and consequences |
| --- | --- |
| Accepted cast start | Capture duration, resources, consumed Footwork/Riposte multiplier, Precision and Dance eligibility. Later changes do not rewrite the cast. |
| Impact | Current damage, mitigation and gold-derived crit. Expiry during windup can change damage without changing windup. |
| Poison tick | Current elemental bonuses, resistance ignore, Virulent instances and enabled critical Poison stats. |
| Source change | Rebuild derived stats; reschedule Poison while preserving fractional progress. |
| Build resolution | Inherited Bandit Blade gold-to-base is a snapshot, not a new live mid-fight consumer. |

### Damage and defense order

**Status: Implemented/tested; inherited mitigation retained.** P6M5-D015: negative block adds 0.1 times its magnitude to an originally physical packet's base; negative absorb adds 0.1 times its magnitude to an originally elemental packet's base. Every ten points below zero give +1 base damage; fractional bonuses survive until ordinary final damage rounding. Apply applicable base/scaling/critical calculations, then conversion and destination defenses. Do not add a second negative-defense base bonus from the destination.

- Physical mitigation: critical negation when applicable, armor, then positive block.
- Elemental/magical mitigation: resistance, then positive absorb. Poison uses this path unless converted.
- For nonnegative armor `A`, multiplier = `1 - 0.75A/(A+100)`. Negative armor gives `1 + 0.75|A|/(|A|+100)`.
- Resistance multiplier = `1 - clamp(resistance, 0, 1)`. Master of Poisons makes effective elemental resistance zero while active.
- Both inherited conversion flags together apply physical then magical mitigation, preserving the existing gear interaction.
- Fully prevented packets stay zero. Surviving positive packets round to an integer with minimum one.
- Crit negation reduces damage without erasing the critical flag. Guaranteed crits do not bypass it.

**Example:** physical base 10 plus 0.5 from block -5, with physical 2x, gives 21. Convert to magical, apply absorb 4 and neutral resistance: 17. Negative absorb would not add another bonus to this originally physical packet.

Evidence: [T7 defense rules](P6M3_T7_Status_And_Mitigation_Interactions.md), [damage calculator](../project/scripts/systems/damage_calculator.gd), [interaction tests](../project/tests/p6_status_interactions_test.gd).

## Skill execution and timing

### Categories

| Category | Timing | Dodge / counters | Examples |
| --- | --- | --- | --- |
| Attack | Ordinary IAS, minimum and slow rules. | Attack interruption/hit rules and applicable cleanse/interrupt counters. | Quick Cut, Plunge, Poison Strike, Steal, Mug, Big Score. |
| Debuff | Ordinary IAS and minimum. | Cannot dodge; neither advances nor resets attack cleanse/interrupt counters; does not manufacture an attack hit. | Poison Vile, Blinding Powder, Pick Pocket. |
| Self Buff | Ignores IAS; existing slow and minimum-proc behavior remains. | Cannot dodge; neither advances nor resets attack cleanse/interrupt counters. | Dance, Virulent, Master, Touch, Beguiling Presence. |

Ordinary timing uses `speed_factor = max(0.05, 1 + IAS)`. First compute `max(1, ceil(max(skill_min_ms, base_ms / speed_factor)))`, then apply nonnegative slow with another ceiling and minimum check. Self Buffs use IAS zero here. Ignoring IAS does not grant immunity to every timing modifier.

Footwork reduces Plunge after ordinary speed/slow while respecting its minimum. The inherited minimum-time proc respects a one-millisecond macro floor. Triggered children retain zero windup.

### Scheduling and cooldowns

**Status: Implemented/tested.** P6M5-D012: eligible macro casts start cooldown when their cast time completes, shared by stable skill ID across duplicate slots. Dodge/interruption does not refund it. Required resources are checked/spent at start. Missing Readiness spends the skill's time without effects and starts no cooldown.

A cooling-down slot spends exactly **100 ms**, then advances: no damage, grants, consumption, attack/proc RNG or attack-counter change. IAS, slow, minimum-time procs and Footwork cannot modify that wait. Becoming ready during it does not execute retroactively; entering at the exact deadline is eligible.

Repeats/procs bypass and do not restart macro cooldowns but retain resource requirements. Casts that cannot finish within the window start no cooldown and consume no resources. Remaining ticks/expiry continue through the endpoint. Preview retains inherited minimum-time-proc RNG behavior for the final omitted cast.

All-cooling macros keep cycling. Invalid slots, nonpositive windows and conflicting cooldown definitions produce explicit invalid results. An empty macro with a positive window retains its valid empty result.

Evidence: [T5 scheduling](P6M3_T5_Conditional_Skills_And_Macro_Scheduling.md), [timing code](../project/scripts/systems/combat_timing.gd), [macro tests](../project/tests/p6_macro_scheduler_test.gd), [cooldown tests](../project/tests/p6_cooldown_scheduler_test.gd).

## Buffs, charges and resources

### Grants and lifetimes

**Status: Implemented/tested.** Eligible normal grants request `(base + applicable extra stacks) × doubling factor`, then use remaining capacity. Doubling factor is two when applicable, otherwise one. Death Touch adds +3/6/9 into the same extra-stack total as gear, once.

| Resource / conversion | Extra stacks and doubling | Limit |
| --- | --- | --- |
| Footwork | Both, in that order. | Five. |
| Bypass | Both, in that order. | Three. |
| Normal Poison, Shred, Decay, ordinary Penetration/Potency | Eligible status bonuses then doubling. | Applicable status capacity; Decay has no authored hard cap in this shared path. |
| Precision / Readiness | Fixed one-charge resources. | One each. |
| Virulent | Neither. | Five charges per independent instance. |
| Death Pact | Neither. | Actual consumption to each debuff, each capped at 50. |
| Beguiling / Touch | Neither amplifies converted quantity. | Actual fuel; independent bonus instance. |
| Distilled | Poison bonuses once after actual Decay consumption, then doubling. | Poison capacity; no overflow refund. |

Shared-timer grants refresh at cap; zero-unit grants do not refresh. Partial consumption retains the deadline; consuming all removes the instance. Self Buff recasts create independent instances. Each fight has fresh state; cleanup removes surviving effects and their stat sources.

### Bladedancer and Bypass

| Mechanic | Grant / lifetime | Effect and consumption |
| --- | --- | --- |
| Footwork | Connected Quick Cut of any origin grants one base stack after its subtree. Cap five, shared three-second timer, refresh at cap. | Plunge consumes all at accepted start. Fancy Footwork rank `r`, count `n`: `max(0.50 s, ordinary_time × (1 - 0.04 × r × n))`. |
| Riposte | Uses that Plunge's actual captured Footwork consumption; two ranks. | Damage multiplier `1 + 0.2 × rank × n`. Child Plunge must consume its own stacks. |
| Readiness | Connected retrigger grants one untimed charge after descendants; full block qualifies. | Parry consumes at start; missing charge gives no effects. A repeat cannot enable itself with its later grant. |
| Precision | Connected Quick Cut grants one untimed charge **before** children; no second end grant. | Eligible Stab/Heavy Slash of any origin consumes at start for its initial guaranteed repeat if connected. |
| Dance | Independent five-second window, granted at completed activation; twenty-second cooldown begins at completion. | Macro-only guarantee. Precision overlap gives one repeat and spends Precision. Multiple Dance instances do not multiply it. |
| Bypass | Connected Stab of any origin grants one base stack after its subtree; cap three, shared three seconds, refresh at cap. | Separate elemental multiplier `1 + 0.1 × stacks`; three = 1.3x. Live ticks and Shadow Mastery read it. |

**Expiry exception:** Plunge may consume existing Footwork exactly at its deadline. A Quick Cut grant at that deadline expires old Footwork first and creates a fresh instance. Bypass, defense debuffs and ordinary live buffs expire before deadline-equal reads; Footwork's exception is not universal.

**Example:** Fancy Footwork five and five stacks change an ordinary two-second Plunge to its 0.50-second minimum. Riposte two also gives 3x damage. Dodge/interruption after acceptance refunds neither resource.

### Poison and Shadow Self Buffs

| Mechanic | Effect | Lifetime / boundary |
| --- | --- | --- |
| Touch of Darkness | Consume all actual Poison; +10% ordinary IAS and +2 base physical damage per stack; actual consumption triggers Pact. | Twelve seconds, thirty-second cooldown. Independent instances add both bonuses. Zero fuel still casts/starts cooldown but grants nothing and preserves old instances. |
| Virulent Poison | Five charges each; every active instance gives a fueled tick 2x and spends one charge. | Charge-limited, no timed expiration. Two instances = 4x. Empty ticks spend none; fully mitigated fueled ticks still spend charges. |
| Master of Poisons | Live zero elemental resistance, including pre-existing Poison and converted elemental hits. | Five seconds, ten-second cooldown. Stored Decay remains; normal resistance resumes at expiry. |
| Beguiling Presence | Consume all actual Decay for +1 base elemental and +2 percentage points crit chance per stack; triggers Pact. | Ten seconds, thirty-second cooldown. Independent elemental and crit bonuses add; effective crit chance caps at 100%. Zero fuel cannot erase an older bonus. |

All four have 0.50-second authored casts. Normal Touch/Beguiling cooldowns exceed duration; future enabled overlap uses the independent-instance rules without implying that such gear currently exists.

**Touch example:** base 20 s with +100% existing IAS takes 10 s. Consume 80 Poison: add +800% IAS, giving `20 / (1 + 1 + 8) = 2 s`, subject to minimum/other timing rules. This is not an 80% direct time reduction.

Evidence: [T4 final contracts](P6M3_T4_Timed_Effects_And_Charges.md), [T7 Self Buffs](P6M3_T7_Status_And_Mitigation_Interactions.md), [T4 tests](../project/tests/p6_t4_completion_test.gd), [status completion tests](../project/tests/p6_status_completion_test.gd).

## Poison and statuses

### Poison applications, cadence and fuel

**Status: Implemented/tested.** Ordinary Poison cap is 20. Redesigned Umbral Presence's adapter raises it to at least 80. Legacy cap 40 belongs to old Umbral Presence content; it is not a competing authored gear cap. Extra stacks/doubling do not raise capacity.

Poison Vile requests 20 base stacks. With +2 extras and doubling it requests 44; an empty ordinary cap-20 target accepts 20 and discards 24.

Hastened Poison and Accelerant each contribute 10% of IAS per rank, five ranks each. Contributions **add**: five plus five uses 100% of IAS for tick rate. Accelerant requires at least one Hastened rank.

`interval_ms = max(1, round(1000 × legacy_interval_multiplier × (1 + effective_suppress + echoing_suppression) / (1 + max(0, IAS) × 0.1 × (hastened_rank + accelerant_rank))))`

Echoing adds 40/30/20% suppression at ranks 1/2/3 (zero without the talent), additive with enemy suppression. This lengthens natural tick intervals; forced ticks are not delayed. Enemy slow modifies casting; suppress modifies cadence. The fight-wide Poison clock runs even without stacks. IAS changes preserve percentage progress: halfway remains halfway. Changing an interval from 1000 to 500 ms at 50% progress leaves 250 ms. Fractional deadlines round up to integer milliseconds. Natural ticks reset phase; forced ticks do not.

| Active talents | Requested fuel per natural or forced tick |
| --- | --- |
| Neither Echoing nor Resonance | One stack. |
| Echoing Toxin | Two stacks. |
| Resonance with required Echoing | Three stacks, replacing two. |

Actual fuel is limited to remaining stacks. Echoing has three ranks; Resonance has four and requires Echoing. One tick makes **one packet**:

`raw_tick = ordinary_poison_damage × actual_fuel × (1 + 0.05 × resonance_rank)`

Ordinary Poison damage includes applicable live base/elemental/negative-absorb contributions; Virulent supplies separate instance multipliers. At ten damage per stack and maximum ranks: `10 × 3 × 1.20 = 36`; two remaining stacks give 24. Neutral noncritical results are 36 or 24. Empty fuel means no damage, tick crit roll or Virulent expenditure.

Critical Poison, when enabled, rolls once per fueled packet using current crit chance and full crit multiplier after raw calculation. Apply crit to the whole packet, then conversion/mitigation/rounding. Tick crits do not trigger Shadow's direct-hit crit-to-Poison hook or become repeat sources.

Poison Strike causes one forced tick on a connected cast, including eligible procs/repeats. Dodge/interruption prevents it; full block does not. A same-time natural tick resolves first, then skill damage and the forced tick before later status additions/cleanse. Both tick origins deplete fuel; neither triggers Pact.

Evidence: [T9 final contract](P6M3_T9_Poison_Timing_And_Consumption.md), [Poison tests](../project/tests/p6_poison_contract_test.gd), [cadence code](../project/scripts/systems/poison_cadence.gd).

### Shred, Decay, defense debuffs and Consume

| Mechanic | Current rule |
| --- | --- |
| Shred | Cap 500. Each stack reduces armor by resolved Shred value (inherited default 10; Dusk Strike adds +10). Rending deals damage, then applies two base stacks with bonuses/doubling. |
| Decay | Explicit count even at zero base resistance; no shared hard cap. Resistance = `base_resistance × (1 - resolved_decay_value)^remaining_stacks` (inherited default value 0.2). Removal restores resistance from remaining count. |
| Decay-to-Shred | Each Decay application separately requests one base Shred plus its own bonuses/doubling. Do not copy the final Decay count. |
| Virulent Corruption | Protects Shred only from cleanse. Poison, Decay, Penetration and Potency remain cleansable. Existing full cleanse denial protects all. |
| Penetration | One less block per stack, cap 50, shared refreshed three-second baseline timer. |
| Potency | One less absorb per stack, cap 50, its own shared refreshed three-second baseline timer. |
| Death Pact | Explicit Consume of actual Poison/Decay grants that quantity to **each** defense debuff without extra stacks/doubling. Adds one second per rank to both debuffs regardless of source: 4/5/6 seconds. No separate Pact player buff. |
| Blinding Powder | Base Potency equals invested Assassin points, then normal extras/doubling. |
| Finders Keepers | Rank one halves encounter-start block; rank two sets it to zero. Full block-denial gear establishes zero and makes the reduction redundant. |
| Absorb-denial gear | Establishes zero encounter-start absorb before Potency. |
| Distilled Corruption conversion | Consume up to five actual Decay; one Poison application from that quantity, then Poison extras once, doubling and cap. Zero fuel makes no application; overflow gives no Decay refund. Full skill binding is complete in M5-T8. |
| Bribery | One Shred application per successful credited theft event, with base 2/4/6 by rank plus normal modifiers. Amount stolen does not multiply application count. |

Defense debuffs expire before exact-deadline operations and are cleansable. Consume restores Decay resistance before descendants. Newly granted defense debuffs affect subsequent damage, not damage already resolved for their granting cast. Cleanse, expiry, tick depletion and Virulent charge spending never trigger Pact.

**Conversion example:** with two Decay, +1 eligible Poison bonus and doubling, Distilled consumes two and requests `(2 + 1) × 2 = 6` Poison before cap. Pact separately requests exactly two Penetration and two Potency, not six.

Evidence: [T7 status rules](P6M3_T7_Status_And_Mitigation_Interactions.md), [accounting tests](../project/tests/p6_status_accounting_test.gd), [interaction tests](../project/tests/p6_status_interactions_test.gd).

## Triggers and event ordering

### Repeat and proc eligibility

Player-facing terminology: **Retrigger** is the mechanical keyword; **Retrigger Chance** is the numeric character stat. Precision and Dance grant a **guaranteed Retrigger**, without increasing that stat. Repeat describes the visible outcome or retained internal implementation terminology.

**Status: Implemented/tested.** Numeric retrigger and guaranteed repeats are distinct. A guarantee replaces the initiating synthetic random-repeat decision; it adds no second independent roll. Its child resumes ordinary rules. Authored chance-one procs remain authored procs, not guarantees.

- Opportunity: 10/20/30% chance for eligible connected Quick Cut of any origin to proc Rending Slash, which can retrigger normally.
- Precision: eligible Stab/Heavy Slash of any origin may spend a charge. Quick Cut → critical Poison application → Death Blade Stab may consume the same-hit Precision because its grant precedes children.
- Dance: macro-only; activation without a connected attack does not manufacture a repeat. Pick Pocket and Self Buff activations are not attacks for repeat eligibility. Future nonattack content needs an explicit contract.
- Side Step: Parry's effective crit chance is 100%; normal critical negation applies.
- Death Blade: Stab cannot apply Poison by any source, including Coated Weapons, critical applications or conversion. Roll once per application that actually adds stacks, never per stack. Cap-only applications and ticks give no candidate.
- Shadow's direct-hit critical hook rolls once per qualifying direct critical cast, not per packet. Poison tick crits do not qualify.
- Full block permits connected-hit repeats. Dodge, interruption and missing required resources do not.

### Causal ordering and exact ties

Authoritative order is simulation time then increasing execution sequence. Do not reconstruct ties by alphabetically sorting event kinds or IDs.

1. Capture accepted cast-start timing, resource and guarantee decisions.
2. Advance due natural ticks and lifecycle changes through completion, including natural ticks at that timestamp. Expired ordinary buffs do not affect deadline-equal damage.
3. Resolve interruption/dodge and cast damage, then its applicable forced tick, Consume/defense transactions, status applications and cleanse. Precision is granted once before child dispatch.
4. Visit authored candidates in stable order, then Death Blade application candidates, then the synthetic repeat candidate. Finish each successful child and its entire subtree before the next sibling.
5. Apply post-subtree player grants, including Footwork, Readiness and Bypass. Advance the macro with applicable stun delay.

The [Footwork deadline exception](#bladedancer-and-bypass) is specific to its cast-start consumption. Cast-start guarantees survive expiry during the accepted windup but still require a hit.

Each macro root permits **1,024 trigger-candidate evaluations**, including filtered candidates and descendants. Attempting candidate 1,025 invalidates simulation and suppresses outcome/reward handling. The inherited depth-16 guard suppresses deeper descendants. Invalid results clean up fight-local effects and are not valid zero-damage outcomes. Filtered candidates consume budget but no proc RNG.

Trace collection must not change RNG/results. Events preserve source, instance, cast, parent and root identities. Damage/status/gold transactions and recap totals reconcile; uptime is clipped to the observed window.

Evidence: [T2 ordering](P6M3_T2_Combat_Ordering_And_Diagnostics.md), [T6 origins](P6M3_T6_Triggers_Repeats_And_Critical_Interactions.md), [repeat tests](../project/tests/p6_repeat_contracts_test.gd), [origin tests](../project/tests/p6_trigger_origins_test.gd), [failure tests](../project/tests/p6_combat_failure_consumers_test.gd).

## Approved Thief content — M5-T5

**Status: Implemented and verified in [M5-T6](P6M5_T6_Thief_Implementation.md).** The user confirmed [T5 decisions D01–D03](P6M5_T5_Thief_Design_Review.md) under P6M5-D004:

- Sticky Fingers: +10/20/30/40/50% Increased Gold, multiplicative with the existing intrinsic and gear gold buckets.
- Charisma: +10/20/30 percentage points Shop Discount, additive with gear; preserve floor rounding and the one-gold minimum for positive-price offers.
- Loaded Dice: +100/200/300% Magic Find, Charisma rank-one prerequisite; preserve shop/reward upgrade chance scaling and Fill Your Pockets' separate elemental factor. The approved display name is Loaded Dice; canonical ID remains `talent.thief.load_dice`.

All other T5 mechanics preserve the settled contracts below. Numerical tuning remains M6; T6 promotes all ten Thief talents/35 ranks and four skills in Test Mode and Practice.

## Approved Assassin content — M5-T7

**Authority: P6M5-D009 for content; P6M5-D010 for the user-approved balance changes on 2026-10-03.** Full specification: [Assassin review](P6M5_T7_Assassin_Design_Review.md). Implementation and acceptance are [complete in T7](P6M5_T7_Assassin_Implementation.md).

- Venom Jab: Attack, 22% weapon damage, 1000/500 ms base/minimum, no cooldown; connected hit deals damage then applies five base Poison with ordinary stack bonuses/doubling/cap. The legacy compatibility resource retains eight.
- Toxic Tradeoff: five ranks supply separate Poison tick factors 1.1/1.2/1.3/1.4/1.5 and physical factors 0.9/0.8/0.7/0.6/0.5. The Poison factor multiplies natural and forced tick packets before crit/conversion/defenses/rounding. It does not change other elemental damage or Shadow Mastery's copied elemental bonus. Originally physical damage retains the penalty after conversion; Poison converted to physical retains its Poison bonus without acquiring that penalty.
- Quick Hands adds 1/2/3/4/5 percentage points of ordinary IAS; Precision adds 1/2/3/4/5 percentage points of critical chance. This Precision talent grants no charge or repeat guarantee.
- Assassin intrinsic is +5 flat base elemental damage in both roles plus +0.5 per Assassin point for primary only. Blinding Powder uses total Assassin points in either role, independently of intrinsic scaling.

Example: with ordinary Poison damage 10, Echoing three, Resonance four and Toxic Tradeoff five, a three-fuel tick has raw damage `10 * 3 * 1.2 * 1.5 = 54` before Virulent, crit and defenses. Weapon Master two with Toxic five gives `2 * 0.5 = 1` times ordinary physical damage before other factors. All existing cadence, fuel, Bypass, critical tick and self-buff rules above remain settled; numerical tuning remains M6.

## Gold and combat

**Status: Implemented/tested.** Stash and credited gold stolen this fight are separate. Existing stash is not theft. Clearing the fight counter does not remove credited stash. Rewards/Overkill Gold remain outside theft; shop spending does not change the theft counter.

Each theft credits `max(0, floor(raw_gold × resolved_gold_multiplier))`, floored separately per effect. Playback credits it once, without applying Increased Gold again. Zero-credit events do not trigger Bribery.

| Consumer | Current calculation |
| --- | --- |
| Thief intrinsic | +10% Increased Gold plus +2 percentage points per primary Thief point. Five primary points = +20%; secondary receives +10%, even at zero investment. |
| Gold buckets | Base/primary Thief contributions add internally; preserve surrounding gear gold bucket and talent/intrinsic multiplier composition. Fast Hands reads final multiplier minus one. |
| Steal | Critical connected hit steals three raw gold. |
| Pick Pocket | Ten raw gold per execution; eight-second cooldown from completion, shared by all slots. Debuff rules apply. |
| Greed | Visual player buff: one stack per credited gold stolen this fight, after Increased Gold. No additional stat modifier, timer or stack cap. Appears on positive theft; resets on fight completion/retry/exit. |
| Mug | Add `min(50, credited_fight_stolen_gold)` to base physical before ordinary scaling/crit. Neither spends gold nor counts starting stash. |
| Silvered Edge | +1 percentage point crit chance per credited fight-stolen gold, talent contribution capped at 25/50/75 points by rank. Clamp total crit afterward. |
| Gilded Blade | +1 percentage point crit damage per stash gold, counting at most 500. Preserve other crit sources. |
| Big Score | 90% weapon scaling; on crits, six times the full current crit multiplier. Normal 3x becomes 18x. Noncrits receive no extra multiplier. |

Gold changes affect subsequent hits, immediate children and critical Poison. Adventure keeps credited stash after combat. Practice retry restores configured starting stash and clears fight theft. Resolver inputs stay unchanged; playback owns crediting.

**Examples:** two separate three-gold thefts at 1.5x credit four each, totaling eight, not nine. A 100-damage weapon with neutral defenses and no other bonuses gives Big Score 90 noncritical damage or 1620 with normal 3x crit multiplied by six to 18x.

Legacy uncapped scalar consumers remain separate compatibility behavior; new talent caps do not silently cap unrelated gear. Bandit Blade remains a build-resolution snapshot, rebuilt after spending rather than automatically during a fight.

Evidence: [T10 gold contracts](P6M3_T10_Gold_And_Mixed_Build_Handoff.md), [gold code](../project/scripts/systems/combat_gold.gd), [gold tests](../project/tests/p6_gold_contract_test.gd).

## Reviewed skill values

Percentages are weapon scaling, not fallback resource damage. Times are seconds before modifiers. This is the reviewed M3 set, not certification of all twenty planned skill identities. Self Buff timing still observes the existing slow/minimum-proc rules.

| Skill | Category | Weapon damage | Base / minimum | Cooldown | Status / behavior |
| --- | --- | --- | --- | --- | --- |
| Beguiling Presence | Self Buff | — | 0.50 / 0.50 | 30 | D023: Consume Decay, ten-second elemental and crit bonuses. |
| Big Score | Attack | 90% | 1.80 / 0.70 | 0 | D017: multiply full crit multiplier by six on crit. |
| Blinding Powder | Debuff | 0% | 1.20 / 0.50 | 0 | D013 timing; Assassin-point Potency, capped at 50. |
| Dance of Death | Self Buff | — | 0.50 / 0.50 | 20 | Descriptor/exact mixed fixture tested; five-second window. |
| Leaping Plunge | Attack | 190% | 2.50 / 0.50 | 0 | Exact core fixture tested; Footwork/Riposte. |
| Master of Poisons | Self Buff | — | 0.50 / 0.50 | 10 | Descriptor tested; five-second resistance ignore. |
| Mug | Attack | 100% | 1.50 / 0.70 | 0 | Descriptor/exact mixed fixture tested; capped theft base bonus. |
| Parrying Strike / Parry Strike | Attack | 120% | 0.50 / 0.30 | 0 | Exact core fixture tested; requires Readiness. |
| Pick Pocket | Debuff | 0% | 1.80 / 0.80 | 8s | Descriptor tested; ten raw gold. |
| Poison Strike | Attack | 83% | 1.20 / 0.50 | 0 | Descriptor tested; forced fueled tick. |
| Poison Vile | Debuff | 0% | 1.80 / 0.50 | 0 | Descriptor tested; twenty base stacks; name retained as authored. |
| Quick Cut | Attack | 66% | 0.85 / 0.50 | 0 | Exact core fixture tested; Precision before children, Footwork after. |
| Rending Slash | Attack | 78% | 1.40 / 0.65 | 0 | Exact core fixture tested; two base Shred after damage. |
| Steal | Attack | 106% | 1.10 / 0.65 | 0 | Inherited descriptor/exact mixed fixture tested; critical theft. |
| Touch of Darkness | Self Buff | — | 0.50 / 0.50 | 30 | D023: twelve-second additive IAS and +2 base physical damage per consumed stack. |
| Virulent Poison | Self Buff | — | 0.50 / 0.50 | 10 | Descriptor tested; five charges per instance. |
| Venom Jab | Attack | 22% | 1.00 / 0.50 | 0 | M5-D009: five base Poison after connected damage. |

Evidence: [T1 values](P6M3_T1_Bladedancer_First_Slice_Specification.md), [core fixture](../project/tests/fixtures/p6/bladedancer_core/core.gd), [status descriptors](../project/scripts/systems/p6_status_skill_contracts.gd), [Poison descriptor](../project/scripts/systems/p6_poison_contracts.gd), [Thief descriptors](../project/scripts/systems/p6_thief_contracts.gd).

## Alphabetical index

This indexes the named mechanics consolidated here, not the complete planned 44-talent roster. Their values belong to the linked sections rather than being duplicated here.

| Name | Rule location |
| --- | --- |
| Accelerant | [Poison cadence](#poison-applications-cadence-and-fuel) |
| Bandit Blade | [Snapshots](#live-values-and-snapshots), [gold](#gold-and-combat) |
| Beguiling Presence | [Self Buffs](#poison-and-shadow-self-buffs) |
| Beguiling Strike | [Pending content](#open-content-work-and-reconciliation) |
| Big Score | [Gold](#gold-and-combat), [skill values](#reviewed-skill-values) |
| Bladedancer intrinsic | [Derived stats](#aggregation-and-derived-stats) |
| Blinding Powder; Bribery | [Statuses](#shred-decay-defense-debuffs-and-consume) |
| Bypass | [Bladedancer and Bypass](#bladedancer-and-bypass) |
| Cloak & Dagger | [Derived stats](#aggregation-and-derived-stats) |
| Coated Weapons | [Death Blade suppression](#repeat-and-proc-eligibility); full rank binding M5 |
| Critical Poison | [Poison](#poison-applications-cadence-and-fuel) |
| Dance of Death | [Buffs](#bladedancer-and-bypass), [repeat eligibility](#repeat-and-proc-eligibility) |
| Death Blade | [Repeat/proc eligibility](#repeat-and-proc-eligibility) |
| Death Pact | [Consume](#shred-decay-defense-debuffs-and-consume) |
| Death Touch | [Grant rules](#grants-and-lifetimes) |
| Decay; Distilled Corruption | [Statuses and conversion](#shred-decay-defense-debuffs-and-consume) |
| Double Dip | [Derived stats](#aggregation-and-derived-stats) |
| Echoing Toxin | [Poison fuel](#poison-applications-cadence-and-fuel) |
| Fancy Footwork | [Bladedancer and Bypass](#bladedancer-and-bypass) |
| Fast Hands; Fill Your Pockets | [Derived stats](#aggregation-and-derived-stats) |
| Finders Keepers | [Defense baselines](#shred-decay-defense-debuffs-and-consume) |
| Footwork | [Bladedancer and Bypass](#bladedancer-and-bypass) |
| Gilded Blade | [Gold](#gold-and-combat) |
| Hastened Poison | [Poison cadence](#poison-applications-cadence-and-fuel) |
| Heavy Slash / Heavy Strike | [Sharpened Edge](#aggregation-and-derived-stats), [Precision](#bladedancer-and-bypass) |
| Keen Eye | [Derived stats](#aggregation-and-derived-stats) |
| Leaping Plunge | [Footwork/Riposte](#bladedancer-and-bypass), [values](#reviewed-skill-values) |
| Master of Poisons | [Self Buffs](#poison-and-shadow-self-buffs) |
| Mug | [Gold](#gold-and-combat) |
| Opportunity | [Repeat/proc eligibility](#repeat-and-proc-eligibility) |
| Parrying Strike / Parry Strike | [Readiness](#bladedancer-and-bypass), [values](#reviewed-skill-values) |
| Penetration | [Defense debuffs](#shred-decay-defense-debuffs-and-consume) |
| Pick Pocket | [Gold](#gold-and-combat), [categories](#categories) |
| Poison Strike; Poison Vile | [Poison](#poison-applications-cadence-and-fuel), [values](#reviewed-skill-values) |
| Potency | [Defense debuffs](#shred-decay-defense-debuffs-and-consume) |
| Precision | [Buffs](#bladedancer-and-bypass), [repeat eligibility](#repeat-and-proc-eligibility) |
| Quick Cut | [Grant order](#bladedancer-and-bypass), [values](#reviewed-skill-values) |
| Readiness | [Bladedancer and Bypass](#bladedancer-and-bypass) |
| Rending Slash | [Shred](#shred-decay-defense-debuffs-and-consume), [values](#reviewed-skill-values) |
| Resonance | [Poison fuel](#poison-applications-cadence-and-fuel) |
| Riposte | [Bladedancer and Bypass](#bladedancer-and-bypass) |
| Shadow intrinsic | [Direct-hit crit hook](#repeat-and-proc-eligibility); complete T8 binding under D011 |
| Shadow Mastery; Sharpened Edge | [Derived stats](#aggregation-and-derived-stats) |
| Shred | [Statuses](#shred-decay-defense-debuffs-and-consume) |
| Side Step | [Repeat/proc eligibility](#repeat-and-proc-eligibility) |
| Silvered Edge; Steal | [Gold](#gold-and-combat) |
| Thief intrinsic | [Gold](#gold-and-combat) |
| Touch of Darkness | [Self Buffs](#poison-and-shadow-self-buffs) |
| Umbral Presence | [Poison capacity](#poison-applications-cadence-and-fuel) |
| Venom Jab | [Pending content](#open-content-work-and-reconciliation) |
| Virulent Corruption | [Cleanse](#shred-decay-defense-debuffs-and-consume) |
| Virulent Poison | [Self Buffs](#poison-and-shadow-self-buffs) |
| Whetstone | [Derived stats](#aggregation-and-derived-stats) |

## Open content work and reconciliation

There is no remaining M3 shared-mechanics design question in the completed closeout. These boundaries remain explicit:

| Item | Disposition / owner |
| --- | --- |
| Full four-tree inventory | M5 authors/binds all 44 talents, 140 rank slots and planned skill/unlock inventory. This reference does not certify unreviewed draft ranks. |
| Beguiling Strike, Distilled Corruption | Complete skill values/resources remain M5. Distilled's conversion is settled above; a synthetic test does not certify its entire descriptor. |
| Blinding Powder | Category, timing and Potency mechanism settled; full binding M5. |
| Empty slots | Bladedancer and Thief nine-point slots remain empty unless explicitly changed. |
| Playable builds | M4 starts with exact Bladedancer ten-point core, then Bladedancer 15 / Thief 5 extension. Use T8/T10 evidence; fixtures are not wholesale release assets. |
| Balance/presentation | M6 owns numerical targets/economy/Watchmen; M4/M7 rendered readability/icons. Headless tests do not certify these. |

Reconciliation traps resolved in this edition:

- Earlier Touch multiplication/direct-time proposals are superseded by ordinary additive IAS under D023.
- D018 supersedes earlier Riposte examples with +20% per rank per actual consumed Footwork stack; Fancy Footwork reduces Plunge cast time by 4% per rank per stack.
- D012's macro-only Precision restriction is revoked by D013; eligible proc casts may consume it.
- T7's old forced-tick no-depletion wording is superseded by D024; both tick origins use fuel.
- The legacy noncritical Poison helper's comment does not describe the enabled T9 Critical Poison path.
- Big Score's 110% value is superseded by the user's 90% correction.
- Historical “next task” and incomplete-scope notes describe those handoffs' dates. Use current trackers and this reference for current state.

No gameplay was changed to reconcile these documentation differences. Future discrepancies between approved behavior and code must be recorded with an owner, rather than silently changing the rule to match code.

## Evidence and maintenance

### Evidence baseline

The [M3 closeout](P6M3_T11_Closeout_And_M4_Handoff.md) reconciles C1–C7 and Q01–Q20. Its [65-script regression](../project/reports/p6_m3_t11_regression/summary.json) and [integrated script](../project/reports/p6_m3_t11_integrated_final/summary.json) pass: 66 distinct scripts, with six scenarios × twenty seeds × three trace/replay modes in the integrated test. These are existing runtime results, not a new run for this documentation task.

Both closeout isolation reports show protected saves and Enigma files unchanged. The [T11 checkpoint](P6M3_T11_Repository_Checkpoint.json) remains a historical checkpoint; later documentation edits naturally differ from its hashes.

Related contracts: [progression/allocation](P6M2_T3_Progression_And_Allocation_Rules.md), [identity/compatibility](P6M2_T4_Content_Workflow_And_Compatibility.md), [M3 decisions](P6M3_Shared_Combat_Mechanics_Tracker.md#decision-log), [milestone status](P6_Milestone_Tracker.md).

### Update rules

1. Update this reference in the same task as every accepted mechanics change. Update the owning section and affected quick rules, tables and examples together.
2. Record approval/decision ID or explicit user correction, affected implementation, tests and content-binding status. Keep approved behavior distinct from implementation status.
3. Add a revision entry below. Keep superseded reasoning in historical handoffs/decision logs, outside active rule descriptions.
4. Check consequences for grants/caps, timing/expiry, live/captured values, categories, repeat origins, Consume, conversion, crit, gold and cleanup.
5. Run focused tests when behavior changes. For documentation-only consolidation, check source consistency, calculations and links; do not claim new runtime evidence without executing it.
6. If code and documents disagree without a later approved decision, record both observations and an owner here. Do not invent a resolution or silently promote draft content.

### Revision history

| Revision | Date | Change | Authority / validation |
| --- | --- | --- | --- |
| 1 | 2026-09-24 | Consolidated shared rules, interaction exceptions, skill values, status boundaries and evidence index. | M3 T1–T11; D002–D025 with recorded supersessions; user Big Score 90% correction. Relevant runtime adapters/calculators and existing tests cross-checked; documentation-only change. |
| 2 | 2026-10-03 | Recorded approved Weakness, Weapon Master and Virulent Corruption complete-node rules; distinguished base-one three-stack applications from Rending base-two four-stack applications. | P6M5-D003, user confirmation; specification arithmetic and source checks only. Full bindings and runtime acceptance remain T4; numerical tuning M6. |
| 4 | 2026-10-03 | Complete Thief bindings promoted; shared approved formulas unchanged. | P6M5-D004; M5-T6 implementation, economy and journey evidence. |
| 5 | 2026-10-03 | Pick Pocket 1.80 seconds and ten raw gold; Mug +1 base damage per two credited gold, floored, cap +100. | User tuning request P6M5-D005. |
| 6 | 2026-10-03 | Restored Mug +1 base damage per credited stolen gold, cap +100; Pick Pocket tuning retained. | User request P6M5-D006. |

| 7 | 2026-10-03 | Approved Venom Jab, Poison-only Toxic Tradeoff and basic Assassin ranks; full specification linked. | P6M5-D009; runtime acceptance tracked in T7. |

| 8 | 2026-10-03 | Echoing/Resonance +5% per rank separately; Toxic +10% Poison/-10% physical; primary Assassin +0.5 elemental per point. Fuel and Powder unchanged. | User-approved P6M5-D010 balance implementation. |


## Complete Shadow binding — P6M5-D011

The user approved all four [T8 review decisions](P6M5_T8_Shadow_Design_Review.md). All eleven talents / 35 ranks and automatic skills at 1/3/6/9/12 points are playable in Test Mode and Practice. Primary Shadow has 20% +2 percentage points per Shadow point conditional chance for direct crits to apply one base Poison; secondary has 20%. Poison tick crits do not qualify.

- Beguiling Strike (`skill.toxic_flurry`): 22% weapon damage, 1700/650 ms, no cooldown; one base Decay on connection.
- Death Strike (`skill.killers_mark`): one physical packet, 111% × (weapon roll + 2 × actual current Poison count + applicable physical base bonuses), before ordinary multipliers/defenses. Timing 1500/650 ms, no cooldown; Poison is not consumed. Due natural ticks resolve before impact; this cast's new applications follow its damage.
- Distilled Corruption: 100% weapon damage, 1500/650 ms, no cooldown; connected hit then Consumes up to five actual Decay and converts the consumed quantity to Poison. Poison bonuses apply once, then doubling/cap; no refund at cap, no conversion on zero fuel.
- Blind Spot adds two percentage points crit/rank; Snake Oil adds two base elemental/rank; Deception adds 10% elemental/rank as its own talent factor; Death from the Shadows adds twenty percentage points crit damage/rank.
- Coated Weapons adds two base Poison to Stab/Heavy Slash (D019). Death Touch adds 3/6/9 to eligible stack applications. Umbral Presence raises Poison cap to 80.
- Shadow Mastery copies 10–50% of elemental bonuses as specified above. Death Pact grants the actual Poison/Decay Consume count to each Penetration/Potency and sets both durations to 4/5/6 seconds, regardless of source. Dusk's Shred grant is independently modified. Death Blade rolls 40/80% per positive Poison application and suppresses every Stab Poison source.
- Touch of Darkness and Beguiling Presence retain the settled self-buff consumption, duration and cooldown contracts above.

See [T8 implementation and evidence](P6M5_T8_Shadow_Implementation.md). Current Assassin coefficients follow D010 with the documented D015 successor. T9 verifies the representative mixed-tree/gear matrix; M6 owns broad balance acceptance.

| 9 | 2026-10-04 | Echoing removes bonus damage and adds 40/30/20% natural-tick suppression; negative block/absorb grant 0.1 base per point. | User-approved P6M5-D015. |

D020: Death Strike adds +2 base physical damage per active Poison stack before its 111% weapon coefficient and physical modifiers. Death Blade grants no additional Stab crit chance.

T9 reconciliation: corrected stale quick-reference Touch duration, defense cap and negative-block arithmetic; approved gameplay is unchanged. See [mixed-tree and gear validation](P6M5_T9_Mixed_Tree_And_Gear_Integration.md).

T11 reconciliation: the complete Shadow binding formula now includes D020's +2 base damage per Poison stack, matching the current rule already recorded above. No gameplay values changed. See [M5 closeout and M6 handoff](P6M5_T11_Closeout_And_M6_Handoff.md).
