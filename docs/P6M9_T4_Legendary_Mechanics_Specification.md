# P6M9-T4 — Legendary roster and mechanics specification

Last updated: 2026-10-26. **Status: approved under P6M9-D014; T4 Complete.**

The user confirms **exactly four new Legendaries: two Pants and two Gloves** and requests the completed specification using the recommended technical defaults.
The item designs and core effects below are confirmed under M9 D010–D012; the roster count is confirmed under M9 D013 by the latest instruction.
The user accepted the consolidated technical defaults under D014 and clarified Arctic Mittens’ visual countdown requirement below. Details marked **technical default** are now part of that approved contract; they were recommendations before D014, not independently earlier approvals.
No runtime implementation, art import, game/simulation run or save reset is part of this document.

Authority: [M9 tracker](P6M9_Gear_Slot_Expansion_And_Progression_Pacing_Tracker.md), [approved T3 pools](P6M9_T3_Stat_Pool_Specification.md), [T2 source audit](P6M9_T2_Gear_System_And_Pacing_Audit.md).
The [M8 Legendary reference](P6M8_T5_Legendary_Mechanics_Specification.md) retains existing mechanics, subject to its latest D091/D095/D097 supersessions.
The companion [four-item contract](../work/m9_t4_spec/roster.json) records exact IDs, values, source art and proposed defaults.

2026-10-26 amendment — **P6M9-D021:** the user supplies the exact compact effect text below and clarifies that Lightning Lord does not enable Poison retriggers; Poison requires Serpent’s Coil. Scales’ activation/Consume scope and Golden’s capped-gold calculation remain unchanged.

## Roster, fixed stats and identities

Retain all 16 current items, their IDs, paths, art, affixes and accepted effects. Add these four for **20 total**.
Final distribution: **7 weapons, 2 helms, 2 armors, 2 charms, 3 trinkets, 2 Legs/Pants and 2 Hands/Gloves**.
One item occupies each slot. The Pants are mutually exclusive; the Gloves are mutually exclusive. No additional Legendary equip cap is introduced.
The Crown of Concentration and Helm of the Samurai remain mutually exclusive helms; no legal fixture may equip both.

| Item / slot | Fixed authored stats, in order | Confirmed signature | Source sprite |
| --- | --- | --- | --- |
| **Serpent’s Scales** / Legs, Pants | `base_elemental_damage = 12`; `percent_elemental_damage = .70`; `crit_applies_potency = .30` | Poison damage activations have a 20% chance to preserve their entire Poison-stack cost, including Decrepit Consume. | Leg Armor / `55.png` |
| **Golden Greeves** / Legs, Pants | `increased_gold = 1.00`; `increased_magic_find = .50`; `shop_discount = .40` | Double the ordinarily capped Overkill Gold component: maximum 100g before Increased Gold. | Leg Armor / `5.png` |
| **Arctic Mittens** / Hands, Gloves | `increased_attack_speed = .30`; `increased_buff_duration = .25`; `cooldown_reduction = .20` | Encounter countdown runs at 75% speed; combat timers run normally. | Gloves / `37.png` |
| **Hands of the Lightning Lord** / Hands, Gloves | `base_damage = 12`; `crit_chance = .15`; `crit_damage = 1.20` | Eligible critical operations have an independent 20% self-repeat opportunity in addition to the ordinary repeat. Includes eligible Poison and repeats only with Serpent’s Coil; does not grant numeric Retrigger Chance. | Gloves / `16.png` |

All four sprite sources are 32×32 and previously visually inspected under D010/D011. Root: `F:\Data\Junk\DPS Game\Purchased Sprites\Rpg Icon Pack\Armor`.
Preserve exact supplied pixels and the spelling **Golden Greeves**. T8 owns project asset destinations, import, icon mapping and actual-size inspection.

| Approved stable item ID | Approved `legendary_effect_id` | Approved resource path |
| --- | --- | --- |
| `gear.legendary.serpents_scales` | `serpents_scales` | `res://data/gear/serpents_scales.tres` |
| `gear.legendary.golden_greeves` | `golden_greeves` | `res://data/gear/golden_greeves.tres` |
| `gear.legendary.arctic_mittens` | `arctic_mittens` | `res://data/gear/arctic_mittens.tres` |
| `gear.legendary.hands_of_the_lightning_lord` | `hands_of_the_lightning_lord` | `res://data/gear/hands_of_the_lightning_lord.tres` |

