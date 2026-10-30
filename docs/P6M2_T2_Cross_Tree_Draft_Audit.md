# P6M2-T2 Cross-Tree Draft Audit

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

Date: 2026-09-21. Status: Complete as an audit; design decisions remain open.

This audits the four collected drafts against the current FacelessVoid runtime.
It does not approve draft values, change gameplay, repair the source exports, or
complete T3–T5. The [M2 tracker](P6M2_Build_Model_And_Progression_Foundations_Tracker.md)
owns follow-up. The [generated inventory appendix](P6M2_T2_Draft_Inventory_Appendix.md)
preserves every original object, identifier, description, rank value, prerequisite,
gate, skill grant, intrinsic, automatic slot, icon ID, and JSON pointer.

## Audited revision and method

Runtime checkout HEAD: `1222e1c263df8dd173dd8d571a6134e79b5e69b2`.
The checkout already contained uncommitted Phase 6 planning, draft collection,
and Tree Lab documentation organization. These were retained. The source exports
were read from `docs/talent_tree_drafts/`, following that folder's provenance README.

| Draft | SHA-256 | Talents / rank slots | Talent skill grants | Populated automatic slots | Prerequisite links |
| --- | --- | --- | --- | --- | --- |
| Assassin | `7c70b4c80ccf089e9b0f8069db7827ffa8c703b52a4fbf1ce48111e80b8081bd` | 10 / 35 | 1 | 5 | 2 |
| Bladedancer | `f70eebc8a15db7780aa062795c82978c2db48721b5ff06a0c8889ddb2b7a9b6c` | 13 / 35 | 1 | 4 | 3 |
| Shadow | `4475e00e6fa0a544143a956b646d88a8e4582f64fd785e7e04af9bff5fe68171` | 11 / 35 | 0 | 5 | 3 |
| Thief | `029ea87fd1c31f6251c7d9b8024de9a58134e3f6c5fe4cf28a8cbd1b00fdebaf` | 10 / 35 | 0 | 4 | 1 |

Total: **44 talents, 140 rank slots, four intrinsics, 20 automatic slots
(18 populated, two blank), and two talent-granted skills**. There are 20 populated
skill records overall. All four files declare `faceless-void.tree-lab`, schema version 1.

All trees specify level gates **0, 5, 10, 15, 20** and automatic thresholds
**1, 3, 6, 9, 12**. No per-rank point-cost field or point-income schedule is authored.
Tree Lab treats each rank as one point, prerequisites as at least one rank in every
listed predecessor, and values as `rank_1 + (rank - 1) * per_rank`. These are preview
conventions, not approved game rules. All nodes are reachable under that unlimited-budget
preview; this says nothing about Adventure pacing or mixed-tree legality.

## Principal findings

- Static stats, ordinary skill grants, poison/shred/decay application, Quick Cut →
  Rending Slash, and Steal-on-crit provide substantial reusable foundations.
- Every tree needs ranked allocation, investment gates, per-point intrinsics,
  automatic unlocks, and persistence extensions. Adventure and Practice Room currently
  cap at 10 points; gates at 15/20 and unlocks at 12 cannot be reached under those budgets.
- Timed player buffs, charge consumption, cooldowns, conditional rotation eligibility,
  and explicit consumable Decay state are shared-system work. Existing proc and stat
  hooks do not implement those behaviors on their own.
- Copied entity IDs collide across Assassin and Bladedancer. Labels and IDs sometimes
  describe different mechanics. Conversion must use explicit mappings and approved
  semantics, not names, labels, or UUIDs as executable instructions.
- Guaranteed retriggers in Precision Attacks and Dance of Death require an explicit
  interpretation alongside the existing below-100% normal-build watch item.
- Actual saves use tree/talent **resource paths** and rotation **skill IDs**. Preserving
  IDs alone is insufficient when moving/removing resources.

## Runtime evidence key

References below name inspected functions or fields so they remain usable after line shifts.
An absent feature means absent from these relevant runtime paths, not a claim about every file.

