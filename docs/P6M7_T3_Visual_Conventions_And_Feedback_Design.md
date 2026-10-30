# M7-T3 — Visual conventions and feedback design

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

**Current status: Historical, withdrawn proposal. T3 itself is Complete (2026-10-09, D015).** Use the [accepted conventions and closeout](P6M7_T3_Closeout_And_Accepted_Conventions.md) for current direction. The user rejected these lanes/event-list layouts, then approved the revised category treatment and live promotion excluding combat-log changes. The material below preserves the original proposal and evidence only. Its R1–R3 review requests and numerical layout targets are not current requirements; exact art refinements and effect-overflow choices are handed to T4/T6.

## Recommendation and review choices

Recommend **Separated lanes**: preserve the combat stage, reserve bounded areas for direct hits, Poison totals and important outcomes, and keep all defense/status values clear. The alternative **Compact event list** dedicates more of the stage to a readable ordered feed. Both use the same effect vocabulary, overflow access, event records and audio lifecycle rules.

| Choice | Recommended direction | Alternative / tradeoff |
| --- | --- | --- |
| R1: combat feedback layout | Separated lanes; maintain the visual focus on combat while eliminating randomized text collisions | Compact event list; easier sequential reading but takes more space from the action |
| R2: effect access and density | Four stable visible groups, explicit `+N more`, always-available `Effects (N)` and reduced-motion access | More permanently visible groups would need additional space and integrated layout review |
| R3: icon refinement | Preserve approved identities/reuse; first review local contrast/silhouette refinements for the five T2 candidates | Replacing imagery is a separate art choice when refinement cannot make it recognizable |

The user can accept the recommended package or identify changes by R1–R3. Exact art replacements, if any, are reviewed in T4. Numerical presentation timings below are starting targets to test in T7, not gameplay timings or balance changes. No mechanics approval is requested.

## Review examples and their limits

An interactive two-variant review accompanies this chat. It offers dense Assassin/Shadow, Footwork consumption, ten-group overflow and no-active-effect states; effect inspection, exact-event log, enlarged text and existing icons at 22/32/52px. Ten simultaneous effect groups are explicitly **synthetic**; they do not imply a legal two-tree build. Damage values and event times are illustrative, not a recorded resolver output or a balance claim.

Repository copies: [fragment](../project/reports/p6_m7_t3_design/review-fragment.html), [browser preview](../project/reports/p6_m7_t3_design/review-preview.html). They are focused component studies, not full-game screenshots. The outer title, situation picker, text toggle and art-review disclosure are review controls, not proposed new game chrome. The sword mark stands in for the existing combat art; no character or environment replacement is proposed.

| Example | What to assess |
| --- | --- |
| [Separated lanes, 680px component](../project/reports/p6_m7_t3_design/lanes-1280.png) | Clear separation of enemy values, active buffs, direct-hit labels, Poison totals and important outcomes |
| [Compact list, 850px component](../project/reports/p6_m7_t3_design/ledger-1600.png) | Alternative text-heavy organization using the same events |
| [Overflow inspection](../project/reports/p6_m7_t3_design/overflow-inspector.png) | Discoverable access to all ten groups and independent-instance explanations |
| [Actual-size icons](../project/reports/p6_m7_t3_design/actual-size-icons.png) | Existing pixels on current dark background and a lighter backing; especially Shadow Mastery |

Browser checks cover component widths 680/850/1020 within 1280×720, 1600×900 and 1920×1080 viewports, plus a 336px narrow conversation preview. Both variants, four states and normal/125% text passed 64 layout/state checks. Inspector close/focus restoration, log access, motion toggle and native image loading passed. [Results](../project/reports/p6_m7_t3_design/prototype-checks.json). The prototype's text toggle demonstrates message/status/chip enlargement; it is not a certification of every game control at 125%.

The full 11-defense HUD, character sprites, skill rotation and accepted tree layout remain in Godot. These focused examples do not prove all proposed regions fit simultaneously with that complete HUD at 1280. T7 must measure the complete stage; T8 must review the integrated screens. Do not shrink important text or delete defense values to make the prototype fit.

## C1 — Protected regions and popup layout

