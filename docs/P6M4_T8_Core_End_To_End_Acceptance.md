# M4-T8 - Practice Room and core end-to-end acceptance

Completed 2026-10-02. The scoped Bladedancer core passes the complete Test Mode and Practice journeys. M4-T1 through T8 are Complete; T9 mixed-tree integration and role reversal are next.

## Accepted journeys

The new `p6_core_journey_test.gd` instantiates the actual game root, combat screen and Practice scene. It drives rank buttons, skill inspection/Add, rotation selection/reordering, lock controls, contract/map signals, fight controllers, reward selection, retry/restart and mode entry/exit. It also dispatches keyboard input to open a skill dialog and checks focus restoration. Combat results are produced by the real resolver; wins and losses are not fabricated. Rendered mode runs the same assertions with the real viewport, not a separate mock screen. This is automated scene/UI acceptance, not a claim of an independent human playtest.

| Coverage | Result and evidence |
| --- | --- |
| U01/U02 allocation | Practice budget 0 rejects purchase; budget 10 supports Whetstone 4, Rending Slash 1, Fancy Footwork 5. Five-point gate explains rejection. Test Mode rejects active-contract refunds without mutation. Existing talent acceptance covers other invalid edits and focus. |
| U03 unlocks | Seven core skills; empty nine-point slot grants no extra skill. Reset removes unavailable macro entries and names them; buying ranks again does not silently restore the macro. |
| U04 rotation | Persistent inspection/Add constructs Quick Cut, Quick Cut, Parry Strike, Leaping Plunge, Rending Slash. Reordering preserves duplicates. Existing skill acceptance covers ten slots, removal, locks and keyboard actions. |
| U06/U13 playback | Real fights use 1x/2x/4x, Skip and natural completion. Active Practice blocks a second fight; finish clears effects and releases the lock. Fixed-seed retry repeats damage and starting stash. T7 presentation/core suites retain exact Footwork/Readiness/Plunge and expiry-boundary checks. |
| U14 Test Mode | Fresh entry has fixed Bladedancer, ten unspent points, empty rotation and 100 gold. Actual victory deposits rewards once, selects equipment and returns through shop continuation to the route. Actual Hold-only losses exercise Retry, relock, terminal failure and Restart Test Mode. Title, save-and-quit, autosave and abandon preserve saved files. Adventure New/Resume remain disabled. |
| U14 Practice | Actual scene edits autosave; Save Setup works; leaving/reopening restores ranks, ten-point budget, reordered duplicates, gold, fixed seed and target. Reopened state has no stale result/effect/lock, and fights successfully again. Subsequent Test Mode entry/autosave/abandon preserves the saved core Practice bytes. |

The journey waits for outcome controls to appear before taking reward/retry actions, so the authored outcome presentation delay is included. Natural Practice completion waits for its finished signal before checking the released lock.

## Changes made

Practice's Settings reservation was followed by Save Setup in the header child order, placing Save Setup beneath the global Settings button. The reserved space now follows all header actions. The full Save Setup control is visible at the minimum resolution and at both larger targets.

The existing save-boundary test wrote its malformed fixture to the legacy Practice path although the current Practice scene loads the separate core path. It now verifies invalid-file protection at `PracticeSaveSystem.core_save_path`. No save protection was relaxed and no historical combat signature fixture was changed.

The terminal Test Mode header now names Test Mode rather than Adventure. Result content reserves the actual Fight/Combat Log button band, preventing Restart from overlapping those controls. The effects layer sits below the result overlay so it cannot paint over the recap.

The broader combat-screen regression had three stale T6 assumptions: an HBox rather than the wrapping container, click-to-remove rather than explicit Remove, and disabled inspection while locked. These expectations now match the accepted UI while retaining the locked-mutation checks.

No combat rules, numerical balance or playable content changed.

## Validation

