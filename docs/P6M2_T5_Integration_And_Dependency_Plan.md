# P6M2-T5 Integration and Dependency Plan

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

Date: 2026-09-22. Status: **Complete — planning and downstream handoff.**

Follow-up (2026-09-23): M2 T6–T9 are complete; see the
[T9 closeout and M3 handoff](P6M2_T9_Closeout_And_M3_Handoff.md). Future-tense foundation steps below record the
original plan. The ranked Balance Lab adapter was delivered in T8; redesigned
combat scenarios remain gated. The original mechanics and scenario requirements
still apply to M3 onward.

T5 orders implementation of the [T3 build rules](P6M2_T3_Progression_And_Allocation_Rules.md)
and [T4 content/persistence policy](P6M2_T4_Content_Workflow_And_Compatibility.md),
assigns the remaining [T2 audit](P6M2_T2_Cross_Tree_Draft_Audit.md) questions, and
selects reproducible builds. It does not approve unresolved mechanics, final balance,
art, or completed gameplay. T6 is next. T4's full fresh-run invalidation of old
saves remains settled; do not implement the superseded talent-refund proposal.

Companion: [exact planning fixtures](P6M2_T5_Build_Fixtures.json).
`node tools/p6/check_build_fixtures.js --expand` prints their complete rank maps.
These are model fixtures and future integration candidates, not executable content.

## 1. Scope and priority

**Essential foundation:** explicit primary/secondary roles, ranks, shared 45-point
budget and reward ownership, gates/prerequisites, legal refunds, intrinsics, grants,
rotation normalization, content registry, new persistence, old-save invalidation,
isolated Practice Room setup, deterministic checks and understandable failures.

**Essential content work, subject to detailed review:** the mechanics supporting
all 44 authored talents, four intrinsics and 20 populated skill records. Being
unresolved does not make a mechanic optional. M3/M5 must specify each affected
behavior with the user before implementing it. Any removal/substitution requires
an explicit content decision and tracker update; T5 does not silently cut scope.

**Essential presentation:** tree/rank/gate and rotation UI, temporary-effect state,
usable tooltips, readable icons, playback and diagnostics sufficient to explain
the implemented mechanics. Placeholder art is acceptable during M4 prototyping;
final readable assets remain M7 acceptance work. Enemy/progression tuning remains M6.

**Deferred/experimental:** new content for the two empty 9-point slots, a general
undo history, named build-preset library, advanced diagnostic charts/trace export,
and additional animation/audio beyond the cues needed for comprehension. Empty
slots remain null in this plan; M5 may propose content explicitly. Alchemist,
consumables, tree/role-changing respec, new classes, broad gear/route redesign and
real-time combat controls remain outside the agreed Phase 6 implementation scope.
No essential mechanic may be reclassified as experimental to close a milestone.

## 2. Dependency packages and content coverage

Packages below are work groupings, not new milestone numbers. A-T01 etc. refer to
the audit's exact source objects, not runtime IDs. Every tree also depends on F1–F3.

