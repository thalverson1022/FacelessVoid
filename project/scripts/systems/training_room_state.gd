class_name TrainingRoomState
extends RefCounted
## P2:R10 Practice Room's own build state -- deliberately NOT an autoload
## and never touching the real `BuildState` singleton, so a practice session
## can never read or mutate a real Adventure run. Mirrors the minimal slice
## of `BuildState`'s shape/behavior that the reused dashboard panels
## (`talent_panel.gd`, `available_skills_panel.gd`, `skill_build_panel.gd`,
## `character_stats_panel.gd`) actually need -- same signals, same method
## names/semantics -- so those panels can take either object interchangeably
## via their new `state` property (default `BuildState`).
##
## Talent points are granted in full immediately rather than earned --
## Practice Room is meant for freely testing a practice character, not
## replaying Adventure's earn-as-you-go pacing.

signal build_changed
signal lock_changed
signal fight_setup_changed
signal fight_finished
signal stats_preview_changed

const DEFAULT_DURATION_MS := 20000
const DEFAULT_FIGHT_SEED := 1
const DEFAULT_CONTRACT_LEVEL := 1
const DEFAULT_TARGET_ARMOR := 0
const DEFAULT_TARGET_POISON_RESIST := 0.0
const PRACTICE_TALENT_POINT_BUDGET := BuildProgression.POINT_CAP
const GENERATED_MONSTER_KIND := "normal"
const GENERATED_MONSTER_TEMPO := "standard"
const GENERATED_MONSTER_SEED_CONTEXT := "training_room_generated_monster"
const GENERATED_MONSTER_SEED_MAX := 2147483647
const StatCatalog := preload("res://scripts/systems/stat_catalog.gd")
const TARGET_DEFENSE_FIELDS := [
	"armor",
	"poison_resistance",
	"dodge_chance",
	"crit_negation",
	"block",
	"absorb",
	"cleanse_threshold",
	"suppress",
	"slow",
	"stun_duration_ms",
	"interrupt_skip_count",
]
const TARGET_PRESETS := [
	{
		"id": "blank",
		"name": "Blank",
		"defenses": {},
	},
	{
		"id": "armored",
		"name": "Armored",
		"defenses": {"armor": 80},
	},
	{
		"id": "fortified",
		"name": "Fortified",
		"defenses": {"armor": 100, "crit_negation": 0.5, "block": 3.0},
	},
	{
		"id": "warded",
		"name": "Warded",
		"defenses": {"poison_resistance": 0.25, "absorb": 5.0, "suppress": 0.25},
	},
	{
		"id": "nimble",
		"name": "Nimble",
		"defenses": {"dodge_chance": 0.12, "crit_negation": 0.55},
	},
	{
		"id": "hexed",
		"name": "Hexed",
		"defenses": {"cleanse_threshold": 5, "suppress": 0.35},
	},
	{
		"id": "devious",
		"name": "Devious",
		"defenses": {"cleanse_threshold": 5, "slow": 0.25, "stun_duration_ms": 300, "interrupt_skip_count": 1},
	},
]
## Practice Room only measures damage dealt in a fixed window -- it never
## shows win/loss -- but stun needs a hidden max-HP reference for its "large
## hit" threshold. Keep this low enough that ordinary Rogue burst can exercise
## stun in the harness without adding an HP control to the target card.
const PRACTICE_TARGET_HP := 100

var content_registry: BuildContentRegistry = null
var practice_save_path := ""
var allocation_locked := false
var ranked_build: RankedBuild = null
var last_build_error := ""
var rotation_changes: Dictionary = {"removed": [], "overflow": []}

var selected_class: ClassDef = null
var selected_trees: Array[SubclassTree] = []
var selected_talents: Array[Talent] = []
var earned_talent_points: int = PRACTICE_TALENT_POINT_BUDGET
var rotation: Array[Skill] = []
var build_locked: bool = false
var gold: int = 0
var configured_gold: int = 0
var combat_stolen_gold: int = 0
const MAX_CARRIED_ITEMS := 3
var carried_items: Array[GearItem] = []

var equipped_weapon: GearItem = null
var equipped_helm: GearItem = null
var equipped_armor: GearItem = null
var equipped_trinket: GearItem = null
var equipped_charm: GearItem = null

## P2:R10:T4 -- freeform, hand-editable practice gear, one per slot.
## Practice Room starts with no gear equipped; choosing a non-Legendary rarity
## equips the corresponding practice item, and choosing None unequips it.
## `equip_legendary()` points the weapon slot at a fixed catalog item instead
## (read-only in the UI), and `use_custom_weapon()` points it back to the
## editable practice weapon. Trinket/charm have no Legendary items today, so
## they are only controlled by the rarity dropdown.
var practice_weapon: GearItem
var practice_helm: GearItem
var practice_armor: GearItem
var practice_trinket: GearItem
var practice_charm: GearItem

## P2:R10:T5 -- freeform fight-setup, independent of any real Adventure
## encounter/seed. `fight_seed` is deliberately separate from
## `BuildState.adventure_seed` so a Practice Room result is reproducible on
## its own terms, per the P2:R10 scope decision.
var selected_target: Monster
var duration_ms: int = DEFAULT_DURATION_MS
var fight_seed: int = DEFAULT_FIGHT_SEED
var random_fight_seed_enabled := false
var generated_monster_draft: GeneratedMonsterDraft = null
var generated_monster_difficulty_id: int = 1
var generated_contract_level: int = DEFAULT_CONTRACT_LEVEL

## P2:R10:T6 -- the most recent practice fight's raw result, for the reused
## CombatResultFormatter/CombatRecap presentation to render. Never written
## anywhere but here -- unlike a real Adventure fight, running one in
## Practice Room never calls `BuildState.finish_fight()` or advances any
## encounter/route state.
var last_result: CombatResolver.CombatResult = null
var _generated_roll_index: int = 0


