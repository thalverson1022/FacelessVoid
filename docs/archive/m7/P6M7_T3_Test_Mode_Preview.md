# M7 Test Mode presentation preview

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. [Current context](../../P6_Project_Onboarding_Context.md).

**Current status — withdrawn (2026-10-08):** The user rejected the Test Mode preview and requested restoration of the original. The three modified runtime files were restored byte-for-byte from the verified pre-preview snapshot; preview scripts and controls were removed. The material below is historical, not the active UI or an accepted design. T3 needs a revised direction.


Implemented 2026-10-08 at the user's request to evaluate the proposed presentation inside Test Mode before changing Adventure.

## How to compare

Start Test Mode from the title screen. Below the combat buttons, choose **Feedback: Lanes**, **Feedback: Event list**, or **Feedback: Original**. Lanes is the default for each new Test session. Switching is available during playback. Effects opens the full effect inspector even when there are no active effects. Reduced motion is local to the preview; it does not change Adventure or Practice settings.

The preview provides fixed feedback rows, short grouping windows, explicit critical/outcome labels, priority effect ordering, visible overflow, available versus already-spent effect counters, effect-specific inspector explanations, and scoped corrections for Death Strike, Mug, Pick Pocket and Big Score tooltips. Pending additional hit sounds are canceled on speed changes, layout changes, skip, completion and screen exit. Existing sounds already playing are allowed to finish.

This is a playable T3 experiment, not acceptance of a final visual policy. Existing icon artwork and mappings are retained. Broader talent-description cleanup, icon production, enlarged-text certification and final dense-build accessibility review remain downstream work.

## Isolation and reversal

Adventure instantiates the original presenter and effect display. Practice retains its existing combat view. The three `test_feedback_*.gd` files own the alternative presentation. The shared screen selects them only when `BuildState.is_test_mode` is true. The shared presenter contains one extracted virtual audio dispatch method whose default body retains the original behavior. Tooltip changes require both Test Mode and active preview metadata; stale metadata cannot enable them in Adventure.

Original restores normal popup presentation and original tooltip/effect content within Test Mode. The Test-only selector and audio cancellation guard remain available for comparison. No gameplay values, resolver, save format, icon assets or mappings changed. Preview preferences are not saved to player profiles.

## Verification

The dedicated `p6_m7_test_feedback_test` exercises mode gating, Original restoration, exact resolver damage accounting without repeat double counting, consumed Footwork inspection, local motion state, speed-generation cancellation, skip clearing and Adventure's original component selection. Rendered captures use a real seeded Bladedancer resolver fixture inside the Test Mode screen, with a high-HP test target; they are fixture screenshots, not a saved player run or user playtest.

- [Final focused regression](../../../project/reports/p6_m7_test_preview_final/summary.json): six suites pass (preview, existing combat presentation, combat screen, attack audio, Adventure UI, Practice combat view).
- [Rendered preview](../../../project/reports/p6_m7_test_preview_visual2/summary.json): passes; all three selector modes captured at 1280×720, 1600×900 and 1920×1080. The first render exposed toolbar/timer and effect/HP overlaps; the retained second render places controls in the lower band and effects beneath the HUD.
- [1280 lanes capture](../../../project/reports/p6_m7_test_preview_visual2/p6_m7_test_feedback_test/m7_preview/preview-1280-1.png) and [1600 event-list capture](../../../project/reports/p6_m7_test_preview_visual2/p6_m7_test_feedback_test/m7_preview/preview-1600-2.png).
- [Scope check](../../../project/reports/p6_m7_test_preview/scope_check.json): only three existing runtime files changed from the pre-preview snapshot; gameplay systems, autoloads, data and assets are unchanged. The alternative implementations are three new UI scripts.
- Final headless and rendered runs confirm unchanged source during validation and isolated per-suite user data. Existing certificate-store and engine teardown warnings remain outside this preview's qualification scope.

T3 remains awaiting user hands-on review. This fixture establishes the tested layout and mode boundary; it does not certify every dense mixed-tree configuration, 125% text, subjective readability or real-audio listening. Long labels currently trim with an ellipsis; the effect inspector and existing combat log retain access to details. These are preview refinements to assess before promotion.