| Package | Scope and exact content coverage | Owner and prerequisites | Required evidence |
| --- | --- | --- | --- |
| F1 Build/progression | All four trees: roles, ranks, costs, gates, ALL prerequisites, 45-point cap, 1/0/4/5 Tavern and five-point contract rewards, playtest refunds and final full reset | T6; T3 | Legal purchase/retention, atomic invalid edits, rewards once, role retention and cap tests |
| F2 Resolution/content | All intrinsics, all 20 automatic slots and two talent grants; A-T01/02/07, B-T01/02/10/13, S-T03/04/08/09, T-T02/03/07/08 static fields after bucket review | T6 resolution, T7 conversion; F1, T4, approved stat meanings | Exact rank selection, base versus primary-only scaling, independent grant sources, registry validation |
| F3 Persistence/sandbox | Adventure and Practice build state, rotation, old-save reset, new envelope/version outcomes | T7; F1/F2, T4 | T4-C/S/R/P cases; no practice-to-Adventure state leakage |
| C1 Stat derivation | B-T08 Double Dip, B-T09 Sharpened Edge skill multiplier, S-T07 Shadow Mastery, T-T05 Fast Hands, T-T06 Fill Your Pockets; temporary bonus updates and source buckets | M3 shared math; M5 definitions; F2 | Source aggregation, live/snapshot order, negative/floor/cap cases and tooltips |
| C2 Timed effects and charges | A-T06 Bypass, A-U3/U4; B-T06/T11 Footwork/Riposte, B-T07 Precision, B-U5 Dance; S-T10 Death Pact, S-U4/U5; A-U2 if confirmed temporary | M3; F2, approved activation/refresh/reset rules | Lifecycle, charge consumption, expiry ties, no between-fight leakage; event records |
| C3 Scheduler/skill contract | All 20 populated skills; especially B-U2 Plunge, B-U3 Parry, B-U5 Dance, S-U4/U5 cooldowns | M3 scheduling; M5 per-skill definitions; C2 when applicable | Finite progress with ineligible/cooling slots, duplicate-slot ownership, interruption/consumption ordering |
| C4 Poison execution | A-T03/08 cadence, A-T04/09 multi-consumption, A-T05 forced ticks, A-T10 critical poison, A-U1/U3/U5 | M3; C1/C2/C3 and event ordering | Zero/remainder stacks, forced/natural ties, phase and cadence changes, actual consumption and crit source |
| C5 Trigger/repeat/crit | B-T03 Opportunity, B-T07 Precision, B-T12 Side Step, B-U3/U5, S intrinsic, S-T11 Death Blade, A-T10; inherited gear procs | M3; C2/C3 and approved origin filters | Seeded order, eligibility, guaranteed versus random repeats, termination and suppression |
| C6 Status/mitigation | B-T04 Virulent Corruption, B-T05 Rending Slash; S-T01/02/05/06/10/11, S-U1/U2/U3/U4/U5; A-U2/U4; T-T10 Finders Keepers | M3; C1/C2/C4/C5 as applicable | Decay accounting/restoration, selective cleanse, Bonus Stacks applied once, caps and penetration order |
| C7 Economy combat | T intrinsic, T-T01 Gilded Blade, T-T04 Silvered Edge, T-T09 Bribery and all five-slot track's four skills; T-T03/05/06/07/08 interactions | M3 source/state math; M5 content; F2, C1/C5/C6 | Current versus fight-stolen gold, floors/caps, spending and reward separation, reset/retry behavior |
| U1 Views/diagnostics | Trees, tooltips, macro editor, player effects, enemy statuses, recap and Practice Room | M3 event producer; M4 UI/playback; M5 content copy; M7 finish | UI and event contracts below, actual visual and playable verification |
| V1 Scenarios/tuning | Exact fixtures, both role orientations, progression checkpoints, gear and enemy interactions | T8 foundations; M3 deterministic mechanics; M4 integration; M5 content; M6 balance | Correctness before measured difficulty targets; retain watch items |

The class skills Stab, Heavy Slash and Hold, gear-generated grants, and existing
damage conversion/denial effects are regression dependencies even when absent from
the drafts. No package replaces the combat resolver wholesale.

### Audit question disposition

| Audit question | T5 handoff |
| --- | --- |
| Q01–Q03 | Settled by T3/T4; implement in F1–F3. Do not reopen allocation policy. |
| Q04 | C1/F2: specify canonical units, rank totals versus increments, stat buckets, copy semantics, dynamic aggregation and order before each affected modifier. Preserve confirmed Shadow Mastery meaning. |
| Q05–Q06 | C4: resolve cadence formula/phase, Accelerant/Resonance composition, remainder/zero stacks, forced ticks, Virulent charges, crit RNG and consumption provenance. |
| Q07 | C2: each effect gets an activation/duration/cap/refresh/expiry/consumption/reset contract. Death Pact timer unit requires M3/M5 review. |
| Q08–Q09 | C3: combat stays macro playback. Specify skip/wait/advance, cooldown ownership/start, windup snapshots and all skill eligibility. No algorithm is approved here. |
| Q10–Q11 | C5: specify trigger origin eligibility, guaranteed-repeat semantics, first-hit meaning, crit negation, poison-on-crit and recursion/event limits. Keep below-100% normal random-retrigger watch; no invented 99% cap. |
| Q12–Q14 | C6: authoritative Decay quantity, resistance restoration, conversion/cleanse order, penetration, cap overflow and Bonus Stacks scope. Never derive live Decay only from accumulated resistance reduction. |
| Q15 | C7: retain T3's stash-gold cap and fight-local stolen gold; specify remaining Mug, Steal, Pick pocket, Big Score and Bribery behavior before implementation. |
| Q16 | T4 resolved the pipeline, identities and save policy. Heavy Strike alias, Death Pact unit and affected executable effects stay M3/M5 blockers, not reasons to reopen T4. |
| Q17 | Two empty slots stay unassigned. Adding content is a later explicit M5 decision; no replacement skill is required for foundation completion. Essential/experimental boundary above. |
| Q18 | T3 reward checkpoints and qualitative identities retained; fixtures below make builds exact. Numerical difficulty targets and gear-quality cohorts remain M6. |
| Q19–Q20 | UI/diagnostic contract, selected M4 builds, scenario matrix and ownership below complete T5's planning portion. Execution evidence is downstream. |

