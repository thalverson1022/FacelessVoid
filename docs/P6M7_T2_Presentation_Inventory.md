# M7-T2 live presentation inventory

Generated with `python tools/p6/audit_m7_presentation.py`. Full rank descriptions, unlocks and asset hashes: [coverage JSON](../project/reports/p6_m7_t2_audit/coverage.json).

Mappings are retained as the baseline; flagged readability candidates need T3/T4 review before changes. Text dispositions are audit findings, not final T5 acceptance. Skill text uses default planning stats; conditional build wording needs the T5 matrix. Gap IDs refer to the [audit](P6M7_T2_Presentation_And_Asset_Audit.md).

## Bladedancer

| Talent / stable ID | Ranks | Gate | Text disposition |
| --- | ---: | ---: | --- |
| Whetstone (`talent.bladedancer.wet_stone`) | 5 | 0 | Retain - no specific discrepancy found |
| Rending Slash (`talent.bladedancer.rending_slash`) | 1 | 0 | Retain - no specific discrepancy found |
| Fancy Footwork (`talent.bladedancer.fancy_footwork`) | 5 | 5 | Retain - no specific discrepancy found |
| Opportunity (`talent.bladedancer.opportunity`) | 3 | 10 | Retain - no specific discrepancy found |
| Cloak & Dagger (`talent.bladedancer.cloak_and_dagger`) | 2 | 10 | Retain - no specific discrepancy found |
| Weakness (`talent.bladedancer.weakness`) | 5 | 0 | Retain - no specific discrepancy found |
| Precision Attacks (`talent.bladedancer.precision_attacks`) | 1 | 5 | Retain - no specific discrepancy found |
| Double Dip (`talent.bladedancer.double_dip`) | 2 | 5 | Retain - no specific discrepancy found |
| Sharpened Edge (`talent.bladedancer.sharpened_edge`) | 5 | 10 | Retain - no specific discrepancy found |
| Riposte (`talent.bladedancer.riposte`) | 2 | 15 | Retain - no specific discrepancy found |
| Side Step (`talent.bladedancer.side_step`) | 1 | 15 | Retain - no specific discrepancy found |
| Weapon Master (`talent.bladedancer.weapon_master`) | 2 | 15 | Improve - G04 terminology |
| Virulent Corruption (`talent.bladedancer.virulent_corruption`) | 1 | 20 | Retain - no specific discrepancy found |

Automatic unlocks: 1 -> skill.quick_cut, 3 -> skill.leaping_plunge, 6 -> skill.parry_strike, 9 -> None, 12 -> skill.dance_of_death.

## Thief

| Talent / stable ID | Ranks | Gate | Text disposition |
| --- | ---: | ---: | --- |
| Keen Eye (`talent.keen_eye`) | 5 | 0 | Improve - G04 terminology |
| Sticky Fingers (`talent.sticky_fingers`) | 5 | 0 | Retain - no specific discrepancy found |
| Fast Hands (`talent.thief.fast_hands`) | 5 | 5 | Retain - no specific discrepancy found |
| Fill Your Pockets (`talent.thief.fill_your_pockets`) | 5 | 5 | Retain - no specific discrepancy found |
| Charisma (`talent.thief.charisma`) | 3 | 5 | Retain - no specific discrepancy found |
| Bribery (`talent.thief.bribery`) | 3 | 10 | Retain - no specific discrepancy found |
| Silvered Edge (`talent.thief.silvered_edge`) | 3 | 10 | Retain - no specific discrepancy found |
| Finders Keepers (`talent.thief.finders_keepers`) | 2 | 15 | Retain - no specific discrepancy found |
| Loaded Dice (`talent.thief.load_dice`) | 3 | 15 | Retain - no specific discrepancy found |
| Gilded Blade (`talent.gilded_blade`) | 1 | 20 | Retain - no specific discrepancy found |

Automatic unlocks: 1 -> skill.steal, 3 -> skill.mug, 6 -> skill.pick_pocket, 9 -> None, 12 -> skill.big_score.

