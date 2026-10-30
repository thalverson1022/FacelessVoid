# M5-T7 — Assassin design review and implementation plan

> **Balance supersession — P6M5-D010 (2026-10-03):** The user approved Echoing and Resonance at +5% Poison damage per rank as separate multipliers, Toxic Tradeoff at +10% Poison/-10% physical per rank, and primary Assassin at +0.5 base elemental damage per invested point. The +5 innate and all stack-consumption/Potency rules remain unchanged. Numerical examples below preserve the original D009 design-review record; use [the balance implementation](P6_Assassin_Balance_Implementation.md) and [current combat reference](Combat_Mechanics_Reference.md) for live values.

Date: 2026-10-03. Status: **Design approved — D01–D03 confirmed under P6M5-D009; implementation Complete.**
The user confirmed all three proposals on 2026-10-03. Runtime implementation and acceptance are complete; see [T7 implementation](P6M5_T7_Assassin_Implementation.md).

## Scope and authority

Cover `tree.assassin`, `intrinsic.assassin`, ten talents / 35 ranks, five populated automatic slots and six skills including the Poison Strike talent grant. Preserve the [Assassin source draft](talent_tree_drafts/Assassin.json) and [canonical identity manifest](P6M2_T4_Content_Identity_Manifest.json). The draft's blank-fifth-slot note and statements that Bypass/tick mechanics are unimplemented are historical: Poison Vile occupies the fifth slot and shared mechanics are implemented.

Use the [M5 tracker](P6M5_Complete_Rogue_Tree_And_Skill_Implementation_Tracker.md), [coverage ledger](P6M5_T2_Content_Coverage_Ledger.md), [combat reference](Combat_Mechanics_Reference.md), [M3 poison contract](P6M3_T9_Poison_Timing_And_Consumption.md), [M4 closeout](P6M4_T11_Closeout_And_M5_Handoff.md), and [T6 implementation and subsequent corrections](P6M5_T6_Thief_Implementation.md). The latest M5-D007 lower-tier-support rule supersedes the original M2 total-points gate interpretation. M5-D008's Mug cap is 50; Pick Pocket remains ten raw gold / 1800 ms. Preserve these later changes in regression fixtures.

Shared M2/M3 rules are settled. Approved D01–D03 resolve T2 Q01, Q03 and Assassin's Q06 rank authoring. Numerical tuning remains M6. The task's explicit design checkpoint requires confirmation before affected implementation, even though review and implementation share T7.

## Approved decisions — P6M5-D009

| Decision | Proposed complete behavior | Reason and concrete consequence |
| --- | --- | --- |
| D01 — Venom Jab | Attack; 22% weapon damage; 1000 ms base / 500 ms minimum; no cooldown; connected hit applies five base Poison stacks after damage, with ordinary bonus-stack/doubling/cap rules. Ordinary attack crit, dodge, interruption and repeat rules apply. | Use the draft's five-stack intent while retaining inherited 22% resolver scaling and resource timing. The legacy resource currently applies eight; leave that compatibility resource unchanged. With a 100-damage weapon and neutral defenses, deal 22 physical damage then request five Poison. |
| D02 — Toxic Tradeoff | Five ranks multiply natural and forced Poison tick damage by 1.2/1.4/1.6/1.8/2.0 and originally physical damage by 0.9/0.8/0.7/0.6/0.5. Both are separate multiplicative factors. The Poison factor applies before crit, conversion, defenses and rounding; it does not increase unrelated elemental damage or Shadow Mastery's copied elemental bonus. | Preserve the draft's Poison-specific wording. This needs an explicit Poison-only factor; the generic elemental modifier would affect a broader scope. At rank five, a neutral 10-damage Poison tick becomes 20; a 100-damage physical hit becomes 50. An originally physical hit converted to elemental still takes the physical penalty; a Poison tick converted to physical keeps its Poison bonus and does not acquire that penalty. |
| D03 — Basic passives | Quick Hands adds 1/2/3/4/5 percentage points of ordinary IAS. Precision adds 1/2/3/4/5 percentage points of crit chance, subject to the normal total clamp. | Keep the draft's values. At rank five, existing +100% IAS becomes +105%; existing 20% crit becomes 25%. Precision grants no charge and no guaranteed repeat. |

