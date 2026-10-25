# P6 Implementation And Test Handoff

**2026-10-17 — M7 Complete; T1–T11 Complete under D053, final presentation accepted D052.** [Final M7 closeout and M8 handoff](P6M7_T11_Closeout_And_M8_Handoff.md) records 27 passing current suites, three inherited legacy test exceptions, final integrated/footer/icon renders, current real-Fight autosave proof, one optional-footer guard and the source/repository checkpoint. M8 integrated playtest/refinement is next; M8/M9 Not started. Accepted capability/human-coverage limits, intentional counters and separate Legendary-remake ownership remain. Current navigation: [onboarding](P6_Project_Onboarding_Context.md), [M7 tracker](P6M7_Icons_And_Player_Feedback_Completion_Tracker.md). Earlier dated handoffs below remain historical.

**2026-10-08 — M6 Complete (T1–T11).** Final retained-baseline verification passes 95 distinct suites, four rendered executions and ten current static checks. Gameplay code, scenes and data are unchanged. T10 acceptance remains D015: hands-on balance review accompanies M7 icon/UI feedback; Legendary refinement belongs to the separate next-phase remake. No experimental Bandit curve or rejected T6 nerf is adopted. See [T11 closeout and M7 handoff](P6M6_T11_Closeout_And_M7_Handoff.md). Earlier dated entries describe historical states.

Current release: Adventure `p6.adventure.1`; Practice/Test Mode `p6.playable.shadow.1`. Use the T11 handoff for reproduction commands and accepted values. The M2–M5 status sections below are historical.

Current combat rules: [Combat Mechanics Reference](Combat_Mechanics_Reference.md). This living reference consolidates accepted rules and interaction exceptions; task handoffs retain historical decisions and validation evidence. Update the reference alongside every accepted mechanics change.

M3 closeout: [M3 closeout and M4 handoff](P6M3_T11_Closeout_And_M4_Handoff.md). All 66 regression scripts pass; protected files unchanged. M4 playable integration and UI validation is next.
Date: 2026-09-16
Source baseline: Project Enigma audited Phase 5, commit `d0e025ae9ff6b86aa389582443be6382547cb4cc` on `main` (integrated 2026-09-21; original closeout `91c1f2fdfaae7b48aa1e193adfb910956b1d6574`). See `docs/P6_Audited_Baseline_Integration.md`.

## Historical status addendum (2026-09-24)

M2 T1–T9 are Complete for foundation scope. Start with the
[T9 closeout and M3 handoff](P6M2_T9_Closeout_And_M3_Handoff.md) and its repository checkpoint for current
APIs and foundation validation. For subsequent progress, use the
[M3 tracker](P6M3_Shared_Combat_Mechanics_Tracker.md): T1–T11 are Complete for shared-mechanics scope. T4 closed under D023
with 26 passing regression scripts and final boundary coverage. T8 core Bladedancer
validation and M4 handoff is complete, with 35 passing regression scripts and
final gear coverage. T9 Poison timing and consumption, T10 gold/mixed validation and T11 closeout are Complete. M4 is next.
The sections below describe the inherited
Phase 5 baseline, not the current completion status.

Version-2 persistence and full incompatible-save resets supersede earlier migration
assumptions. The ranked model and Balance Lab adapter are implemented; the playable
registry remains p6.compat.1. Full redesigned p6.1 content is gated on M3/M5
mechanics and M4 playable validation. Use the isolated foundation runner documented
in T8/T9 for current checks; preserve Enigma and its saves.

## Purpose

This is the engineering handoff for the Phase 6 Rogue skill-tree redesign. It lists the likely files, validation commands, regression surfaces, migration risks, and closeout expectations for the next phase.

Use this as the practical companion to:

- `P6_Skill_Tree_Redesign_Brief.md`
- `P6_Current_Player_Build_System_Map.md`
- `P6_Skill_Tree_Content_Audit.md`

## Baseline To Preserve

Start from the closed Phase 5 baseline. Do not reopen Phase 5 unless a Phase 6 task explicitly requires it.

Preserve:

- Generated-contract Adventure loop.
- Five-slot gear model and item presentation.
- Deterministic reward and shop generation.
- Practice Room as the build sandbox.
- Balance Lab as deterministic build validation.
- Save/load compatibility and materialized build state.
- Itch.io-ready export path and P5M12 closeout scripts.

Accepted Phase 5 warnings remain non-blockers unless Phase 6 directly touches them:

- Godot headless ObjectDB/RID/resource cleanup warnings at process exit.
- Intentional corrupt-save parse output in `save_load_test.gd`.
- One Balance Lab watch item for `bladedancer_contract_watchmen`.

## Likely Implementation Files

Core build data:

