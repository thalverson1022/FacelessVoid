# P6M8-T5 — Consolidated Legendary mechanics specification

Last updated: 2026-10-24. **T5 Complete under D073 — user approved the specification and technical defaults on 2026-10-24.** T1–T7 Complete. T6 prototype findings approved under D076; T7 implementation and findings approved under D079; T8 Complete under D082; T1–T8 Complete; T9–T12 Not started. [T8 results](P6M8_T8_Acquisition_Progression_And_Persistence_Verification.md). See [T7 results](P6M8_T7_Implementation_And_Verification.md). See [T6 report](P6M8_T6_Representative_Prototypes_And_Findings.md). This specification records mechanics approval; implementation evidence is recorded separately, and final balance remains unaccepted.

Authority: [M8 decision log](P6M8_Legendary_Item_Revamp_And_Expansion_Tracker.md), [approved T4 roster and art sources](P6M8_T4_Legendary_Roster_Proposal.md), [T3 stat specification](P6M8_T3_Gear_Stat_Implementation_Specification.md), current [combat reference](Combat_Mechanics_Reference.md). The [archived question workbook](P6M8_T5_Decision_Workbook_Archive.md) preserves the original discussion through D066, including superseded proposals and obsolete open labels. This document is the current consolidated contract.

## Authority and boundaries

**Accepted** denotes explicit user decisions. **Technical reconciliation** denotes reviewable implementation details derived from those decisions and current source; it does not claim separate prior user approval. Q1–Q7 are resolved in the disposition table below; the consolidated technical defaults were approved under D073. T5 checkpoint is resolved; prototype behavior is reviewed at the T6 checkpoint before broad implementation.

- Retain all 16 identities, supplied sprites and fixed affixes. Existing weapon IDs and artwork remain. Existing Mithril Karambit is the user's “Mitrhril Krarambit”; retain its stable ID. Preserve new display spellings such as Nightkiss Kitana unless copy-editing is requested.
- Fixed Legendary affixes do not depth-scale; normal eligible build bonuses remain (D058). Both new weapons use 21–27 base weapon damage separately from affixes (D059). Current range resolution depends on tier and slot, not sprite or family metadata.
- One item per existing slot, up to five Legendaries simultaneously (D056). Chests use Armor. No new equipment slots, classes, account progression or global lives system.
- **Supersessions:** D016 replaces D015's retrigger-based Locket. D050 replaces D049's global-life prerequisite with retained encounter attempts. D062 rejects new loot-roll/rarity rules, including proposed shop-matched enemy odds. D063–D064 resolve the early open stack-grant questions.
- Keep T3 multiplicative CDR, additive Buff Duration, All Stacks, All Stats eligibility, inventory economy and intentional counters. Accepted recursive chains remain; no unreviewed cap or diminishing chance is introduced. D068 explicitly retains the existing depth-16 cutoff; no new lower or item-specific cap.

**D072 — economy additions deferred (2026-10-24):** user put the proposed additional economy Legendaries/Overkill Gold effects on hold for a later economy pass. None of the brainstormed identities/effects/values is adopted; retain the approved 16-item roster. This does not defer existing item economy contracts or T10’s recorded discount/resale and balance validation. T5 still awaits final specification/technical-default review only.

## Full roster: authored stats and signatures

These values are transcribed design inputs, not new tuning. All 14 sprite paths remain in T4: eleven new item icons, Exsanguinate, Meditation and Dash. Existing five weapon sprites stay unchanged.

