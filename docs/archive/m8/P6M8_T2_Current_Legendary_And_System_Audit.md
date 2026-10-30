# P6M8-T2 — Current Legendary and system audit

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. [Current context](../../P6_Project_Onboarding_Context.md).

2026-10-17. **Source audit complete.** This document supplies the current-state evidence for [M8 T3–T5](../../P6M8_Legendary_Item_Revamp_And_Expansion_Tracker.md). It adopts no new stat, item, value, slot, acquisition rule or compatibility policy. Current project source/data is authority; older reports and experimental copies are evidence only. M7's accepted presentation, hard difficulty, intentional counters and real-save isolation remain the baseline.

## Evidence and limits

Read the [onboarding context](../../P6_Project_Onboarding_Context.md), [M8 plan](../../P6M8_Legendary_Item_Revamp_And_Expansion_Tracker.md), [Legendary handoff](../../P6_Legendary_Remake_Next_Phase_Handoff.md) and [M7 closeout](../../P6M7_T11_Closeout_And_M8_Handoff.md), then traced current resources and callers. Paths below link to the current repository; `L` references are one-based source locations at audit time, not immutable commit permalinks. Named functions are additional search anchors.

Fresh verification consists of read-only source searches, complete catalog/pool/range extraction and documentation target checks. **No Godot suite, gameplay run, save/load experiment, human UI inspection or balance test was executed for T2.** Existing tests are described separately below; their presence is not a fresh pass. Source-derived concerns are not claimed as reproduced runtime defects. No runtime, resource, test or save edits are part of this audit. No real userdata or sibling Enigma checkout was needed.

## Current system in one view

| Area | Verified current behavior | Consequence for subsequent work |
| --- | --- | --- |
| Gear | Five slots; six generated rarities; fixed Crude starter and five authored Legendary daggers. | A new canonical stat must cross generation, aggregation, combat, presentation, Practice and save boundaries. |
| Normal stat pool | Slot/category tables in `StatCatalog` govern actual generation. Thirteen Basic-listed IDs include two not enabled in any current slot pool; seven Rare-listed IDs include three economy overlaps; sixteen Specials include two not enabled in any current slot pool. | Catalog membership, eligible pool membership and active combat support must be distinguished. |
| Legendaries | All five compete for one Weapon slot, each with fixed affixes and one signature effect. None has a level/rank/upgrade track. | Existing five-way exclusion limits combinations; non-Weapon items would change assumptions beyond catalog content. |
| Item behavior | Affixes aggregate through `StatSheet`; triggers, unlocks, stash damage and minimum-cast chance use separate fields. | A single generic stat pipeline does not represent every item effect. |
| Acquisition | Normal Adventure uses low-weight contract shop rolls; authored reward-choice APIs remain supported; Practice equips directly. Generated reward upgrades never create Legendary gear. | Acquisition timing and duplicate rules differ by path. |
| Persistence | Authored items rehydrate current resource data; generated items serialize inline affixes and metadata. | Stable IDs/paths and policy for changed definitions matter before implementation. |

Sources: [GearItem](../../../project/scripts/resources/gear_item.gd) L4–56; [StatCatalog](../../../project/scripts/systems/stat_catalog.gd) `BASIC_STAT_IDS`, `RARE_STAT_IDS`, `SPECIAL_STAT_IDS`, `SLOT_CATEGORY_POOLS`; [LegendaryCatalog](../../../project/scripts/systems/legendary_catalog.gd) L11–40; [BuildResolver](../../../project/scripts/systems/build_resolver.gd) L126–157.

## Gear identities, units and aggregation

[GearItem](../../../project/scripts/resources/gear_item.gd) preserves serialized enum order: slots Weapon=0, Trinket=1, Charm=2, Helm=3, Armor=4; displayed order is Weapon, Helm, Armor, Trinket, Charm. Rogue families are Dagger, Hood, Doublet, Ring, Necklace respectively. Rarity enum order is Basic=0, Master=1, Cursed=2, Legendary=3, Crude=4, Epic=5, Chaos=6, Unique=7; UI rarity order differs. Source kinds are Unknown=0, Generated=1, Fixed=2, Legendary=3, Compatibility=4. Do not reorder persisted enums to match presentation.

[StatModifier](../../../project/scripts/resources/stat_modifier.gd) stores canonical `stat_id` plus inherited enum `stat`, operation ADD=0/MULTIPLY=1, category Basic=0/Rare=1/Special=2/Drawback=3/Compatibility=4, numeric value, drawback flag and label. The inherited stat enum is Attack Speed=0, Crit Chance=1, Crit Multiplier=2, Poison Damage=3, Physical Damage=4, Poison Stacks Applied=5, Armor Reduction=6, Gold Rewards=7, Poison Tick Interval=8, Crit Chance per Stolen Gold=9, Crit Multiplier per Current Gold=10. Canonical string IDs are the extensible contract; several new IDs map to the same inherited enum for compatibility and generated naming.

Generated canonical numeric affixes use ADD; a decimal `0.10` means ten percentage points/increased-percent units, not literal 10. `StatSheet` sums canonical numeric contributions across equipped items, converts a MULTIPLY contribution to `value - 1`, floors specified aggregates, applies the All Stats 1.2 multiplier only to eligible numeric gear aggregates, then caps chance stats. Binary Specials deduplicate by ID; duplicate All Stats does not compound. `base_damage`, `shred_value`, `decay_value`, compatibility fields and binary effects do not receive All Stats scaling. Negative damage/speed/crit-damage affixes can survive aggregation; combat/build floors still apply. Positive and negative copies on Chaos can cancel before flooring. See [StatSheet](../../../project/scripts/resources/stat_sheet.gd) `add_modifier`, `finalize`, `apply_to_player_stats` (L27, L55, L289) and [StatCatalog definitions](../../../project/scripts/systems/stat_catalog.gd) `DEFINITIONS`.

