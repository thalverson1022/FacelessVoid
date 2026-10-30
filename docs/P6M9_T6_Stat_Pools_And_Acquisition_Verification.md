# M9 T6 — Stat pools and acquisition integration

2026-10-25. **T6 Complete under P6M9-D016.** The [M9 tracker](P6M9_Gear_Slot_Expansion_And_Progression_Pacing_Tracker.md) owns current task status; [T3](P6M9_T3_Stat_Pool_Specification.md) owns the approved ranges and weights.

## Implemented contract

The user authorized T6 with equal selection among eligible slots, isolated saves and tracker completion. `GearGenerator.ALL_SLOTS` and `PHASE5_ALL_SLOTS` now contain the seven stable slots in T5 order: Weapon, Helm, Armor, Trinket, Charm, Legs, Hands (`[0,3,4,1,2,5,6]`). Six ordinary rarities accept Pants and Gloves: Basic, Master, Epic, Cursed, Chaos and Unique. Crude remains starter-only; Legendary remains catalog-backed.

`StatCatalog` adds exactly 49 positive slot/category rows: 25 Pants and 24 Gloves, with 14 Basic-derived drawbacks. The complete catalog now has 148 positive occurrences and 47 drawback occurrences. Every Basic weight is 1; Rare/Special weights and deterministic category row order match the approved specification. Old-five membership, ranges, weights and definitions remain unchanged.

Pants preserve separate Basic and Rare gold/Magic Find ranges through explicit category overrides. Basic Magic Find can roll as a negative drawback in both new slots; Rare-only entries cannot become drawbacks. Ordinary rolls keep one canonical used-ID set across categories/signs. Chaos keeps four independent rolls with replacement and category weights 5/4/5; duplicates, opposing signs and all-negative outcomes remain legal. Unique retains three Basic, one Rare and one binary Special. All existing rarity/depth/request scaling, rounding, binary value 1 and invalid-request rules remain.

## Equal selection and acquisition

| Acquisition source | Slot policy |
| --- | --- |
| Ordinary shop offer or reroll | One uniform draw from all seven slots, 1/7 each. Duplicate-offer retries retain that sampled slot. |
| Ordinary reward without an explicit subset | One uniform draw per choice from all seven slots. Duplicate-stat retries retain that sampled slot. |
| Explicit reward subset | Equal selection within its authored eligible subset; an intentional two-slot pool remains 1/2 each. |
| Generated normal encounter | One uniformly selected eligible slot from all seven. |
| Generated elite encounter | Two distinct slots sampled uniformly without replacement from all seven; reward choices use that subset. |
| Generated boss | All seven eligible slots, in stable universal order. |
| Fixed Legendary shop/reward | Retained selection by eligible authored identity and existing unlock/ownership gates, independent of the preliminary ordinary-slot draw. |

The six authored Gilded Serpent ordinary reward subsets are intentional `[0,1]`, `[0,2]` or `[1,2]` pairs and retain their exact membership. Generated route subsets already derive from `ALL_SLOTS`; extending that list makes new slots reachable without changing subset sizes or route algorithms. No new generated-enemy Legendary outcome is introduced. The active fixed catalog remains 16 until T8 adds the approved four items.

The duplicate-retry correction matters because resampling the slot after rejecting an affix signature could favor slots with fewer collisions. Selection now occurs once before either shop or reward retry loop. Shop rarity/upgrades still follow their existing per-attempt algorithm, and a fixed Legendary result still follows global identity selection. Equal ordinary-slot draws do not mean equal representation of all item slots after those Legendary outcomes.

Gold amounts, shop prices, resale, reward frequency, offer/choice counts, rarity curves, Magic Find upgrades/snapshots, inventory capacity and acquisition ownership rules remain unchanged. New-slot items retain generated provenance and saved values; load does not reroll them. Fresh Adventure still equips only Crude Dagger, with Pants/Gloves empty. T5 Adventure v5 / Practice v4 and epoch1 remain the persistence boundary; this task adds no reset epoch.

