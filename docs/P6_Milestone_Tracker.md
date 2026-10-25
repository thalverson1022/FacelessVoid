# Phase 6 Milestone Tracker

Last updated: 2026-10-24.

**M7 — Icons and Player Feedback Completion is Complete, T1–T11, under D053; presentation accepted under D052. Next milestone: M8 — Legendary Item Revamp and Expansion (In progress; T1–T8 Complete under D082; T9 presentation/feedback Pending input under D084).** [Final M7 closeout and M8 handoff](P6M7_T11_Closeout_And_M8_Handoff.md) records scoped regression, triaged legacy test exceptions and accepted limits. Use the [M7 task tracker](P6M7_Icons_And_Player_Feedback_Completion_Tracker.md) for its acceptance history. M9 — Integrated Playtest and Refinement and M10 — Regression and Closeout remain Not started.

M1–M7 are complete within their recorded scopes. Adventure is enabled. Retain current values and intentional hard counters under M6 D015. M7 final presentation is explicitly accepted; broader full-run/unusual-build feedback belongs to M9. Legendary revamp and expansion is now Phase 6 M8 under P6M8-D001; the earlier next-phase deferral is superseded. No numerical approval is pending.

## Goal and Scope

Redesign Assassin, Bladedancer, Shadow and Thief with distinct identities, meaningful progression, gear synergies and readable combat behavior. Phase 6 covers build/progression foundations, shared combat mechanics, playable trees, supporting enemy balance, UI, temporary effects, icons, Practice Room, Balance Lab, persistence, and the approved Legendary item revamp, expansion and scoped gear stat pool additions.

Preserve the Phase 5 gear and generated-contract foundation. New classes, broad gear/route/economy redesign, The Road, true endless scaling and wholesale combat resolver replacement remain outside this phase unless explicitly promoted. See the [audited baseline](P6_Audited_Baseline_Integration.md) for inherited foundations and limitations.

## Milestone Overview

| Milestone | Status | Purpose | Exit Criteria |
| --- | --- | --- | --- |
| P6M1: Design Audit and Planning | Complete | Establish the roadmap, scope, draft inputs, tracking, and planning handoff. | Revised at closeout (P6-D006): roadmap agreed, drafts collected, tracking/onboarding established, and unfinished detailed design assigned to later milestones. |
| P6M2: Build Model and Progression Foundations | Complete — T1–T9 foundation scope | Use the completed cross-tree audit to decide build foundations, then implement ranks, gates, prerequisites, intrinsics, automatic unlocks, mixed-tree support, content conversion, and migration. | Build rules and migration policy are documented; representative builds allocate, refund, resolve, and save/load correctly, including the agreed treatment of older saves. |
| P6M3: Shared Combat Mechanics | Complete — T1–T11 shared-mechanics scope | Implement shared effect systems required by approved drafts, with timing, ordering, caps, and event reporting. | Each new shared mechanic has focused deterministic coverage and exposes the state needed for UI and playback. |
| P6M4: Playable Integration and UI Validation | Complete — T1–T11 scoped playable/UI validation | Integrate a representative build through selection, rotation, combat, effect display, and Practice Room; prototype dense and busy UI cases; create Icon Lab for skill/talent asset assignments. | The build works end to end and its mechanics are understandable; major architecture and layout uncertainties are resolved. |
| P6M5: Complete Rogue Tree and Skill Implementation | Complete — T1–T11 implementation scope | Implement the four approved trees and their skills, intrinsics, unlocks, tooltips, and validation. | All approved content is playable; progression and mixed-tree interactions work. Balance values remain provisional. |
| P6M6: Enemy Balance and Adventure Progression | Complete — T1–T11; D015 exceptions retained | Tune player power and enemy challenge across progression stages, gear levels, tree identities, and matchups. | Representative Adventure runs and deterministic scenarios meet agreed difficulty targets; exceptions are documented. |
| P6M7: Icons and Player Feedback Completion | Complete — T1–T11; D052 acceptance / D053 closeout | Complete icons, tree/skill presentation, temporary-effect displays, and necessary combat cues. | All approved features have readable, consistent presentation at actual display sizes and under heavy effect activity. |
| P6M8: Legendary Item Revamp and Expansion | In progress — T1–T8 Complete; T9 Pending input under D084; T10–T12 Not started | Revamp existing Legendaries, add approved items that use the new build/combat systems, and expand the regular gear stat pool under D002. | Approved roster works end to end with understandable choices, verified interactions, acquisition and save behavior, user acceptance and a documented M9 handoff. |
| P6M9: Integrated Playtest and Refinement | Not started | Play full runs and unusual builds with the revised Legendary roster; refine choices, pacing, comprehension, and usability. | The agreed playtest checklist passes; remaining issues are explicitly accepted or deferred. |
| P6M10: Regression and Closeout | Not started | Complete regression, migration/replay verification, documentation, and an optional playtest package. | A validated, reproducible Phase 6 baseline and complete handoff are recorded. |

