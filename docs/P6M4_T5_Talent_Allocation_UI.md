# M4-T5 — Ranked talent allocation UI

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

Completed 2026-10-02 for the supported Bladedancer core. T6 is next; T8 remains the full core playtest checkpoint.

## Delivered

The shared talent modal now uses `project/scripts/ui/ranked_talent_view.gd` for ranked builds. It groups talent cards into tiers using point gates and prerequisite depth, draws prerequisite links, and displays assigned icons, current/max ranks, current and next effects, named requirements and purchase/refund reasons. Core talents have point gates but no explicit prerequisite edges; the link renderer is verified with synthetic dependencies rather than invented core prerequisites.

Rank buttons use state/model transactions. Rejected actions leave allocations unchanged and report the reason nearby; keyboard focus survives refresh. Successful edits refresh point totals, intrinsic information, automatic unlocks and other build panels. The display retains fractional primary scaling: Bladedancer gains 0.2 percentage points of retrigger per invested primary point. The empty nine-point slot is labelled explicitly.

Refunds preserve the established rules: Test Mode refunds only between contracts; Practice refunds outside playback. Invalid dependent refunds name the blocking talent or gate rather than cascading refunds. Skills removed from a rotation are named; unlocking them again does not silently restore slots. Fancy Footwork details describe the reviewed three-second duration, five-stack cap and rank-dependent 2/4/6/8/10% Leaping Plunge reduction per consumed stack.

## Mode behavior and persistence

- Test Mode keeps its fixed Bladedancer core, ten-point starting budget, fresh-entry behavior and save isolation from T4.
- Practice now loads the same supported ranked core explicitly, with its existing 45-point configurable budget. The talent modal offers a 0–45 budget control; reductions below allocated points are rejected.
- Practice provides primary/secondary selectors, duplicate-role prevention, primary removal and a role-swap action. Only Bladedancer is currently shipped in this slice, so no supported secondary tree is available and swapping is disabled. Two-tree role preservation is tested with an injected fixture; actual mixed-build promotion remains T9.
- Practice uses `user://practice_bladedancer_core.json`. Its previous `practice_build.json` remains untouched. Registry/path selection belongs to each Practice state, not a global Adventure registry override. Autosave, explicit Save Setup and reopening use the scoped registry and save path.
- Practice allocation, role changes, budget changes and refunds are blocked while combat playback is active and enabled when playback finishes or is skipped.

Legacy allocation behavior is retained for legacy state consumers. This does not promote the other three redesigned trees or complete the mixed-build implementation.

## Evidence

[Acceptance results](../project/reports/p6_m4_t5_verified/summary.json) cover nine scripts: new talent UI acceptance, persistence UI, ranked model, persistence codec, Test Mode safety, Practice entry, shared build panels, Practice build controls and Practice combat view.

The new UI test exercises actual rank-button signals, rejected point gates and focus, ten-point core allocation and seven skill unlocks, named rotation removals, no automatic rotation restoration, active-contract refund rejection, scoped Practice save/load, legacy-save preservation, playback restrictions, zero points, role removal/duplicate rejection, dependent refund rejection and supported role swapping with retained ranks.

Actual Godot modals were rendered at 1280×720, 1600×900 and 1920×1080. A labelled, unsaved 20-talent synthetic fixture checks long names, five tiers, prerequisite links and scrolling to the final controls. Initial picker layout and fractional-stat formatting issues were corrected during review.

- [Test Mode talent modal](../project/reports/p6_m4_t5_visual/talents-1280.png)
- [Practice talent modal](../project/reports/p6_m4_t5_visual/practice-talents-1280.png)
- [Synthetic dense fixture, top](../project/reports/p6_m4_t5_visual/synthetic-top-1280.png)
- [Synthetic dense fixture, bottom](../project/reports/p6_m4_t5_visual/synthetic-bottom-1280.png)

Tests use isolated runtime save locations. The OpenGL render process reports cleanup warnings at exit and the environment's certificate-store warning; completed renders contain no script errors. Rendering and scripted control checks do not replace the full T8 player-flow review or T10 usability pass.

## Remaining owners

T6: fuller skill descriptions and rotation editing UX. T7: complete combat feedback and cooldown presentation. T8: integrated core acceptance and focused playtesting. T9: the exact mixed build and real role reversal. T10: full dense/busy usability acceptance. T11: milestone closeout.
