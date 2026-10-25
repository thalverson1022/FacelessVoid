# M7-T5 Minimal Talent Tooltip Design and Implementation

Current task status: **Complete — user accepted T5 under D039 on 2026-10-15.** See [closeout and accepted conventions](P6M7_T5_Closeout_And_Accepted_Conventions.md).

The dated status, proposals and evidence below are historical snapshots; later accepted conventions and D039 supersede earlier In progress/closeout-excluded instructions.

## Bladedancer copy refinement D035 (2026-10-15)

Removed the requested effect-text trailing periods from Parry Strike, Double Dip, Opportunity, Riposte and Virulent Corruption. Dance of Death now says `The first hit of all attacks have 100% Retrigger Chance`. Side Step is a single rule, `Parry Strike has 100% crit chance`, with no Next rank section at rank 0 or rank 1. Shared Active Talents inherits the talent wording; scaling values, gold emphasis and mechanics are unchanged.

Both [focused tooltip suites](../project/reports/p6_m7_bladedancer_copy_cleanup_focused/summary.json) pass. The existing [rendered hierarchy fixture](../project/reports/p6_m7_bladedancer_copy_cleanup_rendered/summary.json), extended with unlearned/learned Side Step, passes 68 captures across Adventure, Practice and Test. Actual Side Step hovers at 125% were inspected in both states; both show one sentence without Next rank. Source/save isolation is unchanged and all 330 protected mechanics files match the retained baseline. T5 remains **In progress**.

Historical design and superseding decisions follow below.

Status: **In progress - approved general talent format implemented; individual wording review and T5 closeout remain deferred.**

Authority: P6M7-D026, 2026-10-14. This replaces the old paragraph-based Current/Next talent hovers. The [current skill hover format](P6M7_T5_Minimal_Skill_Tooltip_Design_And_Implementation.md) remains unchanged.

## Approved format

- The exact theme-chain `TooltipPanel` background used by item/skill hovers: semi-transparent black, without an opaque card override.
- Original 32x32 icon plus cream 22px VT323 name, top-aligned. Second line: cream 18px tree name and `Rank x/y`.
- Concise 20px core effects and basic numbers. Invested talents show their current effect, then a spaced cream 18px `Next rank:` heading and the next effect. Each section uses its own live values and the same effect colors. Rank zero shows only `Next rank:`; maximum shows only the effect and `Rank x/y`, with no next section or redundant Current/Max rank heading. Single-rank talents show a concise rule or `Unlocks Skill Name`.
- Ordinary benefits are cream (`#F0E2C5`), special mechanics yellow (`#E7D967`), actual drawbacks violet (`#CFA6FF`), matching the item palette. Names and signs remain explicit. Drawbacks appear after benefits. Reduced enemy block and shorter player cast time are benefits, not automatically drawbacks because their numbers are negative.
- `Requires` appears only for a missing lower-tier gate or prerequisite, using the actual tree/talent name. Budget, editing-phase policy and duplicate rule paragraphs stay out of the hover. Maximum-rank talents do not show a purchase requirement.
- Defining dependencies remain concise where necessary (e.g. Quick Cut grants Footwork and Leaping Plunge consumes it). Gear explanations, proc ordering and detailed exceptions remain in the retained reference formatter and are explored in Practice.

Separate rank sections supersede the original arrow comparisons. For example, the current section shows `Critical chance: +3%`; the `Next rank:` section shows `Critical chance: +4%`. Each section contains its complete short description, including shared rules and any newly introduced effect. This follows the user-provided World of Warcraft references while retaining the item palette and concise wording.

## Live content and implementation

`talent_hover_formatter.gd` reads actual `TalentRank` modifiers, derivation fractions, trigger chances, unlocks and explicit passive carriers. `talent_hover_panel.gd` renders the structured rows. An optional talent provider on `IconTooltipButton` selects the new talent path; its existing skill path keeps precedence and behavior. Ranked talent cards, including skill-granting talent nodes, use this provider in Adventure, Test Mode and Practice. Automatic skill-unlock boxes remain skill hovers.

All **44 talents / 140 ranks** are handled without a verbose fallback: Bladedancer 13 talents/35 ranks, Thief 10/35, Assassin 10/35 and Shadow 11/35. The [current compact inventory](../project/reports/p6_m7_talent_next_rank_verified/p6_m7_talent_hover_test/talent_hover/inventory.json) includes each talent's zero, partial and maximum states (184 states total). The original arrow-format inventory remains historical evidence.

