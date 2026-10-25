# P6 Project Onboarding Context

Last updated: 2026-10-24.

## Current Status and Next Work

**D084 — T9 presentation review pending:** All16 Legendary item panels, compact comparisons, live skill/buff descriptions and separate Exsanguinate health-removal feedback are implemented and verified using isolated saves. [T9 report, screenshots and limits](P6M8_T9_Presentation_And_Combat_Feedback_Verification.md) records698 counted T9 checks, actual-size1280×720 UI and preserved gameplay/loot/data/art/save implementations. T9 Pending input; T10–T12 Not started.

**M7 — Icons and Player Feedback Completion is Complete; T1–T11 Complete under D053.** M1–M7 are complete within their recorded scopes; Adventure is enabled. User explicitly accepted the final M7 presentation with limits under D052. [Final M7 closeout and M8 handoff](P6M7_T11_Closeout_And_M8_Handoff.md) records 27 passing current suites, three inherited legacy test exceptions, the optional-footer metadata guard, current Fight autosave proof and a source/repository checkpoint. **Next: M8 Legendary Item Revamp and Expansion — T1 planning and T2 audit Complete; T3 Complete under D008 with the approved gear pools, new stats, Practice/UI and save compatibility implemented; [closeout and verification](P6M8_T3_Closeout_And_Verification.md) records 33 passing suites and retained exceptions. T4 Complete under D010; T5 specification and technical defaults approved under D073. T6 findings approved and T6 Complete under D076; T7 implementation/findings approved and T7 Complete under D079; T8 implementation/findings approved and T8 Complete under D082; T9 presentation/feedback is Pending input for user review under D084.** The [M8 tracker](P6M8_Legendary_Item_Revamp_And_Expansion_Tracker.md) records the current twelve-task plan: D001 approved the initial plan; D002 inserts T3 Gear stat pool expansion before roster design and shifts former T3–T11 to T4–T12. [T2 source audit](P6M8_T2_Current_Legendary_And_System_Audit.md) records current pools, five fixed weapons, lifecycle/save constraints and downstream evidence needs. D006 records the replacement five-slot pools/base ranges, uncapped multiplicative CDR, retained All Stacks and additive timed-buff duration including Penetration/Potency. Near-zero cooldowns are explicitly accepted. D007 defines the implementation contract; D008 delivers it. T7 now implements all16 fixed Legendaries and the supplied new artwork; existing artwork remains unchanged. T10 owns the recorded inventory-discount resale risk; broader earned-run balance remains unaccepted. Former M8 integrated playtest/refinement is M9; former M9 regression/closeout is M10, both Not started. Historical IDs and evidence retain their original numbering; preserve accepted limits, values and intentional counters. See the [M7 tracker](P6M7_Icons_And_Player_Feedback_Completion_Tracker.md).

