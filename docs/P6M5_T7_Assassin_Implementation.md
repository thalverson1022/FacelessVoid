# M5-T7 — Complete Assassin implementation

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

Status: **Complete** · 2026-10-03 · Authority: **P6M5-D009**, user approval of all three review proposals and instruction to implement T7.

The [approved Assassin specification](P6M5_T7_Assassin_Design_Review.md) is playable in Test Mode and Practice: ten talents / 35 ranks, the role-aware intrinsic, five automatic unlocks and talent-granted Poison Strike. T8 Shadow review is next. Numerical tuning remains M6; full-content presentation polish remains M7.

## Implementation and access

Ten explicit [Assassin resources](../project/data/p6/assassin/) define complete ranks and canonical prerequisites. The [registry extension](../project/scripts/systems/playable_assassin_content.gd) binds the intrinsic, skills and approved icons. The new content revision is `p6.playable.assassin.1`; prior thief, bladedancer, mixed and core playable revisions remain compatible. Adventure remains disabled and retains `p6.compat.1`. Legacy same-ID skill resources and source drafts remain unchanged.

Test Mode: choose 45 starting points, accept the contract, and choose Assassin as secondary in Talent Trees. Practice: select Assassin as primary or secondary, allocate points and edit the macro; role swaps preserve ranks. All 35 Assassin ranks leave ten points for another tree within the shared budget. The existing lower-tier support rule applies to purchases, refunds and restores. Reset removes unavailable skills from the rotation while retaining base skills.

Assassin gives +5 flat base elemental damage in either role plus +1 per Assassin point when primary. Blinding Powder reads actual Assassin investment in either role, including after a live stat rebuild. Explicit validated rank carriers activate Hastened/Accelerant, Echoing/Resonance, Critical Poison and Bypass through the existing shared mechanics.

Toxic Tradeoff uses a separate Poison-tick multiplier, before crit/conversion/defenses/rounding, while the physical penalty uses the existing physical talent bucket. General elemental damage and Shadow Mastery's copied elemental bonus exclude the Poison-only factor. Tick diagnostics include it in the reported talent multiplier; neutral defaults preserve compatibility. The character panel's Poison Damage Increase includes the new factor. Talent details and the active-talent panel explain all Assassin effects; skill tooltips describe forced ticks, Potency, Virulent charges and Master duration.

## Validation evidence

| Area | Executed result |
| --- | --- |
| Every rank and both roles | **1,972 checks pass** in [full-tree validation](../project/reports/p6_m5_t7_verified/p6_full_assassin_test_console.txt). All ranks including zero, intrinsic scaling, grants, complete descriptions, gates/prerequisites, reset, malformed carriers, current and old save revisions. |
| Poison boundaries and composition | **334 checks pass** in [boundary validation](../project/reports/p6_m5_t7_verified/p6_assassin_boundaries_test_console.txt). All Toxic ranks with partial/empty fuel, natural/forced ticks, two Virulent instances and crit; conversion, isolated Shadow Mastery adapter, source rebuilds, gear stack/doubling and legal Thief 24 / Assassin 21 in both roles with live theft-derived Poison crit. |
| Deterministic allocated combat | 160 Assassin 35 / Bladedancer 10 cases: both roles × twenty seeds × neutral/dodge/cleanse/crit-negation targets. Trace repeats and trace-off outcome/RNG comparisons pass within the full-tree suite. |
| Balance Lab | Two role configurations × twenty seeds, each repeated with matching samples/aggregates. [Lab results](../project/reports/p6_m5_t7/lab.json) establish correctness, not balance. |
| Actual player flows | **139 checks pass** headless and rendered: Test Mode selection, all ranks via UI, Practice primary, macro duplicates, combat/retry, save/reload, reset/pruning, keyboard details and enlarged text. [Headless](../project/reports/p6_m5_t7_journey/checks.json), [rendered](../project/reports/p6_m5_t7_journey/visual-checks.json). |
| Regression | **68 distinct suites pass** in the [reconciled final report](../project/reports/p6_m5_t7_final/summary.json), which retains each original run or corrected rerun's command and report provenance. Build, saves, shared mechanics, exact compatibility traces, full Blade/Thief, UI, audio and Assassin coverage included. |
| Isolation | [Protected-file report](../project/reports/p6_m5_t7_final/isolation.json) verifies real FacelessVoid/Enigma saves and sibling project files unchanged across regression and final reruns. |
| Static content/provenance | [Static report](../project/reports/p6_m5_t7_static/summary.json): release predecessor chain, compatibility resource hashes, identity/draft hashes, display catalog, coverage ledger, fixture and review checks. |

