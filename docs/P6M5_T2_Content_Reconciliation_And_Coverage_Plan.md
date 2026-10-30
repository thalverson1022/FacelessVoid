# M5-T2 — Content reconciliation and coverage plan

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

Date: 2026-10-03. Status: **Complete — content audit and validation planning only.**

The user requested execution of the eight-step T2 plan after reviewing it. This
also permits recording T1's planning closeout: the eleven-task sequence, review
checkpoints, acceptance matrix and owners are already recorded in the
[M5 tracker](P6M5_Complete_Rogue_Tree_And_Skill_Implementation_Tracker.md).
This authorization does not approve unresolved mechanics or start T3 implementation.

**T9 reconciliation (2026-10-06):** This is the original audit/planning snapshot. For current values through D023 and executable mixed/gear coverage, use the [T9 matrix](P6M5_T9_Mixed_Tree_And_Gear_Integration.md). Mug caps at 50, defense debuffs at 50, Footwork uses 4%/rank/stack, Riposte 20%/rank/stack, and Touch lasts twelve seconds with IAS and physical bonuses. Historical examples below do not override those approvals.

## Deliverables and authority

- [Readable coverage ledger](P6M5_T2_Content_Coverage_Ledger.md): every intrinsic,
  talent, skill and automatic slot, with status, owners and reconciliation notes.
- [Structured ledger](P6M5_T2_Content_Coverage_Ledger.json): all 92 source identity
  records, 140 individual rank cases, two talent skill grants, canonical
  prerequisites, source pointers/hashes, implementation evidence and test candidates.
- This document: discrepancies, dependencies, access/promotion requirements,
  validation matrix and closeout evidence.
- [Ledger builder/checker](../tools/p6/build_m5_coverage_ledger.py): reproducible
  inventory expansion and checks for complete rank/identity coverage, evidence
  paths, source hashes and stale generated output. Annotations are human-reviewed
  audit conclusions; the checker does not infer behavior from names or execute Godot.

Authority is the four versioned drafts plus the identity manifest for provenance;
the [M2 build rules](P6M2_T3_Progression_And_Allocation_Rules.md),
[compatibility policy](P6M2_T4_Content_Workflow_And_Compatibility.md), explicit
M3 decisions and [combat reference](Combat_Mechanics_Reference.md) for approved
behavior; and the [M4 closeout](P6M4_T11_Closeout_And_M5_Handoff.md) for current
playability. Source prose, reserved IDs and representative fixtures are not release
approval. Historical unresolved notes yield to later explicit decisions.

## Reconciled inventory and runtime boundary

| Tree | Talents | Rank slots | Playable talents / rank definitions | Remaining talents / ranks | Intrinsic | Automatic slots |
| --- | --- | --- | --- | --- | --- | --- |
| Bladedancer | 13 | 35 | 5 / 16 | 8 / 19 | Bound | 4 populated, 1 intentionally empty |
| Thief | 10 | 35 | 1 / 5 | 9 / 30 | Bound | 4 populated, 1 intentionally empty |
| Assassin | 10 | 35 | 0 / 0 | 10 / 35 | Shared stat support; binding pending | 5 populated |
| Shadow | 11 | 35 | 0 / 0 | 11 / 35 | Shared crit hook; binding pending | 5 populated |
| Total | 44 | 140 | 6 / 21 | 38 / 119 | 4 accounted for | 20, including 2 empty |

The 18 populated automatic slots plus two talent grants reference 20 planned skill
identities. Seven are currently reachable through the scoped registry: Quick Cut,
Leaping Plunge, Parry Strike, Dance of Death, Rending Slash, Steal and Mug. The
three class skills Stab, Heavy Slash and Hold are outside that 20-skill inventory;
they explain the ten unlocked skills in the existing exact mixed journey.

The six playable talents are Whetstone, Rending Slash, Fancy Footwork, Opportunity,
Cloak & Dagger and Keen Eye. All 21 rank definitions are present, but inherited
core/mixed journeys exercise specific allocations; this audit does not claim
new exhaustive per-rank acceptance. Seventeen other Bladedancer/Thief talents are
display-only previews. Assassin/Shadow's 21 talents are not in the current full-tree
display catalog. Every tree has 35 draft ranks; maxing both trees would cost 70,
so mixed tests must use legal allocations within the shared 45-point budget.

`BuildContentRegistry.test_mode()` constructs `p6.playable.mixed.1` from the three
core talent resources and `playable_mixed_content.gd`. It exposes only Bladedancer
and Thief and accepts old-core Practice revision `p6.playable.bladedancer_core.1`.
`current()` retains the separate `p6.compat.1` registry. An inherited resource with
the same ID does not certify the redesigned effect or grant path.