- `project/data/subclass_trees/assassin.tres`
- `project/data/subclass_trees/bladedancer.tres`
- `project/data/subclass_trees/shadow.tres`
- `project/data/subclass_trees/thief.tres`
- `project/data/talents/assassin/*.tres`
- `project/data/talents/bladedancer/*.tres`
- `project/data/talents/shadow/*.tres`
- `project/data/talents/thief/*.tres`
- `project/data/skills/*.tres`

Core resource scripts:

- `project/scripts/resources/subclass_tree.gd`
- `project/scripts/resources/talent.gd`
- `project/scripts/resources/skill.gd`
- `project/scripts/resources/skill_effect.gd`
- `project/scripts/resources/skill_augment.gd`
- `project/scripts/resources/triggered_skill_effect.gd`
- `project/scripts/resources/player_stats.gd`
- `project/scripts/resources/stat_modifier.gd`

Core systems:

- `project/scripts/systems/build_resolver.gd`
- `project/scripts/systems/combat_resolver.gd`
- `project/scripts/systems/damage_calculator.gd`
- `project/scripts/systems/combat_timing.gd`
- `project/scripts/systems/combat_recap.gd`
- `project/scripts/systems/combat_result_formatter.gd`
- `project/scripts/systems/stat_catalog.gd`
- `project/scripts/systems/save_system.gd`
- `project/scripts/systems/training_room_state.gd`

UI and player-facing explanation:

- `project/scenes/subclass_select/subclass_select.gd`
- `project/scenes/combat/talent_panel.gd`
- `project/scenes/combat/talent_overlay.gd`
- `project/scenes/combat/active_talents_panel.gd`
- `project/scenes/combat/available_skills_panel.gd`
- `project/scenes/combat/skill_build_panel.gd`
- `project/scripts/ui/skill_tooltip_formatter.gd`
- `project/scenes/training_room/training_room.gd`
- `project/scenes/training_room/training_room_combat_view.gd`

Tools and reports:

- `project/scripts/tools/balance_lab.gd`
- `project/scripts/tools/run_balance_suite.gd`
- `project/reports/balance/latest/`
- `tools/p5m12/run_regression.ps1`

## Recommended Work Order

Use the [Phase 6 milestone tracker](P6_Milestone_Tracker.md) for the current
nine-milestone sequence, status, and decision log. The guidance below supports
that roadmap; it does not replace its milestone boundaries. Required enemy
rebalance and expanded UI/icon work are part of the agreed Phase 6 scope.

1. Design first.

Create the Phase 6 talent/tree design table before editing resources. Include tree identity, talent list, costs, prerequisites, active skills, intended gear synergies, expected weaknesses, and required tests.

2. Decide migration strategy.

Before renaming or deleting IDs, decide how old save/load data should behave. Prefer preserving stable IDs when the concept remains recognizable.

3. Update data resources.

Change `.tres` resources in small groups. Keep each tree independently testable.

4. Update resolver hooks.

Only add new resolver fields or combat hooks when existing `StatModifier`, `SkillAugment`, and `TriggeredSkillEffect` shapes are insufficient.

5. Update tooltips and UI.

Make sure talent summaries, active talent cards, skill tooltips, and Practice Room panels explain what the player can actually observe.

6. Add tests with each mechanic.

Do not wait for the full redesign to write tests. Each new tree mechanic should get a focused test when it lands.

7. Run Balance Lab after the mechanics are stable.

Balance Lab should compare whole builds and representative enemies after implementation correctness is covered.

## Test Surfaces To Preserve Or Extend

Existing tests likely to matter:

- `project/tests/thief_subclass_test.gd`
- `project/tests/build_panels_test.gd`
- `project/tests/training_room_build_test.gd`
- `project/tests/training_room_fight_test.gd`
- `project/tests/training_room_fight_setup_test.gd`
- `project/tests/training_room_combat_view_test.gd`
- `project/tests/skill_tooltip_formatter_test.gd`
- `project/tests/skill_build_geometry_test.gd`
- `project/tests/hold_skill_test.gd`
- `project/tests/opportunity_strikes_test.gd`
- `project/tests/engine_mechanics_test.gd`
- `project/tests/legendary_mechanics_test.gd`
- `project/tests/p5m4_weapon_scaling_percentages_test.gd`
- `project/tests/p5m7_gold_gain_economy_test.gd`
- `project/tests/p5m11_economy_stats_test.gd`
- `project/tests/p5m11_overkill_gold_test.gd`
- `project/tests/save_load_test.gd`
- `project/tests/combat_hud_test.gd`
- `project/tests/combat_screen_test.gd`

New Phase 6 tests should cover:

- Each tree resource loads and exposes the expected talent IDs.
- Talent prerequisites and costs produce the intended progression.
- Tree intrinsics resolve into stats, skills, augments, or triggers correctly.
- Active skill unlocks appear in Adventure and Practice Room.
- Rotation filtering still removes unavailable skills and keeps the 10-slot cap.
- Skill tooltip text matches resolved mechanics after tree changes.
- Save/load handles existing and redesigned talent selections safely.
- Practice Room can select every tree and run representative builds.
- Balance Lab includes one baseline and one pushed build per tree.
- Mixed-tree builds do not accidentally bypass intended gates.

## Regression Commands

Use the existing P5M12 script as the broad closeout smoke while Phase 6 is still in progress:

```powershell
powershell -ExecutionPolicy Bypass -File tools\p5m12\run_regression.ps1
```

For Balance Lab:

```powershell
F:\Applications\Godot\Godot_v4.7-stable_win64_console.exe --headless --path project -s res://scripts/tools/run_balance_suite.gd
```

For Shop Lab, only needed if Phase 6 touches gear reward/shop economy or Thief economy behavior broadly:

```powershell
node tools\shop-lab\run_checks.js
```

For itch/web closeout if Phase 6 produces a new hosted build:

```powershell
powershell -ExecutionPolicy Bypass -File tools\p5m12\export_itchio.ps1
```

## Suggested P6 Test Bundle

Create a Phase 6 script once enough tests exist, likely `tools/p6/run_skill_tree_regression.ps1`, with this shape:

1. Focused tree resource and BuildResolver tests.
2. Focused combat mechanic tests for new tree effects.
3. Skill tooltip formatter checks.
4. Talent panel and Practice Room build checks.
5. Save/load compatibility checks.
6. Balance Lab scenario run.
7. Optional broad P5M12 regression at closeout.

## Migration Rules

Default safe rules:

- Keep resource IDs stable if the player-facing concept survives.
- Add aliases or explicit save migration before deleting an old ID.
- Treat file names as less important than `id` fields.
- Keep old tests until equivalent Phase 6 coverage exists.
- Record intentional behavior changes in the Phase 6 tracker rather than silently updating assertions.

High-risk changes:

- Renaming `skill.killers_mark` or `skill.toxic_flurry` without migration.
- Removing Thief or Steal paths without updating `thief_subclass_test.gd` and save/load assumptions.
- Moving poison/shred/decay behavior without updating tooltip and combat recap text.
- Changing gold scaling without checking reward gold, stolen gold, current gold, Overkill Gold, and Increased Gold together.
- Adding retrigger or triggered-skill interactions without proving chain caps and source filters still work.

## Balance Lab Handoff

Current Balance Lab closeout ended with 69 pass, 1 accepted warning, and 0 fail. The accepted warning is the Bladedancer Cloaked Watchmen matchup.

Phase 6 should add scenarios that answer:

- Can Assassin beat long fights through poison without erasing all resistance pressure?
- Can Bladedancer answer armor without becoming the best generic damage tree?
- Can Shadow exploit resistance and debuff setup without duplicating Assassin and Bladedancer too much?
- Can Thief convert gold into combat without making shopping feel wrong?
- Do mixed-tree builds have clear opportunity cost?

Do not tune from a single scenario. Use representative normal, captain, elite, boss, armor-heavy, resistance-heavy, cleanse/suppress, dodge/block, and crit-negation enemies.

## Documentation To Update During Phase 6

Create or update:

- `docs/P6_Skill_Tree_Redesign_Overview.md`
- `docs/P6M1_..._Tracker.md` through closeout trackers as milestones are defined.
- `docs/P6_Project_Onboarding_Context.md`
- `README.md`
- Record current Rogue talent and gear synergy changes in Phase 6 docs; keep historical Enigma documents outside this docs folder.
- `docs/P6_Phase_6_Closeout_Handoff.md` at phase close.

Keep Phase 6 docs separate from Phase 5 closeout docs. Reference Phase 5 as baseline evidence; do not rewrite Phase 5 history unless correcting an error.

## Closeout Expectations

Phase 6 closeout should include:

- Updated Rogue tree resources.
- Updated active skill and tooltip behavior.
- Practice Room support for redesigned builds.
- Balance Lab scenarios and current results.
- Focused tests for every new tree mechanic.
- Save/load compatibility notes.
- Known tuning caveats and accepted warnings.
- Updated onboarding and project overview docs.
- A clean Git commit and push.
- Optional itch.io-ready export if the phase produces a new external playtest build.

## Stop Conditions

Pause and re-scope before continuing if:

- The redesign requires new classes.
- The redesign requires a gear-system rewrite.
- The redesign requires replacing the combat resolver wholesale.
- The UI needs a full layout paradigm change beyond making talent trees readable.
- Balance changes become broad economy or generated-route redesign work.

Those may be good ideas later, but they are not automatically Phase 6.
