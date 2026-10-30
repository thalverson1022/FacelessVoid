# M6 Tavern 1/0/2/3 — rule and balance assessment

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. [Current context](../../P6_Project_Onboarding_Context.md).

2026-10-07. **Rule implemented under P6M6-D006; balance assessment complete.**

The user requested Tavern rewards of **1/0/2/3** so early progression follows skill
unlocks rather than quickly crossing talent-tier milestones. The shared policy and
authored encounter rewards now match. Contracts still award three points and total
earned points still cap at 45. Already earned points remain intact; future claims
use the new rule. No enemy, skill, gear or gold values were tuned.

| Checkpoint | Incoming points | After victory |
| --- | ---: | ---: |
| Mouthy Drunk | 0 | 1 |
| Drunk Buddy | 1 | 1 |
| Tavern Bouncer | 1 | 3 |
| Hired Goon | 3 | 6 |
| C1 | 6 | 9 |
| C4 | 15 | 18 |
| C6 | 21 | 24 |
| C8 | 27 | 30 |
| C10 | 33 | 36 |
| C13 | 42 | 45 |

Test Mode now defaults to a six-point Tavern-exit budget. The explicit 10- and
45-point presets remain for diagnostic builds. Existing ten-point UI fixtures now
request that budget explicitly. Test Mode's special equipment/gold remains a testing
convenience; the balance acquisition runner starts from real starter gear and zero gold.

## Skill pacing

The 1/3/6 cumulative milestones reach one early investment unlock at a time. With
primary-first allocations, all four trees have five available skills entering the
Goon (including Hold and base skills), as before: three points already cross the
second unlock threshold. The difference is fewer talent ranks supporting those skills.

At C1, the sampled Bladedancer, Assassin and Shadow builds have **six available
skills rather than seven**; the Thief sample has six under either schedule. In these
allocations the delayed skills are Rending Thrust, Master of Poisons and Touch of
Darkness respectively. See [exact skill lists](../../../project/reports/p6_m6_tavern_1023/unlock_comparison.json).
These counts describe the recorded allocations and equipment, not every possible build.

## Combat findings

The comparison baseline is the previous **1/0/4/5 Tavern with three-point contracts**,
not the original five-point-contract run. Figures below are successes within two
attempts among the same 20 held-out combat roots, under the typical acquisition
policy and primary-first allocation. A failed reasonable macro retries using the
macro selected on separate training seeds.

| Representative matchup | Previous Tavern | New Tavern |
| --- | ---: | ---: |
| Bladedancer, Hired Goon | 9/20 | 3/20 |
| Thief, Hired Goon | 4/20 | 3/20 |
| Assassin / Shadow, Hired Goon | 20/20 each | 20/20 each |
| Bladedancer / Thief, C1 boss | 20/20 | 0/20 |
| Bladedancer / Thief, C4 boss | 20/20 | 9/20 |
| Thief / Assassin, C1 captain (optional branch) | 20/20 | 2/20 |
| Shadow / Bladedancer, C6 and C8 bosses | 0/20 each | 0/20 each |

Thief / Assassin and Assassin / Shadow still clear every sampled base-route boss
through C11 in 20/20 roots. Shadow's existing middle-contract boss problem remains;
Bladedancer now has a clear early-contract concern. The first three Tavern fights
match the earlier raw samples exactly because their incoming budgets are unchanged.
The Goon and C1 findings should be priorities for focused tuning against the intended
smooth-through-about-C10 experience. Changing the reward rule does not close those
balance questions or require reverting the user's desired unlock pace.

Not every outcome gets worse. Thief's C15/C20 representative boss outcomes improve
to 20/20 from 1/20 and 0/20. Both policies are capped then; different acquisition
histories, gear and stash persist after the cap. Do not interpret this as proof that
fewer talent points directly increase combat power.

## Coverage, method and limits

