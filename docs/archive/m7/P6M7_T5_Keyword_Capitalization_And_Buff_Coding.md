# T5 keyword capitalization and Buff coding

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. [Current context](../../P6_Project_Onboarding_Context.md).

Current task status: **Complete — user accepted T5 under D039 on 2026-10-15.** See [closeout and accepted conventions](../../P6M7_T5_Closeout_And_Accepted_Conventions.md).

The dated status, proposals and evidence below are historical snapshots; later accepted conventions and D039 supersede earlier In progress/closeout-excluded instructions.

D038, 2026-10-15. **T5 remains In progress.** This implements the approved presentation revision without milestone closeout.

A shared [keyword registry](../../../project/scripts/ui/presentation_keywords.gd) normalizes skill/talent effect text and their plain fallbacks. Names and aliases come from stable effect/stat IDs and live skill/talent resources. Matching is case-insensitive, longest whole phrase first, with Unicode word boundaries and possessive support. Distinct Physical Damage/Base Physical Damage/Increased Physical Damage phrases stay distinct; generic gold, stack, attack, hit and damage prose is unchanged. Crit Chance/Crit Damage are canonical; Critical Chance/Critical Damage are aliases. Full Buff names retain lowercase connective “of”. The [reference glossary](../../P6M7_T5_Presentation_Keyword_Reference.md) lists 103 consolidated names from 112 source entries, without mechanical definitions.

Named Buff references use the existing Self Buff cyan **#9ED5EF**. Poison, Shred, Decay, Potency and Penetration remain cream statuses. Stat and skill references remain cream, including skill unlock rows. Talent scaling values retain gold and their existing signs/operators; static embedded numbers remain ordinary text. Safe RichTextLabel push_color/add_text rendering does not interpret BBCode or add italics. Shared talent rows carry this treatment into current-only Active Talents. Skill headers, category colors, Cooldown/Duration styling and existing exceptions remain unchanged. Tree/Active Talents intrinsic and bonus summaries receive canonical capitalization as plain cream text. Gear, logs and compendium are outside this pass.

The source-backed rank rows, compact skill effect rules and planning-damage function are byte-for-byte preserved within their method blocks. D034–D037 punctuation/wording remains in those rules; normalization changes only approved keyword casing and aliases at output. Stable keys, changed-only Next, rank-zero explanations, maximum-rank omission of Next, absence of Requires, current-build counts and live provider refresh remain intact.

## Verification

Final focused command:

```powershell
python tools/p6/run_m6_closeout.py --report-name p6_m7_keyword_coding_focused_final --tests p6_m7_keyword_coding_test p6_m7_talent_hover_test p6_m7_minimal_skill_hover_test p6_m7_tree_background_active_text_test build_panels_test
```

[All five suites pass](../../../project/reports/p6_m7_keyword_coding_focused_final/summary.json): 1,423 keyword checks, 7,940 talent checks, 748 skill checks, 1,728 shared Active Talents/background checks, and existing build panels. Coverage includes all 44 talents/140 ranks and 23 skills, aliases, longest-span and word-boundary behavior, ambiguous Shred status resolution, cream debuffs/cyan Buffs, gold precedence, literal text safety, rich/plain parity and unchanged category colors. Distilled Corruption still refreshes 5/7/13/26 through base/gear/talent/doubling providers in all modes.

Actual hover rendering commands:

```powershell
python tools/p6/run_m6_closeout.py --report-name p6_m7_keyword_coding_rendered --visual --tests p6_m7_keyword_coding_visual
python tools/p6/run_m6_closeout.py --report-name p6_m7_keyword_precision_rendered_final --visual --tests p6_m7_keyword_precision_visual
```

[Main 69 captures](../../../project/reports/p6_m7_keyword_coding_rendered/summary.json) and [three Precision supplement captures](../../../project/reports/p6_m7_keyword_precision_rendered_final/summary.json) pass: **72 actual captures** across Adventure/Test/Practice. The narrow matrix covers all trees, zero/partial/max/unlock states, long current/Next rules, cyan Buff paragraphs, cream statuses, gold values and dense shared Active Talents. Actual enlarged RichTextLabel fonts are stressed at 125% (tooltip 25px, Active Talents 16px); fitted wrapped heights settle and hover bounds remain inside the viewport. Long Mastery also samples 1600/1920; principal stress is 1280×720. Precision supplement supplies actual max-rank hovers in all three modes without repeating the passing main batch.

Inspected examples:

- [Fancy Footwork, cyan Buffs and gold current/Next](../../../project/reports/p6_m7_keyword_coding_rendered/p6_m7_keyword_coding_visual/keyword_coding_visual/test-fancy_footwork-1280-125.png).
- [Parry Strike, cyan Readiness and unchanged Attack category](../../../project/reports/p6_m7_keyword_coding_rendered/p6_m7_keyword_coding_visual/keyword_coding_visual/test-parry_strike-1280-125.png).
- [Precision Attacks, full-name matching and no Next at max](../../../project/reports/p6_m7_keyword_precision_rendered_final/p6_m7_keyword_precision_visual/keyword_coding_visual/practice-precision-attacks-1280-125.png).

Independent parent review also inspected enlarged Death Pact (all four statuses cream), Touch of Darkness (canonical stat names and unchanged Self Buff category), and dense Active Talents. No clipping/readability issues remained in the inspected samples. These are formatting checks, not a new individual mechanics audit or exhaustive capture of every rank.

All three accepted reports record unchanged source/save isolation with per-suite scratch APPDATA/LOCALAPPDATA; real saves were not used. [Final fingerprint reconciliation](../../../work/t5_keyword_coding_before/final_verification.json) matches current production sources to every accepted report baseline. All **330 protected mechanics files** remain unchanged. Shadow JPEG is separately hashed because the runner does not track JPG assets: unchanged `458fe5901d0ed4ddc5afe4003d792a4c35c92659cb51ee4addbb4108bd6b43da`. Tooltip panel/input helper and gear formatter hashes are unchanged from the pre-change capture. Skill formatter/panel intentionally changed in this revision.

Earlier reports are superseded: initial keyword expectations exposed generated uppercase “Of” names and empty effect bodies on direct attacks; explicit Buff canonical names and appropriate empty-body assertions fixed those checks. An expectation-edit pass accidentally capitalized test metadata keys and retained one lowercase stat assertion; production IDs never changed, and those fixture assertions were corrected. The first inherited Precision supplement was cancelled because the isolated runner replaced its inherited initializer; the final self-contained fixture passes. Existing engine certificate-store/teardown warnings do not correspond to final assertion or script failures. No additional broad combat suites were needed for this presentation-only change.
