# M9 T8 — Artwork and Legendary integration

2026-10-27. **T8 Complete — user item/visual acceptance recorded under P6M9-D025.** Implementation/scoped verification was completed under D019, followed by the corrections and audits D020–D024. The user confirms everything looks good and requests completion. This acceptance update performs no new runtime changes, test runs or save access; retained verification limitations remain. Next: T9 combined mechanics/reset verification. The [M9 tracker](P6M9_Gear_Slot_Expansion_And_Progression_Pacing_Tracker.md) owns current task status; the [approved T4 contract](P6M9_T4_Legendary_Mechanics_Specification.md) owns the mechanics and exact authored values.

2026-10-26 amendment — **D020:** Master Pants now use supplied `Leg Armor/9.png`, replacing the earlier8.png selection. Current art manifests and all30 review renders are refreshed and visually checked; [D020 asset verification](../work/m9_t8_master_pants_correction/correction.json) records the new sprite and render hashes. Original T8 test/profile evidence remains its historical checkpoint. At this historical checkpoint T8 item/visual acceptance remained pending; D025 subsequently records acceptance.

2026-10-26 amendment — **D021:** compact text is now “Critical hits have a 20% chance to Retrigger”, “Poison ticks have a 20% chance to not consume Poison stacks”, and “Overkill gold is doubled”. Poison Lightning trials require Serpent’s Coil; ordinary Retrigger Chance is unchanged. Scales’ full activation scope and Golden’s cap/multiplier ordering are unchanged. [Correction verification](../work/m9_t8_effect_text_correction/verification.json) records three passing isolated suites (1,587 mechanics/280 presentation checks), unchanged protected profiles and thirty refreshed renders; earlier T8 reports remain historical checkpoints.

2026-10-26 amendment — **D022:** requested UI cleanup removes talent-refund rotation-removal and Lucky Coin discovery status text while retaining actual rotation pruning and unlocks. Enemy Stats stays230px tall with a157px scrolling text viewport; Adventure/Test Gear ends at884px on1600×900 screens. Reward hovers retain item details and choice/capacity hints, with Equipped/On equip comparisons hidden. Three focused isolated suites pass and seven actual renders are recorded in the [cleanup manifest](../work/m9_ui_cleanup/final_manifest.json) and [render summary](../project/reports/m9_ui_cleanup/visual_summary.json). Independent checks confirm all163 protected-profile files unchanged. Supplemental core-journey and T9 UI suites retain unrelated legacy failures ([journey report](../project/reports/m9_ui_cleanup_affected/summary.json), [T9 report](../project/reports/m9_ui_cleanup_t9/summary.json)); no broad regression pass is claimed. At this historical checkpoint T8 acceptance remained pending; D025 subsequently records acceptance.

## Integrated content

All twelve ordinary Pants/Gloves sprites and four Legendary sprites are imported and mapped. The sixteen project PNGs are byte-identical to the supplied 32×32 sources. Existing artwork, the accepted seven-slot layout, and all sixteen prior Legendary resources/identities/order are preserved. Gray silhouettes remain the empty-slot backgrounds; valid ordinary and Legendary items now display their supplied artwork.

The fixed catalog now contains 20 items, appending these four in the approved order. All twelve fixed affixes retain their approved canonical IDs, ADD operation, values and authored order, without rarity/depth scaling:

