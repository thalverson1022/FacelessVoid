# P6M2-T3 Progression and Allocation Rules

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

Date: 2026-09-22. Status: **Complete — design specification and handoff.**

This finalizes the user decisions following the [T2 audit](P6M2_T2_Cross_Tree_Draft_Audit.md).
T3 completion is documentation/design completion, not gameplay implementation or
balance validation. **T4 — Content workflow and compatibility is next.**

The build rules below are settled. Operational examples spell out their consequences
for implementation. Tree-role summaries are working interpretations of the drafts,
not new restrictions or approval of every talent. Unresolved individual mechanics
are assigned to M3/M5 and numerical balance targets to M6. These downstream decisions
do not reopen the agreed build foundations.

## Agreed foundations

- Shared earned budget capped at 45; one talent point buys one rank.
- Tavern rewards 1/0/2/3; subsequent contract completion grants gold plus three
  talent points once, until the cap. Bosses grant gear, not an extra talent payout.
- All investment in the same tree counts toward gates, regardless of row.
  One rank satisfies a prerequisite.
- Both selected trees grant base intrinsics and investment skill unlocks;
  only the primary receives per-point intrinsic scaling.
- Respec changes points only and preserves the selected trees and their roles.
  Playtesting uses free individual edits between contracts; eventual Alchemist
  respec refunds all points and starts cheap with dramatically escalating costs.
- Combat remains a player-designed macro that plays out automatically.

## Tree identities and build incentives — working design interpretations

| Tree | Role and intended decisions | Strength | Intended weakness | Gear synergies |
| --- | --- | --- | --- | --- |
| Assassin | Poison throughput: keep poison supplied, choose tick acceleration versus fuel consumption, time poison amplification through rotation order. | Sustained elemental damage and poison-specific mitigation answers. | Runs out of poison when consumption outruns application; spending heavily on poison weakens physical fallback. | Base/percent elemental, attack speed, crit once Critical Poison is available, Bonus Stacks. |
| Bladedancer | Physical rotation combos: build with Quick Cut, spend with Stab/Heavy Slash or Plunge, exploit repeat opportunities. | Armor pressure, rapid physical attacks and combo payoffs. | Block, crit negation, interrupted setup and poor rotation sequencing; shred alone should not solve every defense. | Base/percent physical, attack speed, retrigger, crit, Shred Value. |
| Shadow | Status management: apply and convert poison/Decay, decide whether to retain stacks for damage/mitigation or consume them for temporary power. | Flexible hybrid setup and payoff; mixed-tree status support. | Setup cost, depleted status pools after consumption, timing sensitivity and overlapping resource demands. | Elemental, crit-to-poison, Bonus Stacks, Decay Value; physical bonuses for selected payoffs. |
| Thief | Economy-to-combat growth: seed steals, reach capped combat bonuses, and spend excess gold without losing all combat value. | Gold-funded crit and hybrid scaling; economic utility. | Weak early theft ramp and noncrit sequences; capped gold conversion must prevent limitless hoarding dominance. | Increased Gold, Magic Find, crit, physical/elemental according to allocation; Shop Discount supports spending. |

Use these interpretations to guide M5 review and M6 testing; they are not
additional user-approved restrictions on the draft content. Overlap can serve
different purposes in different trees. Assassin owns tick
throughput; Shadow owns status consumption/conversion. Bladedancer owns physical
combos and direct shred specialization; Thief's shred is tied to actual theft.
Enemy counterplay remains necessary even where a capstone answers one defense.
These are intended roles to test in M6, not guarantees made by current draft values.

## Point income — Tavern and contract-completion rewards agreed

Use one earned budget B shared by both selected trees, capped at **45** as agreed by the user. Unspent points are legal.
Investment, not character level, controls gates/unlocks. Tree capacity is 35 ranks
in each audited draft; capacity does not determine how many points the player earns.

**Agreed reward ownership:** Contract completion awards **gold plus three talent
points** after the boss is defeated. The boss awards **gear**. There is one
three-point talent payout per completed contract, not separate boss and completion
point awards. Gold amounts are unchanged by this decision.