func _init() -> void:
	build_changed.connect(_clear_lock_on_change)
	practice_weapon = _make_practice_item(GearItem.SlotType.WEAPON, "Custom Weapon")
	practice_helm = _make_practice_item(GearItem.SlotType.HELM, "Custom Hood")
	practice_armor = _make_practice_item(GearItem.SlotType.ARMOR, "Custom Doublet")
	practice_trinket = _make_practice_item(GearItem.SlotType.TRINKET, "Custom Ring")
	practice_charm = _make_practice_item(GearItem.SlotType.CHARM, "Custom Necklace")
	# Not a seeded roster entry -- a plain in-memory Monster this state owns
	# and mutates directly for Practice Room defense checks, never a .tres.
	selected_target = Monster.new()
	selected_target.display_name = "Practice Target"
	selected_target.hp = PRACTICE_TARGET_HP
	selected_target.armor = DEFAULT_TARGET_ARMOR
	selected_target.poison_resistance = DEFAULT_TARGET_POISON_RESIST
	_reset_target_defenses()
	# Practice items begin as empty shells so entering Practice Room has no
	# equipped gear. The rarity-first invariant still applies once a player
	# picks a non-Legendary rarity: that choice equips the item and fills the
	# real GearGenerator-shaped affix count.


func _make_practice_item(slot: GearItem.SlotType, display_name: String) -> GearItem:
	var item := GearItem.new()
	item.id = "gear.training_room.practice_%s" % GearItem.SlotType.keys()[slot].to_lower()
	item.display_name = display_name
	item.slot = slot
	item.item_family = GearGenerator.rogue_item_family_for_slot(slot)
	item.class_family = GearItem.ClassFamily.ROGUE
	item.source_kind = GearItem.SourceKind.COMPATIBILITY
	return item


## Owned occurrences isolated from Adventure and inactive custom templates.
func add_carried_item(slot: GearItem.SlotType = GearItem.SlotType.WEAPON) -> GearItem:
	if carried_items.size() >= MAX_CARRIED_ITEMS or allocation_locked:
		return null
	var item := _make_practice_item(slot, "Carried %s" % GearGenerator.universal_slot_label(slot))
	carried_items.append(item)
	set_slot_rarity(item, GearItem.Tier.BASIC)
	return item


func remove_carried_item(index: int) -> bool:
	if index < 0 or index >= carried_items.size() or allocation_locked:
		return false
	carried_items.remove_at(index)
	build_changed.emit()
	return true


func set_carried_slot(item: GearItem, slot: GearItem.SlotType) -> bool:
	if not carried_items.has(item) or item.tier == GearItem.Tier.LEGENDARY or allocation_locked or not GearItem.SlotType.values().has(slot):
		return false
	item.slot = slot
	item.item_family = GearGenerator.rogue_item_family_for_slot(slot)
	item.display_name = "Carried %s" % GearGenerator.universal_slot_label(slot)
	item.affixes.clear()
	set_slot_rarity(item, item.tier)
	return true


func _clear_lock_on_change() -> void:
	if build_locked:
		build_locked = false
		lock_changed.emit()


func set_locked(locked: bool) -> void:
	if locked and rotation.is_empty():
		locked = false
	if build_locked == locked:
		return
	build_locked = locked
	lock_changed.emit()


func set_class(class_def: ClassDef) -> void:
	ranked_build = null
	selected_class = class_def
	selected_trees = []
	selected_talents = []
	rotation = []
	build_changed.emit()


## Two independent dropdown slots (Primary/Secondary) rather than
## `BuildState.select_tree()`'s "pick exactly one" Adventure semantics --
## Practice Room lets the player freely choose either of the 3 real trees
## into either slot. `selected_trees` stays a plain compact array (no null
## entries) so every existing reader (`unlocked_skills()`, `BuildResolver`,
## etc.) is untouched; slot identity is just "index 0 = primary, index 1 =
## secondary" by convention, resolved fresh from the current array each call.
func set_primary_tree(tree: SubclassTree) -> bool:
	return _set_tree_at_slot(0, tree)


func set_secondary_tree(tree: SubclassTree) -> bool:
	return _set_tree_at_slot(1, tree)

func swap_tree_roles() -> bool:
	if allocation_locked or ranked_build == null or ranked_build.secondary_tree() == null:
		last_build_error = "Select two supported trees outside playback to swap roles."
		return false
	return _finish_rank_edit(ranked_build.set_practice_trees(ranked_build.secondary_tree(), ranked_build.primary_tree()))


func tree_at_slot(slot_index: int) -> SubclassTree:
	return selected_trees[slot_index] if slot_index < selected_trees.size() else null


func _set_tree_at_slot(slot_index: int, tree: SubclassTree) -> bool:
	if allocation_locked:
		last_build_error = "Finish or skip combat playback before editing talents."
		return false
	if ranked_build == null and tree != null and tree.ranked_content_ready:
		if slot_index != 0:
			last_build_error = "Select a primary tree first."
			return false
		return configure_ranked_build(tree)
	if ranked_build != null:
		if tree != null:
			last_build_error = RankedBuild.content_error(tree)
			if last_build_error != "":
				return false
		var primary := tree if slot_index == 0 else ranked_build.primary_tree()
		var secondary := tree if slot_index == 1 else ranked_build.secondary_tree()
		if primary == null and slot_index == 1 and secondary != null:
			return false
		return _finish_rank_edit(ranked_build.set_practice_trees(primary, secondary))
	var current_at_slot := tree_at_slot(slot_index)
	if current_at_slot == tree:
		return true
	var trees := selected_trees.duplicate()
	if current_at_slot != null:
		trees.erase(current_at_slot)
	if tree != null:
		if trees.has(tree) or not PassiveAllocator.can_select_tree(trees, tree):
			return false
		trees.insert(mini(slot_index, trees.size()), tree)
	selected_trees = trees
	var remaining: Array[Talent] = []
	for talent in selected_talents:
		for kept_tree in selected_trees:
			if kept_tree.talents.has(talent):
				remaining.append(talent)
				break
	selected_talents = remaining
	_prune_rotation_to_unlocked()
	build_changed.emit()
	return true