## Assassin

| Talent / stable ID | Ranks | Gate | Text disposition |
| --- | ---: | ---: | --- |
| Quick Hands (`talent.assassin.quick_hands`) | 5 | 0 | Retain - no specific discrepancy found |
| Precision (`talent.assassin.precision`) | 5 | 0 | Retain - no specific discrepancy found |
| Hastened Poison (`talent.assassin.hastened_poison`) | 5 | 5 | Retain - no specific discrepancy found |
| Echoing Toxin (`talent.assassin.echoing_toxin`) | 3 | 5 | Retain - no specific discrepancy found |
| Poison Strike (`talent.assassin.poison_strike`) | 1 | 5 | Retain - no specific discrepancy found |
| Bypass (`talent.assassin.bypass`) | 1 | 10 | Retain - no specific discrepancy found |
| Toxic Tradeoff (`talent.assassin.toxic_tradeoff`) | 5 | 10 | Improve - G04 terminology |
| Accelerant (`talent.assassin.accelerant`) | 5 | 15 | Retain - no specific discrepancy found |
| Resonance (`talent.assassin.resonance`) | 4 | 15 | Retain - no specific discrepancy found |
| Critical Poison (`talent.assassin.critical_poison`) | 1 | 20 | Retain - no specific discrepancy found |

Automatic unlocks: 1 -> skill.venom_jab, 3 -> skill.blinding_powder, 6 -> skill.virulent_poison, 9 -> skill.master_of_poisons, 12 -> skill.poison_vile.

## Shadow

| Talent / stable ID | Ranks | Gate | Text disposition |
| --- | ---: | ---: | --- |
| Coated Weapons (`talent.shadow.coated_weapons`) | 1 | 0 | Retain - no specific discrepancy found |
| Blind Spot (`talent.shadow.blind_spot`) | 5 | 0 | Retain - no specific discrepancy found |
| Snake Oil (`talent.shadow.snake_oil`) | 4 | 0 | Retain - no specific discrepancy found |
| Deception (`talent.shadow.deception`) | 5 | 5 | Improve - G04 terminology |
| Death from the Shadows (`talent.shadow.death_from_the_shadows`) | 5 | 5 | Retain - no specific discrepancy found |
| Death Touch (`talent.shadow.death_touch`) | 3 | 10 | Improve - G04 terminology |
| Death Pact (`talent.shadow.death_pact`) | 3 | 10 | Retain - no specific discrepancy found |
| Shadow Mastery (`talent.shadow.shadow_mastery`) | 5 | 15 | Retain - no specific discrepancy found |
| Dusk Strike (`talent.shadow.dusk_strike`) | 1 | 15 | Retain - no specific discrepancy found |
| Death Blade (`talent.shadow.death_blade`) | 2 | 15 | Retain - no specific discrepancy found |
| Umbral Presence (`talent.umbral_pressure`) | 1 | 20 | Retain - no specific discrepancy found |

Automatic unlocks: 1 -> skill.toxic_flurry, 3 -> skill.killers_mark, 6 -> skill.distilled_corruption, 9 -> skill.touch_of_darkness, 12 -> skill.beguiling_presence.

## Skills

