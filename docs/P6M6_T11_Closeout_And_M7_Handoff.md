# M6-T11 closeout and M7 handoff

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

2026-10-08. **M6-T11 Complete; M6 T1–T11 Complete.** This performs the user's requested final verification and closeout. D015 already accepts the retained milestone scope and defers further human balance review. D016 records completion of the authorized technical work; it does not approve new numerical changes.

## Final verification

The [accepted summary](../project/reports/p6_m6_t11_closeout/summary.json) reconciles passing results for **95 distinct suites**, **four rendered executions**, and **ten current static checks**. Failed preliminary runs remain available and are not counted as passes. Every accepted suite's source hash matches the final test file.

- Combat, ordering, effects, Poison, triggers, cooldowns, four complete trees, gold/economy, gear and persistence regressions pass.
- The mixed-build/gear matrix passes all 576 scenarios. Full-content journeys cover twelve ordered tree pairings and 3,243 checks, including rendered execution. These focused journeys are not complete earned Adventure runs.
- Current Adventure lifecycle passes 2,692 checks and 360 save/load roundtrips across twelve ordered pairings: rewards, allocation/refunds, equipment, offers, commitment, retry, terminal loss and revision isolation. Its progression outcomes are synthetic and do not measure victory rates.
- Adventure UI passes 62 checks headless and rendered. Usability passes 152 rendered checks. The updated save/load UI passes real New Adventure, Save & Quit, Resume, abandon and restart flows. Rendered full-content and usability suites include 1280/1600/1920 widths.
- Three representative screenshots were inspected: the 1280-wide archetype guide, 125% text tree view and dense Assassin/Shadow combat. The guide and tree controls remain readable; dense damage popups and effect labels overlap during combat and remain M7 work. This is not final presentation acceptance.
- The accepted T10 snapshot contains 1,115 protected files. **1,111 are byte-identical; only four tests changed.** Gameplay scripts, scenes, resources and project settings are unchanged. The item candidate was never applied.

The runner uses a copied project with separate APPDATA/LOCALAPPDATA per suite. Player saves are not used. Initial/recheck/rendered batch isolation summaries sometimes report `unchanged: false` because authorized test repairs were made in the live workspace while copied runs completed. The [reconciled isolation report](../project/reports/p6_m6_t11_closeout/isolation.json) identifies those test-only changes. No runtime drift is accepted. Existing dirty working-tree changes were retained; no commit or publication was performed.

## Repairs and historical-check reconciliation

Four stale tests were repaired without gameplay changes:

| Test | Resolution |
| --- | --- |
| `combat_screen_test` | The retained legacy Opportunity Strikes resource has unrestricted source skills. Check that resource contract and its 20% Rending Slash tooltip, rather than requiring the redesigned Quick Cut wording. |
| `save_load_ui_test` | Replace M4's disabled-entry assumptions with enabled M6 Adventure. Use the current registry, stable tree IDs rather than array position, and stable class identity after load; preserve the complete save/abandon/restart assertions. |
| `p6_core_journey_test` | Keep Practice/Test Mode sentinel preservation. New and Resume are enabled when a save file exists; malformed content is validated when loading, not by the title's file-existence check. |
| `balance_lab_test` | Explicitly classify three legacy unranked Shadow/Poison diagnostic warnings alongside the historical Watchmen warning. Assert zero Poison damage for those legacy fixtures; keep every mechanics check, current ranked coverage and rejection of unexpected warnings. Their old Poison thresholds do not certify current Adventure balance. |

The runner initially rejected four successful scripts whose terminal output lacks a generic PASS/OK word. It now recognizes three exact legacy completion messages and checks the Shadow balance JSON's `passed` flag plus eleven cohorts. All four were rerun successfully; script errors and assertion failures still fail immediately.

Nine inherited static checks pass unchanged: core Bladedancer, mixed builds, Shadow/Assassin/Thief design review, content conversion, tree display catalog, identity manifest and build fixtures. The tenth is `check_m6_closeout.py`: final inventory, accepted values and exact comparison with the retained T10 protected snapshot.

Seven M5 historical checks are **superseded, not reported as passing**: Shadow/Assassin/Thief/Bladedancer release hashes, the compatibility-resource hash check, M5 coverage-ledger freshness, and Bladedancer review's nested ledger-freshness call. Their frozen predecessors predate accepted M6 registry, progression and resource changes. Their failure logs remain under `p6_m6_t11_static`; the old manifests and historical ledgers were not regenerated to hide the differences. The current M6 snapshot check enforces byte-for-byte runtime identity with accepted T10, and current suites verify behavior. The separate old `p5m3_existing_gear_wiring_test` remains superseded test debt: use current five-slot, stat aggregation, Legendary, gold and persistence suites instead; do not use its old crit/Wyvern/save-envelope expectations as current gates.

