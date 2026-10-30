# P6M4 — Playable Integration and UI Validation

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

Current status: **M4 Complete — T1–T11 Complete. Next: M5 planning and complete Rogue content implementation.**

[T11 closeout and M5 handoff](P6M4_T11_Closeout_And_M5_Handoff.md) records 60 passing regression suites, seven passing static checks, refreshed rendered core/mixed/usability checks (110/174/152), and unchanged protected saves/project files. T11 reconciled all original compatibility hashes without changing fixtures, fixed the Practice time-conversion/gear-limit regression, freed orphan playback labels, and updated inherited UI tests. Baseline script/certificate and rapid audio teardown warnings have explicit downstream owners.

The [accepted T10 tree UI](P6M4_T10_Full_Tree_UI_UX_Plan.md) is the implementation baseline. Test Mode and Practice use `p6.playable.mixed.1`, including old-core Practice compatibility; Adventure remains disabled and retains `p6.compat.1`. Exact Bladedancer core, 15/5 mixed and reversed Practice roles are accepted. Only six of the 23 displayed Bladedancer/Thief talents are playable; 17 remain labeled previews for M5. Test Mode resets are allowed between fights during planning; Adventure retains between-contracts refunds. M6 owns balance/progression and M7 full-content presentation.

Read the [M4 tracker](P6M4_Playable_Integration_And_UI_Validation_Tracker.md), [T11 handoff](P6M4_T11_Closeout_And_M5_Handoff.md), and [Combat Mechanics Reference](Combat_Mechanics_Reference.md) before new implementation. Icon Lab and its [approved mappings](P6M4_Icon_Assignment_Integration.md) remain available. Last updated: 2026-10-02.

## Historical post-T8 UI handoff (2026-10-02)

Superseded for talent-tree layout status by the accepted T10 baseline above; retained as implementation history.

The user accepted the current UI as sufficient to continue, while explicitly noting that the talent tree layout needs substantial further work. This is not final layout approval. Carry that work into T10; do not reopen it as a prerequisite for T9. Implemented changes and their regression/rendered evidence are consolidated in the [compact UI revision](P6_UI_Compact_Interaction_Revision.md).

**M4-T9 is Complete:** the exact M3-T10 Bladedancer 15 / Thief 5 fixture, reversed Practice roles, Dance and capped Mug benefits are integrated and verified. See the [T9 handoff](P6M4_T9_Mixed_Playable_Integration.md). Next is **M4-T10: Dense-layout and usability validation**. This historical checkpoint is superseded by the completed T10/T11 handoffs above; save isolation and the presentation-only buff timing distinction are preserved.

## Goal and scope

Deliver a scoped playable experience with the approved ten-point Bladedancer
core, followed by Bladedancer 15 / Thief 5 and a Practice Room role reversal.
Validate selection, allocation, unlocks, rotations, combat playback, temporary
effects, Practice persistence and retries through the game UI. Per T2, Adventure
will be temporarily disabled and a fresh-session Test Mode will enter contracts
with fixed Bladedancer, ten unspent points and an empty rotation. Test Mode is the
Adventure-flow proxy; it must preserve both Adventure and Practice saves.

Use the [M3 closeout](P6M3_T11_Closeout_And_M4_Handoff.md) and its exact T8/T10
fixtures. Adventure retains `p6.compat.1`; Test Mode and scoped Practice use
`p6.playable.mixed.1`, with old-core save compatibility. Full four-tree implementation belongs to M5, numerical balance to
M6, and final icon/feedback completion to M7. M4 includes UI/UX decisions, an
initial asset inventory, Icon Lab, and the assets needed for its playable scope.

## Task plan

The eleven-task milestone plan is established by the user-directed T1 closeout
on 2026-09-25. Detailed UI and tool decisions have the owners listed below and
must be settled before affected implementation. Icon Lab and the scoped T4 playable foundation are complete; full end-to-end
acceptance remains T8 onward.