## Verification and scope

The authoritative [focused engine summary](../project/reports/m9_t6_final/summary.json) records **14 passing suites**, each with its final source hash, command and result. [Verification index](../project/reports/m9_t6_final/verification_index.json) identifies the contributing runs; [aggregate isolation](../project/reports/m9_t6_final/aggregate_isolation.json) confirms unchanged protected paths across all three. Fingerprints cover default gameplay files/temporaries, marker and sibling project identity files.

| Evidence | Verified behavior |
| --- | --- |
| `m9_t6_pool_test` — 44,816 checks | Exact ordered pools/weights/ranges; 148/47 totals; six ordinary rarities; canonical cross-category/sign exclusions; positive/negative Basic Magic Find; Pants economy category ranges; Chaos duplicates/opposing signs/all-negative outcomes; scaling, rounding, depth and invalid-scale boundaries. |
| `m9_t6_acquisition_test` — 2,026 checks | Seeded shop/reward repeatability and provenance; equal-slot RNG oracle through forced duplicate retry exhaustion; all seven slots reachable in each generated reward role; exact boss order; authored subset restrictions; pending Adventure and generated Practice round trips; claim/purchase/equip ownership and duplicate-transaction rejection; one Magic Find snapshot per batch. |
| `t8_acquisition_test` — 348 checks | Retained 16,000-sample Legendary identity study, unlock/ownership gates, transaction rules, pricing and Magic Find upgrade stories. |
| Eleven retained suites | Seven-slot foundation, original-five stat foundation, weighted selection, Cursed, Chaos, canonical uniqueness, Unique Specials, stat scaling, rarity counts, fixed Legendary generation boundary and persistence/inventory. |

Initial runs found two obsolete retained fixtures: Unique exhaustion requested four Weapon Specials despite four already being available before T6; the Legendary boundary assumed five Weapon-only identities despite the accepted16-item multi-slot roster. Only those assertions were corrected, retaining the exhaustion/error checks and adding an exact16-ID/slot expectation. The T5 generation-gated assertion now verifies T6 enabling. The [initial summary](../project/reports/m9_t6_final/initial_summary.json) preserves these failures and an initial45-second timeout of the unchanged large acquisition suite; affected suites passed bounded reruns, with the large suite allowed180 seconds. The consolidated summary retains actual contributing command paths rather than implying a fresh single all-suite run.

The parent [independent closeout verifier](../work/m9_t6/verify_closeout.py) compares all 49 new rows and their exact order/ranges/weights against the approved machine-readable contract. Removing just the eight newly added slot dictionaries must reproduce the entire pre-T6 catalog, demonstrating preservation of existing definitions, pools, ranges and algorithms. [Closeout results](../work/m9_t6/verification.json) also reconcile final test source hashes and bounded runtime changes against the pre-T6 snapshot.

[Whole-profile verification](../work/m9_t6/protected_verification.json) checks the FacelessVoid and sibling Enigma trees against their pre-task hashes, including additions/deletions. Engine checks use task-specific `res://reports/` save namespaces configured before persistence access. No live profile reset is performed during validation.

An independent source/acquisition review found no blocking runtime issue after the fixed-slot retry correction and directed checks. Certificate-store and shutdown ObjectDB/resource diagnostics remain in the logs. One parser-only check omitted the report log override and failed to open the default engine log before test execution; actual test runs used explicit report logs and isolated persistence paths. All161 preexisting protected-profile files remain unchanged, with no added/deleted files. No engine/export qualification is claimed.

T7 still owns seven-slot paper doll/editor controls and comparison presentation. T8 owns standard/new Legendary artwork integration and the four new Legendary runtime effects. This record does not claim completed player-facing new-slot presentation, new Legendary acquisition, full-run pacing acceptance, broad balance simulation or crash/power-loss durability. T9 verifies the combined system; T10/T11 own focused progression and user acceptance, with M10/M11 retaining wider qualification. D009's hidden Adventure-shop projected comparison remains in force.
