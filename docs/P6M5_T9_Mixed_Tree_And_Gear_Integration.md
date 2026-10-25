# M5-T9 — Mixed-tree and gear integration

Date: 2026-10-06. Status: **Complete. Next: T10 full-content player-flow acceptance.**

Authority: the user requested execution of the seven-step T9 plan. Current runtime
is `p6.playable.shadow.1`, with approved tuning through P6M5-D023. The original
[T2 coverage plan](P6M5_T2_Content_Reconciliation_And_Coverage_Plan.md) defines
the interaction families; its historical coefficient examples do not override
later approved decisions. No new gameplay design or numerical tuning is proposed.

## Current baseline

- D012: cooldowns start at completion, shared across duplicate skill IDs.
- D013–D015: Powder casts in 1200/500 ms; Penetration/Potency cap at 50;
  Virulent cooldown is ten seconds; negative block/absorb add 0.1 base per point.
  Echoing adds 40/30/20% natural-tick suppression and no damage bonus. Echoing
  uses two fuel; Resonance replaces that with three and retains +5% damage/rank.
- D016–D018: Pick Pocket cooldown eight seconds; Big Score multiplies the full
  crit multiplier by six; Fancy Footwork reduces Plunge by 4%/rank/stack and
  Riposte adds 20% damage/rank/stack.
- D019–D023: Coated Weapons grants two base Poison; Death Strike adds two base
  damage/Poison; Death Blade chance 40/80%; Death Touch adds 3/6/9 stacks;
  Dusk adds ten Shred Value. Touch gives +10% IAS and +2 physical base per
  consumed Poison for twelve seconds. Beguiling Presence gives +1 elemental
  base and +2 percentage points crit per consumed Decay for ten seconds.
- Mug's damage cap is 50, Silvered Edge caps its own contribution at 25/50/75
  percentage points, and Gilded Blade caps its own gold-derived contribution.
  Original M3 examples with different values remain historical evidence only.

## Matrix and reproducible fixtures

[Matrix suite](../project/tests/p6_mixed_gear_integration_test.gd) defines exact
rank maps, macros, synthetic gear affixes and target properties. All builds use
the actual released registry and allocation validator, not injected talent flags.

For every unordered pair, test both 35/10 allocations and a deeper 22/23 split,
then reverse primary/secondary without changing those allocations. This gives
36 legal builds across all twelve ordered combinations. Five seeds (1–5),
30-second windows, 100 starting gold and HP 100,000,000 are used for the combat
matrix. Separate zero-stash five-seed Lab parity checks use the same builds.

Each build runs nine target cases with Crude Dagger: neutral, armor 300,
75% resistance/15 absorb, block 30, cleanse every two attacks, guaranteed dodge,
interrupt skip count two, 50% slow/75% suppress, and full crit negation. Six
additional gear profiles cover scalar bonuses, stacks/doubling, block/absorb
denial, and physical/magical/both conversions. A Bandit Blade case checks the
inherited gold snapshot. Synthetic affix combinations isolate supported stat
consumers; they are not claims about loot-generation legality or balance.

Every matrix seed is rerun with tracing enabled and disabled. Assertions check
trace equality, outcome/RNG equality, damage and gold sums, Poison bounds,
cooldown waits, Stab suppression, fight cleanup, and source-stat immutability.
Independent expected formulas check role-only intrinsic scaling, gold buckets,
Double Dip, Fast Hands, Fill Your Pockets, Toxic Tradeoff, Weapon Master and
Shadow Mastery, including temporary source removal and Bandit Blade spending.

## Pairing acceptance and evidence

| Pair | Allocated interaction checks | Supporting current regression |
| --- | --- | --- |
| Bladedancer / Thief | Numeric retrigger copied by Double Dip; gear/intrinsic/Sticky gold buckets and Fast Hands; Bandit spending; Dance/Footwork combat. Additional 21/24 split reaches Virulent Corruption with Bribery and observes preserved Shred at cleanse. | Full Bladedancer/Thief, gold contract, repeat contracts, exact core/mixed journeys, Thief economy. |
| Bladedancer / Assassin | Gear physical × Weapon Master × Toxic; actual Precision/Opportunity with Poison/Bypass; IAS and cadence under slow/suppress. | Full Assassin, Poison contract, trigger origins, stat derivation, scheduler. |
| Bladedancer / Shadow | Precision consumed by proc Stab is an observed matrix path; all Stab Poison sources suppressed; independent Decay/Shred, stack amplification and Mastery. | Repeat contracts assert exact same-hit ordering; full Shadow and Shadow boundaries verify application origin/caps and D023 carriers. |
| Thief / Assassin | Fast Hands and elemental derivation from actual ranks/gear; live theft with Critical Poison; Powder and Finders reachable together in deeper splits. | Gold contract/live crit, Poison contract, full Thief/Assassin and economy. Pact requires Shadow and is excluded from this two-tree pair. |
| Thief / Shadow | Fill/Loaded Dice precede Mastery; actual Finders rank two plus Distilled/Pact creates block -5; Pact bypasses stack amplification and expires at 5000 ms. | Status interactions/completion, full Thief/Shadow, gold caps and snapshot tests. |
| Assassin / Shadow | Bypass reaches cap three and feeds Mastery once; expiry restores stats. Additional 21/24 split combines Critical Poison with Umbral and observes >30 stacks, forced ticks, Consume, Master and Virulent charge expenditure. | Poison contract, Shadow boundaries, status/lifecycle and source tests. |

