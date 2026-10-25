# Tree Lab implementation tracker

Date: 2026-09-16
Status: Local editor implemented and automated checks passed; real-browser visual
and native interaction smoke remains outstanding.

Tree Lab is a scoped Phase 6 planning tool. This does not mark the Rogue tree
design charter or any redesigned game mechanic complete.

## TL0 — Planning package

- [x] Inspect lab packaging, presentation, persistence, icons, and runtime boundary.
- [x] Record confirmed requirements and proposed defaults.
- [x] Create Assassin mockup, schema, fixtures, interaction rules, and delivery plan.

## TL1 — Data model and persistence

- [x] Runtime schema and semantic validation with readable error paths.
- [x] Generated default/example/schema/icon bundle; canonical JSON parity check.
- [x] Empty startup; five levels, intrinsic, five empty automatic slots.
- [x] Atomic JSON import and readable design-only export; import undo.
- [x] Draft storage, explicit Restore, corrupt-draft download, protected replacement.
- [x] Storage-denial and malformed-import checks.

Evidence: production model tests and DOM integration tests pass. Imported unknown
icons retain IDs with fallback. Browser download is used; a native save picker
was optional and is not implemented. Export reports a requested download rather
than claiming that the browser completed saving it.

## TL2 — Visual editing

- [x] Five rows, horizontal positioning, drag/drop with vertical level snapping.
- [x] Add/edit/delete talents with Apply/Cancel and undo/redo.
- [x] Name, flavour, description, ranks, values, optional skill grant, prerequisites.
- [x] Local icon bank, hover/focus details, prerequisite lines.
- [x] Tree thresholds, intrinsic, five automatic unlock slots.
- [x] Disabled second-tree placeholder and responsive inspector placement.

Evidence: DOM tests recreate ten Assassin talents from scratch through the actual
inspector controls, including two prerequisite links, multiple values, icons, and
an upper skill grant. They add the intrinsic and four automatic skills, leaving
the fifth slot blank. Invalid upward movement by level field is rejected; deleting
a prerequisite removes links and Undo restores them. User text is rendered as text.
Visual layout and native dragging are implemented but not browser-verified.

## TL3 — Allocation preview

- [x] Edit/Allocate modes, budget, rank controls, reset, spent summary.
- [x] Total-points gates and all-source rank-1 prerequisites.
- [x] Descriptive scaling, intrinsic totals, and automatic unlock updates.
- [x] Deterministic normalization after refund, budget changes, and structural edits.
- [x] Undo/redo, including budget and cascading allocation changes.

Evidence: checks cover gate evaluation before purchase, one-point prerequisites,
both linked requirements and tier gates, self-support prevention after refund,
reachable-rank retention, rank reductions, reset, and budget history. Free unlocks
do not enter the rank dictionary or spend points.

## TL4 — Integration and verification

- [x] Production launch README and root README lab links.
- [x] Focused model/persistence checks: 22 passed.
- [x] DOM workflow integration: 13 passed.
- [x] Generated fixture parity and JavaScript syntax checks passed.
- [x] Document current limitations and Phase 6 handoff.
- [ ] Real-browser desktop/narrow visual inspection, native dragging, keyboard and
  tooltip placement, and actual browser download completion.
- [ ] Direct-file browser-storage behavior and optional HTTP browser smoke.

The browser URL security policy rejected the local preview in this session. No
alternate browser route was used to bypass that restriction. DOM checks run in
jsdom and make no claim about real-browser rendering or native downloads. The
user can open `tools/tree-lab/index.html` directly to review the shipped editor.

No Godot files were changed; broad Godot regression was not needed. Existing
Phase 5 documentation deletions in the workspace remain untouched.

## Verification commands

```powershell
node tools/tree-lab/run_checks.js
node tools/tree-lab/build-data.js --check
node --check tools/tree-lab/app.js
node --check tools/tree-lab/model.js
$env:NODE_PATH = "$env:TEMP\tree-lab-test-runtime\node_modules"
node tools/tree-lab/ui_checks.js
```

The DOM suite requires development-only jsdom 26.1.0. Its setup is documented in
`tools/tree-lab/README.md`; the app itself has no install or network dependency.

## Deferred

Grid follow-up delivered: 21-column guides in Edit mode, snapping for dragging
and numeric position changes, a free-placement toggle, and undoable bulk alignment.
Automated checks cover rounding/clamping, existing-coordinate preservation,
unrelated edits, allocation preservation, bulk Undo, and simulated drag events.
The canvas has a scrollable minimum width to keep neighboring columns legible.
Native drag and visual-browser verification remain under TL4 above.

Multi-tree budgets, executable effects, `.tres` conversion, Practice Room and
Balance Lab integration, custom image uploads, arbitrary level counts, distinct
per-rank behaviors, and OR prerequisites. Unapplied inspector text is not saved;
Apply commits it, and navigation/export guards prevent silent loss.
