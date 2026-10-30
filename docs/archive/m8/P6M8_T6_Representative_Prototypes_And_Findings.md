# P6M8-T6 — Representative prototypes and findings

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. [Current context](../../P6_Project_Onboarding_Context.md).

2026-10-24. **T6 Complete under D076 — user approved prototype findings and the review checkpoint on 2026-10-24.** T1–T7 Complete; T7 production implementation/findings approved under D079; T8 Complete under D082; T1–T8 Complete; T9–T12 Not started. [T8 results](P6M8_T8_Acquisition_Progression_And_Persistence_Verification.md). [T7 results](P6M8_T7_Implementation_And_Verification.md). Governing design: [approved T5 specification](../../P6M8_T5_Legendary_Mechanics_Specification.md). [M8 tracker](../../P6M8_Legendary_Item_Revamp_And_Expansion_Tracker.md).

## Result and prototype boundary

The representative prototypes pass **307 assertions across four suites**, plus **five distinct focused regression suites** in the final combined disposable project. All three independently developed prototype groups were merged, overlapping live-stat hooks reconciled, and their tests rerun together. Sixteen additional checks exercise cross-system interactions and actual saved encounter state feeding combat.

These are executable modifications to copied actual Godot runtime/state helpers, not a separate spreadsheet or arithmetic-only simulator. Runtime patches are opt-in and confined to disposable `work/m8_t6_prototypes/` projects. The production project remains unchanged; all **2,283 task-start production files** match their captured hashes, with no new files in that measured scope. Artwork and existing runtime content have not been promoted or replaced.

**User review checkpoint accepted under D076.** Acceptance retains the documented findings and limitations. Passing representative checks does not establish full 16-item production integration, final player-facing presentation, earned-run balance, production migration or export qualification. Extra economy items, new generated-enemy Legendary outcomes, loot-roll changes, global lives and account progression remain deferred.

## Isolation and reproducibility

- [Runner](../../../work/m8_t6_prototypes/run_prototypes.py) creates independent combat/stats/state copies and a combined copy. Save-system defaults point inside each copy; APPDATA/LOCALAPPDATA are redirected below that group; copied project names use separate T6 custom userdata names. Selected runs explicitly identify the project, command and environment.
- [Task-start manifest](../../../work/m8_t6_prototypes/baseline.json), [final preservation comparison](../../../work/m8_t6_prototypes/source_preservation.json), [selected-run verification](../../../work/m8_t6_prototypes/verification.json) and [combined source hashes](../../../work/m8_t6_prototypes/combined/manifest.json) establish the captured source interval. Production `.godot`/reports are outside the hash scope. This is not a clean-Git-HEAD or player-save hashing claim.
- [Combined patch](../../../work/m8_t6_prototypes/combined/combined_prototype.patch) is a reviewable prototype artifact. It includes disposable save-path and descriptor changes and must not be copied wholesale into production.
- [Disposable persistence policy](../../../work/m8_t6_prototypes/state/project/T6_SAVE_POLICY.md) was recorded before adding the run-local flag in the copied loader. The scratch extension retains version 3 only as a prototype policy; T8 still owns production envelopes, old-reader handling and migration decisions.
- No real FacelessVoid save file or sibling Enigma file was used. All selected accepted runs use the canonical isolated runner. A separate check-only startup attempt failed creating scratch-named user logs and crashed before executing a script; it is excluded. Initial missing-font import caches were bootstrapped from unchanged font cache resources; theme changes were restricted to scratch bootstrap.

## Selected final evidence

Only the following combined-project runs count as current passing suite evidence. Separate group runs support investigation and are not counted again as additional suites/assertions.

