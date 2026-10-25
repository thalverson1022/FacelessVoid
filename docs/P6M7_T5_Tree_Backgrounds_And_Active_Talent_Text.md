# T5: subclass tree backgrounds and current-rank Active Talents

Current task status: **Complete — user accepted T5 under D039 on 2026-10-15.** See [closeout and accepted conventions](P6M7_T5_Closeout_And_Accepted_Conventions.md).

The dated status, proposals and evidence below are historical snapshots; later accepted conventions and D039 supersede earlier In progress/closeout-excluded instructions.

User-approved D028 implementation, 2026-10-14. T5 remains **In progress**; this records the requested presentation change and verification, without milestone closeout.

## Implementation

Copied the four original 848x1264 JPGs from `F:/Data/Junk/DPS Game/Finished Game Assets/` into `project/assets/ui/tree_backgrounds/`: Assassin, Bladedancer, Shadow and Thief. Each packaged copy has the same SHA256 as its original; no source bitmap was edited. Stable `tree.*` IDs select the artwork, so it follows either role and role swaps in Adventure, Test Mode and Practice. The empty secondary panel retains its existing appearance.

`talent_tree_backdrop.gd` draws behind the whole inner tree panel, including padding, with proportional cover cropping and a runtime 65% black overlay. Its shader masks the inner rounded corners using the existing frame border widths. The decorative node is a Node2D, so texture dimensions cannot enter container minimum sizing and it cannot intercept Control input. The gold frame, content layout, graph coordinates, button targets and allocation behavior are retained. All four images remained at 65% after rendered contrast review.

Active Talents now uses the same `talent_hover_formatter.rank_rows()` and `row_text()` as the hover's current-rank effects. Every displayed row uses the shared cream/yellow/violet semantic color at the existing 13px size. Names/ranks and subclass portraits remain; no individual talent icons, Next rank, Requires or repeated header are added. This covers all 44 talents and 140 positive ranks, including the special rules previously missing from modifier-only summaries. The existing legacy summary fallback is retained.

The skill and talent hover formatter/panel files are byte-identical to this step's pre-change fingerprints. Their separate Next rank/max behavior, Retrigger keyword and Attack versus Debuff/Self Buff timing conventions are retained. No combat math, resource values or save behavior changed.

## Verification

- New focused suite passes **1,355 checks**: all 140 current-rank row texts/colors, legacy fallback, four assets, proportional cropping, all modes/roles, empty secondary, geometry/minimum-size equality with and without the backdrop, and actual hover/click allocation input. [Focused report](../project/reports/p6_m7_tree_background_focused/summary.json).
- Existing `build_panels_test` and `p6_talent_ui_test` both pass against the same final production hashes, without assertion changes. [Existing-suite results](../project/reports/p6_m7_tree_background_first/summary.json).
- Actual rendered matrix passes **87 captures**, covering all four trees, Adventure/Test/Practice, 1280/1600/1920 widths, normal and 125% text, dense mixed builds/locked nodes, live hover, swapped roles and empty secondary. [Final rendered report](../project/reports/p6_m7_tree_background_rendered_v2/summary.json). Representative images were inspected by the implementation and coordinating agents: subtle artwork, intact borders, readable text and unblocked hover were confirmed.
- Final focused and rendered isolation records report unchanged source files and disposable save directories. All eight production/hover fingerprints match the first, focused and final visual run baselines. All four original/copy image hashes still match. [Before fingerprints](../work/t5_tree_background_before/hashes.json), [copy hashes](../work/t5_tree_background_before/asset_copy_hashes.json), [final reconciliation](../work/t5_tree_background_before/final_verification.json). The coordinating agent independently confirmed all 330 protected mechanics/resource/data files remain unchanged.

Commands:

```text
python tools/p6/run_m6_closeout.py --report-name p6_m7_tree_background_first --tests p6_m7_tree_background_active_text_test build_panels_test p6_talent_ui_test
python tools/p6/run_m6_closeout.py --report-name p6_m7_tree_background_focused --tests p6_m7_tree_background_active_text_test
python tools/p6/run_m6_closeout.py --report-name p6_m7_tree_background_rendered_v2 --visual --tests p6_m7_tree_background_active_text_visual
```

New texture import used Godot's headless editor with APPDATA/LOCALAPPDATA redirected to `work/t5_tree_import_userdata`; test runners used disposable scratch projects and saves. No real player save paths were used.

## Reviewed rendered samples

- [Adventure Assassin/Shadow, 1280](../project/reports/p6_m7_tree_background_rendered_v2/p6_m7_tree_background_active_text_visual/tree_background_visual/adventure-trees-assassin-shadow-1280-100.png)
- [Test Bladedancer/Thief, 1280 at 125%](../project/reports/p6_m7_tree_background_rendered_v2/p6_m7_tree_background_active_text_visual/tree_background_visual/test-trees-bladedancer-thief-1280-125.png)
- [Dense current-rank Active Talents](../project/reports/p6_m7_tree_background_rendered_v2/p6_m7_tree_background_active_text_visual/tree_background_visual/test-active-assassin-shadow-1280-100.png)
- [Practice Bladedancer/Thief, 1920](../project/reports/p6_m7_tree_background_rendered_v2/p6_m7_tree_background_active_text_visual/tree_background_visual/practice-trees-bladedancer-thief-1920-100.png)

## Shadow artwork refresh (2026-10-14)

Replaced the packaged Shadow JPG with the user's updated `Shadow_Background.jpg` from the same source folder and reimported it in Godot. The source and packaged copy both have SHA256 `458fe5901d0ed4ddc5afe4003d792a4c35c92659cb51ee4addbb4108bd6b43da`. Earlier image fingerprints above describe the original implementation; this fingerprint records the replacement. The existing 65% overlay and cropping remain suitable after inspecting the actual tree panel and enlarged hover. The existing 87-capture visual suite passes with isolated saves and unchanged script/data sources: [refresh report](../project/reports/p6_m7_shadow_background_refresh/summary.json).

## Diagnostics and limits

The initial new focused fixture preloaded the HUD before the isolated singleton rewrite and failed with `BuildState` unresolved; runtime loading corrected that fixture. The initial visual fixture failed String inference before rendering; an explicit String annotation corrected it. These failures remain in their initial reports and do not represent runtime failures in the final implementation. Existing certificate-store/teardown warnings are retained in engine logs. The final suites have no script/assertion errors. This matrix verifies the approved artwork/text change; it does not close later accessibility or human playtesting tasks.
