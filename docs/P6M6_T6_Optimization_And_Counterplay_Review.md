# T6 optimization and counterplay reassessment

2026-10-08. **T6 focused enemy review Complete. Retain the current enemy values; reject adoption of the three previously proposed generator nerfs.** No new numerical change or approval is required. D007 Steal and D008 armor remain adopted. Adventure remains disabled. T7 remains Complete; T8 integration is next. Full-run difficulty and hands-on balance acceptance remain T9/T10, not a claim made by this closeout.

## Decision and rationale

The clarified goal is a hard game in which synergy, preparation and informed matchup selection matter. Strong specialization can have severe counters. Success percentages alone do not justify changing enemy values. A coherent preset is a control, not an entitlement to win; the search arm is a bounded attempt at optimization, not proof of a global optimum.

- **Keep the C1–C3 18-second minimum HP-budget window.** In the flagged 14-second Thief toll fight, allocation and macro adaptation already achieve 80/80 within two attempts with median damage 1.62× HP. Omitting a used skill drops that to 8/80. The proposed floor reduction raises the omitted-skill setup to 71/80 and optimized damage to 2.09× HP. This would substantially soften the consequence of the tested mistake. The time-budget discrepancy is retained as pressure, not classified as a defect.
- **Keep C1 Slow + Interrupt boss values.** The flagged boss reaches 77/80 with the searched allocation and macro, versus 12/80 with the coherent preset and 0/80 after the skill omission. Median searched damage is only 1.03× HP: a demanding matchup with demonstrated preparation value. The proposed compensation produces 80/80 and 1.21× HP. There is no current justification to adopt it.
- **Keep C4–C6 triple Poison-counter bosses.** Shadow C4 remains a severe counter; its low searched success is not itself a defect under the clarified direction. The proposed package turns the searched C4 case from 22/80 to 80/80. C6 already reaches 63/80 at 1.08× HP, compared with 80/80 and 1.55× under the proposal. Preserve the counter identity and assess informed offer selection in full runs. Do not claim every offered set is safe or every weak gear history recoverable.
- **Keep other enemies, including Bladedancer C10 and the approved Tavern values.** The new evidence does not justify a broad enemy nerf or buff. Some tested optimized cases already have high damage headroom; these are explicit T9/T10 follow-ups rather than evidence that current overall difficulty is accepted.

The previous candidate remains saved as rejected evidence. No candidate code replaces the live generators. The original three numerical questions are resolved as retain-current-values decisions, not deferred approvals.

## Matched build comparisons

All four primaries are covered at C1, C4, C6 and C10, with route roots 7001 and 85016. For each stage/primary, use up to the first two typical T7 histories that actually reached that stage (roots 84001–84008). Shadow C10 has only one reached history in this cohort. Test the first generated encounter, the toll encounter when present, and the boss. Gear, gold and full point budget are held equal within each comparison; secondary roles remain fixed. At least two-thirds of points stay in the named primary during alternative allocation search.

Five controls are used:

1. **Unplanned:** a deterministic alternative allocation chosen without scoring its encounter outcome; full budget and a legal default sequence. It is not deliberately chosen to be the worst and may outperform the preset.
2. **Coherent preset:** the earned-history allocation and protocol's legal default sequence.
3. **Macro search:** the same allocation with a searched skill sequence.
4. **Allocation + macro search:** up to 24 bounded legal allocations, followed by broader macro search for three finalists. The original allocation remains eligible.
5. **Used skill omitted:** hold the searched allocation fixed and remove one used skill, selected for its training damage impact. If removing the sole skill leaves an empty sequence, substitute legal Stab. This is a deliberate tactical mistake control, not a claim that every omitted skill is mechanically a synergy or every weak build resembles it.

Search uses roots 3201–3202; validation uses fresh roots 215001–215040. The search optimizes training damage, not the validation success rate; it can generalize worse than another arm. It uses exact enemy information and is therefore a diagnostic preparation upper bound, not a model of what a player knows from tags. Each encounter's searched allocation is an alternative pre-contract plan, not a legal mid-route respec. These results must not be concatenated into a claimed successful run. Stage-reached histories also have survivor selection; late-stage rows do not represent typical fresh-run success.

