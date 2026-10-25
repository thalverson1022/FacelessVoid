# P6M8-T8 — Acquisition, progression and persistence verification

2026-10-24. **T8 Complete under D082: user approved the implementation and findings on 2026-10-24.** T1–T8 Complete; T9–T12 Not started. Authority: [approved T5 contract](P6M8_T5_Legendary_Mechanics_Specification.md#acquisition-persistence-and-mode-contracts), [accepted T7 implementation](P6M8_T7_Implementation_And_Verification.md), D079/D080 in the [M8 tracker](P6M8_Legendary_Item_Revamp_And_Expansion_Tracker.md).

## Result

**11 distinct suites pass, including 3,852 counted checks across four T8 suites.** All16 Legendaries were exercised through actual acquisition/equipment transactions. The persistence matrix covers **384 combinations**:16 identities ×3 supported Adventure versions ×4 locations ×2 encodings. Coin lifecycle, pending offers, generated-contract acceptance, encounter retry/terminal state and Practice isolation have saved/resumed runtime witnesses.

Current loot rules are preserved. A frozen pre-edit comparison matches **36 complete shop generations,180 generated reward choices and540 upgrade stories** across12 seed/depth contexts. Twenty-five roll/pricing/reroll method bodies and generator/RNG/stat/Legendary catalog files are unchanged. No new generated-enemy Legendary outcome, rarity formula, price, discount, resale coefficient or balance tuning was introduced.

[Verification manifest](../work/m8_t8_acquisition/verification.json) selects passing runs, commands, environment paths, source hashes and limits. [Loot-rule preservation record](../work/m8_t8_acquisition/loot_rule_preservation.json) includes the exact matching witness hash and unchanged source checks.

## Gaps fixed

| Gap | Resulting behavior |
| --- | --- |
| Fixed reward and direct acquisition paths could bypass Legendary ownership/unlock gates | `add_inventory_item`/`grant_gear` enforce eligibility. Fixed batches preflight all Legendary IDs before gold, points, grants or claim changes. Owned transfers remain valid. |
| Direct choices and sampled Legendary pools could repeat an identity | Eligible Legendary IDs are deduplicated before sampling/combining the choice lists. Existing explicit authored pools remain the same pools. |
| Unequipping could exceed inventory capacity | Full-inventory unequip preserves equipment and capacity. Full-inventory swaps and existing reward overflow resale still work. |
| Malformed gear/run metadata could be coerced, fail midway or bypass validation through canonical IDs/paths | Primitive validation precedes decoding and supported-envelope incompatible resets. Canonical metadata cannot bypass those checks; established invalid-integer-enum drop and slot-migration policies remain. |
| Unsupported nested build schemas could reset an explicitly incompatible snapshot | Shared registry-independent shape checking rejects unknown build schemas before any reset/write. It does not require historical IDs to resolve against the current registry. |
| Practice omitted Missing attempts from saves | Practice version3 persists it; versions1/2 default an absent value to0. Reload displays the restored input and actual Death’s Door damage uses it. |
| Restored ordinary carried gear could alias cached Adventure resources | Mutable carried gear and custom editor items are detached per setup. Editing a restored Lucky Coin leaves Adventure ownership, pending references and canonical values intact. |
| A rejected Missing attempts edit could remain displayed during playback | The control is disabled while locked and resynchronizes if an edit is rejected. |
| Practice canonical metadata could bypass validation in its older path | All supported versions validate item/equipment metadata before canonical resolution, including version1. Slot mismatches, fixed items in custom templates and ambiguous custom references fail atomically. |

Fixed resources/artwork and combat mechanics were not changed. T8 changes six existing project files and adds five test scripts relative to its captured task-start source. The workspace was already dirty; this is not a clean Git checkpoint. Scoped whitespace checks pass.

## Acquisition and progression evidence

The acquisition suite covers all16 real items through purchase, inventory equip, full-inventory replacement, sale, explicit reward auto-equip/overflow, unequip and destruction. Five Legendaries can coexist in five slots; actual ownership prevents a second acquisition. Sale/destruction restores eligibility, subject to the Coin gate.

A fixed-seed16,000-selection sample reaches every unlocked identity and checks the expected uniform frequencies. This supports inspected equal-ID sampling; it is not a proof over every seed. The all-owned fallback fixture intentionally exceeds legal ownership capacity to exercise the Cursed fallback and is labeled synthetic. Actual Knives reward choices retain their authored five-item pool; no unapproved expansion of that reward was made.

Coin tests exercise inventory/equipped ordinary Coin destruction, no immediate Legendary grant, no unlock on sale/unequip, idempotence, locked/unlocked stale claims, pending shops/rewards across resume, actual purchase/claim, and new-run reset. Rejected transactions retain money, pending choices and claim state. Synthetic fixed Legendary batches use the real claim API and authored resources; current shipped fixed gear rewards include ordinary Lucky Coin, so these fixtures do not claim an earned fixed-Legendary drop.

Saved limited-encounter losses retain failure/retry counts and remaining attempts, feed actual ×2 Death’s Door damage, and preserve terminal second-loss restrictions across resume. Opening unlimited retries remain ×1 even after six saved losses. A new encounter resets the bonus context. No global lives/account progression was introduced.

## Persistence policy and compatibility

The [Adventure policy](P6M8_T8_Persistence_Compatibility_Policy.md) and [Practice policy](P6M8_T8_Practice_Persistence_Policy.md) were recorded before the corresponding edits.

- Adventure remains version4; current reader supports2/3/4. Fixed path and stable-ID entries resolve to the current authored signature in equipment, inventory, shops and pending rewards. Ordinary generated rolls/provenance and unrelated build/run/history/economy fields are preserved. Version2 retains its inline T3-stat exclusion. Missing unlock flags default locked; malformed flags fail without mutation.
- Practice writes version3; current reader supports1/2/3. Version3 requires integer Missing attempts in0–99; older snapshots default an absent value to0. Existing carried-gear/T3 checks apply to current snapshots. Actual Practice entry/save/reload preserves Adventure state and Adventure fixture bytes.
- Invalid/future data and unknown nested build schemas are tested for preservation of live script state, signals and fixture bytes. Structurally valid explicitly incompatible historical snapshots retain the established reset policy. Current Adventure refuses version1; an explicitly selected historical compatibility registry retains its version1 reset behavior. Real legacy slots are never used by the tests.
- Pinned previous readers reject Adventure4 and Practice3 without changing the fixture or live state. Ordinary temp-file replacement remains unchanged; no power-loss durability is claimed.

The matrix uses **copied synthetic supported-version fixtures, not player-save samples**. Actual transaction → save → reset → resume journeys additionally cover unlocks, shops, rewards, equipped items and generated pending/accepted contracts. The generated route checks compare exact persisted JSON values, allowing the inherited PackedArray→JSON Array container normalization without ignoring numeric/state differences. Unrelated legacy sentinel bytes survive all persistence journeys.

## Selected passing runs

| Suite | Evidence |
| --- | --- |
| Acquisition | [348 checks](../work/m8_t8_acquisition/final/evidence/t8_acquisition_test_01/result.json), [transaction/pool/roll witnesses](../work/m8_t8_acquisition/final/project/reports/t8_acquisition_witness.json) |
| Adventure persistence | [3,342 checks](../work/m8_t8_acquisition/final/evidence/persistence_complete/result.json), [matrix and journey witnesses](../work/m8_t8_acquisition/final/project/reports/t8_persistence_witness.json) |
| Practice/progression | [112 checks and visual render](../work/m8_t8_acquisition/final/evidence/practice_complete/result.json), [witnesses](../work/m8_t8_acquisition/final/project/reports/t8_practice_progression_witness.json) |
| Future nested build schemas | [50 checks](../work/m8_t8_acquisition/final/evidence/future_build_01/result.json) |
| Pinned previous readers | [Pass](../work/m8_t8_acquisition/old_readers/evidence/rejection_01/result.json): Adventure3-reader/Practice2-reader reject new envelopes without mutation |
| Existing inventory model | [Pass](../work/m8_t8_acquisition/final/evidence/inventory_model_test_01/result.json) |
| Existing five-slot equipment | [Pass](../work/m8_t8_acquisition/final/evidence/p5m2_five_slot_equipment_test_01/result.json) |
| Existing ordinary Lucky Coin | [Pass](../work/m8_t8_acquisition/final/evidence/p5m2_lucky_coin_charm_test_01/result.json) |
| Existing economy stats | [Pass](../work/m8_t8_acquisition/final/evidence/p5m11_economy_stats_test_01/result.json) |
| T3 inventory/persistence | [Pass](../work/m8_t8_acquisition/final/evidence/t3_persistence_inventory_test_01/result.json); writer-version expectation follows the current constant; explicit old-version fixtures and rejection checks retained |
| Existing generated contract save/load | [Pass](../work/m8_t8_acquisition/final/evidence/generated_contract_save_load_test_01/result.json) |

The focused boundary-debug run and visual reruns are not counted again as distinct suites. No previous milestone pass counts are added to these totals.

## Isolation, inspection and limits

All Godot runs use [the T8 isolated runner](../work/m8_t8_acquisition/run_isolated.py), disposable copied projects, redirected save defaults and per-copy APPDATA/LOCALAPPDATA under `work/m8_t8_acquisition`. Some tests choose their own `res://reports` fixture files inside those copies. No production Godot launch, real player-save access or sibling Enigma access occurred. Final copied gameplay/data/test/art files match production, apart from checked save-path redirection. No fixed data or artwork changed.

The actual [restored Practice UI](../work/m8_t8_acquisition/final/project/reports/t8_review/practice_restore.png) was rendered and inspected at1280×720. Missing attempts is visible as4, its controls fit the scrolled setup panel, and the test verifies its restored state and lock behavior. This is T8 functional UI evidence, not full T9 presentation acceptance.

Earlier failures remain in evidence: initial icon-import bootstrap, test type inference, an unrealistic blank-family fixture, a wrong-slot Coil expectation and raw PackedArray equality/instrumentation. Test fixtures/representation comparisons were corrected; the final selected suites above supersede them. The Practice damage witness respects ordinary per-hit rounding rather than requiring an invalid exact ratio after rounding. Review caught and repaired actual isolation, rejected-input display and canonical metadata/reset-preflight gaps.

Existing certificate-store and ObjectDB/resource-at-exit diagnostics remain in logs; engine teardown/export qualification stays M10. T7’s inherited playback autosave assertion and six pre-T2 signature mismatches retain their recorded ownership and are not counted as passing T8 suites. Candidate-limit overflow remains invalid combat, with reachable-build/balance qualification in T10; T8 did not change trigger limits or mechanics.

## Review checkpoint

**User review checkpoint accepted under D082; T8 is Complete.** Approval retains the documented evidence and limits. T9 final item presentation/comparisons/combat feedback, T10 economy/exploit/earned-build balance, T11 user playtesting and T12 closeout remain. New generated-enemy Legendary outcomes, loot-roll redesign, economy additions, global lives and account progression stay deferred. T8 does not claim final balance or earned full-run acceptance.

[T9 execution steps](P6M8_Legendary_Item_Revamp_And_Expansion_Tracker.md#t9-execution-steps) are recorded in the M8 tracker. This closeout changes documentation only; no new runtime, artwork, save edits or gameplay execution.