These identities/paths are approved technical defaults for authored Legendary resources, not generated item IDs. On disk, `res://` is `project/`.
Use canonical affix IDs with `StatModifier.Operation.ADD`, fixed values and the existing Legendary source/tier conventions.
No rarity/depth scaling applies to fixed authored affixes. Ordinary eligible build bonuses still apply; physical base retains its existing All Stats exclusion.
Signature probabilities, factors and caps are fixed: All Stats, Crown, rarity and depth do not scale 20%, 75%, doubling or the 100g cap.
T5 selects stable numeric slot IDs and universal aggregation order, retaining existing numeric identities. This specification does not assign enum values.

## Serpent’s Scales: fuel and actual consumption

Confirmed scope: natural ticks, ordinary forced ticks and Decrepit Blade’s all-stack Poison Strike release.
Touch of Darkness is a separate non-damaging Consume; the signature does not affect it or Shred/Decay consumption.
The +30% Crits Apply Potency affix retains existing direct-critical-contribution eligibility; Poison critical packets do not gain that hook.

**Technical default — one preservation trial:** after live state/expiry preparation, determine the original packet’s requested and available fuel.
For an original activation, `fuel = min(available_poison, requested_cost)`; Decrepit requests all current Poison.
When `fuel > 0` and Scales is equipped, draw once at 20% before stack debit and before the packet’s damage/crit RNG.
On success, `actual_consumed = 0`; otherwise `actual_consumed = fuel`. Damage uses `fuel` in either case.
Preserve the entire qualifying cost, never one trial per stack. Do not remove then refund stacks.
When fuel is zero, emit the normal empty event but no preservation trial, damage/crit packet or damage-derived proc.
Free Poison repeats retain inherited fuel, require no active stack, consume zero and make no Scales preservation draw.

The current implementation derives `legendary_fuel` from `stacks_consumed`; T8 must separate these before introducing preservation.
Keep live Poison damage/modifier calculation, normal conversion/mitigation, talent-enabled crits and Virulent charge spending.
A preserved packet is still a real damage activation and spends available Virulent charges normally; its repeat recalculates from then-live inputs.
Natural clock advancement remains normal. Forced activations/repeats neither reset nor advance the natural Poison clock.
Retain ordering: natural tick before simultaneous impact; direct attack before forced Poison; later on-hit additions and cleanse afterward.
Preserved stacks remain available to later legitimate operations, but cleanse can still remove them.

Decrepit retains keyword Consume. Invoke actual-consumption grants only when `actual_consumed > 0`, once for that original removal.
A preserved Decrepit release grants no Death Pact or other actual-Consume reward; do not pass zero through a bonus-stack grant path.
Ordinary tick depletion does not become keyword Consume. No free repeat grants another Consume reward.
Trace requested cost, available fuel, preserved flag, roll, actual consumed, remaining stacks and repeat-inherited fuel distinctly.

Arithmetic witnesses: a two-stack request with only one available stack deals one-stack damage whether preserved or paid.
A five-stack Decrepit release preserved by Scales deals five-stack damage, leaves five stacks and grants zero consumption reward.
Its repeat has five-stack fuel even if a later operation leaves the enemy empty; no second stack debit or preservation trial occurs.

## Golden Greeves: reward-time Overkill

Let `O = min(50, 10 * floor(max(0, overkill_damage) / 100))`, the ordinary capped component.
While the signature is active, use `G = 2 * O`; otherwise use `G = O`.
Final ordinary encounter gold remains `floor((max(0, encounter_base_gold) + G) * resolved_gold_reward_multiplier)` with existing validation.
Only the Overkill component doubles. Base encounter gold, theft, sales and reroll credits do not receive this signature multiplier.
Losses, invalid results and absent rewards remain ineligible through the existing reward guards.

**Technical default — reward-time activation:** use currently equipped Greeves when calculating/claiming the reward, matching existing live gold-stat semantics.
Inventory ownership alone does not activate the signature, including when carried economy affixes are enabled by another item.
Eligible carried numeric economy affixes retain their established behavior. Rebuild/signature toggles must not increment an already-doubled stored value.
Derive the component afresh from the original result; pending display, save/resume and claim must not double it a second time.
Freeze the computed gold amount at the existing preview/commit boundary before reward grants; deferred animation payout uses that committed amount, not later equipment.
Preserve pre-purchase pricing, capacity, owned-item filters, price/resale floors and reward transaction ownership.

