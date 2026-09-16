# P6 Project Onboarding Context

Date: 2026-09-16
Source baseline: Project Enigma Phase 5 closeout, commit `91c1f2fdfaae7b48aa1e193adfb910956b1d6574` on `phase-5-gear-redesign`

## Purpose

Use this document as the first prompt/context handoff for the next phase of the project. Phase 6 is the Rogue skill-tree redesign. The goal is to keep the phase scoped, readable, and separate from the completed Phase 5 gear redesign.

Phase 6 should start from the closed Phase 5 baseline. Do not reopen gear, generated routes, shop economy, publishing, or broad combat architecture unless a Phase 6 task explicitly promotes that work into scope.

## Read These Documents First

Read these Phase 6 handoff documents in order:

1. `docs/P6_Skill_Tree_Redesign_Brief.md`
2. `docs/P6_Current_Player_Build_System_Map.md`
3. `docs/P6_Skill_Tree_Content_Audit.md`
4. `docs/P6_Implementation_And_Test_Handoff.md`

Then read these Phase 5/current-baseline documents as supporting context:

5. `docs/Project_Overview.md`
6. `docs/Project_Onboarding_Context.md`
7. `docs/P5_Phase_5_Closeout_Handoff.md`
8. `docs/P5M12_Phase_5_Regression_Smoke_And_Closeout_Tracker.md`
9. `docs/New_Gear_Overview.md`
10. `docs/P5_Gear_Redesign_Overview.md`

Use the Phase 6 docs as the current scope boundary. Use the Phase 5 docs as baseline evidence for what already exists.

## Current Phase 6 Goal

Redesign the Rogue skill trees so Assassin, Bladedancer, Shadow, and Thief each have clear mechanical identity, readable progression, meaningful gear synergies, useful matchup roles, and deterministic validation through Practice Room and Balance Lab.

The current tree system is functional but not final. It already supports subclass trees, talents, prerequisites, stat modifiers, unlocked skills, skill augments, triggered skill effects, skill tooltips, Practice Room build testing, and Balance Lab simulation. Phase 6 should improve the design using those foundations where possible.

## Initial Prompt To Paste Into A New Conversation

```text
Please read `F:\Data\Claude Projects\Project-FacelessVoid\docs\P6_Project_Onboarding_Context.md` to get the starting context for this conversation.

Then read these docs, in order:

1. `F:\Data\Claude Projects\Project-FacelessVoid\docs\P6_Skill_Tree_Redesign_Brief.md`
2. `F:\Data\Claude Projects\Project-FacelessVoid\docs\P6_Current_Player_Build_System_Map.md`
3. `F:\Data\Claude Projects\Project-FacelessVoid\docs\P6_Skill_Tree_Content_Audit.md`
4. `F:\Data\Claude Projects\Project-FacelessVoid\docs\P6_Implementation_And_Test_Handoff.md`
5. `F:\Data\Claude Projects\Project-Enigma\docs\Project_Overview.md`
6. `F:\Data\Claude Projects\Project-Enigma\docs\Project_Onboarding_Context.md`
7. `F:\Data\Claude Projects\Project-Enigma\docs\P5_Phase_5_Closeout_Handoff.md`
8. `F:\Data\Claude Projects\Project-Enigma\docs\P5M12_Phase_5_Regression_Smoke_And_Closeout_Tracker.md`
9. `F:\Data\Claude Projects\Project-Enigma\docs\New_Gear_Overview.md`
10. `F:\Data\Claude Projects\Project-Enigma\docs\P5_Gear_Redesign_Overview.md`

After reading, treat Phase 6 as the Rogue skill-tree redesign phase. Keep the scope separate from the completed Phase 5 gear redesign. Start by summarizing the Phase 6 goal, current baseline, key systems, and recommended first milestone before suggesting or making changes.
```

## Scope Guardrails

In scope for Phase 6:

- Rogue skill-tree redesign.
- Assassin, Bladedancer, Shadow, and Thief identity cleanup.
- Talent costs, prerequisites, and progression structure.
- Active skill unlocks and tree-specific skill behavior.
- Skill/talent tooltip readability.
- Practice Room support for redesigned builds.
- Balance Lab scenarios for tree identities and mixed-tree builds.
- Save/load compatibility for changed talent and skill IDs.
- Focused regression and closeout docs.

Out of scope unless explicitly promoted:

- New playable classes.
- A new gear-system redesign.
- New generated route-node systems.
- Crafting, consumables, transmutation, scouting, boss bargains, or hidden events.
- Broad generated-monster architecture changes.
- Replacing the combat resolver wholesale.
- Full final balance or commercial polish.
- Publishing work beyond a scoped new playtest package if Phase 6 needs one.

## Most Important Current Files

Start implementation research with:

- `project/scripts/systems/build_resolver.gd`
- `project/scripts/resources/subclass_tree.gd`
- `project/scripts/resources/talent.gd`
- `project/scripts/resources/skill.gd`
- `project/scripts/resources/player_stats.gd`
- `project/scripts/systems/combat_resolver.gd`
- `project/scripts/ui/skill_tooltip_formatter.gd`
- `project/scenes/combat/talent_panel.gd`
- `project/scenes/training_room/training_room.gd`
- `project/data/subclass_trees/assassin.tres`
- `project/data/subclass_trees/bladedancer.tres`
- `project/data/subclass_trees/shadow.tres`
- `project/data/subclass_trees/thief.tres`

## Current Watch Items

- `bladedancer_contract_watchmen` ended Phase 5 above the old win-rate watch threshold and should be reviewed during Phase 6.
- Chance for Retrigger should stay below 100% in normal legal builds.
- Poison, shred, and decay all interact with Bonus Stacks, so new tree effects can accidentally over-scale multiple mechanics.
- Thief economy-combat scaling must be tested against reward gold, stolen gold, current gold, Increased Gold, Overkill Gold, and shop spending pressure.
- Save/load and Practice Room can break if talent or skill IDs are renamed without migration.

## Working Rule For New Conversations

Use this onboarding document as the first file. Then read the four Phase 6 handoff docs before proposing a milestone plan. If implementation begins, keep changes small, update a Phase 6 tracker as work completes, and verify with focused tests before broad balance work.