| Legendary | Fixed stats | Implemented signature |
| --- | --- | --- |
| Serpent’s Scales | +12 Base Elemental Damage; +70% Increased Elemental Damage; +30% Crits Apply Potency | One 20% preservation trial per original positive-cost Poison activation, including Decrepit’s all-stack release. Damage fuel remains available when actual consumption is 0. Free repeats inherit fuel and make no preservation trial; preserved Decrepit consumption grants no Death Pact reward. |
| Golden Greeves | +100% Increased Gold; +50% Magic Find; +40% Shop Discount | Double the ordinarily capped Overkill component, giving at most 100g before Increased Gold. Determine activation at reward time; derive from raw Overkill and freeze the committed payout before reward-granted gear can change it. |
| Arctic Mittens | +30% Increased Attack Speed; +25% Buff Duration; +20% Cooldown Reduction | Derive and freeze `E = ceil(4B/3)` once from nominal budget `B`. Only the displayed countdown runs at 75%; casts, cooldowns, Poison, animations and elapsed timestamps retain ordinary timing. DPS uses actual elapsed duration. |
| Hands of the Lightning Lord | +12 Base Physical Damage; +15% Crit Chance; +120% Crit Damage | Independent 20% self-repeat candidate per eligible own-critical Attack cast and per critical Poison packet, including repeats, only while Serpent’s Coil enables Poison retriggers. Lightning Lord does not add numeric Retrigger Chance. Ordinary and Lightning candidates may both succeed. Preserve source snapshots, depth-first order, existing hooks and shared depth 16/candidate 1,024 guards. |

Scales keeps fuel and actual debit separate in events/logs; it does not remove then refund stacks. Lightning does not add numeric Retrigger Chance, change Double Dip or inherit a descendant’s crit. Signet still suppresses critical output and therefore Lightning candidates. Golden does not double base gold/theft/sale values. Arctic neither changes engine time scale nor mutates saved/authored nominal encounter durations. All Stats and Crown do not scale signature constants.

The four legal Pants/Gloves pairings are available; the two Pants cannot be equipped together, nor can the two Gloves. No new Legendary equip cap, generated-enemy Legendary route, rarity/economy tuning or slot-selection change is introduced. Ordinary pools remain 148 positive occurrences/47 drawbacks. Fresh Adventure remains Crude Dagger-only; Test remains hidden and memory-only; Practice retains its separate setup.

## Acquisition, editing and persistence

Catalog-backed Legendary shops sample uniformly by eligible identity:20 when all are eligible, 19 with Coin locked, then existing ownership filters apply. Existing explicit authored reward pools retain their membership. Practice exposes all 20 through the correct slot filters and keeps fixed stats read-only. Item cards, equipped/inventory references, stat detail, recap and Combat Log use the new artwork and effect descriptions. D009 hides Adventure shop projected **On equip** comparisons; D022 additionally makes gear reward hovers item-only.

Canonical catalog identity survives equipped, inventory, shop-offer, pending-choice and Practice contexts. Full Adventure save/load permutations place each new identity in every applicable context; path and inline canonical reload checks cover all 20 items. The Adventure v5 / Practice v4 / epoch1 boundary is unchanged; this task performs no new reset.

Review found a reachable persistence gap: the existing autosave could record a completed-unclaimed RESULT without its raw Overkill. T8 adds optional, strictly validated `reward_result_basis` containing validity, win and original `overkill_damage`. Reload uses that reward-only basis when calculating Overkill; it clears stale full results and does not fabricate replay data. Missing optional data in earlier v5 envelopes clears stale basis. Invalid/nonfinite/negative basis is rejected before state mutation. Rebuild/equip/load never doubles an already-doubled stored bonus.

`committed_reward_gold` freezes the final amount before fixed reward grants. Immediate payout and the existing deferred animation use that committed amount; existing claimed-reward guards prevent a second claim. This is a scoped save/transaction correction, not a power-loss or cross-file atomicity guarantee. Full fight replay remains unpersisted as before.

## Actual 1600×900 review artifacts

All 30 final PNGs are native 1600×900. The review driver uses the actual scenes and shared card/editor controls. Its four-card overlay and art sheet are review fixtures, not new in-game screens or a four-item simultaneous loadout.

