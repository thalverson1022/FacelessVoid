# M7-T5 Tooltip Audit and Verification

Current task status: **Complete — user accepted T5 under D039 on 2026-10-15.** See [closeout and accepted conventions](P6M7_T5_Closeout_And_Accepted_Conventions.md).

The dated status, proposals and evidence below are historical snapshots; later accepted conventions and D039 supersede earlier In progress/closeout-excluded instructions.

Status: **In progress - requested steps 1-6 implemented; step 7 closeout excluded.**

Date: 2026-10-13. Later live-format approval: [D025 minimal skill tooltip design](P6M7_T5_Minimal_Skill_Tooltip_Design_And_Implementation.md), 2026-10-14. This audit retains historical wording-verification evidence; the approved minimal skill hover now supersedes its verbose player-facing format. This record documents presentation edits and reproducible evidence; it does not close T5, M7, accessibility review or human playtesting.

## Authority and scope

Read the current onboarding guide, M7 tracker, T2 audit (G01-G05/G08), T3 accepted conventions and Combat Mechanics Reference. Audited the executable registry (`BuildContentRegistry.test_mode()` and Adventure revision), live `TalentRank` resources, `playable_*_content.gd` overrides, skill contracts, resolver constants, temporary-effect snapshots and gold/stack consumers. Historical draft and resource descriptions are not executable authority. All combat math, identities, ranks/gates, cooldowns, save behavior and installed source art are preserved.

The inventory is **44 talents / 140 ranks / 23 skills**: Bladedancer 13 talents/35 ranks, Thief 10/35, Assassin 10/35, Shadow 11/35. The three base Rogue skills are Hold, Stab and Heavy Slash. All twenty authored automatic slots are inventoried, including the intentionally empty Bladedancer/Thief nine-point slots. Rending Slash and Poison Strike are talent unlocks. Every rank's disposition appears below; complete extracted strings and icon paths are in the [live inventory JSON](../project/reports/p6_m7_t5_final/p6_m7_t5_inventory/p6_m7_t5_inventory/inventory.json).

## Corrections and retained contracts

| Finding | Presentation change | Mechanics checked |
| --- | --- | --- |
| G01 Death Strike | Shared summary/condition now say `111% x (weapon damage + 2 x current Poison count + applicable flat physical bonuses)`; Poison is read at impact and not consumed. | Resolver constant is 2.0; weapon coefficient 1.11. Boundaries 0/1/10 stacks correspond to 111/113.22/133.2 with a 100 weapon and neutral modifiers. |
| G02 Mug | Compact text now gives +1 base physical per credited fight-stolen gold, cap +50; starting stash excluded. | Actual helper gives 0/1/49/50/50 at credited theft 0/1/49/50/51. No gold spent. |
| G03 Pick Pocket | Compact text explains credited theft from ten raw gold, no direct damage, dodge/attack-counter exclusions, Bribery and eight-second shared cooldown. | Increased Gold floors each theft once; 55% gives 15 credited, not 15.5. |
| G04 Rank language | UI labels distinguish base physical/elemental and percentage bonuses; Death Touch lists eligible stack applications. Toxic Tradeoff's physical penalty appears once, paired with Poison-only bonus. Primary scaling uses invested points, not levels. | Every scalar/special rank matched to live bindings. Death Pact conversions do not receive extra stack grants/doubling; charges are not extra stack grants. |
| Additional intrinsic precision | Tree heading hover preserves Assassin +0.5 per primary point instead of rounding it to +1. | Runtime already used 0.5. Both roles receive base intrinsics; primary alone scales. |
| G05 Big Score | Compact summary includes six times the full current critical multiplier, conditional on a crit. | A normal 3x crit becomes 18x; gold bonuses are included before multiplication. Noncrits receive no factor; enemy crit negation remains. |
| G08 Effects | Shared current names replace Rending Thrust/Killers Mark/Toxic Flurry aliases in inspector source, cooldown and cast/event presentation. Hover/inspector explain all ten buffs and timed defenses with stacks/charges/consumed status units and meaningful magnitude labels. | Snapshot amounts retained. Beguiling shows actual elemental and critical bonuses. Touch shows actual consumed Poison bonuses. Shared versus independent timers and held-until-impact consumption remain unchanged. |
| Long rank hover | Custom tooltip uses a wider text column for strings over 600 characters. Current/Next and purchase restrictions remain visible. | Presentation geometry only. Worst invested Shadow Mastery 4/5 + next 5/5 reviewed at 1280/125%, including engine edge repositioning. |

Available Skills and macro share `compact_tooltip`; tree skill boxes share summary/conditions. The four approved category tooltips retain their format. Virulent's category and ordinary paths both explain independent activations and fueled natural/forced ticks. Category Stab now includes relevant Precision conditions. Full detail formatter retains base/minimum/planning time and shared cooldown instead of truncating four selected skills to the prototype text.

