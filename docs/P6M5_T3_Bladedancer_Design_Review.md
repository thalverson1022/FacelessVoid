# M5-T3 — Complete Bladedancer design review

Date: 2026-10-03. Status: **Complete — D01–D03 confirmed by the user; full specification reconciled.**
T4 implementation is next and has not started.

## Scope and authority

This specifies the intrinsic, all 13 talents / 35 ranks, five automatic slots
(one empty), five tree skills including the talent-granted Rending Slash, player
descriptions and acceptance cases. The five currently playable talents remain the
baseline. The eight remaining talents require T4 bindings and validation even
where their shared mechanics were approved and tested in M3.

Source order: [M2 build rules](P6M2_T3_Progression_And_Allocation_Rules.md),
[current combat reference](Combat_Mechanics_Reference.md), the explicit
[first-slice specification](P6M3_T1_Bladedancer_First_Slice_Specification.md),
[stat formulas](P6M3_T3_Stat_Derivation_And_Temporary_Modifiers.md),
[final timed-effect rules](P6M3_T4_Timed_Effects_And_Charges.md),
[repeat rules](P6M3_T6_Triggers_Repeats_And_Critical_Interactions.md),
[status rules](P6M3_T7_Status_And_Mitigation_Interactions.md) and
[M4 closeout](P6M4_T11_Closeout_And_M5_Handoff.md). The
[T2 ledger](P6M5_T2_Content_Coverage_Ledger.md) and
[canonical identity manifest](P6M2_T4_Content_Identity_Manifest.json) connect these
to the [unchanged draft](talent_tree_drafts/Bladedancer.json).

**P** below means already playable in the scoped registry. **S** means reviewed
shared mechanics, with full talent binding still pending. **D** means the
complete-node decision was confirmed in this review. Values remain provisional for balance;
approval establishes behavior for implementation, not M6 balance acceptance.

## Confirmed decisions — P6M5-D003

The user confirmed D01–D03 on 2026-10-03. Weakness and Virulent add to base
Shred Value; Weapon Master interactions are approved, with possible numerical
tuning reserved for M6. The remaining specification preserves settled contracts.

| Decision | Approved complete behavior | Concrete consequence |
| --- | --- | --- |
| D01 — Weakness | Five ranks add +5/+10/+15/+20/+25 **Shred Value**. Add to other Shred Value sources. This changes armor removed per Shred stack, not stacks granted or the cap. | With base Shred Value 10 and rank five, each stack removes 35 armor; a two-stack Rending Slash removes 70 armor after its damage. |
| D02 — Weapon Master | Two ranks give **1.5x / 2x physical damage**, through the existing talent physical multiplier. Applies to originally physical damage before conversion, across skills/origins. Combines multiplicatively with other talent/gear factors and Sharpened Edge; not a rank-one plus rank-two accumulation. | Rank two Weapon Master and rank five Sharpened Edge make eligible Stab/Heavy Slash physical damage 4x before other factors; Quick Cut gets 2x. Originally elemental Poison does not gain Weapon Master merely by being converted to physical. |
| D03 — Virulent Corruption | One rank adds **+100 Shred Value and +2 bonus Shred stacks per eligible application**, and enables the already settled **Shred-only cleanse immunity**. Bonuses add before eligible doubling; cap stays 500. Applies to eligible Shred sources, including later Bribery/Dusk interactions, not only Rending Slash. | Base value 10 + Weakness five (+25) + Virulent (+100) = 135 per stack. Rending requests four stacks and removes 540 armor after its damage, before any extra gear/doubling. Poison, Decay, Penetration and Potency remain cleansable. |

The user's example uses a base one-stack application: with Weakness five and
Virulent, it grants `1 + 2 = 3` stacks, removing `3 * (base Shred Value + 125)`
armor. Rending Slash retains its already approved two-stack base and therefore
grants `2 + 2 = 4`, removing `4 * (base Shred Value + 125)` before other bonuses
or doubling. No universal three-stack replacement or change to Rending is inferred.
No review decision remains open; implementation and runtime acceptance belong to T4.

## Identity, allocation and intrinsic

Bladedancer is a physical combo tree: Quick Cut establishes resources, Stab/Heavy
Slash spend Precision, Plunge spends Footwork, and successful repeats enable
Parry. Shred supplies its armor interaction. Combat remains macro playback.
Exact matchup strength and intended numerical weaknesses belong to M6.

