# Shadow Touch and Shred — P6M5-D021

**Superseded in part by D022:** Touch now grants +1 base physical damage per consumed Poison. D021 duration, cooldown, attack speed and Dusk Strike changes remain live. The +2 coefficient and DPS values below are historical. See [current verification](P6_Shadow_Touch_Damage_Update.md).

User-approved live changes (2026-10-06):

- Dusk Strike retains independent Shred application on positive Decay application and adds +10 Shred Value. With the default 10, each stack reduces armor by 20. This is additive with gear and other talents and applies to all Shred sources while allocated.
- Touch of Darkness consumes all actual Poison and grants +10% increased attack speed and +2 base physical damage per consumed stack for 12 seconds. Both bonuses share the independent instance lifecycle, expire together, and never mutate the build. Its cooldown remains 30 seconds; zero consumption grants nothing.
- Beguiling Presence remains +1 base elemental damage per actual Decay consumed for 10 seconds, with a 30-second cooldown. Earlier shorter cooldown and larger elemental bonus trials were not promoted. D020 and D019 changes remain active.

The screenshot's 21-point allocation is unchanged: Snake Oil 4, Coated Weapons 1, Deception 5, Death Touch 3, Death Pact 2, Shadow Mastery 2, Dusk Strike 1, Death Blade 2, Umbral Presence 1.

Macro: 2 × (Beguiling Strike → Distilled Corruption → Death Strike) → Touch of Darkness → Beguiling Presence.

Live Balance Lab: Crude Dagger only, zero starting stash, zero-defense dummy, 30 seconds, seeds 1–200. Mean **184.28617 DPS** (154.45117 direct, 29.835 Poison), exactly matching the isolated trial. Practice/Balance Lab seed-one parity passes. [Live verification](../project/reports/balance/shadow_twenty_one_point_d021_live/summary.json).

Focused checks cover full and partial allocations, secondary-tree resolution, independent Touch instances, exact 12-second expiry of damage and attack speed, zero consumption, Poison cadence phase preservation, combat presentation, journeys and display. [Main suites](../project/reports/p6_d021_shadow_balance/summary.json); [updated boundary suites](../project/reports/p6_d021_shadow_boundaries/summary.json).

Previous D020 release metadata is archived as `shadow_release_manifest_pre_d021.json`. Existing compatible revisions, save IDs and legacy resources are preserved. Source hashes and immutable predecessor checks are refreshed for D021.