| Canonical numeric ID | Unit and consumer | Catalog floor / cap; All Stats scaling | Normal pool status |
| --- | --- | --- | --- |
| `base_damage` | Flat bonus physical base before skill scaling/damage buckets | None / none; no | Basic; Weapon, Trinket |
| `percent_physical_damage` | Decimal increase added to gear physical multiplier bucket | None / none; yes | Basic; all slots |
| `increased_attack_speed` | Decimal IAS added to player speed; cast timing/cadence derivatives | None / none; yes | Basic; Helm, Trinket, Charm |
| `crit_chance` | Probability added to player chance | 0 / 1; yes | Basic; Helm, Armor, Trinket, Charm |
| `crit_damage` | Additive critical multiplier increment (`1.0` = +100%) | None / none; yes; final player multiplier at least 1 | Basic; Weapon, Charm |
| `base_elemental_damage` | Flat elemental base, feeds Poison damage and supported derived stats | None / none; yes | Basic; Weapon, Helm, Trinket, Charm |
| `percent_elemental_damage` | Decimal increase in separate gear elemental bucket | None / none; yes | Basic; all slots |
| `increased_all_stacks` | Integer-rounded bonus to Footwork, Bypass, Poison, legacy armor-reduction, Shred, Decay, Penetration and Potency grants | 0 / none; yes | Basic; Helm, Armor, Charm |
| `shred_value` | Flat armor reduction per Shred stack, integer-rounded | 0 / none; no | Defined and Basic-listed; no enabled normal pool/range |
| `bonus_shred_stacks` | Additional integer Shred grants | 0 / none; yes | Defined and Basic-listed; no enabled normal pool/range |
| `decay_value` | Decimal bonus resistance-reduction potency | 0 / none; no | Defined; not in category lists or enabled normal pools/ranges |
| `increased_gold` | Decimal increase feeding common gold-reward multiplier | 0 / none; yes | Basic and Rare; all slots |
| `shop_discount` | Decimal reduction of purchase price only | 0 / none; yes; minimum paid price 1 | Basic and Rare; all slots |
| `increased_magic_find` | Decimal increase to rarity-upgrade chances | 0 / none; yes | Basic and Rare; all slots |
| `chance_for_retrigger` | Chance for direct-attack self-repeat candidate | 0 / 1; yes | Rare; Weapon, Trinket |
| `chance_to_shred` | Direct-attack Shred proc chance | 0 / 1; yes | Rare; all slots |
| `chance_to_decay` | Direct-attack Decay proc chance | 0 / 1; yes | Rare; all slots |
| `crit_applies_element` | Chance that a critical direct attack grants Poison | 0 / 1; yes | Rare; Helm, Armor, Trinket, Charm |

All current Basic numerical definitions allow drawbacks; slot drawbacks are filtered from that slot's Basic pool with the same weights. Rare chances do not allow drawbacks. Economy IDs have Basic metadata but are deliberately also Rare pool entries, using category-specific Rare ranges. IDs declared as `increased_shred_stacks`, `increased_decay_stacks`, `increased_elemental_stacks` are compatibility aliases that canonicalize to `increased_all_stacks`; they are not independent current gear stats. Other aliases include `attack_speed`, `crit_multiplier`, `poison_damage`, `physical_damage`, `poison_stacks_applied`, `armor_reduction`, `gold_rewards`, `purchase_discount`, `magic_find`, `shred` and `bonus_resist_decay`. See [StatCatalog](../../../project/scripts/systems/stat_catalog.gd) `LEGACY_STAT_ID_BY_TYPE`, `STAT_ID_ALIASES`, `canonical_id_for_modifier`.

Compatibility-only IDs are `legacy_poison_tick_interval` (multiplier-kind metadata, floor .05), `legacy_crit_chance_per_stolen_gold` (chance, 0–1), and `legacy_crit_damage_per_current_gold` (decimal crit increment, floor 0). They do not roll normally and do not scale with All Stats. The blank-ID legacy Poison interval MULTIPLY form is handled separately as an actual product; assigning it an explicit canonical ID changes which aggregation path runs. Wyvern retains the blank-ID form. A definition/label alone does not establish an active caller.

## Binary Special inventory

Every Special has binary value `1`, no numeric roll scaling, no drawback, set-style aggregation and no All Stats scaling. These are existing Unique gear features that can overlap future Legendary design space; they are not new proposals. Slot abbreviations: W Weapon, H Helm, A Armor, T Trinket, C Charm. Numbers in parentheses are selection weights within Special pools.

| ID | Current behavior / fixed contract | Enabled normal slots |
| --- | --- | --- |
| `disable_enemy_dodge` | Effective enemy dodge becomes zero | A/T/C (10 each) |
| `disable_enemy_block` | Effective enemy block becomes zero | A/T/C (10 each) |
| `disable_enemy_absorb` | Effective enemy absorb becomes zero | A/T/C (10 each) |
| `disable_enemy_suppress` | Effective enemy suppress becomes zero | A/T/C (10 each) |
| `disable_enemy_cleanse` | Enemy cleanse disabled | A/T/C (10 each) |
| `ignore_armor_no_shred` | Ignore armor and cannot apply Shred | H/C (5 each) |
| `ignore_resistance_physical_penalty` | Ignore resistance; physical damage penalty .5 | H/C (5 each) |
| `double_applied_stacks` | Doubles supported applied stack quantities, subject to status caps/application rules | H/T/C (5 each) |
| `convert_damage_to_physical` | Converts damage channel to physical; original proc/source identity remains relevant | W/T (5 each) |
| `convert_damage_to_magical` | Converts damage channel to magical; original proc/source identity remains relevant | W/T (5 each) |
| `all_stats_increased` | One 1.2 multiplier on eligible gear aggregates | W/A (5 each) |
| `immune_to_stun` | Effective enemy stun duration zero | A (5) |
| `immune_to_slow` | Effective enemy slow zero | A (5) |
| `immune_to_interrupt` | Effective enemy interrupt skips zero | A (5) |
| `decay_applies_shred` | Decay application can mirror/apply Shred; current independent-Decay/Shred talent rules matter | Defined/supported; not in normal slot pools |
| `poison_stack_cap_40` | Raises Poison cap to at least 40; does not itself supply stacks | Defined/supported; not in normal slot pools |

Sources: [StatCatalog](../../../project/scripts/systems/stat_catalog.gd) `SPECIAL_STAT_IDS`, `DEFINITIONS`, `SLOT_CATEGORY_POOLS`; [StatSheet](../../../project/scripts/resources/stat_sheet.gd) `special_effect_summary`; [combat resolver](../../../project/scripts/systems/combat_resolver.gd) `_effective_enemy_*`, `_applied_*_stacks`, `_apply_skill_effects`, `_decay_applies_shred`. Preserve the existing combined-conversion behavior and test it deliberately; two independently equipped conversion Specials are possible today. [Mixed gear tests](../../../project/tests/p6_mixed_gear_integration_test.gd) already include `both_conversions` fixtures.

