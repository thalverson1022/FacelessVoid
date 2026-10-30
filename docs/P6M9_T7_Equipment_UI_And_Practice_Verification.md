# M9 T7 — Seven-slot equipment UI and Practice

2026-10-25. **T7 Complete under P6M9-D018.** The user explicitly approves the Adventure, Test and Practice layouts and requests completion. D017 records the implementation and scoped verification; D018 records visual acceptance. Current authority: [M9 tracker](P6M9_Gear_Slot_Expansion_And_Progression_Pacing_Tracker.md).

## Implemented layout and controls

Adventure and Test share the seven-slot equipment panel. Practice uses the same topology at its existing smaller scale:

| Column | Arrangement | Adventure/Test sizes | Practice sizes |
| --- | --- | --- | --- |
| Left | Weapon, then Gloves | 88×88; 68×68 | 78×78; 60×60 |
| Center | Helm, Chest, then Pants | 76×76; 112×112; 88×88 | 66×66; 96×96; 88×88 |
| Right | Charm above Trinket | 60×60 each | 56×56 each |

Pants are larger than Gloves. Existing inventory capacity and item actions remain. Both new slots have refresh, empty labels, equipped-reference tooltips, equip/swap/unequip, appropriate sell/destroy menus and animation/feedback destinations. Full-inventory behavior and selling restrictions retain the existing rules. The shared left-click equip helper now checks the combat build lock as the action menu does.

Practice exposes the new custom shells, six ordinary rarity plans, affix/category choices, equip state and carried-item slot selection. Pants/Gloves display labels retain their stable enum IDs. The paper-doll buttons resolve the current custom shell when clicked, so loading a setup cannot leave a button editing a detached old resource. The slot-to-button map is likewise keyed by stable slot ID.

Custom carried editing no longer inherits the same-slot equipped Legendary's read-only presentation, and cannot accidentally replace that equipped Legendary through the carried rarity selector. Long affix selections have full-label tooltips. No new Legendary identities are exposed: the active catalog remains 16, with the new-slot catalog empty until T8. No new custom Crude/Legendary generation route is introduced.

D009 remains in force: Adventure shop projected **On equip** comparisons stay hidden, while item/equipped-reference details and other-surface comparisons remain. T7 does not change the stat pools, rarity/economy rules, seven-slot IDs or T5 save epoch. Fresh Adventures still equip only Crude Dagger, Test retains Bandit Blade and 100 gold, and fresh Practice starts with all seven shells unequipped.

## Artwork boundary

`GearIcons` now uses the previously prepared gray `slot_legs.png` and `slot_hands.png` for empty backgrounds. Populated ordinary Pants/Gloves temporarily use these correct-slot silhouettes instead of the misleading generic helmet fallback. The original files/pixels are unchanged; nearest filtering preserves pixel-art presentation.

Only the two new-slot texture layers are inset 4 pixels so the existing equipped/rarity frame remains visible around the opaque provisional silhouette. Gray empty borders and colored equipped frames therefore remain distinguishable. T8 still owns the supplied six-rarity sprite sets, four new Legendary sprites and runtime effects. These renders approve no final new-slot item artwork and do not complete T8.

## Actual 1600×900 review artifacts

The parent inspected the actual rendered scenes, not a layout mockup. All thirteen PNGs are 1600×900:

| Mode | Starting state | Populated layout | Additional states |
| --- | --- | --- | --- |
| Adventure | [Crude-only fresh Adventure](../project/reports/m9_t7_visual/adventure_fresh.png) | [Seven equipped slots](../project/reports/m9_t7_visual/adventure_populated.png) | [Pants comparison](../project/reports/m9_t7_visual/adventure_pants_comparison.png), [Gloves action menu](../project/reports/m9_t7_visual/adventure_gloves_actions.png) |
| Test | [Bandit-only fresh Test](../project/reports/m9_t7_visual/test_fresh.png) | [Seven equipped slots](../project/reports/m9_t7_visual/test_populated.png) | Test remains a hidden, memory-only entry; no new menu exposure. |
| Practice | [All seven empty](../project/reports/m9_t7_visual/practice_fresh.png) | [Seven equipped slots](../project/reports/m9_t7_visual/practice_populated.png) | [Pants editor](../project/reports/m9_t7_visual/practice_pants_editor.png), [Gloves editor](../project/reports/m9_t7_visual/practice_gloves_editor.png), [Carried Gloves editor](../project/reports/m9_t7_visual/practice_carried_gloves_editor.png), [Seven-slot selector](../project/reports/m9_t7_visual/practice_carried_slot_selector.png), [Gloves hover](../project/reports/m9_t7_visual/practice_gloves_hover.png) |

