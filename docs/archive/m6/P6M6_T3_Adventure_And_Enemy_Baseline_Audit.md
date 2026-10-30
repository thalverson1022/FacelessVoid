# M6-T3 — Adventure and enemy baseline audit

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. [Current context](../../P6_Project_Onboarding_Context.md).

Date: 2026-10-07. Status: **Complete — bounded baseline audit and diagnostic measurements.**

T3 maps existing behavior and identifies work for T2/T4–T8. It does not accept
Adventure balance, enable Adventure, tune gameplay, or implement The Road.
Current scaling remains the starting point for this phase, as requested.

## Findings that affect the plan

1. **The current loop is finite.** There are 30 generated boss identities across
   six biomes. Offers exclude defeated identities, and `BuildState` ends the run
   with `ALL_BOSSES_DEFEATED` after the catalog is cleared. This corrects the earlier
   planning assumption that the existing player loop continues indefinitely.
   Generator-only C31+ samples are diagnostic calls, not reachable normal runs.
2. **Combat scaling plateaus.** HP, target-DPS, armor, block and absorb curves all
   clamp to their C30 anchors. The difficulty band caps at five. The continuing
   completed-contract pressure counter increases reward gold, but is not added
   to the actual encounter difficulty calculation (`completed_bonus = 0`).
   At the same within-band stage, all 39 sampled C40/C60 enemy pairs had identical
   combat stats and duration. Increasing gold does not establish increasing danger.
3. **Timing is already close to the agreed direction.** Across 702 generated enemies,
   ordinary/captain windows were 14–34 seconds, elites 20–36 and bosses 30–60.
   Preserve these as the baseline; review ordinary short/long variants during play,
   rather than changing the generator just to force every window into 15–30.
4. **Dummy rankings do not transfer directly to defended enemies.** Shadow leads
   the existing mature dummy tests but struggles against several sampled
   cleanse/suppression encounters. This is an investigation case, not evidence
   that the entire tree needs a buff or that its dummy lead requires a nerf.
5. **Smooth C10 progression is not established yet.** Weapon-only controls show
   substantial early/midgame margins in many encounters but weak results in some
   Tavern and defended encounters. Stage-appropriate gear, secondary investment,
   gold and macro responses are needed before deciding whether these are walls.

## Existing player flow and budgets

The title disconnects Adventure/Resume while Test Mode directly creates a playable
ranked build, grants a Bandit Blade and 100 gold, and starts generated contracts.
Test Mode is not a fresh Adventure economy baseline. Its 10/45-point and immediate
main/secondary selectors are test conveniences.

Retained Adventure proceeds through class/main selection and four Tavern fights,
then generated offers. The retained class selector loads ordinary class resources;
it does not promote the playable registry. Generated offers default to three
different undefeated bosses. Accept an offer, choose the secondary at the contract
transition, and traverse a branching route to its terminal boss. Completing a
contract grants five talent points once, then offers another contract unless the
boss catalog is exhausted. The old authored Gilded Serpent route and Vyra encounter
remain resources; the normal post-Tavern handoff uses generated offers instead.

| Tavern fight | Incoming points | HP | Armor | Poison resistance | Window | Base gold / points awarded |
| --- | --- | --- | --- | --- | --- | --- |
| Mouthy Drunk | 0 | 145 | 0 | 0% | 12 s | 12 / 1 |
| Drunk Buddy | 1 | 155 | 160 | 10% | 18 s | 18 / 0 |
| Tavern Bouncer | 1 | 305 | 20 | 65% | 24 s | 24 / 4 |
| Hired Goon | 5 | 360 | 160 | 10% | 30 s | 36 / 5 |

Contract incoming budgets are C1=10, C2=15, C3=20, C4=25, C5=30, C6=35,
C7=40, C8 onward=45. Rewards are available after victory, never before it.
Both trees share the budget; main alone gains per-point intrinsic scaling.

