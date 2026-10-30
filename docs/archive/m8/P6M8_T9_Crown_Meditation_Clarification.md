# Crown boosts Meditation

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. [Current context](../../P6_Project_Onboarding_Context.md).

P6M8-D097, 2026-10-25. User clarified that Crown should boost Meditation because it is a buff, while acknowledging both are currently helm effects.

Crown now doubles the additive Meditation bonus: **+20% →+40% all damage per stack**, so the five-stack maximum becomes **×3 total damage**, versus×2 normally. Both physical damage and Poison use the Crown-aware multiplier. Zero stacks still gives×1. The grant trace stores the doubled magnitude, so the existing buff tooltip/inspector shows the actual multiplier. Shared rules mention40% with Crown.

Stack grants, All Stacks/stack-doubling behavior, cap five, refresh-at-cap and duration scaling are unchanged. Exsanguinate remains unscaled and unable to retrigger. Equipment rules are unchanged: Crown and Samurai remain mutually exclusive helms. The combined effect is qualified with isolated descriptor fixtures; this does not claim a currently obtainable two-helm loadout.

[Manifest](../../../work/m8_t9_presentation/d097_verification.json). Four suites pass701 checks (Meditation all-damage258, combat119, Legendary stats186, combat feedback138), plus two actual-inspector checks: **703 total**. Physical and natural/free-retrigger Poison packets are checked with Crown off/on, including per-stack arithmetic, cap, shared expiry and raw-input immutability. The Exsanguinate exclusion fixture now creates actual Crown-amplified Meditation through preceding attack retriggers, then confirms health removal remains30 rather than90. Its obsolete pre-D090/D091 repeat expectations were updated to the already-adopted no-retrigger/1× rule; no Exsanguinate behavior changed.

Inspected [actual buff inspector](../../../work/m8_t9_presentation/crown_meditation_d097/project/reports/crown_meditation/inspector.png) at1280×720: five stacks,×3.0 damage multiplier,40% Crown rule, unchanged3s base timer. All runs used a disposable project and isolated paths, without real saves or a production launch. Existing certificate-store/resource shutdown diagnostics remain visible.

Only the resolver, shared effect text and relevant Meditation regression test changed. All2,408 other existing project files are hash-identical, including loot, save systems, assets, fixed item resources and Signet conversion. This resolves the known Crown/Meditation T9 mismatch. **T9 remains Pending input for overall presentation acceptance**; T10 remains In progress.
