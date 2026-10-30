# M9 T5 — Seven-slot foundation and save reset

**Subsequent integration — D016:** T6 now enables the approved ordinary Pants/Gloves pools and seven-slot acquisition; see [T6 verification](P6M9_T6_Stat_Pools_And_Acquisition_Verification.md). Statements below about generation being gated describe the verified T5 checkpoint, not current acquisition. T5 reports/source hashes remain historical evidence.

Date: 2026-10-25. Status: **Complete under P6M9-D015**, within the foundation scope below. Current task authority: [M9 tracker](P6M9_Gear_Slot_Expansion_And_Progression_Pacing_Tracker.md).

## Approved behavior and implemented foundation

The user requested T5 implementation, isolated-save verification and tracker completion, while retaining **only the Crude Dagger** on fresh Adventures. Class selection equips that weapon; Pants and Gloves, like all other non-weapon slots, remain empty. Restart retains the existing seed behavior. Practice retains its existing unequipped custom-shell baseline, now with seven shells. Test retains Bandit Blade and 100 gold, with Pants/Gloves empty.

| Universal slot | Stable enum ID | Rogue label |
| --- | --- | --- |
| Weapon | 0 | Weapon |
| Trinket | 1 | Trinket |
| Charm | 2 | Charm |
| Helm | 3 | Helm |
| Armor | 4 | Chest |
| Legs | 5 | Pants |
| Hands | 6 | Gloves |

The old five IDs are unchanged. Universal enumeration/aggregation order is Weapon, Helm, Armor, Trinket, Charm, Legs, Hands: `[0,3,4,1,2,5,6]`. `GearItem`, Adventure `BuildState` and `TrainingRoomState` support seven-slot lookup, equipment collection, equip/swap/unequip and stat rebuilding. Ownership and carried economy include the new slots. Existing inventory capacity, displacement/autosale, sell/destroy and equipped-item protections remain in force. Practice stores independent item instances and preserves its canonical Legendary handling.

This foundation deliberately leaves `GearGenerator.ALL_SLOTS` and `PHASE5_ALL_SLOTS` at five acquisition slots. T6 integrates approved stat pools and acquisition; T7 extends paper doll/editor presentation; T8 integrates sprites and the four new Legendaries/effects. The existing 16-item Legendary catalog remains the active catalog. Synthetic new-slot fixtures prove ownership and aggregation without asserting that Pants/Gloves already drop in ordinary play. T9 will verify the combined integration.

## Persistence boundary

Adventure now requires `save_version: 5`; Practice and its core envelope require `practice_version: 4`. Both formats explicitly represent seven slots and validate primitive shape, slot bounds, slot-to-item compatibility and affixes before resource decoding or state mutation. Missing/extra Practice slot entries, missing Adventure equipment keys, incompatible slot contents and invalid affixes fail atomically. New-slot saves round-trip through independent state/resource instances.

`SevenSlotSaveBoundary` owns exactly these FacelessVoid gameplay files and each corresponding `.tmp`:

| File | Reset classification |
| --- | --- |
| `user://adventure_p6_m6.json` | Recognized positive integer `save_version` below5 |
| `user://practice_build.json` | Recognized positive integer `practice_version` below4 |
| `user://practice_bladedancer_core.json` | Recognized positive integer `practice_version` below4 |
| `user://save.json` | Recognized positive integer `save_version` below5, or valid JSON object without that field |

The versionless legacy exception is intentional path ownership: `save.json` is the retired gameplay envelope and has no current writer. Any valid JSON object there, including `{}`, is treated as retired legacy data. This exception does not apply to current Adventure/Practice paths. Invalid JSON or invalid/nonpositive version fields block preflight and preserve files.

The shared guard runs at normal entry/persistence access, not autoload startup. It preflights all four paths and temporaries before deleting recognized old data. Only after successful cleanup does it write `user://seven_slot_epoch.json` with `seven_slot_epoch: 1`. Successful later checks are idempotent. Deletion or marker-write failure blocks normal loading/saving and reports a retryable error; no success marker is committed. A deletion failure may leave partial cleanup, which a later successful attempt finishes. This is not a cross-file transaction or a power-loss durability guarantee.

