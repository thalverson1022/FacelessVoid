# P6M8-T9 — Item presentation and combat feedback

2026-10-24. **T9 Pending input: implementation and verification finished; user presentation review pending.** T1–T8 remain Complete. Authority: D083 in the [M8 tracker](P6M8_Legendary_Item_Revamp_And_Expansion_Tracker.md), [approved mechanics](P6M8_T5_Legendary_Mechanics_Specification.md), accepted T7/T8 implementation and M7 presentation conventions.

## Result

All 16 authored Legendaries now share readable fixed-stat/effect copy across item hovers, comparisons and the actual Practice selector. The existing compact two-box comparison remains; long lines wrap and its backing is opaque. Previews explain skill gains/losses, signatures and effective conversions without changing equipment or transactions. Practice no longer shows an empty fixed-item details area.

Combat feedback distinguishes Exsanguinate health removal from damage, DPS and biggest hits. Its live total, zero-Shred result, repeated removal, restored enemy armor, recap and separate inspector chart are visible. Poison consumption and free repeats have distinct log wording; Meditation/Dash show actual sources, strength, duration, cap refresh and expiry. Existing timed-buff rules identify base durations so Crown-scaled timers do not contradict their descriptions.

**698 counted T9 checks pass across four focused suites, plus 52 checks across five actual skill-hover captures** and focused M7/recap/Practice regressions. [Verification manifest](../work/m8_t9_presentation/verification.json) retains commands, isolation paths, source hashes and failed attempts. These are presentation fixtures rendered through production controls, not earned-build or balance acceptance.

## Item coverage

Every row has real-resource identity, slot, fixed-affix, effect, icon, tooltip/comparison and actual Practice-selector coverage. Supplied artwork and fixed resources remain unchanged.

| Item | Presentation emphasis |
| --- | --- |
| [Wyvern Kriss](../work/m8_t9_presentation/final/project/reports/t9_ui_review/practice_wyvern_kriss.png) | Twice-fast Poison cadence; no duplicate implementation affix |
| [Umbral Stiletto](../work/m8_t9_presentation/final/project/reports/t9_ui_review/practice_umbral_stiletto.png) | Death Strike unlock and additive Decay bonus without consuming Decay |
| [Mithril Karambit](../work/m8_t9_presentation/final/project/reports/t9_ui_review/practice_mithril_karambit.png) | Local +50 percentage points on Stab/Heavy Slash; no false global Retrigger stat |
| [Bandit Blade](../work/m8_t9_presentation/final/project/reports/t9_ui_review/practice_bandit_blade.png) | Current stash, whole groups of10, +100 cap and live preview |
| [Bejeweled Push Dagger](../work/m8_t9_presentation/final/project/reports/t9_ui_review/practice_bejeweled_push_dagger.png) | 40% minimum Cast Time, readiness/cooldowns retained |
| [Decrepit Blade](../work/m8_t9_presentation/final/project/reports/t9_ui_review/practice_decrepit_blade.png) | Poison Strike retains its attack and Consumes all Poison in one burst |
| [Nightkiss Kitana](../work/m8_t9_presentation/final/project/reports/t9_ui_review/practice_nightkiss_kitana.png) | All Stacks/Shred Value labels; Exsanguinate Consume and mitigation/crit exclusions |
| [The Crown of Concertation](../work/m8_t9_presentation/final/project/reports/t9_ui_review/practice_crown_of_concertation.png) | Double bonus strength, x2 becomes x3; duration/grants/caps unchanged |
| [Helm of the Samurai](../work/m8_t9_presentation/final/project/reports/t9_ui_review/practice_helm_of_the_samurai.png) | Skill/Poison repeats grant Meditation; additive strength, cap and refreshed base duration |
| [Cloak of Speed](../work/m8_t9_presentation/final/project/reports/t9_ui_review/practice_cloak_of_speed.png) | 30% retriggered-attack Quick Cut trigger with ordinary recursive rules |
| Death’s Door | Missing encounter attempts x1/x2/x4/x6; Poison included, Exsanguinate/opening exception |
| [The Signet of the Old Kings](../work/m8_t9_presentation/final/project/reports/t9_ui_review/practice_signet_of_the_old_kings.png) | Uncapped input conversion, extra Crit Damage, Poison crit suppression; raw conversion detail |
| Lolzorz’s Locket | Retains approved concise critical-hit cooldown sentence; replay follows recorded deadlines |
| Serpent’s Coil | Free Poison repeats use current calculation and can repeat again |
| [Wingjammer](../work/m8_t9_presentation/final/project/reports/t9_ui_review/practice_wingjammer.png) | Poison crit eligibility, Dash strength, cap and shared refreshed base duration |
| [Mysterious Lucky Coin](../work/m8_t9_presentation/final/project/reports/t9_ui_review/practice_mysterious_lucky_coin.png) | Total Magic Find doubling and current-run discovery/pool gate, no immediate grant |

