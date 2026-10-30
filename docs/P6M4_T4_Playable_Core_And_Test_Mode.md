# M4-T4 — Playable core and Test Mode

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

Status: Complete for the representative playable content scope. M4-T5 is next; full UI and end-to-end milestone acceptance remain T5–T11.

## Entry and starting conditions

The title now displays disabled New Adventure and Resume Adventure buttons and an enabled Test Mode button. Test Mode opens the generated contract picker directly. Each entry starts with Rogue / fixed Bladedancer, ten unspent talent points and an empty rotation. Restart uses the same seed; a new title entry uses the selected/random seed control.

Starting defaults retain the former test setup: equipped Bandit Blade, 100 gold, no extra starter dagger in inventory, three medium-difficulty generated contract offers. These defaults were proposed during implementation and retained pending any user preference change. Gear, shops, rewards and generated enemies use the existing Phase 5 systems.

## Content boundary

`BuildContentRegistry.test_mode()` deliberately selects `p6.playable.bladedancer_core.1`, backed by production resources in `project/data/p6/test_mode/`. Runtime resources do not depend on `tests/fixtures`. This is a mode-specific registry; Adventure and Practice retain `p6.compat.1` and their existing compatibility behavior.

The playable slice copies the reviewed M3-T8 contracts:

- Whetstone, maximum five ranks; Rending Slash, one rank; Fancy Footwork, five ranks.
- Core acceptance allocation: Whetstone 4 / Rending Slash 1 / Fancy Footwork 5.
- Base Hold, Stab and Heavy Slash; Quick Cut at one invested point, Leaping Plunge at three, Parrying Strike at six, Rending Slash from its talent. The nine-point slot is intentionally empty.
- Bladedancer intrinsic: 5% retrigger plus 0.2 percentage points per invested primary-tree point.
- No secondary tree, Dance or other talents. The contract picker explains this boundary.

The existing generated contract loop remains available. Contract rewards still award five talent points under the existing 45-point cap. The core supports eleven total ranks; subsequent points remain unspent once these ranks are filled. This limits available content without introducing new progression rules or granting unfinished skills.

## Session and save isolation

Test Mode sets `BuildState.is_test_mode` and `SaveSystem.session_only`. Central Adventure save, load and delete entry points reject persistence during the session; autosave calls remain harmless. No Test Mode save file is created. Exit, abandon and restart clear or recreate in-memory state. Restart stays in Test Mode rather than entering Adventure selection. The exit tooltip and terminal restart labels describe the session correctly.

Practice uses its existing independent state and save system. No registry override is applied globally. The disabled title Adventure signals are disconnected, protecting the preserved save from accidental menu dispatch.

## Validation

- Actual title-to-contract-card-to-route-selection checks pass.
- The core allocates all ten points, unlocks seven skills, accepts the approved five-slot rotation and resolves a real UI-triggered fight.
- Sentinel-file tests verify Adventure and Practice bytes survive combat autosave, explicit save deletion attempts, restart, retry, terminal failure, reward claims, next-contract generation, exit and abandon. Reward/route traversal uses synthetic wins to isolate state transitions; this is not a balance claim.
- Re-entry resets allocations, rotation and starting conditions. Unsupported secondary selection is rejected. Adventure entry remains disabled.
- Regression evidence: [eight-script suite](../project/reports/p6_m4_t4_validation/summary.json), [final session safety](../project/reports/p6_m4_t4_safety_final/summary.json). Later UI-focused results are recorded under `project/reports/p6_m4_t4_ui_final/`.
- Real Godot title, contract picker and planning screens were rendered at 1280×720, 1600×900 and 1920×1080. The seven-skill row initially overflowed at 1280; it now wraps and all columns fit. [Title](../project/reports/p6_m4_t4_visual/title-1280.png), [contracts](../project/reports/p6_m4_t4_visual/contracts-1280.png), [core planning](../project/reports/p6_m4_t4_visual/planning-1280.png).

The OpenGL screenshot process reported resource cleanup warnings on exit and the environment's certificate-store warning; no script errors were reported in the completed render. This is scoped scene verification, not full M4 dense-layout acceptance or a manual gameplay/balance playtest.

## Next work

T5 implements the agreed tiered talent tree with icons, prerequisites and rank controls, and validates Practice tree/role selection and allocation. T6 owns fuller skill descriptions/rotation UX; T7 owns complete effect/cooldown presentation. T8 remains the complete core end-to-end acceptance gate, and T9 introduces the mixed-tree extension. Those tasks are not closed by this integration.
