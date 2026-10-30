# P6M2-T9 — Closeout and M3 handoff

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

Date: 2026-09-23. Status: **Complete. M2 is Complete for foundation scope.**
Next: **P6M3-T1 — Milestone planning and first-slice specification.** M3 remains
Not started; this handoff does not approve unresolved combat rules.

## Acceptance reconciliation

| Task / exit criterion | Evidence | Disposition |
| --- | --- | --- |
| T1 scope and task sequence | [M2 tracker](P6M2_Build_Model_And_Progression_Foundations_Tracker.md) | Complete; nine tasks and milestone boundaries recorded. |
| T2 cross-tree inventory | [Audit](P6M2_T2_Cross_Tree_Draft_Audit.md), [appendix](P6M2_T2_Draft_Inventory_Appendix.md) | Complete; four drafts, 44 talents, 140 rank slots, four intrinsics, 18 populated automatic slots and two talent skill grants. |
| T3 rules and progression | [Specification](P6M2_T3_Progression_And_Allocation_Rules.md), T6/T8 tests | Complete; allocation, roles, refunds, intrinsics, grants and reward ownership implemented. Qualitative targets are planning inputs; numerical tuning belongs to M6. |
| T4 content and compatibility policy | [Policy](P6M2_T4_Content_Workflow_And_Compatibility.md), identity checker, T8 acceptance map | Complete; stable identities, explicit conversion, full incompatible-save reset and independent Practice persistence. |
| T5 integration dependencies | [Plan](P6M2_T5_Integration_And_Dependency_Plan.md), 121 checked fixtures | Complete; M4 candidates, UI/event requirements and mechanic owners assigned. Fixtures validate graphs, not redesigned combat execution. |
| T6 build/resolution implementation | [Implementation](P6M2_T6_Build_Model_And_Resolution.md), ranked model/state tests | Complete; representative builds allocate, refund, resolve and unlock correctly. |
| T7 conversion and persistence | [Implementation](P6M2_T7_Content_And_Persistence.md), conversion/registry and persistence tests | Complete for representative foundation scope; full-tree release remains gated. |
| T8 integration and regression | [Acceptance map and commands](P6M2_T8_Foundation_Integration_Validation.md) | Complete; 29 passing tests, 176 synthetic lifecycle checkpoints, 121 graph fixtures, protected-file fingerprints. |
| T9 evidence, limitations and handoff | This document and [repository checkpoint](P6M2_T9_Repository_Checkpoint.json) | Complete; remaining work assigned below and next task defined. |

All eight M2 exit criteria are satisfied within the agreed foundation boundary.
No unresolved combat mechanic has been dropped to achieve closure.

## What M3 inherits

- The playable registry is **p6.compat.1**, containing inherited binary content.
  Redesigned **p6.1 is not released**. Whetstone/Keen Eye executable resources are
  scalar test fixtures; synthetic ready trees and graph fixtures are not full trees.
- `RankedBuild` owns stable-ID ranks, explicit roles, atomic legal edits and the
  shared 0–45 budget. One point buys one rank; prerequisites use ALL semantics.
  Purchase gates inspect pre-purchase investment; retained legality uses final
  investment. Individual refunds cannot cascade; full refunds retain roles/budget.
- Both trees grant base intrinsics; primary alone receives per-point scaling from
  its own investment. `TalentRank` stores complete effects for a rank, not summed
  increments. Nullable automatic slots do not suppress later grants.
- Adventure refunds remain free between contracts for testing. Practice edits are
  independent. Rotation normalization preserves repeats/order and the first ten
  available entries; re-unlocking does not restore removed slots.
- Tavern rewards are 1/0/4/5, then five points per completed contract, capped at 45;
  no elite points or duplicate boss/completion award. Seven contracts reach the cap.
- Version-2 saves validate candidates before applying state. Incompatible old saves
  reset the entire run; corrupt/future data is rejected. This is normal save/load
  correctness, not a crash-durability guarantee.
- FacelessVoid has its own project identity, exports and `%APPDATA%/FacelessVoid/`
  data directory. Preserve the original Enigma checkout and saves.

## Shared combat work and unresolved decisions

The exact content-to-package map and audit Q01–Q20 disposition remain authoritative
in [T5 sections 2–3](P6M2_T5_Integration_And_Dependency_Plan.md). The table below is
the implementation handoff, not a new set of formulas.