## Retained final values and rules

| Area | Accepted baseline |
| --- | --- |
| Content | Four Rogue trees; 44 talents / 140 ranks. Adventure `p6.adventure.1`; Practice/Test Mode `p6.playable.shadow.1`. |
| Progression | Tavern points 1/0/2/3; six at Tavern exit. Three per completed contract; cap 45 after C13. Existing earned points remain preserved. |
| Steal (D007) | 1100 ms base, 650 ms minimum; damage/theft unchanged. |
| Drunk Buddy (D008) | Armor 140, HP 155, Poison resistance 10%, duration 18 seconds; rewards unchanged. |
| Other enemies (D010) | Retain current values. Earlier short-window HP and stacked-counter boss nerfs remain rejected. |
| Bandit Blade | 0.1 physical damage per gold; no experimental soft cap or diminishing-return curve. It remains a build-resolution snapshot. |
| Persistence | Fresh `user://adventure_p6_m6.json`; legacy `user://save.json` preserved without migration. Practice remains isolated. |
| Commitment/counterplay | Inspect tags and routes; Back returns to offers before the first fight commitment. Refunds between contracts; fixed primary/secondary roles. Legal gear/sequence adjustments remain available. |
| Prototype boundary | Finite 30-boss catalog and C30 scaling plateau retained. The Road and true endless progression remain future work. |

The game is intended to be hard. Optimization, coherent synergies and informed matchup choices should matter; weak choices may fail. Heavy stacked counters can be intentional. Universal wins, or removing every severe matchup, are not acceptance goals. Diagnostic percentages do not replace this design direction.

## Evidence carried forward and downstream owners

| Work | Owner / next action |
| --- | --- |
| Icons and UI feedback | M7: preserve approved tree layout/Icon Lab mappings; finish inventory, actual-size icon readability, skill/effect descriptions, dense popup/effect prioritization, accessibility and audio lifecycle feedback. Use the captured crowded-combat frame as an explicit review case. |
| Human difficulty and balance feel | User playtesting alongside M7, per D015. Record build/ranks, earned gear and gold, macro, route/tag decisions, seed/checkpoint and retry outcome. Revisit optimized-play tension, confusing losses and preparation costs. These playtests have not yet happened. |
| Legendary excess power | Separate next-phase Legendary Item remake. Follow the [remake handoff](P6_Legendary_Remake_Next_Phase_Handoff.md). Carry Bandit hoarding/scaling and early usefulness tradeoffs; no candidate curve is prescribed. Re-run earned trajectories after the remake. |
| Severe counter losses | M7 observations and later refinement: distinguish unclear information or mechanics defects from intentional counters before changing numbers. Preserve T6 matched-choice controls and route commitment evidence. |
| Prototype limitations | Future scope: true endless scaling, The Road, catalog expansion. M6 completion does not implement them. |
| Engine/environment qualification | M9: root-certificate-store error, ObjectDB/resource-at-exit warnings and shader/export/clean-teardown qualification. They remain visible in logs and are not script errors. |

T9 retains 192 victory-dependent trajectories and 8,060 fight attempts, earned checkpoint UI evidence and independent checks. T10 retains 133 journeys / 5,393 attempts **across baseline and unadopted candidates**; do not treat candidate passes or endpoints as live balance results. T11 does not repeat those expensive cohorts because runtime/data are identical to accepted T10. Neither automated trajectories nor this closeout claim universal success or completed future human playtesting.

## Reproduction and records

From the repository root with Python 3.12 and Godot 4.7 installed:

```powershell
python tools/p6/run_m6_closeout.py --report-name p6_m6_t11_fresh
python tools/p6/run_m6_closeout.py --report-name p6_m6_t11_fresh_visual --visual --tests p6_m6_adventure_ui_test p6_t10_usability_test p6_full_content_journey_test save_load_ui_test
python tools/p6/check_m6_closeout.py
```

Use a fresh report name: the runner refuses to overwrite evidence. Per-suite timeout is 900 seconds, with immediate termination on script/assertion errors. The default roster is the 83 M5 regression suites, eight journeys and four current Adventure/route/tree-selection suites. Temporary copies are recorded in each `workspace.json` for inspection.

Accepted runs are selected from `p6_m6_t11`, `p6_m6_t11_recheck`, `p6_m6_t11_recheck2`, `p6_m6_t11_visual` and `p6_m6_t11_core_final`. See the [summary](../project/reports/p6_m6_t11_closeout/summary.json), [isolation reconciliation](../project/reports/p6_m6_t11_closeout/isolation.json), [current baseline check](../project/reports/p6_m6_t11_static/current_baseline.json) and [repository checkpoint](P6M6_T11_Repository_Checkpoint.json). Historical failed attempts remain intact.