| Suite | Result | Detailed evidence |
| --- | --- | --- |
| Combat prototypes | 123 assertions; zero failures | [Run](../../../work/m8_t6_prototypes/combined/evidence/joint_combat_02/result.json), [numeric packets/casts/traces](../../../work/m8_t6_prototypes/combined/project/reports/t6_combat_witness.json). |
| Stat/buff prototypes | 125 assertions; all pass | [Run](../../../work/m8_t6_prototypes/combined/evidence/joint_stats_02/result.json), [values/expiry/engine witnesses](../../../work/m8_t6_prototypes/combined/project/reports/t6_stats_witness.json). |
| State/acquisition/save prototypes | 43 checks; pass | [Run](../../../work/m8_t6_prototypes/combined/evidence/joint_state_02/result.json), [state/save/pool witnesses](../../../work/m8_t6_prototypes/combined/project/reports/t6_state_witness.json). |
| Additional joint interactions | 16 assertions; zero failures | [Run](../../../work/m8_t6_prototypes/combined/evidence/joint_interactions_01/result.json), [joint runtime/save witnesses](../../../work/m8_t6_prototypes/combined/project/reports/t6_joint_witness.json). |
| Existing T3 timing | Pass | [Run](../../../work/m8_t6_prototypes/combined/evidence/final_reg_timing/result.json). |
| Existing T3 crit mechanics | Pass | [Run](../../../work/m8_t6_prototypes/combined/evidence/final_reg_crit/result.json). |
| Existing stat derivation | Pass | [Run](../../../work/m8_t6_prototypes/combined/evidence/final_reg_stats/result.json). |
| Existing inventory model | Pass / legacy OK marker | [Run](../../../work/m8_t6_prototypes/combined/evidence/final_reg_inventory/result.json). |
| Existing T3 inventory/persistence | Pass | [Run](../../../work/m8_t6_prototypes/combined/evidence/final_reg_persistence/result.json). |

Reproduce with `python work/m8_t6_prototypes/run_prototypes.py --group combined --script res://tests/t6_joint_test.gd --label review_rerun` (choose a fresh label for new evidence). The other prototype scripts are `t6_combat_test.gd`, `t6_stats_test.gd`, `t6_state_test.gd` in that same copied project. Group preparation never syncs over edited prototypes. Rebuilding the combined artifact uses [three-way merge preparation](../../../work/m8_t6_prototypes/merge_prototypes.py) and [explicit hook resolutions](../../../work/m8_t6_prototypes/resolve_combined.py); the parent joint test is retained separately in the combined copy.

## Verified mechanics

### Retriggers, buffs and critical hooks

- Mithril contributes one skill-local +50-point roll, clamps effective probability normally, and does not change numeric Retrigger Chance or Double Dip. Guaranteed repeat replaces the random candidate. Root plus 16 descendants is observed at 100% probability.
- A **legal five-slot fixture** resolves actual Mithril plus four representative fixed-affix GearItems through BuildResolver: Samurai, Cloak, Locket and Wingjammer. Seed 3 produces **13 casts, three Cloak Quick Cuts, 2,684 total damage**. Quick Cut retains its supplied build augmentation and actual Precision/Footwork behavior. Separate guaranteed/100% fixtures verify recursive Cloak activation.
- Locket traces reduction of its own already-running root cooldown from deadline 2,000 to 1,000 at time 300 ms. Tests use before/after deadline trace, not scheduler state after cleanup. All-running targets, zero floor, no stored credit, per-packet trials and deterministic Locket-before-Wingjammer order pass.
- Connected zero-damage crits qualify; dodges do not. Meditation/Dash use All Stacks → doubling → caps 5/20, shared duration scaling, refresh at cap, exact expiry and cleanup. Meditation is a separate multiplier; Dash is IAS.
- Dash IAS feeds Hastened/Accelerant Poison cadence and expiration restores the prior rate while preserving clock phase. Crown-powered three-stack Dash produces +30% IAS and 769 ms cadence with full IAS-to-Poison scaling; expiry restores 1,000 ms.

### Poison, Consume and live free ticks

- Actual Poison Strike retains its attack and replaces the single forced tick with the all-stack packet. Four actual Poison stacks are consumed once; at 100% Coil chance a root plus 16 free packets uses no further Poison.
- Without Crown, one Virulent instance gives raw 80 for the first five four-stack packets, then raw 40 after its five charges are exhausted. A **legal Crown + Decrepit + Coil** joint fixture gives raw **120 → 40** at exhaustion. These are fresh live calculations, not copied post-crit damage.
- Crit rolls are independent and talent-gated; each critical packet gets separate Locket/Dash trials. Poison repeats grant Meditation. Empty initial fuel creates no crit/retrigger RNG draws.
- Decrepit triggers keyword Consume/Pact once for actual removed count. In the witness, original raw 40 resolves before newly granted defense debuffs; a repeat reads the resulting negative Absorb and becomes raw 41.6. Repeats do not regrant Consume talents.
- Natural and forced sources, Wyvern's 500 ms cadence, current defenses/conversion and connected crit-negation-to-zero behavior are covered. Example: raw 20 against 50% resistance and 3 Absorb yields 7; converted physical against 100 Armor and 2 Block yields 11.
- Shared ancestry respects depth 16: a forced activation belonging to a depth-15 skill permits one Poison repeat; depth-16 permits none. Sixty-five independent natural tick roots evaluate 1,040 candidates in total but only 16 per root and remain valid. Main cast budgets reset after intervening natural ticks.

