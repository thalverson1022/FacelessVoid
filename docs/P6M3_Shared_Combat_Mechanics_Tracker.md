# P6M3 Shared Combat Mechanics Tracker

Current combat rules: [Combat Mechanics Reference](Combat_Mechanics_Reference.md). This living reference consolidates accepted rules and interaction exceptions; task handoffs retain historical decisions and validation evidence. Update the reference alongside every accepted mechanics change.

## Status

Last updated: 2026-09-24.

**P6M3 is Complete for shared-mechanics scope. T1–T11 are Complete.**
**Current: M4 playable integration and UI validation is next.** See [M3 closeout and M4 handoff](P6M3_T11_Closeout_And_M4_Handoff.md) for coverage, evidence and downstream content owners.
The task plan, first-slice specification, tested ordering/diagnostic foundations
and shared stat derivation/temporary-source foundations are complete. Reviewed T4–T7 shared mechanics are implemented within the scopes below; remaining mechanics and playable content integration retain their downstream owners.

The [Phase 6 milestone tracker](P6_Milestone_Tracker.md) remains the source of
truth for phase-wide status, scope and major decisions. This supporting tracker
records M3 tasks, acceptance checklists, evidence and downstream handoffs.
Start from the completed [M2 closeout and M3 handoff](P6M2_T9_Closeout_And_M3_Handoff.md)
and [T5 integration plan](P6M2_T5_Integration_And_Dependency_Plan.md).

## Goal and Scope

Specify and implement the shared combat systems required by the redesigned Rogue
trees, with precise execution rules, deterministic validation and observable state
for playback, UI and diagnostics. Extend the existing resolver and preserve the
audited gear, class-skill and generated-contract foundations.

M3 covers stat derivation, timed effects and charges, conditional macro scheduling,
poison execution, triggers/repeats/crit, status/mitigation interactions and
gold-based combat. Every implemented mechanic includes its event reporting and
focused tests. Resolve gameplay ambiguities with the user before affected code;
draft text and planning fixtures are not approved executable specifications.

Bring affected M5 content review forward to specify the first Bladedancer slice
and the mixed-tree extension. M4 owns end-to-end playable and visual acceptance;
M5 owns complete four-tree content and tooltips; M6 owns numerical balance targets
and enemy tuning; M7 owns finished icons and feedback. Keep Tree Lab separate.
Do not reopen settled M2 allocation, progression, roles, respec or save policies.

The playable registry remains `p6.compat.1`. Redesigned `p6.1` promotion requires
reviewed effects, complete references, deterministic evidence and M4 integration.
Test-only resources must not become released content or silently execute no-op effects.

## Task Overview

| Task | Status | Purpose / Expected Output |
| --- | --- | --- |
| P6M3-T1: Milestone planning and first-slice specification | Complete | Task plan, dependencies, user-approved core Bladedancer contracts and acceptance examples recorded. |
| P6M3-T2: Combat ordering and diagnostic foundations | Complete | Define total event order, source/cast relationships, versioned event records and observable chain-limit failures. |
| P6M3-T3: Stat derivation and temporary modifiers | Complete | Implement canonical units, stat buckets, live/snapshot evaluation and temporary-source aggregation. |
| P6M3-T4: Timed effects and charges | Complete — shared scope | D023 Riposte, Bypass, Touch and stack-grant integration implemented; 26 regression scripts plus final boundary coverage pass. |
| P6M3-T5: Conditional skills and macro scheduling | Complete | Implement eligibility, skip/wait/advance, cooldowns, duplicate slots and windup/interruption rules. |
| P6M3-T6: Triggers, repeats, and critical interactions | Complete | D010–D013 implemented; original 18-script regression plus ten-script D013 revision and final same-hit/application coverage pass. |
| P6M3-T7: Status and mitigation interactions | Complete — reviewed shared scope | Status/defense, independent buffs, extra stacks, forced-tick and theft hooks validated by 24 scripts plus boundary coverage; content promotion remains downstream. |
| P6M3-T8: Core Bladedancer validation and M4 handoff | Complete | Exact ranked core, seven skills, seven repeated twenty-seed scenarios and event handoff; 35 regression scripts plus final gear coverage pass. |
| P6M3-T9: Poison timing and consumption | Complete | Implement natural/forced ticks, cadence, consumption, provenance and critical poison behavior. |
| P6M3-T10: Gold-based combat and mixed-tree extension | Complete | Implement gold source/state math and validate Bladedancer 15 / Thief 5, role reversal and zero-secondary-investment cases. |
| P6M3-T11: Integrated regression and milestone closeout | Complete | Reconcile shared-system coverage, verify interactions and inherited behavior, and record downstream handoffs and limitations. |

### Dependencies and delivery sequence

T1 defines the first slice; T2 establishes ordering and diagnostic contracts.
T3–T7 deliver the reviewed dependencies for T8. Prioritize each task's core subset
so unrelated mature-tree mechanics do not delay M4. T8 may complete while broader
T3–T7 work remains In progress, provided every core dependency has evidence.
Record partial delivery explicitly; a core subset does not complete a full task.

T4 uses T2/T3; T5 uses the applicable T4 lifecycle rules; T6 uses T2/T4/T5.
T7 uses T3–T6 and T9 where poison/status conversion requires it. Implement the
Rending Slash subset before T8, then return to poison-dependent T7 cases after T9.
T9 uses the applicable T2–T6 foundations. T10 uses T3–T7 and brings any missing
Dance, Opportunity and Thief dependencies back to their shared-system owners.
T9 and T10 may proceed in dependency order rather than strict task-number order.
T11 requires all essential shared-system tasks and both handoffs to be reconciled.