Canonical tree ID is `tree.bladedancer`. Talent IDs below use the
`talent.bladedancer.` prefix. Whetstone retains suffix `wet_stone`; Heavy Strike
means existing Heavy Slash. Keep the accepted authored positions, upward tiers,
two-panel UI, links and icons; this review does not redesign the layout.

The selected tree supplies +5 percentage points numeric retrigger at zero or more
investment. As primary, add +0.2 percentage points per allocated Bladedancer point;
as secondary, receive only the base. Gear retrigger adds normally. At 10/20/35
primary points, the tree supplies 7%/9%/12%. The same investment as secondary
supplies 5%. Guarantees from Precision/Dance never increase that numeric stat.

Each rank costs one point; shared budget is 45. Purchase checks current own-tree
total against the gate before buying. Retained-build/refund checks use the
resulting own-tree total, including retained ranks themselves. All listed
prerequisites need at least one rank; no hidden lower-row-spending requirement.
Automatic skills cost no points and follow current own-tree investment in either
role. Invalid individual refunds reject atomically. Practice can change roles;
Test Mode keeps its existing between-fights planning refunds. Adventure stays
disabled and retains its between-contract rule.

## All talents and complete rank effects

Each listed rank is the complete effect at that rank, not an incremental bonus to
accumulate with previous ranks. At rank zero its talent-owned effects are absent.
Skill unlocks and independent gear/other-tree sources survive if still granted.

| Talent / ID suffix | Gate | Ranks: complete effects | Prerequisite | State / acceptance |
| --- | --- | --- | --- | --- |
| Weakness / `weakness` | 0 | +5 / +10 / +15 / +20 / +25 Shred Value | None | D01; B03 |
| Whetstone / `wet_stone` | 0 | +1 / +2 / +3 / +4 / +5 base physical damage | None | P; B04 |
| Rending Slash / `rending_slash` | 0 | Rank 1 grants `skill.rending_thrust` | None | P; B05 |
| Fancy Footwork / `fancy_footwork` | 5 | 2 / 4 / 6 / 8 / 10% Plunge time reduction **per consumed Footwork stack** | None | P; B06 |
| Precision Attacks / `precision_attacks` | 5 | Rank 1 enables the untimed, one-charge Precision contract below | None | S; B07 |
| Double Dip / `double_dip` | 5 | Copy 50 / 100% of numeric retrigger chance into crit chance | None | S; B08 |
| Opportunity / `opportunity` | 10 | 10 / 20 / 30% chance for connected Quick Cut to proc Rending Slash | Rending Slash 1 | P; B09 |
| Sharpened Edge / `sharpened_edge` | 10 | Stab/Heavy Slash separate physical factor 1.2 / 1.4 / 1.6 / 1.8 / 2.0 | Precision Attacks 1 | S; B10 |
| Cloak & Dagger / `cloak_and_dagger` | 10 | +50 / +100 percentage points crit damage | None | P; B11 |
| Riposte / `riposte` | 15 | Plunge damage factor `1 + 0.1 * rank * consumed Footwork`, ranks 1 / 2 | Fancy Footwork 1 | S; B12 |
| Side Step / `side_step` | 15 | Rank 1 gives Parry effective crit chance 100%; normal crit negation remains | None | S; B13 |
| Weapon Master / `weapon_master` | 15 | Physical damage factor 1.5 / 2.0 | None | D02; B14 |
| Virulent Corruption / `virulent_corruption` | 20 | Rank 1: +100 Shred Value, +2 Shred application stacks, Shred-only cleanse immunity | None | D03; B15 |

## Resource, trigger and damage contracts

**Footwork:** while Fancy Footwork is allocated, a connected Quick Cut of any
origin grants one base stack after its descendants. Apply eligible extra stacks,
then doubling, then cap five. Positive grants refresh the shared three-second
timer, including at cap. Plunge consumes all at accepted cast start and captures
`max(500 ms, ordinary_time * (1 - 0.02 * rank * count))`; ordinary timing already
includes IAS/slow. Preserve integer timing rules. Consumption survives later
dodge/interruption. Plunge can consume exactly at expiry; Quick Cut finishing
exactly at expiry starts a fresh instance after old stacks expire.

**Precision:** connected Quick Cut of any origin grants one untimed charge before
children, cap one; it does not grant again at subtree end. Eligible Stab/Heavy
Slash of any origin consumes it at accepted start, guaranteeing one initial repeat
if connected. A miss/interruption spends the captured charge but produces no
repeat. The guaranteed child has zero windup and resumes ordinary repeat rules;
it does not inherit a free guarantee. Same-hit Death Blade Stab can consume the
new charge. Precision is a separate resource from Assassin's crit talent Precision.

