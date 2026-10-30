# P6M2-T6 — Build model and resolution

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

Follow-up: [T7](P6M2_T7_Content_And_Persistence.md) supersedes the temporary save
barrier and adds persistence/reset behavior. The boundaries below record T6 closeout.

Completed: 2026-09-23. Scope: implementation foundations and focused automated checks.

## Implemented contracts

- `RankedBuild` owns ordered primary/secondary roles, a shared integer budget of
  0–45, and a copied stable-ID-to-rank map. One point buys one rank. Failed edits
  leave state untouched and expose `last_error`.
- Purchases check own-tree investment before purchase. Retained builds and refunds
  check final own-tree investment, including higher-row ranks. All prerequisites
  require rank one. Invalid references, cycles, duplicate IDs, unknown ranks,
  fractional values, overspending and duplicate tree roles are rejected.
- Individual refunds never cascade. Full refunds retain roles and earned points.
  Ranked Adventure fixes roles, permits a secondary at the contract transition,
  and allows free refunds only in the between-contract offer window. That window
  includes the pending offer preview already stored in `active_contract`.
- Practice has independent state, immediate secondary access, free edits and
  budgets from 0–45. Lowering budget below spend fails. Removing primary clears
  both roles; replacing roles retains only talents in retained trees.
- Both trees contribute base intrinsics at zero spend. Only primary contributes
  explicit additive per-point modifiers, multiplied by its own investment.
- `TalentRank` contains the complete effects for that rank, not increments to sum:
  stat modifiers, existing triggered effects and skill augments. Talent skill
  grants apply from rank one. `TreeSkillUnlock` pairs a threshold and nullable
  skill; null slots grant nothing and do not block later unlocks.
- Ranked resolution adapts copies into the established resolver, preserving gear,
  duplicate grant handling and source resources. It refuses unready trees and
  incomplete rank arrays; graph-only fixtures cannot become silent playable content.
- Rotation normalization preserves order and repetitions, keeps the first ten
  available entries, and reports removed and overflow IDs. Re-unlocking a skill
  does not restore or add rotation entries. State exposes `rotation_changes` for
  later UI notices; existing empty-rotation fight/lock restrictions remain.
- `BuildProgression` centralizes cap 45, Tavern rewards 1/0/4/5 and five points per
  completed contract. The terminal boss claim carries that single completion payout;
  no second completion award is added. Other contract nodes, including elites,
  grant no points. Runtime reward previews override stale embedded point values.
  Claims award capped points immediately, even with deferred cosmetic animation;
  repeated claims cannot award them again. Gold retains its existing animation flow.

## Integration and activation boundary

Adventure and Practice expose `configure_ranked_build`, rank-aware editing,
resolution and rotation normalization. Combat, stat panels and tooltips read the
state's resolved stats. Progression changes are active on the existing game path.

Current authored trees remain legacy binary content with `ranked_content_ready`
false. The current talent UI still uses binary selection. T6 does not activate the
four redesigned trees or provide their new combat mechanics. The model fixtures
validate allocation graphs; synthetic ready resources validate numerical resolution.
Legacy talent editing remains on its inherited rules until ranked activation.

Until T7 supplies the new save envelope, SaveSystem rejects saving/loading an
active ranked model rather than silently losing its ranks in the binary format.
Legacy save regression behavior remains supported at this intermediate checkpoint.
The approved full reset of old saves is **not yet implemented**; no actual player
save was invalidated during T6. T7 must implement that policy together with ranked
persistence, conversion validation and activation. Practice persistence and visible
rotation-removal notices remain T7/M4 integration work.

## Validation

2026-09-23, Godot 4.7 stable, headless Windows:

```powershell
python tools/p6/run_foundation_tests.py
node tools/p6/check_build_fixtures.js
node tools/p6/check_content_identity_manifest.js
node tools/p6/audit_tree_drafts.js
```

The Godot runner redirects default save writes to per-test files, scans for script
errors in addition to exit codes, and writes ignored reports under
`project/reports/p6_t6/`, including `summary.json`. All 18 focused tests pass:

- New model and state/progression tests: all 121 T5 fixtures, gates 5/10/15/20,
  prerequisites, invalid ranks/budgets, non-cascading refunds, both tree roles,
  zero-spend intrinsics, complete rank effects/augments, automatic unlock thresholds,
  null slots, gear grants, rotation pruning, Adventure restrictions, Practice
  isolation, missing content rejection, single claims and cap saturation.
- Inherited allocator, rotation cap, encounter rewards, authored/generated routes,
  generated outcomes, three save/load suites, Practice builds/fights, tooltip,
  combat screen, gear stat aggregation, overkill gold and deterministic replay.

The three Node checks pass: original draft hashes/appendix parity unchanged,
92-object identity coverage intact, all 121 planning fixtures valid. Godot emitted
existing certificate-store and shutdown resource-leak diagnostics; no script,
assertion or parse errors remained in passing runs. These are headless checks,
not rendered UI validation, balance acceptance or proof of save power-loss safety.

## T7 handoff

1. Convert reviewed representative content using the T4 manifest and explicit
   rank effects; validate references and semantics before marking any tree ready.
2. Add ranked serialization and restoration with integer ranks, roles, budget,
   revision and normalized rotation. Replace the temporary save barrier.
3. Implement the user-approved whole-run reset for old saves, plus independent
   Practice persistence and compatibility tests.
4. Activate converted content through the state APIs and update binary UI
   consumers before exposing ranked builds. M4 owns the complete playable UI
   checkpoint; M3/M5 own reviewed combat effects.
5. T8 verifies integrated conversion, persistence, gameplay and regression behavior;
   T9 closes M2 and reconciles the M3 handoff.
