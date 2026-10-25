# T5: Thief tooltip revision

Current task status: **Complete — user accepted T5 under D039 on 2026-10-15.** See [closeout and accepted conventions](P6M7_T5_Closeout_And_Accepted_Conventions.md).

The dated status, proposals and evidence below are historical snapshots; later accepted conventions and D039 supersede earlier In progress/closeout-excluded instructions.

## Copy refinement D034 (2026-10-15)

Removed trailing periods from Steal, Mug, Pick Pocket, Fast Hands and Fill Your Pockets. Bribery now begins with `Stealing gold applies Shred`; Finders Keepers begins with `Enemies start with less block`. Their current scaling lines remain, and Next rank shows only the changing values. Silvered Edge now says `Gold stolen in combat grants +1% crit chance`. Gilded Blade has a separate `max: +500%` value row. Shared Active Talents inherits these talent rows, with the existing gold values and spacing retained.

Both existing [focused tooltip suites](../project/reports/p6_m7_thief_copy_cleanup_focused/summary.json) pass. The updated narrow [Thief render fixture](../project/reports/p6_m7_thief_copy_cleanup_rendered/summary.json) passes 45 captures across Adventure, Test and Practice, including enlarged text, all revised talent descriptions and the three skill punctuation changes. Gilded Blade's separate cap, Bribery/Finders/Silvered Edge current/Next and actual Steal hover were visually inspected. Both isolation reports are unchanged; all 330 protected mechanics files match the retained baseline. T5 remains **In progress**.

Earlier sections below retain the original D030 evidence.

User-approved D030 presentation revision, 2026-10-14. T5 remains **In progress**; no milestone closeout.

## Current wording

The tree header and Active Talents share a presentation-only Thief innate helper: `x10% Increased Gold`, derived from the unchanged live 0.1 modifier. The primary tree's separate per-point line remains `+2% Increased Gold per invested point`, with the requested `(primary only)` suffix removed for Thief. An actual secondary Thief still shows `Bonus: NONE`; role behavior and primary-only scaling remain unchanged.

- Mug: `+1 base physical damage per gold stolen in combat.`
- Pick Pocket: retains Cooldown, removes only Duration. Its current-build theft amount and category/cast remain.
- Big Score: `Critical hits from this skill are increased by 6x`, derived from its live skill critical-damage factor.
- Keen Eye: x2% per rank for both physical and elemental damage; Sticky Fingers: x10% per rank Increased Gold.
- Fill Your Pockets: `Magic Find also grants Increased Elemental Damage.` followed by `Percentage of Magic Find converted to Elemental Damage: X%` (20% per live rank).
- Fast Hands: `Increased Gold also grants Increased Attack Speed.` followed by `Percentage of Increased Gold converted to Attack Speed: X%` (10% per live rank).
- Gilded Blade: `Gain +1% Critical Damage per 1 gold in your stash (maximum of +500%)`.

Conversion values use plain percentages; Charisma and Loaded Dice retain additive values. Active Talents inherits the current-rank talent copy. Neutral cream effects, no Requires text, Next rank sections and omission of Next at maximum remain intact. The new Shadow image and increased-stacks gear label are preserved. No combat/resource/save changes.

## Verification

[Focused results](../project/reports/p6_m7_thief_wording_focused/summary.json): all three affected suites pass. **4,716** talent assertions cover all 44 talents/140 ranks, exact source-backed Thief percentages/copy, x10% intrinsic, additive +2% primary-point display, secondary Bonus: NONE and retained neutral/Next/gate behavior. **609** skill assertions cover all 23 skills, exact Mug/Big Score copy and Pick Pocket's absent Duration with retained Cooldown. **1,356** shared Active Talents/background assertions include every positive rank plus its shared Thief intrinsic.

[Rendered results](../project/reports/p6_m7_thief_wording_rendered/summary.json): **33 actual captures** pass. Adventure, Test Mode and Practice cover primary/secondary Thief roles; header rendering at 1280/1600/1920 with 125% text; current+next Fast Hands/Fill Your Pockets, max Gilded Blade, Active Talents and actual Pick Pocket/Mug/Big Score hovers at 1280/125%. Representative long conversion lines and timing fields were inspected by implementation/coordinating agents and fit fully. This is a narrow revision matrix, not a fresh all-skill visual audit.

Both accepted runs report unchanged source isolation and disposable save paths. [Pre-change fingerprints](../work/t5_thief_wording_before/hashes.json) and [final reconciliation](../work/t5_thief_wording_before/final_verification.json) show all tracked production files match both run baselines. Talent/skill renderers, stat catalog and Shadow JPG remain byte-identical to this revision's start; Shadow SHA256 remains `458fe5901d0ed4ddc5afe4003d792a4c35c92659cb51ee4addbb4108bd6b43da`. Assets are separately hashed because runner baselines omit them. The coordinating agent confirmed all 330 protected mechanics/resource/data files remain unchanged.

```text
python tools/p6/run_m6_closeout.py --report-name p6_m7_thief_wording_focused --tests p6_m7_talent_hover_test p6_m7_minimal_skill_hover_test p6_m7_tree_background_active_text_test
python tools/p6/run_m6_closeout.py --report-name p6_m7_thief_wording_rendered --visual --tests p6_m7_thief_wording_visual
```

Reviewed examples:

- [Fast Hands current/next and primary intrinsic](../project/reports/p6_m7_thief_wording_rendered/p6_m7_thief_wording_visual/thief_wording_visual/adventure-fast_hands-1280-125.png)
- [Fill Your Pockets 80%/100% at 125%](../project/reports/p6_m7_thief_wording_rendered/p6_m7_thief_wording_visual/thief_wording_visual/practice-fill_your_pockets-1280-125.png)
- [Pick Pocket Cooldown without Duration](../project/reports/p6_m7_thief_wording_rendered/p6_m7_thief_wording_visual/thief_wording_visual/test-pick_pocket-1280-125.png)
- [Thief secondary with Bonus: NONE](../project/reports/p6_m7_thief_wording_rendered/p6_m7_thief_wording_visual/thief_wording_visual/test-thief-secondary-1280-125.png)

Retained certificate-store/teardown warnings remain in logs; no script/assertion failures occurred. No broad combat suite or milestone closeout was performed for this presentation change.
