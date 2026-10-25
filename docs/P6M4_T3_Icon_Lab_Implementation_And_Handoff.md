# M4-T3 — Icon Lab implementation and handoff

Updated 2026-10-01. **T3 Complete: authoring tool and approved game-icon handoff.**
See [installed mapping and verification](P6M4_Icon_Assignment_Integration.md).
The original implementation record below describes the 2026-09-25 baseline;
its initial counts and pending integration statements are superseded by this update.

Open [Icon Lab](../tools/icon-lab/index.html) directly in a browser.
[Usage and maintenance](../tools/icon-lab/README.md).

## User-selected scope

The user expanded the initial skill/talent inventory to five categories, then
confirmed the exact catalog before requesting implementation:

| Category | Entries |
| --- | ---: |
| Defensive Mechanics | 11 |
| Skills | 23 |
| Talents | 44 |
| Player Buffs | 9 |
| Enemy Statuses | 5 |
| Total | 92 |

Gear, intrinsics as separate entries, general stats and interface icons are
excluded. Defense-related Armor and Resistance remain in Defensive Mechanics.
Poison, Shred, Decay, Penetration and Potency are the five Enemy Statuses.
Skill/talent/buff identities remain distinct; buffs now inherit the granting source icon.
Death Pact and Riposte do not create additional persistent player-buff entries.

## Delivered

- Standalone local browser application under `tools/icon-lab`, following Tree
  Lab's packaging and visual conventions. No install, network or server needed.
- 92 stable identities; canonical manifest IDs for skills/talents and explicit
  `defense.*`, `buff.*`, `status.*` IDs for shared mechanics.
- 24 relevant existing assets, fingerprinted from the game. Initial assignments:
  11 defensive mechanics, 10 skills and 3 enemy statuses; 68 unassigned entries.
  Draft icon hints are not misrepresented as currently used game resources.
- Search/category/tree/assignment filters; per-category coverage and M4 subset
  filter; current-game and workspace previews shown separately.
- Assign, replace, clear, restore game reference, intentional sharing, used-by
  navigation and deletion of unused imported icons. Thirty undo/redo steps.
- Batch PNG/JPEG/WebP import; content-hash deduplication; duplicate filenames
  supported. Size/dimension limits and full-batch validation protect workspace
  consistency. Imported bytes are held in the workspace, not copied into Godot.
- Actual-size previews at 22/28/32/54/58/64px, game-panel backgrounds and optional
  rank/stack/timer overlays. Assignment controls stay outside scrolling details.
- Local autosave with explicit recovery, raw-draft recovery download and graceful
  storage failure. JSON export/import includes all imported image bytes, full
  assignments, existing resource paths/hashes and catalog snapshot.
- Versioned import validation. Unsupported/mismatched catalogs, unknown entries,
  invalid references and tampered image content reject atomically.
- Read-only `inspect-export.js` produces a full verified mapping/change report.

## Export and application contract

`format: facelessvoid.icon-lab`, `schema_version: 1`. `assignments` is a complete
entity-ID-to-asset-ID map, including explicit `null` for cleared/unassigned.
Existing asset IDs are their `res://` paths. Imported IDs are `import:<sha256>`;
their image bytes, MIME, dimensions, names and byte lengths live in
`imported_assets`. Filenames are labels, never identity or filesystem targets.

Exports contain a catalog fingerprint and descriptive snapshot. Import requires
the same fingerprint; changed source catalogs need deliberate reconciliation by
stable ID. A stale file remains available for that reconciliation. Informational
`changes` and snapshot text are not trusted as assignment authority on import.

The browser decodes imported images, verifies their hashes/dimensions and uses
text-only rendering for imported names. No arbitrary URL/SVG source is accepted.
Limits: 2 MB/image, 4096×4096, 200 imported assets, 20 MB imported image bytes,
30 MB JSON. Browser storage may have a smaller quota; JSON remains the backup.

