# P6M2 Build Model and Progression Foundations Tracker

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

## Status

Last updated: 2026-09-23.

**P6M2 is Complete for foundation scope. T1–T9 are Complete.**
**Current: P6M3-T1 is Complete; P6M3-T2 — Combat ordering and diagnostic foundations is next.**
See the [M3 task tracker](P6M3_Shared_Combat_Mechanics_Tracker.md) and its approved first-slice specification.
See [T9 closeout and M3 handoff](P6M2_T9_Closeout_And_M3_Handoff.md) for the acceptance reconciliation and remaining work.
The [T2 audit](P6M2_T2_Cross_Tree_Draft_Audit.md) records the reviewed revisions,
runtime support, presentation requirements, and open decisions. The [final T3 specification](P6M2_T3_Progression_And_Allocation_Rules.md) settles
build foundations. The [T4 policy](P6M2_T4_Content_Workflow_And_Compatibility.md)
defines content authority, identity, validation and Practice Room persistence.
The user selected full fresh-run invalidation of old saves (P6M2-D006).
The [T5 plan](P6M2_T5_Integration_And_Dependency_Plan.md) records dependencies,
UI/diagnostic contracts, M4 builds and 121 checked planning fixtures.
The [T6 implementation](P6M2_T6_Build_Model_And_Resolution.md) supplies tested rank,
resolution and progression foundations. [T7](P6M2_T7_Content_And_Persistence.md) adds
representative test-only conversion, versioned saves, full legacy resets and Practice
persistence. Full redesigned content release remains M3/M5/M4 work.

The [Phase 6 milestone tracker](P6_Milestone_Tracker.md) remains the source of
truth for phase-wide status, scope, and major decisions. This supporting tracker
records M2 tasks, acceptance checklists, evidence, and the handoff to M3.

## Goal and Scope

Make redesigned Rogue builds representable, legal, resolvable, and persistent.
Audit Assassin, Bladedancer, Shadow, and Thief together, define the required
build rules and content workflow, then implement and validate those foundations.

M2 includes ranks, point costs and income, gates, prerequisites, allocation and
refunds, respec, tree intrinsics, automatic skill unlocks, mixed-tree support,
content conversion, stable IDs, save compatibility, and affected Practice Room
state and rotation handling. Initial progression/power targets, UI requirements,
combat dependencies, and diagnostic needs are planning outputs for later work.

Shared combat-effect execution belongs to M3; end-to-end playable integration
and UI prototypes to M4; complete four-tree content to M5; enemy tuning to M6;
finished icons and feedback to M7. M2 can define the data contracts needed by
those milestones without claiming their mechanics or presentation are complete.
Preserve the audited Phase 5 gear and generated-contract foundation. Keep Tree
Lab separate; its preview conventions are not automatically approved game rules.

## Task Overview

| Task | Status | Purpose / Expected Output |
| --- | --- | --- |
| P6M2-T1: Milestone planning | Complete | Agree and record M2 scope, task sequence, deliverables, and completion criteria. |
| P6M2-T2: Cross-tree draft audit | Complete | Four revisions inventoried; runtime classifications, interactions, presentation needs, and assigned questions recorded in the T2 audit. |
| P6M2-T3: Progression and allocation rules | Complete | Specify identities, progression budgets, ranks, gates, prerequisites, mixed-tree access, refunds/respec, and initial power targets. |
| P6M2-T4: Content workflow and compatibility | Complete | Content pipeline, checked identity manifest, fresh-run invalidation and persistence acceptance cases finalized. |
| P6M2-T5: Integration and dependency plan | Complete | Ordered dependencies, essential/experimental scope, UI/diagnostics, Bladedancer M4 core/mixed extension and 121 checked planning fixtures. |
| P6M2-T6: Build model and resolution | Complete | Implement approved build rules, allocation/refunds, intrinsics, unlocks, and mixed-tree resolution with focused tests. |
| P6M2-T7: Content conversion and persistence | Complete | Implement conversion, content validation, save/migration behavior, Practice Room state, and rotation filtering. |
| P6M2-T8: Foundation integration validation | Complete | Verify the foundations together, cover affected inherited behavior, fix defects, and record limitations. |
| P6M2-T9: Closeout and M3 handoff | Complete | Reconcile acceptance evidence, update documentation, and hand off shared combat requirements and downstream questions. |