**Current live detail boundary:** `skill_details_dialog.gd` remains a retained component; the current palette/macro do not expose an inspection affordance. Its rendered screenshots are component verification, not evidence of an added live dialog. This task does not introduce a new interaction.

## Intrinsics and automatic unlocks

Shadow's 20% base plus 2 percentage points per primary point is conditional on a direct critical hit, applying one base Poison through stack rules; Poison critical ticks do not qualify. Bladedancer starts with 5% numeric Retrigger plus 0.2 percentage points per primary point. Thief starts with 10% Increased Gold plus 2 percentage points per primary point. Assassin has +5 base elemental plus +0.5 per primary point. The selected secondary receives base benefits and its point unlocks; it receives no primary scaling.


### Bladedancer

| Points | Unlock | Disposition |
| --- | --- | --- |
| 1 | Quick Cut | Retain live rule |
| 3 | Leaping Plunge | Retain live rule |
| 6 | Parry Strike | Retain live rule |
| 9 | Empty slot | Retain live rule |
| 12 | Dance Of Death | Retain live rule |

### Thief

| Points | Unlock | Disposition |
| --- | --- | --- |
| 1 | Steal | Retain live rule |
| 3 | Mug | Retain live rule |
| 6 | Pick Pocket | Retain live rule |
| 9 | Empty slot | Retain live rule |
| 12 | Big Score | Retain live rule |

### Assassin

| Points | Unlock | Disposition |
| --- | --- | --- |
| 1 | Venom Jab | Retain live rule |
| 3 | Blinding Powder | Retain live rule |
| 6 | Virulent Poison | Retain live rule |
| 9 | Master Of Poisons | Retain live rule |
| 12 | Poison Vile | Retain live rule |

### Shadow

| Points | Unlock | Disposition |
| --- | --- | --- |
| 1 | Beguiling Strike | Retain live rule |
| 3 | Death Strike | Retain live rule |
| 6 | Distilled Corruption | Retain live rule |
| 9 | Touch Of Darkness | Retain live rule |
| 12 | Beguiling Presence | Retain live rule |

## Talent and rank dispositions

Gate values are invested points in lower tiers of the same tree. Listed prerequisites require one rank. Every rank 1 through the listed maximum was read from the live rank array and reviewed; `Retain` means no specific mismatch found in this audit, not certification of every gear combination.

| Tree / talent | Ranks reviewed | Gate | Prerequisites | Disposition |
| --- | --- | --- | --- | --- |
| Bladedancer / Whetstone | 1-5 | 0 | None | Base physical terminology |
| Bladedancer / Rending Slash | 1-1 | 0 | None | Retain live wording/mechanics |
| Bladedancer / Fancy Footwork | 1-5 | 5 | None | Clarify minimum cast boundary |
| Bladedancer / Opportunity | 1-3 | 10 | talent.bladedancer.rending_slash | Retain live wording/mechanics |
| Bladedancer / Cloak & Dagger | 1-2 | 10 | None | Retain live wording/mechanics |
| Bladedancer / Weakness | 1-5 | 0 | None | Retain live wording/mechanics |
| Bladedancer / Precision Attacks | 1-1 | 5 | None | Retain live wording/mechanics |
| Bladedancer / Double Dip | 1-2 | 5 | None | Retain live wording/mechanics |
| Bladedancer / Sharpened Edge | 1-5 | 10 | talent.bladedancer.precision_attacks | Retain live wording/mechanics |
| Bladedancer / Riposte | 1-2 | 15 | talent.bladedancer.fancy_footwork | Retain live wording/mechanics |
| Bladedancer / Side Step | 1-1 | 15 | None | Retain live wording/mechanics |
| Bladedancer / Weapon Master | 1-2 | 15 | None | Physical percentage terminology |
| Bladedancer / Virulent Corruption | 1-1 | 20 | None | Retain live wording/mechanics |
| Thief / Keen Eye | 1-5 | 0 | None | Physical/elemental percentage terminology |
| Thief / Sticky Fingers | 1-5 | 0 | None | Retain live wording/mechanics |
| Thief / Fast Hands | 1-5 | 5 | None | Retain live wording/mechanics |
| Thief / Fill Your Pockets | 1-5 | 5 | None | Retain live wording/mechanics |
| Thief / Charisma | 1-3 | 5 | None | Retain live wording/mechanics |
| Thief / Bribery | 1-3 | 10 | None | Retain live wording/mechanics |
| Thief / Silvered Edge | 1-3 | 10 | None | Retain live wording/mechanics |
| Thief / Finders Keepers | 1-2 | 15 | None | Retain live wording/mechanics |
| Thief / Loaded Dice | 1-3 | 15 | talent.thief.charisma | Retain live wording/mechanics |
| Thief / Gilded Blade | 1-1 | 20 | None | Retain live wording/mechanics |
| Assassin / Quick Hands | 1-5 | 0 | None | Retain live wording/mechanics |
| Assassin / Precision | 1-5 | 0 | None | Retain live wording/mechanics |
| Assassin / Hastened Poison | 1-5 | 5 | None | Retain live wording/mechanics |
| Assassin / Echoing Toxin | 1-3 | 5 | None | Retain live wording/mechanics |
| Assassin / Poison Strike | 1-1 | 5 | None | Retain live wording/mechanics |
| Assassin / Bypass | 1-1 | 10 | None | Retain live wording/mechanics |
| Assassin / Toxic Tradeoff | 1-5 | 10 | None | Remove duplicate physical penalty |
| Assassin / Accelerant | 1-5 | 15 | talent.assassin.hastened_poison | Retain live wording/mechanics |
| Assassin / Resonance | 1-4 | 15 | talent.assassin.echoing_toxin | Retain live wording/mechanics |
| Assassin / Critical Poison | 1-1 | 20 | None | Retain live wording/mechanics |
| Shadow / Coated Weapons | 1-1 | 0 | None | Retain live wording/mechanics |
| Shadow / Blind Spot | 1-5 | 0 | None | Retain live wording/mechanics |
| Shadow / Snake Oil | 1-4 | 0 | None | Base elemental terminology |
| Shadow / Deception | 1-5 | 5 | talent.shadow.snake_oil | Elemental percentage terminology |
| Shadow / Death from the Shadows | 1-5 | 5 | None | Retain live wording/mechanics |
| Shadow / Death Touch | 1-3 | 10 | None | List eligible stack grants |
| Shadow / Death Pact | 1-3 | 10 | None | Retain live wording/mechanics |
| Shadow / Shadow Mastery | 1-5 | 15 | talent.shadow.deception | Retain live wording/mechanics |
| Shadow / Dusk Strike | 1-1 | 15 | None | Retain live wording/mechanics |
| Shadow / Death Blade | 1-2 | 15 | talent.shadow.coated_weapons | Retain live wording/mechanics |
| Shadow / Umbral Presence | 1-1 | 20 | None | Retain live wording/mechanics |

