# M7-T5 Minimal Skill Tooltip Design and Implementation

Current task status: **Complete — user accepted T5 under D039 on 2026-10-15.** See [closeout and accepted conventions](P6M7_T5_Closeout_And_Accepted_Conventions.md).

The dated status, proposals and evidence below are historical snapshots; later accepted conventions and D039 supersede earlier In progress/closeout-excluded instructions.

Status: **In progress; general skill format implemented for review. T5 closeout and individual skill/talent audit remain excluded.**

Approved direction: P6M7-D025, 2026-10-14. This supersedes the previous verbose live skill hover format from the [T5 audit](P6M7_T5_Tooltip_Audit_And_Verification.md). It does not supersede combat mechanics, the detailed formatter or the unchanged talent format.

## Player-facing format

- Exact theme-chain `TooltipPanel` background used by item tooltips: semi-transparent black, with no opaque `CardStyle` card override.
- Header: original 32x32 icon and cream 22px VT323 skill name, both top-aligned.
- Second line: 18px colored category and qualitative cast bracket. Attack red, Debuff violet, Self Buff blue; Fast / Normal / Slow / Brief. No numeric cast time.
- Debuff/Self Buff timing: separate 18px cream Cooldown and Duration lines below type/cast. Cooldown shows seconds or `None`; Duration shows seconds, `Instant`, `Until charges are spent`, or `Until stacks are depleted`, as appropriate. Attack tooltips omit both timing lines. These are effect lifetimes and cooldown durations, not live countdowns.
- Damaging skills: 20px current-build planning damage range, noncritical and before enemy defenses. This excludes live Poison, fight theft and temporary combat effects. The neutral packet calculator preserves ordinary build multipliers and conversion handling.
- Basic effect: 20px short text, usually one or two lines. Show intrinsic basic numbers: on-hit stack count, Death Strike +2 **base** physical per Poison stack, buff strength/duration, critical-only Big Score factor and current-build credited theft. Pure attacks need no duplicate damage sentence.
- Omit formulas, gear explanations, talent/other-skill proc interactions, ordering, caps, cooldown interaction rules, unlock sources, live stash and macro slot/removal instructions. Practice supports discovery of deeper interactions.

Steal/Pick Pocket display only the current-build credited amount (floored once), e.g. `Steals 15 gold.` at 55% Increased Gold. Raw theft values remain in detailed mechanics text. Death Strike's range starts at zero live Poison, with the separate +2 base-per-stack clause; it never implies an unscaled +2 final damage. Touch/Beguiling duration applies to both listed per-consumed-stack bonuses.

## Implementation and scope

`skill_hover_formatter.gd` supplies one structured model and plain-text fallback. `skill_hover_panel.gd` renders it. `IconTooltipButton` accepts an optional structured skill provider; its existing talent/generic path remains unchanged.

The provider is installed in Available Skills, macro slots and automatic skill-unlock boxes in Adventure, Test Mode and Practice, including locked automatic boxes. Skill-granting talent nodes retain the talent Current/Next/gate format. Test Mode's old four-skill category comparison does not bypass this skill hover renderer. Existing icon-button accents, art, hit areas, selection/removal/locking and combat presentation are preserved.

Detailed `SkillTooltipFormatter`, Combat Mechanics Reference, combat math, resources, identities, saves and source textures are unchanged. The retained skill-details component remains outside current live palette/macro navigation; no new affordance is introduced.

## Evidence

Pre-step copies and [SHA256s for affected existing files](../work/t5_minimal_skill_before/hashes.json). These separate the current approved format from the earlier T5 audit's changes in the already dirty checkout.

- `python tools/p6/run_m6_closeout.py --report-name p6_m7_minimal_skill_final --tests p6_m7_minimal_skill_hover_test p6_skill_ui_test skill_tooltip_formatter_test build_panels_test`: the first three pass. The new focused suite checks **500 assertions**, all 23 useful skills/basic numeric values, actual cross-surface/mode providers, exact item background, category-comparison immunity and original talent branch. Existing interaction checks retain add/duplicate/right-remove/lock behavior and changed-gear hover resolution. Build-panels initially failed an assertion-edit variable name at parse time; its corrected-only rerun is recorded separately below.
- `python tools/p6/run_m6_closeout.py --report-name p6_m7_minimal_skill_build_verified --tests build_panels_test`: **passes**. Focused verification of the existing build-panel assertions updated for approved minimal Hold/damage/no-slot text.
- `python tools/p6/run_m6_closeout.py --report-name p6_m7_minimal_skill_rendered_final --visual --tests p6_m7_minimal_skill_hover_visual`: **passes, 78 actual engine-controlled skill hovers**. Matrix covers three modes, 1280x720 / 1600x900 / 1920x1080, all three categories, normal/125% text; plus live macro/tree hovers and Death Strike/Touch examples at 1280. Font stress is applied before popup placement; it is a fixture override, not a new user setting. Art remains 32px during enlarged-text stress.

The six renderer/provider production source files match SHA256 baselines in the final focused, build-panel and rendered reports; all three source-isolation records are unchanged. Representative actual renders were inspected: Venom Jab at 1280, Poison Vile at 1600, Practice Virulent at 1920/125%, Death Strike/Touch at 1280/125% and Practice automatic skill-box hover. Headers, category colors, basic numbers, background and popup bounds are readable.

All commands use disposable project copies and report-local save paths, plus isolated APPDATA/LOCALAPPDATA. Exact commands, source fingerprints and isolation records are retained in the report directories. Adventure rendering uses the retained isolated fixture with Adventure presentation; this is not a campaign journey or human comprehension acceptance.

