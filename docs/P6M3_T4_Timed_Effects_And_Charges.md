# P6M3-T4 Timed Effects and Charges

**T9 update (D024):** Natural and forced Poison ticks now both deplete actual fuel (one/two/three stacks), without keyword Consume or Death Pact. Earlier no-depletion forced-tick statements below are superseded. See [T9 final contract](P6M3_T9_Poison_Timing_And_Consumption.md).

Last reconciled: 2026-09-24. Status: **Complete — shared lifecycle, approved effects and opt-in implementation.**

**Current authority:** D023 below supersedes D022's partial Riposte example and
Touch's independent multiplicative-bonus proposal. Riposte is +10% damage per
rank per consumed Footwork stack. Touch is ordinary additive increased attack
speed, not a separate cast-time multiplier. T6/T7 contracts remain settled.

Owner: [M3 tracker](P6M3_Shared_Combat_Mechanics_Tracker.md).
Authority: [T1 approved rules](P6M3_T1_Bladedancer_First_Slice_Specification.md),
T2 D006 ordering, and T3 live recalculation. The user authorized T4 implementation.
Current authority includes the later T6 D010-D013 and T7 D014-D021 decisions,
plus the user's final T4 decisions D023 below. Do not reuse the initial T4 proposal
list as current questions: several of those effects are now implemented in T6/T7.
All remaining effect questions are resolved; final implementation evidence is recorded below.

## Implemented lifecycle

`project/scripts/systems/combat_effect_state.gd` owns fight-local state:

- Explicit definitions contain source ID, duration in integer milliseconds
  (`-1` for untimed), cap (`-1` for uncapped), stack/charge units, additive or
  replacement reapplication, per-unit magnitude and optional T3 stat inputs.
- Grants clip to the hard cap and refresh one shared timer. Replacement grants
  replace the count. Zero-unit grants never refresh an existing instance.
- Partial consumption retains the deadline; all-unit consumption removes the
  instance. Empty consumption is explicit and never creates negative charges.
- New instances receive monotonically increasing fight-local IDs. Refreshes
  retain identity; expiry followed by a grant creates a new identity.
- Definitions and returned snapshots are deep copies. Source resources and
  previously captured cast/stat snapshots remain unchanged.
- Expiry and consumption update/remove the same T3 stat source, which rebuilds
  derived values. Independent effects remain independent stat multipliers;
  stacks within one source add before its multiplier is calculated.
- Expirations are ordered by deadline, then stable effect ID. A caller can
  preserve explicitly inclusive cast-start deadlines. Granting that effect at
  equality still expires the old instance first. This implements T1's asymmetry.
- Reset removes all effect-owned stat sources and records the supplied reason.
  A new fight/retry receives a new lifecycle object; resetting an existing
  object's clock backwards is deliberately rejected.
- Invalid definitions, unknown effects, negative grants/consumption and backwards
  time return errors. Effect state must exclusively own its registered sources;
  callers must check operation errors and must not separately remove them.

The service owns lifetimes, not hit classification, poison accounting, proc
eligibility, defense penetration, cooldowns or build-content interpretation.
Callers advance it before consumers read stats and check returned errors.
Effect storage and its associated stat state are one fight-local ownership unit.

## Approved core adapter and combat integration

`bladedancer_effect_lifecycle.gd` implements the approved contracts with manifest
IDs `skill.quick_cut`, `skill.leaping_plunge`, `skill.parry_strike` and
`talent.bladedancer.fancy_footwork`.

| Effect | Activation and lifetime | Consumption |
| --- | --- | --- |
| Footwork | Connected Quick Cut, including repeats; one base stack plus increased-stack bonuses, then doubling; cap 5; shared 3,000 ms timer refreshed at cap | Plunge consumes all at start, including exact expiry; rank 1–5 reduces ordinary windup by 2/4/6/8/10% per consumed stack, respecting the 500 ms minimum |
| Readiness | Connected retrigger; cap 1; no timer; full block qualifies, dodge/interruption do not | Parry consumes one at start; if absent, cast spends time without effects; later grants cannot enable it retroactively |