| Slot / item | Fixed authored stats | Current signature contract |
| --- | --- | --- |
| Weapon — Wyvern Kriss | +8 Base Elemental Damage; +40% Elemental Damage; +12% Chance to Decay | Poison ticks twice as fast; retain current natural cadence ×0.5 with normal fuel, suppression and clock rules. No added Poison source. |
| Weapon — Umbral Stiletto | +10% Crit Chance; +100% Crit Damage; +50% Crits Apply Poison | Grants Death Strike; +1 Physical Damage per current Decay stack, added to existing damage and Poison scaling, without consuming Decay (D039–D040). |
| Weapon — Mithril Karambit | +15% Increased Attack Speed; +15% Crit Chance; +20% Chance to Shred | Add 50 percentage points to Stab/Heavy Slash's normal retrigger roll only. Exclude from numeric Retrigger Chance and every stat-scaling bonus, including Double Dip (D011). Replace the separate authored signature rolls; do not keep both. |
| Weapon — Bandit Blade | +20% Physical Damage; +12% Crit Chance; +50% Increased Gold | `min(100, floor(stash_gold / 10))` Base Physical Damage, updated live on combat stash changes (D045–D046). |
| Weapon — Bejeweled Push Dagger | +8 Base Physical Damage; +20% Physical Damage; +10% Crit Chance | 40% chance to use a skill's minimum cast time, without cooldown bypass or an extra cast (D047). |
| Weapon — Decrepit Blade | +10 Base Physical Damage; +10 Base Elemental Damage; +12% Retrigger Chance | Grants Poison Strike. Keep normal attack damage; replace its single forced tick with one all-stack Poison burst (D017–D019). D068/D071 finalize normal Poison modifiers, Consume hooks and live repeat calculations. |
| Weapon — Nightkiss Kitana | +50 Armor Decrease per Shred Stack; +5 All Stacks; +20% Chance to Shred | Grants Exsanguinate. +5 is the existing All Stacks stat, not Shred-only or a cap increase (D034). |
| Helm — The Crown of Concertation | +20% Attack Speed; +20% Increased Buff Duration; +15% Cooldown Reduction | Double active/passive self-buff strength, including Dash. Duration, caps and grant counts unchanged (D032–D033). D070 doubles the bonus above baseline (×2 → ×3). |
| Helm — Helm of the Samurai | +12% Crit Chance; +20% Attack Speed; +8% Retrigger Chance | Retriggers grant one base Meditation stack: skill repeats, guaranteed repeats and Poison repeats (D014/D024). |
| Armor — Cloak of Speed | +70% Increased Physical Damage; +25% Crits Apply Penetration | Grants Quick Cut; retriggered attacks have provisional 30% chance to trigger Quick Cut. That Quick Cut follows normal rules and can retrigger into further Cloak activations (D012–D013). |
| Armor — Death's Door | +35% Increased Physical Damage; +35% Increased Elemental Damage; +60% Increased Gold Rewards | Multiply all damage, including Poison, by `max(1, 2 × missing_attempts)`; exclude Exsanguinate. Use current encounter failures; opening unlimited-retry fight gives ×1 (D050/D066). |
| Charm — The Signet of the Old Kings | +20% Crit Chance; +100% Crit Damage; +20% Chance to Shred | Cannot crit, including Poison. Convert all-source uncapped Crit Chance at 2× to IAS; extra Crit Damage above a normal hit at 2× to Increased Physical Damage (D041–D044). |
| Charm — Lolzorz's Locket | +15 Base Physical Damage; +15 Base Elemental Damage; +15% Cooldown Reduction | “Critical hits have a 20% chance to reduce all cooldowns by 1 sec.” Includes Poison crits; one roll per packet, all running skill cooldowns, zero floor, no stored credit (D016/D048). |
| Trinket — Serpent's Coil | +15% Crit Chance; +15% Attack Speed; +10% Retrigger Chance | Natural/forced Poison can retrigger, including Decrepit's burst. Repeats consume no extra Poison, can retrigger again, and independently roll talent-gated crits (D020–D025). |
| Trinket — Wingjammer | +15 Base Physical Damage; +50% Increased Gold; +30% Crits Apply Penetration | Critical packets have 30% chance to grant one base Dash stack, including Poison and its repeats (D029–D031/D048). |
| Trinket — Mysterious Lucky Coin | +100% Crit Chance; +15% Cooldown Reduction | Double total Magic Find once: 150% → 300%, zero → zero (D051). Current-run pool unlock by destroying ordinary Lucky Coin, no immediate grant (D052–D054). |

## Shared event and formula contracts

### Retriggers, origins and normal scheduling

Accepted: all skill retriggers, including guarantees, grant Meditation. Poison retriggers also grant it. Exsanguinate repeats are repeated skills. Locket has no direct retrigger reward: repeats must crit to roll it. Cloak recursive Quick Cuts and Coil recursive Poison are accepted.