Each implementation task includes mechanic review, agreed specifications,
implementation, event production and focused tests. No essential mechanic may be
silently omitted or reclassified as optional to close the milestone.

## Task Completion Checklists

### P6M3-T1 — Milestone planning and first-slice specification

Final specification: [Bladedancer first slice](P6M3_T1_Bladedancer_First_Slice_Specification.md).
User decisions on additive stats, skill values, Footwork, Plunge consumption,
Readiness and Rending Slash ordering are recorded. Footwork rank scaling,
arithmetic, minimum timing, blocked-hit eligibility and cast-start resource
checks are settled. Refresh-at-cap and expiration ties are also settled: Plunge
consumes at cast start on the expiry tick; Quick Cut applies a fresh buff after
same-tick expiration. T1 is Complete as planning/specification.

- [x] Record the user-requested eleven-task breakdown, scope and delivery sequence.
- [x] Define task outputs, dependencies and milestone exit criteria.
- [x] Map inherited C1–C7 packages and unresolved audit questions to M3 owners.
- [x] Link this tracker from phase tracking and onboarding.
- [x] Draft and review the Bladedancer intrinsic, Whetstone, Rending Slash,
  Fancy Footwork, Quick Cut, Leaping Plunge and Parry Strike contracts.
- [x] Resolve first-slice gameplay questions with normal, boundary and
  conflicting-effect examples; record remaining downstream questions explicitly.

Completion target: an actionable tracker and agreed first-slice specification.

Evidence (2026-09-23): eleven-task plan, linked first-slice specification,
user decisions D002–D004 and explicit acceptance examples. Current inherited skill
values verified from source; links and whitespace checked. No implementation,
runtime tests, playable acceptance or content release claimed.

### P6M3-T2 — Combat ordering and diagnostic foundations

- [x] Specify total ordering for simultaneous actions, ticks, effect changes,
  consumption, expiration and triggered children.
- [x] Define/version event records with monotonic sequence/time, stable source
  IDs, parent/root cast, origin kind, effect instance and lifecycle reason.
- [x] Specify bounded branching and observable event-limit failure behavior;
  do not invent an unapproved limit value or rely only on recursion depth.
- [x] Implement diagnostic foundations and test trace-on/off result equality,
  same-seed ordering and no extra RNG draws.

Completion target: a tested ordering/event contract extended alongside each mechanic.

Evidence (2026-09-23): [T2 contract, implementation and validation](P6M3_T2_Combat_Ordering_And_Diagnostics.md). User-approved D005/D006; 21 passing headless scripts, six normalized pre-T2 combat signatures, trace/RNG equality, and invalid-result consumer checks. Protected saves and Enigma files unchanged. Actual redesigned effects and visual acceptance remain downstream.

### P6M3-T3 — Stat derivation and temporary modifiers

[Approved specification, implementation and evidence](P6M3_T3_Stat_Derivation_And_Temporary_Modifiers.md).
D007/D008 settle formulas and timing. Core Bladedancer scalar requirements and
all five named shared formulas are implemented, with source tracking, temporary
updates and T2 diagnostic values. All 29 distinct regression scripts pass in
their final runs; protected saves and Enigma fingerprints are unchanged.

- [x] Review units, additive/multiplicative buckets, floors/caps, aggregation,
  copy order and live versus snapshot evaluation for affected effects.
- [x] Implement source-aware derivation and temporary modifier updates without
  mutating source resources or duplicating the existing build model.
- [x] Preserve confirmed Shadow Mastery semantics; review Double Dip, Sharpened
  Edge, Fast Hands and Fill Your Pockets where they require shared math.
- [x] Test gear/buff changes, copy behavior, boundaries and derived event values.

Completion target: consistent tested derivation for all required shared consumers;
core delivery and remaining mature-tree work are recorded separately.

### P6M3-T4 — Timed effects and charges

[Final contracts, implementation and closeout](P6M3_T4_Timed_Effects_And_Charges.md).
D023 resolves Riposte rank scaling, increased/doubled Footwork and Bypass grants,
and Touch's ordinary additive IAS. T6/T7 retain Precision, Dance, Death Pact,
Virulent, Master and Beguiling authority. All 26 scripts pass in
`p6_m3_t4_closeout_final`; three final boundary/regression scripts pass in
`p6_m3_t4_final_boundaries`. Protected saves and Enigma files are unchanged.

- [x] Specify activation, duration, caps, refresh/stack/replace and consumption.
- [x] Implement lifecycle handling, consume/expire ties and fight/retry cleanup.
- [x] Deliver Footwork, Riposte, Precision, Bypass, Dance, Death Pact and other
  reviewed temporary effects; reconcile T6/T7 implementations and evidence.
- [x] Emit before/after charges, magnitude, expiry and reset reasons; test zero
  fuel, boundary timestamps, independent instances and no between-fight leakage.

T4 is Complete for shared mechanics and opt-in descriptors. Ranked content
promotion and visual/playable acceptance remain M4/M5/M7; T8 core validation is complete.

### P6M3-T5 — Conditional skills and macro scheduling

[Implementation, approved rules and evidence](P6M3_T5_Conditional_Skills_And_Macro_Scheduling.md).
Shared cast planning, finite-progress protection, core weapon percentages and
cooldown scheduling are implemented under D009. Cooling-down slots spend 100 ms
without effects. Eighteen regression scripts pass; subsequent T4 contracts are complete under D023.