An alternative for D02 is a general elemental factor using the existing elemental talent bucket. That would also amplify other elemental damage and Shadow Mastery's copied bonus, and requires explicitly changing the proposed wording and examples. It is not silently selected for implementation convenience.

## Allocation and intrinsic

Every selected Assassin tree grants +5 flat base elemental damage, even at zero investment. Primary Assassin adds +1 flat base elemental damage per Assassin point. Secondary receives only +5. At 0/1/5/10/20/35 primary points the contribution is +5/6/10/15/25/40; points in the other tree do not count. This is not a percentage modifier. Existing class base Poison is separate.

One point buys one rank, with a shared 45-point budget. A talent at gate G requires at least G retained points in strictly lower tiers of its own tree. Same-tier and higher-tier points never support the gate. Buy, refund and restore must agree; reject invalid refunds atomically. Prerequisites require one rank, not maximum rank. Rank zero removes only that talent's effects; a rank's complete value replaces the preceding value.

Automatic unlocks use total Assassin investment in either role, independently of primary scaling. Both roles receive the same talent effects. Refunds/reset prune unavailable rotation entries, preserving available entries' order and duplicates; later re-unlocking does not reinsert slots. Preserve alternate grants when deciding whether a skill remains available.

## All talents and complete rank effects

S = settled shared behavior; D = approved decision above. Full bindings are now complete in T7. IDs are canonical, not the draft's short IDs.

| Talent / canonical ID | Gate | Complete rank effects | Prerequisite | State |
| --- | --- | --- | --- | --- |
| Quick Hands / `talent.assassin.quick_hands` | 0 | +1/2/3/4/5 percentage points IAS | None | D03 |
| Precision / `talent.assassin.precision` | 0 | +1/2/3/4/5 percentage points crit chance | None | D03 |
| Hastened Poison / `talent.assassin.hastened_poison` | 5 | Poison cadence uses 10/20/30/40/50% of ordinary IAS | None | S |
| Echoing Toxin / `talent.assassin.echoing_toxin` | 5 | Two-stack tick fuel; separate Poison tick multiplier 1.1/1.2/1.3 | None | S |
| Poison Strike / `talent.assassin.poison_strike` | 5 | Unlock reviewed Poison Strike at rank one | None | S |
| Bypass / `talent.assassin.bypass` | 10 | Connected Stab grants one base Bypass after descendants; three-second shared timer, cap three; elemental factor 1 + 0.1 × stacks | None | S |
| Toxic Tradeoff / `talent.assassin.toxic_tradeoff` | 10 | Poison-only tick factor 1.2/1.4/1.6/1.8/2.0; physical factor 0.9/0.8/0.7/0.6/0.5 | None | D02 |
| Accelerant / `talent.assassin.accelerant` | 15 | Add another 10/20/30/40/50% IAS contribution to Poison cadence | Hastened Poison 1 | S |
| Resonance / `talent.assassin.resonance` | 15 | Replace tick fuel with three stacks; separate multiplier 1.2/1.4/1.6/1.8 | Echoing Toxin 1 | S |
| Critical Poison / `talent.assassin.critical_poison` | 20 | One live crit roll per fueled natural/forced tick packet, using full current crit multiplier | None | S |

## Skills and unlocks

| Own-tree points / grant | Skill / canonical ID | Category | Weapon scaling | Base / minimum ms | Cooldown ms | Complete behavior |
| --- | --- | --- | --- | --- | --- | --- |
| 1 / `unlock.assassin.slot_1` | Venom Jab / `skill.venom_jab` | Attack | 22% | 1000 / 500 | 0 | D01: damage then five base Poison, ordinary application modifiers. |
| 3 / `unlock.assassin.slot_2` | Blinding Powder / `skill.blinding_powder` | Debuff | 0% | 1000 / 500 | 0 | Base Potency equals current invested Assassin points in either role, then eligible extras/doubling; cap 100, shared three-second baseline timer. |
| 6 / `unlock.assassin.slot_3` | Virulent Poison / `skill.virulent_poison` | Self Buff | — | 500 / 500 | 5000 | Each activation grants an independent five-charge instance. Every fueled tick gets 2x per active instance and spends one charge from each. |
| 9 / `unlock.assassin.slot_4` | Master of Poisons / `skill.master_of_poisons` | Self Buff | — | 500 / 500 | 10000 | Ignore elemental resistance for five seconds after activation. Live ticks and eligible converted damage use the current buff. |
| 12 / `unlock.assassin.slot_5` | Poison Vile / `skill.poison_vile` | Debuff | 0% | 1800 / 500 | 0 | Request twenty base Poison, with eligible extras/doubling/cap. Preserve the authored name. |
| Poison Strike talent 1 | Poison Strike / `skill.poison_strike` | Attack | 83% | 1200 / 500 | 0 | Connected cast causes one fueled forced tick after attack damage and before later status additions/cleanse. |