## Generation, rarity and deterministic roll contract

[GearGenerator](../../../project/scripts/systems/gear_generator.gd) `generate_from_request` normalizes tier/rarity, RNG/seed, source/context, stable ID/deterministic key, `value_scale` (default 1) and contract depth (default 0). It rejects missing/invalid slots/rarities, non-generated source kind, invalid RNG, nonpositive value scale, procedural Crude and procedural Legendary. Current source metadata includes seed, context, deterministic key, scale, depth and reward-upgrade story. An explicit RNG's state and draw order matter: a stable ID is metadata, not an independent per-affix RNG seed.

| Rarity | Affix shape | Numeric multiplier | Base purchase price | Dagger damage |
| --- | --- | --- | --- | --- |
| Crude | Authored starter only, not generated | — | 0 (starter sale special case 5) | 16–20 |
| Basic | 1 Basic | 1 | 18 | 17–19 |
| Master | 2 Basic | 1.75 | 32 | 17–21 |
| Epic | 2 Basic + 1 Rare | 2 | 46 | 18–20 |
| Cursed | 2 Basic + 1 Rare + 1 Basic drawback | +2.5 / −2.5 | 40 | 17–23 |
| Chaos | 4 independent weighted outcomes: Basic positive 5, Rare positive 4, Basic drawback 5 | +3 / −3 | 55 | 16–25 |
| Unique | 3 Basic + 1 Rare + 1 Special | 2; Special stays 1 | 70 | 19–25 |
| Legendary | Fixed catalog only | Authored values | 80 | 21–27 |

For non-Chaos gear, canonical IDs cannot repeat across any affix categories or drawback/positive positions on one item, including economy IDs shared by Basic/Rare. Chaos explicitly allows repeats, including positive and drawback copies. Weighted stat picking removes used/zero-weight IDs; probabilities renormalize across the remaining eligible pool. Insufficient pools return errors rather than silently substituting another category. The historical `AFFIX_POOL`, `BASIC_VALUE`, `MASTER_VALUE`, `CURSED_*` constants and legacy `_make_modifier` helper near the top of GearGenerator are **not** current procedural value/pool authority; active rolling routes through StatCatalog.

Numeric value = uniform float within the slot/category range × rarity multiplier × request `value_scale` × depth scale. Depth is clamped to 1–12 and interpolates linearly from 1 to 1.35. Percent/chance values round to .01; flat/stack values round to whole units; positive stacks floor at 1. Binary values skip numeric scaling. This means source range decimals are not necessarily reachable output values after rounding. New stats can alter deterministic draw selection and old seeded outputs even if existing ranges stay unchanged; preserve persisted inline results and document generator compatibility expectations rather than assuming identical seeds imply unchanged items across content revisions.

Sources: [GearGenerator](../../../project/scripts/systems/gear_generator.gd) `rarity_roll_plan`, `chaos_roll_plan`, `_affixes_for_rolls`, `_pick_stat_id_from_pool`, `_roll_value_for_stat_id`, `_rarity_value_multiplier`, `_contract_depth_value_scale`; [weapon ranges](../../../project/scripts/systems/weapon_damage_catalog.gd) L10–19. No-weapon/invalid-weapon fallback is 1–1, distinct from a Crude dagger.

## Complete current Legendary inventory and timing

Each listed resource is fixed `gear.legendary.*`, tier Legendary, slot Weapon, Rogue family Dagger, source kind Legendary and base damage range 21–27. Icons are individually mapped in [GearIcons](../../../project/scripts/ui/gear_icons.gd). Affixes below are stored ADD values unless stated otherwise. No item has an individual tier progression curve; fixed affixes do not gain generated depth scaling.

| Item / stable ID | Fixed affixes | Signature data and actual runtime path |
| --- | --- | --- |
| [Wyvern Kriss](../../../project/data/gear/wyvern_kriss.tres), `gear.legendary.wyvern_kriss` | +8 base elemental, +.40 elemental%, +.12 Decay chance; legacy Poison interval MULTIPLY .5 | StatSheet multiplies interval by .5 (floor .05); `PoisonCadence.interval` applies live IAS talents, suppress and Echoing scaling. Not a Poison source by itself. Forced ticks do not reset the natural clock. Faster cadence can also consume Poison fuel sooner under current Poison contracts. |
| [Mithril Karambit](../../../project/data/gear/mithril_karambit.tres), `gear.legendary.mithril_karambit` | +.15 IAS, +.15 crit chance, +.20 Shred chance | Two `TriggeredSkillEffect`s: 50% Stab triggered by `skill.stab`; 50% Heavy Slash triggered by `skill.heavy_slash`. Source-filtered immediate proc children can chain. This is distinct from numeric `chance_for_retrigger`; it does not add .5 to that stat or automatically feed derivations that read numeric retrigger. |
| [Bandit Blade](../../../project/data/gear/bandit_blade.tres), `gear.legendary.bandit_blade` | +.20 physical%, +.12 crit chance, +.30 increased gold | `physical_damage_per_gold=.1`: BuildResolver adds .1 × current stash to flat bonus physical damage when resolving the build. Unbounded and fractional (text says +1 per 10 gold; no integer ten-gold step). Spending/rebuilding changes the next resolved value. In-fight theft changes simulated stash/crit handling, but no Bandit coefficient is carried into the combat gold helper to recompute this flat bonus live. |
| [Umbral Stiletto](../../../project/data/gear/umbral_stiletto.tres), `gear.legendary.umbral_stiletto` | +.10 crit chance, +1.0 crit damage, +1.0 crit-applies-Poison chance | Adds [Death Strike](../../../project/data/skills/death_strike.tres) to unlocked skills (`skill.killers_mark`, historical stable ID). BuildResolver clones/deduplicates unlocks by ID, class → trees → talents → gear, then tree augments apply. Removing the item prunes unavailable macro entries unless another source still unlocks the same ID. |
| [Bejeweled Push Dagger](../../../project/data/gear/bejeweled_push_dagger.tres), `gear.legendary.bejeweled_push_dagger` | +8 base physical, +.20 physical%, +.10 crit chance | `min_cast_time_proc_chance=.2`: root macro cast draws chance only when cooldown-ready, then scheduler uses skill minimum execution time. No cooldown bypass, no extra child cast and no new minimum-time draw for instant retrigger children. Enemy interruption/dodge and other failure conditions still apply after scheduling. |

