# P6M5 — Complete Rogue Tree and Skill Implementation

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

**P6M5-D018 (2026-10-05):** Riposte now grants +20% Plunge damage per rank per consumed Footwork stack. Fancy Footwork reduces Plunge cast time by 4% per rank per consumed stack (20% at rank five), respecting the 500 ms minimum. See [verification](P6_Bladedancer_Footwork_Riposte_Update.md).


**P6M5-D017 (2026-10-05):** Big Score now multiplies the full current critical damage multiplier by six (previously two). See [verification](P6_Big_Score_Crit_Update.md).


**P6M5-D016 (2026-10-04):** Pick Pocket now has an eight-second cooldown from cast completion, shared across slots; ten raw gold and all other Thief values retained. See [verification](P6_Pick_Pocket_Cooldown_Update.md).


**P6M5-D015 (2026-10-04):** Echoing Toxin now adds 40/30/20% suppression to natural Poison ticks, with no damage bonus; Echoing uses two fuel per tick; Resonance retains three. Negative block/absorb now grant 0.1 base damage per point. See [implementation and verification](P6_Echoing_And_Negative_Defense_Balance_Update.md).


Current status: **M6 In progress — T1 planning Complete. T2 difficulty and progression targets is next; T2–T11 are Not started. M5 remains Complete.**

**2026-10-06 — M6-T1 Complete:** The [M6 task tracker](P6M6_Enemy_Balance_And_Adventure_Progression_Tracker.md) records the eleven-task plan, acceptance matrix, dependencies and review checkpoints. Planning is complete at the user's request; T2 difficulty and progression targets is next. Numerical targets, tuning and Adventure enablement remain downstream. This current status supersedes historical M6 planning references below.

**2026-10-06 — M5 Complete:** [T11 closeout and M6 handoff](P6M5_T11_Closeout_And_M6_Handoff.md) records 91 passing distinct suites, sixteen static checks, fresh mixed/gear and player-flow evidence, approved source reconciliation and a protected-file/repository checkpoint. No T11 runtime or balance changes. M6 planning is next.


**2026-10-06 — T10 Complete:** [Full-content player-flow acceptance](P6M5_T10_Full_Content_Player_Flow_Acceptance.md) covers 25 runtime executions (19 distinct suites), nine static checks, twelve ordered pairings and rendered UI at three sizes. Fixed Practice rotation pruning when replacing the last gear skill grant. T11 milestone-wide regression and closeout is next.


Last updated: 2026-10-06.

## Goal and scope

Deliver complete, playable and verified Assassin, Bladedancer, Shadow and Thief
content: intrinsics, every approved talent/rank, skills, automatic unlocks and
accurate descriptions. Review the detailed behavior with the user before affected
implementation, then verify individual trees and their mixed-tree/gear interactions.
Balance values remain provisional.

Start from the [M4 closeout](P6M4_T11_Closeout_And_M5_Handoff.md),
[combat mechanics reference](Combat_Mechanics_Reference.md) and
[phase tracker](P6_Milestone_Tracker.md). The inherited inventory contains
44 talents / 140 ranks, four intrinsics, 20 automatic slots and two talent skill
grants. These are inventory counts, not approval of every draft mechanic.
After T7, all 13 Bladedancer, ten Thief and ten Assassin talents are playable (105 ranks); these trees have no preview nodes. T2's original six-playable/17-preview count is historical.

Preserve the accepted [T10 UI](P6M4_T10_Full_Tree_UI_UX_Plan.md), settled M2/M3
contracts, stable content identities, the Phase 5 gear foundation and separate
Tree Lab scope. Keep intentionally empty automatic slots empty. Remove Preview
only after functionality is verified. Bring concrete new content/layout conflicts
to the user without reopening the accepted design as a whole.

Test Mode and Practice currently use `p6.playable.shadow.1`, including old-core
and mixed Practice compatibility. Adventure remains disabled and retains `p6.compat.1`.
M5 must define supported test access and content promotion within existing policy;
this plan does not enable Adventure or select a new content revision.
Numerical balance and Adventure progression/release decisions belong to M6.
Final art and full-content presentation completion belong to M7; readable,
truthful descriptions and functional feedback are required during M5 implementation.