Arithmetic witnesses: Overkill 99/100/499/500/900 gives ordinary 0/10/40/50/50g and Greeves 0/20/80/100/100g.
With 40g base, 500 Overkill and only Greeves’ +100% Increased Gold, the reward is `(40 + 100) × 2 = 280g`.
With an additional eligible +50% Increased Gold, it is `floor(140 × 2.5) = 350g`.
The ordinary cap is applied before doubling; do not raise the raw cap to 100 and then double it again.
Discount/resale profitability and inventory-economy amplification remain T9/T10 review risks; this item does not resolve or retune them.

## Arctic Mittens: nominal countdown and elapsed combat

Confirmed: only the encounter countdown runs at 75%; ordinary elapsed combat proceeds for `B / .75`.
**Technical default:** `B` is the configured positive integer nominal budget in milliseconds; the effective simulation endpoint is `E = ceil(4B / 3)`.
Compute exactly as `E = B + floor(B / 3) + (1 if B % 3 != 0 else 0)` using checked integer additions.
Reject invalid/nonpositive or overflowing inputs through ordinary invalid-result handling; never multiply `B` by four or rely on an overflowing float conversion.
Without Mittens, `E = B` and existing timing/RNG behavior remains identical.

Resolve equipment once immediately before a fight, derive `E` once and freeze both budgets into that result.
Store the authored/configured nominal budget unchanged. Do not mutate a route node, encounter, Practice setting or saved draft to the expanded duration.
Repeated rebuilds, equip toggles and save/resume must not compound duration. Equip changes cannot retime an ongoing result or its replay.
Use the same effective-window contract for Adventure, Test Mode and Practice; Practice’s configured duration is its nominal `B`.
T5/T8 choose the shared API placement, but every entry point must apply the factor exactly once and preserve both result fields.

Preserve current endpoint semantics: casts completing at exactly `E` fit; casts completing later do not.
Natural Poison advancement includes ticks due at `E`; same-timestamp eligible repeat chains finish subject to the ordinary guards.
Cleanup still occurs at `E`. Keep existing expiry-versus-event ordering and skill/resource/cooldown ownership.
Casts, cooldowns, 100ms blocked-slot skips, buffs/debuffs, Poison cadence, stun and interrupt use ordinary elapsed milliseconds.
The +25% Buff Duration and +20% CDR affixes apply through existing additive duration/multiplicative CDR rules, independently of the countdown signature.

Countdown at elapsed simulation time `t` is `max(0, B - .75t)`; clamp to zero on completion.
**D014 visual requirement:** the player must visibly see the countdown ticking 25% slower. Start the main encounter countdown at nominal `B` (20 seconds in the example), not at the expanded 26.667 seconds counting down normally. At normal playback speed, losing one displayed countdown second takes 4/3 seconds of elapsed combat; fractional countdown updates follow the same75% rate. Every encounter countdown representation must use this nominal slowed clock. Keep actual elapsed/log timestamps and the effective endpoint separate. Preserve normal combat/animation pace and existing pause/speed/skip semantics so the faster combat relative to the slower countdown conveys the time-slowing effect.
At rest, show nominal duration. During playback use recorded simulation elapsed time, preserving existing presentation pauses/speed/skip behavior.
Do not change engine time scale or stretch each attack/Poison animation by 4/3. Playback wall time may differ because of existing presentation controls.
Timeline/log timestamps, result duration and actual/required DPS denominators use actual `E / 1000` seconds.
Keep native damage-only DPS and existing Combat Log health-loss-inclusive presentation distinctions; Arctic changes their denominator consistently.
Use enough duration precision in result summaries to distinguish 26.667s from a nominal 20s; presentation rounding must not feed back into DPS.
Show nominal/effective duration in detail context where needed, without adding simulation internals to compact item text.
Generated target pressure metadata remains authored at nominal generation context; displayed encounter required DPS uses the current effective window.

