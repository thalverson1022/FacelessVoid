# P6M8-T3 — Gear stat implementation specification

2026-10-22. **Approved implementation contract; implemented and verified under D008.** T3 is Complete; see the [closeout and evidence](P6M8_T3_Closeout_And_Verification.md). This document reconciles the user's replacement pool and timing decisions with current source. It supersedes conflicting implementation details in the [earlier proposal](P6M8_T3_Gear_Stat_Pool_Proposal.md); the contract alone did not establish completion, and the linked closeout does not claim broader balance acceptance.

## Authority and resolved defaults

**User-confirmed:** the complete five-slot ranges/categories below; all five new identities; multiplicative CDR per contribution with no aggregate hard cap, including the reviewed 99.7536% extreme; additive duration affecting timed player buffs and Penetration/Potency; existing rarity/depth and All Stacks behavior. Crit eligibility follows the existing direct-critical-contribution interpretation already stated to the user.

**Implementation defaults resolved by this reconciliation:** retained-entry weights stay at current source values; new timing entries weight 8, crit-debuff entries 10, inventory-economy Special 5; additive duration has **no hard cap**; CDR factors saturate individually at 100% after All Stats; exact RNG/order, carried-item aggregation, version gates and validation contracts below. These are specified under the user's request to finish technical reconciliation, not falsely attributed as individually explicit user decisions. There are no unresolved core implementation choices. Subsequent balance observations do not authorize restoring rejected timing caps.

## Complete normal pool

Every row is an individual eligible affix. Ranges are baseline units before rarity/depth/request scaling; decimal `.10` means 10%. Numeric generated rows use ADD as their serialization operation, including CDR whose dedicated aggregation is multiplicative. Special value is fixed `1`. Only these entries are enabled for new generation. Every Basic row also supplies that slot's Basic drawback with the same weight/range; Rare/Special rows are not generated drawbacks.

### Weapon / Dagger

| Category | Canonical ID | Weight | Base min | Base max |
| --- | --- | --- | --- | --- |
| Basic | `base_damage` | 20 | 2 | 5 |
| Basic | `percent_physical_damage` | 15 | .10 | .20 |
| Basic | `crit_damage` | 15 | .50 | .75 |
| Basic | `base_elemental_damage` | 10 | 3 | 6 |
| Basic | `percent_elemental_damage` | 10 | .30 | .40 |
| Basic | `increased_gold` | 5 | .20 | .30 |
| Rare | `chance_to_shred` | 15 | .08 | .10 |
| Rare | `chance_to_decay` | 10 | .08 | .10 |
| Rare | `chance_for_retrigger` | 10 | .05 | .08 |
| Rare | `shop_discount` | 5 | .10 | .20 |
| Rare | `increased_magic_find` | 5 | .10 | .20 |
| Rare | `increased_gold` | 5 | .50 | 1.00 |
| Rare | `cooldown_reduction` | 8 | .04 | .06 |
| Rare | `increased_buff_duration` | 8 | .08 | .14 |
| Special | `convert_damage_to_physical` | 5 | 1 | 1 |
| Special | `convert_damage_to_magical` | 5 | 1 | 1 |
| Special | `all_stats_increased` | 5 | 1 | 1 |
| Special | `inventory_economy_stats` | 5 | 1 | 1 |

### Helm / Hood

| Category | Canonical ID | Weight | Base min | Base max |
| --- | --- | --- | --- | --- |
| Basic | `percent_physical_damage` | 10 | .20 | .25 |
| Basic | `crit_chance` | 15 | .03 | .08 |
| Basic | `increased_attack_speed` | 15 | .05 | .12 |
| Basic | `base_elemental_damage` | 10 | 4 | 10 |
| Basic | `percent_elemental_damage` | 10 | .25 | .35 |
| Basic | `increased_all_stacks` | 30 | 1 | 2 |
| Basic | `increased_gold` | 5 | .40 | .50 |
| Rare | `chance_to_shred` | 10 | .08 | .10 |
| Rare | `chance_to_decay` | 10 | .08 | .10 |
| Rare | `crit_applies_element` | 10 | .20 | .30 |
| Rare | `crit_applies_penetration` | 10 | .10 | .15 |
| Rare | `crit_applies_potency` | 10 | .10 | .15 |
| Rare | `cooldown_reduction` | 8 | .04 | .08 |
| Special | `double_applied_stacks` | 5 | 1 | 1 |
| Special | `ignore_armor_no_shred` | 5 | 1 | 1 |
| Special | `ignore_resistance_physical_penalty` | 5 | 1 | 1 |