| Key | Inspected source and supported behavior |
| --- | --- |
| R1 | [Talent](../project/scripts/resources/talent.gd), [SubclassTree](../project/scripts/resources/subclass_tree.gd), [PassiveAllocator](../project/scripts/systems/passive_allocator.gd): binary selections, one `cost`, AND across prerequisite groups / OR within each group, two selected trees, dependency-blocked removal. No ranks, investment gates, or automatic threshold track. Default allocator budget is 7; callers can override it. |
| R2 | [BuildResolver](../project/scripts/systems/build_resolver.gd): `resolve_stats`, `_apply_canonical_modifier`, `_apply_all_stack_bonus`, `_apply_special_modifier`; static tree/talent/gear modifiers, distinct gear/talent damage buckets, gold multipliers, Bonus Stacks, fixed special cap 40. Selected tree innates apply equally; no main-only per-point formula. |
| R3 | [BuildResolver](../project/scripts/systems/build_resolver.gd): `resolve_unlocked_skills`, `_apply_skill_augment`, `resolve_rotation`; cloned/deduplicated skill grants, tree-owned additive poison/effect augments, filtering to available skills, 10 rotation slots. Talent has no skill-augment field. |
| R4 | [Skill](../project/scripts/resources/skill.gd), [SkillAugment](../project/scripts/resources/skill_augment.gd), [TriggeredSkillEffect](../project/scripts/resources/triggered_skill_effect.gd): cast times and effect arrays; source-skill filtering and chance. No cooldown, charge, conditional availability, or timed player-effect resource contract here. |
| R5 | [CombatResolver](../project/scripts/systems/combat_resolver.gd): `resolve`, `_resolve_poison_tick`; poison interval computed at fight start, shared timer, one stack consumed per active tick, noncritical poison packet, scheduled ticks processed before same-time cast completion. No forced-tick skill effect or attack-speed-linked dynamic tick schedule. |
| R6 | [CombatResolver](../project/scripts/systems/combat_resolver.gd): `_triggers_for_source`, `_resolve_retrigger_chain`, `_apply_skill_effects`; recursive immediate proc casts, fresh weapon/crit rolls, source filtering, chain depth cap 16. Cast/crit/poison/shred/decay/gold events exist, but no general event-subscription system for consumption or poison-applied triggers. |
| R7 | [CombatResolver](../project/scripts/systems/combat_resolver.gd): `_apply_decay_stacks`, `_apply_shred_stack_total`, `_finalize_cast_event`; poison and shred counts, multiplicatively reduced resistance and per-event Decay applications. No authoritative live consumable Decay count. Cleanse resets poison, shred/armor, and resistance together unless globally denied. |
| R8 | [DamageCalculator](../project/scripts/systems/damage_calculator.gd): `resolve_damage_packet`; physical crit/armor/block and magical resistance/absorb paths, conversion and ignore flags. Resolver denial helpers support full defense denial, not draft-specific flat/percentage penetration or temporary/selective immunity. Existing damage-type conversion is not stat-bonus conversion. |
| R9 | [CombatResolver](../project/scripts/systems/combat_resolver.gd): `_apply_skill_effects`; [Steal resource](../project/data/skills/steal.tres): Steal already steals 3 gold on its crits, multiplied/floored by Increased Gold. Fight-local stolen gold and simulated current gold feed existing crit scaling; no per-talent caps 25/50/75 or 500. |
| R10 | [BuildState](../project/scripts/autoload/build_state.gd): `TALENT_POINT_CAP = 10`, talent selection/refund, secondary tree choice, `modified_gold_reward`, `current_shop_discount`, `current_magic_find`, rewards/shop/Overkill Gold. [TrainingRoomState](../project/scripts/systems/training_room_state.gd): `PRACTICE_TALENT_POINT_BUDGET = 10`, tree slots, binary talent selection and filtered rotation. |
| R11 | [SaveSystem](../project/scripts/systems/save_system.gd): `_serialize`, `_deserialize`, `SAVE_VERSION = 1`; resource paths for trees/talents, skill IDs for rotation, no allocation-rank map. Missing selected resources fail load. Combat is resolved synchronously; saved FIGHTING normalizes to PLANNING. |
| R12 | [Talent panel](../project/scenes/combat/talent_panel.gd): prerequisite-depth layout, cost circles and binary toggle; [SkillTooltipFormatter](../project/scripts/ui/skill_tooltip_formatter.gd): known effect summaries; [CombatRecap](../project/scripts/systems/combat_recap.gd): cast/tick totals and peak poison inferred with `stacks_remaining + 1`. Resolver `TickEvent` has no crit/consumption-source fields; no generic buff lifecycle events in `CombatResult`. |

## Per-element mechanics and presentation inventory

**R = reuse** an existing behavior/resource after content conversion; **E = extension**
to an existing system; **N = new shared behavior/state**. **U** marks unresolved semantics.
R does not mean the entire ranked node or skill is already implemented. All talents
also depend on R1/R2 rank/gate work; all automatic unlocks on R3 threshold work.
IDs such as A-T01 identify exact objects in the appendix in original array order.
Question IDs Q01–Q20 below have explicit owners. Numerical ranges are draft displayed
rank totals, not balance recommendations. All new skills also need Q09's execution contract.

### Assassin