The [runner](../../../project/scripts/tools/run_m6_tavern_1023.gd) uses the live reward rule,
with no counterfactual adjustment. It regenerates all 36 conditional acquisition
histories and **576 snapshots**, then runs **728 cases / 29,120 first-attempt samples**
plus failed-attempt retries. The baseline [T4 methodology](P6M6_T4_Representative_Balance_Scenarios_And_Tooling.md)
otherwise stays fixed: acquisition seed 84001, three loot/shop policies, bounded macro
search on seeds 101–104 and 20 held-out roots, four primaries, twelve ordered pairs,
all six route templates, native enemies/windows, shop comparisons, legal retry state.

C10's primary targets 35, 33 and 24 now produce allocations **33/0, 33/0 and 24/9**.
The first two are duplicate allocation controls at this reduced budget, not distinct
builds. Secondary base intrinsics still apply. C15/C20 sample capped builds. C13 is
covered by the acquisition ledger and progression tests, not a new combat checkpoint.

Equipment policies are acquisition effort proxies, not population percentiles.
Previous victories are assumed to obtain checkpoint gear. One acquisition seed,
heuristic macros and twenty combat seeds identify issues but do not establish real
run-completion rates or certify diagnostic success targets. Actual unlock pacing and
fun still require hands-on observation. Enemy values remain unchanged in this task.

## Reproduction and verification

From the repository root:

```powershell
$engine = 'F:\Applications\Godot\Godot_v4.7-stable_win64_console.exe'
foreach ($tree in @('bladedancer','thief','assassin','shadow')) {
    & $engine --headless --path project --log-file "F:/Data/Claude Projects/Project-FacelessVoid/project/reports/p6_m6_tavern_1023/fixtures_$tree.log" -s res://scripts/tools/run_m6_tavern_1023.gd -- "--tree=$tree" --phase=fixtures
    if ($LASTEXITCODE -ne 0) { throw "Fixtures failed: $tree" }
    & $engine --headless --path project --log-file "F:/Data/Claude Projects/Project-FacelessVoid/project/reports/p6_m6_tavern_1023/matrix_$tree.log" -s res://scripts/tools/run_m6_tavern_1023.gd -- "--tree=$tree" --phase=matrix
    if ($LASTEXITCODE -ne 0) { throw "Matrix failed: $tree" }
}
& $engine --headless --path project --log-file 'F:/Data/Claude Projects/Project-FacelessVoid/project/reports/p6_m6_tavern_1023/unlocks.log' -s res://scripts/tools/run_m6_tavern_unlocks.gd
python tools/p6/check_m6_tavern_1023.py
```

All four fixture and four matrix passes exited successfully. The report verifier
passed **193,908 engine assertions**, complete coverage, budget accounting, replay
and Practice damage parity for every case, identical enemy exports/combat seeds,
and identical first-three-Tavern controls. The unlock comparison passed another 152
checks. Preservation verification found precisely the five authorized gameplay/UI
resource changes; 1,074 captured files remained unchanged, including historical
balance reports and discovered real save/Enigma files. As before, the preservation
manifest is specific to this checkout and intentionally detects later source edits.
Known certificate-store and shutdown resource diagnostics remain in successful logs.

See the [paired comparison](../../../project/reports/p6_m6_tavern_1023/comparison.md),
[all paired measurements](../../../project/reports/p6_m6_tavern_1023/comparison.csv), and
[verification provenance](../../../project/reports/p6_m6_tavern_1023/verification.json).


Eight focused regression scripts passed: p6_build_state_progression_test,
p6_foundation_integration_test (176 budget checkpoints), p6_test_mode_test,
contract_test_entry_test, encounter_reward_test, p6_test_mode_tree_selection_test,
p6_core_journey_test (110 checks), and p6_full_shadow_journey_test (145 checks).
The reward tests cover the unchanged 45-point cap, first thirteen contract grants,
a fourteenth capped claim, duplicate claims, and save/load. UI checks cover the
six-point default and retained explicit ten-/45-point presets and restart choices.
Logs are saved beside the balance reports; run each with the same Godot headless
command using `-s res://tests/NAME.gd` and a distinct report-local `--log-file`.