### Armor / Doublet (user's Chest)

| Category | Canonical ID | Weight | Base min | Base max |
| --- | --- | --- | --- | --- |
| Basic | `percent_physical_damage` | 15 | .10 | .20 |
| Basic | `crit_chance` | 10 | .02 | .04 |
| Basic | `percent_elemental_damage` | 10 | .30 | .40 |
| Basic | `increased_gold` | 15 | .20 | .30 |
| Basic | `increased_all_stacks` | 30 | 1 | 2 |
| Rare | `chance_to_shred` | 10 | .08 | .10 |
| Rare | `chance_to_decay` | 10 | .08 | .10 |
| Rare | `crit_applies_element` | 10 | .10 | .20 |
| Rare | `crit_applies_penetration` | 10 | .10 | .15 |
| Rare | `crit_applies_potency` | 10 | .10 | .15 |
| Rare | `increased_buff_duration` | 8 | .10 | .20 |
| Special | `all_stats_increased` | 5 | 1 | 1 |
| Special | `disable_enemy_dodge` | 10 | 1 | 1 |
| Special | `disable_enemy_block` | 10 | 1 | 1 |
| Special | `disable_enemy_absorb` | 10 | 1 | 1 |
| Special | `disable_enemy_suppress` | 10 | 1 | 1 |
| Special | `disable_enemy_cleanse` | 10 | 1 | 1 |
| Special | `immune_to_stun` | 5 | 1 | 1 |
| Special | `immune_to_slow` | 5 | 1 | 1 |
| Special | `immune_to_interrupt` | 5 | 1 | 1 |
| Special | `inventory_economy_stats` | 5 | 1 | 1 |

### Trinket / Ring

| Category | Canonical ID | Weight | Base min | Base max |
| --- | --- | --- | --- | --- |
| Basic | `base_damage` | 15 | 4 | 6 |
| Basic | `percent_physical_damage` | 15 | .15 | .25 |
| Basic | `crit_chance` | 15 | .04 | .06 |
| Basic | `increased_attack_speed` | 15 | .08 | .10 |
| Basic | `base_elemental_damage` | 10 | 5 | 8 |
| Basic | `percent_elemental_damage` | 10 | .20 | .30 |
| Basic | `increased_gold` | 5 | .10 | .20 |
| Rare | `chance_for_retrigger` | 15 | .03 | .06 |
| Rare | `chance_to_shred` | 10 | .08 | .10 |
| Rare | `chance_to_decay` | 10 | .08 | .10 |
| Rare | `crit_applies_element` | 10 | .10 | .15 |
| Rare | `crit_applies_penetration` | 10 | .10 | .15 |
| Rare | `crit_applies_potency` | 10 | .10 | .15 |
| Rare | `increased_buff_duration` | 8 | .10 | .12 |
| Special | `double_applied_stacks` | 5 | 1 | 1 |
| Special | `disable_enemy_dodge` | 10 | 1 | 1 |
| Special | `disable_enemy_block` | 10 | 1 | 1 |
| Special | `disable_enemy_absorb` | 10 | 1 | 1 |
| Special | `disable_enemy_suppress` | 10 | 1 | 1 |
| Special | `disable_enemy_cleanse` | 10 | 1 | 1 |
| Special | `convert_damage_to_physical` | 5 | 1 | 1 |
| Special | `convert_damage_to_magical` | 5 | 1 | 1 |

### Charm / Necklace

| Category | Canonical ID | Weight | Base min | Base max |
| --- | --- | --- | --- | --- |
| Basic | `percent_physical_damage` | 10 | .15 | .25 |
| Basic | `crit_chance` | 20 | .06 | .08 |
| Basic | `increased_attack_speed` | 15 | .10 | .15 |
| Basic | `crit_damage` | 15 | .40 | .60 |
| Basic | `base_elemental_damage` | 10 | 6 | 10 |
| Basic | `percent_elemental_damage` | 10 | .30 | .40 |
| Basic | `increased_gold` | 5 | .15 | .30 |
| Basic | `increased_all_stacks` | 30 | 1 | 2 |
| Rare | `chance_to_shred` | 10 | .08 | .10 |
| Rare | `chance_to_decay` | 10 | .08 | .10 |
| Rare | `crit_applies_element` | 15 | .12 | .18 |
| Rare | `crit_applies_penetration` | 10 | .10 | .15 |
| Rare | `crit_applies_potency` | 10 | .10 | .15 |
| Rare | `cooldown_reduction` | 8 | .06 | .10 |
| Special | `ignore_armor_no_shred` | 5 | 1 | 1 |
| Special | `ignore_resistance_physical_penalty` | 5 | 1 | 1 |
| Special | `double_applied_stacks` | 5 | 1 | 1 |
| Special | `disable_enemy_dodge` | 10 | 1 | 1 |
| Special | `disable_enemy_block` | 10 | 1 | 1 |
| Special | `disable_enemy_absorb` | 10 | 1 | 1 |
| Special | `disable_enemy_suppress` | 10 | 1 | 1 |
| Special | `disable_enemy_cleanse` | 10 | 1 | 1 |