Keep the zero-point start and six Tavern points. After the Tavern, no normal,
captain or elite fight grants talent points. On first claiming a completed
contract's reward, grant `min(3, max(0, 45 - earned_points))` talent points.
The cap uses total earned points, including spent and unspent points; respec does
not restore reward eligibility. Prevent duplicate claims. Once 45 is reached,
subsequent completions still grant their other rewards but zero talent points.
Implemented in the shared progression policy; three-point contract rewards adopted under P6M6-D005 on 2026-10-07.

**Agreed Tavern distribution: 1 / 0 / 2 / 3** (P6M6-D006, 2026-10-07; supersedes the original 1/0/4/5).
Implemented in the shared runtime policy and authored encounter rewards.

| Encounter | Current reward | Cumulative reward |
| --- | --- | --- |
| Mouthy Drunk | 1 | 1 |
| Drunk Buddy | 0 | 1 |
| Tavern Bouncer | 2 | 3 |
| Hired Goon | 3 | 6 |
| Total | 6 | 6 |

Drunk Buddy retains its gear/shop introduction. With primary-tree investment,
the Tavern reward milestones are now 1, 3 and 6 points, matching the early automatic
skill-unlock thresholds. Three points after the Bouncer unlock the second investment
skill; six after the Goon unlock the third. The nine-point threshold now follows
Contract 1 rather than arriving in the Tavern. Actual skill lists still depend on
the selected tree and authored content. Talent tier gates are unchanged.

`RunFlow.TAVERN_ENCOUNTER_COUNT` is four. The separate legacy Vyra encounter is
not automatically a completed generated contract; being flagged as a boss alone
must not grant the new completion reward. Generated elites currently can award
points under depth rules; remove those talent rewards when implementing this policy.
T6/T7 must preserve the user-facing reward ownership even if the existing runtime
stores a contract payout on its terminal boss node.

| Progression milestone | Total earned talent points |
| --- | --- |
| New run | 0 |
| After Mouthy Drunk | 1 |
| After Drunk Buddy | 1 |
| After Tavern Bouncer | 3 |
| After Hired Goon / Tavern complete | 6 |
| Contract 1 complete | 9 |
| Contract 2 complete | 12 |
| Contract 3 complete | 15 |
| Contract 4 complete | 18 |
| Contract 5 complete | 21 |
| Contract 6 complete | 24 |
| Contract 7 complete | 27 |
| Contract 8 complete | 30 |
| Contract 9 complete | 33 |
| Contract 10 complete | 36 |
| Contract 11 complete | 39 |
| Contract 12 complete | 42 |
| Contract 13 complete and later | 45 |

Thus thirteen completed post-Tavern contracts reach the cap. Benchmark
checkpoints include Tavern exit (6), early contracts (9/12), middle (21/27/33), and
mature (45). At total budget 20 a single-tree build can meet the 20-point gate but
cannot buy the capstone's first rank until more points arrive; contract 5 supplies
that opportunity at 21. At 45, compare full-tree 35/10 and dual-capstone 24/21
allocations. These comparisons do not preapprove individual talent behavior.

Preserve the current secondary-selection milestone at the transition to generated
contracts as inherited behavior. Both trees become selectable in
Practice Room immediately. Adventure secondary access is not moved earlier by this specification.

## Allocation legality and validation contract

1. Exactly one primary tree is required; at most one distinct secondary tree may
   be selected after its Adventure access milestone. No duplicate tree in both slots.
2. A talent has an integer rank from zero to its authored maximum. **Agreed:
   each talent point buys one rank.** Total allocated ranks across both trees must not exceed earned budget.
3. **Updated by the user's refund bug report (P6M5-D007): talent gates require
   points in strictly lower tiers of the same tree.** Same-tier and higher-tier
   ranks cannot support a talent's own gate. Thresholds remain 0/5/10/15/20.
   Purchases, refunds and restored allocations validate the same rule; a refund
   is rejected atomically if any retained talent would lose its required support.