[Focused suite](../project/tests/p6_mixed_interactions_test.gd) adds those two
21/24 allocations in both roles, twenty seeds each, plus exact defense/Bypass
checks using resolved mixed-build stats. Its reports preserve complete seed-one
traces. No three-tree or over-budget fixture is used to certify a legal build.

## Corrections found during validation

The inherited scheduler suite still asserted pre-D018 Footwork durations.
Rank five with three stacks now reduces the 2000 ms post-IAS duration to 800 ms,
so the clipped window is 799 ms. A one-stack Plunge after stun now completes at
4700 ms, not 4900 ms. Updated the four assertions while preserving exact-expiry,
resource-retention and immutable-plan checks. No gameplay value changed.

Initial new-suite failures were test-authoring errors: missing Charisma
prerequisite for Loaded Dice, omitted gear/derived multiplier terms, untyped
GDScript expressions, optional Bladedancer lifecycle access on non-Bladedancer
builds, and trace JSON shape. Diagnostic reports are retained separately and
are not acceptance evidence. The isolated runner now accepts an explicit
per-suite timeout; its ordinary 180-second default is unchanged.

## Reproduction and closeout

```powershell
python tools/p6/run_foundation_tests.py --timeout 900 --report-name p6_m5_t9_matrix_final p6_mixed_gear_integration_test
python tools/p6/run_foundation_tests.py --report-name p6_m5_t9_interactions_final p6_mixed_interactions_test
python tools/p6/run_foundation_tests.py --report-name p6_m5_t9_scheduler p6_macro_scheduler_test
```

The selected existing contract suites and exact commands are recorded in
`project/reports/p6_m5_t9_contracts/summary.json`; its scheduler failure is
superseded only by the passing dedicated scheduler rerun. Each batch has a
protected-save/Enigma fingerprint report. The [consolidated acceptance report](../project/reports/p6_m5_t9_final/summary.json) references the exact accepted run for each suite; failed logs remain diagnostic history.

## Final acceptance

- **22 runtime suites pass**, including current full-tree, Poison/status/gold,
  trigger/ordering, stat-source, core/mixed journey and Lab checks.
- **Nine static checks pass**: four release/predecessor checks, compatibility
  resources, core/mixed fixture checks, display catalog and coverage ledger.
- **576 matrix scenarios / 2,880 seeded cases** pass across 36 allocations and
  twelve ordered pairings. Every seeded case also passes identical replay and
  trace-off outcome/RNG comparison. [Exact matrix](../project/reports/p6_m5_t9_matrix_final/matrix.json).
- **Four additional allocations / 80 seeded cases** pass with exact status
  transaction reconciliation and focused cap/expiry assertions.
  [Focused evidence](../project/reports/p6_m5_t9_interactions_final/focused.json).
- [Protected-file fingerprints](../project/reports/p6_m5_t9_final/isolation.json)
  are unchanged. D023 release and compatibility hashes pass without rewriting
  their manifests; no gameplay, source draft, real save or Enigma file changed.

Run `python tools/p6/check_m5_t9.py` to recheck report completeness, all twelve
role combinations, legal point totals, seed ranges, current static checks and
accepted isolation evidence. It records exact source hashes and commands.
Existing certificate-store/resource-exit warnings remain assigned to M7/M9;
accepted runs have no script errors. No fresh rendered acceptance is claimed.

The ledger originally rejected Shadow's approved D019–D023 draft revision.
Comparison with the original hash-matching source found only eight changed
leaves: Coated/Dusk/Touch/Presence descriptions and Death Touch/Death Blade
scalar entries. The checker now accepts only that exact old/new hash pair,
requires the D023 release manifest to agree, validates every identity pointer,
and records both historical and current source hashes. The original identity
manifest and draft are unchanged. Arbitrary future source drift still fails.

## Exclusions and downstream owners

- T10: combined four-tree player flows, full rendered acceptance, editing and
  persistence journeys. T9 reruns existing core/mixed journeys headlessly;
  it does not claim fresh visual or user-playtest acceptance.
- T11: milestone-wide regression and final coverage reconciliation.
- M6: DPS/win-rate targets, resource adequacy, gold ramp, normal retrigger tuning,
  enemy/progression balance, Watchmen comparison and Adventure enablement.
- M7: final art, crowded effect presentation, accessibility polish and audio teardown.
- M9: packaging, environment and inherited engine shutdown warnings.
- Exhaustive equipment Cartesian products and three-tree builds are outside this
  agreed representative matrix. Real saves and sibling Enigma remain protected.

T9 is Complete: the agreed matrix, targeted assertions, selected regressions and static checks pass. T10 full-content player-flow acceptance is next; T11 remains separate.