Rank values are runtime authority, rather than illustrative planning examples. Assassin Precision remains +1/+2/+3/+4/+5% critical chance. Toxic Tradeoff reads the actual physical drawback and Poison factor at every rank. Echoing's natural-tick Suppression penalty is +40/+30/+20%; Fancy Footwork reduces Plunge cast time by 4% per rank per consumed stack. Shadow Mastery's live fractions are 10-50%. These are presentation statements, not changes to mechanics.

Gate checks count only retained ranks in talents with strictly smaller `required_tree_points` in the same tree, matching `RankedBuild.validate`. Same-tier/current-node ranks do not support the gate. Each missing prerequisite requires one rank and uses its current display name. The tooltip reports only those blockers; allocation validation and restrictions remain owned by existing state code.

## Verification

Pre-step file copies and [SHA256 fingerprints](../work/t5_talent_before/hashes.json) include both current skill-hover files, the palette/macro providers, ranked talent view and icon-tooltip control. The skill formatter/panel and palette/macro files remain byte-identical; the retained detailed `ranked_talent_view.effects()` body is unchanged. No combat/system/resource/data/save logic or original art was edited.

Commands used `python tools/p6/run_m6_closeout.py` with disposable project copies, report-local save paths and isolated APPDATA/LOCALAPPDATA:

- `--report-name p6_m7_talent_hover_verified --tests p6_m7_talent_hover_test p6_talent_ui_test`: **both pass**. The new suite performs **3,429 checks** across all 44 talents/140 ranks plus zero states, keyed comparisons/no duplicate rules, real numerical boundaries, tradeoff colors/order, missing/satisfied gates, introduced next-rank effects, all-mode live providers and unchanged skill rendering. Existing talent UI checks retain buy/refund/prerequisite/point-gate/reset/rotation-pruning behavior. [Summary](../project/reports/p6_m7_talent_hover_verified/summary.json).
- `--report-name p6_m7_talent_hover_rendered --visual --tests p6_m7_talent_hover_visual`: **rendered suite passes 84 actual engine-controlled hover captures**. Covers Adventure presentation, Test Mode and Practice at 1280x720, 1600x900 and 1920x1080, normal/125% text; representatives include ordinary stats, special mechanics, dual benefit/drawback, partial numerical comparison, maximum, single unlock and rank-zero missing gate/prerequisite. All four trees are represented. [Rendered summary](../project/reports/p6_m7_talent_hover_rendered/summary.json).

Representative renders were inspected: [Precision](../project/reports/p6_m7_talent_hover_rendered/p6_m7_talent_hover_visual/talent_hover_visual/test-precision-1280-100.png), [Toxic Tradeoff](../project/reports/p6_m7_talent_hover_rendered/p6_m7_talent_hover_visual/talent_hover_visual/adventure-toxic_tradeoff-1600-125.png), [Shadow Mastery](../project/reports/p6_m7_talent_hover_rendered/p6_m7_talent_hover_visual/talent_hover_visual/practice-shadow_mastery-1920-125.png), [blocked Mastery](../project/reports/p6_m7_talent_hover_rendered/p6_m7_talent_hover_visual/talent_hover_visual/test-requires-shadow-mastery-1280-125.png), [Fancy Footwork](../project/reports/p6_m7_talent_hover_rendered/p6_m7_talent_hover_visual/talent_hover_visual/practice-fancy_footwork-1280-125.png), [Silvered Edge](../project/reports/p6_m7_talent_hover_rendered/p6_m7_talent_hover_visual/talent_hover_visual/adventure-silvered_edge-1280-125.png) and [single-rank unlock](../project/reports/p6_m7_talent_hover_rendered/p6_m7_talent_hover_visual/talent_hover_visual/test-state-poison_strike-1280-125.png). Headers, palette, value comparison, compact requirements and popup placement are readable without clipping in those reviewed cases.

The focused run's source isolation is unchanged. The rendered runner reports one concurrent workspace change to the independent headless test file (`p6_m7_talent_hover_test.gd`), so its overall wrapper exit is nonzero despite the visual suite passing; this is explicitly retained in `isolation.json`. Its visual fixture and all four talent renderer/provider production files match current SHA256s in both final reports. No production code changed during that render. This discrepancy does not imply a real-save or UI mutation. The later focused test is verified separately at its final source hash.

