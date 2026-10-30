# M9 T9 — Combined mechanics and reset verification

2026-10-27. **T9 Complete under P6M9-D030.** The [M9 tracker](P6M9_Gear_Slot_Expansion_And_Progression_Pacing_Tracker.md) owns status and decisions. T9 checks correctness of the integrated seven-slot system; progression tuning remains T10.

## Result and concrete correction

[Consolidated evidence](../project/reports/m9_t9_final/summary.json) contains **15 passing suites**, retaining each actual contributing command and final test-source hash. These are contributing runs, not a claimed single execution. The retained foundation, T8 presentation and T3 persistence rows predate the one-line marker correction; final targeted persistence/reset/entry runs cover the corrected guard. New combined suites add 424 mechanics, 1,731 persistence and 602 ownership/economy checks. Current retained runs include 44,816 pool checks, 2,026 acquisition checks, 1,587 Legendary mechanics checks and 385 stat-foundation checks.

One production defect was reproduced and fixed: `SevenSlotSaveBoundary.ensure_ready()` compared an untyped reset-marker value directly with integer 1. A marker such as `{"seven_slot_epoch":"1"}` caused a String/int script error instead of reporting an incompatible marker. The guard now requires `TYPE_INT` before comparing the epoch. Invalid markers preserve the files and in-memory state, emit no build-change signal and return a readable error. The policy remains epoch1, Adventure v5 and Practice v4.

- [Pre-fix reproduction](../project/reports/m9_t9_persistence_final/m9_t9_persistence_test/console.txt).
- [Final frozen-source combined regression](../project/reports/m9_t9_persistence_verified/summary.json): integer2, string, float, bool, null, array, object, missing field and malformed JSON, plus valid epoch1. [Witness](../project/reports/m9_t9_persistence_verified/m9_t9_persistence_test/m9_t9_persistence_witness.json).
- [Post-fix reset and normal-entry checks](../project/reports/m9_t9_persistence_marker_fixed/summary.json): select the passing T5 reset/entry rows. The final combined source is the frozen-source run above.

The [source audit](../project/reports/m9_t9_final/verification.json) compares 1,042 runtime/resource/art files to the T9 starting snapshot. **Only `project/scripts/systems/seven_slot_save_boundary.gd` changed.** No combat, generation, economy, item/artwork, UI, save-version or progression tuning changed during T9.

## Coverage and evidence

| Area | Final coverage |
| --- | --- |
| Legal seven-slot combinations | [New mechanics suite](../project/tests/m9_t9_combined_mechanics_test.gd) and [endpoint fixture](../project/tests/fixtures/m9_t9_mechanics_fixture.gd) validate complete rarity shapes, pool membership, uniqueness, domain and item round trips. Ordinary fixtures use scale1/depth12 legal rounded endpoints. |
| Conversions and binary effects | Both conversions preserve physical-then-magical mitigation independent of input order; original-type resistance-ignore physical penalty remains at its established stage. Repeated All Stats, doubling, denial and immunity do not compound. Physical base stays unamplified while eligible elemental base scales. |
| Timing and critical procs | Twenty CDR affixes plus All Stats give factor 0.0000109296780818862 and a 1ms result for a 10-second cooldown. Pants `.54` plus Gloves `.38` duration yields 1.104 with one All Stats factor. Retained T3 timing/crit suites cover Pact order, expiration/overflow, Penetration then Potency, connected zero damage, caps, zero-chance RNG and finalize/cleanse/descendant order. |
| New and existing Legendaries | All four Pants/Gloves pairings run 16 seeds with Decrepit/Coil and a complete seven-slot collection; preservation success/failure and independent candidates occur. The observed trace maximum is 44 root candidates for those fixtures. Current T8 mechanics adds the directed Scales/Consume/fuel, Lightning source-snapshot/Coil-gating, Arctic countdown/endpoint, Golden activation/one-payout/resume and no-effect RNG baselines. [Mechanics reports](../project/reports/m9_t9_mechanics/summary.json), [new detailed witnesses](../project/reports/m9_t9_mechanics/m9_t9_combined_mechanics_test/m9_t9_mechanics.json). |
| Proc guards and consumers | A legal gear endpoint stress collection with diagnostic skills and an authored Critical Poison rank carrier reaches 928 candidates for seed1 and exhausts the shared 1,024 budget for seed7. The invalid result cannot enter DPS/history or grant Overkill, and preparation resumes without consuming an attempt. This verifies fail-closed handling, not earned-run probability or headroom. |
| Ownership and acquisition | All 20 fixed identities pass actual buy/equip/full-inventory swap/sale/unequip/destroy/reacquisition and duplicate/unlock gate checks. Seven simultaneous Legendary slots work. Authored reward atomicity and distinct identity filtering remain. [602-check combined suite](../project/reports/m9_t9_ownership_final/summary.json) reuses narrowly updated transaction helpers from `t8_acquisition_test`. The whole historical T8 acquisition script is not counted as passing. |
| Pools and source selection | [T6 pool](../project/reports/m9_t9_pool_verified/summary.json), [T6 acquisition](../project/reports/m9_t9_acquisition_verified/summary.json), [fixed-catalog boundary](../project/reports/m9_t9_legendary_boundary_verified/summary.json), [old-five stat foundation](../project/reports/m9_t9_stat_foundation_verified/summary.json). All seven ordinary slots/six rarities, 148 positive/47 drawback rows, Basic weight 1, retained old-five ranges/order/Rare/Special weights, category overrides, uniqueness/Chaos duplicates, rounding/depth, fixed-slot collision retries and authored subsets are covered. |
| Carried economy | A full seven-slot endpoint loadout combines repeated All Stats, equipped Pants activation, three carried occurrences and legal positive/negative Chaos. Independent raw summation checks all three imported IDs, floors before one factor, no carried combat/timer import, exact occurrence transfer/sale, rebuild/load, inactive carried activator and frozen pending/shop items. The retained stat-foundation suite covers signed legacy discount-domain inputs separately from current legal drawback pools. [Ownership/economy witnesses](../project/reports/m9_t9_ownership_final/m9_t9_ownership_economy_test/ownership_evidence.json). |
| Current saves | New persistence suite covers 20 canonical Legendaries in applicable Adventure/Practice locations, all seven slots across six procedural rarities, exact build/run/setup/affix/provenance/Magic Find upgrade fields and resolved values, detached decoded ordinary occurrences, and seven independent custom Practice shells. Multi-location repeated Legendary identities are codec stress fixtures, not legal ownership examples; actual ownership legality is established by the transaction suite. |
| Old-save reset and modes | Actual normal Title and Practice-first entry retire all four old envelopes and temps, commit epoch1, start Crude-Dagger-only Adventures and then preserve current full-seven content across repeated entry. Strict malformed/future inputs, failed deletion/marker write and namespace rejection retain T5 directed coverage. Full-seven Test APIs preserve every old file/temp byte and do not write the marker. Test entry/restart/autosave retains T5 coverage. |

