# Shadow Coated Weapons — P6M5-D019

User-approved live change: Coated Weapons adds two base Poison stacks (previously one) to connected Stab and Heavy Slash attacks. Stack extras apply after the base amount and doubling follows extras. Death Blade still suppresses all Stab Poison applications. Talent rank, cost, gate, IDs, and save revisions are unchanged.

Beguiling Strike remains one base Decay. The temporary two-Decay experiment, other proposed Shadow buffs, and prior simulation overrides are not promoted.

Current 10-point testing baseline: Snake Oil 4/4, Coated Weapons 1/1, Deception 5/5; Stab / Heavy Slash / Heavy Slash; Crude Dagger only, no other gear, zero starting gold, zero-defense dummy, 30 seconds. Live Balance Lab averages 36.85133 DPS over seeds 1–200: 13.65133 direct and 23.2 Poison. Practice and Lab seed-one parity passes. [Live results](../project/reports/balance/shadow_ten_point_d019_baseline_live/summary.json).

Four focused suites pass: full Shadow allocation/combat, Shadow boundaries, full Shadow Practice journeys, and combat presentation. Added regression checks both augmented skills, two base stacks, extra stacks applied once, subsequent doubling, and the data-driven two-stack talent tooltip. Existing Death Blade suppression coverage passes. [Test results](../project/reports/p6_d019_coated_weapons/summary.json); [protected save fingerprints](../project/reports/p6_d019_coated_weapons/isolation.json).

The D018 manifest is archived as shadow_release_manifest_pre_d019.json. Prior one-stack Shadow design descriptions are superseded by D019; earlier balance reports remain historical. No player save was changed.