| Record | Draft behavior | Support / evidence | Open detail and presentation |
| --- | --- | --- | --- |
| A-I | Base +5 elemental damage; Main +1 increased elemental damage per invested point | E/U R2 | Flat versus percent and primary-only split; structured base/per_point combines the two. Show base/main separately. Q02, Q04. |
| A-T01 Quick Hands | Five ranks, +1–5% attack speed | R R2 | Rank total and next-rank preview. Q01, Q04. |
| A-T02 Precision | Five ranks, +1–5 percentage points crit | R R2 | Display percentage points and resolved crit cap. Q04. |
| A-T03 Hastened Poison | Five ranks, 10–50% of attack speed increases poison tick rate | E/U R5 | Rate versus interval formula; dynamic buffs, suppress and minimum interval. Show effective cadence. Q05. |
| A-T04 Echoing Toxin | Three ranks, consume two poison per tick, +10/20/30% damage | E/U R5 | One-stack remainder behavior and multiplier base. Show actual stacks consumed. Q06. |
| A-T05 Poison Strike | One rank grants skill whose hits cause poison ticks | E/U R3/R5 | Existing skill applies poison; forced ticks are new behavior, not just renaming. Trigger count and hit eligibility. Q06, Q09. |
| A-T06 Bypass | Stab grants Bypass for 3 seconds, max 3; x10% elemental per stack, x30% total | N/U R4/R6 | Stacking totals imply 1.30, not 1.1 cubed; refresh/expiry and successful-hit requirement unknown. Buff count/timer. Q04, Q07. |
| A-T07 Toxic Tradeoff | Five ranks, +20–100% poison and -10–50% physical | R/U R2 | Poison-only versus shared elemental bucket; additive/multiplicative penalty. Both sides in preview. Q04. |
| A-T08 Accelerant | Five ranks, +10–50% additional IAS scaling; requires Hastened Poison | E/U R5 | Add to or multiply earlier scaling; predecessor rank requirement. Q01, Q05. |
| A-T09 Resonance | Four ranks, consume three poison, +20–80% tick damage; requires Echoing Toxin | E/U R5 | Replace versus add to two-stack consumption and earlier damage bonus. Q06. |
| A-T10 Critical Poison | One rank; ticks use player crit chance and crit damage | E/U R5/R8 | Tick RNG, negation, gold-derived crit, and crit-procs need policy. Crit marker and damage source. Q06, Q11. |
| A-U1 Venom Jab, 1 point | Apply five poison | R R3/R6 | Existing Venom Jab applies eight stacks; draft changes this to five. Preserve or revise direct hit/cast time explicitly. Stack tooltip. Q09, Q14. |
| A-U2 Blinding Powder, 3 points | Poison ignores Assassin Level absorb; value base 0 +1/point | E/U R8 | Active or passive, duration, tree-point definition, flat penetration and conversion interaction. Q02, Q09, Q13. |
| A-U3 Virulent Poison, 6 points | Next five poison ticks deal 2x damage | N/U R4/R5 | Charge-based buff; empty/forced ticks and refresh policy. Remaining charges. Q06, Q07, Q09. |
| A-U4 Master of Poisons, 9 points | Elemental damage ignores resistance for five seconds | N/E R4/R8 | Timed ignore flag; snapshot versus live damage and cooldown unspecified. Timer/active state. Q07, Q09, Q13. |
| A-U5 Poison Vile, 12 points | Apply 20 poison | R/U R3/R6 | Application primitive exists; new skill contract and cap/Bonus Stacks behavior needed. Preserve spelling until T4. Q09, Q14, Q16. |

### Bladedancer

| Record | Draft behavior | Support / evidence | Open detail and presentation |
| --- | --- | --- | --- |
| B-I | Base 5% retrigger; Main +0.2% per point | E/U R2 | Role-sensitive scaling and cap. Main/secondary preview. Q02, Q10. |
| B-T01 Weakness | Five ranks, +5–25 armor shred | R/U R2 | Interpret as Shred Value, not stacks; value ID incorrectly says `ias`. Q04, Q16. |
| B-T02 Whetstone | Five ranks, +1–5 base physical | R R2 | Value ID says `crit`; correct through approved mapping. Q16. |
| B-T03 Opportunity | Three ranks, Quick Cut → Rending Slash chance 10/20/30%; requires Rending Slash | R R6 | Existing Opportunity Strikes hook fits; retain source/chain rules intentionally. Proc chance/source tooltip. Q10. |
| B-T04 Virulent Corruption | +100 shred value, +2 shred stacks, shred cannot be cleansed | R + E R2/R7 | Static bonuses reusable; selective immunity is missing. Show immunity without implying poison/Decay immunity. Q12, Q14. |
| B-T05 Rending Slash | One rank; unlock skill applying two shred | R R3/R6 | Existing skill behavior; damage/timing details omitted. Q09, Q16. |
| B-T06 Fancy Footwork | Five ranks; Quick Cut builds Footwork, max 5, 3 seconds; Leaping Plunge consumes all for 10–50% attack speed | N/U R4/R6 | Per-stack versus total speed, consuming cast versus later buff, when cast duration is calculated. Stack/timer and predicted Plunge time. Q07, Q08. |
| B-T07 Precision Attacks | Quick Cut grants Precision; next Stab or Heavy Strike consumes one for guaranteed retrigger | N/E/U R6 | Stack cap/lifetime absent; alias Heavy Strike; distinguish one guaranteed repeat from guaranteed chain. Charge/readiness cue. Q07, Q10, Q16. |
| B-T08 Double Dip | Two ranks; 50/100% of retrigger chance also grants crit chance | E/U R2 | Derived stat pass after gear; whether temporary guarantees count. Show source and derived crit. Q04, Q10. |
| B-T09 Sharpened Edge | Five ranks, +20–100% Stab/Heavy Strike damage; requires Precision Attacks | E/U R3/R6 | No skill-specific damage multiplier augment; do not add a second hit packet. Q04, Q16. |
| B-T10 Cloak & Dagger | Two ranks, +50/100% crit damage | R/U R2 | Additive bonus versus multiplier wording. Q04. |
| B-T11 Riposte | Two ranks; Footwork gives Plunge +10/20% damage per stack; requires Fancy Footwork | N/E R4/R6 | Snapshot same stacks before consumption and order with speed benefit. Preview consumed count and bonus. Q07, Q08. |
| B-T12 Side Step | Parry Strike has 100% crit chance | E R6/R8 | Per-skill override, not global crit; enemy negation still needs explicit treatment. Q09, Q11. |
| B-T13 Weapon Master | Two ranks, +50/100% all physical damage | R/U R2 | Damage bucket and conversion semantics. Q04. |
| B-U1 Quick Cut, 1 point | Fast, low-damage, high-DPS attack | R/U R3/R6 | Existing skill candidate, but no approved numbers; copied ID names Venom Jab. Q09, Q16. |
| B-U2 Leaping Plunge, 3 points | Long windup, high damage | R + N/E R4 | Ordinary attack data reusable; Footwork consumption changes scheduling. Windup and empowered preview. Q08, Q09. |
| B-U3 Parry Strike, 6 points | Very fast; usable only after a retriggered attack | N/U R4/R6 | Eligibility window, proc versus self-retrigger, skip/wait/fallback when unavailable. Readiness cue. Q08, Q10. |
| B-U4 Unassigned, 9 points | Null skill, empty values | U | Retain as unassigned design slot; no runtime skill inferred. Q17. |
| B-U5 Dance of Death, 12 points | Five seconds; first hit of any skill has 100% retrigger, 20-second cooldown | N/E/U R4/R6 | First hit per cast/skill/window; exclude or include proc casts; nonattacks and guaranteed-repeat policy. Duration/cooldown. Q07–Q10. |