`CombatResolver` constructs the adapter only when `PlayerStats.footwork_rank`
or `readiness_enabled` opts in. `bonus_footwork_stacks` is the resolved additional grant before doubling,
clamped nonnegative. Gear, canonical/legacy talent extra stacks and Death Touch
feed Footwork and Bypass exactly once; the resolver doubles the resulting grant
before the lifecycle applies its unchanged cap.
Existing `p6.compat.1` builds leave these inputs disabled.

The scheduler previews Footwork duration without mutation so a cast beyond the
combat window never consumes charges. Accepted casts snapshot/consume resources
at start, before interruption or dodge. Child casts retain zero windup but still
check resources. Footwork/Readiness apply after the cast's trigger subtree;
T6 D013 grants Precision before children as an explicit exception. Inherited
`RETRIGGER` classification identifies same-skill repeats; T6 owns new origin rules.

Poison beats, cast records and cast starts advance lifecycle time while preserving
the approved Footwork deadline opportunity. Final fight cleanup expires deadlines
inclusively, then removes untimed/surviving effects. Invalid root-budget results
clear previously granted effects without producing additional combat outcomes.
Each new resolution/retry starts empty and does not mutate input PlayerStats.

Unready Parry is represented by `resource_unavailable`, not a connected zero-damage
hit. The text log explicitly reports missing Readiness. Full visual presentation,
authored descriptors and redesigned resource promotion remain M4/M5/M7 work.
T5 scheduling and reviewed T6/T7 shared mechanics are complete. These changes do not make the draft trees playable.

## Diagnostics

T2's `effect_lifecycle` envelope carries source, instance and cast ancestry plus
`lifecycle_reason`: granted, refreshed, replaced, consumed, empty_consumption,
expired, fight_end or invalid_simulation (the reset API also accepts retry).
Payloads contain deep before/after state and explicit stack, charge, magnitude
and expiry before/after fields, including zeros after removal. Grants report
requested units and overflow; consumption reports actual units consumed.
T3 emits its accompanying `stats_recalculated` source change.

Cast-start payloads and `CastEvent.lifecycle_snapshot` expose consumed resources,
eligibility and fixed execution time. Effect events are independent of RNG;
disabling trace collection preserves state, event counts and combat RNG/results.

## Current cross-task contracts (reconciled 2026-09-24)

The later [T6 handoff](P6M3_T6_Triggers_Repeats_And_Critical_Interactions.md)
and [T7 handoff](P6M3_T7_Status_And_Mitigation_Interactions.md) supersede the
initial T4 proposals. Their implementation/evidence is theirs; it is not a new
T4 test run. The playable registry remains unchanged.

