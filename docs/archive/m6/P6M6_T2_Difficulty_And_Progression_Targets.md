# M6-T2 — Difficulty and progression targets

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. [Current context](../../P6_Project_Onboarding_Context.md).

**2026-10-08 — T6 focused review Complete:** [Optimization and counterplay reassessment](P6M6_T6_Optimization_And_Counterplay_Review.md) retains current enemy values and rejects the three prior nerfs. Matched build/skill-omission trials, tag-only offer comparisons, route commitment checks and nine regressions support the decision. No numerical approval is pending. T1–T7 Complete; T8–T11 Not started; Adventure disabled. Full-run difficulty, optimized-play tension and hands-on acceptance remain T9/T10.

**2026-10-08 — Difficulty direction clarified:** [User direction and reassessment criteria](P6M6_T6_Difficulty_Direction_Clarification.md) require a hard game where optimization, synergy and informed matchup avoidance matter; heavy build counters are acceptable. The three-change recommendation is withdrawn pending weak/coherent/optimized comparisons and routing review. T6 In progress; no numerical approval currently requested. Live values unchanged; Adventure disabled.

Date: 2026-10-07. Status: **Complete — design specification and T4 handoff.**

The user authorized finalization of the proposed closeout choices on 2026-10-07.
Decision P6M6-D004 adopts success percentages as diagnostic references, preserves
subclass matchup differences while requiring investigation of persistent pre-C10
walls, and accepts the finite boss catalog and C30 plateau as prototype limitations.
T3 evidence is reconciled. This closes target design, not gameplay balance testing.
T4 supplies realistic fixtures and measurement procedures; T5–T7 own focused tuning,
T9–T10 assess full runs and fun, and T8 owns Adventure release readiness.

## Established baseline

- Use current P6M5-D023 playable content, retaining the M5 closeout fixes and the
  2026-10-07 Test Mode starting-tree selectors.
- Combat is a fixed-duration damage check. `CombatResolver.resolve` declares a win
  when total damage is at least enemy HP. Player health remaining is not a metric
  for this combat model. Simulation duration and actual playback time are distinct.
- Tavern rewards are 1/0/2/3 points. Contracts then grant three points per completion,
  capped at 45. Boss gear and contract talent rewards are separate benefits.
- Adventure offers its secondary at the generated-contract transition. Test Mode's
  new immediate selection is a test convenience, not a changed Adventure rule.
- Main/secondary roles remain fixed. Use legal point allocations and only the
  existing permitted gear, macro and respec changes at each transition.
- The first Tavern encounter has unlimited retries; other encounters allow two
  attempts total. Do not assume independent retry outcomes or unlimited rerolls.
- Contracts continue beyond the point cap, but the current loop ends after the
  30 generated boss identities are defeated. Combat scaling curves clamp at C30;
  generator-only later-stage probes are not ordinary reachable runs. See the
  [T3 audit](P6M6_T3_Adventure_And_Enemy_Baseline_Audit.md).

Sources: [progression rules](../../P6M2_T3_Progression_And_Allocation_Rules.md),
[M5 handoff](../../P6M5_T11_Closeout_And_M6_Handoff.md),
`project/scripts/autoload/build_state.gd`, `project/scripts/systems/combat_resolver.gd`,
and `project/scripts/systems/contract_route_generator/contract_route_generator.gd`.
Older numerical talent examples in the progression specification are historical;
current approved content takes precedence.

## Progression checkpoints

Evaluate encounters at their incoming budget, before paying their reward.

Updated under P6M6-D006 (2026-10-07): three points per contract, capped at 45 after C13. Earlier T3/T4 baseline measurements used five-point progression; the linked three-point experiment records the comparison.