Arithmetic witnesses: `B = 20,000` gives `E = 26,667ms` (the exact continuous endpoint is 26,666.666…ms).
At 10,000ms elapsed the countdown is 12,500ms; at 20,000ms it is 5,000ms. `B = 30,000` gives exactly 40,000ms.
Against 1,000 HP, required DPS for the 20-second example is `1000 / 26.667 ≈ 37.4995`, not 50.
An isolated 1,000ms cast still takes 1,000ms; an 8,000ms cooldown with only the +20% CDR affix lasts 6,400ms.
Do not round the underlying stats again; rounding the effective endpoint once does not authorize per-event rounding changes.

The resolver currently evaluates the full window and then calculates victory/Overkill from total health loss; retain that behavior.
Do not stop at the first lethal hit. More elapsed time may increase total damage and Overkill Gold, but health-removal rules are unchanged.
This longer window is a balance implication for T10, not measured progression evidence in T4.

## Hands of the Lightning Lord: independent critical repeats

Confirmed: a separate 20% critical self-repeat candidate can succeed alongside the ordinary random/guaranteed candidate.
It is neither +20 percentage points of numeric Retrigger Chance nor a fallback roll. Double Dip never reads this signature as a stat.
Dance and Precision still supply at most one ordinary guaranteed self-repeat; they do not suppress Lightning.

**Technical default — operation granularity:** one Lightning candidate per completed, connected eligible Attack cast if any of its own direct damage contributions crit.
Multiple critical contributions in that cast still produce one Lightning candidate. Full mitigation does not erase a recorded critical connected hit.
Dodge, interruption, missing resources, non-Attack operations and noncritical casts produce none.
One fueled critical Poison packet produces one independent Lightning candidate; this includes natural, forced, Decrepit and repeated packets.
The direct Attack and forced Poison from one cast are distinct operations, each eligible on its own crit outcome.
D021 clarification: Lightning Poison eligibility requires Serpent’s Coil. Lightning Lord does not enable Poison retriggers or add numeric Retrigger Chance. With Coil equipped, its independent critical-hit trial remains separate from Coil’s ordinary numeric-chance candidate. This supersedes D014’s earlier no-Coil default.

Snapshot each source operation’s own crit flag, direct eligibility, ordinary guarantee and repeat provenance before resolving descendants.
A descendant crit cannot arm a noncritical parent. A forced Poison crit cannot stand in for its parent Attack’s direct crit.
Keep Locket/Wingjammer’s existing per-critical-contribution/packet hooks unchanged; do not move Lightning into that shared callback once per contribution.
Preserve direct contribution hooks before forced Poison, then forced Poison and its complete repeat chain before later attack-finalization work.

**Technical default — candidate/RNG order:** retain existing authored proc and Death Blade candidate order, then ordinary self-repeat, then Lightning, then Cloak.
Eligible Attack Lightning children use explicit origin `lightning_repeat`; Poison children use `lightning_poison_repeat` with packet provenance.
For Poison, preserve damage/crit, Virulent spend, actual Consume grants, Locket/Wingjammer and repeat Meditation ordering; then ordinary Coil candidate, then Lightning.
Resolve each successful child and its descendants depth-first before evaluating the next sibling candidate.
Thus the parent’s Lightning roll follows the ordinary candidate’s full subtree, while its eligibility snapshot remains fixed.
Absent/ineligible candidates draw no RNG; an ordinary guarantee draws no chance RNG; each eligible Lightning candidate draws once at 20%.
Use the existing `roll <= chance` success convention. Repeats recalculate fresh damage/crit from live state rather than copy a prior outcome.

Attack Lightning repeats are full retriggers: zero windup, normal resource checks, no new macro cooldown, eligible Readiness/Meditation and Cloak hooks.
Cloak’s initially triggered Quick Cut remains an authored proc; only its actual self-repeats qualify as retriggers for repeat-specific hooks.
Poison Lightning repeats retain original packet fuel, consume zero Poison, spend Virulent normally and can crit/qualify again.
They grant eligible Samurai Meditation like existing Poison repeats, but are not attacks and acquire neither Attack Readiness nor Cloak eligibility.
Signet suppresses all critical output and therefore all Lightning trials; its latest conversion factor remains 1.5×.
Exsanguinate remains a noncritical, non-retriggerable Debuff, consuming actual Shred at 1× resolved Shred Value without ordinary damage scaling.