Before implementing an affected mechanic, M3/M5 must record: eligible sources and
miss/interrupt behavior; value/unit and caps; activation/consumption timing; duration
or charges; refresh/stack/replace policy; same-time priority; RNG/proc eligibility;
cleanup between fights/retries; emitted events; and at least one normal, boundary
and conflicting-effect example. M3 specifies a total event order and finite-event
safeguard, including what a limit breach reports. Depth 16 alone is not a proof of
bounded branching. No limit value or gameplay outcome is silently selected by T5.

## 3. Ordered implementation and release gates

| Order | Work | Start dependency | Exit/handoff |
| --- | --- | --- | --- |
| 1 — T6a | Establish rank/role state and pure legality operations; reconcile allocator default 7 and all three current 10-point caps under one policy | T3/T4 and this plan | F1 legal/invalid and role tests; retain legacy OR fixtures separately from new ALL semantics |
| 2 — T6b | Intrinsic and grant resolution; buy/refund transaction; reward ownership/single-claim state; callers updated coherently | T6a | F1/F2 tests including no cascade, no elite points, cap crossing, unchanged tree roles |
| 3 — T7a | Registry/content validation and representative converted resources; Balance Lab adapter accepts explicit roles/ranks | T6 state interface, T4 manifest | Hash/reference checks, unsupported-effect rejection and explicit content readiness |
| 4 — T7b | Save classification/full legacy reset, v2 round trips, isolated Practice setup, shared rotation normalization | T6b/T7a; complete registry for enabled content | F3/T4 cases, load UI outcomes and write-failure reporting |
| 5 — T8/T9 | Integrate foundation fixtures through allocate/refund/resolve/save/reload; affected inherited regression; close M2 with limitations | T6/T7 evidence | Verified model/persistence handoff to M3; no claim of full combat or M4 visual completion |
| 6 — M3 first slice | Specify and implement C2/C3/C5 subset for core Bladedancer; bring the affected M5 skill review forward | Foundation handoff; core prerequisite list below | Tested Footwork, conditional skill scheduler, repeat origins and event feed |
| 7 — M4 core | Wire first build through Adventure and Practice, effects, playback, tooltips and rank UI | All core accessible mechanics approved and implemented | Core end-to-end and visual cases pass; defects return to responsible package |
| 8 — M3/M4 extension | Dance/cooldowns, Opportunity and Thief Steal/Mug contracts; mixed-role integration and stress UI | Core, C2/C3/C5/C7 reviewed dependencies | Mixed build works; zero-investment, refund and busy-state cases reviewed |
| 9 — M3/M5 remaining content | Remaining poison/status/derived/economy mechanics, then per-tree and mixed content review/implementation | Relevant package contracts | All approved content and tooltips work; full pair matrix validated |
| 10 — M6/M7/M8/M9 | Measure/tune progression and enemies; finish icons/feedback; playtest, regression and closeout | Implemented content, reproducible scenarios | Named milestone acceptance evidence; numerical targets agreed before tuning |

Orders 6–9 may overlap when dependencies are ready; they are not permission to
skip detailed content review. Implement event production alongside each mechanic,
not after UI integration discovers missing state.

**M2 isolation rule:** foundation tests may use test-only descriptors for rank,
gate and grant graphs whose combat effects are unimplemented. They must be labeled
model-only, must never execute as silent no-op gameplay, and must not enter the
release manifest. T7 persistence tests can use an isolated complete test registry.
Activating new player saves requires a complete registry for the enabled content
subset, as T4 requires. Keep the inherited playable path coherent until the
reviewed slice can replace it; do not flatten ranks back to binary selection to
make an old panel appear to work.

## 4. First playable build and exact validation fixtures

### Candidate comparison and selection

