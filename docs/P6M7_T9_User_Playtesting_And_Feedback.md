# M7-T9 — User Playtesting and Feedback Collection

Status: **Complete** under D050, 2026-10-17. Started 2026-10-16 under D048. T1–T9 Complete; T10–T11 Not started.

The user reports “Everything looks good for now” after reviewing the implemented refinements and the remaining-playtest checklist. Current reported findings are accepted/closed; T10 refinement and milestone acceptance is next. Earlier pending notes below describe the collection period and are superseded by the D050 closeout at the end.

The user reports they have not yet playtested the latest T8 changes and are beginning now. No completed fresh session is claimed. Four user requests from Adventure playtesting are recorded below. Earlier accepted buff/retrigger/audio feedback is retained below. T9 collects observations; T10 resolves agreed findings and records acceptance.

## First pass: keep feedback simple

Start with the familiar Practice build at 1×, then 4×. Focus on:

1. Cause and effect: can you distinguish opening attacks, ghost follow-ups, Poison and other procs, and understand where damage came from?
2. Effects: can you identify active buffs/debuffs, read their remaining duration or uses, and inspect crowded rows without losing track of combat?
3. Readability: do popups, skill labels, tooltips or the inspector cover useful information, clip, or feel too faint or busy? Check the action row near the bottom.
4. Controls: can you open/close the inspector and Settings, use Escape, and return to the fight comfortably? Try keyboard navigation if that is part of normal play.
5. Understanding: after a surprising result, can you explain why it happened and what you would change next time?

Report the mode/build, what happened, what you expected, and whether it repeats. A short observation is enough; seed, screenshot and exact gear changes help when available. “No new issues in Practice at 1×/4×” is useful evidence for that scope. No need to reapprove the already accepted ghost look or audio unless a new problem appears.

## Prepared context

[Candidate revision](../project/reports/p6_m7_t9_context/candidate_revision.json) identifies the dirty working tree through 446 source/configuration hashes. It is a scoped fingerprint, not every binary asset. [Context](../project/reports/p6_m7_t9_context/context.json) and an exact [Practice snapshot](../project/reports/p6_m7_t9_context/practice_saved_snapshot.json) were captured read-only before playtesting. They describe saved configuration, not proof of the currently running session or historical feedback setup.

Saved Practice configuration: Bladedancer primary / Shadow secondary, 45 points, Mithril Karambit plus custom equipment, 500 gold, 30-second duration, Practice Target with 100 HP. The snapshot includes full ranks, gear stats and rotation: Dance of Death, Quick Cut, Toxic Flurry, Distilled Corruption, Killer’s Mark, Parry Strike, Toxic Flurry, Distilled Corruption, Touch of Darkness. Opportunity rank 3 and Death Blade rank 2 are present.

Random fight seeds are enabled. Stored seed 1711321330 does not establish the next fight’s seed; record the actual seed if reproducing an issue. A changed build/gear/macro needs fresh context. No current Adventure save was present at preparation; this does not establish whether Adventure was previously played. Preparation did not launch the game or modify real saves.

## Representative sessions

| Case | Purpose | Human evidence |
| --- | --- | --- |
| P1: familiar Bladedancer/Shadow Practice, 1× and 4× | Dense ghost/proc/effect readability and T8 layout changes | User beginning playtesting; results pending |
| P2: Assassin/Thief in Practice or Test Mode | Other two trees, Poison/gold cues, tooltips and build preparation | Pending; record actual ranks/gear/macro and mode |
| P3: representative Adventure encounter/checkpoint | Preparation friction, enemy/counter visibility, route choices and explanation of win/loss | Pending; record actual checkpoint, tags, build, seed and retry when relevant |

Use normal play rather than exhaustively testing every combination. The final coverage record must state any omitted modes/roles/checkpoints explicitly. T8 automated and rendered cases support reproduction but do not count as human sessions. A surprising loss is evidence to investigate, not automatic evidence that a counter should be weakened.

## Carried-forward feedback

The [feedback register](../project/reports/p6_m7_t9_context/feedback_register.json) preserves six historical records with context limits:

| Record | Observation / disposition |
| --- | --- |
| H01 | T6 temporary-effect display accepted by user, D041 |
| H02 | Jarring instant retrigger bursts addressed with paced ghosts; accepted through D045 |
| H03 | Main actor jumping, combo text and X effect addressed by anchored actor and faded ghosts, D043–D045 |
| H04 | Missing follow-up impact text addressed with smaller, translucent labels, D044–D045 |
| H05 | Sixteen visible chain strikes requested, implemented and accepted, D045 |
| H06 | Actual 1×/4× ghost-chain audio clips accepted: “Both sound good”, D046 |

Exact historical build/mode context is unavailable where not recorded; the new saved snapshot is not retroactively assigned to those observations. Audio listening acceptance does not establish a fresh full-mode playtest.