| Package / audit questions | M3 specification and implementation | M5 content review / deterministic evidence |
| --- | --- | --- |
| C1 derivation; Q04 | Canonical units, additive/multiplicative buckets, live versus snapshot evaluation, temporary-source aggregation and copy order | Double Dip, Sharpened Edge, Shadow Mastery, Fast Hands, Fill Your Pockets; test gear/buff changes, floors/caps and confirmed Shadow Mastery examples. |
| C2 timed effects/charges; Q07 | Activation, duration units, caps, refresh/replace, consume/expire ties and fight/retry cleanup | Footwork, Riposte, Precision, Bypass, Dance, Death Pact and other temporary skills; test zero charges, boundary times and no leakage. Death Pact's timer unit remains unresolved. |
| C3 macro scheduling; Q08–Q09 | Conditional-slot skip/wait/advance, cooldown ownership/start, duplicate slots, windup snapshots and interruption/consumption order | Full Quick Cut, Plunge and Parry contracts first; every accessible skill must work. Test all slots blocked/cooling and finite progress. Combat remains macro playback. |
| C4 poison; Q05–Q06 | Cadence/phase, forced versus natural tick order, multi-consumption, remainder/zero fuel, charge provenance and critical poison RNG | Accelerant/Resonance composition and affected Assassin skills; test 0/1/2/3 stacks, actual consumption, interval changes and simultaneous ticks. |
| C5 triggers/repeats/crit; Q10–Q11 | Eligible origin types, guaranteed versus random repeats, first-hit meaning, suppression, total event order and finite branching safeguards | Opportunity, Precision, Side Step, Dance, Shadow intrinsic, Death Blade and gear procs; forced success/failure branches and same-seed trace equality. No invented 99% cap or unapproved event-limit value. |
| C6 statuses/mitigation; Q12–Q14 | Authoritative Decay quantity, partial removal/restoration, cleanse scope, conversion/penetration order, cap overflow and Bonus Stacks once | Affected Shadow, Bladedancer, Assassin and Thief effects; test zero base resistance, conservation, immunity and defense-denial combinations. |
| C7 economy; Q15 | Stash versus fight-stolen sources, theft/spending/rewards, dynamic gold-derived stats and retry/reset behavior | Steal, Mug, Pick pocket, Big Score, Bribery and related passives; test 0/100/499/500/501/10000 gold and no theft. Preserve Gilded Blade's 500 counted-gold cap and fight-local stolen counter. |

Q01–Q03 and the pipeline/save part of Q16 are settled. The Heavy Strike alias and
Death Pact unit in Q16 need affected M3/M5 content review. Q17's two empty slots
stay null unless M5 explicitly approves additions. Q18's numerical targets belong
to M6; Q19–Q20's UI and diagnostic execution belongs to M3/M4/M7.

For each affected mechanic, record eligible sources, miss/interrupt behavior,
values/units/caps, activation and consumption timing, duration/charges,
refresh/stack/replace, same-time ordering, RNG/proc eligibility, cleanup, events,
and normal/boundary/conflicting examples before implementation. Resolve actual
gameplay ambiguities with the user; do not reopen settled M2 policies. Specify
observable failure behavior for event-limit breaches, not just a depth limit.

## Implementation and diagnostic contracts

Use the existing APIs rather than maintaining parallel build or persistence models:

| Interface | Contract / reference |
| --- | --- |
| Build edits and resolution | [RankedBuild](../project/scripts/systems/ranked_build.gd), [BuildResolver.resolve_ranked_build](../project/scripts/systems/build_resolver.gd). Preserve atomic errors, source resources, grant deduplication and gear behavior. |
| Runtime resources | [TalentRank](../project/scripts/resources/talent_rank.gd), [TreeSkillUnlock](../project/scripts/resources/tree_skill_unlock.gd). Add only reviewed executable behavior; never mark a graph-only tree ready. |
| Content/persistence | [BuildContentRegistry](../project/scripts/systems/build_content_registry.gd), [BuildSaveCodec](../project/scripts/systems/build_save_codec.gd), [StrictSaveJson](../project/scripts/systems/strict_save_json.gd). Preserve stable IDs/revision checks and strict integer parsing. |
| State callers | [BuildState](../project/scripts/autoload/build_state.gd), [TrainingRoomState](../project/scripts/systems/training_room_state.gd). Keep Adventure and Practice isolated, with consistent normalization/error notices. |
| Diagnostics entry | [BalanceLab.run_scenario_spec(spec, registry)](../project/scripts/tools/balance_lab.gd). Supply a versioned payload under `ranked_build`; use an explicit ready registry for test content. Unavailable content returns `not_ready` with zero simulation; illegal builds/rotations fail. |

T5 section 6 defines required event information. M3 must choose/version its concrete
representation and produce it alongside each mechanic:

- Monotonic sequence/time, source content ID, parent/root cast and origin kind.
- Effect instance/source, lifecycle reason, before/after charges/stacks, magnitude,
  expiry and reset reason; scheduler slot/readiness/cooldown/start/end/interruption.
- Status requested/applied/consumed/overflow quantities; damage components, crit and
  mitigation; trigger eligibility, existing roll, children and suppression/limit result.
- Gold stash/fight-stolen before/after, raw/credited amount and source/capped contribution.

Diagnostics must not draw RNG or change ordering. Tracing on/off must produce the
same result; recap totals must reconcile and uptime uses clipped simulation time.
M4 consumes these records for HUD/playback/tooltips; M6 uses the aggregates.

