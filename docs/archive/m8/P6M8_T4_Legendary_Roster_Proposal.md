# P6M8-T4 — Legendary roster proposal and identity review

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. [Current context](../../P6_Project_Onboarding_Context.md).

**Current Exsanguinate tuning:** D091 adopts 1× resolved Armor Shred Value per actual Shred stack consumed, with no retriggers. [Current specification and verification](P6M8_T10_Exsanguinate_Adopted_Balance.md). Original supplied roster values below remain historical design inputs.

2026-10-22. **T4 Complete — user approved the full roster and identity review under D010.** The user supplied the complete proposed roster and requested this proposal and its roles, overlap, synergies and counterplay review. The proposal contains **16 items: seven weapons, two helms, two chests, two charms and three trinkets** (five existing identities and eleven additions). This count comes from the user's complete submission, not a quota. The T4 review checkpoint is resolved. Next: [T5 mechanics specification and guided discussion](../../P6M8_T5_Legendary_Mechanics_Specification.md).

**Later T5 revision — D016 (2026-10-23):** Locket’s effect is now “Critical hits have a 20% chance to reduce all cooldowns by 1 sec.” Includes Poison crits, one roll per critical packet. This supersedes the retrigger-based Locket text and related synergy assumptions below, which preserve the T4 review history. Current mechanics authority is the [T5 specification](../../P6M8_T5_Legendary_Mechanics_Specification.md).

## Authority and boundaries

All numeric stats, effects, names and sprite selections below are user-supplied proposal inputs. Review conclusions and suggested priorities are design analysis, not gameplay evidence or permission to change values. No item has been removed, rebalanced or implemented. T4 acceptance concerns identities, roles, coverage, overlap and counters; unresolved formulas, timing, acquisition details and interactions belong to T5. T6 demonstrates representative reviewed mechanics before broad implementation.

The [T2 audit](P6M8_T2_Current_Legendary_And_System_Audit.md) is historical current-state evidence at the start of M8. The implemented [T3 specification](../../P6M8_T3_Gear_Stat_Implementation_Specification.md) and [closeout](P6M8_T3_Closeout_And_Verification.md) supersede its old normal stat pools. Current [combat contracts](../../Combat_Mechanics_Reference.md) remain the mechanics baseline. Accepted near-zero cooldowns, hard difficulty, intentional counters, M7 presentation conventions, original existing artwork and real-save isolation remain intact.

Names are transcribed as supplied, including **Mitrhril Krarambit**, **Nightkiss Kitana** and **The Crown of Concertation**. The first maps to the existing **Mithril Karambit** identity; no stable ID or spelling change is adopted by this document. Cosmetic spelling can be settled in T5/T9. Chests use the existing Armor equipment slot. Proposed combinations below assume one item per existing slot; concurrent Legendaries in different slots need an explicit T5 equipment contract. No second weapon or second trinket is assumed.

## Complete user roster

### Weapons — existing identities

All five existing weapon sprites remain unchanged. Preserve their stable resource identities when implementing reviewed changes.

| Item | Proposed stats | Proposed Legendary effect |
| --- | --- | --- |
| **Wyvern Kriss** | +8 Base Elemental Damage; +40% Elemental Damage; +12% Chance to Decay | Poison ticks twice as fast. |
| **Umbral Stiletto** | +10% Crit Chance; +100% Crit Damage; +50% Chance for crits to apply Poison | Grants Death Strike. Death Strike gains +1 Physical Damage per Decay stack. |
| **Mitrhril Krarambit** (existing Mithril Karambit) | +15% Increased Attack Speed; +15% Crit Chance; +20% Chance to Shred | Stab and Heavy Slash have a +50% retrigger chance. |
| **Bandit Blade** | +20% Physical Damage; +12% Crit Chance; +50% Increased Gold | Gain +1 Base Physical Damage per 10 gold in stash, capped at +100. |
| **Bejeweled Push dagger** | +8 Base Physical Damage; +20% Physical Damage; +10% Crit Chance | 40% chance for skills to cast lightning fast. |