T2 informs T3 and T4. T5 consolidates their decisions and dependencies before
affected implementation in T6/T7. T6 and T7 include focused tests as changes
land; T8 verifies their integration. T9 follows acceptance verification.
Unresolved questions must be settled before implementing the behavior they
affect, or explicitly assigned to a later milestone without blocking M2's exit.

## Task Completion Checklists

### P6M2-T1 — Milestone planning

- [x] Record the agreed nine-task breakdown and M2 scope.
- [x] Define task outputs, dependencies, and milestone exit criteria.
- [x] Carry forward unfinished M1 design work with named M2 owners.
- [x] Link this tracker from phase tracking and onboarding.

Evidence: the user requested this tracker based on the task breakdown discussed
on 2026-09-21. T1 establishes the work plan; it does not approve specific
progression values, migration behavior, or new combat mechanics.

### P6M2-T2 — Cross-tree draft audit

- [x] Read `Assassin.json`, `Bladedancer.json`, `Shadow.json`, and `Thief.json`
  in `docs/talent_tree_drafts/` together and record the audited revisions.
- [x] Inventory every talent/rank, active skill, intrinsic, automatic unlock,
  prerequisite, and gate represented in the drafts.
- [x] Compare required behavior with runtime support; classify reuse,
  extensions, and new systems with relevant code/resource references.
- [x] Identify ambiguous text, missing rules, cross-tree/gear interactions,
  temporary effects, and presentation needs.
- [x] Produce a mechanics/presentation inventory with questions assigned to
  T3, T4, T5, or a named downstream milestone.

Completion target: a traceable cross-tree inventory, not an assumption that
design-only JSON already specifies executable behavior.

Evidence (2026-09-21): [cross-tree audit](P6M2_T2_Cross_Tree_Draft_Audit.md)
and [exact inventory appendix](P6M2_T2_Draft_Inventory_Appendix.md): 44 talents,
140 rank slots, four intrinsics, 20 automatic slots (18 populated), and two
talent skill grants. `node tools/p6/audit_tree_drafts.js` verifies appendix parity
and repository Tree Lab validation (zero errors/warnings per file); six cross-file
entity-ID collisions are recorded for T4. Q01–Q20 assign remaining decisions.
Runtime source/test inspection only; no new gameplay validation or design approval.

### P6M2-T3 — Progression and allocation rules

Final specification: [T3 progression and allocation rules](P6M2_T3_Progression_And_Allocation_Rules.md).
User decisions on 2026-09-22: 45 shared points; both trees get base intrinsics
and skill unlocks, primary alone gets per-point intrinsic scaling; Adventure
respec is free only between contracts for initial testing. Future respec belongs
at the Alchemist, with a cheap first use and dramatically escalating later costs.
It must preserve build identity rather than encourage fight-by-fight redistribution.
The user requested finalization after answering the foundational questions.
Operational examples are documented; individual mechanic specifications belong
to M3/M5 and numerical difficulty targets to M6.

- [x] Define each tree's role, weakness, and intended gear synergies.
- [x] Define point income/budgets, rank costs/caps, investment gates,
  prerequisite semantics, and primary/secondary tree access.
- [x] Specify mixed-tree opportunity costs and legal-build validation.
- [x] Define allocation, refunds, respec, and handling of invalidated dependent
  ranks, intrinsics, skills, and rotation entries.
- [x] Establish early/middle/mature progression checkpoints, representative
  builds, and initial player-power/difficulty targets for later tuning.
- [x] Record intended player decisions and complexity limits that constrain
  the build model; route detailed combat questions to T5/M3.

Completion target: an agreed build-rule specification with examples of legal
and invalid allocations, including refunds and mixed-tree cases.

Evidence (2026-09-22): finalized linked specification; agreed point income,
allocation and respec policy; legal/invalid examples; actual progression checkpoints;
working tree-role/gear summaries and qualitative goals; named downstream owners.
Document links, active statuses, progression arithmetic and draft inventory parity
checked. Documentation only: no gameplay implementation or balance validation.
The role/target checklist records planning inputs, not approval of every talent
or the withdrawn numerical difficulty proposals.

