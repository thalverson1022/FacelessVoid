# Compact combat UI - user-directed revision

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

**Current talent-tree status (2026-10-02):** The subsequent T10 talent-tree UI/UX
is accepted by the user. The [accepted baseline and remaining checks](P6M4_T10_Full_Tree_UI_UX_Plan.md#accepted-baseline-and-remaining-t10-work)
supersede this document's historical provisional-layout statements and tree
interaction details. T10 final usability validation is complete; T11 regression/closeout is next.

Implemented 2026-10-02 after M4-T8 playtesting. This instruction supersedes T2/T6 decisions for persistent skill dialogs, explicit bottom Add/Remove/Move actions and detailed talent cards. M4-T9 remains next; this is a shared UI revision, not a new content milestone.

## Current interaction

- Available Skills: icons only. Click or keyboard activate to append immediately; duplicates and the ten-slot limit remain. No details dialog opens.
- Skill Build: one row of ten compact numbered icons, without name captions or bottom action buttons. Right-click removes exactly that entry; Delete works on a focused icon. Manual and playback locks still reject edits. The bottom status line is removed; cast progress and per-slot cooldown/charge feedback remain.
- Skill hover: name, cast-speed bracket/current-build cast time, current gear/talent damage range or effect, then a short condition/extra line. Values are resolved at hover time, so gear and allocation changes are reflected. Damage is the build's pre-defense, noncritical range rather than a prediction of the next randomized hit.
- Talent Trees: level rows progress upward from Level 1 at the bottom, with clickable icons and rank counts. Click purchases one point; right-click refunds one rank under existing respec rules. Hover contains current/next effects and restrictions. Compact point totals, role headers and Reset points remain; Practice retains its role/budget controls. A lower strip shows automatic skill unlock icons with required invested-point counts; unlocked icons brighten. Intrinsic details remain in the tree-header hover. Unsupported content is not added.

The Available Skills strip and Skill Build panel require less height, returning space to combat in both Test Mode and Practice. The shared Adventure combat UI uses the same components.

## Verification

[Nine affected suites pass](../project/reports/p6_ui_simplify_final/summary.json): skill UI, talent UI, combat presentation, integrated core journey, persistence UI, icon assignment, tooltip formatting, combat screen and Practice combat view. [Protected files remain unchanged](../project/reports/p6_ui_simplify_final/isolation.json).

Tests now reflect direct icon interactions instead of requiring the superseded dialogs/action buttons. Coverage includes duplicates, right-click removal/refund, zero/gated allocation, manual/playback locks, the ten-slot cap, keyboard activation, dynamic damage after a gear change, real combat/reward/retry flows and independent Practice persistence. No combat or allocation rule changed.

Rendered Test Mode and Practice at 1280x720, 1600x900 and 1920x1080, including the full ten-slot strip, talent levels and actual tooltip controls. The renderer log has no script errors. Existing certificate-store and renderer/resource-cleanup diagnostics remain environmental validation limitations.

- [Test Mode - ten slots](../project/reports/p6_compact_ui_visual/test-build-1280.png)
- [Compact talent tree](../project/reports/p6_compact_ui_visual/test-tree-1280.png)
- [Skill tooltip](../project/reports/p6_compact_ui_visual/skill-tooltip.png)
- [Talent tooltip](../project/reports/p6_compact_ui_visual/talent-tooltip.png)
- [Practice layout](../project/reports/p6_compact_ui_visual/practice-build-1600.png)
- [Practice talent controls](../project/reports/p6_compact_ui_visual/practice-tree-1280.png)

Reproduce with `python tools/p6/run_foundation_tests.py p6_skill_ui_test p6_talent_ui_test p6_combat_presentation_test p6_core_journey_test p6_persistence_ui_test icon_assignment_test skill_tooltip_formatter_test combat_screen_test training_room_combat_view_test --report-name p6_ui_simplify_final`. Current visual fixture: `res://tests/p6_compact_ui_visual.gd`, using a workspace log path and the compatibility renderer. It redirects saves to its report directory. Older task handoff screenshots describe their historical UI; this document and the compact visual fixture describe the current controls.

## Follow-up: compact buff clocks

User-directed follow-up on 2026-10-02 replaces the large red player-effect header/cards with a horizontal row of buff icons, centered stack/charge counts and the same radial countdown control used for stun. Both stun and buffs now share `combat_radial_countdown.gd`. The countdown is driven by recorded simulation time, resets on a refreshed deadline and retains its origin on consumption without refresh. Untimed Readiness charges have no clock. Independent instances use their nearest expiry; individual timers remain in the inspector.

Hover gives the effect name and remaining time; clicking an icon opens the existing inspector. Overflow beyond four grouped effects uses a small count control. Expiry and finish remove icons; the later impact-timing follow-up below delays consumed-stack removal until cast resolution; no large empty/finished effects box remains. Combat rules are unchanged.

[Four affected suites pass](../project/reports/p6_buff_clock_verified/summary.json): presentation, playback, Practice combat view and integrated core journey. Added checks cover half-time progress, refresh, consumption without timer reset, untimed charges, independent expiries, centered counts and removal on finish. [Protected files are unchanged](../project/reports/p6_buff_clock_verified/isolation.json). Rendered both modes at 1280x720, 1600x900 and 1920x1080 using `res://tests/p6_buff_clock_visual.gd`; no script errors in the rendered run.

- [Test Mode buff icons](../project/reports/p6_buff_clock_visual/test-buffs-1600.png)
- [Practice buff icons](../project/reports/p6_buff_clock_visual/practice-buffs-1280.png)


## Follow-up: consumed buffs remain until impact

Consumed player buff icons and their spent stack counts now stay visible through the consuming cast's windup, then clear on that cast's resolution. Combat consumption, eligibility, damage and captured cast duration are unchanged. The shared presentation model keeps separate display-only snapshots linked to exact cast IDs; its active state and inspector still reflect immediate consumption. Instant consumption needs no delay. Interrupted casts also release the snapshot at resolution.

Partial spends retain only the spent units, normal expiry still removes unspent units, and a new grant is preserved when an older cast resolves. Held units remain visible even if their original timer expires during windup. Skip, finish and retry clear these snapshots.

[Four affected suites pass](../project/reports/p6_buff_impact_verified/summary.json): presentation, playback, Practice combat view and core journey. [Additional boundary checks pass](../project/reports/p6_buff_impact_boundaries/summary.json), covering Readiness and Footwork just before/at impact, partial spending, unrelated casts, original expiry, new grants, interruption, skip, finish and retry. Protected saves remain unchanged. This is a timing-only follow-up; the previous buff icon layout is retained.


## Follow-up: upward trees and skill unlock strip

Talent levels now progress upward from Level 1 at the bottom, with prerequisite connections running upward too. Below each tree, a compact row shows automatic skill unlock icons and their required invested-point counts, ordered by threshold. Locked icons are dimmed; unlocked icons brighten with a gold border. Hover identifies the skill, requirement and current unlock state. Allocation refreshes these indicators in both modes.

Removed the Skill Build bottom status line. Existing per-slot cooldown/charge feedback and detailed combat inspection remain available.

Talent UI, skill UI and combat presentation suites pass in `project/reports/p6_upward_trees_verified`. Rendered Test Mode and Practice at 1280x720, 1600x900 and 1920x1080 with the compact UI fixture; reviewed both modes at 1280x720. No script errors in `project/reports/upward_trees_visual_console.txt`.


## User handoff and deferred layout work

On 2026-10-02 the user accepted the current implementation as sufficient to move on, while explicitly stating that the talent tree layout needs substantially more work. The layout remains provisional. Further refinement belongs to M4-T10 dense-layout/usability validation; this does not block M4-T9 and is not a claim of final visual acceptance.

This document consolidates the implemented playtest requests, including upward talent progression, the lower unlock strip, removal of Skill Build status text, compact buff clocks and display-only delayed consumption. No additional runtime changes or new test runs were made for this documentation closeout; evidence above comes from the implementation runs.

Next: M4-T9 mixed-tree extension and role reversal, using the exact M3-T10 Bladedancer 15 / Thief 5 fixture. See the [M4 tracker](P6M4_Playable_Integration_And_UI_Validation_Tracker.md) for scope and status.