func select_talent(talent: Talent) -> bool:
	if allocation_locked:
		last_build_error = "Finish or skip combat playback before editing talents."
		return false
	if ranked_build != null:
		return _finish_rank_edit(ranked_build.buy(talent.id)) if talent != null else false
	if not PassiveAllocator.can_select_talent(selected_trees, selected_talents, talent, earned_talent_points):
		return false
	selected_talents.append(talent)
	_prune_rotation_to_unlocked()
	build_changed.emit()
	return true


func deselect_talent(talent: Talent) -> bool:
	if allocation_locked:
		last_build_error = "Finish or skip combat playback before editing talents."
		return false
	if ranked_build != null:
		return _finish_rank_edit(ranked_build.refund(talent.id, true)) if talent != null else false
	if not PassiveAllocator.can_deselect_talent(selected_talents, talent):
		return false
	selected_talents.erase(talent)
	_prune_rotation_to_unlocked()
	build_changed.emit()
	return true


func set_rotation(skills: Array[Skill]) -> void:
	rotation_changes = BuildResolver.normalize_rotation(skills, unlocked_skills())
	rotation = rotation_changes["rotation"]
	build_changed.emit()


func unlocked_skills() -> Array[Skill]:
	if ranked_build != null:
		var skills: Array[Skill] = []
		skills.assign(BuildResolver.resolve_ranked_build(selected_class, ranked_build, equipped_gear(), gold, carried_items).get("skills", []))
		return skills
	return BuildResolver.resolve_unlocked_skills(selected_class, selected_trees, selected_talents, equipped_gear())


func can_run_fight() -> bool:
	return build_locked and not allocation_locked and not rotation.is_empty()


## Direct Legendary equip for Practice Room's Legendary-equip control
## bypasses reward/shop flow and routes fixed items to their authored slot.
func equip_legendary(item: GearItem) -> void:
	if item == null or item.tier != GearItem.Tier.LEGENDARY:
		return
	_equip_practice_item(item)
	_prune_rotation_to_unlocked()
	build_changed.emit()


## Switches the weapon slot back to the freeform practice item after a
## Legendary was equipped (P2:R10:T4's Custom/Legendary toggle).
func use_custom_weapon() -> void:
	equipped_weapon = practice_weapon
	_prune_rotation_to_unlocked()
	build_changed.emit()


## True while the weapon slot shows a fixed Legendary rather than the
## editable practice item -- the affix editor reads this to know whether to
## render itself as read-only.
func is_weapon_legendary() -> bool:
	return equipped_weapon != null and equipped_weapon != practice_weapon


## "None" rarity choice (user-requested) -- empties the slot entirely, no
## stats at all. Distinct from set_slot_rarity() since GearItem.Tier has no
## "no item" value to represent this; the UI reads an empty `affixes` array
## as "None" currently selected (see training_room.gd's _refresh_gear_slot()).
func clear_slot(item: GearItem) -> void:
	if item == null or item.tier == GearItem.Tier.LEGENDARY:
		return
	# The editor targets its custom slot even while fixed gear occupies it.
	_equip_practice_item(item)
	_unequip_practice_item(item)
	item.affixes.clear()
	_prune_rotation_to_unlocked()
	build_changed.emit()


## Rarity-first gear editor (replaces the earlier freeform add/remove-any-
## affix editor): picking a rarity for a practice item's slot fixes its real
## GearGenerator affix-slot shape rather than letting the player add/remove
## arbitrary numbers of affixes. `item` must be one of the practice paper-doll
## items -- never a Legendary (those are handled entirely by
## equip_legendary()/use_custom_weapon(), never passed here).
func set_slot_rarity(item: GearItem, tier: GearItem.Tier) -> void:
	if item == null or item.tier == GearItem.Tier.LEGENDARY:
		return
	if item.tier == GearItem.Tier.LEGENDARY: return
	_equip_practice_item(item)
	_prune_rotation_to_unlocked()
	item.tier = tier
	if tier == GearItem.Tier.CRUDE:
		item.affixes.clear()
		build_changed.emit()
		return
	var slots := _affix_slots_for_tier(tier)
	var target_count := slots.size()
	while item.affixes.size() > target_count:
		item.affixes.remove_at(item.affixes.size() - 1)
	while item.affixes.size() < target_count:
		var slot_index := item.affixes.size()
		var slot_spec: Dictionary = slots[slot_index]
		var pool := _pool_for_slot(item.slot, String(slot_spec.get("category", StatCatalog.CATEGORY_BASIC)), bool(slot_spec.get("is_drawback", false)))
		var used: Array = []
		for existing in item.affixes:
			used.append(StatCatalog.canonical_id_for_modifier(existing))
		var stat_id := _first_unused_stat_id(pool, used)
		var modifier := StatModifier.new()
		_apply_stat_to_modifier(modifier, stat_id, item.slot, tier, slot_index, slots)
		item.affixes.append(modifier)
	# Re-stamp every slot's operation/value to the current tier's real table
	# (a slot kept across a rarity change may otherwise carry a stale
	# magnitude from the tier it was created under).
	for i in item.affixes.size():
		var modifier: StatModifier = item.affixes[i]
		var stat_id := StatCatalog.canonical_id_for_modifier(modifier)
		var slot_spec: Dictionary = slots[i]
		var pool := _pool_for_slot(item.slot, String(slot_spec.get("category", StatCatalog.CATEGORY_BASIC)), bool(slot_spec.get("is_drawback", false)))
		if not pool.has(stat_id):
			stat_id = _first_unused_stat_id(pool, _used_stat_ids_except(item, i))
		_apply_stat_to_modifier(modifier, stat_id, item.slot, tier, i, slots)
	build_changed.emit()


func _equip_practice_item(item: GearItem) -> void:
	if carried_items.has(item):
		return
	match item.slot:
		GearItem.SlotType.WEAPON:
			equipped_weapon = item
		GearItem.SlotType.HELM:
			equipped_helm = item
		GearItem.SlotType.ARMOR:
			equipped_armor = item
		GearItem.SlotType.TRINKET:
			equipped_trinket = item
		GearItem.SlotType.CHARM:
			equipped_charm = item