### P6M2-T4 — Content workflow and compatibility

Specification: [T4 content workflow and compatibility](P6M2_T4_Content_Workflow_And_Compatibility.md).
Registry: [T4 identity manifest](P6M2_T4_Content_Identity_Manifest.json).

- [x] Decide authoritative content sources and the draft-to-runtime workflow.
- [x] Define schema/semantic validation, revision handling, and stable IDs.
- [x] Specify older-save treatment, including changed/removed content and
  invalid allocations; preserve recognizable IDs where appropriate.
- [x] Specify Practice Room state and rotation compatibility, including
  unavailable skills and the inherited 10-slot rotation limit.
- [x] Define conversion and migration acceptance cases before implementation.

Evidence (2026-09-22): inspected save, build, allocator, resolver and Practice Room
paths; mapped 92 draft objects and 37 legacy resources. Identity-manifest and T2
draft-parity checks pass. Conversion, rotation and Practice Room acceptance cases
are specified. User decision P6M2-D006 invalidates old saves and resets the full
run; refund/migration proposals are superseded. Link, whitespace and active-status
checks pass. T4 is Complete as documentation; T5 is next. Runtime, existing saves
and original source drafts are unchanged.

Completion target: a documented content pipeline and compatibility policy.
Normal save/load validation must not be described as power-loss safety; the
audited baseline retains a separately documented save-durability limitation.

### P6M2-T5 — Integration and dependency plan

Specification: [T5 integration and dependency plan](P6M2_T5_Integration_And_Dependency_Plan.md).
Fixtures: [exact planning builds](P6M2_T5_Build_Fixtures.json).

- [x] Map mechanics to essential/experimental scope and implementation owners.
- [x] Assign activation, duration, stacking, refresh, expiration, reset,
  simultaneous-effect ordering, recursion, and crit/proc/retrigger questions
  to M3 specifications where applicable.
- [x] Capture UI requirements for ranks, prerequisites, automatic unlocks,
  rotation details, and temporary effects, including dense/busy M4 cases.
- [x] Capture diagnostic needs such as damage sources, buff uptime, and
  trigger counts; assign state/event contracts to their implementation owners.
- [x] Select a representative M4 build with rationale and dependency list.
- [x] Define focused test cases, integration checks, and initial Balance Lab
  scenario needs; assign icon/asset inventory to M4 and production to M7.

Completion target: a dependency plan and downstream handoff that make the
implementation sequence and remaining decisions explicit.

Evidence (2026-09-22): content/package and Q01–Q20 ownership mapped; M4
Bladedancer 10-point core and Bladedancer 15 / Thief 5 extension selected, with an
explicit Practice role-reversal case. Six purchase profiles and 121 fixtures pass
source-hash, identity, purchase/retention, rank, budget and skill-availability checks;
36 cases cover all mature pairings in both roles and three splits. UI, diagnostics,
asset ownership, initial scenarios and implementation exit gates are documented.
Detailed mechanic approval/implementation and numerical tuning remain downstream.
No gameplay files, player saves or balance reports changed. T6 is next.

### P6M2-T6 — Build model and resolution

- [x] Implement approved ranks, budgets, costs, gates, and prerequisites.
- [x] Implement allocation/refund/respec rules and dependent-choice handling.
- [x] Resolve intrinsics, automatic unlocks, and mixed-tree builds correctly.
- [x] Establish any approved data contracts needed for later combat mechanics.
- [x] Add focused deterministic coverage for legal/invalid builds, rank and
  gate boundaries, refunds, unlocks, and mixed-tree behavior.

Completion target: representative builds resolve according to T3, with evidence
for each implemented rule. New combat-effect execution remains an M3 deliverable.

Evidence (2026-09-23): [implementation and handoff](P6M2_T6_Build_Model_And_Resolution.md);
18 headless Godot tests pass, including all 121 T5 model fixtures. Draft, identity
and planning checks pass. Rank content activation, new persistence and old-save
reset remain T7; visual/playable integration remains M4.

### P6M2-T7 — Content conversion and persistence

- [x] Implement the approved authoring-to-runtime workflow and content checks.
- [x] Convert representative content and verify stable IDs and references.
- [x] Implement new build persistence and agreed older-save behavior.
- [x] Connect Practice Room state and rotation filtering to the build model.
- [x] Test conversion failures, save round trips, compatibility cases, and
  unavailable-skill filtering against the T4 policy.

