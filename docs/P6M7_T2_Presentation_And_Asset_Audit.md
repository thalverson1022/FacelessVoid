# M7-T2 — Presentation and asset audit

Date: 2026-10-08. **Complete — coverage and gaps recorded; T3 visual conventions and feedback design is next.** This is an audit closeout, not presentation acceptance or authorization to change mechanics.

## Scope and authority

Reviewed the live ranked registry, accepted full-tree layout, approved icon mapping and Icon Lab handoff, earlier UI/feedback specification, current combat reference, presentation consumers and isolated rendered samples. The runtime registry takes precedence over historical inventory counts and draft descriptions. Preserve existing art assignments and tree geometry until a concrete T3 decision.

The working tree already contained substantial uncommitted work. Exact Git HEAD is in [coverage.json](../project/reports/p6_m7_t2_audit/coverage.json); HEAD alone does not identify this baseline. Each isolated run records the full source hashes in `baseline.json`, the original test hashes, commands and scratch paths. No production script, gameplay resource, assigned image, real save or sibling Enigma file was changed by this audit. New files are inventory tooling, reports and documentation; current status documents were updated.

## Coverage

The [per-identity inventory](P6M7_T2_Presentation_Inventory.md) lists every talent, skill and mapped asset with a disposition. The [machine-readable inventory](../project/reports/p6_m7_t2_audit/coverage.json) includes all 140 generated rank descriptions, 23 skill summaries/conditions, automatic unlock gates, prerequisites, icon paths, hashes and sharing groups.

| Area | Current count | Audit result |
| --- | ---: | --- |
| Bladedancer | 13 talents / 35 ranks | All mapped; generated descriptions present |
| Thief | 10 talents / 35 ranks | All mapped; generated descriptions present |
| Assassin | 10 talents / 35 ranks | All mapped; generated descriptions present |
| Shadow | 11 talents / 35 ranks | All mapped; generated descriptions present |
| Skills | 23 | Three base skills plus tree/talent unlocks; all mapped |
| Player buffs | 10 | Nine inherited source icons plus Greed |
| Enemy statuses | 5 | Poison, Shred, Decay, Penetration, Potency |
| Defensive mechanics | 11 | Armor, resistance, block, absorb, dodge, crit negation, cleanse, suppress, slow, stun, interrupt |
| Total mapped identities | 93 | 84 distinct paths; all exist, all 32×32, all match installed manifest hashes |

No missing live icon assignment was found. The 92-entry historical handoff omits the later Greed addition. Icon Lab still tests a 92-entry catalog and its generated-data freshness check fails (G11). Do not rerun the installer against old approved inputs as a way to resolve this.

Nine buff mappings intentionally inherit their sources: Footwork→Fancy Footwork; Readiness→Parry Strike; Precision→Precision Attacks; Dance→Dance of Death; Bypass→Bypass; Virulent Poison, Master of Poisons, Touch of Darkness and Beguiling Presence→their skills. Greed uses the gold icon. Skill-unlock talents may also use identical artwork in separate named files (Poison Strike and Rending Slash); path counts do not imply unique imagery. Keep Assassin Precision distinct from the Precision buff.

The accepted empty nine-point slots in Bladedancer and Thief are not missing skills. Intrinsic headers use tree identity art and text; there is no requirement to invent separate intrinsic icons. Health/gold and general interface icons remain supporting UI assets, outside the 93-identity mapping.

## Description review

Every rank's text was extracted from live `RankedTalentView.effects`, not the draft catalog. Scalar ranks use `StatModifierFormatter`; special rules use explicit branches in `ranked_talent_view.gd`. Skill summaries and conditions come from `skill_tooltip_formatter.gd`, used by available skills, rotation, tree unlocks and detailed inspection. Runtime builders can override resource fields; for example Death Strike reads the resolver's current per-stack constant.

The audit reviewed those formatter branches against live resource fields/contracts and the combat reference. It found three definite wording defects (G01–G03), a compact-detail omission (G05), and terminology/duplication issues (G04). Remaining entries have no specific discrepancy identified in this pass. This does not certify every gear-modified estimate or conditional tooltip across all rank combinations; T5 owns that validation. The extracted default-context Blinding Powder value of zero is not a defect: it has no invested Assassin points in that context.

## Prioritized gap register

Priority describes implementation order: P1 blocks reliable comprehension; P2 is a material clarity or validation gap. All entries below are presentation/tooling work unless explicitly labeled a suspected lifecycle defect. None calls for balance tuning.

