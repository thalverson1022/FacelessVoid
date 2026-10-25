# P6M6 — Enemy Balance and Adventure Progression

Current status: **Complete — T1–T11 Complete.** Last updated: 2026-10-08.

The [final closeout and M7 handoff](P6M6_T11_Closeout_And_M7_Handoff.md) records 95 distinct passing suites, four rendered executions and ten current static checks. D015 accepts the retained scope and preserves current values and intentional counters; further hands-on balance review accompanies M7. Legendary refinement remains separate next-phase work. No numerical approval is pending.

M7 planning is now active in the [M7 tracker](P6M7_Icons_And_Player_Feedback_Completion_Tracker.md). The sections below retain the M6 plan, completion evidence and decisions as dated records. Repeated status preambles were removed during M7 documentation cleanup; their history remains in the [phase archive](P6_Milestone_Tracker_History_Through_M6.md).

## Goal and scope

Make the redesigned Rogue trees support satisfying Adventure progression, with
measurable difficulty targets, meaningful build choices and reproducible evidence.
Tune player power and existing enemy challenge across progression stages, gear
levels, subclass identities and mixed builds. Validate the complete reward and
spending loop and establish Adventure readiness before normal access is enabled.

Start from the [M5 closeout and M6 handoff](P6M5_T11_Closeout_And_M6_Handoff.md),
[phase tracker](P6_Milestone_Tracker.md) and
[current subclass protocol](P6_Subclass_Balance_Protocol.md). The accepted baseline
is P6M5-D023 plus the T10 Practice gear-unlock pruning fix: 44 talents / 140 ranks
are playable in Test Mode and Practice using `p6.playable.shadow.1`. T8 now enables
Adventure using `p6.adventure.1` and a separate fresh-run save slot.

Preserve established allocation, progression, respec and compatibility rules unless
a specific change is reviewed and recorded. Preserve the Phase 5 gear and generated
contract foundations, stable identities, accepted tree UI and separate Tree Lab.
New classes, gear-system or broad economy/route redesign, wholesale combat resolver
replacement and broad generated-monster architecture changes remain outside scope.
Final presentation belongs to M7, broader playtest refinement to M8 and packaging
qualification to M9.

## Task plan

The eleven-task plan is complete. D007/D008 remain adopted; D010 rejects the prior T6 nerfs. D015 accepts the retained scope and defers further hands-on balance review to M7. T11 verifies the retained baseline and records the final evidence and downstream owners. No numerical approval is pending.

