# Documentation Guide

Last assessed: 2026-10-25. Start with the current plan; consult history only for a specific question.

## Current navigation

| Need | Authority |
| --- | --- |
| Project context and working boundaries | [Onboarding](P6_Project_Onboarding_Context.md) |
| Phase status and milestone ownership | [Phase roadmap](P6_Milestone_Tracker.md) |
| Closed M11 regression and Phase 6 acceptance | [M11 tracker — T1–T6 and Phase 6 Complete / D012](P6M11_Regression_And_Closeout_Tracker.md) |
| Closed M10 tasks, accepted deferrals and bounded M11 handoff | [M10 tracker — T1–T4 Complete under D006](P6M10_Integrated_Playtest_And_Refinement_Tracker.md) |
| Closed M9 tasks and confirmed Pants/Gloves pools | [M9 tracker](P6M9_Gear_Slot_Expansion_And_Progression_Pacing_Tracker.md) |
| M9 final regression, accepted baseline and candidate M10 checklist — T12 Complete | [T12 closeout/M10 handoff](P6M9_T12_Regression_And_M10_Handoff.md) |
| M9 accepted user playtesting and refinements — T11 Complete | [T11 playtest refinements](P6M9_T11_Playtest_Refinement.md) |
| M9 focused progression evidence and tuning recommendations — T10 Complete | [T10 review](P6M9_T10_Focused_Progression_Review.md) |
| M9 combined mechanics, ownership and reset verification — T9 Complete | [T9 evidence and retained risks](P6M9_T9_Mechanics_And_Reset_Verification.md) |
| Processed Self Buff/Debuff cues, category routing and audio previews | [Audio processing and verification](P6M9_Buff_And_Debuff_Audio_Verification.md) |
| M9 approved new-slot stat specification, weights and category pool order | [T3 specification](P6M9_T3_Stat_Pool_Specification.md) |
| M9 approved four-item Legendary roster, technical defaults and Arctic countdown presentation | [T4 specification](P6M9_T4_Legendary_Mechanics_Specification.md) |
| M9 accepted artwork and four new Legendary signatures — T8 Complete | [T8 verification and review pack](P6M9_T8_Artwork_And_Legendary_Integration_Verification.md) |
| M9 accepted seven-slot UI, three-mode renders and verification | [T7 verification and screenshots](P6M9_T7_Equipment_UI_And_Practice_Verification.md) |
| M9 implemented stat pools, equal slot selection and acquisition verification | [T6 verification](P6M9_T6_Stat_Pools_And_Acquisition_Verification.md) |
| M9 implemented foundation, reset policy and isolated verification | [T5 verification](P6M9_T5_Foundation_And_Save_Reset_Verification.md) |
| M9 dependencies, current mechanics/pacing and save-reset inventory | [T2 source audit](P6M9_T2_Gear_System_And_Pacing_Audit.md) |
| Closed M8 tasks | [M8 tracker](P6M8_Legendary_Item_Revamp_And_Expansion_Tracker.md): all T1–T12 Complete |
| M8 accepted baseline, evidence and deferred risks | [Final M8 handoff](P6M8_T12_Closeout_And_M9_Handoff.md) |

## Retained references

- [Combat mechanics](Combat_Mechanics_Reference.md): shared rules; M8 Legendary-specific contracts are in the dedicated specification below.
- [Existing five-slot stat specification](P6M8_T3_Gear_Stat_Implementation_Specification.md) and [Legendary specification](P6M8_T5_Legendary_Mechanics_Specification.md): accepted mechanics, not new task queues. M9 extends the slot pools; it does not silently replace these rules.
- [Accepted tooltip conventions](P6M7_T5_Closeout_And_Accepted_Conventions.md), [keyword reference](P6M7_T5_Presentation_Keyword_Reference.md), [full-tree UI](P6M4_T10_Full_Tree_UI_UX_Plan.md) and [icon mappings](P6M4_Icon_Assignment_Integration.md): consult when editing presentation.
- `talent_tree_drafts/`, JSON fixtures/manifests and tool-consumed design reviews remain at stable paths. Historical documents retained at the root are labelled where safe. The 18 Markdown sources hashed by `project/data/p6/` release manifests retain their exact pre-cleanup bytes: the M5 tree design reviews/Shadow implementation and dated balance implementation/update records are historical evidence even where their original text has no banner. The current tracker, dedicated specifications and adopted decisions determine present scope.

## Historical material

`archive/` holds completed-milestone evidence, superseded proposals, experiments and execution logs. Its [guide](archive/README.md) identifies their role. Archived status labels, test plans, save policies and milestone numbering describe their original checkpoint. They do not create work or override current decisions. Raw reports, fixtures and player data were not removed.

## Assessment and cleanup

The full assessment covered **158 Markdown and 14 JSON files** in `docs/`, plus repository entry points and tool/manifest dependencies. No byte-identical Markdown duplicates were found. The problem was repeated status/prose and obsolete work instructions presented beside current guidance.

The cleanup replaces repeated onboarding/roadmap history with short current guides, separates the M8 decision/execution log from its final task table, consolidates the redundant T9 and T10 handoffs into the final M8 closeout and historical record, and archives unpinned historical documents. Unique evidence and machine-consumed paths are preserved. A machine-readable disposition/link audit is saved under `work/docs_cleanup/`; it is maintenance evidence, not an additional project plan.

Result: **54 historical documents archived; two redundant handoffs merged and removed; root Markdown files reduced from 153 to 98.** Current document file/section links pass validation, and game-file hashes are unchanged. Eight inherited broken links remain only inside preserved `project/reports/` before-snapshots; they are not current navigation. No gameplay or balance tests were run.

## Maintenance rules

1. M9/M10 are closed. The M10 tracker owns integrated acceptance, explicit deferrals and the bounded M11 handoff; the [M11 tracker](P6M11_Regression_And_Closeout_Tracker.md) owns current planning/status. T1–T6, M11 and Phase 6 are Complete under D012 following explicit user acceptance of the scoped outcome and documented limitations. Credit existing evidence with its limits. Keep the next-phase economic audit and deferred trigger investigation separate from automatic M11 work. Update the relevant tracker in place rather than adding status banners to every document.
2. Add a new document only for a substantial specification or verification record. Put small clarifications and decisions in the existing owner document.
3. Once superseded, merge redundant guidance or archive unique history and repair links. Keep tooling/fixture dependencies intact.
4. Deferred risks do not automatically become mandatory tasks or authorize simulations. New scope/tuning needs a recorded decision. M9 retains its approved twelve tasks.
5. Historical test counts are evidence for the recorded revision, not fresh certification. Document-only maintenance does not require gameplay or balance runs.
