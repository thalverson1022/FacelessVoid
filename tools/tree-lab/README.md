# Tree Lab

A local visual editor for Rogue skill-tree ideas. Open **`index.html`** directly
in a browser. No install, server, network, or Godot process is required.

## Create a tree

1. Start with the empty template, restore a saved draft, import JSON, or load the
   illustrative Assassin example.
2. Select the tree name to edit its name, notes, five upper-level thresholds,
   and five automatic-unlock thresholds.
3. Select **Add talent**. Set its name, descriptions, ranks, level, position,
   scalable values, optional skill grant, prerequisite sources, and icon.
4. Select **Apply changes** to commit the edit. Cancel discards the inspector
   changes. Nodes can be dragged between rows or positioned with numeric fields.
   **Snap to grid** is on by default: dragging and changed horizontal-position
   fields snap to 21 equally spaced columns. Faint guides appear in Edit mode.
   Turn snapping off for free placement. **Align all to grid** moves every talent
   to its nearest column as one undoable action. Opening a tree or toggling snap
   never moves existing nodes. Snap is a session control, not part of design JSON.
   Nodes that snap to the same column remain separate and may need rearranging.
5. Select the intrinsic or any lower unlock slot to describe its effects.
6. Choose **Allocate**, select a talent, and use **Allocate** or **Refund**.
   Change the budget, reset, undo, or redo to explore progression.
7. Use **Export JSON** to request a browser download. Check the browser's download
   destination; the app does not silently write to the repository.

All prerequisite sources require one invested point, and the destination level
must also be open. Refunds and structural edits remove allocations that can no
longer be purchased from zero; Undo restores the complete operation. Automatic
skills are free and never add to spent points. Numbers are descriptive: this lab
does not calculate DPS or execute combat mechanics.

## Saving and recovery

Applied edits and preview changes are autosaved when browser storage is available.
Inspector text is not committed until **Apply changes**; leaving unapplied edits
prompts before discarding them. Export is blocked until those edits are resolved.

On startup the app opens the empty template and offers **Restore draft** when a
saved draft exists. It never silently overwrites a pending saved draft. You can
download the saved draft envelope or keep the current tree instead; keeping the
current tree preserves the previous raw draft under a browser backup key.

Invalid imports leave the current design untouched. Unknown icons use a neutral
placeholder while preserving their IDs. A failed or unsupported saved draft is
retained for download. If storage is denied, editing and JSON export remain usable.
Browser storage for file URLs varies; exported JSON is the portable backup.

Design exports contain authoring data only. Preview allocations live in the
browser draft, not in exported designs. Draft-envelope recovery downloads are
diagnostic backups, not design imports; a valid envelope's `state.design` is the
portable design. Importing a design resets allocation and budget to 15 and can
be undone. New tree, example loading, and deletion can also be undone.

## Files

- `index.html`, `styles.css`, `app.js`: production editor.
- `model.js`: validation, allocation, history, and draft parsing.
- `templates/empty-tree.json`: canonical empty default.
- `examples/assassin-sketch.json`: illustrative design, not approved balance.
- `schema/tree-lab-v1.schema.json`: design interchange contract.
- `data/icon-catalog.json`: icon IDs; existing project PNG files are reused.
- `data/bundle.js`: generated local script containing schema, defaults, example,
  and resolved icon paths; avoids file-URL JSON fetch restrictions.
- `planning/`: original mockup and planning validation utilities.

After editing canonical JSON, run:

```powershell
node tools/tree-lab/build-data.js
node tools/tree-lab/planning/build-preview-data.js
```

## Checks

From the repository root:

```powershell
node tools/tree-lab/run_checks.js
node tools/tree-lab/build-data.js --check
node --check tools/tree-lab/app.js
```

DOM integration checks additionally use `jsdom` 26.1.0 as a development-only
dependency. It is not shipped with the app. One temporary-directory setup:

```powershell
npm install --ignore-scripts --no-audit --no-fund --no-package-lock --prefix "$env:TEMP\tree-lab-test-runtime" jsdom@26.1.0
$env:NODE_PATH = "$env:TEMP\tree-lab-test-runtime\node_modules"
node tools/tree-lab/ui_checks.js
```

Model checks cover validation, gates, prerequisite chains, refunds, history,
drafts, and data fidelity. DOM checks exercise the actual editor controls to
author an Assassin tree, export/import, recover drafts, and handle invalid data
or denied storage. They do not replace real-browser layout and drag testing.

## Limits and handoff

- One tree, exactly five levels and five automatic slots; second-tree tab is reserved.
- ALL prerequisite semantics with lower-level sources only.
- Fixed per-rank increments; any number of descriptive values per talent.
- Budget 0–10,000 and import size up to 2 MB; undo/redo retains 100 operations.
- Overlap and unreachable content produce design notes, not export blockers.
- Browser download export; no native save picker or direct disk writes.
- No game-resource conversion, combat simulation, or changes to Adventure saves.
- Real-browser visual, drag, and native download verification remains outstanding
  because the session's browser URL policy blocked local preview verification.

See [plan](../../docs/P6_Tree_Lab_Plan.md),
[interaction rules](../../docs/P6_Tree_Lab_Interaction_Rules.md),
[JSON contract](../../docs/P6_Tree_Lab_JSON_Contract.md), and
[tracker](../../docs/P6_Tree_Lab_Implementation_Tracker.md).