### Shadow

| Record | Draft behavior | Support / evidence | Open detail and presentation |
| --- | --- | --- | --- |
| S-I | 20% crit-to-poison chance +2% per point | E/U R2/R6 | Existing chance hook, new scaling; primary/secondary treatment unspecified. Q02, Q11. |
| S-T01 Umbral Presence | Poison cap 80 | E R2/R7 | Runtime cap field supports values; authored special currently fixes 40. Cap precedence with gear. Q14. |
| S-T02 Coated Weapons | Stab/Heavy Slash apply one poison | E R3 | Existing Shadow tree augment must become talent-controlled. Tooltip updates on allocation/refund. Q03, Q14. |
| S-T03 Blind Spot | Five ranks, +2–10% crit | R/U R2 | Percent versus percentage points. Q04. |
| S-T04 Snake Oil | Four ranks, +2/4/6/8 base elemental | R R2 | Resolved base and rank preview. Q04. |
| S-T05 Death Touch | Three ranks, +2/4/6 to all stacks applied | R/U R2/R7 | Existing Bonus Stacks covers poison/shred/Decay, not player buff stacks. Scope must be explicit. Q14. |
| S-T06 Dusk Strike | Applying Decay also applies shred | R/U R2/R7 | Existing same-count mirroring fits if intended; avoid reapplying bonus stacks to mirrored total. Q12, Q14. |
| S-T07 Shadow Mastery | Five ranks, convert 10–50% elemental damage bonuses to physical; requires Deception | E/U R2/R8 | Copy versus transfer; base/percent/gear/talent/buff sources; not damage-type conversion. Derived stat explanation. Q04. |
| S-T08 Deception | Five ranks, +10–50% elemental; requires Snake Oil | R/U R2 | Buckets and prerequisite rank. Q01, Q04. |
| S-T09 Death from the Shadows | Five ranks, +20–100% crit damage | R/U R2 | Additive versus multiplicative. Q04. |
| S-T10 Death Pact | Poison/Decay consumption grants equal Pact stacks; each ignores one block or absorb; three ranks of timer value 2/4/6 with unit `%` | N/U R4/R7/R8 | Timer unit contradictory; passive tick consumption eligible? Cap, refresh, flat penetration and stack spending unknown. Buff count/timer/penetration. Q06, Q07, Q12, Q13. |
| S-T11 Death Blade | Stab stops applying poison; poison application has 10/20% chance to trigger Stab; requires Coated Weapons | N/E/U R3/R6 | General poison-event trigger and suppression needed; does suppression include crit/gear poison? Loop risk. Proc provenance. Q10, Q11, Q14. |
| S-U1 Beguiling Strike, 1 point | Apply one Decay | R R3/R7 | Existing skill uses internal `skill.toxic_flurry`; full attack contract omitted. Q09, Q16. |
| S-U2 Death Strike, 3 points | Adds poison-stack damage | R/U R6 | Existing `skill.killers_mark` uses pre-hit poison count, does not consume it; wording doesn't approve a new formula. Stack contribution tooltip. Q09, Q12, Q16. |
| S-U3 Distilled Corruption, 6 points | Physical hit; convert up to five Decay to poison | N/E/U R7 | Explicit Decay count/removal, ratio, resistance restoration, application order and Bonus Stacks. Consumption/conversion event. Q12, Q14. |
| S-U4 Touch of Darkness, 9 points | Consume all poison; +10% attack speed per consumed stack for eight seconds; 30-second cooldown | N R4/R5/R7 | At 80 stacks this suggests +800% IAS before other effects; audit risk, not approved power. Consumption timing and caps. Buff amount/duration/cooldown. Q05, Q07–Q09, Q18. |
| S-U5 Beguiling Presence, 12 points | Consume all Decay; +1 base elemental per stack for ten seconds; 30-second cooldown | N R4/R7 | Decay accounting and buff snapshot/refresh. Show consumed count, granted stat, time. Q07, Q09, Q12. |