125% is a fixture font-stress override applied before engine popup placement; original art remains 32px. Adventure uses an isolated retained fixture with Adventure presentation, not a new campaign journey. Engine certificate-store and teardown/resource warnings remain recorded M9/environment boundaries. Rendering and checks do not replace human comprehension acceptance or the later individual skill/talent audit.

## Separate Next rank sections — 2026-10-14

User approved the WoW-inspired section layout. The model and renderer now use independent current/next effect arrays, a cream `Next rank:` heading and an 8px section gap. Both blocks retain their original effect colors. Rank zero has no current block; maximum rank has no next block, spacer or heading. The tree/rank line communicates the maximum without a separate Max rank message. Skills, mechanics and core effect wording are unchanged.

- `python tools/p6/run_m6_closeout.py --report-name p6_m7_talent_next_rank_verified --tests p6_m7_talent_hover_test p6_talent_ui_test`: **both pass**, with **4,263 focused checks** including all 184 rank states, actual next-section control presence/absence, independent rank values, tradeoff colors and allocation behavior. [Summary](../project/reports/p6_m7_talent_next_rank_verified/summary.json).
- `python tools/p6/run_m6_closeout.py --report-name p6_m7_talent_next_rank_rendered --visual --tests p6_m7_talent_hover_visual`: **pass, 84 live hover captures** across the existing mode/size/text matrix. [Summary](../project/reports/p6_m7_talent_next_rank_rendered/summary.json). Enlarged-text Toxic Tradeoff, Fancy Footwork, maximum Quick Hands and unallocated/blocked Shadow Mastery screenshots were inspected; sections remain readable and the maximum tooltip has no next-rank content.

Both accepted runs use disposable saves with unchanged source isolation. A preliminary test used a Window where the renderer requires a Control; that fixture was corrected and its failed report is not accepted evidence. T5 remains In progress.

## Per-talent coverage

Each row covers every positive rank listed plus rank zero. All use the structured compact model. Complete state strings are in the inventory JSON linked above.

| Tree | Talent | Ranks covered | Core presentation |
| --- | --- | --- | --- |