[Geometry evidence](../project/reports/m9_t7_visual/geometry.json) checks all seven equipment rectangles for viewport containment, pairwise non-overlap and the required ordering/relative sizes in each of the six base states. Adventure/Test also check Gear, inventory and major dashboard panel bounds. Parent visual inspection caught an initial 4-pixel dashboard overflow; reducing Gear spacing from 10 to 8 and Pants from 100 to 88 restored the normal 16-pixel bottom margin. The final Gear panel ends at y884. Practice's lower target settings retain their existing scroll container; the entire equipment layout and Carried Gear control are visible.

Parent review also caught the initial provisional textures obscuring the equipped frame. The 4-pixel texture inset resolves that without modifying artwork. Popovers/editors fit within the inspected viewport. The user accepts the completed layouts under D018. The provisional-art boundary and retained verification limits remain in force.

Reproduction: [render runner](../work/m9_t7/render_ui.py), [isolated scene driver](../project/tests/m9_t7_visual.gd), [render console](../project/reports/m9_t7_visual/console.txt). The offscreen Godot Compatibility-renderer process uses an explicit report log, embedded popups and task-specific save paths configured before persistence access. The illustrative populated loadouts are validation fixtures; they do not change starting gear or imply a progression/balance recommendation.

## Behavioral verification and audit findings

[Final engine summary](../project/reports/m9_t7_final/summary.json): **four focused suites pass**, with recorded commands and matching final test source hashes:

- `m9_t7_ui_test`: 141 checks covering the new slot controls/actions, full inventory, combat-lock input path, Practice rarity/pool selection, carried contexts and current-shell editing after isolated save/load.
- `t3_ui_carried_gear_test`: retained carried gear/UI behavior.
- `reward_shop_route_ui_test`: retained reward/shop/comparison behavior, including the D009 boundary.
- `m9_t5_entry_test`: retained Crude-only Adventure, hidden Bandit-only Test entry and persistence isolation.

[Independent closeout verification](../work/m9_t7/verification.json) reconciles the source boundary, test hashes, all thirteen PNG dimensions/hashes and geometry cases. Runtime changes are confined to `gear_panel.gd`, `training_room.gd` and `gear_icons.gd`; source artwork, gameplay/save logic, stat pools and content resources remain unchanged. Independent source review found no remaining blocking T7 issue after the lock, carried-context and current-shell fixes.

Two supplementary legacy suites were inspected separately: [supplemental results](../project/reports/m9_t7_supplemental/summary.json). `build_panels_test` and `training_room_gear_editor_test` contain old hierarchy/catalog/flavor-text expectations, including a five-item Weapon-only catalog and superseded Bandit wording. They are not reported as passing T7 acceptance checks. Temporary edits to their topology assertions were reverted, preserving their pre-T7 contents; broader fixture reconciliation remains downstream regression work. Earlier development failures and superseded renders do not replace the final focused evidence.

[Runner isolation](../project/reports/m9_t7_final/isolation.json) fingerprints the default gameplay paths/temporaries, epoch marker and sibling project identity files. [Whole-profile audit](../work/m9_t7/protected_verification.json) compares all preexisting FacelessVoid and sibling Enigma files, including additions/deletions. Live saves/preferences and sibling data are unchanged; no live reset is performed. Test remains memory-only.

Known Compatibility-renderer shader, certificate-store and shutdown ObjectDB/resource diagnostics remain recorded. Render completion and scoped behavior checks do not qualify the engine/export environment or prove crash/power-loss durability. Practice playback-wide editing locks and other retained baseline questions were not redesigned here. T9 retains combined mechanics/reset verification; T10/T11 retain progression and user acceptance, with M10/M11 owning wider qualification.