## Task plan

This plan records the eleven tasks discussed with the user. On 2026-10-03, the
user's request to carry out the reviewed T2 steps authorized proceeding from the
recorded plan; T1 planning closeout and T2 audit/coverage completion are recorded
below. No unresolved mechanics or new runtime acceptance are implied.

| Task | Status | Deliverable / completion criteria |
| --- | --- | --- |
| M5-T1 — Milestone planning | Complete | Goals, eleven-task sequence, acceptance matrix, dependencies and owners recorded here; planning closeout recorded with user-authorized T2 execution (D002). |
| M5-T2 — Content reconciliation and coverage plan | Complete | [Reconciliation/coverage plan](P6M5_T2_Content_Reconciliation_And_Coverage_Plan.md), [ledger](P6M5_T2_Content_Coverage_Ledger.md) and [140-rank inventory](P6M5_T2_Content_Coverage_Ledger.json) account for all content, current bindings, questions, dependencies, access/promotion requirements and planned validation. [Static evidence](../project/reports/p6_m5_t2_static/summary.json); no new runtime acceptance. |
| M5-T3 — Bladedancer design review | Complete | [Approved specification](P6M5_T3_Bladedancer_Design_Review.md): all 13 talents / 35 ranks, skills, descriptions, examples and acceptance cases reconciled. User confirmed D01–D03 under P6M5-D003. [Static evidence](../project/reports/p6_m5_t3_review/summary.json); runtime implementation remains T4. |
| M5-T4 — Complete Bladedancer | Complete | [Implementation and evidence](P6M5_T4_Bladedancer_Implementation.md): all 13 talents / 35 ranks, full Practice/Test Mode access, old revision compatibility, allocation/combat/Lab and rendered validation. |
| M5-T5 — Thief design review | Complete | [Approved specification](P6M5_T5_Thief_Design_Review.md): 10 talents / 35 ranks, four skills, gold/shop/loot contracts, descriptions, examples and T6 acceptance plan. User confirmed D01–D03 and Loaded Dice name under P6M5-D004. |
| M5-T6 — Complete Thief | Complete | [Implementation and evidence](P6M5_T6_Thief_Implementation.md): ten talents/35 ranks, four skills, combat/gear/economy checks, save compatibility and rendered journeys pass. |
| M5-T7 — Assassin design review and implementation | Complete | [Implementation and evidence](P6M5_T7_Assassin_Implementation.md): D01–D03 confirmed under P6M5-D009; ten talents / 35 ranks and six skills playable; allocation/combat/boundary/persistence/rendered checks pass. |
| M5-T8 — Shadow design review and implementation | Complete | D01–D04 approved under D011; [implementation and evidence](P6M5_T8_Shadow_Implementation.md) covers eleven talents / 35 ranks, five skills, both roles, focused combat, rendered journeys and 200-seed Lab cohorts. |
| M5-T9 — Mixed-tree and gear integration | Complete | [T9 matrix and evidence](P6M5_T9_Mixed_Tree_And_Gear_Integration.md): twelve ordered pairings, 40 legal allocations, 576 matrix scenarios plus focused cap/expiry checks; 22 runtime suites and nine static checks pass. |
| M5-T10 — Full-content player-flow acceptance | Complete | [T10 acceptance](P6M5_T10_Full_Content_Player_Flow_Acceptance.md): four trees, twelve ordered mixed flows, persistence, seeded Practice/Lab parity and rendered usability; fixed last-gear-grant rotation pruning. |
| M5-T11 — Regression, closeout and M6 handoff | Complete | [Closeout and M6 handoff](P6M5_T11_Closeout_And_M6_Handoff.md): 91 distinct suites, sixteen static checks, fresh journeys/matrix, source reconciliation and protected-file checkpoint; downstream owners recorded. |

## Dependencies and review checkpoints

T2 establishes the coverage ledger and identifies questions before tree work.
T3 precedes T4; T5 precedes T6. Complete the remaining Bladedancer and Thief
content before proceeding to Assassin and Shadow. T7 and T8 each contain separate
design-review and implementation checkpoints: a combined task does not bypass
user review of unresolved gameplay behavior.

