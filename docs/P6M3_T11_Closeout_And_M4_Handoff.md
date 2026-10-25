# P6M3-T11 — Shared combat closeout and M4 handoff

Date: 2026-09-24. Status: **Complete — M3 shared-mechanics scope**.

All eleven M3 tasks are complete for their documented scopes. The reviewed
shared mechanics and both exact M4 candidates have reproducible combat evidence.
**M4 Playable Integration and UI Validation is next.** This does not release the
four redesigned trees: `p6.compat.1` remains the packaged playable registry.

## Final verification

- **65 regression scripts pass** across M2 foundations, shared combat, inherited
  gear/enemy behavior, economy, saves, Practice Room and combat-screen consumers.
- **One new integrated script passes**: six combined-mechanic scenarios × twenty
  seeds, each run with tracing, replayed, and run without tracing (360 runs).
- The regression also reruns T8's seven and T10's seventeen twenty-seed scenarios
  with their exact ranked fixtures. Big Score is **90%**, including the corrected
  noncritical/critical expectations; 110% is superseded.
- Identity, allocation fixtures, packaged content registry, core fixture and
  mixed fixture validation all pass: four trees, 44 talents, 140 rank slots,
  twenty skill identities, twenty slots, six profiles and 121 planned fixtures.
- Both final isolation reports show unchanged protected FacelessVoid/Enigma saves
  and Enigma project/export files. No commit, release, export or content promotion.

Evidence:

- [65-script results and exact commands](../project/reports/p6_m3_t11_regression/summary.json)
- [Combined-mechanics result](../project/reports/p6_m3_t11_integrated_final/summary.json)
- [Integrated samples, recap and complete trace](../project/reports/p6_m3_t11_integrated_final/integrated_handoff.json)
- [Final core evidence](../project/reports/p6_m3_t11_regression/core_handoff.json)
- [Final mixed evidence](../project/reports/p6_m3_t11_regression/mixed_handoff.json)
- [Regression isolation](../project/reports/p6_m3_t11_regression/isolation.json)
- [Integrated isolation](../project/reports/p6_m3_t11_integrated_final/isolation.json)
- [Repository checkpoint](P6M3_T11_Repository_Checkpoint.json)

The initial integrated harness assumed that the optional Bladedancer lifecycle
always existed. The corrected test allows its intentional absence in a Poison/
Thief harness. That test-only error required no production change. The final
reports above are authoritative; earlier attempt reports remain historical.
Headless logs can include the host certificate-store warning and existing
resource-exit warnings; the runner checks return codes, script errors, parse/
compile errors, assertions and protected-file fingerprints.

## C1–C7 requirement reconciliation

The scope boundary follows the existing M2-T5 package table: M3 owns reusable
mechanics and the two integration candidates; M5 owns full per-content binding.
No essential shared mechanic has been reclassified as optional for closeout.

| Package | Implemented contract and owner evidence | Final checks | Remaining owner |
| --- | --- | --- | --- |
| C1 Stat derivation | T3: Double Dip, Sharpened Edge, Fast Hands, Fill Your Pockets, Shadow Mastery; canonical buckets, source provenance, temporary rebuilds, live impact/tick versus cast-start snapshots. T10 adds capped gold consumers. | Stat derivation/sources, all-stat and damage-bucket regressions; integrated Fast Hands + Touch + Poison. | M5 complete rank resources; M4 display; M6 balance. |
| C2 Timed effects | T4/T6/T7: Footwork/Riposte, Readiness, Precision, Dance, Bypass, Touch, Virulent, Master, Beguiling, and Death Pact's defense debuffs; caps, independent instances, charges, expiry and cleanup. | Lifecycle/combat/T4/repeat/status suites; integrated cross-effect teardown and combat-window-clipped uptime. | M5 bindings; M4/M7 timers, charge displays and presentation. |
| C3 Scheduling | T5: macro playback, resource eligibility, cast-start snapshots, shared cooldowns, fixed 100 ms unavailable-cooldown attempts, interruption and finite progress. T8/T10 bind all skills unlocked by their exact candidates. | Macro/cooldown suites; mixed duplicate Dance; long/clipped cast Poison cadence; zero-resource tests. | M5 remaining individual skill descriptors; M4 macro/playback UI. |
| C4 Poison | T9/D024: additive IAS scaling, phase preservation, fueled natural/forced depletion, separate rank multipliers, partial/zero fuel, Virulent charges and one live critical roll per tick. | All legal Echoing/Resonance rank pairs at 0/1/2/3 stacks, conversion/crit/expiry checks and combined scenarios. | M5 Assassin binding; M4 tick/crit/cadence views. |
| C5 Triggers/crit | T2/T6: depth-first order, 1024 root candidate budget, depth-16 suppression, Opportunity, Precision, Dance, Side Step, Death Blade and inherited direct-hit crit hooks. T9/T10 integrate Poison/gold crit. | Ordering, repeat/origin, failure-consumer, RNG compatibility and integrated exact trace equality. | M5 remaining content wiring; M6 legal-build retrigger watch. |
| C6 Status/mitigation | T7: explicit Decay, removal/restoration, Distilled conversion, independent Decay-to-Shred, selective cleanse immunity, Penetration/Potency, negative-defense base bonuses, conversion order, Master resistance ignore, Bribery. | Accounting/interactions/completion suites, gear conversion/denial regressions, zero-resistance/cleanse/physical-conversion combined scenarios. | M5 full Shadow/static rank descriptors; M4 status views. |
| C7 Economy combat | T10/D025: current stash versus fight theft, raw/floored credit, Gilded/Silvered caps, Mug, Steal, Pick Pocket, Big Score, Thief primary scaling; reward/spending/reset separation. | Gold boundary suite, both roles, no theft, Practice retry/playback, inherited economy and Overkill Gold, integrated gold/status reconciliation. | M5 full Thief binding; M6 economy tuning; M4 capped-source display. |

