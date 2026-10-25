# P6M3-T1 Bladedancer First-Slice Specification

Date: 2026-09-23. Status: **Complete — first-slice design specification.**

Owner: [M3 tracker](P6M3_Shared_Combat_Mechanics_Tracker.md). This records design
decisions, not implemented behavior or runtime acceptance. T1 is Complete;
T2 combat ordering and diagnostic foundations is next.
Full Bladedancer review was discussed as an option; it has not replaced the
tracked first-slice scope. M2 allocation, roles and progression remain settled.

## Confirmed decisions

### Stats and skill values

Retrigger chance from the intrinsic adds directly to gear retrigger chance.
Whetstone's base physical damage adds to base damage in the same manner as gear.
The draft inputs remain 5% base retrigger plus 0.2 percentage points per primary
tree point and +1 base physical damage per Whetstone rank; the user confirmed
their additive treatment while answering the first-slice review.

| Skill | Damage percentage | Base attack time | Minimum attack time | Authority |
| --- | --- | --- | --- | --- |
| Quick Cut | 66% | 0.85 s | 0.50 s | User requested current values; inspected resource and resolver scaling table. |
| Rending Slash | 78% | 1.40 s | 0.65 s | User requested current values; inspected resource and resolver scaling table. |
| Parrying Strike | 120% | 0.50 s | 0.30 s | User supplied values. Draft calls this Parry Strike; stable identity mapping is unchanged by this document. |
| Leaping Plunge | 190% | 2.50 s | 0.50 s | User supplied values. |

Current-value evidence: `project/data/skills/quick_cut.tres`,
`project/data/skills/rending_slash.tres`, and
`CombatResolver.WEAPON_SCALING_BY_SKILL_ID`. The resource fallback physical amounts
12/14 are not the weapon damage percentages. No resource has been edited.

### Fancy Footwork

- A successful Quick Cut hit grants one base Footwork stack. Retriggered Quick
  Cut hits also grant stacks. Increased-stack talents and gear increase the grant.
- Each grant increases the stack count and resets the shared timer to three
  seconds on the fight clock. Expiration removes the entire buff and all stacks.
- The hard cap is five stacks. Increased-stack bonuses increase stacks granted,
  not this cap. Only explicit cap-changing effects can change a hard cap; no new
  such effect is approved here. A qualifying hit at cap refreshes the timer.
- Example: a hit at 1.0 s grants a stack with expiry 4.0 s. Another at 2.0 s
  increases the count and moves expiry to 5.0 s. If unused and not refreshed,
  all stacks expire then, subject to the confirmed cast-start ordering below.

### Leaping Plunge consumption

- At cast start, inspect Footwork and consume all available stacks.
- Apply the special attack-time reduction after other gear/talent speed bonuses.
  Stack reductions add together within this separate multiplicative reduction.
- Fancy Footwork ranks 1–5 give 2/4/6/8/10% reduction per consumed stack.
  The draft's 10/20/30/40/50% values describe the total at five stacks,
  not the per-stack reduction. This clarification governs eventual conversion
  and tooltip wording; the source draft is unchanged by this specification.
- For rank `r`, consumed stacks `n`, and attack time `T` after ordinary bonuses:
  `final_seconds = max(0.50, T * (1 - 0.02 * r * n))`.
  The special reduction cannot bypass Plunge's minimum attack time.
- Consumed stacks are lost even if the attack is dodged or interrupted.

### Readiness and Parrying Strike

- Readiness has no timer, persists for the fight, caps at one and resets after combat.
- A retrigger of any skill that hits grants Readiness. A dodged repeat does not.
- Parrying Strike requires and consumes a Readiness stack to execute from the macro.
- When its macro slot is reached without Readiness, its cast time is spent but
  it produces no skill effect, similarly to an interrupted skill. It is not skipped.
- Resource availability is checked at cast start. A cast started without its
  required resource remains ineffective even if that resource is gained during
  its windup; it cannot retroactively consume the newly gained resource.
- A retriggered Parrying Strike also needs an available Readiness stack.
- The user states this is unavailable in baseline behavior; possible future
  legendary effects could enable it. Such effects are not authorized content work.
- In general, cast-granted buffs apply at cast end after damage. Preserve the
  user's baseline no-self-enabling-repeat intent when specifying child-event order.
- T2/T6 must express ordering that preserves this no-self-enabling-repeat rule
  and the confirmed end-of-cast buff timing; do not grant Readiness early merely
  to enable a baseline Parrying Strike repeat.

### Connected hits and damage prevention

- A connected hit counts even if block prevents 100% of its damage. It still
  qualifies for Footwork, Shred and (if retriggered) Readiness grants.