### Mechanical totals and generation rules

| Slot | Basic count / weight | Rare count / weight | Special count / weight | Positive entries |
| --- | --- | --- | --- | --- |
| Weapon | 6 / 75 | 8 / 66 | 4 / 20 | 18 |
| Helm | 7 / 95 | 6 / 58 | 3 / 15 | 16 |
| Armor | 5 / 80 | 6 / 58 | 10 / 75 | 21 |
| Trinket | 7 / 85 | 7 / 73 | 8 / 65 | 22 |
| Charm | 8 / 115 | 6 / 63 | 8 / 65 | 22 |
| Total | **33 / 450** | **33 / 318** | **33 / 240** | **99** |

There are **66 numeric** positive slot/category entries, **33 binary** entries and **33 derived Basic-drawback entries**. Weight is relative within category, not percentage. The [machine-readable expected pool](../work/m8_t3_spec/expected_pool.json) and [weight reconciliation](../work/m8_t3_spec/weight_reconciliation.json) are specification evidence, not runtime data: 83 retained entries preserve source weights, 16 new entries are added and 22 old entries removed. Source: [StatCatalog.SLOT_CATEGORY_POOLS](../project/scripts/systems/stat_catalog.gd).

Remove Basic Discount/Magic Find everywhere and Rare economy outside Weapon from generation only; retain definitions/aliases/consumers for saved gear. Weapon Rare economy overrides must be `.50–1.00`, `.10–.20`, `.10–.20`, not inherited old overrides. Unpooled Shred strength, extra Shred and Decay strength remain unpooled and unchanged.

Keep [GearGenerator](../project/scripts/systems/gear_generator.gd) shapes: Basic 1 Basic; Master 2 Basic; Epic 2 Basic+1 Rare; Cursed 2 Basic+1 Rare+1 Basic drawback; Unique 3 Basic+1 Rare+1 Special; Chaos four independent outcomes (Basic positive weight5, Rare positive4, Basic drawback5). Rare entries never roll on Basic/Master. Specials only roll on Unique, not Chaos. Crude/fixed Legendary resources do not enter generation. Ordinary canonical IDs stay unique across categories/signs; Chaos permits duplicates. Retain pool order shown above for deterministic generation in the new content revision.

`roll = uniform(base_min,base_max) × rarity_multiplier × value_scale × [1+.35×(clamp(depth,1,12)−1)/11]`.

Multipliers remain Basic1, Master1.75, Epic/Unique2, Cursed±2.5, Chaos±3. Request `value_scale` remains finite positive, default1. Round percent/chance to `.01`, flat/stacks to integer, positive stacks at least1; use current Godot rounding, not integer-uniform input. Binary rows bypass scaling. Reject non-finite inputs/results with a deterministic validation error, not reroll/clamp to an unrelated affix. Do not add global value-scale or balance caps.

## Aggregation and resolved stat interface

New IDs: `cooldown_reduction`, `increased_buff_duration`, `crit_applies_penetration`, `crit_applies_potency`, `inventory_economy_stats`. Numeric new Rare values must be finite and nonnegative, ADD only; invalid operation/sign fails build/Practice preview/load validation atomically. Values above1 are allowed as raw inputs, with the explicit consumer rules below. New Special is binary value1 and non-drawback; duplicate copies deduplicate. Existing signed numeric/legacy operation behavior remains for old IDs, including imported economy drawbacks.

[StatSheet](../project/scripts/resources/stat_sheet.gd) must give CDR a dedicated per-affix path, not generic ADD finalization. Store an ordered contribution ledger with source slot/item/affix index, raw `c_i`, All Stats multiplier and effective factor. Raw values remain available; any arithmetic sum is labeled raw sum and never used as resolved CDR. In the final sheet, `value_for(cooldown_reduction)` returns combined CDR. Expose retained cooldown factor separately so the scheduler never reconstructs a tiny factor from rounded display text.