### Thief

| Record | Draft behavior | Support / evidence | Open detail and presentation |
| --- | --- | --- | --- |
| T-I | 10% extra gold +2% per point | E/U R2/R9 | Main/secondary split and whether extra gold means Increased Gold bucket. Show affected sources. Q02, Q15. |
| T-T01 Gilded Blade | +1% crit damage per stash gold, capped at 500 | E/U R9 | Existing current-gold scalar is uncapped; cap gold input versus bonus, starting/current stash semantics. Cap progress. Q15. |
| T-T02 Keen Eye | Five ranks, +2–10% all damage (physical and elemental value entries) | R/U R2 | Two bucket modifiers available; all-damage scope after conversions. Q04. |
| T-T03 Sticky Fingers | Five ranks, +10–50% Increased Gold | R/U R2/R9 | Preserve or revise multiplying talent/gear buckets intentionally. Reward and steal examples. Q04, Q15. |
| T-T04 Silvered Edge | +1% crit per stolen gold, rank caps 25/50/75% | E/U R9 | Fight-local baseline exists; cap contribution versus final chance and pre/post-multiplier gold. Q15. |
| T-T05 Fast Hands | Five ranks; 10–50% of Increased Gold becomes attack speed | E/U R2 | Derivation after final gold aggregation; percentage conversion and temporary updates. Source/derived values. Q04, Q15. |
| T-T06 Fill Your Pockets | Five ranks; 20–100% of Magic Find becomes elemental damage | E/U R2 | Flat versus percentage elemental; consumes or copies stat; gear sources. Q04, Q15. |
| T-T07 Charisma | Three ranks, +10/20/30% Shop Discount | R R2/R10 | Value label empty; aggregate with gear and current price floor. Shop/build preview. Q15, Q16. |
| T-T08 Load Dice | Three ranks, +100/200/300% Magic Find; requires Charisma | R/U R2/R10 | Stat exists; power/economy effect and Fill Your Pockets interaction need testing. Q15, Q18. |
| T-T09 Bribery | Stealing gold applies 2/4/6 shred | E/U R6/R9 | Event-based trigger on actual gold gain; per steal versus per gold, failed/zero steals. Shred source reporting. Q14, Q15. |
| T-T10 Finders Keepers | Two ranks, ignore 50/100% block | E R8 | Full denial primitive exists; partial block reduction and converted attacks need policy. Mitigation tooltip. Q13. |
| T-U1 Steal, 1 point | Crits steal three gold | R/U R3/R9 | Fits existing Steal skill if local to its crits; could be read as global passive. Q09, Q15. |
| T-U2 Mug, 3 points | Add stolen gold as base physical, cap 100 | E/U R6/R9 | Attack-only versus global bonus, gold scope and weapon scaling order. Show capped contribution. Q09, Q15. |
| T-U3 Pick pocket, 6 points | Low damage, steals 20 gold | E/U R9 | Existing steal effect is crit-only; unconditional steal needs extension or clarified requirement. Q09, Q15. |
| T-U4 Unassigned, 9 points | Null skill, empty values | U | Preserve empty slot without inventing content. Q17. |
| T-U5 Big Score, 12 points | Physical attack with 2x crit damage | E/U R6/R8 | Double entire crit multiplier versus bonus portion; doesn't explicitly guarantee crit. Skill-specific override. Q09, Q11, Q15. |

## Content integrity and compatibility findings

Six cross-file entity-ID collisions are enumerated in the appendix: the shared
`draft.assassin` tree ID; four talent IDs (`quick_hands`, `precision`, `bypass`,
`critical_poison`); and `draft.skill.venom_jab` used for both Venom Jab and Quick Cut.
Each export passes the repository's per-file validator because cross-file identity
is outside that check. Repeated `level.*`/`unlock.*` IDs are local structural IDs;
their repetition alone is not a defect.

Further Q16 inputs:

- Shadow's `subclass` is empty. UUID-style IDs are valid opaque authoring identifiers,
  but do not establish runtime mappings.