| Checkpoint | Incoming points | Points after completion | Purpose |
| --- | --- | --- | --- |
| Mouthy Drunk | 0 | 1 | Common starter macro and basic combat introduction |
| Drunk Buddy | 1 | 1 | First talent choice; gear/shop introduction follows victory |
| Tavern Bouncer | 1 | 3 | First meaningful check without borrowing its reward points |
| Hired Goon | 3 | 6 | Tavern exit challenge before deeper tree purchases |
| Contract 1 | 6 | 9 | Secondary access and first generated route |
| Contract 2 | 9 | 12 | Smooth progression and skill unlock development |
| Contract 3 | 12 | 15 | Smooth progression and skill unlock development |
| Contract 4 | 15 | 18 | Smooth progression and skill unlock development |
| Contract 5 | 18 | 21 | Smooth progression and skill unlock development |
| Contract 6 | 21 | 24 | Smooth progression and skill unlock development |
| Contract 7 | 24 | 27 | Smooth progression and skill unlock development |
| Contract 8 | 27 | 30 | Smooth progression and skill unlock development |
| Contract 9 | 30 | 33 | Smooth progression and skill unlock development |
| Contract 10 | 33 | 36 | Smooth progression and skill unlock development |
| Contract 11 | 36 | 39 | Difficulty ramp; remaining talent income |
| Contract 12 | 39 | 42 | Difficulty ramp; remaining talent income |
| Contract 13 | 42 | 45 | Difficulty ramp; remaining talent income |
| Contracts 14–15 | 45 | 45 | Post-cap difficulty ramp |
| Contracts 16–20, 21–25, 26–30 | 45 | 45 | Increasing challenge; eventual failure expected |
| Beyond contract 30 | 45 | 45 | Future endless-mode context; not a current player-run acceptance requirement |

All four primaries need coverage. At mixed checkpoints cover all twelve ordered
pairings, not just six unordered pairs. At 45 include legal 35/10, 33/12 and 24/21
families; T4 chooses concrete allocations. A diagnostic single-tree build is not
automatically the expected full-budget Adventure build.

## Agreed experience direction and phase scope

User direction, 2026-10-07: Adventure should feel smooth until around contract 10,
then difficulty should ramp up. Difficulty continues escalating indefinitely,
with eventual failure expected in the future endless loop. For this phase, assess
the existing ramp within the finite prototype; indefinite escalation is not a
closeout requirement. The diagnostic references below support this experience goal.

Clarified on 2026-10-08: the game should be hard from early progression onward. Optimization, mechanical synergy, preparation and informed matchup avoidance are central gameplay. Strong, appropriately matched builds should outperform weak or incoherent ones, while optimized play still faces meaningful challenges. A coherent preset is not guaranteed C10 progress, and a strong specialized build need not defeat its severe counter. Inspect weak-choice failure, damage margins, adaptation and player-readable routing alternatives. Later difficulty escalation remains relevant; do not use the earlier smooth-C10 interpretation to automatically reduce early enemy pressure.

### Current playtest and future victory loop

The current goal of completing as many contracts as possible is a temporary way
to test whether building, planning and combat are fun. It is not the final victory
condition. The intended future loop is:

1. Build strength through contracts.
2. Choose to enter a final map, **The Road**, at any time when the player feels
   strong enough; no fixed contract-count or talent-cap entry requirement is specified.
3. Progress through a series of bespoke boss fights to the dragon at the top of
   the mountain.
4. Slay the dragon to beat the game.
5. Optionally continue contracts in endless mode, with difficulty ramping to
   impossible levels.

The Road is future design context, not added implementation scope for Phase 6.
Boss lineup, entry/exit behavior, failure/retry rules, rewards and exact difficulty
remain unspecified. C10 is a current playtest pacing reference, not an entry gate
for The Road or a substitute for defeating the dragon. The current prototype permits contracts without implementing or defeating the
dragon, but has its own finite all-generated-bosses completion condition.

For this phase, inspect and playtest existing scaling first. Preserve it where it
supports smooth progress through approximately C10 and a useful later challenge.
Prioritize clear progression walls, broken interactions, poor choice feedback and
large pacing problems. Make focused numerical adjustments supported by evidence;
do not replace the curve or pursue exhaustive endless-mode balance merely to
match provisional percentages. Record whether upgrades feel useful, macro changes
produce understandable results, losses suggest a response, and players want to
try another build/run. Quantitative results support those observations.