Let `a=1.2` if an equipped All Stats Special exists, else1. For every equipped CDR affix: `effective_i=min(1,raw_i×a)` and `retained_i=1−effective_i`. Then `cooldown_factor=product(retained_i)` and `cooldown_reduction=1−cooldown_factor`. Empty list yields factor1/CDR0. Do not round `raw_i×a`; do not scale combined CDR by All Stats; do not merge duplicate affixes before multiplying. The per-factor [0,1] mathematical domain is not an aggregate balance cap: raw100% or larger, including a value pushed above100% by All Stats, gives factor0. Product underflow to0 is acceptable and uses the1ms floor. Never allow negative factors. Multiplication order is displayed equipment order Weapon/Helm/Armor/Trinket/Charm then affix index, for deterministic floating-point results. Validate finite raw values before multiplying; implement saturation without overflowing an intermediate `raw_i×a` (compare against `1/a` first).

Duration: `d=max(0,sum(raw_duration))×a`, no hard cap. Crit-debuff chances: `p=min(1,max(0,sum(raw_chance))×a)` independently. No second rounding after All Stats. Reject non-finite intermediate sums/products instead of propagating infinity. Generic old stats keep their current floors/caps/All Stats eligibility; All Stacks retains its existing Footwork/Bypass/Poison/Shred/Decay/Penetration/Potency grants and integer rounding. No new gear cap is added to old stats.

Resolved PlayerStats CDR/factor, duration and two probabilities default to0/1/0/0/0. Preserve them through [BuildResolver](../project/scripts/systems/build_resolver.gd), derivation-base clones and temporary-stat copies/rebuilds; apply gear once, before existing derivations. They are build-static, not temporary effects or attack-speed aliases. The equipped Special is a boolean in the existing special set. Source inspection distinguishes imported economy, equipped raw, effective aggregate and derived outputs; no raw CDR list is reapplied as an additive source during rebuild.

## Cooldown and duration consumers

For authored positive `C`: `effective_C=max(1,ceil(C×cooldown_factor))`; authored zero remains0. Use the factor directly, including factor0. Preserve [CombatMacroScheduler](../project/scripts/systems/combat_macro_scheduler.gd) ownership: cooldown starts at completed eligible root windup; dodged/interrupted attempts still start it; missing-resource/clipped attempts do not. Same stable skill IDs share a deadline. Snapshot at start; never rescale an active deadline or mutate the authored Skill. Blocked slots cost100ms, exact deadline is ready, and children retain existing zero-windup/cooldown-bypass behavior without starting/resetting macro cooldowns. CDR includes Virulent and Pick Pocket; zero-CD skills gain no interval. Bejeweled/IAS/slow/resource rules remain.

For eligible authored positive duration `D`: `effective_D=max(1,ceil(D×(1+d)))`, snapshot at each grant/refresh. Do not rescale a previously scaled duration. These eight families are eligible:

| Family | Base before duration scaling | Existing state rule retained |
| --- | --- | --- |
| Footwork | 3000ms | Shared refresh, cap5; cast-start-inclusive boundary preserved. |
| Bypass | 3000ms | Shared refresh, cap3; existing expiry/consumption boundary. |
| Dance of Death | Authored5000ms | Independent instances and existing guaranteed-repeat rules. |
| Master of Poisons | Authored5000ms | Independent instances; live resistance denial. |
| Touch of Darkness | Authored12000ms | Actual Poison consumption sets magnitude; independent instances. |
| Beguiling Presence | Authored10000ms | Actual Decay consumption sets magnitude; independent instances. |
| Penetration | **3000+1000×Death Pact rank ms** | Enemy shared refresh, cap50, cleansable. |
| Potency | **3000+1000×Death Pact rank ms** | Separate enemy shared refresh, cap50, cleansable. |

Death Pact's added seconds apply before multiplying duration: rank3 and `d=.50` gives `6000×1.5=9000ms`. All sources of these statuses use that duration: new crit grants, ordinary skills and Consume grants. Quantity remains source-specific. Timer length neither doubles through All Stacks nor changes magnitude, charges, cap, consumption or cleanse. Positive grants refresh even at cap; zero grants do not. Partial consumption preserves expiry; full consumption removes the instance. Expiry/boundaries remain effect-specific, particularly Footwork; do not substitute one universal boundary rule.

