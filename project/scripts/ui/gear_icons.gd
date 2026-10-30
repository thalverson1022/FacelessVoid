class_name GearIcons
extends RefCounted
## Maps a GearItem to its icon texture for display in the shop, inventory,
## and equipment slots. Named items (the 20 Rogue Legendaries, Lucky Coin) get
## their own hand-authored icon; generated Rogue gear resolves by slot+tier;
## unexpected future gear falls back to a generic rarity icon. All are
## transparent-background PNGs meant to sit on top of the existing tier-colored
## slot background, not replace it.

const BANDIT_BLADE_ICON := preload("res://assets/Items/Rogue/Bandit_Blade.png")
const BEJEWELED_PUSH_DAGGER_ICON := preload("res://assets/Items/Rogue/Bejeweled_Push_Dagger.png")
const MITHRIL_KARAMBIT_ICON := preload("res://assets/Items/Rogue/Mithril_Karambit.png")
const UMBRAL_STILETTO_ICON := preload("res://assets/Items/Rogue/Umbral_Stiletto.png")
const WYVERN_KRISS_ICON := preload("res://assets/Items/Rogue/Wyvern_Kriss.png")
const LUCKY_COIN_ICON := preload("res://assets/Items/Rogue/Lucky_Coin.png")

const CRUDE_DAGGER_ICON := preload("res://assets/Items/Rogue/Generated/rogue_dagger_crude.png")
const BASIC_DAGGER_ICON := preload("res://assets/Items/Rogue/Generated/rogue_dagger_basic.png")
const MASTER_DAGGER_ICON := preload("res://assets/Items/Rogue/Generated/rogue_dagger_master.png")
const EPIC_DAGGER_ICON := preload("res://assets/Items/Rogue/Generated/rogue_dagger_epic.png")
const CURSED_DAGGER_ICON := preload("res://assets/Items/Rogue/Generated/rogue_dagger_cursed.png")
const CHAOS_DAGGER_ICON := preload("res://assets/Items/Rogue/Generated/rogue_dagger_chaos.png")
const UNIQUE_DAGGER_ICON := preload("res://assets/Items/Rogue/Generated/rogue_dagger_unique.png")

const BASIC_HOOD_ICON := preload("res://assets/Items/Rogue/Generated/rogue_hood_basic.png")
const MASTER_HOOD_ICON := preload("res://assets/Items/Rogue/Generated/rogue_hood_master.png")
const EPIC_HOOD_ICON := preload("res://assets/Items/Rogue/Generated/rogue_hood_epic.png")
const CURSED_HOOD_ICON := preload("res://assets/Items/Rogue/Generated/rogue_hood_cursed.png")
const CHAOS_HOOD_ICON := preload("res://assets/Items/Rogue/Generated/rogue_hood_chaos.png")
const UNIQUE_HOOD_ICON := preload("res://assets/Items/Rogue/Generated/rogue_hood_unique.png")

const BASIC_DOUBLET_ICON := preload("res://assets/Items/Rogue/Generated/rogue_doublet_basic.png")
const MASTER_DOUBLET_ICON := preload("res://assets/Items/Rogue/Generated/rogue_doublet_master.png")
const EPIC_DOUBLET_ICON := preload("res://assets/Items/Rogue/Generated/rogue_doublet_epic.png")
const CURSED_DOUBLET_ICON := preload("res://assets/Items/Rogue/Generated/rogue_doublet_cursed.png")
const CHAOS_DOUBLET_ICON := preload("res://assets/Items/Rogue/Generated/rogue_doublet_chaos.png")
const UNIQUE_DOUBLET_ICON := preload("res://assets/Items/Rogue/Generated/rogue_doublet_unique.png")

const BASIC_RING_ICON := preload("res://assets/Items/Rogue/Generated/rogue_ring_basic.png")
const MASTER_RING_ICON := preload("res://assets/Items/Rogue/Generated/rogue_ring_master.png")
const EPIC_RING_ICON := preload("res://assets/Items/Rogue/Generated/rogue_ring_epic.png")
const CURSED_RING_ICON := preload("res://assets/Items/Rogue/Generated/rogue_ring_cursed.png")
const CHAOS_RING_ICON := preload("res://assets/Items/Rogue/Generated/rogue_ring_chaos.png")
const UNIQUE_RING_ICON := preload("res://assets/Items/Rogue/Generated/rogue_ring_unique.png")