| Candidate | Useful first-slice coverage | Main unresolved dependencies | Decision |
| --- | --- | --- | --- |
| Assassin 10 | Ranks, poison cadence/consumption, talent skill grant, timed/charged automatic skills | Forced/scheduled ticks, poison buckets, penetration, active/passive Blinding Powder, several temporary effects | Use as focused C4 case after core event/scheduler foundations |
| Bladedancer 10 | Ranks, explicit grant, automatic skills, Footwork gain/consume, Parry eligibility, inherited repeat events | Footwork timing, Plunge consumption/windup, Parry window, trigger-origin rules | **Selected first M4 build:** exercises real temporary effects without needing every status/economy system |
| Shadow 10 | Talent augments, Decay, poison conversion and temporary IAS | Live Decay state, resistance restoration, consumption ordering and cooldowns | Later C4/C6 integration |
| Thief 10 | Gold state, derived stats, stealing and capped combat bonuses later | Steal/Mug/Pick pocket scope, gold-to-stats aggregation; less temporary-effect coverage | Secondary in M4 extension; mature economy scenarios later |

Selection is a planning decision made while carrying out T5, not a user approval
of unfinished Bladedancer/Thief behavior or values.

**Core `m4_bladedancer_core`, budget 10:** Bladedancer primary, no secondary;
Whetstone 4, Rending Slash 1, Fancy Footwork 5. Buy Whetstone four times and
Rending Slash once before Footwork. Rotation: Quick Cut, Quick Cut, Parry Strike,
Leaping Plunge, Rending Slash. It uses five slots and intentional repeated Quick Cut.
It is a single-tree build usable at Tavern exit; mixed access is tested separately.

Core prerequisites: approve Bladedancer base/per-point intrinsic; Whetstone and
Rending Slash content; Quick Cut, Plunge and Parry full skill contracts; Footwork
trigger/refresh/expiry/cap and consumption timing; whether consumption affects the
consuming windup; Parry readiness window and ineligible-slot behavior; eligible
random/proc/retrigger origins; inherited class skills/gear interactions; effect
events and displays. Every unlocked skill needs a working contract even if a test
rotation omits it. The empty 9-point slot grants nothing. No Dance dependency is
introduced until twelve points are allocated.

**Extension `m4_bladedancer_thief`, budget 20:** Bladedancer primary 15 = core
10 plus Opportunity 3 and Cloak & Dagger 2; Thief secondary 5 = Keen Eye 5.
Rotation: Dance of Death, Quick Cut, Quick Cut, Parry Strike, Leaping Plunge,
Rending Slash, Steal, Mug. Thief receives its base intrinsic and own 1/3-point
unlocks, without per-point primary scaling. Secondary selection occurs after
Tavern at the inherited contract transition, not earlier.

Additional prerequisites: Dance first-hit/repeat interpretation, duration and
cooldown ownership; Opportunity proc source rules; Cloak & Dagger bucket; Keen Eye
damage scope; Thief base intrinsic and Steal/Mug definitions. This is the M4
mixed/cooldown acceptance build, not an attempt to complete Thief's entire tree.
Run the same setup with zero secondary investment and in separate role-reversed
Practice fixture `m4_thief_bladedancer` to expose primary-only scaling. Adventure respec never swaps roles.

### Fixture contract and coverage

The JSON contains **six purchase profiles and 121 exact fixtures**:

- Four full-tree profiles, each a legal 35-rank purchase sequence. A profile step
  names a stable runtime talent ID and a target rank; expand one rank at a time.
  A fixture's point count selects that exact prefix. This determines a unique rank
  map, not a suggestion to distribute points arbitrarily.
- Each tree has 19 budget snapshots: 0/1/3/5/6/9/10/11/12/15/20/21/24/25/30/33/35/40/45.
  Budgets 40/45 spend 35 and retain 5/10 unspent. Extra snapshots test gate/unlock
  boundaries; they do not change the actual reward schedule.
- All six pairings, both primary/secondary orientations, each at 35/10, 24/21 and
  33/12 = 36 mature mixed builds. Each 21/24 prefix includes that tree's capstone;
  each 12-point side reaches its populated final automatic slot.
- Three M4 fixtures (core, mixed and explicit role reversal), an Assassin forced-tick variant, a Bladedancer Precision
  variant, and four zero-investment secondary cases.