**Readiness:** unlocking Parry enables the shared resource. A connected retrigger
grants one untimed charge after its descendants, cap one. Parry consumes at start.
Without it, Parry spends ordinary cast time with no effect. A child Parry also
needs a charge; its parent's later grant cannot enable it retroactively. Full
block is connected; dodge/interruption is not. Resources reset each fight/retry.

**Dance:** completed activation creates a five-second independent window; cooldown
starts at accepted cast start and is shared across duplicate skill slots. Eligible
macro attacks capture one repeat guarantee at cast start, requiring a connected
hit. Dance/Precision overlap gives one guarantee and still consumes Precision.
Dance activation and other nonattack skills do not manufacture a hit or repeat.
Expiry during an accepted windup does not revoke its captured eligibility.

**Opportunity:** each eligible connected Quick Cut, including proc/repeat origins,
can roll its rank chance for a Rending Slash proc. That child can repeat normally.
Keep stable candidate order, depth-first traversal, 1,024-candidate root budget
and depth-16 suppression. A guaranteed repeat is not an additional numeric RNG roll.

**Damage:** Whetstone adds to physical base. Double Dip copies current numeric
retrigger, excludes guarantees, and clamps final crit to 100%. Sharpened Edge is
skill-specific before conversion/mitigation; Side Step changes Parry's effective
crit, not global crit. Cloak & Dagger adds to the normal crit multiplier (base 2x
becomes 2.5x/3x). Weapon Master uses the existing physical talent bucket;
rank two with Keen Eye five gives `2 * 1.10 = 2.2`, not `1 + 1 + 0.10 = 2.1`.
Gear percentage factors remain separate. Use live impact damage/stat reads;
Footwork/Riposte resource decisions are captured at accepted cast start.

**Shred:** Rending resolves damage before applying two base stacks. Bonuses add
once before doubling; cap remains 500. Armor becomes original armor minus active
stacks times current Shred Value and may become negative under existing mitigation.
Shred does not improve the damage of the same hit that applies it. Virulent's
+2 changes grants, not cap. Its approved immunity protects Shred only;
it does not stop attack cleanse counters or protect other statuses. Existing
ignore-armor/no-Shred gear suppression remains intact.

## Skills and automatic slots

Percentages are weapon scaling, not resource fallback damage. Attack timings use
ordinary IAS/minimum/slow rules; Self Buff ignores IAS but retains existing slow/
minimum-proc rules. Unfinished casts spend no resources or cooldown. An attempted
cooling-down slot spends exactly 100 ms without effects or attack/proc RNG.

| Access | Skill / canonical ID | Category | Weapon scaling | Base / minimum | Cooldown | Behavior |
| --- | --- | --- | --- | --- | --- | --- |
| 1 point | Quick Cut / `skill.quick_cut` | Attack | 66% | 850 / 500 ms | 0 | Supplies Footwork/Precision only when their talents are allocated; Opportunity only when bound. |
| 3 points | Leaping Plunge / `skill.leaping_plunge` | Attack | 190% | 2500 / 500 ms | 0 | Uses available Footwork and Riposte; zero stacks means ordinary timing/damage. |
| 6 points | Parry Strike / `skill.parry_strike` | Attack | 120% | 500 / 300 ms | 0 | Unlock enables Readiness; each cast requires it. Side Step requires its talent. |
| 9 points | Intentionally empty / `unlock.bladedancer.slot_4` | — | — | — | — | No fallback grant; does not prevent 12-point unlock. |
| 12 points | Dance of Death / `skill.dance_of_death` | Self Buff | None | 500 / 500 ms | 20000 ms | Five-second macro guarantee window after activation. |
| Rending Slash rank 1 | Rending Slash / `skill.rending_thrust` | Attack | 78% | 1400 / 650 ms | 0 | Direct damage, then two base Shred. |

Parry Strike and historical Parrying Strike refer to the same skill; preserve
current display presentation and stable ID. Stab, Heavy Slash and Hold remain
class skills. A complete single Bladedancer unlocks five tree skills plus those
three class skills. No blank skill tile is added for the empty slot.

## Worked examples for the review

All examples are specified expectations for T4, not new combat test results.

