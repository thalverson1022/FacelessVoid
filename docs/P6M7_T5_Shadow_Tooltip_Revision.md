# T5: Shadow tooltip revision

Current task status: **Complete — user accepted T5 under D039 on 2026-10-15.** See [closeout and accepted conventions](P6M7_T5_Closeout_And_Accepted_Conventions.md).

The dated status, proposals and evidence below are historical snapshots; later accepted conventions and D039 supersede earlier In progress/closeout-excluded instructions.

User-approved D032 presentation revision, 2026-10-14. T5 remains **In progress**; no milestone closeout.

## Current wording

Shadow's per-point bonus display omits `(primary only)`. Actual primary-only scaling, innate effects and secondary `Bonus: NONE` remain unchanged.

Skills:

- Beguiling Strike: `On hit: Apply X stacks of Decay`, using the live effective application count.
- Death Strike: removes only `Does not consume Poison.`; its base-per-Poison damage line and planning damage remain.
- Distilled Corruption: `Consume up to 5 stacks of Decay to apply up to X stacks of Poison`. Both the five-stack consumption limit and output ratio come from its effect resource. X is the full-consumption planning application maximum: effect amount times Poison-per-consumed, plus current Poison application bonuses, then application doubling. It refreshes from current resolved gear/talent stats and does not read the opponent's live Decay/Poison pool.
- Touch of Darkness: `Consume all stacks of Poison. Each stack consumed grants x10% Attack Speed and +2 Base Physical Damage`.
- Beguiling Presence: `Consume all stacks of Decay. Each stack consumed grants +1 Base Elemental Damage`. Only compact critical-chance copy is omitted; the critical bonus remains in mechanics/detailed descriptions.

Talents:

- Coated Weapons: `Stab and Heavy Slash now apply 2 stacks of Poison`, sourced from its live augment.
- Deception: x10% per rank on its actual **Elemental Damage** stat; no attack-speed stat was introduced.
- Death Touch: `Increased stacks: +X`, sourced from live +3/+6/+9 modifiers.
- Death Pact: the user clarified **Poison or Decay** and keeping mechanics unchanged. `Consuming stacks of Poison or Decay grants the same number of stacks of both Penetration and Potency.` Then `Increased duration of Penetration and Potency: Xs`, showing current total 4/5/6-second durations.
- Death Blade: `Stab can no longer apply Poison, but any application of Poison has a chance to trigger Stab.` Then `Stab trigger chance: X%`, showing plain live 40%/80% values.
- Dusk Strike: one combined rule, `+10 armor decrease per stack of Shred and when you apply Decay you also apply 1 stack of Shred`. Its generic Shred row is suppressed; the +10 comes from the live modifier.
- Shadow Mastery: `Increased Elemental Damage and Base Elemental Damage also grant Increased Physical Damage and Base Physical Damage.` Then `Percentage of Elemental converted to Physical: X%`, sourced from live rank fractions.
- Umbral Presence: `Maximum Poison stacks increased from 20 to 80`.

Active Talents inherits these current-rank rows. Neutral cream, absent talent Requires, current/Next sections and omission of Next at max remain. D029-D031 copy, detailed mechanics, both renderers, approved Shadow artwork and gear label are preserved. No gameplay/resource/save change.

## Verification

[Focused report](../project/reports/p6_m7_shadow_wording_focused/summary.json): all three suites pass. **4,771** talent assertions cover all 44 talents/140 ranks, exact Shadow copy/live values, one Dusk row, neutral/Next/max and preserved prior revisions. **748** skill assertions cover all 23 skills, exact new copy, dynamic Decay/Poison counts and actual provider refresh. **1,352** shared Active Talents/background assertions cover every positive rank plus retained role/layout/input behavior; the count decreased because Dusk now has one combined row.

The refresh checks use actual resolved stats and build/equip signals with disposable gear fixtures: base Distilled 5, +2 Increased Stacks gear gives 7, Death Touch rank 2 adds +6 for 13, and the binary double-applied-stacks affix gives 26. Palette, macro and automatic tree providers all refresh correctly in Adventure, Test Mode and Practice. The counts are also checked against the combat application's unchanged stack formula. The fixture does not modify packaged gear/resources.

[Rendered report](../project/reports/p6_m7_shadow_wording_rendered/summary.json): **66 targeted actual captures** pass. All modes cover primary/secondary Shadow; headers at 1280/1600/1920 and 125%; all eight revised talent hovers and five revised skill hovers at 1280/125%; current-rank Active Talents; and actual base/gear/talent/doubling Distilled refresh hovers showing 5/7/13/26. Umbral Presence is invested in this rendered build, so the displayed 26-stack planning application is within its 80-stack cap. Longer Mastery and Death Pact current+next text and refreshed Distilled were inspected by implementation/coordinating agents and fit fully. This is a focused revision matrix rather than a new full individual audit.

Both isolation records report unchanged sources and disposable save paths. [Before fingerprints](../work/t5_shadow_wording_before/hashes.json) and [final reconciliation](../work/t5_shadow_wording_before/final_verification.json) confirm all tracked production files match both run baselines. Active Talents implementation, both hover renderers, gear stat formatter and Shadow JPG are byte-identical to this revision's start. Shadow SHA256 remains `458fe5901d0ed4ddc5afe4003d792a4c35c92659cb51ee4addbb4108bd6b43da`; assets are separately hashed. The coordinating agent confirmed all 330 protected mechanics/resource/data files remain unchanged.

```text
python tools/p6/run_m6_closeout.py --report-name p6_m7_shadow_wording_focused --tests p6_m7_talent_hover_test p6_m7_minimal_skill_hover_test p6_m7_tree_background_active_text_test
python tools/p6/run_m6_closeout.py --report-name p6_m7_shadow_wording_rendered --visual --tests p6_m7_shadow_wording_visual
```

Reviewed examples:

- [Mastery current 40% / next 50%](../project/reports/p6_m7_shadow_wording_rendered/p6_m7_shadow_wording_visual/shadow_wording_visual/test-shadow_mastery-1280-125.png)
- [Distilled live 26-stack refresh](../project/reports/p6_m7_shadow_wording_rendered/p6_m7_shadow_wording_visual/shadow_wording_visual/test-distilled-refresh-26-1280-125.png)
- [Death Pact supported statuses and total duration](../project/reports/p6_m7_shadow_wording_rendered/p6_m7_shadow_wording_visual/shadow_wording_visual/test-death_pact-1280-125.png)
- [Death Blade core rule and chance](../project/reports/p6_m7_shadow_wording_rendered/p6_m7_shadow_wording_visual/shadow_wording_visual/practice-death_blade-1280-125.png)

Retained certificate-store/teardown warnings remain in engine logs; focused/rendered suites have no script/assertion failures. No broad combat suite or milestone closeout was performed.

## Punctuation refinement D037 (2026-10-15)

Removed only the trailing effect-text periods from Death Strike, Death Pact, Death Blade and Shadow Mastery. Shared Active Talents inherits the talent text. Both existing [focused tooltip suites](../project/reports/p6_m7_shadow_punctuation_focused/summary.json) pass with unchanged source/save isolation. Gold values, rank sections, layout and mechanics are unchanged; all 330 protected mechanics files match the retained baseline. T5 remains **In progress**.