Use the actual combat-stage content rectangle, not full viewport coordinates. Layout owns four non-overlapping regions: enemy HUD, player-effect strip, feedback area and controls. The sprite/action area may sit behind feedback only if the feedback has a readable opaque/subtle backing; text never overlays status values, active-effect counters or controls. Keep at least an 8px inset and 6px between message rows. Measure complete text rectangles including critical emphasis/outline before placement.

For the recommended layout, reserve two rows for direct-hit summaries and one for Poison. A separate one-line important-outcome area holds control failures and mitigation/consumption feedback. The mockup illustrates those relationships; final pixel allocations must adapt to the full existing HUD. At 1280 or 125% text, remove optional skill-name repetition or use a two-line message before reducing font size. Fall back to a compact text region inside the same combat panel when space is insufficient. No popup may cross the panel border.

Remove randomized horizontal/vertical placement as the collision-avoidance mechanism. Keep modest optional lift/fade inside each measured lane; reduced motion uses static rows. Preserve current palette, combat fonts and crit emphasis where they remain readable. Use a body font for dense numeric/status detail rather than large decorative action lettering. The accepted talent-tree geometry is unchanged.

Candidate readability targets in Godot logical pixels: normal hit 22–26, important outcome 22–26, Poison total 20–22; critical emphasis uses weight/label/backing rather than the current 68px headline. Use existing project font assets. These are testable starting values, not new global theme settings. Actual-size icons retain current context sizes: 22px HUD, 32px source art and existing 52px buff controls; do not globally enlarge every icon.

## C2 — Event priority, grouping and time

| Priority / channel | Always-visible content | Saturation rule |
| --- | --- | --- |
| Current action/state | Active cast, actual stun/no-Readiness/cooldown failure state | State remains current; do not queue it behind damage |
| Important outcome | Dodge, crit negation, cleanse, interrupt, meaningful Consume result | One bounded row; replace with newer important outcome and count additional outcomes in inspection/log; no unbounded queue |
| Direct hits | Actual damage with source name; explicit `CRIT` or `PROC` when applicable | Two occupied rows; merge repeat hits with matching source/outcome into a counted total; other excess direct hits become `Other hits: total (N)` with exact constituents in log |
| Poison ticks | Actual total and tick count | One independent row, e.g. `Poison: 24 total · 3 ticks`; never merge Poison into physical hit totals |
| Routine effect change | New state on existing icon/counter; exact transition in inspector | Do not create a new large popup for every stack grant/refresh/expiry |
| Gold | Credited theft with `gold` label/icon | Attach to the relevant direct-hit row or separate compact theft summary for Pick Pocket; never imply raw theft or rewards are credited combat theft |

Aggregation is presentation only. Partition incoming records into disjoint buckets; use actual resolved damage/credited gold, never recompute critical outcomes. Never combine crit and noncrit outcomes under one unqualified `CRIT` label. Mixed buckets say “mixed hits,” with constituents preserved. Display totals must reconcile exactly to the represented event IDs; replacement does not remove them from the combat log. Long histories remain inspectable without replaying every popup.

Starting grouping window: 200ms of presentation wall time, accumulating all ordered simulation records delivered during that interval. Flush on fight end/skip without spraying summaries. Labels remain readable for approximately 700–1000ms wall time; incoming values may update an occupied row. Timed buff rings/countdowns and cast states always use simulation time. At 2×/4×, the number of rows stays bounded; more events may enter each summary. Do not slow the simulation or build a visual queue that trails the fight.

At Skip: suppress pending transient visual/audio callbacks, clear held popup state, finish authoritative replay and retain inspectable results. At retry/new fight/exit: increment the presentation generation, cancel delayed work and reset state. A speed change affects future presentation delivery, not previously resolved combat outcomes. Reduced motion disables lift, punch and flashes but preserves all labels, counters, critical/mitigation markers and access to logs.

The Compact event list alternative uses the same aggregation/priority rules with stable rows ordered by latest contributing event time. The review shows the dense example in that order; it is still a still-frame study rather than a runtime scheduler. Select one display mode for implementation; do not build both merely because both are shown for review.

## C3 — Player effects, timers and overflow

Keep four visible **effect groups**, not four instances. Use a fixed priority ordering: Readiness, Footwork, Precision, Dance, Virulent Poison, Touch of Darkness, Beguiling Presence, Master of Poisons, Bypass, Greed. Missing groups leave no blank slots; when groups change, avoid reordering unchanged peers. This gives immediate cast resources priority over passive accumulated gold. The full set is always inspectable.