Current/future version envelopes are preserved if the marker is absent. A malformed marker blocks access. Strict loaders reject incompatible envelopes rather than migrating them. Ordinary writers protect existing incompatible/malformed data and block any existing gameplay `.tmp`; New Adventure uses explicit replacement confirmation even for a physical file that cannot be resumed. Explicit replacement and deletion failures are handled before resetting in-memory Adventure state. Practice's explicit Save Setup can replace a file; automatic persistence cannot silently replace an incompatible save.

Test Mode uses memory-only persistence bypasses: no reset, marker, load, write or deletion. Returning to normal Title resumes the normal entry policy. The guarantee applies to Test operations, not to every subsequent normal-mode action after leaving Test.

All three active paths must be redirected together for isolated validation. Legacy/marker defaults derive into that namespace, or explicit overrides must share it. Duplicate canonical paths, partial overrides and `.tmp` aliases are rejected. Wrapper startup configures all five paths before the first persistence call. No recursive directory cleanup, preference deletion or Enigma access is part of the runtime reset.

## Verification and evidence

The final focused run is [six-suite engine summary](../project/reports/m9_t5_final/summary.json), with [protected-path isolation](../project/reports/m9_t5_final/isolation.json). All six suites passed and their recorded source hashes match the final test files. The new suites report118 foundation,88 reset and18 entry checks. [Parent closeout verification](../work/m9_t5/verification.json) confirms those hashes, document links and the bounded source changes against the pre-T5 snapshot. The suites cover:

- `m9_t5_foundation_test`: stable identities/order, Crude-only start, seven-slot ownership/economy/stat contributions, swap/full-inventory behavior, Adventure/Practice round trips, detached instances, strict malformed inputs and all16 retained Legendaries.
- `m9_t5_save_reset_test`: four old paths and temporaries, Practice-first cleanup, marker idempotence, malformed/future preservation, removal/marker-write failures and retry, namespace confinement, rejected-write byte preservation and Test bypasses.
- `m9_t5_entry_test`: actual Title reset, class selection, Crude-only Adventure, failed-delete blocking, seed-preserving restart, future-file replacement confirmation and Bandit-only Test entry/restart/autosave isolation.
- `t3_stat_foundation_test`, `t3_persistence_inventory_test`, `p6_m7_t11_current_autosave_test`: retained stats, inventory/persistence and current autosave behavior. The persistence fixture changes replace only obsolete migration expectations superseded by this release boundary.

The parent independently inspected the actual reset-blocked Title at **1600×900**: [render](../project/reports/m9_t5_visual/reset_blocked.png), [reproducible isolated driver](../work/m9_t5/render_entry.py). The notice wraps within the menu and Adventure actions are disabled. This is entry/error presentation verification, not seven-slot paper doll acceptance.

[Whole-profile hash comparison](../work/m9_t5/protected_verification.json) covers the preexisting FacelessVoid and sibling Enigma profile trees, including file additions/deletions. Live gameplay files, preferences and sibling data were preserved throughout verification. **The live reset was not executed during testing**; normal release entry will apply the implemented policy. Per-run fingerprints also cover the default gameplay paths/temporaries, epoch marker and sibling project identity files.

An independent correctness review identified and drove fixes for partial path overrides, decode-before-validation, permissive Practice keys, automatic overwrite of incompatible data, deletion-failure state mutation and protected temporary envelopes. Historical pre-fix reports are intermediate evidence; the final summary is authoritative. Earlier T4 source-hash evidence remains a historical specification checkpoint and is not a post-T5 runtime immutability assertion.

Known certificate-store and shutdown resource/ObjectDB diagnostics remain recorded in engine logs. Passing scoped checks do not qualify engine teardown, export, crash recovery, broad balance or full-run gameplay. M10/M11 retain those broader responsibilities. Existing discount/resale and recursive-proc-budget risks remain open for their assigned downstream review.
