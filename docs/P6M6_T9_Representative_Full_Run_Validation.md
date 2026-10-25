# M6-T9 Representative full-run validation

2026-10-08. **T9 Complete for representative run validation and agent UI review. Balance acceptance remains open in T10.** Optimization makes a substantial difference, but the completed runs also expose excessive damage margins and remaining failure cases. No gameplay values were changed.

## Method and boundaries

The accepted cohort contains 144 main runs: all twelve ordered tree pairs × three policies × four fresh run seeds (233001–233004). Another 48 matched runs remove one informed behavior at a time for four cyclic pairings: Bladedancer/Thief, Thief/Assassin, Assassin/Shadow and Shadow/Bladedancer. These pairings each use the same four run seeds. The repeated pairings share their Tavern history; they are not twelve independent seed samples per primary. This is representative diagnostic coverage, not a population success-rate estimate.

Every journey starts with the actual starter weapon, zero gold and zero earned points, and ends in a real defeat or all thirty generated bosses defeated. Only real victories grant rewards. Purchases, sales, rerolls, earned points and equipment pass through production state APIs. Normal two-attempt limits apply, with the existing unlimited-retry exception for the first Tavern fight. No conditional victories, injected gear, replenished boss catalogs or mid-contract refunds are used.

| Policy | Allocation and sequence | Routing and purchases |
| --- | --- | --- |
| Weak / unplanned | A deterministic alternate legal allocation, chosen without scoring its combat outcome; ordinary legal sequence. It is not selected as the worst build. | First offered path; takes useful earned loot but makes no shop purchases. |
| Coherent | Existing protocol allocation priorities and ordinary legal sequence, adapted only for unlocked skills. | First offered path; up to one improving purchase per shop. |
| Informed search | Up to eight legal allocations, retaining at least two-thirds of points in the primary; bounded sequence search using two training seeds (4301–4302). Short search samples up to twelve sequences; final allocation preparation up to thirty-two. | Build-aware weights cover all fourteen displayed tags and all paths; chooses lowest total tag risk. Up to six improving shop purchases and one affordable reroll. |

Contract allocation search uses a fixed neutral practice target, owned gear and current gold. Tavern preparation and current-fight sequence adaptation use the current enemy information displayed by the combat panel, rounded to its presentation precision. Route selection cannot inspect future rolled enemy stats. Actual fight seeds come from normal run RNG and are disjoint from training seeds. Allocations remain fixed inside a contract; earned gear and sequences may change through their legal controls.

This is a bounded informed policy, not a global optimum or a claim about every skilled player. Its route weights are a documented heuristic; its gear score is the inherited stat-based T7 heuristic, not an exhaustive inventory optimizer. It can miss useful counters, build plans or reward-rich routes. Poor outcomes do not prove unavoidable walls.

Pilot runs used earlier seeds and exposed gaps in tag coverage and terminal-victory handling in the investigation tool. The accepted cohort uses the corrected, frozen policy and fresh seeds. Earlier pilot outcomes are excluded. The production continuation API correctly returns false after the final boss; the runner treats that terminal victory as success.

## Full-run outcomes

| Policy | Primary | Runs | Left Tavern | Reached C10 | Completed catalog | Median contracts completed |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| coherent | bladedancer | 12 | 0 | 0 | 0 | 0 |
| coherent | thief | 12 | 9 | 9 | 3 | 12.5 |
| coherent | assassin | 12 | 0 | 0 | 0 | 0 |
| coherent | shadow | 12 | 12 | 3 | 1 | 3 |
| informed | bladedancer | 12 | 12 | 11 | 8 | 30 |
| informed | thief | 12 | 12 | 12 | 9 | 30 |
| informed | assassin | 12 | 12 | 12 | 0 | 19.5 |
| informed | shadow | 12 | 12 | 8 | 2 | 10 |
| weak | bladedancer | 12 | 0 | 0 | 0 | 0 |
| weak | thief | 12 | 0 | 0 | 0 | 0 |
| weak | assassin | 12 | 0 | 0 | 0 | 0 |
| weak | shadow | 12 | 3 | 0 | 0 | 0 |

Failures remain outcomes, not automatically defects. The weak and coherent policies are controls; neither is entitled to finish. Conversely, a high completion rate does not establish sufficient optimized-play tension.

## Matched decision controls

The following counts compare contracts completed on matched pair/seed runs. Subsequent resource and encounter differences are consequences of the changed decisions; these are whole-policy effects, not equal-gear single-fight comparisons.

| Comparison against informed play | Pairs | Informed went further | Same endpoint depth | Other went further | Total difference in completed contracts |
| --- | ---: | ---: | ---: | ---: | ---: |
| coherent | 48 | 39 | 4 | 5 | +723 |
| informed_default_macro | 16 | 12 | 4 | 0 | +261 |
| informed_first_route | 16 | 9 | 4 | 3 | +107 |
| informed_typical_shop | 16 | 4 | 7 | 5 | +9 |
| weak | 48 | 48 | 0 | 0 | +1007 |

