# M5-T11 — Regression, closeout and M6 handoff

Date: 2026-10-06. Status: Complete — M5 content implementation and acceptance closed.

## Accepted baseline

M5 delivers all four Rogue trees: 44 talents / 140 ranks, four intrinsics, twenty planned skills, eighteen populated automatic slots, two intentionally empty slots and two talent skill grants. Three common class skills remain outside the twenty-skill tree inventory. The current authority is P6M5-D023 plus the T10 Practice gear-unlock pruning fix.

Test Mode and Practice use `p6.playable.shadow.1`. Supported saved playable revisions are Shadow, Assassin, Thief, Bladedancer, mixed and Bladedancer-core; the release manifest lists their exact identifiers. Adventure entry remains disabled and its retained compatibility implementation uses `p6.compat.1`. This closeout introduces no runtime changes, balance values, Adventure enablement or new release revision.

## Findings and corrections

- Historical identity/fixture/review/conversion tools assumed the original Shadow draft bytes remained current. T9 had already reconciled the exact approved D023 successor. Shared provenance helpers now accept either the historical hash or that exact successor, requiring the D023 release manifest and T9 reconciliation evidence to agree. Original identity manifests, compatibility fixtures and predecessor release manifests remain intact. Unrecognized bytes or predecessor hashes fail. Historical review arithmetic remains historical specification evidence, not a current balance assertion.
- An inherited five-slot equipment test wrote under `user://` and expected the earlier three-affix Cursed shape. It now writes beside its isolated test wrapper and verifies the current four-affix shape with the drawback in slot four, consistent with the gear editor and generator contract. Its five-slot save/load assertions remain in place.
- The inherited Practice combat-view test expected only four status chips. It now expects the existing six-chip strip including Penetration and Potency. The rest of its combat animation, defense, tooltip and playback assertions pass unchanged.
- The regression runner gains optional report isolation, preserves source hashes, scans explicit failed checks and saves incremental results. An initial path-rebasing bug omitted a report parent directory; it was corrected before the final sweep. The large mixed/gear matrix uses its documented 900-second allowance; an ordinary-suite timeout does not count as matrix acceptance. The initial partial run and static failures are diagnostic history, not acceptance evidence.

## Acceptance reconciliation

| Requirement | Final evidence |
| --- | --- |
| Complete content, stable identities, legal gates/prerequisites and every rank | Four full-tree suites, current ledger, identity/fixture and release-chain checks; [content-to-suite map](../project/reports/p6_m5_t11/acceptance_map.json) |
| Q01–Q07 design questions | T3/T5/T7/T8 approved specifications, D003/D004/D009/D011 and explicit D012–D023 successors; resolutions in acceptance map |
| B01–B04 registry, carrier, UI and compatibility dependencies | Full-tree/mechanic tests, eight player journeys, release manifests and persistence boundary checks |
| Shared scheduling, effects, resources, triggers, defenses and approved tuning | All current P6 runtime test suites, including D012/D013/D023 and live balance protocol checks |
| Mixed builds and gear | Fresh T9 matrix: 576 scenarios over twelve ordered pairings and 36 main allocations; four additional interaction cases; legendary and five-slot gear consumers |
| Player flows and Practice/Lab parity | Eight fresh headless journeys; combined journey has twelve ordered cases and 3,243 checks |
| Economy, rewards, contracts and retained compatibility | Thief economy, Phase 5 consumer tests, save/load and contract suites; Adventure controller checks do not imply Adventure player access |
| UI, accessibility and lifecycle | Fresh rendered usability and combined journeys; T10 four-tree captures retained and applicable because runtime/UI content is unchanged; sampled image inspection recorded separately |
| Save protection and repository state | Per-run fingerprints, baseline comparison and final working-tree checkpoint |

The aggregate report records exact suite counts and accepted commands, including any separately accepted matrix run. Initial failed/aborted runs are excluded. Closeout does not treat historical pre-tuning DPS values as current results.

Final acceptance: **91 distinct suites, 93 accepted runtime executions and sixteen static checks**. This includes 83 regression suites, eight headless journeys and two rendered reruns. The fresh mixed/gear matrix contains 576 scenarios; both roles are covered in twelve combined player flows.

## Evidence and reproduction

- [Final summary](../project/reports/p6_m5_t11/summary.json)
- [Full sweep results](../project/reports/p6_m5_t11_regression_final/summary.json), with the two superseding passes explicitly selected in the final aggregate: [mixed/gear matrix](../project/reports/p6_m5_t11_matrix/summary.json) and [Practice combat view](../project/reports/p6_m5_t11_view_fixed/summary.json)
- [Eight headless journeys](../project/reports/p6_m5_t11_journeys/summary.json)
- [Rendered journeys](../project/reports/p6_m5_t11_rendered/summary.json)
- [Sixteen static checks](../project/reports/p6_m5_t11_static_final/summary.json)
- [Visual inspection and limitations](../project/reports/p6_m5_t11/visual_review.json)
- [Protected files](../project/reports/p6_m5_t11/isolation.json)
- [Repository checkpoint](P6M5_T11_Repository_Checkpoint.json)

```powershell
python tools/p6/check_m5_t11.py --run regression
python tools/p6/check_m5_t11.py --run journeys
python tools/p6/check_m5_t11.py --run rendered
python tools/p6/build_m5_coverage_ledger.py
python tools/p6/check_m5_t11.py
```

The final command reconciles existing runtime reports, reruns static checks and verifies current source/report hashes. Visual inspection is a recorded human-style review of sampled frames, not an automated assertion that every frame looks correct. The checkpoint records HEAD, working-tree status and source hashes; it does not create a commit or publish the repository.

## M6 starting work

1. Define balance objectives and acceptable differences across point budgets, short/long fights, subclass roles and mixed builds before changing coefficients.
2. Use the [D023 subclass protocol](P6_Subclass_Balance_Protocol.md) and its sixteen fixed builds / independently optimized 30- and 120-second rotations as the current comparison baseline. Preserve its separate 200-seed validation cohorts and BD2 at 21 points. Shadow leads the recorded 21/35-point windows; sustained Thief differs materially from its short-window result. These are scoped neutral-dummy observations, not universal rankings.
3. Plan representative enemies, defenses, progression and economy scenarios. Boss/mechanic/resource evaluation was excluded from the earlier protocol; specify that new scope explicitly rather than treating it as already covered.
4. Establish Adventure progression/release requirements and acceptance gates before enabling Adventure. Preserve save/revision compatibility and legal allocation rules.
5. Propose tuning from measured evidence, implement approved changes, then rerun focused and cross-tree regression. Keep final presentation work with M7.

## Remaining work and owners

| Owner | Work and acceptance boundary |
| --- | --- |
| M6 | Numerical balance, enemy/difficulty progression, Poison supply, theft/gold ramp and caps, normal retrigger below 100%, Watchmen comparison and Adventure enablement planning. Current coefficients are an approved provisional baseline. |
| M7 | Crowded damage-popup overlap, final icons/effect cues, readability/accessibility completion and audio/lifecycle polish. Preserve the accepted tree layout and Icon Lab assignments. |
| M9 | GLES3 shader-initialization messages, root-certificate environment diagnostics, clean engine teardown and packaging/export verification on target hardware. Rendered interaction tests and sampled images do not substitute for export qualification. |

No unresolved content-implementation question is silently deferred as balance work. New mechanics proposals require their own documented contract and validation.