4. **Agreed: one rank satisfies a prerequisite.** For the current flat list, all listed
   prerequisites required. Existing grouped OR prerequisites are a legacy shape;
   T4 must translate or migrate them explicitly, not reinterpret silently.
5. Gate and prerequisite requirements remain true after any edit, not just at
   the instant of purchase. A rank can be bought only if the resulting build is legal.
6. Automatic unlocks use total investment in their own tree, including all rows,
   at 1/3/6/9/12 points. They cost no additional points, award no points, and do not
   count as prerequisite ranks. Null slots grant nothing and do not block later slots.
7. Talent skill grants activate at rank one and disappear at rank zero unless
   another retained source grants the same approved runtime skill.
8. Gates and unlocks count current allocated points, not lifetime purchases,
   refunded points, available budget, gear stats, or the other tree's investment.

Purchase and retained-build legality now use the same lower-tier support rule.
For five points in tier one and five in tier two, refund tier-two points first;
removing a tier-one point while tier two remains is rejected. Full-tree/all-point
resets remain available under the existing respec rules. Invalid restored builds
follow existing save rejection handling. This supersedes the original resulting-total
rule that permitted upper ranks to support themselves. Automatic skill unlocks
and intrinsic scaling still count all allocated points in their own tree.

## Primary and secondary intrinsics

Under the agreed role distinction, a chosen tree grants its base
intrinsic even at zero investment. Only primary-tree investment provides the
per-point term. Both trees receive skills according to their own investment.
Base intrinsics do not spend points or contribute to gates. Slots carry explicit
roles; never infer primary from which tree has more points.

| Tree | Draft base | Primary per-point term | Content status |
| --- | --- | --- | --- |
| Assassin | +5 flat base elemental | **+1 flat base elemental per invested point** | User clarified: ten invested points grant +10 flat elemental, not +10%. |
| Bladedancer | +5 percentage points random retrigger | +0.2 percentage points per invested point | Draft value retained for M3/M5 review; no new hard cap approved here. |
| Shadow | +20 percentage points chance for eligible crits to apply poison | +2 percentage points per invested point | Apply the agreed primary-only scaling convention; detailed proc behavior belongs to M3/M5. |
| Thief | +10 percentage points Increased Gold | +2 percentage points Increased Gold per invested point | Uses the gold bonus bucket, not a new currency or separate payout. |

**Agreed: respec redistributes points only.** It does not replace selected trees
or swap primary/secondary roles. A very expensive future Alchemist option to change
the secondary or promote it to primary is only a possibility to revisit later,
not an approved feature. Initial secondary selection remains progression, not respec.

## Refunds, respec and rotation consequences

**Agreed intent:** Build archetypes should persist across fights. Respec allows
occasional correction without making choices permanent; moving points for each
opponent must not become a core or expected mechanic. Encounter balance must not
assume that players redistribute points before every fight.

**Reconfirmed testing access:** Individual point allocation/deallocation for
respec is free **between contracts only**. No redistribution between fights within
an active contract, including retries, or during combat/playback. Use the existing
between-contract flow; this does not require the Alchemist. Costs remain deferred
until proper testing. New spending of earned/unspent points follows the existing
progression planning flow; the between-contract restriction controls respec.

**Agreed future direction, deferred:** Respec belongs at the planned Alchemist,
a shop-like provider for non-gear upgrades. The first respec should be cheap,
with dramatically increasing costs for subsequent respecs. The user also envisages
consumable potions and upgrades such as extra inventory space. Those systems,
the Alchemist itself, pricing, and the respec-count reset/persistence policy are
future work, not newly authorized Phase 6 implementation. The scope/lifetime of
account versus run upgrades remains to be specified separately.

**Agreed final respec operation:** Refund all allocated talent points, retaining
selected trees and their primary/secondary roles. No individual-rank refund in the
final version. Refunds return spent points to the unspent pool without changing the
earned budget. Full reset clears allocations across both trees, retaining their
identities and primary/secondary roles.

