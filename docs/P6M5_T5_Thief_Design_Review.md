# M5-T5 — Complete Thief design review

Date: 2026-10-03. Status: **Complete — D01–D03 confirmed by the user under P6M5-D004.**
T6 implementation has not started. Only the approved display-name correction changes presentation data; gameplay behavior and source drafts remain unchanged.

## Scope and authority

Review all ten talents / 35 ranks, the intrinsic, five automatic slots (one empty), four skills, player descriptions and T6 acceptance cases. Keen Eye, Steal and Mug are the playable baseline. Nine talent nodes and Pick Pocket/Big Score remain unpromoted. Numerical tuning belongs to M6.

Sources: [allocation rules](P6M2_T3_Progression_And_Allocation_Rules.md), [combat reference](Combat_Mechanics_Reference.md), [stat derivation](P6M3_T3_Stat_Derivation_And_Temporary_Modifiers.md), [status contracts](P6M3_T7_Status_And_Mitigation_Interactions.md), [gold contracts and D025](P6M3_T10_Gold_And_Mixed_Build_Handoff.md), [identity manifest](P6M2_T4_Content_Identity_Manifest.json), [coverage ledger](P6M5_T2_Content_Coverage_Ledger.md) and [unchanged Thief draft](talent_tree_drafts/Thief.json). The completed [Bladedancer implementation](P6M5_T4_Bladedancer_Implementation.md) is the current playable baseline.

Settled M2/M3 behavior is retained. The user confirmed the complete-node values for Sticky Fingers, Charisma and Loaded Dice under P6M5-D004, explicitly confirming Sticky Fingers is multiplicative. Q06/Q07 from the T2 plan are resolved by these approved definitions and the consumer-validation plan here. This is a design review, not runtime or balance certification.

## Confirmed decisions — P6M5-D004

| Decision | Approved complete behavior | Example |
| --- | --- | --- |
| D01 — Sticky Fingers | Five ranks provide +10/20/30/40/50% Increased Gold using the existing talent multiplier. Preserve multiplicative composition with the Thief intrinsic and the aggregated gear gold bucket. | Primary Thief at 35 points supplies 1.8x; Sticky Fingers five supplies 1.5x. Together: 2.7x gold. Pick Pocket credits 54 gold. Fast Hands five copies the 170% bonus into +85% attack speed. |
| D02 — Charisma | Three ranks add 10/20/30 percentage points of Shop Discount to existing discount sources. Preserve existing purchase-price flooring and the one-gold minimum for positive-price offers. | A base-price 100 offer costs 90/80/70. Rank three plus 20% gear discount costs 50. A total discount of 100% or more still costs one gold. |
| D03 — Loaded Dice | Three ranks add +100/200/300% Magic Find, requiring Charisma rank one. Preserve the existing gear-quality upgrade consumers and Fill Your Pockets interaction. | With no other Magic Find, rank three multiplies each eligible depth-adjusted upgrade chance by four, capped at 100%. Fill Your Pockets five supplies a separate 4x elemental damage factor. |

The user approved these values with the existing system's meaning. They do not introduce a new loot table, discount cap, gold rounding rule or progression rebalance. Large multipliers are explicitly approved; their tuning remains M6.

## Identity, allocation and intrinsic

Canonical tree: `tree.thief`. Preserve the existing `talent.keen_eye`, `talent.sticky_fingers` and `talent.gilded_blade` IDs; the other seven talents use `talent.thief.*`. Silvered Edge is a talent; similarly named gear retains its separate identity. Keep approved icons, authored positions, prerequisite links and the accepted two-tree UI.

Every selected Thief tree grants +10% Increased Gold, including zero investment. Primary Thief additionally grants +2 percentage points per allocated Thief point; secondary receives only the base. At 0/1/5/10/20/35 primary points the intrinsic is +10/12/20/30/50/80%. Points in the other tree do not contribute.

Each rank costs one point within the shared 45-point budget. Check the current own-tree total before purchases; retained-build legality includes retained ranks. Charisma rank one is the only talent prerequisite, for Loaded Dice. Invalid refunds reject atomically. Automatic skills use own-tree investment in either role and cost no extra points. Refunding below an unlock removes only unavailable rotation entries, retaining order and duplicates of still-available skills. Re-unlocking never reinserts removed slots.

## All talents and complete rank effects

Rank values replace earlier ranks rather than accumulate with them. Rank zero removes only the talent's own effect. P = currently playable; S = settled shared contract, binding pending; D = user-confirmed full-node decision above.

