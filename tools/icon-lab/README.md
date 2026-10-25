# Icon Lab

Open **[index.html](index.html)** directly in a desktop browser. No installation,
server, internet access or Godot process is required. Uses the same standalone
HTML/CSS/JavaScript approach as Tree Lab.

## Scope

93 stable identities: 11 Defensive Mechanics, 23 Skills, 44 Talents, 10 Player
Buffs and 5 Enemy Statuses. Gear and general interface icons are excluded.
Nine buffs share the icon of their granting skill or talent; Greed retains its dedicated gold icon. Editing a buff also updates its source; importing older workspaces normalizes these links.

The library contains 585 images: 417 retained game, purchased and custom assets,
84 previous assigned originals, and 84 installed flat-charcoal icons. All 93 current game references
are assigned. Use the Source filter to browse packs or Assigned game icons.
The catalog reflects the live Phase 6 identities. Historical talent draft prose is hidden;
full player-facing wording review belongs to M7-T5.

## Assign and import

1. Search/filter the mechanics list by category, tree or assignment status.
2. Select an entry. Its current game image and workspace assignment are separate.
3. Select a library thumbnail. Inspect 22/28/32/54/58/64-pixel previews, backgrounds
   and rank/stack/timer overlays. Scroll the center details to reach previews.
4. Click **Assign selected icon**. Clear an assignment or use its game reference
   with the corresponding buttons. Multiple entries can intentionally share art.
5. **Import icons** accepts multiple PNG/JPEG/WebP images. They stay embedded in
   this workspace, not automatically copied into the game folder. Equal bytes
   reuse an icon; equal filenames with different bytes remain separate assets.
6. **Used by** lists entries sharing the selected asset. Unused imported icons
   can be removed. Undo/redo includes assignments, imports and removals (30 steps).

Limits: 2 MB per image, 4096×4096 maximum dimensions, 200 imported images and
20 MB of imported bytes per workspace. SVG and animated formats are not supported.
JSON import is limited to 30 MB. Imported images are decoded and checked against
their SHA-256 fingerprints; a failed batch/import leaves the workspace intact.

## Save, restore and export

Applied changes autosave to this browser when storage permits. On reopening,
**Restore workspace** explicitly recovers the saved draft. Pending recovery is
not overwritten by edits. Saved raw data can be downloaded even if restoration
fails. Starting from the current workspace requires confirming replacement.

Browser storage quotas and file-URL storage behavior vary. If autosave fails,
the tool displays an export warning and editing remains usable. Export regularly:
browser storage is not a portable backup. JSON can be larger than the browser's
storage quota because imported images are embedded.

**Export JSON** requests `icon-lab-workspace.json` as a browser download. It
contains every assignment, all imported image bytes, existing game paths and
fingerprints, a descriptive catalog snapshot and a changes summary. Unassigned
is explicit `null`. **Import workspace** validates the entire file and restores it
atomically, with a replacement confirmation and Undo support.

Adding bundled packs preserves the mechanics/game-reference fingerprint, so older drafts and exports still load. A separate library fingerprint and pack paths record the expanded assets. Bundled packs do not consume the 200 manual-import allowance.

The frozen 92-entry fingerprint is explicitly supported: its exact identity set migrates
by adding the current Greed icon, preserving assignments, imported bytes and explicit clears.
Modern workspaces must contain all 93 identities. Other fingerprints remain rejected. A changed source catalog
needs deliberate reconciliation by stable ID; mismatched workspaces are rejected
without losing their file or the current draft. Keep the export for that handoff.
This prevents quietly applying stale identities or changed game assets.

## Game handoff

Send the exported JSON back to the project maintainer/assistant. It is the full
assignment state, including any newly imported art. For a read-only report:

```powershell
node tools/icon-lab/inspect-export.js path/to/icon-lab-workspace.json
```

The inspector validates IDs and asset fingerprints and reports all mappings and
changes. It never writes to game resources or saves. Applying the export is a
separate operation: copy approved embedded images into the game's icon assets,
bind skill icons or the planned talent/effect lookup, then verify the actual
Godot screens. Existing mappings, cleared mappings and new imported mappings are
all explicit. Assigning an icon must never promote gameplay content.

The approved assignment handoff is now installed. See the
[integration report](../../docs/P6M4_Icon_Assignment_Integration.md) for game
consumers, naming, buff links and verification. Import
[installed_icons.json](approved/installed_icons.json) for the exact installed
workspace; the original user export and frozen source catalog are preserved
under `approved/`. Your browser draft is not overwritten automatically.

Reproduce the approved game assets with `python tools/icon-lab/install-approved-icons.py`
(Pillow required), then run `node tools/icon-lab/build-data.js`. This replays the
approved inputs; future exports require review before installation. Gameplay
content availability is separate from icon coverage.

## Maintain and verify

`build-data.js` derives identities/descriptions from the manifest/drafts, current
skill references from Godot resources and reviewed shared-mechanic entries from
its explicit catalog. It fingerprints every bundled icon. The generated script
avoids browser JSON fetch restrictions for direct file opening.

```powershell
node tools/icon-lab/build-data.js
node tools/icon-lab/build-data.js --check
node tools/icon-lab/run_checks.js
node --check tools/icon-lab/app.js
```

Dev-only browser acceptance uses an available Playwright installation:

```powershell
# Point NODE_PATH at your installed Playwright package directory if necessary.
node tools/icon-lab/ui_checks.js
```