The model fixtures' default Stab/Hold rotation only checks base-skill availability.
It is not a damage-optimized macro and must not be used to infer tree balance.
Scenario-specific rotations are specified below and reviewed with the corresponding
skill contract. The checker verifies source hashes, identity revision, each purchase
gate/prerequisite, retained legality, rank caps, budget, distinct roles, and authored
rotation availability/ten-slot limits. It does not verify execution of any skill.

| Mechanic family | Exact fixture(s) | Future combat probe |
| --- | --- | --- |
| Poison baseline/forced ticks | `assassin_forced_tick_10`: Quick Hands 5, Hastened Poison 3, Echoing Toxin 1, Poison Strike 1 | Venom Jab → Poison Strike → Virulent Poison; vary fuel, natural/forced ties and charges |
| Mature poison | `assassin_30`, `assassin_35` | Venom Jab → Virulent Poison → Poison Strike → Poison Vile; check Accelerant/Resonance/Critical Poison and compare supply shortage |
| Footwork/conditional | `m4_bladedancer_core`, `bladedancer_20` | Core macro; latter also tests Riposte and wider status presentation |
| Precision repeat | `bladedancer_precision_15` | Quick Cut → Stab → Parry Strike → Dance of Death; test guaranteed versus random repeat origin |
| Shadow conversion | `shadow_25`, `shadow_35` | Beguiling Strike → Beguiling Strike → Distilled Corruption → Death Strike → Touch of Darkness → Beguiling Presence; compare retaining versus consuming status |
| Thief ramp/caps | `thief_10`, `thief_21`, `thief_35` | Steal → Mug; add Pick pocket at 6 and Big Score at 12 invested points; compare initial gold 0/100/499/500/501/10000 and zero theft |
| Mixed roles/depth | All 36 `mix_*` fixtures | M5 chooses mechanic-specific macro comparisons after each skill review; run both orientations with the same gear/enemy/seed cohort |

For mechanical threshold tests, use deterministic setup/state injection rather than
hoping a random 30-second fight happens to produce exactly zero, one or two stacks.
These probes supplement, not replace, playable macro tests.

## 5. UI, playback and asset acceptance

| Surface | Minimum required information and behavior | Owner / verification |
| --- | --- | --- |
| Tree selection | Explicit primary/secondary labels, base intrinsic and primary-only scaling, Adventure access gate; Practice freely edits roles under T4 rules | T6 state, M4 view; zero-investment and opposite-role fixtures |
| Talent tree | Authored rows, rank/max, current and next effect, one-point cost, own-tree gate progress, all prerequisites at rank one, selected/locked/available states | M4; do not derive authored rows solely from prerequisite depth |
| Refund/edit | Preview rank and unlock losses; identify the exact failed gate/prerequisite; invalid edits leave all ranks unchanged; respec availability reflects contract state | T6/T7 state, M4 UI; dependent and gate-refund cases |
| Automatic track | Five thresholds per tree, current progress, granted skill details, visibly unassigned slot, no invented grant | M4/M5; 8/9/10 and 11/12/13 investment cases |
| Rotation editor | Ten slots, duplicates, resulting skill details and conditional/cooldown rules, clear removed-entry notice; empty editing allowed but fight/lock blocked | T7/M4; unavailable/overflow and alternate-grant cases |
| Temporary player effects | Name/icon, source, stacks or charges, magnitude, remaining time, active/ready/cooling state as appropriate | M3 events, M4 prototype, M7 finish; no color-only distinction |
| Enemy status | Actual poison/shred/Decay count, cap, consumed/applied changes, selective protection and relevant effective mitigation | M3 state, M4 playback; consume/cleanse/overflow cases |
| Recap/debug | Damage by source, actual consumption, eligible/proc/repeat counts, uptime, starvation, cap waste and gold changes | M3 producer, M4 consumer; reconcile against resolver totals |

M4 must inspect these cases at the project's supported minimum window and normal
play size, recording actual dimensions and screenshots:

1. Core and extension: select, allocate, read tooltips, arrange macro, lock, fight,
   replay, refund between contracts, and save/reopen; repeat with Practice setup.
2. Dense Bladedancer+Shadow tree view: both complete authored node sets (13+11),
   long descriptions, prerequisite lines, locked rows and all automatic slots.
   Use the 24/21 model fixture for layout before effects are playable; clearly
   label fixture-fed views and do not claim gameplay completion from them.