Technical reconciliation: distinguish random/guaranteed skill repeats, initial authored proc casts, Poison repeats and Exsanguinate repeats in trace. An initial Cloak Quick Cut is a triggered attack; its self-repeat is a retriggered attack that can activate Cloak. Poison and Exsanguinate Debuff repeats do not become attacks and cannot activate Cloak. Preserve normal build-resolved Quick Cut effects, including Precision, Footwork and Opportunity, rather than a damage-only clone. Shared skill IDs deduplicate unlocks; removal of gear prunes a macro entry only if no other source still unlocks it.

Current numeric chance is clamped to 100%, with one self-repeat candidate per source. A guaranteed repeat replaces that random candidate, not a second additional self-repeat. For Mithril apply local +0.50 to the two skills' roll, clamp effective probability as normal, and retain the original global stat for derivations. Over-100 chance does not imply multiple repeat charges. D068 explicitly retains depth 16 for recursive chain termination, including at 100% chance.

Existing triggered children have zero macro windup at the parent's timestamp, do not start new root cooldowns, and retain normal resource/effect/failure behavior. “Normal Quick Cut” preserves skill rules without converting an instant triggered child into a separately scheduled root. Existing normal depth-first ordering remains.

Current depth 16 terminates descendants, while 1,024 candidates per root invalidates an exhausted simulation; playback's visible-contact limit is separate. **D068 accepts retaining the depth-16 cutoff.** The 1,024-candidate guard remains a distinct technical failure path, not permission to count failed simulations as passes. T6 still qualifies branching combinations; do not introduce a new item-specific cutoff.

### Meditation and Dash

| Property | Meditation | Dash |
| --- | --- | --- |
| Grant | One base stack per qualifying repeat | One base stack on successful 30% critical-packet trial |
| Modifiers | Add All Stacks, then normal stack doubling, then remaining capacity | Same |
| Cap | Five | 20 |
| Strength | Separate physical multiplier `1 + 0.20 × stacks`; max ×2 | Additive IAS `0.05 × stacks`; max +100% |
| Lifetime | Shared three-second base scaled by T3 Buff Duration; refresh all on every grant, even at cap | Same |
| Crown | Mutually exclusive in helm slot | +10% IAS per stack; no duration/cap/grant change |

D026–D030/D063–D064 resolve these rules. Technical reconciliation: grant after the triggering operation completes, before later descendants, without retroactive damage changes; trace the grant order. Expire before equal-deadline reads under ordinary timer rules, with no extension of Footwork's special expiry exception. Reset fight-local state on cleanup. Retain T3 ceiling-to-millisecond scaling, finite arithmetic checks and no new duration cap.

### Critical packets and cooldown recovery

Locket and Wingjammer each roll once per eligible critical direct-hit or Poison damage packet, including repeats. Connected zero-damage crits qualify; dodges do not (D065). Poison needs its existing crit talent (D025); Signet prevents all crit output regardless of that talent (D044). Poison crits do not become direct-hit crit-to-Poison/Penetration/Potency applications: Wingjammer's Penetration affix still uses T3 direct-hit eligibility.

Technical reconciliation: deterministic hook order Locket then Wingjammer, with source/RNG/deadline trace. No roll without an eligible crit. Locket reduces **skill cooldown deadlines**, not buff durations, enemy timers, windup, Poison clock or macro cooldown-skip time. The root cooldown starts before damage in current code, so the root's own crit may reduce it. Proc children start no additional cooldown. Floor deadlines at current time, no negative stored credit; becoming ready does not execute a skill until the macro reaches it.

### Decrepit and Coil

Accepted Decrepit release: normal direct attack retained; replace the ordinary forced tick with one all-stack packet, consuming all actual current Poison once. Base expression is `resolved base elemental damage × actual stack count × (1 + applicable elemental increase)`; avoid applying an increase twice to already-derived values. One crit roll when the talent permits, not one roll per stack. **D068 resolves Q2/Q4:** retain normal Poison damage modifiers once (Resonance, Toxic Tradeoff, Virulent, Beguiling and negative-absorb contributions, ordinary conversion/mitigation), and treat the initial all-stack removal as keyword **Consume**, activating applicable consumption talents. **D071 resolves repeats:** each is a free Poison activation with a fresh standard damage calculation from live stats/buffs, spending Virulent charges normally if present, without requiring or consuming another Poison stack.