Runtime evidence: [BuildResolver](../../../project/scripts/systems/build_resolver.gd) L126–143, `resolve_unlocked_skills`, `_append_skill_clone`; [StatSheet](../../../project/scripts/resources/stat_sheet.gd) `apply_to_player_stats`; [PoisonCadence](../../../project/scripts/systems/poison_cadence.gd) L17–21; [combat gold](../../../project/scripts/systems/combat_gold.gd); [resolver](../../../project/scripts/systems/combat_resolver.gd) L19–31, L238–316, `_triggers_for_source`, `_resolve_retrigger_chain`; [scheduler](../../../project/scripts/systems/combat_macro_scheduler.gd) `plan`.

Death Strike source-resource fields are historical generic effects (flat 20 and stack scalar 1); runtime special-cases `skill.killers_mark`. It rolls weapon damage, adds 2 × current Poison stacks plus flat bonus physical/negative-block bonus, floors the base, applies 1.11 skill scaling and standard damage buckets/crit/defenses once; it skips the second generic physical/stack effect packet. Base execution is 1500 ms, minimum 650 ms. Specifications must use the resolver path rather than infer a formula from the two resource effects. See [resolver](../../../project/scripts/systems/combat_resolver.gd) L1018–1044, `_skill_is_death_strike` and [Death Strike resource](../../../project/data/skills/death_strike.tres).

Root casts resolve windup/cooldown/resource/interruption, effects and finalization before the permitted retrigger chain. Dodged direct attacks do not start a chain. Trigger candidates preserve origin/source, source-skill filters and optional origin filters. Children occur at their parent's timestamp, use their authored target skill resource and can retrigger other allowed effects; they do not advance the macro scheduler or start root cooldowns. A Mithril child therefore does not automatically inherit every cloned/augmented root skill detail. This needs explicit review whenever future effects depend on augmented skill identity, proc origin, resources, temporary buffs, chance-one effects or cooldowns.

Combat has a depth limit of **16** and a shared per-root **1024 candidate** budget. Depth-limit decisions terminate further recursion; exhausted candidate budget invalidates the simulation via the budget failure path. These are not balance guarantees or permission for exponential chains. The separate M7 [playback](../../../project/scripts/ui/combat_playback.gd) `MAX_VISIBLE_STRIKES=16` limits visible contacts including opener; it does not cap resolver damage/events. Large valid proc trees can be visually compressed. Current event/trace fields include cast ID, parent/origin, retrigger depth/decision, trigger labels, minimum-cast flag, stat snapshots and status transactions. They are useful reuse points for T6/T9 verification.

## Acquisition, equip, economy and progression

The authored [Gilded Serpent knives reward](../../../project/data/contract_routes/gilded_serpent/knives.tres) has all five catalog resources and samples two distinct Legendary choices. [ContractOfferSource](../../../project/scripts/systems/contract_offer_source.gd) `contract_offers` can include authored or generated contracts according to caller context. **Normal Adventure continuation uses generated-only offers:** [BuildState](../../../project/scripts/autoload/build_state.gd) `continue_after_win` (L912) and `_complete_contract_and_offer_next` (L942) call `start_generated_contract_loop_offer` (L367), which passes `include_authored=false`, `include_generated=true`. Generated route reward materialization in [ContractRouteGenerator](../../../project/scripts/systems/contract_route_generator/contract_route_generator.gd) populates generated gear choices, not a Legendary pool. Therefore contract shops are the normal current Adventure Legendary acquisition path; the authored knives reward is retained API/test/compatibility content, not the ordinary generated-run reward schedule. Internal [Test Mode entry](../../../project/scenes/game_root.gd) L133–138 directly grants a duplicated Bandit Blade before starting generated offers; that debug loadout is not earned acquisition.

[BuildState](../../../project/scripts/autoload/build_state.gd) `_gear_choices_for_reward` still combines explicit fixed choices, seeded Legendary sampling and generated choices when supplied such a reward; Legendary reward sampling is distinct within that sample but does not filter already owned IDs.

Contract shops generate six offers. Tavern/no active contract returns Basic; contract base rarity weights interpolate with integer rounding between these depth anchors (relative weights, not percentages):

| Depth | Basic | Master | Epic | Cursed | Chaos | Unique | Legendary |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 65 | 23 | 6 | 2 | 3 | 1 | 1 |
| 6 | 54 | 26 | 10 | 4 | 4 | 2 | 2 |
| 12 | 41 | 29 | 15 | 7 | 5 | 3 | 3 |

Depth clamps through the current reward-depth helper. Upgrade rolls can advance Basic→Master→Epic→Cursed/Chaos/Unique; Magic Find scales upgrade chances, not a new procedural Legendary pool. A base Legendary shop roll selects uniformly among currently unowned catalog IDs (equipped plus inventory), ignores the sampled regular slot because every catalog item is Weapon, and falls back to generated Cursed in that slot when all are owned. Offer property/signature duplicate avoidance and retry attempts are separate from owned-ID filtering. Selling/destroying an item removes current ownership; there is no permanent collection/discovery flag.

Shop Legendary base price is 80; purchase price floors `base_price × max(0,1-discount)` with minimum 1. General sale is half base tier price, floored/minimum 1, so Legendary sells for 40; sale ignores discount. Rerolls start at 5 and increase by 5 each reroll. Three inventory spaces make keeping alternate weapons consequential. Deep discount plus resale is an existing economy surface to test before adding economic item effects; source establishes the arithmetic, not a fresh reproduced infinite-gold exploit or a decision to change it.

Shop purchases require a free inventory space and grant to inventory, even with an empty equipment slot. Legendary reward choice auto-equips and can be selected at full inventory. `equip` removes the selected inventory entry, swaps the correct slot, returns displaced gear to inventory if there is room, otherwise sells it for gold. This is intentional current overflow handling, not silently retained alternate gear. Inventory membership mainly uses object identity while shop ownership uses stable IDs; new duplicate/stacking rules require a deliberate policy. Unequip appends an item without its own capacity check; UI guards and direct API behavior should be covered together in later inventory-focused work. Sources: [BuildState](../../../project/scripts/autoload/build_state.gd) L31–40, L68–115, L783–804, L860–880, L1048–1197, L1586–1594, L1611–1789.