func _unequip_practice_item(item: GearItem) -> void:
	match item.slot:
		GearItem.SlotType.WEAPON:
			if equipped_weapon == item:
				equipped_weapon = null
		GearItem.SlotType.HELM:
			if equipped_helm == item:
				equipped_helm = null
		GearItem.SlotType.ARMOR:
			if equipped_armor == item:
				equipped_armor = null
		GearItem.SlotType.TRINKET:
			if equipped_trinket == item:
				equipped_trinket = null
		GearItem.SlotType.CHARM:
			if equipped_charm == item:
				equipped_charm = null


## Re-picks one affix slot's stat (the player's dropdown choice) and
## auto-fills that stat's real tier value into the still-editable value
## field -- per the confirmed design, the value stays editable afterward,
## this just seeds a sensible real default instead of leaving it at
## whatever the previous stat's magnitude happened to be.
func set_affix_stat(item: GearItem, index: int, stat: Variant) -> void:
	if item.tier == GearItem.Tier.LEGENDARY: return
	if index < 0 or index >= item.affixes.size():
		return
	var slots := _affix_slots_for_tier(item.tier)
	if index >= slots.size():
		return
	var modifier: StatModifier = item.affixes[index]
	var stat_id := _canonical_stat_id_from_selection(stat)
	_apply_stat_to_modifier(modifier, stat_id, item.slot, item.tier, index, slots)
	build_changed.emit()


## Affix value edits mutate the `StatModifier` field directly -- GearItem/
## StatModifier are plain exported-field Resources with no encapsulation
## elsewhere in the codebase (see gear_generator.gd) -- then call this to
## trigger the same live-refresh every other build_changed-driven panel
## already uses.
func notify_gear_edited() -> void:
	build_changed.emit()


func _affix_slot_count(tier: GearItem.Tier) -> int:
	return _affix_slots_for_tier(tier).size()


func _affix_slots_for_tier(tier: GearItem.Tier) -> Array[Dictionary]:
	match tier:
		GearItem.Tier.BASIC:
			return [_roll_spec(StatCatalog.CATEGORY_BASIC)]
		GearItem.Tier.MASTER:
			return [_roll_spec(StatCatalog.CATEGORY_BASIC), _roll_spec(StatCatalog.CATEGORY_BASIC)]
		GearItem.Tier.EPIC:
			return [
				_roll_spec(StatCatalog.CATEGORY_BASIC),
				_roll_spec(StatCatalog.CATEGORY_BASIC),
				_roll_spec(StatCatalog.CATEGORY_RARE),
			]
		GearItem.Tier.CURSED:
			return [
				_roll_spec(StatCatalog.CATEGORY_BASIC),
				_roll_spec(StatCatalog.CATEGORY_BASIC),
				_roll_spec(StatCatalog.CATEGORY_RARE),
				_roll_spec(StatCatalog.CATEGORY_BASIC, true),
			]
		GearItem.Tier.CHAOS:
			return [
				_roll_spec(StatCatalog.CATEGORY_BASIC),
				_roll_spec(StatCatalog.CATEGORY_RARE),
				_roll_spec(StatCatalog.CATEGORY_BASIC, true),
				_roll_spec(StatCatalog.CATEGORY_BASIC),
			]
		GearItem.Tier.UNIQUE:
			return [
				_roll_spec(StatCatalog.CATEGORY_BASIC),
				_roll_spec(StatCatalog.CATEGORY_BASIC),
				_roll_spec(StatCatalog.CATEGORY_BASIC),
				_roll_spec(StatCatalog.CATEGORY_RARE),
				_roll_spec(StatCatalog.CATEGORY_SPECIAL),
			]
	return []


func _roll_spec(category: String, is_drawback: bool = false) -> Dictionary:
	return {"category": category, "is_drawback": is_drawback}


func _pool_for_slot(slot: GearItem.SlotType, category: String, is_drawback: bool) -> Array[String]:
	if is_drawback:
		return StatCatalog.drawback_stat_ids_for_slot(slot)
	return StatCatalog.stat_ids_for_slot(slot, category)


func _stat_category_for_slot(slots: Array[Dictionary], slot_index: int) -> StatModifier.StatCategory:
	var slot_spec: Dictionary = slots[slot_index]
	if bool(slot_spec.get("is_drawback", false)):
		return StatModifier.StatCategory.DRAWBACK
	match String(slot_spec.get("category", StatCatalog.CATEGORY_BASIC)):
		StatCatalog.CATEGORY_RARE:
			return StatModifier.StatCategory.RARE
		StatCatalog.CATEGORY_SPECIAL:
			return StatModifier.StatCategory.SPECIAL
	return StatModifier.StatCategory.BASIC


func _tier_value(stat_id: String, slot: GearItem.SlotType, tier: GearItem.Tier, slot_index: int, slots: Array[Dictionary]) -> float:
	var stat_category := _stat_category_for_slot(slots, slot_index)
	if stat_category == StatModifier.StatCategory.SPECIAL:
		return GearGenerator.PLACEHOLDER_BINARY_VALUE
	var category := String(slots[slot_index].get("category", StatCatalog.CATEGORY_BASIC))
	var max_roll := GearGenerator.max_rolled_value_for_stat_id(
		stat_id, slot, stat_category == StatModifier.StatCategory.DRAWBACK, tier, 1.0, 0, category
	)
	if not bool(max_roll.get("ok", false)):
		return 0.0
	return float(max_roll["value"])


func _rarity_value_multiplier(tier: GearItem.Tier, is_drawback: bool) -> float:
	match tier:
		GearItem.Tier.MASTER:
			return 1.75
		GearItem.Tier.EPIC:
			return 2.0
		GearItem.Tier.CURSED:
			return -2.5 if is_drawback else 2.5
		GearItem.Tier.CHAOS:
			return -3.0 if is_drawback else 3.0
		GearItem.Tier.UNIQUE:
			return 2.0
	return 1.0


