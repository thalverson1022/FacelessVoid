class_name LegendaryCatalog
extends RefCounted
## Approved fixed Legendary roster. Acquisition eligibility is run state policy.

const WeaponDamageCatalog := preload("res://scripts/systems/weapon_damage_catalog.gd")

static func all_paths() -> Array[String]:
	return [
		"res://data/gear/wyvern_kriss.tres",
		"res://data/gear/mithril_karambit.tres",
		"res://data/gear/bandit_blade.tres",
		"res://data/gear/umbral_stiletto.tres",
		"res://data/gear/bejeweled_push_dagger.tres",
		"res://data/gear/decrepit_blade.tres",
		"res://data/gear/nightkiss_kitana.tres",
		"res://data/gear/crown_of_concertation.tres",
		"res://data/gear/helm_of_the_samurai.tres",
		"res://data/gear/cloak_of_speed.tres",
		"res://data/gear/deaths_door.tres",
		"res://data/gear/signet_of_the_old_kings.tres",
		"res://data/gear/lolzorzs_locket.tres",
		"res://data/gear/serpents_coil.tres",
		"res://data/gear/wingjammer.tres",
		"res://data/gear/mysterious_lucky_coin.tres",
	]


static func all_items() -> Array[GearItem]:
	var items: Array[GearItem] = []
	for path in all_paths():
		items.append(load(path))
	return items


static func effect_text(item: GearItem) -> String:
	if item == null:
		return ""
	match item.id:
		"gear.legendary.mithril_karambit":
			return "Stab and Heavy Slash gain +50 percentage points to their Retrigger roll (maximum 100%); does not increase the Retrigger Chance stat"
		"gear.legendary.bandit_blade":
			return "+1 Base Physical Damage per 10 current stash gold, up to +100; updates as gold changes"
		"gear.legendary.wyvern_kriss":
			return "Poison ticks twice as fast"
		"gear.legendary.umbral_stiletto":
			return "Grants Death Strike; it gains +1 Physical Damage per current Decay stack without consuming Decay"
		"gear.legendary.bejeweled_push_dagger":
			return "40% chance for a ready skill to use its minimum Cast Time; does not bypass cooldowns"
		"gear.legendary.decrepit_blade":
			return "Grants Poison Strike; keeps its attack and Consumes all Poison stacks, dealing their Poison damage in one burst"
		"gear.legendary.nightkiss_kitana":
			return "Grants Exsanguinate: Consume all Shred; remove twice its full Shred Value as health per stack. Bypasses mitigation; cannot crit or gain damage bonuses"
		"gear.legendary.crown_of_concertation":
			return "Double self-buff bonuses, including Dash: a x2 buff becomes x3. Duration, stack grants and caps are unchanged"
		"gear.legendary.helm_of_the_samurai":
			return "Skill and Poison Retriggers grant Meditation: x1.2 Physical Damage at 1 stack, x2 at the 5-stack cap. 3-second base duration; grants refresh all stacks"
		"gear.legendary.cloak_of_speed":
			return "Grants Quick Cut; retriggered attacks have a 30% chance to trigger Quick Cut, which can Retrigger and trigger it again"
		"gear.legendary.deaths_door":
			return "Damage (including Poison): x1/x2/x4/x6 at 0/1/2/3 missing encounter attempts. Opening unlimited-retry fight stays x1; excludes Exsanguinate"
		"gear.legendary.signet_of_the_old_kings":
			return "Cannot crit, including Poison. Convert uncapped Crit Chance at 2x to Attack Speed, and extra Crit Damage above a normal hit at 2x to Increased Physical Damage; includes buffs and gold bonuses"
		"gear.legendary.lolzorzs_locket":
			return "Critical hits have a 20% chance to reduce all cooldowns by 1 sec."
		"gear.legendary.serpents_coil":
			return "Poison can Retrigger; repeats consume no additional Poison, use current damage bonuses and can Retrigger again"
		"gear.legendary.wingjammer":
			return "Critical hits, including Poison, have a 30% chance to grant Dash: +5% Attack Speed per stack, up to 20. 3-second base duration; grants refresh all stacks"
		"gear.legendary.mysterious_lucky_coin":
			return "Double total Magic Find (150% becomes 300%). Destroy ordinary Lucky Coin to unlock this item for the current run; no immediate grant"
	return ""


## Fixed authored rolls use concise player vocabulary; exact source/timing math
## remains in the Character Stats detail view rather than every item card.
static func stat_text(affix: StatModifier) -> String:
	var catalog = preload("res://scripts/systems/stat_catalog.gd")
	var stat_id: String = catalog.canonical_id_for_modifier(affix)
	var labels := {
		"base_damage": "Base Physical Damage",
		"percent_physical_damage": "Increased Physical Damage",
		"base_elemental_damage": "Base Elemental Damage",
		"percent_elemental_damage": "Increased Elemental Damage",
		"increased_attack_speed": "Increased Attack Speed",
		"crit_chance": "Crit Chance", "crit_damage": "Crit Damage",
		"increased_gold": "Increased Gold",
		"increased_all_stacks": "All Stacks",
		"shred_value": "Armor Decrease per Shred Stack",
		"cooldown_reduction": "Cooldown Reduction",
		"increased_buff_duration": "Buff Duration",
		"crit_applies_penetration": "Crits Apply Penetration",
		"crit_applies_potency": "Crits Apply Potency",
		"crit_applies_element": "Crits Apply Poison",
		"chance_for_retrigger": "Retrigger Chance",
		"chance_to_shred": "Chance to Shred", "chance_to_decay": "Chance to Decay",
	}
	if not labels.has(stat_id): return StatModifierFormatter.format(affix)
	var percent: bool = catalog.value_kind_for(stat_id) in [catalog.VALUE_PERCENT, catalog.VALUE_CHANCE]
	var value := affix.value * (100.0 if percent else 1.0)
	return "%s%s%s %s" % ["+" if value >= 0.0 else "", number_text(value), "%" if percent else "", labels[stat_id]]


static func number_text(value: float) -> String:
	var text := String.num(value, 4)
	if text.contains("."):
		while text.ends_with("0"): text = text.trim_suffix("0")
		text = text.trim_suffix(".")
	return text


static func tooltip_lines(item: GearItem) -> PackedStringArray:
	var lines: PackedStringArray = []
	if item == null:
		return lines
	lines.append(item.display_name)
	lines.append("%s %s / %s" % [
		GearGenerator.tier_name(item.tier),
		GearGenerator.universal_slot_label(item.slot),
		GearGenerator.item_family_for(item),
	])
	if item.slot == GearItem.SlotType.WEAPON:
		var damage_range := WeaponDamageCatalog.damage_range_for_weapon(item)
		lines.append("Weapon Damage: %d-%d" % [int(damage_range["min"]), int(damage_range["max"])])
	var stat_lines: PackedStringArray = []
	for affix in item.affixes:
		if affix.stat == StatModifier.StatType.POISON_TICK_INTERVAL:
			continue
		stat_lines.append(stat_text(affix))
	if not stat_lines.is_empty():
		lines.append("Stats:")
		lines.append_array(stat_lines)
	var text := effect_text(item)
	if text != "":
		lines.append("Legendary:")
		lines.append(text)
	return lines