| Effect | Current authoritative rule and implementation status |
| --- | --- |
| Precision | T6 D013: connected Quick Cut grants one untimed charge, cap one, before child triggers. Eligible Stab/Heavy Slash casts of any origin consume it at start for the initiating cast's guaranteed repeat. Implemented. The user confirms the Footwork damage correction applies to Riposte; Precision stays unchanged. |
| Dance | T6: five-second window, twenty-second shared cooldown, macro-only guarantee. Precision/Dance overlap gives one guaranteed repeat and still consumes Precision. T7 adds independent Self Buff instances and IAS-independent Self Buff casting; overlapping Dance instances do not multiply its one-repeat guarantee. Implemented. |
| Death Pact | T7: no unique Pact player buff. Only explicit **Consume** of actual Poison/Decay grants equal stacks of both enemy debuffs, Penetration and Potency, without extra stacks or doubling. Natural depletion, cleansing and natural/forced ticks are not Consume. Each debuff caps at 100, subtracts one block/absorb per stack respectively, and has a shared refreshed three-second baseline timer. Death Pact adds one second per rank to both debuffs regardless of source (4/5/6 seconds). Cleansable; expiry wins exact-time ties. Implemented. |
| Virulent Poison | T7: separate instances, five charges each, unaffected by stack bonuses/doubling. Every actual natural/forced Poison tick spends one charge from every active instance; empty ticks spend none. Each instance supplies an independent 2x multiplier (two instances = 4x). Charge spending is not Consume. Self Buff; 500 ms cast, five-second cooldown. Implemented. |
| Master of Poisons | T7: independent five-second instances; live elemental resistance ignore, including pre-existing Poison. Decay stays stored and normal resistance resumes on expiry. Self Buff; 500 ms cast, ten-second cooldown. Implemented. |
| Beguiling Presence | T7 and current user reaffirmation: Consume all actual Decay, gain exactly +1 base elemental per consumed stack, no stack amplification. Each cast creates a separate instance with its own quantity and ten-second timer; flat contributions add. Zero fuel cannot erase prior instances. Consumption also triggers Death Pact. Self Buff; 500 ms cast, thirty-second cooldown. Implemented. |
| Touch of Darkness | D023: Consume all actual Poison; +10% ordinary increased attack speed per consumed stack, additive with all other IAS and other Touch instances. Eight-second independent duration, thirty-second cooldown, 500 ms Self Buff cast. No extra-stack amplification of conversion. Zero fuel spends time/starts cooldown without granting or replacing a bonus. Actual Consume triggers Death Pact. Implemented in opt-in descriptors. |

T7 also settles Blinding Powder: Debuff, 1,000 ms base/500 ms minimum, no cooldown,
base Potency equal to invested Assassin points with normal stack modifiers. Its
old active/passive question is closed. Self Buffs ignore increased attack speed;
Debuffs retain normal speed scaling. Preserve T7's category/counter rules.

## Final T4 contracts — D023

The user confirmed all remaining decisions in this conversation:

- **Riposte:** rank 1/2 gives +10/20% Leaping Plunge damage per Footwork stack
  actually consumed at cast start. Five stacks at rank two give +100% (2x total).
  The earlier two-stack +20% example describes rank one. Snapshot this one
  multiplier for the consuming Plunge; a child Plunge must consume its own stacks.
  Preserve Footwork's five-stack cap, inclusive cast-start expiry, normal minimum
  windup, and consumption even if the accepted cast later misses/is interrupted.
- **Bypass:** connected Stab of any origin grants one base stack after its child
  subtree. Full block qualifies; dodge/interruption do not. Add increased-stack
  bonuses, double if applicable, then cap at three. Shared three-second timer
  refreshes at cap; expiry wins exact-time ties. Each stack adds 10% to this
  elemental damage multiplier (three stacks = 1.3x). Damage/ticks use live stats.
- **Footwork grants:** the same approved add-bonuses, double, then cap ordering;
  cap remains five. Precision/Readiness remain one charge; Virulent's fixed five
  charges and the T7 conversion exceptions are unchanged.
- **Touch of Darkness:** consume all actual Poison for +10% ordinary increased
  attack speed per consumed stack. Add to the normal IAS bucket. Eight-second
  lifetime; thirty-second shared cooldown; 500 ms Self Buff cast, unaffected by
  IAS. Actual consumption triggers Death Pact. No bonus stacks/doubling applied
  to the conversion. Zero fuel still casts/starts cooldown but creates no bonus
  and preserves prior instances. Separate future instances add their bonuses
  and expire independently; ordinary cooldown prevents overlap. Normal skill
  minimums, slow/minimum-proc rules and cast-start timing snapshots are retained.

Example: a 20-second base attack with +100% existing IAS takes ten seconds.
Consuming 80 Poison adds +800% IAS, so it takes 20 / (1 + 1 + 8) = two seconds,
subject to its minimum. This supersedes the briefly proposed direct percentage
cast-time reduction and multiplicative Touch stacking; neither is implemented.