3. Ten rotation entries, repeated skills, long conditional tooltip and missing-
   skill notices: no clipping, unreachable controls or ambiguous ready states.
4. Busy temporary effects: test 0/1/6/10 simultaneous synthetic effect records with
   mixed timers/charges, including the same icon on distinct sources. Overflow must
   expose every hidden name/count/timer through an accessible list; this is a UI
   stress count, not a proposed gameplay mechanic cap.
5. Pause/seek/replay at a refresh/consume/expiry tie. Display derives from recorded
   simulation time; changing playback speed never changes effects or RNG results.

M4 inventories all 44 talents, four intrinsics, 20 skill identities and every named
buff/debuff plus locked/unassigned states. Document deliberate reuse, placeholder
status, target display sizes and cue priority. M7 produces and verifies final art
at actual sizes, including overflow and contrast. Asset production is not part of
T5; Tree Lab icon validity alone is not visual approval.

## 6. Required state and event contract

The current resolver exposes CastEvent/TickEvent arrays; TickEvent lacks consumed
quantity and crit origin, and recap infers one consumed stack. Extend those APIs
or add a compatible event stream; choose the concrete representation in M3.
Do not force UI/recap to reverse-engineer new state from old damage totals.

| Data contract | Minimum payload/meaning | Producer → consumers |
| --- | --- | --- |
| Build snapshot | Revision, roles, budget/spend/unspent, rank map, gates, grants with all source IDs, resolved intrinsic contributions, legal-edit failure reason | T6/T7 → panels, save, Balance Lab |
| Event identity/order | Monotonic event sequence, simulation time, source content ID, parent/root cast ID, origin kind (macro/proc/random repeat/guaranteed repeat/natural tick/forced tick) | M3 → replay, recap, deterministic comparisons |
| Effect lifecycle | Stable effect instance/source IDs, applied/refreshed/consumed/expired/cleared reason, before/after stacks or charges, magnitude, expiration time and reset reason | C2 → effect HUD, uptime/cap-waste accounting |
| Scheduler state | Requested slot/skill, ready/blocked reason, cooldown available-at time, actual start/end, interruption or consumption decision | C3 → rotation readiness, playback, no-progress diagnostics |
| Status transaction | Type, requested/applied/consumed/overflow amounts, before/after quantity and cap, source, conversion/cleanse reason | C4/C6 → enemy HUD, recap, stack conservation checks |
| Damage/crit/mitigation | Source/packet type, damage components, crit eligibility/outcome, prevented amounts, final contribution and applied conversion/penetration | C1/C4/C5/C6 → source totals, tooltips, recap |
| Trigger decision | Origin, eligible/ineligible reason, chance/roll already used when applicable, emitted child IDs, repeat/depth/event-limit outcome | C5 → proc counts, loop diagnosis, replay |
| Gold transaction | Stash and fight-stolen before/after, raw versus credited amount, reward/theft/spend source, capped derived contribution | C7 → economy scenarios and player explanation |

Observation must not draw new random values, reorder events, or alter simulation.
Trace detail may be optional for performance, but correctness-required state and
aggregate accounting are essential. Disabling diagnostics must preserve results.
Recap sums must reconcile with total damage/gold and use actual consumed counts.
Uptime uses simulation intervals clipped to fight duration, not frame count.
M3 defines event priorities and contract versions; M4 validates producer/consumer
agreement; M6 adds diagnostic measures to reports. Detailed charting is optional.

## 7. Validation plan and initial Balance Lab scenarios

### Foundation checks (T6/T7, combined in T8)

| Family | Required cases and expected outcome | Existing test anchors in `project/tests/` |
| --- | --- | --- |
| Ranks/gates | Each gate at N−1/N/N+1, rank 0/negative/fractional/max/over-max, ALL prerequisites, shared overspend; reject invalid edits atomically. Retained Quick Hands 4 + Hastened Poison 1 remains legal under T3. | `passive_allocator_test.gd`, `training_room_build_test.gd` |
| Roles/grants | Four zero-secondary cases, both orientations of six pairs, automatic thresholds before/at/after refund, alternate grant survives, empty slots do not block 12-point grant | `training_room_build_test.gd`, `rotation_cap_test.gd`, `build_panels_test.gd` |
| Rewards/respec | Tavern totals 1/1/5/10; contract totals 15/20/25/30/35/40/45; no elite point reward; cap crossing grants only remainder; repeat claim grants none; refund never increases earned budget. Reject in-contract respec, permit between-contract playtest edits, preserve roles. | `encounter_reward_test.gd`, `generated_contract_outcome_test.gd`, `generated_route_commit_flow_test.gd` |
| Persistence | Every T4-C/S/R/P case, including full old-run reset, repeat reload, failure reporting and unknown future data; model-only complete registry in tests | `save_load_test.gd`, `save_load_ui_test.gd`, `generated_contract_save_load_test.gd` |
| Practice isolation | Budgets 0/10/45, custom gear/target/seed/roles persist; no combat-state leakage, no Adventure mutation, invalid edits and role resets follow T4 | `training_room_entry_test.gd`, `training_room_build_test.gd`, `training_room_fight_setup_test.gd` |