## Skill dispositions

| Skill / stable identity | Unlock source | Cast / minimum / cooldown (seconds) | Disposition |
| --- | --- | --- | --- |
| Hold / `skill.hold` | class.rogue | 1 / 1 / 0 | Retain live summary/condition |
| Stab / `skill.stab` | class.rogue | 1.5 / 0.7 / 0 | Category path retains conditional Precision note |
| Heavy Slash / `skill.heavy_slash` | class.rogue | 2.2 / 0.9 / 0 | Retain live summary/condition |
| Rending Slash / `skill.rending_thrust` | talent.bladedancer.rending_slash | 1.4 / 0.65 / 0 | Retain live summary/condition |
| Quick Cut / `skill.quick_cut` | tree.bladedancer:1 | 0.85 / 0.5 / 0 | Retain live summary/condition |
| Leaping Plunge / `skill.leaping_plunge` | tree.bladedancer:3 | 2.5 / 0.5 / 0 | Retain live summary/condition |
| Parry Strike / `skill.parry_strike` | tree.bladedancer:6 | 0.5 / 0.3 / 0 | Retain live summary/condition |
| Dance Of Death / `skill.dance_of_death` | tree.bladedancer:12 | 0.5 / 0.5 / 20 | Retain live summary/condition |
| Steal / `skill.steal` | tree.thief:1 | 1.1 / 0.65 / 0 | Retain live summary/condition |
| Mug / `skill.mug` | tree.thief:3 | 1.5 / 0.7 / 0 | G02 corrected |
| Pick Pocket / `skill.pick_pocket` | tree.thief:6 | 1.8 / 0.8 / 8 | G03 corrected |
| Big Score / `skill.big_score` | tree.thief:12 | 1.8 / 0.7 / 0 | G05 defining crit condition added |
| Poison Strike / `skill.poison_strike` | talent.assassin.poison_strike | 1.2 / 0.5 / 0 | Retain live summary/condition |
| Venom Jab / `skill.venom_jab` | tree.assassin:1 | 1 / 0.5 / 0 | Retain live summary/condition |
| Blinding Powder / `skill.blinding_powder` | tree.assassin:3 | 1.2 / 0.5 / 0 | Retain live summary/condition |
| Virulent Poison / `skill.virulent_poison` | tree.assassin:6 | 0.5 / 0.5 / 10 | Independent activations unified in both category paths |
| Master Of Poisons / `skill.master_of_poisons` | tree.assassin:9 | 0.5 / 0.5 / 10 | Retain live summary/condition |
| Poison Vile / `skill.poison_vile` | tree.assassin:12 | 1.8 / 0.5 / 0 | Retain live summary/condition |
| Beguiling Strike / `skill.toxic_flurry` | tree.shadow:1 | 1.7 / 0.65 / 0 | Retain live summary/condition |
| Death Strike / `skill.killers_mark` | tree.shadow:3 | 1.5 / 0.65 / 0 | G01 corrected |
| Distilled Corruption / `skill.distilled_corruption` | tree.shadow:6 | 1.5 / 0.65 / 0 | Retain live summary/condition |
| Touch Of Darkness / `skill.touch_of_darkness` | tree.shadow:9 | 0.5 / 0.5 / 30 | Actual Consume/no-fuel and independent bonus wording |
| Beguiling Presence / `skill.beguiling_presence` | tree.shadow:12 | 0.5 / 0.5 / 30 | Actual Consume/no-fuel and independent bonus wording |