| Case | Inputs | Expected outcome |
| --- | --- | --- |
| E01 — roles | 35 primary Bladedancer points, gear +8% retrigger | Numeric retrigger 5% + 7% + 8% = 20%; Double Dip two adds 20 crit percentage points. Same points as secondary give 13% retrigger and +13 crit points. |
| E02 — Footwork/Riposte | Fancy Footwork five, Riposte two, five consumed stacks, ordinary Plunge 2000 ms | Plunge takes 1000 ms and deals 2x its otherwise applicable damage. Three stacks instead give 1400 ms and 1.6x. |
| E03 — timing floor | Fancy Footwork five, five stacks, ordinary Plunge 700 ms | Calculated 350 ms becomes 500 ms. No cooldown or added stack capacity is introduced. |
| E04 — guarantee overlap | Precision available, Dance active, connected macro Heavy Slash, numeric retrigger zero | Precision is spent; exactly one guaranteed child. Double Dip receives no additional crit from either guarantee. With nonzero numeric retrigger, the child may continue normally. |
| E05 — same-hit child | Quick Cut critically applies Poison and a Death Blade Stab proc succeeds; Precision Attacks bound | Quick Cut grants Precision before dispatch; the child Stab can spend it. Stab cannot apply Poison, so it cannot recursively feed Death Blade through a Poison application. |
| E06 — Weapon Master | Otherwise 100 pre-mitigation Stab physical damage, Weapon Master two, Sharpened Edge five | 400. Equivalent Quick Cut physical damage becomes 200. Add Keen Eye five to the same Stab example: 440. No crit or other gear factors in this example. |
| E07 — Shred package | Base Shred Value 10; Weakness five, Virulent one; Rending hits target with armor 600 | First hit uses pre-application armor. Four stacks at value 135 reduce armor afterward to 60. With one extra eligible gear stack and doubling: `(2+2+1)*2=10` stacks, armor becomes -750. |
| E08 — selective cleanse | Virulent active, target has Shred, Poison, Decay, Penetration and Potency | Cleanse leaves Shred and removes the other cleansable statuses unless a separate full-denial source applies. |
| E09 — per-rank replacement | Weapon Master rank one upgraded to two | Factor changes 1.5x to 2x, not 3x. Refund to one restores 1.5x; other sources remain. |
| E10 — capped grant | 499 Shred, Virulent Rending requests four | Add one, discard three; value bonuses do not increase the 500 cap. |

## Player-facing description drafts

These are text templates for the accepted UI, with selected/current and next-rank
values substituted by T4. D01–D03 wording now reflects the confirmed decisions. Detailed timing/origin
rules belong in expanded details rather than overcrowding the main description.

| Item | Primary description |
| --- | --- |
| Intrinsic | +5% Retrigger Chance. As your primary tree, gain another +0.2% per point invested in Bladedancer. |
| Weakness | +{5/10/15/20/25} Shred Value. Each Shred stack removes this much additional armor. |
| Whetstone | +{1/2/3/4/5} base physical damage. |
| Rending Slash | Unlock Rending Slash: deal 78% weapon damage, then apply 2 Shred stacks. |
| Fancy Footwork | Quick Cut hits grant Footwork for 3 seconds, up to 5 stacks. Leaping Plunge consumes all stacks to reduce its cast time by {2/4/6/8/10}% per stack, down to its minimum. |
| Precision Attacks | Quick Cut hits grant Precision. Your next Stab or Heavy Slash consumes it to repeat once if it hits. |
| Double Dip | Gain crit chance equal to {50/100}% of your Retrigger Chance. Guaranteed repeats do not count. |
| Opportunity | Quick Cut hits have a {10/20/30}% chance to trigger Rending Slash. |
| Sharpened Edge | Stab and Heavy Slash deal {20/40/60/80/100}% more physical damage. |
| Cloak & Dagger | +{50/100}% critical damage. |
| Riposte | Each Footwork stack consumed increases that Leaping Plunge's damage by {10/20}%. |
| Side Step | Parry Strike has 100% crit chance. Enemy critical-damage negation still applies. |
| Weapon Master | Deal {50/100}% more physical damage. |
| Virulent Corruption | +100 Shred Value. Apply 2 additional Shred stacks per application. Your Shred cannot be cleansed. |
| Quick Cut details | Deal 66% weapon damage. 0.85-second base cast; 0.50-second minimum. Show actual bound talent additions rather than promising preview effects. |
| Leaping Plunge details | Deal 190% weapon damage. Consume Footwork for its cast-time benefit and any allocated Riposte bonus. 2.50-second base; 0.50-second minimum. |
| Parry Strike details | Requires Readiness, gained when a retriggered attack hits. Consume it to deal 120% weapon damage. Without Readiness, the cast has no effect. 0.50-second base; 0.30-second minimum. |
| Dance of Death details | For 5 seconds, your macro attacks repeat once if they hit. Repeats still need their required resources. 0.50-second cast; 20-second cooldown. Precision does not add another guaranteed repeat. |