func _round_value_for_stat_id(stat_id: String, value: float) -> float:
	var kind := StatCatalog.value_kind_for(stat_id)
	match kind:
		StatCatalog.VALUE_PERCENT, StatCatalog.VALUE_CHANCE:
			return round(value * 100.0) / 100.0
		StatCatalog.VALUE_FLAT, StatCatalog.VALUE_STACKS:
			var rounded: float = round(value)
			if value > 0.0 and kind == StatCatalog.VALUE_STACKS:
				rounded = maxf(1.0, rounded)
			return rounded
	return value


func _first_unused_stat_id(pool: Array[String], used: Array) -> String:
	for stat in pool:
		if not used.has(stat):
			return stat
	return pool[0]


func _used_stat_ids_except(item: GearItem, ignored_index: int) -> Array:
	var used: Array = []
	for i in item.affixes.size():
		if i == ignored_index:
			continue
		used.append(StatCatalog.canonical_id_for_modifier(item.affixes[i]))
	return used


func _canonical_stat_id_from_selection(stat: Variant) -> String:
	if typeof(stat) == TYPE_STRING or typeof(stat) == TYPE_STRING_NAME:
		return StatCatalog.canonicalize_stat_id(String(stat))
	return StatCatalog.legacy_stat_id(int(stat))


func _apply_stat_to_modifier(modifier: StatModifier, stat_id: String, slot: GearItem.SlotType, tier: GearItem.Tier, slot_index: int, slots: Array[Dictionary]) -> void:
	modifier.stat_id = StatCatalog.canonicalize_stat_id(stat_id)
	modifier.stat = _legacy_stat_for_stat_id(modifier.stat_id)
	modifier.category = _stat_category_for_slot(slots, slot_index)
	modifier.is_drawback = modifier.category == StatModifier.StatCategory.DRAWBACK
	modifier.operation = StatModifier.OperationType.ADD
	var value_slots: Array[Dictionary] = slots.duplicate(true)
	if tier == GearItem.Tier.CHAOS and not modifier.is_drawback:
		var category := String(value_slots[slot_index].get("category", StatCatalog.CATEGORY_BASIC))
		if not StatCatalog.stat_ids_for_slot(slot, category).has(modifier.stat_id):
			category = StatCatalog.CATEGORY_RARE if StatCatalog.stat_ids_for_slot(slot, StatCatalog.CATEGORY_RARE).has(modifier.stat_id) else StatCatalog.CATEGORY_BASIC
		value_slots[slot_index]["category"] = category
		modifier.category = StatModifier.StatCategory.RARE if category == StatCatalog.CATEGORY_RARE else StatModifier.StatCategory.BASIC
	modifier.value = _tier_value(modifier.stat_id, slot, tier, slot_index, value_slots)
	modifier.display_label = StatCatalog.label_for(modifier.stat_id)


func _legacy_stat_for_stat_id(stat_id: String) -> StatModifier.StatType:
	match StatCatalog.canonicalize_stat_id(stat_id):
		StatCatalog.BASE_DAMAGE:
			return StatModifier.StatType.PHYSICAL_DAMAGE
		StatCatalog.PERCENT_PHYSICAL_DAMAGE:
			return StatModifier.StatType.PHYSICAL_DAMAGE
		StatCatalog.INCREASED_ATTACK_SPEED:
			return StatModifier.StatType.ATTACK_SPEED
		StatCatalog.CRIT_CHANCE:
			return StatModifier.StatType.CRIT_CHANCE
		StatCatalog.CRIT_DAMAGE:
			return StatModifier.StatType.CRIT_MULTIPLIER
		StatCatalog.BASE_ELEMENTAL_DAMAGE:
			return StatModifier.StatType.POISON_DAMAGE
		StatCatalog.PERCENT_ELEMENTAL_DAMAGE:
			return StatModifier.StatType.POISON_DAMAGE
		StatCatalog.INCREASED_ALL_STACKS:
			return StatModifier.StatType.ARMOR_REDUCTION
		StatCatalog.INCREASED_GOLD:
			return StatModifier.StatType.GOLD_REWARDS
		StatCatalog.SHOP_DISCOUNT:
			return StatModifier.StatType.GOLD_REWARDS
		StatCatalog.INCREASED_MAGIC_FIND:
			return StatModifier.StatType.GOLD_REWARDS
	return StatModifier.StatType.ATTACK_SPEED


func set_target_armor(value: int) -> void:
	selected_target.armor = maxi(0, value)
	fight_setup_changed.emit()


func set_target_poison_resistance(value: float) -> void:
	selected_target.poison_resistance = clampf(value, 0.0, 1.0)
	fight_setup_changed.emit()


func set_target_defense(field: String, value: Variant) -> void:
	generated_monster_draft = null
	match field:
		"armor":
			selected_target.armor = maxi(0, int(value))
		"poison_resistance":
			selected_target.poison_resistance = clampf(float(value), 0.0, 1.0)
		"dodge_chance":
			selected_target.dodge_chance = clampf(float(value), 0.0, 1.0)
		"crit_negation":
			selected_target.crit_negation = clampf(float(value), 0.0, 1.0)
		"block":
			selected_target.block = maxf(0.0, float(value))
		"absorb":
			selected_target.absorb = maxf(0.0, float(value))
		"cleanse_threshold":
			selected_target.cleanse_threshold = maxi(0, int(value))
		"suppress":
			selected_target.suppress = clampf(float(value), 0.0, 10.0)
		"slow":
			selected_target.slow = clampf(float(value), 0.0, 10.0)
		"stun_duration_ms":
			selected_target.stun_duration_ms = maxi(0, int(value))
		"interrupt_skip_count":
			selected_target.interrupt_skip_count = maxi(0, int(value))
		_:
			return
	fight_setup_changed.emit()


