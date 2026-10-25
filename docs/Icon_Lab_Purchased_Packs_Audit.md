# Icon Lab purchased-pack audit

Date: 2026-09-25. Source: `F:\Data\Junk\DPS Game\Purchased Sprites\New Icon Packs`.
Read-only source audit; no purchased assets copied, converted or assigned.

Inspected 18 packs and decoded all 4,434 PNG files without errors. PNG totals
include alternate resolutions, upscales, atlases, palettes and promotional images;
they are not unique icon counts. Checked representative pack previews and original
images, plus per-file dimensions, bytes, transparency and hashes for the shortlist.

## Best direct additions: 208 transparent individual PNGs

| Pack | Source subfolder | Count | Fit |
| --- | --- | ---: | --- |
| 48-combat-damage-icons | `png_32` | 48 | Defensive mechanics and physical talents: block, parry, dodge, armor, absorb, riposte, expose, sunder, etc. |
| 48-rpg-skill-icons-vol-2 | `png_32` | 48 | Attacks, stealth, poison cloud, haste, parry, lunge, smoke bomb, cleanse and other skills/buffs. |
| spell-ability-icons | `png_32` | 64 | Combat, shadow, support and status symbols. |
| 48-elemental-icons | `png_32` | 48 | Poison, corruption, curse, acid, smoke, time and shadow imagery; some elements are less relevant to Rogue content. |

All 208 are separate 32×32 PNGs with actual transparent pixels, totalling
280,100 bytes (about 274 KiB). No slicing or conversion is required. The first
three packs provide a focused 160-icon starting set; elemental imagery adds 48.
These are available artwork candidates, not 208 new gameplay entities or automatic
assignments. Names from an asset pack do not authorize corresponding mechanics.

The packs also include native `png_64` alternatives. They are useful for the
58/64px macro and inspection previews; the spell pack explicitly states its 64px
version has separately prepared detail. Choose one base resolution per initial
library entry, or label variants clearly. Do not indiscriminately add `_x4` and
`_x8` copies as new icon concepts. Keep original PNGs/pixel art intact.

## Directly loadable, but review the background treatment: 39

| Pack | Source subfolder | Count | Finding |
| --- | --- | ---: | --- |
| Rogulite icon pack | `Rogulite icon pack/PNG_icons` | 20 | Strong status/buff candidates. Actual files are 128×128 and all are fully opaque, despite README claims of transparent 32px images. Purple backgrounds are visible in inspected art. |
| rpg_skill_icons | `rpg_skill_icons` | 19 | Individual 32×32 images. Five have transparent pixels; fourteen are fully opaque, often with a baked-in tile/background. Includes shield block, stealth, lockpick and void blade. |

These import without preprocessing if their backgrounds are acceptable. Do not
automatically remove background colors: they may also occur inside the artwork.
Rogulite has eleven additional glow variants; keep these optional rather than
counting them as eleven distinct underlying mechanics. All first-batch 199 files
(160 clean + these 39) have distinct byte hashes. Total shortlisted candidates
including elemental = 247; the JSON manifest records transparency individually.

## Sprite sheets requiring extraction: 36 icons

- `Pixel_icons_32x32/Pixel_icons_32x32/Sprite_sheet(spells).png`:
  128×128, a 4×4 grid of 32px cells = 16 icons.
- `Pixel2_icons_32x32/Pixel2_icons_32x32/Skill_icons_2.png`:
  128×160, a 4×5 grid of 32px cells = 20 icons.

Only sheet PNGs and x4 showcase versions were found in these folders, despite
README wording mentioning individual PNGs. Extract the native sheets into named
files before adding. Compare extracted images with existing game art to avoid
duplicates. Their included README files request author attribution; retain the
source credit/license alongside any eventual asset integration.

## Lower priority for the agreed Icon Lab scope

- `alchemists-workshop-icons`: 50 individual icons at each native size. Mostly
  ingredients/equipment, but poison bottles, books, hourglass, knife and herbs
  could be selectively useful for talents or skills.
- `48-character-class-role-icons`: 48 native icons, mostly class/role imagery;
  generic `icon01`–`icon48` filenames need descriptive catalog labels.
- Currency/gems/crafting and potions/scrolls packs: mechanically loadable, but
  select only specific useful Thief/Poison/talent metaphors if needed.
- Equipment slots, map/dungeon markers, pets/mounts, cursors, quest objectives
  and menu icons: low priority or outside the agreed five-category scope.

Skip `preview`, `palette`, `atlas`, `.aseprite`, `.cur` and scaled-copy folders
when collecting individual icons. The named packs already supply native PNGs;
their atlas JSON and source files are not needed for direct imports.

## Integration recommendation

Start with the 160 combat/skill/spell images and include the elemental 48 if a
broader selection is wanted. Bundle purchased candidates as a pack-aware asset
library with source pack, native size, original filename and fingerprint. Keep
the current game reference separate from workspace assignments.

Current Icon Lab allows 200 imported images per workspace. A fresh workspace
can import the first 160 through its existing UI; the full clean 208 exceed that
count even though they are far below its 20 MB byte limit. A bundled library
extension is the better route for several purchased packs and avoids consuming
manual-import capacity. Preserve existing saved assignments when evolving the
catalog/import contract; its current fingerprint check rejects changed catalogs.

No library or gameplay changes were made in this audit.

Evidence:

- [Pack/folder dimension and byte inventory](../tools/icon-lab/reports/purchased-packs-audit.json)
- [247-file shortlist with source paths, transparency, sizes and hashes](../tools/icon-lab/reports/purchased-icons-shortlist.json)