In details, identify chance/damage additions as percentage points where needed.
Show Cloak's resulting critical multiplier so +100% is not read as doubling the
entire current multiplier. Bonus Shred grants and resulting totals must be distinct.
All previews remain previews until implementation is verified.

## Acceptance matrix and legal fixture plan

Apply B01 to every rank, not only maximum ranks. Case IDs B01–B21 are local to this
specification; T2's B01–B04 dependency IDs remain a separate namespace.

| Case | Required T4 evidence |
| --- | --- |
| B01 — 35 ranks | For each of 13 talents, buy every rank legally, inspect complete resolved effects/units and current/next text, refund/rebuy, compare fresh rebuild. Verify zero disables its own effects, max+1 rejects, no rank accumulation. |
| B02 — intrinsic | Primary/secondary at 0/1/10/20/35 invested points; gear addition, role reversal and reset; no numeric contribution from Precision/Dance. |
| B03 — Weakness | D01 values each rank; Shred Value versus count; no same-hit damage improvement; bonus source composition and refund. |
| B04 — Whetstone | All five flat-base values with gear, weapon scaling and conversion; preserve stable wet_stone ID and approved name. |
| B05 — Rending grant | Unlock at rank one, invalid prerequisite refund rejection with Opportunity, valid removal/pruning, alternate retained grant survival. Full block grants Shred; dodge/interruption does not. |
| B06 — Footwork | All five rank coefficients, 0/1/3/5 stacks, extra/double/cap/refresh, exact expiry and +/-1 ms, cast-start loss on miss, timing minimum; compare E02/E03. |
| B07 — Precision | Charge cap one, no timer, macro/proc/repeat origins, pre-child grant once, consumed on miss, overlap with Dance, no global retrigger increase; same-hit child fixture. |
| B08 — Double Dip | Fractions 0.5/1.0, base/gear/role inputs, final crit clamp, no guarantee contribution; E01. |
| B09 — Opportunity | 10/20/30% compiled chances, deterministic source filtering, children and repeats, prerequisite at one rank; ordering/budget/depth/replay coverage retained. |
| B10 — Sharpened | All five factors on Stab/Heavy Slash only, all origins, before conversion; Precision prerequisite; no extra packet or scaling of unrelated elemental effects. |
| B11 — Cloak | +0.5/+1.0 crit multiplier, other sources retained; regular crit negation; no accidental multiplier doubling. |
| B12 — Riposte | Both ranks with 0..5 consumed stacks, captured multiplier, child consumes its own stacks, deadline exception, Fancy prerequisite; E02. |
| B13 — Side Step | Parry crit at zero ordinary crit, crit negation, readiness failure, other skills unchanged; successful hit hooks use ordinary critical flag. |
| B14 — Weapon Master | D02 rank replacement, all physical skills/origins, talent/gear/Sharpened product, both conversion directions; E06/E09. |
| B15 — Virulent | D03 combined bonuses, gear/Death Touch extra stacking, doubling, 499/500 boundary, no cap increase, cleanse preserves only Shred, ignore-armor/no-Shred suppression; E07/E08/E10. |
| B16 — unlocks | Counts just below/at/above 1/3/6/9/12, both roles, empty nine-point slot, later Dance still available, Parry enables Readiness independently of Fancy. |
| B17 — edits/flows | Buy gates checked before purchase; retained refunds count own ranks; all three prerequisites; per-tree reset preserves other tree; duplicate rotation order and ten-slot cap; no automatic reinsertion on re-unlock; combat/playback locks. |
| B18 — Dance/timing | 500/500 ms and 20 s shared cooldown, grant at completion, exact five-second window, expiry during cast, clipped cast, cooling slot 100 ms, nonattack activation no repeat, Parry resource requirement. |
| B19 — persistence/access | Full Bladedancer selectable/reachable in Practice and supported Test Mode access; old-core/mixed setups remain legal under declared policy; isolated round trip/retry, malformed/future rejection, fresh Test Mode no persistence. |
| B20 — presentation | All 13 nodes/35 ranks and five skills described truthfully; approved icons/grid retained; keyboard/tooltip/125% text and accepted resolutions; rendered busy combat shows new buffs and source contributions. |
| B21 — interactions/lab | Retain exact M4 core/mixed/reversed anchors; new legal builds below, fixed seeds and trace equivalence in Balance Lab; use harnesses for unpromoted partner mechanics without calling those partner trees playable. |

