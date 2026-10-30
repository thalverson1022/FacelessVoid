# P6M3-T5 Conditional Skills and Macro Scheduling

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

**Later T4 closeout:** [T4 is Complete under D023](P6M3_T4_Timed_Effects_And_Charges.md#final-t4-contracts--d023).
Earlier statements assigning remaining T4 review/implementation describe that
handoff's original checkpoint. Riposte, Bypass and Touch are now implemented;
Touch uses ordinary additive IAS with independent expiration. Existing T6/T7
contracts and their historical validation remain unchanged.

**T7 completion update:** The [T7 closeout](P6M3_T7_Status_And_Mitigation_Interactions.md#shared-mechanics-closeout)
now implements and validates D018–D021 shared rules, including independent buffs,
fixed multiplicative Virulent charges, live resistance ignore, Beguiling and
IAS-independent Self Buff timing. Later pending implementation statements below
are historical. Other T4 effect contracts and content promotion remain open.


**D018 design update:** See the [T7 approved contracts](P6M3_T7_Status_And_Mitigation_Interactions.md#further-approved-skill-contracts--d018).
Self Buff cast times ignore increased attack speed. Master of Poisons, Virulent
Poison and Beguiling Presence each cast in 500 ms; cooldowns are 10/5/30 seconds.
Master uses live zero resistance for five seconds; Virulent grants five double-damage
Poison-tick charges; Beguiling grants independent ten-second instances from actual
Decay consumed, with no extra-stack amplification. These later approvals supersede
conflicting proposals; D019/D020 settle Virulent boundaries, and T7 records implementation and validation.



**2026-09-24 D017 update:** The later [T7 handoff](P6M3_T7_Status_And_Mitigation_Interactions.md)
supersedes pending statements below about categories, Blinding Powder and Death Pact.
Their shared rules are now implemented: debuffs/self buffs cannot dodge or change
cleanse/interrupt counters; Powder has no cooldown; Pact adds one second per rank
to universal timed Penetration/Potency. Only explicit Consume triggers Pact;
ordinary depletion, forced ticks and cleanse do not. Named content promotion and
other per-effect contracts remain with their existing owners.

Date: 2026-09-24. Status: **Complete - shared scheduling and approved core contracts.**

Owner: [M3 tracker](P6M3_Shared_Combat_Mechanics_Tracker.md).
Dependencies: [T1 approved contracts](P6M3_T1_Bladedancer_First_Slice_Specification.md),
[T4 lifecycle implementation](P6M3_T4_Timed_Effects_And_Charges.md), T2 ordering
and T3 cast-start snapshots. The user authorized T5 implementation. The user confirmed shared cooldown rules and specified that a cooling-down slot
spends 100 ms without effects, then advances. Poison and buff timers continue
independently. Earlier T4 per-effect questions remain open and are not implied
approved by this scheduling decision (P6M3-D009).

## Implemented

`project/scripts/systems/combat_macro_scheduler.gd` supplies shared, pure cast
planning. It records the ordinary execution time, final execution time, source,
requested start/end, attack speed, slow, minimum-time proc and whether the cast
fits inside the simulation window. It never draws RNG, consumes resources or
changes source resources. The resolver retains ownership of the existing proc
roll and passes its result to the planner, preserving inherited RNG ordering.

The planner delegates to existing timing and the approved Footwork preview:
ordinary speed and slow first, then Footwork's per-stack reduction and minimum.
Accepted casts use T4's cast-start consumption. Clipped casts never consume
resources. Later state changes cannot alter the captured windup or enable an
unready cast retroactively. Child casts retain zero windup and their resource
checks; repeats bypass and do not restart macro cooldowns. New proc-origin eligibility remains T6.

A pre-existing finite-progress bug is fixed: the legendary minimum-cast proc
previously used `skill.min_execution_ms` directly. A zero minimum could make the
macro loop run indefinitely. Both ordinary and minimum-proc macro planning now
respect the existing 1 ms floor. This does not add windup to triggered children.

Missing skill slots and nonpositive simulation windows return a structured
`invalid_macro_schedule` result before simulation. Empty macros retain their
existing valid, empty-result behavior for positive windows.

All shipped skills use the shared planner. The approved core's damage table now
includes `skill.parry_strike` at 120% and `skill.leaping_plunge` at 190%, alongside
the existing Quick Cut 66%. These are T1-approved values, not a balance revision.
Redesigned resources and build activation remain downstream content work.

## Diagnostics

`schedule_decision` records accompany macro and child cast starts with slot,
eligibility decision/reason, actual start/end, ordinary/final execution times
and the lifecycle consumption snapshot. Missing Readiness reports
`spend_time_without_effect` / `missing_readiness`. The cast still spends its
approved time and advances to the next slot. Existing interruption diagnostics
remain authoritative for interrupted/skipped attack effects.

The final clipped plan is reported as `window_exhausted` at the window's end,
after remaining poison beats and lifecycle cleanup. Its requested start and
planned end remain in the payload, even when a stun extends beyond the window.
This prevents a future scheduling timestamp from preceding earlier poison
events in the trace. Trace-on/off behavior and inherited compatibility
signatures remain unchanged.

## Approved cooldown contract (2026-09-24)

- `Skill.cooldown_ms` defaults to zero for compatibility. Eligible macro casts
  start cooldowns at cast start, shared by stable skill ID across duplicate slots.
- Dodge and interruption do not refund cooldowns. Missing Readiness does not
  start one. Triggered children bypass and do not restart the macro cooldown,
  but retain their required-resource checks.
- A skill still cooling down at slot entry occupies exactly 100 ms, then the
  macro advances. It does no damage, consumes no charges, grants no effects,
  draws no attack/proc RNG and does not update interrupt/cleanse attack counters.
- Speed, slow, minimum-cast procs and Footwork cannot change this 100 ms duration.
  Becoming ready during that attempt does not retroactively execute the skill.
  At an exact cooldown deadline, the next slot entry is eligible.
- All-cooling macros continue cycling; there is no jump to the next cooldown or
  immediate zero-time skip. Poison beats and effect deadlines keep advancing.
- Cooldowns reset on normal completion and invalidation. Each resolution/retry
  owns a new scheduler. Clipped casts do not start cooldowns or spend resources.
- Negative durations, missing IDs for positive cooldowns and conflicting
  cooldown durations for one macro skill ID are rejected as invalid schedules.

Cast events expose `cooldown_blocked` and the available-at deadline. Schedule
records report `cooldown_skip` / `cooldown`, actual 100 ms duration and whether
child execution bypasses the macro cooldown. The text log labels the empty
cooldown attempt explicitly. Defaults preserve the shipped resource behavior.

This supersedes the earlier instant-skip/earliest-deadline-wait proposal. It does
not set any still-unapproved content-specific cooldown duration, buff duration
or guaranteed-repeat meaning in T4's draft effects.

## Evidence and remaining scope

Subsequent T7 decision D016 introduces Attack/Debuff/Self Buff categories.
Blinding Powder, Pick Pocket and Poison Vile must not advance cleanse/interrupt
counters; Blinding Powder's timing is 1,000 ms base/500 ms minimum. Full category
and interrupt-streak semantics require T7 reconciliation; earlier T5 completion
does not claim this later category model was implemented.

All 18 scripts in `project/reports/p6_m3_t5/summary.json` pass on 2026-09-24.
The isolation report confirms protected saves and original Enigma files are
unchanged. T2's pre-change combat signatures still match.

`p6_cooldown_scheduler_test.gd` verifies shared duplicate-slot ownership, all-cooling
cycling, exact/mid-attempt deadlines, speed/slow/proc immunity, independent poison
and buff expiry, no cooldown-attempt RNG, trace parity, fresh retries, dodge,
interruption, repeat bypass, missing Readiness and invalid definitions.

`p6_macro_scheduler_test.gd` covers minimum-proc and ordinary zero-time progress,
duplicate unready Parry slots, immutable planning snapshots, window clipping,
inclusive Footwork expiry, speed/slow floors, all 12 shipped skill resources,
the approved core weapon percentages, stun-gap poison ordering, invalid inputs,
deterministic replay and trace/RNG parity. T4 tests separately retain actual
cast consumption, post-subtree grants, interruption and invalidation cleanup.

Run via `python tools/p6/run_foundation_tests.py --report-name p6_m3_t5` followed
by test basenames. The report's `summary.json` records the exact regression
commands/results; `isolation.json` checks real saves and original Enigma files.
This is headless evidence, not redesigned-content or visual acceptance.

The shared T5 scheduler is complete. Named effects depending on unanswered T4
contracts remain unimplemented and retain their T4/M5 review owners. T6
owns new guaranteed-repeat origins, T7 status accounting, T9 poison consumers,
and M4/M5 authored build/content promotion. No runtime registry promotion or
source-draft changes were made.
