# P6M2-T7 — Content conversion and persistence

Completed for the M2 foundation scope: 2026-09-23. T8 integration validation subsequently completed; see the [acceptance report](P6M2_T8_Foundation_Integration_Validation.md).
The redesigned four-tree release remains gated on M3/M5 mechanic review and M4 integration.

## Content sets and promotion

T7 supplies explicit conversion of representative **test-only** scalar resources:
Whetstone's five base-physical ranks and Keen Eye's five physical/elemental percentage
ranks. Their stable IDs come from the T4 manifest. The converter verifies all four
source hashes and refuses duplicate/missing mappings. It uses explicit stat IDs and
units, never source value labels as handler selectors. `--write` creates resources;
the default invocation verifies exact parity. `--release` refuses promotion.

The resulting fixture manifest and Godot resources live in
`project/tests/fixtures/p6/`. They deliberately omit tree intrinsics, skill grants,
Footwork, retriggers and other unresolved mechanics. They are complete scalar test
slices, not representations of the full trees, and are excluded from exports.
The original four source drafts remain unchanged. M3/M5 must review the missing
mechanics before full content conversion/promotion; M4 remains the playable checkpoint.

The shipped **p6.compat.1** registry describes the complete inherited playable
content set, with 79 trusted resource paths and source-file hashes. This interim
revision is distinct from the reserved redesigned `p6.1` release. Version-2 saves
include an explicit `allocation_mode`; compatibility allocations remain binary and
cannot masquerade as redesigned ranks. The current game keeps its existing trees,
while using the new save envelope and the T6 progression rewards. This allows
persistence/reset behavior to ship without publishing incomplete trees as working
content. No saved payload can select a fixture registry or load an arbitrary path.

`BuildContentRegistry` supports explicit ranked registries and validates rank
content, supported scalar modifiers, prerequisite graphs, gates, unlock slots,
reachability and duplicate identities. `BuildSaveCodec` resolves IDs through the
selected registry. Representative ranked registries are injected only by tests.
When the reviewed full content is ready, publish its complete registry and declare
whether `p6.compat.1` is incompatible; do not silently reinterpret its allocations.
The new registry JSON is explicitly included in both export presets.

## Adventure persistence and reset behavior

- Save envelope version 2 stores one build payload: schema/revision, class ID,
  explicit tree roles, earned points, talent ranks and ordered rotation skill IDs.
  Derived stats/unlocks and duplicate legacy build fields are not written.
- Strict JSON reading preserves integer tokens and rejects fractional rank fields,
  duplicate keys, malformed containers, nonfinite numbers and integer overflow.
- Current builds validate before commit: roles/membership, rank caps, budget,
  retained gates and prerequisites. Unknown IDs and unsupported future versions or
  revisions fail without changing live state or the file. Non-build fields decode
  on a detached candidate before being copied into live state.
- Existing gear and generated-contract encodings remain, including their inherited
  gear quarantine/notices. Resource loading is restricted to the packaged allowlist.
- `load_run_result` distinguishes `loaded`, `reset-incompatible`, `missing` and
  `failed`; the boolean wrapper remains for existing callers/tests. Continue uses
  detailed outcomes and never deletes a save merely because loading failed.
- Version-1 saves reset before resource resolution. All run fields return to the
  ordinary New Run defaults, including the normal default seed. The fresh version-2
  state replaces the active old save; Continue enters class selection and displays
  the reset notice. A write failure is reported, and the old data is never merged.
- Explicitly incompatible older content revisions also reset fully. Compatible
  revisions retain legal builds. A fresh preselection save reloads into ordinary
  class/subclass selection rather than entering combat or locking class selection.
- JSON writes request full float precision. Temp-file replacement retains the
  documented remove/rename durability limitation; no power-loss guarantee is claimed.

The approved reset is now implemented in the application. Development tests used
isolated save paths; they did not manually delete the user's real save. Continuing
an actual version-1 save will apply the reset policy.

## Practice Room and UI integration

`PracticeSaveSystem` uses only `user://practice_build.json`, envelope version 1.
It persists the class/build, budget, ordered rotation, configured gold, all five
editable item definitions and equipment selections, target snapshot, generated
metadata, duration, seed and random-seed settings. It restores the actual snapshot;
loading does not reroll a generated target.

Configured gold is separate from combat gains. Fight results, stolen-gold totals,
buffs, locks and RNG continuation are excluded. Reopening starts from the saved
setup; starting another fight resets to configured gold. Setup changes queue one
save per UI transaction/frame. A Save Setup button permits explicit replacement.
Missing files use defaults. Invalid/future files show a notice and disable automatic
overwrite until explicit Save Setup; known incompatible revisions reset only
Practice. Adventure remains untouched.

Load/edit normalization keeps the first ten available rotation entries, preserving
order and duplicates. It clears locks and reports unavailable/overflow entries.
Continue and Practice expose load notices. Ranked talent panels now use rank counts,
plus/minus controls, explicit refund errors and full refunds; active summaries use
the chosen rank's scalar effects. Selecting a ready tree enters the ranked state
path. These controls are tested with fixtures; no incomplete draft tree is offered
in the live game. Comprehensive effect presentation and rendered review remain M4.

## Validation evidence

Run from the repository root:

```powershell
python tools/p6/run_foundation_tests.py
python tools/p6/check_content_registry.py
python tools/p6/convert_representative_content.py
python tools/p6/test_content_conversion.py
node tools/p6/check_content_identity_manifest.js
node tools/p6/check_build_fixtures.js
node tools/p6/audit_tree_drafts.js
```

The foundation runner now includes 20 headless Godot tests. Reports and per-test
isolated Adventure/Practice saves are under ignored `project/reports/p6_t7/`.
It checks process exit codes and script/assertion failures, so a script printing
PASS before another failed assertion cannot produce a passing suite.

New coverage includes strict parser rejection, incomplete/unsupported rank content,
whole-run resets at multiple checkpoints, repeated loading, forced write failure,
malformed/future data preservation, ranked mixed-tree round trips and role reversal,
compatible/incompatible revisions, preselection restoration, duplicate rotations,
removed/overflow notices, Practice budgets 0/10/45, configured gold versus fight
gains, equipment identity, generated target snapshot/seed restoration and isolated
Practice resets. Scene checks exercise Continue reset/failure, Practice save/reopen,
and rank increment/refund controls. Existing 18 foundation/regression tests remain.
The conversion negative tests reject changed hashes, duplicate IDs and missing
mappings. Registry/resource hashes, identity coverage and all 121 T5 fixtures pass.

Existing certificate-store/shutdown resource diagnostics occur in this environment;
the parser overflow test also intentionally exercises an exponent-overflow warning.
No remaining script/assertion errors are accepted. Headless scene checks do not
claim rendered UI acceptance, balance verification or complete four-tree gameplay.

## T8 handoff

Verify the implemented foundation paths together against T4's acceptance matrix,
expand boundary coverage where needed, and keep the declared compatibility/scalar
fixture scope explicit. Validate final redesigned content only after its dependent
mechanic specifications and executable resources are ready. Preserve the Phase 5
gear/generated-route regressions and independent Practice save behavior. T9 then
reconciles M2 closeout and the M3 handoff.
