# M4-T7 - Combat playback and temporary effects

Completed 2026-10-02 for scoped Test Mode and Practice. T8 core end-to-end acceptance is next. This task changes presentation, not combat rules, content availability or balance.

## Delivered

Normal combat results retain a compact ordered presentation stream even when diagnostic tracing is disabled. A shared read-only projection consumes initial state and recorded lifecycle, scheduler, status, poison and gold transactions. It never rerolls combat or recalculates its outcome. Records at the same timestamp are applied in sequence before display expiry, preserving consumption at an exact deadline.

Both combat views show grouped player stacks and charges, shared or per-instance deadlines, and separate enemy status counts. The summary is bounded to four effects; a scrollable inspector exposes remaining effects, independent instances, cooldowns and the event history. Finish clears active effects but retains reviewable history. Retry starts from the next result's initial state.

Macro slots show shared cooldowns on every matching copy. Unavailable Parry displays its full spent cast and missing Readiness; cooldown failures show the 0.1-second attempt. Neither animates a successful attack. Proc/retrigger casts no longer replace macro progress. Live skill details distinguish current resources and timers from captured cast duration and the planning reference; scroll position survives refresh.

The inspector includes a session-wide reduced-motion toggle. It removes intros and optional combat feedback while preserving static state and timing; switching it on clears existing stage effects and popups. Practice rejects another fight while playback owns the allocation lock. Gold presentation separates starting/current stash, this-fight theft, Mug cap and recorded crit contributions. Existing callbacks remain responsible for crediting gold exactly once.

## Verification

[Eight scoped acceptance scripts pass](../project/reports/p6_m4_t7_acceptance/summary.json): presentation, Test Mode, skill UI, Practice view, playback, icons, Bladedancer core and cooldown scheduler. [Final closeout checks](../project/reports/p6_m4_t7_closeout/summary.json) pass after the Practice guard and immediate reduced-motion cleanup. [Protected-file fingerprints](../project/reports/p6_m4_t7_closeout/isolation.json) verify isolation.

The new presentation test covers trace-on/off equivalence, record ordering, the seed-7 core Footwork/Readiness/Plunge sequence, exact-deadline consumption, speed 1/2/4 equivalence, skip/finish/retry, actual failed Parry, poison depletion versus consumption, overflow, independent effect instances, live details, both playback integrations and exactly-once theft credit. Dance, oversized effect populations and theft resources are explicitly synthetic fixtures; they do not promote mixed-tree content before T9.

Two broader suites (`p6_combat_ordering_test` and `p6_gold_contract_test`) still fail their six historical compatibility signatures. These failures reproduce with the pre-T7 resolver/observer behavior restored. The [before/after parity comparison](../project/reports/p6_m4_t7_parity/comparison.json) confirms identical damage, RNG state and signatures for all six seeds. Historical fixtures were not replaced. T11 owns reconciliation of those inherited snapshots; this is not a claim that the full regression suite passes.

## Rendered evidence

Actual Test Mode and Practice screens were rendered at 1280x720, 1600x900 and 1920x1080. Review corrected summary overflow, cropped timers, duplicate Dance captions and low-contrast cooldown overlays. Synthetic screenshots are labelled in their filenames.

- [Test Mode effects, 1280](../project/reports/p6_m4_t7_visual/core-effects-1280.png), [1600](../project/reports/p6_m4_t7_visual/core-effects-1600.png), [1920](../project/reports/p6_m4_t7_visual/core-effects-1920.png)
- [Practice effects, 1280](../project/reports/p6_m4_t7_visual/practice-effects-1280.png), [1600](../project/reports/p6_m4_t7_visual/practice-effects-1600.png), [1920](../project/reports/p6_m4_t7_visual/practice-effects-1920.png)
- [Live Plunge inspection](../project/reports/p6_m4_t7_visual/live-plunge-1280.png), [missing Readiness](../project/reports/p6_m4_t7_visual/missing-readiness-1280.png), [finished state](../project/reports/p6_m4_t7_visual/finished-1280.png)
- [Synthetic shared cooldown](../project/reports/p6_m4_t7_visual/synthetic-cooldown-1280.png), [bounded overflow](../project/reports/p6_m4_t7_visual/synthetic-overflow-1280.png), [scrollable inspector](../project/reports/p6_m4_t7_visual/synthetic-inspector-bottom-1280.png)

Reproduce automated checks with `python tools/p6/run_foundation_tests.py p6_combat_presentation_test training_room_combat_view_test p6_test_mode_test --report-name p6_m4_t7_closeout`. Render with Godot `--path project --rendering-method gl_compatibility -s res://tests/p6_playback_visual_review.gd`. The visual fixture isolates saves under its report directory. Real core screens use Whetstone 4 / Rending Slash 1 / Fancy Footwork 5; Test Mode uses Bandit Blade and seed 7, Practice uses its default unarmed setup and seed 7. Godot emits environment certificate-store and OpenGL/resource-cleanup diagnostics; the final rendered run has no script errors.

## Remaining ownership

T8 owns complete core player-flow acceptance, including persistence and repeated mode entry. T9 owns playable mixed builds and role reversal. T10 owns broader dense-layout and usability review, including the existing Practice header crowding. T11 owns full regression and historical snapshot reconciliation. No mechanics-reference update is required because no combat rule changed.