Add focused Phase 6 tests when the runtime changes. Do not rewrite all inherited
tests merely to make old binary assumptions pass; preserve legacy behavior fixtures
where still meaningful and migrate player-facing expectations explicitly.

### Shared mechanics checks (M3/M5)

| Package | Deterministic boundary/conflict cases | Existing anchors |
| --- | --- | --- |
| C1/C7 | T3 Shadow Mastery +10 flat/+150% example; Gilded at 499/500/501 and 10000; fight-local counter reset while stash persists; gear/temporary source changes and capped excess | `p5m3_stat_sheet_aggregation_test.gd`, `thief_subclass_test.gd`, `p5m11_economy_stats_test.gd` |
| C2/C3 | Apply/refresh/expire/consume ties; charge zero; conditional slot never eligible; all slots cooling; repeated same skill; interruption before/after consumption; no zero-time loops | `hold_skill_test.gd`, `combat_playback_test.gd`, `training_room_fight_test.gd` |
| C4 | 0/1/2/3 stacks, residual after multi-consumption, forced/natural simultaneous ticks, cadence change during an interval, crit/no-crit and charge exhaustion | `engine_mechanics_test.gd`, `p5m4_crit_applies_poison_test.gd`, `combat_recap_test.gd` |
| C5 | Forced deterministic success/failure branches, proc-origin filters, guaranteed single/multiple repeats per approved rule, Death Blade suppression, bounded branching, same-seed trace equality | `opportunity_strikes_test.gd`, `p5m4_retrigger_semantics_test.gd`, `deterministic_replay_test.gd` |
| C6 | Decay consume at zero/base-zero-resistance, partial removal, cleanse immunity scope, Bonus Stacks once, status overflow, physical/magical conversion and defense denial combinations | `p5m4_shred_stack_mechanics_test.gd`, `p5m4_death_strike_stack_order_test.gd`, `p5m4_conversion_ignore_hooks_test.gd`, `enemy_defense_mechanics_test.gd` |

Expected gameplay quantities for unresolved cases must be filled into the M3/M5
specification before implementation/tests. T5 defines the cases and invariant
expectations, not invented formulas. Random sampling cannot replace branch tests.

### Scenario execution contract

The current `project/scripts/tools/balance_lab.gd` loads binary talent resource
paths in `_run_scenario`; it cannot run the new rank fixtures unchanged. T7 adds
an adapter for role/rank snapshots and readiness checks. M3/M5 add approved effect
execution; M6 owns measured targets. The JSON here is not the lab's import schema.

For initial diagnostics, use the same `res://data/gear/crude_dagger.tres` on every
candidate, no other gear, default gold 0, fixed duration 30000 ms, seeds 1–20.
Store exact content/build/gear/monster snapshots and revisions with the report.
Use high-HP target 1000000, all defenses zero unless the scenario sets them.
These targets measure behavior/DPS, not win-rate balance. After correctness passes,
use seeds 1–200 for reports without changing fixtures between tree comparisons.
M6 later chooses low/typical/strong generated gear snapshots at matched progression
stages; this initial dagger is a fixed comparison fixture, not a claim of typical gear.

