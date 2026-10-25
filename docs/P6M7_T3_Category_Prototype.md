# M7-T3 skill category prototype

**Current status: T3 Complete (2026-10-09, D015).** The user reviewed the iterations below and approved live promotion except combat-log changes. See [accepted conventions, current scope and closeout](P6M7_T3_Closeout_And_Accepted_Conventions.md). This document preserves prototype history; its Test Mode-only boundaries and pending-review instructions describe earlier stages. Approved visuals now run in Adventure and Practice; the experimental log stays Test Mode only.

**User refinement:** Boxed combat notices and category symbols on skill buttons were rejected. The prototype now colours the existing floating-text presentation: violet Debuff and pale-blue Self Buff text, without a window or backing panel. Skill buttons retain their original size and artwork. Category labels remain in tooltips and the log.

**Latest user refinement:** The category-preview selector and reduced-motion checkbox are now hidden, and their reserved toolbar space is removed. Category styling remains enabled in Test Mode. Cooldown-blocked casts produce no floating text; the combat log still records their outcome. Earlier comparison-control instructions below are historical.

**2026-10-09 icon-accent experiment:** Attack is now light red (`#EE8880`) in the Test Mode category palette, selected attack floating text and category log entries. Available Skills has an **Outline / Bottom edge / Off** selector. It controls draw-only accents on Stab, Venom Jab, Poison Vile and Virulent Poison, plus the three corresponding automatic skill-unlock icons in the tree (Stab is a base skill). Other skill/talent icons remain unchanged for this comparison. Button dimensions, artwork, existing selection frames and hit areas are preserved; locked unlock accents are subdued. The old combat preview and reduced-motion controls remain hidden. Adventure and Practice retain their existing appearance.

Validation: `p6_m7_icon_accent_check` passes the category, combat-screen and Practice suites. `p6_m7_icon_accents_visual` passes geometry/isolation checks and captures both treatments plus Off in Available Skills and the actual talent overlay at 1280×720, 1600×900 and 1920×1080. Existing certificate-store and teardown warnings remain. User comparison is the next step.

## Try it

1. Start **Test Mode**, choose **Assassin** as the main tree and **45 points**.
2. Allocate Quick Hands 5, Precision 5 and Hastened Poison 2. This legal twelve-point allocation unlocks all representative skills.
3. Build a rotation using **Virulent Poison, Poison Vile, Venom Jab and Stab**. Add a second Virulent Poison before its ten-second cooldown ends to inspect the failure cue.
4. Use **Category Preview / Original**, below the combat buttons, before or during a fight. Category Preview is the default in new Test Mode screens. Reduced motion beside it suppresses the prototype's movement and pulses while preserving its outcome text; it is not a global settings change.
5. Hover the selected skills and rotation slots, inspect their details, watch the cast cues, then open Combat Log. Compare each element with Original.

Only these four skills participate. Other skills remain on the existing presentation. The controls do not grant skills or alter progression. Preferences are session-only.

## Visual language

| Category | Accent | Symbol | Presentation |
| --- | --- | --- | --- |
| Attack | Light red `#EE8880` | `/` | Existing strike, damage and critical popups; category in tooltips and log |
| Debuff | Soft violet `#D2B3EE` | `v` | Poison Vile: stationary preparation, enemy colour pulse and actual Poison stacks added, without zero-damage text |
| Self Buff | Pale blue `#9ED5EF` | `+` | Virulent Poison: short upward preparation and player pulse, followed by five charges; cooldown failures explicitly say no effect |

Full category words accompany the symbols in tooltips, outcomes and the log. Existing skill icons and effect colours remain intact; this experiment does not recolour Poison damage or equipment rarity. One existing readable font is used for category notices and controls.

The four tooltips follow name/category, effect and conditions, duration or charges, cast time, then cooldown. Virulent Poison explains that empty ticks do not spend charges and that charges have no duration timer. Poison Vile explains delayed Poison damage and caps. Venom Jab remains an Attack and retains direct damage plus Poison application.

## Implementation and boundaries

`skill_category_preview_style.gd` owns the representative skill set, names, accents, tooltip and outcome wording. `skill_category_preview.gd` is instantiated only by the Test Mode combat screen; it owns controls, notices and cancellable animation tweens. The presenter delegates only selected non-attack skills to it. The palette and tooltip formatter require both explicit preview metadata and Test Mode; stale metadata cannot enable Adventure changes. Practice has its own state and remains unchanged.

The log receives the preview flag only from this Test Mode controller. It adds a coloured chronological summary of the selected casts above the original full event text; existing timeline, damage totals and charts remain intact. Original restores the existing text without BBCode and retains the original skill-button geometry. The comparison controls remain so the preview can be re-enabled.

Cast timing and damage come from the existing resolver. Poison application quantities come from each CastEvent. Virulent Poison's five-charge successful grant follows its current authored contract; failed casts are checked first. No gameplay values, skill resources, sprites, save formats or balance changes are part of this work.

