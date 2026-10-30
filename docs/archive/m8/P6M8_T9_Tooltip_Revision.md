# T9 tooltip and Meditation revision

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. [Current context](../../P6_Project_Onboarding_Context.md).

2026-10-24, D085. Implements the user's follow-up to the initial T9 presentation review. T9 remains Pending input for overall acceptance; T10–T12 have not started.

## Changes

- Item effect heading is **Legendary Effect:**. Requested concise wording and line breaks replace the previous detailed mechanical explanations; spelling is corrected. Wyvern and Locket retain their existing effect copy; Nightkiss uses a short two-line grant/Consume description.
- Shared item headers use rarity, universal slot and item type: Weapon / Dagger, Charm / Necklace and Trinket / Ring. This includes ordinary weapons and the Legendary roster without changing generator families or slot/save identities.
- The Crown display name is **The Crown of Concentration**. Its old stable ID and resource path remain valid.
- Parry Strike explains that it requires and consumes Readiness, granted by any skill retrigger. Existing combat eligibility is unchanged.
- Meditation now increases **all ordinary damage**, including natural/forced/consumed/retriggered Poison. It keeps the additive `1 + 0.2 × stacks` multiplier, five-stack cap, existing grant order, refresh and expiry. Exsanguinate remains separate health removal and gains no damage multiplier.
- With Signet equipped, the main stat panel displays **Crit Chance:0%** and **Crit Damage:0%**, alongside converted Attack Speed and Increased Physical Damage. Its read-only replay observer updates conversions for temporary Crit Chance grants/expiry and combat gold changes; equipping/unequipping still updates through the existing build signals. Raw inputs are retained for correct conversion and are not overwritten by display values.
- Leaving Adventure or Practice during playback now removes that view's owned replay metadata. This prevents abandoned temporary conversions leaking onto a later screen; an older view cannot clear a newer replay on the same state. No save/run-state implementation changes are needed.

Only Meditation's damage scope changes gameplay. Wording such as Bejeweled's “instantly” and Death's Door's “x100%” is the requested presentation; existing minimum-cast/cooldown and missing-attempt formulas remain unchanged. Loot rules, authored affix values, supplied art and save schemas are unchanged.

Multi-line effect handling also needed a tooltip fix: flattened base lines are counted when appending offer/comparison footers, preventing repeated effect lines or dropped price text.

## Verification

All launches used copied projects and redirected saves/userdata under `work/m8_t9_presentation`; real player saves and sibling Enigma were not used. [Revision manifest](../../../work/m8_t9_presentation/tooltip_revision_verification.json) records selected runs and tested-source hashes. Original failed attempts remain local.

| Suite | Result |
| --- | --- |
| Meditation all-damage cases |204 checks: physical/Poison packet families, fresh recursive calculation, consumed fuel, cap/refresh, exact expiry, no double application and Exsanguinate exclusion |
| Live Signet stat panel |32 checks: real Signet+Coin overcap conversion, zero critical output, equip replacement, recorded Beguiling grant/expiry, gold changes, raw-state preservation and actual Adventure/Practice teardown |
| All16 item presentations |455 checks: authored values, revised copy, actual production widgets, comparisons, geometry/state purity, each effect line once and price/footer retention |
| Skill presentation |109 checks |
| Minimal skill hover regression |810 checks |
| T7 combat regression |149 checks; expectations updated for Meditation's intentional Poison increase |
| T9 combat feedback |102 checks |
| Actual Practice/shop UI |72 checks and all16 fixed-item editor captures |
| Actual native skill hovers |63 checks and six1280×720 captures, including Parry Strike |
| Existing Practice combat view |Pass after replay-teardown cleanup |

Engine certificate-store and resource-at-exit diagnostics remain as previously documented. An initial new-test parse issue, an obsolete physical-only feedback expectation and an intermediate missing-metadata access were corrected; the final selected runs exclude those failures. No new balance, earned-run or export acceptance is claimed.

## Screenshots

Original captures are1280×720; Godot's logical viewport is1600×900 with the existing0.8 scale. All16 editor panels and the six native skill popups fit. The shop comparison uses the production builder mounted in a temporary high CanvasLayer for capture, preserving the original two-box presentation.