Build changes rebuild displayed stats and unlocked skills; rotation normalization filters by unlocked stable ID with a ten-slot maximum. Gold is both currency and a build input; preserve live spend/gain refresh and save timing when considering Bandit/Thief interactions. No gear affix upgrade, item XP, Legendary rank, crafting or consumable path exists in this model. Current finite contract/boss progression and intentional counter matchups remain constraints; this audit does not introduce enemy compensation or endless scaling.

## Practice and persistence boundaries

[TrainingRoomState](../../../project/scripts/systems/training_room_state.gd) `equip_legendary` (L316) unconditionally assigns `equipped_weapon` and prunes rotation. The UI's Custom/Legendary weapon toggle and all-items dropdown share LegendaryCatalog; fixed items are read-only in the affix editor. Thus adding a non-Weapon Legendary to the catalog alone would misroute Practice equipment. Normal custom items use catalog pools, canonical stat IDs and generator maximum-value helper defaults; numeric values remain manually editable, so Practice can deliberately exceed natural rolls. Configured stash, fight seed/duration and target controls feed isolated fights.

Practice rarity shapes are explicitly duplicated in `_affix_slots_for_tier`; Chaos is a fixed Basic/Rare/Basic drawback/Basic editor shape rather than the real generator's four weighted independent outcomes. Defaults use maximum current rarity rolls at depth 0 (clamped to depth 1), not the maximum deep-contract 1.35 scale. Consequently a Practice item is a useful controlled snapshot, not evidence of earned availability, actual rolled distribution, acquisition timing or full-run viability. New stats need dropdown eligibility, value kinds/ranges, editable defaults, live stat/combat effects and persistence checks. See [Practice UI](../../../project/scenes/training_room/training_room.gd) `_refresh_gear_editor`, `_on_weapon_legendary_selected`, `_build_affix_row` and [Practice save](../../../project/scripts/systems/practice_save_system.gd).

[SaveSystem](../../../project/scripts/systems/save_system.gd) L9–12 uses Adventure `user://adventure_p6_m6.json`, save version 2; legacy `user://save.json` remains separate. Gear serializes inventory, pending choices, offers and all five equipped slots. Authored resource-backed items save `resource_path`; load reloads current resources. Adventure `_gear_from_save_entry` first canonicalizes known authored IDs/paths (including LegendaryCatalog entries), then handles obsolete/invalid gear and slot migration notices. Existing persisted Legendary values therefore follow revised authored definitions on reload; path/ID changes or removed content need explicit compatibility decisions.

Runtime/generated inline gear serializes ID/name, slot/tier/family/source, deterministic metadata, generation scale/depth, reward upgrade history, affix canonical ID/legacy enum/category/operation/value/drawback/label and unidentified state. It **does not serialize** `triggered_skill_effects`, `unlocked_skills`, `physical_damage_per_gold` or `min_cast_time_proc_chance`. Existing ordinary fixed Legendaries survive through resource/canonical reload, not complete inline effect serialization. A runtime prototype or future per-instance item progression cannot assume these effect fields round-trip. Practice uses `_gear_from_entry` for custom/equipped entries and shares serialization primitives; it does not automatically share all Adventure canonicalization/migration validation. No separate item-schema revision or item-level progression is present.

Build payloads separately carry schema/content revision, role/ranks and rotation IDs through [BuildSaveCodec](../../../project/scripts/systems/build_save_codec.gd); gear must be available before restored unlock-dependent rotation normalization. T3/T8 must define compatibility before changing IDs, enums, catalog paths, aliases, persisted instance fields or content revision acceptance. Ordinary successful save/load remains different from power-loss durability; no durability/export qualification is claimed here.

## Presentation and feedback support

[LegendaryCatalog](../../../project/scripts/systems/legendary_catalog.gd) `effect_text` is a hardcoded ID→short-description table; mechanics are not generated from it. Tooltip lines include name, rarity/slot/family, weapon damage, affixes and Legendary text. Wyvern's legacy interval affix is suppressed to avoid duplicating the named effect. [CardStyle](../../../project/scripts/ui/card_style.gd) L250–275 and `gear_tooltip`/rich-tooltip code around L500 provide shared stat/effect card surfaces. [StatModifierFormatter](../../../project/scripts/ui/stat_modifier_formatter.gd) formats percentages, probabilities, flat/stack units and binary statements; [GearCompareButton](../../../project/scripts/ui/gear_compare_button.gd), [GearTooltipPanel](../../../project/scripts/ui/gear_tooltip_panel.gd) and [gear panel](../../../project/scenes/combat/gear_panel.gd) support inventory/equipped/comparison surfaces. Display labels/names and max-roll highlighting must continue to agree with actual generator category/depth rules.

Current signatures use authored images via [GearIcons](../../../project/scripts/ui/gear_icons.gd), shared by paper doll, cards, rewards and Practice. A new fixed Legendary requires catalog, icon mapping, description and tests, not just a resource. No new image or visual treatment is selected by T2. Item comparisons display numerical/stat/effect content; they are not an evaluated expected-DPS simulation for conditional effects.

The resolver's `trigger_labels`, proc-origin children and `min_cast_time_proc_applied` support playback highlights; [Practice combat view](../../../project/scenes/training_room/training_room_combat_view.gd) `play`, `_on_playback_cast_start`, popup paths and log formatting include item cues. Practice additionally checks the Wyvern stable ID for its active effect indication. A mechanically equivalent new cadence item would not inherit that ID-specific cue automatically. Current accepted M7 timing/category/keyword/artwork conventions stay in force. There is no implemented general item-event definition/compendium to make future effects self-describing; the experimental log remains Test Mode only.

## Existing coverage versus new validation needed

The following tests exist and were inspected for intent; **not rerun by T2**. Historical passing records, where cited, apply to their recorded source/setup only. Some older tests intentionally assert exact current roster/value/pool signatures and will require reviewed expectation updates after approved changes.

