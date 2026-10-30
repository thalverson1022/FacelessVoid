# P6M3-T9 — Poison timing and consumption

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

Status: **Complete for reviewed shared-mechanics scope.**
Date: 2026-09-24. Decision: **P6M3-D024**.

## Approved contract

The user's T9 answers supersede D015's no-depletion forced tick rule and the
initial T9 proposals. Tick depletion remains distinct from keyword Consume:
neither natural nor forced ticks trigger Death Pact. Cleansing also does not.

### Cadence

Hastened Poison contributes 10% of increased attack speed per rank (five ranks);
Accelerant adds another 10% per rank (five ranks). Both at maximum apply 100%
of increased attack speed to Poison's tick rate. Accelerant requires at least
one rank of Hastened Poison.

`interval_ms = max(1, round(1000 * legacy_interval_multiplier * (1 + effective_suppress) / (1 + max(0, IAS) * 0.1 * (hastened_rank + accelerant_rank))))`

This preserves the existing interval modifier, suppress and one-millisecond
floor. Enemy slow remains a cast-time modifier. The fight-wide clock runs even
with no Poison. Changes in IAS preserve fractional tick progress; Touch's
activation and exact expiry both reschedule, including during long/clipped casts,
stun gaps and cooldown waits. Fractional deadlines round up to the next integer
millisecond. Each natural tick resets phase; forced ticks never reset it.
Natural ticks resolve before same-time skill completion. At exact buff expiry,
live damage stats exclude the expired buff; already-earned tick progress remains.

### Fuel and damage

Without either talent, each tick depletes up to one stack. Echoing Toxin requests
two; Resonance replaces that with three and requires Echoing Toxin. Natural and
forced ticks use the same rule. Partial fuel produces proportionate damage;
zero fuel produces no damage, no crit roll and no Virulent charge expenditure.

`raw_tick = ordinary_poison_damage * actual_stacks_depleted * (1 + 0.1 * echoing_rank) * (1 + 0.2 * resonance_rank)`

Echoing has three ranks; Resonance has four. Multipliers are separate. Ten damage
per stack at maximum ranks gives `10 * 3 * 1.3 * 1.8 = 70.2`; two remaining stacks
give `10 * 2 * 1.3 * 1.8 = 46.8`. This is one packet, not separate hits. Existing
live elemental bonuses, negative-absorb base bonuses and Virulent multipliers
apply. Each Virulent instance spends one charge per fueled tick, irrespective
of stack count or whether mitigation prevents damage.

### Critical Poison and mitigation

Critical Poison rolls once per fueled packet on the shared seeded combat RNG,
after computing raw damage. It samples current crit chance and multiplier,
including current stolen/stash-gold contributions. Empty ticks and disabled
Critical Poison draw no tick RNG. A successful roll multiplies the whole packet.
Existing conversion, resistance, block/absorb and physical-destination critical
negation rules then apply. Final damage retains existing integer rounding:
70.2 becomes 70 against neutral defenses without a crit. Trace keeps raw 70.2.
Ticks remain ineligible for Shadow's direct-hit crit-to-Poison hook and Death
Blade application rolls; they do not become attacks or retrigger sources.

### Poison Strike

Attack, 83% weapon damage, 1200 ms base, 500 ms minimum, no cooldown. A connected
cast causes one ordinary Poison tick, including eligible repeated/proc casts.
Dodge/interruption prevents the forced tick; block does not erase a connected
hit's attached effect. Natural tick first, then the connected cast's forced tick,
then existing status application/cleanse ordering. Explicit keyword Consume
still uses actual available stacks and is the only depletion path here that
triggers Death Pact.

## Implementation and reporting

- `poison_cadence.gd`: fractional phase with live IAS rescheduling.
- `p6_poison_contracts.gd`: validated opt-in passive adapter and reviewed Poison
  Strike descriptor. Talent prerequisites/rank limits are checked.
- `combat_resolver.gd`: shared natural/forced fuel, one-packet damage, critical
  RNG, live stats, rank validation and complete stack/charge/crit diagnostics.
- Tick traces include before/requested/depleted/remaining stacks, raw/final
  damage, crit inputs/outcome, mitigation, cadence and source ancestry.
- Virulent spends identify grant source, instance and before/after charges.
- Consume transactions distinguish requested from actual consumption.
- Recap uses actual pre-tick stack counts; inspector exposes depletion/crit data;
  text output identifies critical/forced/multi-stack ticks, even fully prevented
  fueled ticks. Full visual acceptance remains M4.

These are shared mechanics and fixture adapters, not full Assassin content
promotion. `p6.compat.1` remains the playable registry; full tree binding belongs
to M5. No draft balance values were changed beyond the user's decisions.

## Validation

`p6_poison_contract_test.gd` covers every legal Echoing/Resonance rank pair at
0/1/2/3 fuel for both tick origins, exact RNG draw counts, partial-fuel damage,
70.2 raw damage, gold-derived crit, converted critical mitigation, Virulent
provenance, sequential Consume exhaustion and exact Death Pact conversions.
It also covers additive IAS, suppress, minimum interval, phase preservation,
Poison Strike timing/scaling, natural-before-forced ties, seeded replay and
Touch expiry during a clipped cast (next tick at 9812 ms).

The inherited status and ordering suites remain part of that test. Legacy
compatibility snapshots exclude new observation fields, preserving their
original gameplay hash and RNG checks.

All 36 regression scripts pass, plus five final boundary/reporting/playable
consumer checks. Both isolation reports confirm protected FacelessVoid/Enigma
saves and Enigma project/export files are unchanged.

- [36-script regression](../project/reports/p6_m3_t9_regression/summary.json)
- [Final five checks](../project/reports/p6_m3_t9_final/summary.json)
- [Reproducible Poison trace](../project/reports/p6_m3_t9_final/poison_handoff.json)
- [Regression isolation](../project/reports/p6_m3_t9_regression/isolation.json)
- [Final isolation](../project/reports/p6_m3_t9_final/isolation.json)

Final check command:

```powershell
python tools/p6/run_foundation_tests.py --report-name p6_m3_t9_final p6_poison_contract_test combat_recap_test combat_playback_test training_room_fight_test combat_screen_test
```

T9 is complete. Next: **T10 — Gold-based combat and mixed-tree extension**.
Full tree promotion and visual acceptance remain downstream.