| Bladedancer | Whetstone | 0-5 | Base physical damage: +1 |
| Bladedancer | Rending Slash | 0-1 | Unlocks Rending Slash |
| Bladedancer | Fancy Footwork | 0-5 | Quick Cut grants Footwork; Leaping Plunge consumes it.; Plunge cast time per consumed stack: -4% |
| Bladedancer | Opportunity | 0-3 | Quick Cut can trigger Rending Slash on hit.; Trigger chance: 10% |
| Bladedancer | Cloak & Dagger | 0-2 | Critical damage: +50% |
| Bladedancer | Weakness | 0-5 | Armor removed per Shred stack: +5 |
| Bladedancer | Precision Attacks | 0-1 | Quick Cut grants Precision; Stab or Heavy Slash consumes it to repeat. |
| Bladedancer | Double Dip | 0-2 | Retrigger chance also grants critical chance.; Retrigger chance copied to critical chance: 50% |
| Bladedancer | Sharpened Edge | 0-5 | Stab and Heavy Slash physical damage: +20% |
| Bladedancer | Riposte | 0-2 | Consumed Footwork increases Leaping Plunge damage.; Plunge damage per consumed stack: +20% |
| Bladedancer | Side Step | 0-1 | Parry Strike critical chance: 100% |
| Bladedancer | Weapon Master | 0-2 | Physical damage: +50% |
| Bladedancer | Virulent Corruption | 0-1 | Armor removed per Shred stack: +100; Additional Shred stacks: +2; Your Shred cannot be cleansed. |
| Thief | Keen Eye | 0-5 | Physical damage: +2%; Elemental damage: +2% |
| Thief | Sticky Fingers | 0-5 | Increased Gold: +10% |
| Thief | Fast Hands | 0-5 | Increased Gold also grants attack speed.; Increased Gold bonus copied to attack speed: 10% |
| Thief | Fill Your Pockets | 0-5 | Magic Find also grants elemental damage.; Magic Find copied to elemental damage: 20% |
| Thief | Charisma | 0-3 | Shop discount: +10% |
| Thief | Bribery | 0-3 | Shred stacks applied per successful theft: 2 |
| Thief | Silvered Edge | 0-3 | Each gold stolen this fight grants +1% critical chance.; Maximum critical chance from theft: +25% |
| Thief | Finders Keepers | 0-2 | Enemy starting block: -50% |
| Thief | Loaded Dice | 0-3 | Magic Find: +100% |
| Thief | Gilded Blade | 0-1 | Each stash gold grants +1% critical damage (up to 500 gold). |
| Assassin | Quick Hands | 0-5 | Attack speed: +1% |
| Assassin | Precision | 0-5 | Critical chance: +1% |
| Assassin | Hastened Poison | 0-5 | Attack speed also speeds up Poison ticks.; Attack speed applied to Poison tick rate: 10% |
| Assassin | Echoing Toxin | 0-3 | Poison ticks use up to 2 stacks.; Natural Poison tick Suppression penalty: +40% |
| Assassin | Poison Strike | 0-1 | Unlocks Poison Strike |
| Assassin | Bypass | 0-1 | Stab grants Bypass: +10% elemental damage per stack for 3s. |
| Assassin | Toxic Tradeoff | 0-5 | Poison damage: +10%; Physical damage: -10% |
| Assassin | Accelerant | 0-5 | Apply more attack speed to Poison tick rate.; Additional attack speed applied: 10% |
| Assassin | Resonance | 0-4 | Poison ticks use up to 3 stacks.; Poison damage per stack used: +5% |
| Assassin | Critical Poison | 0-1 | Poison ticks can critically strike. |
| Shadow | Coated Weapons | 0-1 | Stab and Heavy Slash apply Poison on hit: 2 stacks |
| Shadow | Blind Spot | 0-5 | Critical chance: +2% |
| Shadow | Snake Oil | 0-4 | Base elemental damage: +2 |
| Shadow | Deception | 0-5 | Elemental damage: +10% |
| Shadow | Death from the Shadows | 0-5 | Critical damage: +20% |
| Shadow | Death Touch | 0-3 | Additional stacks per application: +3 |
| Shadow | Death Pact | 0-3 | Consume Poison or Decay to gain that many Penetration and Potency stacks.; Penetration and Potency duration: 4s |
| Shadow | Shadow Mastery | 0-5 | Copy base and percentage elemental bonuses into physical damage.; Elemental bonuses copied: 10% |
| Shadow | Dusk Strike | 0-1 | Armor removed per Shred stack: +10; Applying Decay also applies 1 Shred stack. |
| Shadow | Death Blade | 0-2 | Applying Poison can trigger Stab.; Stab trigger chance: 40% |
| Shadow | Umbral Presence | 0-1 | Maximum Poison stacks: 80 |

## Retrigger terminology — 2026-10-14

Retrigger is the mechanical keyword. Dance of Death and Precision Attacks describe a guaranteed Retrigger; Double Dip refers to numeric Retrigger Chance. Repeat remains a colloquial outcome, not a substitute keyword in mechanical tooltip copy. The skill/talent format and combat mechanics are unchanged. The affected skill-hover, talent-hover, detailed formatter, combat-presentation and category suites pass in [focused verification](../project/reports/p6_m7_retrigger_wording_focused/summary.json).


**D029 revision (2026-10-14):** Current palette/Requires and requested Bladedancer/stack wording changes supersede the corresponding earlier descriptions. See [approved decision and final evidence](P6M7_T5_Neutral_Talent_And_Stack_Wording.md). T5 remains In progress.


**D030 revision (2026-10-14):** Approved Thief intrinsic/talent/skill copy and Pick Pocket Duration exception are recorded in [Thief revision evidence](P6M7_T5_Thief_Tooltip_Revision.md). T5 remains In progress.


**D031 revision (2026-10-14):** Approved Assassin wording and Virulent/Vile Duration omissions are recorded in [Assassin revision evidence](P6M7_T5_Assassin_Tooltip_Revision.md). T5 remains In progress.


**D032 revision (2026-10-14):** Approved Shadow copy and live Distilled maximum/provider refresh are recorded in [Shadow revision evidence](P6M7_T5_Shadow_Tooltip_Revision.md). T5 remains In progress.


**D033 revision (2026-10-15):** Gold values, shared rich current rows, spacing and shorter changed-only Next rank supersede the earlier complete repeated next-rank presentation. [Approved design and evidence](P6M7_T5_Talent_Value_Hierarchy_And_Next_Rank_Polish.md). T5 remains In progress.
