# P6M3-T7 Status and Mitigation Interactions

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

**T9 update (D024):** Natural and forced Poison ticks now both deplete actual fuel (one/two/three stacks), without keyword Consume or Death Pact. Earlier no-depletion forced-tick statements below are superseded. See [T9 final contract](P6M3_T9_Poison_Timing_And_Consumption.md).

**Later T4 closeout:** [T4 is Complete under D023](P6M3_T4_Timed_Effects_And_Charges.md#final-t4-contracts--d023).
Earlier statements assigning remaining T4 review/implementation describe that
handoff's original checkpoint. Riposte, Bypass and Touch are now implemented;
Touch uses ordinary additive IAS with independent expiration. Existing T6/T7
contracts and their historical validation remain unchanged.

Date: 2026-09-24. Status: **Complete for reviewed shared-mechanics scope. Named content promotion and broader T9/T10 work remain downstream.**

Owner: [M3 tracker](P6M3_Shared_Combat_Mechanics_Tracker.md). This handoff consolidates the user's successive clarifications, including D014–D021, and supersedes the earlier pending proposals. The playable registry remains `p6.compat.1`; new mechanics use opt-in fixture inputs until content promotion.

## Approved rules and implementation

### Status quantities, conversion and cleansing

- Decay has an explicit fight-local count, including when base resistance is zero. Removing stacks restores resistance to `base_resistance * (1 - decay_value)^remaining_stacks`.
- Rending Slash deals damage before applying its two base Shred stacks, bonuses and doubling. Shred caps at 500. Dodge prevents the application; a blocked connected hit can apply it.
- Virulent Corruption protects **Shred only** against cleansing. Poison, Decay, Penetration and Potency remain cleansable. Existing full cleanse denial still protects all.
- Distilled Corruption consumes up to five actual Decay and makes one Poison application from that quantity. Poison Bonus Stacks apply once, followed by normal doubling. Zero consumption makes no application. Overflow is discarded with no Decay refund.
- Decay-triggered Shred is an independent application: one base Shred plus its own bonuses/doubling per Decay application, rather than copying the final Decay count. The opt-in `independent_decay_shred` flag preserves inherited behavior for compatibility content.
- **Consume is an explicit keyword.** Death Pact reacts only to actual Poison/Decay removed by a Consume effect. Cleansing, ordinary Poison depletion and all natural/forced elemental ticks are not Consume. Poison Strike's caused tick must not consume Poison; its full implementation remains T9.
- A conversion Poison application reports actual additions and supplies one Death Blade candidate, not one per stack. Existing Stab poison suppression applies to this source too.

### Defense baselines and timed debuffs — D014/D015/D016

- Finders Keepers rank one halves encounter-start block; rank two sets it to zero. Full block-denial gear also establishes zero starting block and is redundant with either rank.
- Full absorb-denial gear establishes zero starting absorb in the same way.
- **Penetration** subtracts one block per stack; **Potency** subtracts one absorb per stack. They have independent 100-stack caps and three-second baseline timers. Adding stacks refreshes the whole timer, including at cap. At the exact expiry time, the old stacks expire before the next operation.
- Death Pact ranks add one second per rank to both debuffs regardless of source: rank 1/2/3 gives 4/5/6 seconds.
- Ordinary grants receive their own Bonus Stacks and normal doubling. Death Pact instead grants exactly the actual consumed quantity to **both** debuffs, with no Bonus Stacks or doubling.
- Blinding Powder applies base Potency equal to invested Assassin points, then normal bonuses/doubling. Its base cast is 1,000 ms, minimum 500 ms, with zero weapon damage and no cooldown. No cooldown for all debuffs is a working direction, not a universal rule.
- Cleansing removes both timed debuffs without producing consumption. Expiry and fight cleanup also remove them.

### Categories and final defense clarification — D017

Skills explicitly declare Attack, Debuff or Self Buff. Debuffs and Self Buffs cannot be dodged, do not require a hit, and neither advance nor reset cleanse/interrupt counters. In particular, they leave an existing repeated-attack interrupt streak unchanged.

| Category | Confirmed skills |
| --- | --- |
| Debuff | Blinding Powder, Thief Pick Pocket, Assassin Poison Vile |
| Self Buff | Dance of Death, Virulent Poison, Master of Poisons, Touch of Darkness, Beguiling Presence |
| Attack | Reviewed attack skills; Hold retains its compatibility behavior |

Negative defense adds its magnitude to the **original damage type's base**, before applicable damage scaling. Conversion happens afterward, and the resulting type's positive defenses mitigate the converted damage. The resulting type does not supply a second negative-defense base bonus.

Example: physical base 10, effective block -5 and a 2x physical multiplier produce 30 physical damage. Convert to magical and apply positive absorb 4 to obtain 26 (with other mitigation neutral). Negative absorb does not boost this originally physical packet. Conversely, originally elemental Poison uses negative absorb for its base bonus before conversion to physical and positive block mitigation. Empty Poison ticks still deal zero damage.

## Further approved skill contracts — D018

These decisions were approved after the D017 regression run. Their shared
implementation and later validation are recorded in the closeout below.

- **Death Touch:** contributes +2/4/6 to the same extra-stack mechanic as gear.
  Gear +1 and rank-three Death Touch +6 give +7 extra stacks. It is not a second
  application or independent multiplier. Previously agreed conversion exceptions
  (Death Pact and Beguiling Presence) still bypass extra-stack bonuses. This does
  not independently extend gear's stack mechanic to every player buff.
- **Poison Vile:** Debuff; one base-20 Poison application using normal extra-stack
  and doubling rules. Doubling alone gives 40; +2 extra alone gives 22. Under the
  already approved bonus-then-double order, both give 44 before capacity limits.
  D021 confirms Debuff category, 1,800 ms base cast, 500 ms minimum cast,
  zero-percent weapon damage and no cooldown. It applies 20 base Poison stacks.
  Debuff timing follows normal attack-speed scaling down to the minimum; the
  Self Buff attack-speed exception does not apply. D019 corrects the mistaken
  gear-cap question below.
- **All Self Buffs:** increased attack speed does not affect their cast time.
  This category-wide rule must also be applied when updating existing self buffs.
- **Master of Poisons:** Self Buff, 500 ms cast, five-second duration, ten-second
  cooldown. Every elemental damage instance during the window treats enemy
  resistance as zero, including Poison applied before activation. On expiry,
  normal live resistance applies again; underlying Decay is not removed.
- **Virulent Poison:** Self Buff, 500 ms cast, five-second cooldown. Grants a buff
  with five stacks; the next five actual Poison ticks deal double damage, whether
  natural or caused by Poison Strike. This spends buff charges, not keyword
  Consume of enemy Poison, and must not trigger Death Pact. D019 confirms separate instances and exactly five charges per instance, unaffected
  by extra stacks or stack doubling. D020 confirms a separate 2x damage multiplier per active instance.
- **Beguiling Presence:** Self Buff, 500 ms cast, ten-second duration, thirty-second
  cooldown. Consume all actual Decay and gain +1 base elemental damage per consumed
  stack. The conversion is exactly one-to-one, with no extra-stack amplification.
  Each cast creates a separate instance with its own quantity and timer; do not
  replace an existing instance. Zero fuel contributes zero damage bonus and cannot
  erase an older instance. Ordinary cooldown exceeds duration, so overlap is not
  normally possible. Actual Decay consumption also feeds the agreed Death Pact rule.
- **Bribery:** one normal Shred application per successful theft event, regardless
  of amount stolen, using the rank's base quantity and normal stack modifiers.
  Steal requires a critical hit that steals gold; Pick Pocket is a Debuff but
  mechanically steals gold and also qualifies. “One application” does not change
  the talent's base 2/4/6 Shred to one stack. No successful theft means no trigger.

## Charges, independent instances and cap-source correction — D019

User clarification following D018; implemented in the closeout below:

- Self Buff recasts create separate instances, rather than merging or replacing
  the previous instance. Each keeps its own remaining duration or charges.
- Virulent Poison always grants **five charges** per instance. Extra stacks and
  stack doubling do not increase charges. Use the distinct word charges in rules
  and presentation; do not silently rename enemy stack mechanics or other resources.
- Each actual Poison tick spends one charge from every active Virulent instance.
  With instances at three and five charges, three ticks leave the first exhausted
  and the second at two charges. Natural and Poison Strike ticks both qualify.
- **D020 — approved overlap:** each active Virulent instance contributes a
  separate 2x multiplier to the same Poison tick. Two instances give 4x damage;
  in general N active instances give 2^N. Each spends one charge on that tick.
  With three and five charges remaining, the next three ticks receive 4x damage,
  then the remaining two charges of the second instance provide 2x damage.
  Implemented and tested by the T7 completion suite.
- Poison Vile applies extra stacks first, then doubling, then the Poison cap.
  Base 20 plus two extra, doubled, requests 44; on an empty target with ordinary
  cap 20, only 20 apply and 24 overflow. A higher cap comes from an actual cap
  modifier, not from stack doubling or extra stacks.

**Correction to the assistant's earlier gear claim:** no current gear roll pool
contains `poison_stack_cap_40`, and no authored gear resource applies it. The
stat exists in the catalog and generic resolution code because the old Umbral
Presence talent (`project/data/talents/shadow/umbral_pressure.tres`) applies it.
The redesigned Umbral Presence draft raises the cap to 80. This is old versus
redesigned talent content, not a competing cap-40 gear source. The proposed
gear/talent cap-precedence question is withdrawn; no new cap gear is authorized.

Evidence: `stat_catalog.gd` defines the special stat but omits it from every
`SLOT_CATEGORY_POOLS` entry; `gear_generator.gd` selects those slot pools.

## Runtime and diagnostics

- `skill.gd` provides the explicit category; scheduler and trigger validation reject invalid category/effect definitions. Category checks control dodge, hit eligibility and enemy counters.
- `combat_defense_debuffs.gd` owns encounter-start defenses and enemy-owned timed effects using `combat_effect_state.gd`. Cleanse uses removal rather than charge consumption.
- `apply_defense_debuff_effect.gd` and `consume_status_effect.gd` describe applications and explicit consumption. PlayerStats supplies resolved ranks, Assassin points, bonus quantities and the opt-in selective cleanse/mirroring rules. This is not yet authored build-stat wiring for the redesigned trees.
- Resolution applies damage, then explicit consumption/defense grants, then status additions and applicable cleanse. Consuming Decay restores resistance before descendant casts/ticks. A newly granted defense debuff affects subsequent damage, not the direct damage already resolved for its granting cast.
- Cast `status_transactions` distinguish requested, actual, removed, consumed and overflow quantities. `status_snapshot` records final cast status quantities and defenses; mitigation diagnostics record defenses at impact. Timed grants/expiry/cleanse use the effect lifecycle trace, including enemy ownership.
- Natural tick diagnostics retain the legacy `stacks_consumed` field for old consumers but explicitly mark `keyword_consume: false` and report `stacks_depleted`. Do not use that legacy field to trigger Consume effects.
- Recaps read the authoritative post-cast snapshots for restored resistance and selectively preserved Shred. Compatibility signature helpers exclude new diagnostic fields; expected historical hashes are unchanged.

## Validation

`project/reports/p6_m3_t7_reviewed_final/summary.json` records the 22-script final regression run. Run it with `python tools/p6/run_foundation_tests.py --report-name p6_m3_t7_reviewed_final` and the script names in that report. Its `isolation.json` records protected-save and Enigma-file integrity.

`p6_status_interactions_test.gd` covers category counter preservation and dodge exclusion; Powder timing/no cooldown; all duration ranks; capped refresh and exact expiry; gear denial and Finders Keepers redundancy; negative-defense scaling and both conversion directions; partial Decay restoration; Poison/Decay Consume and zero fuel; bonuses/doubling exceptions; overflow without refund; one Death Blade candidate per conversion; natural depletion exclusion; independent mirroring; selective cleanse; recap values; invalid definitions; cleanup; seeded replay and trace/RNG parity.

The remaining scripts cover inherited status accounting, repeat/trigger contracts, ordering, effects, scheduling, stat derivation, Shred/Decay, conversion, critical Poison, enemy defenses, Opportunity, replay, recaps, playback and failure consumers. A direct poison-tick helper compatibility failure in the first broad run was fixed and retested before the final run.

Earlier evidence remains in `p6_m3_t7`, `p6_m3_t7_final`, and the intermediate category/damage/interaction reports. These do not replace the final reviewed contract. Headless checks establish mechanics, not rendered UI acceptance or final balance.

## Shared-mechanics closeout

T7 is Complete for the reviewed shared mechanics. All six implementation and
verification steps requested by the user have evidence below. This does not close
T4, T9, T10 or promote redesigned content into the playable registry.

- `combat_self_buffs.gd` stores separate instances with source/instance identity,
  immutable lifecycle snapshots, independent deadlines, and five fixed Virulent
  charges. Active Virulent instances multiply damage by 2 each and spend one
  charge each on actual natural or forced ticks. Empty ticks spend none.
- `combat_timing.gd` applies the Self Buff attack-speed exception centrally.
  Existing slow and minimum-proc behavior is retained. Dance also keeps separate
  lifetimes, while its already approved guarantee remains one repeat per cast.
- `self_buff_effect.gd` and the extended `consume_status_effect.gd` activate
  Master/Virulent and Beguiling. Master uses live resistance ignore at damage
  resolution (including converted elemental hits), without changing stored Decay.
  Beguiling consumes actual Decay, restores resistance, triggers Death Pact, and
  grants an independent ten-second base-elemental bonus without extra stacks.
- `p6_status_skill_contracts.gd` supplies the reviewed Master, Virulent, Beguiling
  and Poison Vile descriptors. Its passive adapter combines Death Touch with the
  same fields as gear, applies Umbral's cap 80, and resolves Bribery's base rank
  quantity. Gear and ordinary talent extra-stack paths now also feed Penetration
  and Potency. Inputs are copied; the adapter never changes the source build.
- `forced_poison_tick_effect.gd` uses the same tick damage/buff path as natural
  ticks, without enemy Poison depletion or cadence changes. The adapter attaches
  this effect to a separately reviewed attack descriptor. It does not invent the
  remaining Poison Strike attack values or implement unrelated T9 critical Poison.
- `steal_gold_effect.gd` supports unconditional theft such as Pick Pocket. Actual
  successful theft and existing critical theft each grant one normal Bribery
  application per event. No gold means no grant. Dodge/interrupt still prevent
  attack theft; Debuffs retain their approved counter/dodge behavior.
- Tick origin is explicit and recap peak-stack accounting handles forced ticks
  without inventing a consumed stack. Self-buff impact values and lifecycle
  records expose the information needed for later presentation.

### Final evidence

All **24 scripts pass** in `project/reports/p6_m3_t7_completion_regression/summary.json`.
The expanded completion suite passes again in
`project/reports/p6_m3_t7_completion_boundaries/summary.json`.
Both isolation reports confirm protected saves and Enigma files are unchanged.

`p6_status_completion_test.gd` includes the earlier T7 and ordering suites and adds:
gear +1 plus Death Touch rank three = +7; Poison Vile timing, caps and 44-stack
request; IAS-independent Self Buffs; 3/5 Virulent charges giving three 4x ticks then
two 2x ticks; independent expiry; natural/forced charge spending and zero fuel;
normal-cooldown overlap; live Master activation/expiry and converted damage;
Beguiling base scaling/restoration/Death Pact; Bribery success/zero/critical cases;
immutable trace identity, cleanup, input isolation, replay and trace/RNG parity.
Historical compatibility hashes remain unchanged. No visual or balance acceptance
is claimed by these headless checks.

### Downstream ownership

| Work | Owner |
| --- | --- |
| Remaining unrelated buff contracts (e.g. Bypass, Riposte, Touch of Darkness) | T4 |
| Poison cadence/phase changes, Accelerant/Resonance, multi-consumption and critical Poison; full Poison Strike descriptor | T9 |
| Full theft/reward economy and remaining Thief skill values | T10 |
| Rank-resource binding, registry promotion, tooltips/log/UI treatment and playable acceptance | M4/M5/M7 |

These owners retain their own acceptance criteria. They can reuse the tested T7
adapters without reopening settled stack, charge, conversion or defense rules.

## Poison Vile final timing — D021

Approved: Debuff; base cast 1.8 seconds; minimum cast 0.5 seconds; zero-percent
weapon damage; no cooldown; applies 20 base Poison stacks. Normal extra stacks
apply before doubling, then the available Poison capacity limits actual additions.
Existing Debuff rules exclude dodge and cleanse/interrupt counter interaction.
This resolves its outstanding timing question. The reviewed descriptor and application are now tested in the completion suite;
the earlier 22-script report does not cover this later approval.