| Talent / canonical ID | Gate | Complete rank effects | Prerequisite | State |
| --- | --- | --- | --- | --- |
| Keen Eye / `talent.keen_eye` | 0 | +2/4/6/8/10% physical and elemental damage, in existing talent buckets | None | P |
| Sticky Fingers / `talent.sticky_fingers` | 0 | +10/20/30/40/50% Increased Gold talent multiplier | None | D01 |
| Fast Hands / `talent.thief.fast_hands` | 5 | Copy 10/20/30/40/50% of final Increased Gold bonus into additive increased attack speed | None | S |
| Fill Your Pockets / `talent.thief.fill_your_pockets` | 5 | Separate elemental factor `1 + Magic Find * fraction`, fractions 20/40/60/80/100% | None | S |
| Charisma / `talent.thief.charisma` | 5 | +10/20/30 percentage points Shop Discount | None | D02 |
| Bribery / `talent.thief.bribery` | 10 | One application of 2/4/6 base Shred per positive credited theft event | None | S |
| Silvered Edge / `talent.thief.silvered_edge` | 10 | +1 percentage point crit chance per credited gold stolen this fight; talent contribution caps 25/50/75 points | None | S |
| Finders Keepers / `talent.thief.finders_keepers` | 15 | Encounter-start enemy block multiplied by 0.5/0.0 | None | S |
| Loaded Dice / `talent.thief.load_dice` | 15 | +100/200/300% Magic Find | Charisma 1 | D03 |
| Gilded Blade / `talent.gilded_blade` | 20 | +1 percentage point crit damage per current stash gold, counting at most 500 gold | None | S |

## Skills and unlocks

| Own-tree points | Skill / canonical ID | Category | Weapon scaling | Base / minimum ms | Cooldown | Complete behavior |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | Steal / `skill.steal` | Attack | 106% | 1300 / 650 | 0 | A critical connected hit steals three raw gold. Ordinary critical mitigation and attack-origin eligibility apply. |
| 3 | Mug / `skill.mug` | Attack | 100% | 1500 / 700 | 0 | Add current-fight credited stolen gold to physical base, capped at 100, before ordinary damage scaling and crit. Does not spend gold. |
| 6 | Pick Pocket / `skill.pick_pocket` | Debuff | 0% | 1300 / 800 | 0 | Steal twenty raw gold per completed execution. No damage, dodge or attack repeat. Preserve attack cleanse/interrupt counters. |
| 9 | Intentionally empty | — | — | — | — | Grant nothing; this does not block the twelve-point skill. |
| 12 | Big Score / `skill.big_score` | Attack | 90% | 1800 / 700 | 0 | On crit, double the full current critical multiplier. Noncritical hits do not gain the doubling. Ordinary critical mitigation remains. |

M3-D025 supersedes Pick Pocket's draft “low damage” wording with zero-damage Debuff behavior. No review of that settled choice is requested. Preserve existing timing/minimum/slow rules, missed/interrupted cast rules, trigger filtering, shared scheduler and deterministic ordering. Attack skills may repeat only under eligible existing rules; a Debuff does not gain attack eligibility through theft or Bribery.

## Gold, damage and defense contracts

With ordinary Rogue base multiplier one, aggregated gear Increased Gold `G`, Sticky Fingers bonus `S`, and intrinsic bonus `I`, preserve `M = max(0, (1 + G) * (1 + S) * (1 + I))`. Gear aggregation and its existing special-stat rules occur first. Do not sum these three distinct buckets. Fast Hands reads final `M - 1`, not stash size or raw gold, and adds `fraction * (M - 1)` to increased attack speed. Preserve existing behavior for unusual negative gear inputs; do not silently change shared derivation floors.

Each theft effect credits `max(0, floor(raw * M))` separately. Stash increases by credited gold; the separate fight-theft counter increases by the same amount. Zero credits trigger no Bribery. Rewards, Overkill Gold, pre-existing stash and shop spending are not theft. Playback deposits each recorded credit once, without multiplying it again. Practice retries restore configured stash and reset fight theft. Resolver inputs remain unchanged.

Silvered Edge adds `min(0.01 * fight_theft, 0.25 * rank)` to crit chance before the existing total chance clamp. Gilded Blade adds `0.01 * min(stash, 500)` to crit multiplier. These caps apply only to their own contributions; preserve independent gear sources. Gold changes affect subsequent hits, immediate children and critical Poison; they cannot retroactively change the hit that produced the gold. Bandit Blade remains a build-resolution snapshot, refreshed after spending rather than continuously during combat.