const BASIC_NECKLACE_ICON := preload("res://assets/Items/Rogue/Generated/rogue_necklace_basic.png")
const MASTER_NECKLACE_ICON := preload("res://assets/Items/Rogue/Generated/rogue_necklace_master.png")
const EPIC_NECKLACE_ICON := preload("res://assets/Items/Rogue/Generated/rogue_necklace_epic.png")
const CURSED_NECKLACE_ICON := preload("res://assets/Items/Rogue/Generated/rogue_necklace_cursed.png")
const CHAOS_NECKLACE_ICON := preload("res://assets/Items/Rogue/Generated/rogue_necklace_chaos.png")
const UNIQUE_NECKLACE_ICON := preload("res://assets/Items/Rogue/Generated/rogue_necklace_unique.png")

const BASIC_WEAPON_ICON := preload("res://assets/Items/Rogue/Generated/rogue_dagger_basic.png")
const MASTER_WEAPON_ICON := preload("res://assets/Items/Rogue/Generated/rogue_dagger_master.png")
const CURSED_WEAPON_ICON := preload("res://assets/Items/Rogue/Generated/rogue_dagger_cursed.png")
const BASIC_TRINKET_ICON := preload("res://assets/Items/Rogue/Generated/rogue_ring_basic.png")
const MASTER_TRINKET_ICON := preload("res://assets/Items/Rogue/Generated/rogue_ring_master.png")
const CURSED_TRINKET_ICON := preload("res://assets/Items/Rogue/Generated/rogue_ring_cursed.png")
const BASIC_CHARM_ICON := preload("res://assets/Items/Rogue/Generated/rogue_necklace_basic.png")
const MASTER_CHARM_ICON := preload("res://assets/Items/Rogue/Generated/rogue_necklace_master.png")
const CURSED_CHARM_ICON := preload("res://assets/Items/Rogue/Generated/rogue_necklace_cursed.png")
const CRUDE_GEAR_ICON := preload("res://assets/ui/icons/gear_drop_helm_basic.png")
const BASIC_GEAR_ICON := preload("res://assets/ui/icons/gear_drop_helm_basic.png")
const MASTER_GEAR_ICON := preload("res://assets/ui/icons/gear_drop_helm_master.png")
const EPIC_GEAR_ICON := preload("res://assets/ui/icons/gear_drop_helm_master.png")
const CURSED_GEAR_ICON := preload("res://assets/ui/icons/gear_drop_helm_cursed.png")
const CHAOS_GEAR_ICON := preload("res://assets/ui/icons/gear_drop_helm_cursed.png")
const UNIQUE_GEAR_ICON := preload("res://assets/ui/icons/gear_drop_helm_legendary.png")
const LEGENDARY_GEAR_ICON := preload("res://assets/ui/icons/gear_drop_helm_legendary.png")
const SLOT_WEAPON_BACKGROUND := preload("res://assets/ui/equipment_slots/slot_weapon.png")
const SLOT_HELM_BACKGROUND := preload("res://assets/ui/equipment_slots/slot_helm.png")
const SLOT_ARMOR_BACKGROUND := preload("res://assets/ui/equipment_slots/slot_armor.png")
const SLOT_TRINKET_BACKGROUND := preload("res://assets/ui/equipment_slots/slot_trinket.png")
const SLOT_CHARM_BACKGROUND := preload("res://assets/ui/equipment_slots/slot_charm.png")
const SLOT_LEGS_BACKGROUND := preload("res://assets/ui/equipment_slots/slot_legs.png")
const SLOT_HANDS_BACKGROUND := preload("res://assets/ui/equipment_slots/slot_hands.png")
const SLOT_EMPTY_BACKGROUND := preload("res://assets/ui/equipment_slots/slot_empty.png")