Blocked shop/reward actions now distinguish ownership/unlock failures from inventory capacity. Destroying ordinary Lucky Coin through the actual Gear panel displays current-run discovery feedback; resetting the run clears stale text. These explanations read the accepted gates; acquisition rules are unchanged.

## Actual-size screenshots

All source captures are1280×720. Open the original PNG to judge actual size. The Practice editor uses production placement; the shop comparison screenshot mounts the production tooltip in a temporary high CanvasLayer at a viewport-safe position to reproduce native tooltip stacking. Combat captures use actual Practice screen/shared inspector with deterministic resolver fixtures; the blank macro strip reflects the fixture, not a saved player setup.

- [All 16 Practice captures and geometry witness](../work/m8_t9_presentation/final/project/reports/t9_ui_review/witness.json); filenames are `practice_<item key>.png` in that directory.
- [Nightkiss fixed-item editor](../work/m8_t9_presentation/final/project/reports/t9_ui_review/practice_nightkiss_kitana.png).
- [Signet versus equipped Locket comparison](../work/m8_t9_presentation/final/project/reports/t9_ui_review/adventure_signet_comparison.png).
- [Coin discovery feedback](../work/m8_t9_presentation/final/project/reports/t9_ui_review/coin_discovery.png).
- [Exsanguinate repeated removal](../work/m8_t9_presentation/combat/project/reports/t9_combat_feedback_visual/nightkiss_repeated_removal.png):2160 health removed, zero damage, Shred0 and armor restored100.
- [Zero-Shred removal](../work/m8_t9_presentation/combat/project/reports/t9_combat_feedback_visual/zero_shred_removal.png).
- [Crown/Dash inspector](../work/m8_t9_presentation/combat/project/reports/t9_combat_feedback_visual/crown_effect_inspector.png):9 recorded Dash stacks, +90% Attack Speed,3.60s remaining.
- [Separate health-removal chart](../work/m8_t9_presentation/combat/project/reports/t9_combat_feedback_visual/nightkiss_separate_chart.png): damage/DPS0; removal12240 in its own chart.
- [Actual macro-slot skill hovers and geometry](../work/m8_t9_presentation/skill_hover_debug/project/reports/t9_skill_hover/geometry.json): [Nightkiss](../work/m8_t9_presentation/skill_hover_debug/project/reports/t9_skill_hover/exsanguinate_nightkiss.png), [Decrepit](../work/m8_t9_presentation/skill_hover_debug/project/reports/t9_skill_hover/poison_strike_decrepit.png), [Crown](../work/m8_t9_presentation/skill_hover_debug/project/reports/t9_skill_hover/virulent_crown.png), [Umbral](../work/m8_t9_presentation/skill_hover_debug/project/reports/t9_skill_hover/death_strike_umbral.png), [Signet](../work/m8_t9_presentation/skill_hover_debug/project/reports/t9_skill_hover/beguiling_signet.png). Native mouse hovers use the production providers/panels. Godot's logical viewport is1600×900, scaled0.8 into1280×720 captures; bounds checks use that transform.