**Agreed playtest operation:** Permit individual allocation and deallocation,
following the existing simplified-tree interaction. The inspected
`PassiveAllocator.can_deselect_talent` blocks removal when it would break a retained
prerequisite; it does not cascade-refund dependents. Extend that existing policy to
ranks: removing a predecessor from rank two to one can be legal, but removing its
last rank is blocked while required. Do not silently refund other nodes. Investment
gates are new and need an explicit post-edit check using total tree investment; the old allocator cannot cover that case unchanged.

**Build-edit behavior:** New rank purchases using unspent points remain free in
existing planning/build-edit flows. Practice Room retains free editing and a freely
adjustable budget from zero to 45. Successful individual edits must preserve legal
rank caps, gates, prerequisites and total spend. Reject an invalid edit atomically
and explain the dependency; earned points are never lost.

Re-resolve stats, intrinsics and skill availability once after the transaction.
Filter rotation entries against the resulting skill set, preserving surviving
order and duplicates and the inherited ten-slot limit. Do not auto-insert newly
unlocked skills or silently restore removed entries later. Show which entries were
removed. An empty rotation is legal as an editing state but cannot start a fight.
Clear the existing build lock on changes. T4 defines persistence and any draft-edit
undo behavior; these rules do not specify migration of old saves.

## Legal and invalid examples

Refund examples below assume an allowed between-contract respec window; the same
edits must be rejected within an active contract. These examples use tree-local
names because the T2 audit found ID collisions.
They do not authorize runtime IDs. “Budget” is the total available points.

| Case | Allocation or edit | Expected result |
| --- | --- | --- |
| First gate | Assassin Quick Hands 5, then Hastened Poison 1, budget 6 | Legal: five invested tree points unlock row 2 before purchase. Six points unlock the first three populated automatic slots. |
| Buy too early | Assassin Quick Hands 4, then Hastened Poison 1, budget 5 | Rejected: row 2 lacks five supporting points even though budget is sufficient. |
| Rank maximum | Assassin Quick Hands rank 6 | Rejected: authored maximum is five. |
| Cross-tree gate | Assassin Quick Hands 4 plus Thief Keen Eye 5; buy Hastened Poison | Rejected: Thief investment cannot satisfy Assassin's gate. |
| Prerequisite | Assassin Quick Hands 5, Precision 5, Echoing Toxin 3, Poison Strike 1, Bypass 1; buy Accelerant | Rejected: enough tree investment for row 4, but Hastened Poison is absent. |
| One-rank predecessor | Assassin Quick Hands 5, Precision 5, Hastened Poison 1, Echoing Toxin 3, Poison Strike 1; buy Accelerant 1, budget 16 | Legal: 15 tree points and one rank in the predecessor. |
| Total-tree gate refund | From Quick Hands 5 + Hastened Poison 1, refund Quick Hands to 4 | Rejected: Hastened Poison still needs five points in lower tiers. Refund Hastened Poison first. |
| Unlock loss on individual refund | Assassin Quick Hands 5 + Precision 5 + Hastened Poison 2; refund one Hastened Poison rank | Eleven invested remain; lose the 12-point Poison Vile unlock. Only its unavailable rotation entries are removed. |
| Same/higher-row support | Retained nodes have at least their required total tree investment after a refund, even though lower-row investment alone is below the gate | Rejected under P6M5-D007: same/higher-tier ranks cannot replace lower-tier support. |
| Shared budget | Two individually legal 18-point trees with budget 35 | Rejected: 36 exceeds shared budget. |
| Mature dual capstone | A legal 24/21 split at the agreed budget 45 | Both capstones and both 12-point automatic tracks available; neither tree can spend all 35 ranks. |
| Mature full tree | A legal 35/10 split at budget 45 | One fully ranked tree; secondary cannot reach its 12-point automatic skill or capstone. |
| Duplicate trees | Same tree selected as primary and secondary | Rejected. |
| Refund unlock with another source | Lose a talent grant but retain an independent grant of the same approved skill | Keep the skill and its rotation entries. |

## Confirmed individual mechanic meanings to preserve

These clarifications must travel into the M3/M5 specifications. They are not
implemented by this document and must not be reinterpreted from ambiguous draft labels.

