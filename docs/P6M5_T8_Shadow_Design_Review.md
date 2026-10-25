# M5-T8 — Shadow design review and implementation plan

**D023 update (2026-10-06):** Touch is restored to +2 physical base per consumed Poison. Beguiling Presence also grants +2 percentage points crit chance per consumed Decay. Existing durations and 30-second cooldowns are retained. See [current verification](P6_Shadow_Presence_Crit_And_Touch_Update.md).

**D022 update (2026-10-06):** Touch of Darkness grants +1 base physical damage per consumed Poison (superseding D021’s +2), with its 12-second duration, +10% IAS per stack and 30-second cooldown retained. See [current verification](P6_Shadow_Touch_Damage_Update.md).

**D021 update (2026-10-06):** Dusk Strike also adds +10 Shred Value; Touch of Darkness now grants +2 base physical damage alongside +10% IAS per consumed Poison, both for 12 seconds. Its cooldown remains 30 seconds. Earlier duration descriptions below are historical. See [live verification](P6_Shadow_Touch_And_Shred_Update.md).

**D020 balance update:** Death Strike +2 damage per Poison stack, Death Blade 40/80% without extra crit, Death Touch +3/6/9 stacks supersede earlier values below. See [current verification](P6_Shadow_Death_Balance_Update.md).

**D019 balance update:** Coated Weapons now applies two base Poison stacks; earlier one-stack descriptions below are historical. See [current verification](P6_Shadow_Coated_Weapons_Update.md).

Date: 2026-10-03. Status: **D01–D04 approved by the user under P6M5-D011; implementation complete; see the linked T8 evidence.**

## Scope and authority