Game application remains separate: review the exported mapping, copy approved
images into a chosen game asset directory, bind `Skill.icon` or the planned
talent/effect mapping consumer, and verify the actual rendered game. T4–T7 own
those resources/consumers. No redesigned content is promoted by this tool.
The tool's catalog serves as the stable shared-effect identity list for that
handoff; repeated effect instances should look up their effect type, not invent
an icon assignment for every combat-instance ID.

## Verification

Passed 12 model/catalog checks and 12 browser acceptance groups. Browser tests
use installed Edge headlessly through Playwright with isolated profiles and a
direct `file://` URL. No real browser draft, Adventure or Practice saves touched.

- Exact counts/IDs and all 24 source asset fingerprints.
- Assignment/clear, shared icons, import removal restrictions and undo/redo.
- Same-name/different-byte distinction; same-byte duplicate reuse.
- Actual file input, image assignment, browser download and reimport round trip.
- Embedded image preservation, forged hash rejection and invalid-batch atomicity.
- Explicit saved-draft recovery after reload.
- Storage-write failure with working JSON download.
- Search/filter empty states, keyboard focus and no uncaught browser errors.
- 1280×720, 1600×900 and 1920×1080 layouts with no page-width overflow.

The rendered assigned-state screenshot was inspected; the first pass placed
assignment actions too low. The revised layout pins them above the scrolling
inspector; browser acceptance passed again afterward.

Evidence:

- [Browser summary](../tools/icon-lab/reports/browser-summary.json)
- [1280px layout](../tools/icon-lab/reports/icon-lab-1280.png)
- [1600px layout](../tools/icon-lab/reports/icon-lab-1600.png)
- [1920px layout](../tools/icon-lab/reports/icon-lab-1920.png)
- [Assigned-state layout](../tools/icon-lab/reports/icon-lab-assigned.png)
- [Test-only round-trip export](../tools/icon-lab/reports/roundtrip.json)
- [Read-only handoff report](../tools/icon-lab/reports/handoff-report.json)

The example export assigns a fixture image solely for testing; it is not a user
art decision. Default Icon Lab still starts from game references or offers the
user's own saved-workspace recovery.

Reproduce using the README commands. No Godot regression was run: production
gameplay code and game data were unchanged. Browser validation is not acceptance
of the future Godot screens.

## Original M4 dependency (resolved for icon handoff on 2026-10-01)

The user-requested authoring tool is usable now. The original T3 acceptance also
requires a representative mapping to visibly reach actual game UI. That remains
open until T4–T7 have playable resources and talent/effect consumers. T3 remains
**In progress — tool ready, in-game handoff pending**; do not claim that the whole
task or redesigned game release is complete. Icon choice/art refinement can now
proceed in the tool while integration follows the existing M4 sequence.

## 2026-09-25 — Character Class & Role pack addition

At the user’s request, copied 48 native 32×32 PNGs into Icon Lab’s local pack
library, retaining supplied README/license. The available library now has 72
assets, with a dedicated Character Class & Role source filter. No mechanics
were assigned or game resources changed. Existing saved workspaces remain
compatible because additive packs preserve the mechanics/game-reference
fingerprint. Exports record pack IDs, paths and hashes separately from manual
embedded imports. Fourteen model checks and thirteen browser groups pass.

## 2026-09-25 — Elemental pack addition

Added 48 native 32×32 Elemental PNGs with supplied README/license, bringing the
library to 120 assets. The Elemental Icons source filter shows the pack, using
source filenames as labels. Existing workspace compatibility is preserved;
no production assignments or game resources changed. Fourteen model checks and
fourteen browser groups pass, including all elemental thumbnails and assignment/undo.

## 2026-09-25 — RPG Skill Icons Vol. 2 pack addition

Added 48 native 32×32 PNGs with supplied README/license, bringing the library to 168 assets. The RPG Skill Icons Vol. 2 source filter shows the pack with source filename labels. Saved workspace compatibility is preserved. Fourteen model checks and fifteen browser groups pass, including all new thumbnails and assignment/undo. Production assignments and game resources are unchanged.

## 2026-09-25 — Pixel Spell Icons pack addition