Against the T2 baseline, notable explicit proposals include Umbral's crit-to-Poison changing from 100% to 50%, Bandit's Gold from 30% to 50% plus the new damage cap, and Bejeweled's cast proc from 20% to 40%. Umbral's Decay addition is a new item-specific requirement against the current Death Strike runtime formula. Mithril's wording must be reconciled with the existing authored child triggers rather than silently treated as +50 percentage points to the global numeric stat. The audit records the actual current paths; the supplied names/text alone do not establish equivalence.

### Weapons — additions

| Item | Proposed stats | Proposed Legendary effect | Sprite source |
| --- | --- | --- | --- |
| **Decrepit Blade** | +10 Base Physical Damage; +10 Base Elemental Damage; +12% Retrigger Chance | Grants Poison Strike. Poison Strike now procs all Poison stacks. | `F:\Data\Junk\DPS Game\Purchased Sprites\Rpg Icon Pack\Weapons\Swords\33.png` |
| **Nightkiss Kitana** | +50 Armor Decrease per Shred Stack; +5 Stacks; +20% Chance to Shred | Grants Exsanguinate (specified below). | `F:\Data\Junk\DPS Game\Purchased Sprites\Rpg Icon Pack\Weapons\Swords\7.png` |

**Exsanguinate — user-supplied new skill:** Type **Debuff**; Cast Time **0.3 seconds**; Cooldown **8 seconds**. Consumes all Shred stacks. Removes **2 × Armor Shred Value health per stack consumed**. Sprite: `F:\Data\Junk\DPS Game\Purchased Sprites\Rpg Icon Pack\Skills\Rogue\25.png`.

The symbolic expression is `2 × Armor Shred Value × actual stacks consumed`; what constitutes that value, and whether health removal is damage or another operation, remain T5 questions. The supplied Debuff category is preserved. No physical damage packet, crit, defense bypass, Death Pact interaction or retrigger eligibility is inferred.

### Helms

| Item | Proposed stats | Proposed Legendary effect | Sprite source |
| --- | --- | --- | --- |
| **The Crown of Concertation** | +20% Attack Speed; +20% Increased Buff Duration; +15% Cooldown Reduction | The effects of self buffs are doubled. | `F:\Data\Junk\DPS Game\Purchased Sprites\Rpg Icon Pack\Armor\Helmets\45.png` |
| **Helm of the Samurai** | +12% Crit Chance; +20% Attack Speed; +8% Retrigger Chance | Retriggered skills grant 1 Meditation stack. Meditation stacks up to 5 and lasts 3 seconds. Meditation grants **×20% Physical Damage per stack**. | `F:\Data\Junk\DPS Game\Purchased Sprites\Rpg Icon Pack\Armor\Helmets\12.png` |

**Meditation sprite:** `F:\Data\Junk\DPS Game\Purchased Sprites\Rpg Icon Pack\Skills\Paladin\17.png`.

### Chests (Armor slot)

| Item | Proposed stats | Proposed Legendary effect | Sprite source |
| --- | --- | --- | --- |
| **Cloak of Speed** | +70% Increased Physical Damage; +25% Crits Apply Penetration | Grants Quick Cut. Retriggered attacks have a chance to trigger Quick Cut. **Chance not supplied.** | `F:\Data\Junk\DPS Game\Purchased Sprites\Rpg Icon Pack\Armor\Cloaks\8.png` |
| **Death’s Door** | +35% Increased Physical Damage; +35% Increased Elemental Damage; +60% Increased Gold Rewards | You deal **2× damage for each missing life**. | `F:\Data\Junk\DPS Game\Purchased Sprites\Rpg Icon Pack\Armor\Chests\32.png` |

The doubled separator in the submitted Death's Door path is normalized here to one separator. The source selection is unchanged.

### Charms

