# M7-T5 closeout and accepted conventions

> **Retained mechanics/presentation reference.** Work status and scope are maintained in the current M9 tracker and phase roadmap. Older checkpoint/save-policy labels below are historical; the approved M9 save reset applies at implementation. [Current context](P6_Project_Onboarding_Context.md).

2026-10-15. **T5 Complete under user acceptance P6M7-D039. M7 remains In progress: T1–T5 Complete; T6–T11 Not started. Next: T6 temporary-effect display completion.** This is a documentation-only closeout; T6 implementation has not started.

The user accepted the finished tooltip work and explicitly requested closeout and documentation updates. This acceptance supersedes earlier instructions excluding step 7 and dated “T5 In progress” statements. Those records remain historical evidence, not current next-step instructions. Human acceptance of this format is distinct from automated checks and does not complete later integrated accessibility, user playtesting or milestone acceptance.

## Accepted presentation

The shared current format covers all **44 talents / 140 ranks and 23 skills**, across Adventure, Test Mode and Practice, including tree skill boxes, Available Skills, macro hovers and current-only Active Talents. It favors short core rules and basic live numbers; deeper formulas, proc ordering and interaction exceptions remain in internal detail/reference material and can be explored in Practice. Omitted detail is intentional scope, not a mechanics change or certification of every possible build interaction.

- Item-style translucent black tooltip background; original 32px icon, cream 22px VT323 name and top alignment. Skill category labels and qualitative cast brackets remain. Attacks omit Cooldown and Duration rows; Debuff/Self Buff Cooldown/Duration use accepted per-skill exceptions. Damage is current-build planning damage, noncritical and before defenses.
- Talents retain full current effects, gold scaling values with unchanged signs/operators, separated description/value groups, and concise Next containing only changed values or new/changed rules. Rank zero shows its explanation once; maximum rank and rule-only unlocks do not gain an empty Next. Requires text is absent; actual allocation gates/prerequisites remain enforced.
- Canonical whole-phrase keywords use the [names/aliases reference](P6M7_T5_Presentation_Keyword_Reference.md). Named Buff references are existing Self Buff cyan #9ED5EF; statuses including Potency and Penetration, stats and skill references are cream. Crit Chance/Crit Damage are the short canonical forms. Talent values retain gold; ordinary prose is not globally capitalized. No italics or formula expansion is added.
- Active Talents shares current-rank rows and the same value/keyword treatment at its existing compact size; names, ranks and subclass portraits remain, individual talent icons are omitted. Four tree-ID backgrounds use unmodified copied artwork, proportional cover cropping and runtime dark overlay; tree swaps follow stable IDs, and empty secondary panels retain their prior treatment.

The keyword registry/reference is a foundation for a possible future compendium. **Compendium UI and mechanical-definition pages are not implemented.**

## Accepted decision trail

| Decisions | Accepted result / evidence |
| --- | --- |
| D025–D026 | [Minimal skill format](archive/m7/P6M7_T5_Minimal_Skill_Tooltip_Design_And_Implementation.md) and [all-talent structured format](archive/m7/P6M7_T5_Minimal_Talent_Tooltip_Design_And_Implementation.md). |
| D027–D028 | Active Talents icon simplification, [tree backgrounds and shared current effect text](archive/m7/P6M7_T5_Tree_Backgrounds_And_Active_Talent_Text.md). |
| D029 | [Neutral talent rules, no Requires and stack terminology](archive/m7/P6M7_T5_Neutral_Talent_And_Stack_Wording.md). |
| D030–D032 | Source-backed [Thief](archive/m7/P6M7_T5_Thief_Tooltip_Revision.md), [Assassin](archive/m7/P6M7_T5_Assassin_Tooltip_Revision.md) and [Shadow](archive/m7/P6M7_T5_Shadow_Tooltip_Revision.md) revisions, including dynamic application counts and user-clarified Death Pact scope. |
| D033 | [Gold scaling values, spacing and changed-only Next](archive/m7/P6M7_T5_Talent_Value_Hierarchy_And_Next_Rank_Polish.md). |
| D034–D037 | Later per-tree wording/punctuation refinements retained in the linked tree/design evidence and tracker. |
| D038 | [Canonical keywords and cyan Buff references](archive/m7/P6M7_T5_Keyword_Capitalization_And_Buff_Coding.md), shared rich/plain output and glossary. |
| D039 | User accepts T5 as finished and requests this closeout; no additional implementation or numerical change. |