Precision/Readiness and Virulent charges remain untimed, including sentinel values; do not invent a timer. Poison/Decay/Shred lifetimes, stun, slow, cooldowns and all other effects are excluded. Future identities require explicit integration. Fight cleanup clears instances/sources as today.

Grant anchors: [CombatSelfBuffs.grant](../project/scripts/systems/combat_self_buffs.gd), [CombatTalentBuffs](../project/scripts/systems/combat_talent_buffs.gd), [BladedancerEffectLifecycle](../project/scripts/systems/bladedancer_effect_lifecycle.gd), [CombatDefenseDebuffs](../project/scripts/systems/combat_defense_debuffs.gd), and [CombatEffectState](../project/scripts/systems/combat_effect_state.gd). Build-static lifecycle definitions may precompute once from the preserved base; refresh uses that definition without compounding.

Unbounded additive duration does not authorize numeric overflow: reject non-finite aggregate/duration or a `ceil(D×(1+d))`/timestamp addition outside signed64-bit representability before conversion/addition. Preview reports an invalid stat/timer; combat returns its existing invalid-simulation result, never wraps, silently shortens, discards instances or converts finite timers to untimed. Use checked arithmetic rather than a float comparison that rounds INT64_MAX upward. This is arithmetic validation, not a gameplay cap. Retain current finite fight window/trigger budgets; large valid durations may outlast that window.

## Crit-trigger contract and exact ordering

At the end of [CombatResolver._apply_skill_effects](../project/scripts/systems/combat_resolver.gd), after existing direct damage and current Poison/Shred/Decay proc checks, insert independent checks in order Penetration then Potency, before returning to `_finalize_cast_event`. Eligibility is `_skill_is_direct_attack(skill)` and that call's local `contribution_crit`, on a connected noninterrupted/non-resource-failed contribution. Use the local result, not cumulative `event.is_crit`. Several damage effects within a contribution yield at most one trial per new stat. Separate eligible repeat/proc children have their own trials. Self Buff/Debuff and natural/forced Poison tick crits, including converted ticks, are excluded.

[DamageCalculator](../project/scripts/systems/damage_calculator.gd) retains `is_crit` when crit negation/block/absorb reduces damage to0; those connected rolled crits qualify, matching crit-to-Poison. No positive-damage requirement, new crit roll or extra repeat source. Chance0 makes no draw; positive chance makes one `rng.randf() <= p` trial per stat, including chance1, consistent with existing chance hooks. Positive new chances change later seeded draws; chance0 preserves baseline draw consumption.

Success invokes ordinary defense grant with base1: add the status's existing bonus stacks, then double if Double Applied Stacks, then cap at50. Do not use `is_conversion=true`: Death Pact's actual-consumed-quantity exception belongs only to Consume. Duration is Pact-then-duration above. Penetration lowers block1/stack; Potency lowers absorb1/stack; negative defenses retain existing base-damage bonuses. At zero starting defense,50 stacks give −50 and +5 relevant base damage, not an armor/resistance bypass. Denial/Finders Keepers and cleanse interactions remain intentional.

Exact root/child sequence: direct damage/current applications → new crit-debuff checks → `_finalize_cast_event` effects (including later forced tick/Consume) → post-hit cleanse counter/clear → descendants in `_resolve_retrigger_chain`. Triggering damage cannot benefit retroactively. A forced tick in finalize may use the new debuff before cleanse; descendants see only what survived finalize/cleanse. Test and explain that distinction. The helper's optional `result=null` compatibility path cannot silently claim new procs: nonzero new proc stats require a combat result/defense lifecycle, otherwise return an invalid-context error before drawing/applying.

## Inventory Economy Special

Only an equipped `inventory_economy_stats` activates the feature; multiple copies do not compound. Import from owned unequipped carried gear exactly `increased_gold`, `shop_discount`, `increased_magic_find`, using canonical IDs/recognized aliases and existing numeric operation/sign rules. Basic/Rare occurrences and negative Chaos copies all count. Valid old saved economy affixes outside the replacement pool still contribute. No inventory weapon damage, combat stat, timing/proc stat, unlock, trigger, Bandit signature, All Stats or other Special is imported. A Special in inventory cannot activate itself recursively.

Sum imported raw economy contributions with equipped raw contributions before floors, equipped All Stats and existing talent/derived processing. Do not floor individual inventory items or apply All Stats twice. Inventory All Stats is inactive; equipped All Stats scales each combined eligible bucket once. No new economy cap. Fast Hands/Fill Your Pockets derive combat outputs from final gold/Magic Find as before; increased theft feeds existing Bribery/live-gold context. This is not combat-neutral. Bandit keeps resolved-stash snapshot behavior.