- [x] Review full Quick Cut, Leaping Plunge and Parry Strike contracts,
  including readiness windows and consumption's effect on windup.
- [x] Specify skip/wait/advance, cooldown ownership/start, duplicate-slot
  behavior, snapshots, interruption and consumption order.
- [x] Implement approved macro behavior and emit slot/readiness/cooldown,
  start/end and interruption records.
- [x] Test repeated slots, all slots blocked/cooling, finite progress, and
  every accessible skill's use of the shared scheduler contract.

Completion target: deterministic scheduling that preserves macro playback and
inherited class skills; full per-tree content completion remains M5.

### P6M3-T6 — Triggers, repeats, and critical interactions

[Approved contracts, implementation and validation](P6M3_T6_Triggers_Repeats_And_Critical_Interactions.md).
Opt-in origin filtering, Precision/Dance guarantees, Readiness checks, Side Step,
Death Blade application/suppression and inherited Shadow/Opportunity behavior
are verified under D010–D013. Eighteen original scripts and ten D013 revision scripts plus final coverage pass;
protected saves/Enigma remain unchanged. Playable content promotion remains M4/M5.

- [x] Define eligible origin types, guaranteed/random repeat distinction,
  first-hit meaning, crit negation, suppression and child ordering.
- [x] Implement approved source filters and T2 finite-chain safeguards.
- [x] Cover Opportunity, Precision, Side Step, Dance, Shadow intrinsic,
  Death Blade and poison/gear interactions as their shared rules are reviewed.
- [x] Test forced success/failure branches, branching limits, inherited gear
  procs and same-seed trace equality; emit eligibility/roll/suppression outcomes.

Completion target: traceable and bounded trigger execution. Retain the normal-build
below-100% random-retrigger watch without inventing a 99% cap.

### P6M3-T7 — Status and mitigation interactions

[Reviewed implementation, validation and remaining integrations](P6M3_T7_Status_And_Mitigation_Interactions.md).
The reviewed shared rules are implemented in opt-in descriptors and adapters.
All 24 scripts pass in `p6_m3_t7_completion_regression`, with additional
`p6_m3_t7_completion_boundaries` evidence. Protected files are unchanged.
Playable content remains downstream; T4 subsequently closed under D023; broader T9/T10 scope remains separately owned.

- [x] Specify authoritative Decay, partial restoration, selective cleanse,
  conversion order and defense-denial combinations.
- [x] Implement reviewed caps/overflow, once-only bonuses, explicit Consume,
  timed Penetration/Potency and Attack/Debuff/Self Buff counter behavior.
- [x] Deliver reviewed independent buffs, resistance ignore, extra-stack/cap
  adapters and forced-tick/theft hooks; assign broader T4/T9/T10 work explicitly.
  Rending Slash requirements for T8 are delivered.
- [x] Test zero resistance, partial consumption, immunity, conversion, caps,
  negative defenses, duration/refresh, cleanup, diagnostics and compatibility.

Completion target: tested status and mitigation contracts covering C6 requirements.
Do not derive live Decay solely from accumulated resistance reduction.

### P6M3-T8 — Core Bladedancer validation and M4 handoff

- [x] Assemble `m4_bladedancer_core`: Bladedancer primary, ten points,
  Whetstone 4 / Rending Slash 1 / Fancy Footwork 5, no secondary.
- [x] Verify Quick Cut / Quick Cut / Parry Strike / Leaping Plunge / Rending
  Slash and every other unlocked skill, including inherited class skills.
- [x] Verify intrinsic/rank effects, timing, charge changes, source filters,
  gear interactions and event consumption through deterministic scenarios.
- [x] Supply reviewed resource/reference readiness, event examples, commands,
  results and known limitations to M4 without bypassing content-release gates.

Evidence: [T8 core validation and M4 handoff](P6M3_T8_Core_Bladedancer_Validation_And_M4_Handoff.md). The exact ranked core resolves its lifecycle inputs,
all seven skills execute, and seven twenty-seed scenarios reproduce. All 35
regression scripts and final expanded gear checks pass; protected saves and Enigma
files unchanged. The core's combat dependencies are ready for M4 integration.
No Dance dependency exists at ten points; the nine-point slot stays empty.
Headless evidence does not establish rendered UI clarity or playable acceptance.

### P6M3-T9 — Poison timing and consumption

The approved [T9 contract and validation](P6M3_T9_Poison_Timing_And_Consumption.md)
records D024: additive Hastened/Accelerant IAS scaling, preserved fractional
phase, actual stack-scaled damage with separate Echoing/Resonance multipliers,
and one live critical roll per fueled tick. Natural and forced ticks both
deplete stacks; neither is keyword Consume or triggers Death Pact. This
supersedes D015's no-depletion forced tick rule. Poison Strike is an Attack,
83% weapon damage, 1200/500 ms, no cooldown. All 36 regression scripts and five final checks pass; protected files are unchanged.

- [x] Review cadence/phase, interval changes, natural versus forced tick order,
  Accelerant/Resonance composition and affected Assassin skill contracts.
- [x] Implement multi-consumption, zero/remainder fuel, charge provenance and
  critical poison RNG under the approved origin and ordering rules.
- [x] Test 0/1/2/3 stacks, actual versus requested consumption, simultaneous
  ticks, cadence changes and affected C6 conversions.
- [x] Emit tick/consumption/crit data that reconciles with status and damage totals.

