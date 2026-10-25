# M4-T10 — Full-tree layout and UI/UX refinement

Status: **Complete - accepted talent-tree UI/UX and final usability validation recorded 2026-10-02. Next: M4-T11.**
User direction: 2026-10-02. Design and iterate on the complete Bladedancer primary
and Thief secondary trees so the display can be settled before remaining mechanics
are implemented. This is an explicit expansion of visual coverage, not playable
content promotion. The current talent layout is accepted as the baseline for continuing work.

## Accepted baseline and remaining T10 work

**Closeout update:** All checklist items below are now complete within the scoped M4
content. See [final validation and T11 handoff](#final-validation-and-t11-handoff)
for evidence, fixes, test-only boundaries and remaining T11 warnings.

**User acceptance: 2026-10-02.** The user considers the current talent-tree UI/UX
sufficient to move forward. No further design iteration is required to satisfy
that acceptance. Reopen it only for a concrete usability failure or a new request.
This acceptance and the final validation below complete T10. They do not promote
the 17 preview talents into playable mechanics.

Accepted behavior:

- Equal-width dark primary/secondary panels, reserving the secondary slot before
  selection; authored JSON grid positions and upward progression, without level labels.
- Centered role/name/icon headers, current intrinsic and primary Bonus lines;
  secondary Bonus is NONE. Bladedancer retains +0.2% per invested point, displayed
  with the user-selected `per level` wording. No invested-point caption.
- Compact talent nodes and smaller centered skill unlocks; empty unlocks omitted.
  Available/allocated content stays full color, with no green fill or + indicator;
  locked and preview content uses gray frames and dimmed grayscale art.
- Per-tree small reset controls, preserving the other tree and existing mode rules.
  No persistent red click/focus fill on talent, skill or reset buttons.
- Practice selectors inside each tree, points/budget/swap toolbar, no Unspent caption;
  mode-specific content sizing and scrolling only when necessary.
- Skill tooltips explain effects, previews identify draft descriptions, and talent
  tooltips omit click instructions. Selection success text is suppressed.

| T10 acceptance item | Current state / next action |
| --- | --- |
| Full tree coverage, authored positions, preview isolation and user layout acceptance | Complete for the current 23-node baseline. |
| Normal-size rendering | Complete at 1280x720, 1600x900 and 1920x1080; both modes, empty/populated secondary panels, availability contrast and content-fit checks have evidence. |
| 125% text stress / longest names (U10, U15) | Complete: both modes at 125% text, all three target resolutions; long skill/talent tooltips at 28px (rounded up from 22px x 1.25) remain bounded. |
| Keyboard-only editing, modal focus and edge tooltips (U15) | Complete: real key events select a secondary, swap roles, allocate/refund/reset, inspect previews, close inspection/modals and wrap Tab/Shift-Tab inside the modal. Keyboard-only outline and refresh focus fixes installed. Engine tooltips checked at all four corners at each resolution. |
| Dense skill lists, rotation and busy combat (U10, U11, U15) | Complete for the ten-skill mixed library and ten-slot rotation: rendered busy Practice combat and reduced motion; twelve synthetic effects and overflow inspection. Current presentation suite rechecks independent instances, enemy statuses, cooldowns, consumption, skip and motion behavior. |
| Synthetic gold-cap presentation (U12) | Complete: nine combinations of Gilded stash 499/500/501 and rank-one Silvered theft 24/25/26, with source caps and combined crit totals separately displayed. Additional rank-cap mechanics remain covered by inherited mechanics tests; no content promotion. |
| Consolidated T10 validation record | Complete: final scoped evidence below. T11 owns milestone-wide regression and inherited compatibility reconciliation. |

Latest rendered tree evidence: 166 passing checks in
`project/reports/p6_t10_full_tree_preview/visual-checks.json`; three-size screenshots
include `compact-grid-trees-*`, `available-tree-nodes-*` and `test-mode-content-fit-*`.
`project/reports/p6_t10_content_fit_verified/summary.json` records display, talent UI
and core journey passes; `project/reports/p6_t10_tree_reset_final/summary.json` also
records the mixed journey. Later appearance-only revisions have rendered evidence
under `project/reports/p6_t10_node_availability/neutral-visual.log`. These are scoped
results, not a claim that all milestone regressions pass. Render runs have documented
certificate/cache and resource-cleanup warnings; triage remains part of closeout.

T11 retains broad milestone regression, reconciliation of the inherited six
compatibility signatures in two suites, final handoff and downstream ownership.
M5 retains unimplemented talent/skill mechanics; M6 balance and M7 remaining art
retain their existing scope. Those are not additional talent-layout prerequisites.

The revision sections below are chronological history. Their earlier provisional
statuses, sizing, colors and check counts are superseded by this accepted baseline.

## Required display scope

Use all **13 Bladedancer talents and 10 Thief talents**, across all five tiers,
with their rank capacities, point gates, prerequisite links, assigned icons,
intrinsic/role information and automatic skill-unlock positions. Include
talent-granted skill information. Each tree has five authored automatic-unlock
positions (1/3/6/9/12 points); the nine-point positions are empty and must not imply
an invented skill. The accepted treatment omits empty slots and centers the remaining assigned skills.

Source structure comes from the [Bladedancer](talent_tree_drafts/Bladedancer.json)
and [Thief](talent_tree_drafts/Thief.json) drafts, mapped through the
[canonical identity manifest](P6M2_T4_Content_Identity_Manifest.json). Use installed
icon assignments. Reviewed mechanics and names take precedence over stale draft
descriptions; unreviewed descriptions must be clearly identified as draft content.
Do not reuse draft-local IDs as runtime identities.

| Tier / point gate | Bladedancer | Thief |
| --- | --- | --- |
| 1 / 0 | Weakness, Whetstone, Rending Slash | Keen Eye, Sticky Fingers |
| 2 / 5 | Fancy Footwork, Precision Attacks, Double Dip | Fast Hands, Fill Your Pockets, Charisma |
| 3 / 10 | Opportunity, Sharpened Edge, Cloak & Dagger | Silvered Edge, Bribery |
| 4 / 15 | Riposte, Side Step, Weapon Master | Load Dice, Finders Keepers |
| 5 / 20 | Virulent Corruption | Gilded Blade |

All dependencies must come from the mapped draft/approved contracts. The presence
of a higher tier alone must not create a prerequisite link.

## Working steps

1. **Inventory and establish a complete visual baseline.** Reconcile all 23 talent
   identities, ranks, tiers, dependencies, icons and skill slots. Add the missing
   nodes to presentation data with an explicit preview state. Existing supported
   talents remain functional. Preview nodes can be hovered/inspected but cannot
   spend points, grant skills or buffs, affect combat, or enter saved allocations.
   Keep them outside the production build registry and resolver. Distinguish
   “Not yet implemented” from an implemented talent locked by a gate or prerequisite.
2. **Discuss the layout using the full two-tree view.** Review the user's concerns
   and agree on goals: primary/secondary arrangement, tier direction, spacing,
   node/rank treatment, dependency routing, unlock placement, point summary, Reset
   points, tooltip behavior and scrolling. Existing upward progression is the
   starting point, subject to explicit user revision. Avoid making later rows an
   afterthought or routing prerequisite lines through unrelated nodes.
3. **Present concrete mockups and iterate together.** Offer a small number of
   complete two-tree arrangements, showing all nodes rather than only the current
   playable subset. Compare screen usage and navigation. The user chooses a
   direction before substantial layout implementation; record accepted choices.
   Use labelled preview states for unallocated, partial/max rank, gate/dependency
   locks and unavailable content without mutating gameplay data.
4. **Implement the chosen layout and review it in-game.** Reuse the same view in
   Test Mode and Practice. Preserve role swapping, legal rank editing, reset,
   rotation pruning and persistence. Include preview node inspection in keyboard
   navigation. Iterate on actual screens with the user until the layout and
   interactions are accepted, keeping short recorded feedback/change lists.
5. **Complete T10 usability checks.** Inspect 1280×720, 1600×900 and 1920×1080,
   plus 125% text stress. Verify readable names/ranks, unobstructed dependency
   paths, reachable nodes/actions, tooltips at screen edges, keyboard focus,
   modal scrolling and no clipped essential controls. Retain the original T10
   checks for large skill lists, busy combat, twelve synthetic effects/overflow,
   reduced motion and synthetic gold-cap presentation. Synthetic display states
   do not imply playable content availability.
6. **Accept and document.** Record the user's accepted full-tree layout and
   interaction rules, screenshots and focused regression results. Verify that
   preview nodes cannot affect allocations, unlocks, saves or combat and that
   core/mixed journeys still work. Close T10 only after UI/UX acceptance and the
   remaining usability checks; T11 owns milestone regression and closeout.

## Completion boundary

T10 must leave a complete Bladedancer-plus-Thief display with an accepted layout,
working supported nodes, clearly marked nonfunctional preview nodes and a clean
path for M5 to enable reviewed content without reorganizing the screen.

M5 retains full talent/skill behavior review and implementation; M6 balance and M7
remaining icon/presentation completion retain their ownership. No new mechanics,
balance values, purchasable ranks or skill grants are approved by this UI plan.

Related: [M4 tracker](P6M4_Playable_Integration_And_UI_Validation_Tracker.md),
[T2 acceptance cases U05/U10–U12/U15](P6M4_T2_UI_UX_And_Player_Feedback_Specification.md),
[T9 playable boundary](P6M4_T9_Mixed_Playable_Integration.md).

## First review checkpoint (2026-10-02)

The shared in-game talent view now includes all 23 talents and ten skill-slot
positions using the presentation-only `full_tree_display.json` catalog. Six talents
remain playable; the other 17 use inspectable Preview buttons. The production
registry, allocation model and combat resolver do not receive display copies.
Current layout remains the provisional vertically stacked modal while a new
arrangement is selected. This checkpoint does not claim layout acceptance.

`tools/p6/build_tree_display_catalog.py --check` reconciles the catalog against
both drafts, the canonical identity manifest and installed icon assignments.
[75 preview checks](../project/reports/p6_t10_full_tree_preview/checks.json) pass,
including counts, four dependency links, no purchase action for preview nodes,
state-level allocation rejection, save rejection and unchanged encoded builds.
The [same 75 rendered checks](../project/reports/p6_t10_full_tree_preview/visual-checks.json)
pass at 1280x720, 1600x900 and 1920x1080. Existing
[talent UI and mixed journey checks](../project/reports/p6_t10_preview_initial/summary.json)
also pass. Final dense-layout/125% text/accessibility acceptance is still pending.

Two interactive design options have been prepared using the full catalog and
assigned icons: A shows both trees side by side; B gives one tree the full width
with primary/secondary tabs. Both keep upward levels, visible point/reset controls,
rank/preview distinctions, prerequisite paths and five skill positions per tree.
Node names and tier spacing are adjustable for review. Mockup controls affect only
local display state. [Browser checks](../project/reports/p6_t10_full_tree_preview/mockup-checks.json)
verify all icons/nodes, node inspection, tab switching, reset and narrow reflow.

The next user choice is the screen arrangement (A, B, or a specific revision).
After that, implement the chosen geometry in-game and continue the agreed
back-and-forth. No arrangement is recorded as approved yet.

## Selected layout revision - 2026-10-02

The user selected side-by-side primary/secondary trees and asked for connected
talents to align vertically with top-to-bottom connections. The shared ranked
view now uses equal-width tree columns, aligned five-level canvases (Level 1
at the bottom), and reserved dependency lanes. All four connections run straight
from the lower talent's top to its dependent's bottom, without passing through
unrelated nodes. Both Practice and the combat talent modal have been widened.
Reset points sits beside the point summary and Practice role swap sits beside
the tree selectors. All 23 talent nodes and ten skill positions fit in the
baseline screenshots. Preview content retains its existing nonfunctional behavior.

Validation: `project/reports/p6_t10_side_by_side_verified/summary.json` records
passing full-tree display, talent UI and mixed journey suites, with protected
files unchanged. The display suite passes 85 checks including horizontal tree
placement, vertical dependency anchors, clear connector paths and visible Reset.
Rendered evidence at 1280x720, 1600x900 and 1920x1080 is in
`project/reports/p6_t10_full_tree_preview/side-by-side-trees-*.png`.
The rendered run passes the same 85 checks. Godot still emits certificate-store
and resource-cleanup warnings at shutdown; no GDScript errors were reported.
This revision does not close T10: user review and the remaining text stress,
keyboard, tooltip and broader presentation checks remain on the checklist.

## Compact panel revision - 2026-10-02

User feedback requested the Enigma-style separate side-by-side subpanels, stable
primary width before selecting a secondary, and removal of level labels. Both
slots now have equal-width bordered panels, including an empty secondary slot.
Test Mode secondary selection is offered inside that slot when eligible.
The label gutter is removed, row spacing tightened, and modal width reduced from
1380 to 1160 logical pixels. Straight dependency links remain intact.

`project/reports/p6_t10_tree_panels/summary.json` records passing display, talent
UI and mixed journey suites. The final rendered display run passes 87 checks,
including the empty-slot width and unchanged primary width after selection.
Screenshots cover primary-only and two-tree states at all three target sizes:
`project/reports/p6_t10_full_tree_preview/panels-primary-only-*.png` and
`project/reports/p6_t10_full_tree_preview/framed-tree-panels-*.png`.
T10 remains open for iterative user review and the remaining usability checks.

## Tree identity and choice-card revision - 2026-10-02

Following the user's Enigma screenshot, selected trees now have centered role
headings, larger gold names with the original subclass icons, current intrinsic
bonuses, and a separate invested-point line. Primary scaling and skill thresholds
remain available in the name tooltip. Empty secondary panels center a Second
Subclass prompt and framed choice cards with icon, name, current intrinsic, and
Choose action. Practice supports the same cards as well as its existing selectors;
Test Mode retains its eligibility rules. Only currently available trees appear.
The taller headers use the existing modal scroll to reach the skill-unlock row.

The tree-header regression run passes the talent UI and mixed journey suites.
The final rendered full-tree suite passes 89 checks, including selecting Thief
through its choice card. Primary-only and populated screenshots were refreshed
at all three target sizes in the existing full-tree preview report directory.
Evidence: `project/reports/p6_t10_tree_headers/summary.json` and
`project/reports/p6_t10_full_tree_preview/visual-checks.json`.

## Authored grid revision - 2026-10-02

The user requested restoration of the original JSON grid placement. The display
catalog now carries each talent's original `position.x` alongside its authored
tier. The detached display tree stores these coordinates as presentation metadata;
the ranked view maps normalized x directly to panel width and uses the authored
row, keeping Level 1 at the bottom. The original JSON files are unchanged.
All 23 talents now preserve their original horizontal ordering, staggered rows,
centered top nodes, and four vertically aligned dependency chains. Automatic
lane placement remains a fallback for trees without authored layout metadata.
Both panel slots reserve enough width to keep 72-pixel nodes separated at the
closest authored spacing (0.15 of the grid width).

Validation: `project/reports/p6_t10_authored_grid/summary.json` records passing
display, talent UI and mixed journey suites. The rendered display suite passes
158 checks including each node's authored position, tier and non-overlap, as
well as clear dependency paths. Screenshots at all three target sizes are
`project/reports/p6_t10_full_tree_preview/authored-grid-trees-*.png`.
The current taller tree headers retain vertical scrolling to the skill row.
T10 remains in iterative review.

## Compact talent and skill sizes - 2026-10-02

User requested smaller talent icons and distinctly smaller skill unlocks. Talent
nodes are now 60px with 36px art, spaced on 72px rows; skill chips are 44px with
28px art beneath a Skill unlocks label. Rank/preview badges and skill thresholds
remain visible. Authored normalized coordinates and vertical links are unchanged.
Both full trees and the skill rows fit at baseline 1280x720. The modal reserves
a consistent scrollbar gutter so feedback cannot shift the tree panel widths.

Display and talent UI suites pass in `project/reports/p6_t10_compact_icons`.
The rendered display suite retains 158 checks and captures all three target
sizes as `project/reports/p6_t10_full_tree_preview/compact-grid-trees-*.png`.
This supersedes the prior header revision's baseline need to scroll to skills.
T10 remains open for user review and the remaining usability checks.

## Narrower panels - 2026-10-02

Following the smaller icons, the user requested a narrower window. Modal content
width is now 1000 logical pixels (down from 1160), with 480px minimum tree panels
and a 456px grid minimum. The authored grid, headers, empty secondary slot, node
sizes and smaller skill row are preserved. The complete baseline fits at 1280x720.
Display and talent UI suites pass in `project/reports/p6_t10_narrow_panels`;
the rendered run passes 158 checks at the existing three target resolutions.
The `compact-grid-trees-*.png` screenshots now show this narrower revision.

## Compact skill unlock rows - 2026-10-02

User chose compact centered skill rows instead of reserved empty positions.
Unassigned automatic unlocks are now omitted entirely from the display; assigned
skills retain their point thresholds and ascending order. The centered flow row
closes the gap automatically. Source unlock positions remain unchanged in data.
The rendered display suite passes 158 checks and refreshed screenshots show four
centered skills per tree with no empty nine-point slot.

## Intrinsic, bonus and tooltip copy - 2026-10-02

Bladedancer intrinsic now reads `Intrinsic: +5% Retrigger chance`. A separate
Bonus line formats the primary subclass's actual per-point modifiers with
fractional precision, using the user's requested `per level` wording. Secondary
headers and choice cards show `Bonus: NONE`. The user explicitly confirmed keeping
Bladedancer's existing +0.2% gameplay bonus, so its line reads
`Bonus: +0.2% Retrigger chance per level`; mechanics remain unchanged.

Skill unlock tooltips now show the name and effect/condition descriptions from
the shared runtime formatter, instead of unlock requirements. Unimplemented skill
previews use the original draft descriptions, clearly marked draft and not yet
playable. Threshold numbers remain on the chips. Talent tooltips omit the click
and right-click instructions. Display and talent UI suites pass in
`project/reports/p6_t10_tooltip_copy`; the rendered display run passes 158 checks.

## Per-tree reset and tighter panels - 2026-10-02

User requested further narrowing, small per-tree reset buttons at bottom right,
less bottom space, and removal of selection feedback and invested-point labels.
The modal is now 940x740 logical pixels, with 450px minimum tree panels and 68px
row spacing. Each populated panel has a small `reset` button. The atomic ranked
model operation refunds that tree only, retaining the other tree's ranks, both
roles and budget. State wrappers preserve existing refund/playback restrictions
and rotation pruning. Secondary selection success and selector success text are
hidden; errors and relevant rotation-change notices remain visible. The separate
invested-point line is removed.

Display, talent UI, core journey and mixed journey suites pass in
`project/reports/p6_t10_tree_reset_final`. The rendered display suite passes 162
checks, including primary-only refunds preserving all secondary ranks, role and
budget retention, and subsequent secondary reset. Screenshots are refreshed in
the existing full-tree preview directory. T10 remains in iterative review.

## Panel contrast and mode-aware sizing - 2026-10-02

Tree panel backgrounds are darker than the outer modal. Practice selectors now
live inside their respective tree panels; its budget and role-swap controls share
the points toolbar. The summary no longer displays Unspent points. Reset uses a
smaller data-font button with tight padding. Talent normal/hover/pressed styles
are dark and the inherited red focus fill is removed; focus and keyboard
activation remain supported.

Both modal implementations now measure their content and cap the scroll area to
the available viewport. They resize when content minimum size changes, and only
show a scrollbar for actual overflow. Test Mode therefore omits the height of
Practice-only controls instead of inheriting a fixed modal height.

The display, talent UI and core journey suites pass in
`project/reports/p6_t10_content_fit_verified`. Rendered checks pass 166 assertions,
including no unnecessary scrollbar in either mode, selector placement and a
shorter Test Mode modal. Screenshots at all three sizes include
`compact-grid-trees-*.png` (Practice) and `test-mode-content-fit-*.png` in the
full-tree preview report directory. T10 remains open for user acceptance.

## Node availability contrast - 2026-10-02

Available playable talents now use a green border/background, full-color art and
an additional + beside the rank count. This reflects the actual purchase check,
including gates, dependencies, remaining points and editing restrictions. Allocated
nodes retain gold styling when no further rank can be bought. Locked unallocated
nodes and preview nodes use gray frames, grayscale dimmed art and muted labels;
previews remain explicitly labeled and inspectable. Skill styling is unchanged.
Reset buttons override the inherited focus fill, removing the lingering red state.

Display and talent UI suites pass in `project/reports/p6_t10_node_availability`.
The rendered run passes 166 checks; `available-tree-nodes-*.png` captures available,
locked, preview and allocated nodes together at all three target sizes. The renderer
reported a shader-cache write warning plus the previously observed cleanup warnings;
no GDScript failures occurred and the grayscale rendering was visually checked.

## Neutral availability and grayscale skills - 2026-10-02

User preferred availability through full-color art without green styling or a +.
Available nodes now use the normal dark background, gold border and plain rank
count. Locked and preview nodes retain their grayscale treatment. Locked and
preview skill chips now use matching grayscale art, gray frames and muted
threshold labels; unlocked skills remain full color. Skill hover/pressed/focus
styles no longer introduce red fills. The rendered suite passes 166 checks and
refreshed available-node screenshots show the resulting contrast.

## Final validation and T11 handoff

Completed 2026-10-02 after the user's accepted visual baseline. No further layout
redesign was needed. The validation exposed and corrected these concrete issues:

- Talent refunds lacked a keyboard action. Delete now refunds the focused talent;
  Enter/Space retains normal activation, F1 opens inspectable talent/skill text,
  and Escape closes inspection or the talent modal.
- Removing the rejected red focus fill had also removed keyboard focus feedback.
  A transparent parchment outline now appears only during keyboard navigation;
  mouse input clears it. Tab/Shift-Tab remain inside the modal, and focus survives
  allocation refreshes. Role swap now carries a stable focus key.
- The gold inspector showed capped source contributions without combined crit
  values. It now also displays total crit chance and total crit damage.

Evidence:

- [Seven scoped suites](../project/reports/p6_t10_acceptance/summary.json) pass:
  usability, combat presentation, skill UI, full-tree display, talent UI, core
  journey and mixed journey. [Isolation](../project/reports/p6_t10_acceptance/isolation.json)
  confirms protected saves/project files unchanged.
- [128 headless usability checks](../project/reports/p6_t10_usability/checks.json)
  and [152 rendered usability checks](../project/reports/p6_t10_usability/visual-checks.json)
  pass. The separate full-tree suite retains its 166-check coverage.
- Rendered scenarios cover 1280x720, 1600x900 and 1920x1080: 125% tree text in
  Practice and Test Mode, keyboard preview inspection, ten available skills and
  ten rotation slots, actual mixed combat with reduced motion off/on, synthetic
  effect overflow and synthetic gold-cap presentation. Twelve real engine tooltip
  placements cover four corners at each size, alternating long talent/skill text.
- Screenshot examples: [125% Practice](../project/reports/p6_t10_usability/practice-text-125-1280.png),
  [125% Test Mode](../project/reports/p6_t10_usability/test-text-125-1280.png),
  [long edge tooltip](../project/reports/p6_t10_usability/tooltip-1280-1558-858.png),
  [dense rotation](../project/reports/p6_t10_usability/dense-mixed-rotation-1280.png),
  [busy combat](../project/reports/p6_t10_usability/busy-combat-1280.png),
  [reduced motion](../project/reports/p6_t10_usability/busy-combat-reduced-motion-1280.png),
  [overflow inspector](../project/reports/p6_t10_usability/synthetic-effects-inspector-1280.png),
  [gold caps and totals](../project/reports/p6_t10_usability/synthetic-gold-caps-1280.png).

The stress hook enlarges existing text and tooltip text in tests; it does not add
or promise a player text-scale setting. Synthetic effects and gold fixtures are
isolated test data, not additional selectable mechanics. The source grid and
accepted mouse styling remain unchanged.

T11 remains responsible for broader milestone regression, the six inherited
compatibility signatures across two suites, final handoff and downstream owners.
Final rendered logs still emit the existing certificate-store and teardown
resource/RID warnings. They are documented for T11 triage, not hidden by the
passing script assertions. No GDScript failures occurred in the final runs.


### T11 resolution (2026-10-02)

[T11 is Complete](P6M4_T11_Closeout_And_M5_Handoff.md). Original compatibility hashes pass unchanged after normalizing icon paths. Detached playback labels and Practice time conversion/gear limits are fixed. Sixty regression suites, seven static checks and refreshed rendered checks pass. Remaining baseline shutdown/environment warnings and downstream work are recorded in that handoff. The accepted T10 layout is preserved.
