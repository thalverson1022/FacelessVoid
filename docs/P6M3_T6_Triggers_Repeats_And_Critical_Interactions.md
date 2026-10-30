# P6M3-T6 Triggers, Repeats, and Critical Interactions

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

**Later T4 closeout:** [T4 is Complete under D023](P6M3_T4_Timed_Effects_And_Charges.md#final-t4-contracts--d023).
Earlier statements assigning remaining T4 review/implementation describe that
handoff's original checkpoint. Riposte, Bypass and Touch are now implemented;
Touch uses ordinary additive IAS with independent expiration. Existing T6/T7
contracts and their historical validation remain unchanged.

Date: 2026-09-24. Status: **Complete — shared trigger/repeat/crit contracts and opt-in implementation.**

Owner: [M3 tracker](P6M3_Shared_Combat_Mechanics_Tracker.md).
The user requested the T6 audit, review, implementation and validation workflow.
That request does not select answers to the unresolved gameplay alternatives.

## Initial source audit (before the implementation below)

- `triggered_skill_effect.gd` originally exposed target skill, chance and source
  skill IDs only. Both talents and gear reach the same resolver candidate list.
- `combat_resolver.gd::_triggers_for_source` appends the ordinary random self-repeat
  after authored triggers. Authored chance-one triggers remain `proc`; the appended
  candidate is `random_repeat`. Same-skill authored procs carry the legacy
  `RETRIGGER` label independently of their origin.
- `_resolve_retrigger_chain` checks the source skill before drawing a proc roll,
  traverses children depth first and shares the 1,024-candidate root budget.
  Filtered candidates count. Depth 16 suppresses descendants. Connected direct
  attacks recurse; dodges, interruptions and unavailable resources do not.
- Child casts keep zero windup, check resources and bypass macro cooldowns without
  restarting them. Player buffs are granted after the child subtree. Readiness
  currently uses the inherited `RETRIGGER` label; new guaranteed-repeat origins
  require explicit integration rather than relabeling every chance-one proc.
- `_apply_skill_effects` performs packet crit calculation and rolls the Shadow
  poison hook once after any direct packet crit. Ordinary poison and crit poison
  are accumulated on the cast. There is no general poison-application trigger or
  guaranteed-repeat grant system yet.
- `damage_calculator.gd` preserves the critical flag while applying enemy crit
  negation to physical mitigation. Negation reduces damage, not crit probability.
  Side Step must preserve or explicitly change that distinction after review.

## Implemented foundation

`TriggeredSkillEffect.source_origin_kinds` is an opt-in allowlist, intersected
with the existing skill filter. Empty preserves inherited behavior. A nonempty
list accepts only matching cast origins; unknown entries never match existing
origins. Rejections occur before RNG, still consume the root candidate budget,
and emit `origin_filtered` with the source origin, target and allowed origins.
No shipped resource enables a new policy. No guaranteed-repeat behavior is
inferred from a chance of one. Existing cooldown, buff and chain contracts remain.

## Approved clarification — 2026-09-24, P6M3-D010

- Precision: a Quick Cut hit grants one stack. Casting Stab or Heavy Strike
  with Precision consumes the buff and guarantees the initial attack's repeat.
  Subsequent repeats use ordinary retrigger chance. This is a skill-specific
  guarantee, not a stat-sheet modifier; Double Dip and other retrigger-stat
  consumers must not receive a bonus from it. The user's example is two casts
  of the initiating skill, followed by ordinary repeat behavior.
- Dance of Death: the same initial-cast guarantee applies to skills hard-cast
  from the macro, with no cast time for the second cast. Descendant retriggers
  do not inherit the Dance guarantee. The user explicitly said all macro skills;
  do not silently narrow that to direct attacks. Resource requirements and
  nonattack/self-activation boundaries still need reconciliation with T4/T5.
- Opportunity: preserve current behavior. Every eligible Quick Cut attack,
  including repeats, can proc Rending Slash. That Rending Slash is a cast that
  can retrigger normally, with inherited chain safeguards.
- Side Step: use normal critical-hit interactions, including enemy crit
  negation. The guarantee does not bypass mitigation.
- Death Blade: Stab cannot apply poison through any means, including Coated
  Weapons and the crit-applies-poison stat. This confirms suppression, not the
  still-unspecified granularity of Death Blade's poison-application proc roll.

These decisions supersede conflicting earlier proposals. In particular, the
old proposal of two extra guaranteed repeats when Precision and Dance overlap
has not been approved. Precision's guarantee belongs to the initial cast's
repeat decision, not an additional increase to the persistent random-repeat stat.
This is specification evidence, not implementation or new test evidence.

## Final repeat clarification — 2026-09-24, P6M3-D011

The user confirmed:

- Precision caps at one and persists until consumed. Heavy Strike means the
  existing Heavy Slash (`skill.heavy_slash`).
- Precision plus Dance supplies one automatic repeat, independent of buff order;
  Precision is still consumed when Dance also supplies the same guarantee.
- A repeat is an on-hit proc. Dodge prevents it regardless of chance. Full block
  remains a connected hit under T1. Interrupted and resource-blocked casts have
  no hit and cannot proc a repeat.
- Readiness is still required by repeated Parrying Strike. The macro consumes
  the charge earned by a preceding connected repeat; its guaranteed child is
  negated when it finds no Readiness and cannot grant Readiness itself.
- Dance uses a five-second window and twenty-second shared cooldown. T5 starts
  cooldown at accepted macro cast start; T2 grants the buff after cast completion.
- Death Blade rolls once per poison application that actually adds stacks, not
  once per stack. A capped application and a poison damage tick do not roll.

This supersedes the earlier proposal of two extra repeats under overlap.
The guarantee replaces the initial random-repeat decision, does not add a
second independent random roll there, and uses no chance RNG. Its child resumes
normal repeat rules. Neither guarantee modifies the retrigger stat or Double Dip.

## Readiness and revised origin/timing clarification — D013

Readiness is T1's one-stack, untimed, fight-local prerequisite for Parrying Strike.
A connected retrigger grants it, including full block; dodge does not. Parrying
Strike consumes it at start; absent Readiness spends cast time without effects.
Repeated Parrying Strike also checks the resource. Grants occur after the cast's
descendants, preserving the approved no-self-enabling-repeat behavior.

The user revoked D012: **any eligible Stab/Heavy Slash cast can consume existing
Precision**, including proc/repeat origins. Dance remains macro-only. A guarantee
is never inherited for free: a later cast must consume a newly available charge
or use its own macro-only Dance eligibility.

Quick Cut now grants Precision once on its connected hit, before dispatching
child triggers. This is an explicit exception to D006's post-subtree player-buff
timing. Thus Quick Cut -> crit-applied poison -> Death Blade Stab can consume
the freshly granted Precision and produce one guaranteed repeat. No second
Precision grant occurs at Quick Cut's end. Footwork and Readiness retain their
post-subtree timing and Parry retains its resource requirement.

The successful-hit rule governs Dance as well: activation without a hit cannot
proc a repeat. Future nonattack skill content requires its own hit/activation
contract in M5, rather than silently manufacturing connected hits.

## Earlier proposals — historical, superseded by D010–D013

Two grouped questions were submitted in the task:

1. Precision: connected Quick Cut of any origin grants one untimed charge, cap
   one; Stab/Heavy Slash spends it at start and gets one repeat if connected.
   Dance: five seconds, twenty-second cooldown, one repeat on each macro attack's
   first connected hit. Both together supply two repeats. Guaranteed repeats
   cannot earn guarantees but can roll ordinary repeats and Opportunity.
   Connected repeats grant Readiness; Opportunity accepts connected Quick Cut
   of any origin. These lifecycle details overlap the pending T4 review.
2. Side Step: 100% Parry crit chance with inherited enemy crit-damage negation.
   Shadow's intrinsic: critical direct hits of any origin qualify, one roll per
   cast. Death Blade: suppress all Stab poison, including crit/gear additions;
   one roll per poison application that adds stacks, not per stack; poison
   damage ticks do not qualify. Critical poison tick execution remains T9.

These historical proposals are not authority where they conflict with D010–D013.

## Implemented mechanics and downstream handoff

The shared lifecycle adapter defines opt-in Precision/Dance effects. Eligible
cast-start snapshots consume Precision and record all guarantee sources; the
resolver replaces its synthetic random-repeat candidate with one
`guaranteed_repeat`. Authored triggers retain their order, followed by Death
Blade application candidates and then the repeat candidate; each child's subtree
finishes before the next sibling. All candidates share T2's budget/depth rules.
Precision grants before children; other buffs retain their timing. Guarantees snapshot at accepted cast
start and survive buff expiry during windup; clipped/cooldown casts do not consume.

`side_step_enabled` overrides only Parry's effective crit chance; enemy mitigation
remains unchanged. `death_blade_enabled` suppresses Stab's skill/augmented and
crit poison. `death_blade_chance` enables per-application Stab proc candidates.
Poison source and cap accounting now distinguish skill versus critical-proc
applications; each records requested/applied/overflow before cleanse and child
execution. Successful earlier applications can trigger even if the same cast
subsequently cleanses the poison. Suppressed/capped applications do not draw
Death Blade RNG. Pure poison applications can trigger Stab; ticks cannot.

Shadow's inherited direct-hit crit-to-poison hook remains once per cast after
packet crit evaluation, across cast origins; T9 owns critical poison ticks.
Stab uses the existing resource; future authored augments/content remain M5.
No new talent rank values are selected by these shared opt-in inputs.

Diagnostics record guarantee sources, suppression, explicit child origin,
application provenance, chance/roll outcomes, resources and ancestry without
extra RNG. Legacy pre-cap poison totals remain unchanged for old consumers;
new application records supply actual quantities needed by T6/T7/T9.

T6's checklist is complete for these shared contracts. Content/build promotion,
ranked talent conversion, final skill resources and full tree definitions remain
M4/M5; critical poison execution remains T9. The below-100% normal-build random
retrigger watch remains M6; no 99% cap was introduced. Fixture chance-one inputs
exercise deterministic chains without changing legal-build balance rules.

`p6.compat.1` remains playable. Draft resources and content promotion are unchanged.
Headless checks do not establish UI clarity or playable redesigned content.

## Validation

Seven scripts pass on 2026-09-24 via:

```text
python tools/p6/run_foundation_tests.py --report-name p6_m3_t6 p6_trigger_origins_test opportunity_strikes_test p5m4_retrigger_semantics_test p5m4_crit_applies_poison_test deterministic_replay_test p6_effect_combat_test p6_cooldown_scheduler_test
```

`project/reports/p6_m3_t6/summary.json` records commands and results;
`isolation.json` confirms protected saves and Enigma files remained unchanged.
The new test covers macro/proc/random-repeat filtering, unchanged empty defaults,
no RNG draw on rejection, filtered-candidate budget exhaustion, ancestry and replay.
It also runs the inherited T2 ordering suite, including pre-T2 compatibility
signatures and trace equality. The first attempt did not start the inherited
initializer through the isolation wrapper and was interrupted; an explicit
initializer fixed the harness integration before the successful run.

### D010/D011 implementation evidence

Eighteen scripts pass in `project/reports/p6_m3_t6_complete/summary.json`:

```text
python tools/p6/run_foundation_tests.py --report-name p6_m3_t6_complete p6_repeat_contracts_test p6_trigger_origins_test p6_status_accounting_test p6_effect_lifecycle_test p6_effect_combat_test p6_cooldown_scheduler_test p6_macro_scheduler_test p6_stat_derivation_test p6_stat_sources_test opportunity_strikes_test p5m4_retrigger_semantics_test p5m4_crit_applies_poison_test p5m4_shred_stack_mechanics_test p5m4_conversion_ignore_hooks_test enemy_defense_mechanics_test deterministic_replay_test combat_recap_test p6_combat_failure_consumers_test
```

Isolation confirms protected saves/Enigma unchanged. The new test verifies cap
one, Precision/Dance overlap, consumed-on-dodge, no Double Dip inflation, child
origins/zero windup, normal repeat chains, Readiness negation, Opportunity from
both macro and guaranteed Quick Cut, crit negation, all-source Stab suppression,
per-application poison/cap roll behavior, seeded success/failure, independent
ticks, Dance cooldown/expiry, invalid definitions, budget cleanup and trace/RNG
parity. It also runs the inherited T2 ordering/compatibility tests. An initial
test-only call to a nonexistent `current()` accessor was fixed to `snapshot()`
before this passing run. No runtime failure was masked by that correction.

After D012, `p6_repeat_contracts_test` passed again in
`project/reports/p6_m3_t6_final/summary.json`, including proc-origin Stab retaining
Precision and reversed buff-acquisition order. Final isolation checks also pass.
The 18-script suite plus this final added coverage establish T6 completion; no
rendered acceptance, playable redesigned release or broader T4/T7 completion is
claimed.

### D013 correction and current evidence

D012's macro-only Precision policy and its retaining-charge test are superseded.
Ten scripts pass in `project/reports/p6_m3_t6_precision_revision/summary.json`:
repeat contracts, origins, lifecycle, combat effects, cooldown scheduling,
ordering, status accounting, crit poison, inherited retriggers and replay.
The report records exact commands; isolation confirms unchanged protected files.
Updated tests cover the user's same-hit chain, grant-before-child sequence,
single consumption, no end-of-cast regrant, normal subsequent casts and trace/RNG
parity. A final added two-application case verifies that only the first Death
Blade Stab consumes the one Precision charge; evidence is in
`p6_m3_t6_precision_revision_final/summary.json`. T6 remains Complete with D013.