### Exsanguinate and existing weapon/state effects

- With ten Shred and resolved value 60, Exsanguinate removes **1,200 health** per activation regardless of mitigation, crit chance, player damage multipliers or Death's Door. At 100% repeat chance, one cast plus 16 repeats removes **20,400 health**. This is expected approved behavior, not balance acceptance.
- Only the first activation consumes Shred; captured repeats reuse its amount. A boundary fixture with four newly present Shred preserves those stacks and their remaining armor reduction. Zero initial fuel removes zero; no crit hooks or Death Pact. Debuff 300 ms minimum, 8-second cooldown and ordinary CDR are covered.
- Umbral adds three actual Decay to the Death Strike raw base and retains those stacks: base 100 becomes 114 after current skill scaling/rounding. Bandit floor/cap/replacement is proven across 0/9/10/19/20/999/1,000 and larger gold; actual theft from 19 to 20 gold changes consecutive hit damage **18 → 19**, without input mutation.
- Actual saved encounter failure state feeds combat: one limited-encounter loss yields ×2, then direct damage **200** and Poison **20** from base 100/10 after save/resume. A new encounter resets ×1. Opening unlimited retries stay ×1 after one and six losses; terminal state cannot start another fight. Exsanguinate remains excluded from the multiplier.

### Crown, Signet and Coin

- Crown doubles additive Bypass/Touch/Beguiling strength, maintains independent expirations, and changes Virulent ×2 to ×3 (two independent instances ×9), with unchanged five charges each. Boolean resistance-ignore and guarantees remain unchanged. Footwork respects skill minimum/cap/consumption; actual Riposte bonus becomes ×1.4 instead of ×1.2 in the rank-one/count-one fixture.
- Signet preserves raw overcap source input, converts once, and overrides direct/Side Step/Poison crit output. A representative **260% raw Crit Chance → +520% IAS**. Base ×2.6 Crit Damage yields +320% Increased Physical Damage. Double Dip continues to read only numeric retrigger, excluding Mithril's local bonus.
- Actual engine witnesses prove Beguiling's converted IAS **1.4 → 1.0** on expiration; live theft changes IAS **0 → 0.4** and physical hit **30 → 32** through its crit-derived inputs. The legal Signet + Wingjammer joint fixture produces no critical Dash trials.
- Coin doubles resolved Magic Find once, including temporary-source rebuilds and the existing reward-upgrade consumer, without adding RNG draws or rarity outcomes. 60% becomes 120%; Fill Your Pockets' resulting elemental multiplier changes ×1.3 to ×1.6.

### Acquisition, Practice and disposable persistence

- Locked ordinary Coin destruction from inventory and fresh equipment each unlocks eligibility without granting the Legendary. Sale/unequip do not. Repeated destruction is idempotent. New run resets; same-run reload preserves; missing old flag defaults locked; malformed flag fails without changing state or fixture bytes.
- The representative catalog has five baseline weapons plus four fixed resources spanning Helm/Armor/Charm/Trinket. Across seven eligible IDs, **7,000 actual uniform shop selections** produce counts **967–1,041**. This supports the directly inspected uniform selection path; it is not a proof over every seed.
- Owned equipment/inventory are excluded; actual sale/destruction restore eligibility; all-owned falls back Cursed. Stale ownership/unlock shop claims preserve money and offers; stale reward claims preserve the pending reward.
- Five-slot fixed-resource save/reload preserves identities, an Umbral skill unlock and unrelated ordinary gear. Practice routes fixed items to correct slots, guards fixed-affix editing APIs and maintains a separate attempt input. Actual final UI prevention and production save-version policy remain later work.
- Shop rarity and relevant generation functions remain unchanged. No new generated-enemy Legendary outcome is introduced.