Inspected captures at 1280×720 and 1920×1080 plus enlarged-text tree views; the rendered journey also captures 1600×900. The Assassin header icon, node controls, skill strip and Critical Poison details fit the accepted layout. Bypass/Virulent/Master use existing status presentation. Inherited floating combat labels can extend beyond the arena; presentation polish remains M7. Existing certificate-store and teardown resource warnings remain visible in some headless logs, as in the inherited Poison suite; passing runs contain no script errors.

Initial failures are retained as history: a test used a nonexistent conversion property; the first boundary wrapper omitted its inherited initializer; two inherited UI tests assumed exactly two registry trees or treated every catalog entry as a displayed Thief node. Corrected the harnesses/expectations and reran them successfully. A real binding issue found during inspection was corrected: Powder investment now survives live stat rebuilds and has focused coverage. No historical compatibility hashes or gameplay fixtures were rewritten to hide differences.

## Reproduction and closeout

From the repository root:

```powershell
python tools/p6/run_foundation_tests.py --report-name p6_m5_t7_recheck p6_full_assassin_test p6_assassin_boundaries_test p6_full_assassin_journey_test
python tools/p6/check_assassin_release.py
python tools/p6/check_content_registry.py
python tools/p6/build_tree_display_catalog.py --check
python tools/p6/build_m5_coverage_ledger.py --check
python tools/p6/check_m5_assassin_review.py
```

Rendered run: launch the configured Godot 4.7 console executable with `--path project --log-file <workspace report path> -s res://tests/p6_full_assassin_journey_test.gd -- --visual`; use the documented isolated journey save paths. The [Assassin release manifest](../project/data/p6/assassin_release_manifest.json) fingerprints the new resources and binding sources and preserves the exact predecessor manifest hash.

All per-tree checklist items are complete for T7. The ledger now accounts for 33 playable talents / 105 ranks and fifteen planned skills across three trees. T8 owns Shadow; T9 consolidates the full mixed-tree matrix; T10 handles combined full-content journeys; T11 closes M5. These downstream tasks are not marked complete by Assassin acceptance.


### Potency HUD follow-up

Potency appears immediately before Poison in Test Mode and Practice. Its icon uses the shared self-buff radial countdown, driven by the recorded expiry and refresh time, with remaining seconds in its tooltip. Expiry removes the chip.

Validation: `p6_combat_presentation_test`, `combat_hud_test`, and `training_room_combat_view_test` passed; the presentation test covers placement, half-duration, refreshed duration, and expiry in both HUD paths. A rendered half-duration Practice capture is in `project/reports/p6_potency_hud/potency-half-time.png`. The runner's overall isolation guard failed because the real Practice core save hash changed during both runs; other Godot instances were open, and the cause is not established. Test wrappers redirect all three save paths into their report directories. See `p6_potency_hud` and `p6_potency_hud_recheck` reports for unmodified evidence.


### Fixed defense-status slots

Superseding the temporary Potency chip above, Penetration and Potency now remain visible before Poison in combat and Practice. At zero they show grey icons and x0; active icons regain color and share the self-buff radial timer. Counter space reserves x100 so activation, rank changes and expiry do not shift adjacent chips. Practice uses the full HUD width instead of the old 260-pixel row, keeping Interrupt within the combat view; finishing a fight resets the defense chips to inactive.

Validation: the three focused presentation/HUD suites pass in `project/reports/p6_fixed_defense_hud`; final presentation checks additionally verify stable Poison position and the final chip's right boundary. Active and inactive rendered views were inspected. Protected save fingerprints are unchanged in this follow-up. Rendered runs retain environment certificate/shader-cache warnings.