Technical reconciliation: preserve natural-tick-before-impact order, direct attack before forced activation, and later on-hit additions/cleanse. Empty fuel creates no damage/crit packet or item proc. Forced activations do not advance/reset the natural clock. Wyvern changes natural cadence, not instant repeat spacing or available fuel.

**D071 accepted:** each Poison retrigger is a free activation: no Poison-stack requirement or additional Poison consumption, but standard live damage calculation and normal Virulent charge spending. Do not freeze or copy the original raw damage, crit outcome or exhausted buff multiplier. Preserve the originating packet’s stack-count/fuel context for repeat size (including Decrepit’s actual all-stack count) rather than reread the now-empty enemy stack pool; reevaluate applicable live damage inputs and buffs for each repeat. A remaining Virulent charge contributes normally and is spent; subsequent repeats without it lose that instance’s multiplier. Each repeat still makes its own talent-enabled crit roll and can roll Locket/Wingjammer, and grants Meditation. No actual Poison Consume occurs again, so no repeated consumption-talent grant. Ordinary live mitigation/conversion applies; these are not direct-health-removal packets and do not acquire direct-hit status hooks.

Technical reconciliation for D068’s Consume: record actual positive stacks removed once, activate applicable consumption talents once, and preserve their existing eligibility restrictions. Death Pact receives actual consumed quantity rather than All Stacks/doubled damage counts. Do not reinterpret every tick or repeat as Consume, or invent a Touch of Darkness skill-specific grant for unrelated skills. Final ordering must trace burst damage, consumption and talent grants without retroactively applying newly granted debuffs to already-resolved damage. Suggested concise item wording: “Poison Strike Consumes all Poison stacks, dealing their Poison damage.”

### Exsanguinate

Accepted: **Debuff**, base cast **300 ms**, cooldown **8,000 ms**. Consume all Shred once and capture `health_removed = 2 × resolved Shred Value × actual stacks consumed`. Use full per-stack value regardless of enemy armor. Directly remove health, bypass all enemy mitigation, with no physical/elemental/general damage multiplier and no crit. No Death's Door/Meditation scaling or crit-driven Locket/Dash. Shred consumption never grants Death Pact (D034–D038).

Repeat the captured health-removal amount without consuming more Shred or requiring remaining stacks, recursively under normal repeat rules. This remains a repeated skill for Meditation, not an attack. Zero starting Shred yields zero removal; do not apply stack bonuses/doubling to consumed quantity. Restore armor after removing Shred, rather than retaining spent armor reduction.

Technical reconciliation: retain Debuff classification (current attack-only dodge/interrupt/counter hooks do not apply), ordinary CDR/timing and explicit effect validation. Approved technical default under D073: minimum cast time is 300 ms, matching the supplied base time; accepted as part of the final specification review. Current Debuffs use IAS/slow above their minimum; no new category-wide timing change. Add an explicit captured-amount repeat path, not a generic second Consume against an empty pool.

### Existing weapon integration

Umbral technical reconciliation: add `+actual_decay_count` into current Death Strike's `weapon roll + 2 × Poison + flat physical` raw base, before existing skill scaling and ordinary physical/crit/defense buckets. Read current counts at successful resolution, no new consumption or extra packet. Preserve stable `skill.killers_mark` and shared unlock ownership.

Bandit: floor and cap only its signature contribution first, then use the normal flat physical bucket. Recompute from current actual simulated stash changes without incrementally adding onto an already-derived bonus. +100 is not a final damage cap. All Stats does not automatically scale signature coefficients/cap. Gold/Gold Rewards affixes map to the existing Increased Gold stat, including normal rewards/theft; do not invent a new gold multiplier.

Bejeweled: retain the current ready-root scheduler path and 40% minimum-time draw; no new draws for instant children or cooldown-blocked slots. Wyvern retains existing cadence/fuel rules. Neither changes CDR or numeric Retrigger Chance.

### Signet, Crown and Magic Find

Accepted Signet: `IAS_added = 2 × uncapped_crit_chance`; `physical_increase_added = 2 × (resolved_crit_multiplier - 1)`. Include gear, talents, temporary buffs and live gold-derived contributions. Convert only the extra portion above a normal hit, including inherent extra crit damage. 150% crit chance → +300% IAS; ×2.5 crit damage → +300% Increased Physical Damage. Disable crit output after preserving conversion inputs.