The first Tavern fight permits unlimited retries. Other fights permit two attempts;
the second loss ends the Adventure or active contract. Retry increments a counter
included in the deterministic combat seed with the adventure seed and fight key.
It is a new deterministic sample, not a replay or an independent-run probability.
Gear/macro changes still require their normal legal state. Adventure point refunds
remain between contracts; Test Mode allows them during planning. Tree roles stay fixed.

Sources: `game_root.gd`, `title.gd`, `class_select.gd`, `build_state.gd`
(`current_reward`, `current_combat_rng_seed`, `finish_fight`,
`continue_after_win`, `_complete_contract_and_offer_next`, `can_respec`),
`run_flow.gd`, `contract_offer_source.gd`, and the four Tavern encounter resources.

## Generated encounter and scaling inventory

Six route templates are authored: braided_sideboard, split_spill_rejoin,
elite_orbit, five_way_market, hourglass_detour and woven_boss_approach.
The five sampled seeds cover four of them; T4 must cover the remaining two.
Sampled paths contain three or four fights, end at a boss, and include a path
without an elite in every sampled route. This is sample evidence, not proof that
all routes or all captains are avoidable. Branches offer differing defense profiles
and rewards; the selected path determines which optional enemies are fought.

The inventory includes 270 ordinary enemies, 252 captains, 90 elites and 90 bosses.
It encounters all eleven listed archetypes: aegis, arcane, armored, devious,
fortified, hexed, nimble, nullify, resistant, spiteful and warded. Mechanics observed
are armor, block, absorb, poison resistance, cleanse, suppression, dodge, crit
negation, slow, stun and interrupt. Exact per-enemy values, archetype combinations,
modifiers, variant metadata, rewards and next-node IDs are retained in `probe.json`.
Named boss identities are presentation/offer identities separate from their generated
mechanics; they are not bespoke Road bosses.

Default medium progression uses five-contract bands: C1–5 medium, C6–10 hard,
C11–15 ultra and C16 onward nightmare. Within each band, bosses promote their
content pool at stage 3, elites at stage 4, captains at stage 5. Stats also receive
bounded depth/role adjustments. Thus C3/4/5 and C6 can introduce changes before C10.
C1–3 have explicit hard-counter combination and defense guardrails; these disappear
at C4. Captains use the normal runtime monster kind with separate route role tuning.

| Contract | HP curve | Target-DPS curve | Armor curve | Block / absorb curve |
| --- | --- | --- | --- | --- |
| 1 | 1.0 | 1.0 | 1.0 | 1.0 |
| 5 | 1.4 | 1.8 | 1.6 | 1.4 |
| 10 | 2.3 | 3.5 | 2.8 | 2.4 |
| 15 | 3.8 | 6.0 | 4.8 | 4.0 |
| 20 | 6.0 | 10.0 | 7.5 | 6.2 |
| 25 | 9.0 | 16.0 | 11.0 | 9.0 |
| 30+ | 13.0 | 25.0 | 16.0 | 13.0 |

These are base curves, not final enemy multipliers. Role weights further scale
them, with stronger boss weights. Generated HP combines the scaled target DPS,
HP-budget duration, archetype/kind HP biases, mitigation adjustment and HP curve.
The HP-budget duration floor is 18 seconds at C1–3, 22 at C4–10, 26 at C11–20
and 30 thereafter. A short fight can therefore have HP budgeted for a longer
window. Do not independently tune time, HP and the DPS curve without considering
their combined effect. Gold pressure continues as floor(contract_number / 2),
but the same unbounded value does not drive enemy stats.

Sources: `contract_route_generator.gd` (`TEMPLATES`, `_progression_for`,
`_encounter_pressure_scale`, `_mechanic_guardrails_for_encounter`, five curve
functions, `_encounter_tempo_profile`, `_assign_generated_reward`),
`runtime_monster_generator.gd` (`_apply_pressure_model`, `TEMPO_PROFILES`).

## Reward, shop and equipment opportunity