| Review surface | Evidence |
| --- | --- |
| All 16 supplied sprites at integer 5× enlargement | [Artwork sheet](../project/reports/m9_t8_visual/art_contact_sheet.png) |
| Adventure item cards | [All four cards](../project/reports/m9_t8_visual/adventure_four_cards.png) |
| Test item cards | [All four cards](../project/reports/m9_t8_visual/test_four_cards.png) |
| Practice item cards | [All four cards](../project/reports/m9_t8_visual/practice_four_cards.png) |
| Practice Pants/Gloves selection and fixed details | [Pants picker](../project/reports/m9_t8_visual/practice_5_picker.png), [Pants details](../project/reports/m9_t8_visual/practice_5_fixed_details.png), [Gloves picker](../project/reports/m9_t8_visual/practice_6_picker.png), [Gloves details](../project/reports/m9_t8_visual/practice_6_fixed_details.png) |
| Four legal equipped pairs | [Scales + Arctic](../project/reports/m9_t8_visual/adventure_serpents_scales_arctic_mittens.png), [Scales + Lightning](../project/reports/m9_t8_visual/adventure_serpents_scales_hands_of_the_lightning_lord.png), [Golden + Arctic](../project/reports/m9_t8_visual/adventure_golden_greeves_arctic_mittens.png), [Golden + Lightning](../project/reports/m9_t8_visual/adventure_golden_greeves_hands_of_the_lightning_lord.png) |
| Ordinary and empty slots | [Ordinary artwork](../project/reports/m9_t8_visual/adventure_ordinary.png), [Adventure empty slots](../project/reports/m9_t8_visual/adventure_empty.png), [Practice empty slots](../project/reports/m9_t8_visual/practice_empty.png) |
| Arctic actual elapsed/DPS presentation | [Practice Combat Log](../project/reports/m9_t8_visual/practice_arctic_combat_log.png) shows elapsed 26.667s, DPS using that denominator, and nominal 20s at 75% in detail. |

The accepted T7 geometry is retained: Gloves below Weapon, larger Pants below Chest, Helm above Chest, Charm above Trinket. Geometry checks cover equipment containment/non-overlap, key dashboard panels and inventory; Adventure/Test Gear ends at y884 with the 16-pixel bottom margin. Parent inspection confirms the art, cards, fixed editors, countdown and log fit these views. User visual/item acceptance is pending.

Arctic is equipped in each timer fixture, with the visible Stab macro matching the resolved result. All three modes show the same frozen countdown:

| Simulation elapsed | Visible countdown | Adventure | Test | Practice |
| --- | --- | --- | --- | --- |
| 0ms | 20.0s | [Frame](../project/reports/m9_t8_visual/adventure_arctic_0.png) | [Frame](../project/reports/m9_t8_visual/test_arctic_0.png) | [Frame](../project/reports/m9_t8_visual/practice_arctic_0.png) |
| 10,000ms | 12.5s | [Frame](../project/reports/m9_t8_visual/adventure_arctic_10000.png) | [Frame](../project/reports/m9_t8_visual/test_arctic_10000.png) | [Frame](../project/reports/m9_t8_visual/practice_arctic_10000.png) |
| 20,000ms | 5.0s | [Frame](../project/reports/m9_t8_visual/adventure_arctic_20000.png) | [Frame](../project/reports/m9_t8_visual/test_arctic_20000.png) | [Frame](../project/reports/m9_t8_visual/practice_arctic_20000.png) |
| 26,667ms | 0.0s | [Frame](../project/reports/m9_t8_visual/adventure_arctic_26667.png) | [Frame](../project/reports/m9_t8_visual/test_arctic_26667.png) | [Frame](../project/reports/m9_t8_visual/practice_arctic_26667.png) |

[Render summary](../project/reports/m9_t8_visual/summary.json), [geometry](../project/reports/m9_t8_visual/geometry.json) and [countdown witnesses](../project/reports/m9_t8_visual/countdown_evidence.json) record the actual commands, source hashes, dimensions and values. [Reproducible render runner](../work/m9_t8/render_ui.py) uses an offscreen Compatibility-renderer process, explicit report log and isolated save paths installed before first persistence access. Playback tests also cover pause/speed/skip, replay and equipment changes without retiming a frozen result.