[Ten scoped suites pass](../project/reports/p6_m4_t8_verified/summary.json): core journey, talent UI, skill UI, combat presentation, persistence UI, Test Mode, Practice combat view, playback, Bladedancer core and save-boundary integration. The final expanded journey and affected Test Mode/playback/combat-screen suites also [pass](../project/reports/p6_m4_t8_final_closeout/summary.json), bringing coverage to eleven distinct scripts: [110 individual checks](../project/reports/p6_m4_t8_journey/checks.json). [Protected-file fingerprints](../project/reports/p6_m4_t8_final_closeout/isolation.json) confirm Adventure/Practice and Enigma files are unchanged.

The rendered run passes the same [110 checks](../project/reports/p6_m4_t8_journey/visual-checks.json). Eighteen screenshots cover six stages at 1280x720, 1600x900 and 1920x1080 using the existing 1600x900 canvas scaling. Screenshot metadata records window and logical viewport sizes; reduced motion is enabled. Readability and essential action placement were reviewed across the three sizes. The broad 125% text/dense-layout review remains T10.

| Stage | 1280 | 1600 | 1920 |
| --- | --- | --- | --- |
| Test Mode ready | [image](../project/reports/p6_m4_t8_journey/test-core-ready-1280.png) | [image](../project/reports/p6_m4_t8_journey/test-core-ready-1600.png) | [image](../project/reports/p6_m4_t8_journey/test-core-ready-1920.png) |
| Test Mode playback | [image](../project/reports/p6_m4_t8_journey/test-core-playing-1280.png) | [image](../project/reports/p6_m4_t8_journey/test-core-playing-1600.png) | [image](../project/reports/p6_m4_t8_journey/test-core-playing-1920.png) |
| Equipment rewards | [image](../project/reports/p6_m4_t8_journey/test-reward-1280.png) | [image](../project/reports/p6_m4_t8_journey/test-reward-1600.png) | [image](../project/reports/p6_m4_t8_journey/test-reward-1920.png) |
| Terminal loss | [image](../project/reports/p6_m4_t8_journey/test-terminal-loss-1280.png) | [image](../project/reports/p6_m4_t8_journey/test-terminal-loss-1600.png) | [image](../project/reports/p6_m4_t8_journey/test-terminal-loss-1920.png) |
| Practice playback | [image](../project/reports/p6_m4_t8_journey/practice-core-playing-1280.png) | [image](../project/reports/p6_m4_t8_journey/practice-core-playing-1600.png) | [image](../project/reports/p6_m4_t8_journey/practice-core-playing-1920.png) |
| Practice restored | [image](../project/reports/p6_m4_t8_journey/practice-restored-1280.png) | [image](../project/reports/p6_m4_t8_journey/practice-restored-1600.png) | [image](../project/reports/p6_m4_t8_journey/practice-restored-1920.png) |

Fixture: `p6.playable.bladedancer_core.1`; exact core ranks and rotation above; no secondary. Test Mode seed 7, Bandit Blade, first generated Treant Sapling (304 HP, 22 seconds): actual total damage 1512, victory. Hold-only loss coverage uses the same generated target on a fresh entry. Practice uses default unarmed gear and Generated Target, 20 seconds, seed 7 with random seed disabled, configured gold 321 and ten-point budget. Restored rotation is Quick Cut, Parry Strike, Quick Cut, Leaping Plunge, Rending Slash.

Reproduce with `python tools/p6/run_foundation_tests.py p6_core_journey_test --report-name p6_m4_t8_journey_recheck`. For rendered checks, run Godot with `--path project --rendering-method gl_compatibility --log-file <workspace-report-log> -s res://tests/p6_core_journey_test.gd -- --visual`. The journey itself redirects saves to `res://reports/p6_m4_t8_journey`; do not run two copies simultaneously. It recreates only its own isolated core Practice fixture. Logs retain environment certificate-store and renderer/resource cleanup diagnostics; final checks contain no script errors.

## Remaining ownership

T9 owns the exact mixed builds, playable Dance/theft and role reversal. T10 owns full dense-layout, text-scale and accessibility acceptance. T11 owns milestone-wide regression, including the two inherited compatibility snapshot failures established by T7's before/after parity evidence. These suites were not rebaselined or claimed fixed by T8. See the [T7 handoff](P6M4_T7_Combat_Playback_And_Temporary_Effects.md).