Preserve the shared depth-16 cutoff and 1,024-candidate budget per root, across Attack and Poison descendants.
Count every evaluated eligible candidate, including failed chance trials, against that budget. Natural Poison starts its existing independent root; forced Poison shares the cast root.
At depth cutoff emit diagnostics and no deeper candidate/RNG; at candidate exhaustion invalidate the result using existing failure handling, with no rewards.
No item-specific repeat cap, recursion suppression or silent truncation is added. Both successful siblings may produce further eligible chains.
Record parent/root/source IDs, originating operation, own-crit snapshot, candidate index/origin, chance/roll, depth and budget consumption.

Arithmetic witness: with an ordinary 30% chance and a critical source, the two independent immediate trials give 6% both, 24% ordinary-only, 14% Lightning-only, 56% neither.
A guaranteed ordinary repeat and a successful Lightning trial produce two immediate self-repeat children, before counting descendants.
These are analytical examples; deterministic traversal means their RNG draws need not be adjacent.

## Acquisition, persistence and presentation

**Technical default:** append the four entries to the existing catalog in the table order above; retain existing 16-entry order.
All 20 identities participate in catalog-backed Legendary shops, subject to owned filters and Mysterious Lucky Coin’s current-run unlock gate.
Selection remains uniform per eligible ID conditional on a Legendary outcome, not uniform per slot. All 20 eligible gives 1/20 each; Coin locked gives 1/19.
Existing rarity rolls, prices, Magic Find behavior, owned/pending-offer checks, Cursed fallback and capacity/claim rules remain.
Explicit authored reward pools keep their authored membership unless specifically catalog-backed; adding catalog entries does not rewrite those pools.
Do not add new generated-enemy Legendary outcomes. Seven-slot ordinary generation is T6, separate from these fixed-item definitions.
Sale/destruction restores eligible identity availability under existing gates. Coin destruction unlock stays run-local; Practice cannot mutate it.

Practice exposes all 20 fixed Legendaries in the correct slots, independent of Adventure unlocks, with authored affixes read-only.
Retain separate custom-item editing and carried economy behavior. Test/Adventure use the same signatures and legal equip rules.
Item cards, inventory, equip views, shop/reward hovers, stat detail and Combat Log must identify each source and show accurate fixed values.
Preserve D009’s hidden Adventure shop On equip comparison and retained item/equipped-reference details.
Suggested compact signatures: “Poison ticks have a 20% chance to not consume Poison stacks”; “Overkill gold is doubled”.
Gloves copy: “Encounter countdown runs 25% slower”; “Critical hits have a 20% chance to Retrigger”.
Detail context explains all-stack preservation, free Poison repeats and the two independent opportunities where needed.

Persist authored identity through the canonical catalog reload path, including equipped, inventory, offers/rewards and Practice setup.
Do not reconstruct a fixed Legendary as generic inline numeric gear and lose its signature. Preserve nominal budgets in saved encounter/setup data.
T5/T9 implement the approved reset of all old FacelessVoid saves, including Adventure, legacy `save.json`, core Practice and fallback Practice paths/temporary artifacts.
No migration or live-save deletion is performed here. Protect sibling Enigma data; validate reset/new-format round trips in isolated storage.

## Source anchors and downstream acceptance

