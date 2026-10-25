# P6M3-T8 Core Bladedancer Validation and M4 Handoff

Date: 2026-09-24. Status: **Complete — core combat integration and deterministic validation.**

Owner: [M3 tracker](P6M3_Shared_Combat_Mechanics_Tracker.md).
Authority: [T5 integration plan](P6M2_T5_Integration_And_Dependency_Plan.md),
[T1 approved core specification](P6M3_T1_Bladedancer_First_Slice_Specification.md),
and completed T2–T7 contracts, including T4 D023's stack-grant ordering.
No new gameplay values or balance targets were selected during T8.

## Result and exact fixture

`m4_bladedancer_core` now resolves from a real ranked allocation into executable
skills and combat inputs, without manually enabling Footwork or Readiness.

- Bladedancer primary, no secondary, ten earned/spent points, zero unspent.
- Purchase Whetstone to rank four, Rending Slash rank one, then Fancy Footwork
  to rank five. The five-point gate is enforced.
- Intrinsic: 5% base retrigger plus 0.2 percentage points per primary tree point
  gives 7%. Whetstone adds four base physical damage; gear adds normally.
- Rotation: Quick Cut / Quick Cut / Parry Strike / Leaping Plunge / Rending Slash.
- All seven unlocks are verified: Hold, Stab, Heavy Slash, Quick Cut, Leaping
  Plunge, Parry Strike and Rending Slash. The nine-point slot stays empty.
- No Dance, Riposte, Precision, Bypass or other mature talent is part of this build.

The explicitly injected registry is `p6.test.bladedancer_core.1`.
Its resources and helper are in `project/tests/fixtures/p6/bladedancer_core/`.
`manifest.json` records source hashes, authority, exclusions and `release_ready: false`.
The helper's allocation and rotation match the original T5 fixture exactly.
The slice includes the three reviewed talents, not a complete Bladedancer tree;
the twelve-point Dance slot is excluded rather than mislabeled as an empty slot.

## Dependency audit and integration changes

| Dependency | T8 result |
| --- | --- |
| Ranked allocation and scalar stats | Existing model reused; purchases, gates, refunds, primary intrinsic and Whetstone resolve correctly. |
| Fancy Footwork binding | Added explicit `footwork_rank` descriptors to TalentRank/Talent; ranked resolution copies the selected rank and BuildResolver binds it before stat derivation. Invalid ranks and duplicate active sources fail explicitly. |
| Readiness binding | Added `Skill.enables_readiness`; the reviewed Parry resource declares it. Ranked resolution enables Readiness only when that skill is unlocked, with source provenance. Refunding below six points disables it. |
| Quick Cut and Rending Slash | Reuse inherited resources and stable IDs, including `skill.rending_thrust` for Rending Slash. Verified 66%/78% weapon scaling and 850/1400 ms base, 500/650 ms minimum timing. |
| Plunge and Parry resources | Added test-only descriptors with T1's 190%/120% resolver scaling and 2500/500 ms base, 500/300 ms minimum timings. Fallback physical amounts are not weapon percentages. |
| Temporary effects, triggers and statuses | Reuse T2–T7 implementations. No separate combat resolver or fixture-only combat path. |
| Balance Lab and content gates | Existing ranked adapter accepts the explicit core registry; default packaged registry returns `not_ready` with zero simulated seeds. |
| Fixture isolation | Explicitly copy external rank resources inside typed arrays; invalid-input tests cannot mutate another fixture or cached source resources. |

Both Adventure BuildState and TrainingRoomState already call the same ranked
resolver. T8 establishes the data/combat handoff, not their rendered or playable
acceptance. The new descriptor fields default to disabled on compatibility content.

## Deterministic evidence

All **35 regression scripts pass** in
`project/reports/p6_m3_t8_regression/summary.json`. The final expanded gear/core
check passes in `project/reports/p6_m3_t8_final_gear/summary.json`.
Both isolation reports confirm protected FacelessVoid/Enigma saves and original
Enigma project/export files are unchanged.

`p6_bladedancer_core_test.gd` records 129 assertions before the final report-write
check. It exercises seven thirty-second, twenty-seed scenarios and repeats each
for identical samples/aggregates. Their descriptive mean DPS values are below;
these are correctness probes with controlled targets, not difficulty targets.