## Temporary effect dispositions

| Effect | Hover/inspector disposition and preserved rule |
| --- | --- |
| Footwork | Stacks, max five, refreshed three seconds; actual cast-reduction percent; cast minimum; spent units held until impact. |
| Readiness | One untimed charge; Parry requirement/consumption at cast start; held until impact. |
| Precision | One untimed charge; Quick Cut grants before children; eligible Stab/Heavy Slash including proc casts; Dance does not add a second guarantee. |
| Dance of Death | Active macro repeat guarantee; five seconds; triggered/repeated attacks receive no Dance guarantee. |
| Bypass | Stacks, max three, refreshed three seconds; +10% elemental per stack. |
| Virulent Poison | Five charges per independent activation, no expiry; double per active instance; each fueled natural/forced tick spends one per instance; empty ticks spend none. |
| Master of Poisons | Active resistance-ignore instance, five seconds; no fictitious zero-charge requirement; Decay remains stored. |
| Touch of Darkness | Poison actually consumed; +10% ordinary IAS and +2 base physical per consumed stack for twelve seconds; independent activations add. |
| Beguiling Presence | Decay actually consumed; actual +base elemental and critical chance in percentage points; ten seconds; cap total crit afterward. |
| Greed | Credited fight theft after Increased Gold; no extra stat bonus; fight-local reset. |
| Penetration / Potency | Actual stacks and block/absorb removed; refreshed timer; baseline three seconds, Death Pact four/five/six; cap fifty. |
| Poison / Shred / Decay | Retain live status counts and application order. Fueled tick depletion remains explicitly distinct from Consume. |

Independent-instance hover magnitudes are labeled per instance and nearest expiry is identified. Shared Footwork/Readiness/Bypass do not claim independent activations. Inspector lists the actual snapshot for each instance. Layout/overflow G07 and dense combat G06 remain T6/T7 work.

## Individual icon review

Reviewed all **84 installed framed textures**, native 32px alongside nearest-neighbor enlargement, in three [current-art contact sheets](../project/reports/p6_m7_t5_art_review/current-art-1.png), [sheet 2](../project/reports/p6_m7_t5_art_review/current-art-2.png), [sheet 3](../project/reports/p6_m7_t5_art_review/current-art-3.png). Reviewed all-four-tree live views and representative actual tooltip icon renderings. Source-linked buff reuse remains intentional; current subclass portraits retain original art. No original asset or mapping changed.

No fresh missing-art or compelling replacement defect was identified. Shadow Mastery's small purple silhouette remains subdued in compact use; the installed T4 refinement is accepted, and this is a recognition observation for human follow-up. Reused blade/boot silhouettes remain candidates for user recognition feedback, not authorization to repaint. Toxic Tradeoff, Sharpened Edge, Dusk Strike and Potency use the accepted T4 refinements; historical G09 is not reopened automatically.

## Verification and evidence

Commands use the isolated runner `python tools/p6/run_m6_closeout.py`; all suites launch disposable copies with per-suite APPDATA/LOCALAPPDATA and report-local save paths. Report `summary.json` contains exact commands/source SHA256; `baseline.json` fingerprints source and `isolation.json` records changes during execution. Player saves and sibling Enigma were not read/copied into fixtures.

