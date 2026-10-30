# P6M4-T11 — Regression, closeout and M5 handoff

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

Date: 2026-10-02. Status: **Complete — M4 scoped playable integration and UI validation closed.**

## Accepted scope

The user accepted the T10 talent-tree UI and authorized regression and closeout.
M4 delivers the exact ten-point Bladedancer core, Bladedancer 15 / Thief 5,
and reversed Practice roles through `p6.playable.mixed.1`. Old-core Practice
saves remain compatible. Adventure entry remains disabled and its retained
controller/save implementation uses `p6.compat.1`; fresh-session Test Mode is
the Adventure-flow proxy. Test Mode refunds are allowed between fights during
planning; Adventure retains its between-contracts rule.

The displayed Bladedancer/Thief catalog has 23 talents (13/10), of which six
are playable and 17 are explicitly nonfunctional previews. The full four-tree
inventory is 44 talents / 140 ranks. Display completeness does not promote
preview mechanics or authorize full Adventure release.

## Findings and fixes

1. **Historical compatibility hashes:** all six seeds failed in the ordering
   suite and inherited gold suite. A copy of the committed pre-T2 resolver and
   the current resolver produced identical raw historical event hashes for all
   six seeds. The mismatch against the original fixtures was solely the three
   Icon Lab texture paths serialized inside damage contributions. The helper
   now normalizes those three presentation paths to their historical identities.
   All six original expected hashes pass unchanged. Combat fields, trace/RNG
   assertions, fixtures and gameplay rules were not changed. Evidence:
   `project/reports/p6_m4_t11_baseline/probe.json` and
   `project/reports/p6_m4_t11_compatibility/summary.json`.
2. **Detached playback labels:** `PlaybackControls` created a hidden time label
   without parenting it. Parenting it preserves the appearance and frees it with
   the control. The T10 headless and rendered runs now have no CanvasItem,
   texture or font RID leaks. A new lifecycle test enters Practice and Test Mode,
   opens their trees and destroys the game three times, with no new orphan nodes.
3. **Inherited test expectations:** the rotation-cap and Practice fight tests
   now exercise the accepted direct-add/hover and explicit removal interactions.
   The Practice armor comparison uses an explicit Bandit Blade instead of an
   unarmed one-damage floor and resolves the current ranked stats. The old combat
   screen test expects the accepted content-sized talent panel. The save UI test
   asserts Adventure/Resume remain disabled, then exercises retained compatibility
   controllers directly; it does not claim player access to Adventure.
4. **Packaging audit:** the compatibility checker now recognizes the exact six
   separately scoped M4 resources. All 79 compatibility resource hashes remain
   unchanged, the compatibility allowlist is unchanged, and unexpected files
   still fail validation. Runtime tests validate the playable registry separately.
5. **Practice duration regression:** a prior window-width replacement had also
   changed milliseconds/seconds conversion and gear editor limits from 1000 to
   940. Restored all three time conversions and the original ±1000 gear limits;
   only the two intended talent-window dimensions retain 940. The existing
   fight-setup test caught a displayed-duration mismatch and now verifies that
   entering 35 seconds produces 35000 ms. Its random-fight fixture uses an
   unlocked base skill instead of assuming a legacy intrinsic Quick Cut grant.
   Evidence: `project/reports/p6_m4_t11_duration_verified/summary.json`.

The inherited Practice entry test also follows the accepted Save Setup header
placement, and the build-panel test uses the current slot tooltip/removal action.
The legacy combat-screen test created a standalone RichTextLabel for an assertion
and never freed it. It now releases that test-owned control; this was a test
cleanup defect, not an additional gameplay UI change.

## Final validation

- [60 regression suites](../project/reports/p6_m4_t11_final/summary.json): all pass.
  Coverage spans build/progression, save boundaries, retained Adventure controllers,
  Practice, contracts/rewards, deterministic replay, shared combat mechanisms,
  exact core/mixed journeys, tree/skill UI and icons.
- [Protected-file isolation](../project/reports/p6_m4_t11_final/isolation.json):
  unchanged. The initial 59-suite sweep also preserved protected files; its six
  failures are retained as diagnostic history, not final acceptance evidence.
- [Seven static checks](../project/reports/p6_m4_t11_static/summary.json): all pass.
  Catalog, identity manifest, allocation fixtures, compatibility resource hashes,
  core/mixed fixture contracts and content conversion are checked separately.
- Rendered core **110**, mixed **174**, and usability **152** checks pass after
  the duration fix. Logs are `p6_m4_t11_cleanup/core-visual.log`,
  `mixed-visual.log` and `visual.log`; captures remain in the established T8/T9/T10
  report directories. No GDScript failures or renderer RID leaks in those runs.
- The three-cycle lifecycle test passes. The final legacy screen-test cleanup
  rerun is recorded separately in `p6_m4_t11_legacy_cleanup/summary.json`.

The final source/report hashes and repository state are recorded in
`P6M4_T11_Repository_Checkpoint.json`. The accepted T10 UI is the M5 baseline.

## Acceptance reconciliation