Completion target: representative content converts reliably and persisted builds
load correctly. Full four-tree gameplay content completion remains in M5.

Evidence (2026-09-23): [T7 implementation and scope](P6M2_T7_Content_And_Persistence.md).
Twenty headless Godot tests, explicit conversion rejection checks, identity and
registry checks pass. New saves/reset and Practice persistence are active against
the complete p6.compat.1 set. Ranked conversion is tested with declared scalar
fixtures; p6.1 whole-tree promotion remains gated on M3/M5/M4.

### P6M2-T8 — Foundation integration validation

- [x] Exercise representative single- and mixed-tree builds across progression
  checkpoints through allocation, refunds, resolution, save/load, and reload.
- [x] Verify intrinsics, unlock removal/restoration, rotations, and Practice
  Room state together under the approved rules.
- [x] Run focused checks and appropriate inherited regression for affected
  surfaces; fix defects and rerun affected checks.
- [x] Record reproducible commands/procedures, results, reports, and limitations.

Completion target: M2 acceptance cases pass with evidence. Automated model/state
checks do not constitute M4 visual or playable integration validation.

Evidence (2026-09-23): [T8 acceptance report](P6M2_T8_Foundation_Integration_Validation.md),
29 passing Godot tests, 176 synthetic lifecycle checkpoints, the 121 draft graph
fixtures, conversion/registry checks and before/after Enigma/save fingerprints.
Ranked Balance Lab readiness and reproducibility are covered; full redesigned
mechanics and rendered/playable acceptance remain M3/M5/M4.

### P6M2-T9 — Closeout and M3 handoff

- [x] Reconcile all tasks and milestone exit criteria against evidence.
- [x] Record remaining issues as accepted limitations or named downstream work.
- [x] Hand off required shared combat mechanics, data contracts, ordering and
  recursion questions, diagnostics, and deterministic test expectations to M3.
- [x] Update phase tracking, onboarding, and relevant implementation guidance.
- [x] Record the final repository state, validation references, and next task.

Completion target: a reproducible M2 foundation and actionable M3 handoff.

Evidence (2026-09-23): [T9 closeout and M3 handoff](P6M2_T9_Closeout_And_M3_Handoff.md), acceptance reconciliation,
repository/evidence fingerprints, static checks and named downstream owners.
The 29-test T8 result is retained; T9 changes documentation only. M3-T1 is next.

## Milestone Exit Criteria

- [x] Cross-tree audit and mechanics/presentation inventory are complete.
- [x] Build rules, initial progression targets, and compatibility policy are documented.
- [x] Dependencies, UI/diagnostic requirements, and the M4 candidate are recorded.
- [x] Representative builds allocate, refund, resolve, and unlock skills correctly. (T8 foundation scope; see evidence report.)
- [x] Content conversion and stable IDs follow the agreed workflow. (T8 foundation scope; see evidence report.)
- [x] New build persistence and agreed older-save behavior are verified. (T8 foundation scope; see evidence report.)
- [x] Practice Room state, mixed-tree behavior, and rotation filtering are verified. (T8 foundation scope; see evidence report.)
- [x] Validation evidence, limitations, and downstream handoff are recorded.

## Carried-Forward M1 Work

| M1 Work | M2 Owner | Later Completion Owner |
| --- | --- | --- |
| T3: Mechanics audit | P6M2-T2 | Required mechanics implemented in M3/M5. |
| T4: Identities and progression | P6M2-T3 | Content completion in M5. |
| T5: Shared combat rules | P6M2-T2/T5 inventory and dependencies | Detailed specifications and execution in M3. |
| T6: Power and enemy targets | P6M2-T3 initial checkpoints/targets | Final targets and tuning in M6. |
| T7: UI and feedback | P6M2-T2/T5 requirements | Prototypes in M4; completion in M7. |
| T8: Icons and assets | P6M2-T5 downstream assignment | Inventory in M4; production in M7. |
| T9: Content and compatibility | P6M2-T4/T7 | Broader closeout verification in M9. |
| T10: Implementation slices/checks | P6M2-T5/T8 | Playable integration in M4. |