- `--report-name p6_m7_t5_final --tests p6_m7_t5_tooltip_boundary_test p6_m7_t5_inventory skill_tooltip_formatter_test p6_combat_presentation_test p6_m7_category_preview_test p6_full_thief_test p6_thief_economy_test`: **seven pass**, source isolation unchanged. [Summary](../project/reports/p6_m7_t5_final/summary.json).
- `p6_m7_t5_focused` also ran `p6_shadow_balance_test`: **11 live cohorts pass**. The legacy `p6_gold_contract_test` failed six pre-T2 golden signatures; no legacy fixture was repaired in this presentation task. Current full Thief/economy and presentation/gold boundaries above pass.
- `--report-name p6_m7_t5_visual_verified --visual --tests p6_m7_t5_tooltip_surfaces_visual p6_m7_t5_tooltip_visual`: **matrix suite passes**; the surface fixture returned a void-result assertion failure and was corrected/superseded below. See [matrix summary](../project/reports/p6_m7_t5_visual_verified/summary.json) and `p6_m7_t5_tooltip_visual/t5_visual` screenshots/geometry. The matrix uses Adventure presentation, Test Mode and Practice at **1280x720, 1600x900, 1920x1080**, normal and **125% tooltip/detail text stress**. Adventure uses an isolated Test fixture with `is_test_mode=false`; these are presentation tests, not a fresh Adventure campaign journey.
- `--report-name p6_m7_t5_hover_verified --visual --tests p6_m7_t5_tooltip_surfaces_visual`: **passes**, source isolation unchanged. [Final surface summary](../project/reports/p6_m7_t5_hover_verified/summary.json). Inspected [live Current/Next tree hover](../project/reports/p6_m7_t5_hover_verified/p6_m7_t5_tooltip_surfaces_visual/t5_surfaces/live-tree-mastery-current4-next5-hover-125.png), [live Pick Pocket macro hover](../project/reports/p6_m7_t5_hover_verified/p6_m7_t5_tooltip_surfaces_visual/t5_surfaces/live-macro-pick-pocket-hover-125.png) and realistic effect inspector.
- Surface captures cover G01/G02/G03/G05 plus Virulent/Touch/Beguiling, four-tree views, current/next rank text, an engine-positioned bottom-right popup, live tree/macro hovers and effect inspector at enlarged text. Effect inspector uses realistic explicitly authored snapshots, not a resolver-generated dense fight; full existing replay/lifecycle suite supplies runtime integration evidence.
- The actual engine hover for legally invested Shadow Mastery **Current 4/5, Next 5/5** fits/readable at 1280/125%; the popup repositions clear of the bottom/right edge. Actual Pick Pocket hover shows current-build credited gold and shared cooldown. The 125% setting is a fixture font stress override, not a newly added user preference.

Earlier `first`, `compile`, `rendered`, `rendered_v2`, `visual_final` reports retain diagnostic failures: mixed indentation/parser repair, expected effect-text assertion update, stale removed `_details` fixture access, and an initially locked four-skill macro. The initial edge hover hit an underlying inventory control because of logical/physical viewport coordinates; final local-coordinate engine hover supersedes it. Early inspector snapshots were synthetic impossible values and are superseded by the final realistic state fixture. A live hover stress fixture initially resized the label after popup placement, producing clipping. Final stress swaps the live button's tooltip-construction script while preserving its provider/art/interaction, so enlargement occurs before engine placement; the real tree/macro popups fit after automatic positioning. No failed intermediate image is acceptance evidence.

The eight changed presentation source files match the baseline SHA256s in the final focused, final matrix and final hover reports; later fixture changes do not invalidate unchanged production source verification.

Engine certificate-store and teardown/resource-leak warnings remain recorded; they are retained M9/environment boundaries, not hidden success claims. These checks do not establish power-loss save durability, human comprehension, every possible conditional gear/temporary-state estimate or final M7 accessibility.

## Full rank text appendix

The entries below are the extracted live strings at the tested presentation revision. Dispositions for every rank are inherited from the explicit talent table above.


### Bladedancer ranks


**Whetstone** (`talent.bladedancer.wet_stone`)

- Rank 1: +1 base physical damage
- Rank 2: +2 base physical damage
- Rank 3: +3 base physical damage
- Rank 4: +4 base physical damage
- Rank 5: +5 base physical damage

**Rending Slash** (`talent.bladedancer.rending_slash`)

- Rank 1: Unlocks Rending Slash

**Fancy Footwork** (`talent.bladedancer.fancy_footwork`)

- Rank 1: Quick Cut grants Footwork (3s, max 5 stacks). Leaping Plunge consumes stacks for 4% less windup per stack, respecting the minimum cast time.
- Rank 2: Quick Cut grants Footwork (3s, max 5 stacks). Leaping Plunge consumes stacks for 8% less windup per stack, respecting the minimum cast time.
- Rank 3: Quick Cut grants Footwork (3s, max 5 stacks). Leaping Plunge consumes stacks for 12% less windup per stack, respecting the minimum cast time.
- Rank 4: Quick Cut grants Footwork (3s, max 5 stacks). Leaping Plunge consumes stacks for 16% less windup per stack, respecting the minimum cast time.
- Rank 5: Quick Cut grants Footwork (3s, max 5 stacks). Leaping Plunge consumes stacks for 20% less windup per stack, respecting the minimum cast time.

**Opportunity** (`talent.bladedancer.opportunity`)

- Rank 1: Quick Cut: 10% chance to trigger Rending Slash on a connected hit.
- Rank 2: Quick Cut: 20% chance to trigger Rending Slash on a connected hit.
- Rank 3: Quick Cut: 30% chance to trigger Rending Slash on a connected hit.

**Cloak & Dagger** (`talent.bladedancer.cloak_and_dagger`)

- Rank 1: +50% Crit Damage
- Rank 2: +100% Crit Damage

**Weakness** (`talent.bladedancer.weakness`)