| ID | Priority / disposition | Finding and evidence | Owner and validation case |
| --- | --- | --- | --- |
| G01 | P1 / Improve | Death Strike `conditions_for` and early-return `effect_summary` say weapon + current Poison count; live resolver uses **2 × count** (`DEATH_STRIKE_DAMAGE_PER_POISON_STACK = 2.0`). | T5. Check tree, library, rotation and details at 0/1/10 Poison; all must explain the same 111% × (weapon + 2×Poison + applicable flat bonuses) rule without Consume. |
| G02 | P1 / Improve | Mug short summary says **+2** per credited gold unit, while detailed text and `Skill.stolen_gold_damage_bonus` use **+1**, cap 50. | T5. Check 0/1/49/50/51 credited theft and starting stash; reconcile short/detail/live text with unchanged formula. |
| G03 | P1 / Missing summary handling | Pick Pocket returns **No effect** from `effect_summary`; its detailed conditions correctly describe ten raw gold. Compact library/rotation text therefore misrepresents an effective skill. | T5. Inspect all four skill surfaces with base and increased-gold builds; show theft, no damage, shared cooldown and relevant conditions consistently. |
| G04 | P2 / Improve | Raw phrases such as “Percent Physical Damage,” “Percent Elemental Damage,” “Increased All Stacks” are awkward/underspecified. Toxic Tradeoff states its physical penalty twice (modifier plus special explanation). | T5 with T3 terminology. Review Weapon Master, Keen Eye, Deception, Death Touch and Toxic Tradeoff across ranks; identify base versus percentage, eligible stack grants and one penalty without implying two penalties. |
| G05 | P2 / Improve | Big Score's compact tooltip shows ordinary physical damage but omits its defining six-times-full-crit-multiplier condition; detailed/tree conditions contain it. | T5. Compare library, rotation, tree and details with normal 3× crit and gold bonuses; explain why the skill differs without implying unconditional 18× damage. |
| G06 | P1 / Improve | Dense Assassin/Shadow damage labels overlap each other, cross the combat boundary and interfere with status values. Fresh 1280/1920 captures reproduce this. Adventure has capped randomized popups; Practice has a parallel implementation. | T3 priority/layout decisions, T7 implementation. Replay recorded Assassin/Shadow case at 1×/2×/4× and reduced motion; include simultaneous procs, Poison ticks, crit negation and gold hits in both combat implementations. Essential messages must remain legible within their area. |
| G07 | P1 / Improve | Effect display shows four groups and a `+N` inspector button, but the rendered synthetic-overflow button appears as a narrow blank red control. Code sets `clip_text` and shrink sizing without a minimum width. | T3 overflow design, T6 fix, T8 review. Reproduce 5/10/12 groups at all sizes; verify visible count, keyboard activation and access to every instance. Synthetic null art is fixture-only, not missing production icons. |
| G08 | P2 / Improve | Effect inspector uses ID-derived names and generic “Amount”; e.g. `rending_thrust`, `killers_mark` and `toxic_flurry` can leak historical names into event text. Most buff hover text describes counts/times without explaining the effect; Beguiling hover omits its elemental bonus. | T3 effect vocabulary, T5 text, T6 display. Inspect each of the ten buffs and both timed defenses; translate stable IDs to current names, label magnitudes/units, and explain independent instances and nearest expiry. |
| G09 | P2 / Improve candidates | At 22px on dark backgrounds Shadow Mastery is nearly black; Dusk Strike is subdued; Potency has low contrast. Toxic Tradeoff and Sharpened Edge have very thin silhouettes. Contact sheets and tree samples support review, not an automatic reassignment. | T3/T4 art review; T8 contextual check. Compare 22/32/52px, allocated/locked grayscale and stack/countdown overlays. Retain source-linked reuse; seek improved recognition without relying only on color. |
| G10 | P2 / Suspected lifecycle defect | Delayed proc audio schedules an autoload timer with captured speed; `_play_delayed_attack_sfx` calls playback without fight-generation/skip/exit cancellation. Popup callbacks do have generation guards. Existing audio tests pass but do not prove absence of stale delayed sound. | T7. Schedule multi-hit audio, immediately Skip/exit/retry/change speed; verify no stale sound crosses fights or screens. Validate with audible playback as well as event assertions. Dummy-driver audit runs do not certify sound quality. |
| G11 | P2 / Improve tooling | `build-data.js --check` fails “Stale generated data: catalog.json”; model checks still pass 92 identities/500 assets, while live mapping has 93 identities. | T3 reconciliation decision, T4 authoring integration. Reconcile Greed and current catalog metadata with backward-compatible old exports; verify freshness, import/export and source-linked buffs. Preserve frozen approved export and browser drafts. |
| G12 | P2 / Missing full validation evidence | Current samples establish usable layouts, not completed M7 accessibility, all-build text accuracy or human comprehension. Reduced motion is session-scoped and accessed through effect inspection; discoverability before/no active buffs needs review. | T3 access convention, T8 full matrix, T9 human feedback. Check keyboard discovery, no-buff state, non-color cues, contrast, long hover text and all target sizes. Do not mark future human playtesting complete. |