## Reconciled differences that are already settled

| Draft/history trap | Authoritative treatment | Future binding owner |
| --- | --- | --- |
| Colliding source IDs, misleading `ias`/`crit`/`poison_per_point` labels | Use file/revision/pointer plus canonical manifest ID; never infer handlers from source keys. Preserve all six collision resolutions. | All tree tasks |
| Wet Stone / Whetstone | Approved display rename only; stable ID remains `talent.bladedancer.wet_stone`. | T3/T4 |
| Heavy Strike | Reviewed alias for Heavy Slash; not a new skill or reopened design question. | T3/T4 |
| Fancy Footwork 10–50% draft values | Full five-stack result; cast-time reduction is `0.02 * rank * stacks`, with Plunge minimum. Riposte is `1 + 0.1 * rank * actual_consumption`. | T3/T4 |
| Precision macro-only restriction | Superseded: eligible proc Stab/Heavy Slash can consume; Quick Cut grants before children. Dance remains macro-only. | T3/T4, T9 |
| Assassin increased elemental wording | +5 flat base elemental; primary adds +1 flat per invested point. | T7 |
| Echoing/Resonance “consumes” and forced-tick no-depletion history | Natural and forced ticks deplete actual fuel; not keyword Consume. Separate multipliers and additive cadence are settled. | T7 |
| Blinding Powder ignores absorb | Reviewed Potency application based on Assassin investment, eligible stack modifiers, Debuff 1000/500 ms. | T7 |
| Assassin note says fifth slot blank | Populated Poison Vile slot is retained. Bladedancer and Thief nine-point slots stay empty. | T4/T6/T7 |
| Death Pact player buff and `%` timer | Actual keyword Consume grants both Penetration/Potency; rank durations 4/5/6 seconds. | T8 |
| Shadow Mastery converts bonuses away | Copies bonuses without removing elemental benefits; excludes class base Poison. | T8 |
| Legacy Umbral cap 40 | Reviewed redesigned cap is at least 80; do not bind the legacy cap-40 special. | T8 |
| Dusk Strike legacy mirroring | Enable independent Shred application and its own modifiers, not copied Decay quantity. | T8 |
| Touch multiplicative/direct time reduction | Ordinary additive IAS +10% per actual Poison consumed, eight seconds; 500 ms Self Buff, 30 s cooldown. | T8 |
| Pick pocket low-damage prose | Reviewed zero-damage Debuff, twenty raw gold, 1300/800 ms. | T5/T6 |
| Big Score 110% history | User correction is 90%; crit doubles the full live crit multiplier. | T5/T6 |
| Stash versus theft / Silvered Blade versus Silvered Edge | Preserve separate counters, stable identities and capped own contributions; no name-based aliasing. | T5/T6 |

## Questions reserved for content review

These are specific content decisions or confirmations, not reopened M3 mechanisms.
Numbers already explicitly reviewed remain the baseline; full-tree balance is M6.

| ID | Evidence / unresolved content | Required output | Owner |
| --- | --- | --- | --- |
| Q01 | Venom Jab draft grants five Poison; inherited `venom_jab.tres` grants eight and has 1000/500 ms timing. | Approve the complete redesigned descriptor: Poison quantity, damage scaling, category, timing/cooldown and interactions. Do not silently pick five or eight. | T7 design checkpoint |
| Q02 | Beguiling Strike uses legacy `PoisonResistanceReductionEffect`; current resolver already turns that into one Decay application. It is not a demonstrated missing Decay mechanic. | Certify complete redesigned attack values/timing, effect representation and provenance; preserve `skill.toxic_flurry`. | T8 design checkpoint |
| Q03 | Toxic Tradeoff explicitly calls its values illustrative and says poison damage, whereas generic elemental modifiers affect the wider elemental bucket. | Specify affected damage scope, positive/negative buckets and provisional rank values before authoring. | T7 design checkpoint |
| Q04 | Death Strike has inherited physical and Poison-stack-scaling effects but no complete redesigned descriptor in the reviewed skill-value table. | Confirm or revise full scaling, timing, snapshot/live reading and whether stacks are merely read. Do not infer Consume from “adds poison stacks damage”; preserve `skill.killers_mark`. | T8 design checkpoint |
| Q05 | Distilled's up-to-five Decay Consume/conversion is settled; no complete released attack descriptor exists. | Approve remaining weapon scaling, base/minimum time, cooldown and descriptor using the settled conversion order. | T8 design checkpoint |
| Q06 | Generic scalar support exists for Weakness, Weapon Master, Quick Hands, Precision, Blind Spot, Snake Oil, Deception, Death from the Shadows, Sticky Fingers, Charisma and Load Dice; source existence is not full-node approval. | Record complete rank values, units/buckets, grants and prerequisites at each tree review. Preserve already settled semantics and identify any deliberate change explicitly. Review Virulent Corruption's combined static bonuses plus immunity together. | T3, T5, T7, T8 as mapped in ledger |
| Q07 | Charisma/Load Dice need observable shop/loot behavior; Practice combat alone cannot establish it. | Specify existing Test Mode shop/reward access or isolated controller evidence, pricing floors/rounding and Magic Find consumer checks; preserve Phase 5 economy rules. | T5 plans, T6 verifies; M6 tunes |