| Scenario | Mean DPS | Purpose |
| --- | ---: | --- |
| Neutral | 22.715 | Core rotation and ordinary 7% random repeats |
| Armor 200 | 10.412 | Physical mitigation and Shred sequencing |
| Full block | 0 | Zero damage remains a connected hit for effects |
| Dodge 100% | 0 | Misses cannot grant Footwork/Readiness |
| Interrupt | 20.913 | Repeated Quick Cut and interruption rules |
| Slow 50% | 13.710 | Ordinary slow before Footwork's reduction |
| Cleanse every two attacks | 19.022 | Status removal within the core rotation |

Additional checks cover every unlocked skill individually; all five Footwork
ranks through allocation/refund; invalid rank contracts; ready and unready Parry
from natural retriggers; exact-expiry and one-millisecond-late Plunge starts;
clipped casts; damage-before-Shred; fresh-fight cleanup; trace/RNG parity; codec
roundtrip; gear IAS/retrigger/extra stacks, doubling and filtered Stab procs.
Gear stack grants add bonuses, double, then clip at five. Plunge retains its floor.

Regression also covers ranked persistence and foundation integration, Practice
builds, existing tooltips/panels, T3 stat sources, T4–T7 effects, scheduler,
ordering, inherited damage/status/gear interactions, replay, recaps, playback
and invalid-result consumers. Initial harness parse and fixture-copy failures
were corrected before the passing evidence above; no assertion was suppressed.

### Reproduce

```powershell
python tools/p6/check_bladedancer_core.py
python tools/p6/run_foundation_tests.py --report-name p6_m3_t8_verify p6_bladedancer_core_test
```

The checker verifies source hashes, the exact T5 allocation/rotation, stable
identity-manifest IDs, fourteen resource references and the unchanged release
gate. For the broad run, use the test basenames listed in the regression summary
with `run_foundation_tests.py`; that summary records every full command.
The test writes `core_handoff.json` beside its isolated wrapper. The final report
is `project/reports/p6_m3_t8_final_gear/core_handoff.json` and contains the encoded
build, resolved values, all scenario results, resource snapshots, event examples
and the complete 219-record seed-seven core trace.

## Event example for M4

At seed seven with the crude dagger and neutral target:

| Time | Event | Expected presentation |
| --- | --- | --- |
| 0–850 ms | First Quick Cut | Grants Footwork after its subtree |
| 850–1700 ms | Second Quick Cut, then a zero-time repeat | Three Footwork total; repeat grants Readiness |
| 1700–2200 ms | Parry Strike | Consumes one Readiness at start |
| 2200–3950 ms | Leaping Plunge | Consumes three Footwork; 2500 × 0.7 = 1750 ms |
| 3950 ms | Plunge repeat | No inherited Footwork consumption or parent windup |
| 3950–5350 ms | Rending Slash | Damage resolves before its two base Shred stacks |

Use `cast_start`/`schedule_decision` for fixed cast timing and resource eligibility;
`effect_lifecycle` for grants, counts, deadlines, consumption and cleanup;
`cast_resolved` and `status_transaction` for damage and status outcomes. Root,
parent and origin fields distinguish macro casts, random repeats and gear procs.
An unready Parry must display a spent-time/no-effect attempt, not a connected hit.

## M4 readiness and remaining work

The reviewed core's combat dependencies are ready. M4 should use this fixture
and evidence to wire Adventure/Practice selection, rank editing, macro controls,
playback and effect presentation. It must verify actual UI clarity, dense layouts,
tooltips and player comprehension; existing inherited UI regression is not a
visual review of the redesigned tree.

Content promotion still requires an explicitly scoped complete release registry
with reviewed references and persistence boundaries. `ranked_content_ready` in
this injected test slice does not make it the full tree or authorize publishing.
`p6.compat.1` remains the packaged playable registry. Placeholder presentation for
new skills needs M4/M7 review; final icons remain M7. Full tree content is M5,
numerical balance is M6, and the mixed Bladedancer/Thief extension is M3-T10.

T8 is complete. Next M3 task: **T9 — Poison timing and consumption**.