### Timing policy

The user accepted regular fights around **15–30 seconds** and bosses around
**30–60 seconds** as appropriate timing windows. Treat these as pacing ranges, not
exact mandatory durations or a reason to retune an otherwise enjoyable encounter.
Retain the Tavern's existing 12/18/24/30-second windows as the initial baseline.
T3 sampled ordinary/captain windows at 14–34 seconds, elites at 20–36 and bosses
at 30–60. Short/long variants are acceptable where playtesting supports them;
20–40 seconds remains an elite pacing reference, not a separate mandatory band.
There is no duration edit required by T2. Changing duration changes damage
opportunity and potentially generated HP; T6 must assess the combined effect.

Keep the protocol's 30/120-second dummy windows for historical comparison. A
120-second diagnostic does not imply a 120-second Adventure boss target.

### Historical success references and current practical acceptance

The following percentages are historical diagnostic references, not current tuning targets or pass/fail gates. The 2026-10-08 optimization/counterplay direction takes precedence. Current acceptance requires meaningful decision advantages, costly mistakes, legible counters and remaining challenge for optimized play; T9/T10 supply full-run and hands-on evidence. This is a
final policy choice, not a pending request to approve exact floors. Use realistic
stage-appropriate gear and a coherent macro; report observed rates and variation
without tuning solely to reach a percentage. No exhaustive statistical certification
of a 99% or 99.5% floor is required for this phase.

| Diagnostic reference | First-attempt success | Success through the playtest horizon |
| --- | --- | --- |
| Tavern and ordinary encounters through approximately C10 | Around 99% as a reference for reliable progress | Report actual retries and Tavern completion; first fight retains unlimited retries |
| Bosses through approximately C10 | Around 95% as a reference for preparation without routine run-ending failure | Report actual outcomes within the allowed attempts |
| Fresh run through C10 | Report encounter and contract outcomes separately | Around 80% completion as a diagnostic reference under a recorded reasonable-play policy |

Earlier proposed 99.5% retry, 97% captain, 98% Tavern and weak-gear 80%/70% floors
are retired as acceptance requirements. Record those cohorts' actual outcomes
instead. Higher success is not a defect by itself; do not manufacture random losses.
The old Watchmen scenario's threshold stays intact as historical evidence, separate
from this current-content policy.

The practical acceptance standard is:

- Typical obtainable gear and understandable macros support smooth progression
  through approximately C10 across the four primaries and representative mixed builds.
- Each primary has a viable progression path. Investigate persistent mandatory
  encounter walls before C10, especially where legal, obtainable gear/macro/route
  responses do not resolve the problem. One unlucky roll or one weapon-only probe
  does not establish a persistent wall.
- Distinct strengths, weaknesses and occasional difficult encounters are acceptable.
  Record the response available to the player. Neither equal dummy DPS nor every
  possible allocation beating every enemy is required.
- Upgrades and coherent macro improvements have useful, understandable effects;
  losses provide useful feedback and players have reasons to try another build/run.
  T9/T10 record hands-on observations alongside reproducible outcomes.
- After approximately C10, increasing pressure and eventual build failure are intended.
  Assess the existing C11–30 ramp without prescribing a fixed failure contract or
  requiring a curve rewrite. The 30-boss ending and C30 plateau are accepted limits
  of the present prototype, not defects that must be removed in Phase 6.

T4 defines representative scenarios and policies before scoring. T9 measures actual
run/retry trajectories; do not multiply isolated encounter win rates or assume
`1 - (1 - p)^2` describes actual retry success. T10 reviews evidence against the
experience standard and records any accepted exceptions. A deviation from a
reference percentage calls for explanation, not an automatic fix or waiver.

## Gear, gold and macro expectations

T3 records actual availability; T4 freezes reproducible fixtures. Do not invent
new rewards or assume access to equipment before its introduction.

