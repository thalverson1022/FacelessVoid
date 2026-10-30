# M7-T8 — Integrated UI and accessibility review

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. [Current context](../../P6_Project_Onboarding_Context.md).

2026-10-15. **Complete under D047.** The user requested executing the T8 review after [T7 closeout under D046](../../P6M7_T7_Combat_Cues_And_Audio_Verification.md). Integrated review, six bounded repairs, affected checks and parent source/visual reconciliation are complete. T1–T8 Complete; T9–T11 Not started; M7 remains In progress. This is scoped technical review, not a claim of milestone-wide user presentation acceptance.

## Coverage and capability boundaries

The main matrix covers Adventure, Test Mode and Practice at physical 1280×720, 1600×900 and 1920×1080, with normal text and diagnostic 125% text: **18 cases, 900 passing checks and 198 main PNGs**. The existing logical 1600×900 canvas scales into the physical window; metadata records both spaces. Legal dense Assassin/Shadow (43/45) and Bladedancer/Thief (32/45) builds feed actual resolver playback. Cases distribute all four trees in both roles rather than claiming every possible tree-pair combination.

| Physical size | Normal text roles | Diagnostic 125% roles | Modes |
| --- | --- | --- | --- |
| 1280×720 | Assassin / Shadow | Assassin / Shadow | Adventure, Test, Practice |
| 1600×900 | Bladedancer / Thief | Thief / Bladedancer | Adventure, Test, Practice |
| 1920×1080 | Shadow / Assassin | Shadow / Assassin | Adventure, Test, Practice |

Reviewed surfaces include HUD/status values, Active Talents and bottom scrolling, original tree/icon presentation, talent and skill hovers, keyboard talent details, effect overflow/inspector and bottom scrolling, Settings/Audio, and real resolver plus disclosed special combat outcomes. Names, rank/stack values, categories, timers, hover descriptions and inspector text supplement color. Keyboard routes use actual Tab/Enter/Escape/F1/arrow/Space events; the existing inspector's session-only reduced-motion toggle was exercised across nine mode/size cases.

**125% is diagnostic stress coverage, not a shipping global text-size setting.** Scoped overrides cover Active Talents/tree labels/buttons, structured hovers and the effect inspector. They do not certify every UI string at a global scale. Inline category/reduced-motion prototype controls remain hidden; the existing inspector toggle is supported and retained. No new global accessibility settings were inferred from this review.

## Findings repaired

| ID | Reproduced issue | Final repair |
| --- | --- | --- |
| F01 | Settings loses opener focus on Escape; Tab can reach background controls. | Keep Tab within the visible Settings/Audio controls and return focus to the opener. Actual keyboard slider adjustment and Back navigation pass, with volume restored. |
| F02 | Active Shred/block/dodge/crit-negation numbers use low-contrast dark red. | A label-only warning foreground changes from `8A2E2E` to `F28E86`. Original icons, red fills, health bars and global palette roles remain unchanged. |
| F03 | Wide crit-negation text extends beyond the stage during scale/pivot animation. | Placement reserves visible bounds at both 0.92× and 1.35× scale endpoints, including centered-pivot translation. |
| F04 | Enlarged Active Talents header widens the sidebar and clips the right panels. | The existing heading wraps instead of imposing its unbroken minimum width. Full title/counter remain visible; normal text may also wrap with a wide points counter. |
| F05 | A wide Practice outcome label overlaps Fight/Combat Log despite remaining stage-contained. | Register the actual action row and constrain normal outcome lanes above its live footer boundary. Accepted actors, ghosts and right-side Poison placement remain fixed. |
| F06 | Settings gear keyboard focus is visually identical to its normal fill/border. | Add a transparent, expanded cream outline that changes the visible ring geometry; the normal gear appearance remains. |

Parent independently reproduced F05 and F06 during image/source review. Footer validation now checks actual button intersection and lane separation at four punch/rise samples per case; stage containment alone is not accepted as sufficient.

Active full-opacity warning numbers were checked on actual screen backgrounds in all three modes. Measured contrast improves from approximately **2.31:1 to 8.27:1** in Test/Adventure and **2.01:1 to 7.21:1** in Practice. These are contextual sRGB measurements, not whole-game WCAG certification. Intentionally inactive states and accepted faded ghost labels are distinguished from active informational numerals.

## Evidence and verification