| Item | Proposed stats | Proposed Legendary effect | Sprite source |
| --- | --- | --- | --- |
| **The Signet of the Old Kings** | +20% Crit Chance; +100% Crit Damage; +20% Chance to Shred | You can no longer crit. Crit Chance is converted to Attack Speed at 2×. Crit Damage is converted to Increased Physical Damage at 2×. | `F:\Data\Junk\DPS Game\Purchased Sprites\Rpg Icon Pack\Armor\Trinkets.Amulets\58.png` |
| **Lolzorz’s Locket** | +15 Base Damage; +15 Base Elemental Damage; +15% Cooldown Reduction | Retriggers reduce skill cooldowns by 1 second. | `F:\Data\Junk\DPS Game\Purchased Sprites\Rpg Icon Pack\Loot\Monster loot\66.png` |

### Trinkets

| Item | Proposed stats | Proposed Legendary effect | Sprite source |
| --- | --- | --- | --- |
| **Serpent’s Coil** | +15% Crit Chance; +15% Attack Speed; +10% Retrigger Chance | Poison is affected by Retrigger Chance. | `F:\Data\Junk\DPS Game\Purchased Sprites\Rpg Icon Pack\Armor\Rings\12.png` |
| **Wingjammer** | +15 Base Damage; +50% Increased Gold; +30% Crits Apply Penetration | Crits have a 30% chance to grant Dash. Dash stacks up to 20 and lasts 3 seconds; each stack grants +5% Increased Attack Speed. | `F:\Data\Junk\DPS Game\Purchased Sprites\Rpg Icon Pack\Armor\Rings\40.png` |
| **Mysterious Lucky Coin** | +100% Crit Chance; +15% Cooldown Reduction | **×100% Magic Find.** Special Easter egg Legendary, unlocked only by destroying the Lucky Coin. | `F:\Data\Junk\DPS Game\Purchased Sprites\Rpg Icon Pack\Armor\Trinkets.Amulets\8.png` |

**Dash sprite:** `F:\Data\Junk\DPS Game\Purchased Sprites\Rpg Icon Pack\Skills\Archer\27.png`.

“Base Damage” on Locket/Wingjammer is preserved verbatim; mapping it to Base Physical Damage needs T5 confirmation. “×100% Magic Find” is also preserved: neither +100% nor ×100 is substituted. Unlocking the special Coin is not assumed to grant, equip or offer it immediately. Its availability after unlocking and the scope/persistence of that unlock remain open.

## Roles, intended users, overlap and counterplay

This is a qualitative design review. Counters below refer to existing combat rules when applicable, or explicit resource/slot tradeoffs. They are not new enemy mechanics. Where a proposed effect has no settled defense contract, its counterplay is conditional and must be reviewed in T5.