| Mechanic | User-confirmed meaning | Detail still owned downstream |
| --- | --- | --- |
| Assassin intrinsic | +1 **flat base elemental damage** per primary-tree point; ten points add +10 flat, alongside the draft +5 base intrinsic. | M5 full intrinsic/tooltip integration. |
| Shadow Mastery | Copy the rank percentage of current flat elemental and increased elemental bonuses into physical benefits without removing the elemental benefits. Include gear, talents, intrinsics and temporary buffs. At rank one (10%), +10 elemental adds +1 base physical to weapon damage; +150% increased elemental grants a separate x1.15 physical multiplier. Both apply together. | M3 source aggregation, update timing as buffs change, rounding and effect order; M5 talent/interaction checks. |
| Gilded Blade | Count at most 500 current stash gold at +1 percentage point bonus crit damage per gold: 100 gold gives +100%, 500 or 10,000 gives +500%. Cap this talent's contribution, not all crit damage. | M3/M5 dynamic updates and tooltip/gear interaction. |
| Stolen gold | Current-fight theft only; reset the counter to zero after each fight, without removing the actual credited stash gold. | M3/M5 preserve baseline credited-steal multiplier/floor unless deliberately changed. |

Other derived-stat formulas, Silvered Edge/Mug details, poison crit behavior,
conversion ordering, and random versus guaranteed repeat execution remain M3/M5
work. No 99% retrigger hard cap, specific guaranteed-repeat algorithm, or numerical
win-rate band is approved by this closeout. Retain existing retrigger safety/watch
requirements until M3 defines the affected mechanics explicitly.

## Player decisions and complexity requirements

**Agreed:** Combat remains unchanged in interaction: the player designs a macro
that plays out during the combat phase. Preserve pre-fight build/gear/rotation
planning followed by automatic combat and playback. Do not add real-time reaction buttons in this phase. Conditional skills
and cooldowns must have deterministic scheduler behavior defined in M3; unavailable
skills must not deadlock or create zero-time infinite loops. Retain ten rotation
slots, with repeated skill entries allowed. Cooldown ownership and conditional-slot
execution are M3 specifications, not newly settled combat rules.

Keep macro planning understandable: show the requirements and effects of the
player's choices, and expose temporary effects through playback rather than
requiring real-time reactions. T5/M4 assess complexity with dense tree and busy
combat examples. No arbitrary maximum number of tree mechanics is adopted here.

Planning must expose current/next ranks, total-tree gate progress, unlock thresholds,
intrinsic role, refund consequences and capped derived bonuses. M3 supplies event
data for consumption, charges and timed effects; M4 tests dense mixed-tree views
and busy playback; M7 finishes art and feedback.

## Progression checkpoints, initial power goals and representative cases

Use entry/10/15/20/25/30/45 budgets with low, typical and strong gear at the same
progression stage. M6 must select reproducible gear fixtures and seeded enemy sets;
do not compare one tree in best-case gear against another in starter gear.

Initial qualitative goals: each tree should support a coherent macro at its
progression stage; mixed investment should trade deeper ranks for broader access;
gear and macro choices should provide matchup responses without requiring respec
before each fight. Use the actual 10/15/20/25/30/35/40/45 reward progression when
selecting cases. Compare typical, weak and strong gear at the same stage.

M6 owns numerical win-rate/DPS targets and enemy tuning after measuring representative
builds. Earlier candidate numerical bands are withdrawn, not acceptance criteria.
Track damage sources, fuel starvation, actual proc counts, cap waste and buff uptime
alongside DPS. Retain the Bladedancer Watchmen watch item. M5 refines working tree
identities/weaknesses through detailed content review; T5 selects exact test builds.

Representative build families (exact allocations selected in T5):

- Assassin: poison supply baseline, accelerated/multi-consumption variant, mature
  Critical Poison; compare fuel shortage against sustained application.
- Bladedancer: Quick Cut/Rending baseline, Precision repeat route, Footwork/Plunge
  route; compare armor-heavy targets with block and interruption counters.