Complete `tree.shadow`: one intrinsic, eleven talents / 35 ranks, five populated automatic unlocks, five skills, both tree roles, descriptions and player-flow acceptance. Preserve the [Shadow draft](talent_tree_drafts/Shadow.json) and [canonical identity manifest](P6M2_T4_Content_Identity_Manifest.json). Use [M5's checklist and checkpoint](P6M5_Complete_Rogue_Tree_And_Skill_Implementation_Tracker.md), the [coverage ledger](P6M5_T2_Content_Coverage_Ledger.md), [current combat reference](Combat_Mechanics_Reference.md), and [M3 status contract](P6M3_T7_Status_And_Mitigation_Interactions.md).

The user authorized executing T8. The tracker still explicitly requires decisions on unresolved mechanics before affected implementation. The user approved all four proposals below on 2026-10-03 ("everything looks good"). Existing shared rules remain settled. In particular, preserve [P6M5-D010 Assassin tuning](P6_Assassin_Balance_Implementation.md), D007 lower-tier allocation support and D008 Mug's +50 base-damage cap. Do not enable Adventure or claim M6-wide balance acceptance.

## Decisions for approval

| Decision | Proposed behavior | Rationale / example |
|---|---|---|
| D01 — Beguiling Strike | Attack; **22% weapon damage**, **1700/650 ms** base/minimum, no cooldown; apply **one base Decay** on a connected hit, modified by applicable stacks/doubling. Preserve `skill.toxic_flurry`. | Retain the inherited resolver scaling and skill timing; its resistance effect already represents one Decay application. With weapon roll 100 and neutral stats/defenses, hit for 22, then apply Decay. Dodge/interruption prevents the application; full block still allows it. |
| D02 — Death Strike | Attack; **111% × (weapon roll + current Poison-stack count + applicable flat physical base bonuses)** as one physical packet; **1500/650 ms**, no cooldown. Read actual Poison at impact after due natural ticks, before this cast's new applications; **do not consume Poison**. Preserve `skill.killers_mark`. | Certify the implemented special-case formula rather than treating the two inherited effect resources as two separate hits. With weapon 100, 20 Poison and no other bonus, raw damage is 133.2, rounded to 133 without crit/mitigation. Stack count contributes flat physical base, not Poison tick damage. |
| D03 — Distilled Corruption | Attack; **100% weapon damage**, **1500/650 ms**, no cooldown; connected hit deals physical damage, then **Consumes up to five actual Decay and converts that quantity to Poison**, using the approved conversion order. Preserve `skill.distilled_corruption`. | New numerical proposal because no complete released attack descriptor exists. A full-strength hit at this timing supports its setup/conversion role; approval does not establish balance. With weapon 100 and two Decay, neutral damage is 100 and two Decay are consumed; Poison extras then apply once. A zero-fuel cast still deals its normal hit but makes no conversion application. |
| D04 — Basic passive rank package | **Blind Spot:** +2 percentage points crit/rank (2/4/6/8/10%). **Snake Oil:** +2 base elemental/rank (2/4/6/8). **Deception:** +10% elemental damage/rank as one talent factor (1.1/1.2/1.3/1.4/1.5). **Death from the Shadows:** +20 percentage points crit damage/rank (+20/40/60/80/100%; a base 2x becomes 3x at rank five). | Preserve the draft values and specify their units/buckets. Deception multiplies the other elemental buckets and enters Shadow Mastery's effective percentage calculation. It is not a Poison-only bonus like Toxic Tradeoff. |

For D03, numerical changes are easy to substitute at approval. Its already-approved Consume/conversion behavior is not reopened.

## Intrinsic and allocation

Every selected Shadow tree grants **20% conditional chance for a qualifying direct critical cast to apply one base Poison**. Primary Shadow adds **two percentage points per invested Shadow point**; secondary receives the base chance only. At 0/1/10/20/35 primary points, this chance is 20/22/40/60/90%, clamped with applicable modifiers at the normal chance consumer. This is conditional on a direct crit, not unconditional Poison chance and not crit chance itself. Poison tick crits do not qualify. Eligible procs/repeats can qualify; Death Blade suppresses every Poison source on Stab.

Each rank costs one point. Talent gates require points in strictly lower tiers, following D007; the same-tier points do not satisfy their own gate. Listed prerequisites require one rank. Automatic skill unlocks use total invested points in either role. Refunding/resetting prunes unavailable skills while retaining available duplicates/order and alternative grants.

## All talents and complete rank effects

| Talent / canonical ID | Gate | Ranks and effect | Prerequisite | Authority |
|---|---:|---|---|---|
| Coated Weapons / `talent.shadow.coated_weapons` | 0 | 1: Stab and Heavy Slash each apply one base Poison on connected eligible casts; ordinary extras/doubling/cap. Stab applications are suppressed under Death Blade. | None | Settled shared suppression; bind augment |
| Blind Spot / `talent.shadow.blind_spot` | 0 | 5: +2/4/6/8/10 percentage points crit chance | None | D04 |
| Snake Oil / `talent.shadow.snake_oil` | 0 | 4: +2/4/6/8 base elemental damage | None | D04 |
| Deception / `talent.shadow.deception` | 5 | 5: separate general elemental factor 1.1/1.2/1.3/1.4/1.5 | Snake Oil 1 | D04 |
| Death from the Shadows / `talent.shadow.death_from_the_shadows` | 5 | 5: +20/40/60/80/100 percentage points crit damage | None | D04 |
| Death Touch / `talent.shadow.death_touch` | 10 | 3: +2/4/6 eligible applied stacks, additive with gear extras, before doubling/caps | None | M3 grant contract |
| Death Pact / `talent.shadow.death_pact` | 10 | 3: actual Poison/Decay Consume grants that quantity to **each** Penetration and Potency; each rank adds one second to both debuff timers regardless of source, for 4/5/6 seconds | None | M3; draft's player buff, % unit and 2/4/6 values superseded |
| Shadow Mastery / `talent.shadow.shadow_mastery` | 15 | 5: copy 10/20/30/40/50% of flat elemental bonuses into physical base and the same fraction of the effective elemental percentage bonus into a separate physical factor; retain elemental benefits | Deception 1 | M3 stat contract; excludes class base Poison and Toxic's Poison-only multiplier |
| Dusk Strike / `talent.shadow.dusk_strike` | 15 | 1: a positive Decay application also requests **one base Shred**, independently modified by Shred extras/doubling/cap | None | M3 independent grant contract; do not copy the final Decay quantity |
| Death Blade / `talent.shadow.death_blade` | 15 | 2: 10/20% chance per Poison application that actually adds stacks to proc Stab; Stab cannot apply Poison from any source | Coated Weapons 1 | M3 trigger contract; not per stack, no candidate for cap-only application or ticks |
| Umbral Presence / `talent.umbral_pressure` | 20 | 1: Poison cap becomes 80 | None | Settled cap; preserve canonical legacy ID and new display name |

Ranks are complete replacement values, not cumulative application of all earlier rank resources. Rank zero removes its effect. Each carrier must survive temporary-stat rebuilds, primary/secondary reversal and save round trips without retaining removed effects.

## Skills and unlocks

| Points / slot | Name / canonical ID | Category | Damage | Base/min ms | Cooldown | Effects |
|---|---|---|---|---|---|---|
| 1 / `unlock.shadow.slot_1` | Beguiling Strike / `skill.toxic_flurry` | Attack | 22% weapon, proposed | 1700/650 | 0 | One base Decay; D01 |
| 3 / `unlock.shadow.slot_2` | Death Strike / `skill.killers_mark` | Attack | 111% of combined weapon + Poison count + flat base, proposed | 1500/650 | 0 | Live impact stack read; no Consume; D02 |
| 6 / `unlock.shadow.slot_3` | Distilled Corruption / `skill.distilled_corruption` | Attack | 100% weapon, proposed | 1500/650 | 0 | Consume up to five Decay → one Poison application; D03 |
| 9 / `unlock.shadow.slot_4` | Touch of Darkness / `skill.touch_of_darkness` | Self Buff | — | 500/500 | 30000 | Consume all actual Poison; +10% ordinary additive IAS per stack for eight seconds |
| 12 / `unlock.shadow.slot_5` | Beguiling Presence / `skill.beguiling_presence` | Self Buff | — | 500/500 | 30000 | Consume all actual Decay; +1 base elemental per stack for ten seconds |

No intentionally empty Shadow slots. No talent-granted sixth skill. Self Buffs ignore IAS and do not participate in attack dodge/cleanse/interrupt counters. Shared cooldowns remain keyed by skill ID; unavailable macro cooldown attempts spend 100 ms. Zero fuel still spends the cast/cooldown but cannot erase an existing independent bonus.

## Timing, consumption and triggers

- Follow the existing scheduler: due natural Poison ticks and expiries resolve before equal-time impact reads. Attack damage is resolved before its Consume effects in finalization. Do not let a newly granted Pact debuff retroactively affect the granting physical hit.
- Distilled consumes only actual Decay, up to five. If positive, make one Poison application from that count, add applicable Poison extras once, double, cap; no refund on overflow. Pact grants the actual consumed count to each defense debuff without extras or doubling. Existing same-cast status and trigger ordering is retained and traced.
- Touch's actual Poison consumption grants +10% IAS each for eight seconds. Existing IAS adds; tick cadence preserves progress when IAS changes. M3's independent Touch instances add. Beguiling's actual Decay consumption grants independent ten-second flat elemental instances; Shadow Mastery copies the eligible bonus while it is live.
- Death Touch applies to the established eligible grant channels (Poison, Shred, Decay, Footwork, Bypass, Penetration, Potency), not every charge or conversion. It does not amplify Readiness, Precision, Virulent charges, actual consumption, Pact conversion, or Touch/Beguiling's consumed quantity.
- Death Blade rolls once for each distinct application that adds Poison. Coated and critical-hook applications remain distinct. Stab cannot apply Poison through Coated, critical hooks, conversion or other sources when Death Blade is active, preventing a self-sustaining Poison/Stab loop. Stab may still retrigger through ordinary rules. The existing depth and candidate safeguards remain.
- Shadow Mastery copies bonuses without removing them. Evaluate upstream derived sources such as Fill Your Pockets first. It does not copy the class baseline Poison, Poison-only Toxic factor or the Echoing/Resonance tick multipliers. It does copy eligible Snake Oil, Assassin innate/primary base, Deception, Bypass and Beguiling bonuses.
- Crit chance/crit damage are live at impact/tick under existing rules. One qualifying critical direct cast gets at most one intrinsic roll, even if its effect descriptor contains multiple physical components. Death Strike is one combined packet, one crit decision.

## Player-facing description requirements

Descriptions must distinguish percentage points from multipliers, conditional critical Poison from ordinary crit chance, and tick depletion from Consume. Show every next-rank value, requirements and current invested-point intrinsic chance. Death Strike should say it adds current Poison count to the hit's base without consuming it. Distilled should list its weapon coefficient and exact Consume/conversion cap. Shadow Mastery must say **copy**, never imply removal. Death Pact must describe both enemy debuffs and their real duration, not an extra player buff. Preserve the accepted layout and existing assigned icons; do not revive legacy talent names where a canonical display name is specified.

## Worked examples and boundary cases

| Case | Expected result |
|---|---|
| E01 — Conditional intrinsic | Shadow 35: 90% conditional Poison application chance as primary, 20% as secondary. With 15% direct crit chance and no suppression, per-cast probability is 13.5% versus 3%, before application/cap effects. |
| E02 — Passive package | Blind Spot five adds 10 percentage points; Snake Oil four adds 8 base elemental; Deception five multiplies by 1.5; Death from the Shadows five changes base 2x crit damage to 3x. |
| E03 — Mastery copy | +8 flat elemental, 1.5 elemental factor and Mastery five give +4 physical base and separate 1.25 physical factor, while preserving +8/1.5 elemental. Class base Poison is excluded. |
| E04 — Death Strike | Weapon 100, 20 current Poison and +4 flat physical base: (100+20+4)×1.11 = 137.64, rounded to 138 on a neutral noncrit. Poison remains 20 absent other same-time events. |
| E05 — Distilled and Pact | Two Decay, +6 Poison extras from Death Touch, doubling: consume two, request (2+6)×2 = 16 Poison. Pact requests exactly two of each defense debuff, not sixteen. |
| E06 — Full Poison cap | With Poison already at cap, Distilled still consumes available Decay, grants Pact from actual Consume and requests conversion; accepted Poison is zero, no refund and no Death Blade candidate from that application. |
| E07 — Touch | Twelve actual Poison consumed grant +120% IAS for eight seconds. Existing +20% IAS becomes +140%, not a 2.2x multiplicative increase. Pact grants twelve of each debuff. |
| E08 — Beguiling/Mastery | Seven Decay consumed grant +7 base elemental for ten seconds; Mastery five copies +3.5 physical base while active, with exact recomputation on expiry. |
| E09 — Independent grants | One base Decay with +6 eligible extras/doubling requests fourteen Decay; Dusk's one base Shred with +6 Shred extras/doubling separately requests fourteen Shred. Unequal gear bonuses must produce unequal counts. |
| E10 — Pact expiry | Rank three sets both defense-debuff lifetimes to six seconds, including Powder grants. Deadline-equal reads expire the old debuff before damage. Poison tick depletion/cleanse grants no Pact. |
| E11 — Death Blade | An application adding seven Poison creates one 10/20% roll. A cap-only application creates zero rolls. A proc Stab cannot add Poison but can use ordinary retrigger/Precision rules. |
| E12 — Current Assassin mix | Primary Assassin 35 contributes +22.5 base elemental, secondary +5. Shadow Mastery five copies +11.25 or +2.5 physical base from that contribution; never copy Toxic's Poison-only factor. |

## Legal allocation and comparison fixtures

- **Starter 1:** Coated Weapons 1. Unlock Beguiling Strike; verify suppression only after Death Blade is actually selected.
- **Basic 10:** Coated Weapons 1, Blind Spot 5, Snake Oil 4. All ten points are tier zero; unlock the first four automatic skills. No Beguiling Presence until twelve total points.
- **Consume 15:** Basic 10 + Death Pact 3 + Death Touch 2. Ten lower-tier points support tier-three purchases; verify actual Consume and timer behavior.
- **Mastery 20:** Basic 10 + Deception 5 + Shadow Mastery 5. Fifteen lower-tier points support Mastery, and its Deception prerequisite is present.
- **All ranks 35:** Basic 10 → Deception 5 → Death from the Shadows 5 → Death Pact 3 → Death Touch 3 → Shadow Mastery 5 → Dusk Strike 1 → Death Blade 2 → Umbral Presence 1. Every gate is supported by lower tiers.

Pair full Shadow 35 with an accepted ten-point allocation from each released tree, then reverse roles. For Assassin, Quick Hands 5 + Precision 5 is a legal ten-point partner; for Bladedancer use the established Whetstone 4/Rending Slash 1/Fancy Footwork 5 core; for Thief use Keen Eye 5/Sticky Fingers 5. T8 tests representative integration; T9 still owns the exhaustive six-pair matrix.

## Implementation sequence after decisions

1. Record approved D01–D04 or replacements, then add explicit `project/data/p6/shadow/` rank resources and a reviewed Shadow content adapter. Preserve legacy resource files and canonical skill IDs.
2. Bind the intrinsic, scalar ranks/derivations/augments, cap and explicit Death Pact/Death Blade/Dusk carriers with validation and duplicate-source protection. Reuse current shared mechanics; document and test any actual missing shared contract before using it.
3. Author Distilled's weapon scaling explicitly in the shared skill-scaling path, avoiding a hidden fixed-damage fallback. Certify Beguiling/Death Strike's already-existing behavior through new allocated content.
4. Promote the complete tree with compatible previous revisions; wire display/catalog/icons and descriptions. Retain disabled Adventure and truthful availability.
5. Implement per-rank, primary/secondary, refund/prune, trigger/cap/timer/conversion, stat-rebuild and replay/trace parity tests. Protect the D010 live Assassin baseline and existing Thief/Bladedancer acceptance.
6. Run real Test Mode/Practice allocation-to-fight journeys, saved-build reload/retry, keyboard access and rendered checks at supported widths/scales.
7. Run deterministic Balance Lab batches: full Shadow 35 crude/no-other-gear, reference budgets, damage/trigger/fuel/Consume diagnostics, and representative mixed roles. Use at least 200 seeds for the main DPS comparisons. Mark macros/allocation paths explicitly; do not infer broad balance from one dummy macro.
8. Update the coverage ledger, combat reference, onboarding and tracker; fingerprint promoted sources; remove Preview only after full focused acceptance. T9/T10/T11 remain separate tasks.

## Acceptance groups

| Group | Evidence required |
|---|---|
| T01 Inventory | 11 talents/35 ranks, intrinsic, five skills/five slots, canonical IDs and unchanged drafts |
| T02 Allocation | Every rank, lower-tier gate, prerequisite, budget, refund/reset and duplicate purchase boundary |
| T03 Roles | Intrinsic at 0/1/10/20/35 points in both roles; partner points excluded |
| T04 Scalars | All D04 values, buckets, source attribution, rank replacement and clamps |
| T05 Derived | All Mastery ranks, Snake/Deception, live Beguiling/Bypass, upstream gold derivation, exclusions |
| T06 Grants/caps | Coated, Death Touch, Umbral; bonuses once, doubling, partial capacity and overflows |
| T07 Dusk | Independent Shred count and modifiers, positive application, cleanse/immunity/ignore-Shred cases |
| T08 Pact | Actual Consume only, both debuffs, source-independent duration, cap refresh and deadline expiry |
| T09 Death Blade | 10/20%, positive application only, origin ancestry, all-source Stab suppression, ordinary retrigger chain |
| T10 Beguiling | D01 full descriptor, dodge/block/crit/Decay order, canonical ID and repeat behavior |
| T11 Death Strike | Single packet, combined base formula, impact stack reads, zero/partial/80 fuel, no consumption |
| T12 Distilled | Full proposed descriptor, zero/1/5/over-five Decay, restoration, bonus/doubling/cap/Pact/trigger order |
| T13 Self Buffs | Touch/Beguiling actual fuel, cooldown/zero fuel/independent instances, expiry and live derived stats |
| T14 Mixed | All three partners in both roles, D010 preservation, representative trigger/consumption interactions |
| T15 Determinism | Fixed-seed repeat, trace on/off parity, packet/stack/gold conservation and guard failures |
| T16 Player flows | Practice/Test Mode, allocation-to-fight, descriptions, icons, keyboard, refunds and saved-build reload |
| T17 Balance inquiry | Main 200-seed Shadow cohort, source breakdown and explicit limitations; separate correctness from balance approval |
| T18 Closeout | Regressions, static/source checks, rendered evidence, ledger, compatibility and truthful status |

## Review evidence

`project/reports/p6_m5_t8_review/source_hashes.json` captures the pre-implementation runtime/content/scene/draft/project baseline. Before implementation, the static review checker verified all 310 source fingerprints. After promotion, it checks inventory, legal allocations, example arithmetic, links and immutable draft/identity fingerprints; the release checker covers current runtime sources. Shared-mechanic regression results are recorded separately; they certify existing behavior only, not playable Shadow. D01–D04 were approved under P6M5-D011.

### Completed review validation

- Static review checker passes: eleven talents / 35 ranks, five skills / five slots, five legal D007 builds, example arithmetic, references and all 310 unchanged baseline fingerprints.
- Seven existing regression suites pass: status interactions, status completion, T4 completion, repeat contracts, trigger origins, stat derivation and the D010 live Assassin balance acceptance. See [regression summary](../project/reports/p6_m5_t8_review_regressions/summary.json). These validate existing shared behavior; they do not certify Shadow implementation.
- [Isolation report](../project/reports/p6_m5_t8_review_regressions/isolation.json) confirms protected saves and project files remain unchanged.
- D01–D04 approved under P6M5-D011; runtime acceptance is complete; see [T8 implementation](P6M5_T8_Shadow_Implementation.md).
