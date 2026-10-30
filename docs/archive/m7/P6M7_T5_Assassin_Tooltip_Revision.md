# T5: Assassin tooltip revision

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. [Current context](../../P6_Project_Onboarding_Context.md).

Current task status: **Complete — user accepted T5 under D039 on 2026-10-15.** See [closeout and accepted conventions](../../P6M7_T5_Closeout_And_Accepted_Conventions.md).

The dated status, proposals and evidence below are historical snapshots; later accepted conventions and D039 supersede earlier In progress/closeout-excluded instructions.

User-approved D031 presentation revision, 2026-10-14. T5 remains **In progress**; no milestone closeout.

## Current wording

Assassin's per-point bonus row omits `(primary only)`, retaining its live `+0.5 base elemental damage per invested point`. Actual primary-only scaling and secondary `Bonus: NONE` remain unchanged, as in the earlier Thief display revision.

Skills:

- Venom Jab: `On hit: Apply X stacks of Poison`, using the current-build effective Poison application count. Other Poison skill application copy remains unchanged.
- Blinding Powder: `Apply X stacks of Potency`, using current invested Assassin points, application bonuses and existing cap/doubling rules.
- Virulent Poison: `Next 5 ticks of Poison deal 2x damage`; Duration omitted, Cooldown retained.
- Master of Poisons: `Elemental damage ignores Resistance`; its existing Cooldown/Duration remain.
- Vile of Poison (`skill.poison_vile`): Duration omitted, existing Cooldown retained.

Talents:

- Echoing Toxin: `Each Poison tick now consumes 2 stacks at the cost of slower tick rate.` Then `Poison Suppression penalty: xX%`, using live 40%/30%/20% suppression values.
- Hastened Poison: `Poison tick rate is affected by your Attack Speed.` Then `Percentage of Attack Speed converted to Tick Rate: X%` (10% per live rank).
- Bypass: `Stab grants 1 stack of Bypass. Bypass stacks up to 3 and lasts for 3 sec. Each stack of Bypass increases elemental damage by x10%`.
- Resonance: `Each Poison tick now consumes 3 stacks.` Then `Increase Poison damage per stack consumed: xX%` (live 5% per rank).
- Accelerant: `Apply more of your attack speed to Poison tick rate.` Then `Percentage of Attack Speed converted to Tick Rate: X%` (10% per live rank).
- Critical Poison: `Poison can now critically hit based on your crit chance and crit damage.`

Active Talents inherits these current-rank rows automatically. Neutral cream effects, absent talent Requires text, current/Next sections and omission of Next at maximum remain. D030 Thief copy, both renderers, new Shadow image and increased-stacks gear label are preserved. The supplied player-facing consumes/ticks language changes presentation only; detailed mechanics, effects, counters, tick behavior and combat resources remain untouched.

## Verification

[Final talent/skill focused report](../../../project/reports/p6_m7_assassin_wording_focused_final/summary.json): both suites pass, with **4,750** talent assertions and **612** skill assertions. Coverage includes all 44 talents/140 ranks and 23 skills, exact new wording, source-backed suppression/Resonance/tick-rate values, live Venom and Potency counts, approved duration exceptions, retained Thief assertions, neutral cream/no Requires and current/Next/max behavior.

[Shared Active Talents/background result](../../../project/reports/p6_m7_assassin_wording_focused/summary.json): the existing suite passes **1,356** assertions against the same final production hashes, including every positive-rank row's text/color and role/layout/input checks. That initial report also retains two failed talent/skill fixtures: a malformed Venom assertion replacement and a stale capitalized stat-label expectation. Those were corrected in tests only; the final focused report supersedes their failures.

[Rendered results](../../../project/reports/p6_m7_assassin_wording_rendered/summary.json): **48 actual captures** pass. Adventure, Test Mode and Practice cover primary/secondary Assassin roles; headers at 1280/1600/1920 and 125%; current/next Echoing, Hastened, Resonance and Accelerant; max Bypass/Critical Poison; Active Talents and all five revised skill hovers at 1280/125%. Representative renders were inspected by implementation and coordinating agents. Longer Bypass text and Echoing current+next fit the 1280x720 viewport; Venom/Potency counts and Virulent/Vile duration omissions are visible. This narrow matrix does not repeat a complete individual audit of every skill/talent.

All three run isolation records report unchanged sources and disposable saves. [Before fingerprints](../../../work/t5_assassin_wording_before/hashes.json) and [final reconciliation](../../../work/t5_assassin_wording_before/final_verification.json) confirm all tracked production files match every run baseline. Active Talents implementation, both hover renderers, stat catalog and Shadow JPG are unchanged from the start of this revision; Shadow SHA256 remains `458fe5901d0ed4ddc5afe4003d792a4c35c92659cb51ee4addbb4108bd6b43da` (assets are separately hashed). The coordinating agent confirmed all 330 protected mechanics/resource/data files remain unchanged.

```text
python tools/p6/run_m6_closeout.py --report-name p6_m7_assassin_wording_focused --tests p6_m7_talent_hover_test p6_m7_minimal_skill_hover_test p6_m7_tree_background_active_text_test
python tools/p6/run_m6_closeout.py --report-name p6_m7_assassin_wording_focused_final --tests p6_m7_talent_hover_test p6_m7_minimal_skill_hover_test
python tools/p6/run_m6_closeout.py --report-name p6_m7_assassin_wording_rendered --visual --tests p6_m7_assassin_wording_visual
```

Reviewed examples:

- [Bypass max rank, 1280/125%](../../../project/reports/p6_m7_assassin_wording_rendered/p6_m7_assassin_wording_visual/assassin_wording_visual/test-bypass-1280-125.png)
- [Echoing current x30% / next x20%](../../../project/reports/p6_m7_assassin_wording_rendered/p6_m7_assassin_wording_visual/assassin_wording_visual/practice-echoing_toxin-1280-125.png)
- [Virulent Poison without Duration](../../../project/reports/p6_m7_assassin_wording_rendered/p6_m7_assassin_wording_visual/assassin_wording_visual/test-virulent_poison-1280-125.png)
- [Blinding Powder current-build stacks](../../../project/reports/p6_m7_assassin_wording_rendered/p6_m7_assassin_wording_visual/assassin_wording_visual/practice-blinding_powder-1280-125.png)
- [Vile of Poison without Duration](../../../project/reports/p6_m7_assassin_wording_rendered/p6_m7_assassin_wording_visual/assassin_wording_visual/adventure-poison_vile-1280-125.png)

Retained certificate-store/teardown warnings remain in engine logs; final focused/rendered suites have no script/assertion failures. No broad combat regression or milestone closeout was performed for this presentation revision.

## Copy refinement D036 (2026-10-15)

Removed the requested effect-text trailing periods from Poison Vile, Hastened Poison, Echoing Toxin, Accelerant and Critical Poison. Resonance now says `Each tick of Poison now consumes 3 stacks but does more damage`; its separate gold damage value remains unchanged. Shared Active Talents inherits the current-rank wording, and Next rank still shows only changing values or new effects.

Both [focused tooltip suites](../../../project/reports/p6_m7_assassin_copy_cleanup_focused/summary.json) and the [48-capture Assassin rendering fixture](../../../project/reports/p6_m7_assassin_copy_cleanup_rendered/summary.json) pass. Actual Resonance current/Next and Poison Vile hovers were inspected at 125%; the visual fixture also scales RichTextLabel rows in Active Talents. Both source/save isolation records are unchanged, and all 330 protected mechanics files match the retained baseline. T5 remains **In progress**.
