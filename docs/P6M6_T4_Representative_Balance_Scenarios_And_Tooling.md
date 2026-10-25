# P6M6-T4 — Representative balance scenarios and tooling

**2026-10-07 — Three-point contract rule adopted (P6M6-D005):** User approved three talent points per completed contract as the permanent rule. Tavern rewards remain 1/0/4/5 and the total cap remains 45, reached after C12. Existing earned points are preserved; future claims use the new rule. The [experiment](P6M6_T4_Three_Point_Contract_Experiment.md) is now the relevant progression comparison; its Shadow/Bladedancer findings remain tuning inputs.

The report below describes the original measurement run. Its reproduction commands require the historical five-point source baseline; guarded runners prevent overwriting those reports under the newly adopted rule. Historical preservation verifiers intentionally detect the subsequent source changes.


Status: **Complete — 2026-10-07.** Authority: [T2 / D004](P6M6_T2_Difficulty_And_Progression_Targets.md).

## Deliverables and scope

The versioned [scenario manifest](../project/data/balance_lab/m6_t4_protocol.json),
[Godot runner](../project/scripts/tools/run_m6_t4_matrix.gd) and
[report verifier](../tools/p6/check_m6_t4.py) extend the historical subclass protocol
with actual encounters and conditional reward/shop acquisition. The historical
protocol, gameplay values, Adventure access, content revision and saves are preserved.

Each main tree has nine acquisition trajectories: every other secondary, each with
three acquisition policies. Each trajectory exports 16 exact snapshots: four Tavern
entrances, C1/C4/C6/C8/C10/C11/C15/C20 entrances, and before/after C9 and C10 shops.
Incoming Tavern budgets are 0/1/1/5; contracts begin at 10, gain five per completion,
and cap at 45. Primary-first 35/10 allocation follows the historical priorities and
legal gates. At C10, 33/12 and 24/21 legal respecs reuse the acquired equipment.
The exported rank maps, serialized gear, gold and ledger offsets identify each build.

Full checkpoint coverage uses Bladedancer/Thief, Thief/Assassin, Assassin/Shadow and
Shadow/Bladedancer. C10 expands to all twelve ordered pairs: all three equipment
policies at 35/10, and the typical policy at 33/12 and 24/21. This is a representative
matrix; it does not exhaust every rank distribution or build combination.

## Obtainable equipment and gold

Acquisition starts from the real starter and zero gold, uses seed 84001, accepts the
first legal offer and follows the first connected branch. Real reward, inventory,
shop-price, purchase, sale and equip APIs generate the fixtures. Every preceding
fight is **conditionally marked won** to isolate acquisition from survival. No
combat theft or overkill income is added to those trajectories. Reward modifiers
still apply through the live reward API. These are feasible conditional histories,
not evidence that a build survived to the checkpoint.

| Policy name | Loot choice | Shopping |
| --- | --- | --- |
| weak | First proxy-improving identified item | No purchases |
| typical | Best proxy-improving identified item | Up to one improving affordable item per shop |
| strong | Best proxy-improving identified item | Up to six improving affordable items per shop |

All policies sell displaced/inventory items through the live API, skip unidentified
choices, and perform no rerolls. The proxy combines resolved weapon/elemental damage,
attack speed and crit; elemental weights are 3 for Assassin, 1.5 for Shadow and 0.5
otherwise. It never scores the validation enemy. The labels describe acquisition
effort, **not gear percentiles or guaranteed power ordering**. A conserved gold stash
can outperform aggressive purchases. One acquisition seed cannot establish the
population's typical gear. T7 expands acquisition seeds, theft/overkill income,
spending strategies and poor-loot recovery before making economy claims.

## Enemy and macro selection

Base routes use seed 7001 at all eight contract checkpoints. Six additional routes,
selected deterministically from seeds 85001 onward, cover every route template.
Each route contributes its first node of each combat role; native generated payloads
supply HP, defenses, mechanics and duration. The exports retain template, route seed,
node and whether every path crosses that node. Mandatory flags describe that route,
not every possible offer. Four authored Tavern encounters and a separate 26-second
current-content Watchmen control are included. The legacy Watchmen measurement stays
in T3. Generated fights remain at their native durations, including outliers from the
preferred timing ranges; no enemy values are adjusted to make a measurement pass.

Reasonable macros are fixed in the manifest and filtered to unlocked skills, with
Stab fallback. Candidate search compares those macros, the primary tree's historical
30/120-second optimized macros, and six explicit counter-patterns, also filtered for
legality. Mean damage across training seeds 101–104 selects a winner before any
held-out scoring. This is bounded search, not global optimization. A searched macro
can be identical to the reasonable one or perform worse on unseen seeds.

