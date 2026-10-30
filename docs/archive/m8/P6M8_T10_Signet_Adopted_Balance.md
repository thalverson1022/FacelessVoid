# Adopted Signet conversion balance

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. [Current context](../../P6_Project_Onboarding_Context.md).

P6M8-D095, 2026-10-25. User approved changing Signet from2× to **1.5×**. Both Crit Chance→Increased Attack Speed and bonus Crit Damage→Increased Physical Damage now use1.5× in the game. This supersedes the previous production2× coefficient; D094’s results remain historical evidence for their tested coefficients.

## Runtime and presentation

- `IAS added =1.5 × uncapped resolved Crit Chance`.
- `Physical increase added =1.5 × (resolved Crit Damage multiplier −1)`.
- Keep all-source and live gold/temporary-buff inputs, single conversion/replacement behavior and universal inability to crit. Fixed item affixes are unchanged.
- Item effect text now says1.5x on both conversion lines. Character Stats’ worked example now maps150% Crit Chance to+225% IAS, and×2.5 Crit Damage to+225% physical damage.
- Beguiling Presence now displays+3% Attack Speed per consumed Decay with Signet alone, or+6% with Crown; detailed conversion wording also says1.5x. Live stat sheet and equipment comparison use the actual resolved values.

## Verification

[Manifest](../../../work/m8_t9_presentation/d095_verification.json). Disposable project `work/m8_t9_presentation/signet_adopted_15x`; save paths and app-data redirects remain isolated. No real-save access or production launch.

Seven focused suites pass **1,038 checks**: Legendary stats186; Signet live stat display32; all16 item presentations456; skill presentation110; combat119; actual skill hovers63; actual UI72. Checks cover raw overcap inputs, temporary sources/expiry, gold/theft changes, no duplicate conversions, no-crit including Poison/Side Step, effective display and item/skill copy. Updated independent expected arithmetic, including the engine’s27-damage rounding of a26.5 raw test hit.

Inspected actual-size shop Signet comparison and Beguiling hover captures: both1.5x lines fit, and the skill shows+3% Attack Speed. [Shop capture](../../../work/m8_t9_presentation/signet_adopted_15x/project/reports/t9_ui_review/adventure_signet_comparison.png), [Beguiling capture](../../../work/m8_t9_presentation/signet_adopted_15x/project/reports/t9_skill_hover/beguiling_signet.png).

The same200-seed35BD/10Thief Crude-Dagger baseline from D094 now averages **1,921.23 DPS**, versus2,540.33 at2×. It uses the same30-second empty dummy, full35BD and Sticky Fingers5/Fast Hands5, zero starting gold and five-skill rotation. This is a focused adoption benchmark, not a rerun of the entire704-evaluation D094 study or a claim of final overall balance.

Only five runtime/presentation files and five test files changed. All2,401 other existing project files remain hash-identical, including item resources, loot, saves and artwork. Existing certificate-store and shutdown resource diagnostics remain in logs. T10 remains In progress; T9 Pending input. No additional drawbacks or unrelated mechanics changed.