Stab and Heavy Slash retain their existing base-skill availability. Bypass modifies connected Stab; it does not grant a new skill. Debuffs cannot dodge and do not change attack counters or gain attack-repeat eligibility. Self Buffs ignore IAS but retain existing slow/minimum rules. Cooldowns start at accepted macro cast start and are shared by skill ID; cooling slots spend exactly 100 ms with no activation, refresh or charge grants. Triggered children follow the existing eligibility and zero-windup contracts.

## Poison, timing and interaction contracts

Ordinary Poison capacity remains 20. Bonus stacks/doubling change application requests, not capacity. Shadow's future redesigned capacity is covered by shared fixtures until T8 promotes it; do not accidentally use legacy cap 40.

Cadence uses `max(1, round(1000 * legacy_interval_multiplier * (1 + effective_suppress) / (1 + max(0, IAS) * 0.1 * (hastened_rank + accelerant_rank))))`. Hastened and Accelerant add. IAS changes preserve fractional phase; natural ticks reset phase, forced ticks do not. Enemy slow affects casts; suppress affects cadence. The clock advances even while Poison is empty.

Natural and forced ticks deplete actual available fuel: one normally, two with Echoing, three with Resonance replacing two. Neither is keyword Consume and neither triggers Death Pact. A fueled tick makes one packet. Under proposed D02, before crit and defenses:

`raw = ordinary_live_poison_damage * actual_fuel * (1 + 0.1 * echoing_rank) * (1 + 0.2 * resonance_rank) * (1 + 0.2 * toxic_tradeoff_rank) * product(active_virulent_factors)`.

Use negative-absorb/base contributions in the ordinary damage term, consistent with existing origin-based conversion rules. Critical Poison rolls once for the entire fueled packet, reading live chance and full multiplier; it does not become a direct-hit critical hook, repeat source or Poison application. Empty fuel causes no tick damage, crit RNG or Virulent spending. Fully mitigated fueled ticks still deplete fuel and spend charges. Existing damage floors and final packet rounding remain unchanged.

Poison Strike permits a forced tick after a fully blocked connected hit; dodge/interruption prevents it. Natural ticks due at the same timestamp resolve first and may exhaust fuel before the forced tick. No phase reset and no use of Poison applied later in that same cast.

Bypass grants after Stab's subtree, so the granting hit/earlier children do not receive the new stack. Add applicable extra stacks, double, then cap three. Grants refresh at cap; zero grants do not. All Bypass stacks share a three-second timer and expire before deadline-equal live reads. Three stacks give 1.3x, not 1.1 cubed. Bypass contributes to elemental stats and Shadow Mastery; proposed Toxic Tradeoff's Poison-only factor does not.

Potency reduces absorb by one per stack, refreshes at cap and expires before exact-deadline operations. It can make absorb negative; preserve origin-based base-damage treatment and no second destination bonus after conversion. Powder's own-tree point count is separate from the primary intrinsic. Cleanse removes Poison/Potency; Bladedancer Virulent Corruption protects Shred only. Existing full cleanse-denial gear remains separate.

Virulent instances have five charges and no timed expiration. Extra-stack/doubling gear does not add charges. Two active instances multiply to 4x and each spends one charge on a fueled natural or forced tick. Master instances use independent five-second lifetimes, effective resistance zero while any is active, and retain stored Decay. Fight completion, retry, invalidation and exit clear fight-local state without mutating configured inputs.

## Proposed player descriptions

Rank tooltips show current/next complete values from the table, using these descriptions. D01–D03 wording is approved.

