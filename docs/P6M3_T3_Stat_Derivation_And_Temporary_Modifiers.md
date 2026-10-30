# P6M3-T3 Stat Derivation and Temporary Modifiers

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

Date: 2026-09-23. Status: **Complete — approved shared stat derivation and temporary-source foundations.**
Owner: [M3 tracker](P6M3_Shared_Combat_Mechanics_Tracker.md).

## Scope and inherited implementation

Extend the existing BuildResolver/PlayerStats/StatSheet pipeline. RankedBuild
continues to resolve one complete rank resource per selected talent, including
primary-only point scaling. Do not introduce a second allocation/build model.
The playable registry remains `p6.compat.1`; test resources do not promote p6.1.

The source audit found:

- BuildResolver starts with class stats, applies intrinsic and selected talent
  modifiers, applies the aggregated gear StatSheet, then resolves weapon range
  and legacy gear-specific gold/minimum-time contributions.
- Gear numeric affixes add within the gear StatSheet, with its existing floor,
  All Stats and cap order. Talent physical/elemental percentage multipliers
  multiply separately from gear multipliers. Preserve these inherited buckets.
- Increased Gold has a deliberate ordering: class baseline plus aggregated gear
  Increased Gold, multiplied by talent/intrinsic reward multipliers afterward.
  Fast Hands must read the final reward multiplier minus one.
- Chances use fractional units (0.25 means 25%); Increased Gold and Magic Find
  bonuses use fractional percentages; flat damage uses damage units. Multiplier
  1.5 means x1.5, not +1.5%.
- Existing damage calculation keeps floating values until final packet rounding.
  Damage bases have a floor of 1 when applicable; damage multipliers have a
  0.05 floor. Timing uses integer milliseconds and skill-specific minimums.
- The inherited resolver reads damage stats at hit/tick time, but currently has
  no player temporary-stat lifecycle. T4 must call T3's source-change interface;
  T5 owns cast scheduling and T6 owns grant eligibility/order.

## Approved formulas and timing

The user approved Double Dip, Sharpened Edge, Fast Hands, Fill Your Pockets and
timing on 2026-09-23 (P6M3-D007). The subsequent Shadow Mastery clarification
(P6M3-D008) explicitly uses elemental bonuses calculated through the normal
buckets, then the rank fraction, as a separate physical multiplier.
The following formulas are implemented:

| Consumer | Approved formula / example |
| --- | --- |
| Double Dip | Copy 50%/100% of current numeric retrigger chance into crit chance, including temporary numeric bonuses; exclude separate guaranteed-repeat effects. Final crit caps at 100%. |
| Sharpened Edge | Separate x1.2/1.4/1.6/1.8/2 physical damage multiplier on Stab and Heavy Slash, treating the draft's Heavy Strike as that skill. No extra hit packet. |
| Fast Hands | Copy 10%–50% of final Increased Gold bonus to attack speed; +200% gold at rank 5 gives +100% attack speed. Source gold bonus remains. |
| Fill Your Pockets | Copy 20%–100% of Magic Find into a separate elemental multiplier; +150% Magic Find at rank 5 yields x2.5. Retain Magic Find; this bonus feeds Shadow Mastery. |
| Shadow Mastery details | Preserve settled copying of flat elemental bonuses and elemental percentage bonuses into physical benefits, retaining elemental benefits. The effective percentage is the combined elemental multiplier minus one; base class poison damage is excluded from copied flat bonuses. Negative bonuses reduce the copy. |
| Timing | Recalculate after a temporary source changes. Cast time stays fixed at cast start; damage uses current stats at impact, poison at each tick. Preserve fractional values until existing final damage rounding. |

Shadow Mastery's already-settled example remains mandatory: rank-one 10% copy
of +10 flat elemental adds +1 physical base; +150% increased elemental supplies
a separate x1.15 physical multiplier. Both apply together. For combined gear x2 and talent x1.5 elemental buckets,
the effective multiplier is x3: the +200% bonus yields a separate physical
x1.20 at rank 1 and x2 at rank 5. This follows the user’s final clarification;
the interim proposal to add +100% and +50% without their normal bucket product
was not adopted. "Five stacks" in the earlier reply is interpreted as rank 5
of this five-rank passive, not a new stacking buff.

