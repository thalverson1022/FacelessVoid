# M6-T8 Adventure integration and controlled access

2026-10-08. T8 Complete. Adventure is enabled with all four redesigned Rogue trees (44 talents / 140 ranks). T1–T8 are Complete; T9–T11 remain open. This is integration acceptance; full-run difficulty and hands-on balance acceptance remain T9/T10.

## Adopted behavior

- New Adventure and Resume Adventure are connected to the normal progression flow. New runs start with zero earned talent points and gold and the existing Crude Dagger. Class selection uses the redesigned content registry.
- Adventure uses revision `p6.adventure.1` and `user://adventure_p6_m6.json`. Previous `user://save.json` runs are preserved on disk but cannot resume into the redesigned rules. Start a fresh Adventure; no progress, gold, gear or points migrate. The title explains this when an old save exists. Restart affects only the new slot.
- Practice and Test Mode keep their existing content revision and save isolation. Unsupported, malformed, future and Practice-revision Adventure saves fail without mutating state or their files. Legacy fixtures explicitly retain their historical compatibility registry and reset contract.
- The route map has a scrollable Archetype guide explaining tag tendencies and commitment rules. Offer inspection and return remain available; refunds remain between contracts, with fixed tree roles. Gear and sequence editing retain their existing rules.
- Fixed save restoration of an already committed generated contract: an empty pending-offer list now remains empty rather than being repopulated with the active contract.
- Enemy values, combat formulas, rewards and generator data are unchanged. D007 Steal 1100 ms and D008 armor 140 remain adopted. The T6 nerf proposals remain rejected.

## Verification

Two new suites and twenty existing regression suites passed in an isolated project copy using isolated user-data directories:

- Integration: 2,692 checks, all twelve ordered primary/secondary pairs and 360 save/load roundtrips. Covers Tavern rewards, secondary gating, allocation/refunds, shops/equipment, offers, commitment, retry, terminal loss, contract rewards, revisions and save isolation.
- UI: 62 checks, headless and rendered at 1280×720. Real title/class/subclass signals, first-fight resolution for all four primaries, autosave/resume, guide and restart. Screenshots checked for readable text, scrolling and clipping.
- Twenty existing suites cover persistence, ranked builds, progression, generated routes, map previews, rewards, mixed/full-content journeys and Practice setup. Foundation integration passes 176 checkpoints; full-content journeys pass 3,243 checks. See `regressions.json` and individual logs in `project/reports/p6_m6_t8/`.

The lifecycle suite uses synthetic victory results to reach progression boundaries, alongside real resolver checks. These counts do not represent full-run victories or a balance success rate. The rendered guide checkpoint also uses synthetic progression. Initial foundation execution lacked a scratch report directory; after creating that fixture directory, the suite passed. Accepted evidence retains the successful retry. Certificate-store and shutdown resource warnings remain in logs; accepted runs have no script errors.

Publication is restricted to eleven existing source/test files and two new tests, plus this evidence and status documentation. All 1,110 protected source/data/scene/test hashes are checked before publication; the other 1,099 existing files remain unchanged. Real player saves are not used by tests. A post-publication UI smoke runs with isolated APPDATA; its separate adoption log records the live-source result.

## Next: T9

Run matched complete journeys for weak, coherent and informed optimized policies, using earned gear, spending, legal allocations and tag-based routing. Measure success and failure, optimized damage headroom, weak-choice victories, severe counters, Shadow counterplay and catalog depletion. Preserve the hard-game direction: optimization and synergy should matter, and poor builds or matchups may fail. T10 owns the subsequent hands-on balance acceptance. No numerical approval is pending for T8.

## Adopted-source smoke

The post-publication UI suite passed all 62 checks against the actual project, exiting 0 with isolated test saves. All thirteen adopted source/test files match the verified scratch copy byte for byte. See `adoption.json` and `adoption.log`. Known shutdown ObjectDB/resource warnings remain.