## Keyed by GearItem.id -- only items with real, hand-authored art. Procedurally
## generated gear never matches one of these (its id is generated per-roll),
## so it falls through to the Rogue slot-and-rarity map below.
const NAMED_ICONS := {
	"gear.legendary.decrepit_blade": preload("res://assets/ui/assigned_flat/gear/decrepit_blade.png"),
	"gear.legendary.nightkiss_kitana": preload("res://assets/ui/assigned_flat/gear/nightkiss_kitana.png"),
	"gear.legendary.crown_of_concertation": preload("res://assets/ui/assigned_flat/gear/crown_of_concertation.png"),
	"gear.legendary.helm_of_the_samurai": preload("res://assets/ui/assigned_flat/gear/helm_of_the_samurai.png"),
	"gear.legendary.cloak_of_speed": preload("res://assets/ui/assigned_flat/gear/cloak_of_speed.png"),
	"gear.legendary.deaths_door": preload("res://assets/ui/assigned_flat/gear/deaths_door.png"),
	"gear.legendary.signet_of_the_old_kings": preload("res://assets/ui/assigned_flat/gear/signet_of_the_old_kings.png"),
	"gear.legendary.lolzorzs_locket": preload("res://assets/ui/assigned_flat/gear/lolzorzs_locket.png"),
	"gear.legendary.serpents_coil": preload("res://assets/ui/assigned_flat/gear/serpents_coil.png"),
	"gear.legendary.wingjammer": preload("res://assets/ui/assigned_flat/gear/wingjammer.png"),
	"gear.legendary.mysterious_lucky_coin": preload("res://assets/ui/assigned_flat/gear/mysterious_lucky_coin.png"),
	"gear.legendary.bandit_blade": BANDIT_BLADE_ICON,
	"gear.legendary.bejeweled_push_dagger": BEJEWELED_PUSH_DAGGER_ICON,
	"gear.legendary.mithril_karambit": MITHRIL_KARAMBIT_ICON,
	"gear.legendary.umbral_stiletto": UMBRAL_STILETTO_ICON,
	"gear.legendary.wyvern_kriss": WYVERN_KRISS_ICON,
	"gear.lucky_coin": LUCKY_COIN_ICON,
	"gear.legendary.serpents_scales": preload("res://assets/ui/assigned_flat/gear/serpents_scales.png"),
	"gear.legendary.golden_greeves": preload("res://assets/ui/assigned_flat/gear/golden_greeves.png"),
	"gear.legendary.arctic_mittens": preload("res://assets/ui/assigned_flat/gear/arctic_mittens.png"),
	"gear.legendary.hands_of_the_lightning_lord": preload("res://assets/ui/assigned_flat/gear/hands_of_the_lightning_lord.png"),
}

## [slot][tier] -> icon, for Rogue generated/custom item families without
## named art above. No Legendary entries here -- every retained Rogue
## Legendary is a named item.
const ROGUE_GENERATED_ICONS := {
	GearItem.SlotType.LEGS: {
		GearItem.Tier.BASIC: preload("res://assets/Items/Rogue/Generated/rogue_pants_basic.png"),
		GearItem.Tier.MASTER: preload("res://assets/Items/Rogue/Generated/rogue_pants_master.png"),
		GearItem.Tier.EPIC: preload("res://assets/Items/Rogue/Generated/rogue_pants_epic.png"),
		GearItem.Tier.CURSED: preload("res://assets/Items/Rogue/Generated/rogue_pants_cursed.png"),
		GearItem.Tier.CHAOS: preload("res://assets/Items/Rogue/Generated/rogue_pants_chaos.png"),
		GearItem.Tier.UNIQUE: preload("res://assets/Items/Rogue/Generated/rogue_pants_unique.png"),
	},
	GearItem.SlotType.HANDS: {
		GearItem.Tier.BASIC: preload("res://assets/Items/Rogue/Generated/rogue_gloves_basic.png"),
		GearItem.Tier.MASTER: preload("res://assets/Items/Rogue/Generated/rogue_gloves_master.png"),
		GearItem.Tier.EPIC: preload("res://assets/Items/Rogue/Generated/rogue_gloves_epic.png"),
		GearItem.Tier.CURSED: preload("res://assets/Items/Rogue/Generated/rogue_gloves_cursed.png"),
		GearItem.Tier.CHAOS: preload("res://assets/Items/Rogue/Generated/rogue_gloves_chaos.png"),
		GearItem.Tier.UNIQUE: preload("res://assets/Items/Rogue/Generated/rogue_gloves_unique.png"),
	},
	GearItem.SlotType.WEAPON: {
		GearItem.Tier.CRUDE: CRUDE_DAGGER_ICON,
		GearItem.Tier.BASIC: BASIC_WEAPON_ICON,
		GearItem.Tier.MASTER: MASTER_WEAPON_ICON,
		GearItem.Tier.EPIC: EPIC_DAGGER_ICON,
		GearItem.Tier.CURSED: CURSED_WEAPON_ICON,
		GearItem.Tier.CHAOS: CHAOS_DAGGER_ICON,
		GearItem.Tier.UNIQUE: UNIQUE_DAGGER_ICON,
	},
	GearItem.SlotType.HELM: {
		GearItem.Tier.BASIC: BASIC_HOOD_ICON,
		GearItem.Tier.MASTER: MASTER_HOOD_ICON,
		GearItem.Tier.EPIC: EPIC_HOOD_ICON,
		GearItem.Tier.CURSED: CURSED_HOOD_ICON,
		GearItem.Tier.CHAOS: CHAOS_HOOD_ICON,
		GearItem.Tier.UNIQUE: UNIQUE_HOOD_ICON,
	},
	GearItem.SlotType.ARMOR: {
		GearItem.Tier.BASIC: BASIC_DOUBLET_ICON,
		GearItem.Tier.MASTER: MASTER_DOUBLET_ICON,
		GearItem.Tier.EPIC: EPIC_DOUBLET_ICON,
		GearItem.Tier.CURSED: CURSED_DOUBLET_ICON,
		GearItem.Tier.CHAOS: CHAOS_DOUBLET_ICON,
		GearItem.Tier.UNIQUE: UNIQUE_DOUBLET_ICON,
	},
	GearItem.SlotType.TRINKET: {
		GearItem.Tier.BASIC: BASIC_TRINKET_ICON,
		GearItem.Tier.MASTER: MASTER_TRINKET_ICON,
		GearItem.Tier.EPIC: EPIC_RING_ICON,
		GearItem.Tier.CURSED: CURSED_TRINKET_ICON,
		GearItem.Tier.CHAOS: CHAOS_RING_ICON,
		GearItem.Tier.UNIQUE: UNIQUE_RING_ICON,
	},
	GearItem.SlotType.CHARM: {
		GearItem.Tier.BASIC: BASIC_CHARM_ICON,
		GearItem.Tier.MASTER: MASTER_CHARM_ICON,
		GearItem.Tier.EPIC: EPIC_NECKLACE_ICON,
		GearItem.Tier.CURSED: CURSED_CHARM_ICON,
		GearItem.Tier.CHAOS: CHAOS_NECKLACE_ICON,
		GearItem.Tier.UNIQUE: UNIQUE_NECKLACE_ICON,
	},
}