Show a count with a unit rather than an unexplained central numeral. Examples: `1 charge`, `3 stacks`, `8 absorbed`, `125 gold`. Untimed effects say `Untimed` in inspection, not a misleading `0s` timer. Timed groups use the radial ring plus readable remaining time on hover/focus/inspection; expiry/consumption cannot be inferred from color alone. In compact chips, prefer a short count badge outside the recognizable center of the artwork. Multiple instances show both total units and `N instances`; a timer represents the **next expiry**, explicitly labeled in inspection.

`Effects (N)` remains available before combat, with no buffs, during playback and after completion. N counts active player groups; after completion it reads `Effects (0)` while history remains available. Enemy effects are a separate section, not silently included in N. `+N more` beside the four chips counts hidden groups and opens the same inspector. It has a measured text minimum width (starting minimum 88 logical px), no clipped text, a full accessible label, keyboard activation and focus restoration. Keep the trigger present while the inspector is open even if the last effect expires.

The game inspector is a scrollable modal with bounded viewport margins, a visible Close button, Escape support and a trapped Tab sequence. Restore focus to its still-existing trigger, or the permanent Effects button. Hover and keyboard focus share the same brief explanation; clicking/keyboard activation opens persistent details. The review displays details inline for convenient comparison; this is not a decision to replace the game modal.

The permanent Effects inspector also exposes the existing reduced-motion setting with its true “this session” scope. It must be reachable before combat/no buffs. Do not imply saved persistence without implementing and verifying it. A combat-toolbar shortcut may expose the same setting if it fits; the inspector is the required access path.

| Effect | Chip meaning | Required inspection text |
| --- | --- | --- |
| Footwork | Available stacks; during a consuming cast distinguish `0 ready / 3 spent → hit` | Available count, consumed count tied to cast, captured cast benefit, remaining time of any newly available stacks; spent units are not reusable |
| Readiness | Available charge; spent badge only until consuming impact | Requires/consumes at Parry start; no charge spends cast time with no effect; new grants remain separate |
| Precision | Available untimed charge | Eligible Stab/Heavy Slash repeat, including applicable procs; no extra guarantee stacked with Dance |
| Dance | Active with remaining time | Connected macro attacks guarantee one repeat; no automatic guarantee for proc/repeated attacks; skill cooldown is separate |
| Bypass | Available stacks and shared expiry | +10% elemental per stack, cap three; refresh rules |
| Virulent Poison | Total charges plus instance count | Each independent instance's charges; fueled tick consumes one from each; empty tick consumes none; multiplicative instance effects explained |
| Master of Poisons | Active and next expiry | Elemental resistance ignored while active; stored Decay remains |
| Touch of Darkness | Actual Poison absorbed and instance count if needed | Each instance's +10% attack speed and +2 base physical per consumed stack, remaining duration; no fuel produces no buff |
| Beguiling Presence | Actual Decay absorbed and remaining time | +1 base elemental and +2 percentage points crit chance per absorbed stack, ten-second duration, cap/total where relevant |
| Greed | Credited gold stolen this fight | Not starting stash/reward gold; no separate stat modifier or timer; reset each fight |
| Penetration / Potency | HUD stack count plus timed indication | Actual duration including Death Pact override, cap 50, block/absorb reduction and below-zero base-damage benefit |
| Poison / Shred / Decay | HUD counts | Current value/cap where relevant; tick depletion, Consume and cleanse labeled separately; no invented universal expiry |

Held-consumption visuals remain supported, but never add held units back to “available.” If a new grant arrives during windup, the chip can say `1 ready + 3 spent`; the inspector links the spent units to the accepted cast. At impact/interruption, only that cast's held record disappears. Expiry of an active grant does not retroactively invalidate already captured cast benefits.

## C4 — Icon appearance, reuse and authoring

Retain the 93 installed mappings as the baseline. Keep the nine source-linked buff mappings; Precision remains linked to Precision Attacks, not Assassin Precision. Greed keeps its existing gold icon. Stable IDs and original purchased/custom masters stay unchanged. An icon is not a new gameplay identity.