Technical reconciliation: current early clamps must not discard accepted overcap inputs. Collect raw provenance, evaluate existing derivations once, convert once, then expose outputs and suppress crits. Rebuild on eligible buff/gold changes without cycles or double All Stats. Double Dip reads numeric **Retrigger Chance**, not IAS; no current Signet→IAS→Double Dip cycle exists. Mithril's local +50 points remain excluded. Side Step's Parry-local critical guarantee is an effective-hit override rather than a numeric Crit Chance source: approved technical reconciliation under D073 is to suppress the guarantee under Signet without creating +200% IAS from it. This is not a new ordinary stat source.

Crown additive strength: double the bonus from Dash, Bypass, Touch of Darkness and Beguiling Presence, not the final player stat. Keep active/passive scope; do not automatically include ordinary always-on gear stats or every passive talent as buff instances. Footwork's per-stack reduction is strength, but its normal skill minimum remains. Enemy-applied Penetration/Potency are debuffs, not self buffs. Charges, duration, caps, grants and activation chances stay unchanged; Wingjammer's 30% does not become 60%. **D070 accepted:** for a buff multiplier M, Crown gives `1 + 2 × (M - 1)`; ×2 becomes ×3. Double the bonus above baseline, not the baseline or entire multiplier. This applies to applicable multiplier-based buff strength without changing grants, caps or durations; remaining boolean/guaranteed effects have no extra scalar strength to double.

Coin: double resolved total Magic Find once before downstream consumers/display, including Fill Your Pockets, preserving existing floors/validation. Do not double each source and the total again. This does not introduce new rarity rolls under D062.

## Acquisition, persistence and mode contracts

Accepted: one Legendary per existing slot, no extra cap; equal weight per eligible identity after Legendary outcome, not equal slot weights. Exclude equipped/inventory-owned identities, restore eligibility after sale/destruction subject to unlock gates. Retain current shop rarity chances and all existing loot-roll/rarity rules (D055–D062). **D068 resolves Q5:** defer new generated-enemy Legendary outcomes to the later loot-system review. Shops and existing explicit authored Legendary rewards may use the eligible roster; ordinary generated enemy drops stay unchanged.

Destroying ordinary `gear.lucky_coin` from equipment or inventory unlocks Mysterious Lucky Coin pool eligibility for the **current run** only. Selling/unequipping does not. No immediate item grant, account achievement or permanent discovery. Repeated destruction is idempotent. Reset with a new run, retain across save/resume of that run. Practice access must not mutate Adventure unlocks.

Technical reconciliation: persist run-local flag with the run, default supported old saves to locked, validate candidates before replacing state, and document version/compatibility policy in T8 before implementation. Stable authored-ID reload must preserve fixed signatures; ordinary numeric inline serialization is insufficient. No unrelated player saves, legacy envelopes or real userdata are rewritten by specification work.

Retain existing storage/economy: shop buys enter inventory and require capacity; current reward auto-equip/overflow handling; current prices/resale/discount/reroll formulas. Empty eligible shop pool retains Cursed fallback. Pending offers retain generated identity, but ownership/unlock must be checked before claim so stale choices cannot grant duplicates; reject/refresh without charging or losing the reward. Do not silently reroll offers on unrelated build changes.

Practice: correct-slot fixed Legendary equip, read-only authored affixes, representative combinations and Coin testing independent of Adventure gate. Expose controlled missing attempts for Death's Door only in Practice's isolated state. Adventure retains current encounter failures/reset and opening unlimited-retry ×1. Existing terminal behavior stays; global lives and Alchemist upgrades are deferred.

## Review questions and current disposition

D068 resolves Q2, Q4, Q5 and Q6. D070 resolves Q1: Crown doubles the bonus above baseline (×2 → ×3). D071 resolves Q3: free repeat activations recalculate normal live damage and spend available Virulent charges, exempting only Poison-stack consumption. D069 resolves Q7 by reconfirming D050’s original Death’s Door table: 0/1/2/3 missing gives ×1/×2/×4/×6, formula `max(1, 2 × missing_attempts)`. Discard the conflicting `1 + 2 × missing` proposal. All design choices in this review are resolved. D073 approves the technical defaults and consolidated specification, resolving the T5 checkpoint. No prototype implementation is claimed; T6 is next.