Completion target: deterministic poison execution with explicit boundary behavior.

### P6M3-T10 — Gold-based combat and mixed-tree extension

[Reviewed contracts, implementation and evidence](P6M3_T10_Gold_And_Mixed_Build_Handoff.md). D025 resolves the remaining skill details. All 42 regression scripts pass, with 17 repeated twenty-seed scenarios and actual Practice checks; protected files unchanged.

- [x] Review remaining theft, spending, rewards, dynamic gold-derived stats,
  retry/reset behavior and applicable Thief skills/passives.
- [x] Preserve Gilded Blade's 500 counted-stash-gold cap and the fight-local
  stolen counter; do not remove credited stash gold when that counter resets.
- [x] Implement source/state math and emit stash/stolen before/after,
  raw/credited amounts, source and capped stat contribution.
- [x] Review Dance, Opportunity, Cloak & Dagger, Keen Eye, Thief intrinsic,
  Steal and Mug; complete their shared dependencies in T3–T7.
- [x] Validate exact `m4_bladedancer_thief` fixtures, Bladedancer 15 / Thief 5,
  Practice role reversal and zero-secondary-investment cases.
- [x] Test gold 0/100/499/500/501/10000, no theft, reset/retry, reward separation
  and affected gear bonuses; provide the mixed-build handoff to M4.

Completion target: tested economy-combat contracts and mixed-build combat evidence.
Use the exact T5 allocations; this task does not authorize broad economy redesign.

### P6M3-T11 — Integrated regression and milestone closeout

- [x] Reconcile every C1–C7 requirement and task checklist against specifications
  and evidence; assign remaining content work explicitly to M5.
- [x] Verify shared-system combinations, deterministic replay, reset/cleanup,
  trace-on/off equality, recap reconciliation and clipped-time effect uptime.
- [x] Run appropriate inherited and M2 regression; fix defects and rerun affected checks.
- [x] Record commands, dates, results, reports, repository state and limitations;
  distinguish headless, rendered and playable evidence.
- [x] Update phase tracking/onboarding and hand off M4 integration, M5 content,
  M6 diagnostics/tuning and M7 presentation needs.

Completion target: a reproducible shared-combat baseline with explicit downstream owners.

## Milestone Exit Criteria

- [x] Required shared mechanics have reviewed contracts and executable implementations.
- [x] Timing, stacking, expiration, ordering, consumption and reset rules are tested.
- [x] Trigger origins, finite branching and deterministic replay are verified.
- [x] State/events support playback, UI and diagnostics without altering simulation.
- [x] Core and mixed integration candidates have complete combat dependency evidence.
- [x] Affected inherited skills, gear and M2 foundations pass regression.
- [x] Cross-tree coverage is reconciled without silent omissions or no-op content.
- [x] Limitations, downstream work and closeout evidence are recorded.

Closeout evidence: [M3 closeout and M4 handoff](P6M3_T11_Closeout_And_M4_Handoff.md). Full per-content authoring remains M5; visual/playable acceptance remains M4.

## Carried-Forward M2 Work

The T5 content-to-package map remains authoritative; this maps its owners into
the M3 task sequence rather than replacing its exact content inventory.

| Package / audit questions | M3 Owner | Later Completion Owner |
| --- | --- | --- |
| C1 derivation / Q04 | T3; T10 for gold consumers | M5 per-content definitions; M6 tuning |
| C2 lifecycle / Q07 | T4 | M5 remaining per-effect review; M4/M7 presentation |
| C3 macro scheduler / Q08–Q09 | T5 | M5 full skill content; M4 rotation/playback UI |
| C4 poison / Q05–Q06 | T9, with T6/T7 interactions | M5 Assassin/content completion |
| C5 triggers/repeats / Q10–Q11 | T2/T6 | M5 individual effects; M6 legal-build tuning |
| C6 statuses/mitigation / Q12–Q14 | T7, with T9 conversions | M5 individual effects |
| C7 economy combat / Q15 | T10, using T3 | M5 Thief completion; M6 economy-combat tuning |
| Q16 Heavy Strike alias / Death Pact unit | Settled in T6/T7: existing Heavy Slash; seconds per rank | M5 content binding |
| Q19–Q20 event/diagnostic execution | T2 and every implementation task; T8/T10 handoffs | M4 visual/playable acceptance; M7 finish |
| Q17 empty slots / Q18 difficulty targets | Preserve existing boundaries | M5 explicit additions only; M6 numerical targets |

Q01–Q03 and Q16's content/save-policy portion are settled by M2. Reuse RankedBuild,
BuildResolver, the registry/save codecs and the ranked Balance Lab adapter.
Preserve independent Adventure/Practice state and original Enigma files/saves.

## Decision Log

Keep phase-wide decisions in the main tracker's `P6-D...` log. Use stable
`P6M3-D...` IDs here; retain superseded entries with their replacements.
Entries retain their original decision context: D004 resolves D002/D003's
remaining boundaries; D013 supersedes D012 and the earlier Precision timing;
D017–D021 resolve D014–D016's pending boundaries. Use the current handoffs for
implementation status. D023 supersedes D022's partial Riposte and multiplicative Touch rules; T4 is complete.

