# M6-T5 player power investigation and tuning proposal

Date: 2026-10-07. Status: **Pending input â€” concrete numerical proposal review.**

The investigation supports one targeted candidate: change Steal base execution from **1300 to 1100 ms**, retaining its **650 ms minimum** and every damage, critical and theft rule. The user approved this value on 2026-10-07. It is now implemented in the live resource; [adoption verification](../project/reports/p6_m6_t5_adoption/results.md) records 4,800 matching live Tavern samples and passing focused/mixed regressions. The investigation below records the pre-adoption evidence.

## Evidence and method

[Results tables](../project/reports/p6_m6_t5/results.md), [verification](../project/reports/p6_m6_t5/verification.json), and the eight JSON reports in that directory retain exact allocations, macros, gear, samples and outcomes. There are 1,221 measurements, 55,320 held-out first attempts plus failed attempts retried, and 843,063 engine checks. All eight engine runs passed; logs retain existing certificate/exit resource warnings, with no script or parse errors. Hash verification confirms 1,068 protected files unchanged, including baseline gameplay and protected saves/reports.

Uses current Tavern 1/0/2/3, three points per contract, cap 45 and playable content registry. Three acquisition policies use actual reward/shop APIs: weak skips shopping, typical permits one purchase per shop, strong permits up to six. These are purchasing policies, not population percentiles. Contract gear histories are fixed conditional histories from T4, assuming earlier wins and excluding combat theft income. Legal entrance respecs are searched without retroactively changing that gear. Tavern confirmation instead reacquires gear along a monotonic legal talent path; it still assumes previous victories.

Training uses roots 501â€“504. Independent search validation uses 96001â€“96040, timing comparisons 97001â€“97060, and fresh Tavern confirmation 98001â€“98100. Failed first attempts can retry using the selected macro and retained theft gold. Low-budget talent search is exhaustive through three points; larger budgets and macros use bounded candidate searches, not proven global optima. Candidate selection is on training data. Primary-only follow-ups separate main-tree investment from victories obtained through a secondary tree.

## Findings

All figures below are wins within two attempts under typical acquisition, not full-run completion rates.

- **Bladedancer:** C1 improved from 0/40 to 40/40 with Wet Stone 5 / Precision Attacks 1. C4 improved from 16/40 to 40/40 with a primary-only allocation. Reacquired Tavern path cleared the Goon 100/100; Drunk Buddy remains 90/100. C10 remained 0/40 in the bounded primary search. No broad player buff is justified by these samples alone.
- **Shadow:** Primary-only allocation search reached C4 35/40, C6 36/40 and C8 40/40. Some mixed winners spent most points in Bladedancer, so they are not evidence that Shadow itself is healthy. Poison-denial encounters remain a T6 focus; do not increase Poison supply or defense reduction solely from the original narrow macro baseline.
- **Thief:** Early Tavern remains weak despite legal allocation/macro search. The independent coherent-path cohort improved Drunk Buddy from 22/100 to 100/100 and Goon from 30/100 to 100/100 with 1100 ms Steal. First-attempt results changed from 9 to 100 and 14 to 99 respectively. T2 stayed 100/100. C1 captain weakness is not solved by this change.
- **Assassin:** Sampled C1/C6/C10/C15 bosses cleared 40/40. No player-power change proposed.
- **Scaling:** Sampled resolved retrigger chance stayed below 100% (maximum diagnostic value 49%). Reports record Poison, shred, unavailable casts and trigger diagnostics; this is not an exhaustive fuel/recursion-cap proof. Late Thief damage greatly exceeds sampled enemy health and needs economy/encounter analysis before selecting a nerf.

## Candidate comparison and scope

On the initial 60-sample typical-policy timing cohort, Drunk Buddy/Goon cleared 13/60 and 18/60 at 1300 ms, 58/60 and 59/60 at 1150 ms, and both 60/60 at 1100 ms. The 1000 ms alternative also cleared both but adds unnecessary power. The fresh 100-sample confirmation supports 1100 ms as the smallest tested reliably successful candidate, not a mathematically optimal breakpoint.

1300 to 1100 ms is a 15.4% reduction in base duration. Minimum duration remains 650 ms. No other Steal coefficient, theft amount, talent, enemy, reward or progression value changes. Typical C10/C15/C20 Thief captain/boss controls and C15 controls with Thief secondary had identical mean damage and theft under 1300 and 1100 ms; their selected strategies do not expose a timing-driven increase. This does not establish universal late-game neutrality. Faster theft where Steal is used may alter later purchases, which these conditional gear histories do not model.

## Follow-ups and completion gate

| Owner | Required work |
| --- | --- |
| T5 | Review 1300â†’1100 ms proposal; if approved, update live resource and affected timing expectations, run focused gold/Thief and cross-tree regressions, and reproduce affected early results using live values. Record decision before closing T5. |
| T6 | Revisit Thief C1 captain, Bladedancer Drunk Buddy/C10 and Shadow C4/C6 poison-denial encounters across additional routes and gear histories. Reconcile Watchmen and encounter parameters. No exception is accepted by this report. |
| T7 | Evaluate cumulative theft, spending, overkill income and late Thief excess damage with real victory-dependent acquisition. Determine whether gear/economy or enemy scaling owns any remaining mismatch. |
| T9â€“T10 | Full-run and hands-on validation; confirm smooth progression toward C10 and review remaining exceptions. |

Adventure remains disabled; The Road and true endless scaling remain future work. No new Practice parity run is claimed here; T4 parity evidence remains separate.

## Reproduction

Run Godot 4.7 headless with `--path project`, an explicit unique `--log-file` under the report directory, `-s res://scripts/tools/<script>`, and arguments after `--`:

1. `run_m6_t5_search.gd --tree=<tree>` for bladedancer, thief, assassin and shadow (requires existing Tavern-1023 T4 fixtures).
2. `run_m6_t5_primary_search.gd --tree=<tree>` for bladedancer and shadow.
3. `run_m6_t5_steal_trial.gd` and `run_m6_t5_tavern_paths.gd` after the four main searches complete.
4. `python tools/p6/check_m6_t5.py` verifies all eight completed reports, sample cohorts, legal Tavern path, and protected hashes, then regenerates results and verification.

The protected hash manifest is a pre-investigation baseline. A later approved gameplay change requires a separately recorded validation baseline; do not silently rewrite historical preservation evidence.