For T4, compare the five flagged candidates on dark combat/tree surfaces at 22/32/52px, normal and locked grayscale, with stack badges and countdowns. Shadow Mastery needs the highest-priority contrast review; a lighter tile reveals the silhouette in the example but may clash with the tree style. Prefer a restrained edge/highlight or local silhouette cleanup before adopting a new symbol. Dusk Strike and Potency need contrast review; Toxic Tradeoff and Sharpened Edge need silhouette density/recognition review. Exact pixel edits are T4 work, not approved by this prototype.

No global brightness filter, green availability fill or altered locked-state language is proposed. Use the existing gold frame, grayscale lock treatment and readable rank markers. Keep outline/backing treatment consistent among peers and avoid making allocated art resemble disabled art. Names, counts and accessible tooltips carry meaning independently of hue. Check normal labels against the actual background and reserve sufficient contrast for focus/availability states; final quantitative accessibility checks belong to T8.

Icon Lab reconciliation is additive and explicit: identify the actual catalog diff, add Greed with its current mapping, refresh generated metadata from current authority, and version/fingerprint the resulting catalog. Support a deliberate migration from the known 92-entry format that adds Greed without overwriting the other 92 assignments. Do not silently accept arbitrary unknown fingerprints. Imported legacy data keeps a provenance record and reviewable migration notice; malformed/unknown input still rejects atomically. Round-trip both original approved and current exports, test linked-buff normalization and prove browser drafts are preserved. Never rerun the old installer as a blanket replacement of live art.

## C5 — Player wording and skill examples

Use current display names, not ID suffixes. Resolve `skill.rending_thrust`→Rending Slash, `skill.killers_mark`→Death Strike and `skill.toxic_flurry`→Beguiling Strike in event/inspection text. Keep stable IDs only in diagnostic exports. Translate generic magnitude fields into named bonuses; unsupported legacy metadata can show a clear neutral fallback without invented effects.

Use “base physical damage,” “base elemental damage,” “physical damage,” “elemental damage,” “percentage points of critical chance,” “credited gold stolen this fight,” “Consume,” “Poison tick depletion,” “charges,” and “stacks” consistently. Rank tooltips should explain the total effect at that rank, with current→next comparison when available; do not duplicate the same penalty as two apparent modifiers. Distinguish skill cast duration, buff lifetime and shared cooldown.

Required T5 examples:

- **Death Strike:** “Deals 111% × (weapon damage + 2 per current Poison stack + applicable base physical bonuses), before damage modifiers. Does not consume Poison.” The detailed view explains impact-time reading and ordering; the short view still includes the ×2 coefficient.
- **Mug:** “Adds 1 base physical damage per credited gold stolen this fight, up to +50. Starting stash and rewards do not count.” Keep the resolved damage estimate separate; detailed text says no spending.
- **Pick Pocket:** “Steals 10 raw gold; Increased Gold applies once, rounded down. No damage. 8s shared cooldown.” Detailed text retains Debuff eligibility and Bribery interactions.
- **Big Score:** “Critical hits use 6× your full critical-damage multiplier.” Show this in the compact view beside ordinary hit damage, not only in the detailed view. Do not imply a universal 18× multiplier for all builds or noncritical hits.
- **Toxic Tradeoff:** State the rank's Poison benefit and physical penalty once, identifying separate factors and unchanged other elemental damage.
- **Death Touch:** Explain eligible stack grants and exceptions through the existing mechanics contract; “Increased All Stacks” alone is insufficient. Do not imply it adds Virulent charges.

These are proposed wording templates. Generate numbers from the live resolved contract where practical, then test short/detail/tree/rotation consistency at relevant boundaries. They authorize no numerical change.

## C6 — Visual/audio cue and lifecycle contract

| Trigger | Required visual feedback | Audio direction |
| --- | --- | --- |
| Connected normal/crit/proc attack | Source, actual damage, non-color CRIT/PROC marker | Retain current attack family; bound polyphony under rapid repeats |
| Dodged attack | DODGED outcome; no damage implied | Retain distinct existing dodge sound |
| Crit negated | Actual damage plus `CRIT NEGATED`; prevented/original amount inspectable | No additional sound required for T3 acceptance |
| Stun / interrupt / no Readiness / cooldown failure | Current reason and timing; explain no-effect attempt | Visual first; avoid a new sound for every skipped/failed slot |
| Cleanse | Statuses actually removed; immune Shred distinction | Optional existing cue only if it improves recognition |
| Consume / buff activation or expiry | Updated count/state; key Consume commitment in outcome area | No per-stack sound; no new required sound assets |
| Theft | Credited gold, meaningful source | Reuse existing appropriate sound only if it does not duplicate hit noise |
| Skip / exit / retry / finish | Clear transient state; preserve inspectable result where applicable | Cancel pending combat sounds; no delayed hit in another screen/fight |

