# Bladedancer Footwork and Riposte — P6M5-D018

User-approved live buffs: Riposte adds 20% damage per rank per Footwork stack actually consumed by Plunge (rank two: 40% per stack, five stacks: 3x total). Fancy Footwork reduces Plunge cast time by 4% per rank per consumed stack (rank five: 20% per stack), respecting the skill minimum of 500 ms. This is a Plunge cast-time reduction, not general IAS.

The scheduler preview, accepted cast duration, lifecycle magnitude, talent descriptions, and compact/full skill tooltips use the updated values. Footwork remains capped at five with its three-second timer; resources are consumed at accepted cast start.

All seven focused suites pass. Regression covers ranks, minimum timing, expiry boundaries, actual accepted durations, repeat consumption, full allocations, and UI. [Focused suites](../project/reports/p6_d018_final/summary.json); [protected saves](../project/reports/p6_d018_final/isolation.json).

Live reproduction confirms 307.74583 DPS for Dance of Death / Quick Cut / Stab / Quick Cut / Parrying Strike / Quick Cut / Leaping Plunge. It uses full35, Crude Dagger only, zero-defense dummy, 30 seconds, 200 seeds; Practice and Lab seed-one parity passes. [Results](../project/reports/balance/full35_footwork_riposte_d018_live/summary.json).

No content IDs or save revisions change. The D017 release manifest is archived as shadow_release_manifest_pre_d018.json.