The [original audit](archive/m7/P6M7_T5_Tooltip_Audit_And_Verification.md) retains live inventory, all-rank dispositions, source mechanics review and earlier verbose-format evidence. Later accepted minimal-format decisions supersede that historical player-facing wording; its original closeout exclusion is superseded by D039.

## Evidence and closeout verification

Latest accepted D038 [five focused suites](../project/reports/p6_m7_keyword_coding_focused_final/summary.json) pass: 1,423 keyword checks, 7,940 talent checks, 748 skill checks, 1,728 shared Active Talents/background checks and existing build panels. These are assertion counts, not distinct mechanics or new human playtests. Live current-build provider cases include base/gear/talent/doubling refresh. Earlier D033 and per-tree evidence establishes the hierarchy and wording revisions; do not add their overlapping counts into a new coverage total.

D038 [69 main actual captures](../project/reports/p6_m7_keyword_coding_rendered/summary.json) plus [three Precision hovers](../project/reports/p6_m7_keyword_precision_rendered_final/summary.json) pass: **72 final captures**, with inspected cyan/gold/current/Next/max examples, all modes, enlarged text and fitted wrapped heights. The narrow latest matrix complements earlier 1280×720/1600×900/1920×1080 rendering; it does not mean every rank was captured at every size. All three final reports record unchanged source/save isolation with disposable per-suite save environments.

[Accepted D038 fingerprints](../work/t5_keyword_coding_before/final_verification.json) reconcile current presentation sources to focused/main/supplement report baselines. [D039 documentation-only recheck](../work/t5_d039_closeout_verification.json) confirms no accepted source drift and all **330 protected mechanics files unchanged**. Updated approved Shadow JPEG remains SHA256 `458fe5901d0ed4ddc5afe4003d792a4c35c92659cb51ee4addbb4108bd6b43da`; the gear “increased stacks” label is preserved. Earlier source-copy checks remain in the background evidence; no bitmap edits or new asset copying occurred at closeout. No code, real player saves, commits or publication were changed for D039. Relative links and current task statuses were checked; no gameplay suite was rerun for documentation-only edits.

## Remaining owners and boundaries

| Audit item / work | Disposition and next owner |
| --- | --- |
| G01–G05 wording/rank/intrinsic issues | Addressed within T5 audit and accepted later minimal wording. Detailed math stays in reference/internal detail; omitted caps, formulas and cross-skill exceptions are intentional minimal-format decisions. |
| G08 effect vocabulary/magnitudes | T5 text correction complete; live temporary-effect density, timers, independent-instance access and lifecycle display remain T6 validation. |
| G07 effect overflow / narrow inspector button | **Deferred to T6**, then T8 integrated review. Historical synthetic null-art overflow is fixture-only, not missing production art. |
| G06 dense overlapping combat popups | **Deferred to T7**; verify actual dense combat and playback speeds. |
| G09 icon recognition candidates | T4 approved refinements retained; T5 reviewed current installed art without a new compelling replacement. Intentional source reuse remains; contextual recognition/user feedback belongs to T8–T9, with concrete approved refinements through T10 if needed. |
| G10 delayed audio lifecycle | **Deferred to T7**, including real audible skip/exit/retry/speed review; dummy-driver tests do not certify sound quality. |
| G11 stale Icon Lab metadata | Resolved in T4 integration, not a fresh T5 defect; retain its linked authoring compatibility evidence. |
| G12 integrated accessibility/comprehension evidence | T8 full review, T9 user playtesting and T10 acceptance/refinement remain **Not started**. T5 samples do not close them. |
| Balance and unusual full-run builds | M8 broader integrated refinement; retain intentional hard counters and current values unless explicitly changed. |
| Certificate/shader/export and general teardown warnings | M9 engine/environment/export qualification; not hidden as completed by tooltip checks. |

T6 is the next planning/implementation task. No temporary-effect redesign, T7 cue implementation, compendium UI or broader balance work is authorized by this closeout alone.
