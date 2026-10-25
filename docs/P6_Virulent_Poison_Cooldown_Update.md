# Virulent Poison cooldown — P6M5-D014

Implemented 2026-10-04 at the user's request: **Virulent Poison cooldown increases from 5 to 10 seconds**, starting at cast completion under D012. Cast time remains 500 ms; each activation still grants five independent charges of double Poison damage. Duplicate slots share the cooldown. The tooltip reads the runtime value.

Five focused suites pass: cooldown scheduling (including actual Virulent duplicate slots and tooltip), status completion, Poison contracts, combat presentation and the live Assassin balance acceptance. [Final results](../project/reports/p6_d014_final/summary.json); [protected saves](../project/reports/p6_d014_final/isolation.json); [static checks](../project/reports/p6_d014_static/summary.json).

The overlap test now uses a three-second tick cadence and a sixteen-second fight so it can exercise two activations under the longer cooldown. The charges/overlap behavior itself did not change. The historical DPS reports remain intact.

The same 35-point Assassin / crude dagger / 30-second basic-dummy macro averages **356.693 DPS across 200 seeds**, versus 408.079 before D014. [New result](../project/reports/p6_d014_assassin_balance_live/lab.json). This is a reference macro, not broad balance acceptance.

The exact previous release manifest is archived as `shadow_release_manifest_pre_d014.json`. Current provenance links that snapshot; save identities and all other tuning remain unchanged.