Tests, descriptions and functional UI checks belong to each tree's implementation
task. Review cross-tree dependencies as they arise; T9 consolidates their full
interaction coverage. T10 validates the combined player experience and T11 closes
the milestone. A newly discovered shared-system gap must have a documented
contract and focused coverage before dependent content is promoted.

### Per-tree completion checklist

Completed for Bladedancer (T3/T4), Thief (T5/T6), Assassin (T7) and Shadow (T8); T11 reconciles their evidence in the closeout acceptance map.

- [x] Intrinsics, talents/ranks, skills and automatic slots reconciled against canonical identities.
- [x] Remaining design questions reviewed with the user; approved behavior and examples recorded.
- [x] Applicable timing, stacking, refresh, expiry, consumption, caps and trigger rules specified using settled contracts.
- [x] Primary/secondary role differences, gates, prerequisites and unlock behavior verified.
- [x] Approved content implemented and reachable through supported Practice/Test Mode flows.
- [x] Refund/reset behavior and unavailable-skill rotation pruning verified.
- [x] Descriptions, rank values and functional feedback match actual effects.
- [x] Deterministic mechanic checks, boundary cases and representative combat scenarios pass.
- [x] Practice persistence/retry and applicable content compatibility checked with isolated saves.
- [x] Coverage ledger updated; Preview removed only for verified content; remaining work assigned explicitly.

## Milestone acceptance matrix

| Area | Required evidence | Owner |
| --- | --- | --- |
| Content coverage | Ledger covers the inherited full inventory, intentional empty slots and any approved revisions; no silent omissions. | T2, T3–T8, T11 |
| Design approval | Linked tree specifications distinguish settled rules, newly approved decisions and unresolved questions; concrete examples cover ambiguous behavior. | T3, T5, T7, T8 |
| Playable mechanics | Each promoted node/rank, intrinsic and skill has implemented effects and focused deterministic evidence. | T4, T6–T8 |
| Build editing and progression | Legal allocations, gates, prerequisites, unlock thresholds, role scaling, refunds and resets behave as specified. | T4, T6–T10 |
| Descriptions and feedback | Rank/skill text matches behavior; new content is readable in the accepted UI; Preview status is truthful. | T4, T6–T10 |
| Mixed trees and gear | Agreed pairings and reversed roles exercise relevant shared effects and gear interactions, including boundaries and caps. | T9 |
| Supported player flows | All four trees can be exercised in Practice/Test Mode; rotation editing, pruning, combat and retries work end to end. | T4, T6–T8, T10 |
| Persistence and compatibility | Content revisions and saved IDs follow M2 policy; Practice round trips and old-core treatment are verified; real saves remain protected. | T2, implementation tasks, T10–T11 |
| Practice and Balance Lab | Representative individual/mixed builds and reproducible scenarios cover implemented content. Results establish correctness, not balance approval. | T4, T6–T10 |
| Regression and handoff | Appropriate regression passes, coverage is reconciled, commands/reports are linked and downstream work has owners. | T11 |

### Milestone completion checklist

- [x] Bladedancer content, descriptions and focused acceptance complete.
- [x] Thief content, descriptions and focused acceptance complete.
- [x] Assassin content, descriptions and focused acceptance complete.
- [x] Shadow content, descriptions and focused acceptance complete.
- [x] Mixed-tree and gear integration verified in T9.
- [x] Full progression/unlock player flows accepted in T10.
- [x] Practice Room and Balance Lab support the implemented content.
- [x] Full-content player flows and applicable persistence boundaries accepted.
- [x] Regression, documentation reconciliation and M6/M7 handoff complete.

## Decisions and work assigned downstream

