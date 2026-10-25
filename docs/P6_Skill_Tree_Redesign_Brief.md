# P6 Skill Tree Redesign Brief

Date: 2026-09-16
Source baseline: Project Enigma audited Phase 5, commit `d0e025ae9ff6b86aa389582443be6382547cb4cc` on `main` (integrated 2026-09-21; original closeout `91c1f2fdfaae7b48aa1e193adfb910956b1d6574`). See `docs/P6_Audited_Baseline_Integration.md`.

> Scope update (2026-10-17): the user promoted Legendary item revamp and expansion into Phase 6 M8, with scoped gear stat pool additions under P6M8-D002. See the [M8 tracker](P6M8_Legendary_Item_Revamp_And_Expansion_Tracker.md) and [current ten-milestone roadmap](P6_Milestone_Tracker.md). Broad gear/economy redesign and procedural Legendary generation remain outside the approved scope. The original brief below is historical design context.

## Purpose

Phase 6 redesigns the Rogue skill trees so player build choices become as clear, expressive, and matchup-relevant as the Phase 5 gear system. The phase should treat Phase 5 as a stable gameplay baseline, not as an invitation to reopen gear, route generation, shop economy, or broad combat architecture.

The design target is meaningful buildcraft under pressure: the player should understand what each tree is asking them to do, what enemy defenses it answers, what gear stats improve it, and what tradeoffs come with committing to it.

## Current Starting Point

Project Enigma currently has a playable generated-contract Adventure loop with Rogue subclass selection, talent selection, active skills, deterministic generated contracts, five-slot gear, gear rewards, between-contract shops, Practice Room validation, Balance Lab validation, and an itch.io-ready web package.

Phase 5 closed the gear redesign. Gear now provides readable five-slot build pressure through Weapon, Helm, Armor, Trinket, and Charm, with Rogue-facing Dagger, Hood, Doublet, Ring, and Necklace identities. Combat and UI now understand poison, shred, decay, crit, retrigger, economy stats, Legendary daggers, item tooltips, comparison surfaces, Practice Room gear editing, and balance simulations.

Skill trees are functional but not final. Assassin, Bladedancer, Shadow, and Thief have targeted playtest tuning, but their identities, progression arcs, choice structure, and long-term synergy language still need a deliberate redesign.

## Phase Goal

Create a redesigned Rogue skill-tree model that gives each tree a distinct mechanical fantasy, clean progression, readable choices, and stable implementation hooks.

The phase should answer these questions:

- What is each Rogue tree for?
- What combat problems does each tree solve?
- Which gear stats naturally support each tree?
- Which enemies or route pressures punish or reward each tree?
- What does a mixed-tree build gain and lose?
- How should active skills, passives, triggers, and Specials remain readable to players?

## In Scope

- Redesigning Rogue tree identities for Assassin, Bladedancer, Shadow, and Thief.
- Auditing and revising existing Rogue talents, talent costs, prerequisites, and unlocked skills.
- Revising active skill unlocks and skill augments where they are part of tree identity.
- Updating tooltip and talent panel wording needed to explain redesigned choices.
- Updating Practice Room support so redesigned trees can be tested quickly.
- Updating Balance Lab scenarios and focused tests that cover tree identities and known watch items.
- Preserving deterministic build resolution, save/load compatibility, and existing generated-contract flow.
- Creating a milestone sequence that separates design, data model, UI, combat hooks, balance, and closeout.

## Out Of Scope Unless Explicitly Promoted

- New playable classes.
- A fresh gear-system redesign.
- Procedural Legendary generation or a full Legendary item system rewrite.
- New route-node systems, route-local resources, scouting, crafting, consumables, transmutation, or hidden events.
- Broad generated-monster architecture changes.
- Replacing the combat resolver from scratch.
- Storefront/page publishing beyond using the existing Phase 5 itch.io package path as needed.
- Full final balance. Phase 6 should produce a coherent tree baseline ready for playtest, not claim final commercial tuning.

## Design Pillars

1. Clear Tree Fantasy

