# P6M3-T2 Combat Ordering and Diagnostic Foundations

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

Date: 2026-09-23. Owner: [M3 tracker](P6M3_Shared_Combat_Mechanics_Tracker.md).
Status: **Complete — tested ordering/event contract and diagnostic foundations.**
Next: P6M3-T3 — Stat derivation and temporary modifiers.

## Approved decisions

The user approved both T2 proposals on 2026-09-23:

- **P6M3-D005:** Allow at most **1,024 trigger-candidate evaluations per macro
  cast**, shared across all descendants, including filtered candidates. Before
  evaluating candidate 1,025, stop the simulation, mark it invalid, and report
  its cause. Preserve the inherited depth-16 guard.
- **P6M3-D006:** Preserve natural-poison-before-hit ties and depth-first trigger
  execution. Finish a cast's trigger subtree before applying its new player
  buffs, then start the next macro cast. Preserve T1's inclusive Plunge
  consumption deadline and Quick Cut's replacement of expired stacks.

These decisions do not promote redesigned content. The playable registry remains
`p6.compat.1`. T3–T7 own the actual redesigned stat, effect, scheduler and trigger
implementations; this task supplies their shared contract and diagnostic base.

## Resolver audit

`CombatResolver.resolve()` is a synchronous, integer-millisecond, fixed-window
simulation with one looping player macro. The monster supplies defensive hooks;
there is no independently scheduled enemy attack actor to order against it.

The inherited order is:

1. Choose the next macro slot and roll its minimum-cast-time proc if applicable.
   Casts finishing beyond the window are omitted; preserve the existing RNG draw
   even for that final omitted cast.
2. Resolve all cadence ticks through the cast's completion time, inclusive.
3. Check interruption, then dodge; connected skill effects resolve using the
   existing damage/crit/weapon RNG and resource order. Damage precedes accumulated
   Decay/Shred application. Crit-poison, gear status hooks and cleanse retain
   their inherited positions. Zero damage from block is still a connected hit.
4. Finalize the cast, then visit trigger candidates in stored array order,
   followed by the synthetic gear/intrinsic random-repeat candidate.
5. Immediately resolve each successful child and its entire subtree before the
   next sibling. Source-filtered or missing-skill candidates draw no RNG;
   eligible candidates retain the existing chance roll, including chance 1.
6. Advance the macro, including inherited stun delay, and continue. Resolve
   remaining natural ticks through the window endpoint.

The old depth guard stops descendant expansion at depth 16 but does not bound
the number of siblings. It remains a suppression, not an invalid result. The
new shared root budget bounds breadth as well as depth.

T2 adds start/end observations and an explicit failure result. To emit starts
chronologically after stun, pending natural ticks through the next start time
are drained before recording that start. These ticks already ran before the
next hit and consume no RNG. The six compatibility signatures verify unchanged
cast/tick results. Existing playback and formatter tie ordering already agree
with natural ticks preceding simultaneous hits.

## Execution order contract

The authoritative order is **simulation time, then increasing event sequence**.
Sequence is assigned at execution, never reconstructed by sorting kind names,
resource hashes, object IDs or an unordered dictionary. A child cannot move
ahead of its causal parent just because both share a timestamp.

At a completion timestamp:

1. Resolve due natural ticks in cadence order, including a tick at that timestamp.
2. Resolve the completing cast's interruption/hit, damage, inherited status
   transactions and finalization. A Rending Slash hit cannot benefit from its
   own newly applied Shred.
3. Visit trigger candidates in their stable array order. For each successful
   child: start it, resolve its effects, recursively process its children, then
   perform its end-of-cast player-buff step. Only then visit the next sibling.
4. Perform the parent's end-of-cast player-buff step after its entire subtree.
   `cast_end` marks this handoff. It is emitted for interrupted casts too, but
   does not imply a hit or authorize a buff grant.
5. Start the next macro slot when its start time is reached. Cast-start checks
   and resource consumption precede windup. Stun can put that start later.

An empty trigger list does not produce a synthetic roll. Authored procs and the
synthetic random repeat remain separate origins, even when their chance is 1.
Guaranteed repeats and forced poison ticks are reserved origins; their actual
eligibility, cadence interactions and emission belong to T6/T9 review. They
must remain causal children within this sequence contract.

### Exact expiration boundaries

Expiration cannot be implemented as one unconditional global purge before
cast starts. T4/T5 must use the shared predicates in `combat_event_order.gd`:

- At cast-start consumption, an existing instance is available when
  `now_ms <= expires_at_ms`; strictly older instances are unavailable.
- Before a new grant/refresh, an existing instance is expired when
  `now_ms >= expires_at_ms`. Remove it, recording expiration, before applying
  the fresh grant. Increased grants still obey the approved cap.
- Clear any unconsumed deadline-equal instances after same-time consumption
  opportunities. An instance already removed by an earlier operation cannot
  be consumed again; stable effect-instance IDs distinguish a replacement.

Examples at 3,000 ms: Plunge starting with four Footwork stacks expiring at
3,000 consumes four. Quick Cut's final grant at that time first removes those
four old stacks, then creates a fresh grant. A following Plunge sees the new
instance. A Plunge at 3,001 cannot consume the old instance. These predicates
are tested; the actual Footwork lifecycle remains T4/T5 work.

Readiness granted by a repeated hit arrives after that hit's descendant
decisions. It cannot retroactively satisfy its own Parrying Strike repeat or
a cast that already started without Readiness. T5/T6 must retain cast-start
eligibility snapshots and apply grants only to qualifying connected hits.

## Version 1 event envelope

Opt in with the sixth argument to `CombatResolver.resolve(..., seed, true)`.
Existing callers keep their five-argument API and legacy cast/tick arrays.

| Field | Meaning |
| --- | --- |
| `schema_version` | 1; consumers must check before interpreting payloads. |
| `sequence` | Fight-local, strictly increasing, starts at 1; retained in counters with detail disabled. |
| `time_ms` | Integer simulation time; nondecreasing, ties permitted. |
| `kind` | `cast_start`, `cast_resolved`, `cast_end`, `trigger_decision`, `poison_tick`, or `simulation_failed`; lifecycle producers extend this contract. |
| `source_id` | Stable skill content ID; natural aggregate poison uses `status.poison`. Never an object instance ID. |
| `cast_id` | Fight-local sequential cast identity; 0 for an unowned system/tick event. |
| `parent_cast_id` / `root_cast_id` | Immediate parent and owning macro cast; macro parent is 0, macro root is itself. |
| `origin_kind` | `macro`, `proc`, `random_repeat`, `natural_tick`, or `system` currently emitted; `guaranteed_repeat` and `forced_tick` reserved. |
| `effect_instance_id` | Empty when not applicable; T4 will allocate fight-local lifecycle identities. |
| `lifecycle_reason` | Empty when not applicable; natural poison uses `consumed` or `empty_tick`; future lifecycle producers use applied/refreshed/consumed/expired/cleared reasons. |
| `payload` | Deep-copied value data; no mutable gameplay-resource references in current trace payloads. |

`cast_start` includes macro index and intended end. `cast_resolved` reports
connected/dodged/interrupted, damage, gold, crit, block, status grants, cleanse
and existing weapon rolls. `cast_end` follows the subtree. Trigger decisions
report candidate index, reason, target skill, and the **already-used** roll and
chance where applicable; success includes the emitted child's ID/origin.
Depth suppression has its own reason. Poison records include actual consumed
quantity, remaining quantity, damage and absorption. Empty ticks consume zero.

`CastEvent` gains cast ancestry/origin and resolution sequence; `TickEvent`
gains sequence and `stacks_consumed`. Existing fields keep their meanings.
Current poison is still an aggregate stack pool; per-application provenance,
full status transaction payloads and detailed mitigation components remain
T7/T9 work. Trigger candidate index identifies the assembled source list;
granting talent/gear provenance must be added when those producers are extended.

## Bounded execution and invalid results

Budget accounting runs regardless of tracing. Every visited candidate, including
a missing skill or source-filter mismatch, consumes one unit. All children share
the macro's counter. Exactly 1,024 evaluations are valid; encountering one more
candidate fails **before** its eligibility checks or RNG roll. The next macro
starts with a fresh budget. Descendant branches cut by the inherited depth guard
are not visited and do not spend candidate units.

On breach:

- `is_valid = false`; `failure` stores code, time, source/cast/root IDs, candidate
  index, limit and completed evaluation count, even with tracing disabled.
- Emit one `simulation_failed` record when tracing is enabled, then unwind and
  stop. No later siblings, macro casts, trailing ticks or end/grant steps execute.
- Partial damage/gold remain for diagnosis; DPS/overkill are not scored and
  `is_win` remains false. **Callers must check validity before win/loss.**