| Question / work | Owner / point of resolution |
| --- | --- |
| Draft/runtime discrepancies and missing specification coverage | T2 inventories them; relevant tree review settles them before affected implementation. |
| Exact supported Test Mode access, tree selection and point availability for full-content validation | T2 plans requirements; implementation tasks establish necessary test access without changing Adventure progression rules. |
| Content revision and Practice compatibility during promotion | T2 identifies required treatment under the existing M2 policy; implementation tasks document and verify it before promotion. |
| Remaining tree-specific mechanical ambiguities | T3, T5 and the design checkpoints in T7/T8. Previously settled contracts remain the baseline. |
| Newly discovered shared-mechanic requirements | Relevant tree task records the contract, dependency and focused checks before implementation. |
| Pairing/gear coverage and representative scenarios | T2 establishes the coverage plan; T9 completes and verifies the interaction matrix. |
| Concrete conflicts between new content and accepted layout | Relevant implementation task presents the specific conflict to the user; T10 verifies the resulting full-content flow. |
| Quantitative difficulty, enemy tuning, Poison supply, gold ramp/caps, normal retrigger below 100% and Watchmen comparison | M6. Existing fixture values/results are not balance approval. |
| Adventure enablement and full progression acceptance | M6 progression/release planning; no incidental enablement during M5. |
| Final icons, crowded combat text, full effect cues, accessibility/readability completion and audio teardown | M7, preserving the accepted T10 styling and existing Icon Lab assignments. |
| Packaging environment and clean engine shutdown verification | M9, following the inherited M4 warning ownership. |

## Decision log

| ID | Date | Status | Decision |
| --- | --- | --- | --- |
| P6M5-D001 | 2026-10-02 | User requested | Create a tracking document using the established format and the discussed eleven-task plan. This records planning structure; it does not approve unresolved content mechanics or close T1. |
| P6M5-D002 | 2026-10-03 | User authorized execution | User requested carrying out the eight-step T2 plan. Record T1 planning closeout against the existing sequence/acceptance matrix and execute T2 reconciliation. This authorizes audit/planning work, not unresolved mechanics, runtime promotion or Adventure enablement. |
| P6M5-D003 | 2026-10-03 | User confirmed | Weakness adds +5 base Shred Value per rank. Virulent adds +100 base Shred Value and +2 stacks per eligible application: with Weakness five, base-one applications remove 3*(base+125) armor; Rending retains base two and grants four stacks. Weapon Master 1.5x/2x and multiplicative Sharpened Edge interactions approved; numerical tuning remains M6. T3 Complete; implementation T4. |
| P6M5-D004 | 2026-10-03 | User confirmed | Approved Sticky Fingers multiplicative +10..50% gold, Charisma +10/20/30% discount and Loaded Dice +100/200/300% Magic Find with existing consumer rules. Corrected player-facing name to Loaded Dice; stable talent.thief.load_dice identity retained. T5 Complete; T6 next. |
| P6M5-D005 | 2026-10-03 | User requested | Pick Pocket execution 1800 ms, minimum 800 ms retained, ten raw gold. Mug bonus is min(100, floor(credited fight theft / 2)); starting stash excluded. Tooltips and live presentation share runtime calculation. |
| P6M5-D006 | 2026-10-03 | User requested | Restore Mug +1 base physical damage per credited fight stolen gold, capped at +100. Pick Pocket remains 1800 ms and ten raw gold. Supersedes only the Mug conversion in D005. |
| P6M5-D007 | 2026-10-03 | User requested | Block lower-tier refunds that remove access to retained upper talents; require lower-tier support consistently for buys/refunds/restores. Supersedes original M2 resulting-total gate rule. Dance cooldown skips verified not to activate/refresh its guarantee or change retrigger chance. |
| P6M5-D008 | 2026-10-03 | User requested | Mug bonus physical base damage cap reduced to +50. Keeps +1 damage per credited gold stolen this fight; Greed continues tracking the uncapped theft total. |

| P6M5-D009 | 2026-10-03 | User confirmed | Approved all T7 proposals: Venom Jab 22% weapon, five Poison, 1000/500 ms, no cooldown; Toxic Tradeoff separate Poison-only 1.2–2x and physical 0.9–0.5x factors before conversion; Quick Hands/Precision +1..5 percentage points IAS/crit. Proceed with full Assassin implementation and validation. |
| P6M5-D010 | 2026-10-03 | User confirmed | Apply the Balance Lab candidate: Echoing/Resonance +5% per rank as separate factors; Toxic +10% Poison/-10% physical per rank; primary Assassin +0.5 base elemental per point. Innate +5, fuel consumption, Powder scaling and save identities unchanged. See [implementation](P6_Assassin_Balance_Implementation.md). |