Twenty validation roots (92001–92020) use the live combat seed derivation with each
fight key and attempts 0/1. Each case reports reasonable and searched first attempts,
damage distributions/margins, and success within two attempts. Failed reasonable
attempts retry using the frozen searched macro; failed searched attempts keep that
macro unchanged. Gear and ranks stay fixed, while stolen gold is retained and stats
re-resolve as in the live retry. Thus the searched arm is the unchanged-macro retry
control; the reasonable arm permits macro-only adaptation. No free in-fight respec
or additional purchases are assumed. Tavern's within-two metric is diagnostic even
though the first live Tavern encounter allows unlimited retries.

Every first-attempt sample records its seed, damage, win, casts, Poison tick events,
trigger candidate count and retained theft; retry damage/outcome are separate fields.
Search candidates and scores remain in the result. Twenty seeds give 5-percentage-point
resolution and substantial uncertainty: even 20/20 has an approximately 84% lower
bound for a two-sided 95% Wilson interval. These samples identify follow-up cases;
they cannot certify a 99% target. Compare paired roots within the same case. Do not
pool different enemies into a purported normal Adventure completion probability.

## Verification and reproduction

From the repository root in PowerShell (substitute the local Godot executable):

```powershell
$engine = 'F:\Applications\Godot\Godot_v4.7-stable_win64_console.exe'
foreach ($tree in @('bladedancer','thief','assassin','shadow')) {
    & $engine --headless --path project -s res://scripts/tools/run_m6_t4_matrix.gd -- "--tree=$tree" --phase=fixtures
    if ($LASTEXITCODE -ne 0) { throw "Fixture pass failed: $tree" }
    & $engine --headless --path project -s res://scripts/tools/run_m6_t4_matrix.gd -- "--tree=$tree" --phase=matrix
    if ($LASTEXITCODE -ne 0) { throw "Matrix pass failed: $tree" }
}
python tools/p6/check_m6_t4.py
```

Outputs live in [p6_m6_t4](../project/reports/p6_m6_t4/). The verifier rejects partial
matrix files and insufficient coverage, checks budget totals, affordable purchase
arithmetic, seed separation, sample totals, replay/Practice parity flags, shopping
pairs, tree roles and templates. Godot checks legal allocations/unlocks, malformed
budget/duplicate-role rejection, gear round trips, route validity and resolver output.
Each matrix case repeats a seeded simulation and compares damage/cast count/final RNG;
then runs the same fixture through TrainingRoomState and compares damage.

Acquisition and Practice use report-local save paths. The original protected-file
manifest is an evidence snapshot for this checkout: the verifier checks all listed
pre-existing runtime/content and discovered save/Enigma files. On another machine,
that absolute-path preservation audit must be recreated before work; it is not a
portable gameplay fixture. verification.json fingerprints source, protocol and outputs.
Expected Windows certificate-store and engine shutdown leak diagnostics are retained
in logs; a passing tooling run does not close those M9 environment/lifecycle issues.

## Interpretation and downstream handoff

Read [results](../project/reports/p6_m6_t4/results.md) and
[all case measurements](../project/reports/p6_m6_t4/summary.csv) alongside the raw
per-tree matrix files. The report lists pre-C10 typical-policy cases still failing
held-out roots after adaptation, plus C10 representative first/retry outcomes.
Those are investigation candidates, not accepted exceptions or automatic tuning orders.

T5 should reproduce the named weak cases, inspect the exact ranks/gear/macro and
compare alternatives before proposing numerical changes. T6 owns enemy and Watchmen
responses; T7 owns representative acquisition distributions and gold/spending effects.
T8 owns Adventure integration. T9 must run real, uninterrupted seeded Adventures with
actual failures/retries and rewards, then hands-on checks: record route choice,
checkpoint gear/stash, shop decisions, macro changes, retries and where progression
feels obstructed. Use the same root when comparing a proposed change, expand cohorts
when variance could change the decision, and retain both successful and failed runs.
T10 applies D004's practical experience standard and records explicit exceptions.
The Road and indefinite post-C30 scaling remain future work.

## Closeout evidence — 2026-10-07

All four fixture passes and all four matrix passes exited successfully. The final
verifier passed: **576 snapshots, 728 cases, 29,120 first-attempt samples plus failed
attempt retries, and 190,124 engine assertions**. All twelve ordered tree pairs,
three allocation families, six route templates and pre/post shop comparisons are
represented. Each of the 728 cases passed deterministic replay and Practice damage
parity. All 1,026 protected files retained their original SHA-256 hashes.

The typical-policy baseline flags Tavern T0/T1/T3 for Bladedancer and Thief, and
C4/C6 bosses for Shadow, for investigation after macro adaptation. The representative
Bladedancer/Thief C10 boss records 0/20 within two attempts in both macro arms;
the other three representative C10 boss cases record 20/20. This is matchup evidence
under the saved fixtures, not a class ranking or proof of general C10 readiness.
No tuning was applied. T4 is complete; T5 player-power investigation is next.

Follow-up: the [three-point contract experiment](P6M6_T4_Three_Point_Contract_Experiment.md) compares the candidate with this preserved five-point baseline. The candidate was subsequently adopted under D005.