| ID | Question | Source finding and recommendation |
| --- | --- | --- |
| **Q1 — Resolved D070** | Crown doubles the bonus: a ×2 damage buff becomes ×3. | User confirmed bonus doubling, `1 + 2 × (M - 1)`. Prior strength-only restrictions remain: no changed duration, stack caps, grants or charge counts. |
| **Q2 — Resolved D068** | Retain ordinary Poison modifiers on Decrepit’s burst. | User answered yes. Normal modifiers/conversion/defenses apply once, with all-stack fuel, one packet and accepted crit rules. |
| **Q3 — Resolved D071** | A free Poison activation recalculates standard damage with live stats/buffs and spends Virulent charges normally. | User explicitly requires no Poison-stack cost, not a frozen copy of damage. If a Virulent charge remains it contributes and is consumed; when exhausted its bonus no longer applies. Fresh crit rolls, normal retrigger recursion, depth 16 and no repeated Consume hooks remain. |
| **Q4 — Resolved D068** | Decrepit’s all-stack release is keyword Consume and activates applicable consumption talents. | User chose Consume wording and talent synergy, superseding the depletion/no-Pact recommendation. Apply hooks once for actual original consumption; repeats consume no extra stacks and cannot trigger those hooks again. |
| **Q5 — Resolved D068** | Defer new generated-enemy Legendary outcomes until later loot review. | User accepted deferral; preserve current loot rolls/rarity and do not add a drop route now. Existing authored Legendary rewards and shops use reviewed eligibility. |
| **Q6 — Resolved D068** | Retain the existing depth-16 recursive cutoff. | User explicitly selected depth 16. Candidate-budget failures remain separately qualified in T6; no new item-specific limit. |
| **Q7 — Resolved D069** | Death’s Door remains ×1 at zero missing, then ×2/×4/×6 for one/two/three missing. | User explicitly reconfirmed the original D050 table, `max(1, 2 × missing_attempts)`, rather than `1 + 2 × missing`. This does not answer Crown’s multiplier question. |

## Source checks and integration implications

| Current source | Concrete checked behavior |
| --- | --- |
| [CombatResolver](../project/scripts/systems/combat_resolver.gd), `_triggers_for_source`, `_resolve_retrigger_chain` | One numeric/guaranteed self-repeat candidate; chance clamp; zero-windup child events; depth 16 and 1,024-candidate safeguard. Exsanguinate and Poison repeats need explicit new eligibility paths. |
| Same resolver, root loop / `_finalize_cast_event` / `_resolve_poison_tick` | Root cooldown starts before damage; direct damage before forced Poison; additions/cleanse afterward; raw Poison modifiers, crit rolls, Virulent charge spend and depletion distinct from Consume. |
| Same resolver, Death Strike branch | Real weapon/Poison base and current skill factor, rather than stale generic resource fields. Umbral must change this path. |
| [CombatSelfBuffs](../project/scripts/systems/combat_self_buffs.gd) | Master of Poisons resistance-ignore boolean; Beguiling elemental/crit contributions; independent Virulent ×2 instances/five charges. D070/D071 resolve bonus strength and repeat-charge behavior; implementation must preserve independent instances and normal charge accounting. |
| [CombatStatState](../project/scripts/systems/combat_stat_state.gd), [StatSheet](../project/scripts/resources/stat_sheet.gd), [BuildResolver](../project/scripts/systems/build_resolver.gd) | Early Crit Chance clamps; explicit one-way derivations. Double Dip input is numeric retrigger, not IAS. Signet needs uncapped provenance and no-crit precedence. |
| [CombatGold](../project/scripts/systems/combat_gold.gd) | Live stash/theft crit sources enter later than ordinary build aggregation; include in Signet, recompute Bandit without double counting. |
| [CombatTiming](../project/scripts/systems/combat_timing.gd), [MacroScheduler](../project/scripts/systems/combat_macro_scheduler.gd) | Debuffs receive ordinary IAS/slow above minimum; Self Buff skills exclude IAS. Current cooldown deadlines and 100ms skips; no cooldown-reduction API for Locket yet. |
| [BuildState](../project/scripts/autoload/build_state.gd) | Current shop owned-ID exclusion/uniform choice/Cursed fallback; rewards do not share all those filters; destruction only removes gear; per-encounter failures, no run Coin unlock flag. |
| [ContractRouteGenerator](../project/scripts/systems/contract_route_generator/contract_route_generator.gd), [GearGenerator](../project/scripts/systems/gear_generator.gd) | Generated gear rewards do not reach Legendary; fixed catalog required and procedural Legendary rejected. D068 defers the new generated-enemy drop outcome to resolve the scope conflict. |
| [WeaponDamageCatalog](../project/scripts/systems/weapon_damage_catalog.gd), [LegendaryCatalog](../project/scripts/systems/legendary_catalog.gd), [TrainingRoomState](../project/scripts/systems/training_room_state.gd) | Tier-based 21–27 baseline; currently five fixed weapons; Practice fixed Legendary equip assumes Weapon. Slot-aware catalog/UI/save work remains. |

