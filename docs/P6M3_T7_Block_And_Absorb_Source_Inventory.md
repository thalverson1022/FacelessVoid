# T7 Block and Absorb Source Inventory

> **Historical record — not an active work plan.** Status labels, next-step instructions and milestone numbering below describe the recorded checkpoint. M8 is closed; consult the current M9 tracker for authorized work. Retained at this path when tooling/manifests depend on it. [Current context](P6_Project_Onboarding_Context.md).

Date: 2026-09-24. Historical source audit, preserved for comparison.

**Current implementation:** The [T7 handoff](P6M3_T7_Status_And_Mitigation_Interactions.md)
now resolves the review items below and records shared fixture implementation
under D014–D017. Starting defense denial, timed debuffs, negative-defense base
bonuses and conversion order are settled. Statements below describe the original
audit snapshot, not current implementation status. Playable content remains unchanged.
Owner: [T7 handoff](P6M3_T7_Status_And_Mitigation_Interactions.md).

Searched player stats, stat catalog/pools, resource/stat resolution, combat
mitigation, authored project data, and all four authoritative tree JSON drafts.
Enemy defense values are targets, not player penetration sources. Tree Lab
examples duplicate draft content and are not additional sources.

## Direct sources

Update: the inventory below preserves the original draft for comparison.
[D014](P6M3_T7_Status_And_Mitigation_Interactions.md) now specifies Finders Keepers
as encounter-start 50%/100% block reduction, Blinding Powder as Assassin-point
Potency application, and Death Pact as consumed-stack applications of both
Potency and Penetration. Both debuffs have 100-stack caps and three-second
baseline refreshed timers. These designs are not implemented by this inventory.

| Source | Status | Existing behavior / draft | Review needed |
| --- | --- | --- | --- |
| Enemies can no longer block (`disable_enemy_block`) | Implemented special gear stat | Binary full denial; effective block is zero, no timer, no additive stacking. In special pools for armor, trinkets and charms. | Whether zero is a starting baseline before new flat reduction, or complete bypass; interaction with negative block bonus. |
| Enemies can no longer absorb (`disable_enemy_absorb`) | Implemented special gear stat | Binary full denial; effective absorb is zero, no timer, no additive stacking. In special pools for armor, trinkets and charms. | Same question for absorb; interaction with timed reductions and converted damage. |
| Blinding Powder — Assassin automatic skill at three points | Draft, not implemented | Poison ignores Assassin Level absorb; draft value is +1 per tree point and defines Level as an unresolved design question. | User now favors a timed absorb-reduction stack effect. Need activation, amount per stack, stack grants/cap, duration/refresh, point scaling and Poison-only versus all elemental scope. |
| Death Pact — Shadow talent, three ranks | Draft, not implemented | Consuming Poison/Decay grants that many Pact stacks; each ignores one block or one absorb. Timer values 2/4/6 have a mistaken percent unit. | Player buff versus enemy reduction; eligible consumption, duration unit/refresh/cap, defense selection, whether charges are spent, interaction with below-zero defenses. |
| Finders Keepers — Thief talent, two ranks | Draft, not implemented | Text says attacks ignore block; numerical values are 50%/100% ignored block. | User now describes treating starting block as zero, before other reductions. Resolve whether that changes rank one, scope, and equivalence to the existing gear denial. |

No additional direct player block/absorb penetration source was found in the
searched runtime/data/drafts. In particular, there is no implemented ordinary
flat or percentage block/absorb penetration stat in `PlayerStats`/`StatCatalog`.
The generic `enemy_denial.block/absorb` flags are the runtime representation of
the two special stats above, not separate mechanics.

## Related interactions, not direct penetration sources

- Physical/magical damage-conversion gear changes which defenses a packet uses.
  Both flags currently run physical then magical mitigation. It does not lower
  either defense; negative-defense base bonuses need a reviewed conversion rule.
- Armor ignore, resistance ignore, Shred and Decay affect armor/resistance rather
  than block/absorb. They are not additional sources for this inventory.
- Bonus Stacks/doubling could affect future Blinding Powder/Pact stack grants,
  but that must be decided per effect; they do not currently penetrate defenses.

## Source evidence

- `project/scripts/systems/stat_catalog.gd`: labels, binary definitions and
  armor/trinket/charm special pools.
- `project/scripts/resources/stat_sheet.gd`: maps special stats to enemy denial.
- `project/scripts/systems/combat_resolver.gd`: effective block/absorb return zero
  on denial, otherwise monster values; natural Poison uses effective absorb too.
- `project/scripts/systems/damage_calculator.gd`: conversion/mitigation and current
  nonnegative defense clamps. Negative-defense damage bonuses are not implemented.
- `docs/talent_tree_drafts/Assassin.json`: Blinding Powder unlock.
- `docs/talent_tree_drafts/Shadow.json`: Death Pact talent.
- `docs/talent_tree_drafts/Thief.json`: Finders Keepers talent/rank values.

Review the five sources individually before finalizing shared composition.
An inventory does not approve the draft values or change the playable registry.