| Cohort | Definition and expectation |
| --- | --- |
| Typical gear | Obtainable at that checkpoint under recorded ordinary reward and spending choices. No required rare/legendary drop or perfect affix combination. This is the main acceptance cohort. |
| Weak gear through C10 | Plausible unlucky rewards or a delayed upgrade, not deliberately empty equipment. Measure sensitivity and review obtainable recovery options after legal adaptation; no separate success floor is imposed. |
| Strong gear | Plausible favorable rewards and sensible purchases. Demonstrate improvement without using best-in-slot gear to conceal a weak baseline. No upper success cap. |
| Reasonable macro | A short, understandable cycle using unlocked skills with coherent setup/payoff and cooldown handling. Use at most ten slots; repeated entries are legal. Author and explain it before scoring validation seeds. No seed-specific script or exhaustive search required. |
| Optimized macro | Independently searched legal candidate on training seeds, frozen before held-out validation. Report its advantage without making it the only viable route. |

Compare trees at equivalent opportunity and stage, allowing relevant gear choices
rather than forcing identical gear that only suits one damage type. Record item
IDs/affixes, weapon, budget, tree roles/ranks, macro, starting gold, purchases and
theft state. For Thief, include low-stash, pre/post-shop and wealthy states reachable
at that point. Neither a permanent zero stash nor free 500 starting gold represents
all Adventure stages. Full-run gold carries forward through actual rules.

## Metrics and matchup policy

- Primary metrics: first-attempt wins, wins within allowed attempts, conditional
  contract completion, and fresh-run completion through the selected horizon.
- Damage margin: `total_damage / enemy_hp - 1`; zero is the win boundary. Report
  median and low/high percentiles for all outcomes, plus required DPS and actual DPS.
  Diagnostic review flags: median margin below +10% on ordinary typical encounters,
  or above +100% across an entire stage. These trigger investigation, not automatic tuning.
- Report simulation window separately from time first crossing enemy HP, where
  derivable from timestamped damage. Do not estimate kill time using average DPS
  when the macro ramps or bursts. Wall-clock UI/playback pacing is a separate observation.
- Report Poison supply/depletion, temporary-effect uptime, cooldown skips, defense
  reduction, crit/retrigger variance and gold ramp as explanations, not substitute wins.
- Preserve distinct matchups. Each primary needs a coherent viable path; an
  arithmetic average must not hide a mandatory encounter wall for one tree.
- Diagnostic review trigger: more than 15 percentage points between the best and
  worst reasonable primary in the same stage/encounter family with comparable
  gear opportunity. Equal dummy DPS or identical performance on every enemy is not required.
- Difficult matchups should have an obtainable gear, macro or route response.
  Do not require changing fixed tree roles or an unavailable mid-contract respec.
  Mature mixed builds need evidence of a benefit and a cost, not universal dominance.

## Measurement and exception contract

T4 specifies exact seed cohorts and sample sizes appropriate to encounter and
full-run questions. Retain the existing protocol's 200-seed comparison and separate
200-seed validation cohorts as historical inputs; do not automatically impose that
sample size on every new scenario. Report denominators and uncertainty, freeze
candidates before held-out scoring, and use paired comparisons where appropriate.
No larger cohort is required solely to certify a diagnostic percentage. Expand
sampling when unresolved variance could change a practical decision. Full-run
coverage is separate from dummy testing.

Freeze a legal retry/adaptation policy before scoring: inspect the failed result,
allow only changes the live state permits, then use the actual retry seed/state.
Record unchanged-retry results separately. No inferred independence or free respec.

An exception record must name the checkpoint, enemy, builds, gear/macro policy,
experience criterion affected, measured sample and uncertainty, player-facing
reason, available response, scope, owner and review decision. Persistent mandatory
progression walls through C10, nonfunctional builds and missing obtainable
counterplay in the smooth-progression band require resolution or explicit T10
disposition; they must not be hidden by aggregate success rates. Beyond C10,
eventual power shortfall is intended; implementation errors remain defects. T10 reviews exceptions; T11 carries accepted
ones forward. Proposals remain separate from accepted exceptions.