Candidate comparisons freeze ranks and macros across versions. Only changed encounters are rerun against the saved candidate. C1 short encounters isolate the floor rule; the long C1 timing boss isolates the boss rule; C4/C6 qualifying bosses isolate the combined Poison-counter rule. No combined changes to player talents, rewards or gear are introduced. Damage ratios use full-window first-attempt damage divided by HP; they measure headroom and are not time-to-kill or direct measures of fun.

| Matchup | Control | Current wins within two | Current median damage/HP | Rejected candidate wins | Candidate median damage/HP |
| --- | --- | ---: | ---: | ---: | ---: |
| Thief C1 toll | Coherent preset | 10/80 | 0.80× | 68/80 | 1.03× |
| Thief C1 toll | Allocation + macro search | 80/80 | 1.62× | 80/80 | 2.09× |
| Thief C1 toll | Used skill omitted | 8/80 | 0.82× | 71/80 | 1.05× |
| Thief C1 timing boss | Coherent preset | 12/80 | 0.90× | 76/80 | 1.06× |
| Thief C1 timing boss | Allocation + macro search | 77/80 | 1.03× | 80/80 | 1.21× |
| Thief C1 timing boss | Used skill omitted | 0/80 | 0.55× | 0/80 | 0.64× |
| Shadow C4 boss | Coherent preset | 0/80 | 0.64× | 8/80 | 0.85× |
| Shadow C4 boss | Allocation + macro search | 22/80 | 0.88× | 80/80 | 1.30× |
| Shadow C4 boss | Used skill omitted | 0/80 | 0.59× | 1/80 | 0.86× |
| Shadow C6 boss | Coherent preset | 0/80 | 0.50× | 12/80 | 0.82× |
| Shadow C6 boss | Allocation + macro search | 63/80 | 1.08× | 80/80 | 1.55× |
| Shadow C6 boss | Used skill omitted | 0/80 | 0.55× | 10/80 | 0.77× |

The toll and timing-boss searches found mixed Thief/Assassin allocations using five Keen Eye ranks and one Assassin Quick Hands rank, with Venom Jab in the sequence. Removing Venom Jab produced the paired omission controls. This is evidence for an available different plan; it does not promise that a player already committed with six Thief points can respec at that fight.

## Cross-primary results on unchanged enemies

Each cell gives wins within two attempts and median first-attempt damage/HP. Aggregates include favorable and unfavorable encounters and are not encounter success targets.