Added the 16 extracted 32×32 spell icons as the Pixel Spell Icons source, bringing the library to 184 assets. Numbered labels retain sheet order. Supplied license and author credit are retained in the pack. Existing workspace compatibility is preserved. Fourteen model checks and sixteen browser groups pass, including all new thumbnails and assignment/undo.

## 2026-09-25 — Pixel Skill Icons 2 pack addition

Split the 128×160 sheet into twenty 32×32 PNGs (4 columns, 5 rows), preserving and verifying every RGBA pixel. Added as Pixel Skill Icons 2, bringing the library to 204 assets. Numbered labels retain sheet order; supplied license and author credit are included. Existing workspace compatibility is preserved. Fourteen model checks and seventeen browser groups pass, including all new thumbnails and assignment/undo.

## 2026-09-25 — RPG Skill Icons pack addition

Added 19 original 32×32 PNGs as RPG Skill Icons, bringing the library to 223 assets. Source filenames and image bytes are preserved, including original backgrounds. No README/license was present in the provided source folder or its immediate parent. Existing workspace compatibility is preserved. Fourteen model checks and eighteen browser groups pass, including all new thumbnails and assignment/undo.

## 2026-09-25 — Poison potion variant

Created the requested purple-background, green-liquid variant of healing potion using built-in image_gen; retained the generated master and prompt, and added a 32×32 version under Custom Variants. Original healing potion remains available. Library total: 224. Fourteen model checks and nineteen browser groups pass.

## 2026-10-01 — RPG Icon Pack Skills addition

Inspected 216 PNGs: 209 individual 32×32 icons and seven overview sheets. Skipped 22 individual icons matching existing library RGBA pixels and added the remaining 187, preserving original PNG bytes with class/number labels. Library total: 411. Existing assignments and mechanics fingerprint preserved. Fourteen model checks and twenty browser acceptance groups cover catalog integrity, new thumbnails, assignment/undo and workspace compatibility.

## 2026-10-01 — Hasten Poison variant

Created a poison droplet with green speed trails from the haste reference using built-in image_gen. Added a transparent 32×32 version under Custom Variants, preserving the original haste and generated master/prompt. Library total: 412. Fourteen model checks and twenty-one browser groups pass.

## 2026-10-01 — Precision crosshair

Created the requested Precision crosshair using built-in image_gen with Rogue pack style references. Added a transparent 32×32 version under Custom Variants, retaining the generated master and prompt. Library total: 413. Fourteen model checks and twenty-two browser groups pass.

## 2026-10-01 — Toxic Tradeoff icon

Created the requested dagger dissolving into poison using built-in image_gen and the Rogue pack style reference. Added a transparent 32×32 version under Custom Variants; master and prompt retained. Library total: 414. Fourteen model checks and twenty-three browser groups pass.

## 2026-10-01 — Sharpened Edge icon

Created the requested dagger with a blade glint using built-in image_gen and the Rogue pack style reference. Added a transparent 32×32 version under Custom Variants; master and prompt retained. Library total: 415. Fourteen model checks and twenty-four browser groups pass.

## 2026-10-01 — Weapon Master icon

Created a crossed-weapon mastery emblem using built-in image_gen and the Rogue pack style reference. Added a transparent 32×32 version under Custom Variants; master and prompt retained. Library total: 416. Fourteen model checks and twenty-five browser groups pass.

## 2026-10-01 — Whetstone display-name correction

User approved renaming Wet Stone to Whetstone. Updated design draft, identity manifest, icon inventory, generated scalar fixture, current documentation and Icon Lab catalog. Stable talent ID and resource filename remain wet_stone. Refreshed active provenance hashes. Icon Lab preserves its prior fingerprint for this exact display-only correction, so old saved assignments/exports remain valid. Historical execution reports and checkpoint hashes retain their original evidence. Identity, build-fixture, conversion, core/mixed provenance and Icon Lab checks pass.

## 2026-10-01 — Gilded Blade icon

Created the requested golden dagger using built-in image_gen and the Rogue pack style reference. Added a transparent 32×32 version under Custom Variants; master and prompt retained. Library total: 417. Fourteen model checks and twenty-six browser groups pass.
