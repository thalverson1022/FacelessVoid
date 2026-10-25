# Git checkpoint — 2026-10-24

User requested a checkpoint and GitHub push of current project changes and documentation, excluding temporary test projects and saves. This checkpoint follows `1222e1c` on `phase-6-skill-tree-redesign`.

## Included scope

- Current game source, scenes, resources, approved artwork, configuration, source tests and fixtures.
- Project documentation, historical decisions, milestone trackers and design/development tools, including Icon Lab and Phase6 validation utilities.
- Existing tracked deletions and renames reflected in the current working tree.

M1–M7 are Complete within their recorded scopes. M8 T1–T8 are Complete; T9 implementation and presentation evidence await overall user review under D084. T10–T12 and M9/M10 have not started. The user confirmed that reopening the editor and completing imports restored talent/skill icons and Practice gear access; this resolves the launch issue, not the overall T9 review checkpoint.

## Excluded local material

`work/`, `.godot_user/`, `.codex/`, Godot caches, exports/releases, generated reports, Python caches and prototype saves remain local. Existing tracked historical reports remain in repository history; their current generated changes are not part of this checkpoint. No player saves or temporary copied Godot projects are added.

Some verification documents link to `work/` or generated `project/reports/` outputs. Those links describe local evidence and are intentionally not portable in this checkpoint. Source tests and tools are retained; excluded local outputs are not deleted. This checkpoint is a source/documentation backup, not a packaged archive of every historical validation artifact.

## Validation and launch

This checkpoint preserves the existing recorded verification results and limitations; no new gameplay acceptance or broad regression run is implied by committing it. T9 records698 focused checks plus52 native skill-hover checks and targeted regressions. Candidate overflow remains invalid; retained legacy exceptions, balance and export/teardown qualification keep their existing owners.

After a fresh checkout, open `project/project.godot` with **Edit** in Godot4.7 and allow asset imports to finish before running. New PNGs can otherwise cause preload failures that cascade into missing icons and incomplete UI. Saves/settings are separate under `%APPDATA%/FacelessVoid/`.