| ID | Date | Status | Decision and Rationale | Affects |
| --- | --- | --- | --- | --- |
| P6M3-D025 | 2026-09-24 | Implemented and tested; T10 Complete | Steal retains 106%, 1300/650 ms; Mug 100%, 1500/700 ms with up to 100 credited fight-stolen gold as base damage; Pick Pocket Debuff zero damage, 1300/800 ms, steals 20 raw gold; Big Score 90%, 1800/700 ms doubles full crit multiplier only on crits. These four have no cooldown. Silvered uses credited theft at +1 percentage point/gold capped at 25/50/75 by rank. Dance casts in 500 ms; existing duration/cooldown retained. Thief base and primary gold bonuses add. | T10/M4/M5 |
| P6M3-D024 | 2026-09-24 | Implemented and tested; T9 Complete | Hastened/Accelerant scaling adds to 100% IAS at maximum ranks and preserves tick progress. Natural and forced ticks deplete actual fuel (1/2/3); damage scales by actual fuel then separate Echoing and Resonance multipliers. Partial fuel scales proportionally; empty ticks do nothing. One current-stat crit roll per fueled tick. Poison Strike is Attack, 83%, 1200/500 ms, no cooldown. Supersedes D015 no-depletion forced ticks, but depletion still is not keyword Consume. | T9/M4/M5 |
| P6M3-D023 | 2026-09-24 | Implemented and tested; T4 Complete | Riposte gives +10% Plunge damage per rank per consumed Footwork stack (rank two, five stacks = 2x). Footwork/Bypass add increased-stack bonuses, double, then cap at five/three. Bypass grants after connected Stab subtrees and refreshes a shared three-second timer. Touch consumes all actual Poison for +10% ordinary additive IAS per stack, eight seconds, thirty-second cooldown, 500 ms Self Buff cast; no conversion amplification; zero fuel casts/starts cooldown without a grant; actual Consume triggers Pact. Independent future Touch instances add and expire separately. Supersedes D022 Touch multiplication and the intermediate direct cast-time reduction proposal. | T4/T8/M4/M5 |
| P6M3-D021 | 2026-09-24 | Implemented and tested in T7 shared scope | Poison Vile: Debuff, 1.8 s base cast, 0.5 s minimum, zero weapon damage, no cooldown, 20 base Poison stacks. Normal extra stacks then doubling then cap apply. Resolves the remaining named-skill timing question. | T5/T7/T9/M5 |
| P6M3-D020 | 2026-09-24 | Implemented and tested in T7 shared scope | Each active Virulent Poison instance supplies a separate 2x multiplier to the same tick; two instances give 4x damage. Each instance spends one charge per actual tick. | T4/T7/T9 |
| P6M3-D019 | 2026-09-24 | Implemented and tested in T7 shared scope | Self Buffs use independent instances. Each Virulent instance has exactly five charges unaffected by extra stacks/doubling; each Poison tick spends one from every active instance. D020 settles overlap damage as separate 2x multipliers. Poison applications add extra stacks, then double, then cap. Audit correction: cap-40 is the old Umbral Presence talent, absent from gear pools; withdraw the gear-cap conflict question. | T4/T7/T9/M5 |
| P6M3-D018 | 2026-09-24 | Implemented and tested in T7 shared scope | Death Touch adds to gear's extra-stack total; Poison Vile is a normal base-20 application. Self Buff cast time ignores IAS. Master of Poisons: 0.5 s cast, 5 s live zero-resistance window, 10 s cooldown. Virulent Poison: 0.5 s cast, 5 s cooldown, five double-damage tick charges. Beguiling Presence: 0.5 s cast, 10 s independent instance, 30 s cooldown, actual Decay to base elemental damage 1:1 without extra stacks. Bribery applies Shred once per successful Steal/Pick Pocket theft event using normal stack modifiers. D019 supersedes the cap-source question and Virulent reapplication/modifier details; see T7. | T4/T5/T7/T9/T10/M5 |
| P6M3-D017 | 2026-09-24 | Agreed and implemented in shared fixtures | Blinding Powder has no cooldown. Debuffs/Self Buffs cannot dodge and neither advance nor reset cleanse/interrupt counters. All ticks/depletion are distinct from keyword Consume. Absorb-denial gear sets starting absorb to zero before Potency. Negative-defense base bonuses use the original damage type before conversion; positive destination defenses then mitigate. D014–D016 shared rules implemented; named content remains downstream. | T4/T5/T7/T9/M5 |
| P6M3-D016 | 2026-09-24 | Agreed design; category boundaries pending | Introduce Attack/Debuff/Self Buff categories. Blinding Powder, Pick Pocket and Poison Vile are Debuffs and do not count toward cleanse/interrupt. Five named skills are Self Buffs (see T7). Blinding Powder casts in 1 s, minimum 0.5 s, zero weapon damage; cooldown pending. Death Pact adds 1 s per rank to universal Potency/Penetration duration, giving 4/5/6 s. | T4/T5/T7/T9/T10/M5 |
| P6M3-D015 | 2026-09-24 | Agreed clarification | Penetration/Potency refresh at cap and are cleansable. Death Pact converts actual consumed Poison/Decay one-to-one into both debuffs, with no increased stacks or doubling. Cleanse is not consumption. Original forced-tick no-depletion rule superseded by D024: natural and forced ticks both deplete fuel, but are not keyword Consume. | T4/T7/T9/M5 |
| P6M3-D014 | 2026-09-24 | Agreed design; boundaries pending | Finders Keepers halves/zeros encounter-start block and is redundant with full block-denial gear. New Penetration/Potency enemy debuffs each cap at 100, subtract one block/absorb per stack, last three seconds baseline and refresh on application. Blinding Powder applies Potency based on Assassin points with normal increased stacks. Death Pact applies both debuffs based on consumed Poison/Decay, excluding increased stacks. Supersedes old Death Pact buff and generic penetration order; timing/rank/source/cleanse boundaries remain T4/T7 review. | T4/T7/T9/M5 |
| P6M3-D013 | 2026-09-24 | Agreed correction; supersedes D012 and Precision timing under D006 | Precision can be consumed by any eligible Stab/Heavy Slash cast, including procs. Quick Cut grants Precision on hit before children, enabling same-hit crit poison -> Death Blade Stab -> guaranteed repeat. Grant once, with no post-subtree regrant. Dance remains macro-only; Footwork/Readiness retain their timing. | T2/T4/T6/M5 |
| P6M3-D012 | 2026-09-24 | Superseded by D013 | Earlier macro-only Precision policy was revoked by the user. See D013 for proc consumption and same-hit grant timing. | T4/T6/M5 |
| P6M3-D011 | 2026-09-24 | Agreed clarification | Precision caps at one, persists until consumed, targets existing Heavy Slash/Stab, and is consumed under Dance overlap; both guarantee one repeat. Dodge prevents repeats. Repeated Parry still requires Readiness. Dance lasts five seconds with twenty-second cooldown. Death Blade rolls per actual poison application, not per stack; cap-only applications and ticks do not roll. Final Precision origin and grant-timing policy is D013; D012 was revoked. | T4/T6/M5 |
| P6M3-D010 | 2026-09-24 | Agreed; boundaries resolved by D011/D013 | Precision guarantees the initiating Stab/Heavy Strike repeat and is consumed at cast start, without changing the retrigger stat or Double Dip. Dance guarantees an extra zero-time cast for macro skills, not descendant retriggers. Preserve Opportunity chains, normal Side Step crit negation, and suppress all Stab poison under Death Blade. D011/D013 settle overlap/lifecycle/miss/proc boundaries; D012 was revoked. | T4/T6/M5 |
| P6M3-D001 | 2026-09-23 | Agreed task plan | Record the user-requested eleven-task breakdown, prioritizing the core Bladedancer handoff before remaining shared systems and mixed extension. This approves the work structure, not unresolved mechanics. | T1–T11 |
| P6M3-D002 | 2026-09-23 | Agreed in part; clarification pending | Record the user's first-slice rules and skill values in the [working specification](P6M3_T1_Bladedancer_First_Slice_Specification.md). Unready Parrying Strike spends its cast time; Footwork is consumed at Plunge start; Rending Slash applies Shred after damage. Remaining formulas and boundary cases are explicitly pending. | T1/T3–T8 |
| P6M3-D003 | 2026-09-23 | Agreed clarification | Resolves D002's formula questions: Footwork grants 2/4/6/8/10% time reduction per stack by rank, additive across stacks and multiplicative after ordinary speed bonuses, with Plunge floored at 0.50 s. Increased grants do not raise the five-stack cap. Connected retriggers grant Readiness, full block still counts as a hit, and missing cast-start resources cannot be acquired retroactively for that cast. Refresh-at-cap and expiry ties remain pending. | T1/T3–T8 |
| P6M3-D005 | 2026-09-23 | Agreed | At most 1,024 trigger-candidate evaluations per macro root, including filtered candidates and all descendants; invalidate and stop before the next candidate. Preserve inherited depth-16 suppression. | T2/T6 |
| P6M3-D006 | 2026-09-23 | Agreed | Preserve natural ticks before simultaneous hits and depth-first children; new player buffs follow the cast subtree, then the next macro starts. Preserve T1 consumption/expiry semantics. | T2/T4–T6 |
| P6M3-D007 | 2026-09-23 | Agreed | Approve Double Dip, Sharpened Edge, Fast Hands and Fill Your Pockets formulas; recalculate after source changes, snapshot cast duration at start and read live damage at impact/tick. Preserve fractional values until existing rounding. | T3–T6/M5 |
| P6M3-D008 | 2026-09-23 | Agreed clarification | Shadow Mastery copies 10–50% by rank of flat elemental bonuses, plus the elemental percentage bonus after normal bucket calculation, into a separate physical multiplier. Exclude baseline class poison damage from flat copying; retain elemental benefits. | T3/M5 |
| P6M3-D009 | 2026-09-24 | Agreed | Cooldowns are shared per skill ID, start on eligible macro cast start, persist on dodge/interruption, and are bypassed without restart by repeats. Missing resources do not start cooldowns. Cooling-down slots spend exactly 100 ms without effects before advancing; poison and buff timers continue. Supersedes instant-skip/earliest-deadline-wait proposal. | T5/T6/M5 |
| P6M3-D022 | 2026-09-24 | Partially superseded by D023 (Riposte ranks and Touch stacking) | Reconcile T4 with completed T6/T7: Death Pact is Consume-only Penetration/Potency, no unique Pact buff; Beguiling retains independent instances. Touch of Darkness recasts create independent multiplicatively stacking bonuses. The user corrects Riposte to two consumed Footwork stacks giving +20% damage (1.2x), superseding the earlier five-stack example, and explicitly keeps T6 Precision unchanged. Other rank mappings are not inferred from this example. | T4/M5 |