| Checked source | Integration implication |
| --- | --- |
| [Legendary catalog](../project/scripts/systems/legendary_catalog.gd#L7) | Current 16 identities and presentation; append four without rewriting existing resources. |
| [Build effect allowlist](../project/scripts/systems/build_resolver.gd#L22) | Register all four new signature IDs; catalog-only additions would otherwise lack active effects. |
| [Poison resolver](../project/scripts/systems/combat_resolver.gd#L972) | Separate fuel/debit; preservation before packet RNG; extend Coil-only candidate branch. |
| [Trigger collection](../project/scripts/systems/combat_resolver.gd#L563), [recursive resolution](../project/scripts/systems/combat_resolver.gd#L745) | Explicit Lightning origins, source snapshots, order, guards and depth-first traversal. |
| [Critical hooks](../project/scripts/systems/combat_resolver.gd#L1732), [Readiness](../project/scripts/systems/bladedancer_effect_lifecycle.gd#L108) | Preserve per-contribution hooks and include Attack Lightning in full retrigger classification. |
| [Shared resolve window](../project/scripts/systems/combat_resolver.gd#L178), [scheduler](../project/scripts/systems/combat_macro_scheduler.gd#L69), [checked timers](../project/scripts/systems/combat_timer_math.gd#L1) | One effective endpoint, exact boundary semantics, checked arithmetic. |
| [Gold reward pipeline](../project/scripts/autoload/build_state.gd#L1558), [shop/reward eligibility](../project/scripts/autoload/build_state.gd#L1192) | Fresh capped component and reward-time activation; retain acquisition gates. |
| [Combat entry](../project/scenes/combat/combat_screen.gd#L2387), [Practice entry](../project/scripts/systems/training_room_state.gd#L1049) | Apply the same derived window once in every mode. |
| [Playback](../project/scripts/ui/combat_playback.gd#L1), [Practice countdown](../project/scenes/training_room/training_room_combat_view.gd#L483) | Elapsed simulation timestamps separate from nominal countdown and presentation time. |
| [Recap](../project/scripts/systems/combat_recap.gd#L87), [Combat Log](../project/scripts/systems/combat_log_inspector_data.gd#L18) | Actual-duration denominators with existing damage/health-loss presentation rules. |
| [Authored save reload](../project/scripts/systems/save_system.gd#L714), [T2 reset inventory](P6M9_T2_Gear_System_And_Pacing_Audit.md) | Catalog identity preservation, new-slot serialization and isolated reset coverage. |

The following are **planned legal representative fixtures**, not game passes, simulations or balance acceptance.
Unlisted slots may be empty or ordinary gear; obtain required talents legally within the 45-point budget and two selected trees. A row may use separate legal two-tree talent variants for different assertions; it does not permit combining three or four trees. Alternate items separated by “/” are separate fixtures.

| Fixture | Required evidence / owner |
| --- | --- |
| Decrepit + Samurai + Cloak + Locket + Coil + Scales + Lightning | Preserved/paid/empty all-stack packets; two candidates; inherited fuel; no zero-Consume grants; full Attack hooks and Poison exclusions. T8/T9. |
| Wyvern + Samurai + Death’s Door + Locket + Wingjammer + Scales + Lightning | Natural cadence; no Lightning Poison repeat without Coil under D021; live charges/crit buffs; partial fuel and recurse/guard traces. T9. |
| Mithril + Samurai + Cloak + Locket + Wingjammer + Greeves + Lightning | Multi-contribution crit deduplication; ordinary guarantees/Mithril chance; both siblings; Readiness/Quick Cut; depth/budget failure. T9. |
| Nightkiss + Crown + Death’s Door + Signet + Coin + Scales + Lightning | No critical/Lightning output; Exsanguinate cannot repeat; 1.5× Signet; no health-removal scaling. T9. |
| Wyvern + Crown + Death’s Door + Locket + Coin + Scales + Arctic | Natural preservation with the longer elapsed window; ordinary cadence/buff timing, no Lightning, correct actual-time DPS and recorded countdown. T9/T10. |
| Bejeweled + Crown + Death’s Door + Locket + Coin + Greeves + Arctic | Nominal/effective timing, normal minimum-time draws/buffs/CDR, 100g cap and reward-time activation; compare a separate no-Arctic control. T9/T10. |
| Each new item across Adventure/Test/Practice | Correct slot/art/card, authored identity round trip, pending offers, eligible-ID selection, no new drop route; effective-window/replay invariance. T6–T9. |

Static review evidence: [verification record](../work/m9_t4_spec/verification.json) checks all four items/twelve fixed stats, sprite provenance/dimensions, source links, catalog counts, legal new-slot pairings, analytical timing/retrigger/Overkill witnesses and unchanged game-file hashes. These checks do not execute gameplay or certify balance.

Review checkpoint completed under **P6M9-D014**: the user accepts the consolidated specification and its technical defaults, with the explicit requirement that Arctic Mittens’ countdown visibly ticks slower at75% rate. The four-item roster remains confirmed under D013.
**T4 is Complete.** Technical choices and the visual countdown requirement are approved; runtime integration and visual acceptance remain downstream. T5–T12 implementation/verification ownership is unchanged.
This document reports source inspection and arithmetic witnesses only. No runtime behavior, visual integration, reset execution or progression outcome is certified.
