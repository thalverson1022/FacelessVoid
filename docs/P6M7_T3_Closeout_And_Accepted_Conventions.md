# M7-T3 — Accepted visual conventions and closeout

> **Retained mechanics/presentation reference.** Work status and scope are maintained in the current M9 tracker and phase roadmap. Older checkpoint/save-policy labels below are historical; the approved M9 save reset applies at implementation. [Current context](P6_Project_Onboarding_Context.md).

Status: **Complete — user-requested closeout, 2026-10-09 (P6M7-D015).**

This is the current T3 design record. It supersedes the rejected lanes/event-list proposal and the prototype's historical pending-review instructions. The user accepted the Test Mode changes except combat-log changes, requested promotion to live modes, and then explicitly requested T3 closeout. M7 remains in progress; T4–T11 are not complete.

## Accepted conventions

| Area | Accepted direction and current scope |
| --- | --- |
| Skill categories | Attack red (`#EE8880`), Debuff violet (`#D2B3EE`), Self Buff pale blue (`#9ED5EF`). Preserve recognizable art and readable labels; color is supplementary. |
| Skill buttons | Bottom-edge accents in Available Skills and the macro; full colored fills on talent-tree skill unlock boxes and skill-granting nodes. Covers all four trees in Adventure, Test Mode and Practice. Passive talent art retains its existing treatment. |
| Geometry | Preserve button dimensions, hit areas and selection behavior. Small automatic-unlock artwork fits a 24×24 region above its point label. No added category symbols on buttons. Locked treatments remain subdued. |
| Combat feedback | Preserve the established floating-text presentation. The reviewed Stab, Venom Jab, Poison Vile and Virulent Poison category treatment is promoted to Adventure and Practice. The two reviewed non-attack skills show applications/charges rather than direct damage and use subtle non-lunging motion. No boxed combat notices. Other skills' bespoke wording/animation is not implicitly redesigned. |
| Cooldowns and motion controls | Cooldown-blocked casts produce no floating text. Category-preview and reduced-motion prototype controls remain hidden. Existing motion accessibility behavior remains; broader review belongs to T8. |
| Status layout | Penetration and stacks appear below Shred; Potency below Decay in every mode. Retain timers and inactive-state readability. |
| Talent allocation | Each selected tree shows invested points / total ranks (currently x/35) in its upper-right corner. Remove the redundant overall points subtitle. Keep Practice's editable point budget and existing allocation restrictions. Invalid/full-node clicks do not create layout-shifting status messages. |
| Combat log | Excluded from live promotion. Adventure and Practice use the original plain log and per-event timestamps. The experimental colored/grouped summary remains Test Mode only; it is not an accepted replacement. |
| Mechanics | No combat values, skill mechanics, unlock rules, persistence policies or intentional counters changed by this closeout. |

## Remaining design details and downstream owners

T3 closes on the accepted direction above with these explicit handoffs, not on adoption of every original proposal:

- **T4 — Icon production/integration:** retain approved identities and mappings as the baseline. Review the T2 contrast/silhouette candidates and reconcile Icon Lab freshness. Exact asset edits or replacements require concrete review. Historical R3 is not blanket art approval.
- **T5 — Tooltip clarity:** carry out the full terminology/tooltip rewrite across all trees. The four-skill prototype is an example, not proof that all descriptions are complete.
- **T6 — Temporary effects:** resolve effect density, overflow and inspectability as part of that task, using current displays as the baseline. The rejected package's four-group limit, `+N more` and permanent Effects button are unapproved options, not requirements. Preserve authoritative stacks, charges, timers and lifecycle behavior.
- **T7 — Combat cues:** review dense combat, collisions, priorities and player-facing audio lifecycle with the accepted floating-text approach. Do not reintroduce the rejected lanes, event-list layout or boxed notices without new direction.
- **T8–T10:** integrated sizes, enlarged text, non-color cues, accessibility and further user playtesting remain milestone work. T3 approval does not constitute final M7 acceptance.
- **T11:** final affected regression and milestone handoff remain outstanding.

## Evidence and acceptance

Human evidence: iterative feedback in this task rejected the earlier layout and boxed notices, selected bottom-edge/full-fill icon treatments, approved the per-tree counters, requested live promotion excluding log changes, and explicitly requested documentation and T3 closeout.

Runtime verification was performed before this documentation-only closeout, using `python tools/p6/run_m6_closeout.py` with isolated project copies and save paths:

| Report | Command arguments and result |
| --- | --- |
| [Promotion checks](../project/reports/p6_m7_live_promotion_checks/summary.json) | `--report-name p6_m7_live_promotion_checks --tests p6_m7_category_preview_test p6_talent_ui_test p6_skill_ui_test training_room_combat_view_test combat_screen_test p6_m7_log_grouping_test`: five passed; Practice's old color assertions failed and were corrected for the approved attack color. |
| [Final Practice/category checks](../project/reports/p6_m7_live_promotion_verified/summary.json) | `--report-name p6_m7_live_promotion_verified --tests training_room_combat_view_test p6_m7_category_preview_test`: both passed, including buff charges, cooldown suppression and motion cleanup. |
| [Rendered cross-mode checks](../project/reports/p6_m7_live_promotion_visual/summary.json) | `--report-name p6_m7_live_promotion_visual --visual --tests p6_m7_icon_accents_test`: passed; all-tree treatments at three sizes plus Adventure/Practice counter and subtitle evidence. |

Reports contain source fingerprints and isolation records for their tested revisions. Historical prototype reports remain evidence of intermediate states, not current acceptance. No gameplay suites were rerun for this documentation-only closeout; current-status consistency and local links were checked.

Next: **M7-T4 — Icon production and integration**, starting from the [T2 audit](P6M7_T2_Presentation_And_Asset_Audit.md). The [M7 tracker](P6M7_Icons_And_Player_Feedback_Completion_Tracker.md) remains authoritative for task status.