| P6M5-D011 | 2026-10-03 | User confirmed | User approved all four Shadow proposals ("everything looks good"): Beguiling 22%/1700/650, Death Strike 111% combined base/1500/650 without Consume, Distilled 100%/1500/650 then Consume up to five Decay into Poison, and the proposed four scalar passive rank packages. See [approved specification](P6M5_T8_Shadow_Design_Review.md). |

| P6M5-D012 | 2026-10-04 | User requested | Start skill cooldowns at cast completion, with shared duplicate IDs and existing dodge/interruption/resource rules. Negative block/absorb add 0.5 physical/elemental base damage per point below zero, preserving fractional base until normal final rounding. See [implementation](P6_Cooldown_And_Negative_Defense_Update.md). |

| P6M5-D013 | 2026-10-04 | User requested | Blinding Powder base cast 1000 → 1200 ms; minimum 500 ms and no cooldown retained. Potency/Penetration maximum 100 → 50 stacks, including ordinary, doubled and Consume grants. See [implementation](P6_Blinding_Powder_And_Defense_Caps_Update.md). |

| P6M5-D014 | 2026-10-04 | User requested | Increase Virulent Poison cooldown from five to ten seconds, measured from cast completion. See [verification](P6_Virulent_Poison_Cooldown_Update.md). |

## Tracking and validation rules

- Use `Not started`, `In progress`, `Pending input`, `Blocked`, `Complete` or `Deferred`. Explain blockers/deferrals and identify the next action or owner.
- Mark completion only with linked deliverables and evidence. Update this tracker and the phase tracker when task or milestone status changes.
- Keep detailed mechanics in linked task specifications; record major changes in the decision log and update the combat mechanics reference when approved rules change.
- For validation, record date, exact command or manual procedure, result and report location. Separate automated, rendered and user-playtest evidence.
- Use deterministic fixtures and isolated save paths. Preserve real Adventure/Practice saves and the sibling Enigma project.
- Run focused checks during implementation and appropriate regression at closeout. Inherited M4 evidence does not validate new M5 content; headless checks do not establish visual readability.

## Progress history

**2026-10-06 — T9 Complete:** [Mixed-tree/gear acceptance](P6M5_T9_Mixed_Tree_And_Gear_Integration.md) passes 22 runtime suites and nine static checks across twelve ordered pairings and 40 legal allocations. Gameplay and protected saves unchanged. T10 is next.

- **2026-10-06 — T9 execution:** User authorized the seven-step integration plan. Reconciled D023 baseline, added legal mixed/gear fixtures and focused reachable interactions, and began isolated current regression. See [T9 handoff](P6M5_T9_Mixed_Tree_And_Gear_Integration.md).

- **2026-10-03 — T7 closeout:** User confirmed all three proposals under D009. Complete Assassin promoted as `p6.playable.assassin.1`, preserving prior playable revisions and disabled Adventure. 1,972 full-tree checks, 334 boundary checks, 139 headless/rendered journey checks and 68 reconciled regression suites pass. Ledger and mechanics reference updated; T8 next.

- **2026-10-03 — T7 review:** User requested executing the eight-step Assassin task. Prepared the full specification, descriptions, twelve worked examples, legal builds under D007 and eighteen acceptance groups. D01 Venom Jab, D02 Poison-only Toxic Tradeoff and D03 basic passive ranks await confirmation at the explicit design checkpoint. No runtime or source-draft changes; implementation remains pending.

- **2026-10-03 — T6 closeout:** All Thief talents/ranks and four skills promoted as `p6.playable.thief.1`; combat, economy, persistence, rendered journeys and 65 regression suites pass. See [T6 implementation](P6M5_T6_Thief_Implementation.md). T7 Assassin review is next.
- **2026-10-03 — T5 closeout:** User confirmed all proposals (P6M5-D004), including multiplicative Sticky Fingers, and corrected Loaded Dice spelling. Specification, preview label, ledger and status reconciled; static checks pass. Gameplay unchanged. T5 Complete; T6 next.