| Content | Player wording |
| --- | --- |
| Intrinsic | Gain +5 base elemental damage. As your primary tree, gain +1 more per point invested in Assassin. |
| Quick Hands | Gain {value}% increased attack speed. |
| Precision | Gain {value} percentage points of critical chance. |
| Hastened Poison | Apply {value}% of your increased attack speed to Poison's tick rate. Adds with Accelerant. |
| Echoing Toxin | Poison ticks use up to two stacks and deal {value}% more damage per stack used. Applies to natural and forced ticks. |
| Poison Strike talent | Unlock Poison Strike. Its connected hits trigger a Poison tick using available stacks. |
| Bypass | Stab grants Bypass for 3 seconds, up to 3 stacks. Each stack adds 10% to Bypass's elemental damage bonus, for up to 30%. New stacks refresh the duration. |
| Toxic Tradeoff | Poison ticks deal {poison}% more damage. Physical damage deals {physical}% less. These modifiers apply before damage conversion. |
| Accelerant | Apply an additional {value}% of your increased attack speed to Poison's tick rate. Requires Hastened Poison. |
| Resonance | Poison ticks use up to three stacks instead of two and deal {value}% more damage per stack used, multiplying Echoing Toxin's bonus. |
| Critical Poison | Natural and forced Poison ticks can critically strike using your current critical chance and critical damage. |
| Venom Jab | Deal 22% weapon damage and apply 5 Poison stacks on hit. |
| Blinding Powder | Apply {Assassin points} base Potency. Each Potency reduces absorb by 1 for 3 seconds, up to 100 stacks. |
| Virulent Poison | Your next 5 fueled Poison ticks deal double damage. Repeated activations grant separate sets of charges. |
| Master of Poisons | Your elemental damage ignores resistance for 5 seconds. |
| Poison Vile | Apply 20 base Poison stacks. |
| Poison Strike skill | Deal 83% weapon damage and trigger one Poison tick on hit. The tick uses available Poison stacks. |

Existing skill tooltip timing, category, dynamic resolved values and cooldown sections supplement these texts. Do not display the static Precision passive as a charge buff. Show Bypass timer/count and each Virulent/Master effect truthfully; final icon polish belongs to M7.

## Worked acceptance examples

These are specification calculations, not executed combat evidence. Unless stated otherwise use neutral defenses, no conversion, no crit and no other modifiers.

| Case | Expected result |
| --- | --- |
| E01 — Intrinsic roles | Assassin 35 contributes +40 elemental base as primary, +5 as secondary. Assassin 10 contributes +15 or +5. Other-tree points do not change either contribution. |
| E02 — Basic passives | Quick Hands five changes +100% IAS to +105%; a 1000 ms / 500 ms minimum attack remains at its 500 ms floor. Precision five changes 20% crit to 25%. |
| E03 — Venom application | D01 with +2 eligible stacks and doubling requests (5 + 2) × 2 = 14. At 18/20 Poison, accept two and discard twelve; no capacity increase. |
| E04 — Additive cadence | +100% IAS, Hastened five and Accelerant five, no suppress: 500 ms interval. Hastened five alone: 667 ms. A 1000→500 ms interval change halfway through leaves 250 ms. |
| E05 — Fuel replacement | Base 10, Echoing three, Resonance four: three fuel gives 70.2 raw; two gives 46.8; one gives 23.4; zero gives no packet. |
| E06 — Toxic composition | D02 rank five doubles E05's full-fuel packet to 140.4. Weapon Master two plus Tradeoff five leaves physical damage at 2 × 0.5 = 1 times the starting value. Poison converted to physical keeps the Poison bonus. |
| E07 — Virulent and crit | E05 full fuel, two active Virulent instances and a 3x critical tick: 70.2 × 4 × 3 = 842.4 raw, rounded to 842. Each instance loses one charge, not three. |
| E08 — Bypass cap | Stab base one +2 extras then doubling requests six; cap admits three, giving 1.3x. Refresh at cap resets the shared deadline. Exact-deadline ticks use no expired bonus. |
| E09 — Powder roles | Assassin ten, +2 extras and doubling applies 24 Potency in either role. Starting absorb 10 becomes -14 until expiry/cleanse; full absorb-denial gear establishes zero first, so it becomes -24. |
| E10 — Tick order | With two Poison and Echoing enabled, a due natural tick at Poison Strike impact spends both; the later forced tick finds zero, spends no Virulent charge and rolls no tick crit. |
| E11 — Lower-tier refunds | Quick Hands five + Hastened five cannot refund Quick Hands while retaining Hastened. Hastened's five points cannot support itself. Refund Hastened first or replace sufficient tier-one support. |
| E12 — Cooldown skip | A second Virulent slot entered while cooling spends 100 ms, grants no instance and refreshes no charges. A slot entered exactly when ready casts normally. |