## Decision Log

Keep phase-wide decisions in the main tracker's stable `P6-D...` log. Record
M2-specific decisions here with stable `P6M2-D...` IDs and links to specifications.
Retain superseded decisions with their replacements.

| ID | Date | Status | Decision and Rationale | Affects |
| --- | --- | --- | --- | --- |
| P6M2-D001 | 2026-09-21 | Agreed | Adopt the nine-task M2 breakdown requested by the user, with T1 as milestone planning. | T1–T9 |
| P6M2-D002 | 2026-09-22 | Agreed | User selected a mature shared budget of 45 points; dual-capstone builds are valid intended cases. | T3/T6/M6 |
| P6M2-D003 | 2026-09-22 | Agreed | Both selected trees grant base intrinsics and investment skill unlocks; only primary grants per-point intrinsic scaling. | T3/T6 |
| P6M2-D004 | 2026-09-22 | Agreed; refined by user | Respec supports occasional correction while preserving build archetype. Initial testing offers free respec only between contracts, never between fights within a contract. Future Alchemist respec starts cheap and increases dramatically in cost; prices, count reset policy and Alchemist systems remain deferred. Supersedes the earlier location/cost question. | T3/T6/M4; future Alchemist |
| P6M2-D005 | 2026-09-22 | Agreed | Tavern talent rewards are 1/0/4/5 for Mouthy Drunk, Drunk Buddy, Tavern Bouncer and Hired Goon: ten total. Retain zero starting points to end the Tavern at ten. As clarified by the user, each completed contract grants gold plus five talent points, capped at 45 earned total; its boss grants gear. No additional boss point payout or elite point rewards. Seven completed contracts after the Tavern reach the cap. Runtime remains unchanged until implementation. | T3/T6/T7/M6 |

### T4 compatibility decision (2026-09-22)

**P6M2-D006 — Agreed:** The user selected “Invalidate old saves and reset
everything to a fresh run.” Supersedes the proposed progress-preserving talent
refund and individual-talent migration alternatives. Version-1 Adventure saves
reset through the ordinary New Run flow with no retained progress, gear, gold,
points, roles or history. T7 implements and T8 validates the finalized
[T4 policy](P6M2_T4_Content_Workflow_And_Compatibility.md). T4 itself changes no
runtime files or actual saves.

### T5 implementation planning decision (2026-09-22)

**P6M2-D007 — Planning selection:** Under the user's instruction to carry out T5,
select Bladedancer 10 as the first M4 integration build, followed by Bladedancer
15 / Thief 5, plus a Practice role reversal. The [T5 plan](P6M2_T5_Integration_And_Dependency_Plan.md)
records exact allocations, coverage and dependencies. This selects implementation
order, not user approval of unresolved combat semantics. Empty 9-point slots remain
unassigned; adding content stays an explicit M5 decision.

### Further T3 user decisions (2026-09-22)

Latest: one point per rank, total-tree investment across all rows for gates,
and between-contract-only playtest respec are confirmed. Contract completion grants gold plus five talent points once, capped at 45;
bosses grant gear. The separate-payout question is resolved.

- Gilded Blade counts at most 500 current stash gold: +1 percentage point crit
  damage per counted gold, maximum +500% from this talent. Excess gold adds nothing.
- Stolen-gold bonuses count only the current fight; the counter resets to zero
  after the fight, without removing credited stash gold. These meanings are agreed.

- Assassin per-point intrinsic grants flat elemental damage (+10 at ten points).
- Shadow Mastery copies both flat and percentage elemental bonuses, including
  temporary buffs, without removing them: at rank one, +10 flat becomes +1 base
  physical and +150% increased elemental grants a separate x1.15 physical multiplier.
  Detailed dynamic timing/aggregation belongs to M3/M5 before affected implementation.

- Prerequisites need only one rank. Gates use investment in their own tree;
  all rows count toward that tree total (subsequently confirmed).
- Respec changes points only; retain trees and roles. Possible expensive future
  Alchemist secondary/role changes are deferred, not approved.
- Final respec refunds all points. Playtesting allows individual rank edits using
  the current dependency-blocking interaction; no automatic cascade. User reconfirmed testing respec access is between contracts only.