Talent method bodies (`effects`, `talent_card`, `talent_tooltip`, `reason`) are identical to the pre-step copies; the detailed formatter is byte-identical. No source art was edited. Initial rendered diagnostics involved a fixture constant named `Panel` shadowing the engine class and a void-return ternary; corrected renders supersede them. Certificate-store and teardown/resource warnings remain recorded environment/M9 boundaries.

This implements the approved general language. Further user review of individual skill/talent wording is reserved, and T5 stays **In progress**.

## Separate cooldown field — 2026-10-14

User requested cooldown time separately from effect text. The structured model, plain-text fallback and renderer now show `Cooldown: 8s`, for example, or `Cooldown: None`. Talent rendering and effect copy are unchanged.

- `python tools/p6/run_m6_closeout.py --report-name p6_m7_skill_cooldown_verified --tests p6_m7_minimal_skill_hover_test`: **pass, 562 checks**, including all 23 skills, separate cooldown controls across surfaces/modes, Pick Pocket 8s, Touch of Darkness 30s and Stab without cooldown. [Summary](../project/reports/p6_m7_skill_cooldown_verified/summary.json).
- `python tools/p6/run_m6_closeout.py --report-name p6_m7_skill_cooldown_visual_final --visual --tests p6_m7_minimal_skill_hover_visual`: **pass, 78 live hover renders** at three sizes/modes and normal/enlarged text. Virulent Poison, Touch of Darkness and Venom Jab representative screenshots were inspected. [Summary](../project/reports/p6_m7_skill_cooldown_visual_final/summary.json).

Both accepted runs use disposable saves and report unchanged source isolation. Initial focused checks rejected trailing decimal zeros; those were removed. The initial rendered batch overlapped that correction and is excluded from final evidence. T5 remains In progress.

## Timing by skill type — 2026-10-14

User refined the format: Attack has no cooldown line; Debuff and Self Buff have separate Cooldown and Duration lines. Fixed durations are removed from effect sentences to avoid repetition. Pick Pocket is instant, Virulent Poison lasts until charges are spent, and Poison Vile lasts until stacks are depleted. Blinding Powder shows current-build Potency duration (3s, or 4–6s with Death Pact); no interaction explanation is added.

`python tools/p6/run_m6_closeout.py --report-name p6_m7_skill_timing_types_focused --tests p6_m7_minimal_skill_hover_test`: **pass, 605 checks**, verifying all 23 skills and category-specific controls, including fixed/instant/charge/stack lifetimes and Potency duration changes. [Summary](../project/reports/p6_m7_skill_timing_types_focused/summary.json).

`python tools/p6/run_m6_closeout.py --report-name p6_m7_skill_timing_types_rendered --visual --tests p6_m7_minimal_skill_hover_visual`: **pass, 78 actual hover renders**, exercising the existing live-hover mode/size/text matrix with the revised layout. [Summary](../project/reports/p6_m7_skill_timing_types_rendered/summary.json). Enlarged-text Virulent Poison, Poison Vile, Touch of Darkness and Venom Jab renders were inspected. Both runs use disposable saves and report unchanged source isolation. No mechanics or talent-format changes; T5 remains In progress.

Final reports: [focused checks](../project/reports/p6_m7_minimal_skill_final/summary.json), [build-panel check](../project/reports/p6_m7_minimal_skill_build_verified/summary.json), [78 hovered renders](../project/reports/p6_m7_minimal_skill_rendered_final/summary.json).

Representative review images: [Venom Jab](../project/reports/p6_m7_minimal_skill_rendered_final/p6_m7_minimal_skill_hover_visual/minimal_skill_hover/test-palette-venom_jab-1280-100.png), [Death Strike](../project/reports/p6_m7_minimal_skill_rendered_final/p6_m7_minimal_skill_hover_visual/minimal_skill_hover/test-basic-killers_mark-1280-125.png), [Touch of Darkness](../project/reports/p6_m7_minimal_skill_rendered_final/p6_m7_minimal_skill_hover_visual/minimal_skill_hover/adventure-basic-touch_of_darkness-1280-125.png).

The later [D026 talent format](P6M7_T5_Minimal_Talent_Tooltip_Design_And_Implementation.md) supersedes this note's historical unchanged-talent boundary; the current skill format itself remains unchanged.

## Retrigger terminology — 2026-10-14

Retrigger is the mechanical keyword. Dance of Death and Precision Attacks describe a guaranteed Retrigger; Double Dip refers to numeric Retrigger Chance. Repeat remains a colloquial outcome, not a substitute keyword in mechanical tooltip copy. The skill/talent format and combat mechanics are unchanged. The affected skill-hover, talent-hover, detailed formatter, combat-presentation and category suites pass in [focused verification](../project/reports/p6_m7_retrigger_wording_focused/summary.json).


**D029 revision (2026-10-14):** Current palette/Requires and requested Bladedancer/stack wording changes supersede the corresponding earlier descriptions. See [approved decision and final evidence](P6M7_T5_Neutral_Talent_And_Stack_Wording.md). T5 remains In progress.


**D030 revision (2026-10-14):** Approved Thief intrinsic/talent/skill copy and Pick Pocket Duration exception are recorded in [Thief revision evidence](P6M7_T5_Thief_Tooltip_Revision.md). T5 remains In progress.


**D031 revision (2026-10-14):** Approved Assassin wording and Virulent/Vile Duration omissions are recorded in [Assassin revision evidence](P6M7_T5_Assassin_Tooltip_Revision.md). T5 remains In progress.


**D032 revision (2026-10-14):** Approved Shadow copy and live Distilled maximum/provider refresh are recorded in [Shadow revision evidence](P6M7_T5_Shadow_Tooltip_Revision.md). T5 remains In progress.