| Existing source | What it already checks | Limit / future use |
| --- | --- | --- |
| [Legendary combat effects](../../../project/tests/p5m10_legendary_combat_effects_test.gd) | Wyvern cadence, Bandit gold delta, Umbral unlock/use, Mithril source filtering and Bejeweled minimum cast | Focused old item checks; not all current tree/combo/acquisition contexts. |
| [Legendary regression](../../../project/tests/p5m10_legendary_regression_test.gd) | Exact authored resources/stats/effect metadata; save/load; legacy ID-only entries; generator/icon boundary | Strong identity/persistence contract; accepted roster/value changes require deliberate fixture review. |
| [Legendary presentation/equip](../../../project/tests/p5m10_legendary_presentation_equip_test.gd) | All cards/icons, inventory/direct equip, reward auto-equip, Practice | Content assertions are not fresh rendered UI inspection. |
| [Legendary generation boundary](../../../project/tests/p5m5_legendary_generator_boundary_test.gd), [RNG contexts](../../../project/tests/run_rng_context_test.gd), [Legendary rewards](../../../project/tests/legendary_reward_test.gd) | Fixed catalog, shop ownership/fallback, no procedural Legendary; distinct seeded choices | Extend for approved new slots/count/duplicate policy and acquired-state reload. |
| [Stat catalog](../../../project/tests/p5m3_stat_catalog_test.gd), [slot eligibility](../../../project/tests/p5m3_slot_stat_eligibility_test.gd), [aggregation](../../../project/tests/p5m3_stat_sheet_aggregation_test.gd), [All Stats](../../../project/tests/p5m3_all_stats_scaling_test.gd) | IDs/metadata/aliases, pools, additive/drawback/floor/caps, binary separation and eligible scaling | T3 must add the new stat contracts, not only generator presence. |
| [Generator regression](../../../project/tests/p5m5_generator_regression_test.gd), [weighted selection](../../../project/tests/p5m5_weighted_stat_selection_test.gd), [value scaling](../../../project/tests/p5m5_stat_value_scaling_test.gd), [unique IDs](../../../project/tests/p5m5_unique_stat_ids_test.gd), [rarity counts](../../../project/tests/p5m5_rarity_stat_count_test.gd) | All-slot/tier seeded generation, inline persistence, weights, range/scaling/rounding and duplicate rules | Chaos is a deliberate exception to ordinary uniqueness; don't infer a current guarantee solely from historical test names. |
| [Economy stats](../../../project/tests/p5m11_economy_stats_test.gd), [gear readability](../../../project/tests/p5m8_stat_readability_test.gd) | Economy Basic/Rare ranges, discount/Magic Find and formatting/order/colors/max rolls | Need conditional effect text and actual-size new item UI evidence. |
| [Practice gear editor](../../../project/tests/training_room_gear_editor_test.gd), [fight setup](../../../project/tests/training_room_fight_setup_test.gd), [full content journey](../../../project/tests/p6_full_content_journey_test.gd) | Shapes/options/Legendaries, live stash inputs and reopening Practice configuration | Controlled editing is not earned progression; non-Weapon Legendary path needs new coverage if adopted. |
| [Mixed gear integration](../../../project/tests/p6_mixed_gear_integration_test.gd) | All four released trees/role pairs, scalar/stack/denial/conversion profiles and hostile defenses; derivation nonduplication, Bandit spending rebuild, damage/gold accounting, cleanup | Hand-authored synthetic gear profiles include normally unavailable stats; not proof those affixes roll or can be earned. |
| [Stat derivation](../../../project/tests/p6_stat_derivation_test.gd), [gold contracts](../../../project/tests/p6_gold_contract_test.gd), [Poison contracts](../../../project/tests/p6_poison_contract_test.gd), [cooldown scheduler](../../../project/tests/p6_cooldown_scheduler_test.gd), [full Shadow](../../../project/tests/p6_full_shadow_test.gd), [full Bladedancer](../../../project/tests/p6_full_bladedancer_test.gd) | Source ordering, derived buckets/live gold, Poison cadence/consumption, origin/cooldown/lifecycle interactions | Reuse focused witnesses for item specs; do not replace their hard-counter expectations merely to improve item win rates. |

[M7 closeout](../../P6M7_T11_Closeout_And_M8_Handoff.md) reports 27 passing current suites and three retained legacy failing suites: `combat_playback_test` old allocation fixture, and inherited six-seed signatures in `p6_combat_ordering_test` / `p6_status_completion_test`. Its roadmap banner assigns fixture/signature reconciliation to M9 and engine/export qualification to M10. T2 does not alter goldens, waive exceptions or convert historical failures into passes. [M6 Legendary handoff](../../P6_Legendary_Remake_Next_Phase_Handoff.md) preserves Bandit/full-run evidence and explicitly rejects treating an experimental softcap as adopted.

## Reusable current systems and boundaries for T3–T5

These are **source-supported opportunity areas**, not proposed item designs or approved additions:

| Existing system | Reusable support | Required design constraint / evidence |
| --- | --- | --- |
| Canonical numeric gear + source ledger | Additive buckets, typed formatting, floors/caps, source snapshots; `CombatStatState` replacement/removal and derived rebuilds | Define unit, bucket, sign, cap, All Stats eligibility and derivation order. A PlayerStats field alone does not enter the normal pool. |
| Ranked derivations | Double Dip sees numeric retrigger; Fast Hands sees final gold bonus; Fill Your Pockets sees Magic Find; Shadow Mastery copies elemental bonuses | Distinguish scalar chances from authored trigger arrays; prevent double counting, cycles and derived-on-derived leakage. |
| Trigger/origin/trace system | Filtered `TriggeredSkillEffect`, guaranteed/random repeat origins, source IDs, depth and per-root budget, explicit decisions | Specify which origins may trigger/retrigger, RNG order, target skill variant and resource/cooldown handling. |
| Bladedancer effects | Footwork/Bypass, Precision/Readiness/Dance and temporary lifecycle sources | Define root/child consumption and duration/expiry order; preserve cleanup and presentation evidence. |
| Assassin/Shadow Poison | Natural clock, forced ticks, caps/fuel, crit Poison, Death Blade, Touch of Darkness and defense-debuff/Consume effects | Define application versus damage versus tick events; do not assume conversion changes proc identity or repeated ticks create free stacks. |
| Thief/live gold | Shared theft/reward rounding, stash/stolen context, Gilded/Silvered caps, Bandit resolved flat base | Specify snapshot versus live values, spend/hoard implications and save-before-playback accounting. |
| Defense/status systems | Shred/Decay, Penetration/Potency, negative defense behavior, denial/immunity Specials, conversion | Intentional severe counters remain valid. Define interactions with ignore-armor's no-Shred tradeoff and existing counter gear. |
| Scheduler and presentation | Macro cooldowns, minimum cast time, proc events, source inspection and M7 compact feedback | Minimum-time effect does not bypass cooldowns; instant child bursts can exceed visible-strike cap. Require consequential feedback without reopening accepted global styling. |

