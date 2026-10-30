# P6M2-T8 — Foundation integration validation

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

Date: 2026-09-23. Complete for the declared M2 foundation scope.
Follow-up: [T9 closeout and M3 handoff](P6M2_T9_Closeout_And_M3_Handoff.md) is complete; M3-T1 is next.
The evidence and original handoff below record the T8 checkpoint.

## Validated scope

This checkpoint combines the rank model, resolution, state edits, progression,
conversion checks, Adventure persistence, Practice persistence and UI integration.
The playable registry remains `p6.compat.1`. Ranked executable checks use declared
scalar fixtures or synthetic supported-effect resources. All 121 T5 draft fixtures
remain allocation-graph tests; their unresolved mechanics are not simulated.

The new lifecycle test exercises **176 checkpoints**: four primary trees, each
alone or paired with each of the other three trees, at budgets
0/1/5/10/15/20/25/30/35/40/45. Every checkpoint allocates, resolves, saves, reloads,
checks roles/ranks/stats/duplicate rotations, rejects in-contract full refunds,
refunds between contracts, saves/reloads again and continues editing. These are
synthetic integration trees, not implementations of the four draft trees.

Additional integrated cases persist a retained four-plus-one gated build, reject
an invalid support refund, remove the dependent rank and reload the result. Practice
checks cross 1/3/6/12 unlock thresholds, save/reload before refunds, remove unavailable
rotation entries, reject locking an empty rotation, avoid automatic restoration on
re-unlock, and save/reload the primary-removal reset. Actual Tavern and authored boss
reward claims save/reload at each checkpoint and cannot be claimed twice after load.

## Defects and missing coverage resolved

- Added the ranked scenario adapter promised by T5 but absent from T7. Balance Lab
  now accepts `ranked_build` payloads plus an explicit registered content set,
  validates readiness/legality and runs the existing deterministic simulator with
  resolved rank effects. Unavailable content yields **not_ready**, with zero seeds
  and no simulation; invalid builds/rotations fail. Report aggregation cannot turn
  a not-ready scenario into an overall pass.
- Ranked scenario reports retain the exact submitted build/revision and data-only
  snapshots of class, tree/rank resources, resolved skills, equipped gear and target.
  Existing seed/duration/gold fields complete the reproducible inputs. The scalar
  diagnostic repeats seeds 1–20 with the fixed crude dagger and a high-HP target;
  matching outcomes establish reproducibility, not a Phase 6 balance target.
- Unknown saved run-phase/outcome enums now reject before live-state commit.
  The regression verifies both live state and file bytes remain unchanged.
- Conversion now checks source identity/name at each manifest pointer. A reordered
  export with its hash updated but stale pointers is rejected, rather than mapping
  the wrong talent into a reserved ID.
- Corrected the inherited build-panel test's gear fixture: its intended two-item
  inventory now explicitly excludes the starter dagger before setting up the panel
  assertions. Gameplay inventory/equipment behavior was not changed.
- Regenerated two test-only tree labels whose em-dashes had become replacement
  characters. Checked conversion parity now passes.

## Acceptance evidence map