## Behavioral evidence and retained limits

[Consolidated acceptance summary](../project/reports/m9_t8_final/summary.json): **nine focused suites pass**. It retains actual contributing commands from three runs rather than implying one new all-suite invocation:

| Suite group | Evidence |
| --- | --- |
| `m9_t8_mechanics_test` — 1,330 directed checks | Preservation success/failure/zero fuel/repeat/Consume; independent Attack/Poison Lightning candidates, source snapshots and guards; Arctic arithmetic/overflow/endpoint/timing; Golden caps/activation/claim/save-resume/stale-basis clearing. |
| Four retained core suites | Existing Legendary stats, Overkill Gold, retrigger semantics and cooldown scheduling. [Core report](../project/reports/m9_t8_core_verified/summary.json). |
| `m9_t8_presentation_test` — 277 checks | Fixed resources/catalog order, artwork mappings, 6,000 eligible-identity samples/gates, all 20 canonical reloads, actual Adventure new-item context round trips, Practice read-only selection and nominal saves, frozen countdown and actual-DPS formatting. |
| Three retained presentation suites | Combat recap, seven-slot UI and reward/shop UI. The T7 test changes only its directly superseded provisional-icon/catalog expectations. |

An actual pre-T8 resolver copy was independently executed for six retained seeds. Every original Cast/Tick field, damage/outcome/timing/gold value and final RNG state matches the new resolver with new effects absent. [Before/after proof](../project/reports/m9_t8_core_baseline_proof/m9_t8_baseline_witness_test/m9_t8_independent_baseline_witness.json) identifies the original source SHA. The durable test reads a compact [baseline fixture](../project/tests/fixtures/m9_t8_no_effect_baseline.json), so it has no hidden dependency on ignored report scripts.

[Parent closeout verification](../work/m9_t8/verification.json) independently reconciles sixteen source/destination PNG hashes, four resources/twelve ordered affixes, old 16/new 20 catalog order, unchanged prior content/art, final test/source hashes, thirty image dimensions/hashes and all three clocks. [Aggregate runner isolation](../project/reports/m9_t8_final/aggregate_isolation.json) covers default save paths/temporaries, epoch marker and sibling project identities. [Whole-profile audit](../work/m9_t8/protected_verification.json) compares all 162 preexisting FacelessVoid/Enigma files, including additions/deletions: unchanged. No live save reset occurred.

Independent combat/save review found no remaining blocking T8 issue. Supplemental failures are retained separately, not counted as passing acceptance:

- [Core supplemental run](../project/reports/m9_t8_core_final/summary.json): old Poison signatures enumerate newly added observation fields. The six original-field/RNG comparisons above pass; the old compact Poison-text assertion was already inconsistent with pre-T8 wording. The old save-boundary fixture uses an incompatible legacy/ranked registry setup and is not current-epoch evidence.
- [Playback supplemental run](../project/reports/m9_t8_presentation_final2/summary.json): its legacy build fails ranked Adventure validation before T8 reward serialization. [Diagnostic](../project/reports/m9_t8_presentation_acceptance_final/playback_diagnostic.log) confirms `Invalid build payload.` A separate exact death-frame assertion after a 0.12-second wall-clock wait still fails; the animation/skip path is unchanged by T8, but its exact runtime timing cause remains unresolved. It is not reported as passing.

Known Compatibility shader, certificate-store and shutdown ObjectDB/resource diagnostics remain. Editor import attempted to save global editor settings and was denied by the sandbox; gameplay persistence was not invoked by import. These scoped checks do not qualify exports/engine teardown, broad regression or full-run balance. Discount/resale amplification and recursive-proc headroom remain for T9/T10; no new safety cap or tuning is silently introduced. T9 owns combined seven-slot mechanics/reset verification, followed by focused progression/user review and M10/M11’s wider responsibilities.