- Bladedancer Weakness's value ID is `ias`, Whetstone's is `crit`, and its retrigger
  intrinsic value ID is `poison_per_point`. Assassin intrinsic also retains a
  poison-oriented value ID while its text says elemental. These IDs cannot select mechanics.
- Assassin notes claim its fifth automatic slot is blank, but Poison Vile occupies it.
  Preserve both source facts; current structured slot content is inventoried, not silently deleted.
- Death Pact's timer uses `%`; Charisma's value label is empty; Beguiling Presence has
  trailing whitespace. Heavy Strike versus existing Heavy Slash needs confirmation.
  Names such as Poison Vile, Load Dice, and Pick pocket are preserved verbatim.
  Whetstone reflects the user-approved 2026-10-01 spelling correction; its ID is unchanged.
- All icon IDs pass the current catalog check, including `placeholder`. Reused icons
  often depict unrelated skills. A valid reference is not approved final art.
- Runtime Rending Slash is `skill.rending_thrust`, Beguiling Strike is `skill.toxic_flurry`,
  and Death Strike is `skill.killers_mark`. Existing Assassin Quick Hands draft ID also
  resembles the current Bladedancer talent identity. Build an explicit old-path/old-ID →
  approved-content mapping; do not infer equivalence from spelling.
- Drafts omit executable effect types, damage coefficients, most timing values, point
  costs, primary/secondary rules, migration rules, and a content revision field distinct
  from schema version. T4 must define authority and validation beyond Tree Lab schema.

## Cross-tree and gear interaction review

All six two-tree pairings need representative coverage. This table identifies
specific interactions, without selecting the M4 build or authorizing all draft mechanics.

| Pair / shared surface | Interaction to specify and later test | Owner |
| --- | --- | --- |
| Assassin + Bladedancer | Quick Hands/Footwork-derived speed and Hastened Poison; Double Dip crit with Critical Poison; repeated Poison Strike forced ticks under guaranteed retriggers. | T5 → M3/M5 |
| Assassin + Shadow | 80-stack cap and Bonus Stacks feed faster/multi-consumption/critical poison; Death Pact on natural versus forced ticks; Death Blade recursion; Touch of Darkness competes for poison fuel and may accelerate ticks. | T5 → M3/M5/M6 |
| Assassin + Thief | Gold-derived crit and crit damage may affect Critical Poison; Magic Find → elemental and Increased Gold → speed amplify poison; gold scope must match tooltips. | T5 → M3/M5/M6 |
| Bladedancer + Shadow | Decay → shred with cleanse immunity, Bonus Stacks and +100 shred; triggered Stab generates poison unless suppressed; elemental-bonus conversion plus physical multipliers. | T5 → M3/M5 |
| Bladedancer + Thief | Retriggered steals increase gold, crit and Bribery shred; Double Dip and Silvered Edge cap ordering; Big Score with Gilded Blade and guaranteed repeats. | T5 → M3/M5/M6 |
| Shadow + Thief | Poison-producing crits, Death Blade triggered attacks, stolen-gold crit feedback; Death Pact and percentage block ignore; Magic Find elemental bonus passed to Shadow Mastery. | T5 → M3/M5 |
| Bonus Stacks / doubling / caps | Existing Bonus Stacks affects poison, shred and Decay. Decide whether Death Touch extends to Bypass, Precision, Footwork or Pact; avoid applying bonuses twice to mirrored/converted stacks; specify capped excess and consumed actual count. | Q14 → M3/M5 |
| Gear retrigger and triggered skills | Keep random retrigger probability, guaranteed repeat eligibility, proc origin and recursion limits separate. Depth 16 bounds depth, not total branching event count. Define a deterministic event budget if needed. | Q10 → M3 |
| Gear damage conversion / denial | Existing conversion chooses mitigation paths; stat conversion changes bonuses. Resolve their ordering, partial penetration, enemy crit-negation, and overlapping full defense-denial gear. | Q04/Q11/Q13 → M3/M5 |
| Enemy cleanse/suppress/slow/interrupt/dodge | Determine whether missed/interrupted/blocked casts generate buffs or consume charges; selective cleanse must preserve only approved statuses; expiration at equal timestamps must be deterministic. | Q05/Q07/Q08/Q12 → M3 |
| Thief rewards and shopping | Track base versus multiplied/floored steals, starting/current stash and fight-local gold, reward and Overkill Gold, spending, discount floors, Magic Find reward effects, and reset/retry semantics. | Q15 → T3/M3/M5/M6 |

## Question register and downstream ownership

All entries are **Open**. They are audit outputs, not blockers to finishing T2.
T3/T4/T5 own decisions assigned to them; M3 must settle detailed execution rules
before implementing affected mechanics. M5 supplies complete skill content and M6
validates tuning. No user answer was required to inventory the supplied revisions.