## Audit questions Q01–Q20

| Questions | Disposition |
| --- | --- |
| Q01–Q03 | Settled M2 progression, roles and respec. Ranked edits, gates, point rewards, persistence and Practice isolation pass again. |
| Q04 | Settled shared units/buckets and live/snapshot behavior in T3; rank authoring remains M5. |
| Q05–Q06 | Settled by D024/T9. Both natural and forced ticks deplete actual fuel; neither is keyword Consume. |
| Q07 | Reviewed shared lifecycles complete. Death Pact gives 4/5/6-second Penetration/Potency by rank, with actual Consume-only conversion. |
| Q08 | Settled macro, eligibility and cooldown behavior under T5/D009. |
| Q09 | Shared category/scheduling rules complete; core/mixed descriptors tested. Full per-skill authoring remains the original M5 owner. |
| Q10–Q11 | T2/T6 origins/guarantees/budgets plus T9 critical Poison and T10 live gold crit implemented. Precision/Dance overlap still gives one guarantee; no invented 99% cap. |
| Q12–Q14 | T7 quantities, removal, conversion, cleanse and mitigation complete; T4/D023 stack grants and T9 depletion incorporated. |
| Q15 | T10 gold contracts settled; D025 plus user's subsequent Big Score 90% correction. Economy balancing remains M6. |
| Q16 | M2 identities and persistence remain authoritative. Heavy Strike aliases existing Heavy Slash per T6; Death Pact unit is settled. M5 completes content conversion. |
| Q17 | Bladedancer and Thief nine-point slots remain intentionally empty. Only an explicit M5 decision adds content. |
| Q18 | Qualitative roles/progression preserved. Numerical difficulty and legal-build retrigger limits/watchmen comparisons belong to M6. |
| Q19 | M3 event data exists and reconciles. Rendered layout, accessibility, icons and effect clarity still require M4/M7 acceptance. |
| Q20 | Exact core/mixed allocations, roles, scenario evidence and persistence validated. End-to-end redesigned playable acceptance remains M4. |

M2 F1–F3 regressions are included: allocation and progression, class/tree/rank
resolution, unlocks and rotation filtering, migration/full-reset policy,
Adventure/Practice persistence, generated-route rewards and isolation.

## Combined verification scope

The new `p6_m3_integrated_test.gd` intentionally composes shared mechanics directly;
it is **not** a legal full-tree allocation or a balance target. Its ten-slot
rotation combines Poison supply, Virulent/Master, Poison Strike, Touch, Pick
Pocket, Decay, Distilled consumption, Beguiling and Big Score. It enables the
reviewed Fast Hands, stacking, gold and defense interactions.

Six scenarios cover neutral defenses, zero resistance, full mitigation, physical
conversion with crit negation, cleansing, and slow/suppress/interruption. Every
trace must preserve chronological ordering; Poison/Decay quantities, theft/stash
changes, cast/tick damage and recap totals must reconcile. Every active lifecycle
is empty after cleanup. Inputs remain unchanged. A separate clipped-cast probe
proves a five-second buff granted at 500 ms has only 1500 ms observed uptime when
the fight ends at 2000 ms, and the unfinished cast does not execute.

## Downstream action list

**M4 — next:** integrate the exact ten-point Bladedancer core first, then the
Bladedancer 15 / Thief 5 extension. Use the T8/T10 fixture contracts and traces.
Implement selection/rank/unlock/rotation/combat/Practice flows and visible
Footwork, Readiness, Dance, cooldown and status feedback. Verify rendered UI and
actual playable comprehension. Do not promote test-only fixtures wholesale.

**M5:** bind all four trees' full 44-talents/140-rank inventory and automatic
slots to reviewed mechanisms. Reconcile draft prose with D023–D025 and Big Score
90% before writing tooltips. Explicitly finish skill-specific authoring for
Venom Jab, Beguiling Strike and Distilled Corruption where only inherited or
mechanics-harness descriptors exist; bind Blinding Powder's approved descriptor
and all remaining passive flags/rules. The shared consume/conversion engine is
complete, but that does not certify those entire skill resources. Keep the two
empty slots empty and validate every release reference; no silent no-op ranks.

**M6:** establish quantitative targets and progression/gear cohorts, assess
Poison supply starvation, gold ramp/caps, below-100% normal retrigger behavior,
and the Watchmen comparison. Inherited Bandit Blade gold-to-base damage remains
a build-resolution snapshot; changing that behavior requires explicit review.
No new DPS threshold or economy balance was approved here.

**M7:** complete icons, visual hierarchy and crowded effect-state presentation.
M4/M7 must verify actual rendered readability; headless screen-controller tests
are not visual acceptance.

## Reproduction and repository state

The 65-script summary records every exact Godot command. Use the isolated runner
for future checks; do not run save-writing tests against normal user paths.

```powershell
python tools/p6/run_foundation_tests.py --report-name p6_m3_t11_verify p6_m3_integrated_test p6_gold_contract_test p6_poison_contract_test p6_bladedancer_core_test
node tools/p6/check_content_identity_manifest.js
node tools/p6/check_build_fixtures.js
python tools/p6/check_content_registry.py
python tools/p6/check_bladedancer_core.py
python tools/p6/check_mixed_build.py
```

The repository checkpoint records HEAD, branch, dirty status, relevant source
hashes and report references. It is a working-tree checkpoint, not a commit or
backup. Existing unrelated modifications and historical reports are preserved.
No production code changed during T11; its additions are the integrated test,
validation evidence and reconciled handoffs.
