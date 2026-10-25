# M6-T4 follow-up — Three-point contract reward experiment

**2026-10-07 — Three-point contract rule adopted (P6M6-D005):** User approved three talent points per completed contract as the permanent rule. Tavern rewards remain 1/0/4/5 and the total cap remains 45, reached after C12. Existing earned points are preserved; future claims use the new rule. The [experiment](P6M6_T4_Three_Point_Contract_Experiment.md) is now the relevant progression comparison; its Shadow/Bladedancer findings remain tuning inputs.

The report below describes the original measurement run. Its reproduction commands require the historical five-point source baseline; guarded runners prevent overwriting those reports under the newly adopted rule. Historical preservation verifiers intentionally detect the subsequent source changes.


Status: **Complete — 2026-10-07.** Originally a candidate; now adopted under D005.

This reruns the [T4 protocol](P6M6_T4_Representative_Balance_Scenarios_And_Tooling.md)
with three points per contract, unchanged Tavern rewards and the 45-point cap.
The original five-point runner, manifest and reports are preserved. The experiment
has its own [runner](../project/scripts/tools/run_m6_t4_three_points.gd),
[manifest](../project/data/balance_lab/m6_t4_three_points_protocol.json),
[verifier](../tools/p6/check_m6_t4_three_points.py) and
[report directory](../project/reports/p6_m6_t4_three_points/).

| Entering | Five-point baseline | Three-point candidate |
| --- | ---: | ---: |
| C1 | 10 | 10 |
| C4 | 25 | 19 |
| C6 | 35 | 25 |
| C8 | 45 | 31 |
| C10 | 45 | 37 |
| C11 | 45 | 40 |
| C13 | 45 | 45 |

The candidate reaches the cap after C12; C15/C20 test later capped builds. C13 is
shown for the point schedule, not added to the original combat sampling matrix.

## Method and controls

The acquisition harness claims each conditional victory through the existing reward
API, then replaces the just-granted boss point increase with min(3, remaining cap)
before reallocating talents, selecting inventory items or shopping. It asserts the
underlying policy still grants five, sets the candidate budget, and records every
replacement in the ledger. This avoids changing any gameplay resource or real save.
Reward gear generation uses the pre-allocation talents; temporarily increasing the
unspent budget does not buy ranks. Shop choices then use the candidate allocation.
Tavern grants are untouched. Every incoming contract budget is asserted, including
the transition to the cap. This is a counterfactual harness, not an implementation
or acceptance test of a shipped three-point reward policy.

All 36 conditional acquisition histories are regenerated using the same acquisition
seed, shop/loot policies and branch-selection policy. The exact enemy payloads and
held-out combat seeds must match the original reports. Gear and gold may differ
because fewer talents change equipment scores and reward modifiers. Consequently,
late results can differ even after both schedules reach 45 points.

The original checkpoint coverage, four main trees, twelve ordered role pairs,
three acquisition policies and six route templates remain. At C10, the candidate's
37-point budget changes the three allocation families from 35/10, 33/12, 24/21 to
**35/2, 33/4, 24/13**. The family field remains the primary-point target, not a claim
that both policies spend the same total. Macros are searched independently on the
same four training seeds, then tested on the same 20 held-out roots per case.

All T4 limitations apply: conditional acquisition assumes prior victories; one
acquisition seed is not a population gear distribution; bounded macro search is not
proof of optimal play; twenty combat seeds cannot certify a 99% success target.
Neither percentage changes nor isolated losses automatically justify tuning.

## Reproduction

From the repository root:

```powershell
$engine = 'F:\Applications\Godot\Godot_v4.7-stable_win64_console.exe'
foreach ($tree in @('bladedancer','thief','assassin','shadow')) {
    & $engine --headless --path project -s res://scripts/tools/run_m6_t4_three_points.gd -- "--tree=$tree" --phase=fixtures
    if ($LASTEXITCODE -ne 0) { throw "Fixture pass failed: $tree" }
    & $engine --headless --path project -s res://scripts/tools/run_m6_t4_three_points.gd -- "--tree=$tree" --phase=matrix
    if ($LASTEXITCODE -ne 0) { throw "Matrix pass failed: $tree" }
}
python tools/p6/check_m6_t4_three_points.py
```

The verifier checks the candidate budgets (including post-contract shop snapshots),
real purchase accounting, all case coverage, replay/Practice parity, paired enemies
and seeds, identical Tavern results, and preservation hashes for baseline/runtime
and previously discovered save/Enigma files. It writes comparison.csv/comparison.md
alongside the candidate's raw fixtures, encounters, samples and summary. The original
absolute-path preservation manifest is specific to this checkout.
## Findings

For the primary-first builds under the typical acquisition policy, successes within
two attempts (out of the same 20 combat roots) changed as follows:

| Matchup | Five points | Three points |
| --- | ---: | ---: |
| Shadow / Bladedancer, C4 boss | 3/20 | 7/20 |
| Shadow / Bladedancer, C6 boss | 17/20 | 0/20 |
| Shadow / Bladedancer, C8 boss | 20/20 | 0/20 |
| Shadow / Bladedancer, C6 elite | 20/20 | 3/20 |
| Shadow / Bladedancer, C8 elite | 20/20 | 2/20 |
| Bladedancer / Thief, C10 elite | 20/20 | 0/20 |
| Bladedancer / Thief, C10 boss | 0/20 | 0/20 |

Thief / Assassin and Assassin / Shadow retain 20/20 within-two successes on all
sampled base-route bosses through C11. Shadow / Bladedancer recovers to 20/20 on
the sampled C10/C11 bosses. This is not a uniformly downward shift: allocations,
unlocked macros, gear purchases and enemy defenses interact, and the C4 Shadow
result improves while C6/C8 worsen. The unchanged C10 Bladedancer boss failure
was already present at five points.

The clearest new concern for the intended smooth-through-about-C10 experience is
Shadow's middle-contract progression, with an additional optional C10 elite obstruction for
Bladedancer. The experiment supports investigating those exact rank/gear/macro
combinations before adopting three points without companion adjustments. It does
not establish that three-point progression is intrinsically unworkable or prescribe
an enemy scaling rewrite. The longer talent progression is achieved mathematically;
its effect on enjoyment still needs actual-run playtesting.

Full results: [paired comparison](../project/reports/p6_m6_t4_three_points/comparison.md)
and [all paired measurements](../project/reports/p6_m6_t4_three_points/comparison.csv).


Bladedancer / Thief also falls from 20/20 to 0/20 on the C11 and C15 sampled
bosses. Both schedules have 45 points by C15, so the latter comparison includes
the lasting effects of different gear/acquisition histories, not a remaining
point-budget deficit.

## Verification

All four fixture runs and all four matrix runs exited successfully: **576 snapshots,
728 cases, 29,120 first-attempt samples plus retries, 193,360 engine assertions**.
Each case passed deterministic replay and Practice damage parity. Paired enemy
exports and combat seeds are identical, and all Tavern/C1 raw samples match the
baseline. The original baseline reports, runtime/content and previously discovered
save/Enigma files pass 1,053 preservation hashes. The known Windows certificate-store
and shutdown resource diagnostics remain in logs; this run does not resolve those
existing environment/lifecycle issues. At measurement time the game still awarded five points; D005 subsequently adopted three.