| ID | Decision needed | Owner / required before |
| --- | --- | --- |
| Q01 | Point income, maximum budget, per-rank costs, 0/5/10/15/20 gates, whether gates use own-tree spend, predecessor minimum/full rank, and whether level means row or investment. | T3 → T6 |
| Q02 | Main versus secondary availability, base intrinsic at zero investment, which per-point terms are main-only, secondary unlock access and tree count/opportunity cost. | T3 → T6 |
| Q03 | Refund/respec availability and cost; reject invalid refunds or cascade; effects on gates, intrinsics, skill removal and rotation restoration; tree switching in Practice Room. | T3 with T4 → T6/T7 |
| Q04 | Canonical units/buckets, totals versus per-rank accumulation, positive/negative percent semantics, poison versus elemental, derived-stat order, conversion copy versus transfer, and snapshot/live recalculation. | T3 foundational meanings; T5 routes combat portions to M3 |
| Q05 | IAS-to-poison-rate formula, Accelerant combination, temporary IAS changes, suppress, minimum interval, timer phase preservation and same-time order. | M3 via T5 |
| Q06 | Multi-stack tick damage formula, remainder/zero-stack behavior, natural versus forced ticks, Virulent charge use, crit RNG and consumption events. | M3 via T5 |
| Q07 | Each buff's trigger, duration/charges, caps, per-stack/shared timers, refresh/replace, consumption, snapshot, expiration ties, cleanse/reset/between-fight behavior; correct Death Pact timer unit. | M3 via T5; unresolved text returned to content owner |
| Q08 | Automatic rotation versus new player decisions, cooldown/eligibility skip or wait, repeat slots, windup snapshot, resource consumption time, and Parry Strike window. | T3 intended decisions; T5 complexity/UI requirements; M3 execution |
| Q09 | For every skill: active/passive identity, direct-hit presence, damage/weapon scaling, base/min cast time, cooldown/start timing, target, proc/crit/dodge eligibility and zero-resource usability. Inherit existing values only explicitly. | T5 contract inventory → M3 mechanics / M5 content |
| Q10 | Guaranteed single repeat versus 100% recursive chance; Dance first-hit meaning; qualifying trigger origins, Precision limits, Parry unlock, proc ordering and total-event safeguards. Resolve relation to normal-build below-100% watch. | T3 policy boundary; M3 detailed execution |
| Q11 | Per-skill/tick crit calculation, crit negation, derived gold crit, proc-on-crit eligibility and Death Blade's suppression of every poison source from Stab. | M3 via T5 |
| Q12 | Explicit Decay stack representation, partial removal and resistance restoration (including zero base resistance), conversion ratio/order, what counts as consumption and selective cleanse persistence. | M3 via T5 |
| Q13 | Flat versus proportional defense penetration, block/absorb choice, cumulative caps, converted packets, full-denial overlap, and temporary resistance ignore. | M3 via T5 |
| Q14 | Which stacks receive Bonus Stacks/doubling, when caps apply, whether conversion creates new applications, mirror amounts, actual versus attempted applications and consumed quantities. | M3 via T5 |
| Q15 | Gold scopes and caps; Increased Gold/Magic Find derivation; Steal skill-local versus global crits; Pick pocket unconditional versus crit-only; Mug scope; Big Score crit multiplier; Bribery per event versus per gold. | T3 economy/build semantics; T5 → M3/M5; M6 tuning |
| Q16 | Authoritative source, revision policy, collision-free IDs, old resource-path/skill-ID mappings, schema-to-runtime conversion, stale notes/names/units, missing content handling, old-save/Practice Room policy. | T4 → T7 |
| Q17 | Whether blank 9-point Bladedancer/Thief slots remain intentionally empty, are deferred, or need content; essential versus experimental mechanics and acceptable scope. | T5 → M5 |
| Q18 | Tree roles/weaknesses and gear synergies; early/mid/mature budgets, representative builds, enemy targets and tolerable scaling. Draft 35-rank capacities are not progression targets. | T3 initial targets → M6 tuning |
| Q19 | Required buff/charge/cooldown visibility, dense tree layout, icon reuse, accessibility, and diagnostics/event contracts. | T5 → M3 data / M4 prototype and asset inventory / M7 finish |
| Q20 | M4 representative build and dependencies; deterministic test scenarios, expected results and migration acceptance cases; diagnostic complexity limits. | T5 with T4 → T8/M3/M4 |

## Presentation and diagnostic handoff