- Rank 1: +5 Shred Value (armor removed per stack)
- Rank 2: +10 Shred Value (armor removed per stack)
- Rank 3: +15 Shred Value (armor removed per stack)
- Rank 4: +20 Shred Value (armor removed per stack)
- Rank 5: +25 Shred Value (armor removed per stack)

**Precision Attacks** (`talent.bladedancer.precision_attacks`)

- Rank 1: Quick Cut hits grant Precision before child effects (untimed, max 1). Stab or Heavy Slash consumes it to repeat once if it hits. Dance does not add a second guarantee.

**Double Dip** (`talent.bladedancer.double_dip`)

- Rank 1: Gain crit chance equal to 50% of numeric Retrigger Chance. Guaranteed repeats do not count.
- Rank 2: Gain crit chance equal to 100% of numeric Retrigger Chance. Guaranteed repeats do not count.

**Sharpened Edge** (`talent.bladedancer.sharpened_edge`)

- Rank 1: Stab and Heavy Slash deal 20% more physical damage, before conversion.
- Rank 2: Stab and Heavy Slash deal 40% more physical damage, before conversion.
- Rank 3: Stab and Heavy Slash deal 60% more physical damage, before conversion.
- Rank 4: Stab and Heavy Slash deal 80% more physical damage, before conversion.
- Rank 5: Stab and Heavy Slash deal 100% more physical damage, before conversion.

**Riposte** (`talent.bladedancer.riposte`)

- Rank 1: Each Footwork stack consumed increases that Leaping Plunge's damage by 20%.
- Rank 2: Each Footwork stack consumed increases that Leaping Plunge's damage by 40%.

**Side Step** (`talent.bladedancer.side_step`)

- Rank 1: Parry Strike has 100% crit chance. Enemy critical-damage negation still applies.

**Weapon Master** (`talent.bladedancer.weapon_master`)

- Rank 1: +50% physical damage
- Rank 2: +100% physical damage

**Virulent Corruption** (`talent.bladedancer.virulent_corruption`)

- Rank 1: +100 Shred Value (armor removed per stack); +2 Shred Stacks; Your Shred cannot be cleansed. Bonus stacks increase each eligible application, not the 500-stack cap.

### Thief ranks


**Keen Eye** (`talent.keen_eye`)

- Rank 1: +2% physical damage; +2% elemental damage
- Rank 2: +4% physical damage; +4% elemental damage
- Rank 3: +6% physical damage; +6% elemental damage
- Rank 4: +8% physical damage; +8% elemental damage
- Rank 5: +10% physical damage; +10% elemental damage

**Sticky Fingers** (`talent.sticky_fingers`)

- Rank 1: +10% Increased Gold; Multiplies with your Thief intrinsic and gear gold multiplier.
- Rank 2: +20% Increased Gold; Multiplies with your Thief intrinsic and gear gold multiplier.
- Rank 3: +30% Increased Gold; Multiplies with your Thief intrinsic and gear gold multiplier.
- Rank 4: +40% Increased Gold; Multiplies with your Thief intrinsic and gear gold multiplier.
- Rank 5: +50% Increased Gold; Multiplies with your Thief intrinsic and gear gold multiplier.

**Fast Hands** (`talent.thief.fast_hands`)

- Rank 1: Gain attack speed equal to 10% of your total Increased Gold bonus.
- Rank 2: Gain attack speed equal to 20% of your total Increased Gold bonus.
- Rank 3: Gain attack speed equal to 30% of your total Increased Gold bonus.
- Rank 4: Gain attack speed equal to 40% of your total Increased Gold bonus.
- Rank 5: Gain attack speed equal to 50% of your total Increased Gold bonus.

**Fill Your Pockets** (`talent.thief.fill_your_pockets`)

- Rank 1: Gain a separate elemental damage bonus equal to 20% of your Magic Find.
- Rank 2: Gain a separate elemental damage bonus equal to 40% of your Magic Find.
- Rank 3: Gain a separate elemental damage bonus equal to 60% of your Magic Find.
- Rank 4: Gain a separate elemental damage bonus equal to 80% of your Magic Find.
- Rank 5: Gain a separate elemental damage bonus equal to 100% of your Magic Find.

**Charisma** (`talent.thief.charisma`)

- Rank 1: +10% Shop Discount; Adds to gear discounts. Positive-price items cost at least 1 gold.
- Rank 2: +20% Shop Discount; Adds to gear discounts. Positive-price items cost at least 1 gold.
- Rank 3: +30% Shop Discount; Adds to gear discounts. Positive-price items cost at least 1 gold.

**Bribery** (`talent.thief.bribery`)

- Rank 1: Each theft that credits gold applies 2 base Shred stacks, regardless of gold amount. Stack bonuses apply.
- Rank 2: Each theft that credits gold applies 4 base Shred stacks, regardless of gold amount. Stack bonuses apply.
- Rank 3: Each theft that credits gold applies 6 base Shred stacks, regardless of gold amount. Stack bonuses apply.