| Task | Status | Deliverable / completion criteria |
| --- | --- | --- |
| M6-T1 â€” Milestone planning and acceptance criteria | Complete | Goals, scope, eleven-task sequence, dependencies, review checkpoints, acceptance matrix and downstream owners recorded here; user-requested planning closeout recorded in D001. |
| M6-T2 â€” Difficulty and progression targets | Complete | [Final specification and T4 handoff](P6M6_T2_Difficulty_And_Progression_Targets.md); D004 finalizes timing, diagnostic success references, practical acceptance, gear/macro expectations, matchup/exception policy and prototype limits. Design completion only. |
| M6-T3 â€” Adventure and enemy baseline audit | Complete | [Audit and measurements](P6M6_T3_Adventure_And_Enemy_Baseline_Audit.md);  Existing enemies, defenses, mechanics, contracts, bosses, rewards and gear availability mapped to progression stages; current measurements, Watchmen comparison and Adventure integration gaps documented. |
| M6-T4 â€” Representative balance scenarios and tooling | Complete | [Closeout and reproduction](P6M6_T4_Representative_Balance_Scenarios_And_Tooling.md); 576 snapshots, 728 cases, 29,120 held-out first attempts; replay/Practice parity and preservation checks pass.  Reproducible builds, macros, gear sets, enemy matchups, seed cohorts and report procedures established; four subclasses, mixed builds, both roles and reasonable/optimized play covered; actual encounter and progression coverage added to the existing protocol. |
| M6-T5 — Player power and subclass tuning | Complete | D007 adopted Steal at 1100 ms; [verification](../project/reports/p6_m6_t5_adoption/results.md) and [investigation](P6M6_T5_Player_Power_Investigation_And_Proposal.md) retain evidence and T6/T7 follow-ups. |
| M6-T6 — Enemy and boss tuning | Complete | [Optimization and counterplay closeout](P6M6_T6_Optimization_And_Counterplay_Review.md): retain live enemy values; reject prior nerfs; record intentional counters and matched build/choice evidence. Nine regressions pass. Full-run evidence and retained-scope acceptance closed in T9/T10 under D015. |
| M6-T7 — Rewards, gear and economy progression | Complete | [Assessment](P6M6_T7_Rewards_Gear_And_Economy_Assessment.md); 128 victory-dependent trajectories, gold/gear/spending ledgers, Thief and Shadow controls, acquired-build T6 handoff and regressions. No new numerical change proposed; T9/T10 acceptance subsequently closed under D015. |
| M6-T8 — Adventure integration and controlled access | Complete | [Integration and access evidence](P6M6_T8_Adventure_Integration_And_Controlled_Access.md): redesigned registry, separate fresh-run save slot, usable tag guide, 12 pairings / 360 roundtrips, two new suites and twenty regressions. Adventure enabled; no numerical changes. |
| M6-T9 — Representative full-run validation | Complete | [Run validation and T10 handoff](P6M6_T9_Representative_Full_Run_Validation.md): 144 main runs / 48 controls, all twelve pairings, earned resources and natural endpoints, eight rendered earned checkpoints, independent verification and eight regressions. No numerical changes; T10 accepted retained scope under D015; further hands-on playtesting is deferred to M7. |
| M6-T10 — Balance refinement and acceptance | Complete | [User-accepted closeout](P6M6_T10_Accepted_Closeout.md), D015: retain current values and intentional counters; accept current evidence for M6. Further hands-on balance review accompanies next milestone’s icon/UI playtesting; Legendary refinement remains deferred to the separate remake. No experimental curve adopted or approval pending. |
| M6-T11 — Regression, closeout and M7 handoff | Complete | [Closeout and M7 handoff](P6M6_T11_Closeout_And_M7_Handoff.md): 95 distinct suites, four rendered executions, ten current static checks; four stale tests repaired, retained gameplay baseline verified, exceptions and owners recorded. |

## Dependencies and review checkpoints

T2 establishes the intended experience, timing and diagnostic numerical references;
T3 supplies the reconciled baseline audit. T4 establishes the measurement matrix
using both and the practical acceptance standard in D004. Complete these
checkpoints before changing balance coefficients.

T5â€“T7 form a bounded tuning loop: player power, enemy challenge and rewards affect
one another. Record each candidate, expected outcome and measured result. Review
concrete tuning proposals against the agreed targets before affected implementation;
planning completion does not approve unspecified values or new mechanics.

T8 uses the T3 integration inventory and T2/T4 acceptance gates. Isolated developer
validation may support earlier tasks; normal Adventure access depends on verified
content, progression and persistence readiness. T9 validates complete runs after
initial tuning and integration. T10 resolves findings, then T11 closes the milestone.
Access readiness in T8 does not substitute for full balance acceptance in T10.

### T1 planning completion checklist

- [x] Milestone goals and scope boundaries recorded.
- [x] Eleven tasks and completion criteria recorded in the established format.
- [x] Dependencies, tuning loop and review checkpoints identified.
- [x] Milestone acceptance areas and validation ownership assigned.
- [x] Open design decisions assigned to later tasks.
- [x] User-requested planning closeout recorded; T2 identified as next.

## Milestone acceptance matrix