## Implementation and closeout scope

- `combat_talent_buffs.gd` uses the existing source-aware stat/lifecycle services
  for Bypass and independent Touch instances. Live Bypass participates in Shadow
  Mastery copying. Touch changes future cast-start plans, never an in-flight cast.
- `combat_resolver.gd` snapshots Riposte's multiplier from consumed Footwork and
  applies it to Plunge damage once, before defense mitigation. Repeats do not
  inherit the parent's consumed stack count. Buff grants and cleanup emit T2/T3
  lifecycle/stat records without additional RNG draws.
- `build_resolver.gd` and `stat_sheet.gd` feed extra-stack grants once from talents
  and gear. Existing Death Touch adapter uses the same path. Raw combat control
  inputs survive temporary-stat rebuilds, including after build derivation.
- `consume_status_effect.gd` and `p6_status_skill_contracts.gd` provide the named
  opt-in Touch descriptor; scheduler validation rejects incompatible definitions.
- `p6_t4_completion_test.gd` covers every Riposte rank/stack count, repeats and
  expiry ties; Bypass cap/refresh, proc/block/dodge/interrupt and child ordering;
  live Poison/Shadow Mastery; Touch conversion, speed/minimums, no-fuel cooldown,
  future overlap, ordinary no-overlap, independent expiry and in-flight timing;
  source isolation, cleanup, seeded replay and trace/RNG parity.

No remaining T4 design question is open. T4 completion covers shared mechanics
and opt-in descriptors, not ranked content promotion, final UI or playable trees.
The registry remains `p6.compat.1`; M4/M5/M7 own content integration/presentation.

## Closeout validation

All **26 scripts pass** in `project/reports/p6_m3_t4_closeout_final/summary.json`.
Final cleanup-boundary coverage and the inherited T7/ordering and failure-consumer
suites pass in `project/reports/p6_m3_t4_final_boundaries/summary.json` (three scripts).
Both `isolation.json` reports confirm protected saves and Enigma files unchanged.
The reports contain exact commands; run with
`python tools/p6/run_foundation_tests.py --report-name <name> <test basenames>`.

The first focused run caught a stunned-window chronology boundary and a test
expectation that ignored final damage rounding; both were corrected before the
passing regression. Final source-composition and cleanup checks also passed.
Historical T4 evidence below is retained separately from this closeout run.

## Validation

All 22 scripts in `project/reports/p6_m3_t4/summary.json` pass. The added
invalidation-cleanup case passes in `p6_m3_t4_followup/summary.json` as well.
Both isolation reports confirm protected saves and Enigma files are unchanged.

Two new scripts cover standalone lifecycle and real resolver integration:

- `p6_effect_lifecycle_test`: all Footwork ranks, capped refresh, exact deadline
  consumption/fresh grants, Readiness eligibility, zero/overconsumption,
  replacement charges, immutable snapshots, invalid inputs, stable simultaneous
  expiry, T3 live Shadow Mastery recalculation/removal, reset and trace parity.
- `p6_effect_combat_test`: actual Plunge windups, block/dodge grants, clipped casts,
  exact-time macro starts, no self-enabling Parry repeat, unready finite progress,
  interruption, seeded replay, trace-on/off combat/RNG equality, invalid config
  and root-budget invalidation cleanup after effects have already been granted.

Run with `python tools/p6/run_foundation_tests.py --report-name p6_m3_t4` followed
by the test basenames. The isolated report's `summary.json` records the exact
commands and final results; `isolation.json` checks real saves and original Enigma
files. The follow-up `p6_m3_t4_followup` report covers the added invalidation case.
Pre-T2 compatibility signatures are unchanged; the observation helper excludes
the two new diagnostic cast fields when comparing the old schema.

Headless evidence establishes implementation behavior, not rendered UI clarity
or playable acceptance. The later closeout above resolves the original remaining
effect questions and completes shared T4/C2 scope. T8/M4 retain integrated acceptance.