Source locations: [skill text](../project/scripts/ui/skill_tooltip_formatter.gd), [rank text](../project/scripts/ui/ranked_talent_view.gd), [skill bonus calculation](../project/scripts/resources/skill.gd), [resolver](../project/scripts/systems/combat_resolver.gd), [effect controls](../project/scripts/ui/combat_effect_icons.gd), [replay model](../project/scripts/ui/combat_presentation_state.gd), [popup layer](../project/scripts/ui/combat_popup_layer.gd), [Practice combat](../project/scenes/training_room/training_room_combat_view.gd), [audio manager](../project/scripts/autoload/audio_manager.gd).

## Temporary-effect and cue inventory

The common replay model observes resolver records. It does not mutate combat math. `begin`/`clear` reset state; `finish` clears active/held effects and cooldowns. Consumed buffs may remain visually held until the consuming cast impacts, while authoritative units are already spent. Preserve that accepted distinction and explain it in T3/T6.

| Effect | Existing display / lifecycle | Disposition and validation |
| --- | --- | --- |
| Footwork | Count up to five; refreshed three-second radial timer; consumed units held until Plunge impact | Retain mechanism; G08. Test partial spend, expiry at cast boundary, interruption and new grants during windup. |
| Readiness | One untimed charge; consumption and held-until-impact display | Retain; G08. Test unavailable Parry, grant from connected retrigger, consumption and reset. |
| Precision | Untimed charge; shared source icon from Precision Attacks | Retain; G08. Test Stab/Heavy Slash including eligible proc, no double guarantee with Dance. |
| Dance | Timed buff independent of shared skill cooldown | Retain; G08. Test activation, five-second expiry, repeated activation and macro/proc distinction. |
| Bypass | Timed stacks from Stab, three-second refresh/cap three | Retain; G08. Test refresh/cap/expiry and secondary Assassin. |
| Virulent Poison | Independent untimed charge instances; grouped total/instance details | Retain state; improve explanation G08. Test multiple activations, fueled natural/forced ticks and empty tick. |
| Master of Poisons | Timed resistance-ignore buff | Retain state; G08. Test five-second expiry with existing Decay/Poison; no claim that stored Decay disappears. |
| Touch of Darkness | Independent timed instances; grouped absorbed stacks and nearest expiry | Retain state; G08. Test no fuel and positive Consume; display +IAS/+physical bonuses and twelve-second lifetime. |
| Beguiling Presence | Absorbed Decay count, crit bonus and remaining time | Improve explanation G08. Include elemental contribution, independent instances and ten-second expiry. |
| Greed | Credited theft total, no timer/cap; reset each fight | Retain; G11 catalog follow-up. Check raw versus credited, rewards/stash exclusion, skip and retry. |
| Penetration / Potency | Fixed HUD positions, x0 gray inactive state; radial timer and hover; cap 50 | Retain mechanism; G09 Potency art. Check refresh/expiry, Death Pact durations, caps and negative-defense explanation. |
| Poison / Shred / Decay | HUD counts, snapshot updates, tick/Consume/cleanse journal | Retain mechanism; G06 crowding/G08 naming. Verify natural/forced tick depletion differs from Consume and immune Shred is not falsely reported cleansed. |

Existing combat cues cover normal/critical/Poison/proc damage, gold theft, crit-negated cross-out, dodge audio, cleanse/stun/slow stage effects, cast progress, shared cooldowns and unavailable Readiness attempts. Eleven defensive-mechanic icons and tooltips are present. G06/G10 concern readability and lifecycle, not absent combat calculations. No extra persistent Riposte/Death Pact buff identity is needed: their results already appear through cast outcomes or defense debuffs.

Intentional hard counters remain retained. Adventure's route guide explains pressures and precommitment choices. A confusing loss becomes a T9 observation with build, gear/gold, macro, seed, route and retry context; it is not evidence by itself that enemy values should change.

## Rendered review and mode matrix

Fresh rendered executions cover Adventure entry/guide, Test Mode and Practice. Full-content journeys exercise twelve ordered tree pairings and both roles. Screenshots include six pairings at three target widths; they do not depict every ordered pairing in every mode. T8 owns the complete cross-mode acceptance matrix.

