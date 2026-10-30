# Tree Lab — design and delivery plan

Status: Local editor implemented; model and DOM workflow checks pass. Real-browser
visual, drag, and native download checks remain outstanding. Open
`tools/tree-lab/index.html`; the planning mockup below is retained as a reference.
Date: 2026-09-16

## Purpose

Tree Lab is a local visual sketchbook for asymmetric Rogue subclass trees. It
lets a designer arrange talents, describe scalable effects, connect prerequisites,
and explore point investment without requiring combat mechanics to exist first.
Interesting high-investment payoffs and potential cross-tree synergies are design
goals; the lab does not score builds or claim to identify optimal choices.

## Confirmed scope

- One editable tree. A disabled second-tree placeholder reserves future space.
- Five talent levels, displayed with level 1 at the bottom and level 5 at the top.
  Each has an editable total-investment threshold.
- Add nodes; snap their vertical position to a level; arrange them horizontally.
- Node fields: name, flavour text, description, icon, maximum ranks, level,
  prerequisites, optional skill-unlock description, and multiple scalable values.
- Each purchased rank costs one point. A prerequisite requires one point in its
  source talent; the destination's level requirement still applies.
- An editable central intrinsic and five free automatic skill-unlock slots below
  it, each with an independently editable points-spent threshold.
- A local icon bank, hover details, and equivalent details on focus/selection.
- Edit mode and single-tree allocation preview with budget, refund, and reset.
- JSON import/export, a bundled empty default, and browser draft recovery.
- Values describe ideas. No DPS accounting, combat execution, or balance scoring.

## Existing-lab inspection

| Evidence | Finding | Tree Lab decision |
| --- | --- | --- |
| `tools/shop-lab/README.md`, `index.html`, `styles.css` | Client-only, open HTML directly; plain HTML/CSS/JS; dark panels, teal actions, gold accents | Use the same packaging and visual vocabulary, with canvas as the dominant surface |
| `tools/monster-lab/README.md`, `app.js` | Editable catalog, JSON import/export, local storage, save-picker/download fallback; script globals avoid file-URL fetch restrictions | Reuse the workflow pattern, not the large monster-specific implementation |
| `tools/balance-lab/README.md`, `server.js` | Node server runs Godot and serves results | No server or Godot bridge needed for sketching |
| `project/assets/skill_icons/rogue/` | Ten existing Rogue PNG icons | Use a stable local icon catalog plus a neutral fallback; no external icon service or Rift asset copying |
| `project/scripts/resources/talent.gd` | Single talent cost and prerequisite groups; no authored rank/level fields | Design JSON is not presently a runtime resource |
| `project/scripts/resources/subclass_tree.gd` | Intrinsic text, modifiers, skills, augments | A later adapter must map concepts intentionally |
| `project/scripts/resources/prerequisite_group.gd` | Runtime can express OR groups | v1 sketch connections use ALL semantics; do not imply automatic parity with runtime groups |

The inspected tool folders have individual launch instructions; no shared lab
launcher was identified. Deliver Tree Lab under `tools/tree-lab/` with its own
README and add a root README link when the editor ships. No game-menu entry is
needed for this planning milestone. Existing deleted Phase 5 documents in the
working tree were present before this work and are unrelated.

## Reviewable screen

Open `tools/tree-lab/planning/mockup.html` directly in a browser. This is a local
interaction mockup, not the production editor. It demonstrates node selection,
hover information, a placeholder icon picker, Edit/Allocate switching, spending,
refunds, intrinsic scaling, automatic unlocks, and an empty-template view.
File import/export, dragging, and persistent editing remain implementation work.

The mockup uses the user's Assassin sketch. Short working names are assigned to
unnamed effects; thresholds, rank caps, budget, and unspecified values are
illustrative. Venom Jab follows the screenshot's label (the conversation also
called it Poison Jab). Master of Poisons remains undescribed. The fifth automatic
slot stays empty because the sketch supplies only four. No invented fifth skill
or capstone behavior is treated as approved content.

Desktop arrangement:

1. Header: tree name, New / Import / Export, draft status.
2. Canvas toolbar: Edit / Allocate, Add talent in Edit; budget/reset in Allocate.
3. Broad canvas: five labelled rows and visible prerequisite arrows, central
   intrinsic, then five automatic unlocks arranged downward.
4. Right inspector: selected node fields, repeatable scaling rows, prerequisites,
   and icon picker. Selecting a level or automatic slot changes the inspector.
5. Disabled “Second tree — later” tab; no empty second canvas consuming space.

At narrow widths the inspector moves below the canvas. The production canvas
keeps a scrollable minimum width so dense talent layouts remain legible. Node
names and rank counts remain visible; full prose lives in hover/focus details.
Keyboard selection and a horizontal-position input complement dragging.

## Proposed defaults for review

These are reversible tool defaults, not approved game balance:

| Decision | Proposal |
| --- | --- |
| Talent level thresholds | 0 / 3 / 6 / 9 / 12 total points; editable |
| Automatic unlock thresholds | 1 / 3 / 6 / 9 / 12; independent of talent levels |
| Preview budget | 15; editable, including zero |
| Multiple prerequisite links | All sources require at least one point |
| Allowed prerequisite direction | Strictly from lower level to higher level |
| Refund | Cascade invalid allocations; show what was removed; support undo |
| First launch | Empty template; offer Restore when a valid saved draft exists |
| Scaling | Value at rank 1 plus fixed increment for each additional rank |

## Architecture and persistence

Use dependency-free classic scripts, matching the file-open labs. Proposed
production modules are `model.js` (validation/allocation), `app.js` (UI),
`styles.css`, `data/icons.js`, and generated `data/default-tree.js`.

Keep `templates/empty-tree.json` as the canonical default. Generate its script
wrapper at development time and check equality in the validation command; do not
fetch JSON on startup under `file://`. The planning mockup's fixture wrapper is
generated the same way. Import uses a file input and FileReader; export uses a
JSON Blob download, optionally a save picker with download fallback. No CDN,
build service, package install, or network connection is required to use the lab.

Store design and preview allocations separately. Design JSON never contains
current spent points, derived unlock flags, or selected UI state. A local draft
envelope can contain both, tagged with its own version. Autosave after valid
edits; catch unavailable/quota storage errors and keep JSON export usable. Start
with the default and a Restore draft affordance instead of silently replacing it.
New/import preserves the previous draft until replacement succeeds.

See [JSON contract](P6_Tree_Lab_JSON_Contract.md) and
[interaction rules](P6_Tree_Lab_Interaction_Rules.md) for precise behavior.

## Runtime boundary

Version 1 JSON is portable design data, not executable code. No expression strings
are evaluated. Placeholder skills and effect labels have lab IDs, not implied
Godot IDs. Importing a sketch into Tree Lab does not modify Adventure saves,
`.tres` resources, Practice Room, or Balance Lab. A later scoped adapter will need
explicit effect mappings, rank/level semantics, resource ID migration, and tests.

## Delivery sequence

1. Review this planning package and settle proposed defaults.
2. Build the model, validator, empty startup, and JSON persistence.
3. Build the visual editor and icon picker.
4. Add allocation preview and cascade/undo rules.
5. Verify file-open use, recovery, layout, and document the shipped lab.

Detailed gates and current completion state are in
[the tracker](P6_Tree_Lab_Implementation_Tracker.md).