**D082 — T1–T8 Complete:** User approved T8 implementation and findings, resolving its review checkpoint. [T8 results](P6M8_T8_Acquisition_Progression_And_Persistence_Verification.md) record11 passing suites and3,852 counted checks, all16 acquisition transactions,384 save combinations and unchanged frozen loot/rarity outcomes. Eligibility/atomic claims/capacity and malformed canonical/save-reset paths are fixed. Practice now persists Missing attempts in version3, supports1/2 defaults, detaches mutable carried resources and synchronizes locked controls; Adventure remains4 with2/3 support. Policies were documented before edits; previous-reader rejection and actual transaction/save-resume/Practice isolation verified in copied projects. T8 Complete under D082. [T9 steps](P6M8_Legendary_Item_Revamp_And_Expansion_Tracker.md#t9-execution-steps) cover all16 item surfaces, descriptions/comparisons and live skill/buff/health-removal feedback, with isolated actual-size renders and user presentation review. T9 is Pending input under D084; T10–T12 Not started; loot redesign/new generated-enemy Legendary outcomes/global lives/account progression remain deferred. Accepted [T7 mechanics and limits](P6M8_T7_Implementation_And_Verification.md) under D079 remain; candidate overflow is invalid, inherited signature/playback exceptions and later balance/presentation owners are retained.

Current presentation decisions:

- **D025-D039 / T5 Complete:** Accepted minimal skill/talent hovers across all modes, shared current-only Active Talents, original icons/subclass backgrounds, gold scaling values and changed-only Next (no Next at max/no Requires). Canonical named Buff references use cyan; stats/statuses remain cream. See [accepted format](P6M7_T5_Closeout_And_Accepted_Conventions.md) and [keyword names/aliases reference](P6M7_T5_Presentation_Keyword_Reference.md). Deeper formulas/interactions stay in reference/Practice; a compendium UI has not been built.

- **D015 / T3:** [Accepted conventions](P6M7_T3_Closeout_And_Accepted_Conventions.md) include category feedback, tree skill-box treatments and per-tree counters in Adventure and Practice. The experimental combat log remains Test Mode only.
- **D018 / T4:** [Flat charcoal icons](P6M7_T4_Icon_Production_And_Integration.md) are installed for all 93 identities, including five refinements. T5 reviewed individual art; future concrete refinements require review under the remaining M7 tasks.
- **D019-D022 icon-bar styling:** User approved promoting the Available Skills and macro-bar treatment to Adventure and Practice. All modes use rounded charcoal frames and 6px category bars. Available Skills preserves original 32x32 artwork in compact buttons; the macro uses exact 2x enlargement to 64x64. Reserve the full macro grid while empty and use 4px slot gaps with tighter panel padding to prevent layout movement in every mode. Category comparison controls and the separate experimental combat log remain Test Mode only. Preserve source pixels when changing frames or spacing.

Adventure progression addition **D024**: the first completed contract earns a second subclass choice from two random remaining subclasses. The pair is saved with the run; finish normal terminal rewards/shop before selecting it and moving to the next contract. Existing runs keep second subclasses already chosen. Test Mode and Practice retain free role selection.

The [M7 tracker](P6M7_Icons_And_Player_Feedback_Completion_Tracker.md) holds task acceptance criteria, decisions and evidence; the [phase tracker](P6_Milestone_Tracker.md) is the roadmap. Use their latest entries rather than superseded proposals.

User playtesting accompanies M7 under M6 D015. Capture comprehension, confusing losses, preparation friction, optimized-play tension and informed counterplay. Broader integrated refinement belongs to M9, after the M8 Legendary revamp. The [earlier Legendary handoff](P6_Legendary_Remake_Next_Phase_Handoff.md) supplies evidence to M8; its next-phase deferral is superseded by D001. The T4 roster is approved under D010; T5 mechanics and technical defaults are approved under D073. No experimental Bandit curve is adopted.

D049 playtest refinements: main-menu Test Mode and the map Archetype guide entry are hidden. Tavern planning permits refunds/reset; before first/later contract offers, the existing Talent Trees opens automatically after reward/shop progression. See [T9 flow and verification](P6M7_T9_User_Playtesting_And_Feedback.md#d049--implemented-flow-and-verification). User accepted current results under D050; T9 is Complete.

## Read First

1. [M8 Legendary tracker](P6M8_Legendary_Item_Revamp_And_Expansion_Tracker.md) — approved scope, twelve tasks, dependencies and acceptance criteria.
2. [Final M7 closeout and M8 handoff](P6M7_T11_Closeout_And_M8_Handoff.md) — retained baseline, final evidence, exceptions and next work.
3. [Phase milestone tracker](P6_Milestone_Tracker.md) - current roadmap and scope.
4. [M7 task tracker](P6M7_Icons_And_Player_Feedback_Completion_Tracker.md) - active plan, dependencies, decisions and acceptance criteria.
5. [M6 closeout and M7 handoff](P6M6_T11_Closeout_And_M7_Handoff.md) - retained baseline, actual verification and downstream issues.

Before presentation implementation, consult the [accepted full-tree UI](P6M4_T10_Full_Tree_UI_UX_Plan.md), [approved icon mappings](P6M4_Icon_Assignment_Integration.md), [Icon Lab handoff](P6M4_T3_Icon_Lab_Implementation_And_Handoff.md) and [combat mechanics reference](Combat_Mechanics_Reference.md). The [earlier UI/feedback specification](P6M4_T2_UI_UX_And_Player_Feedback_Specification.md) supplies prior design rationale; its old content counts and access restrictions are historical.

Read additional task documents as needed for the specific work. Do not replay every historical milestone or follow superseded next-step instructions. Detailed history and evidence remain available through the phase tracker and its [history archive](P6_Milestone_Tracker_History_Through_M6.md).

## Retained Playable Baseline

| Area | Current state |
| --- | --- |
| Content | Assassin, Bladedancer, Shadow and Thief; all 44 talents / 140 ranks playable. Adventure uses `p6.adventure.1`; Practice/Test Mode use `p6.playable.shadow.1`. |
| Progression | Shared 45-point budget; one point per rank. Tavern rewards 1/0/2/3 give six points at exit; completed contracts give three, reaching the cap after C13. Previously earned points remain preserved. |
| Build rules | Primary plus a distinct secondary earned after the first Adventure contract from two fixed random choices (D024); existing chosen secondaries are retained. Test/Practice role selection remains unrestricted. Points in the same tree count toward gates; prerequisites require one rank. Both trees receive base intrinsics/unlocks; primary alone receives per-point scaling. |
| Respec and testing | Adventure refunds during Tavern planning and between contracts; active contracts retain refund locks. Test Mode planning resets between fights. Test Mode defaults to six points with 10/45 presets and selectable tree roles. Practice has an editable budget. |
| Persistence | Fresh Adventure slot `user://adventure_p6_m6.json`; legacy `user://save.json` preserved without migration. Practice remains isolated. Old full-reset policies describe earlier transitions. |
| M6 adopted tuning | Steal 1100 ms base / 650 ms minimum; Drunk Buddy armor 140. Other current values retained; rejected T6 enemy nerfs and experimental Bandit curves are not adopted. |
| Difficulty direction | Hard play where optimization, synergy, preparation and informed matchup avoidance matter. Weak choices may fail; severe counters can be intentional. Universal wins are not the target. |
| Prototype boundary | Finite 30-boss catalog and C30 scaling plateau retained. The Road and true endless progression remain future work. |

The [M6 closeout](P6M6_T11_Closeout_And_M7_Handoff.md) contains baseline verification and known exceptions. It does not establish final M7 presentation acceptance or future human playtesting. For coefficients and timing, use current resources, the combat reference and adopted decisions; historical JSON drafts are not runtime authority.

## Model Routing and Delegation

The user authorized delegation to different models for FacelessVoid on **2026-10-13**. Use `$facelessvoid-model-routing`, installed at `%USERPROFILE%/.codex/skills/facelessvoid-model-routing/SKILL.md`. It is available through automatic skill discovery or explicit invocation. If unavailable on another machine, follow the guidance below and report the missing skill when routing is needed.

**Default: GPT-6.1 Sol / Medium** (`gpt-6.1-sol`, `medium`), saved in the project's `.codex/config.toml`. The model selector controls the active chat separately; this skill routes delegated work and cannot switch the parent chat's model. Explicit user model choices take precedence.

| Task | Starting model / effort |
| --- | --- |
| Bounded approved edits, inventories, text corrections and summaries | Luna / Low |
| Normal implementation, tooltip audits and coordinated UI changes | Sol / Medium |
| Unclear regressions and interacting state or overlay bugs | Sol / High |
| Ambiguous design, difficult balance tradeoffs, save/combat correctness reviews | Astra / High |

Handle tiny changes directly. Delegate substantial bounded work to subagents with explicit model/effort and a compact handoff; prefer one worker and avoid duplicating its investigation. Escalate when evidence warrants it, including two unsuccessful fixes to the same reproduced defect. Higher effort is not a substitute for verification: inspect actual UI renders and run checks appropriate to the changed behavior using isolated saves. The coordinating agent reviews results before accepting them.

This authorization applies to work within the user's requested project task. It does not authorize unrelated work, external messages, publishing or separate user-owned chats. The installed skill holds the detailed routing and escalation policy; revise it when preferences change.

## Scope and Working Rules

- Phase 6 covers Rogue tree redesign and its build, combat, UI, progression, Practice, Balance Lab and persistence support, plus the approved M8 Legendary revamp, expansion and scoped gear stat pool additions. M7 is complete; preserve its accepted presentation conventions.
- Preserve the Phase 5 gear/generated-contract foundation, stable identities and separate Tree Lab. New classes, broad gear/economy/route redesign, crafting, consumables, The Road and wholesale combat resolver replacement remain outside scope unless explicitly promoted.
- Distinguish presentation defects, mechanics bugs and intentional counters before proposing balance changes. Do not reopen settled mechanics simply because an older document lists them as unresolved.
- Keep changes scoped; use focused checks for affected behavior and appropriate regression at closeout. Use isolated saves for validation and protect the sibling Enigma checkout and real player saves.
- Record decisions and task evidence in the active tracker or linked task documents. Keep this onboarding guide short and update status in place instead of appending a milestone diary.
- M10 owns certificate/shader/export and general engine-teardown qualification. M7 owns applicable player-facing audio lifecycle feedback. Ordinary save/load tests do not establish power-loss durability.

## Project Identity and Useful Locations

The Godot project is `project/project.godot`, named **FacelessVoid**. Windows user data is `%APPDATA%/FacelessVoid/`, separate from Enigma; no Enigma saves are copied. Export presets and the Windows executable use FacelessVoid; the web package is `facelessvoid-phase6-itch.zip`. This is identity context, not an instruction to publish.

| Work | Starting locations |
| --- | --- |
| Icon assignments | `tools/icon-lab/index.html` and the linked Icon Lab/mapping documents. |
| Tree and skill UI | `project/scenes/combat/talent_panel.gd`, `talent_overlay.gd`, `available_skills_panel.gd`, `skill_build_panel.gd`; `project/scripts/ui/skill_tooltip_formatter.gd`. |
| Combat feedback | `project/scripts/ui/combat_playback.gd`, `combat_playback_presenter.gd`, `combat_status_icons.gd`, `combat_popup_layer.gd`. |
| State and mechanics | `project/scripts/systems/build_resolver.gd`, `combat_resolver.gd`; `project/scripts/resources/`; `project/data/subclass_trees/`. |
| Practice and audio | `project/scenes/training_room/`; `project/scripts/autoload/audio_manager.gd`. |
| Validation | `project/tests/`, `tools/p6/`, `project/reports/`; follow the affected task's reproduction instructions. |

Historical baseline references: [redesign brief](P6_Skill_Tree_Redesign_Brief.md), [build-system map](P6_Current_Player_Build_System_Map.md), [content audit](P6_Skill_Tree_Content_Audit.md), [implementation handoff](P6_Implementation_And_Test_Handoff.md) and [audited baseline integration](P6_Audited_Baseline_Integration.md). Sibling Project-Enigma documents are optional Phase 5 history.

## Prompt for a New Conversation

```text
Read docs/P6_Project_Onboarding_Context.md and the current trackers linked under
Read First. Use $facelessvoid-model-routing when available: Sol / Medium is the
default, and task-based subagent delegation is authorized. Follow the latest
adopted decisions and preserve mode scope, original artwork and isolated saves.
Read additional task documents as needed, then continue the requested work.
```