| Sample / procedure | Finding | Evidence |
| --- | --- | --- |
| Adventure 1280 guide; four tree entry checks | Readable guide with scrolling and commitment text; retain | [guide](../project/reports/p6_m7_t2_visual/p6_m6_adventure_ui_test/p6_m6_t8/guide.png) |
| Practice Assassin/Shadow 1280 trees | Nodes, ranks and unlocks fit; Shadow Mastery remains visually dark | [trees](../project/reports/p6_m7_t2_visual/p6_full_content_journey_test/p6_m5_t10_combined/assassin-shadow-trees-1280.png) |
| Practice Bladedancer/Thief 1600 trees | Accepted geometry remains usable | [trees](../project/reports/p6_m7_t2_visual/p6_full_content_journey_test/p6_m5_t10_combined/bladedancer-thief-trees-1600.png) |
| Practice 125% text at 1280; Test Mode 125% at 1920 | Sampled controls and headers fit; retain baseline | [Practice](../project/reports/p6_m7_t2_visual/p6_t10_usability_test/p6_t10_usability/practice-text-125-1280.png), [Test Mode](../project/reports/p6_m7_t2_visual/p6_t10_usability_test/p6_t10_usability/test-text-125-1920.png) |
| Dense Assassin/Shadow, three seconds into 30-second Practice fixture, seed 7 | Damage labels overlap and cross panel edge; Poison labels overlap defense HUD | [1280](../project/reports/p6_m7_t2_visual/p6_full_content_journey_test/p6_m5_t10_combined/assassin_shadow_forward-combat-1280.png), [1920](../project/reports/p6_m7_t2_visual/p6_full_content_journey_test/p6_m5_t10_combined/assassin_shadow_forward-combat-1920.png) |
| Twelve synthetic groups, inspector open at 1600 | Entries scroll; overflow trigger lacks readable count; generic debug-like text | [inspector](../project/reports/p6_m7_t2_visual/p6_t10_usability_test/p6_t10_usability/synthetic-effects-inspector-1600.png) |
| All 93 mapped identities, contact sheets at 22/32/52px | No absent image; candidates G09 merit refinement review | [sheet 1](../project/reports/p6_m7_t2_audit/icons-1.png), [sheet 2](../project/reports/p6_m7_t2_audit/icons-2.png), [sheet 3](../project/reports/p6_m7_t2_audit/icons-3.png), [sheet 4](../project/reports/p6_m7_t2_audit/icons-4.png) |

The journey tree captures intentionally follow a rejected budget reduction (45→44); the visible “Allocated ranks exceed earned budget” feedback belongs to that action. It is not evidence that the accepted 45-point build is invalid. Synthetic effects lack production icons by design. Neither observation should be misfiled as missing live content.

T3 should start with G06 and decide message priorities, bounded placement, icon recognition conventions, overflow visibility, grouped-instance/held-consumption wording and minimum always-visible versus inspectable details. T4–T7 then address their linked findings. T8 reruns Adventure/Test/Practice at 1280×720, 1600×900 and 1920×1080, including supported 125% text, all tree roles and dense mixed builds. T9 separately records actual user observations.

## Validation and reproduction

Executed 2026-10-08 with installed Godot 4.7, Python/Pillow and Node. Commands use the existing isolated runner; fresh report names are required for reruns.

```powershell
python tools/p6/run_m6_closeout.py --report-name p6_m7_t2_inventory --tests p6_m7_presentation_inventory
python tools/p6/audit_m7_presentation.py
python tools/p6/run_m6_closeout.py --report-name p6_m7_t2_focused --tests icon_assignment_test p6_combat_presentation_test attack_sfx_audio_test
python tools/p6/run_m6_closeout.py --report-name p6_m7_t2_visual --visual --tests p6_m6_adventure_ui_test p6_t10_usability_test p6_full_content_journey_test
node tools/icon-lab/build-data.js --check
node tools/icon-lab/run_checks.js
```

- Inventory extraction passed: 44 talents / 140 ranks / 23 skills. Asset audit passed: 93 mappings / 84 paths; matching hashes/dimensions; no missing runtime mapping. [Coverage](../project/reports/p6_m7_t2_audit/coverage.json).
- Three focused suites passed. [Summary](../project/reports/p6_m7_t2_focused/summary.json).
- Three rendered suites passed: Adventure UI 62 checks, usability 152, full-content journeys 3,243. [Summary](../project/reports/p6_m7_t2_visual/summary.json). Passing assertions coexist with the visual defects documented above.
- Icon Lab's 15 model checks passed; freshness check **failed** with stale catalog data. [Results and logs](../project/reports/p6_m7_t2_audit/static_checks.json). G11 owns reconciliation; no regeneration masked the failure.
- All three isolated-run `isolation.json` records report unchanged protected project files. User data was redirected per suite; audio used Dummy. Certificate-store and resource-at-exit diagnostics persist in logs and remain M9 qualification work.

The audit added no gameplay changes. Automated/rendered evidence is new; human playtesting and final M7 visual acceptance remain outstanding. T2 is complete because all coverage and identified gaps have an implementing owner and a validation case.