## Source attribution foundation implemented

PlayerStats now carries value-only `stat_sources`. BuildResolver records:

- Class identity and initial numeric values.
- Each intrinsic/talent/gear modifier's stable owner ID, kind, canonical stat,
  operation and authored value.
- Gear's aggregated raw and finalized values and All Stats multiplier.
- Legacy gear-specific gold/minimum-time contributions when present.

Individual gear rows are raw contributions, not independently capped final
benefits: the aggregate row records the actual shared gear transformation.
This avoids falsely attributing the whole cap/floor to one gear item. No source
resource is held in these records. The source ledger does not alter stat math.

## Runtime implementation

- `stat_derivation_rule.gd` is an explicit complete-rank resource with formula
  kind and fraction. Talent and TalentRank own `stat_derivations`; RankedBuild
  adapts only the selected rank. Unsupported resources, nonfinite/out-of-range
  fractions and duplicate active formulas produce errors rather than no-op content.
- BuildResolver compiles the rules after ordinary class/intrinsic/talent/gear
  aggregation, then delegates to `combat_stat_state.gd`. It preserves the existing
  pipeline, weapon range and build allocation model.
- CombatStatState holds an independent raw baseline and temporary source values.
  Recomputing starts from that baseline each time. Fill Your Pockets runs before
  Shadow Mastery; source enumeration cannot change dependency order.
- PlayerStats stores separate temporary/derived damage multipliers and targeted
  skill multipliers. Sharpened Edge multiplies the existing physical packet
  before mitigation/rounding, including a physical packet later converted by gear;
  it creates no extra hit, status grant or random roll.
- Invalid derived builds propagate an explicit error into ranked resolution or
  an invalid CombatResult, using T2’s no-outcome/no-reward consumer handling.

### Temporary source contract

`replace_source(instance_id, source_id, modifiers, time_ms, trace, context)` adds
or replaces one source. `remove_source` removes it; `rebase` replaces build/gear
inputs while retaining active sources. All return an error string (empty on
success), and invalid changes leave state untouched. Inputs are copied into
value dictionaries. Returned snapshots include independent copies of baseline
and derived data; changing source Resources or earlier snapshots cannot change
fight-local state.

Temporary inputs are explicit finite canonical ADD amounts: flat physical/base
elemental damage, attack speed, crit chance/damage, numeric retrigger chance,
Increased Gold, Magic Find and physical/elemental damage percentages. Unsupported
stats/operations are rejected. ADD means a bonus amount: 0.5 percentage damage
means a x1.5 factor, not a factor of 0.5. Values within one effect instance combine;
independent physical/elemental percentage sources multiply separately, consistent
with talent multipliers. Other scalar contributions add to their resolved input
stat. T4 supplies an instance's full current amount, including any stack scaling;
replacing an instance never accumulates its old values again.

Chance clamps and zero floors for gold/Magic Find happen after temporary numeric
aggregation. Damage percentages cannot create negative damage factors, and the
existing final combined damage-multiplier floor of 0.05 remains. Flat damage
flooring and final packet rounding stay in their existing consumers. The timing
consumer retains its 0.05 speed-factor floor and skill minimum. Negative elemental
bonuses that survive ordinary buckets copy as negative Shadow Mastery benefits.

`cast_start_snapshot` returns a value containing current attack speed and duration.
An already captured duration never changes when sources change. `snapshot()`
returns current stats for impact/tick consumers; the resolver’s hit and poison
functions read the supplied current values. T4/T5 must connect actual lifecycle
changes to these calls at the T2 phases. No scheduled buff grants, expiration
engine or redesigned skill implementation is claimed by T3.

Construct a fresh state per fight from the resolved build. A snapshot's stored
raw baseline prevents previously derived copies being copied again; explicit
active-source ownership remains in its originating CombatStatState. Do not use a
previous fight's mutable state as the next fight's state.

### Diagnostic contract

The existing T2 v1 envelope gains additive event/payload information:

- `build_stats` at time zero includes resolved values, source ledger and formula
  inputs/fractions/outputs.
- `stats_recalculated` includes before/after values, source and instance IDs,
  update reason, source ledger and derived explanations. Optional cast/root
  context is preserved; changes cannot move simulation time backwards.
