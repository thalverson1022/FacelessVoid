# P6M7 — Icons and Player Feedback Completion

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

Current status: **Complete — T1–T11 Complete under D053; final presentation accepted under D052.**

Last updated: 2026-10-17. [Final M7 closeout and M8 handoff](P6M7_T11_Closeout_And_M8_Handoff.md) records the accepted baseline, scoped regression, three inherited legacy test exceptions and capability limits. T5/T6/T7/T8/T9/T10 acceptances remain D039/D041/D046/D047/D050/D052. M8 Legendary revamp planning is complete; its T2 audit is next. M9 integrated playtesting and M10 regression remain Not started. See [current numbering and plan](P6M8_Legendary_Item_Revamp_And_Expansion_Tracker.md). Historical decisions below retain their original milestone numbering. The experimental combat log remains excluded from live adoption.

## Goal and scope

Make the completed Rogue systems readable and understandable in actual play, including dense mixed-tree combat. Across all four trees, players should understand their choices, recognize important combat events and inspect their effects without the interface becoming unreadable.

Complete talent/skill/buff/debuff icons, descriptions, temporary-effect displays and necessary combat cues. Check actual-size readability, supported desktop sizes, enlarged text, accessibility and player-facing audio lifecycle behavior. Use user playtesting alongside this work to capture comprehension and balance feedback under M6 D015.

Start from the [M6 closeout and M7 handoff](P6M6_T11_Closeout_And_M7_Handoff.md), [accepted tree UI](P6M4_T10_Full_Tree_UI_UX_Plan.md), [Icon Lab mappings](P6M4_Icon_Assignment_Integration.md) and [combat mechanics reference](Combat_Mechanics_Reference.md). Preserve the accepted layout and mappings as the baseline; review concrete changes when evidence calls for them. M6 observed overlapping damage popups and effect labels in dense Assassin/Shadow combat; use that case early in design review.

Retain current gameplay values and intentional hard counters. Presentation work does not authorize unspecified mechanics or balance changes. Distinguish unclear information, mechanics defects and intentional counters before proposing tuning. Legendary refinement now belongs to [Phase 6 M8](P6M8_Legendary_Item_Revamp_And_Expansion_Tracker.md), using the [prior remake evidence](P6_Legendary_Remake_Next_Phase_Handoff.md). Broader integrated playtest/refinement belongs to M9; engine/environment and export qualification belongs to M10. New classes, gear/route/economy redesign and wholesale combat resolver replacement remain outside scope.

## Task plan

The user accepted the eleven-task plan and requested T1 closeout on 2026-10-08 (P6M7-D002). Planning is complete; detailed presentation design, implementation and user playtesting remain downstream.

