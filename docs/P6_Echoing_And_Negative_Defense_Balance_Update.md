# Echoing Toxin and negative-defense tuning — P6M5-D015

Implemented 2026-10-04 at the user's request.

- Echoing Toxin retains up to two actual stacks depleted per natural or forced Poison tick, but removes its damage bonus at every rank. It adds 40/30/20% suppression, additive with enemy suppression, increasing natural tick intervals. Forced ticks do not wait for or reset the clock. Resonance retains three-stack fuel and +5% damage per rank, alongside Echoing suppression.
- Negative block and negative absorb now supply 0.1 base damage per point below zero to originally physical and elemental packets respectively. Existing scaling, conversion, mitigation and final rounding order is unchanged.
- Base Poison stays 8; Assassin intrinsic stays +5, with +0.5 per primary point. Blinding Powder still grants invested Assassin points (10 in the user's build), with the existing 50-stack cap. Virulent retains its ten-second cooldown.

The live exact 10-point builds, Crude Dagger, blank dummy and 30-second window produce 200-seed means of **39.5853 Bladedancer / 31.2873 Thief / 59.0227 Assassin DPS**. Practice and Balance Lab seed-1 parity passes for all three. [Results](../project/reports/balance/ten_point_d015/summary.json). The full 35-point Assassin reference macro now averages 245.12117 DPS; this is not broad balance acceptance.

Focused coverage includes all Echoing ranks, additive enemy suppression and IAS, empty/partial fuel, natural/forced ticks, Resonance, critical packets, negative block/absorb rounding and conversion, live builds, cooldown scheduling and presentation. See [final regression](../project/reports/p6_d015_final/summary.json) and [save isolation](../project/reports/p6_d015_final/isolation.json).

Stable content IDs and save revision remain unchanged. The previous release manifest is archived as `shadow_release_manifest_pre_d015.json`. Historical balance experiments are superseded; the live reproduction runner is the current baseline. M5-T9 remains next and is not closed by this tuning.

Validation: all 13 focused regression suites pass; protected saves and sibling Enigma files are unchanged. Shadow release, Assassin predecessor-chain and content-registry static checks pass. Existing certificate-store and process-exit resource warnings remain.