- After the Tavern, contract completion grants gold plus five talent points;
  the boss grants gear. There is no extra boss talent payout. Elite talent rewards
  must be removed. Cap earned points at 45; respec does not change earned total.
- Combat interaction remains player-designed macro playback. This does not approve
  proposed numerical retrigger caps or other new mechanic formulas.
- User confirmed one talent point buys one rank. Remaining individual stat details
  and design targets are carried to their appropriate downstream tasks.

### T3 closeout (2026-09-22)

The user requested finalization once all foundational questions were answered.
T3 is Complete as design/documentation; T4 is next. M2 implementation remains
outstanding. Detailed individual mechanics move to M3/M5, numerical tuning to M6.

## Completed Ideas and Deliverables

| ID | Date | Item | Completion Type / Evidence | Remaining Work |
| --- | --- | --- | --- | --- |
| P6M2-C001 | 2026-09-21 | M2 task plan and tracker | Planning document based on the user-requested nine-task breakdown. | T2–T9; no gameplay implementation or audit completed. |
| P6M2-C002 | 2026-09-21 | T2 cross-tree draft audit | [Audit](P6M2_T2_Cross_Tree_Draft_Audit.md), exhaustive appendix, hashes, reproducible validation, runtime references and question ownership. | T3–T5 decisions; T6 onward implementation/validation. |
| P6M2-C003 | 2026-09-22 | T3 build-rule specification and handoff | [Final specification](P6M2_T3_Progression_And_Allocation_Rules.md), user decisions, examples, progression checkpoints and documentation checks. | T4 compatibility; T5 dependencies; T6 onward implementation; M3/M5 individual mechanics and M6 numerical balance. |
| P6M2-C004 | 2026-09-22 | T4 content and compatibility specification | [Final T4 policy](P6M2_T4_Content_Workflow_And_Compatibility.md), checked identity manifest and explicit invalidation/round-trip acceptance cases. | T5 dependency plan; T7 implementation; T8 verification. |
| P6M2-C005 | 2026-09-22 | T5 integration and dependency plan | [T5 plan](P6M2_T5_Integration_And_Dependency_Plan.md), 121 verified planning fixtures, first M4 builds, UI/event contracts and scenario ownership. | T6/T7 implementation; T8 verification; M3/M5 mechanic review; M4 playable/visual integration. |

## Open Questions and Watch Items

| Question / Risk | Resolve In | Current State |
| --- | --- | --- |
| Which draft mechanics reuse existing support or need new systems? | T2 → T5/M3 | Inventory complete in the T2 audit; classifications with unresolved semantics explicitly marked. Phase question P6-Q002 audit portion resolved. |
| What are point income, ranks, gates, mixed-tree, and respec rules? | T3 | Resolved in T3; implemented and verified in T6–T8. |
| What progression and difficulty targets guide later tuning? | T3 / M6 | Actual reward checkpoints and qualitative goals documented; numerical difficulty targets assigned to M6, P6-Q004. |
| Which source governs content, revisions, and older-save compatibility? | T4 | Resolved in final T4 policy and manifest; old saves reset completely under P6M2-D006. Implemented in T7 and verified in T8. P6-Q006. |
| Which build exercises the foundations for M4? | T5 | Selected Bladedancer 10 core, Bladedancer 15 / Thief 5 extension and Practice role reversal; exact checked fixtures in T5. P6-Q005 planning resolved. |
| What complexity, UI, and diagnostic requirements must shared mechanics expose? | T5 / M3 / M4 | T5 specifies required views, event data, dense/busy cases and ownership. M3 defines execution details; M4 verifies comprehension. P6-Q007 planning portion complete. |
| How do retrigger chains, Bonus Stacks, and Thief gold scaling interact? | T2/T5 / M3/M5/M6 | Carry forward P6-Q008/P6-Q009; do not infer rules from draft wording alone. |

## Update and Evidence Rules

- Use `Not started`, `In progress`, `Pending input`, `Blocked`, `Complete`, or
  `Deferred`; explain blockers/deferrals and name the next action or owner.
- Complete tasks only with concrete outputs or evidence; distinguish design
  agreement, implementation, automated checks, visual checks, and playtests.
