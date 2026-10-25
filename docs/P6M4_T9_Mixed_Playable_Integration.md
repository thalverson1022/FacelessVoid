# M4-T9 — Mixed-tree extension and role reversal

Completed 2026-10-02. The exact Bladedancer 15 / Thief 5 build is playable in
Test Mode and Practice. Practice role reversal retains allocations and rotation.
M4-T1–T9 are Complete; T10 dense-layout and usability validation is next.

## Playable content and compatibility

`BuildContentRegistry.test_mode()` now declares `p6.playable.mixed.1`. Its
production extension adds Opportunity, Cloak & Dagger, Keen Eye, Dance of Death,
Steal and Mug to the existing core. It uses reviewed production skill descriptors;
no runtime code depends on test fixtures. The compatibility Adventure registry
remains `p6.compat.1`. Pick Pocket, Big Score, Gilded Blade, Silvered Edge and the
rest of the four trees are not promoted by this task.

Existing `p6.playable.bladedancer_core.1` Practice payloads remain readable: core
IDs, ranks, unlocks and mechanics did not change. Practice retains its separate
`practice_bladedancer_core.json` path, now also storing mixed setups with the new
revision. No user save is migrated or overwritten by tests. The old compatibility
Practice file and Adventure file remain separate. Test-only revisions are rejected.

Fresh Test Mode still starts with Bladedancer, ten unspent points, empty rotation,
Bandit Blade and 100 gold. Accepting a contract exposes the supported Thief
secondary in Talent Trees using the existing contract-transition access rule.
Two completed contracts award the additional ten points needed for this fixture;
the reward schedule is unchanged. The subsequent user-directed Reset points fix allows free Test Mode refunds during planning, including within an active contract; Adventure retains its between-contracts rule.

## Accepted fixture and presentation

- Bladedancer 15: Whetstone 4, Rending Slash 1, Fancy Footwork 5,
  Opportunity 3, Cloak & Dagger 2.
- Thief 5: Keen Eye 5.
- Rotation: Dance of Death, Quick Cut, Quick Cut, Parry Strike, Leaping Plunge,
  Rending Slash, Steal, Mug. All ten unlocked skills have assigned icons.
- Bladedancer primary: 8% retrigger and +10% Increased Gold. Thief primary:
  5% retrigger and +20% Increased Gold. Zero invested Thief points grants its
  base +10% gold but neither Steal nor Mug.

Opportunity hover explains its rank chance and Quick Cut trigger. Tree heading
hover explains base intrinsic and primary-only scaling. Dance hover explains the
five-second macro guarantee and twenty-second shared cooldown. Mug hover explains
fight-stolen gold, starting-stash exclusion, and its +100 base-damage cap; during
playback it also shows live stash, stolen total and counted bonus. Existing
presentation events supply the values without modifying combat math. The accepted
presentation-only delay for consumed buff icons remains intact.

The Practice Swap primary / secondary control retains ranks and ordered duplicate
rotation entries, updates intrinsic scaling, and rejects changes during playback.
Refunding Keen Eye below three points removes Mug and names that removal;
reallocation does not silently restore the slot.

## Validation and evidence

The new [mixed journey](../project/tests/p6_mixed_journey_test.gd) passes
[174 checks](../project/reports/p6_m4_t9_journey/checks.json), including:

- Production versus reviewed M3 fixture: exact trace and final RNG parity in
  both roles at gold 0/100/499/500/501/10000 with seeds 7/19/42 (36 comparisons).
- Production Mug at credited theft 99/100/101, no-theft large stash, duplicate
  Dance shared cooldown and every blocked slot spending 100 ms. The boundary
  stress stats are test-only, not a promoted build or balance target.
- Actual Practice scene allocation, rotation construction, both roles, live Dance,
  nonzero theft credit, fixed-seed retry, save/reopen and unlock-boundary refunds.
  Seed 8, 30 seconds, unarmed/default target and configured stash 499 yield three
  credited stolen gold in each role; retry restores 499 and zero fight theft.
- Actual Test Mode secondary selection, exact mixed allocation and resolver fight.
  The two-contract progression setup uses synthetic wins, explicitly separate
  from the real Practice and final Test Mode combat checks. T8 retains the real
  reward/retry controller journey.
- Old-core decode, rejection of fixture revisions and foreign tree resources,
  preserved Adventure/legacy Practice sentinels and saved mixed Practice bytes.