| Task | Status | Deliverable / completion criteria |
| --- | --- | --- |
| M4-T1 — Planning and acceptance criteria | Complete | Milestone goals, eleven-task sequence, representative builds, acceptance matrix and downstream decision owners recorded; user-directed planning closeout on 2026-09-25. |
| M4-T2 — UI/UX and player-feedback specification | Complete | [Specification and audit](P6M4_T2_UI_UX_And_Player_Feedback_Specification.md), user-selected Test Mode flow, display/input/layout decisions, [67-entity icon inventory](P6M4_T2_Icon_Inventory.json) and U01–U16 acceptance cases. No runtime or rendered acceptance claimed. |
| M4-T3 — Icon Lab tool | Complete | [Approved icon integration](P6M4_Icon_Assignment_Integration.md): 92 assignments, 83 named game assets, nine inherited buff icons, 500 library assets; 15 model checks, 26 browser groups and scoped Godot regression/rendered acceptance passed. Full T4–T7 content/UI work remains. |
| M4-T4 — Representative playable content integration | Complete | [T4 implementation and evidence](P6M4_T4_Playable_Core_And_Test_Mode.md): production core registry, disabled Adventure, fresh Test Mode direct contracts, fixed Bladedancer/10 unspent/empty rotation, Bandit Blade/100 gold defaults, generated contract loop and verified save isolation. |
| M4-T5 — Tree selection and talent allocation | Complete | [T5 handoff and evidence](P6M4_T5_Talent_Allocation_UI.md): ranked tiers/icons/links, rank transactions, gates/refunds, point/intrinsic/unlock information, named rotation removals, scoped Practice persistence and role controls. Mixed playable content remains T9. |
| M4-T6 — Skills, tooltips and rotation editing | Complete | [T6 handoff and evidence](P6M4_T6_Skills_Tooltips_And_Rotation_Editing.md): persistent core details, explicit Add/Remove/Move, two-row numbered slots, lock guards, isolated persistence and rendered checks. Live effects remain T7; mixed skills remain T9. |
| M4-T7 — Combat playback and temporary-effect display | Complete | [T7 handoff and evidence](P6M4_T7_Combat_Playback_And_Temporary_Effects.md): ordered presentation data, live effects and captured casts, shared cooldowns, bounded inspector, reduced motion, speed/skip/retry and rendered checks. Mixed fixtures remain test-only; historical snapshot reconciliation remains T11. |
| M4-T8 — Practice Room and core end-to-end acceptance | Complete | [T8 handoff and evidence](P6M4_T8_Core_End_To_End_Acceptance.md): actual core allocation/edit/fight/reward/retry/reopen flows; 110 journey checks, ten scoped suites, isolated saves and three-size rendered acceptance. Save Setup overlap corrected. |
| M4-T9 — Mixed-tree extension and role reversal | Complete | [T9 handoff](P6M4_T9_Mixed_Playable_Integration.md): exact playable 15/5 build, reversed Practice roles, Dance/theft/Mug feedback, old-core compatibility, 174 journey checks and three-size rendered evidence. |
| M4-T10 — Dense-layout and usability validation | Complete | [Accepted layout and final evidence](P6M4_T10_Full_Tree_UI_UX_Plan.md#final-validation-and-t11-handoff): user-approved full tree UI; 125% text, keyboard/modal focus, edge tooltips, dense skills/combat, reduced motion and synthetic cap presentation verified. 152 rendered usability checks and seven scoped suites pass; isolation preserved. |
| M4-T11 — Regression, closeout and handoff | Complete | [Closeout and M5 handoff](P6M4_T11_Closeout_And_M5_Handoff.md): 60 suites, seven static checks, core/mixed/usability rendered validation, compatibility reconciliation, duration and cleanup fixes, save isolation and downstream owners. |

Visual checks occur during implementation as well as T10. T8 is the complete
core-build checkpoint before mixed-tree acceptance.

## T1 closeout and implementation handoff

T1 establishes a playable milestone, including UI/UX and icon assignment work.
The first build is Bladedancer 10: Whetstone 4, Rending Slash 1, Fancy Footwork 5.
The extension is the exact M3-T10 Bladedancer 15 / Thief 5 fixture, with reversed
primary/secondary roles checked in Practice Room. Do not invent replacement
allocations or promote mechanics-harness content wholesale.

Dependency order: T2 defines the interaction and presentation contract; T3
delivers the icon assignment workflow; T4 supplies playable core resources.
T5–T7 connect allocation, rotation and playback; T8 accepts the complete core.
T9 adds the mixed build; T10 consolidates visual/usability acceptance; T11 closes
the milestone. T3 icon handoff and T4 playable resources are now installed. Asset previews and visual checks
continue throughout implementation.

### Milestone acceptance matrix

| Area | Required evidence | Owner |
| --- | --- | --- |
| Playable content | Exact core and mixed fixtures resolve through the chosen playable content revision; exposed ranks and unlocks have implemented behavior. | T4, T9 |
| Build editing | Legal allocation/refund succeeds; invalid edits explain their restriction; primary/secondary differences and automatic unlocks are visible. | T5, T8, T9 |
| Skills and rotations | Approved descriptions and assigned icons appear; unlocked skills can be placed in rotations; unavailable skills and shared cooldown behavior are understandable. | T6, T8, T9 |
| Combat presentation | Stacks, charges, timers, consumption, expiry and cooldowns agree with event evidence; crowded displays and fight cleanup work. | T7, T10 |
| Test Mode and persistence | Per D004, fixed Bladedancer/10 unspent/empty macro reaches contracts and combat. Each entry starts fresh; all test save paths preserve Adventure/Practice files. Unsupported content has explicit treatment; Practice build/rotation still save/load. | T4, T8, T9 |
| Practice Room | Build editing, retry and role reversal work; state persists independently and does not alter Adventure progress. | T8, T9 |
| Icon workflow | Assignment save/load and import/export round trips pass; invalid references are reported; selected mappings visibly reach game UI. | T3, T5–T10 |
| Visual usability | Actual rendered screens at agreed sizes demonstrate readable dense trees, long tooltips, skill lists and busy combat; issues are fixed or explicitly accepted with an owner. | T2, T10 |
| Closeout | Focused checks and appropriate regression pass; manual procedures/results and downstream work are documented. | T11 |

Use deterministic fixtures and the isolated test runner for automated evidence.
Do not run save-writing checks against real user save paths. Headless tests do
not establish visual readability or playable comprehension. Existing M3 results
are inherited evidence, not validation of future M4 changes.

### Decisions assigned downstream

| Decision | Owner / point of resolution |
| --- | --- |
| Entry flow, supported progression beyond test allocations, and unavailable content | T2/D004 selects fresh Test Mode and disables Adventure. T4 finalizes content boundaries and starting gear/gold/contract parameters. No new progression cap or unlock change is approved. |
| Screen layouts, interaction details, target display sizes, effect overflow and accessibility | T2 specification complete; T5–T10 implement and verify rendered layouts. |
| Art direction, asset sources/formats, reuse conventions and missing M4 icon production | T2 inventories assets and retains current style. Detailed art decisions move to T3 per user choice; T5–T10 integrate and validate scoped assets. Final full-library production remains M7. |
| Icon Lab packaging, mapping ownership and application method | T3, before tool implementation; respect canonical identities and the existing content workflow. |
| Content revision and save compatibility for the playable slice | T4, within the established M2 policy, before content promotion. |
| Buff/debuff assignments in Icon Lab | Review in T2/T3 if useful; the explicit tool requirement covers skills and talents. |

T2 decisions are now recorded below; remaining implementation choices stay with the named owners.
M5 retains full four-tree content, M6 numerical balance, and M7 final presentation.
Preserve settled mechanics, the Phase 5 foundation and separate Tree Lab scope.

T1 evidence: goals and task breakdown discussed with the user; Icon Lab added
at the user's request; this tracker, the phase tracker and onboarding updated
for the requested closeout. Documentation only; no new runtime tests, gameplay
changes, assets or visual acceptance are claimed. **Next: M4-T2.**

## M4-T3 — Icon Lab tool

**Standalone tool implemented:** open [Icon Lab](../tools/icon-lab/index.html).
Read [implementation/handoff](P6M4_T3_Icon_Lab_Implementation_And_Handoff.md).
The user finalized 92 entries: Defensive Mechanics 11, Skills 23, Talents 44,
Player Buffs 9, Enemy Statuses 5. Gear and general interface icons are excluded.
This supersedes the original optional buff/debuff scope below. T3 is complete:
[approved mappings](P6M4_Icon_Assignment_Integration.md) now reach Godot UI.
The remaining full content and UI tasks retain their separate acceptance criteria.

T2 is complete: use the [UI/UX specification](P6M4_T2_UI_UX_And_Player_Feedback_Specification.md)
and [initial inventory](P6M4_T2_Icon_Inventory.json). The user chose current icons
and styles for now; detailed art direction is reviewed during Icon Lab. Include
the three base Rogue skills alongside the 64 manifest skill/talent identities.
The initial core/mixed subset contains 16 entities; ten lack assignments.

Purpose: give the user a visual tool for assigning the library of skills and
talents to icon assets without manually editing each game resource.

Planned capabilities and acceptance criteria:

- Browse all four Rogue trees' skill and talent identities, showing name, type,
  tree, descriptive context, current icon and assignment status. Library presence
  must not imply that the content is already implemented or approved for release.
- Browse/search available icon assets with thumbnails; filter content by tree,
  skill/talent and assigned/unassigned status.
- Assign, replace and clear an icon for a selected entity. Allow intentional
  reuse and show which entities use an asset.
- Preview selected icons at the actual sizes/backgrounds established in T2,
  including representative talent and skill UI contexts.
- Save and reload assignments through an explicit, versioned mapping using the
  canonical content identities from the M2 identity manifest, not display names
  or colliding draft-local IDs. Support a portable import/export workflow.
- Detect missing assets, unknown content IDs and invalid mappings. Clearly mark
  unassigned entries and provide a coverage report for the M4 playable subset
  and the full library.
- Define and validate how mappings reach Godot resources. Demonstrate an
  assignment round trip and verify that representative assigned icons appear
  in the actual game UI; assigning an icon must not promote gameplay content.
- Document asset addition and assignment workflows so newly created icons can
  join the library. Keep Tree Lab's separate design workflow intact.

T2 supplies the visual conventions and initial asset inventory. T3 establishes
the assignment workflow before icon acceptance in T5–T10; its catalog can cover
all four trees while runtime integration remains scoped to M4 content.
Final full-library icon production remains M7. Buff and enemy-status assignments
are now explicitly included by the user's T3 scope decision.

Tool packaging, raster formats, mapping ownership/export and preview sizes are
implemented in the T3 handoff. Approved assignments are installed and visually
verified in Godot controls. Full T4–T7 gameplay/UI acceptance remains separate.

## Decision log

| ID | Date | Status | Decision |
| --- | --- | --- | --- |
| P6M4-D001 | 2026-09-25 | User requested | Add an Icon Lab tool task to assign the library of skills and talents to icon assets, alongside M4 UI/UX and asset planning. |
| P6M4-D002 | 2026-09-25 | User-directed closeout | Close T1 as milestone planning with the eleven-task plan, playable representative-build goal, acceptance matrix and assigned design questions. T2 UI/UX specification is next; implementation remains outstanding. |
| P6M4-D003 | 2026-09-25 | User selected in T2 | Improve current style/layouts; desktop mouse/keyboard at 1280×720 through 1920×1080; tiered talent icons, rank counts and prerequisite links. Use current icon styles; detailed art decisions belong to Icon Lab. |
| P6M4-D004 | 2026-09-25 | User specified in T2 | Temporarily gray out Adventure and restore a visible Test Mode button going directly to the contract menu. Fixed Bladedancer primary, ten unspent points, empty rotation; fresh session each entry. Preserve Adventure and Practice saves. Test Mode is M4's Adventure proxy, not a new permanent progression system. |
| P6M4-D005 | 2026-09-25 | User finalized in T3 | Icon Lab covers exactly the agreed 92 entries in Defensive Mechanics, Skills, Talents, Player Buffs and Enemy Statuses. Exclude gear and general interface icons. User imports art and assigns it; portable JSON carries the whole workspace. |
| P6M4-D006 | 2026-10-02 | User selected | Allow Test Mode point resets and rank refunds between fights within an active contract. Planning, route selection and contract offers are eligible; combat/results remain locked. Adventure respec rules are unchanged. |
| P6M4-D007 | 2026-10-02 | User specified | T10 must include the complete Bladedancer primary and Thief secondary tree nodes/dependencies as the UI/UX layout target. Unimplemented content remains nonfunctional preview. Agree the display through iterative discussion/mockups and in-game review before T10 closes. |

## T2 closeout and implementation handoff

T2 completes source audit, interaction/presentation specification, initial asset
inventory and dense-screen acceptance planning. Q1–Q7 in the specification record
the user's choices. Routine UI defaults and structural wireframe are documented;
actual Godot layouts/assets are still to be implemented and visually inspected.

D004 supersedes the original acceptance wording requiring a currently playable
Adventure entry. T4/T8 must instead verify Test Mode through contract selection,
allocation, rotation, rewards and retry, with no writes to Adventure/Practice
saves. Practice retains its own save/load checks. Normal Adventure rules remain
preserved for restoration; Test Mode's skipped Tavern does not revise them.
The existing hidden contract-test handler is a routing starting point only: it
uses old content and deletes the Adventure save and must not be restored unchanged.

T3 receives identity/asset coverage, current and proposed preview sizes and reuse
rules. T4 owns exact gear/gold/contract parameters, content revision and supported
secondary choices. T5–T7 implement the documented interactions; T8–T10 execute
U01–U16 and rendered acceptance. T11 reconciles the resulting evidence.

Validation is limited to documentation/inventory checks. No gameplay code, saves,
content registry, icon assignments or accepted mechanics changed. **Next: M4-T3.**

## Related documents

- [Phase milestone tracker](P6_Milestone_Tracker.md)
- [Project onboarding](P6_Project_Onboarding_Context.md)
- [M3 closeout and M4 handoff](P6M3_T11_Closeout_And_M4_Handoff.md)
- [Content identity manifest](P6M2_T4_Content_Identity_Manifest.json)
