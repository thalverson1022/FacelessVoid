# Combat Log tabs

2026-10-27 — P6M9-D041. User approves separating the existing Combat Log so long damage breakdowns cannot crowd out the event narrative.

| Tab | Content |
| --- | --- |
| Damage Breakdown | Target/result details, ranked damage bars with amounts and percentages, then the existing skill timeline and hover details |
| Event Log | Chronological combat events using the available page height; duplicate target/summary headers removed |
| Run Log | Existing Adventure DPS trend and encounter history; Practice displays an explanatory empty state |

The shared summary above the tabs contains only actual Damage, DPS and Elapsed time. Target comparisons and the fourth Result chip no longer occupy that row. Exsanguinate health removal remains included in displayed damage/DPS under the existing log convention. Full narrative formatter APIs remain available unchanged for other callers; a new `event_log()` wrapper exposes only the existing timeline, or its invalid/empty diagnostic.

Adventure/Test and Practice now use the same overlay. Each tab owns its scrolling area, retains its position when switching or reopening the same result, and resets for a new result. The modal stays within the viewport, with a maximum1040px width and32px top/bottom margins at tested sizes. Invalid, empty and text-only results clear stale chart/summary state. Close/backdrop behavior and modal priority remain. Practice invalidation clears the shared review without modifying Adventure gold/history.

Run Log uses the already recorded encounter data. This layout change adds no purchase/reward journal, historical data reconstruction, new save schema or gameplay logging.

Verification:

- [Final stress suite](../project/reports/m9_log_tabs_20261027e/summary.json):73 checks pass. Actual resolver fixture has22 distinct damage rows and220 casts, with45 Adventure history entries. Event viewport remains677px at1600×900 and497px at1280×720 in both modes, independent of short versus long breakdowns. Checks reach bottom rows/events, preserve all three scroll positions, reset on new results, and cover invalid/empty/text-only/category-preview and actual Practice finish/invalidation paths.
- [Retained focused checks](../project/reports/m9_log_tabs_20261027d/summary.json): stress suite, Exsanguinate damage-log conventions and grouped event formatting all pass. The final subsequent refinement removes unused Practice Run Log headings/column headers only, with the stress suite rerun afterward.
- [Final screenshots and geometry](../project/reports/m9_log_tabs_20261027e/m9_log_tabs_test/m9_log_tabs/geometry.json):28 screenshots at1600×900 and1280×720. Parent inspected damage, events, Adventure history and the cleaned Practice empty state. Existing certificate-store and shutdown resource warnings remain; no script failures in passing evidence.

Existing `combat_screen_test.gd` assertions were adjusted to read target/verdict details from Damage Breakdown and chronological text from Event Log. That broader legacy suite was not rerun as part of this scoped UI verification. Earlier unrelated legacy-suite limitations remain as recorded in the M9 tracker. Combat resolution, rewards, audio, player saves and source artwork are unchanged. T10 remains Not started.

## Root casts and trigger hierarchy

P6M9-D042 follows user review of a Dance of Death / Quick Cut cascade. The original cast was present, but `_event_type_label()` incorrectly used the first trigger label produced by that cast, and the old `>>>` marker also marked roots that fired children. Original Quick Cut casts therefore appeared as RETRIGGER or Opportunity Strike.

Root casts now remain `CAST` at the left edge. Triggered casts use four spaces per recorded parent level and an arrow, preserving RETRIGGER, Opportunity Strike, PROC and Lightning labels. Indentation is capped at six levels with an explicit depth note beyond that. Missing/duplicate legacy IDs and cyclic ancestry cannot create a false parent or an unbounded loop. Successful self-buff narrative uses its effect text, including Dance's `Guaranteed Retriggers`, instead of claiming no effect.

Chronology still follows the existing millisecond/sequence merge. Natural Poison ticks remain at the left edge; forced/repeated ticks indent only with recorded cast ancestry and name their source, such as `DOT (from Poison Strike)`. This source label matters because the recorded forced tick can precede the cast's final record. No events are rearranged to draw the tree. Experimental category-preview text shares this ordering/hierarchy.

- [Four retained headless suites](../project/reports/event_log_roots_final/summary.json) pass: new real Dance/Quick Cut cascade checks, grouping, combat feedback and recap. Source snapshots verify unchanged event fields, trace, damage totals and RNG after formatting.
- [Final source-label and visual checks](../project/reports/event_log_roots_source_visual/summary.json) pass, including causal tick context, independent same-time roots, bounded deep chains, legacy defaults and missing parents. Eight actual Adventure/Practice screenshots at1600×900 and1280×720 show the original CAST and nested children clearly; parent inspected both modes and the final annotated Adventure view.
- Broader functional checks with rendering enabled exposed timing-sensitive live-view assertions; their final headless runs pass. The dedicated visual helper passes. Existing certificate-store and shutdown resource warnings remain; no broad engine qualification is claimed.