- **2026-10-03 — T5 review:** Prepared the complete Thief specification, eleven worked examples, legal fixture plans, descriptions and fifteen acceptance groups. Preserved settled M3 behavior; draft Sticky Fingers/Charisma/Load Dice proposals await confirmation. No runtime promotion; T6 remains Not started.

- **2026-10-03 — T4 closeout:** Complete Bladedancer promoted as `p6.playable.thief.1`. Added eight explicit resources, passive rank bindings, descriptions and 45-point Test Mode option; protected compatibility preserved. Full-tree and regression evidence is linked in the T4 closeout. T5 Thief design review is next.

- **2026-10-03 — T3 closeout:** User confirmed D01–D03. Reconciled base Shred Value additions and base-one versus Rending base-two stack examples, retained Weapon Master interactions and M6 tuning ownership. Updated specification, combat reference, ledger and status; static checks pass. T3 Complete; T4 next. No runtime changes.

- **2026-10-03 — T3:** Prepared the complete Bladedancer specification, description drafts, ten examples, 21 acceptance groups and four legal build plans. Existing M2/M3 contracts remain settled. Weakness, Weapon Master and Virulent Corruption's full-node proposals are D01–D03 awaiting user confirmation; T3 is Pending input, not Complete. T4 has not started. Ledger, onboarding and phase status link the review; no gameplay or combat-reference changes.
- **2026-10-03:** Closed T1 planning and completed T2 at the user's request. Reconciled 92 identities, 44 talents / 140 ranks, four intrinsics, 20 slots (two empty), 20 skills and two talent grants. Six talents / 21 rank definitions are playable; 38 talents / 119 ranks remain unpromoted. Recorded Q01–Q07, B01–B04, ten validation families and all six pairings in both roles. Static checks and source consistency evidence are linked from the T2 handoff. No gameplay, source draft, save or release changes; no new runtime/rendered acceptance. T3 review is next.
- **2026-10-02:** Started M5-T1 planning. Discussed milestone goals and the eleven-task breakdown; created this tracker at the user's request and linked it from the phase tracker and onboarding. T1 remains In progress. Documentation only; no gameplay changes or new runtime/visual validation claimed.

## Related documents

- [Phase milestone tracker](P6_Milestone_Tracker.md)
- [Project onboarding](P6_Project_Onboarding_Context.md)
- [M4 tracker](P6M4_Playable_Integration_And_UI_Validation_Tracker.md)
- [M4 closeout and M5 handoff](P6M4_T11_Closeout_And_M5_Handoff.md)
- [Accepted tree UI](P6M4_T10_Full_Tree_UI_UX_Plan.md)
- [Combat mechanics reference](Combat_Mechanics_Reference.md)
- [Tree drafts](talent_tree_drafts/README.md)
- [Cross-tree audit](P6M2_T2_Cross_Tree_Draft_Audit.md)
- [Inventory appendix](P6M2_T2_Draft_Inventory_Appendix.md)
- [Progression and allocation rules](P6M2_T3_Progression_And_Allocation_Rules.md)
- [Content workflow and compatibility](P6M2_T4_Content_Workflow_And_Compatibility.md)
- [Content identity manifest](P6M2_T4_Content_Identity_Manifest.json)
- [M3 closeout](P6M3_T11_Closeout_And_M4_Handoff.md)
- [Approved icon mappings](P6M4_Icon_Assignment_Integration.md)

- **2026-10-03 — T8 review:** Reconciled all eleven Shadow talents / 35 ranks, five skills and intrinsic; prepared four decision proposals, twelve examples and eighteen acceptance groups. Shared contracts and D010 remain unchanged. See [review](P6M5_T8_Shadow_Design_Review.md).

- **2026-10-03 — T8 closeout:** Complete Shadow promoted under D011 as `p6.playable.shadow.1`. All 44 Rogue talents / 140 ranks and twenty planned skills are now playable. Focused and rendered acceptance, full regression and reference Balance Lab cohorts are linked in [T8 implementation](P6M5_T8_Shadow_Implementation.md). T9–T11 remain separate.