| Area | Required evidence | Owner |
| --- | --- | --- |
| Difficulty targets | Agreed checkpoints, timing, diagnostic success references, practical acceptance, gear/macro assumptions and exception policy. | T2, T10 |
| Baseline and coverage | Enemy/progression inventory, integration gaps and reproducible scenario matrix linked to targets. | T3â€“T4 |
| Subclass and mixed-build viability | Early, middle and mature builds measured; both roles, short/long fights and reasonable/optimized macros assessed without assuming equal dummy DPS. | T4â€“T5, T9â€“T10 |
| Enemies and bosses | Representative defenses/mechanics, boss encounters and Watchmen comparison meet targets or document accepted exceptions. | T3, T6, T10 |
| Scaling boundaries | Poison fuel, defense reduction, theft/gold ramp and caps, and normal legal retrigger below 100% checked in relevant builds and gear. | T5â€“T7 |
| Rewards and economy | Point progression, gear acquisition, gold income, shop spending and applicable Thief reward/stolen/current gold, Increased Gold and Overkill Gold interactions assessed. | T7, T9 |
| Adventure readiness | Entry, allocation/refunds, progression, rewards, save/load and revision compatibility pass defined access gates with isolated saves. | T8 |
| Complete runs | T9 earned-run evidence and T10 accepted exceptions establish milestone acceptance. D015 explicitly defers additional hands-on observations to M7; future playtesting is not claimed complete. | T9â€“T10 |
| Regression and handoff | Relevant regression passes; final values, reproducible evidence, exceptions and downstream owners recorded. | T11 |

### Milestone completion checklist

- [x] Milestone planning complete.
- [x] Difficulty and progression targets agreed before tuning; percentages are diagnostic references under D004.
- [x] Existing enemy/Adventure baseline audited and representative scenarios established.
- [x] Four subclasses and mixed builds assessed across progression and gear levels.
- [x] Player, enemy and boss tuning meets targets or records accepted exceptions.
- [x] Watchmen comparison and scaling boundaries resolved.
- [x] Reward, gear and economy progression validated.
- [x] Adventure integration, persistence and access gates passed.
- [x] Representative victory-dependent Adventure trajectories validated through natural endpoints (T9); no universal completion guarantee.
- [x] Retained-scope balance acceptance complete under D015; hands-on review and Legendary refinement have named downstream owners.
- [x] Regression, documentation and M7 handoff complete.

## Decisions and work assigned downstream

| Question / work | Owner / point of resolution |
| --- | --- |
| Fight timing, success references and intended boss difficulty | Resolved by T2/D004; T4 measures and T10 assesses the practical experience standard. |
| Expected gear, ordinary/optimized macros and acceptable subclass differences | T2 defines expectations; T3â€“T4 establish concrete coverage. |
| Scenario selection, cohort sizes and treatment of variance | T4; preserve the existing protocol as baseline evidence and specify any extensions. |
| Current Shadow lead and sustained Thief differences | T5â€“T7 investigate actual matchups and progression; neutral-dummy rankings alone do not select tuning. |
| Any change to established point rewards, allocation/respec rules or mechanics | Relevant task records a specific proposal and decision before implementation; no implicit redesign in planning. |
| Adventure release revision, compatibility and enablement requirements | T3 inventories gaps; T8 specifies, implements and verifies the agreed treatment. |
| Balance exceptions and remaining risks | T10 records acceptance or explicit ownership; T11 carries them into the handoff. |
| Final icons, crowded combat text, effect cues, accessibility and audio/lifecycle polish | M7, preserving accepted layout and Icon Lab assignments. |
| Broader unusual-build playtesting and usability refinement | M8. |
| Shader/certificate environment diagnostics, clean engine teardown and export qualification | M9. |

## Decision log