Starting sources: [BuildResolver](../../../project/scripts/systems/build_resolver.gd), [CombatStatState](../../../project/scripts/systems/combat_stat_state.gd), [combat resolver](../../../project/scripts/systems/combat_resolver.gd), [gold](../../../project/scripts/systems/combat_gold.gd), [Poison contracts](../../../project/scripts/systems/p6_poison_contracts.gd), [Bladedancer lifecycle](../../../project/scripts/systems/bladedancer_effect_lifecycle.gd), [scheduler](../../../project/scripts/systems/combat_macro_scheduler.gd), [mixed gear witnesses](../../../project/tests/p6_mixed_gear_integration_test.gd).

## Findings and downstream decisions

| Finding (verified source unless marked historical) | Risk / unresolved question | Owner and concrete next evidence |
| --- | --- | --- |
| Full active pools are smaller than all catalog definitions; aliases collapse three old stack IDs. | Adding only a definition or reusing an alias may appear supported while never rolling or affecting the intended independent stat. | T3: review stable IDs/units/pools/ranges/weights, then prove generated item → resolved stat → combat effect → UI → Practice → isolated save/load. |
| All Stats scales eligible gear aggregates once, not every number on PlayerStats or every signature field. | Broad description/implementation could imply scaling of Bandit coefficients, proc chance fields or talent values. | T3/T5: explicitly specify included/excluded buckets and test capped/drawback cases. |
| Bandit damage scales linearly with resolved stash and has no cap (historical M6 evidence shows excessive scaling). | Hoarding can dominate; flat cuts may remove early usefulness; live theft vs snapshot expectation is easy to misunderstand. | T4/T5 identity/mechanics review; T10 matched early/late snapshots and earned acquisition/spend/hoard trajectories. No curve adopted. |
| Fixed weapon slot makes five effects mutually exclusive; generic slot model supports five categories but Practice Legendary flow assumes Weapon. | Moving slots changes combinations, available skill/rotation and UI/save expectations. | T4/T5 explicitly review slots/combinations; T8/T9 implement and verify only accepted choices. |
| Umbral unlocks historical Death Strike ID; unlocks deduplicate first-seen and runtime special-cases formula. | A same-ID tree/talent unlock can change which resource survives; remaking text or resource effects alone may leave live mechanics unchanged. | T5 define ownership/removal/overlap and source/target variant semantics; T6 verify gear-on/off and multi-source cases. |
| Mithril authored retriggers, numeric random repeat and guaranteed repeat are distinct candidates with recursive effects. | More items can multiply branches or consume temporary resources unexpectedly; a visible cap can hide valid event volume. | T5 origin/RNG/order/budget rules; T6/T10 chain/candidate-limit, interruption/dodge/cleanse and resource witnesses. |
| Bejeweled chance is root cast scheduling, not a new attack/child or cooldown reset. | Ambiguous “lightning fast” text and added cooldown mechanics can invite wrong expectations. | T5 timing contract; T9 compare actual minimum-time/cooldown/failed-cast cases. |
| Canonical authored reload differs from inline serialization, which omits signature-effect fields. | Future instance values/upgrades can silently revert or disappear if treated as ordinary generated gear. | T3/T8 compatibility policy before persisted-data changes; isolated old/current/invalid/partial payload and Practice round trips. |
| Reward auto-equip and overflow sale differ from shop storage; owned exclusion differs from reward sampling. | New rarity/slot/policy can remove alternate gear unexpectedly, allow duplicates or alter acquisition odds. | T5 acquisition assumptions; T8 full-inventory/replaced-Legendary/duplicate/reload cases. |
| Discount minimum purchase price 1 and Legendary sale 40 are separate arithmetic paths. | Economic items may interact with resale/reroll/hoarding; this audit did not reproduce a profitable loop. | T5 review economy interactions; T10 validate reachable rates, timing and net costs before diagnosing exploits. |
| Practice shapes/defaults differ from generation, especially Chaos and deep scaling. | A legal-looking editor build need not represent a real roll or earned build. | T3/T6 keep controlled snapshots and generation/earned evidence separate; fix only if reviewed scope requires it. |
| Hardcoded effect text, icon mappings and some stable-ID feedback cues are separate from mechanics. | New items can be mechanically live but incomplete/misleading across surfaces. | T9 item-by-item cards, comparisons, Practice and actual-size proc/conditional feedback with M7 conventions. |

No finding here adopts a cure or labels intentional hard counters as defects. T3 must review a few candidate stats with the complete contracts above; T4 must review roster roles/overlap/counterplay; T5 must settle timing/interactions/acquisition assumptions before prototype work. M9 retains broader integrated earned-run/unusual-build refinement, M10 broad regression/export qualification.

## Appendix A — Complete enabled numeric pool weights and base ranges

The following tables are transcribed mechanically from current `SLOT_CATEGORY_POOLS`, `SLOT_VALUE_RANGES` and `CATEGORY_SLOT_VALUE_RANGES` in [StatCatalog](../../../project/scripts/systems/stat_catalog.gd). They list every enabled numeric slot/category entry, including repeated economy IDs across categories. Ranges are pre-rarity/pre-depth/pre-request-scale decimal values; use the formula above for actual rolls. Every Basic entry is also eligible for that slot's drawback pool with the same weight. Rare ranges fall back to slot base ranges except the three economy overrides. Weight is relative within the eligible category, not a percentage. Specials are completely inventoried above.

### WEAPON

| Canonical ID | Category | Weight | Base range |
| --- | --- | --- | --- |
| `base_damage` | basic | 20 | 2.0–5.0 |
| `percent_physical_damage` | basic | 15 | 0.06–0.12 |
| `crit_damage` | basic | 15 | 0.30–0.45 |
| `base_elemental_damage` | basic | 10 | 3.0–6.0 |
| `percent_elemental_damage` | basic | 10 | 0.18–0.24 |
| `increased_gold` | basic | 5 | 0.40–0.60 |
| `shop_discount` | basic | 5 | 0.05–0.10 |
| `increased_magic_find` | basic | 5 | 0.15–0.20 |
| `chance_to_shred` | rare | 15 | 0.08–0.10 |
| `chance_to_decay` | rare | 10 | 0.08–0.10 |
| `chance_for_retrigger` | rare | 10 | 0.05–0.08 |
| `increased_gold` | rare | 5 | 0.44–0.66 |
| `shop_discount` | rare | 5 | 0.06–0.11 |
| `increased_magic_find` | rare | 5 | 0.17–0.22 |


