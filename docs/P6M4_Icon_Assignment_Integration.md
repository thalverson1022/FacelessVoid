# Approved icon assignment integration

Completed 2026-10-01. This closes the Icon Lab assignment handoff in M4-T3; full playable content and the remaining M4 UI work are still pending.

## Installed state

The user's `full_icons.json` is preserved unchanged under `tools/icon-lab/approved/`, alongside the frozen source catalog. All 92 identities now resolve to game textures: 11 defensive mechanics, 23 skills, 44 talents, 9 buffs and 5 enemy statuses. The installer created 83 named 32×32 RGBA PNGs under `project/assets/ui/assigned/`; the nine buffs share their granting source's file. Original purchased assets and embedded custom masters are retained.

Names describe the assigned content, for example `skills/blinding_powder.png`, `talents/bladedancer/whetstone.png` and `talents/thief/gilded_blade.png`. Stable gameplay IDs remain unchanged, including the historical `wet_stone` ID. The machine-readable mapping, source hashes and installed hashes are in [icon_assignments.json](../project/data/ui/icon_assignments.json).

| Buff | Icon source |
| --- | --- |
| Footwork | Fancy Footwork |
| Readiness | Parrying Strike |
| Precision | Precision Attacks |
| Dance | Dance of Death |
| Bypass | Bypass talent |
| Virulent Poison | Virulent Poison skill |
| Master of Poisons | Master of Poisons skill |
| Touch of Darkness | Touch of Darkness skill |
| Beguiling Presence | Beguiling Presence skill |

Precision intentionally follows Bladedancer's Precision Attacks, rather than Assassin's Precision. This aligns the original export with the user's subsequent instruction that buffs inherit their granting source.

## Game and authoring integration

`GameIcons` provides one lookup with explicit texture preloads for export inclusion. Skill and talent resources, selection/rotation panels, active talents, icon tooltips, combat status displays, combat log presentation and runtime monster mechanics consume the mapping. Unknown legacy IDs retain their existing fallback where available.

Combat playback and Practice combat display temporary player buffs and enemy Penetration/Potency from recorded effect lifecycle events, including charges and expiry. Multiple effect instances remain separate. Playback completion/skip clears the display. Presentation records are captured without enabling diagnostic tracing or changing combat calculations.

Icon Lab now contains 500 assets: the previous 417 plus 83 descriptive game files. All 92 current references are assigned. Buff edits update their source and imports normalize buff mappings to that source. Older workspace identities remain supported. The user's browser draft is untouched.

To align a browser workspace exactly with the installed game, import [installed_icons.json](../tools/icon-lab/approved/installed_icons.json). The original approved export remains separate for provenance.

To reproduce this approved installation with Python and Pillow available:

```powershell
python tools/icon-lab/install-approved-icons.py
node tools/icon-lab/build-data.js
node tools/icon-lab/build-data.js --check
node tools/icon-lab/run_checks.js
```

The installer replays the frozen approved export; future art revisions require reviewing and replacing its approved inputs deliberately.

## Verification and scope

- 15 Icon Lab model/catalog checks and 26 browser acceptance groups passed, including portable export/import, old workspace compatibility, linked buffs and tamper rejection.
- Seven Godot regression scripts passed: icon assignments, build panels, combat HUD, Practice combat view/fight, persistence UI and deterministic replay. [Final regression summary](../project/reports/icon_final_validation/summary.json).
- Follow-up checks passed after tooltip and runtime mechanic wiring: [tooltip summary](../project/reports/icon_tooltip_validation/summary.json), [final mapping summary](../project/reports/icon_mapping_final/summary.json).
- Assignment checks verify all 92 textures, dimensions, buff identity, resource duplication, lifecycle expiry/consumption, tooltip art and unchanged combat totals/RNG with diagnostic tracing toggled.
- Actual Godot controls were rendered using the core fixture at [1280×720](../project/reports/icon_integration/game-icons-1280.png), [1600×900](../project/reports/icon_integration/game-icons-1600.png) and [1920×1080](../project/reports/icon_integration/game-icons-1920.png).

Tests use isolated save locations and browser profiles. The playable registry remains `p6.compat.1`. Rendering the core fixture proves the icon consumers; it does not promote all redesigned content, implement the requested Test Mode entry flow, or complete M4-T4–T11. Full tree layouts, remaining effect/cooldown UX and end-to-end playable integration remain those tasks' responsibility.