**Ownership uses collection occurrences**, not stable IDs or Resource pointers: one equipped slot and each inventory index are separate owned records, each traversed once. Cached authored resources can give distinct saved copies the same pointer; pointer-deduplicating would wrongly discard legitimate copies. Identical IDs/values/pointers at different authoritative ownership occurrences therefore count separately. Equip must move exactly one inventory occurrence into its equipped slot before rebuilding; do not concatenate the equipped list into the inventory import pass. If a buggy caller leaves the item in both collections, that is an ownership mutation bug to fix/test, not something distinguishable by blanket identity deduplication. This explicitly replaces the earlier proposal's pointer-dedup default. No global UUID migration is needed.

BuildState's existing inventory list is authoritative, without silently truncating preserved legacy/API states above3; acquisition capacity remains3. Practice's new carried editor is bounded to3. Rebuild on acquire/equip/swap/unequip/sell/remove/load. Shop offers, pending unowned rewards and sold items never contribute. Purchase uses pre-purchase ownership for price, then payment/transfer then rebuild; an item cannot discount itself. Preserve Chaos identification before ownership transfer. Selling/overflow sale removes future contribution, with existing fixed sale price/full-inventory guards. Magic Find snapshots at existing offer/reward generation: never reroll persisted offers on ownership change. Discount display/purchase revalidate current state; gold rewards/theft retain rounding and combat setup/live timing. Do not recalculate already-resolved combat retrospectively.

Pass inventory explicitly into BuildResolver from Adventure/Practice stat entry points; optional empty default keeps unrelated callers valid. Attribute source as equipped slot or carried index/affix, preserving raw/effective/derived values. Imported totals are never persisted. Recomputations, including price/gold changes and temporary rebuilds, must not apply them twice.

## Persistence and compatibility policy

Implement an Adventure envelope version3, accepting current supported version2 and version3 through the same build codec/current registries. Writer always emits3 on the next normal save; loading2 does not write/upgrade the file. Preserve `user://adventure_p6_m6.json`, legacy `user://save.json`, existing version1/current-registry rejection and explicit compatibility-registry policy, and Test Mode's session-only behavior. Do not broaden accepted incompatible content revisions or reset a run merely for this gear change.

Implement Practice version2, accepting1/2. Version1 loads carried gear as empty. Version2 requires `carried_items` as an ordered array of0–3 nonnull owned gear entries using the existing gear codec; malformed/missing/out-of-range payload fails. Writer emits2. Default is empty; no Adventure inventory is read/copied. Preserve equipped/custom linking and unrelated target/setup data. Inactive editor custom templates are not additional carried/equipped owned records.

Why envelope bumps: current [Adventure loader](../project/scripts/systems/save_system.gd) rejects3 and current [Practice loader](../project/scripts/systems/practice_save_system.gd) rejects2 before gear decoding, protecting against old executables interpreting unknown new canonical IDs through legacy-enum fallback. Verify old-reader rejection leaves state/file unchanged. No downgrade converter is provided. Keep build content revision/codec and generated-contract schema unchanged; these are gear semantics/Practice inventory gates, not a tree migration. New generation determinism is identified by the implementation/source revision and new save envelope, not an invented incompatible tree revision.

Loads decode into detached candidates, validate new affix domains/ownership shape/timers, then atomically replace state. Failure leaves state/signals/disk unchanged. No automatic read-time rewrite; existing normal autosave after later user/game actions can write the new envelope. Strict JSON/non-finite/duplicate-key rejection remain. New envelopes require known nonempty canonical IDs, or a valid blank-ID legacy enum path; unknown explicit IDs fail rather than silently fallback. For Adventure2/Practice1 payloads retain old-ID decoding policy, but reject the five new IDs in an old envelope as requiring the new version. Never reinterpret an invalid new modifier as attack speed.

Old inline affixes retain exact saved values/categories/operations/signs, including now-removed pool entries. Generation eligibility is not a load-validity filter. Preserve seed/context/depth/scale/history and already-generated equipment/inventory/offers/pending rewards; no backfill/reroll. Each persisted inventory occurrence remains an owned record even if resource caching yields equal object pointers. Authored Legendaries use the existing canonical reload path with unchanged values/signatures/unlocks. Do not flatten their signatures into numeric affixes. Outside new-semantic validation, retain scoped inherited invalid/obsolete gear handling. Do not modify real saves while implementing/tests.

## UI, Practice and implementation boundaries