const FALLBACK_ICONS_BY_TIER := {
	GearItem.Tier.CRUDE: CRUDE_GEAR_ICON,
	GearItem.Tier.BASIC: BASIC_GEAR_ICON,
	GearItem.Tier.MASTER: MASTER_GEAR_ICON,
	GearItem.Tier.EPIC: EPIC_GEAR_ICON,
	GearItem.Tier.CURSED: CURSED_GEAR_ICON,
	GearItem.Tier.CHAOS: CHAOS_GEAR_ICON,
	GearItem.Tier.UNIQUE: UNIQUE_GEAR_ICON,
	GearItem.Tier.LEGENDARY: LEGENDARY_GEAR_ICON,
}


## Returns null only when neither a mapped Rogue icon nor a generic rarity
## fallback exists. Callers keep the plain tier-colored square in that case.
static func icon_for(gear: GearItem) -> Texture2D:
	if gear == null:
		return null
	if NAMED_ICONS.has(gear.id):
		return NAMED_ICONS[gear.id]
	if gear.class_family == GearItem.ClassFamily.ROGUE:
		var slot_icons: Dictionary = ROGUE_GENERATED_ICONS.get(gear.slot, {})
		if slot_icons.has(gear.tier):
			return slot_icons[gear.tier]
	return FALLBACK_ICONS_BY_TIER.get(gear.tier, null)


static func slot_background_for(gear_slot: int) -> Texture2D:
	match gear_slot:
		GearItem.SlotType.WEAPON:
			return SLOT_WEAPON_BACKGROUND
		GearItem.SlotType.HELM:
			return SLOT_HELM_BACKGROUND
		GearItem.SlotType.ARMOR:
			return SLOT_ARMOR_BACKGROUND
		GearItem.SlotType.TRINKET:
			return SLOT_TRINKET_BACKGROUND
		GearItem.SlotType.CHARM:
			return SLOT_CHARM_BACKGROUND
		GearItem.SlotType.LEGS:
			return SLOT_LEGS_BACKGROUND
		GearItem.SlotType.HANDS:
			return SLOT_HANDS_BACKGROUND
		_:
			return SLOT_EMPTY_BACKGROUND