| ID | Date | Status | Decision |
| --- | --- | --- | --- |
| P6M6-D002 | 2026-10-07 | User-confirmed experience direction | Smooth progression through approximately contract 10, followed by indefinite difficulty escalation with eventual failure expected. Timing, numerical thresholds and ramp slope remain to be specified and reviewed in T2. |
| P6M6-D003 | 2026-10-07 | User-confirmed timing and scope clarification | Regular fights around 15â€“30 seconds and bosses 30â€“60 seconds are appropriate. Current scaling is expected to be close enough for this phase; prioritize validation and focused adjustments. Contract endurance currently tests fun. The future optional final map, The Road, can be entered when the player feels ready and leads through bespoke bosses to the mountaintop dragon; defeating it is victory, with optional endless contracts afterward escalating to impossible levels. Record this future direction without adding The Road implementation to Phase 6. Candidate success percentages remain unapproved. |
| P6M6-D009 | 2026-10-08 | User-confirmed difficulty clarification | Hard, optimization-driven play; weak builds may fail and severe build counters are intentional possibilities. Reading tags, preparation and informed avoidance should matter. Earlier smooth-C10 language and percentages do not imply guaranteed progression. |
| P6M6-D010 | 2026-10-08 | T6 investigation closeout; no numerical adoption | Matched optimization, skill-omission and tag-choice evidence supports retaining current enemy values and rejecting the three saved nerfs. T6 focused review Complete; T8 integration and T9/T10 full-run/hands-on acceptance remain open. |
| P6M6-D011 | 2026-10-08 | T8 integration adopted after readiness verification | Enable redesigned Adventure at `p6.adventure.1` with a separate fresh-run save slot, preserved legacy files and tag guide. No numerical changes; T9/T10 balance acceptance remains open. |
| P6M6-D012 | 2026-10-08 | T9 evidence closeout; no balance adoption | Matched complete-run evidence rewards preparation while exposing excessive margins, gold-scaling gear effects and severe counter losses. Retain current values; T10 owns concrete refinement proposals and hands-on acceptance. |
| P6M6-D013 | 2026-10-08 | T10 candidate prepared for review; not adopted | Isolated Bandit Blade diminishing-return candidate: gold-derived bonus = 100 × gold / (1000 + gold); other affixes and enemy values retained. Flat coefficient cuts are not recommended. Snapshot discrimination improves, but no tested candidate journey completes all 30 bosses. Human playtest feedback and explicit numerical approval precede live adoption and T10 acceptance. |
| P6M6-D014 | 2026-10-08 | User-directed scope deferral | Separate Legendary Item remake next phase. Defer Bandit/Legendary refinement; withdraw T10 candidate approval and mandatory candidate playtest requests. Preserve evidence and live values. Human acceptance of retained M6 scope remains open; T10 is not marked Complete. |
| P6M6-D016 | 2026-10-08 | Authorized T11 work completed | Final regression, source protection and documentation reconciliation complete. T1–T11 and M6 Complete; M7 icon/UI feedback plus user playtesting next. D015 exceptions retained; no numerical change or new balance approval. |
| P6M6-D015 | 2026-10-08 | User accepts T10 closeout | Accept retained milestone scope and evidence; preserve current values and intentional counters. User plans substantial playtesting during next milestone’s icon/UI feedback, where balance questions can be revisited. Legendary remake remains deferred; no Bandit experimental curve adopted. T10 Complete, with future hands-on validation explicitly deferred; T11 remains Not started. |
| P6M6-D008 | 2026-10-07 | User-approved implementation | Drunk Buddy armor 160→140, retaining HP 155, Poison resistance 10%, 18-second duration and reward definitions. Live 688-sample candidate/control replay and four regressions pass. T6 remains In progress for generated-matchup work; no approval currently pending. |
| P6M6-D007 | 2026-10-07 | User-approved T5 proposal implemented | Steal base execution 1300 to 1100 ms, minimum 650 ms retained; all other effects unchanged. Live Tavern confirmation and focused/mixed regression passed. T5 Complete; enemy/economy follow-ups assigned to T6/T7. |
| P6M6-D006 | 2026-10-07 | User-approved implementation and rerun | Tavern rewards become 1/0/2/3 to pace skill unlocks; contract rewards remain three, cap remains 45 (after C13). Default Test Mode budget follows the six-point Tavern exit, with prior presets retained. Preserve already earned points and rerun the balance assessment. |
| P6M6-D005 | 2026-10-07 | User-approved implementation | Permanently award three talent points per completed contract, preserving Tavern 1/0/4/5 and the 45-point cap. Existing earned points remain; future claims follow the new rule. Cap is reached after C12. Adopt the tested progression change without additional enemy, gear or skill tuning. |
| P6M6-D004 | 2026-10-07 | User-authorized T2 closeout | Finalize T2 using the discussed choices: success percentages are diagnostic references, not mandatory gates; preserve distinct matchup weaknesses and investigate persistent pre-C10 walls under sensible gear/coherent macros. Accept the existing 30-boss ending and C30 plateau as prototype limitations; The Road and true endless scaling remain future work. T3 is reconciled, T1â€“T3 are Complete, and T4 is next. This is design acceptance, not gameplay balance or Adventure release acceptance. |
| P6M6-D001 | 2026-10-06 | User-directed planning closeout | Create a tracker in the established format for the discussed eleven tasks and mark planning complete. T1 is Complete; M6 is In progress; T2â€“T11 are Not started. Scope, sequence and acceptance structure are recorded; numerical targets, tuning values and Adventure enablement remain subsequent decisions. |