[T9 acceptance suites](../project/reports/p6_m4_t9_acceptance/summary.json) cover
the mixed journey, Test Mode, talent UI, skill UI, combat presentation, persistence
UI, Practice builds/combat view, playback, core mechanics, save boundaries and
tooltip formatting. The [core journey also passes](../project/reports/p6_m4_t9_regression/summary.json)
in the broader run (94 current compact-UI checks). [Protected-file fingerprints](../project/reports/p6_m4_t9_acceptance/isolation.json)
confirm user saves and protected Enigma files are unchanged. Both existing Python
fixture/source checks pass.

The broader `p6_gold_contract_test` still fails only its six inherited pre-T2
compatibility signatures, as documented by [T7](P6M4_T7_Combat_Playback_And_Temporary_Effects.md).
Those fixtures were not rebaselined; T11 retains reconciliation. This is not a
claim of a fully green historical regression suite.

The rendered journey passes the same [174 checks](../project/reports/p6_m4_t9_journey/visual-checks.json).
Twenty-seven screenshots cover nine stages at 1280×720, 1600×900 and 1920×1080.
The tree modal scrolls to Thief's rank/unlock controls; roles, skills, rotation,
Dance timer and live Mug information were visually inspected. Tooltip evidence
renders the actual button's custom-tooltip control on an overlay layer; it is not
a claim of a human mouse-hover playtest. Logs include existing renderer startup,
certificate-store and resource-cleanup diagnostics, with no final script errors.

| Screen | Representative rendered evidence |
| --- | --- |
| Mixed talents and role controls | [1280](../project/reports/p6_m4_t9_journey/mixed-talents-1280.png) |
| Thief ranks and unlocks after scrolling | [1920](../project/reports/p6_m4_t9_journey/mixed-thief-talents-1920.png) |
| Dance playback | [1280](../project/reports/p6_m4_t9_journey/mixed-playing-1280.png) |
| Live Mug: stash 502, stolen 3, bonus +3/100 | [1280](../project/reports/p6_m4_t9_journey/mixed-mug-1280.png) |
| Reversed roles and live Mug | [1600](../project/reports/p6_m4_t9_journey/mixed-reversed-mug-1600.png) |
| Reopened reversed setup | [1920](../project/reports/p6_m4_t9_journey/mixed-restored-1920.png) |

Reproduce focused acceptance:

```powershell
python tools/p6/run_foundation_tests.py --report-name p6_m4_t9_recheck p6_mixed_journey_test p6_test_mode_test p6_talent_ui_test p6_skill_ui_test p6_combat_presentation_test
```

Rendered invocation: Godot `--path project --rendering-method gl_compatibility
--log-file <workspace-log> -s res://tests/p6_mixed_journey_test.gd -- --visual`.
The journey redirects every save path to its report directory; do not run two
copies simultaneously.

## Remaining ownership

T10 retains the provisional talent-tree layout, connector routing through occupied
rows, dense UI, long tooltips, text scaling and broader accessibility review. T9
does not claim final layout approval. T11 retains milestone-wide regression and
historical signature reconciliation. M5 owns remaining tree content, M6 balance,
and M7 final presentation. No combat mechanics or numerical balance changed.

## Test Mode Reset points follow-up (2026-10-02)

The user reported Reset points appearing ineffective after accepting a Test Mode
contract and explicitly chose to allow resets between fights. Test Mode now allows
both full resets and individual rank refunds in contract offers, route selection
and fight planning. Combat playback, result handling and ended runs reject resets.
Adventure keeps its existing between-contracts restriction; Practice is unchanged.
Reset preserves earned points and tree roles, removes unavailable rotation skills
and clears the build lock. A disabled reset now has a visible explanation beside
it, instead of relying on feedback above the scrolled trees.

Validation: the talent UI, core journey and mixed journey pass in the
[UI/journey run](../project/reports/p6_test_mode_reset_verified/summary.json). The
Adventure progression suite passes in its [corrected-fixture rerun](../project/reports/p6_test_mode_reset_adventure/summary.json); its synthetic trees now belong to its isolated class, as required by the T9 content-membership guard. Together these verify Test Mode reset/reallocation/fighting, disabled feedback and state-level combat/result rejection, unchanged Adventure respec behavior, and mixed Practice/Test Mode flows. The earlier failed fixture setup remains recorded in the first report. Both runs preserve protected saves using isolated report paths.