- [Capture matrix and provenance](../../../project/reports/p6_m7_t8_evidence/capture_matrix.json): main 18 cases plus focused final supplements. **Earlier main Practice mixed-popup frames are superseded by the final footer batch.** Other unchanged surfaces retain their main-matrix evidence; not every image claims the same whole-source revision.
- [Main integrated run](../../../project/reports/p6_m7_t8_final2/summary.json): 900 checks pass, 198 captures.
- [Final Practice footer run](../../../project/reports/p6_m7_t8_footer_final/summary.json): six size/font cases, 216 checks and 24 PNGs; live button exclusion and pairwise lane clearance pass.
- [Supplement and focused results](../../../project/reports/p6_m7_t8_evidence/focused_passes.json): six distinct affected suites pass (Settings, HUD, labels, shared presentation, Practice view, tree/Active Talents), with affected reruns after final fixes. Actual engine tooltip-window checks contribute 36 checks/12 PNGs; ghost/Poison and real inspector-toggle coverage contributes nine cases/18 PNGs. Contrast and gear-focus captures complete the 257-image referenced evidence set.
- [Contrast samples](../../../project/reports/p6_m7_t8_evidence/contrast.json), [findings and diagnostic dispositions](../../../project/reports/p6_m7_t8_evidence/findings.json), [frozen sources](../../../project/reports/p6_m7_t8_evidence/manifest.json), [preservation/isolation](../../../project/reports/p6_m7_t8_evidence/verification.json), [parent reconciliation](../../../work/t8_before/parent_review.json).

Representative parent-reviewed final views:

- [Normal 1280 HUD/header](../../../project/reports/p6_m7_t8_final2/p6_m7_t8_integrated_test/integrated/test_1280_100_hud.png) and [125% header stress](../../../project/reports/p6_m7_t8_final2/p6_m7_t8_integrated_test/integrated/test_1280_125_hud.png).
- [Practice 1920 enlarged inspector](../../../project/reports/p6_m7_t8_final2/p6_m7_t8_integrated_test/integrated/practice_1920_125_inspector.png) and [1600 skill hover](../../../project/reports/p6_m7_t8_final2/p6_m7_t8_integrated_test/integrated/practice_1600_125_skill_hover.png).
- [Final Practice 1280 footer clearance](../../../project/reports/p6_m7_t8_footer_final/p6_m7_t8_footer_visual/footer/practice_1280_125_40.png), [active warning counters](../../../project/reports/p6_m7_t8_final2/p6_m7_t8_contrast_visual/contrast/practice_active.png), and [Settings keyboard focus](../../../project/reports/p6_m7_t8_gear_final/p6_m7_t8_settings_focus_visual/settings_focus/gear_tab_focus.png).

The parent rehashed all 572 manifest entries, checked isolated Godot-source equality and independently rehashed all 1,341 protected asset/data/system/resource/autoload paths. Five existing runtime files changed; original artwork, combat rules and protected paths remain unchanged. Captured non-log saves/configuration match their baseline. Of 1,254 userdata paths, 1,253 match and one old FacelessVoid log is missing/rotated, with no verified attribution; this is explicitly not all-userdata hash equality. A probe confirms Godot's userdata directory and Audio settings output are inside isolated scratch APPDATA. No real player data was restored or overwritten. No commit or publication was requested/performed.

## Limits and T9 handoff

The ten-effect inspector density, guaranteed-retrigger geometry and special crit-negation/gold outcomes include disclosed diagnostics; legal builds and resolver playback are covered separately. Earlier fixture/coordinate failures are preserved and superseded, with no mechanics expectations altered to conceal them. Existing certificate/resource-exit warnings remain M9; historical autosave/six-signature exceptions retain prior dispositions.

This review samples M7-relevant tree/Settings/effect overlays and integrated combat surfaces; it does not certify every legacy map/shop/reward flow, every tree-pair combination, screen readers, controller hardware or all color-vision conditions. It retains accepted original icons and color vocabulary, with text/rank/count/category alternatives assessed in the selected surfaces. No supported global enlarged-text setting is claimed.

**T9 is next:** collect representative user playtests with revision, build/ranks, gear/gold, macro, seed/checkpoint, route/tag choices and retry outcome as applicable. Classify comprehension/presentation defects separately from balance concerns and intentional counters. Further agreed refinement and milestone-wide user acceptance belong to T10; broad final regression/closeout remains T11.
