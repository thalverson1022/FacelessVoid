# Shadow Touch damage — P6M5-D022

**D023 update (2026-10-06):** Touch is restored to +2 physical base per consumed Poison. Beguiling Presence also grants +2 percentage points crit chance per consumed Decay. Existing durations and 30-second cooldowns are retained. See [current verification](P6_Shadow_Presence_Crit_And_Touch_Update.md).

User-approved live change (2026-10-06): Touch of Darkness grants **+1 base physical damage** per actual Poison stack consumed, down from +2. Its +10% increased attack speed per consumed stack, 12-second duration, independent instance lifecycle and 30-second cooldown are unchanged. Dusk Strike retains +10 Shred Value; Beguiling Presence remains unchanged.

Maxed 35-point Shadow macro: 2 × (Beguiling Strike → 2 × Distilled Corruption) → 3 × Death Strike → Touch of Darkness.

Crude Dagger only, zero starting gold, zero-defense dummy, 30 seconds, seeds 1–200: **354.073 DPS**, matching the isolated +1 trial (previous live +2: 473.56033). Practice/Balance Lab seed-one parity is verified. [Live comparison](../project/reports/balance/full35_comparison_d022_live/summary.json).

Focused tests verify actual-consumption scaling, independent damage and attack-speed expiry at 12 seconds, zero fuel, talent allocation, tooltips, Poison timing and Practice journeys. [Tests](../project/reports/p6_d022_shadow_balance/summary.json).

The D021 manifest is archived as `shadow_release_manifest_pre_d022.json`. Save IDs, compatible revisions and legacy content are preserved; source hashes are refreshed for D022.
