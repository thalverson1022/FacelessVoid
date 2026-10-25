# P6M3-T10 — Gold-based combat and mixed-tree extension

Status: **Complete for reviewed shared-mechanics and mixed-build scope.**
Decision: **P6M3-D025**, 2026-09-24.

## Reviewed contracts

- Steal retains the existing 106% weapon scaling, 1300 ms base / 650 ms minimum,
  and critical hits steal three raw gold. No cooldown.
- Mug: Attack, 100% weapon scaling, 1500/700 ms, no cooldown. Add current-fight
  credited stolen gold to base physical damage, capped at 100 for this bonus.
  Apply ordinary damage buckets and crit afterward. It neither spends gold nor
  turns pre-existing stash into stolen gold.
- Pick Pocket: Debuff, zero weapon damage, 1300/800 ms, no cooldown, twenty raw
  gold per execution. Existing Debuff rules prevent dodge and preserve attack
  cleanse/interrupt counters. It does not become an attack for repeat eligibility.
- Big Score: Attack, 90% weapon scaling, 1800/700 ms, no cooldown. Double the
  full current crit multiplier on critical hits only (3x becomes 6x). Noncritical
  hits remain ordinary 90% weapon damage. Normal critical mitigation applies.
- Dance: Self Buff, 500 ms cast/minimum, unaffected by IAS; existing five-second
  duration and twenty-second shared cooldown. Existing macro-only repeat and
  Readiness rules remain. Unlocking the descriptor now binds the lifecycle.
- Silvered Edge: each credited gold stolen this fight grants one percentage
  point of crit chance, capped at 25/50/75 percentage points by rank. Cap this
  talent's contribution, then apply the existing total chance clamp.
- Gilded Blade: one percentage point of crit damage per current stash gold,
  counting at most 500 gold. Preserve other crit contributions. Spending below
  the cap reduces its next resolved contribution. Theft can move it toward the
  cap during a fight, including for immediate child casts and critical Poison.
- Cloak & Dagger uses the existing crit-damage bucket: +50/+100 percentage points.
  Keen Eye provides +2% physical and elemental damage per rank. Opportunity
  remains 10/20/30% Quick Cut-to-Rending Slash with the reviewed T6 origin rules.
- Thief intrinsic: +10% Increased Gold plus +2 percentage points per primary
  Thief point. Secondary receives base only, even with zero invested points.
  Base and primary scaling add: five primary points yield +20%, not +21%.

## Gold ownership and diagnostics

Theft credits `max(0, floor(raw * resolved_gold_multiplier))`, preserving the
existing baseline. Gear's gold bucket and talent multipliers remain in their
existing composition. Each theft effect floors separately. Bribery remains one
application per successful credited theft event under T7.

Resolution reads the starting stash without mutating it. Simulated stash and
credited fight-stolen counters advance separately. Combat playback credits the
result to Adventure/Practice; it does not reapply Increased Gold. Clearing the
fight-stolen counter never removes credited stash gold. Rewards and Overkill Gold
remain outside fight theft; shop spending does not alter the stolen counter.
Adventure preserves actual credited stash at fight end; Practice retry restores
its configured starting stash and clears its fight counter.

`combat_gold.gd` owns shared crit-source and transaction calculations. Direct
hits and critical Poison use the same current-gold rules. Each transaction emits
raw/credited amounts, multiplier, source, stash/stolen before and after, and capped
crit contributions. Cast snapshots expose Mug's counted damage bonus.

Gilded/Silvered are explicit opt-in talent/rank descriptors. Legacy uncapped
scalar fields remain separate for compatibility content and gear; they do not
silently acquire the new talent caps. Inherited Bandit Blade's gold-to-base
contribution remains a build-resolution snapshot and rebuilds after spending;
T10 does not redesign its mid-fight behavior. Its source remains observable.

## Exact mixed integration fixture

`project/tests/fixtures/p6/mixed_build.gd` injects revision `p6.test.mixed.1`:

- Bladedancer 15: Whetstone 4, Rending Slash 1, Fancy Footwork 5,
  Opportunity 3, Cloak & Dagger 2.
- Thief 5: Keen Eye 5.
- Rotation: Dance, Quick Cut, Quick Cut, Parry Strike, Leaping Plunge,
  Rending Slash, Steal, Mug.
- All ten unlocked skills resolve; Footwork, Readiness and Dance bind through
  build resolution without manually toggling combat flags.
- Primary Bladedancer gives 8% retrigger and +10% gold. Reversed Practice roles
  retain the same allocations, giving 5% retrigger and +20% gold.
- Zero Thief investment retains +10% gold but grants neither Steal nor Mug.

`tools/p6/check_mixed_build.py` checks exact allocations/rotation against both T5
fixtures, stable IDs, source hashes and the compatibility release gate.
`check_bladedancer_core.py` still passes unchanged. Pick Pocket/Big Score and
mature gold talents have separate shared-mechanic tests; they are not silently
added to this twenty-point fixture.

## Validation

`p6_gold_contract_test.gd` covers:

- Gold 0/100/499/500/501/10000, cap crossings, no-theft Mug, partial/floored credit,
  multiple theft effects, actual stolen versus stash gold, and source totals.
- All Silvered ranks at below/exact/above-cap boundaries; independent legacy,
  Gilded, Cloak and gear contributions; Mug's 100-gold cap; Big Score crit/noncrit.
- Parent theft visible to immediate recursive Steal children; existing depth
  limits remain. Pick Pocket category, defense, interruption and reward rules.
- Adventure playback credit/counter clearing/reward separation/spending and
  actual Practice configuration, both roles, playback and repeatable retries.
- Seventeen Balance Lab scenarios, twenty seeds each, run twice: both roles at
  all six gold boundaries plus crit-negation, full dodge, full block, duplicate
  Dance and zero-secondary cases. These are correctness checks, not DPS targets.
- Exact trace/RNG parity, fight cleanup and default-registry rejection of the
  unreleased fixture. A complete seed-seven trace accompanies the scenario report.

All **42 regression scripts pass**, including T9 and prior shared mechanics,
ranked builds, persistence, economy/Overkill Gold, legacy Thief, playback and
Practice/combat-screen consumers. Isolation confirms protected FacelessVoid and
Enigma saves plus Enigma project/export files are unchanged.

- [42-script results](../project/reports/p6_m3_t10_regression/summary.json)
- [17 repeated twenty-seed scenarios and complete trace](../project/reports/p6_m3_t10_regression/mixed_handoff.json)
- [Protected-file isolation](../project/reports/p6_m3_t10_regression/isolation.json)

Focused reproduction:

```powershell
python tools/p6/check_mixed_build.py
python tools/p6/check_bladedancer_core.py
python tools/p6/run_foundation_tests.py --report-name p6_m3_t10_verify p6_gold_contract_test p6_poison_contract_test thief_subclass_test p5m11_economy_stats_test p5m11_overkill_gold_test
```

The regression summary records exact per-script commands. T10 is complete;
T11 is next.

## Handoff limits

`p6.compat.1` remains the playable registry. M4 owns playable integration and
rendered UI acceptance, including the new capped-gold and Mug/Big Score displays.
M5 owns full tree content binding, M6 balance/economy tuning. No progression,
reward, shop-price, gear-pool, save migration or actual player-save change is
part of T10. T11 integrated regression and milestone closeout is the next M3 task.

## Big Score correction

The user corrected Big Score from 110% to **90% weapon damage** after T10
closeout. Timing and doubled critical multiplier are unchanged. The focused
[gold/mixed contract suite](../project/reports/p6_m3_t10_big_score_90/summary.json)
passes, including 90 noncritical damage and 540 critical damage for a 100-damage
weapon with a normal 3x crit multiplier. Protected files remain unchanged.
