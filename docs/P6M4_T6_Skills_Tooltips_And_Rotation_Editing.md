# M4-T6 — Skills, tooltips and rotation editing

Completed 2026-10-02 for the supported Bladedancer core. T7 is next; T8 remains the full core player-flow checkpoint.

## Delivered

Available Skills is a bounded, wrapping, keyboard-focusable list. Selecting a skill opens a persistent, scrollable details dialog with assigned art and an explicit Add to rotation action. Inspection remains available with a full or locked rotation. Add restrictions are explained outside the scrolling text. Closing returns focus to the invoking control; ordinary rotation changes preserve available-skill buttons and focus.

The shared formatter names category and unlock source, describes all seven core skills, and shows base/minimum cast time, current-build timing, attack-speed context and cooldown rules. Parry explains Readiness consumption and the full spent cast when unavailable. Quick Cut explains Footwork grants, cap and shared timer when Fancy Footwork is allocated. Plunge explains rank-dependent consumption at accepted cast start. Estimates use CombatTiming and resolved stats; planning assumes no temporary effects or slow. Damage is explicitly an estimate, with defenses, crits and live stats distinguished. No combat rule changed.

Rotation slots now select rather than remove immediately. Five columns preserve numbered reading order across two rows, with icons and short names. Details, Remove, Move earlier and Move later are explicit keyboard-accessible actions. Duplicate entries and the ten-slot cap remain intact. Manual lock and playback lock reject edits while allowing inspection; empty rotations cannot be locked. Existing state transactions continue to own unlock pruning, named removals, mode persistence and fight readiness.

Practice reserves space for the editor by reducing the combat panel minimum height and keeping its HUD/actions above actor art. This is a scoped layout adjustment; complete effect presentation and crowded-stage polish remain T7/T10.

## Verification

[Acceptance report](../project/reports/p6_m4_t6_acceptance/summary.json): nine scripts pass — new skill UI acceptance, rotation cap, tooltip formatter, T5 talent UI, persistence UI, Test Mode safety, Practice combat view, shared build panels and Practice build controls. The final HUD-layer adjustment also passes [Practice combat validation](../project/reports/p6_m4_t6_layer_check/summary.json).

The new test exercises both actual mode states, seven core unlocks and named sources, condition copy, explicit Add, duplicates, reorder/remove signals, empty/full rotations, manual/playback guards, keyboard activation, focus return and persistence of edited rotation order. A labelled test-only cooldown resource verifies shared-copy/100ms wording without promoting Dance. Existing talent tests cover named unlock losses and no automatic restoration.

Two existing tests had hardcoded temporary user:// paths; these now use the runner's scoped Practice path or report-directory sentinel files. All reported checks use isolated paths. [Protected-file fingerprints](../project/reports/p6_m4_t6_acceptance/isolation.json) remain unchanged.

Actual Test Mode and Practice screens and details were rendered at 1280×720, 1600×900 and 1920×1080. A 125% details-font stress case remains scrollable with Close/Add and the restriction explanation accessible. Initial slot overflow, overlapping slot captions and first-open dialog sizing were corrected during review.

- [Test Mode ten-slot editor, 1280](../project/reports/p6_m4_t6_visual/rotation-1280.png)
- [Test Mode editor, 1600](../project/reports/p6_m4_t6_visual/rotation-1600.png)
- [Test Mode editor, 1920](../project/reports/p6_m4_t6_visual/rotation-1920.png)
- [Practice editor](../project/reports/p6_m4_t6_visual/practice-rotation-1280.png)
- [Parry details](../project/reports/p6_m4_t6_visual/details-1280.png)
- [Practice Plunge details](../project/reports/p6_m4_t6_visual/practice-details-1280.png)
- [125% text, scrolled bottom](../project/reports/p6_m4_t6_visual/details-text-stress-bottom-1280.png)

Reproduce rendered evidence with `res://tests/p6_skill_visual_review.gd`. It isolates saves in its report folder. Fixture: p6.playable.bladedancer_core.1, Whetstone 4 / Rending Slash 1 / Fancy Footwork 5, no secondary; ten slots cycling through the seven unlocked skills. Test Mode uses seed 424242, Bandit Blade and the generated first route target. Practice uses its fresh default unarmed setup and generated target. Window dimensions above use the existing 1600×900 canvas scaling. Screenshots are planning/inspection evidence, not a balance or complete gameplay acceptance claim.

Godot reports the environment certificate-store warning and OpenGL/resource-cleanup diagnostics; final rendered runs contain no script errors. The full T8 player-flow review and T10 usability pass remain separate.

## Remaining owners

T7 supplies live Footwork/Readiness/cooldown state and complete combat presentation. The T6 dialog intentionally labels its planning estimates and does not pretend to know live stacks. T8 accepts the entire core flow. T9 adds actual mixed skills and shared-cooldown gameplay acceptance. T10 owns broad dense/busy layout validation, including remaining Practice header/stage crowding. T11 closes the milestone.