| Primary | Stage | Unplanned | Coherent preset | Macro search | Allocation + macro search | Used skill omitted |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Bladedancer | C1 | 271/400 (1.19×) | 383/400 (1.53×) | 395/400 (1.75×) | 395/400 (1.75×) | 152/400 (0.58×) |
| Bladedancer | C4 | 306/400 (1.56×) | 320/400 (1.94×) | 389/400 (2.77×) | 400/400 (3.68×) | 205/400 (1.25×) |
| Bladedancer | C6 | 342/400 (1.53×) | 372/400 (1.76×) | 399/400 (2.42×) | 400/400 (6.70×) | 256/400 (1.13×) |
| Bladedancer | C10 | 348/400 (3.33×) | 388/400 (3.39×) | 389/400 (3.80×) | 380/400 (3.90×) | 284/400 (1.97×) |
| Thief | C1 | 177/400 (0.89×) | 236/400 (1.01×) | 300/400 (1.35×) | 397/400 (1.63×) | 88/400 (0.55×) |
| Thief | C4 | 212/400 (1.14×) | 399/400 (2.91×) | 400/400 (3.71×) | 400/400 (8.23×) | 297/400 (1.53×) |
| Thief | C6 | 341/400 (1.67×) | 400/400 (12.85×) | 400/400 (20.32×) | 400/400 (20.70×) | 319/400 (5.74×) |
| Thief | C10 | 328/400 (1.66×) | 400/400 (4.86×) | 400/400 (6.73×) | 400/400 (6.75×) | 280/400 (3.14×) |
| Assassin | C1 | 319/400 (1.61×) | 288/400 (1.56×) | 400/400 (1.98×) | 400/400 (2.70×) | 97/400 (0.45×) |
| Assassin | C4 | 400/400 (2.98×) | 400/400 (4.01×) | 400/400 (5.43×) | 400/400 (6.91×) | 138/400 (0.28×) |
| Assassin | C6 | 398/400 (2.45×) | 400/400 (4.99×) | 400/400 (6.44×) | 400/400 (6.44×) | 194/400 (0.11×) |
| Assassin | C10 | 400/400 (2.09×) | 400/400 (2.90×) | 400/400 (5.78×) | 400/400 (5.71×) | 166/400 (0.43×) |
| Shadow | C1 | 175/400 (0.85×) | 399/400 (1.77×) | 400/400 (1.79×) | 393/400 (1.78×) | 253/400 (1.05×) |
| Shadow | C4 | 266/400 (1.57×) | 320/400 (2.01×) | 345/400 (3.27×) | 342/400 (3.27×) | 193/400 (0.75×) |
| Shadow | C6 | 161/400 (0.65×) | 186/400 (0.90×) | 357/400 (2.22×) | 382/400 (2.65×) | 174/400 (0.64×) |
| Shadow | C10 | 80/200 (0.70×) | 80/200 (0.62×) | 122/200 (1.52×) | 144/200 (1.38×) | 100/200 (0.75×) |

## Information and commitment audit

The real map-card formatter displays archetype tags for the generated nodes. Existing UI tests verify full-route visibility, including the boss, while nonadjacent nodes are not selectable. State checks verify three generated offers, respec at the offer, route inspection, returning to offers before the first node, and no return or respec after commitment. Each sampled contract boss lies on every path through its own contract; it cannot be bypassed within that route. The flagged Thief toll appears on two of five paths and is avoidable on that route. Every sampled offer set has at least one boss without the complete Poison-counter triple; this does not establish that the alternative is beatable or that its tags reveal every rolled mechanic.

Forty offer sets / 120 contracts cover eight fresh roots at C1, C4, C6, C10 and C20. These offer probes do not include a depleted late-run boss catalog; the finite prototype eventually requires remaining identities and does not guarantee indefinite avoidance. Tags predict tendencies, not exact rolled mechanics or values. Map-entry tooltips are disabled in the current renderer; the vocabulary source describes counters, but label rendering alone does not prove that players understand them. T8 must verify a usable explanation/discovery path before relying on informed avoidance as a release criterion.

The nine existing regressions include real route-preview UI and commitment tests, ranked-build fixtures, generator tests and combat/gold checks. This is automated UI/state verification, not hands-on play or a new Adventure enablement.

## Tag-only offer choice

A separate comparison keeps each earned allocation and a neutral-dummy-trained macro fixed across three actual offers. It picks the first lowest-risk offer using only visible boss tags and fixed weights: Bladedancer fortified/nimble=2, devious=1; Thief devious/arcane=2, fortified=1; Assassin fortified/nimble=2; Shadow warded/hexed=2, relentless=1. Ties choose the first offer. The heuristic is a documented simple policy, not an optimized routing oracle. Offers use roots 216001–216004; combat uses held-out roots 215001–215040.

These are conditional boss comparisons using incoming-stage resources. They omit intervening fights, loot, spending and losses, so they measure a component of choice value, not completed contracts or a recommended optimal route policy. Tag choice can improve or worsen outcomes; actual effect sizes are retained below.