- Shadow: coated attacks/Decay baseline, conversion/consumption route, mature cap
  support; verify resource loss and restored enemy resistance after consuming Decay.
- Thief: low-gold opener, theft ramp and capped wealthy build; compare shopping
  before/after, zero steals, high Magic Find and crit-negation enemies.
- Mixed: all six tree pairings at the agreed 45-point budget; compare 35/10, 24/21
  and 33/12. Dual capstones are intentional, but cost deeper ranks elsewhere. Check
  that support investment still has measurable opportunity cost.

## Implementation boundaries and acceptance handoff

The current runtime separately limits points in `BuildState.TALENT_POINT_CAP`,
`TrainingRoomState.PRACTICE_TALENT_POINT_BUDGET` and
`ContractRouteGenerator.TALENT_POINT_REWARD_CAP` (all 10). Updating only the build
cap will not restore reward income above ten. `PassiveAllocator.POINT_BUDGET` is
a separate default of seven. T6/T7 must use one approved policy and reconcile callers.
No constants are changed by this document.

T4 owns stable identities, resource-path migration, old budget handling and save
schema. T5 owns the dependency plan and M4 build choice. M3 owns exact tick/buff/
cooldown/consumption/crit and penetration execution. M6 owns tuning against measured
runs. T3 settles budget, earning, roles, legality and refund policy for T6;
T4 still must settle content authority, compatibility and persistence before T7.

Acceptance examples to carry into T6/T8: all cases above, each gate at N−1/N/N+1,
each unlock threshold before/at/after refund, zero/negative/fractional/over-max ranks,
budget overflow, rejected tree replacement/role swapping, full-reset respec, repeated rewards, cap crossing,
empty rotations and retaining skills granted by another source. These are planned
checks, not tests run against an implementation.

## Downstream decisions and next step

| Owner | Required work before affected implementation |
| --- | --- |
| T4 — next | Authoritative content/revisions, explicit stable-ID mappings for collisions, resource-path migration, old-save budget/rank treatment, Practice Room persistence and rotation compatibility. |
| T5 | Dependency/validation plan, exact representative builds, essential/experimental scope, UI and diagnostic requirements, M4 candidate. |
| T6/T7/T8 | Implement and validate the agreed build/reward rules, content conversion and persistence. Include capped partial rewards, duplicate claims, no elite talent rewards, legal refunds, unlock filtering and primary-only scaling. |
| M3 | Shared buff/charge/cooldown/status/trigger systems, derived-stat timing and ordering, deterministic recursion safety. Use concrete talent cases and settle semantics before coding affected behavior. |
| M4 | Representative playable integration; gate/rank/refund/rotation UI and busy temporary-effect display. Practice Room remains a free experimentation sandbox. |
| M5 | Meticulous review with the user of each tree's intrinsic, every talent/rank, skill and unlock; specify examples, implement, verify tooltips and interactions, then check mixed-tree and gear combinations. |
| M6 | Measured difficulty targets, enemy tuning, progression pacing and economic incentives. |
| Future Alchemist | Location/UI, cheap first respec and sharply escalating later costs, counter persistence/reset, consumables and other upgrades. Expensive secondary/primary changes remain only a possible future feature. |

## T3 closeout evidence and limits

Completed on 2026-09-22 at the user's request after foundational questions were
answered. User decisions are recorded in the M2 tracker; this specification
consolidates them and documents operational consequences and verification examples.
Working identities and initial qualitative goals are provided as planning inputs;
meticulous tree decisions and numerical balance targets have named downstream owners.

Verification: document-link and active-status checks; Tavern/contract arithmetic;
review of rank/gate/refund examples against the four audited drafts and inherited
allocator semantics. Draft inventory parity was checked with
`node tools/p6/audit_tree_drafts.js`; `git diff --check` checks tracked whitespace.
No gameplay test suite was run because no runtime code or source draft was changed.
The checks establish documentation consistency, not implemented correctness or balance.

T3's design/documentation checklist is complete. M2 remains in progress;
**continue with T4 — Content workflow and compatibility**. The T2 audit remains
historical evidence; use this specification for decisions that resolved its questions.