### HELM

| Canonical ID | Category | Weight | Base range |
| --- | --- | --- | --- |
| `percent_physical_damage` | basic | 10 | 0.12–0.15 |
| `crit_chance` | basic | 15 | 0.018–0.048 |
| `increased_attack_speed` | basic | 15 | 0.03–0.072 |
| `base_elemental_damage` | basic | 10 | 4.0–10.0 |
| `percent_elemental_damage` | basic | 10 | 0.15–0.21 |
| `increased_all_stacks` | basic | 30 | 1.0–2.0 |
| `increased_gold` | basic | 5 | 0.80–1.00 |
| `shop_discount` | basic | 5 | 0.05–0.10 |
| `increased_magic_find` | basic | 5 | 0.15–0.20 |
| `chance_to_shred` | rare | 10 | 0.08–0.10 |
| `chance_to_decay` | rare | 10 | 0.08–0.10 |
| `crit_applies_element` | rare | 10 | 0.20–0.30 |
| `increased_gold` | rare | 5 | 0.88–1.10 |
| `shop_discount` | rare | 5 | 0.06–0.11 |
| `increased_magic_find` | rare | 5 | 0.17–0.22 |

### ARMOR

| Canonical ID | Category | Weight | Base range |
| --- | --- | --- | --- |
| `percent_physical_damage` | basic | 15 | 0.06–0.12 |
| `crit_chance` | basic | 10 | 0.012–0.024 |
| `percent_elemental_damage` | basic | 10 | 0.18–0.24 |
| `increased_gold` | basic | 15 | 0.40–0.60 |
| `increased_all_stacks` | basic | 30 | 1.0–2.0 |
| `shop_discount` | basic | 5 | 0.05–0.10 |
| `increased_magic_find` | basic | 5 | 0.15–0.20 |
| `chance_to_shred` | rare | 10 | 0.08–0.10 |
| `chance_to_decay` | rare | 10 | 0.08–0.10 |
| `crit_applies_element` | rare | 10 | 0.10–0.20 |
| `increased_gold` | rare | 5 | 0.44–0.66 |
| `shop_discount` | rare | 5 | 0.06–0.11 |
| `increased_magic_find` | rare | 5 | 0.17–0.22 |

### TRINKET

| Canonical ID | Category | Weight | Base range |
| --- | --- | --- | --- |
| `base_damage` | basic | 15 | 4.0–6.0 |
| `percent_physical_damage` | basic | 15 | 0.09–0.15 |
| `crit_chance` | basic | 15 | 0.024–0.036 |
| `increased_attack_speed` | basic | 15 | 0.048–0.06 |
| `base_elemental_damage` | basic | 10 | 5.0–8.0 |
| `percent_elemental_damage` | basic | 10 | 0.12–0.18 |
| `increased_gold` | basic | 5 | 0.20–0.40 |
| `shop_discount` | basic | 5 | 0.05–0.10 |
| `increased_magic_find` | basic | 5 | 0.15–0.20 |
| `chance_for_retrigger` | rare | 15 | 0.03–0.06 |
| `chance_to_shred` | rare | 10 | 0.08–0.10 |
| `chance_to_decay` | rare | 10 | 0.08–0.10 |
| `crit_applies_element` | rare | 10 | 0.10–0.15 |
| `increased_gold` | rare | 5 | 0.22–0.44 |
| `shop_discount` | rare | 5 | 0.06–0.11 |
| `increased_magic_find` | rare | 5 | 0.17–0.22 |

### CHARM

| Canonical ID | Category | Weight | Base range |
| --- | --- | --- | --- |
| `percent_physical_damage` | basic | 10 | 0.09–0.15 |
| `crit_chance` | basic | 20 | 0.036–0.048 |
| `increased_attack_speed` | basic | 15 | 0.06–0.09 |
| `crit_damage` | basic | 15 | 0.24–0.36 |
| `base_elemental_damage` | basic | 10 | 6.0–10.0 |
| `percent_elemental_damage` | basic | 10 | 0.18–0.24 |
| `increased_gold` | basic | 5 | 0.30–0.60 |
| `increased_all_stacks` | basic | 30 | 1.0–2.0 |
| `shop_discount` | basic | 5 | 0.05–0.10 |
| `increased_magic_find` | basic | 5 | 0.15–0.20 |
| `chance_to_shred` | rare | 10 | 0.08–0.10 |
| `chance_to_decay` | rare | 10 | 0.08–0.10 |
| `crit_applies_element` | rare | 15 | 0.12–0.18 |
| `increased_gold` | rare | 5 | 0.33–0.66 |
| `shop_discount` | rare | 5 | 0.06–0.11 |
| `increased_magic_find` | rare | 5 | 0.17–0.22 |

## T2 documentation verification

The appendix contains all **74 enabled numeric slot/category entries** (14 Weapon, 15 Helm, 13 Armor, 16 Trinket, 16 Charm), extracted from the current catalog with a required base/override range for every row. The Special table accounts for all **31 enabled Special slot entries** and all sixteen defined Special IDs, including the two currently unpooled IDs. Basic drawback eligibility follows each slot's Basic table, so its weights/ranges are not silently omitted as a separate pool.

Final worker local Markdown target checks passed: 96 references, zero missing targets. Parent independently parsed the catalog pools, ranges and Rare overrides and compared Appendix A: 74/74 numeric entries, all weights/ranges match, no extras. Parent also checked the four T2-related documents and compared **1,262 scripts/scenes/data/tests hashes**, all unchanged against the baseline captured after the initial read/source searches. See [parent verification record](../../../work/m8_t2_audit/verification.json). This is scoped preservation evidence for those files during the captured interval, not a claim that Git HEAD alone reproduces the dirty workspace or that every repository file was hashed. No real userdata was accessed and no user-save hash claim is made. No gameplay suites were required or executed for this documentation-only task.