- Record validation date, command/procedure, result, and relevant report/commit.
- Maintain task status, checklists, and the phase-wide milestone summary together.
- Keep detailed mechanic specifications in linked documents as they are created.

## Progress History

- **2026-09-23:** Completed T9 and closed M2 for foundation scope. Reconciled all
  exit criteria, recorded repository/evidence fingerprints and limitations, and
  handed C1–C7 contracts and the Bladedancer first slice to M3. M3-T1 next.

- **2026-09-23:** Completed T8 integration validation. Added 176 lifecycle
  checkpoints, ranked Balance Lab adapter/readiness snapshots and boundary tests;
  fixed unknown run enums, stale conversion pointers and an inherited UI fixture.
  Twenty-nine tests pass; Enigma and real save fingerprints unchanged. T9 next.

- **2026-09-23:** Completed T7 foundation conversion/persistence: strict version-2
  Adventure saves, complete old-save reset, independent Practice persistence,
  normalization notices and ranked controls. Declared compatibility release and
  scalar-only test fixtures avoid premature redesigned-content promotion. T8 next.

- **2026-09-23:** Completed T6 rank model, state integration, resolution and
  progression rewards with 18 passing headless tests. All 121 planning fixtures
  pass the runtime model. T7 is next; ranked content/save activation is gated.

- **2026-09-22:** Completed T5 planning under the user’s instruction. Recorded
  dependency packages, unresolved mechanic owners, exact M4 builds, UI/diagnostic
  requirements, scenario plan and 121 checked fixtures. T1–T5 Complete; T6 next.
  No runtime implementation or gameplay validation is claimed.

- **2026-09-22:** Finalized T4 after the user selected complete old-save
  invalidation and a fresh run (P6M2-D006). Policy, manifest and acceptance cases
  reconciled; documentation checks pass. T1–T4 Complete; T5 next.

- **2026-09-22:** T4 policy, exhaustive identity manifest and acceptance cases
  drafted. Identity coverage and original draft parity passed. At this earlier
  checkpoint T4 awaited legacy-save input; resolved by P6M2-D006 above.

- **2026-09-22:** Finalized T3 at the user's request. Consolidated decisions,
  removed superseded proposals, checked examples/checkpoints and assigned remaining
  mechanics/tuning to M3/M5/M6. T4 is next; no gameplay files changed.

- **2026-09-22:** Final reward clarification: contract completion owns gold plus
  five talent points; boss owns gear. Seven completed contracts after the Tavern
  reach 45. Updated checkpoints and cap/single-claim requirements.

- **2026-09-22:** User selected Tavern rewards 1/0/4/5 (ten total), alongside
  five-point boss rewards. Recorded D005; gameplay reward resources unchanged.

- **2026-09-22:** User clarified D004: free between-contract respec during initial
  testing; preserve archetypes and avoid fight-by-fight redistribution. Future
  Alchemist and escalating prices are deferred. T3 remains In progress.

- **2026-09-22:** Started T3; drafted complete rules and examples, inspected all
  three runtime/reward point caps, recorded D002–D004, and requested focused
  follow-up decisions. T3 remains In progress pending agreement.

- **2026-09-21:** Completed T2 cross-tree audit and generated source inventory.
  Recorded all four hashes, six identity collisions, support/presentation matrix,
  and Q01–Q20 follow-ups. T3 is next; no gameplay or balance decisions approved.

- **2026-09-21:** Created the M2 tracker and completed T1 milestone planning at
  the user's request. T2 is next; T2–T9 have not started. Documentation only;
  no new gameplay validation is claimed.

## Related Documents

- [Phase 6 milestone tracker](P6_Milestone_Tracker.md)
- [Project onboarding](P6_Project_Onboarding_Context.md)
- [Tree draft collection and provenance](talent_tree_drafts/README.md)
- [Skill-tree redesign brief](P6_Skill_Tree_Redesign_Brief.md)
- [Current build-system map](P6_Current_Player_Build_System_Map.md)
- [Baseline content audit](P6_Skill_Tree_Content_Audit.md)
- [Implementation and test handoff](P6_Implementation_And_Test_Handoff.md)
- [Audited baseline integration](P6_Audited_Baseline_Integration.md)
- [Separate Tree Lab tracker](tree_lab_docs/P6_Tree_Lab_Implementation_Tracker.md)
