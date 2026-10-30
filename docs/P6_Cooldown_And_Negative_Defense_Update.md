# Cooldown and negative-defense update — P6M5-D012

Date: 2026-10-04. Authority: the user's request to start cooldowns after casting and halve the base-damage benefit from negative Penetration/Potency.

## Implemented behavior

Eligible macro casts now start their cooldown when the cast time completes. A two-second cast with a one-second cooldown lands at 2.0 seconds, becomes available at 3.0 seconds and can next land at 5.0 seconds. Duplicate slots share the deadline. The presentation stream receives a completion-time cooldown event, so no timer appears during windup and the full duration appears at completion, including when diagnostic tracing is disabled.

Existing attempt rules remain: dodge/interruption still spend the cooldown, now measured from completed cast time; missing required resources start none; cooling slots spend 100 ms; triggered repeats/procs bypass and do not restart it. Casts that cannot finish inside the fight window start none. Cast speed and minimum-time effects influence the actual completion time, while later changes do not retime an accepted cast.

Penetration still removes one block per stack and Potency one absorb per stack. After the resulting defense crosses below zero, its damage bonus is now:

- Originally physical base bonus: `0.5 × max(0, −effective block)`.
- Originally elemental base bonus: `0.5 × max(0, −effective absorb)`.

Thus −1 gives +0.5 base, −2 gives +1 and −5 gives +2.5. Fractional base is preserved until the existing final damage rounding. Applicable skill scaling and damage multipliers follow; conversion does not add the destination's bonus a second time. Positive defense, stack grants, caps and debuff durations are unchanged. No talent rank coefficient changed.

## Verification and evidence

The [focused boundary test](../project/tests/p6_d012_combat_tuning_test.gd) checks zero/even/odd negative defense values, both conversion directions, base bonuses before multipliers, long-cast cooldown timing, duplicate slots and presentation at completion and exact expiry. Scheduler tests cover speed/minimum-time effects, dodge/interruption, resource failures, repeat bypass, clipped casts and replay parity. Presentation tests verify no cooldown during Dance's windup.

**74 distinct suites pass.** The [final regression summary](../project/reports/p6_d012_final/summary.json) records every accepted suite and its source run. [Isolation evidence](../project/reports/p6_d012_final/isolation.json) preserves real-save and protected-project fingerprints. [Static checks](../project/reports/p6_d012_static/summary.json) verify release provenance, compatibility resources, display catalog and ledger. Old formula/deadline assertions were updated to explicit new arithmetic; the older result reports remain historical.

The same 35-point Assassin macro, crude dagger only, 30-second basic-dummy fight and 200 seeds now averages **410.17517 DPS**, versus the pre-D012 **498.43950 DPS** (about 17.7% lower). See [new live result](../project/reports/p6_d012_assassin_balance_live/lab.json). This is the combined effect of both requested changes, not a separate attribution study. D010's 5%/5%, Toxic +10%/−10% and primary +0.5 coefficients are preserved.

The 35-point Shadow reference macro now averages **95.01667 DPS**, versus 121.42433 before D012. Shadow reference cohorts are separately saved in [D012 results](../project/reports/balance/shadow_d012/summary.json); [original T8 results](../project/reports/balance/shadow_t8/summary.json) are retained. This follow-up does not close T9 or establish broad balance acceptance.

The exact prior Shadow manifest is archived as `shadow_release_manifest_pre_d012.json`. The current manifest links and fingerprints it under D012; the older Assassin/Thief/Bladedancer manifests remain unchanged. Save IDs and playable revision remain compatible.

## Reproduction

```powershell
python tools/p6/run_foundation_tests.py --report-name p6_d012_recheck p6_d012_combat_tuning_test p6_cooldown_scheduler_test p6_repeat_contracts_test p6_combat_presentation_test p6_status_interactions_test p6_status_completion_test p6_assassin_balance_live_test
python tools/p6/check_shadow_release.py
python tools/p6/check_assassin_release.py
python tools/p6/check_thief_release.py
python tools/p6/check_bladedancer_release.py
python tools/p6/build_m5_coverage_ledger.py --check
```
