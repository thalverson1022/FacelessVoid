# P6 Current Player Build System Map

Date: 2026-09-16
Source baseline: Project Enigma Phase 5 closeout, commit `91c1f2fdfaae7b48aa1e193adfb910956b1d6574`

## Purpose

This document maps the current player build system before the Phase 6 skill-tree redesign begins. Use it to understand where Rogue class, subclass, talent, skill, gear, stat, UI, save/load, Practice Room, and combat behavior currently meet.

The key rule: Phase 6 should change the skill-tree system deliberately, while preserving the Phase 5 gear baseline and deterministic generated-contract loop.

## High-Level Build Flow

A playable Rogue build is assembled from these layers:

1. Class base stats and base skills.
2. Selected subclass trees.
3. Tree innate modifiers and tree-granted skills.
4. Selected talents.
5. Talent stat modifiers, unlocked skills, skill augments, and triggered skill effects.
6. Equipped gear and gear stat sheet aggregation.
7. Resolved skill rotation, capped at 10 macro slots.
8. Combat resolution using `PlayerStats`, unlocked skills, rotation, gear, and generated enemy data.

The central resolver is `project/scripts/systems/build_resolver.gd`. It is the first file to read before changing how tree choices become combat stats or active skills.

## Core Resource Shapes

`project/scripts/resources/subclass_tree.gd`

A `SubclassTree` currently contains:

- `id`
- `display_name`
- `icon`
- `intrinsic_text`
- `talents`
- `innate_modifiers`
- `unlocked_skills`
- `skill_augments`

Tree-level effects are already data-driven enough for innate stat modifiers, intrinsic unlocked skills, and simple skill augments.

`project/scripts/resources/talent.gd`

A `Talent` currently contains:

- `id`
- `display_name`
- `cost`
- `prerequisites`
- `stat_modifiers`
- `unlocked_skills`
- `triggered_skill_effects`

This supports flat or multiplicative stat changes, skill unlocks, prerequisite gates, and triggered skill procs.

`project/scripts/resources/skill.gd`

A `Skill` currently contains:

- `id`
- `display_name`
- `icon`
- `icon_letter`
- `base_execution_ms`
- `min_execution_ms`
- `poison_stacks_applied`
- `effects`

Skill effects live in concrete `SkillEffect` subclasses. Phase 6 should avoid stuffing complex behavior into display-only fields.

`project/scripts/resources/skill_augment.gd`

A `SkillAugment` targets skill IDs and adds extra effects or poison stacks. Shadow currently uses this for its innate Stab and Heavy Slash poison behavior.

`project/scripts/resources/triggered_skill_effect.gd`

A `TriggeredSkillEffect` contains a skill, chance, and source skill IDs. Bladedancer currently uses this for Opportunity Strikes: Quick Cut can trigger Rending Slash.

## Current Rogue Tree Resources

Tree resources live in `project/data/subclass_trees/`:

- `assassin.tres`
- `bladedancer.tres`
- `shadow.tres`
- `thief.tres`

Talent resources live in `project/data/talents/<tree>/`.

Active skill resources live in `project/data/skills/`.

Current Rogue skills include:

- `stab.tres`
- `heavy_slash.tres`
- `quick_cut.tres`
- `venom_jab.tres`
- `poison_strike.tres`
- `rending_slash.tres`
- `beguiling_strike.tres`
- `death_strike.tres`
- `steal.tres`
- `hold.tres`

Note: Some resource IDs preserve older internal names. For example, `death_strike.tres` currently has `id = "skill.killers_mark"`, and `beguiling_strike.tres` has `id = "skill.toxic_flurry"`. Do not assume file name and resource ID always match.

## BuildResolver Responsibilities

`BuildResolver.resolve_stats()` builds `PlayerStats` in this order:

1. Class base stats.
2. Tree innate modifiers.
3. Selected talent modifiers.
4. Gear stat sheet aggregation.
5. Weapon damage range.
6. Triggered effects from talents and gear.
7. Gold/current-gold-dependent effects.

Important current behavior:

- Talent physical and elemental percent bonuses are separate from gear percent buckets.
- Gear stat aggregation is delegated to `StatSheet`.
- Increased Gold talent modifiers are handled as reward multipliers and then combined with gear reward modifiers.
- Weapon damage comes from equipped gear through `WeaponDamageCatalog`.
- Triggered effects are appended to `stats.triggered_skill_effects`.

`BuildResolver.resolve_unlocked_skills()` starts with class base skills, adds tree skills, adds talent skills, adds gear skills, then applies tree skill augments.

`BuildResolver.resolve_rotation()` filters the selected rotation to currently unlocked skills and caps it at `MAX_ROTATION_SIZE = 10`.

## Stat And Gear Boundary

Phase 5 created a strong gear stat foundation. Phase 6 should use it rather than bypass it.

Important files:

- `project/scripts/resources/stat_modifier.gd`
- `project/scripts/systems/stat_catalog.gd`
- `project/scripts/resources/stat_sheet.gd`
- `project/scripts/resources/player_stats.gd`
- `project/scripts/resources/gear_item.gd`
- `project/scripts/systems/weapon_damage_catalog.gd`
- `project/scripts/systems/gear_generator.gd`