New Adventure starts with the Crude Dagger and zero gold. Tavern base gold totals
90 before purchases, theft, multipliers or overkill. Drunk Buddy also grants Lucky
Coin (+5 percentage points crit) and unlocks shop access. Shop opportunities follow
eligible Tavern rewards and terminal contract victories, except the catalog-ending
victory. Shops roll six offers, with slot/tier/affixes determined by seeded generation;
an exact desired item is not guaranteed. Rerolls cost 5, then 10, 15, etc.

Base tier prices are Basic 18, Master 32, Epic 46, Cursed 40, Chaos 55, Unique 70,
Legendary 80. Discount effects can change purchase price; ordinary sale value is
half the tier price, floored, with a special zero-value starter dagger. Equipment
has five slots and inventory has three spaces. Affordability alone is not proof
that a useful upgrade was offered or could be retained.

Every generated combat role currently offers two generated gear choices; the older
`gear_depth_threshold` fields do not gate `_assign_generated_reward`. Base gear
tier is Basic below difficulty score 4, Master at 4–5, Cursed at 6+, with +1 score
for elites and +2 for bosses. Normal/captain slot pools select one slot, elites two,
bosses all five. Rarity upgrades and Magic Find modify the realized choices.
Shop rarity has anchors at contract depths 1/6/12; reward upgrade depth also clamps
at 12. These are actual availability rules, not guaranteed equipment fixtures.

Sampled complete-path base gold spans 43–72 at C1, 113–167 at C10 and 253–357 at
C30. These are alternative path totals, not summed branch rewards or carried stash.
Overkill adds 10 gold per 100 excess damage up to 50 before applicable reward
multipliers. Theft and selling add other income; purchases/rerolls remove it.
T4/T7 must use recorded acquisition/spending policies to establish typical/weak/strong
gear and Thief/Bandit Blade gold trajectories. Fixed zero stash is only a control.

Sources: `build_state.gd` (shop, reward, sale and gold methods/constants),
`gear_generator.gd` (`PRICE_BY_TIER`), `contract_route_generator.gd` reward methods,
`02_drunk_buddy.tres`, `lucky_coin.tres`, `bandit_blade.tres`.

## Diagnostic combat evidence and limits

The reproducible probe inventories 90 routes: seeds 7001–7005 at C1–11, C15/20/25/30/31/40/60.
Combat samples use seed 7001's first encountered node of each role at C1/4/6/10/11/20/31,
all four primary trees, two weapons and seeds 201–220. Contract allocations use the
existing protocol's 10 points at C1, 21 at C4 and 35 at C6 onward. Remaining earned
points are intentionally unspent; there is no secondary. The frozen 30-second
optimized dummy macro is replayed against the actual encounter window without
re-optimization. This tests portability, not ordinary-player macro quality.

Controls use either Crude Dagger or the legendary Bandit Blade, no other equipment,
and zero starting stash. Bandit Blade is not an assumed early acquisition. Tavern
uses incoming budgets 0/1/1/5; zero-point macro is Stab, and five-point ranks are a
legal prefix of the corresponding ten-point fixture with the one-point macro.
These omit Lucky Coin, purchases and better five-point macros; they cannot qualify
Tavern balance. Exact ranks, macros, monster stats and every sample are recorded.

Selected findings:

- With Bandit Blade, every tree won 20/20 against the sampled C1 boss, but the C1
  captain gave Thief 14/20 and Shadow 7/20. The same tree need not struggle most
  against the boss.
- On the sampled C4 boss, Bladedancer/Thief/Assassin won 20/20 and Shadow 0/20.
  This warrants matchup/macro/gear investigation; it is one fixed enemy sample.
- At C10, weapon-only boss controls ranged from 0/20 to 11/20; at C11 all were
  0/20. This does not establish a normal-gear progression wall.
- Zero-point Crude Dagger/Stab wins against Mouthy Drunk were 13–14/20 across
  primaries. Investigate the intended introductory macro before adopting a 99%
  starter-success target. Unlimited retries alone do not establish a smooth tutorial.
