# Shadow Presence crit and Touch — P6M5-D023

User-approved live changes (2026-10-06):

- Beguiling Presence consumes actual Decay and grants +1 base elemental damage and +2 percentage points of critical chance per consumed stack for 10 seconds. Existing crit chance adds normally; effective crit chance caps at 100%. Bonuses share the independent instance lifetime and expire together. Cooldown remains 30 seconds; zero consumption grants nothing.
- Touch of Darkness is restored to +2 base physical damage per actual Poison consumed, alongside +10% increased attack speed per stack. Both last 12 seconds; its cooldown remains 30 seconds. Dusk Strike retains +10 Shred Value.
- Presence's crit bonus applies to direct macro, triggered and repeated attacks, and Poison ticks only when Critical Poison already permits those ticks to crit. It never enables Poison crits by itself, copies into saved build stats, or changes consumed counts.

The previously selected full 35-point macro remains verified at **473.56033 live DPS**: 2 × (Beguiling Strike → 2 × Distilled Corruption) → 3 × Death Strike → Touch of Darkness. It does not use Presence. A separately verified Presence candidate averages **407.76917 DPS**: Beguiling Strike → 2 × Distilled Corruption → Beguiling Strike → Beguiling Presence → 3 × Death Strike → Touch of Darkness. This is a fixed-macro verification, not a new optimization search.

Both use Crude Dagger only, zero starting stash, zero-defense dummy, 30 seconds and seeds 1–200. Practice/Balance Lab seed-one parity passes for both. [Live report](../project/reports/balance/full35_comparison_d023_live/summary.json).

Tests cover actual consumed scaling, crit cap and attack rolls, exact 10-second expiry, independent instances, eligible and ineligible Poison crits, input-build immutability, unchanged cooldowns, Touch expiry, live UI journeys and tooltips. [Suites](../project/reports/p6_d023_shadow_balance/summary.json); [buff tooltip checks](../project/reports/p6_d023_tooltips/summary.json).

Previous D022 release metadata is archived as `shadow_release_manifest_pre_d023.json`. Compatible revisions, saved IDs and legacy content are preserved. Source hashes are refreshed for D023.