## Triage and completion

Record each fresh session with candidate/revision, mode, build/ranks, gear/gold, macro, seed/checkpoint and route/tag choices as applicable. Note unknown context honestly. Each finding records actual versus expected behavior, reproduction/retry, impact and proposed disposition.

Classify findings as presentation, confirmed mechanics defect, balance concern, or verified intentional counter; retain unconfirmed reports as unconfirmed. Positive observations are recorded too. Prioritize blockers, repeated comprehension failures and cosmetic issues separately. Do not silently change numbers or reopen accepted treatments without new evidence.

T9 closes when representative human observations and coverage exceptions are reviewed, findings have reproducible context where obtainable, and a prioritized list is handed to T10 (including explicitly deferred issues or no new findings within the tested scope). Detailed session context and broader coverage remain pending; four authorized refinements have been implemented during feedback collection under D049. No milestone-wide acceptance is claimed.

## Adventure feedback received 2026-10-16

The user requested four concrete changes during playtesting: hide Test Mode on the main menu; permit Tavern talent refunds/reset; hide the Archetype Glossary; open the existing Talent Tree after Leave Shop and before the contract window. No new talent-phase screen or explanatory copy was requested. These are authorized presentation/flow changes plus an explicit refund-availability rule change, not inferred numerical tuning. Implementation and verification are complete under D049; user review remains pending. Exact session seed/checkpoint/gear were not supplied and are not inferred from the earlier Practice snapshot.

### D049 — Implemented flow and verification

Test Mode and its point/tree selectors are hidden on the main menu; internals remain available for development. The map’s Archetype guide entry is hidden for now, on Tavern and contract maps.

Adventure permits individual talent refunds, tree reset and full reset during Tavern planning, as well as existing between-contract preparation. Combat, results/reward/shop phases and active-contract planning retain their editing/refund locks. Prerequisites, point totals and underlying talent values are unchanged. Refund feedback now describes the expanded availability.

After a terminal contract shop, Leave Shop advances the existing run state and opens Talent Trees before the offer window. Closing by Close, Escape or outside dismissal continues once into the existing offer/required-secondary-choice flow. Choosing the earned secondary directly inside Talent Trees also works. Earlier Tavern shops still advance to the next Tavern encounter. The final Tavern reward has an existing no-shop path: it now opens Talent Trees before the first contract too. No new screen, label or saved phase was added. Loading a save made at this checkpoint reconstructs existing subclass/contract decisions rather than replaying the transient tree popup.

[Final four-suite run](../project/reports/p6_m7_t9_flow_final/summary.json) passes the flow suite, 62 Adventure UI checks, Test Mode safety and Dance/refund regression. [Final supplement](../project/reports/p6_m7_t9_flow_final_supplement/summary.json) passes 41 flow checks, including direct secondary selection and preserved Test Mode continuation. The affected [build-progression suite](../project/reports/p6_m7_t9_progression/summary.json) also passes after its old locked-Tavern assertion was moved to combat, bringing validation to five distinct suites plus the focused supplement. Actual 1280×720 captures were inspected. Synthetic victories exercise flow rather than balance; known certificate-store and resource-teardown diagnostics remain. Commands, isolated userdata paths and source hashes accompany the reports.

[Task diff](../project/reports/p6_m7_t9_flow_baseline/task_changes.diff) and [parent review](../work/t9_before/flow_parent_review.json) record the six runtime files and scoped source preservation. Runtime report hashes match current files; the other 440 captured candidate sources are unchanged. Tests use isolated userdata; no real-save writes were made by this implementation. User playtesting may independently change live saves. T9 remains In progress; these changes do not establish full M7 acceptance.

## D050 — User-accepted T9 closeout (2026-10-17)

After receiving the implementation and remaining-playtest checklist, the user stated: “Everything looks good for now”. Record this as acceptance of the current playtest results, including the four D049 refinements. F01–F04 are accepted/closed; no further issue or balance change was requested. Retain the earlier accepted buff, ghost/proc, impact-label and audio feedback.

Closeout is scoped to reported observations and user acceptance. No detailed fresh-session seed, checkpoint, rank/gear/macro record or confirmation of complementary Assassin/Thief and all-mode human coverage was supplied. Those coverage details remain unspecified; optional cases P1–P3 above are a collection plan, not claimed passes. Automated/rendered evidence remains distinct from human feedback. Future concrete findings can still be recorded during T10/M8.

T10 handoff: no unresolved reported T9 fixes; reconcile accepted conventions, remaining milestone gaps/deferred work and record milestone-wide acceptance. T11 final regression/handoff remains downstream. M7 remains In progress. This documentation-only closeout does not change runtime, saves, balance or the existing verification evidence.