Mug uses fight theft, not stash, and applies its flat bonus before ordinary physical multipliers, weapon scaling and crit. Big Score doubles the full current multiplier on critical hits, including Gilded and independent contributions; ordinary crit negation still applies. Original damage types retain their established modifier/conversion ordering.

Fill Your Pockets reads total resolved Magic Find as a decimal and supplies a separate elemental factor. It does not consume Magic Find. Resolve it before Shadow Mastery copies final eligible elemental bonuses. Preserve elemental/Poison base and gear bucket rules.

Bribery produces one normal Shred application per positive credited theft event, regardless of gold amount. Apply eligible bonus stacks, then doubling, then the 500-stack cap. Weakness and Virulent change Shred Value; Virulent also adds two application stacks and preserves Shred through cleanse. Damage precedes theft-triggered Shred on the granting hit. No application from zero credit; ignore-armor/no-Shred gear suppresses Shred. Future Death Touch/Dusk interactions require harnesses until their trees are promoted.

Finders Keepers modifies encounter-start block, before later Penetration. Full block-denial gear already sets it to zero and is redundant. Penetration may subsequently drive block negative under the settled defense contract; expiry restores the adjusted baseline. This is not a new per-hit 50/100% damage penetration mechanic. Enemy source resources remain immutable.

## Shop, loot and supported T6 access

Charisma uses canonical `shop_discount`, additive with gear. For a positive base price, existing [shop pricing](../project/scripts/autoload/build_state.gd) is `max(1, floor(base_price * max(0, 1 - discount)))`. Preserve null/zero-base offer handling and purchase affordability checks. Refunds or gear changes refresh current prices; do not change offer identities or duplicate rewards.

Loaded Dice uses canonical `increased_magic_find`, additive with gear. Existing reward and shop quality upgrades use the depth-adjusted basis-point chance, multiplied by `max(0, 1 + Magic Find)`, rounded and clamped to 0..10000. Preserve depth rules, deterministic RNG, sequential eligible upgrade steps and high-tier selection. Magic Find increases upgrade chances, not the number of drops or a guaranteed chosen rarity. Already generated items do not retroactively reroll when stats change.

T6 must test actual Test Mode shop prices/purchases and reward/shop generation using allocated talents, not only a scalar PlayerStats fixture. Reach a shop through existing contract flow or an isolated controller harness with declared progression setup. Practice is suitable for combat and derived stats but cannot certify purchasing/loot behavior.

Practice supports primary Thief and role reversal. Test Mode currently starts with Bladedancer; retain that flow and select Thief through its supported secondary control after contract acceptance. The 45-point option permits the full 35-point Thief allocation; primary-Thief integration can be exercised in Practice and Balance Lab. Do not enable Adventure or silently redesign Test Mode selection. T6 must declare its new playable revision and old-Bladedancer/mixed/core compatibility before promotion; no new revision is selected by T5.

## Player-facing description drafts

Use actual current/next rank values, explicit units and source-specific caps. At maximum rank, replace the next preview with “Maximum rank reached.” At zero, show the first-rank effect. Do not expose internal field names in player UI.

| Talent | Description template |
| --- | --- |
| Keen Eye | Gain {2..10}% increased physical and elemental damage. |
| Sticky Fingers | Gain {10..50}% increased gold. Combines multiplicatively with your Thief intrinsic and gear gold multiplier. |
| Fast Hands | Gain attack speed equal to {10..50}% of your total Increased Gold bonus. |
| Fill Your Pockets | Gain a separate elemental damage bonus equal to {20..100}% of your Magic Find. |
| Charisma | Gain {10..30}% Shop Discount. Positive-price items always cost at least 1 gold. |
| Bribery | Each theft that credits gold applies {2/4/6} base Shred stacks, regardless of the amount stolen. Stack bonuses apply. |
| Silvered Edge | Each gold stolen this fight adds 1% crit chance, up to {25/50/75}% from this talent. Starting gold and rewards do not count. |
| Finders Keepers | Enemies begin combat with {50/100}% less block. |
| Loaded Dice | Gain {100/200/300}% Magic Find, increasing eligible gear-quality upgrade chances. Requires Charisma. |
| Gilded Blade | Each gold in your stash adds 1% crit damage, counting up to 500 gold. |