func apply_target_preset(preset_id: String) -> void:
	generated_monster_draft = null
	_reset_target_defenses()
	for preset in TARGET_PRESETS:
		if preset["id"] == preset_id:
			for field in preset["defenses"]:
				_apply_target_defense_silent(field, preset["defenses"][field])
			fight_setup_changed.emit()
			return
	fight_setup_changed.emit()


func target_defense_snapshot() -> Dictionary:
	return {
		"armor": selected_target.armor,
		"poison_resistance": selected_target.poison_resistance,
		"dodge_chance": selected_target.dodge_chance,
		"crit_negation": selected_target.crit_negation,
		"block": selected_target.block,
		"absorb": selected_target.absorb,
		"cleanse_threshold": selected_target.cleanse_threshold,
		"suppress": selected_target.suppress,
		"slow": selected_target.slow,
		"stun_duration_ms": selected_target.stun_duration_ms,
		"interrupt_skip_count": selected_target.interrupt_skip_count,
	}


func _reset_target_defenses() -> void:
	for field in TARGET_DEFENSE_FIELDS:
		_apply_target_defense_silent(field, 0)


func _apply_target_defense_silent(field: String, value: Variant) -> void:
	match field:
		"armor":
			selected_target.armor = maxi(0, int(value))
		"poison_resistance":
			selected_target.poison_resistance = clampf(float(value), 0.0, 1.0)
		"dodge_chance":
			selected_target.dodge_chance = clampf(float(value), 0.0, 1.0)
		"crit_negation":
			selected_target.crit_negation = clampf(float(value), 0.0, 1.0)
		"block":
			selected_target.block = maxf(0.0, float(value))
		"absorb":
			selected_target.absorb = maxf(0.0, float(value))
		"cleanse_threshold":
			selected_target.cleanse_threshold = maxi(0, int(value))
		"suppress":
			selected_target.suppress = clampf(float(value), 0.0, 10.0)
		"slow":
			selected_target.slow = clampf(float(value), 0.0, 10.0)
		"stun_duration_ms":
			selected_target.stun_duration_ms = maxi(0, int(value))
		"interrupt_skip_count":
			selected_target.interrupt_skip_count = maxi(0, int(value))


func roll_generated_target(
	difficulty_id: int,
	seed: int = -1,
	monster_kind: String = GENERATED_MONSTER_KIND,
	archetype_a_id: String = "",
	archetype_b_id: String = "",
	contract_level: int = DEFAULT_CONTRACT_LEVEL
) -> GeneratedMonsterDraft:
	generated_monster_difficulty_id = difficulty_id
	generated_contract_level = clampi(contract_level, 1, 30)
	var library := RuntimeArchetypeLibraryLoader.load_default()
	var roll_seed := seed if seed >= 0 else _next_generated_monster_seed(difficulty_id, monster_kind, archetype_a_id, archetype_b_id, generated_contract_level)
	var input := _generated_monster_input(difficulty_id, roll_seed, library, monster_kind, archetype_a_id, archetype_b_id, generated_contract_level)
	var draft := RuntimeMonsterGenerator.generate(input, library)
	generated_monster_draft = draft
	if not draft.has_errors():
		selected_target = draft.to_monster()
		duration_ms = draft.duration_ms
		fight_seed = draft.source_seed
	fight_setup_changed.emit()
	return draft


func _next_generated_monster_seed(difficulty_id: int, monster_kind: String = GENERATED_MONSTER_KIND, archetype_a_id: String = "", archetype_b_id: String = "", contract_level: int = DEFAULT_CONTRACT_LEVEL) -> int:
	_generated_roll_index += 1
	var seed := RunRng.seed_for_context(
		DEFAULT_FIGHT_SEED,
		GENERATED_MONSTER_SEED_CONTEXT,
		[difficulty_id, monster_kind, archetype_a_id, archetype_b_id, contract_level, _generated_roll_index, Time.get_ticks_msec()]
	)
	return (seed % GENERATED_MONSTER_SEED_MAX) + 1


func _generated_monster_input(
	difficulty_id: int,
	seed: int,
	library: RuntimeArchetypeLibrary,
	monster_kind: String = GENERATED_MONSTER_KIND,
	archetype_a_id: String = "",
	archetype_b_id: String = "",
	contract_level: int = DEFAULT_CONTRACT_LEVEL
) -> RuntimeGenerationInput:
	var available := library.available_for(difficulty_id, monster_kind)
	if available.is_empty():
		return RuntimeGenerationInput.from_dictionary({
			"seed": seed,
			"difficulty": difficulty_id,
			"kind": monster_kind,
			"tempoProfile": GENERATED_MONSTER_TEMPO,
			"overrides": _contract_scaling_overrides(contract_level, monster_kind),
		})

	var rng := RunRng.rng_for_context(seed, GENERATED_MONSTER_SEED_CONTEXT, [difficulty_id, "archetypes"])
	var has_requested_primary := archetype_a_id != ""
	var has_requested_secondary := archetype_b_id != ""
	var primary_id := archetype_a_id
	var secondary_id := archetype_b_id
	if primary_id == "" or not library.has_archetype(primary_id):
		var primary: RuntimeArchetypeDef = available[rng.randi_range(0, available.size() - 1)]
		primary_id = primary.id
	if available.size() > 1 and (not has_requested_primary and not has_requested_secondary):
		if secondary_id == "" or not library.has_archetype(secondary_id) or secondary_id == primary_id:
			var secondary: RuntimeArchetypeDef = available[rng.randi_range(0, available.size() - 2)]
			if secondary.id == primary_id:
				secondary = available[available.size() - 1]
			secondary_id = secondary.id
	if secondary_id == primary_id:
		secondary_id = ""

	return RuntimeGenerationInput.from_dictionary({
		"seed": seed,
		"archetypeA": primary_id,
		"archetypeB": secondary_id,
		"difficulty": difficulty_id,
		"kind": monster_kind,
		"tempoProfile": GENERATED_MONSTER_TEMPO,
		"overrides": _contract_scaling_overrides(contract_level, monster_kind),
	})