- [Samurai revised effect](../../../work/m8_t9_presentation/t9_revision_final/project/reports/t9_ui_review/practice_helm_of_the_samurai.png).
- [Signet three-line effect and zero-percent critical stats](../../../work/m8_t9_presentation/t9_revision_final/project/reports/t9_ui_review/practice_signet_of_the_old_kings.png).
- [Necklace header and comparison](../../../work/m8_t9_presentation/t9_revision_final/project/reports/t9_ui_review/adventure_signet_comparison.png).
- [Actual Parry Strike hover](../../../work/m8_t9_presentation/t9_revision_final/project/reports/t9_skill_hover/parry_readiness.png).

These changes are local follow-up work after checkpoint `7050114`; no new commit or push is implied by this report.


## D088 — Nightkiss / Exsanguinate wording and Combat Log presentation

2026-10-25. User requested wording changes before further balance work. Nightkiss now reads:

> Grants: Exsanguinate
> Consume all Shred to remove 2x the Armor Shred value in health.

Exsanguinate's compact and detailed effect summaries now read **Removes <value> health per stack of Shred consumed**, resolving `<value>` from `2 × current Shred Value`. Canonical keyword capitalization is retained. Technical conditions remain available in the detailed reference.

Combat Log totals/DPS, Damage By Skill, timeline bar amounts/colors/hovers and narrative now present Exsanguinate as damage. Roots, repeats and zero-stack contacts are handled; separate health-removal chart/chip/type are removed. Values are included exactly once. Core combat, native Balance Lab counters, mitigation/crit/consumption/retrigger rules and the 2× coefficient are unchanged. This presentation decision supersedes the earlier separate-health-removal Combat Log convention only; existing Practice HUD, recap and playback counters retain their current behavior. No balance reduction is adopted.

Verification: skill presentation109 checks, item presentation456, actual skill-hover63 and actual UI72; focused mixed-log20 checks, existing combat feedback102, and log-grouping regression pass. The mixed fixture includes physical damage, Poison, Exsanguinate roots/repeats and zero-stack contacts and proves log sums while preserving native counters. All checks/rendering used isolated copies/saves. [Evidence manifest](../../../work/m8_t9_presentation/d088_verification.json) verifies tested-source parity and protected system hashes.

Actual-size screenshots inspected: [Nightkiss](../../../work/m8_t9_presentation/exsang_text_revision/project/reports/t9_ui_review/practice_nightkiss_kitana.png), [Exsanguinate hover](../../../work/m8_t9_presentation/exsang_text_revision/project/reports/t9_skill_hover/exsanguinate_nightkiss.png), [combined Combat Log](../../../work/m8_t9_presentation/exsang_log_1024/project/reports/t9_exsanguinate_log/mixed_damage.png). T9 overall review remains Pending input; T10 remains In progress. D087 simulation measurements remain valid because combat calculations are unchanged.


## D090 — Cannot-Retrigger technical conditions

2026-10-25. User removed Exsanguinate retriggers. Detailed skill conditions/reference now state **Cannot Retrigger** and remove captured-repeat promises. Requested D088 compact wording and Combat Log damage presentation remain. The live2× coefficient is retained;1×is experimental. [D090 implementation and DPS evidence](P6M8_T10_Exsanguinate_No_Retrigger_Comparison.md). Historical repeat-oriented test fixtures are updated to root-only Exsanguinate; ordinary attack/Poison repeats still exercise Meditation and combined log accounting.


## D091 — Adopted 1× and no retriggers

2026-10-25. User approved the production balance change. Nightkiss now says **Consume all Shred to remove 1x the Armor Shred value in health.** Exsanguinate’s resolved effect says **Removes <value> health per stack of Shred consumed** followed by **Cannot Retrigger**. Compact and detailed summaries agree; current Shred Value is used once. [Adoption, verified source and rendered item/skill screenshots](P6M8_T10_Exsanguinate_Adopted_Balance.md). This supersedes earlier 2× wording. Combat Log still combines Exsanguinate with damage.
