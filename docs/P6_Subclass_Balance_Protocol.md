# Rogue subclass balance protocol

This protocol uses current live content and fixed allocations at 1, 10, 21 and 35 points for Bladedancer, Thief, Assassin and Shadow. It changes rotations only; it never changes gameplay values or player saves. User-approved scope excludes boss/mechanic and resource evaluation.

## Test conditions

- Primary subclass only; no secondary tree.
- Crude Dagger only; no armor or other equipment.
- Training dummy with no defensive mechanics. Test HP is raised so presentation does not obscure the full measurement window.
- Zero starting stash for each fresh fight. Existing live in-combat gold rules remain active, including Gilded Blade.
- Separate **30-second** and **120-second** windows. Optimize each independently rather than treating the longer test as a replay of the short macro.
- Fixed baseline and final candidates use seeds **1–200**; the winning candidate is validated separately on **201–400**.
- Report mean DPS, direct/Poison breakdown, variability and exact macro. Validate the winner against the standard Balance Lab adapter and Practice at seed one.

## Builds

The canonical fixture is [subclass_protocol.json](../project/data/balance_lab/subclass_protocol.json). All talent ranks and baseline macros are explicit there. At 35 points, all primary-tree talents are maxed and the sum is checked against 35.

One-point baselines:

| Subclass | Allocation | Baseline macro |
|---|---|---|
| Bladedancer | Whetstone 1/5 | Quick Cut |
| Thief | Keen Eye 1/5 | Steal |
| Assassin | Precision 1/5 | Venom Jab → 2 × Heavy Slash |
| Shadow | Coated Weapons 1/1 | Stab |

Ten-point and 21-point allocations retain the user's previously tested builds. Shadow 10 uses Snake Oil 4, Coated Weapons 1, Deception 5. Shadow 21 uses Snake Oil 4, Coated Weapons 1, Deception 5, Death Touch 3, Death Pact 2, Shadow Mastery 2, Dusk Strike 1, Death Blade 2 and Umbral Presence 1. The completed D023 run retains **BD2** at 21 points: 240.17/240.54 DPS in the 30/120-second windows, versus BD1 at 163.83/173.80. BD1 remains archived as a comparison candidate. The canonical fixture now contains all sixteen builds and the reference optimized macros for both windows.

The request's “Heavy Strike” is the existing **Heavy Slash** skill.

## Rotation search

All unlocked common Rogue and primary-tree skills are eligible. Macros contain at most ten slots. Repeating copies of an identical cycle are reduced to that cycle. The deterministic search seeds historical rotations, enumerates short legal sequences, tests skill-specific stack/cooldown patterns, samples longer sequences and mutates the strongest candidates. Historical DPS values are not reused.

The initial screen uses three seeds; twenty candidates are rescored on twelve seeds. Three finalists, the fixed baseline and the previous window's winner are evaluated on 200 seeds. The best mean becomes the candidate, with another 200 seeds used for validation. The baseline remains eligible so optimization cannot replace it with a worse measured candidate. This is a reproducible heuristic search, not proof of a global optimum. Small gains and complicated cycles should be judged against the variation and validation results.

## Run

From the repository root, run the Godot console executable headlessly with the project path, a workspace log path, and `--script res://scripts/tools/run_subclass_balance_protocol.gd -- --tree=SUBCLASS`. Valid names are `bladedancer`, `thief`, `assassin`, and `shadow`. Workers can run concurrently because each uses separate report and isolated-save paths.

Outputs for the first run are under [subclass_protocol_d023](../project/reports/balance/subclass_protocol_d023). The original fixture is archived as `protocol_used.json`; per-case reports retain exact allocations, durations, seeds, source-release hash, finalists, validation, baseline and optimized macros. Each worker writes a completion summary. The completed [results report](../project/reports/balance/subclass_protocol_d023/results.md) contains every allocation, all 32 optimized macros, DPS, validation, variability and damage breakdown. [Machine-readable results](../project/reports/balance/subclass_protocol_d023/results.json) retain the full evidence. To reproduce the original 17-candidate run, add `--protocol=res://reports/balance/subclass_protocol_d023/protocol_used.json` to each worker command. After all four workers finish, run `python tools/p6/summarize_subclass_protocol.py`; `--select-bd21` additionally updates the canonical fixture after checking that the same BD allocation wins both windows. A canonical sixteen-build rerun reuses the archived omitted BD21 comparison after verifying its release hash.

## Current balance findings

Shadow leads at 21 and 35 points in both windows. Its strongest 35-point 120-second candidate reaches 1,011.28 mean DPS (1,007.87 on independent seeds), mostly direct damage (956.98 direct, 54.30 Poison). Thief overtakes Assassin and Bladedancer in the 120-second tests at 21 and 35 points under live Gilded Blade rules despite zero starting stash. The 30-second result alone does not describe sustained subclass balance. These observations are a baseline for future tuning; the protocol run changes no live gameplay values.