| Task | Status | Deliverable / completion criteria |
| --- | --- | --- |
| M7-T1 — Milestone planning and acceptance criteria | Complete | Scope, eleven-task sequence, dependencies, review checkpoints, acceptance matrix and downstream owners recorded here; user accepted the plan and requested closeout under P6M7-D002. T2 audit subsequently completed. |
| M7-T2 — Presentation and asset audit | Complete | [Audit and validation](P6M7_T2_Presentation_And_Asset_Audit.md), [per-identity inventory](P6M7_T2_Presentation_Inventory.md): 44 talents / 140 ranks, 23 skills, 93 mappings; twelve gaps assigned with validation cases. Three focused and three rendered suites pass; Icon Lab freshness failure recorded as G11. T3 is next. |
| M7-T3 — Visual conventions and feedback design | Complete | User-requested closeout under D015. [Accepted conventions, evidence and handoffs](P6M7_T3_Closeout_And_Accepted_Conventions.md): approved category feedback, all-tree accents and point counters promoted; log experiment excluded. Exact icon refinements and effect-overflow details assigned to T4/T6 without adopting the rejected proposal. |
| M7-T4 — Icon production and integration | Complete | [Approved integration and evidence](archive/m7/P6M7_T4_Icon_Production_And_Integration.md): 93 identities / 84 framed textures, five refinements, compatible Icon Lab; 17 model checks, 28 browser groups, five focused suites and rendered cross-mode checks pass. User accepted the set under D018; individual refinements accompany T5. |
| M7-T5 — Talent, skill and tooltip clarity | Complete | User accepted finished T5 and requested closeout under D039. [Accepted conventions, evidence and handoffs](P6M7_T5_Closeout_And_Accepted_Conventions.md): shared current format covers all 44 talents / 140 ranks and 23 skills across modes, shared Active Talents, original-art review, backgrounds and final keyword/value treatment. T6/T7 display/cue issues remain assigned downstream. |
| M7-T6 — Temporary-effect display completion | Complete | [Implementation and evidence](P6M7_T6_Temporary_Effect_Display_Completion.md): readable overflow, active/held instance inspection, lifecycle/focus fixes; four existing suites and final rendered suite pass with 114 captures. User accepted the changes and requested closeout under D041. |
| M7-T7 — Combat cues and popup readability | Complete | [Closeout and evidence under D046](P6M7_T7_Combat_Cues_And_Audio_Verification.md): accepted ghost/proc feedback, bounded mixed-cue lanes, Poison/footer clearance, actor/text order and immediate exit-audio cancellation. Six affected suites, 126 rendered captures and real WASAPI lifecycle checks pass; user accepted 1×/4× audio. Broader display/accessibility review moves to T8. |
| M7-T8 — Integrated UI and accessibility review | Complete | [Review and evidence under D047](archive/m7/P6M7_T8_Integrated_UI_And_Accessibility_Review.md): 18 mode/size/font cases, six presentation repairs, keyboard/hover/inspector/motion checks and final footer/focus supplements. All selected checks pass; parent source/visual/preservation review complete. Diagnostic 125% and other capability limits recorded. T9 playtesting is next. |
| M7-T9 — User playtesting and feedback collection | Complete | [Feedback and closeout](archive/m7/P6M7_T9_User_Playtesting_And_Feedback.md#d050--user-accepted-t9-closeout-2026-10-17). User reports everything looks good for now; four D049 refinements accepted. Session coverage limits recorded; no unresolved reported findings. T10 next. |
| M7-T10 — Feedback refinement and acceptance | Complete | [Acceptance record and closeout under D052](P6M7_T10_Feedback_Refinement_And_Acceptance.md#d052--explicit-user-acceptance-and-t10-closeout-2026-10-17): user explicitly accepted final M7 presentation with recorded limits. Audit/feedback reconciled; no unresolved reported refinement. T11 next. |
| M7-T11 — Regression, closeout and M8 handoff | Complete | [Final verification and handoff under D053](P6M7_T11_Closeout_And_M8_Handoff.md): 27 passing current suites, three triaged inherited legacy exceptions, final integrated/footer/icon renders, current Fight autosave proof, asset/tooling reconciliation and repository checkpoint. M8 next. |

## Dependencies and review checkpoints

T2 establishes current coverage; T3 settles presentation rules before affected production and implementation. Start T3 with the known crowded-combat case to coordinate icon sizing, effect display and popup behavior. T3 is closed on the accepted conventions under D015. Exact icon refinements, overflow details and further cue work continue under T4, T6 and T7 respectively; historical proposals are not automatic implementation requirements.

T4–T7 may progress together where their reviewed dependencies are ready. Descriptions must follow current mechanics, and presentation must use authoritative combat state/events. T8 reviews the combined result across game modes and supported display conditions.

User playtesting can begin as improvements become usable. T9 consolidates that feedback and records the tested revision; automated or rendered checks do not substitute for hands-on evidence. T10 resolves findings and records user acceptance; T11 verifies the final result and hands off to M8. Do not silently turn feedback into numerical changes.

### T1 planning completion checklist

- [x] Milestone goals and scope boundaries recorded.
- [x] Eleven tasks and completion criteria recorded in the established format.
- [x] Dependencies and design/review checkpoints identified.
- [x] Acceptance areas and validation ownership assigned.
- [x] Open design questions and downstream work assigned.
- [x] User accepted the plan and requested planning closeout under P6M7-D002; T2 confirmed as next.

## Milestone acceptance matrix

| Area | Required evidence | Owner |
| --- | --- | --- |
| Coverage and visual identity | Inventory accounts for all approved talents, skills and displayed buffs/debuffs; missing assets resolved, reuse documented, mappings verified. | T2–T4 |
| Description accuracy | Talent summaries, skill details and effect text match current mechanics and conditions across all four trees and relevant surfaces. | T5 |
| Temporary effects | State, stacks/charges and durations are accurate where relevant; activation, consumption, expiration, reset and overflow remain understandable. | T3, T6 |
| Combat comprehension | Important events have appropriate cues; the captured crowded-combat case and other dense builds remain readable. | T3, T7–T9 |
| Accessibility and display sizes | Actual-size assets and integrated screens reviewed at 1280×720, 1600×900 and 1920×1080, including 125% text where supported; clipping, contrast and non-color cues assessed. | T4, T8 |
| Mode and build coverage | Adventure, Test Mode and Practice; all four trees, both tree roles and representative dense mixed builds covered by a documented matrix. | T2, T8, T11 |
| Hands-on feedback | User observations include tested revision, build/ranks, gear/gold, macro, seed/checkpoint, route/tag choices and retry outcome as applicable. Confusing losses distinguished from intentional counters. | T9–T10 |
| Acceptance and regression | User presentation acceptance, focused checks and final appropriate regression recorded; unresolved issues have explicit owners. | T10–T11 |

### Milestone completion checklist

- [x] Milestone planning complete.
- [x] Presentation inventory and visual/feedback conventions reviewed; T3 closeout scope and downstream exceptions recorded under D015.
- [x] Approved icon inventory integrated with consistent reuse and readable actual-size assets (T4 / D018).
- [x] Talent/skill clarity and scoped effect wording accepted under T5/D039; temporary-effect display validation remains T6.
- [x] Temporary-effect display and overflow treatment accepted under D041; scoped evidence and synthetic-density limitations recorded in the T6 closeout.
- [x] Required combat cues and popup readability verified under D046; mixed-cue, lifecycle and listening evidence recorded.
- [x] Integrated UI and accessibility review complete under D047; matrix, targeted fixes and capability limits recorded.
- [x] User playtesting and categorized feedback recorded; T9 accepted under D050 with session-context/coverage limits explicit.
- [x] Agreed M7 refinements and explicit final presentation acceptance recorded under D052; limits and downstream owners retained.
- [x] Appropriate regression, documentation and M8 handoff complete under D053; inherited test debt and accepted limits retain named owners.

## Decisions and work assigned downstream

| Question / work | Owner / point of resolution |
| --- | --- |
| Exact current asset count, reuse and presentation gaps | T2 audits current content; historical inventories are starting references. |
| Icon style, effect hierarchy, overflow and cue vocabulary | T3 accepted conventions under D015; remaining concrete refinements owned by T4, T6 and T7. |
| Which effect details are always visible versus inspectable | T6 resolves remaining density/overflow details against the retained baseline; T8–T9 validate comprehension. |
| Description discrepancies | T5 checks the live contract and reference; distinguish wording defects from proposed mechanics changes. |
| Dense popups and audio playback lifecycle | T7, with focused lifecycle checks and rendered review. |
| Balance concerns raised during playtesting | T9 records evidence; T10 assigns a specific reviewed action or M9 follow-up while retaining M6 difficulty direction. |
| Legendary power and Bandit hoarding/scaling | M8 Legendary revamp and expansion; no experimental curve adopted. |
| Broader full-run and unusual-build refinement | M9, using M7 findings and the revised Legendary roster. |
| Certificate/shader/export and general engine teardown qualification | M10; distinguish these from player-facing audio fixes in T7. |

## Decision log

| ID | Date | Status | Decision |
| --- | --- | --- | --- |
| P6M7-D001 | 2026-10-08 | User-requested tracking and documentation cleanup | Record the discussed eleven tasks using the prior milestone format. M7/T1 planning is In progress; T2–T11 are Not started. Prune onboarding and repeated phase status while preserving historical decisions/evidence. No design, asset, gameplay or numerical adoption is implied. |
| P6M7-D002 | 2026-10-08 | User-approved planning closeout | User accepted the plan and requested T1 closeout. Scope, eleven tasks, dependencies, acceptance criteria and downstream owners are accepted. T1 Complete; T2–T11 Not started; T2 presentation and asset audit is next. Detailed visual conventions, effect priorities, overflow and cue choices remain T2/T3 work. No gameplay or numerical changes. |
| P6M7-D003 | 2026-10-08 | Proposed — pending user review | T3 package recommends separated message lanes, four visible effect groups with permanent inspection, and targeted icon refinement preserving source reuse. C1–C6 specify wording, grouping and audio lifecycle; R1–R3 await review. No runtime adoption or new numerical change. |

## Tracking and validation rules

- Use `Not started`, `In progress`, `Pending input`, `Blocked`, `Complete` or `Deferred`; explain blockers/deferrals and name the next action or owner.
- Mark completion with linked deliverables and evidence. Keep one current status in this tracker, with short summaries in the phase tracker and onboarding.
- Keep detailed inventory/design/evidence in linked task documents when needed. Do not duplicate running milestone history into onboarding or prepend repeated status notices.
- Record date, tested revision, exact command or manual procedure, result and evidence location. Separate automated checks, rendered inspection and user playtesting.
- Preserve stable content identities, real saves, the sibling Enigma project and unrelated workspace changes. Use isolated saves for validation.
- Run focused checks for affected behavior and appropriate final regression. Pure documentation edits require link/status/content checks, not gameplay suites.
- Record concrete design decisions and scope changes here; update the mechanics reference only when an approved mechanics change requires it.

## Progress history

- **2026-10-15 — T5 Complete:** User accepted the finished tooltip work and requested closeout under D039. [Accepted conventions and evidence](P6M7_T5_Closeout_And_Accepted_Conventions.md); next T6, Not started. M7 remains In progress. Documentation-only link/status/hash verification; no new gameplay run.

- **2026-10-08 — T3 design package prepared:** At the user’s request, developed C1–C6 conventions and interactive Separated lanes / Compact event list proposals with four example states and native-size icon review. Prototype checks pass; user R1–R3 review remains. T3 Pending input; T4–T11 Not started. [Design and evidence](P6M7_T3_Visual_Conventions_And_Feedback_Design.md).

- **2026-10-08 — T2 Complete:** Executed the user-requested audit. Live coverage, source-linked reuse, 140 rank descriptions, 23 skill summaries, effects and cues inventoried. Fresh rendered review reproduces dense overlap and overflow-label clipping; wording defects and art candidates assigned in G01–G12. Icon Lab freshness failure preserved. No gameplay/art changes or human acceptance claimed. [Audit](P6M7_T2_Presentation_And_Asset_Audit.md). T3–T11 remain Not started.

- **2026-10-08 — T1 Complete:** User accepted the plan and requested closeout (D002). Completed the planning checklist and synchronized the phase tracker and onboarding. Documentation links and task/status consistency checked; no gameplay tests required for this documentation-only change. T2 presentation and asset audit is next; T2–T11 remain Not started.

- **2026-10-08 — T1 planning started:** Created this tracker from the discussed eleven tasks with scope, dependencies, acceptance criteria and owners. Pruned onboarding, condensed the phase tracker and removed repeated M6 status notices. Documentation only; no asset production, gameplay changes or new playtest results.

## Related documents

- [T3 design package and review examples](P6M7_T3_Visual_Conventions_And_Feedback_Design.md)

- [T2 presentation and asset audit](P6M7_T2_Presentation_And_Asset_Audit.md)
- [T2 per-identity inventory](P6M7_T2_Presentation_Inventory.md)

- [Phase milestone tracker](P6_Milestone_Tracker.md)
- [Project onboarding](P6_Project_Onboarding_Context.md)
- [M6 tracker](P6M6_Enemy_Balance_And_Adventure_Progression_Tracker.md)
- [M6 closeout and M7 handoff](P6M6_T11_Closeout_And_M7_Handoff.md)
- [Accepted tree UI](P6M4_T10_Full_Tree_UI_UX_Plan.md)
- [M4 UI and feedback specification](P6M4_T2_UI_UX_And_Player_Feedback_Specification.md)
- [Icon Lab implementation](P6M4_T3_Icon_Lab_Implementation_And_Handoff.md)
- [Approved icon mappings](P6M4_Icon_Assignment_Integration.md)
- [Combat mechanics reference](Combat_Mechanics_Reference.md)
- [Legendary remake handoff](P6_Legendary_Remake_Next_Phase_Handoff.md)

### P6M7-D004 — Test Mode preview before adoption (2026-10-08)

The user requested implementation of the proposed changes in Test Mode only, allowing comparison and reversal before affecting Adventure. This authorizes the playable T3 experiment, including a runtime Original switch, rather than production adoption across modes. T3 remains Pending input for hands-on review; T4–T11 completion is not implied. See the [implementation and validation note](archive/m7/P6M7_T3_Test_Mode_Preview.md).

### P6M7-D005 — Restore original presentation (2026-10-08)

The user did not like the Test Mode experiment and requested the original. Restored the three existing runtime files to their verified pre-preview contents and removed the experiment scripts, controls and dedicated preview test. Retained reports and archived preview source as historical evidence. T3 remains Pending input; the experiment is not an accepted direction.

### P6M7-D006 — Category language prototype (2026-10-08)

User accepted the eight-step plan and requested implementation in Test Mode. Unify Attack, Debuff and Self Buff labels/accents, representative tooltips, non-damaging outcomes, stationary cast gestures/pulses and combat-log wording. Preserve current attack feedback and provide Original comparison. The [prototype](archive/m7/P6M7_T3_Category_Prototype.md) covers Stab, Venom Jab, Poison Vile and Virulent Poison; await user review before broader adoption.

### P6M7-D007 — Paired enemy-status columns in all modes

User requested Penetration icon/count directly below Shred and Potency directly below Decay in all game modes. Implemented shared vertical status columns for Adventure/Test and Practice, preserving each chip's tooltip, zero count, timer and active-state styling. Practice reserves additional HUD height for the second row. This cross-mode placement is explicitly authorized independently of the Test-only category prototype. Combat HUD and Practice view regressions pass (`p6_m7_status_columns_verified`); rendered geometry validation is retained in `p6_m7_status_columns_visual2`.

### P6M7-D008 — Red Attack and Test Mode icon-accent comparison (2026-10-09)

User chose red for Attack and requested the proposed thin-outline/bottom-edge comparison in Test Mode. Available Skills now provides Outline / Bottom edge / Off, shared with representative automatic skill unlocks in the tree. Accents are decorative and preserve button geometry. Combat comparison controls remain hidden. Four representative skills remain the scope; broader adoption is pending user review. Evidence and usage: [category prototype](archive/m7/P6M7_T3_Category_Prototype.md).

### P6M7-D009 — Silent blocked talent-node clicks (2026-10-09)

User requested removal of the status line caused by clicking full or unavailable talent nodes across the live game. Rejected buy/refund/edit-locked clicks now return without a feedback line or tree rebuild; preview-only nodes rely on their existing tooltips. Allocation restrictions and successful allocation/rotation-removal notices remain intact. The legacy ranked-panel error label is also hidden. Existing talent UI, full-tree display and usability checks pass in `p6_m7_silent_talent_clicks`.

### P6M7-D010 — Full Assassin icon comparison with macro accents (2026-10-09)

User chose bottom-edge accents for Available Skills and filled boxes for tree skill unlocks, then requested macro bottom edges and coverage of the full Assassin tree in Test Mode. Implemented all six Assassin skills, plus base Stab; Poison Strike's skill-granting talent node receives the fill. Passive talents retain their existing appearance. This does not authorize cross-mode promotion or expand the bespoke tooltip/cast-cue experiment. See the [prototype note](archive/m7/P6M7_T3_Category_Prototype.md) for setup and evidence.

### P6M7-D011 — Group combat-log events by exact instant (2026-10-09)

User requested indentation of information occurring at the same timeline tick. Adventure and Practice narrative logs now emit one millisecond-precision time heading per instant with event details indented beneath it; blank lines separate instants. The Test Mode category summary uses the same hierarchy, with outcome details one level deeper. Grouping uses integer event times and preserves tick-before-cast tie order, all event text and summaries. Dedicated checks cover simultaneous cast/tick events and distinct events one millisecond apart (`p6_m7_log_grouping_verified`). An older presentation test was updated to locate status chips inside the previously approved paired columns instead of assuming flat child indices.


### P6M7-D012 — All-tree skill category accents in Test Mode (2026-10-09)

User requested extending the approved icon treatments to every tree. Skill accents now cover Assassin, Shadow, Bladedancer, and Thief: Attack red, Debuff violet, Self Buff blue. Available Skills and macro buttons retain bottom-edge accents; talent-tree skill unlock boxes retain full fills, including skill-granting talent nodes. Passive talents retain their existing appearance. Test Mode gating and the separate four-skill tooltip/floating-text prototype remain unchanged.

Verification: `project/reports/p6_m7_all_tree_accents_verified` exercises all four trees, category treatments at three resolutions, unchanged button dimensions, and absence of accents in Adventure mode.


### P6M7-D013 — Test Mode per-tree point counters (2026-10-09)

Added a compact point counter in the upper-right of each selected tree header, styled and sized similarly to the reset button. It displays invested ranks / total tree ranks (currently x/35 for each tree), refreshing with allocation, refunds, and resets. It occupies existing header space without shifting the talent graph. Test Mode only.


### P6M7-D014 — Promote approved visuals to live modes; exclude log prototype (2026-10-09)

User accepted the Test Mode changes except combat-log changes and requested live-mode promotion. Adventure and Practice now use all-tree skill accents (bottom edge in Available Skills and macro; full fill for tree skill boxes), per-tree x/35 counters, and the approved four-skill category tooltip/floating-text/non-attack-motion treatment. Existing universal status-column, cooldown-text suppression, and silent invalid-talent-click changes remain. The overall Points X/Y talent-window subtitle is removed in every mode; Practice's budget editor remains available.

Live modes retain the original plain event log, including original per-event timestamps. The experimental colored/grouped log remains Test Mode only. Live icon treatments ignore stale Test Mode comparison settings; comparison controls remain Test Mode only. This promotes the approved presentation without expanding the bespoke four-skill tooltip/animation scope to unreviewed skills or changing combat mechanics.

Verification: `p6_m7_live_promotion_checks` passed talent, skill, Adventure combat, category, and log checks; the Practice old-color assertions were updated to the approved red attack color. `p6_m7_live_promotion_verified` passed Practice combat and category feedback checks, including charges, cooldown suppression, non-lunging buff animation, and speed-change cleanup. Live visual evidence is recorded under `p6_m7_live_promotion_visual`.

### P6M7-D015 — User-requested T3 closeout (2026-10-09)

T3 Complete at the user's explicit request. [Accepted conventions and closeout](P6M7_T3_Closeout_And_Accepted_Conventions.md) consolidates D005–D014, live promotion evidence, the combat-log exclusion, and named handoffs. Exact icon refinement and effect-overflow choices move to T4/T6; the withdrawn R1–R3 package is not implicitly approved. T4–T11 remain Not started; T4 is next. M7-wide presentation/accessibility/playtest acceptance remains downstream. Documentation-only closeout; no runtime or gameplay changes.

### P6M7-D016 — T4 production and concrete review (2026-10-09)

User requested carrying out T4. Reconciled Icon Lab with all 93 live identities and strict legacy-workspace migration; prepared five readability candidates and recorded focused/browser/rendered evidence. T4 is Pending input for the concrete review required by D015, followed by final live integration and affected verification. Approved runtime mappings and frozen exports remain unchanged. [T4 deliverable](archive/m7/P6M7_T4_Icon_Production_And_Integration.md).

### P6M7-D017 — Flat charcoal icon backing (2026-10-09)

User selected Flat charcoal after requesting hard-square consistency across mixed icon packs. Prepared a full 93-identity review gallery using the chosen backing and five refined candidates. T4 remains Pending input for full-set consistency feedback before live integration; this records the chosen direction without reopening the three-way background choice. [Gallery and evidence](archive/m7/P6M7_T4_Icon_Production_And_Integration.md).

### P6M7-D018 — Full icon-set approval and integration (2026-10-09)

User accepted the full Flat charcoal gallery and deferred individual art changes to the tooltip audit. This approves the five refinements and common square backing across all 93 identities. Integrate through the reproducible installer, preserve original art and source-linked buffs, and close T4 after focused and rendered verification. T5 should record any further icon issues alongside tooltip findings; do not reopen the accepted treatment without concrete feedback.

**D018 closeout evidence:** Five focused suites and the rendered icon suite pass; 17 authoring checks and 28 browser groups pass. T4 Complete; T5 next. [Final record](archive/m7/P6M7_T4_Icon_Production_And_Integration.md).

### P6M7-D019 — Test Mode Available Skills styling trial (2026-10-09)

User approved implementing the reviewed combination in Test Mode for in-game evaluation: #28282B normal button fill, 48px icons with 6px rounded display corners, 8px horizontal / 4px vertical padding, and 4px category bottom bars. Buttons remain 64x56. Scope is the Available Skills palette in Test Mode; Adventure, Practice, macro slots, tree boxes, and original icon textures retain their existing presentation. Existing hover/pressed/focus feedback and Test Mode category-style selector remain available. This is an in-game trial, not approval for wider promotion; T5 remains next.

Actual implementation rendered successfully at 1280, 1600, and 1920 widths, with Adventure scope checks: `project/reports/p6_m7_test_skill_styling_live/`. Skill/Practice regression evidence: `project/reports/p6_m7_test_skill_styling_regression/`.

**D019 sizing revision:** User requested reverting the enlarged icons after noticing scaling artifacts. Restored the original 40px icon minimum and 12px horizontal / 7px vertical padding in Test Mode, keeping the charcoal normal fill, rounded corners, 4px category bars, and 64x56 buttons. The original display size was 40px (source artwork remains 32px). Updated rendered evidence: `project/reports/p6_m7_restored_skill_icon_size/`.

**D019 compact/native-art adoption:** User approved the final compact preview for Test Mode. Available Skills now uses 48x48 buttons, original 32x32 skill artwork composed without resampling inside a 40x40 rounded charcoal frame, and a 6px category bar meeting the frame's bottom edge. Margins are 4px left/right, 2px top, and 6px bottom. This supersedes the earlier Test Mode sizing revisions. Source textures are explicitly preloaded in `project/scripts/ui/test_mode_skill_icons.gd` and composed tiles are cached; source files and global icon mappings remain intact. Adventure, Practice, macro slots and tree boxes keep their existing styling. Three-resolution rendering, original opaque-pixel preservation, and Adventure scope checks pass in `project/reports/p6_m7_compact_native_live/`; focused regression evidence is in `project/reports/p6_m7_compact_native_regression/`.

### P6M7-D020 — Practice macro-bar styling trial

User approved the macro preview specifically for Practice Mode testing. Practice Skill Build slots now use 76x80 buttons, 64x64 artwork from exact 2x nearest-neighbor enlargement of the original 32x32 source, 72x72 rounded charcoal frames, and 6px category bars meeting the frames. Ten slots fit at 1280, 1600 and 1920 window widths. Order badges, active/proc highlights, cast fill, interrupt/stun overlays, and unavailable-Parry greying remain functional; greying shares the rounded shader so it cannot remove the corner mask. The native-art cache distinguishes 1x Test Mode palette tiles from 2x Practice macro tiles. Adventure and Test Mode macro styling remain unchanged; Practice Available Skills remains unchanged.

Actual Practice rendering evidence: `project/reports/p6_m7_practice_macro_live/`. Focused readiness, Practice combat and skill regression evidence: `project/reports/p6_m7_practice_macro_regression/`. This is a Practice trial, not wider promotion.

**D020 scope correction (user clarification):** Move the macro trial out of Practice and into Test Mode alongside the Available Skills trial. This supersedes D020's original Practice-only scope. Test Mode now has both treatments; Practice's original 64x64 macro slots, artwork display, button fill, and readiness shader are restored. Adventure remains unchanged. Test Mode macro rendering passes at 1280/1600/1920, with explicit restored-Practice and unchanged-Adventure checks in `project/reports/p6_m7_macro_test_mode_scope/`. Focused regression evidence: `project/reports/p6_m7_macro_scope_regression/`.

### P6M7-D021 — Stable Test Mode macro layout (2026-10-13)

User approved the measured layout fix for Test Mode. Reserve the full 80px height for the macro row, grid and lock holder even with an empty rotation; reduce horizontal slot gaps from 6px to 4px. The artwork remains 64x64 at exact 2x source scaling, inside 72x72 rounded frames and 76x80 buttons with 6px category bars. This prevents the first skill from raising the macro/Available Skills panels and the tenth skill from widening the center column. Practice and Adventure retain their existing dimensions and spacing. Actual empty/1/9/10-slot stability and mode-scope evidence: `project/reports/p6_m7_macro_stable_layout_live/`.


### P6M7-D022 — Approved icon-bar styling across game modes (2026-10-13)

User approved promoting the reviewed Test Mode icon-bar aesthetics and stable layout to the rest of the game. Available Skills uses original unscaled 32x32 artwork in rounded 40x40 charcoal frames, 48x48 buttons, and 6px category bars. The macro uses exact 2x artwork at 64x64 in rounded 72x72 frames, 76x80 buttons, and 6px category bars. All modes reserve the full 80px macro row/grid/lock-holder height and use 4px horizontal slot gaps to prevent empty-to-first and full-row layout jumps. This supersedes D019-D021's Test Mode-only scope and D020's temporary Practice reversal. Preserve skill input, tooltip providers, category feedback, active/proc progress, cooldown, interrupt, stun and readiness behavior. Original assets and global mappings remain intact; category selectors and the earlier log experiment remain Test Mode-only. T5 remains next; this approval does not close downstream accessibility or human playtesting.


**D022 integration evidence:** Shared macro content margins are 8px, and its grid reserves 796x80 even when empty; this resolves the narrower Practice center column without shrinking artwork. Final rendered verification passes 4/4 suites: [summary](../project/reports/p6_m7_icon_styling_promotion_visual_final/summary.json). All 36 combinations of Adventure/Practice/Test, 1280/1600/1920 widths, and 0/1/9/10 slots have stable positions, preserved icon sizes, no lock overlap and no macro overflow. Native source-pixel preservation and rounded Readiness greying pass rendered checks. Focused UI interaction, Practice combat, build-panel effect and Readiness checks pass in [regression evidence](../project/reports/p6_m7_icon_styling_promotion/summary.json). Both isolation records report unchanged source files and disposable saves. Adventure and Practice representative renders were visually reviewed.

**Verification limitation:** The additional `combat_playback_test` execution fails its existing autosave assertion at source line 717; the cause remains undiagnosed and save/combat code was not changed. This is recorded for follow-up rather than changing autosave behavior for an aesthetic promotion. The initial headless source-pixel check used unsuitable Dummy texture readback; that check is now rendered-only and passes. The initial Practice width issue is fixed in the final rendered report. These samples do not close the full T8 accessibility matrix or later human playtesting.

### P6M7-D023 — Restore Bladedancer and Thief subclass icons (2026-10-13)

User requested restoring the existing icons in the subclass menu. Current Bladedancer and Thief content builders now assign their packaged subclass textures, matching Assassin and Shadow. The previous legacy resources had these assignments, but the current generated trees omitted them. No new artwork or gameplay changes. Verification uses current Adventure and Test/Practice registries and the rendered four-card subclass menu: `project/reports/p6_m7_subclass_icon_restore_final/`.


### P6M7-D024 — First-contract secondary subclass reward (2026-10-13)

User explicitly approved an Adventure progression change: the first completed contract earns access to a second subclass, with two randomly selected, distinct options from the three subclasses other than the primary. Contract acceptance and ordinary route victories do not earn this reward. Complete the first contract's normal terminal rewards/shop, then resolve the subclass choice before the next contract selection. Keep the offered pair fixed across reopen and save/load, preserve the primary and allocated ranks, and retain second subclasses already chosen in existing runs. Test Mode and Practice keep unrestricted role selection. This is an approved progression addition alongside the presentation work; it does not change the remaining M7 task statuses.


**D024 integration evidence:** Implemented shared state offer generation and selection validation, persisted `secondary_subclass_offer_ids`, updated ranked/legacy selection UI, and prioritized the earned-choice modal after terminal rewards/shop and on pending save resume. Accepting the next contract is blocked until selection; primary and talent ranks are preserved. Save version 2 remains unchanged. Missing offer IDs in older unchosen saves use a deterministic seed-based fallback; valid existing early-chosen secondary saves retain their previous load acceptance. Test Mode and Practice retain their selection freedom.

Seven focused suites pass in [verified regression](../project/reports/p6_m7_secondary_reward_verified/summary.json), including real route/terminal/shop progression, all four primaries, pair stability and membership, pending/selected/older save round trips, build-state progression, generated saves, save boundaries and Test Mode roles. Final header regression passes 2/2 in [final headless checks](../project/reports/p6_m7_secondary_reward_header_check/summary.json). The focused reward test passes rendered verification with all-four-primary screenshots in [final UI evidence](../project/reports/p6_m7_secondary_reward_ui_final/summary.json); the Assassin render was also reviewed by the coordinating agent. An independent Astra/High read-only review found no material issues in gating, persistence, UI ordering, resume or compatibility. Validation used disposable saves and unchanged source hashes during each final run.

**Verification limits:** The broader rendered `combat_screen_test` stops at its earlier Mouthy Drunk fight-status assertion at line 500; that same suite passes headless, and the focused rendered reward flow passes. The older `shadow_parity_test` stops at its legacy poison-effect assertion at line 45 before reaching subclass behavior; its adaptations were reverted. These failures remain recorded for separate investigation. No unrelated poison/combat timing or save behavior was changed to satisfy them. Human testing of reward pacing and first-contract difficulty remains appropriate; no balance values changed.

### P6M7-D025 - Minimal skill tooltip language (2026-10-14)

User approved implementing the item-style semi-transparent black skill hover: top-aligned original 32px icon/cream 22px name, 18px category color and qualitative cast bracket, 20px current-build planning damage and short basic effects. Show core stack/consumption/buff/theft/critical numbers; omit formulas, gear/other-skill interactions, ordering, caps, cooldown/unlock/live-stash/slot clutter. Apply consistently to Available Skills, macro and automatic tree skill boxes in all modes. Talent tooltips and skill-granting talent nodes remain unchanged. Preserve detailed mechanics for internal reference; no gameplay or art changes. [Implementation and evidence](archive/m7/P6M7_T5_Minimal_Skill_Tooltip_Design_And_Implementation.md). T5 remains In progress; individual review and closeout remain deferred.

**D025 implementation evidence:** Shared structured renderer/providers installed in all three skill surfaces and all modes; detailed formatter and talent method bodies unchanged. Three focused suites plus corrected build-panel check pass; 78 actual engine hovers across three resolutions, categories, modes and 125% stress pass and were inspected. Final source fingerprints match; disposable saves/source isolation unchanged. See the linked design note. T5 remains In progress.

**D025 cooldown revision (2026-10-14):** User requested the basic cooldown time as a separate field. Skill hovers now place an 18px cream `Cooldown: Ns` line below category/cast, or `Cooldown: None` when absent. Effect text remains unchanged; deeper cooldown interaction rules stay omitted. All three surfaces share this field. Focused verification passes 562 checks and rendered verification passes 78 live hovers, using disposable saves with unchanged source isolation; representative renders were inspected. [Evidence](archive/m7/P6M7_T5_Minimal_Skill_Tooltip_Design_And_Implementation.md#separate-cooldown-field--2026-10-14). T5 remains In progress.

**D025 timing-by-type revision (2026-10-14):** User superseded the all-skill cooldown row: Attack omits timing rows; Debuff and Self Buff show separate Cooldown and Duration fields. Duration describes fixed seconds, instant effects, charge exhaustion or stack depletion as applicable. Fixed durations move out of effect text; mechanics and talent tooltips remain unchanged. [Current format and evidence](archive/m7/P6M7_T5_Minimal_Skill_Tooltip_Design_And_Implementation.md#timing-by-skill-type--2026-10-14). T5 remains In progress.

### P6M7-D026 - Minimal talent tooltip language (2026-10-14)

User approved extending the item-style semi-transparent black hover to talents: original 32px icon/cream 22px VT323 name; 18px tree and Rank x/y; concise 20px basic effects. Show shared rules once and compare only changing Current -> Next numerical values. Rank zero shows Next, maximum shows Current plus Max rank, and single-rank nodes show their core rule or Unlocks Skill Name. Use cream benefits, yellow special mechanics and violet actual penalties with explicit stat names/signs; place drawbacks after benefits. Show compact named Requires only for missing lower-tier gates/prerequisites. Omit duplicated paragraphs, gear/proc-ordering explanations and detailed exceptions. Skill hovers, mechanics, resources and artwork remain unchanged. [Implementation and evidence](archive/m7/P6M7_T5_Minimal_Talent_Tooltip_Design_And_Implementation.md). T5 stays In progress; individual wording review and closeout remain deferred.

**D026 implementation evidence:** All 44 talents/140 ranks use the structured model in Adventure, Test Mode and Practice; source-backed compact inventory includes 184 zero/positive-rank states. Focused model/provider checks (3,429 assertions) and existing talent allocation UI suite pass. Rendered suite passes 84 live hovers across all four trees, three sizes, modes and 125% text, including partial/max/single unlock and blocked named requirements; representative images inspected. Skill files/providers and detailed talent effects remain unchanged. Source fingerprints and the rendered runner's independent-test-only concurrent-change diagnostic are recorded in the linked note; saves are disposable. No milestone closeout.

**D026 separate-next-rank revision (2026-10-14):** User approved separate current-effect and `Next rank:` sections using the supplied World of Warcraft examples. Rank zero shows only Next rank; maximum omits the next section entirely. Remove arrow comparisons and redundant Current/Max rank headings. Both sections retain the same item palette, basic values and concise effect copy. Skills, mechanics and art remain unchanged. Verification is recorded in the linked talent design note; T5 remains In progress.

**D025/D026 Retrigger terminology correction (2026-10-14):** User confirmed Retrigger as the mechanical keyword. The short Dance of Death and Precision Attacks hovers had used repeat; both now say guaranteed Retrigger. Consistent buff/retained tooltip descriptions also use Retrigger. Double Dip retains numeric Retrigger Chance wording; guaranteed effects do not change that stat. No combat/stat/resource changes. Five affected suites pass in project/reports/p6_m7_retrigger_wording_focused/summary.json, using disposable saves and unchanged source isolation. T5 remains In progress.

### P6M7-D027 — Text-only talent entries in Active Talents (2026-10-14)

User requested removing individual talent icons from the Active Talents panel while retaining subclass icons. Talent names/ranks now sit directly above their existing effects, with full-width wrapping for long names. Subclass portraits, intrinsic text, point badge, scrolling and Talent Trees controls are retained. The shared panel applies this in Adventure, Test Mode and Practice; talent-tree and tooltip artwork remain unchanged.

`python tools/p6/run_m6_closeout.py --report-name p6_m7_active_talents_text_focused --tests build_panels_test` passes. The existing actual-hover visual matrix passes 84 captures in [rendered evidence](../project/reports/p6_m7_active_talents_text_rendered/summary.json), covering all four trees, modes and supported sizes; Adventure and Practice 1280-wide panel samples were inspected. Both runs use disposable saves and report unchanged source isolation. This is an icon/layout change, not an effect-text audit or gameplay change. T5 remains In progress.

### P6M7-D028 - Subclass tree backgrounds and current-rank Active Talents (2026-10-14)

Shadow artwork refresh: replaced and reimported the packaged Shadow background with the user's improved image at the same source path. Retained the 65% overlay after actual panel/hover review; the existing 87-capture visual suite passes in [refresh evidence](../project/reports/p6_m7_shadow_background_refresh/summary.json). Replacement fingerprint is recorded in the implementation document below.

User approved copying the four original subclass JPG backgrounds and displaying them behind the complete inner Primary/Secondary tree panels with proportional cover cropping, rounded clipping and a runtime black overlay. Stable tree IDs follow all modes and role swaps; the empty secondary remains unchanged. The originals are preserved byte-for-byte. A decorative Node2D retains layout minimums, graph coordinates, frame and input; rendered review accepted 65% black overlay for all four images.

Active Talents now shares the hover's current-rank structured text and cream/yellow/violet colors at 13px for all 44 talents/140 ranks. Names/ranks, subclass portraits and legacy fallback remain; individual icons and Next rank/Requires are absent. Existing skill/talent hover formats and gameplay remain unchanged.

[Implementation and evidence](archive/m7/P6M7_T5_Tree_Backgrounds_And_Active_Talent_Text.md): 1,355 focused checks, existing build-panel/talent UI suites and 87 actual rendered captures pass. All modes, four trees, 1280/1600/1920 widths, 125% stress, dense builds, live hover, role swaps and empty secondary are covered. Final source isolation is unchanged; source/copy SHA256 matches and unchanged hover/mechanics fingerprints are recorded. T5 remains **In progress**; no milestone closeout.

### P6M7-D029 - Neutral talent effects and stack terminology (2026-10-14)

User requested temporarily making all talent effects cream and removing Requires text from talent hovers. Shared Active Talents current-rank rows inherit cream; explicit values/signs and existing drawback order remain. Graph/allocation gating and current/Next/max sections remain unchanged. Approved Bladedancer wording updates cover Shred armor decrease, complete Fancy Footwork stack/time/consumption rule with positive reduction values, Precision Attacks, Double Dip and x-prefixed Sharpened Edge/Riposte/Weapon Master values.

User clarified the first-hit 100% Retrigger Chance sentence belongs to Dance of Death; Parry Strike changes only Readiness charge to stack. Visible numerical buff units use stacks throughout compact/detailed skill text, category preview, effect inspector/status and macro feedback. Internal charge fields and mechanics remain unchanged. Preserve the new Shadow image and increased-stacks gear label.

[Decision and evidence](archive/m7/P6M7_T5_Neutral_Talent_And_Stack_Wording.md): 4,661 talent checks, 608 skill checks, 1,355 shared Active Talents checks, existing allocation UI and three affected terminology suites pass. Final rendering passes 87 tree/Active captures and 78 actual skill hovers across modes, sizes and 125% stress; the longer Fancy Footwork current+next fits. Source/save isolation and final fingerprint reconciliation are recorded. T5 remains **In progress**; no milestone closeout.

### P6M7-D030 - Thief tooltip revision (2026-10-14)

User approved Thief intrinsic x10% in tree headers/Active Talents and retaining additive +2% per invested primary point without the Thief-only `(primary only)` suffix; actual secondary Bonus: NONE and scaling remain unchanged. Mug/Big Score use the supplied copy; Pick Pocket omits Duration while retaining Cooldown. Keen Eye/Sticky Fingers use x-prefixed live percentages; Fast Hands/Fill Your Pockets use the requested conversion rules and plain live conversion percentages. Gilded Blade states +1% Critical Damage per stash gold, maximum +500%. Charisma/Loaded Dice remain additive.

[Implementation and evidence](archive/m7/P6M7_T5_Thief_Tooltip_Revision.md): 4,716 talent checks, 609 skill checks, 1,356 shared Active Talents/background checks and 33 focused actual renders pass. All modes, role distinction, three header resolutions and 125% long current/next conversions/skill timing are covered. Final fingerprints/save isolation reconcile; neutral effects/no Requires/omission of Next at maximum rank, new Shadow art, gear label and mechanics are preserved. T5 remains **In progress**; no closeout.

### P6M7-D031 - Assassin tooltip revision (2026-10-14)

User approved omitting Assassin's per-point `(primary only)` suffix while retaining primary-only scaling and secondary Bonus: NONE. Venom Jab/Potency use the supplied stack wording with current-build counts; Virulent/Vile omit Duration while retaining Cooldown; Master of Poisons uses the supplied Resistance wording. Echoing Toxin/Resonance show requested x-prefixed live values; Hastened/Accelerant use tick-rate conversion percentages; Bypass/Critical Poison use the full supplied concise rules. Shared Active Talents inherits the current-rank copy.

[Implementation and evidence](archive/m7/P6M7_T5_Assassin_Tooltip_Revision.md): 4,750 talent checks, 612 skill checks, 1,356 shared Active Talents/background checks and 48 narrow actual renders pass. All modes, three header resolutions, primary/secondary roles and revised skill/talent hovers at 125% are covered. Initial test-only failures and final fingerprint reconciliation are recorded. Neutral effects/no Requires/current-Next-max format, Thief D030, Shadow art, gear label and all 330 protected mechanics files remain unchanged. T5 remains **In progress**; no closeout.

### P6M7-D032 - Shadow tooltip revision (2026-10-14)

User approved the Shadow per-point suffix removal and supplied compact skill/talent wording. Distilled Corruption shows its current-build full-consumption Poison application maximum, including gear/talent bonuses and doubling. Beguiling Strike uses live Decay application counts; Death Strike omits the redundant non-consumption line; Touch/Beguiling Presence use the supplied base-bonus copy. Deception retains its actual Elemental Damage stat with x-prefixed values. Coated Weapons/Death Touch/Death Blade/Dusk/Mastery/Umbral use supplied source-backed copy, with one combined Dusk row.

User clarified Death Pact must name Poison or Decay and keep mechanics unchanged. Its duration row shows current total 4/5/6 seconds. [Implementation and evidence](archive/m7/P6M7_T5_Shadow_Tooltip_Revision.md): 4,771 talent checks, 748 skill checks, 1,352 shared Active Talents checks and 66 targeted actual renders pass. Palette/macro/tree providers refresh Distilled 5/7/13/26 across base/gear/talent/doubling changes in every mode. Long current/Next text fits at 1280/125%; role headers cover all three resolutions. Final fingerprints/save isolation reconcile; prior copy/neutral format/art/gear label and 330 protected mechanics files remain unchanged. T5 remains **In progress**; no closeout.

### P6M7-D033 - Talent value hierarchy and shorter Next rank (2026-10-15)

User approved gold scaling values, clearer description/value and Next spacing, and shorter Next rank containing only changed values or newly introduced/changed effects. Labels/rules remain cream; static embedded numbers remain cream. Stable-key label/value comparison preserves full current effects and new higher-rank rules. Rank zero shows base explanation once above first-level Next values; rule/unlock-only talents omit an empty Next section. Max still omits Next and Requires stays absent. Shared rich rows apply the same format to current-only Active Talents at 13px, retaining names/ranks/subclass portraits and legacy fallback. Skill styling/category colors remain unchanged.

[Implementation and evidence](archive/m7/P6M7_T5_Talent_Value_Hierarchy_And_Next_Rank_Polish.md): 6,917 talent checks, 1,698 shared Active Talents/background checks, existing build panels and 62 targeted actual captures pass. All trees/modes, zero/partial/max/unlock states, negative values, long labels, 1280/1600/1920 samples and actual 125% rich text are covered. Fitted wrapped heights and final source/save isolation pass. Prior wording, six skill files, art/gear labels and 330 protected mechanics files remain unchanged. T5 remains **In progress**; no closeout.

### P6M7-D034 - Thief tooltip copy refinement (2026-10-15)

Removed the requested trailing periods, added Bribery and Finders Keepers explanations, shortened Silvered Edge's rule, and moved Gilded Blade's cap to a separate `max: +500%` row. Shared Active Talents inherits the talent changes; gold values, spacing and changed-only Next rank remain intact. [Evidence](archive/m7/P6M7_T5_Thief_Tooltip_Revision.md): both focused tooltip suites and 45 targeted actual renders pass with isolated saves and unchanged source isolation. All 330 protected mechanics files remain unchanged. T5 remains **In progress**.

### P6M7-D035 - Bladedancer tooltip copy refinement (2026-10-15)

Removed the requested trailing periods, shortened Dance of Death's first-hit Retrigger sentence, and changed Side Step to a single non-scaling effect sentence without Next rank in either unlearned or learned state. Shared Active Talents inherits the talent text. [Evidence](archive/m7/P6M7_T5_Minimal_Talent_Tooltip_Design_And_Implementation.md): both focused tooltip suites and 68 actual hierarchy captures pass, with enlarged-text Side Step samples inspected. Source/save isolation and all 330 protected mechanics files are unchanged. T5 remains **In progress**.

### P6M7-D036 - Assassin tooltip copy refinement (2026-10-15)

Removed the requested trailing periods and changed Resonance's explanation to `Each tick of Poison now consumes 3 stacks but does more damage`. Gold scaling values, shorter Next rank and shared Active Talents formatting remain intact. [Evidence](archive/m7/P6M7_T5_Assassin_Tooltip_Revision.md): both focused tooltip suites and 48 actual Assassin captures pass, with Resonance/Poison Vile at 125% inspected. Source/save isolation and all 330 protected mechanics files are unchanged. T5 remains **In progress**.

### P6M7-D037 - Shadow tooltip punctuation refinement (2026-10-15)

Removed the requested trailing periods from Death Strike, Death Pact, Death Blade and Shadow Mastery, including shared Active Talents text. Both [focused tooltip suites](../project/reports/p6_m7_shadow_punctuation_focused/summary.json) pass with unchanged source/save isolation. Layout, gold values, rank behavior and all 330 protected mechanics files are unchanged. T5 remains **In progress**.
### P6M7-D038 - Keyword capitalization and cyan Buff references (2026-10-15)

User approved canonical keyword capitalization and existing Self Buff cyan (#9ED5EF) for named Buff references across skill/talent effects and shared Active Talents. Statuses (including Potency/Penetration), stats and skill references remain cream; talent scaling values retain gold. Longest whole-phrase matching preserves distinct stat names and ordinary prose. Crit Chance/Crit Damage use the approved short forms and accept Critical aliases. Plain fallbacks and tree/Active intrinsic/bonus summaries normalize consistently. Headers/categories, prior D034–D037 wording/punctuation, current/Next/max behavior, art and gear labels remain intact.

[Implementation and evidence](archive/m7/P6M7_T5_Keyword_Capitalization_And_Buff_Coding.md), [names/aliases reference](P6M7_T5_Presentation_Keyword_Reference.md): five focused suites pass (1,423 keyword, 7,940 talent, 748 skill and 1,728 shared Active checks plus build panels); 69 main and three supplemental actual captures pass across modes, including enlarged rich text and long cyan/gold paragraphs. Final source/save isolation and fingerprint reconciliation pass; all 330 protected mechanics files remain unchanged. T5 remains **In progress**; no closeout.

### P6M7-D039 - User-accepted T5 closeout (2026-10-15)

User explicitly accepted T5 as finished and requested closeout/documentation updates. [Closeout and accepted conventions](P6M7_T5_Closeout_And_Accepted_Conventions.md) consolidates D025–D038, final automated/rendered evidence, minimal-format boundaries and G06/G07/G09/G10/G12 downstream owners. T1–T5 Complete; T6–T11 Not started; M7 remains In progress. Next is T6 temporary-effect display completion; no T6 work started. Documentation-only recheck confirms accepted D038 code/art/gear labels and all 330 protected mechanics files unchanged; real saves untouched. Earlier dated In progress/closeout-excluded notes remain historical.



### P6M7-D040 — User-requested T6 implementation and review package (2026-10-15)

User requested carrying out the T6 audit, implementation, verification and review steps. [T6 record](P6M7_T6_Temporary_Effect_Display_Completion.md) documents a conservative repair of the existing compact row/inspection interaction: fitted overflow text, active/held independent entries, activation counts, lifecycle cleanup and focus recovery. Four existing focused suites and final rendered T6 suite pass; 114 captures cover scoped cross-mode/font/overflow cases and replay integration. Original runtime reproduces six inherited status-signature failures. Captured mechanics, artwork and real userdata are unchanged. T6 is **Pending input** for user presentation review; no user acceptance of the withdrawn T3 design or T6 closeout is claimed. T7–T11 remain Not started.


### P6M7-D041 — User-accepted T6 closeout (2026-10-15)

User explicitly accepted the T6 results after buff testing and requested closeout. [Accepted treatment, evidence and T7 handoff](P6M7_T6_Temporary_Effect_Display_Completion.md) retain readable overflow, active/held instance inspection, timers/activation counts and lifecycle/focus fixes. Existing four focused passes and final rendered T6 pass with 114 captures remain the scoped evidence; inherited signature failures, synthetic density and 100ms inspector refresh are recorded. Documentation-only fingerprint/link/status verification confirms no runtime changes. T1–T6 Complete; T7–T11 Not started; M7 remains In progress.

T7 feedback: user enjoys retriggers but reports large chains as a jarring instant burst. Review presentation pacing alongside crowded popups and audio lifecycle. Slower animation and the assistant's staggered/accelerating flurry, totals and finishing accents are unapproved options, not adopted timing or mechanics changes.


### P6M7-D042 — Authorized retrigger flurry implementation (2026-10-15)

User requested implementation of the discussed retrigger-feedback changes after T6 closeout. [Implementation, tuning, verification and motion previews](archive/m7/P6M7_T7_Retrigger_Flurry_Presentation.md) record bounded accelerating flurries, continuous contact/trails, compact count/damage, final accent, counterplay outcomes and sound/lifecycle guards across all modes. Viewing time is separate from simulation time; ordered observation frontiers keep effects/health synchronized without changing resolver results. Six focused suites and cross-mode motion checks pass, with T6 display regression carried forward; known autosave and inherited signature failures remain documented. Original mechanics/data/art and captured real userdata remain unchanged. T7 In progress; retrigger implementation is ready for user playtesting, not full T7 acceptance. T8–T11 Not started.


### P6M7-D043 — Authorized ghost retrigger prototype (2026-10-15)

User requested a revision after testing D042: keep the main actor anchored during follow-ups, use semi-transparent ghost attacks, remove the combo text and X effect, and slow retriggers further for 4× playback. [Prototype treatment, timing and evidence](P6M7_T7_Ghost_Retrigger_Prototype.md) implement that scope in Adventure, Test Mode and Practice. One faded original-art echo performs extra contacts, with a 140 ms minimum real-time contact gap and a brief recovery before the next normal attack. Ordered playback keeps health/effects/audio synchronized and protects next-macro consumption during recovery. Eight focused suites pass, including T6 regression; actual 1×/4× cross-mode motion and protected-file/save checks accompany the prototype. Full T7 and audible/user acceptance remain open. T1–T6 Complete; T7 In progress; T8–T11 Not started.


### P6M7-D044 — Authorized lighter retrigger impact labels (2026-10-15)

After preferring D043's ghost treatment, the user requested restoring follow-up skill/damage text with less visual weight. [Current prototype record](P6M7_T7_Ghost_Retrigger_Prototype.md#d044--lighter-retrigger-impact-labels) records 75% font size, 65% opacity, a short 240 ms lifetime, less rise, target-relative lanes and a two-label live cap across Adventure, Test and Practice. Only visible presentation strikes emit labels; opening attacks retain their full-weight text. Actual damage/counter outcomes and cleanup remain, with no combo/X or mechanics changes. Focused behavior and rendered 1×/4× evidence are linked from the prototype record. T7 remains In progress pending user/audible acceptance; T1–T6 Complete and T8–T11 Not started.


### P6M7-D045 — Sixteen visible retrigger-chain strikes (2026-10-15)

User requested increasing the visible cap from eight to sixteen for rare powerful chains. [Current prototype record](P6M7_T7_Ghost_Retrigger_Prototype.md#d045--sixteen-visible-strikes-per-chain) records up to 16 visible/audio strikes including the opener, retained real-time pacing, and unchanged ghost/text styling. Excess events still resolve in order with full damage; the two-label live limit remains. Two affected isolated suites pass including 16/17/200-attack cases. Resolver safeguards and balance are unchanged. T7 remains In progress; no broader milestone closeout.


### P6M7-D046 — T7 mixed-cue/audio verification and closeout (2026-10-15)

User accepted the ghost/retrigger/proc treatment through D045 and requested the remaining G06/G10 work. [Scoped closeout](P6M7_T7_Combat_Cues_And_Audio_Verification.md) records bounded normal/Poison feedback, fitted wide outcomes, text above actors, and immediate cancellation during screen exit crossfades. Six focused suites, 126 matching rendered captures across 18 mode/speed/motion settings, and real WASAPI cancellation/navigation/fresh-audio checks pass. The user listened to actual 1×/4× ghost-chain recordings and replied “Both sound good.” Parent source/visual/PCM review and protected baseline checks pass. Original art, data, combat systems/resources and all 1,170 captured real userdata files remain unchanged. Synthetic special-outcome fixtures, accelerated layout stepping and inherited M9/legacy test exceptions are disclosed. T7 Complete; T1–T7 Complete; T8–T11 Not started; M7 remains In progress. T8 integrated UI/accessibility review is next.


### P6M7-D047 — T8 integrated UI/accessibility review completion (2026-10-15)

User requested execution of the T8 steps. [Scoped review and closeout](archive/m7/P6M7_T8_Integrated_UI_And_Accessibility_Review.md) covers Adventure/Test/Practice at three physical sizes and normal/diagnostic125% text, distributed all-four-tree primary/secondary roles, real resolver builds, selected hovers/overlays and dense diagnostic effects. Six repairs address Settings focus containment/return/visibility, active HUD numeral contrast, popup pivot bounds, heading wrapping and Practice footer clearance. The 18-case main matrix and targeted footer/tooltip/ghost/motion/focused checks pass. Parent inspected actual frames, code and isolated source equality; all1,341 protected paths and captured non-log saves/configuration match baseline. One old log missing/rotated has no verified attribution; capability/diagnostic/M9/legacy-test limits remain explicit. T8 Complete; T1–T8 Complete; T9–T11 Not started. User playtesting is next; no milestone-wide user acceptance, balance change, commit or publication is implied.

### P6M7-D048 — T9 preparation and human feedback collection started (2026-10-16)

User requested T9 execution and confirmed they are beginning latest-build playtesting; no fresh results yet. [Checklist and collection record](archive/m7/P6M7_T9_User_Playtesting_And_Feedback.md) provide a familiar Practice pass, complementary tree and Adventure cases, read-only saved context, candidate source fingerprint and six earlier accepted feedback records. Historical unknowns and random-seed limits remain explicit. T9 In progress; T10–T11 Not started. No runtime, balance or save edits, fabricated human passes or milestone acceptance.

### P6M7-D049 — Authorized playtest refinements: menu visibility and talent preparation (2026-10-16)

User requested hiding main-menu Test Mode and Archetype Glossary, Tavern skill reset, and automatic Talent Trees after shopping before contract selection. [T9 implementation/evidence](archive/m7/P6M7_T9_User_Playtesting_And_Feedback.md#d049--implemented-flow-and-verification) records hidden entries with internals retained, Tavern-planning refunds, and an existing-tree pause before first/later offers (including the existing final-Tavern no-shop path). Intermediate Tavern shops retain normal progression. Close/Escape/outside continuation, both earned-secondary paths and resume are verified with isolated saves; active-contract/combat locks remain. Four final suites and 41-check supplement pass; parent inspected source and rendered samples. User review and broader T9 collection remain open; no milestone closeout or numerical tuning is implied.

### P6M7-D050 — User-accepted T9 closeout (2026-10-17)

User stated “Everything looks good for now” after D049 implementation and the remaining-playtest checklist. [T9 closeout](archive/m7/P6M7_T9_User_Playtesting_And_Feedback.md#d050--user-accepted-t9-closeout-2026-10-17) accepts/closes the four reported refinements and retains earlier accepted feedback. No unresolved reported finding remains; exact fresh-session context and complementary/all-mode human coverage are unspecified, not invented. T1–T9 Complete; T10–T11 Not started; T10 refinement/milestone acceptance next. M7 remains In progress. Documentation-only update; no runtime/save/balance changes or milestone-wide acceptance.

### P6M7-D051 — T10 reconciliation and concrete acceptance review (2026-10-17)

User requested executing T10. [Acceptance record](P6M7_T10_Feedback_Refinement_And_Acceptance.md) reconciles all twelve T2 gaps and four accepted T9 refinements, preserves later accepted minimal descriptions, and names T11/M8/M9/Legendary owners. Independent audit and parent hash checks find no new runtime fix: T8 manifest differs only in the six D049 runtime files and two affected tests; T9 runtime and selected current test hashes match passing evidence. Recorded limitations include diagnostic-only enlarged text, inspector/session reduced motion without no-buff/pre-combat discovery, unspecified human session coverage and inherited legacy/engine diagnostics. No new runtime/test/asset/save/balance changes or unnecessary repeated suite runs. T10 Pending input for milestone-wide presentation acceptance; T11 Not started and M7 In progress. D050 scoped T9 approval is not silently promoted to this decision.

### P6M7-D052 — Explicit final presentation acceptance and T10 closeout (2026-10-17)

User explicitly accepted the final M7 presentation with the recorded limits and requested T10 closeout. [Accepted package](P6M7_T10_Feedback_Refinement_And_Acceptance.md#d052--explicit-user-acceptance-and-t10-closeout-2026-10-17) retains G01–G12/F01–F04 reconciliation, current evidence and T11/M8/M9/Legendary owners. T1–T10 Complete; T11 Not started; M7 remains In progress pending final regression, closeout and M8 handoff. Documentation-only acceptance update; no new runtime/save/balance/test execution, commit or publication.

### P6M7-D053 — Final regression, M7 closeout and M8 handoff (2026-10-17)

User requested T11 execution after explicit D052 acceptance. [Final closeout](P6M7_T11_Closeout_And_M8_Handoff.md) records 27 passing current suites and three retained legacy failures (legacy autosave fixture plus two suites sharing six frozen signatures), with diagnosis/owners and no altered goldens/mechanics. Current real-Fight autosave passes ten checks. A one-line optional-footer metadata guard removes repeated shared-mode engine errors; affected reruns and final 900-check integrated/216-check footer/icon rendered batch pass, 222 final PNGs. One stale scalar persistence fixture repaired; approved art/data remain unchanged. Asset reconciliation covers 93 identities/84 paths, catalog freshness and seventeen model checks. Source, isolated userdata, dirty repository checkpoint and parent review recorded. M7 and T1–T11 Complete within accepted limits; M8 integrated playtest/refinement next, M8/M9 Not started. No real save writes, commit, publication or export.