| Surface | Required information from this audit | Owner |
| --- | --- | --- |
| Tree/build UI | Rank/max, current and next values, per-rank cost, gate progress, predecessor requirements, base/main intrinsic split, automatic unlock progress and refund consequences. Preserve all 44-node identities across selection changes. | T5 requirements → M4 prototype |
| Dense layouts | Bladedancer has 13 talents across five rows, Shadow has 11; prototype mixed-tree view, locked gates, long descriptions and automatic tracks. Current UI derives rows from prerequisites, which cannot represent draft level placement faithfully. | M4 |
| Rotation/skills | Resolved damage/timing, cooldown, conditional-ready state, unavailable-slot handling, empowered Plunge, forced poison ticks, and resource costs. Ten selected slots may have repeated skills; cooldown ownership must be clear. | T5/M3 → M4/M5 |
| Temporary effects | Bypass, Footwork, Precision, Virulent charges, Master of Poisons, Dance of Death, Death Pact, Touch of Darkness, Beguiling Presence; Blinding Powder pending active/passive clarification. Show stacks/charges, magnitude, remaining time, cooldown/readiness and source as applicable. | M3 event state → M4/M7 |
| Enemy status | Actual poison/shred/Decay counts, cap/overflow, consumed/converted counts, cleanse protection, effective penetration and mitigation. | M3 → M4/M7 |
| Diagnostics/playback | Source and parent event, natural/forced tick kind, stacks requested/applied/consumed, buff gain/refresh/expiry, crit and proc rolls/outcomes, prevented damage, gold before/after/caps, cooldown changes and skipped skills. Extend recap's one-stack inference and physical/poison assumptions where necessary. | T5 → M3/M4 |
| Icons/feedback | Catalog validity is established only. Inventory distinct talent/skill/buff/debuff art, deliberate reuse and cue priorities; inspect actual display sizes and crowded effect overflow. | M4 inventory → M7 production |

## Validation and follow-up checks

Performed on 2026-09-21:

1. Read all four source exports and compared all 68 talent/intrinsic/automatic-slot
   entries against the runtime evidence above. The two talent-granted skill records
   are included with their parent talents, so there are 20 populated skills in total.
2. Ran `node tools/p6/audit_tree_drafts.js --write`, then
   `node tools/p6/audit_tree_drafts.js`. Four files parsed and passed the repository
   Tree Lab schema/semantic validator: **0 errors, 0 warnings per file**. The generated
   appendix matches source bytes/objects and expands all structured talent rank values.
3. The cross-file scan found **six entity-ID collisions**. This is a content workflow
   finding, not a per-file schema failure. SHA-256 hashes above freeze the audited revision.
4. Inspected inherited tests and runtime paths to identify coverage anchors. No gameplay
   tests or balance suite were run because runtime code/resources were not changed.
   Schema/preview checks do not validate mechanics, balance, final art, or visual usability.

Re-run the audit command after any source revision; a stale appendix fails its check.
Regeneration alone does not update the manual runtime classifications or approve changed content.

| Later validation family | Existing anchors / new cases to specify |
| --- | --- |
| Build allocation | `project/tests/passive_allocator_test.gd`, `training_room_build_test.gd`, `rotation_cap_test.gd`: add rank/gate boundaries, mixed-tree roles, invalid dependent refunds, threshold unlock loss/restoration and revised point income. |
| Poison/status | `engine_mechanics_test.gd`, `p5m4_crit_applies_poison_test.gd`, `p5m4_death_strike_stack_order_test.gd`, `p5m4_shred_stack_mechanics_test.gd`: add 0/1/2/3-stack ticks, force/scheduled ties, dynamic cadence, poison crits, Decay consume/restore, selective cleanse and cap overflow. |
| Procs/eligibility | `opportunity_strikes_test.gd`, `p5m4_retrigger_semantics_test.gd`, `hold_skill_test.gd`: add guaranteed first repeat without runaway recursion, poison→Stab suppression, skipped Parry/cooldown slots, duplicate slots and deterministic chain limits. |
| Mitigation/buffs | `p5m4_enemy_denial_hooks_test.gd`, `p5m4_conversion_ignore_hooks_test.gd`, `p5m4_rounding_floors_mitigation_order_test.gd`: add partial penetration, expiry ties, charge refresh, conversion interaction, interrupted/dodged consumers and packet crit-negation. |
| Economy | `thief_subclass_test.gd`, `p5m7_gold_gain_economy_test.gd`, `p5m11_economy_stats_test.gd`, `p5m11_overkill_gold_test.gd`: add gold caps at boundary values, per-steal rounding, reset/retry, shopping incentives, derived IAS/elemental and feedback loops. |
| Persistence/replay/UI | `save_load_test.gd`, `deterministic_replay_test.gd`, `skill_tooltip_formatter_test.gd`, `combat_recap_test.gd`, `combat_playback_test.gd`, `build_panels_test.gd`: add explicit migration policy cases, rank round trips, new event timelines and resolved tooltips. Normal save/load still does not prove power-loss durability. |
| Balance | Grow `project/scripts/tools/balance_lab.gd` scenarios for six tree pairs, early/mid/mature budgets, gear extremes and armor/resistance/cleanse/suppress/crit-negation matchups; retain `bladedancer_contract_watchmen` review. Targets are T3/M6 decisions. |

## T2 completion boundary

The revision record, exhaustive appendix, per-element support classifications,
cross-tree/gear review, presentation inventory and assigned question register meet
T2's audit acceptance checklist. **T3 is next.** Begin with Q01–Q04, Q08/Q10 policy
boundaries, Q15 gold semantics and Q18 identities/progression; T4 can use Q16 for
content/migration policy. T5 consolidates remaining combat/UI dependencies and
selects the M4 build. No new gameplay rule, final number, ID mapping, art, or
implementation slice is approved by completing this audit.