`informed_first_route` retains preparation/spending but takes the first path; `informed_typical_shop` retains preparation/routing but limits purchases to the coherent policy; `informed_default_macro` retains allocation/routing/spending but uses the ordinary sequence. No outcome from a control arm feeds back into another run.

Sequence adaptation has the clearest consistent effect in these controls: it goes further in twelve of sixteen matched runs and never less far. Tag-based routing goes further in nine, ties four and loses ground in three; it is useful but imperfect. More aggressive shopping goes further in four, ties seven and loses ground in five, so this evidence does not establish it as a consistently better spending policy. Informed play also loses ground to the coherent control in five of forty-eight main comparisons. These limitations belong in T10 rather than being hidden behind aggregate wins.

## Damage margins and costly mistakes

Ratios below are total first-attempt damage over the full fight window divided by enemy HP. They are not time-to-kill or direct measures of fun. These are conditional on reaching that stage; late-stage rows have survivor selection.

| Primary | Stage | First attempts | Wins | Median damage / HP | Above 5× HP |
| --- | --- | ---: | ---: | ---: | ---: |
| bladedancer | C1 | 45 | 45 | 3.56× | 3 |
| bladedancer | C4 | 39 | 39 | 2.95× | 14 |
| bladedancer | C6 | 37 | 37 | 8.17× | 27 |
| bladedancer | C10 | 36 | 36 | 41.52× | 30 |
| bladedancer | C20 | 36 | 36 | 37.44× | 34 |
| bladedancer | C30 | 27 | 27 | 19.36× | 26 |
| thief | C1 | 44 | 44 | 3.01× | 8 |
| thief | C4 | 42 | 42 | 11.05× | 40 |
| thief | C6 | 41 | 41 | 27.59× | 40 |
| thief | C10 | 39 | 39 | 527.37× | 30 |
| thief | C20 | 34 | 34 | 434.32× | 34 |
| thief | C30 | 27 | 27 | 201.89× | 27 |
| assassin | C1 | 45 | 45 | 3.97× | 18 |
| assassin | C4 | 39 | 39 | 12.44× | 33 |
| assassin | C6 | 43 | 43 | 27.59× | 38 |
| assassin | C10 | 40 | 40 | 18.81× | 33 |
| assassin | C20 | 21 | 21 | 4.67× | 10 |
| shadow | C1 | 42 | 42 | 3.14× | 4 |
| shadow | C4 | 39 | 38 | 4.74× | 19 |
| shadow | C6 | 42 | 39 | 3.81× | 15 |
| shadow | C10 | 26 | 25 | 10.65× | 18 |
| shadow | C20 | 16 | 16 | 13.45× | 13 |
| shadow | C30 | 7 | 7 | 12.53× | 7 |

A separate local mistake control removes the first used skill from the chosen sequence, retaining allocation, gear, gold, enemy and evaluation seed. If empty, it substitutes legal Stab; unchanged sequences are excluded. These are post-hoc first-attempt comparisons, not recomputed complete runs, and the omitted skill is not necessarily the most important synergy.

| Primary | Paired fights | Baseline wins | Omission wins | Median baseline ratio | Median omission ratio |
| --- | ---: | ---: | ---: | ---: | ---: |
| bladedancer | 220 | 220 | 199 | 7.27× | 2.95× |
| thief | 227 | 227 | 218 | 35.80× | 18.25× |
| assassin | 188 | 188 | 140 | 11.04× | 3.39× |
| shadow | 172 | 167 | 137 | 4.40× | 2.90× |

## Gold-scaling equipment diagnostic

The earned runs led to a targeted post-hoc test of equipment's `physical_damage_per_gold` effect. On 262 recorded informed encounters at C6/C10/C20/C30 with that effect equipped, the exact baseline replay matched. Holding allocation, gold, all other item properties, sequence, enemy and seed fixed, copied gear had only that coefficient set to zero. Baseline wins: 262/262; diagnostic-control wins: 143/262. Median damage/HP changed from 53.83× to 1.30×.

Bandit Blade supplies +0.1 physical damage per current gold. The diagnostic isolates its contribution without changing the actual item or recommending zero as a candidate value. It does not rerun the economy without that effect, so later earnings are held fixed. It establishes a concrete gold/equipment interaction to investigate before attributing every large margin to the talent trees or increasing all enemy HP.

## Counters and the finite catalog

The reports retain selected and rejected visible routes, per-node tags, remaining bosses and every terminal loss. Read the Shadow failures alongside the matched routing and sequence controls: a failure of this bounded policy is not proof that every legal alternative fails. Severe counters remain intentional; no success quota is imposed.