## Completed Ideas and Deliverables

First-slice decision closeout: **P6M3-D004 (2026-09-23, Agreed)** resolves the
remaining boundaries in D002/D003. Hits at the Footwork cap refresh duration.
Plunge consumes old Footwork at cast start on its expiry tick; Quick Cut's final
buff step creates a fresh instance after same-tick expiry (one base stack plus
approved grant bonuses). Supersedes the proposed expiration-before-Plunge rule.

| ID | Date | Item | Completion Type / Evidence | Remaining Work |
| --- | --- | --- | --- | --- |
| P6M3-C001 | 2026-09-23 | M3 task plan and tracker | This document, linked from phase tracking and onboarding, follows the established M2 tracker format. | T1 first-slice specification/review; T2–T11. No runtime validation claimed. |
| P6M3-C002 | 2026-09-23 | T1 first-slice specification and closeout | [Approved contracts and acceptance examples](P6M3_T1_Bladedancer_First_Slice_Specification.md); user decisions D002–D004. | T2–T11 implementation/validation; M4 playable integration; full tree review in M5. |
| P6M3-C003 | 2026-09-23 | T2 ordering and diagnostic foundations | [Contract and evidence](P6M3_T2_Combat_Ordering_And_Diagnostics.md); versioned trace, cast ancestry, branching budget, consumer safeguards and 21 passing tests. | T3–T7 mechanics/event extensions; M4/M7 visual acceptance. |
| P6M3-C004 | 2026-09-23 | T3 shared stat derivation | [Approved formulas and evidence](P6M3_T3_Stat_Derivation_And_Temporary_Modifiers.md); source snapshots, ranked rule descriptors, temporary updates, skill multipliers and 29 passing scripts. | T4/T5 lifecycle/scheduler integration; M4/M5 content and UI. |