| Item | Identity/fantasy and intended user | Distinction / overlap boundary | Counterplay, weakness or cost |
| --- | --- | --- | --- |
| Wyvern Kriss | Venom blade accelerating sustained Poison; Assassin/Shadow or mixed elemental applicators. | Natural tick cadence rather than Decrepit's active Poison release. Can use Coil but cannot equip Decrepit simultaneously. | Needs replenishable Poison fuel. Faster ticks consume fuel sooner under current rules. Cleanse, elemental defenses and suppression remain relevant unless a reviewed build specifically answers them. |
| Umbral Stiletto | Execution blade connecting crit-fed Poison, Decay and Death Strike; Shadow/Assassin hybrids. | Direct execution payoff from two status investments, rather than pure cadence or Shred cash-out. | Needs statuses and successful casts; cleanse can remove setup. Decay spent on another ability competes with keeping it for Death Strike. Signet disables its crit-to-Poison engine. |
| Mithril Karambit | Repeating basic-strike weapon; Stab/Heavy Slash physical and Bladedancer builds. | Specific skills, unlike global retrigger gear or Bejeweled's root timing. | Requires those skills in the rotation. Dodged direct attacks do not start the current repeat chain; burst defense/cleanse interactions still matter. Little signature value for rotations that exclude both skills. |
| Bandit Blade | Wealth-backed blade; Thief/economy physical builds. | Stash becomes flat physical power, with an explicit ceiling; Gold rewards elsewhere help funding rather than duplicate this conversion. | Spending competes with power before the cap. The +100 cap is reached at 1,000 stash gold under the stated ratio; extra stash no longer adds signature damage. Physical defenses still apply. Live theft timing remains unresolved. |
| Bejeweled Push dagger | Quick-draw weapon compressing skill execution; flexible root-cast rotations. | Faster root casts, not extra attacks and not cooldown recovery. | Under the current implementation it does not bypass cooldowns, interruption or dodge. Minimum execution times and resources limit benefit; already-minimum casts gain little. Confirm retained meaning in T5. |
| Decrepit Blade | Decaying hybrid blade releasing accumulated Poison through an active attack; Poison setup/burst users. | Active release rather than Wyvern's passive cadence. | Needs a Poison source beyond the item itself. If release consumes fuel, bursts compete with sustained ticks; that tradeoff is not yet settled. Current Poison Strike can be interrupted/dodged. |
| Nightkiss Kitana | Armor-rending execution weapon; Shred builders, including Bladedancer and mixed Thief/Shadow sources. | Spends Shred for a health payoff instead of only maintaining armor reduction. | Consumption trades away armor reduction until rebuilt. Cleanse can deny setup unless protected by an existing reviewed talent. Whether Exsanguinate itself is defended, interrupted or repeated needs T5 definition. |
| Crown of Concertation | Amplifier for deliberate self-buff rotations; Bladedancer/Shadow and mixed buff builds. | Enhances self buffs rather than requiring retriggers. Competes directly with Samurai's helm slot. | Low value without eligible buffs. Buff uptime, rotation time and relevant interruption/expiry rules matter. Exact eligible buffs and doubled properties are unresolved, so it cannot yet be called universal. |
| Helm of the Samurai | Repeated-action physical momentum; retrigger-oriented builds. | Short-lived physical payoff from retriggers; Crown is broader buff amplification but mutually exclusive. | Needs sustained eligible retriggers and physical output. Gaps may lose Meditation; refresh rules decide how easily that happens. Crit affix has opportunity cost with Signet. |
| Cloak of Speed | Extra-cut engine for aggressive physical/retrigger rotations. | Adds Quick Cut access and an extra attack trigger; Samurai adds a buff and Locket changes cooldowns. | Requires eligible retriggered attacks, not just any fast cast. Physical defenses remain meaningful. Source eligibility and recursion rules determine whether chains are controlled; an engine budget failure is not counterplay. |
| Death’s Door | Desperate survivor turning lost lives into power; either physical or elemental builds. | Run-state risk instead of combat-stack setup. Competes with Cloak's attack engine. | Fewer remaining lives reduce room for error. Deliberate losses may become attractive; the actual life/attempt definition and multiplier must be settled before claiming a balanced risk. No low-health interpretation is assumed. |
| Signet of the Old Kings | Renounces crits for reliable speed and physical scaling; physical converters and Shred users. | A true rules conversion with an explicit sacrifice; Locket instead rewards repeat events without disabling crits. | Forfeits crit damage events and crit-dependent Poison, Penetration, Potency and Dash activations within the final scope of “cannot crit.” Vulnerable to remaining physical defenses; conversion order/caps determine scaling. |
| Lolzorz’s Locket | Repeat-driven cooldown engine; users with meaningful cooldown skills, including mixed damage builds. | Flat cooldown recovery is distinct from CDR and Bejeweled's faster windup. | Needs retriggers and useful running cooldowns; zero-cooldown skills offer no direct recovery benefit. Windup, resources and macro sequencing still matter. Feedback loops require defined event scope. |
| Serpent’s Coil | Extends repeat investment into Poison; Poison/retrigger hybrids. | Opens a new event family rather than supplying more ordinary attack repeats. Shares the trinket slot with Wingjammer/Coin. | Needs Poison fuel/application. Defense and cleanse still depend on the selected tick contract. Whether repeats consume more fuel or start more chains is the central unresolved tradeoff. |
| Wingjammer | Critical momentum and wealth; direct-crit attack-speed builds with Penetration. | Crit-fed attack speed, distinct from Samurai's repeat-fed physical multiplier; their different slots allow combination. | Requires eligible crits. Signet prevents that engine. Dash needs maintenance under pending timer rules; wasted excess IAS at cast minima and loss of another trinket are costs. |
| Mysterious Lucky Coin | Secret discovery reward for crit-oriented and loot-focused builds. | Easter egg acquisition and exceptional crit access; competes directly with Coil/Wingjammer. | +100% crit may make further crit investment redundant under the existing effective 100% cap, but conversion can change that assessment. Signet may convert its stats instead. No rarity or unlock difficulty is counted as proof of combat balance. |

