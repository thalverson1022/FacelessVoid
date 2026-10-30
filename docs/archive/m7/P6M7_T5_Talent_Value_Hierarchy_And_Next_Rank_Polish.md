# T5: talent value hierarchy and shorter Next rank

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. [Current context](../../P6_Project_Onboarding_Context.md).

Current task status: **Complete — user accepted T5 under D039 on 2026-10-15.** See [closeout and accepted conventions](../../P6M7_T5_Closeout_And_Accepted_Conventions.md).

The dated status, proposals and evidence below are historical snapshots; later accepted conventions and D039 supersede earlier In progress/closeout-excluded instructions.

User-approved D033 presentation polish, 2026-10-15. T5 remains **In progress**; no milestone closeout.

## Approved format

Talent effect labels/descriptions remain cream. Only the separate structured rank-value text uses the existing worn gold `UIColors.TEXT_GOLD`; operators and signs remain explicit and unchanged. Numbers embedded in static rules, such as Coated Weapons, Bypass or Gilded Blade, remain cream. Existing name/rank styling, original icons and VT323's normal weight remain.

A shared `talent_effect_rows.gd` renderer uses RichTextLabel color runs via `push_color`/`add_text`. This keeps values inline and wrapping with their label, without BBCode in plain text or parsing user-visible copy as markup. It uses the existing 20px tooltip effect size and 13px Active Talents effect size. Decorative row spacing adds 4px between description and value groups; Next rank has a separate 12px spacer, in addition to existing container separation. Rich rows ignore mouse input and fit their complete wrapped content.

Invested talents retain complete current effects. Next rank compares stable row keys plus label/value, showing only changed values, changed rules or newly introduced effects. Identical descriptions are shown once. Maximum rank omits Next rank. At rank zero, the complete first-level base rules appear once above Next rank; Next contains first-level value rows. Rule/unlock-only talents show the rule once without an empty Next header. All rank states remain useful.

Active Talents uses the same shared rich rows for current effects only, with the same value colors and description/value spacing. Names/ranks, subclass portraits, absence of individual talent icons, legacy fallback and scrolling remain. Skills were outside this approval and are byte-identical, including their category colors/timing format. Requires remains absent and allocation gates unchanged.

The live rank-row generation and every approved D029-D032 effect string/value are byte-identical to the pre-change method body. Gear terminology, Shadow artwork and gameplay/resources remain unchanged.

## Verification

[Final focused report](../../../project/reports/p6_m7_talent_polish_focused_final/summary.json): all three affected suites pass. **6,917** talent assertions cover all 44 talents/140 positive ranks plus rank-zero states, stable-key changes, newly introduced/changed rules, no duplicated shared rule, rank-zero explanation/first values, unlock-only handling, max behavior, gold-only value runs, literal copy/negative operators, spacing and prior wording/value assertions. **1,698** shared Active Talents/background assertions verify all positive-rank current texts, cream labels/gold values, 13px normal font and retained role/layout/input behavior. Existing `build_panels_test` passes.

[Final rendered report](../../../project/reports/p6_m7_talent_polish_rendered/summary.json): **62 focused actual captures** pass. All four trees and Adventure/Test Mode/Practice are represented: invested, zero, max, rule-only and unlock-only states; negative tradeoff values; long conversion labels; complete current effects with shortened Next; dense current-only Active Talents. Main stress samples use 1280x720 and 125% text; long Mastery also renders at 1600 and 1920. The stress traversal explicitly scales RichTextLabel `normal_font_size` as well as Label fonts, so Active Talents effects actually render at 16px for the 125% case. Runtime assertions verify each rich label's fitted height includes all wrapped content, remains stable after settling, and popup dimensions fit the viewport. Representative images were visually inspected.

Both accepted runs report unchanged source isolation and disposable saves. [Pre-change fingerprints](../../../work/t5_talent_polish_before/hashes.json) and [final reconciliation](../../../work/t5_talent_polish_before/final_verification.json) show all production source fingerprints match both final baselines. Six skill formatter/provider files are byte-identical, the approved rank-row method body is unchanged, and the gear formatter/Shadow JPG are unchanged. The 330 protected mechanics/resource/data hashes match the retained baseline. No combat math/state/save change.

```text
python tools/p6/run_m6_closeout.py --report-name p6_m7_talent_polish_focused_final --tests p6_m7_talent_hover_test p6_m7_tree_background_active_text_test build_panels_test
python tools/p6/run_m6_closeout.py --report-name p6_m7_talent_polish_rendered --visual --tests p6_m7_talent_polish_visual
```

Reviewed examples:

- [Fancy Footwork current/Next value hierarchy](../../../project/reports/p6_m7_talent_polish_rendered/p6_m7_talent_polish_visual/talent_polish_visual/test-fancy_footwork-1280-125.png)
- [Rank-zero explanation above first-level Next value](../../../project/reports/p6_m7_talent_polish_rendered/p6_m7_talent_polish_visual/talent_polish_visual/test-zero-fancy_footwork-1280-125.png)
- [Toxic Tradeoff explicit negative gold values](../../../project/reports/p6_m7_talent_polish_rendered/p6_m7_talent_polish_visual/talent_polish_visual/test-toxic_tradeoff-1280-125.png)
- [Dense Active Talents with actual 125% rich text](../../../project/reports/p6_m7_talent_polish_rendered/p6_m7_talent_polish_visual/talent_polish_visual/test-active-assassin-1280-125.png)
- [Long Mastery label at 1600](../../../project/reports/p6_m7_talent_polish_rendered/p6_m7_talent_polish_visual/talent_polish_visual/test-mastery-1600-125.png)

The first focused report retains diagnostics from a test constant named Panel conflicting with Godot's native class and duplicate automatic node names causing a fixture lookup to miss later rich rows. The test alias and readable row naming were corrected before the final runs; existing build-panel checks passed in both. A separate check-only parse command used redirected APPDATA/LOCALAPPDATA under `work/t5_talent_polish_diagnostic` and did not run gameplay. Certificate-store warnings remain in engine logs. Final suites have no script/assertion failures. This focused polish does not close the later full accessibility/human playtesting tasks.