- The exact legacy `bladedancer_contract_watchmen` scenario was rerun separately
  over 200 seeds: 99.5% wins, still above its historical 95% upper threshold, so
  the report correctly returns `warn`. It uses legacy mixed content and Wyvern
  Kriss; it is not a current ranked Bladedancer balance result. Current ten-point
  Watchmen controls are separately labeled in the probe.

There are 264 diagnostic cases / 5,280 combat samples plus 200 legacy Watchmen
samples. Twenty-seed cases are screening evidence, not precise success estimates.
No full runs, retry adaptation policy, mixed-build balance matrix, gold trajectory
simulation or hands-on fun acceptance was performed. Those belong to T4/T7/T9.

## Adventure integration gaps and handoff

| Gap / finding | Next owner and action |
| --- | --- |
| Adventure/Resume disabled; retained selection and persistence use compatibility resources | T8: promote a reviewed playable registry through new run, selection, load/save, rewards and restart; verify with isolated saves before normal access. |
| Test Mode skips Tavern and provides special starting gold/gear | T4/T8: establish fresh-Adventure fixtures and entry checks; do not reuse Test Mode convenience as economy acceptance. |
| Fixed roles, contract secondary milestone and different respec rules | T8: preserve and test across allocation, retry, contract completion and persistence. |
| Finite 30-boss completion and C30 stat plateau | T2: record present prototype limits. T6/T8: determine whether any scoped adjustment is needed for this phase. True endless mode and The Road remain future scope unless explicitly promoted. |
| C4 guardrail removal; C6/C11 bands; short-window HP floors | T4–T6: targeted matchup and pacing cases before changing coefficients. |
| Typical gear/stash not represented by controls | T4/T7: reproducible acquisitions and spending; then test proposed C10 smoothness. |
| Old Watchmen upper-threshold warning persists | T4/T10: retain legacy comparison, establish a separate current-content target; do not silently change the historical threshold. |
| Two unsampled route templates and small enemy cohort | T4: expand coverage deliberately, including mandatory versus avoidable counters. |
| Fun and complete-run success remain unmeasured | T9/T10: player observations and representative runs; audit completion is not gameplay acceptance. |

T2 can now reconcile its intended direction with this baseline. Keep timing close
to current values, treat percentages as provisional until realistic scenarios
exist, and distinguish future endless design from present runtime. Nothing here
requires a curve rewrite or adds The Road to Phase 6.

## Reproduction and verification

From the repository root:

```powershell
& 'F:\Applications\Godot\Godot_v4.7-stable_win64_console.exe' --headless --path project --log-file 'F:/Data/Claude Projects/Project-FacelessVoid/project/reports/p6_m6_t3/godot.log' -s res://scripts/tools/run_m6_t3_audit.gd
python project/reports/p6_m6_t3/summarize.py
```

- [Readable results](../../../project/reports/p6_m6_t3/results.md), [summary](../../../project/reports/p6_m6_t3/summary.json), [case CSV](../../../project/reports/p6_m6_t3/measurements.csv), [full inventory and samples](../../../project/reports/p6_m6_t3/probe.json).
- [Legacy Watchmen evidence](../../../project/reports/p6_m6_t3/watchmen_legacy.json).
- Final probe exited 0 with valid generated routes and combat results; 367 preexisting
  source/data/project and discovered save-file fingerprints remained unchanged.
  The audit adds a probe and reports, not gameplay edits. Fingerprint coverage is
  explicit in `protected_before.json`; it is not a claim to hash the entire sibling checkout.
- Initial probe omitted deferred generated payloads and had zero generated enemies;
  it was corrected to decode them as the live commit path does, then rerun. Only
  the final complete report is acceptance evidence. Added coverage guards reject
  empty generated inventories. Existing certificate and shutdown-resource diagnostics
  remain in the log; no clean-engine-shutdown claim is made.

T3 is Complete for this bounded audit. T2 subsequently closed under P6M6-D004
on 2026-10-07; T4 is next and owns the representative scenario matrix and realistic
gear/macro policies. T2 accepts prototype limits and uses percentages diagnostically.