## Validation and review

The dedicated test covers legal unlocks, successful buff/debuff outcomes, cooldown failure, no forward self-buff lunge, local reduced motion, Original tooltip/log restoration, skip/retry/speed/completion cleanup, deterministic damage/RNG parity and Adventure isolation. Rendered fixture captures cover the three supported desktop sizes. Fixtures use a high-HP synthetic target with real resolver events, not user-playtest evidence.

Review priorities: whether the accents are distinguishable, whether the symbols help, whether the stationary cast/pulse feels appropriate, whether the category notice is readable during a mixed rotation, and whether the log explains success versus failure. Keep, tune or revert each element before expanding to the other skills or other modes. T4–T11 completion is not implied.

### Retained evidence

- [Final six-suite regression](../project/reports/p6_m7_category_final/summary.json): category prototype, combat screen, existing presentation, stage visual reset, Practice view and Adventure UI all pass.
- [Rendered checks](../project/reports/p6_m7_category_visual_final/summary.json): pass at 1280×720, 1600×900 and 1920×1080; buff/debuff cues and log captured.
- [Scope check](../project/reports/p6_m7_category_baseline/scope_check.json): only five existing UI files changed, plus two new preview helpers and one test. Gameplay systems, autoloads, data and art remain unchanged. Pre-change copies of the five UI files are retained with this baseline for scoped reversal.
- Final runs used isolated copies and user data, with source unchanged during tests. Historical certificate-store/resource-teardown warnings persist; no script failures in the final runs. An earlier run named a nonexistent log test; that runner invocation failed, and the final complete roster above replaces it.

These early automated checks were not user acceptance. Subsequent user feedback and the D014 promotion request establish the accepted scope recorded in D015; comprehensive milestone art/accessibility/playtest review remains downstream.

### Floating-text refinement

Per user feedback, removed the boxed notice node and restored the skill palette to its pre-prototype source. Non-damaging category feedback now uses CombatPopupLayer with optional colour, text size and static-motion parameters; default callers retain their existing appearance. Virulent Poison floats its name and +5 charges; Poison Vile floats its name and actual Poison application. No new category symbols appear on the skill buttons. Updated rendered evidence: `p6_m7_category_floating_visual_final`; focused regression: `p6_m7_category_floating_verified`.

### Unlock artwork and bounding-frame correction (2026-10-09)

User requested that small skill-unlock buttons fit their artwork and that category colour follow the button bounding box, rather than draw a second square around the icon. Unlock artwork now explicitly ignores source texture minimum dimensions and occupies a centred 24×24 region above the point label. This sizing correction applies to all modes. The Test Mode Outline treatment follows the existing rounded button frame; Bottom edge follows the button bottom. Neither changes hit areas or button dimensions. Rendered validation: `p6_m7_icon_bounds_fix`.

### Filled-box comparison (2026-10-09)

User prefers Bottom edge for Available Skills and requested a category-coloured box alternative for tree unlocks. Added Filled box as the third treatment, followed by Off. Test Mode now has independent selectors: Available Skills defaults to Bottom edge, while Unlocks in the tree toolbar defaults to Filled box. Fill uses a darkened category colour behind the artwork and point label, with a matching outer border; hover brightens it and locked unlocks remain subdued. The four-skill experiment scope and other-mode isolation remain unchanged. Rendered comparison evidence: `p6_m7_icon_fill_visual`.

### Full Assassin icon pass and macro accents (2026-10-09)

User accepted Bottom edge for the skill palette and Filled box for skill unlocks, and requested matching macro bottom edges for the full Assassin tree in Test Mode. Icon coverage now includes Venom Jab, Blinding Powder, Virulent Poison, Master of Poisons, Poison Vile and Poison Strike, plus the already-styled base Stab. Poison Strike's talent node receives the Attack fill because it unlocks that skill; passive talent nodes retain their existing appearance. Macro edges use the same category colours, without changing slot dimensions, hit areas, progress or cooldown controls. This extends icon styling, not the earlier four-skill bespoke tooltip/outcome experiment.

To unlock the complete icon comparison, use Quick Hands 5, Precision 5, Hastened Poison 2 and Poison Strike 1 (13 points total), then add the skills to the macro. Available Skills defaults to Bottom edge and tree unlocks to Filled box; macro slots always use Bottom edge. Adventure and Practice remain outside this experiment.

Evidence: `p6_m7_assassin_accents_visual` (all treatments at three sizes, full Assassin unlock coverage, macro accents and Adventure isolation); `p6_m7_assassin_accents_checks` (talent UI, skill UI, Practice).

The initial skill UI run exposed an outdated assertion shared by Test Mode and Practice. Updated it to check category/cast-time text only in the prototype and the original compact format in Practice; final `p6_m7_assassin_skill_ui_final` passes both. Talent and Practice suites passed in the earlier checks report.