Skill tooltips use the skill table's values and explain: Steal requires a critical hit; Mug counts this fight's theft and caps its base bonus at 100; Pick Pocket is a zero-damage theft Debuff; Big Score doubles critical damage multiplier on crits only. Show conditional/live bonuses as such rather than guaranteeing future damage. Intrinsic text must say primary-tree points, and primary/secondary displays must reflect actual roles.

## Worked examples

| Case | Inputs | Expected result |
| --- | --- | --- |
| E01 — gold composition | Primary Thief 35, Sticky five, gear +20% gold | `1.8 * 1.5 * 1.2 = 3.24x`. Pick Pocket credits 64; Fast Hands five adds 112% IAS. Secondary with identical investment gives `1.1 * 1.5 * 1.2 = 1.98x`, 39 gold, +49% IAS. |
| E02 — event rounding | Two separate raw-three thefts at 1.5x | Four credited each, eight total; not nine. Each positive event can trigger one Bribery application. |
| E03 — stash versus theft | Start stash 400, steal 20 credited | Stash 420, fight theft 20. Mug adds 20 base; Silvered one adds 20 points crit; Gilded adds 420 points crit damage. |
| E04 — own caps | Stash 501, theft 120, Silvered ranks 1/2/3 | Gilded adds 500 points; Mug adds 100 base; Silvered adds 25/50/75 points. Other sources remain; total crit chance still clamps. |
| E05 — Big Score | Neutral target, weapon base 100, full ordinary crit multiplier 3x | Noncrit 90; crit `100 * .9 * 6 = 540`, before any other applicable factors. |
| E06 — shop price | Base price 101, Charisma three, gear discount 20% | Combined 50% discount: floor(50.5) = 50. At 100% discount, positive-price offer costs one. |
| E07 — Magic Find | Depth-adjusted upgrade chance 10%, Loaded Dice three | Magic Find 300%: chance becomes 40%. A 30% chance would cap at 100%. Fill Your Pockets five separately gives 4x elemental damage; Keen Eye five yields 4.4x with otherwise neutral elemental buckets. |
| E08 — Bribery/Shred | Bribery three, Weakness five, Virulent one, base Shred Value ten | One positive theft grants eight stacks at 135 armor each: 1080 armor reduction after that hit. With one extra eligible stack and doubling: eighteen stacks, 2430 reduction, before capacity limits. |
| E09 — cap/zero credit | Existing 499 Shred; request eight. Separately, raw-three theft at .2x | Only one stack fits. The zero-credit theft grants no Bribery; neither overflow nor zero credit becomes extra gold. |
| E10 — block | Enemy block 40, Finders one/two, then ten Penetration | Adjusted baseline 20/0; live block 10/-10. Expiry restores 20/0. Full block-denial gear starts at zero regardless of rank. |
| E11 — spending/retry | Stash 550, Gilded; spend 100 between fights | Next stash-based bonus falls from +500 to +450 points. Spending is not negative theft. Practice retry restores its configured stash instead of accumulating the previous test's credits. |

## Legal T6 fixture plans

Purchase each named talent to the stated rank in this order. These are approved test-build plans under D01–D03, not claims of playable content today. Use fixed seeds and high-HP targets to observe complete rotations; include appropriate armor/block/cleanse targets rather than only neutral targets.

- **Core 5:** Keen Eye 5. Retain the exact M4 mixed fixture as a separate unchanged anchor.
- **Economy 18:** Sticky Fingers 5, Charisma 3, Fast Hands 5, Fill Your Pockets 2, Loaded Dice 3. Covers the prerequisite and both noncombat consumers.
- **Theft 21:** Keen Eye 5, Sticky Fingers 5, Bribery 3, Silvered Edge 2, Finders Keepers 2, Fast Hands 3, Gilded Blade 1. Rotation: Pick Pocket, Steal, Mug, Big Score; add duplicate Steal/Mug cases.
- **All ranks 35:** Keen Eye 5, Sticky Fingers 5, Fast Hands 5, Fill Your Pockets 5, Charisma 3, Bribery 3, Silvered Edge 3, Finders Keepers 2, Loaded Dice 3, Gilded Blade 1.
- **Mixed 45:** Full Thief 35 plus Bladedancer Whetstone 4, Rending Slash 1, Fancy Footwork 5. Run both roles; retain old exact 15/5 mixed and reversed anchors separately. A second targeted fixture uses legal Bladedancer capstone 21 plus Thief 24 for Bribery/Virulent integration.

## T6 acceptance matrix