## Coverage and overlap assessment

**Recommendation: retain all 16 supplied identities for the T4 review checkpoint.** There are meaningful differences between the seven weapon choices and between each same-slot pair. No identity needs removal on the current qualitative evidence. This recommends the supplied roster for review, not acceptance of final numerical balance or a requirement to add more items.

The strongest coverage is physical attacks, Poison, crits, Shred and retriggers. Shadow has status/Decay and self-buff connections; Assassin has Poison/crit connections; Bladedancer has repeats/buffs/Shred connections; Thief has stash, Gold and theft-to-Shred connections. These are intended build opportunities, not subclass locks or a claim that every talent path benefits equally.

Elemental damage has support through Wyvern, Decrepit, Umbral's status setup, Locket and Death's Door, but there is no dedicated non-Poison elemental signature. Economy is mainly a funding/build input: Bandit's signature is stash-based, while Gold on other items supplements income. There is no dedicated defensive/recovery Legendary or direct Decay-consumption signature beyond existing skill interactions. These are coverage observations, not missing requirements: the user's roster is complete, and hard counters/weak choices remain acceptable.

The main overlap is the **retrigger cluster**: Mithril or Decrepit, Samurai, Cloak, Locket and Coil can all reward repeat investment in different slots. Distinct rewards do not guarantee distinct builds if the same engine drives all of them. T5 must preserve clear event meanings so the cluster does not accidentally become the default answer for Poison, physical and cooldown play simultaneously.

Specific same-slot choices remain legible:

- **Weapons:** Poison cadence (Wyvern), Poison release (Decrepit), status execution (Umbral), Shred consumption (Nightkiss), skill-specific repeats (Mithril), root-cast speed (Bejeweled), or stash power (Bandit).
- **Helms:** amplify eligible buffs (Crown) or earn physical momentum through repeats (Samurai). They cannot amplify each other while equipped normally.
- **Chests:** repeat-driven extra attacks (Cloak) or missing-life risk/reward (Death's Door).
- **Charms:** give up crits for conversion (Signet) or convert retriggers into cooldown availability (Locket).
- **Trinkets:** Poison repeats (Coil), crit-driven Dash (Wingjammer), or special crit/loot identity (Coin). Coil + Wingjammer, Coin + Wingjammer and Coin + Coil are not valid normal equipment combinations.

High fixed affixes also compete with regular T3 gear. T10 must compare signatures and total stats against legal generated alternatives; signature uniqueness alone does not establish a meaningful choice.

## Representative synergies and tensions

These are candidate interactions for specification/prototyping, not verified builds. Each row respects one item per listed slot. Unlisted slots are free.

| Candidate equipment | Intended synergy | What the review must establish |
| --- | --- | --- |
| Mithril + Samurai + Cloak + Locket + Wingjammer | Stab/Heavy Slash repeats build Meditation, may create Quick Cuts, recover cooldowns and create crit/Dash momentum. | Distinguish authored Mithril children, numeric repeats and Cloak-triggered Quick Cuts. Decide which feed each reward and whether recursion creates a runaway engine. Wingjammer supplies no automatic Poison tick crits. |
| Wyvern + Coil + Locket | Natural Poison cadence plus possible Poison repeats and cooldown recovery. | Whether Poison repeat events qualify for Locket; fuel consumption, tick crit/source rules and any chain amplification. Faster cadence must not be treated as free fuel. |
| Decrepit + Coil + Samurai | Active Poison release with repeat investment and a possible repeat-fed physical component. | Whether release is one enlarged tick or multiple packets, what consumes fuel, and whether Poison repeats count as retriggered skills for Meditation. These interactions are conditional. |
| Nightkiss + Signet + Wingjammer | Signet supplies speed/physical conversion and Shred, supporting Shred buildup for Exsanguinate; Wingjammer adds flat damage and Gold. | Wingjammer's Dash and crit-Penetration are disabled by no-crit, making it an intentionally poor pairing unless its remaining stats justify it. Do not call Exsanguinate physical damage or scale it by Signet without a contract. |
| Nightkiss + Signet + Mysterious Lucky Coin | Large crit-to-speed conversion can accelerate Shred application; Coin's CDR may support Exsanguinate. | Whether conversion reads uncapped Crit Chance and baseline Crit Damage; unlocking the Coin is separate from its combat interaction. The same-slot weapon restriction prevents adding Mithril. |
| Umbral + Crown + Wingjammer | Crit/status execution, with eligible self-buffs potentially supporting crit or elemental setup and Dash improving casting. | Crown's whitelist and treatment of Beguiling Presence/Dash; Decay consumed for Presence competes with retained Decay damage. Umbral + Decrepit is not a legal pair. |
| Bandit + Death's Door + Wingjammer | Gold income helps reach Bandit's cap; life-based power and crit-fed speed supply separate payoffs. | Stash/spending timing, income ownership rules and deliberate-loss incentives. Damage cap does not cap Gold rewards or establish full-run balance. |
| Bejeweled + Crown + Locket | Shorter root execution, reviewed self-buffs and cooldown recovery can support a varied rotation. | Needs another repeat source to activate Locket. Windup reduction and cooldown recovery solve different bottlenecks; CDR already permits near-zero cooldowns. |
| Any crit-dependent weapon + Signet | Stat conversion trades away crit triggers. | Umbral's crit-to-Poison and every equipped crit-Penetration/Potency effect lose activation within the reviewed no-crit scope. Critical Poison eligibility must be explicit. This is an intentional build choice, not a bug to compensate automatically. |

**Crown and Samurai cannot be equipped together.** Crown doubling Meditation therefore requires an independent source of Meditation before it could be a real combination; none is supplied. Crown + Wingjammer is slot-valid, but whether a passive Dash buff counts as a “self buff” is unresolved. Likewise Locket's recovery cannot simply be multiplied by Crown: cooldown recovery is not already defined as a self buff.

### Source-grounded counterplay and integration findings

The current [monster mechanic library](../../../project/scripts/systems/runtime_monster_generator/runtime_mechanic_library.gd) includes armor, dodge, crit negation, block, resistance, absorb, cleanse, suppress, slow, stun and interrupt. Existing [combat contracts](../../Combat_Mechanics_Reference.md) distinguish connection from damage: full block can leave connected-hit procs active, so blocking damage alone is not a reliable answer to a repeat engine. Crit negation is not automatically denial of critical-event hooks. Forced Poison ticks bypass natural-tick suppression. These distinctions should remain visible in matchup analysis rather than be simplified to “defense stops all procs.”

Current Quick Cut interactions include Precision, Footwork and Opportunity-driven Rending; extra Quick Cuts can therefore create buffs and Shred as well as damage. This makes **Mithril + Samurai + Cloak + Locket + Wingjammer** the first repeat-loop prototype candidate. A separate **Nightkiss + Samurai + Cloak + Locket** candidate examines Quick Cut/Rending Shred supply against Exsanguinate's consumption. Existing ignore-armor Special gear prevents Shred applications, which can conflict with Nightkiss's fuel rather than simply improve it. Replacing regular/Unique gear with five Legendaries also gives up slots for defensive denial/immunity Specials; signature stacking has an equipment opportunity cost.

The existing [Lucky Coin](../../../project/data/gear/lucky_coin.tres) is `gear.lucky_coin`, a fixed Basic Trinket with +5% Crit Chance; its current [focused test](../../../project/tests/p5m2_lucky_coin_charm_test.gd) records Drunk Buddy acquisition. [BuildState](../../../project/scripts/autoload/build_state.gd) destruction paths only remove items and emit state changes. Mysterious Lucky Coin therefore needs a separate stable identity and new unlock behavior; adding it to the current [Legendary catalog](../../../project/scripts/systems/legendary_catalog.gd) without gating would expose it to ordinary shop selection. Both equipped and inventory destruction must be considered.

Death's Door's input is especially important: current Adventure stores per-encounter failure counts and attempts, not an established global lives/HP pool. [BuildState](../../../project/scripts/autoload/build_state.gd) has two standard attempts per encounter and unlimited retries for the first Mouthy Drunk encounter. “Missing life” must be mapped to an agreed state before evaluating the multiplier; unlimited retries cannot silently become unlimited scaling. This finding does not rename the user's effect or adopt an attempts-based replacement.

Finally, non-weapon Legendaries need more than catalog entries: current Practice Legendary equip controls assume Weapon, and shop/tooltip paths carry weapon assumptions. T8/T9 must cover correct slot routing, fixed affix editing restrictions, comparisons, owned-ID filtering, full-inventory reward/equip behavior, multi-source skill unlock removal and authored-resource reload. No new global slot or inventory redesign is implied.

## Roster options and recommendation

| Option | Rationale | Assessment |
| --- | --- | --- |
| **Full supplied 16-item roster** | Preserves all five existing identities and all eleven user additions, across all five gear slots. | Recommended for the identity checkpoint. Keep distinct roles and explicit incompatibilities; resolve mechanics next. |
| Same roster, staged prototype groups | Specify the full roster in T5, then prove Poison, repeat/cooldown, conversion, Shred-health and run-state/unlock representatives before broad implementation. | Recommended delivery strategy for T6; does not cut items or move user content outside M8. |
| Smaller roster or substitute identities | Could reduce implementation scope, but would discard requested content without current evidence of irreducible duplication. | Not recommended or adopted. Any later reduction needs a concrete finding and user review. |

The special Coin remains one of the 16 identities but should be separated from the ordinary acquisition pool until its destroy-only unlock contract is specified. This is a consequence to review from the user's unlock requirement, not a new rarity, spawn rate or grant policy.

## T5 questions and downstream evidence

| Area | Unresolved contract / decision | Follow-up evidence |
| --- | --- | --- |
| Equipment and fixed stats | Confirm one Legendary per existing slot with cross-slot combinations; chest→Armor mapping; new weapon base range/family/minimum times; whether fixed affixes receive normal All Stats treatment. Resolve display spellings while preserving existing stable IDs. | T5 specification; T7 effects; T8 equip/swap/Practice/save; T9 comparisons. |
| Wyvern / Umbral | Confirm retained Poison cadence/fuel rules. Place Umbral's Decay bonus in the real Death Strike formula, define snapshot/order and multi-source unlock ownership. | T6 Poison/Decay witnesses and gear-on/off/macro cases. |
| Mithril / Bejeweled / Bandit | Mithril authored triggers vs additive numeric chance; Bejeweled retained minimum-time semantics; Bandit continuous vs ten-gold steps, cap ordering and snapshot vs live theft. | T6 root/child and spending/theft snapshots; T10 early/late capped comparisons. No old experimental curve is adopted. |
| Decrepit / Coil | Meaning of “proc all stacks,” consume vs preserve, packet count/order, crit eligibility, natural vs forced ticks, fuel and eligible retrigger sources; whether resulting ticks count as skills/attacks/retriggers downstream. | T6 matched fueled/empty/cleanse/proc cases; T10 branching and sustained supply. Current Poison ticks do not become repeat sources. |
| Nightkiss / Exsanguinate | Meaning of +5 Stacks (All Stacks, Shred applications or capacity); Armor Shred Value input; health removal vs damage, defenses/crit/modifiers, category timing and successful consumption; whether Shred consumption qualifies for any hook. | T6 setup→consume→rebuild, zero fuel, defense and cleanse cases. Current Death Pact only explicitly consumes Poison/Decay; do not extend it silently. |
| Crown | Eligible self-buff whitelist: active Self Buff skills only, passive timed buffs, Penetration/Potency, charges and conditional sources; double magnitudes vs counts/durations/caps; ordering with All Stats and conversions. | T6 representative fixed/stacked/consumed buff witnesses; T9 readable doubled outputs. T3 duration covers eight named families; new buffs require explicit integration. |
| Samurai / Wingjammer | What counts as retriggered skill / eligible crit; Meditation **×20%** aggregation (e.g. ×2 vs ×1.2^5 at five stacks); per-stack vs shared refresh timers; duration scaling and expiry. | T6 stack, exact-expiry and no-crit cases; T9 Meditation/Dash icons and feedback. At 20 Dash stacks the stated additive IAS contribution is +100%, before other interactions. |
| Cloak / Locket | Supply Cloak trigger chance. Define eligible root/child origins, Quick Cut augmentation/resource rules, whether child Quick Cuts can repeat, and which active cooldowns Locket reduces with what floor/order. | T6 repeat/cooldown prototype; T10 branching and scheduling. Current depth 16 / 1,024-candidate guards are diagnostics, not a balance policy or an acceptable failed simulation. |
| Death's Door | Define missing life from actual Adventure state (not HP); max/current source, scope and resets; additive-per-loss vs exponential multiplier (2/4/6 vs 2/4/8); zero-loss multiplier and terminal behavior; damage categories, timing and Practice representation. | T6 run-state witness; T8 persistence; T10 intentional losses/retry value. Inspect actual failure/attempt state before inventing a new life system. |
| Signet | Convert total vs gear-only Crit Chance and Crit Damage; include baseline crit multiplier vs bonus portion; pre/post cap conversion, All Stats ordering, consuming original stats and no-crit scope including Poison. | T6 conversion/overcap/derived-source witnesses; no circular stats or disabled-hook RNG surprises. |
| Coin / economy | Interpret **×100% Magic Find** and its ordering; unlock by destroying which stable Lucky Coin identity, equipped/inventory paths, run vs account scope, repeat destruction, availability after unlock, save compatibility and Practice access. Confirm Increased Gold wording maps to existing reward economics. | T5 acquisition assumptions; T8 unlock/save tests; T10 economy trajectories. Existing destruction just removes gear; an unlock is new behavior. |
| Cross-system balance | Cross-slot loops, legal generated gear alternatives, sustained statuses, near-zero cooldowns, flat cooldown recovery, crit conversion, intentional lost lives and discount/resale. | T10 focused, matched and representative earned evidence; T11 user play; broader full runs remain M9. T3's 39-gold arbitrage witness remains open, not cured by Bandit's cap. |

## Review checkpoint and verification

- [x] All 16 user-supplied identities, stats and effect text captured, with 11 new item sprite paths and two new buff icons plus Exsanguinate's icon.
- [x] Existing five weapon sprites retained; existing identity spelling differences recorded.
- [x] Roles, intended users, overlap, slot-valid combinations, synergies and counters reviewed against the T2/T3 baseline.
- [x] Full-roster recommendation and delivery alternative recorded without discarding supplied content or assuming an earlier quota.
- [x] Ambiguities and downstream evidence assigned rather than silently resolved.
- [x] User accepted the full T4 roster and identity/coverage/overlap review under D010. **T4 Complete; T5 In progress**; T6–T12 remain Not started. Ambiguous mechanics pass to T5.

This is documentation/source review only. Verification found all 16 item rows, all 14 supplied sprite files (11 item icons, Exsanguinate, Meditation and Dash), 112 local Markdown targets across the proposal/tracker/onboarding/roadmap with zero missing targets, one D009 decision entry, and consistent Pending input status at proposal preparation. D010 subsequently records user approval and T4 completion; the T5 link and current status are checked at handoff. Source sprite existence is not visual/art acceptance. An independent read-only design/source review informed the counterplay and lifecycle findings; the coordinating pass checked the relevant attempt, destruction, skill and Coin contracts. No gameplay tests, UI renders or balance simulations are claimed. No runtime resources, artwork, save files or sibling-project files are changed.