Suggested legal purchase sequences (numbers are final ranks after each purchase
group; check a gate before each individual purchase within a group):

- **Core 10:** Whetstone 4 → Rending 1 → Fancy Footwork 5. Existing anchor.
- **Precision 16:** Whetstone 5 → Precision Attacks 1 → Double Dip 2 → Rending 1 →
  Fancy Footwork 1 → Sharpened Edge 5 → Weapon Master 1. Exercises three early
  paths plus the row-four gate; Weapon Master uses confirmed D02.
- **Shred capstone 21:** Whetstone 5 → Weakness 5 → Rending 1 → Opportunity 3 →
  Cloak & Dagger 1 → Weapon Master 2 → Double Dip 2 → Fancy Footwork 1 →
  Virulent Corruption 1. Exercises capstone at the earliest total after gate 20.
- **All ranks 35:** Weakness 5 → Whetstone 5 → Rending 1 → Fancy Footwork 5 →
  Precision Attacks 1 → Double Dip 2 → Opportunity 3 → Sharpened Edge 5 →
  Cloak & Dagger 2 → Riposte 2 → Side Step 1 → Weapon Master 2 → Virulent 1.
  This validates full single-tree coverage. With current Thief Keen Eye 5 it
  becomes a legal 40-point pair in either role; do not invent five additional
  playable Thief ranks just to fill a 45-point budget.

Use inherited deterministic seeds and target cohorts from the T2 matrix. T4
completes Bladedancer plus currently playable Thief interactions. T9 completes
full partner-tree permutations after those trees are promoted. Shared fixtures
can check Death Touch/Death Blade/Bypass interactions earlier without bypassing
their own content reviews. No DPS/win-rate target or balance pass is implied.

## T4 implementation handoff and closeout gate

Preserve the five playable talents and existing skill descriptors. Add the eight
missing talent resources with explicit complete ranks, then carry Precision
enablement (untimed), Riposte rank, Side Step and Shred cleanse immunity through
`TalentRank` → `RankedBuild` → `BuildResolver` → `PlayerStats` with validation and
source tracking. Existing stat/derivation carriers handle Weakness, Double Dip,
Sharpened Edge, Weapon Master and Virulent's scalar bonuses. Do not enable effects
by matching display names or by injecting combat fixtures into the player UI.

Provide a supported Test Mode path to the approved full-tree acceptance builds;
its current ten-point start alone cannot exercise the capstone. Practice already
has a 45-point default. Preserve accepted UI; bring an actual control/layout
conflict to the user. Select and document the content revision in T4, with old-core
and mixed Practice compatibility tests. Adventure remains disabled. T4 must run
focused allocation-to-combat checks and rendered checks before removing previews.

Existing test candidates: `p6_ranked_build_test`, `p6_stat_derivation_test`,
`p6_stat_sources_test`, `p6_effect_combat_test`, `p6_t4_completion_test`,
`p6_repeat_contracts_test`, `p6_trigger_origins_test`, `p6_status_interactions_test`,
`p6_core_journey_test`, `p6_mixed_journey_test`, `p6_persistence_test`,
`p6_balance_adapter_test`, `p6_skill_ui_test` and `p6_t10_usability_test`. Reuse
their assertions where relevant and add checks for the new actual bindings.

Completed: full content/rank/skill specification, settled-rule reconciliation,
description drafts, ten examples, 21 acceptance groups and four legal build plans.
The user confirmed D01–D03; P6M5-D003 records the answers. The combat reference,
ledger and trackers are reconciled. T3 is Complete. T4 owns runtime implementation,
content promotion, functional descriptions and new gameplay/rendered validation.

## Validation record

[T3 static review evidence](../project/reports/p6_m5_t3_review/summary.json) records
inventory/gate/prerequisite reconciliation, legal purchase-sequence calculations,
worked-example arithmetic, document links and the unchanged source fingerprints.
These are specification checks, not executed gameplay or rendered acceptance.
No runtime code, source draft, save or content revision changed. Approved content
rules are now recorded; this is not a claim of new runtime validation.
