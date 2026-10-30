# T9 tooltip and buff display cleanup

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. [Current context](../../P6_Project_Onboarding_Context.md).

Decision P6M8-D092, 2026-10-25. User requested consistent new stat tooltips, removal of the confusing red “+1 more” display and shorter shop comparison text. Implemented for review; T9 remains Pending input and T10 In progress.

## Presentation changes

- New ordinary item affixes use the shared short format, e.g. `+15% Cooldown Reduction`, `+15% Increased Buff Duration`, `+15% Crits Apply Potency`. Removed fixed four-decimal values and internal factor/aggregation/contribution explanations. Character Stats uses the same whole-percent precision and canonical labels as existing rows.
- The red counter was an overflow inspector button after four player buff types. Every active buff type now appears in four-icon rows, retaining artwork, stack counts, countdowns and click/keyboard access to the full effect inspector. Independent same-type instances remain grouped. Returning from the inspector restores chip focus.
- Shop comparison retains the adjacent equipped item card and resolved before/after values under `On equip:`. Numbers trim unnecessary decimals; labels are readable for every rarity. Removed ownership/resale explanations, current-gold assumption prose and repeated signature/effect paragraphs. Item effects and granted skills remain available on their normal cards. Full build resolution, carried-gear removal, replacement resale, current-gold inputs and live Legendary conversions are preserved.

## Verification

Disposable copies and isolated saves only: [manifest](../../../work/m8_t9_presentation/d092_verification.json), group `work/m8_t9_presentation/ui_cleanup_d092`.

- Item presentation: 456 checks across all 16 Legendaries.
- Actual UI review: 72 checks, 20 rendered screenshots.
- New cleanup visual review: 19 checks, six rendered screenshots at 1280×720. Inspected five- and twelve-buff Adventure/Practice layouts, ordinary new-affix tooltip and stat panel; no overflow or red counter. Inspected the actual Signet/Locket shop comparison.
- Carried-gear comparison and shop-route suites pass. Effect-display suite passes 54 headless cross-mode/font cases, including inspector keyboard activation, focus return, expiration, skip and mode exit.
- Combat presentation suite exits zero with its explicit `T7 presentation checks complete` marker and no failed assertions. The generic runner reports false because this legacy suite has no literal PASS marker; manually inspected its console.
- Legacy Practice gear-editor suite still expects a five-item, weapon-only Legendary catalog (line424). Reproduced on pre-change source in `ui_cleanup_d092_baseline`; broader roster migration is outside this cleanup. Its Potency row expectation was updated, but this suite is not claimed passing. Carried-gear test also had an obsolete fixed-affix widget assertion; updated to the existing read-only Legendary details surface.

Certificate-store and shutdown resource diagnostics remain visible in evidence. The new visual harness emits 20 ObjectDB /14 resource shutdown diagnostics; an otherwise equivalent old-source diagnostic run reproduces those counts (assertions disabled only in that diagnostic copy, never in verification). This baseline is diagnostic evidence, not a behavior pass.

Ten existing project files changed (five presentation files and five tests), plus one new visual test. All 2,400 other pre-existing project files are hash-identical, including mechanics, resources, loot, save systems and artwork. No real saves accessed or production game launched. No balance or acquisition rules changed.

## Review captures

- [New stat affixes](../../../work/m8_t9_presentation/ui_cleanup_d092/project/reports/t9_ui_cleanup/new_stat_affixes.png)
- [Twelve buffs in Practice](../../../work/m8_t9_presentation/ui_cleanup_d092/project/reports/t9_ui_cleanup/practice_buffs_12.png)
- [Shop comparison](../../../work/m8_t9_presentation/ui_cleanup_d092/project/reports/t9_ui_review/adventure_signet_comparison.png)