| Skill / stable ID | Unlock source | Description disposition |
| --- | --- | --- |
| Hold (`skill.hold`) | class.rogue | Retain - conditional/build estimates require T5 matrix |
| Stab (`skill.stab`) | class.rogue | Retain - conditional/build estimates require T5 matrix |
| Heavy Slash (`skill.heavy_slash`) | class.rogue | Retain - conditional/build estimates require T5 matrix |
| Rending Slash (`skill.rending_thrust`) | talent.bladedancer.rending_slash | Retain - conditional/build estimates require T5 matrix |
| Quick Cut (`skill.quick_cut`) | tree.bladedancer:1 | Retain - conditional/build estimates require T5 matrix |
| Leaping Plunge (`skill.leaping_plunge`) | tree.bladedancer:3 | Retain - conditional/build estimates require T5 matrix |
| Parry Strike (`skill.parry_strike`) | tree.bladedancer:6 | Retain - conditional/build estimates require T5 matrix |
| Dance Of Death (`skill.dance_of_death`) | tree.bladedancer:12 | Retain - conditional/build estimates require T5 matrix |
| Steal (`skill.steal`) | tree.thief:1 | Retain - conditional/build estimates require T5 matrix |
| Mug (`skill.mug`) | tree.thief:3 | Improve - G02 |
| Pick Pocket (`skill.pick_pocket`) | tree.thief:6 | Improve - G03 |
| Big Score (`skill.big_score`) | tree.thief:12 | Improve - G05 |
| Poison Strike (`skill.poison_strike`) | talent.assassin.poison_strike | Retain - conditional/build estimates require T5 matrix |
| Venom Jab (`skill.venom_jab`) | tree.assassin:1 | Retain - conditional/build estimates require T5 matrix |
| Blinding Powder (`skill.blinding_powder`) | tree.assassin:3 | Retain - conditional/build estimates require T5 matrix |
| Virulent Poison (`skill.virulent_poison`) | tree.assassin:6 | Retain - conditional/build estimates require T5 matrix |
| Master Of Poisons (`skill.master_of_poisons`) | tree.assassin:9 | Retain - conditional/build estimates require T5 matrix |
| Poison Vile (`skill.poison_vile`) | tree.assassin:12 | Retain - conditional/build estimates require T5 matrix |
| Beguiling Strike (`skill.toxic_flurry`) | tree.shadow:1 | Retain - conditional/build estimates require T5 matrix |
| Death Strike (`skill.killers_mark`) | tree.shadow:3 | Improve - G01 |
| Distilled Corruption (`skill.distilled_corruption`) | tree.shadow:6 | Retain - conditional/build estimates require T5 matrix |
| Touch Of Darkness (`skill.touch_of_darkness`) | tree.shadow:9 | Retain - conditional/build estimates require T5 matrix |
| Beguiling Presence (`skill.beguiling_presence`) | tree.shadow:12 | Retain - conditional/build estimates require T5 matrix |

## All mapped assets