No source JSON, mechanics reference, runtime effect or compatibility fixture was
changed to resolve these questions. Tree reviews should bring examples for these
items and verify the rest of the tree against settled contracts.

## Dependencies and implementation sequence

| ID | Observed gap / requirement | Work and acceptance | Owner |
| --- | --- | --- | --- |
| B01 | Full-tree content and release registry are incomplete. | Explicitly author every promoted rank, intrinsic, grant and unlock under canonical IDs; preserve gates/prerequisites and intentional blanks. Reject unsupported effects and duplicate definitions. | T4, T6, T7, T8 |
| B02 | Combat support is broader than the rank carrier. `TalentRank` and `RankedBuild.resolved_content()` carry modifiers, augments, triggers, derivations, Footwork, Gilded and Silvered; many other PlayerStats inputs are not wired. | Add narrowly scoped, validated binding paths with allocation-to-combat provenance and refund/role cleanup. Do not inject test adapters into UI code or silently accept an unbound flag. | First needed in T4, extended in T6/T7/T8 |
| B03 | Current UI/entry points only expose the scoped slice. | Establish supported full-content test access and truthful preview/description behavior, as specified below. | Each implementation task, consolidated T10 |
| B04 | New promotion must declare compatible revisions and evidence. | Record exact supported/incompatible revisions, source/spec/resource provenance and isolated round trips before promotion. | Each implementation task, T10/T11 |

B02 work by first owner:

- **T4:** Precision's untimed enabled charge, Riposte rank, Side Step flag and
  Shred cleanse immunity. Existing modifier/derivation/trigger carriers cover
  the other remaining Bladedancer bindings, subject to validation.
- **T6:** Bribery's rank-to-base-stack field and Finders Keepers rank. Gilded/
  Silvered carriers already exist; author resources and test them rather than
  treating their adapter tests as completed talents.
- **T7:** Hastened, Accelerant, Echoing, Resonance and Critical Poison inputs;
  Bypass enablement; actual Assassin investment for Powder in either role.
- **T8:** Death Pact rank, Death Blade flag/chance, independent Decay-to-Shred,
  redesigned cap 80. Death Touch can use the existing all-stack modifier path;
  Coated Weapons can use augments. Verify their interactions after binding.

Sequence remains T3 review → T4 Bladedancer → T5 review → T6 Thief → T7 Assassin
review/implementation → T8 Shadow review/implementation → T9 integration → T10
player flows → T11 closeout. Dependencies discovered during a tree task are
recorded and verified there; T9 does not postpone correctness of an individual tree.

## Supported test access and content promotion plan

Practice currently starts with a 45-point budget, the scoped registry and default
primary Bladedancer, then restores its isolated Practice setup. Its state API can
change budgets within 0–45; this is not evidence that a budget editor is exposed
in the current screen. Test Mode starts fresh with Bladedancer, ten unspent points,
100 gold and the existing Bandit Blade loadout, then enters the contract loop.

For each promoted tree, require an actual supported selection path in Practice
and a documented Test Mode entry/preset path that can exercise it through combat
and applicable shop/reward flows. Practice must allow both ordered roles and
legal allocations up to 45 points. Test Mode must provide enough points for the
chosen acceptance builds without requiring an undocumented console edit. The
specific control/preset design belongs to the relevant implementation task; a
concrete conflict with the accepted T10 layout goes to the user before changing
that design. These are test-access requirements, not changes to Adventure rewards.

Extend the display catalog to Assassin/Shadow as their content is promoted;
currently its generator explicitly includes only Bladedancer and Thief. Bind
approved icons or truthful placeholders, descriptions and functional cues. Preview
is removed only after the node's effect and accessible player flow pass. Preserve
the two panels, grid, interactions and skill strip accepted in M4.