- Dodge prevents a qualifying hit. An interrupted cast that never hits cannot
  earn an on-hit benefit; this does not refund Plunge's start-consumed stacks.
- The user noted dodge is the current way a hit does not count, without making
  an exhaustive claim about every future prevention mechanic. Do not equate
  zero damage with a miss.

### Rending Slash

- Deals direct damage, then applies Shred; newly applied Shred does not improve
  the same hit's damage.
- Shred application requires a hit. Repeated hits also apply stacks.
- Base application is the existing/draft two stacks. Retain inherited Shred
  Bonus Stacks behavior, subject to the C6 once-only accounting checks.

## Acceptance examples specified so far

These are expected results for later tests, not executed validation.

| Case | Expected result |
| --- | --- |
| Rank 5, three Footwork stacks, ordinary Plunge time 2.0 s | Consume three at cast start; time is 1.4 s. |
| Rank 1, five stacks, ordinary time 2.0 s | 10% total reduction; time is 1.8 s. |
| Rank 5, five stacks, ordinary time 1.0 s | Time is 0.50 s. |
| Rank 5, five stacks, ordinary time 0.70 s | Calculated 0.35 s is floored to 0.50 s. |
| Zero Footwork stacks | No Footwork reduction; ordinary timing and minimum apply. |
| Four stacks, qualifying Quick Cut grants three | Count stops at five; increased grant does not raise the cap. |
| Quick Cut hit at 1.0 s, another at 2.0 s | Shared expiry moves from 4.0 s to 5.0 s. |
| Plunge consumes stacks, then is dodged/interrupted | Consumed stacks remain spent. |
| Fully blocked Quick Cut or retriggered Quick Cut | Footwork still granted; the retriggered hit also grants Readiness. |
| Dodged retriggered Quick Cut | Neither on-hit Footwork nor Readiness is granted. |
| Connected Rending Slash, including a fully blocked hit | Resolve damage first, then apply Shred; repeats do likewise. |
| Parrying Strike starts without Readiness, then Readiness arrives | Cast spends its time and does nothing; it does not consume the later resource. |
| Fight ends with unused Readiness | Readiness resets to zero. |
| Five Footwork stacks, Quick Cut hits before expiry | Count stays five; shared expiry resets to hit time plus three seconds. |
| Plunge starts on Footwork's expiration tick | Consume the existing stacks at cast start and apply their time reduction. |
| Quick Cut hits on Footwork's expiration tick | Old buff expires; the final on-hit buff step creates a new instance with one base stack and a fresh three-second timer. Previously approved increased-grant bonuses still apply; old stacks are not retained. |

## Confirmed expiration ordering and downstream handoff

The user confirmed refresh at cap and specified asymmetric same-tick behavior:
Plunge's cast-start consumption can use Footwork on its expiration tick, whereas
Quick Cut's final buff-application step happens after the old buff expires.
This supersedes the earlier proposal to expire Footwork before Plunge starts.
An existing buff must therefore not be globally removed before all cast-start
consumption on that tick. T2 must encode these phase relationships explicitly.
This rule concerns Plunge's cast start, not a damage hit finishing on that tick;
its stacks and time reduction have already been resolved when its cast began.

No first-slice review question remains pending. T2 owns the broader total event
order, event representation and safeguards while preserving these approved
outcomes. T3–T7 implement their respective contracts with focused tests; T8
verifies the complete core. Full tree review remains M5 unless brought forward.
Implementation details such as timestamp rounding must preserve the examples;
any newly discovered gameplay ambiguity must be raised before affected code.

T1 closeout evidence is the task plan, these user-approved rules and the specified
normal/boundary/conflicting cases. Document links and whitespace were checked.
No combat code, source draft, real save or registry release was changed; no
runtime tests or playable acceptance are claimed by this design closeout.

## Evidence and history

- **2026-09-23:** User confirmed refresh at cap, Plunge consumption on the expiry
  tick and Quick Cut creating a fresh buff after same-tick expiration. Updated
  acceptance cases and closed T1 as planning/specification; T2 is next.

- **2026-09-23:** User clarified additive per-stack reduction, rank strength as
  2/4/6/8/10% per stack, the minimum-time floor, successful-retrigger Readiness,
  fully blocked hit eligibility, fixed cap and cast-start resource checks.
  Recorded acceptance examples; refresh-at-cap and expiration ties remain pending.

- **2026-09-23:** Recorded the user's answers to review items 1–6 and inspected
  current Quick Cut/Rending Slash timings and weapon scaling. Item 7 requested
  concrete context. Documentation only; no implementation or runtime tests.