## T3 reconciliation and task completion

**2026-10-07 — T3 complete:** The [baseline audit](P6M6_T3_Adventure_And_Enemy_Baseline_Audit.md)
records 90 routes, 702 enemies, 5,280 current-content diagnostic combat samples and
200 separate legacy Watchmen samples. Boss timing already spans 30–60 seconds;
ordinary/captain windows span 14–34 in the sample. Preserve this baseline for
playtesting. Combat scaling plateaus at C30 and the live run has a finite 30-boss
completion condition; indefinite escalation is future intent, not existing behavior.
T4 must establish realistic gear/stash, mixed allocations and encounter-adapted
macros before drawing progression conclusions; the percentages are diagnostic
references under D004, not acceptance gates. T3 does not
show that current scaling needs a rewrite or that C10 smoothness already passes.

The following requested audit inputs are now addressed by that report; full-run
spending trajectories and acceptance-quality cohorts remain T4/T7/T9 work.

Audited inputs:

1. Actual encounter/role counts, required versus optional routes, time windows and
   HP generation inputs by contract number; include the Watchmen case.
2. Reward/shop/gear availability and gold trajectories at the incoming checkpoints.
3. Retry RNG/state behavior, legal adaptation opportunities and generated difficulty
   labels mapped to the intended normal progression path.
4. Post-cap scaling and any mismatch between retained Adventure content and the
   playable registry. Apply the agreed smooth-through-C10 / escalating-eventual-failure policy;
   inspect the scaling implementation beyond C30 and propose measurable ramp checks.

T2 checklist:

- [x] Existing progression, timed-damage model and retry boundaries researched.
- [x] Incoming checkpoint table and gear/macro definitions drafted.
- [x] Candidate timing, success, matchup and exception policies drafted.
- [x] Smooth through approximately C10 and indefinite escalation with eventual failure recorded.
- [x] Regular 15–30-second and boss 30–60-second timing windows agreed.
- [x] Current scaling treated as the preferred starting point for focused phase-level validation.
- [x] The Road, dragon victory and optional post-victory endless contracts recorded as future context.
- [x] Numerical references finalized as diagnostic aids rather than pass/fail gates under D004.
- [x] T3 baseline findings reconciled; feasibility gaps assigned in the linked audit.
- [x] Practical acceptance policy and current-prototype horizon finalized; D004 logged.
- [x] T2 marked Complete; T4 handoff recorded below and linked from the M6 tracker.

Validation on 2026-10-07: read the linked specifications and inspected the named
runtime sources plus the four Tavern encounter resources. No simulation, balance
tuning, save mutation or Adventure enablement was performed for T2. The earlier
Test Mode selector tests validate that UI change only.

## T4 handoff and closeout verification

Next task: **M6-T4 — Representative balance scenarios and tooling**, in the
[M6 tracker](../../P6M6_Enemy_Balance_And_Adventure_Progression_Tracker.md).

T4 must turn the incoming-budget checkpoints into reproducible scenarios with
obtainable gear/stash, reasonable and optimized macros, both tree roles and legal
adaptation. Prioritize the T3 tutorial, C4 guardrail removal, C6/C11 band transitions,
defended Shadow matchups and Watchmen findings. Cover the two unsampled route
templates and distinguish mandatory encounters from avoidable risk. Record exact
fixtures, seeds, acquisition/spending assumptions, outcome and damage-margin metrics,
and the procedure for later full-run and hands-on assessment. Preserve historical
protocol fixtures. Do not implement The Road or remove prototype limits as part of T4.

Closeout on 2026-10-07: specification, M6/phase trackers and onboarding reconciled;
local links, completion checklist and whitespace checked. No runtime files, gameplay
values or saves changed, and no new runtime test was needed for this documentation
closeout. T3 measurements remain baseline evidence, not newly passed balance tests.
