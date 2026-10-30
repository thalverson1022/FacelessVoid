# Locket verification and Crown effect audit

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. [Current context](../../P6_Project_Onboarding_Context.md).

**D097 supersedes the Meditation exception below:** Crown now doubles its bonus to40% per stack,×3 at five stacks. The seven-family audit below is historical; Meditation is now also affected. [Current implementation](P6M8_T9_Crown_Meditation_Clarification.md).

P6M8-D093, 2026-10-25. User reported not seeing Locket cooldown recovery and requested the Crown’s affected buffs. Read-only audit and isolated verification; no runtime changes. T9 Pending input and T10 In progress remain unchanged.

## Lolzorz’s Locket

Verified the actual resource in a valid ranked 35 Bladedancer /10 Thief build with Nightkiss Katana. Used Dance → Quick Cut → Heavy Slash → Parry Strike → Leaping Plunge → Exsanguinate, an undefended billion-health dummy and 30 seeds, 30 seconds each. No crit or cooldown overrides.

487 qualifying critical-hit trials produced 102 successful 20% rolls and 160 individual running cooldown changes. Each deadline became `max(current time, old deadline -1000ms)`. One success can affect multiple cooldowns. A control retaining the same stats with only the Locket signature disabled emitted no recovery trials.

At3181ms in the representative replay, Dance’s ready deadline moved from17500ms to16500ms. The actual Skill Build countdown label changed **14.3s →13.3s** at the same playback time in both Adventure and Practice. Rendered screenshots were visually inspected at1280×720. These dashboard captures inject the native result into the actual presentation model/panel; the displayed empty gear/talent panels are not a recreation of the simulated equipment. The live presenter wiring into that same model/panel was inspected separately.

The code rolls20% per qualifying critical hit, including critical Poison when its talent permits critting. It does not proc on every critical hit or on ordinary retriggers. A proc only reduces cooldowns already running, with no banked credit. The Signet prevents crits and therefore prevents Locket triggers. The15% Cooldown Reduction affix is separate from its one-second proc. There is no dedicated proc flash; recovery appears as a countdown jump, which can be easy to miss. No missing-recovery bug reproduced; this does not establish the user’s exact saved setup.

Evidence: [manifest](../../../work/m8_t9_presentation/locket_verify_d093/verification.json), [native witnesses](../../../work/m8_t9_presentation/locket_verify_d093/project/reports/locket_audit/witness.json), [Practice before](../../../work/m8_t9_presentation/locket_verify_d093/project/reports/locket_audit/practice_before.png), [Practice after](../../../work/m8_t9_presentation/locket_verify_d093/project/reports/locket_audit/practice_after.png).

## Crown: current implemented scalar effects

| Effect | Without Crown → with Crown |
|---|---|
| Bypass | +10% →+20% elemental damage per stack |
| Touch of Darkness | Per Poison consumed: +10% →+20% attack speed; +2 →+4 base physical damage |
| Beguiling Presence | Per Decay consumed: +1 →+2 base elemental damage; +2 →+4 percentage points Crit Chance |
| Virulent Poison | ×2 →×3 Poison damage per active activation; five charges unchanged |
| Fancy Footwork | Leaping Plunge time reduction doubles:4% × rank →8% × rank per consumed stack; cast-time minimum still applies |
| Riposte | Plunge damage bonus doubles:20% × rank →40% × rank per consumed Footwork stack |
| Wingjammer Dash | +5% →+10% attack speed per stack; cap20 unchanged |

**Meditation is currently an explicit exception:** it remains+20% all damage per stack, up to×2 at five stacks, with or without Crown. This is existing resolver behavior and an explicit expectation in the Meditation test, not a change made during this audit. The general “Doubles the effects of self buffs” tooltip does not explain this exception.

Readiness, Precision, Dance and Master of Poisons have permission/guaranteed/boolean behavior with no extra scalar strength to double. Ordinary always-on stats and every passive talent are not automatically self buffs. Enemy Penetration/Potency are debuffs. Crown does not double stack grants, caps, proc chances, charges or durations; its separate+20% Increased Buff Duration affix still extends applicable timers normally.

Runtime paths: `combat_self_buffs.gd` (Beguiling/Virulent), `combat_talent_buffs.gd` and `combat_stat_state.gd` (Bypass/Touch), `bladedancer_effect_lifecycle.gd` (Footwork), `combat_resolver.gd` (Riposte/Dash/Meditation/Locket), `combat_macro_scheduler.gd` (recovery deadlines), `combat_presentation_state.gd` and `skill_build_panel.gd` (visible recovery).

## Verification scope and limitations

Four successful checks/suites total637 assertions: native/UI Locket audit196; T7 combat119; T9 combat feedback130; Legendary stats192. No production launch or real-save access. Source/content compared byte-for-byte against the isolated copy, excluding the deliberately rewritten save/config isolation paths; no gameplay, loot, assets or save changes.

The legacy `t9_meditation_all_damage_test` reports169 passing/3 failing assertions: its old Exsanguinate repeat expectations conflict with the adopted no-retrigger rule. The failures are not Crown or Locket failures. It is not claimed passing and was left unchanged. Existing certificate-store and shutdown resource diagnostics remain in console logs; the custom UI harness emits20 ObjectDB/14 resources, matching the D092 equivalent UI diagnostic baseline. A broader playtest of the user’s exact saved build was not performed.