Each promotion records source hashes, approved specifications, resource/adapter
definitions and supported content revisions. Select the next revision during
implementation; T2 does not assign or activate a release ID. Test old-core and
mixed Practice setups against the candidate. Preserve legal compatible setups;
explicitly incompatible known revisions follow the existing complete-setup reset
policy. Corrupt/future saves reject without silent rewrite. Do not repurpose an
ID or auto-trim invalid allocations. Keep saves/tests isolated and retain the
Adventure `p6.compat.1` boundary; Adventure/Resume remain disabled.

## Validation matrix

Every individual rank has an explicit planned case in the JSON ledger. Each case
starts from a legal allocation, resolves that complete rank, checks the expected
effect and displayed value, then refunds/rebuys to detect stale or accumulated
effects. Shared tests are reuse candidates; they do not substitute for these new
bindings. The JSON `validation_test_candidates` map lists exact existing scripts.

| Family | Planned acceptance / boundaries | Existing evidence to extend | Owner |
| --- | --- | --- | --- |
| V01 — content/build | Exact inventory/IDs and all 140 ranks; one point per rank; gates 0/5/10/15/20; rank-one prerequisites; no cross-tree gate spending; unlocks below/at/above 1/3/6/9/12; both empty slots; illegal refund/budget edits atomic. | Ranked build, foundation integration, display tests | Each tree; T10 |
| V02 — stats | Every scalar/derivation rank, units/buckets, role scaling and source attribution; final rank replaces prior effects; flat/percent/gear combinations, floors/caps; temporary source add/expire rebuild; guarantee excluded from Double Dip. | Stat derivation/sources, core and gold tests | Each tree; T9 |
| V03 — lifecycle/scheduling | Zero/one/cap stacks; add then double then cap; exact deadline and one ms either side; resource capture, interruption/dodge/full block; duplicate cooldowns, 100 ms wait, clipped casts; retry cleanup. | Lifecycle, effect combat, T4 completion, macro/cooldown tests | T4, T7/T8; T9 |
| V04 — triggers/crit | Macro/retrigger/proc origins; same-hit Precision→Death Blade interaction; crit negation; actual application versus overflow; no Stab Poison loop; stable order, root budget/depth failure, trace-on/off replay. | Repeat/origin/order/failure tests | T4/T8; T9 |
| V05 — Poison | All relevant rank pairs; 0/1/2/3 fuel and near/full cap; natural/forced ticks, separate multipliers, no Pact on depletion; live crit and Virulent charges; IAS/suppress phase preservation. | Poison contract and status completion tests | T7; T9 |
| V06 — status/defense | Quantity/source accounting; Consume versus removal; Decay restoration, independent Shred, selective cleanse; Pact durations/caps, denial gear and negative defenses; physical/elemental conversion order; Master expiry; redesigned cap 80. | Status accounting/interactions/completion, T4 completion | T4/T6/T7/T8; T9 |
| V07 — gold | Raw versus credited floor per event; 0/fractional credits; stash versus theft/rewards/Overkill/spending; 50 Mug, 25/50/75 Silvered and 500 Gilded boundaries; Big Score 90%; children/live crit, once-only playback and Practice reset. | Gold contract, status completion, inherited economy/Overkill tests | T6; T9 |
| V08 — noncombat consumers | Charisma actual shop price/discount floors and rounding; Load Dice Magic Find in existing loot path and derived elemental stats; spending updates build snapshot without rewriting fight theft. | Economy stats and derivation tests, plus actual Test Mode consumer checks | T6; T10 |
| V09 — flows/persistence/lab | Every tree and role reachable; unlock/remove/re-unlock, alternate grant survival, duplicate rotation entries and ten-slot cap; save/reopen/retry; old-core/mixed compatibility and malformed/future rejection; Balance Lab uses legal actual registry builds. | Core/mixed journeys, persistence/boundary and Balance adapter tests | Each tree; T9/T10 |
| V10 — descriptions/rendering | Current/next rank text, effects/units, preview truthfulness, icons and functional feedback; all four trees, keyboard/tooltips and busy combat at accepted 1280×720, 1600×900, 1920×1080 and 125% text stress. | T10 usability, skill UI, combat presentation plus inspected new captures | Each tree; T10, final polish M7 |

Per tree, cover budgets 0, 1, 3, 5, 6, 9, 10, 12, 15, 20, 21, 35 and 45
where relevant; include unlock/gate neighbors and rejection above 45. A legal
35-point single-tree build covers its entire draft rank set, but intermediate
rank transitions still need their individual cases. Keep numerical DPS/win-rate
approval separate from deterministic correctness.