## Verification and preservation

| Selected evidence | Result |
| --- | --- |
| `item_worker/evidence/items_pass` |415 checks; all 16 fixed resources, comparison/state purity, widths and production widgets |
| `final/evidence/skills_02` |109 checks; live unlocks, Crown/Signet/Poison/Exsanguinate descriptions |
| `combat/evidence/final_accepted_feedback` |102 checks; authoritative events, health-removal accounting, zero cases, repeat timing, effects,1x/4x, Skip and reduced motion |
| `final/evidence/ui_capture_final` |72 checks; all 16 actual editors, keyboard selector focus, geometry, shop gates, Coin discovery and Adventure-state preservation |
| `combat/evidence/final_accepted_visual` |Six full-size combat/inspector screenshots |
| `skill_hover_debug/evidence/geometry_05` |52 checks; five native engine skill popups, actual fonts/theme/art, logical bounds and1280×720 PNG size |
| `final/evidence/minimal_hover_02` |810 existing minimal-hover checks pass |
| `final/evidence/skill_tooltip_formatter_test_01`, `p6_m7_keyword_coding_test_01`, `p6_m7_t6_effect_display_test_01` |Focused existing formatter/keyword/effect display checks pass |
| `combat/evidence/recap_verified`, `final_training_room_combat_view_test`, `final_p6_m7_retrigger_label_test` |Existing recap, actual Practice view and compact retrigger-label checks pass |

Task-start SHA256 inventory covers 2324 production files. Exactly 22 existing files changed, all presentation or test files; new files are UI feedback/test helpers. All 1187 protected data/artwork/core files checked by the manifest remain identical. Combat resolution/scheduling, BuildState/resolution, generator/RNG, save implementations and fixed resources are unchanged. Legendary catalog changes are text/formatting only: `all_paths` and `all_items` match the hash-verified T8/task-start source. UI snapshot checks and independent source review found no gameplay/loot mutations.

All launches used disposable copied projects with redirected save paths and APPDATA/LOCALAPPDATA under `work/m8_t9_presentation`. Real player saves and sibling Enigma were not used. `baseline.json` is the task-start authority; the later directory called `baseline/project` contains early T9 edits and is not used as pre-edit proof.

Early attempts exposed test initialization/format-string issues, a legacy non-Legendary Practice fixture, artificial screenshot positioning/stacking and a recap log-prefix compatibility regression. Corrected final runs are selected above; failed logs remain. The existing minimal-hover fixture now marks its synthetic fixed item Legendary to satisfy the accepted T7 equip gate; expected behavior was not weakened.

## Review limits and handoff

User launch follow-up (2026-10-24), resolved: the user confirmed opening the main production project and reported missing talent/skill art and Practice gear. Inspection of the game log found unimported new Legendary PNG preloads, followed by shared `GameIcons` compilation failures and cascading UI errors. The original PNGs were present, but the main project lacked their `.png.import` metadata; isolated copies had completed their own imports. The user reopened the project through the editor, completed asset import and explicitly confirmed that talent/skill icons and Practice gear access returned. This was a main-editor import-state gap, not an intentional UI removal or missing source artwork. Isolated rendering checks did not establish the health of the user's editor import state. This confirmation resolves the launch issue; broader T9 presentation approval remains pending.

T9 awaits user approval; T10–T12 have not started. T10 owns balance/exploit pressure, including recursive proc density and near-zero cooldown combinations. Candidate1024 overflow remains invalid, depth16 is retained, and no tuning or loot redesign is adopted. T11 owns player comprehension and practical full-run observations; M9 retains broader earned-run refinement.

Recorded certificate-store and ObjectDB/resources-at-exit diagnostics remain; these checks do not certify clean engine shutdown, sound, exports, other resolutions/platforms, screen readers, controller access or color-vision accessibility. Reduced motion retains its accepted session-only inspector control. No new account persistence, economy legendaries or lives-system redesign was introduced.