Every delayed combat callback carries a fight/session generation token and checks it at dispatch. Skip/exit/retry invalidates the token and stops or drains owned one-shot players according to the existing audio manager contract. Do not stop unrelated music/ambient audio. Recheck playback speed when scheduling future events; pending speed-dependent work should be cancelled/rescheduled or invalidated coherently. Avoid stale captured-speed callbacks. T7 chooses the least invasive implementation after inspecting existing ownership.

Audio validation needs both event assertions and actual listening. Dummy-driver automated passes are not audible acceptance. No new audio pack or installation is needed for this design.

## Implementation handoff and acceptance cases

| Task | Inputs / output | Validation required |
| --- | --- | --- |
| T4 | C4, G09/G11: local art proposals and catalog reconciliation | All 93 mappings, hashes/provenance, native size, linked buffs, legacy/current import/export, non-destructive migration and freshness |
| T5 | C3/C5, G01–G05/G08: consistent descriptions and player names | Death Strike 0/1/10 Poison; Mug 0/1/49/50/51 theft and starting stash; Pick Pocket gold multipliers; Big Score normal/gold crit; all ranks and role-dependent estimates |
| T6 | C3, G07/G08/G12: effect groups, reliable overflow, inspector access | 0/1/4/5/10 groups; independent timers/charges; held consumption/new grants/interruption; cap/expiry; keyboard/no-buff/finish access |
| T7 | Selected R1 plus C1/C2/C6, G06/G10: shared readable feedback policy and audio cancellation | Dense Assassin/Shadow plus Bladedancer/Thief; 1×/2×/4×; simultaneous ticks/procs; text bounds; aggregation accounting; Skip/exit/retry/speed-change; audible checks |
| T8 | Combined changes | Three display sizes, normal/125% text, Adventure/Test/Practice, four trees and both roles, keyboard/focus, contrast/non-color cues, long names/large numbers, reduced motion |
| T9/T10 | User observations and review | Confusing losses versus intentional counters, recognition, preparation friction and acceptance; no synthetic/harness substitution for human feedback |

Cross-cutting invariants: same input produces the same combat totals/RNG/final gold before and after presentation work; every grouped number maps to exact resolver events; no real save paths during tests; no stage-boundary crossing; no essential state available only by color or fleeting motion; no stalled inspector focus when groups disappear.

Architecture preference: one shared event-to-presentation policy used by `combat_playback_presenter.gd` and `training_room_combat_view.gd`; keep mode-specific hosts if needed. Avoid another pair of diverging grouping/priority implementations. Use the existing replay model as state authority, not popup counters. Adoption of this preference does not authorize a broad combat-resolver rewrite.

## Work performed and completion boundary

- Reviewed T2 gaps, retained layout/icon decisions, relevant live display behavior and previous evidence.
- Produced C1–C6 conventions, R1–R3 review choices, ten-buff/status display rules, cue lifecycle rules and T4–T8 acceptance cases.
- Built and inspected two interactive component proposals, consumption/overflow/no-effect states and actual-size existing art examples.
- Ran the isolated browser prototype checks; all 64 state/layout combinations passed. No Godot tests were required for this design-only turn; T2 runtime results remain historical evidence, not new T3 execution.
- Preserved runtime scripts/resources/assets and source-linked mappings. No approved art assignment or gameplay tuning changed.

Historical next step was R1–R3 review. Superseded by D015: T3 is Complete on the revised accepted conventions, T4 is next, and final integrated presentation acceptance remains T10.

Reproduction: `node tools/p6/check_m7_design.cjs` checks the saved workspace preview using the bundled Playwright path and installed Edge. The preview is generated from `review-fragment.html` with the visualize skill's `scripts/render.py`; its source hash and documentation checks are recorded in this report directory. This is a local review artifact, not a published site.