## Legal build plans and representative scenarios

Purchase in the written order. Every plan obeys lower-tier support and the shared 45-point cap. Pair each with the other tree selected at zero if no other allocation is specified.

- **Entry 6:** Quick Hands 5, Poison Strike 1. Exercises the one/three/six-point unlocks and forced ticks.
- **Cadence 20:** Quick Hands 5, Precision 5, Hastened Poison 5, Accelerant 5. Tier four has fifteen supporting points before Accelerant. Compare to the same setup with reduced cadence ranks and controlled gear IAS.
- **Poison 21:** Quick Hands 5, Precision 5, Echoing Toxin 3, Poison Strike 1, Bypass 1, Resonance 4, Hastened Poison 1, Critical Poison 1. Tier four has fifteen supporting points; tier five has twenty. Exercises fueled/empty natural and forced ticks without Toxic Tradeoff.
- **All ranks 35:** Quick Hands 5, Precision 5, Hastened Poison 5, Echoing Toxin 3, Poison Strike 1, Bypass 1, Toxic Tradeoff 5, Accelerant 5, Resonance 4, Critical Poison 1.

Pair All ranks 35 with Bladedancer 10 (Whetstone 4, Rending Slash 1, Fancy Footwork 5), then reverse primary/secondary roles without changing ranks. Also pair Assassin 35 with Thief 10 (Keen Eye 5, Sticky Fingers 5), reversing roles. Use a separate legal Thief 24 / Assassin 21 fixture for live gold/crit: Thief Keen Eye 5, Sticky Fingers 5, Fast Hands 5, Bribery 3, Silvered Edge 3, Finders Keepers 2, Gilded Blade 1; Assassin Poison 21 above. Broader pairwise consolidation is T9; synthetic Shadow adapters do not establish playable Shadow acceptance.

Representative rotations cover Venom Jab → Poison Strike, Vile → Poison Strike repeats, Virulent → Master → Vile → Poison Strike, and Stab → Vile → Poison Strike for Bypass. Compare neutral, dodge, full block, absorb/resistance, suppress/slow, cleanse, crit-negation and conversion targets/gear. Use twenty fixed seeds, repeat trace-on runs and compare trace-off outcomes/RNG. Measure starvation but reserve supply/balance targets for M6.

## Implementation sequence after confirmation

1. Record the user's decisions and update this specification and the combat reference. If D02 changes scope, revise descriptions/examples/fixtures before coding it.
2. Author explicit Assassin resources under the P6 content namespace. Bind innate/primary point modifiers, all rank carriers, five unlocks and talent-granted Poison Strike. Reuse reviewed descriptor builders where appropriate; do not overwrite legacy same-ID resources.
3. Add and validate explicit rank carriers for Hastened, Accelerant, Echoing, Resonance, Critical Poison and Bypass; derive actual Assassin investment for Powder in both roles. If D02 is approved, add a sourced Poison-only factor in the tick calculation with neutral default 1.0, preserving live state rebuilds and compatibility.
4. Extend the registry/display catalog and supported selection flow. Practice must allow Assassin in either role. Test Mode may use the existing secondary selection with 45 points; preserve the accepted title and two-tree layout. Add readable descriptions and assigned icons/traceable placeholders.
5. Promote under an explicit successor content revision, proposed `p6.playable.assassin.1`, with a release manifest. Verify old thief/bladedancer/mixed/core Practice revisions remain equivalent for their existing builds; require explicit policy treatment for any incompatibility. Adventure remains disabled with `p6.compat.1`.
6. Execute the acceptance matrix below, inspect rendered captures, fix failures, run appropriate regression, then update ledger/tracker/onboarding and record evidence. Remove Preview only after mechanics and reachable flows pass.

## Required acceptance matrix

This matrix was the implementation acceptance plan; executed results and limitations are recorded in the linked T7 closeout. Existing suites are regression candidates; new full-tree/journey tests must validate real allocated resources rather than only shared adapters.