| T2 cases / area | Accepted evidence and interpretation |
| --- | --- |
| U01–U03: entry, allocation, refunds, unlocks | Test Mode, ranked-build, talent UI, full-tree, core and mixed journeys. The later user-approved between-fights Test Mode refund rule supersedes the original active-contract restriction. Per-tree resets preserve the other tree and prune invalid rotation entries. |
| U04–U05: rotations and descriptions | Skill UI, ten-slot cap, core/mixed journeys and T10 keyboard/edge-tooltip checks. Direct clicks, right-click/Delete removal and hover/F1 inspection supersede the original always-open details/action proposal. |
| U06–U09: event feedback and mixed roles | Combat presentation, core/mixed journeys, effect/scheduler/gold tests. Footwork, Readiness, Dance, shared cooldowns, theft and role-specific scaling retain their reviewed contracts. |
| U10: dense trees | Full-tree display tests and accepted T10 rendering: authored grid, upward tiers, vertical links, two persistent panels, compact skill strip without empty slots, gray unavailable/preview nodes. |
| U11–U13: crowded effects, caps, playback | T10 synthetic overflow/cap checks plus presentation and journey checks; contributions and combined totals are distinct. Crowded floating combat text still belongs to the M7 presentation pass. |
| U14: isolation and persistence | Core/mixed journeys, persistence/boundary suites and protected-file fingerprints. Fresh Test Mode does not save/resume; Practice persists separately. |
| U15: usability | 152 rendered T10 checks at 1280×720, 1600×900 and 1920×1080, 125% text stress, keyboard/modal focus, reduced motion. T11 rechecked the rendered Practice and Test Mode trees and busy combat. Small reset buttons and compact tree art are the user's accepted T10 choices. |
| U16: icon workflow | T3's 15 model checks / 26 browser groups, retained assignment integration evidence, current icon-assignment suite and actual T10 screens. No Icon Lab code changed in T11. |

T10 source and screenshots: `project/reports/p6_t10_usability/`;
T11 rendered log: `project/reports/p6_m4_t11_cleanup/visual.log`.
These checks use real game controls with automated input and inspected captures;
they are not a claim that the user personally replayed every acceptance case.

## Remaining warnings and owners

- An empty project SceneTree startup reproduces ten ObjectDB instances / nine
  GDScript resource warnings at shutdown, plus the Windows root certificate store
  warning. The passing T10 rendered run ends with that same baseline; no renderer
  RID leaks remain there. See `p6_m4_t11_baseline/empty.txt` and the rendered log.
- Rapid three-cycle mode teardown additionally reports five MP3 resources and
  playback references at process exit, while the orphan-control check passes.
  See `p6_m4_t11_lifecycle/verbose_console.txt`. M7 owns audio shutdown/fade cleanup;
  M9 must revisit clean engine shutdown before packaging. This is recorded as a
  nonblocking M4 teardown issue, not silently counted as a clean engine log.
- Certificate-store access and any shader-cache permission warning are host/runtime
  diagnostics. No certificate or machine permission changes were made. The final
  T11 rendered run did not reproduce the earlier shader-cache warning. M9 owns
  validation in the intended packaging environment.

## M5 / M6 / M7 handoff

**M5:** plan the implementation sequence for all four approved trees. Start from
the 44-talent / 140-rank inventory and current six playable talents; reconcile
draft prose with the mechanics reference and M3 decisions before authoring each
rank/skill. Complete the remaining Bladedancer and Thief nodes, then the other
trees and their cross-tree interactions. Bind reviewed shared mechanisms, finish
skill-specific descriptors, and validate legal allocation, resets, unlocks,
rotation pruning, persistence and actual effects for each promoted node. Keep
empty automatic slots empty. Remove Preview only when functionality is verified.
Preserve the accepted grid/panel/UI behavior; bring a concrete new content/layout
conflict back to the user instead of reopening the whole design.

**M6:** establish quantitative balance and progression targets, gear cohorts,
enemy matchups, Poison supply and gold ramp/caps. Evaluate normal retrigger below
100% and the inherited Watchmen comparison. Bandit Blade's gold-to-base damage
remains a build-resolution snapshot. Current fixture results are regression
evidence, not balance approval. Adventure enablement needs its planned progression
and release decision, not an incidental toggle during M5.

**M7:** extend assigned art, complete remaining-tree presentation and all new
effect cues, revisit crowded floating text, audio teardown, keyboard accessibility
and readability as the full inventory becomes playable. Preserve user-approved
T10 tree styling. Re-run real rendered stress cases for new content.

## Reproduction

Use `tools/p6/run_foundation_tests.py` with an explicit report name and the test
basenames recorded in the final summary. It isolates save paths and fingerprints
the real Adventure/Practice saves plus sibling Enigma configuration. Each suite
records its exact Godot command. Static checks are recorded in
`project/reports/p6_m4_t11_static/summary.json`.

No gameplay mechanic, balance value, save format, release scope or combat rules
changed in T11. The combat mechanics reference therefore needs no rule revision.
This is a working-tree closeout; no commit, package or deployment was requested.