The default browser is installed Microsoft Edge in headless mode; set
`ICON_LAB_BROWSER=chrome` for installed Chrome. Tests use isolated profiles and
generated files in `reports/`, never your actual browser draft or game saves.
Screenshots cover 1280×720, 1600×900 and 1920×1080. `reports/roundtrip.json` is a
test fixture export, not an approved art assignment.

Files: `index.html`, `styles.css`, `app.js` (UI); `model.js` (state/validation);
`data/catalog.json`, `data/bundle.js` (generated catalog); `inspect-export.js`
(read-only handoff); `run_checks.js`, `ui_checks.js` (checks).

## Purchased pack added 2026-09-25

`assets/packs/48-character-class-role-icons/` contains the 48 original native
32×32 PNGs and the supplied README/license. Labels retain the source numbers
(Class & Role 01–48); no guessed class names or mechanic assignments were made.
Pack references in exports include stable IDs, local library paths and hashes;
manual imports remain embedded. This is a local project authoring library.

`assets/packs/48-elemental-icons/` contains the 48 original native 32×32 PNGs
and supplied README/license. Labels follow the source filenames. Select
**Elemental Icons** in the Source filter to browse this pack.

Updated checks: 15 model/catalog checks and 26 browser acceptance groups pass,
including pre-pack workspace compatibility, all seven purchased packs' thumbnails and pack
assignment/undo.


The RPG Skill Icons Vol. 2 pack is stored in `assets/packs/48-rpg-skill-icons-vol-2/` with its supplied README/license. Select **RPG Skill Icons Vol. 2** in the Source filter; labels follow source filenames.


The **Pixel Spell Icons** source contains 16 tiles extracted from the original 4×4 sheet, numbered left-to-right, top-to-bottom. Stored in `assets/packs/pixel-spell-icons/` with supplied README/license. Icons by Andrey Kalyuzhnyy (Antahonist), https://antahonist.itch.io/.


The **Pixel Skill Icons 2** source contains 20 tiles extracted from the 128×160 sheet (4 columns, 5 rows), numbered left-to-right, top-to-bottom. Stored in `assets/packs/pixel-skill-icons-2/` with supplied README/license. All RGBA pixels verified against the source. Icons by Andrey Kalyuzhnyy (Antahonist), https://antahonist.itch.io/. The supplied README describes 16 icons; the actual sheet contains 20.


The **RPG Skill Icons** source contains 19 original 32×32 PNGs from `rpg_skill_icons/rpg_skill_icons`, stored in `assets/packs/rpg-skill-icons/`. Source filenames, pixels and backgrounds are preserved. No README/license file was supplied in that source folder or its immediate parent.


**Custom Variants** includes `poison potion`: an AI-edited healing potion with purple background and green liquid. The original is preserved; the generated master and exact prompt are retained under assets.


**RPG Icon Pack - Skills** adds 187 individual 32×32 icons labeled by source class and number. Comparison used decoded RGBA pixels against the existing library: 22 duplicate icons were skipped, along with seven overview sheets. Search Archer, Druid, Mage, Paladin, Priest, Rogue or Warrior to narrow the pack. The full source-to-library audit is in `reports/rpg-icon-pack-skills-audit.json`.


**Hasten Poison** is available under Custom Variants: a green poison droplet with mint/lime speed trails, derived from haste using built-in image_gen. Master and exact prompt are retained alongside the 32×32 transparent library icon.


**Precision** is available under Custom Variants: a steel-blue crosshair created with the purchased Rogue pack as a style reference. Transparent 32×32 icon, generated master and exact prompt are retained.


**Toxic Tradeoff** is available under Custom Variants: a steel dagger dissolving into green poison, generated using the Rogue pack as a style reference. Transparent 32×32 icon, generated master and exact prompt are retained.


**Sharpened Edge** is available under Custom Variants: a steel dagger with a bright glint on the cutting edge, generated using the Rogue pack style reference. Transparent 32×32 icon, generated master and exact prompt are retained.


**Weapon Master** is available under Custom Variants: crossed steel weapons with gold accents, generated using the Rogue pack style reference. Transparent 32×32 icon, generated master and exact prompt are retained.

The approved Wet Stone → Whetstone display-name correction preserves the stable talent ID and workspace fingerprint; older drafts/exports continue to load. New exports use Whetstone in catalog display text.


**Gilded Blade** is available under Custom Variants: a golden dagger generated using the Rogue pack style reference. Transparent 32×32 icon, generated master and exact prompt are retained.

## M7-T4 candidate review

[Comparison](proposals/m7-t4/comparison.png) and [portable candidate workspace](proposals/m7-t4/workspace.json) contain five proposed refinements. The five refinements and Flat charcoal treatment were approved under P6M7-D018; the proposal remains historical evidence. Exact prompts, generated masters, normalized 32px assets and hashes accompany the proposal. See [T4 status](../../docs/P6M7_T4_Icon_Production_And_Integration.md).

## Approved flat-charcoal installation

`python tools/icon-lab/install-approved-icons.py` replays the frozen original export, applies the five hash-verified overrides in `approved/m7-t4/treatment.json`, and generates separate opaque 32px tiles in `project/assets/ui/assigned_flat/`. Every tile uses #28282b backing, a #5e5d61 one-pixel border and one-pixel inset. Original art and approved exports remain intact; reruns always start from source art, so framing cannot accumulate.

Import [the current installed workspace](approved/m7-t4/installed_icons.json) to match the game exactly. Both the frozen 92-entry catalog and the pre-framing 93-entry catalog are explicitly supported; existing draft choices and explicit clears remain intact. The library retains previous asset paths. Later individual icon refinements accompany M7-T5 tooltip review.