Each tree should have a short design sentence that remains true in UI, data, and tests. Example directions already implied by the current game are poison execution for Assassin, speed/shred/retrigger for Bladedancer, decay/poison hybrid pressure for Shadow, and gold/crit/economy combat conversion for Thief.

2. Readable Build Choices

A player should understand why they would choose one talent over another, what stat lines improve it, and which combat logs prove it worked. Avoid hidden multipliers that only become visible in tests.

3. Matchup Relevance

Trees should answer different generated enemy defenses. Shred should matter into armor, decay into resistance, crit tools into crit-negation pressure, poison into longer fights, speed/retrigger into proc plans, and economy tools into reward momentum.

4. Controlled Complexity

Phase 6 can introduce new hooks when needed, but it should prefer existing concepts: `StatModifier`, `SkillAugment`, `TriggeredSkillEffect`, `BuildResolver`, `PlayerStats`, `CombatResolver`, Practice Room, and Balance Lab.

5. Deterministic Validation

Every redesigned tree needs stable tests and repeatable scenarios. The project already uses deterministic route, reward, gear, combat, and save/load checks; Phase 6 should extend that pattern rather than rely on manual feel alone.

## Success Criteria

Phase 6 is ready to close when:

- Each Rogue tree has a documented identity, progression path, and intended gear synergies.
- Existing tree resources are updated or replaced without breaking Adventure setup, Practice Room, save/load, or combat playback.
- Talent selection remains understandable in both Adventure and Practice Room.
- Active skill tooltips describe current damage, stack, proc, and economy behavior accurately.
- Balance Lab includes representative scenarios for each redesigned tree and mixed-tree builds.
- The accepted Phase 5 watch item, `bladedancer_contract_watchmen`, has been reviewed under the new tree model.
- Regression covers build resolution, unlocked skills, tree UI, save/load, combat effects, Practice Room, and representative Adventure flows.
- Phase 6 docs clearly separate completed work from deferred balance or future class design.

## Suggested Milestones

**Superseded on 2026-09-21:** Use the current ten-milestone roadmap in the
[Phase 6 milestone tracker](P6_Milestone_Tracker.md). P6M1 closed as roadmap and
planning setup on 2026-09-21; M2 starts with the carried-forward draft audit and
foundational design. Enemy/progression rebalance required by the new trees, temporary-effect
UI, and icon production are explicitly included. The original outline below is
retained as historical planning context, not the current milestone numbering.

P6M1: Design Charter And Tree Identity

Define tree fantasy, player-facing promises, non-goals, vocabulary, and first-pass talent layouts before changing data.

P6M2: Data Model And Resource Migration

Confirm whether `Talent`, `SubclassTree`, `SkillAugment`, and `TriggeredSkillEffect` are enough. Add only the smallest new data shape needed for redesigned trees.

P6M3: Talent And Skill Implementation

Update `.tres` resources, build resolution, combat hooks, and tooltip summaries for the new baseline.

P6M4: UI And Practice Room Readability

Make redesigned trees easy to inspect, select, and test. Keep the build panels stable and scroll-safe.

P6M5: Balance Lab And Scenario Pass

Add tree-specific scenarios, mixed-tree scenarios, and focused regression for the known watch areas.

P6M6: Regression, Smoke, And Closeout

Run the full Phase 6 regression bundle, update onboarding docs, and prepare the next stable handoff.

## First Conversation Prompt For Phase 6

Start by reading:

1. `docs/P6_Skill_Tree_Redesign_Brief.md`
2. `docs/P6_Current_Player_Build_System_Map.md`
3. `docs/P6_Skill_Tree_Content_Audit.md`
4. `docs/P6_Implementation_And_Test_Handoff.md`
5. `../Project-Enigma/docs/Project_Overview.md` (optional historical context)
6. `../Project-Enigma/docs/P5_Phase_5_Closeout_Handoff.md` (optional historical context)
7. `../Project-Enigma/docs/New_Gear_Overview.md` (optional historical context)

Then work from the closed Phase 5 baseline and keep Phase 6 scoped to Rogue skill-tree redesign unless a new task explicitly expands the phase.