| Primary | Stage | First offered boss | Tag-chosen boss |
| --- | --- | ---: | ---: |
| Bladedancer | C1 | 264/320 | 320/320 |
| Bladedancer | C4 | 69/320 | 283/320 |
| Bladedancer | C6 | 298/320 | 320/320 |
| Bladedancer | C10 | 290/320 | 320/320 |
| Thief | C1 | 240/320 | 320/320 |
| Thief | C4 | 104/320 | 276/320 |
| Thief | C6 | 320/320 | 320/320 |
| Thief | C10 | 320/320 | 320/320 |
| Assassin | C1 | 320/320 | 318/320 |
| Assassin | C4 | 320/320 | 320/320 |
| Assassin | C6 | 320/320 | 320/320 |
| Assassin | C10 | 320/320 | 320/320 |
| Shadow | C1 | 280/320 | 280/320 |
| Shadow | C4 | 19/320 | 19/320 |
| Shadow | C6 | 173/320 | 93/320 |
| Shadow | C10 | 81/160 | 41/160 |

## Required downstream work

Two findings prevent treating this closeout as full balance acceptance. First, optimized Thief C6 damage has a median of 20.70× enemy HP in this selected cohort, while several other optimized groups also have large headroom and some unplanned groups win almost every trial. That is a concrete excessive-ease investigation, not proof that weak play reliably fails. Equal resources isolate build differences, but earned gold and gear vary across histories; a uniform enemy HP increase could punish other builds and does not follow from these samples. Second, the tag-only policy leaves Shadow C4 at 19/320 and worsens C6 from 173/320 to 93/320 and C10 from 81/160 to 41/160. This policy is not sufficient Shadow counterplay. T8 must address usable information and T9/T10 must test build-aware routing/adaptation and resolve any remaining unavoidable walls. Keeping the Poison-counter boss is not acceptance of those unresolved outcomes.

- **T8:** preserve and verify the offer inspection/return/respec boundary with redesigned content; verify tag explanation access and real equipment/sequence editing; preserve saves. Resolve essential information gaps before normal access. No broader UI redesign is authorized by this report.
- **T9:** matched full runs with fixed legal allocations inside contracts; compare informed routing, spending and build decisions against weaker policies. Carry forward high-headroom optimized rows and omission controls that still win, as well as Shadow counter losses. Check whether routing benefits survive cumulative rewards and resource constraints. Include catalog depletion and different secondary choices beyond this four-pair cohort.
- **T10:** evaluate optimized-play tension, dominant strategies, weak-choice tolerance and unavoidable counters. Do not weaken a counter merely to raise success. Investigate excessive ease as seriously as excessive pressure. Hands-on acceptance is still required.
- **T11:** retain these distinctions in regression and handoff; do not relabel intentional counter-matchups as bugs. Broader balance acceptance remains open until T10.

## Evidence and reproduction

The new build comparison executes **37,400 first attempts and 8,642 actual retries**. The independent tag-choice comparison executes **14,880 first attempts and 3,381 retries** across all three offers. The choice audit passes 1,438 assertions; the independent verifier passes 110,573 checks. All nine existing regression suites pass after restoring the isolated copy's external planning fixtures. The initial fixture-missing test execution is not counted as a pass. Known certificate-store and shutdown resource warnings remain; accepted executions have no script/assertion failures.

Evidence: `project/reports/p6_m6_t6_optimization/` contains four primary JSON files, `choices.json`, `tag_choice.json`, `verification.json`, regression results and accepted logs. Source tools are `run_t6_optimization_review.gd`, `run_t6_choice_audit.gd`, and `run_t6_tag_choice.gd`. They use the saved T7 histories and prior candidate tool copies; no real saves are read or written. Run in an isolated copy with Godot 4.7, isolated APPDATA and an absolute log path. Invoke the optimization tool once per `-- --tree=<primary>`, then choice and tag tools. Run `verify.py <evidence-folder>` for independent checks. The ranked-build regression additionally requires the repository's referenced planning JSON fixtures alongside the isolated project.

Publication verifies all 1,095 previously protected source/data/test/scene files remain unchanged. New investigation tools and documents are the only project additions/updates. No new numerical approval, implementation or adoption replay is needed because the adopted baseline is unchanged.