| Group | Required evidence |
| --- | --- |
| T01 — Inventory | Ten canonical talents, all 35 ranks, intrinsic, six skills, five populated slots, one talent grant, no duplicate IDs or changed draft/legacy assets. |
| T02 — Allocation | Every rank including zero; caps/budget, both prerequisites, strictly lower-tier support on buy/refund/restore, invalid refund atomicity, malformed rank carriers rejected. |
| T03 — Roles | Intrinsic at zero and representative investments in both roles; Powder own-tree points in both roles; other-tree points excluded; source contributions reconcile. |
| T04 — Unlocks | Immediately below/at/above 1/3/6/9/12 points and talent grant; refunds/reset prune only unavailable rotation entries; alternate grants, duplicates and re-unlock behavior. |
| T05 — Venom | D01 complete descriptor, damage-before-application, crit/dodge/block/interruption/repeat, extras/doubling/cap, no mutation of inherited eight-stack resource. |
| T06 — Cadence | All Hastened/Accelerant ranks, additive scaling, zero/negative IAS, suppress versus slow, phase continuity, empty clock, integer deadlines. |
| T07 — Fuel | Echoing/Resonance ranks and prerequisites; one/two/three/partial/empty fuel, separate multipliers, one packet, natural versus forced phase, no keyword Consume/Pact. |
| T08 — Poison Strike | Real granted descriptor, 83% and 1200/500 ms; all connected origins, full block/dodge/interrupt, same-timestamp natural depletion and later application ordering. |
| T09 — Critical Poison | Live chance/multiplier including theft-derived changes; one roll per fueled packet, zero roll when empty; no direct-hit hooks/repeats; mitigation and trace/RNG parity. |
| T10 — Bypass | Stab of eligible origins, post-subtree timing, bonuses/doubling/cap, refresh/zero grant, expiry ties, derived elemental stats, cleanup and no charge-confusion. |
| T11 — Toxic Tradeoff | Every proposed factor, source attribution and rank replacement/removal, other elemental damage unchanged, both conversion directions, negative absorb, Shadow Mastery isolation, Weapon Master composition. |
| T12 — Buffs/Powder | Independent Virulent charges and Master lifetimes; empty/mitigated ticks, cooldown skip/exact-ready, IAS exclusion for Self Buffs; Powder cap/refresh/expiry/cleanse and negative absorb. |
| T13 — Gear/mixed | Legal mixed builds and reversals above, bonus stacks/doubling, physical/elemental/crit/IAS gear, conversion, live Thief crit, unchanged accepted Bladedancer/Thief behavior. |
| T14 — Persistence | Isolated Practice save/load/retry, old playable revisions, malformed/unsupported content, fresh Test Mode, protected real saves and Enigma fingerprints. |
| T15 — Player journey | Actual Test Mode selection and Practice both roles, all-rank allocation, tooltips, rotation editing, combat/retry/reset, visible timers/charges and full-tree accessibility. |
| T16 — Rendered UI | Inspect 1280×720, 1600×900, 1920×1080 plus 125% text stress, keyboard/F1/hover/modal flow, truthful Preview labels and no clipping of new content. |
| T17 — Determinism/Lab | Twenty-seed allocated scenarios, repeated traces/outcomes, trace-off equality and repeatable Balance Lab samples/aggregates; no balance certification inferred. |
| T18 — Regression/closeout | Focused Poison, lifecycle, stat, ordering, save, full Blade/Thief and UI suites; required static/manifest checks; exact commands, dates and reports; all remaining work has owners. |

Existing candidate suites include `p6_poison_contract_test`, `p6_status_interactions_test`, `p6_status_completion_test`, `p6_t4_completion_test`, `p6_stat_derivation_test`, `p6_stat_sources_test`, `p6_full_bladedancer_test` and `p6_full_thief_test`. Use the existing isolated foundation runner and verify exact suite names before execution. No inherited suite result is represented as new T7 runtime evidence.

## Review validation

Run `python tools/p6/check_m5_assassin_review.py` from the repository root. The [static review report](../project/reports/p6_m5_t7_review/summary.json) checks canonical inventory, gates/prerequisites, legal allocation sequences under D007, example arithmetic, local references and unchanged runtime/draft fingerprints. It does not execute Godot or certify rendered UI. Implementation, promotion and final acceptance are recorded in the linked T7 closeout.

Executed 2026-10-03: the static review checker and `python tools/p6/build_m5_coverage_ledger.py --check` pass. Four Assassin allocation plans and three partner allocations satisfy the current lower-tier support rule. All 443 captured runtime/data/scene/draft/project fingerprints are unchanged. This was review-preparation evidence only; later implementation validation is recorded in the T7 closeout.
