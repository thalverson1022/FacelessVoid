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
		"res://data/gear/serpents_scales.tres",
		"res://data/gear/golden_greeves.tres",
		"res://data/gear/arctic_mittens.tres",
		"res://data/gear/hands_of_the_lightning_lord.tres",
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
			return "Stab and Heavy Slash gain 50% Retrigger Chance"
		"gear.legendary.bandit_blade":
			return "+1 Base Physical Damage (max +100) per 10g in stash"
		"gear.legendary.wyvern_kriss":
			return "Poison ticks twice as fast"
		"gear.legendary.umbral_stiletto":
			return "Grants: Death Strike\nDeath Strike gains +1 Base Damage per stack of Decay"
		"gear.legendary.bejeweled_push_dagger":
			return "Skills have a 40% chance to trigger instantly"
		"gear.legendary.decrepit_blade":
			return "Grants: Poison Strike\nOn hit Poison Strike consumes all Poison stacks dealing a single burst"
		"gear.legendary.nightkiss_kitana":
			return "Grants: Exsanguinate\nConsume all Shred to remove 1x the Armor Shred value in health."
		"gear.legendary.crown_of_concertation":
			return "Doubles the effects of self buffs"
		"gear.legendary.helm_of_the_samurai":
			return "Retriggers grant Meditation\nMeditation stacks up to 5 times and lasts for 3 sec. Each stack of Meditation grants x20% Increase to all Damage"
		"gear.legendary.cloak_of_speed":
			return "Grants: Quick Cut\nRetriggers have a 30% chance to trigger Quick Cut"
		"gear.legendary.deaths_door":
			return "Gain x100% damage per missing fight attempt"
		"gear.legendary.signet_of_the_old_kings":
			return "You can no longer crit\nCrit Chance is converted to 1.5x Increased Attack Speed\nCrit Damage is converted to 1.5x Increased Physical Damage"
		"gear.legendary.lolzorzs_locket":
			return "Critical hits have a 20% chance to reduce all cooldowns by 1 sec."
		"gear.legendary.serpents_coil":
			return "Poison can now Retrigger"
		"gear.legendary.wingjammer":
			return "Critical hits have a 30% chance to grant Dash\nDash stacks up to 20 times and lasts for 3 sec. Each stack of Dash grants +5% Increased Attack Speed"
		"gear.legendary.mysterious_lucky_coin":
			return "Grants x100% Magic Find"
		"gear.legendary.serpents_scales":
			return "Poison ticks have a 20% chance to not consume Poison stacks"
		"gear.legendary.golden_greeves":
			return "Overkill gold is doubled"
		"gear.legendary.arctic_mittens":
			return "Encounter countdown runs 25% slower"
		"gear.legendary.hands_of_the_lightning_lord":
			return "Critical hits have a 20% chance to Retrigger"
	return ""


## Expanded signature context belongs in Character Stats detail, keeping
## inventory and shop cards concise.
static func effect_detail_text(item: GearItem) -> String:
	match item.legendary_effect_id:
		"serpents_scales":
			return "One preservation chance covers the entire Poison cost, including Poison Strike's all-stack Consume. Preserved damage keeps its full fuel; zero stacks consumed grants no Consume reward. Free Poison repeats inherit fuel and do not roll preservation."
		"golden_greeves":
			return "Only equipped Greeves doubles the capped Overkill component. Base encounter gold is unchanged; Increased Gold applies afterward."
		"arctic_mittens":
			return "A nominal 20s countdown allows 26.667s of combat. Casts, cooldowns, buffs and Poison keep normal timing. Actual elapsed combat duration is used for DPS; equipment changes cannot retime a recorded fight."
		"hands_of_the_lightning_lord":
			return "Ordinary and Lightning Retrigger opportunities are independent; both may succeed. One critical Attack operation or fueled critical Poison activation gets one Lightning chance, including repeats. Poison repeats require Serpent's Coil. Lightning Lord does not enable Poison retriggers or add numeric Retrigger Chance; its critical-hit trial is separate."
	return ""


## Fixed authored rolls use concise player vocabulary.
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
		"increased_magic_find": "Increased Magic Find",
		"shop_discount": "Shop Discount",
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


## Player-facing item types are independent of loot families and authored IDs.
static func item_type_text(item: GearItem) -> String:
	if item == null:
		return ""
	match item.slot:
		GearItem.SlotType.WEAPON: return "Dagger"
		GearItem.SlotType.CHARM: return "Necklace"
		GearItem.SlotType.TRINKET: return "Ring"
	return GearGenerator.item_family_for(item)


static func header_text(item: GearItem) -> String:
	if item == null:
		return ""
	return "%s %s / %s" % [
		GearGenerator.tier_name(item.tier),
		GearGenerator.universal_slot_label(item.slot),
		item_type_text(item),
	]


static func tooltip_lines(item: GearItem) -> PackedStringArray:
	var lines: PackedStringArray = []
	if item == null:
		return lines
	lines.append(item.display_name)
	lines.append(header_text(item))
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
		lines.append("Legendary Effect:")
		lines.append(text)
	return lines