- Cast starts include the speed used; resolved casts carry current impact stats,
  effective crit values and the skill multiplier. Poison ticks record the current
  unmitigated poison value they used.

A formula's `output` is its requested copy or multiplier before a final target
chance cap; the final value is recorded in the resulting stat snapshot. No
observation uses RNG. The compatibility signature helper excludes the newly added
`stat_snapshot` observation field, just as it already excluded T2 event IDs; no
expected combat signature was changed.

## Validation and scope boundaries

`p6_stat_derivation_test.gd` covers every approved rank formula, the scalar
Bladedancer ten-point allocation and role reversal, gear/talent bucket order,
Shadow Mastery's flat and percentage examples, Fill Your Pockets composition,
negative and fractional copies, complete-rank replacement, invalid descriptors,
temporary replacement/removal/rebase, source order, caps/floors, snapshot isolation,
fixed start duration with live hit/tick reads, real Sharpened Edge packet damage
and unchanged trace-on/off RNG/results. `p6_stat_sources_test.gd` verifies source
provenance and immutable contribution records.

Core delivery and broader shared formulas are both implemented and tested at
T3 scope. Scalar-only fixtures for Rending Slash/Fancy Footwork do not execute
their effects and are not released content. Actual lifecycle wiring (T4), macro
scheduling (T5), trigger eligibility (T6), gold transactions (T10), tree-content
promotion (M4/M5) and rendered UI acceptance remain with their named owners.
The `p6.compat.1` registry and source drafts are unchanged.

## Final validation evidence — 2026-09-23

Godot 4.7 stable: **29 distinct headless scripts pass** in their final applicable
runs. The initial 29-script run passed 28 and exposed a stale P5M3 gear-save test:
it wrote the current save version without the required Phase 6 `build` envelope.
The fixture now includes that envelope, matching the already-updated P5M2
boundary tests. Its existing canonical stat/gear assertions remain unchanged;
no save runtime behavior was changed. The corrected fixture and six related
stat/ranked/persistence scripts passed the seven-script follow-up.

Both isolated runs report `unchanged: true` for protected FacelessVoid/Enigma
save and Enigma project/export fingerprints. No script errors or assertions
remain in the final results. The inherited headless certificate-store/shutdown
resource diagnostics remain nonblocking. No rendered playtest is claimed.

Exact commands (PowerShell, repository root):

```powershell
python tools/p6/run_foundation_tests.py --report-name p6_m3_t3 p6_stat_derivation_test p6_stat_sources_test p6_ranked_build_test p6_foundation_integration_test p6_balance_adapter_test p6_persistence_test p6_persistence_ui_test p6_combat_ordering_test p6_combat_failure_consumers_test p5m3_stat_sheet_aggregation_test p5m3_all_stats_scaling_test p5m3_foundation_regression_test p5m4_base_damage_physical_buckets_test p5m4_negative_stat_floors_test p5m4_rounding_floors_mitigation_order_test p5m4_deterministic_weapon_rolls_test p5m4_retrigger_semantics_test p5m4_crit_applies_poison_test p5m10_legendary_combat_effects_test p5m11_economy_stats_test p5m11_overkill_gold_test deterministic_replay_test combat_playback_test combat_recap_test shadow_parity_test thief_subclass_test combat_screen_test training_room_fight_test skill_tooltip_formatter_test
python tools/p6/run_foundation_tests.py --report-name p6_m3_t3_followup p6_stat_derivation_test p6_ranked_build_test p6_foundation_integration_test p6_balance_adapter_test p6_persistence_test p6_persistence_ui_test p5m3_foundation_regression_test
```

Evidence: `project/reports/p6_m3_t3/{summary,isolation}.json` and
`project/reports/p6_m3_t3_followup/{summary,isolation}.json`, with per-test logs.
Reports are generated/ignored; the tests and this evidence summary are retained.

Next is **P6M3-T4 — Timed effects and charges**. Use T3's source-instance API
at the approved T2 lifecycle phases, and extend the deterministic scenarios
through actual grants, consumption and expiration. These formulas do not
approve any additional talent content or bypass M4/M5 release gates.