Current tree/talent stats can still use legacy `StatModifier.StatType` values or canonical `stat_id` values. Phase 6 should prefer canonical `stat_id` values for new work where possible, because that keeps tooltips, stat sheet display, gear interaction, and tests aligned.

Current combat-relevant stat concepts include:

- Attack Speed
- Crit Chance
- Crit Damage
- Base Damage
- Percent Physical Damage
- Base Elemental Damage
- Percent Elemental Damage
- Bonus Stacks
- Shred Value
- Bonus Shred Stacks
- Decay Value
- Increased Gold
- Shop Discount
- Magic Find
- Chance for Retrigger
- Chance to Shred
- Chance to Decay
- Chance for Crits to Apply Poison
- Special effects such as `decay_applies_shred` and `poison_stack_cap_40`

## Combat Boundary

The main combat touch points are:

- `project/scripts/systems/combat_resolver.gd`
- `project/scripts/systems/damage_calculator.gd`
- `project/scripts/systems/combat_timing.gd`
- `project/scripts/systems/combat_recap.gd`
- `project/scripts/systems/combat_result_formatter.gd`
- `project/scripts/resources/player_stats.gd`

Current Phase 5 combat rules to preserve unless Phase 6 explicitly changes them:

- Physical Rogue skills roll weapon damage once per cast.
- Retriggers are separate casts with fresh rolls and a chain cap.
- Death Strike adds damage based on active poison stacks before weapon scaling.
- Poison ticks on a shared timer and uses current poison stack behavior.
- Shred reduces armor by the player's shred value per stack.
- Decay reduces resistance multiplicatively per stack.
- Bonus Stacks increases poison, shred, and decay applications.
- Hold is not an attack for proc purposes.
- Crit-applies-poison only rolls on crits.
- Overkill Gold is awarded after combat wins and then modified by Increased Gold.

## UI Surfaces

Talent and skill UI touch points:

- `project/scenes/combat/talent_panel.gd`
- `project/scenes/combat/talent_overlay.gd`
- `project/scenes/combat/active_talents_panel.gd`
- `project/scenes/combat/available_skills_panel.gd`
- `project/scenes/combat/skill_build_panel.gd`
- `project/scenes/combat/secondary_subclass_overlay.gd`
- `project/scripts/ui/skill_tooltip_formatter.gd`
- `project/scenes/subclass_select/subclass_select.gd`

Practice Room touch points:

- `project/scenes/training_room/training_room.gd`
- `project/scenes/training_room/training_room_combat_view.gd`
- `project/scenes/training_room/training_target_panel.gd`
- `project/scripts/systems/training_room_state.gd`

Phase 5 improved scroll-safe talent windows, active talent summaries, skill tooltips, and a 10-slot skill build panel. Phase 6 should preserve these usability gains while updating text and controls for redesigned trees.

## Save And Adventure State Boundary

Important files:

- `project/scripts/autoload/build_state.gd`
- `project/scripts/systems/save_system.gd`
- `project/scenes/game_root.gd`
- `project/scenes/combat/combat_screen.gd`

Risks for Phase 6:

- Existing saves may reference old talent IDs or old skill IDs.
- Renaming IDs without migration can break selected talents, unlocked skills, rotations, Practice Room setups, and deterministic tests.
- Changing resource IDs can affect UI lookup, save/load, and BuildResolver filtering.

Default recommendation: keep existing stable IDs when a talent or skill is still conceptually the same. Add migration handling before deleting or renaming IDs.

## Validation Tools

Practice Room is the hands-on build sandbox. It should remain the fastest way to test tree combinations, gear interactions, generated targets, and combat playback.

Balance Lab is the deterministic scenario surface. It should gain Phase 6 scenarios for tree identities and mixed-tree builds.

Shop Lab is primarily for gear generation and item economy. Phase 6 should not treat Shop Lab as the main skill-tree validation surface unless tree changes intentionally affect shop/reward economy.

## Known Watch Areas For Phase 6

- `bladedancer_contract_watchmen` ended Phase 5 with a 100% win rate against Cloaked Watchmen and was accepted as a future talent-tree balance watch.
- Chance for Retrigger should stay below 100% in normal legal builds.
- Triggered skill effects can recursively interact with retriggers; keep source filtering and chain caps visible in tests.
- Poison, shred, and decay share Bonus Stacks; tree changes can accidentally over-buff all three at once.
- Economy talents and gear Increased Gold multiply together; Thief changes should be tested against Overkill Gold and normal reward gold.
- Skill tooltip text must match actual resolved stats, not authored base values.

## Read First When Implementing

Recommended first files for a Phase 6 implementer:

1. `project/scripts/systems/build_resolver.gd`
2. `project/scripts/resources/subclass_tree.gd`
3. `project/scripts/resources/talent.gd`
4. `project/scripts/resources/skill.gd`
5. `project/scripts/resources/player_stats.gd`
6. `project/scripts/systems/combat_resolver.gd`
7. `project/scripts/ui/skill_tooltip_formatter.gd`
8. `project/scenes/combat/talent_panel.gd`
9. `project/scenes/training_room/training_room.gd`
10. `project/tests/thief_subclass_test.gd`
11. `project/tests/training_room_build_test.gd`
12. `project/tests/skill_tooltip_formatter_test.gd`