Display CDR as combined effective reduction, with raw/effective per-affix factors in inspection; never add printed item percentages to imply combined CDR. Show the1ms floor truthfully near100%; keep adequate precision in detail. Duration shows additive percentage and actual resolved durations, including Pact. Crit lines show chance per critical direct contribution and base1 stack; detail explains extras/doubling/cap50. Show probabilities/imported economy sources/derived combat outputs. Comparisons recompute full owned state, including Special loss/gain and equipped/inventory movement.

Practice uses replacement tables for new selectable rolls/defaults and keeps raw values editable with validation feedback. Add a minimal isolated carried-gear editor with0–3 owned entries, slot/tier/affixes and remove action using existing controls. Fixed Legendary editing stays read-only. Retained old custom gear with removed-pool affixes remains displayed/editable as legacy content without putting those IDs in new-roll dropdowns. Fixed-shape Chaos editing is not a generation witness: duplicate extremes need explicit custom snapshots or generated fixtures. Preserve M7 artwork/layout/colors/compact hovers and actual expiry/proc feedback.

Expected touches: catalog/ranges/weights, generator canonical naming/metadata/value validation, dedicated StatSheet CDR aggregation, PlayerStats/build inventory wiring and clone preservation, scheduler/eight duration consumers, two crit checks/trace, shared UI/Practice, save gates/ownership and focused tests. No wholesale resolver/economy redesign, new Legendary values, enum reorder, class or route additions. Rebuilds cannot turn build-static timing into temporary-source amplification.

## Analytical acceptance witnesses and risk classification

The [current analytical examples](../work/m8_t3_spec/analytical_examples.json) concern this replacement pool, not the historical30% cap proposal. They are formulas/structural gear arrangements, not drop-frequency measurements, simulated balance or simultaneous universal maxima.

- Maximum depth12/scale1 CDR Chaos contributions are Weapon.24, Helm.32, Charm.41; four of each plus All Stats on Unique Armor retain `.712^4×.616^4×.508^4`, about.002464 of cooldown. This gives about99.7536% CDR and25ms for an authored10s cooldown. **This endpoint was explicitly accepted; verify it, do not cap it away.** Other macro slots/windup/100ms blocked attempts still affect actual recast spacing.
- Duration's individual depth12 Chaos maxima are Weapon.57, Armor.81, Trinket.49. Four copies on each sum7.48, giving **8.48×** authored lifetime with no All Stats. An All Stats Special must replace a Chaos Weapon or Armor; it cannot be added on an imaginary extra slot. Best such duration arrangement uses Unique Weapon maximum.38 plus Chaos Armor3.24 and Trinket1.96: `5.58×1.2=6.696`, or7.696× lifetime. Therefore this particular maximum is larger without All Stats. Normal generated duration is bounded by these tables; arbitrary editable/request scales are not balance-capped.
- New crit-proc base.10–.15 reaches rawChaos.41–.61 at depth12. Many copies plus All Stats can hit100% probability, but grant quantity still follows existing bonuses/doubling/cap50. Duration now extends maintenance/cleanse-recovery windows for these debuffs as requested. Negative block/absorb outcomes and retained hard counters require witnesses, not hidden immunity or chance reductions.
- New Weapon Rare economy maxima at depth12 are discount/Magic Find.81 and gold4.05 per Chaos affix. Three carried Chaos weapons can contribute12 copies: discount/Magic Find9.72 raw (11.664 with equipped All Stats), or gold48.6 raw (58.32 after All Stats), as separate maximal inventories. Inventory Special on Unique Armor plus All Stats on Unique Weapon is structurally compatible; these inventory affixes contribute no weapon damage or signature effects.

Long-lived/overlapping buffs, large Virulent multipliers, maintained debuffs and more theft are expected stress cases under accepted timing freedom. Preserve finite fight windows and current invalid-simulation/trigger budgets; do not truncate valid events to fake success or impose a balance cap. Non-finite damage/state produced by extreme valid builds must be surfaced as an invalid simulation with diagnostics, not silently accepted as a win. Report numerical/runtime failures separately from intended strong builds and separately from measured balance findings.

Inventory economy has a concrete purchase/resale surface: an80-gold Legendary sells40;50% discount breaks even before reroll costs, larger discounts can profit, and≥100% discount buys1/sells40. Two carried duplicate maxChaos discount rolls exceed100% while using one inventory space. Validate owned/excluded offers, free space, reroll cost and loss of sold modifiers before calling a complete infinite loop. This spec leaves prices/resale/discount/talent coefficients intact. Classify the evidence for T3/T10 review rather than silently nerfing economy or claiming launch balance acceptance. M9 owns broader earned runs; M10 broad export/regression qualification.

