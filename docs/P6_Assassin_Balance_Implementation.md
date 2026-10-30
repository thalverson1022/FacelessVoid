# Assassin balance implementation — P6M5-D010

**2026-10-04 follow-up:** [D012 shared combat tuning](P6_Cooldown_And_Negative_Defense_Update.md) changes cooldown start times and negative-defense damage. DPS figures below remain historical, before D012. Talent rank coefficients are unchanged.

User-approved on 2026-10-03 after the Balance Lab inquiry. Implemented in the live shared Poison rules and complete Assassin content used by Test Mode and Practice.

| Setting | Previous | Current |
|---|---|---|
| Echoing Toxin damage per rank | +10% | +5%; three ranks give x1.15 |
| Resonance damage per rank | +20% | +5%; four ranks give x1.20 |
| Toxic Tradeoff Poison per rank | +20% | +10%; five ranks give x1.50 |
| Toxic Tradeoff physical per rank | -10% | Unchanged; five ranks give x0.50 |
| Primary Assassin base elemental per point | +1 | +0.5; 35 points give +17.5 |

Echoing and Resonance remain separate multipliers. The +5 innate, stack consumption (one/two/three), natural/forced cadence, Virulent, Bypass, Powder's full invested-point scaling, caps, cooldowns, conversion order and save identities remain unchanged. Primary Assassin at 35 points contributes +22.5 including innate; secondary Assassin still contributes +5.

Runtime coefficients are named in `p6_poison_contracts.gd`, `assassin_passives.gd` and `playable_assassin_content.gd`. Rank descriptions show the new values. The tree bonus formatter now preserves fractional flat amounts so +0.5 is not incorrectly displayed as +1.

## Verification

The new `p6_assassin_balance_live_test` resolves released content directly through Balance Lab, without diagnostic stat substitutions: full single-tree Assassin, Crude Dagger, no other gear, zero gold, Poison Vile → Powder → three Stabs → Virulent, 30 seconds, surviving zero-defense dummy, seeds 1–200. Mean DPS is **498.43950**, matching the approved probe. It also checks primary scaling, unchanged Powder investment and physical penalty, rank descriptions, and the fractional tree label. Report: `project/reports/p6_assassin_balance_live/lab.json`.

Full Assassin, rank/fuel/conversion boundaries and the headless UI journey pass. The shared Poison test's previous 70.2 max-rank example was updated to 41.4 under D010 and passes on rerun; its rank matrix still independently checks every supported rank/fuel combination. 26 unique suites pass across the preserved first-pass, regression and live reports; consolidated evidence is in `project/reports/p6_assassin_balance_closeout/summary.json`. The rendered full Assassin journey passes all 139 checks at 1280/1600/1920 widths; its separate report is `project/reports/p6_assassin_balance_visual`. The +0.5 header and updated stats were visually inspected. Protected saves were unchanged across the headless runs. Existing certificate/resource-exit warnings remain in the logs.

## Provenance and compatibility

No IDs, save schemas or allocation rules changed. Existing builds resolve to the new values automatically. The original T7 review and historical balance reports retain their old numerical evidence with explicit supersession notices. The release manifest archives its exact pre-D010 version and fingerprints the current sources. Historical pre-tuning experiment entry points now reject the changed coefficient baseline before writing any reports, preventing accidental double application or overwriting old evidence. Use the live acceptance test for current gameplay; reproducing historical probes requires their captured old source baseline.

The original drafts and historical predecessor manifests remain unchanged. This is the three-change tuning request, not M6-wide balance acceptance or a claim of parity across gear, mixed builds and encounters.
