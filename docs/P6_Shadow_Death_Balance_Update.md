# Shadow damage and stacks — P6M5-D020

User-approved live changes:

- Death Strike adds +2 base physical damage per active Poison stack, before its 111% coefficient and physical modifiers. It still does not consume Poison.
- Death Blade triggers Stab at 40% per rank (40/80%) per Poison application that actually adds stacks. It grants no additional Stab crit chance. All Stab Poison sources remain suppressed under Death Blade.
- Death Touch adds +3 stacks per rank (3/6/9) to the existing Increased All Stacks fields. Extras and doubling retain their original order; Poison/Decay quantities consumed remain actual quantities.

D019 Coated Weapons remains two base Poison stacks. Beguiling Strike remains one base Decay. Talent IDs, gates, costs, ranks, and compatible save revisions are unchanged. Legacy resource files are preserved; the promoted Death Strike clone and its tooltips bind the live coefficient.

Live verification uses the screenshot's 21-point allocation: Snake Oil 4, Coated Weapons 1, Deception 5, Death Touch 3, Death Pact 2, Shadow Mastery 2, Dusk Strike 1, Death Blade 2, Umbral Presence 1. Macro: Beguiling Strike / Distilled Corruption / Distilled Corruption / Beguiling Strike / Death Strike / Distilled Corruption / Death Strike / Death Strike / Touch of Darkness / Distilled Corruption.

Crude Dagger only, zero starting gold, zero-defense dummy, 30 seconds, seeds 1–200: 134.89733 DPS (108.94133 direct, 25.956 Poison). Live native Balance Lab matches the isolated trial exactly; Practice and Lab seed-one parity passes. [Live report](../project/reports/balance/shadow_twenty_one_point_d020_live/summary.json).

Six focused suites pass: full Shadow, Shadow boundaries, full Shadow journeys, combat presentation, status completion, and full tree display. Final full Shadow and boundary reruns additionally verify the promoted damage descriptor, 40/80% tooltip, and unchanged Stab crit chance. [Suites](../project/reports/p6_d020_shadow_balance/summary.json); [final tooltip checks](../project/reports/p6_d020_shadow_tooltips/summary.json). Protected player saves remain unchanged.

The previous D019 manifest is archived as shadow_release_manifest_pre_d020.json. Release source hashes and immutable compatibility checks pass. Earlier Shadow reports and one-stack/10–20%/+2-stack design values are historical.