These are completion checkpoints, not rigid work silos. M1 established UI,
balance, and asset workstreams; their detailed design is carried forward below.
UI is exercised in M4, scenarios grow
with mechanics, and icon production can start once identities stabilize. M6 and
M7 complete their respective passes. M5 has checkpoints for each tree and then
mixed-tree behavior.

## Task Trackers and Completion Evidence

| Milestone | Authoritative task record / handoff |
| --- | --- |
| M1 | Roadmap/planning closeout under P6-D006; detailed audit/design carried forward. [Historical task record](P6_Milestone_Tracker_History_Through_M6.md#p6m1-task-tracker). |
| M2 | [Build model and progression tracker](P6M2_Build_Model_And_Progression_Foundations_Tracker.md). |
| M3 | [Shared combat mechanics tracker](P6M3_Shared_Combat_Mechanics_Tracker.md). |
| M4 | [Playable integration and UI tracker](P6M4_Playable_Integration_And_UI_Validation_Tracker.md); [accepted tree UI](P6M4_T10_Full_Tree_UI_UX_Plan.md). |
| M5 | [Complete Rogue implementation tracker](P6M5_Complete_Rogue_Tree_And_Skill_Implementation_Tracker.md); [closeout](P6M5_T11_Closeout_And_M6_Handoff.md). |
| M6 | [Balance and Adventure tracker](P6M6_Enemy_Balance_And_Adventure_Progression_Tracker.md); [final evidence and M7 handoff](P6M6_T11_Closeout_And_M7_Handoff.md). |
| M7 | [Final closeout and M8 handoff](P6M7_T11_Closeout_And_M8_Handoff.md); [tracker](P6M7_Icons_And_Player_Feedback_Completion_Tracker.md). T1–T11 Complete under D053, user presentation acceptance D052; retained legacy test/capability exceptions explicitly owned. |
| M8 | [Legendary Item Revamp and Expansion tracker](P6M8_Legendary_Item_Revamp_And_Expansion_Tracker.md); T1–T3 Complete; [T2 evidence](P6M8_T2_Current_Legendary_And_System_Audit.md); [T3 implementation closeout](P6M8_T3_Closeout_And_Verification.md) under D008. [T4 roster and review](P6M8_T4_Legendary_Roster_Proposal.md) approved under D010; T4 Complete. [T5 consolidated specification](P6M8_T5_Legendary_Mechanics_Specification.md) Complete under D073, including user approval of technical defaults. [T6 prototype findings](P6M8_T6_Representative_Prototypes_And_Findings.md) approved under D076; T6 Complete (307 assertions, five focused regressions; production unchanged during T6). [T7 implementation/results](P6M8_T7_Implementation_And_Verification.md) approved under D079: 11 passing suites, all16 items, isolated saves and actual Practice UI. T7 Complete; [T8 acquisition/progression/persistence results](P6M8_T8_Acquisition_Progression_And_Persistence_Verification.md) approved under D082; T8 Complete (11 passing suites,3,852 counted checks, loot rules preserved). [T9 presentation/screenshots](P6M8_T9_Presentation_And_Combat_Feedback_Verification.md) Pending input under D084; T10–T12 Not started. |

## Milestone numbering change — 2026-10-17

Under [P6M8-D001](P6M8_Legendary_Item_Revamp_And_Expansion_Tracker.md#decision-log), the user approved inserting Legendary Item Revamp and Expansion as M8. Former M8 Integrated Playtest and Refinement is M9; former M9 Regression and Closeout is M10. M1–M7 and their evidence remain complete within their recorded scopes. Historical documents, decision IDs, report names and filenames retain their original numbering; use this mapping for downstream ownership. No specific item roster, values or experimental Bandit curve is adopted by this planning decision.

## Current Baseline and Decisions

- Four Rogue trees, 44 talents / 140 ranks. Adventure uses `p6.adventure.1`; Practice/Test Mode use `p6.playable.shadow.1`.
- Tavern rewards 1/0/2/3; six points at exit; three per completed contract; cap 45 after C13. Already earned points remain preserved. Test Mode defaults to six points and retains 10/45 presets.
- Retain shared allocation/role rules and accepted respec behavior. Adventure refunds are between contracts; Test Mode allows planning-phase resets between fights; Practice has an editable budget.
- Adventure uses `user://adventure_p6_m6.json`; legacy `user://save.json` is preserved without migration. Practice stays isolated. Older reset/migration decisions describe historical transitions, not current Adventure migration instructions.
- M6 adopted Steal 1100 ms base / 650 ms minimum and Drunk Buddy armor 140. Current enemy values and intentional counters are retained. Rejected T6 nerfs and the experimental Bandit curve were not adopted.
- Optimization, synergies, preparation and informed matchup choices should matter. Diagnostic win rates do not promise universal success. The finite 30-boss catalog and C30 plateau remain accepted prototype limitations.
- The [M6 final verification](P6M6_T11_Closeout_And_M7_Handoff.md) reports 95 distinct suites, four rendered executions and ten current static checks. It does not establish final presentation acceptance or completed future user playtesting.

Detailed numerical/mechanics contracts belong in the [combat reference](Combat_Mechanics_Reference.md) and their task decisions; check live resources when editing descriptions. Phase-wide decisions P6-D001–D008 and earlier progression/implementation history remain in the [historical decision log](P6_Milestone_Tracker_History_Through_M6.md#major-decision-log). Subsequent decisions stay in the linked milestone trackers.

## Current Work and Downstream Owners

| Work | Owner / next action |
| --- | --- |
| Icons, descriptions, effect displays, crowded popups, necessary combat cues and accessibility | M7 Complete under D053, presentation accepted D052. Preserve accepted T5–T10 conventions and recorded limits; further concrete UX/playtest refinement belongs to M9. |
| Hands-on comprehension and balance observations | User playtesting alongside M7 under M6 D015; T9 records findings, T10 resolves or assigns them. |
| Broader full-run and unusual-build refinement | M9, after the Legendary revamp. Assess choice clarity, pacing, comprehension and usability; fix agreed issues and record exceptions. |
| Legendary revamp, gear stat pool additions, excess power and gold-scaling tradeoffs | M8; [tracker](P6M8_Legendary_Item_Revamp_And_Expansion_Tracker.md) and [prior evidence](P6_Legendary_Remake_Next_Phase_Handoff.md). |
| Broad regression, save/replay checks, environment/engine/export qualification, final documentation and optional package | M10. Record reproducible evidence and remaining limitations. |

## Update and Evidence Rules

- Use `Not started`, `In progress`, `Pending input`, `Blocked`, `Complete` or `Deferred`; explain blockers/deferrals and name the next action.
- Keep this document as the phase index. Put task progress, decisions and detailed evidence in the relevant milestone tracker or linked task record.
- Update the current status in place. Keep onboarding short; do not prepend duplicate chronological notices to several documents.
- Completion needs concrete outputs and evidence, with date, command/manual procedure, result and report location. Distinguish automated, rendered and hands-on validation.
- Scope changes and mechanics decisions require a recorded decision. Historical candidates, diagnostic results and planning completion are not runtime adoption or player acceptance.

## Progress History

- **2026-10-22 — M8-T3 Complete (P6M8-D008):** [Implementation closeout](P6M8_T3_Closeout_And_Verification.md) records exact gear pools, timing/crit/inventory mechanics, Practice/UI and save compatibility, 33 passing suites, isolated old-reader rejection, retained historical failures and economy risk assigned to T10. T4 roster and identity design is next.

- **2026-10-22 — M8-T3 specification ready (P6M8-D007):** User requested reconciliation of weights/technical rules. [Implementation specification](P6M8_T3_Gear_Stat_Implementation_Specification.md) records the full 99-entry pool and deterministic generation, uncapped multiplicative CDR, additive duration, crit/inventory, Practice and save contracts. T3 In progress; runtime implementation and validation remain. Documentation/source/arithmetic checks only.

- **2026-10-22 — M8-T3 timing/pool decisions (P6M8-D006):** User replacement slot pools/base ranges and confirmed uncapped multiplicative CDR, retained All Stacks, additive timed-buff duration including Penetration/Potency are recorded in the [current T3 decisions](P6M8_T3_Gear_Stat_Pool_Proposal.md#current-decisions--2026-10-22). Near-zero cooldowns are accepted. Weight/detail reconciliation, implementation and verification remain; documentation only.

- **2026-10-17 — M8-T3 user-selected scope (P6M8-D005):** Four Rare stats—Cooldown reduction, Increased Buff Duration, Crits apply penetration/potency—and the inventory-economy Special replace the earlier candidate package. [Revised proposal](P6M8_T3_Gear_Stat_Pool_Proposal.md) supplies base ranges, eligible slots and detailed rules for review. T3 remains Pending input; no implementation or numerical approval.

- **2026-10-17 — M8-T3 proposal prepared (P6M8-D004):** [Gear stat proposal](P6M8_T3_Gear_Stat_Pool_Proposal.md) recommends Cooldown Recovery, Self-Buff Duration and Decay Strength pool activation, with exact contracts and explicit risks. T3 Pending input for review; every candidate/value/policy remains unapproved. No runtime changes or gameplay tests.

- **2026-10-17 — M8-T2 Complete (P6M8-D003):** [Source audit](P6M8_T2_Current_Legendary_And_System_Audit.md) inventories current gear/stat pools, five Legendaries, runtime/lifecycle/save/UI support, existing coverage and downstream constraints. Source/document checks only; no new mechanics, values or policies adopted. T3 gear stat design review is next.

- **2026-10-17 — M8 gear-stat task added (P6M8-D002):** Insert T3 Gear stat pool expansion after the audit; former T3–T11 become T4–T12. Current plan has twelve tasks; T2 remains next. Stat selection, values and pool rules await T3 design review. Documentation only.


- **2026-10-17 — M8 inserted (P6M8-D001):** User approved the eleven-task Legendary revamp and expansion plan and requested documentation. [M8 tracker](P6M8_Legendary_Item_Revamp_And_Expansion_Tracker.md) created; T1 planning Complete, T2–T11 Not started. Former M8/M9 become M9/M10. Historical acceptance/evidence retained; no gameplay changes or item-design adoption.


- **2026-10-15 — M7-T5 Complete (D039):** User accepted the finished tooltip format and requested closeout. [Accepted conventions and evidence](P6M7_T5_Closeout_And_Accepted_Conventions.md). M7 remains In progress; T6 is next and T6–T11 remain Not started. Documentation-only verification; no gameplay changes.


- **2026-10-09 — M7-T3 Complete:** User requested closeout after accepting live promotion excluding combat-log changes. [Accepted conventions and handoff](P6M7_T3_Closeout_And_Accepted_Conventions.md) records evidence and remaining T4/T6 details; T4 is next.

- **2026-10-08 — M7-T3 Pending input:** [Design package](P6M7_T3_Visual_Conventions_And_Feedback_Design.md) and interactive examples prepared and checked. User selection/acceptance remains; no runtime or art changes.

- **2026-10-08 — M7-T2 Complete:** [Presentation/asset audit](P6M7_T2_Presentation_And_Asset_Audit.md) records complete live mapping coverage, wording and dense-feedback issues, validation and downstream owners. T3 is next. Gameplay and approved assignments unchanged.

- **2026-10-08 — M7-T1 Complete:** User accepted the eleven-task plan and requested closeout (P6M7-D002). Planning checklist, active status and onboarding updated; T2 presentation and asset audit is next. T2–T11 remain Not started. Documentation only.

- **2026-10-08 — M7 planning:** Created the eleven-task M7 tracker at the user's request. T1 In progress; T2–T11 Not started. Pruned onboarding and condensed this phase index; preserved the former phase tracker in the linked history archive. Documentation only.
- **2026-10-08 — M6 complete:** T1–T11 Complete, with retained-scope acceptance under D015 and final verification under D016. See the linked M6 handoff for evidence and exceptions.

Earlier history is retained in [Phase 6 tracker history through M6](P6_Milestone_Tracker_History_Through_M6.md). That archive is a historical reference, not the next-action guide.

- **2026-10-08 — M7 D004:** User authorized the [Test Mode-only preview](P6M7_T3_Test_Mode_Preview.md), with Original/Lanes/Event list comparison. Adventure and Practice remain on baseline presentation. T3 awaits hands-on review; no milestone-wide presentation adoption.

- **2026-10-08 — M7 D005:** User rejected the Test Mode preview. Original presentation restored from verified pre-preview source, preview controls removed; T3 remains Pending input for a revised direction.

- **2026-10-08 — M7 D006:** User approved and requested the [four-skill category prototype](P6M7_T3_Category_Prototype.md). Implemented in Test Mode with Original comparison; final hands-on acceptance remains pending.

- **2026-10-17 — M7 Complete (D053):** Final regression, legacy-exception triage, source/asset checkpoint and [M8 handoff](P6M7_T11_Closeout_And_M8_Handoff.md) complete after explicit D052 presentation acceptance. M8/M9 Not started.