| Scenario ID | Build / target variation | Evidence sought / owner |
| --- | --- | --- |
| `p6_m4_footwork` | Core; blank, armor 100 + block 5, then slow 0.5 + interrupt_skip_count 1 | Gain/consume/expire, Parry availability, finite macro progress; M3/M4 |
| `p6_m4_mixed` | Extension; blank and crit_negation 1; initial gold 0/100; duplicate Dance slot variant within ten slots | Shared cooldown behavior, no proc explosion, primary-only scaling and Thief sources; M3/M4 |
| `p6_poison_supply` | Forced-tick 10, Assassin 30/35; blank then poison_resistance 0.5 + absorb 5 | Fuel starvation, actual consumption, charge use, critical/forced source totals; M3/M5 |
| `p6_shadow_consume` | Shadow 25/35; resistance 0/0.5; separate cleanse_threshold 3 | Decay conservation/restoration, conversion and temporary state; M3/M5 |
| `p6_thief_caps` | Thief 10/21/35; blank/crit_negation 1; gold 0/100/499/500/501/10000 | Stash cap, theft ramp, no-theft case, derived-stat saturation; M3/M5; spending/rewards M6 |
| `p6_mixed_depth` | All 36 mature pair fixtures, same gear/seed/target cohorts; mechanic-specific rotations finalized by M5 | Roles, opportunity costs, depth versus breadth; no universal win-rate pass band; M5/M6 |
| `p6_progression` | Actual budget sequence 0/1/5/10/15/20/25/30/35/40/45; matched gear/enemy stages chosen in M6 | Point delivery, time to mature build, full Adventure challenge; T8 state/M6 gameplay |
| `p6_watchmen` | Existing Cloaked Watchmen resource, 26000 ms, gold 67, Wyvern Kriss as inherited control; redesigned Shadow/Bladedancer 24/21 and reversed-role counterpart | Revisit `bladedancer_contract_watchmen` explicitly; preserve old report separately and label changed builds; M6 |

Do not carry the inherited Watchmen 0.30–0.95 band forward as an approved Phase 6
target. Preserve its historical baseline/watch finding and measure the new builds.
Numerical win-rate/DPS bands require M6 decisions. Correctness failures remain hard
failures; unavailable content is reported as not ready, never as a passing scenario.

### Commands and evidence handling

T5 checks, run from this repository root:

```powershell
node tools/p6/audit_tree_drafts.js
node tools/p6/check_content_identity_manifest.js
node tools/p6/check_build_fixtures.js
git diff --check
```

For later runtime checks, use this project's paths (the Balance Lab README still
contains historical sibling-project examples). The inspected suite uses standalone
SceneTree test scripts; no GdUnit addon is required by these tests. Example:

```powershell
$godotExe = 'F:\Applications\Godot\Godot_v4.7-stable_win64_console.exe'
$projectDir = 'F:\Data\Claude Projects\Project-FacelessVoid\project'
$testLog = 'F:\Data\Claude Projects\Project-FacelessVoid\project\reports\p6_passive_allocator.log'
& $godotExe --headless --path $projectDir --log-file $testLog -s res://tests/passive_allocator_test.gd
```

Use isolated test save paths and absolute log paths. Record command, exit status,
assertions and report status, not just “Godot ran.” `run_balance_suite.gd` currently
exits zero after writing a report even when scenario checks may fail: inspect
`results.json` status/fail counts too. Archive the inherited report before running
a new suite that writes `reports/balance/latest`; do not compare overwritten data.
Run affected focused tests first, then integration and inherited gear/route checks
appropriate to the changed surface. Repeat broader suites only for new failures,
changes or remaining concerns. T5 itself runs no gameplay suite or balance tuning.

## 8. Completion and downstream acceptance

- T6 can start with rank/role state, legality and reward rules without waiting for
  all combat formulas; it cannot pretend unresolved effects are implemented.
- T7 has the complete T4 contract and named Balance Lab/Practice adapters; content
  readiness and explicit reset outcomes are required before player activation.
- T8/T9 close foundation work with reproducible evidence and unresolved combat
  items assigned, not hidden. M4 cannot close on headless model tests alone.
- M3/M5 review the named first-slice mechanics with the user before implementation.
  M4 core and extension must work end to end, including unlocked skill readiness,
  dense layouts and busy playback. Full four-tree completion remains M5.
- M6 sets measured enemy/progression targets; M7 completes assets; M8/M9 own
  integrated playtest and final regression. T5 does not claim those outcomes.

Verification on 2026-09-22: all 121 planning fixtures pass the independent draft
legality/availability checker, including 36 mature mixed cases. Original draft
hashes and T4 identity checks pass. Links, whitespace and active tracker status
were checked. No runtime resource, source draft, real save, art or balance report
was modified. These results establish planning consistency only.