No claim is made that these new contracts are implemented. Most require combat, catalog, Practice, source-inspector and save work in T6–T9. The code audit is source inspection, not fresh gameplay evidence.

## Validation plan and completion gate

| Representative witness | Required evidence / owner |
| --- | --- |
| Mithril + Samurai + Cloak + Locket + Wingjammer | Local chance excluded from Double Dip; guaranteed candidate deduplication; build-resolved Quick Cut effects; recursive origin/RNG traces; Meditation/Dash grants/timing; Locket own-cooldown reduction; high-chance cutoff/candidate qualification. T6/T10. |
| Decrepit + Coil; Wyvern + Coil | One all-stack packet/consumption, no second fuel, independently rolled crits, Q2–Q4 outcomes, zero fuel, conversion/defenses, modifier/charge basis, Locket/Dash/Med hooks and natural clock. T6/T10. |
| Nightkiss / Exsanguinate | Actual stack/value capture, armor restoration, repeated identical removal, zero fuel, no mitigation/crit/damage bonuses/Pact, Debuff timing, Meditation on repeats. T6. |
| Crown families | Q1 multiplier rule, unchanged charges/grants/caps/timers/activation chance, additive strength, independent instance expiry and minimum cast times. T6; actual-size descriptions/icons T9. |
| Signet + Coin / gold and buff sources | Overcap and inherent extra crit inputs, dynamic expiration/theft, no-crit override including Side Step, one-way conversions and MF ×2 before downstream consumers. T6. |
| Death's Door | Current attempt multiplier, Poison included/Exsanguinate excluded, next-encounter reset, unlimited opening ×1, no post-terminal fight, controlled Practice states. T6/T8. |
| Acquisition / Coin / save | Unchanged rarity/RNG rules, uniform eligible IDs, owned filters, fallback/pending offers, both destruction paths/no immediate grant, run save/resume/new-run reset, supported-old-save policy, multi-slot equip and unlock ownership. T8; Q5 limits drop claims. |
| Combined economy | Existing discount/resale witness, live capped gold scaling, legal generated alternatives, earned timing/counters. T10/T11; full earned runs M9, broad exports/teardown M10. |

- [x] All 16 supplied items and accepted rules through D071 consolidated.
- [x] Superseded proposals separated from current contracts; historical workbook preserved.
- [x] Remaining details checked against source and independently reviewed; six material questions isolated.
- [x] All Q1–Q7 answered and incorporated.
- [x] Final source-specific technical defaults and consolidated specification approved by the user under D073.
- [x] T5 checkpoint accepted under D073; T6 prototypes and their review checkpoint follow.

Documentation/source review verification: all 16 roster rows and 7/2/2/2/3 slot counts checked; D010–D066 preserved in the archive; D010–D071 tracker entries unique; Q1–Q7 resolved; D073 user approval and T5 Complete status verified; local Markdown targets and referenced source symbols checked. [Verification record and checked-source hashes](../work/m8_t5_consolidation/verification.json) records the source snapshot and limits. No gameplay tests or UI renders were needed for this documentation change. Artwork, runtime resources, real player saves and sibling Enigma remain untouched.