**Silvered Edge** (`talent.thief.silvered_edge`)

- Rank 1: Each gold stolen this fight adds 1% crit chance, up to 25% from this talent. Starting gold and rewards do not count.
- Rank 2: Each gold stolen this fight adds 1% crit chance, up to 50% from this talent. Starting gold and rewards do not count.
- Rank 3: Each gold stolen this fight adds 1% crit chance, up to 75% from this talent. Starting gold and rewards do not count.

**Finders Keepers** (`talent.thief.finders_keepers`)

- Rank 1: Enemies begin combat with 50% less block. Later Penetration can reduce it further.
- Rank 2: Enemies begin combat with 100% less block. Later Penetration can reduce it further.

**Loaded Dice** (`talent.thief.load_dice`)

- Rank 1: +100% Increased Magic Find; Increases eligible gear-quality upgrade chances; does not add extra drops.
- Rank 2: +200% Increased Magic Find; Increases eligible gear-quality upgrade chances; does not add extra drops.
- Rank 3: +300% Increased Magic Find; Increases eligible gear-quality upgrade chances; does not add extra drops.

**Gilded Blade** (`talent.gilded_blade`)

- Rank 1: Each gold in your stash adds 1% crit damage, counting up to 500 gold.

### Assassin ranks


**Quick Hands** (`talent.assassin.quick_hands`)

- Rank 1: +1% Increased Attack Speed
- Rank 2: +2% Increased Attack Speed
- Rank 3: +3% Increased Attack Speed
- Rank 4: +4% Increased Attack Speed
- Rank 5: +5% Increased Attack Speed

**Precision** (`talent.assassin.precision`)

- Rank 1: +1% Crit Chance
- Rank 2: +2% Crit Chance
- Rank 3: +3% Crit Chance
- Rank 4: +4% Crit Chance
- Rank 5: +5% Crit Chance

**Hastened Poison** (`talent.assassin.hastened_poison`)

- Rank 1: Apply 10% of increased attack speed to Poison tick rate. Adds with Accelerant.
- Rank 2: Apply 20% of increased attack speed to Poison tick rate. Adds with Accelerant.
- Rank 3: Apply 30% of increased attack speed to Poison tick rate. Adds with Accelerant.
- Rank 4: Apply 40% of increased attack speed to Poison tick rate. Adds with Accelerant.
- Rank 5: Apply 50% of increased attack speed to Poison tick rate. Adds with Accelerant.

**Echoing Toxin** (`talent.assassin.echoing_toxin`)

- Rank 1: Natural and forced Poison ticks use up to 2 stacks, with no bonus damage. Adds 40% Suppression to natural ticks. Forced ticks are not delayed. Tick depletion is not Consume.
- Rank 2: Natural and forced Poison ticks use up to 2 stacks, with no bonus damage. Adds 30% Suppression to natural ticks. Forced ticks are not delayed. Tick depletion is not Consume.
- Rank 3: Natural and forced Poison ticks use up to 2 stacks, with no bonus damage. Adds 20% Suppression to natural ticks. Forced ticks are not delayed. Tick depletion is not Consume.

**Poison Strike** (`talent.assassin.poison_strike`)

- Rank 1: Unlocks Poison Strike

**Bypass** (`talent.assassin.bypass`)

- Rank 1: Stab grants Bypass after child effects: 3 seconds, max 3 stacks. Each adds 10% elemental damage, up to 30%. Grants refresh the shared timer.

**Toxic Tradeoff** (`talent.assassin.toxic_tradeoff`)

- Rank 1: Poison ticks deal 10% more damage; physical damage deals 10% less. Separate factors before conversion. Other elemental damage is unchanged.
- Rank 2: Poison ticks deal 20% more damage; physical damage deals 20% less. Separate factors before conversion. Other elemental damage is unchanged.
- Rank 3: Poison ticks deal 30% more damage; physical damage deals 30% less. Separate factors before conversion. Other elemental damage is unchanged.
- Rank 4: Poison ticks deal 40% more damage; physical damage deals 40% less. Separate factors before conversion. Other elemental damage is unchanged.
- Rank 5: Poison ticks deal 50% more damage; physical damage deals 50% less. Separate factors before conversion. Other elemental damage is unchanged.

**Accelerant** (`talent.assassin.accelerant`)

- Rank 1: Apply an additional 10% of increased attack speed to Poison tick rate.
- Rank 2: Apply an additional 20% of increased attack speed to Poison tick rate.
- Rank 3: Apply an additional 30% of increased attack speed to Poison tick rate.
- Rank 4: Apply an additional 40% of increased attack speed to Poison tick rate.
- Rank 5: Apply an additional 50% of increased attack speed to Poison tick rate.

**Resonance** (`talent.assassin.resonance`)

