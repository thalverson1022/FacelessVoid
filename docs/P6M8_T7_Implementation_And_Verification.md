# P6M8-T7 — Legendary implementation and verification

2026-10-24. **T7 Complete under D079: user approved the implementation and findings on 2026-10-24.** T1–T7 Complete; T8 Complete under D082; T1–T8 Complete; T9–T12 Not started. [T8 results](P6M8_T8_Acquisition_Progression_And_Persistence_Verification.md). Governing contracts: [T5 specification](P6M8_T5_Legendary_Mechanics_Specification.md) and [approved T6 findings](P6M8_T6_Representative_Prototypes_And_Findings.md). No balance tuning adopted.

## Delivered

All 16 fixed Legendary resources are implemented: seven weapons, two helms, two Armor items, two charms and three trinkets. They retain the approved names, exact affixes, existing stable weapon identities and 21–27 weapon ranges. Fourteen supplied PNGs cover eleven new items, Exsanguinate, Meditation and Dash; existing artwork hashes are unchanged.

Equipped items now enable production descriptors automatically. The build resolver captures augmented Quick Cut and maintains raw inputs for idempotent Signet/Bandit/Coin live calculations. Decrepit gets a separate modern Poison Strike resource with the same skill identity, selected before augments while equipped. The old shared Poison Strike resource is unchanged, preserving behavior without Decrepit and restoring the selected source on unequip. Repeated skills, free Poison activations, Consume hooks, live charge spending, shared depth 16 and independent natural tick budgets carry forward from T6.

Exsanguinate has a dedicated effect class, `health_removed` events and separate result totals. Victory, remaining HP and overkill read total health loss; damage/DPS/crit hooks retain damage-only semantics. Recap and playback explain health removal. Meditation/Dash grants, expiration and effective strength reach replay; Locket updates displayed cooldown deadlines. Final feedback polish remains T9.

Practice offers slot-filtered Legendary selectors for every slot, immutable fixed affixes, removal through None and a separate Missing attempts input. All sixteen actual selectors were exercised. Existing skill ownership is deduplicated. A [rendered actual Practice selector](../work/m8_t7_implementation/final/project/reports/t7_review/practice_helm.png) was inspected at 1280×720; its art, controls and selector fit the viewport. This is functional integration evidence, not full T9 visual acceptance.

Minimum acquisition/save integration prevents the expanded catalog from exposing a locked Coin or duplicate owned Legendary. Destroying ordinary Lucky Coin from inventory or equipment unlocks the run-local pool without granting the item; sale/unequip do not. Uniform selection, stale-claim rejection and fallback use existing roll rules. New generated-enemy Legendary outcomes and rarity redesign remain deferred. [Persistence policy](P6M8_T7_Save_Integration_Policy.md) was written before edits: version 4 retains the run flag, versions 2/3 remain readable under their existing stat rules, missing flags default locked, malformed data fails atomically, and the previous version-3 reader rejects version 4 without mutation. T8 still owns broad acquisition/progression and compatibility qualification.

## Verification

[Verification manifest](../work/m8_t7_implementation/verification.json) records commands, per-copy APPDATA/LOCALAPPDATA, selected results, source hashes and limits. All Godot runs used disposable projects below `work/m8_t7_implementation/`; save paths were redirected inside those copies. No production Godot launch, real player-save access or sibling Enigma use occurred. The final tested source matches production gameplay files, with only the checked save redirection. The workspace was already dirty; this is not a clean-Git-HEAD claim. Scoped whitespace checking passes.

**11 distinct passing suites:**

| Suite | Selected result |
| --- | --- |
| Full roster audit | [Pass](../work/m8_t7_implementation/final/evidence/t7_roster_test_01/result.json): 16 identities, exact affixes, icons, slots, ranges and shared skill ownership |
| Production combat | [149 checks](../work/m8_t7_implementation/final/evidence/combat_final/result.json); [numeric witnesses](../work/m8_t7_implementation/final/project/reports/t7_combat_witness.json) |
| Stats/buffs/conversions | [192 checks](../work/m8_t7_implementation/final/evidence/stats_final/result.json); [witnesses](../work/m8_t7_implementation/final/project/reports/p6_m8_legendary_stats_witness.json) |
| State/unlock/persistence | [50 checks](../work/m8_t7_implementation/final/evidence/t7_state_test_01/result.json); [witnesses](../work/m8_t7_implementation/final/project/reports/t7_state_witness.json) |
| Actual item/save/UI integration | [153 checks and rendered UI](../work/m8_t7_implementation/final/evidence/integration_final/result.json): all 16 fixed-resource round trips and actual Practice equip/remove controls |
| T3 combat timing | [Pass](../work/m8_t7_implementation/final/evidence/t3_combat_timing_test_final/result.json) |
| T3 crit mechanics | [Pass](../work/m8_t7_implementation/final/evidence/t3_combat_crit_test_final/result.json) |
| Stat derivation | [Pass](../work/m8_t7_implementation/final/evidence/p6_stat_derivation_test_final/result.json) |
| Inventory model | [Pass](../work/m8_t7_implementation/final/evidence/inventory_model_test_final/result.json) |
| T3 inventory/persistence | [Pass](../work/m8_t7_implementation/final/evidence/t3_persistence_inventory_test_02/result.json); version assertion follows the current envelope constant, substantive rejection/preservation checks retained |
| Pinned previous reader | [Pass](../work/m8_t7_implementation/old_reader/evidence/rejection_03/result.json): rejects version 4 without changing live state or fixture bytes |

The four counted behavioral suites total **544 checks**, in addition to the roster audit. Visual reruns, import runs and earlier passes are not counted as additional suites.