| Identity | Asset path | Disposition |
| --- | --- | --- |
| `defense.absorb` | `res://assets/ui/assigned/mechanics/absorb.png` | Retain; T4 actual-size acceptance |
| `defense.armor` | `res://assets/ui/assigned/mechanics/armor.png` | Retain; T4 actual-size acceptance |
| `defense.block` | `res://assets/ui/assigned/mechanics/block.png` | Retain; T4 actual-size acceptance |
| `defense.cleanse` | `res://assets/ui/assigned/mechanics/cleanse.png` | Retain; T4 actual-size acceptance |
| `defense.crit_negation` | `res://assets/ui/assigned/mechanics/critical_negation.png` | Retain; T4 actual-size acceptance |
| `defense.dodge` | `res://assets/ui/assigned/mechanics/dodge.png` | Retain; T4 actual-size acceptance |
| `defense.interrupt` | `res://assets/ui/assigned/mechanics/interrupt.png` | Retain; T4 actual-size acceptance |
| `defense.resistance` | `res://assets/ui/assigned/mechanics/resistance.png` | Retain; T4 actual-size acceptance |
| `defense.slow` | `res://assets/ui/assigned/mechanics/slow.png` | Retain; T4 actual-size acceptance |
| `defense.stun` | `res://assets/ui/assigned/mechanics/stun.png` | Retain; T4 actual-size acceptance |
| `defense.suppress` | `res://assets/ui/assigned/mechanics/suppress.png` | Retain; T4 actual-size acceptance |
| `skill.blinding_powder` | `res://assets/ui/assigned/skills/blinding_powder.png` | Retain; T4 actual-size acceptance |
| `skill.master_of_poisons` | `res://assets/ui/assigned/skills/master_of_poisons.png` | Retain; T4 actual-size acceptance |
| `skill.poison_strike` | `res://assets/ui/assigned/skills/poison_strike.png` | Retain; T4 actual-size acceptance |
| `skill.poison_vile` | `res://assets/ui/assigned/skills/poison_vile.png` | Retain; T4 actual-size acceptance |
| `skill.venom_jab` | `res://assets/ui/assigned/skills/venom_jab.png` | Retain; T4 actual-size acceptance |
| `skill.virulent_poison` | `res://assets/ui/assigned/skills/virulent_poison.png` | Retain; T4 actual-size acceptance |
| `skill.dance_of_death` | `res://assets/ui/assigned/skills/dance_of_death.png` | Retain; T4 actual-size acceptance |
| `skill.leaping_plunge` | `res://assets/ui/assigned/skills/leaping_plunge.png` | Retain; T4 actual-size acceptance |
| `skill.parry_strike` | `res://assets/ui/assigned/skills/parry_strike.png` | Retain; T4 actual-size acceptance |
| `skill.quick_cut` | `res://assets/ui/assigned/skills/quick_cut.png` | Retain; T4 actual-size acceptance |
| `skill.rending_thrust` | `res://assets/ui/assigned/skills/rending_slash.png` | Retain; T4 actual-size acceptance |
| `skill.heavy_slash` | `res://assets/ui/assigned/skills/heavy_slash.png` | Retain; T4 actual-size acceptance |
| `skill.hold` | `res://assets/ui/assigned/skills/hold.png` | Retain; T4 actual-size acceptance |
| `skill.stab` | `res://assets/ui/assigned/skills/stab.png` | Retain; T4 actual-size acceptance |
| `skill.beguiling_presence` | `res://assets/ui/assigned/skills/beguiling_presence.png` | Retain; T4 actual-size acceptance |
| `skill.toxic_flurry` | `res://assets/ui/assigned/skills/beguiling_strike.png` | Retain; T4 actual-size acceptance |
| `skill.killers_mark` | `res://assets/ui/assigned/skills/death_strike.png` | Retain; T4 actual-size acceptance |
| `skill.distilled_corruption` | `res://assets/ui/assigned/skills/distilled_corruption.png` | Retain; T4 actual-size acceptance |
| `skill.touch_of_darkness` | `res://assets/ui/assigned/skills/touch_of_darkness.png` | Retain; T4 actual-size acceptance |
| `skill.big_score` | `res://assets/ui/assigned/skills/big_score.png` | Retain; T4 actual-size acceptance |
| `skill.mug` | `res://assets/ui/assigned/skills/mug.png` | Retain; T4 actual-size acceptance |
| `skill.pick_pocket` | `res://assets/ui/assigned/skills/pick_pocket.png` | Retain; T4 actual-size acceptance |
| `skill.steal` | `res://assets/ui/assigned/skills/steal.png` | Retain; T4 actual-size acceptance |
| `talent.assassin.accelerant` | `res://assets/ui/assigned/talents/assassin/accelerant.png` | Retain; T4 actual-size acceptance |
| `talent.assassin.bypass` | `res://assets/ui/assigned/talents/assassin/bypass.png` | Retain; T4 actual-size acceptance |
| `talent.assassin.critical_poison` | `res://assets/ui/assigned/talents/assassin/critical_poison.png` | Retain; T4 actual-size acceptance |
| `talent.assassin.echoing_toxin` | `res://assets/ui/assigned/talents/assassin/echoing_toxin.png` | Retain; T4 actual-size acceptance |
| `talent.assassin.hastened_poison` | `res://assets/ui/assigned/talents/assassin/hastened_poison.png` | Retain; T4 actual-size acceptance |
| `talent.assassin.poison_strike` | `res://assets/ui/assigned/talents/assassin/poison_strike.png` | Retain; T4 actual-size acceptance |
| `talent.assassin.precision` | `res://assets/ui/assigned/talents/assassin/precision.png` | Retain; T4 actual-size acceptance |
| `talent.assassin.quick_hands` | `res://assets/ui/assigned/talents/assassin/quick_hands.png` | Retain; T4 actual-size acceptance |
| `talent.assassin.resonance` | `res://assets/ui/assigned/talents/assassin/resonance.png` | Retain; T4 actual-size acceptance |
| `talent.assassin.toxic_tradeoff` | `res://assets/ui/assigned/talents/assassin/toxic_tradeoff.png` | Improve - G09 readability review |
| `talent.bladedancer.cloak_and_dagger` | `res://assets/ui/assigned/talents/bladedancer/cloak_dagger.png` | Retain; T4 actual-size acceptance |
| `talent.bladedancer.double_dip` | `res://assets/ui/assigned/talents/bladedancer/double_dip.png` | Retain; T4 actual-size acceptance |
| `talent.bladedancer.fancy_footwork` | `res://assets/ui/assigned/talents/bladedancer/fancy_footwork.png` | Retain; T4 actual-size acceptance |
| `talent.bladedancer.opportunity` | `res://assets/ui/assigned/talents/bladedancer/opportunity.png` | Retain; T4 actual-size acceptance |
| `talent.bladedancer.precision_attacks` | `res://assets/ui/assigned/talents/bladedancer/precision_attacks.png` | Retain; T4 actual-size acceptance |
| `talent.bladedancer.rending_slash` | `res://assets/ui/assigned/talents/bladedancer/rending_slash.png` | Retain; T4 actual-size acceptance |
| `talent.bladedancer.riposte` | `res://assets/ui/assigned/talents/bladedancer/riposte.png` | Retain; T4 actual-size acceptance |
| `talent.bladedancer.sharpened_edge` | `res://assets/ui/assigned/talents/bladedancer/sharpened_edge.png` | Improve - G09 readability review |
| `talent.bladedancer.side_step` | `res://assets/ui/assigned/talents/bladedancer/side_step.png` | Retain; T4 actual-size acceptance |
| `talent.bladedancer.virulent_corruption` | `res://assets/ui/assigned/talents/bladedancer/virulent_corruption.png` | Retain; T4 actual-size acceptance |
| `talent.bladedancer.weakness` | `res://assets/ui/assigned/talents/bladedancer/weakness.png` | Retain; T4 actual-size acceptance |
| `talent.bladedancer.weapon_master` | `res://assets/ui/assigned/talents/bladedancer/weapon_master.png` | Retain; T4 actual-size acceptance |
| `talent.bladedancer.wet_stone` | `res://assets/ui/assigned/talents/bladedancer/whetstone.png` | Retain; T4 actual-size acceptance |
| `talent.shadow.blind_spot` | `res://assets/ui/assigned/talents/shadow/blind_spot.png` | Retain; T4 actual-size acceptance |
| `talent.shadow.coated_weapons` | `res://assets/ui/assigned/talents/shadow/coated_weapons.png` | Retain; T4 actual-size acceptance |
| `talent.shadow.death_blade` | `res://assets/ui/assigned/talents/shadow/death_blade.png` | Retain; T4 actual-size acceptance |
| `talent.shadow.death_from_the_shadows` | `res://assets/ui/assigned/talents/shadow/death_from_the_shadows.png` | Retain; T4 actual-size acceptance |
| `talent.shadow.death_pact` | `res://assets/ui/assigned/talents/shadow/death_pact.png` | Retain; T4 actual-size acceptance |
| `talent.shadow.death_touch` | `res://assets/ui/assigned/talents/shadow/death_touch.png` | Retain; T4 actual-size acceptance |
| `talent.shadow.deception` | `res://assets/ui/assigned/talents/shadow/deception.png` | Retain; T4 actual-size acceptance |
| `talent.shadow.dusk_strike` | `res://assets/ui/assigned/talents/shadow/dusk_strike.png` | Improve - G09 readability review |
| `talent.shadow.shadow_mastery` | `res://assets/ui/assigned/talents/shadow/shadow_mastery.png` | Improve - G09 readability review |
| `talent.shadow.snake_oil` | `res://assets/ui/assigned/talents/shadow/snake_oil.png` | Retain; T4 actual-size acceptance |
| `talent.umbral_pressure` | `res://assets/ui/assigned/talents/shadow/umbral_presence.png` | Retain; T4 actual-size acceptance |
| `talent.thief.bribery` | `res://assets/ui/assigned/talents/thief/bribery.png` | Retain; T4 actual-size acceptance |
| `talent.thief.charisma` | `res://assets/ui/assigned/talents/thief/charisma.png` | Retain; T4 actual-size acceptance |
| `talent.thief.fast_hands` | `res://assets/ui/assigned/talents/thief/fast_hands.png` | Retain; T4 actual-size acceptance |
| `talent.thief.fill_your_pockets` | `res://assets/ui/assigned/talents/thief/fill_your_pockets.png` | Retain; T4 actual-size acceptance |
| `talent.thief.finders_keepers` | `res://assets/ui/assigned/talents/thief/finders_keepers.png` | Retain; T4 actual-size acceptance |
| `talent.gilded_blade` | `res://assets/ui/assigned/talents/thief/gilded_blade.png` | Retain; T4 actual-size acceptance |
| `talent.keen_eye` | `res://assets/ui/assigned/talents/thief/keen_eye.png` | Retain; T4 actual-size acceptance |
| `talent.thief.load_dice` | `res://assets/ui/assigned/talents/thief/load_dice.png` | Retain; T4 actual-size acceptance |
| `talent.thief.silvered_edge` | `res://assets/ui/assigned/talents/thief/silvered_edge.png` | Retain; T4 actual-size acceptance |
| `talent.sticky_fingers` | `res://assets/ui/assigned/talents/thief/sticky_fingers.png` | Retain; T4 actual-size acceptance |
| `status.decay` | `res://assets/ui/assigned/statuses/decay.png` | Retain; T4 actual-size acceptance |
| `status.penetration` | `res://assets/ui/assigned/statuses/penetration.png` | Retain; T4 actual-size acceptance |
| `status.poison` | `res://assets/ui/assigned/statuses/poison.png` | Retain; T4 actual-size acceptance |
| `status.potency` | `res://assets/ui/assigned/statuses/potency.png` | Improve - G09 readability review |
| `status.shred` | `res://assets/ui/assigned/statuses/shred.png` | Retain; T4 actual-size acceptance |
| `buff.footwork` | `res://assets/ui/assigned/talents/bladedancer/fancy_footwork.png` | Retain; T4 actual-size acceptance |
| `buff.readiness` | `res://assets/ui/assigned/skills/parry_strike.png` | Retain; T4 actual-size acceptance |
| `buff.precision` | `res://assets/ui/assigned/talents/bladedancer/precision_attacks.png` | Retain; T4 actual-size acceptance |
| `buff.dance` | `res://assets/ui/assigned/skills/dance_of_death.png` | Retain; T4 actual-size acceptance |
| `buff.bypass` | `res://assets/ui/assigned/talents/assassin/bypass.png` | Retain; T4 actual-size acceptance |
| `buff.virulent_poison` | `res://assets/ui/assigned/skills/virulent_poison.png` | Retain; T4 actual-size acceptance |
| `buff.master_of_poisons` | `res://assets/ui/assigned/skills/master_of_poisons.png` | Retain; T4 actual-size acceptance |
| `buff.touch_of_darkness` | `res://assets/ui/assigned/skills/touch_of_darkness.png` | Retain; T4 actual-size acceptance |
| `buff.beguiling_presence` | `res://assets/ui/assigned/skills/beguiling_presence.png` | Retain; T4 actual-size acceptance |
| `buff.greed` | `res://assets/ui/assigned/buffs/greed.png` | Retain; T4 actual-size acceptance |
