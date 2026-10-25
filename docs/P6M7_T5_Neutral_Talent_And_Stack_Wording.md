# T5: neutral talent effects and stack terminology

Current task status: **Complete — user accepted T5 under D039 on 2026-10-15.** See [closeout and accepted conventions](P6M7_T5_Closeout_And_Accepted_Conventions.md).

The dated status, proposals and evidence below are historical snapshots; later accepted conventions and D039 supersede earlier In progress/closeout-excluded instructions.

User-approved D029 revision, 2026-10-14. T5 remains **In progress**; no milestone closeout.

## Approved presentation

All talent effect rows temporarily use cream, including the shared current-rank rows in Active Talents. Benefits and drawbacks retain their existing order and explicit signs; neutral coloring is applied after semantic ordering. Talent hovers omit all Requires text and its UI control. Graph feedback and actual purchase gates/prerequisites remain unchanged. Current/Next rank sections and maximum-rank omission of Next rank remain intact.

Bladedancer copy now uses the requested wording:

- Weakness and Virulent Corruption: `Armor decrease per Shred stack`.
- Fancy Footwork: `Quick Cut grants 1 stack of Footwork. Footwork stacks up to 5 and lasts for 3 sec. Leaping Plunge consumes all stacks of Footwork for decreased attack time.` Then `Decreased attack time per stack: X%`, showing positive 4% per live Footwork rank.
- Precision Attacks: `Quick Cut grants Precision. Stab and Heavy Slash consume Precision to gain 100% Retrigger Chance`.
- Double Dip: `Percentage of Retrigger Chance converted to Crit Chance: X%`.
- Sharpened Edge, Riposte and Weapon Master show the user-requested `x` prefix. Values remain source-backed: Sharpened Edge x20% through x100%; Riposte x20% per rank; Weapon Master x50%/x100% from its unchanged 0.5/1.0 physical-damage modifier values.

The user clarified that `Causes the first hit of all attacks to have 100% Retrigger Chance` belongs to **Dance of Death**. Parry Strike changes only Readiness charge to stack. Virulent Poison uses 5 stacks and retains its 2x Poison damage and untimed exhaustion.

Visible charge terminology was also changed to stacks in retained detailed skill descriptions, category preview/outcomes, effect tooltip/inspector count/rules, Readiness status and macro `No stack` feedback. Runtime `charges` fields, consumption, independent instances, counters, durations and comments remain intact. Detailed Virulent text names **Increased Stacks** to distinguish the stat from the buff's stacks. Skill timing/category styling remains unchanged.

The separately approved new Shadow JPG and gear label `increased stacks` are preserved. This revision changes presentation only.

## Focused evidence

[Core focused report](../project/reports/p6_m7_neutral_talent_focused/summary.json): all four suites pass. Talent model/provider checks pass **4,661 assertions**, including all 44 talents/140 ranks, cream in both sections, no Requires text/control at any rank, retained diagnostic gate math, exact revised Bladedancer values and preserved max/Next behavior. Minimal skill hover checks pass **608 assertions**, including all 23 useful skills and exact Parry/Dance/Virulent wording. Shared Active Talents/background checks pass **1,355 assertions** across every positive rank. Existing talent allocation UI passes.

[Additional terminology report](../project/reports/p6_m7_stack_terminology_focused/summary.json): combat presentation, category preview and skill UI suites pass. Their assertions verify visible stack labels while consuming unchanged internal charge snapshots and preserving replay/readiness behavior. Both focused runs report unchanged source isolation and disposable saves.

Commands:

```text
python tools/p6/run_m6_closeout.py --report-name p6_m7_neutral_talent_focused --tests p6_m7_talent_hover_test p6_m7_minimal_skill_hover_test p6_m7_tree_background_active_text_test p6_talent_ui_test
python tools/p6/run_m6_closeout.py --report-name p6_m7_stack_terminology_focused --tests p6_combat_presentation_test p6_m7_category_preview_test p6_skill_ui_test
python tools/p6/run_m6_closeout.py --report-name p6_m7_neutral_talent_rendered_final --visual --tests p6_m7_tree_background_active_text_visual p6_m7_minimal_skill_hover_visual
```

## Rendering and source reconciliation

[Final rendered report](../project/reports/p6_m7_neutral_talent_rendered_final/summary.json) passes both existing matrices: **87** tree/Active Talents captures and **78** actual skill hovers. They cover Adventure, Test Mode and Practice at 1280/1600/1920 with normal/125% stress. The longer Fancy Footwork current+next popup at 1280/125% fits fully; Test and Practice examples were inspected, along with Virulent stack text and the neutral current-rank Active Talents list. The coordinating agent independently reviewed Fancy Footwork. Individual Parry/Dance copy is covered by exact model assertions; this matrix uses representative skill categories/surfaces rather than an individual rendered review of every changed sentence.

[Before fingerprints](../work/t5_neutral_talent_before/hashes.json) and [final reconciliation](../work/t5_neutral_talent_before/final_verification.json) distinguish this revision from prior dirty work. All final production files match the rendered baseline; original core formatter files match their focused baseline. The seven additional stack-wording files match their later terminology-suite baseline; their earlier core-run differences are expected and recorded. All three accepted isolation records report unchanged sources and disposable save paths. The renderer for skills, Active Talents implementation, stat catalog and new Shadow asset are unchanged from this revision's start; Shadow SHA256 remains `458fe5901d0ed4ddc5afe4003d792a4c35c92659cb51ee4addbb4108bd6b43da` (assets are separately hashed because the runner does not track them). The coordinating agent confirmed all 330 protected mechanics/resource/data files remain unchanged.

Reviewed examples:

- [Fancy Footwork Test, 1280/125%](../project/reports/p6_m7_neutral_talent_rendered_final/p6_m7_tree_background_active_text_visual/tree_background_visual/test-hover-bladedancer-thief-1280-125.png)
- [Fancy Footwork Practice, 1280/125%](../project/reports/p6_m7_neutral_talent_rendered_final/p6_m7_tree_background_active_text_visual/tree_background_visual/practice-hover-bladedancer-thief-1280-125.png)
- [Virulent Poison stack text](../project/reports/p6_m7_neutral_talent_rendered_final/p6_m7_minimal_skill_hover_visual/minimal_skill_hover/test-palette-virulent_poison-1280-100.png)

Retained certificate-store/teardown warnings remain in engine logs; final suites have no script/assertion errors. No broader combat regression was needed for these string/palette changes. The earlier `p6_m7_neutral_talent_rendered` batch was deliberately cancelled before adding the remaining visible stack strings; it is superseded by the final complete baseline.