- Adventure returns to planning and shows the error. It does not call
  `finish_fight`, record history, grant stolen gold, consume retries or autosave
  a fight outcome. Build locking remains unchanged and Tavern choice is restored.
- Practice displays the error without combat playback. Balance Lab fails the
  scenario, retaining the cause/seed and excluding partial samples from aggregates.

The 1,024 budget bounds candidate traversal, not diagnostic record count or
normal-build retrigger chance. It is not a new chance cap. Full trigger origin
filters and redesigned suppression behavior remain T6 work.

## Observation invariants and validation

The trace owns no RNG and no gameplay state. With detail off it stores no
records but preserves sequence/counters, cast identity and failure accounting.
`rng_final_state` allows direct on/off comparisons. Nested payload data is copied
at emission so later state changes cannot rewrite the trace.

New tests:

- `p6_combat_ordering_test.gd`: six pre-T2 compatibility signatures; exact
  same-seed traces; on/off outcome, final-RNG-state and counter equality;
  monotonic records across stun gaps; damage/gold reconciliation; agreement
  with playback; depth-first siblings/grandchildren and ancestry; post-subtree
  buff handoff; blocked versus dodged hits; exact/over-budget, root reset,
  filtered-candidate and shallow-branching cases; lifecycle boundary predicates
  and snapshot isolation; invalid-result state protection.
- `p6_combat_failure_consumers_test.gd`: real Adventure instant/animated calls,
  Practice handling and Balance Lab invalid-scenario behavior using isolated
  test-only gear with 1,025 candidates.

Signature fixture: `project/tests/fixtures/p6/t2_compatibility_signatures.json`.
The original resolver was unchanged from HEAD before T2. Initial hashes exposed
texture object IDs in inherited contribution data; normalized signatures were
captured from a separate copy of that original resolver, replacing resources
with their stable paths. Expected results were not regenerated from the new
implementation. The fixture helper covers weapon/crit/min-time/retrigger RNG,
poison, shred, decay, dodge/block, cleanse, interruption and stun.

Runner: `tools/p6/run_foundation_tests.py --report-name p6_m3_t2 ...`.
The new optional report name separates T2 evidence from retained T8 evidence.
Real FacelessVoid/Enigma save files and Enigma project/export files are
fingerprinted before and after the isolated runs.

## Downstream handoff

- **T3:** stat derivation and temporary modifiers; attach source-aware values.
- **T4:** real lifecycle instances, ordering-aware expiration/consumption,
  refresh/cleanup and detailed before/after effect events.
- **T5:** readiness snapshots, conditional scheduling, future cooldown ownership,
  and finite macro progress. Use cast-start and deadline semantics above.
- **T6:** route new trigger producers through the shared root budget and causal
  IDs; apply reviewed new player-buff grants after each cast's subtree.
- **T7/T9:** full status transactions, mitigation, poison provenance and cadence.
- **M4/M7:** consume the event contract for redesigned playback/effect UI and
  visually validate it. T2 headless checks do not establish rendered acceptance.

No redesigned skill resources, source drafts, registry release or real saves
were changed. Full Footwork/Readiness mechanics and their playable validation
remain downstream; the tested boundary helpers are not a claim of that work.

## Final validation evidence

On 2026-09-23, Godot 4.7 stable completed **21/21 scripts successfully**, with
no script errors or assertions. Exact command (PowerShell, repository root):

```powershell
python tools/p6/run_foundation_tests.py --report-name p6_m3_t2 p6_combat_ordering_test p6_combat_failure_consumers_test p5m4_retrigger_semantics_test deterministic_replay_test combat_playback_test combat_recap_test combat_test engine_mechanics_test enemy_defense_mechanics_test p5m4_shred_stack_mechanics_test p5m4_deterministic_weapon_rolls_test p5m4_crit_applies_poison_test p5m10_legendary_combat_effects_test p5m11_overkill_gold_test p5m11_economy_stats_test opportunity_strikes_test hold_skill_test p6_foundation_integration_test p6_balance_adapter_test combat_screen_test training_room_fight_test
```

Generated evidence: `project/reports/p6_m3_t2/summary.json`, per-test logs and
`isolation.json` (`unchanged: true`). Normalized compatibility signatures are
checked in with the tests; generated logs are ignored. The inherited headless
certificate-store and shutdown-resource diagnostics remain nonblocking.
No rendered playtest or redesigned mechanic acceptance is claimed.