## Item coverage

All items have exact authored-stat, descriptor wiring, icon, canonical save round-trip and actual Practice selector coverage. Signature checks additionally cover:

| Item | Mechanics verified |
| --- | --- |
| Wyvern Kriss | Actual equipped cadence multiplier 0.5; natural fuel/clock rules and Coil repeats |
| Umbral Stiletto | Actual Death Strike unlock; Decay adds to existing raw damage and remains intact |
| Mithril Karambit | One local +50-point Stab/Heavy Slash chance; numeric Retrigger/Double Dip unchanged; recursive depth 16 |
| Bandit Blade | Actual stash floor/cap; live gold changes replace the signature contribution without accumulation |
| Bejeweled Push Dagger | Actual 40% minimum-time trials; running cooldown remains respected |
| Decrepit Blade | Actual unlock retains direct hit and releases all Poison once; Consume/Pact once; free repeats retain originating fuel size |
| Nightkiss Kitana | Actual +50 Shred Value/+5 All Stacks; six Shred at value60 removes720 health through extreme mitigation, with zero classified damage and a valid victory |
| Crown of Concertation | Strength-only additive and multiplicative bonuses; independent Virulent charges; Footwork/Riposte and Dash effective values |
| Helm of Samurai | Random, guaranteed and Poison repeats grant capped Meditation; All Stacks/doubling, refresh/expiry and physical multiplier |
| Cloak of Speed | Build-augmented normal Quick Cut; 30% recursive attack-repeat hook and ordinary talent behavior |
| Death's Door | Actual encounter context; armor-required negative control; unlimited opening x1; direct/Poison scaling with Exsanguinate excluded |
| Signet of Old Kings | Uncapped all-source inputs, temporary/gold changes, extra Crit Damage conversion once; suppresses all crits and Wingjammer trials |
| Lolzorz's Locket | Per-critical-packet 20% trials; own-root/all-running cooldown reduction; zero floor, no banking, connected-zero versus dodged eligibility |
| Serpent's Coil | Natural/forced recursive free activations; fresh talent-gated crits and live Virulent calculations; no repeated Consume |
| Wingjammer | Direct/Poison critical trials; Dash stack grants, shared timer, Crown strength and live cadence effects |
| Mysterious Lucky Coin | Actual total MF150→300; zero→zero, rebuild once and downstream economy derivation; run-local destruction gate and save restoration |

## Combinations and review findings

- Actual Mithril + Samurai + Cloak + Locket + Wingjammer resolves a legal five-slot fixture with recursive skill hooks and Quick Cut: four casts, one Quick Cut,614 damage at its recorded seed. It is controlled mechanics evidence, not an earned-run balance sample.
- Decrepit + Coil retains the normal direct hit, consumes the initial Poison once and makes free live repeats. Crown/Virulent joint tests verify strength and charge exhaustion; subsequent packets lose exhausted modifiers. Consume/Pact grants once, and later repeats read the resulting live defenses.
- Signet prevents Poison and guaranteed direct crits, suppressing Locket/Wingjammer crit rewards. Signet + Crown + Beguiling + Poison speed scaling crosses the exact self-buff expiry boundary with phase preserved.
- Exsanguinate repeats reuse captured removal without consuming newly added Shred; no crit/Consume-Pact/damage-multiplier leakage. Mitigation-bypass removal remains separate from damage reporting.
- Independent review caught and repaired an omitted Death's Door equipment gate, non-weapon Practice removal and a Signet/Beguiling Poison-cadence expiry gap. Negative controls now cover them.

**Candidate overflow remains an honest failure.** Synthetic two-branch 100% proc stress reaches1,024 candidates at depth16 and produces invalid `trigger_candidate_limit`, as in T6. That assertion confirms diagnosis; it is not a valid fight or a proven earned roster build. No unapproved probability reduction or new termination cap was added. T10 retains reachable-build qualification and balance of strong accepted multipliers.

**One inherited playback suite remains excluded.** Current [playback run](../work/m8_t7_implementation/final/evidence/playback_final/result.json) and [unchanged pre-T7 comparison](../work/m8_t7_implementation/pre_t7/evidence/inherited_playback_01/result.json) both fail the same legacy autosave-before-playback assertion. An earlier T7 attempt also broke two old Poison-application fixtures by replacing the shared resource; separating the equipped-only Decrepit resource fixed those new failures. The remaining inherited failure is not counted as a pass. The six pre-T2 signature mismatches retain their existing ownership; no goldens were replaced. Flags-off current-source gameplay/RNG parity remains checked.

Initial disposable imports reported preload errors before new icons were imported; after bootstrap, clean import and runtime checks passed. Early stale-envelope test expectation was updated from literal3 to the current version constant, keeping its preservation/invalid-data assertions. Existing certificate-store and ObjectDB/resource-at-exit diagnostics remain; M10 teardown/export qualification is not claimed.

## Review checkpoint and next ownership

**User review checkpoint accepted under D079; T7 is Complete.** Approval retains the documented findings and limits, without treating candidate-overflow combat as valid or granting final balance acceptance. T8 follows for broad acquisition/progression/save qualification; T9 for full item comparison/description/feedback acceptance; T10 for matched and earned progression, economy/exploit checks and reachable branching stress. T11 user playtesting and T12 closeout remain. Economy additions, new generated-enemy Legendary outcomes, loot-roll changes, global lives, account progression and final balance remain deferred as previously agreed.

T8 execution steps are recorded in the [M8 tracker](P6M8_Legendary_Item_Revamp_And_Expansion_Tracker.md#t8-execution-steps). This closeout changes documentation only; no runtime, artwork or save data changes and no new gameplay runs.