Of ten terminal informed Shadow losses, seven carry Devious + Arcane tags and three carry Spiteful + Hexed. Timing/control pressure therefore deserves investigation alongside Poison disruption. These labels identify cases, not a causal proof or a reason to weaken those archetypes. The rendered Shadow C20 example also demonstrates a legal physical-damage sequence against magical defenses; its acquired gold-scaling weapon makes gear dependence part of that counterplay question.

There are 124 informed offer checkpoints at C25–C30. These use the actually depleted catalog from prior victories. The final remaining identity must eventually be faced; tag-based avoidance cannot be promised indefinitely. Exact late-offer records are in `analysis.json`, and full offered-path records are in each run file.

## UI observations and verification

8 earned checkpoints covering all four primaries were resumed through the real Adventure UI at 1280×720 (90 checks). Offer inspection shows the whole route and tag labels, opens the guide and returns to preparation. Committed checkpoints retain the no-refund boundary, require relocking after resume, and resolve through the actual Fight button. Replayed fight results match the recorded held-out run. Screenshots were reviewed for readable controls and visible state. These are agent-driven automated UI observations, not a human playtest or subjective fun acceptance.

The accepted cohort contains 192 complete run records, 8060 actual fight attempts and 300 retries. The independent verifier passes 130,587 checks covering gold arithmetic, victory/reward correspondence, budgets, fixed allocations, retry rules, held-out seeds, routing decisions and natural endpoints. The equipment diagnostic passes 2,254 checks. Eight focused existing suites pass, including T8's 2,692 integration checks/360 save-load roundtrips and its 62 UI checks, plus gold, route generation/commitment, map preview, persistence and ranked builds.

Known Godot certificate-store and shutdown resource warnings remain in logs. Accepted runs have no script/assertion failures. UI harness development corrected JSON integer preservation and the intentional relock-after-load requirement; accepted UI evidence comes from reruns after those harness fixes.

A complete Shadow/Assassin informed journey (233003) was independently rerun and produced byte-identical evidence, including all purchases, route choices, rewards and its natural C6 defeat. See `replay.json`.

All 1,112 pre-existing protected source/data/scene/test/project files are checked against their starting hashes before publication and remain unchanged. Only investigation tools, evidence and milestone documents are added or updated. Tests use isolated user-data directories; real Adventure and Practice saves and the Enigma project are untouched.

## Finding classification

| Finding | Classification and implication |
| --- | --- |
| Preparation separates outcomes | Supports the intended optimization reward; weak-policy failures do not justify easier enemies. |
| Large margins and mistakes that still win | Excessive-ease investigation for T10; evaluate the measured gear/economy contribution and remaining talent/sequence effects. |
| Severe counter losses | Intentional pressure unless a separate defect or unavoidable failure is demonstrated; bounded search failure is insufficient evidence for a nerf. |
| Route and combat information | Fourteen-tag guide, full-route inspection and current-enemy details are available in the reviewed UI. Human comprehension remains unverified. |
| Implementation correctness | No new product defect established by this scope; eight regressions, ledger verification, exact replay and UI checks pass. Tooling corrections are recorded separately. |

## T10 handoff

1. Investigate excessive optimized headroom and gold-scaling equipment/economy feedback with matched candidate controls. Preserve synergy rewards while testing whether mistakes still cost enough after a build gets established. Do not infer a broad enemy buff or automatic item removal from these results.
2. Review early progression cliffs separately from late runaway power. Compare accessible alternative allocations/sequences before classifying a failed coherent preset as an enemy defect.
3. Follow up Shadow losses with build-aware counterplay and route alternatives, including the finite catalog. Distinguish intended severe counters, a weak heuristic and a genuinely unavoidable wall.
4. Use hands-on play to assess comprehension, tension, preparation effort and pacing. Automated full-window ratios cannot settle those questions. Review any concrete numerical or mechanical proposal before adopting it; there is no pending numerical approval from T9.

## Reproduction

Use an isolated copy of the current project, including the existing planning JSON fixtures required by the regression tests. Set APPDATA to a scratch directory. Run `run_m6_t9.gd` with `--tree=<primary> --secondary=<secondary> --policy=<policy> --seed=<seed>` after the Godot `--` separator. `cohort_manifest.json` lists the exact 192 combinations; `frozen_policy.json` records the accepted policy hash. Reports are written under `res://reports/p6_m6_t9/`. Run `run_m6_t9_driver.gd` after all run files exist. `run_m6_t9_ui.gd` accepts `--snapshot=<file.json> --visual` for saved earned checkpoints.

The retained Python orchestration and verifier scripts show the exact commands and independent aggregation. Their working-directory layout is `work-folder/project` for the isolated checkout, with manifests/logs beside it. `setup.py` records the source-copy procedure and its original local source location; adjust that location for another machine. No software installation or external service is required.
