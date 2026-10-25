# Blinding Powder and defense caps — P6M5-D013

Implemented 2026-10-04 at the user's request.

- Blinding Powder base cast: **1200 ms**, increased from 1000 ms. Minimum remains **500 ms**; cooldown remains **zero**. Ordinary attack speed and slow apply.
- Penetration and Potency each cap at **50 stacks**, down from 100. The shared defense-debuff state enforces the cap for ordinary applications, bonus stacks, doubling, repeated casts and Death Pact's exact Consume grants. Overflow still refreshes the timer; expiry restores the starting defense.
- D012 remains in effect: cooldowns begin at cast completion; each point of negative block/absorb contributes 0.5 appropriate base damage. No talent rank coefficient changed.

Skill and status tooltips, the current combat reference, coverage ledger and onboarding are updated. Save identities are unchanged. The prior release manifest is archived as `shadow_release_manifest_pre_d013.json`; its D012→pre-D012 provenance is retained.

## Verification

**11 focused suites pass**, covering the new [cap/timing boundaries](../project/tests/p6_d013_powder_caps_test.gd), full Assassin ranks and combat, Assassin/Shadow boundaries, status consumption, cooldowns, D012 damage behavior and UI descriptions/presentation. [Final results](../project/reports/p6_d013_final/summary.json), [save isolation](../project/reports/p6_d013_final/isolation.json), [static release checks](../project/reports/p6_d013_static/summary.json).

The dedicated test verifies both statuses at 49→50, ordinary doubled grants versus exact Consume grants, capped timer refresh, expiry, repeated Powder 35→50, 1200 ms unmodified timing and the unchanged 500 ms minimum. Existing expected values were updated for the requested timing and cap; no historical balance report was overwritten.

The same 35-point Assassin / crude dagger / 30-second basic-dummy macro averages **408.079 DPS over 200 seeds**, versus **410.17517** after D012. [D013 live results](../project/reports/p6_d013_assassin_balance_live/lab.json). This is one reference macro, not a general estimate of the cap's effect on all builds.

```powershell
python tools/p6/run_foundation_tests.py --report-name p6_d013_recheck p6_d013_powder_caps_test p6_status_interactions_test p6_status_completion_test p6_full_assassin_test p6_assassin_boundaries_test p6_shadow_boundaries_test p6_assassin_balance_live_test p6_combat_presentation_test skill_tooltip_formatter_test p6_d012_combat_tuning_test p6_cooldown_scheduler_test
python tools/p6/check_shadow_release.py
python tools/p6/build_m5_coverage_ledger.py --check
```