func _contract_scaling_overrides(contract_level: int, monster_kind: String) -> Dictionary:
	var level := clampi(contract_level, 1, 30)
	var completed_count := level - 1
	return {
		"contract_hp_scaling": _contract_scaling_entry("contract_hp_curve_v2", level, completed_count, _contract_hp_multiplier_for_number(level), _contract_hp_role_scale(monster_kind)),
		"contract_dps_scaling": _contract_dps_scaling_entry(level, completed_count, _contract_dps_multiplier_for_number(level), _contract_dps_role_scale(monster_kind)),
		"contract_armor_scaling": _contract_scaling_entry("contract_armor_curve_v1", level, completed_count, _contract_armor_multiplier_for_number(level), _contract_armor_role_scale(monster_kind)),
		"contract_block_scaling": _contract_scaling_entry("contract_block_curve_v1", level, completed_count, _contract_block_multiplier_for_number(level), _contract_block_absorb_role_scale(monster_kind)),
		"contract_absorb_scaling": _contract_scaling_entry("contract_absorb_curve_v1", level, completed_count, _contract_block_multiplier_for_number(level), _contract_block_absorb_role_scale(monster_kind)),
	}


func _contract_scaling_entry(id: String, contract_level: int, completed_count: int, contract_multiplier: float, role_scale: float) -> Dictionary:
	return {
		"id": id,
		"contract_number": contract_level,
		"completed_contract_count": completed_count,
		"contract_multiplier": contract_multiplier,
		"role_scale": role_scale,
		"multiplier": 1.0 + (contract_multiplier - 1.0) * role_scale,
	}


func _contract_dps_scaling_entry(contract_level: int, completed_count: int, contract_multiplier: float, role_scale: float) -> Dictionary:
	var entry := _contract_scaling_entry("contract_dps_curve_v1", contract_level, completed_count, contract_multiplier, role_scale)
	entry["min_hp_budget_duration_sec"] = _minimum_hp_budget_duration_for_number(contract_level)
	return entry


func _contract_hp_multiplier_for_number(contract_level: int) -> float:
	return _interpolated_contract_multiplier(contract_level, [
		{"contract": 1, "multiplier": 1.0},
		{"contract": 5, "multiplier": 1.4},
		{"contract": 10, "multiplier": 2.3},
		{"contract": 15, "multiplier": 3.8},
		{"contract": 20, "multiplier": 6.0},
		{"contract": 25, "multiplier": 9.0},
		{"contract": 30, "multiplier": 13.0},
	])


func _contract_dps_multiplier_for_number(contract_level: int) -> float:
	return _interpolated_contract_multiplier(contract_level, [
		{"contract": 1, "multiplier": 1.0},
		{"contract": 5, "multiplier": 1.8},
		{"contract": 10, "multiplier": 3.5},
		{"contract": 15, "multiplier": 6.0},
		{"contract": 20, "multiplier": 10.0},
		{"contract": 25, "multiplier": 16.0},
		{"contract": 30, "multiplier": 25.0},
	])


func _contract_armor_multiplier_for_number(contract_level: int) -> float:
	return _interpolated_contract_multiplier(contract_level, [
		{"contract": 1, "multiplier": 1.0},
		{"contract": 5, "multiplier": 1.6},
		{"contract": 10, "multiplier": 2.8},
		{"contract": 15, "multiplier": 4.8},
		{"contract": 20, "multiplier": 7.5},
		{"contract": 25, "multiplier": 11.0},
		{"contract": 30, "multiplier": 16.0},
	])


func _contract_block_multiplier_for_number(contract_level: int) -> float:
	return _interpolated_contract_multiplier(contract_level, [
		{"contract": 1, "multiplier": 1.0},
		{"contract": 5, "multiplier": 1.4},
		{"contract": 10, "multiplier": 2.4},
		{"contract": 15, "multiplier": 4.0},
		{"contract": 20, "multiplier": 6.2},
		{"contract": 25, "multiplier": 9.0},
		{"contract": 30, "multiplier": 13.0},
	])


func _interpolated_contract_multiplier(contract_level: int, anchors: Array) -> float:
	var clamped_level := clampi(contract_level, 1, 30)
	for index in range(anchors.size() - 1):
		var start: Dictionary = anchors[index]
		var finish: Dictionary = anchors[index + 1]
		var start_contract := int(start["contract"])
		var finish_contract := int(finish["contract"])
		if clamped_level > finish_contract:
			continue
		var span := float(finish_contract - start_contract)
		var progress := clampf(float(clamped_level - start_contract) / maxf(1.0, span), 0.0, 1.0)
		return lerpf(float(start["multiplier"]), float(finish["multiplier"]), progress)
	return float(anchors[anchors.size() - 1]["multiplier"])


func _minimum_hp_budget_duration_for_number(contract_level: int) -> float:
	if contract_level <= 3:
		return 18.0
	if contract_level <= 10:
		return 22.0
	if contract_level <= 20:
		return 26.0
	return 30.0


func _contract_hp_role_scale(monster_kind: String) -> float:
	match monster_kind:
		"captain":
			return 1.1
		"elite", "boss":
			return 1.25
	return 1.0


func _contract_dps_role_scale(monster_kind: String) -> float:
	match monster_kind:
		"normal":
			return 0.85
		"captain":
			return 1.0
		"elite":
			return 1.2
		"boss":
			return 1.5
	return 1.0


func _contract_armor_role_scale(monster_kind: String) -> float:
	match monster_kind:
		"normal":
			return 0.75
		"captain":
			return 1.0
		"elite":
			return 1.2
		"boss":
			return 1.35
	return 1.0


func _contract_block_absorb_role_scale(monster_kind: String) -> float:
	match monster_kind:
		"normal":
			return 0.55
		"captain":
			return 0.75
		"elite":
			return 1.0
		"boss":
			return 1.2
	return 1.0


func set_duration_ms(ms: int) -> void:
	duration_ms = maxi(1000, ms)
	fight_setup_changed.emit()


func set_fight_seed(value: int) -> void:
	fight_seed = clampi(value, 0, GENERATED_MONSTER_SEED_MAX)
	fight_setup_changed.emit()