## Mixed-tree and gear coverage

T9 validates all six pairings in both primary/secondary orders (12 ordered
combinations). Select legal builds that activate the named effects; use 35/10
and legal 23/22 or other 45-point splits as needed, not an impossible all-max
70-point fixture. Retain exact M4 core and 15/5/reversed builds as regression anchors.

| Pair | Required interaction focus |
| --- | --- |
| Bladedancer / Thief | Retrigger→Double Dip versus gold crit; Fast Hands timing/Footwork; Bribery Shred/cleanse immunity; Dance/Precision; snapshot Bandit Blade after spending. |
| Bladedancer / Assassin | Bypass on Stab, Sharpened Edge physical versus Toxic Tradeoff; IAS/cadence; Opportunity children, Precision and buff grant order. |
| Bladedancer / Shadow | Same-hit Poison→Death Blade Stab consumes Precision; Coated suppression; Death Touch Footwork caps; independent Shred, immunity and Shadow Mastery physical benefits. |
| Thief / Assassin | Theft-derived live Poison crit; Fast Hands cadence; Fill Your Pockets elemental; Powder versus Finders (Pact requires Shadow and cannot join this two-tree build); resource starvation is measured, not balance-approved. |
| Thief / Shadow | Fill Your Pockets before Shadow Mastery; Load Dice/derived damage, theft/Shred and Decay/Shred, Finders plus Pact negative block; live capped gold sources. |
| Assassin / Shadow | Poison supply/depletion versus Consume; Umbral 80; Death Touch grants; Bypass/Mastery, Master resistance, Virulent charges; Touch IAS phase changes and Death Blade exclusions. |

Across those builds include gear for base/percent physical/elemental, IAS, crit,
retrigger, Bonus Stacks/doubling, Shred/Decay, gold/Magic Find/shop discount, block/
absorb denial, damage conversions and Bandit Blade's snapshot. Use neutral,
armor-heavy, resistance/absorb-heavy, block-heavy, cleanse, dodge/interrupt,
slow/suppress and crit-negation targets. Reuse seed sets from core/mixed/Poison
evidence; record exact build, target, seed, duration and trace mode for new cases.
Check identical reruns and trace-on/off equivalence, source immutability, cleanup
and reconciled damage/status/gold totals. Do not claim an exhaustive Cartesian
product of every gear combination.

M6 owns win-rate/DPS targets, progression, Poison supply tuning, economy ramp and
normal legal retrigger below 100%, plus Watchmen comparisons. M7 owns final art,
crowded text/effect presentation completion and audio teardown. M9 owns packaging
environment/shutdown checks. These are explicit exclusions, not missing M5 bindings.

## Validation and closeout

Fresh T2 checks and their exact commands/output are recorded in
[validation results](../project/reports/p6_m5_t2_static/summary.json).
Run the ledger check with `python tools/p6/build_m5_coverage_ledger.py --check`.
The report also records draft audit, identity, allocation-fixture, compatibility
registry, core/mixed fixture, display-catalog and negative conversion checks.

All nine checks pass. The first draft-audit run found a stale Bladedancer SHA-256
in the generated M2 inventory appendix. Regenerating with
`node tools/p6/audit_tree_drafts.js --write` changed only that hash, from
`f70eebc8a15db7780aa062795c82978c2db48721b5ff06a0c8889ddb2b7a9b6c` to the already
manifested current `8c33a60060ad7e42c45f254b2c24515c217f22f94fe68dfec819ae183242cbc2`.
The [exact diff](../project/reports/p6_m5_t2_static/inventory_appendix_refresh.diff)
and initial failed summary are retained. No source hash expectation or runtime
fixture was relaxed. The check run fingerprinted 759 runtime/data/test/scene and
draft files and found them unchanged; no save-writing runtime was invoked.

This task adds documentation and an audit tool only. No Godot runtime or rendered
suite was rerun; inherited M3/M4 results are linked as historical evidence and
test candidates, not fresh acceptance of M5 content. No gameplay resources,
source drafts, saves, fixtures, releases or combat rules were changed.

T2 completion: all source identities/ranks/grants accounted for; current bindings
distinguished from shared support and previews; settled discrepancies reconciled;
remaining questions and binding gaps have owners; supported access/promotion and
validation requirements recorded. **Next: T3 Bladedancer design review**, using
the ledger's eight remaining talents and the existing five as the reviewed baseline.