| Group | Required checks |
| --- | --- |
| T01 — ranks | All ten talents / 35 ranks, zero removal, complete replacement, legal buy/refund/rebuy, maximum+1 rejection, current/next descriptions, fresh rebuild equivalence. |
| T02 — intrinsic | 0/1/5/10/20/35 own points, both roles, role swaps, gear bucket and reset; other-tree points excluded. |
| T03 — gold buckets | Every Sticky rank; intrinsic/gear composition, per-event flooring, multiple theft effects, zero credit and source attribution. |
| T04 — derivations | Every Fast Hands/Fill rank; zero and large gold/Magic Find inputs, gear aggregation, role changes, rebuild without accumulation, timing minimums, Fill before Shadow Mastery harness. |
| T05 — live gold | Stash and theft separation; Silvered each rank below/at/above cap; Gilded 0/499/500/501; rewards/Overkill/spending excluded from theft; children and critical Poison see updated values. |
| T06 — skills | All four descriptors and timings; Steal crit/hit requirements; Mug 0/99/100/101 theft; Big Score noncrit/crit and negation; Pick Pocket category/no damage, no dodge or attack-repeat eligibility. |
| T07 — Bribery | All three base grants, one application per positive event, zero credit, multiple effects, Weakness/Virulent, bonuses/doubling/cap, selective cleanse and ignore-armor/no-Shred. Preserve before/after-hit ordering. |
| T08 — defenses | Both Finders ranks, zero/positive baseline, denial redundancy, later negative block and Penetration expiry; both conversion directions and immutable monster source. |
| T09 — shop | Each Charisma rank, gear composition, fractional-price flooring, one-gold minimum, insufficient/sufficient stash, refund refresh, real purchase/debit and subsequent Gilded/Bandit rebuild. |
| T10 — loot | Each Loaded Dice rank, actual allocated Magic Find into reward and shop generation, deterministic seeds, chance rounding/cap, depth boundaries, existing offer preservation and no extra drops. |
| T11 — build rules | Thresholds immediately below/at/above 1/3/6/9/12 in both roles, empty slot, gates before purchase, Charisma prerequisite/refund rejection, per-tree resets preserving other tree. |
| T12 — player flows | Practice and Test Mode access, editable budget, full allocation, combat locks, ten-slot rotation, duplicates and pruning, retry, role reversal, no automatic reinsertion. |
| T13 — persistence | Declared revision and compatibility, isolated round trips, malformed/unknown revision rejection, no real-save mutation, no stale fight-local theft on reload. |
| T14 — presentation | All talent/rank and skill descriptions, actual gold source breakdown, live stash/theft versus planning values, approved icons/grid, keyboard/tooltips, 125% text and three accepted resolutions; previews removed only after verification. |
| T15 — integration | Exact old core/mixed/reversed parity; legal new fixtures in actual registry; fixed-seed traced/untraced parity and repeated Balance Lab samples; later-tree harnesses clearly marked unpromoted. |

Existing test foundations: `p6_gold_contract_test`, `p6_status_completion_test`, `p6_status_interactions_test`, `p6_stat_derivation_test`, `p6_stat_sources_test`, `p5m11_economy_stats_test`, `p5m7_gold_gain_economy_test`, `p5m11_overkill_gold_test`, `p6_ranked_build_test`, `p6_mixed_journey_test`, `p6_persistence_test` and `p6_balance_adapter_test`. T6 needs new allocation-to-combat/noncombat checks, not only repetition of synthetic shared-mechanic tests.

## Implementation handoff and review status

T6 authors nine complete talent resources, binds Bribery's base-stack rank and Finders Keepers rank through validated ranked resolution, reuses reviewed Gilded/Silvered carriers and Fast Hands/Fill derivations, promotes Pick Pocket/Big Score descriptors and preserves the explicit empty slot. It also verifies all existing Keen Eye ranks, noncombat consumers, descriptions, revision compatibility and supported access.

Static review checks validate inventory, canonical gates/prerequisites, legal purchase examples, exact example arithmetic, references and runtime/draft fingerprints allowing only the exact approved display-name edit. They do not simulate combat or mark remaining nodes playable. See [review evidence](../project/reports/p6_m5_t5_review/summary.json).

T5 is Complete. The user confirmed D01–D03 and corrected the player-facing name to **Loaded Dice**. Preserve canonical `talent.thief.load_dice`, its icon path and historical draft/identity records; the preview label and T6 resources use Loaded Dice. No mechanic remains unresolved in this review. T6 implementation is next and has not started.