The T4 representative row that said “Poison Lightning without Coil” was corrected to the adopted D021 exclusion. The coverage above combines actual legal gear combinations with retained directed interaction tests; it does not claim every named T4 full-loadout row was separately executed.

## Isolation, fixture corrections and reproduction

[Whole-profile comparison](../project/reports/m9_t9_final/isolation.json) records **164 protected files unchanged**, including additions/deletions across the existing FacelessVoid/Enigma profile roots and sibling project identity files. No live reset, deletion, restore or migration occurred.

Simulations and persistence checks used explicit, distinct Adventure/Practice/core/legacy/marker paths before persistence access. Copied-project runs additionally redirected APPDATA/LOCALAPPDATA per suite. The mechanics group used the existing wrapper with all five paths and redirected application-data directories. An intermediate mechanics parser check reached inference errors before executing the fixture; the full real-profile comparison also spans that invocation.

`run_retrigger_checks.py` previously assigned `save.json` to Adventure while the legacy boundary default derived that same filename. The namespace guard correctly rejected this alias. The runner now configures five distinct paths. Initial alias failures are excluded from final acceptance; the stalled isolated test process was stopped and affected checks were rerun with the corrected runner.

Narrow test maintenance updated obsolete16-item/five-slot assertions in T5 foundation, T6 acquisition, the fixed-catalog boundary and reused transaction helpers. Production rules were not changed to satisfy stale fixtures. Initial parser/fixture iterations and the pre-fix malformed-marker failure remain in their task report directories; the consolidated summary selects only passing runs whose hashes match the current test sources.

Reproduce the new suites with the copied-project runner, using a fresh report name:

```text
python tools/p6/run_retrigger_checks.py --report-name m9_t9_recheck --timeout 120 --tests m9_t9_combined_mechanics_test m9_t9_persistence_test m9_t9_ownership_economy_test
```

The retained-suite commands are recorded in the consolidated summary. `python tools/p6/check_m9_t9_evidence.py` reconciles contributing rows, current test hashes, runtime changes and the protected-file baseline in `work/m9_t9/before.json`; it performs no gameplay/reset operations.

[Independent read-only closeout review](../project/reports/m9_t9_final/review.json) verified the selected source hashes, final runtime/content hashes, marker fix, protected-file comparison and scoped coverage without repeating the engine runs. No blocking finding remains.

## Retained risks and downstream work

- **Discount/resale profitability:** the legal endpoint witness buys Golden Greeves for 1g and sells for 40g, net +39g. T9 confirms existing arithmetic and ownership behavior. T10 owns focused economic significance and any proposed tuning; prices and caps are unchanged.
- **Proc-budget headroom:** the existing guard correctly invalidates exhausted diagnostic stress simulations. The frequency and usability impact for earned builds remain unmeasured; T10/M10 retain that review. The 44-candidate combination sample is not a global safe maximum.
- **Validation scope:** certificate-store and shutdown ObjectDB/resource diagnostics remain in logs. No crash/power-loss durability, export, broad engine regression, full-run balance or user pacing acceptance is claimed. Earlier unrelated broad UI/death-frame fixture limitations remain assigned to their existing owners; T9 does not mark them resolved.
- **Next:** T10 focused progression review using the unchanged gold/reward/rarity baseline. D099's deferred expanded balance matrix remains deferred.
