# M5-T4 — Complete Bladedancer

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

Status: **Complete** · 2026-10-03

Implements the [approved T3 specification](P6M5_T3_Bladedancer_Design_Review.md), including user decisions D01–D03. All 13 Bladedancer talents / 35 ranks and all five tree skills are available in Practice and Test Mode. Thief remains limited to Keen Eye and its existing skill unlocks; nine Thief nodes remain previews. Numerical tuning remains M6; broader presentation polish remains M7.

## Implementation and access

Eight explicit resources in `project/data/p6/bladedancer/` complete the five previously released nodes. The promotion adapter loads only those reviewed resources. Four passive carriers connect Precision, Riposte, Side Step and selective Shred immunity through ranked resolution into the existing combat contracts. Double Dip and Sharpened Edge use the existing derivation system. No draft JSON is executed as gameplay.

Weakness adds five Shred Value per rank; Virulent adds 100 Shred Value and two application stacks, without increasing the 500-stack cap. With both maxed, each stack removes 135 armor from the current base of ten. Rending's two base stacks become four, reducing armor by 540 after its own damage. Weapon Master supplies 1.5x/2x physical damage and multiplies with Sharpened Edge's skill-local factor.

Practice retains its editable 45-point budget. Title now offers 10-point (default) or 45-point Test Mode starts. Restart preserves the selected starting budget while resetting the build. Both modes expose every Bladedancer node on the accepted icon grid. Tooltips explain passive triggers, Shred Value versus application count, guaranteed repeats, and conditional damage. Skill damage previews now include Sharpened Edge.

The release revision is `p6.playable.bladedancer.1`. Valid `p6.playable.mixed.1` and `p6.playable.bladedancer_core.1` Practice setups remain compatible; malformed ranks and unknown future revisions reject. Adventure remains disabled, with its unchanged `p6.compat.1` resource manifest. The [promotion manifest](../project/data/p6/bladedancer_release_manifest.json) records explicit source hashes; [release checker](../tools/p6/check_bladedancer_release.py) and the compatibility checker enforce the declared boundary.

## Acceptance evidence

The [full allocation/combat test](../project/tests/p6_full_bladedancer_test.gd) checks every rank including zero/max rejection, legal incremental purchases, gates, prerequisites, thresholds, fresh derivation, refunds, resets, role reversal, persistence and invalid content. An 80-case full-tree combat cohort (20 seeds across four target conditions) compares repeated traces and traced/untraced outcomes, exercises Precision, Footwork/Riposte, Parry crits, and Shred survival through cleanse. Two actual released Balance Lab builds, with reversed roles, repeat 20-seed results and aggregates. These are correctness fixtures, not balance certification.

The [UI journey](../project/tests/p6_full_bladedancer_journey_test.gd) buys all 35 points through live controls in each mode, starts actual combat, retries, restarts, reloads saved ranks and duplicate skills, and resets/prunes the rotation. It checks keyboard capstone inspection and 125% text geometry. Rendered captures cover 1280×720, 1600×900 and 1920×1080.

| T3 acceptance groups | New integration evidence plus retained boundary tests |
| --- | --- |
| B01–B05, B08–B11, B14 | Full-tree rank/stat assertions and actual combat; stat derivation/source, core, repeat and conversion suites retain source/gear/conversion coverage. |
| B06–B07, B12–B13, B18 | Actual allocated cohort and UI playback; effect lifecycle/combat, T4 completion, repeat-origin, macro/cooldown suites retain exact expiry, miss, guarantee overlap and resource boundaries. |
| B15 | Actual base+125/four-stack result and cleanse survival; status accounting/interactions/completion retain cap, doubling, selective cleanse and unpromoted partner harnesses. |
| B16–B19 | Actual purchase thresholds, gates/refunds, saved build compatibility, full UI journey; ranked/progression/persistence/core/mixed journeys retain locks and duplicate/pruning boundaries. |
| B20–B21 | New rendered full-tree journey, retained usability/presentation tests, exact old core/mixed parity and released Balance Lab role-reversal fixtures. |

Earlier T2/T3 reports are historical planning snapshots. The coverage ledger now reflects T4 promotion; rechecking the design writes separate T4 evidence and does not overwrite T3's original unchanged-runtime report. No unsupported partner tree is declared playable.

## Validation results and handoff

- [Existing regression](../project/reports/p6_m5_t4_regression/summary.json): 60/60 suites pass, including unchanged exact core/mixed combat parity.
- [Focused validation](../project/reports/p6_m5_t4_final/summary.json): 4/4 suites pass (full allocation/combat, full UI journey, conversion/ignore hooks, Shred mechanics). Full-tree mechanics: 1,772 assertions. The final UI-only rerun also [passes](../project/reports/p6_m5_t4_ui_final/summary.json).
- [Rendered journey](../project/reports/p6_m5_t4_journey/visual-checks.json): 142 checks pass; 15 screenshots across the three accepted sizes, including the 125% tree, capstone inspection, title budget selector and live combat. Visual inspection confirms controls and effect indicators fit. Dense simultaneous floating combat labels can overlap; broader burst-label presentation remains M7.
- [Balance Lab output](../project/reports/p6_m5_t4_mechanics/lab.json): primary/reversed full allocations, 20 seeds each, repeatable samples and aggregates.
- [Protected-file fingerprints](../project/reports/p6_m5_t4_final/isolation.json): real FacelessVoid and Enigma saves and sibling project/export files unchanged.
- [Static checks](../project/reports/p6_m5_t4_static/checks.json): compatibility, promotion provenance, exact fixture identities, display catalog and approved specification checks pass. Ledger regeneration/check also passes.

The first new test had an invalid test-only type annotation, then the UI wrapper needed an explicit initializer. Both were corrected before the final successful runs. Baseline certificate-store and shutdown ObjectDB/resource warnings still appear; no script errors or failed assertions remain in final evidence. T4 does not claim a balance or complete four-tree release.

T5 is the Thief design review; T6 implements it after approval. The mechanics reference, coverage ledger, milestone tracker and onboarding context now point to this completed scope.

## Follow-up: Dance of Death recast display

Fixed blank icons on second/later activations: runtime instances `dance.2`, `dance.3`, etc. now share the `buff.dance` presentation identity while retaining individual expiry/start times. Gameplay, cooldown skips and guarantees are unchanged. A real 50-second resolver replay checks three casts, icon/tooltip textures, full and half countdowns, expiry, retry and finish. [Four passing suites](../project/reports/p6_dance_recast/summary.json).