## Open Questions and Watch Items

| Question / Risk | Resolve In | Current State |
| --- | --- | --- |
| Exact first-slice intrinsic, skills and Footwork semantics | T1; T3–T7 implementation | Specification and shared core implementation/tests complete; T8 integrated combat validation complete; M4 visual/playable acceptance remains. |
| Simultaneous effects and runaway event chains | T2/T6 | Ordering, root budget and reviewed origin filters implemented and tested; preserve them in later mechanics. |
| Temporary source copying and live/snapshot updates | T3/T4/T5/T7 | Shared stat, lifecycle and scheduler wiring implemented; named T4 effects and coverage complete under D023. |
| Consumption/expiry ties and Death Pact timer unit | T4/T5 | Footwork ties implemented; Death Pact and defense-debuff expiry settled in T7. T4 has no remaining design questions after D023. |
| All slots unavailable, repeated slots and interruptions | T5 | Unready Parry and zero-time progress tested; shared cooldowns and 100 ms no-effect cycling implemented under D009. |
| Retrigger, Bonus Stacks and poison/status amplification | T6/T7/T9 | Implemented and tested; combined coverage reconciled in T11. |
| Gold-derived stats, theft and shop spending pressure | T10 / M6 | Shared mechanics settled and tested in T10/T11; M5 content binding and M6 balance remain. |
| Core handoff delayed by unrelated mature mechanics | T3–T8 | Core and mixed handoffs complete; full package coverage reconciled in T11. |
| Premature content promotion or overstated acceptance | T8/T10/T11 / M4/M5 | The tested core slice is not a released full tree; keep release gates and visual/playable evidence explicit. |
| Watchmen matchup and numerical difficulty | M6 | Retained watch item; historical balance results are not redesigned-tree acceptance. |

## Update and Evidence Rules

- Use `Not started`, `In progress`, `Pending input`, `Blocked`, `Complete`, or
  `Deferred`; explain blockers/deferrals and name the next action or owner.
- Complete tasks only with concrete outputs/evidence. Distinguish specification
  agreement, implementation, automated checks, visual checks and playtests.
- Before affected implementation, record sources, miss/interrupt behavior,
  values/units/caps, activation/consumption, duration/charges, refresh/stack/replace,
  same-time order, RNG/proc eligibility, cleanup, events and normal/boundary/conflict examples.
- Record validation date, command/procedure, result and relevant report/commit.
  Do not relabel retained M2 results as new M3 evidence.
- Maintain task status, checklists and phase-wide status together. Link detailed
  specifications as created; preserve exact T5 fixture identities and content authority.

## Progress History

- **2026-09-24:** Completed T8 core Bladedancer combat validation and M4 handoff.
  Added explicit rank/unlock bindings and the injected core registry. All 35
  regression scripts plus final core/gear checks pass; original files/saves
  protected. T9 is next; playable registry remains p6.compat.1.


- **2026-09-24:** Closed T4 under D023 after Riposte, Bypass, Touch and shared
  stack-grant implementation. All 26 regression scripts and final boundary checks
  pass; protected files unchanged. T8 core validation is next; no content promotion.

- **2026-09-24:** Reconciled T4 context with completed T6/T7 and D022 user
  corrections. Removed obsolete pending proposals for Death Pact, Virulent,
  Master and Beguiling. Recorded multiplicative independent Touch instances and
  the confirmed Riposte damage example; user clarified that Precision stays unchanged.
  Documentation reconciliation only; no new runtime validation or T4 closeout.

- **2026-09-24:** User revised Precision to allow proc consumption and same-hit
  Quick Cut -> Death Blade -> repeat (D013). Implemented the Precision-only
  pre-child grant exception; ten revision scripts and final application coverage
  pass. Readiness/Footwork timing and protected files remain unchanged.

- **2026-09-24:** Closed T6 shared mechanics under D010–D012: Precision/Dance
  guarantees, normal resource/proc rules, Side Step and Death Blade hooks,
  per-application diagnostics, 18 passing regression scripts plus final added
  proc-origin/buff-order coverage. Protected files unchanged; T4/T7 remain pending.