## Tracking and validation rules

- Use `Not started`, `In progress`, `Pending input`, `Blocked`, `Complete` or `Deferred`. Explain blockers/deferrals and identify the next action or owner.
- Mark completion with linked deliverables and evidence. Update this tracker, the phase tracker and onboarding when current status changes.
- Keep detailed targets and tuning specifications in linked task documents; record major decisions here and update the combat mechanics reference when approved rules change.
- Record date, exact command or manual procedure, result and report location. Distinguish automated scenarios, rendered checks and hands-on observations.
- Preserve the D023 protocol's sixteen fixed builds, independently optimized 30/120-second macros, separate 200-seed validation cohorts and BD2 at 21 points as historical comparison inputs. Clearly label new revisions and expanded scenarios.
- Use deterministic fixtures and isolated save paths; protect real Adventure/Practice saves and the sibling Enigma project.
- Run focused checks during tuning and appropriate regression at closeout. M5 correctness evidence and neutral-dummy results do not establish Adventure balance.

## Progress history

- **2026-10-07 â€” D006 implemented and assessed:** Tavern 1/0/2/3, six-point Test Mode default, unchanged three-point contracts/45 cap. Eight focused checks and 728 balance scenarios passed tooling validation; new early Bladedancer concerns recorded in the [assessment](P6M6_Tavern_1023_Assessment.md). Balance acceptance remains downstream.

- **2026-10-07 â€” D005 implemented:** Permanently changed contract talent rewards to three. Updated cap/claim/persistence tests and current progression tables. [Eight focused checks passed](../project/reports/three_point_adoption/results.md). Historical balance measurements are retained; no additional tuning or Adventure enablement.

- **2026-10-07 â€” T4 Complete:** Added the reproducible manifest, conditional acquisition ledger, actual-encounter matrix and verifier. Eight Godot passes plus report checks passed; gameplay values, access and protected files preserved. T5 is next.

- **2026-10-07 â€” T2 Complete:** User-authorized design closeout under D004; finalized diagnostic references, practical acceptance, prototype limits and T4 handoff. Documentation checks only; no tuning or new runtime acceptance.

- **2026-10-07 â€” T3 Complete:** Finished the bounded Adventure/enemy/economy audit and diagnostic probes. Assigned integration gaps and realistic scenario work, reconciled T2 baseline assumptions, and retained all gameplay values. See the linked audit for evidence and limitations.

- **2026-10-06 â€” T1 Complete:** At the user's request, created the eleven-task tracker using the M5 format, recorded acceptance areas, dependencies and decision owners, and closed milestone planning. M6 is In progress; T2 difficulty and progression targets is next. Documentation only; no gameplay changes or new runtime validation.

## Related documents

- [Phase milestone tracker](P6_Milestone_Tracker.md)
- [Project onboarding](P6_Project_Onboarding_Context.md)
- [M5 tracker](P6M5_Complete_Rogue_Tree_And_Skill_Implementation_Tracker.md)
- [M5 closeout and M6 handoff](P6M5_T11_Closeout_And_M6_Handoff.md)
- [Subclass balance protocol](P6_Subclass_Balance_Protocol.md)
- [D023 protocol results](../project/reports/balance/subclass_protocol_d023/results.md)
- [Progression and allocation rules](P6M2_T3_Progression_And_Allocation_Rules.md)
- [Content workflow and compatibility](P6M2_T4_Content_Workflow_And_Compatibility.md)
- [Combat mechanics reference](Combat_Mechanics_Reference.md)