| Cases | Evidence | Result / boundary |
| --- | --- | --- |
| T4-C01 | Draft audit, identity manifest checker | Four exact source hashes, 92 identities/140 rank slots, collision mappings intact. |
| T4-C02 | Conversion parity and negative conversion tests | Changed hash, missing mapping, duplicate ID and reordered identity pointers reject. |
| T4-C03 | Explicit scalar mapping allowlist, test-only manifest, release refusal; Balance Lab readiness test | Unsupported mechanics do not enter executable scenarios. Death Pact/Heavy Strike and complete mechanic approval remain M3/M5. |
| T4-C04 | Ranked model and integrated unlock/refund tests | Empty 9-point slots do not prevent the 12-point grant; threshold loss prunes rotation. |
| T4-C05 | Legacy allocator regressions and ranked prerequisite checks | Inherited OR prerequisites remain separate from ranked ALL semantics. |
| T4-S01 | Persistence tests and 176-checkpoint lifecycle | Explicit roles, ranks, budget, ordered repeated skills and unlocked state survive round trips; locks clear. |
| T4-S02–S03 | Strict parser/persistence tests, boundary integration test | Corrupt/future data, duplicate keys, invalid IDs/ranks/budgets and invalid run enums reject without repair or overwrite. |
| T4-S04 | Retained-gate integration case | Four lower ranks plus one gated rank survives persistence; illegal support refund rejects atomically. |
| T4-S05 | Resource-replacement integration case | A registered tree with the same ID, new display name and no old resource path restores its saved ranks. |
| T4-S06–S08 | Persistence/reset and Continue scene tests | Version-1 paths are not resolved; complete fresh state replaces old saves; repeats, current reload and forced write failure checked. |
| T4-S09 | Compatible/incompatible revision persistence cases | Legal compatible builds retain roles/ranks; explicitly incompatible versions reset fully. |
| T4-R01 | Persistence and model normalization tests | First ten available entries, order and duplicates retained; unavailable/overflow IDs reported separately. |
| T4-R02 | Model alternate-gear-grant test and integrated refunds/reloads | Alternate grants survive; losing the final grant removes entries; re-unlock does not restore them. |
| T4-R03 | Integrated empty-rotation checks | Valid editing state; lock and fight start remain blocked. |
| T4-P01 | Practice persistence/UI tests and inherited fight-setup checks | Budgets 0/10/45, custom item/equipment identity, gold, target/metadata, duration and seed restore independently. |
| T4-P02 | Practice future/corrupt/missing checks and boundary scene test | Defaults/notices as appropriate; ordinary edits cannot silently overwrite a failed-restore file. |
| T4-P03 | Model/state tests and integrated primary-removal persistence | Budget/invalid edits reject atomically; clearing primary clears both roles, without implicit promotion. No general draft/undo feature is claimed. |
| T4-P04–P05 | Practice gold and incompatible-revision tests | Configured gold survives independently of fight gains; incompatible Practice reset never alters Adventure. |
| T3/T5 rewards | State progression, generated outcomes and reward-resume integration | Tavern totals 1/1/5/10; completion totals through 45; no elite points; cap remainder and single-claim behavior. |
| Enigma isolation | Runner before/after fingerprints and runtime project assertion | Original Enigma project/export configs and its real save unchanged; real FacelessVoid save/Practice files unchanged. FacelessVoid uses its own user-data directory. |

## Commands and reports

```powershell
python tools/p6/run_foundation_tests.py
python tools/p6/check_content_registry.py
python tools/p6/convert_representative_content.py
python tools/p6/test_content_conversion.py
node tools/p6/check_content_identity_manifest.js
node tools/p6/check_build_fixtures.js
node tools/p6/audit_tree_drafts.js
git diff --check
```

The final Godot suite includes **29 tests**: the original 20, three new T8 tests,
and six additional inherited UI/route/Practice/Balance Lab regressions. It scans
script/assertion failures as well as exit codes. Reports live under ignored
`project/reports/p6_t8/`: `summary.json`, per-test logs, `isolation.json`, and
`ranked_balance_diagnostics.json`. The mixed diagnostic report intentionally has
`not_ready` overall because it includes one unavailable-content case; its ready
scalar scenario passes. That is expected rejection coverage, not a gameplay failure.

The inherited Balance Lab regression runs its suite in memory and checks failure
counts. It does not overwrite `reports/balance/latest` or redefine inherited tuning
bands. Static checks verify 79 compatibility resource hashes, conversion parity,
original source/identity coverage and all 121 planning fixtures.

The new adapter is accessible through
`BalanceLab.run_scenario_spec(spec, registry)`. Supply the versioned build payload
under `ranked_build`, use stable rotation IDs there, and pass an explicit ready
registry for test-only content. Otherwise the packaged registry determines readiness.
Use `StrictSaveJson.read` for imported JSON payloads to preserve integer field types.
Legacy path-based scenario inputs remain supported by their existing path.

## Limits and T9 handoff

Headless scene/state checks do not establish rendered UI clarity, complete redesigned
combat behavior or numerical balance. Shared mechanics and full-tree conversion
remain M3/M5; the first playable redesign and complete feedback remain M4; measured
enemy/build targets remain M6. The named M4 Footwork/mixed builds are still not ready
for combat simulation. No unsupported effect is treated as implemented.

Existing certificate-store and shutdown resource diagnostics remain; negative numeric
parsing deliberately exercises an exponent-overflow warning. Save replacement still
has the documented remove/rename power-loss limitation. These checks establish normal
round trips and failure handling, not crash-durability guarantees.

T9 should reconcile this evidence with M2 exit criteria, capture the repository state,
and give M3 the remaining mechanic specifications, ordering/recursion questions and
diagnostic contracts. Keep the distinction between tested foundations, compatibility
content, synthetic fixtures and unreleased redesigned content in that handoff.
