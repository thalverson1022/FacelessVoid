# Pick Pocket cooldown — P6M5-D016

User-approved live change: Pick Pocket has an 8-second cooldown starting at cast completion. Duplicate slots share it; a cooling slot spends 100 ms and gives no gold or effects. Cast time stays 1800/800 ms and theft stays ten raw gold. Mug, Steal, Keen Eye and all other Thief tuning remain unchanged.

Four focused suites pass: cooldown scheduling (including actual Pick Pocket duplicate slots, gold, and tooltip), full Thief, combat presentation and integrated shared mechanics. [Regression](../project/reports/p6_d016_final/summary.json); [protected saves unchanged](../project/reports/p6_d016_final/isolation.json).

The updated 20-point Bribery build, Crude Dagger, 30-second blank dummy and 200 seeds produces **112.95867 DPS** for Pick Pocket / Mug and **101.42317 DPS** for Pick Pocket / Steal / Mug. Live Practice/Balance Lab seed-1 parity passes with no diagnostic overrides. [Results](../project/reports/balance/thief_pick_pocket_d016_live/summary.json).

No content IDs or save revisions changed. Previous manifest archived as shadow_release_manifest_pre_d016.json. All other Thief experiments remain unimplemented.