func set_random_fight_seed_enabled(enabled: bool) -> void:
	if random_fight_seed_enabled == enabled:
		return
	random_fight_seed_enabled = enabled
	fight_setup_changed.emit()


func set_generated_contract_level(level: int) -> void:
	var normalized := clampi(level, 1, 30)
	if generated_contract_level == normalized:
		return
	generated_contract_level = normalized
	fight_setup_changed.emit()


func randomize_fight_seed(context: String = "fight") -> int:
	_generated_roll_index += 1
	fight_seed = (RunRng.seed_for_context(
		DEFAULT_FIGHT_SEED,
		"%s.%s" % [GENERATED_MONSTER_SEED_CONTEXT, context],
		[generated_contract_level, _generated_roll_index, Time.get_ticks_msec()]
	) % GENERATED_MONSTER_SEED_MAX) + 1
	fight_setup_changed.emit()
	return fight_seed


## Practice gold rides on `build_changed`, not `fight_setup_changed` --
## unlike target/duration/seed, it genuinely affects resolved stats
## (Bandit Blade's gold-scaling physical damage) and must trigger the same
## live-refresh `character_stats_panel` already listens for.
func set_practice_gold(amount: int) -> void:
	configured_gold = maxi(0, amount)
	gold = configured_gold
	combat_stolen_gold = 0
	build_changed.emit()


func add_practice_combat_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	combat_stolen_gold += amount
	stats_preview_changed.emit()


## Resolves the current practice build and runs one fight against
## `selected_target` over `duration_ms`, seeded by `fight_seed` --
## completely separate from any real Adventure encounter/seed/state.
## `rotation` is already filtered to unlocked skills (`set_rotation()`
## and `_prune_rotation_to_unlocked()` both route through
## `BuildResolver.resolve_rotation()`), so it's ready to feed directly into
## `CombatResolver.resolve()`.
func run_fight() -> void:
	if not can_run_fight():
		return
	combat_stolen_gold = 0
	gold = configured_gold
	if random_fight_seed_enabled:
		randomize_fight_seed("fight")
	stats_preview_changed.emit()
	var stats := current_player_stats()
	last_result = CombatResolver.resolve(rotation, stats, selected_target, duration_ms, fight_seed)
	fight_finished.emit()


## Universal Phase 5 paper-doll order, matching `BuildState.equipped_gear()`.
func equipped_gear() -> Array[GearItem]:
	var gear: Array[GearItem] = []
	for item in [equipped_weapon, equipped_helm, equipped_armor, equipped_trinket, equipped_charm]:
		if item != null:
			gear.append(item)
	return gear


func _prune_rotation_to_unlocked() -> void:
	rotation_changes = BuildResolver.normalize_rotation(rotation, unlocked_skills())
	rotation = rotation_changes["rotation"]


func current_player_stats() -> PlayerStats:
	if ranked_build != null:
		var resolved := BuildResolver.resolve_ranked_build(selected_class, ranked_build, equipped_gear(), gold, carried_items)
		if resolved.get("stats") != null:
			return _with_legendary_practice_context(resolved.stats)
		var invalid := PlayerStats.new()
		invalid.derivation_error = String(resolved.get("error", "Invalid practice build."))
		return invalid
	return _with_legendary_practice_context(BuildResolver.resolve_stats(selected_class, selected_trees, selected_talents, equipped_gear(), gold, carried_items))


func configure_ranked_build(primary: SubclassTree, secondary: SubclassTree = null) -> bool:
	var candidate := RankedBuild.new()
	if not candidate.configure(primary, secondary, earned_talent_points):
		last_build_error = candidate.last_error
		return false
	if candidate.resolved_content()["error"] != "":
		last_build_error = candidate.resolved_content()["error"]
		return false
	ranked_build = candidate
	return _finish_rank_edit(true)


func set_talent_budget(points: Variant) -> bool:
	if allocation_locked:
		last_build_error = "Finish or skip combat playback before editing talents."
		return false
	if ranked_build != null:
		return _finish_rank_edit(ranked_build.set_budget(points))
	if typeof(points) != TYPE_INT or points < PassiveAllocator.points_spent(selected_talents) or points > BuildProgression.POINT_CAP or points < 0:
		last_build_error = "Budget must cover allocated points and be within 0ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“45."
		return false
	earned_talent_points = points
	build_changed.emit()
	return true


func refund_all_talents() -> bool:
	if allocation_locked:
		last_build_error = "Finish or skip combat playback before editing talents."
		return false
	return _finish_rank_edit(ranked_build.refund_all(true)) if ranked_build != null else false


func refund_tree_talents(tree_id: String) -> bool:
	if allocation_locked:
		last_build_error = "Finish or skip combat playback before editing talents."
		return false
	if ranked_build == null: return false
	return _finish_rank_edit(ranked_build.refund_tree(tree_id, true))


func _finish_rank_edit(success: bool) -> bool:
	last_build_error = ranked_build.last_error
	if not success:
		return false
	selected_trees = ranked_build.trees()
	selected_talents = []
	earned_talent_points = ranked_build.budget()
	_prune_rotation_to_unlocked()
	set_locked(false)
	build_changed.emit()
	return true


# Controlled Practice fixture; Adventure encounter attempts remain separate.
var legendary_missing_attempts := 0

func _with_legendary_practice_context(stats: PlayerStats) -> PlayerStats:
	if stats != null:
		var effects: Dictionary = stats.special_effects.get("legendary", {})
		effects["missing_attempts"] = maxi(0, legendary_missing_attempts)
		effects["unlimited_retries"] = false
		stats.special_effects["legendary"] = effects
		if stats.derivation_base != null:
			stats.derivation_base.special_effects["legendary"] = effects.duplicate(true)
	return stats


func set_legendary_missing_attempts(value: int) -> bool:
	if allocation_locked or value < 0 or value > 99:
		return false
	legendary_missing_attempts = value
	build_changed.emit()
	fight_setup_changed.emit()
	return true