## Required implementation verification

The [T2 audit](P6M8_T2_Current_Legendary_And_System_Audit.md) and [mechanics reference](Combat_Mechanics_Reference.md) establish source anchors, not fresh passes. Extend affected suites and deliberately update pool/range fixtures; preserve unrelated expectations.

| Existing suite anchors | Required witnesses |
| --- | --- |
| `p5m3_stat_catalog_test`, `p5m3_slot_stat_eligibility_test`; `p5m5_weighted_stat_selection_test`, `p5m5_stat_value_scaling_test`, `p5m5_rarity_stat_count_test`, `p5m5_unique_stat_ids_test` | Exact99 positive entries/weights and33 drawbacks;66 numeric ranges/overrides; removed entries absent from generation; all rarities/slots; depth1/12/clamps; request scales; ordinary uniqueness/Chaos duplicates and deterministic new revision. |
| `p5m3_stat_sheet_aggregation_test`, `p5m3_all_stats_scaling_test`, `p6_stat_derivation_test` | Separate CDR copies versus sum, per-affix All Stats once, deterministic order, no aggregate cap, raw≥100%, nonnegative factors/finite validation, duration uncapped sum, probability caps, old-stat compatibility and derivation-base/temporary rebuilds. |
| `p6_cooldown_scheduler_test`, `p6_macro_scheduler_test` | Same-ID deadlines, authored0, positive1ms floor, accepted99.7536%→25ms/10s, skipped100ms attempts, clipped/resource/dodge/interrupt behavior, children/no reset, minimum-cast/slow and cleanup. |
| `p6_status_accounting_test`, `p6_status_interactions_test`, `p6_poison_contract_test`, `p6_full_bladedancer_test`, `p6_full_shadow_test` | All eight durations, Pact-before-scaling, Footwork exact inclusive boundary, shared refresh at cap, zero grant/partial Consume, independent overlap and cleanup; untimed/excluded effects; float/int64 overflow failure. |
| `p6_mixed_gear_integration_test`, `p6_gold_contract_test`, `p5m11_economy_stats_test` | Local crit/zero damage/multiple effects/children/tick exclusion; RNG0 and1; before-finalize/cleanse/descendant ordering; negative defenses, All Stacks/doubling/Pact; exact carried filter/signs/All Stats/derivations and price/Magic Find snapshots. |
| `training_room_gear_editor_test`, `training_room_fight_setup_test`; current persistence suites | Carried defaultempty/editor/comparisons; same-ID/cached-resource copies count by ownership occurrence and equip moves one occurrence; Adventure3 reads2&3, Practice2 reads1&2, no read-write, old reader rejects new; old removed affixes preserved, candidate failure atomicity, all persisted locations round-trip. |
| Legal-build snapshots and actual rendered UI | Generated item→owned-source ledger→combat→display→isolated reload; nearzeroCD repeated buffs/stockpile, duration overlap/debuff maintenance, event volume/cleanse, complete purchase/sale/reroll trajectory; earned acquisition distinguished from synthetic stress. |

Use the established isolated-save workflow, never real userdata or sibling Enigma. Existing focused tests are SceneTree/derived SceneTree scripts with entry form `godot --headless --path <isolated-project-copy> --script res://tests/<existing_test>.gd`. Resolve the executable and copy/fixture setup from the actual local runner before execution; do not guess an installed path. Specification preparation ran no engine command; actual implementation evidence is recorded in the linked closeout. M7's inherited legacy exceptions remain recorded, not waived or counted as new passes.

## Completion boundary and documentation evidence

T3 implementation, targeted evidence, isolated compatibility and presentation checks are delivered in the [implementation closeout](P6M8_T3_Closeout_And_Verification.md). Broader earned-run and launch balance acceptance remains outside this closeout. Machine-readable pool/weight/math artifacts above remain specification evidence; actual runtime reports are linked from the closeout.

The historical specification-preparation [documentation verification report](../work/m8_t3_spec/verification.json), reproducible with [verify_spec.py](../work/m8_t3_spec/verify_spec.py), checks all 99 table entries against the reconciled pool, local document links, 21 existing test anchors and 1,262 source-file hashes against the task-start baseline. At specification preparation these checks passed with no pool mismatches, broken links, missing test anchors or source changes. The separate closeout manifest records subsequent authorized implementation changes.