- **2026-09-24:** Delivered T7 core Rending Slash/status-accounting evidence:
  explicit Decay count, application/overflow and cleanse-removal diagnostics,
  ten passing isolated scripts and unchanged protected files. T7 is Pending
  input for remaining status/mitigation contracts; T4/T6 reviews remain open.

- **2026-09-24:** Closed T5 after D009 approval and implementation of shared
  cooldowns with fixed 100 ms empty attempts. Eighteen regression scripts pass;
  protected files unchanged. T4 effect reviews remain pending; T6 is next.

- **2026-09-24:** Implemented settled T5 shared cast planning, minimum-proc
  progress floor, scheduling diagnostics and approved Parry/Plunge scaling.
  Two scheduling-policy questions are pending; no cooldown policy was assumed.
  See the T5 handoff for implementation, validation and remaining scope.

- **2026-09-23:** Implemented T4 reusable effect state and approved Footwork/Readiness
  combat hooks. Lifecycle/stat/trace and core combat tests pass alongside inherited
  regression. T4 is Pending input for remaining per-effect rules, not Complete;
  see the linked T4 implementation note. Runtime content release stays unchanged.

- **2026-09-23:** Completed T3 after formula/timing approval and the final Shadow
  Mastery clarification. Shared formulas, temporary-source updates and diagnostics
  implemented; 29 distinct scripts pass in final runs. Corrected one stale gear
  test save envelope. Protected files unchanged; T4 next.

- **2026-09-23:** Completed T2 ordering/diagnostic foundations and approved the
  1,024-candidate budget plus post-subtree player-buff timing. Twenty-one
  headless scripts pass; real saves and Enigma fingerprints unchanged. T3 next.

- **2026-09-23:** Closed T1 after final refresh/expiry decisions. First-slice
  specification and acceptance examples complete; T2 ordering/diagnostics next.
  Documentation only; no runtime validation or content promotion.

- **2026-09-23:** Recorded the user's Footwork formula/rank/floor, Readiness,
  blocked-hit, cap and resource-timing clarifications; added acceptance examples.
  T1 remains In progress for refresh-at-cap and expiration-tie decisions.

- **2026-09-23:** Recorded first-slice user decisions in the linked specification
  and verified inherited Quick Cut/Rending Slash values from source. T1 remains
  In progress pending remaining clarifications and acceptance examples.

- **2026-09-23:** Created the eleven-task M3 tracker at the user's request and
  linked phase tracking/onboarding. M3 and T1 are In progress; first-slice
  specification/review remains next. Documentation only; no combat rules approved,
  gameplay implementation, runtime tests or release promotion performed.

## Related Documents

- [Phase 6 milestone tracker](P6_Milestone_Tracker.md)
- [Project onboarding](P6_Project_Onboarding_Context.md)
- [M2 tracker](P6M2_Build_Model_And_Progression_Foundations_Tracker.md)
- [M2 closeout and M3 handoff](P6M2_T9_Closeout_And_M3_Handoff.md)
- [Cross-tree audit](P6M2_T2_Cross_Tree_Draft_Audit.md)
- [Draft inventory appendix](P6M2_T2_Draft_Inventory_Appendix.md)
- [Settled build rules](P6M2_T3_Progression_And_Allocation_Rules.md)
- [Content and compatibility policy](P6M2_T4_Content_Workflow_And_Compatibility.md)
- [Integration and dependency plan](P6M2_T5_Integration_And_Dependency_Plan.md)
- [Exact build fixtures](P6M2_T5_Build_Fixtures.json)
- [Foundation acceptance evidence](P6M2_T8_Foundation_Integration_Validation.md)
- [Tree drafts and provenance](talent_tree_drafts/README.md)

- **2026-09-24:** Implemented reviewed T7 defense/status/category rules under D017; final 22-script regression recorded in `p6_m3_t7_reviewed_final`. T7 is In progress for remaining cross-task integrations, with no outstanding question on the approved defense order.

- **2026-09-24:** Closed T7 reviewed shared-mechanics scope: independent Self Buff instances, fixed multiplicative Virulent charges, live Master resistance ignore, Beguiling conversion, Death Touch/Umbral/Vile adapters and Bribery/forced-tick hooks. 24 regression scripts plus expanded boundary suite pass; protected files unchanged. Full content promotion and broader T4/T9/T10 scope remain downstream.

- **2026-09-24:** Closed T9 under D024: live phase-preserving cadence, shared stack-scaled natural/forced ticks, multiplicative rank bonuses, critical Poison and reviewed Poison Strike. 36 regression scripts plus five final checks pass; protected files unchanged. T10 next.

- **2026-09-24:** Closed T10 under D025: capped Gilded/Silvered, reviewed Thief/Dance skills, exact mixed and reversed-role builds, gold transactions, Practice retries and source accounting. All 42 regression scripts pass, including 17 repeated twenty-seed scenarios. T11 next; playable registry remains p6.compat.1.

- **2026-09-24:** Closed T11 and M3 shared-mechanics scope: 65 inherited/foundation regression scripts plus the combined-mechanics script pass. Six scenarios across 20 seeds verify replay, trace parity, accounting and cleanup. C1–C7 and Q01–Q20 are reconciled in the T11 closeout; M4 is next, with M5/M6/M7 owners explicit. Protected files unchanged; p6.compat.1 remains playable.