The adapter already records build/revision, class/tree/gear/target/resolved-skill
snapshots. Initial probes use crude dagger, no other gear, gold 0, 30000 ms,
seeds 1–20, and a 1000000-HP zero-defense target unless overridden by the scenario.
Use deterministic state injection for exact thresholds. Once correctness passes,
T5 proposes seeds 1–200 for reports; numerical balance bands still require M6.

## First M3 task and delivery sequence

**P6M3-T1 — Milestone planning and first-slice specification** should create the M3
task tracker, translate C1–C7 into dependency-ordered tasks and acceptance cases,
and draft the first slice's rule decisions for user review. It can begin from this
handoff without repeating the four-tree audit. Its exit is an actionable tracker
and resolved first-slice contracts; any unanswered gameplay question remains
explicitly pending before its affected code is implemented.

1. Specify the core Bladedancer intrinsic, Whetstone, Rending Slash, Fancy Footwork,
   Quick Cut, Leaping Plunge and Parry Strike with the necessary C2/C3/C5 support
   and Rending Slash's C6 behavior. Bring affected M5 content review forward.
2. Implement approved shared behavior, event production and focused deterministic
   tests, preserving inherited class skills, gear effects and route behavior.
3. Hand M4 the `m4_bladedancer_core` 10-point fixture: Whetstone 4, Rending Slash 1,
   Fancy Footwork 5; Quick Cut / Quick Cut / Parry Strike / Leaping Plunge / Rending
   Slash. Verify every unlocked skill, not just those in this rotation. No Dance
   dependency at ten points; the nine-point slot is empty.
4. Extend to `m4_bladedancer_thief`: Bladedancer 15 / Thief 5, then the Practice
   role reversal and zero-secondary-investment case. Review Dance, Opportunity,
   Cloak & Dagger, Keen Eye, Thief intrinsic, Steal and Mug first.
5. Complete remaining C1–C7 systems and M5 content, including all mature pairings.
   M4 owns rendered/playable acceptance; M6 owns numerical tuning.

Neither core nor extension is combat-ready at M2 closeout. Release requires reviewed
effects, complete registry/references, deterministic tests and M4 integration;
the converter's test-only release rejection must not be bypassed.

## Remaining work and limitations

| Item | Disposition / owner / next action |
| --- | --- |
| Full redesigned mechanics and content | Required M3/M5 work above; no silent omission or no-op implementation. |
| Rendered UI, dense/busy effects and playable core/mixed builds | M4; headless scene tests do not establish visual clarity. Inventory assets there; M7 produces final icons/feedback. |
| Difficulty, gear cohorts, tree comparisons and Watchmen matchup | M6; preserve historical reports and establish new targets. Inherited 69-pass/one-warning result is historical, not Phase 6 acceptance. |
| Integrated playtest and final release regression | M8/M9; include all released content, exports, save behavior and project isolation. |
| Remove/rename save replacement power-loss window | Documented foundation limitation, not a durability claim. M9 owns explicit reassessment and any required repair/testing before release. |
| Headless certificate-store and shutdown resource diagnostics | Existing nonblocking baseline diagnostics; M9 reassesses, or the affected implementation task investigates if behavior changes. Script/assertion failures always fail. |
| Empty nine-point slots | Remain null; optional additions require explicit M5 content decisions. |
| Alchemist prices/role changes, presets/undo and advanced charts | Deferred/outside current essential scope as recorded by T3/T5. Do not implement as incidental M3 work. |
| Uncommitted repository state | This closeout records a working-tree checkpoint, not a release/tag/commit. Preserve existing edits and Tree Lab moves; include untracked implementation files when later committing. |

## Validation and repository checkpoint

Base HEAD: `1222e1c263df8dd173dd8d571a6134e79b5e69b2`, branch
`phase-6-skill-tree-redesign`. HEAD alone does not contain the M2 implementation.
The companion JSON records Git status, tracked/untracked file SHA-256 fingerprints,
deleted paths, protected Enigma/save hashes, and retained T8 report hashes/results.
It excludes itself to avoid a recursive hash. It identifies the local state; it is
not a backup of file contents. No commit, export or deployment was made in T9.

T9 changes documentation/evidence only. The 29-test runtime result is retained
from T8, including its two affected reporting reruns; it was not rerun or relabeled
as new gameplay evidence. T9 rechecks the six static draft/identity/fixture/registry/
conversion checks and expected `--release` refusal, documentation links/status,
whitespace, report completeness and protected-file hashes. Results are recorded
in the checkpoint. Reproduce runtime evidence with:

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

The converter with `--release` must fail for the test-only manifest. Reports remain
under ignored `project/reports/p6_t8/`; preserve the checkpoint summary if these
local reports are later regenerated. Keep full suites isolated through the runner
and inspect report statuses, not exit codes alone. No real saves or Enigma files
were modified by this closeout.