## Findings requiring review / downstream work

| Finding | Interpretation and recommended disposition |
| --- | --- |
| **F1 — candidate overflow remains reachable** | Two synthetic 100%-chance authored proc branches reach 1,024 evaluated candidates, max depth 16, and invalidate the simulation with `trigger_candidate_limit`. The assertion passes because it correctly detects the expected failure; this is **not a valid combat result**. It is an adversarial runtime fixture, not a proven earned roster build. Preserve the accepted depth cutoff; carry candidate diagnostics and reachable-build qualification into T7/T10. No unreviewed chance reduction or new cap was applied. |
| **F2 — strong approved multipliers** | Consumption-free repeats, Crown's independent ×3 buffs, near-zero CDR and Exsanguinate's mitigation bypass produce large payoffs. The 20,400-health-removal witness and charge-exhaustion behavior are intentional contract consequences; T10 needs matched/earned progression evidence before balance acceptance. No automatic tuning was adopted. |
| **F3 — presentation/event model is provisional** | The [Godot-rendered review bench](../../../work/m8_t6_prototypes/baseline/project/reports/t6_review/overview.png) was inspected at 1280×720 and passed clipping/image-size checks. It displays real recorded engine outputs. It is not the final player HUD or T9 art/feedback acceptance. Crown's temporary source inspector still reports some original input magnitudes; production output must show effective strength. Exsanguinate temporarily uses the numeric cast-damage field for transport; T7/T9 should give health removal a distinct event/type so downstream physical-damage hooks cannot misclassify it. |
| **F4 — integration remains representative** | Full 16-item resource/catalog authoring, final Practice UI, actual item-to-descriptor wiring, broad talent permutations and production migration were not performed. Multi-slot/save behavior was proven with representative fixed resources and explicit opt-in flags. T7–T9 own full integration under the accepted specification. |
| **F5 — inherited exceptions remain** | Six pre-T2 signature mismatches (seeds 1, 103, 11, 23, 42, 7) reproduce in unchanged baseline and prototype inherited suites. Exclude them from clean pass counts; retain existing exception ownership. Fresh flags-off prototype versus current-source gameplay/RNG comparison matches all six seeds. No golden signatures were replaced. |

## Verification history and limits

Initial import attempts failed on missing copied font caches. Early checks also exposed bad field-name/cleanup expectations and missing merged fixtures; these were repaired with failed attempts retained. Parent review corrected a genuine opening-fight Death's Door descriptor error and required an Exsanguinate repeat to preserve new Shred. Parent/worker review also repaired shared skill/Poison depth accounting, independent natural tick candidate budgets and Dash/cadence expiry integration. Final evidence above supersedes early passes that lacked those boundaries.

The inventory test's original `OK` success marker was initially misclassified by a PASS-only wrapper; the canonical runner now accepts PASS/PASSED/OK and the final combined inventory run passes. Existing certificate-store and ObjectDB/resource-at-exit diagnostics remain in logs; passing exit-zero mechanics checks do not establish clean engine teardown/export qualification (M10).

[Visual render result](../../../work/m8_t6_prototypes/baseline/evidence/review_visual_01/result.json) verifies the developer review bench only. Test-source hashes, exact commands, selected results and preservation scope are recorded in the verification manifest. No new earned full run, power-loss durability or comprehensive balance result is claimed.

## T6 review checkpoint

- [x] Representative combat, stat/buff, state/save and cross-system behaviors prototyped in isolated actual-runtime copies.
- [x] Focused checks, current-source compatibility comparison, selected regressions and source preservation recorded.
- [x] Necessary prototype review presentation rendered and inspected, with final player UI work explicitly assigned onward.
- [x] Findings, inherited failures, implementation limitations and follow-up owners documented.
- [x] User approved behavior/findings and the T6 checkpoint under D076. Downstream implementation/qualification owners remain as recorded.

**Current follow-up:** T7 has implemented the approved roster/runtime and is Complete after user approval under D079; T8 is next. T6 is Complete; see the separate T7 report for production evidence. Retain F1–F5 as implementation/validation follow-ups; no balance tuning or prototype patch promotion is implied by this documentation closeout.