- Rank 1: Poison ticks use up to 3 stacks instead of 2 and deal 5% more damage per stack used. Echoing Toxin's Suppression still applies.
- Rank 2: Poison ticks use up to 3 stacks instead of 2 and deal 10% more damage per stack used. Echoing Toxin's Suppression still applies.
- Rank 3: Poison ticks use up to 3 stacks instead of 2 and deal 15% more damage per stack used. Echoing Toxin's Suppression still applies.
- Rank 4: Poison ticks use up to 3 stacks instead of 2 and deal 20% more damage per stack used. Echoing Toxin's Suppression still applies.

**Critical Poison** (`talent.assassin.critical_poison`)

- Rank 1: Each fueled natural or forced Poison tick can crit using current critical chance and damage. No direct-hit critical triggers.

### Shadow ranks


**Coated Weapons** (`talent.shadow.coated_weapons`)

- Rank 1: Stab and Heavy Slash apply 2 base Poison on connected hits. Stack bonuses apply; Death Blade suppresses all Stab Poison.

**Blind Spot** (`talent.shadow.blind_spot`)

- Rank 1: +2% Crit Chance
- Rank 2: +4% Crit Chance
- Rank 3: +6% Crit Chance
- Rank 4: +8% Crit Chance
- Rank 5: +10% Crit Chance

**Snake Oil** (`talent.shadow.snake_oil`)

- Rank 1: +2 base elemental damage
- Rank 2: +4 base elemental damage
- Rank 3: +6 base elemental damage
- Rank 4: +8 base elemental damage

**Deception** (`talent.shadow.deception`)

- Rank 1: +10% elemental damage
- Rank 2: +20% elemental damage
- Rank 3: +30% elemental damage
- Rank 4: +40% elemental damage
- Rank 5: +50% elemental damage

**Death from the Shadows** (`talent.shadow.death_from_the_shadows`)

- Rank 1: +20% Crit Damage
- Rank 2: +40% Crit Damage
- Rank 3: +60% Crit Damage
- Rank 4: +80% Crit Damage
- Rank 5: +100% Crit Damage

**Death Touch** (`talent.shadow.death_touch`)

- Rank 1: +3 base stacks per eligible Poison, Shred, Decay, Footwork, Bypass, Penetration or Potency application
- Rank 2: +6 base stacks per eligible Poison, Shred, Decay, Footwork, Bypass, Penetration or Potency application
- Rank 3: +9 base stacks per eligible Poison, Shred, Decay, Footwork, Bypass, Penetration or Potency application

**Death Pact** (`talent.shadow.death_pact`)

- Rank 1: Consuming Poison or Decay grants the actual consumed count to both Penetration and Potency. Both last 4 seconds, regardless of source. Tick depletion is not Consume.
- Rank 2: Consuming Poison or Decay grants the actual consumed count to both Penetration and Potency. Both last 5 seconds, regardless of source. Tick depletion is not Consume.
- Rank 3: Consuming Poison or Decay grants the actual consumed count to both Penetration and Potency. Both last 6 seconds, regardless of source. Tick depletion is not Consume.

**Shadow Mastery** (`talent.shadow.shadow_mastery`)

- Rank 1: Copy 10% of flat elemental bonuses into physical base and of the effective elemental percentage bonus into a separate physical multiplier. Elemental bonuses remain. Excludes class base Poison and Poison-only damage bonuses.
- Rank 2: Copy 20% of flat elemental bonuses into physical base and of the effective elemental percentage bonus into a separate physical multiplier. Elemental bonuses remain. Excludes class base Poison and Poison-only damage bonuses.
- Rank 3: Copy 30% of flat elemental bonuses into physical base and of the effective elemental percentage bonus into a separate physical multiplier. Elemental bonuses remain. Excludes class base Poison and Poison-only damage bonuses.
- Rank 4: Copy 40% of flat elemental bonuses into physical base and of the effective elemental percentage bonus into a separate physical multiplier. Elemental bonuses remain. Excludes class base Poison and Poison-only damage bonuses.
- Rank 5: Copy 50% of flat elemental bonuses into physical base and of the effective elemental percentage bonus into a separate physical multiplier. Elemental bonuses remain. Excludes class base Poison and Poison-only damage bonuses.

**Dusk Strike** (`talent.shadow.dusk_strike`)

- Rank 1: +10 Shred Value (armor removed per stack); Positive Decay applications also apply 1 base Shred, independently modified by Shred stack bonuses and doubling.

**Death Blade** (`talent.shadow.death_blade`)

- Rank 1: Each Poison application that adds stacks has a 40% chance to trigger Stab. Stab cannot apply Poison from any source; ordinary repeats still apply.
- Rank 2: Each Poison application that adds stacks has a 80% chance to trigger Stab. Stab cannot apply Poison from any source; ordinary repeats still apply.

**Umbral Presence** (`talent.umbral_pressure`)

- Rank 1: Raises the Poison stack cap to 80.
