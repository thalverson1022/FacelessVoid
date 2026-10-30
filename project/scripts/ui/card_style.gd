class_name CardStyle
extends RefCounted
## Shared "card" look used across the title/class_select/subclass_select/
## combat screens -- a bordered, dark panel. Centralized so the eventual
## full theming pass has one place to change, rather than each screen
## re-implementing a slightly different StyleBoxFlat. As of P2:R7:T2, both
## the color values below and the project-wide Theme
## (project/assets/ui_theme.tres) read from UIColors, so this file and the
## Theme resource can never drift out of sync with the adopted palette.

## Highlight color tying the macro slot letters to the matching first
## letter in Available Skills, so the connection between the two reads at
## a glance. Also used throughout as the general header/highlight accent.
const ACCENT_COLOR := UIColors.ACCENT

## Body/data font for small fixed-size boxes carrying multi-line data text
## (map nodes) -- the theme's default Press Start 2P button font would
## overflow them. Mirrors combat_screen.gd's DATA_BUTTON_FONT rationale
## (P2:R7:T2 legibility pass).
const DATA_FONT := preload("res://assets/fonts/VT323-Regular.ttf")

## Shared selection-card sizing/typography, extracted from
## subclass_select.gd so the primary subclass select screen and
## combat_screen.gd's secondary Rogue tree chooser render identical cards
## (P2:R7 second playtest-feedback pass, item 5).
const SELECTION_CARD_WIDTH := 280
const SELECTION_CARD_TITLE_FONT_SIZE := 24
const SELECTION_CARD_BODY_FONT_SIZE := 15
const SUBCLASS_ICON_SIZE := Vector2(36, 36)
const UI_ICON_SIZE := Vector2(22, 22)
const TALENT_POINT_ICON_PATH := "res://assets/ui/icons/talent_point.png"
const StatCatalog := preload("res://scripts/systems/stat_catalog.gd")
const WeaponDamageCatalog := preload("res://scripts/systems/weapon_damage_catalog.gd")
const STAT_COLOR_BASIC := Color("F0E2C5")
const STAT_COLOR_RARE := Color("8FCBFF")
const STAT_COLOR_SPECIAL := Color("E7D967")
const STAT_COLOR_DRAWBACK := Color("CFA6FF")
const MAX_ROLL_EPSILON := 0.0001
const TOOLTIP_RICH_FONT_SIZE := 18
const TOOLTIP_RICH_MAX_ROLL_FONT_SIZE := TOOLTIP_RICH_FONT_SIZE + 2
const TOOLTIP_RICH_MAX_WIDTH := 340.0
const DISPLAY_STAT_ORDER := {
	StatCatalog.BASE_DAMAGE: 10,
	StatCatalog.PERCENT_PHYSICAL_DAMAGE: 20,
	StatCatalog.INCREASED_ATTACK_SPEED: 30,
	StatCatalog.CRIT_CHANCE: 40,
	StatCatalog.CRIT_DAMAGE: 50,
	StatCatalog.BASE_ELEMENTAL_DAMAGE: 60,
	StatCatalog.PERCENT_ELEMENTAL_DAMAGE: 70,
	StatCatalog.INCREASED_ALL_STACKS: 80,
	StatCatalog.INCREASED_SHRED_STACKS: 80,
	StatCatalog.INCREASED_DECAY_STACKS: 80,
	StatCatalog.INCREASED_ELEMENTAL_STACKS: 80,
	StatCatalog.BONUS_SHRED_STACKS: 80,
	StatCatalog.INCREASED_GOLD: 90,
	StatCatalog.SHOP_DISCOUNT: 100,
	StatCatalog.INCREASED_MAGIC_FIND: 105,
	StatCatalog.CHANCE_FOR_RETRIGGER: 110,
	StatCatalog.CHANCE_TO_SHRED: 120,
	StatCatalog.CHANCE_TO_DECAY: 130,
	StatCatalog.CRIT_APPLIES_ELEMENT: 140,
}
const DISPLAY_SPECIAL_ORDER := {
	StatCatalog.DISABLE_ENEMY_DODGE: 10,
	StatCatalog.DISABLE_ENEMY_BLOCK: 20,
	StatCatalog.DISABLE_ENEMY_ABSORB: 30,
	StatCatalog.DISABLE_ENEMY_SUPPRESS: 40,
	StatCatalog.DISABLE_ENEMY_CLEANSE: 50,
	StatCatalog.IGNORE_ARMOR_NO_SHRED: 60,
	StatCatalog.IGNORE_RESISTANCE_PHYSICAL_PENALTY: 70,
	StatCatalog.DOUBLE_APPLIED_STACKS: 80,
	StatCatalog.CONVERT_DAMAGE_TO_PHYSICAL: 90,
	StatCatalog.CONVERT_DAMAGE_TO_MAGICAL: 100,
	StatCatalog.ALL_STATS_INCREASED: 110,
	StatCatalog.IMMUNE_TO_STUN: 120,
	StatCatalog.IMMUNE_TO_SLOW: 130,
	StatCatalog.IMMUNE_TO_INTERRUPT: 140,
	StatCatalog.DECAY_APPLIES_SHRED: 150,
	StatCatalog.POISON_STACK_CAP_40: 160,
}

static var _talent_point_icon: Texture2D = null


static func make_stylebox(content_margin: int = 16) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UIColors.PANEL
	style.border_color = UIColors.PANEL_BORDER
	style.set_border_width_all(3)
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 4
	style.border_width_bottom = 5
	style.border_blend = true
	style.set_corner_radius_all(8)
	style.set_content_margin_all(content_margin)
	style.shadow_color = UIColors.PANEL_DROP_SHADOW
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 3)
	return style


static func make_action_button_stylebox(bg: Color, border: Color, state_name: String = "normal") -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(3)
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 4
	style.border_width_bottom = 5
	style.border_blend = true
	style.set_corner_radius_all(6)
	style.shadow_color = UIColors.PANEL_DROP_SHADOW
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 9
	style.content_margin_bottom = 12
	if state_name == "pressed":
		style.border_width_top = 5
		style.border_width_left = 4
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = UIColors.BUTTON_EDGE_SHADOW if border == UIColors.PANEL_BORDER else border
		style.shadow_size = 1
		style.shadow_offset = Vector2(0, 1)
		style.content_margin_top = 12
		style.content_margin_bottom = 9
	elif state_name == "hover" or state_name == "focus":
		style.border_color = UIColors.BUTTON_EDGE_LIGHT
		style.shadow_color = UIColors.BUTTON_INNER_GLOW
		style.shadow_size = 7
	elif state_name == "disabled":
		style.border_width_top = 1
		style.border_width_left = 1
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.shadow_size = 1
		style.shadow_offset = Vector2(0, 1)
		style.content_margin_top = 10
		style.content_margin_bottom = 10
	return style


static func make_slot_stylebox(fill: Color, border: Color, border_width: int = 2, state_name: String = "normal") -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill.darkened(0.08)
	style.border_color = border
	style.set_border_width_all(border_width)
	style.border_width_top = max(1, border_width - 1)
	style.border_width_left = max(1, border_width - 1)
	style.border_width_right = border_width + 1
	style.border_width_bottom = border_width + 2
	style.border_blend = true
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0, 0, 0, 0.36)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 2)
	if state_name == "hover" or state_name == "focus":
		style.bg_color = fill
		style.border_color = UIColors.SLOT_HOVER if border == UIColors.SLOT_BORDER else border
		style.shadow_color = UIColors.BUTTON_INNER_GLOW
		style.shadow_size = 5
	elif state_name == "pressed":
		style.bg_color = fill.darkened(0.18)
		style.border_width_top = border_width + 1
		style.border_width_left = border_width + 1
		style.border_width_right = max(1, border_width - 1)
		style.border_width_bottom = max(1, border_width - 1)
		style.shadow_size = 1
	elif state_name == "disabled":
		style.bg_color = fill.darkened(0.35)
		style.border_color = UIColors.TEXT_DISABLED
		style.shadow_size = 0
	return style


## Adds the standard gear-box icon (GearIcons.icon_for()'s art over the
## button's existing tier-colored background) as a child of `button` --
## shared by gear_panel.gd's inventory slots and combat_screen.gd's
## shop/reward-choice boxes (P2:R7 gear-art pass) so this layout only exists
## once. The icon alone now carries slot/tier at a glance (art distinguishes
## slot type, background color distinguishes tier), so the caption text this
## helper used to add alongside it was dropped as redundant.
static func build_gear_box_content(button: Button, gear: GearItem) -> void:
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Nearest-neighbor keeps the 32x32 pixel art crisp when scaled up to fit
	# an 88-112px box, instead of blurring like the project's photographic
	# backgrounds (which use the default linear filter).
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.texture = GearIcons.icon_for(gear)
	button.add_child(icon)


## The regular tooltip lines for one gear item -- slot/name, tier, affixes,
## and any triggered-skill effects. Shared by combat_screen.gd's shop/reward
## offer tooltips and gear_panel.gd's
## inventory/equipped-slot tooltips, so the same item can't show different
## information in different screens.
static func gear_tooltip_lines(gear: GearItem) -> PackedStringArray:
	var lines: PackedStringArray = []
	if gear == null:
		return lines
	if is_unidentified_chaos(gear):
		return unidentified_gear_tooltip_lines(gear)
	if gear != null and gear.tier == GearItem.Tier.LEGENDARY:
		return _legendary_tooltip_lines(gear)
	lines.append_array(gear_header_lines(gear))
	lines.append_array(_gear_affix_lines(gear))
	for trigger in gear.triggered_skill_effects:
		if trigger != null and trigger.skill != null:
			lines.append("%d%% chance to trigger %s" % [roundi(trigger.chance * 100.0), trigger.skill.display_name])
	return lines


static func is_unidentified_chaos(gear: GearItem) -> bool:
	return gear != null and gear.tier == GearItem.Tier.CHAOS and gear.is_unidentified


static func unidentified_gear_tooltip_lines(gear: GearItem) -> PackedStringArray:
	var lines: PackedStringArray = []
	if gear == null:
		return lines
	lines.append("Unidentified")
	lines.append(LegendaryCatalog.header_text(gear))
	lines.append("Stats:")
	lines.append("Unidentified")
	return lines


static func gear_header_lines(gear: GearItem) -> PackedStringArray:
	var lines: PackedStringArray = []
	if gear == null:
		return lines
	lines.append(gear.display_name)
	lines.append(LegendaryCatalog.header_text(gear))
	if gear.slot == GearItem.SlotType.WEAPON:
		var damage_range := WeaponDamageCatalog.damage_range_for_weapon(gear)
		lines.append("Weapon Damage: %d-%d" % [int(damage_range["min"]), int(damage_range["max"])])
	return lines


static func _legendary_tooltip_lines(gear: GearItem) -> PackedStringArray:
	var lines := gear_header_lines(gear)
	var visible_affixes: Array[StatModifier] = []
	for affix: StatModifier in gear.affixes:
		if affix.stat == StatModifier.StatType.POISON_TICK_INTERVAL:
			continue
		if StatModifierFormatter.format(affix) != "":
			visible_affixes.append(affix)
	visible_affixes.sort_custom(_sort_affixes_for_display)
	if not visible_affixes.is_empty():
		lines.append("Stats:")
		for affix in visible_affixes:
			lines.append(LegendaryCatalog.stat_text(affix))
	var text := LegendaryCatalog.effect_text(gear)
	if text != "":
		lines.append("Legendary Effect:")
		lines.append(text)
	return lines


static func rarity_fill_color(tier: int) -> Color:
	return GearGenerator.tier_color(tier)


static func rarity_border_color(tier: int, equipped: bool = false, disabled: bool = false) -> Color:
	if disabled:
		return UIColors.TEXT_DISABLED
	if equipped:
		return ACCENT_COLOR
	match tier:
		GearItem.Tier.EPIC:
			return UIColors.PANEL_EDGE_LIGHT
		GearItem.Tier.CHAOS:
			return UIColors.TEXT_NORMAL
		GearItem.Tier.UNIQUE:
			return UIColors.TEXT_GOLD
		GearItem.Tier.LEGENDARY:
			return UIColors.TIER_LEGENDARY.lightened(0.18)
	return UIColors.SLOT_BORDER


static func rarity_border_width(tier: int, equipped: bool = false) -> int:
	if equipped:
		return 4 if tier == GearItem.Tier.EPIC else 3
	return 3 if tier == GearItem.Tier.EPIC else 2


static func make_gear_item_stylebox(gear: GearItem, equipped: bool = false, state_name: String = "normal") -> StyleBoxFlat:
	var tier := gear.tier if gear != null else GearItem.Tier.BASIC
	var fill := UIColors.SLOT_EMPTY if gear == null else rarity_fill_color(tier)
	var border := UIColors.SLOT_BORDER if gear == null else rarity_border_color(tier, equipped, state_name == "disabled")
	var width := 2 if gear == null else rarity_border_width(tier, equipped)
	var style := make_slot_stylebox(fill, border, width, state_name)
	if gear != null and tier == GearItem.Tier.EPIC:
		style.border_blend = false
		style.shadow_color = Color(1.0, 0.94, 0.72, 0.34) if state_name != "disabled" else UIColors.PANEL_DROP_SHADOW
		style.shadow_size = 6 if state_name != "disabled" else 1
	elif gear != null and tier == GearItem.Tier.CHAOS and state_name != "disabled":
		style.border_blend = false
	return style


static func _gear_affix_lines(gear: GearItem) -> PackedStringArray:
	if gear == null:
		return PackedStringArray()
	if gear.tier == GearItem.Tier.CHAOS:
		return _chaos_affix_lines(gear)
	var positive_affixes: Array[StatModifier] = []
	var drawback_affixes: Array[StatModifier] = []
	var special_affixes: Array[StatModifier] = []
	for affix: StatModifier in gear.affixes:
		var formatted := StatModifierFormatter.format(affix)
		if formatted == "":
			continue
		var stat_id := StatCatalog.canonical_id_for_modifier(affix)
		if affix.is_drawback:
			drawback_affixes.append(affix)
		elif stat_id != "" and StatCatalog.is_special(stat_id):
			special_affixes.append(affix)
		else:
			positive_affixes.append(affix)
	positive_affixes.sort_custom(_sort_affixes_for_display)
	drawback_affixes.sort_custom(_sort_affixes_for_display)
	special_affixes.sort_custom(_sort_affixes_for_display)
	var lines: PackedStringArray = []
	if not positive_affixes.is_empty():
		lines.append("Stats:")
		lines.append_array(_formatted_affix_lines(positive_affixes))
	if not drawback_affixes.is_empty():
		lines.append("Drawbacks:")
		lines.append_array(_formatted_affix_lines(drawback_affixes))
	if not special_affixes.is_empty():
		lines.append("Special:")
		lines.append_array(_formatted_affix_lines(special_affixes))
	return lines


static func _chaos_affix_lines(gear: GearItem) -> PackedStringArray:
	var lines: PackedStringArray = []
	var affix_lines := _formatted_affix_lines(gear.affixes)
	if affix_lines.is_empty():
		return lines
	lines.append("Stats:")
	lines.append_array(affix_lines)
	return lines


static func _formatted_affix_lines(affixes: Array) -> PackedStringArray:
	var lines: PackedStringArray = []
	for affix: StatModifier in affixes:
		var formatted := StatModifierFormatter.format(affix)
		if formatted != "":
			lines.append(formatted)
	return lines


static func _sort_affixes_for_display(a: StatModifier, b: StatModifier) -> bool:
	var a_id := StatCatalog.canonical_id_for_modifier(a)
	var b_id := StatCatalog.canonical_id_for_modifier(b)
	var a_order := _display_order_for_stat_id(a_id)
	var b_order := _display_order_for_stat_id(b_id)
	if a_order == b_order:
		return StatModifierFormatter.format(a) < StatModifierFormatter.format(b)
	return a_order < b_order


static func _display_order_for_stat_id(stat_id: String) -> int:
	var canonical_id := StatCatalog.canonicalize_stat_id(stat_id)
	if DISPLAY_STAT_ORDER.has(canonical_id):
		return int(DISPLAY_STAT_ORDER[canonical_id])
	if DISPLAY_SPECIAL_ORDER.has(canonical_id):
		return 1000 + int(DISPLAY_SPECIAL_ORDER[canonical_id])
	return 500


## Builds the backdrop -> CenterContainer -> bare PanelContainer inside
## `root` for a full-screen modal overlay, and returns the panel so the
## caller can style it and add its own content. The helper enforces the
## full-rect geometry on root/backdrop/center so extracted overlay scenes
## stay centered even if their serialized root anchors drift during refactors.
##
## `dismissable`: overlays that are pure informational views (Combat Log,
## Talent Trees) close on an outside click; overlays that gate a real
## decision (accept a contract, choose a reward, pick a route) with no
## defined "cancel" behavior stay locked -- see combat_screen.gd's overlay
## builders for which is which.
static func build_modal_panel(root: Control, dismissable: bool, dimmed: bool = false) -> PanelContainer:
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_index = 100

	if dismissable:
		var backdrop := Button.new()
		backdrop.flat = not dimmed
		backdrop.focus_mode = Control.FOCUS_NONE
		backdrop.z_index = 100
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var backdrop_style := StyleBoxFlat.new()
		backdrop_style.bg_color = UIColors.OVERLAY_BACKDROP
		for state in ["normal", "hover", "pressed"]:
			backdrop.add_theme_stylebox_override(state, backdrop_style)
		# Godot draws focus over the normal style; an opaque focus fill
		# would double the dimming until a talent takes keyboard focus.
		backdrop.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		backdrop.pressed.connect(func(): root.visible = false)
		root.add_child(backdrop)
	else:
		var backdrop := ColorRect.new()
		backdrop.z_index = 100
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		backdrop.color = UIColors.OVERLAY_BACKDROP
		backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
		root.add_child(backdrop)

	var center := CenterContainer.new()
	center.z_index = 101
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.z_index = 102
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(panel)
	return panel


## Gear hovers show only the hovered item's details in every mode. Keep the
## shared builder signature and wrapper for existing shop/inventory callers;
## equipped references and projected equip deltas are intentionally hidden.
static func build_gear_compare_tooltip(theme_owner: Control, item_text: String, _equipped: GearItem, item: GearItem = null, _include_equip_preview: bool = true) -> Control:
	var row := HBoxContainer.new()
	row.add_child(_make_tooltip_box(theme_owner, "", item_text, item))
	return row


## Resolve ownership after equip, traversing each carried occurrence once.
static func gear_comparison_lines(item: GearItem, theme_owner: Control) -> PackedStringArray:
	var lines: PackedStringArray = []
	if item == null or is_unidentified_chaos(item):
		return lines
	var state = theme_owner.get_node_or_null("/root/BuildState")
	for property in theme_owner.get_property_list():
		if property.name in ["state", "_state"] and theme_owner.get(property.name) != null:
			state = theme_owner.get(property.name)
			break
	if state == null or state.selected_class == null:
		return lines
	var equipped: Array[GearItem] = state.equipped_gear().duplicate()
	if equipped.has(item):
		lines.append("Already equipped.")
		return lines
	var carried: Array[GearItem] = []
	var owned = state.get("carried_items") if state is TrainingRoomState else state.get("inventory")
	if owned != null: carried.assign(owned)
	var occurrence := carried.find(item)
	if occurrence >= 0: carried.remove_at(occurrence)
	var replaced: GearItem = null
	for i in equipped.size():
		if equipped[i].slot == item.slot:
			replaced = equipped[i]
			equipped.remove_at(i)
			break
	var preview_gold: int = state.gold
	if replaced != null:
		if carried.size() < 3: carried.append(replaced)
		elif state.has_method("sell_value_for"): preview_gold += state.sell_value_for(replaced)
	equipped.append(item)
	var before: PlayerStats = state.current_player_stats()
	var after: PlayerStats
	var after_skills: Array[Skill] = []
	if state.ranked_build != null:
		var resolved := BuildResolver.resolve_ranked_build(state.selected_class, state.ranked_build, equipped, preview_gold, carried)
		if resolved.get("stats") == null:
			lines.append("Equip preview invalid: " + String(resolved.get("error", "Invalid build.")))
			return lines
		after = resolved.stats
		after_skills.assign(resolved.skills)
	else:
		after = BuildResolver.resolve_stats(state.selected_class, state.selected_trees, state.selected_talents, equipped, preview_gold, carried)
		after_skills = BuildResolver.resolve_unlocked_skills(state.selected_class, state.selected_trees, state.selected_talents, equipped)
	if after.derivation_error != "":
		lines.append("Equip preview invalid: " + after.derivation_error)
		return lines
	var before_context: Dictionary = before.special_effects.get("legendary", {})
	var after_context: Dictionary = after.special_effects.get("legendary", {})
	for key in ["missing_attempts", "unlimited_retries"]:
		if before_context.has(key): after_context[key] = before_context[key]
	after.special_effects["legendary"] = after_context
	var stolen := int(state.get("combat_stolen_gold"))
	before = preload("res://scripts/systems/legendary_live_stats.gd").resolve(before, state.gold, stolen)
	after = preload("res://scripts/systems/legendary_live_stats.gd").resolve(after, preview_gold, stolen)
	lines.append("On equip:")
	var labels := {
		"cooldown_reduction": "Cooldown Reduction", "increased_buff_duration": "Buff Duration",
		"crit_applies_penetration": "Crits Apply Penetration", "crit_applies_potency": "Crits Apply Potency",
		"shop_discount": "Shop Discount", "magic_find": "Magic Find",
		"shred_chance": "Chance to Shred", "decay_chance": "Chance to Decay",
		"elemental_proc_chance": "Poison Proc Chance", "retrigger_chance": "Retrigger Chance",
		"min_cast_time_proc_chance": "Minimum Cast Time Chance", "attack_speed": "Attack Speed",
		"gold_reward_multiplier": "Increased Gold", "bonus_physical_damage": "Base Physical Damage",
		"physical_damage_multiplier": "Physical Damage", "elemental_damage_multiplier": "Elemental Damage",
		"bonus_poison_stacks": "Bonus Poison Stacks", "bonus_shred_stacks": "Bonus Shred Stacks",
		"bonus_decay_stacks": "Bonus Decay Stacks", "shred_value": "Armor Decrease per Shred Stack",
		"poison_stack_cap": "Poison Stack Cap", "poison_tick_interval_multiplier": "Poison Tick Interval",
	}
	for field in ["cooldown_reduction", "increased_buff_duration", "crit_applies_penetration", "crit_applies_potency", "shop_discount", "magic_find", "shred_chance", "decay_chance", "elemental_proc_chance", "retrigger_chance", "min_cast_time_proc_chance", "attack_speed"]:
		if not is_equal_approx(before.get(field), after.get(field)):
			lines.append("%s: %s%% -> %s%%" % [labels[field], _comparison_number(before.get(field) * 100.0), _comparison_number(after.get(field) * 100.0)])
	for field in ["gold_reward_multiplier", "bonus_physical_damage", "physical_damage_multiplier", "elemental_damage_multiplier", "bonus_poison_stacks", "bonus_shred_stacks", "bonus_decay_stacks", "shred_value", "poison_stack_cap", "poison_tick_interval_multiplier"]:
		if not is_equal_approx(before.get(field), after.get(field)):
			if field == "gold_reward_multiplier":
				lines.append("%s: %s%% -> %s%%" % [labels[field], _comparison_number((before.gold_reward_multiplier - 1.0) * 100.0), _comparison_number((after.gold_reward_multiplier - 1.0) * 100.0)])
			elif field.ends_with("multiplier"):
				lines.append("%s: x%s -> x%s" % [labels[field], _comparison_number(before.get(field)), _comparison_number(after.get(field))])
			else:
				lines.append("%s: %s -> %s" % [labels[field], _comparison_number(before.get(field)), _comparison_number(after.get(field))])
	var before_crit := effective_crit_text(before, state.gold, stolen)
	var after_crit := effective_crit_text(after, preview_gold, stolen)
	if before_crit != after_crit:
		lines.append("Crit Chance / Damage: %s -> %s" % [before_crit, after_crit])
	if before.weapon_damage_min != after.weapon_damage_min or before.weapon_damage_max != after.weapon_damage_max:
		lines.append("Weapon Damage: %d-%d -> %d-%d" % [before.weapon_damage_min, before.weapon_damage_max, after.weapon_damage_min, after.weapon_damage_max])
	var before_poison := before.base_poison_damage + before.bonus_base_elemental_damage
	var after_poison := after.base_poison_damage + after.bonus_base_elemental_damage
	if not is_equal_approx(before_poison, after_poison):
		lines.append("Base Poison Damage: %s -> %s" % [_comparison_number(before_poison), _comparison_number(after_poison)])
	var before_skills: Array[Skill] = state.unlocked_skills()
	for skill in after_skills:
		if not _has_skill(before_skills, skill.id): lines.append("Skill gained: " + skill.display_name)
	for skill in before_skills:
		if not _has_skill(after_skills, skill.id): lines.append("Skill lost: " + skill.display_name)
	if lines.size() == 1: lines.clear()
	return lines


## Keep comparison totals compact; detailed derivation remains in Character Stats.
static func _comparison_number(value: float) -> String:
	return LegendaryCatalog.number_text(snappedf(value, 0.01))


static func _has_skill(skills: Array[Skill], id: String) -> bool:
	for skill in skills:
		if skill.id == id: return true
	return false


static func effective_crit_text(stats: PlayerStats, stash: int, stolen: int = 0) -> String:
	if stats.legendary_signet: return "Cannot crit"
	var inputs: Dictionary = preload("res://scripts/systems/combat_gold.gd").crit_values(stats, stash, stolen)
	return "%.0f%% / %.2fx" % [clampf(inputs.crit_chance, 0.0, 1.0) * 100.0, inputs.crit_multiplier]


## Conditional outputs belong beside resolved stats, never in static affix totals.
static func legendary_stat_lines(stats: PlayerStats, unchanged: Dictionary = {}) -> PackedStringArray:
	var lines: PackedStringArray = []
	var flags: Dictionary = stats.special_effects.get("legendary", {})
	if stats.legendary_bandit and not unchanged.get("bandit", false):
		lines.append("Bandit: +%.0f Base Physical Damage from current stash (cap +100)" % stats.legendary_added_flat)
	if stats.legendary_signet and not unchanged.get("signet", false):
		lines.append("Signet conversion: +%s%% Attack Speed; +%s%% Physical Damage" % [LegendaryCatalog.number_text(stats.legendary_added_ias * 100.0), LegendaryCatalog.number_text(stats.legendary_added_physical * 100.0)])
		for source in stats.stat_sources:
			if source.get("source_id", "") == "legendary.signet":
				lines.append("From uncapped %s%% Crit Chance and x%s Crit Damage" % [LegendaryCatalog.number_text(float(source.get("raw_crit_chance", 0.0)) * 100.0), LegendaryCatalog.number_text(float(source.get("raw_crit_multiplier", 1.0)))])
	if flags.get("death_door", false) and not unchanged.get("death_door", false):
		var multiplier := 1.0 if flags.get("unlimited_retries", false) else maxf(1.0, 2.0 * int(flags.get("missing_attempts", 0)))
		lines.append("Death's Door: x%.0f damage; Exsanguinate excluded" % multiplier)
	if flags.get("mithril", false) and not unchanged.get("mithril", false):
		lines.append("Mithril: +50 points on Stab / Heavy Slash rolls only (cap 100%)")
	if stats.legendary_crown and not unchanged.get("crown", false):
		lines.append("Crown: self-buff bonuses x2; x2 becomes x3")
	return lines


static func build_gear_tooltip(theme_owner: Control, gear: GearItem, body_override: String = "") -> Control:
	var body := body_override if not body_override.is_empty() else "\n".join(gear_tooltip_lines(gear))
	return _make_tooltip_box(theme_owner, "", body, gear)


## One compact item box, deliberately
## styled to be visually identical to a standard tooltip: the theme chain's
## own TooltipPanel stylebox and TooltipLabel font color, default font and
## size, no extra padding. `header`, when non-empty, renders as an
## accent-colored first line.
static func _make_tooltip_box(theme_owner: Control, header: String, body: String, gear: GearItem = null) -> Control:
	var panel := PanelContainer.new()
	var tooltip_style := theme_owner.get_theme_stylebox("panel", "TooltipPanel").duplicate() as StyleBox
	if tooltip_style is StyleBoxFlat:
		var fill: Color = tooltip_style.bg_color
		fill.a = 1.0
		tooltip_style.bg_color = fill
	panel.add_theme_stylebox_override("panel", tooltip_style)
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)

	if gear != null:
		row.add_child(make_pixel_icon(GearIcons.icon_for(gear), Vector2(32, 32)))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	row.add_child(vbox)

	if header != "":
		var header_label := Label.new()
		header_label.text = header
		header_label.add_theme_color_override("font_color", ACCENT_COLOR)
		vbox.add_child(header_label)

	if gear == null:
		for line in body.split("\n"):
			_add_plain_tooltip_label(vbox, line, theme_owner.get_theme_color("font_color", "TooltipLabel"))
	else:
		_add_gear_tooltip_line_labels(vbox, theme_owner, gear)
		_add_extra_tooltip_body_lines(vbox, body, gear, theme_owner.get_theme_color("font_color", "TooltipLabel"))
	return panel


static func _add_gear_tooltip_line_labels(vbox: VBoxContainer, theme_owner: Control, gear: GearItem) -> void:
	var default_color := theme_owner.get_theme_color("font_color", "TooltipLabel")
	if is_unidentified_chaos(gear):
		for line in gear_tooltip_lines(gear):
			_add_plain_tooltip_label(vbox, line, default_color)
		return
	for line in gear_header_lines(gear):
		_add_plain_tooltip_label(vbox, line, default_color)
	if gear.tier == GearItem.Tier.LEGENDARY:
		var legendary_affixes: Array[StatModifier] = []
		for affix: StatModifier in gear.affixes:
			if affix.stat == StatModifier.StatType.POISON_TICK_INTERVAL:
				continue
			if StatModifierFormatter.format(affix) != "":
				legendary_affixes.append(affix)
		legendary_affixes.sort_custom(_sort_affixes_for_display)
		_add_affix_group_labels(vbox, "Stats:", legendary_affixes, gear, default_color)
		var legendary_text := LegendaryCatalog.effect_text(gear)
		if legendary_text != "":
			_add_plain_tooltip_label(vbox, "Legendary Effect:", default_color)
			_add_plain_tooltip_label(vbox, legendary_text, STAT_COLOR_SPECIAL)
		return
	if gear.tier == GearItem.Tier.CHAOS:
		var chaos_affixes: Array[StatModifier] = []
		for affix: StatModifier in gear.affixes:
			if StatModifierFormatter.format(affix) != "":
				chaos_affixes.append(affix)
		_add_affix_group_labels(vbox, "Stats:", chaos_affixes, gear, default_color)
		return
	var positive_affixes: Array[StatModifier] = []
	var drawback_affixes: Array[StatModifier] = []
	var special_affixes: Array[StatModifier] = []
	for affix: StatModifier in gear.affixes:
		var formatted := StatModifierFormatter.format(affix)
		if formatted == "":
			continue
		var stat_id := StatCatalog.canonical_id_for_modifier(affix)
		if affix.is_drawback:
			drawback_affixes.append(affix)
		elif stat_id != "" and StatCatalog.is_special(stat_id):
			special_affixes.append(affix)
		else:
			positive_affixes.append(affix)
	positive_affixes.sort_custom(_sort_affixes_for_display)
	drawback_affixes.sort_custom(_sort_affixes_for_display)
	special_affixes.sort_custom(_sort_affixes_for_display)
	_add_affix_group_labels(vbox, "Stats:", positive_affixes, gear, default_color)
	_add_affix_group_labels(vbox, "Drawbacks:", drawback_affixes, gear, default_color)
	_add_affix_group_labels(vbox, "Special:", special_affixes, gear, default_color)
	for trigger in gear.triggered_skill_effects:
		if trigger != null and trigger.skill != null:
			_add_plain_tooltip_label(vbox, "%d%% chance to trigger %s" % [roundi(trigger.chance * 100.0), trigger.skill.display_name], default_color)


static func _add_affix_group_labels(vbox: VBoxContainer, heading: String, affixes: Array, gear: GearItem, default_color: Color) -> void:
	if affixes.is_empty():
		return
	_add_plain_tooltip_label(vbox, heading, default_color)
	for affix: StatModifier in affixes:
		var line := LegendaryCatalog.stat_text(affix) if gear.tier == GearItem.Tier.LEGENDARY else StatModifierFormatter.format(affix)
		if line == "":
			continue
		_add_rich_tooltip_label(vbox, _bbcode_for_affix_line(gear, affix, line), line, default_color, _font_size_for_affix_line(gear, affix))


static func _add_plain_tooltip_label(vbox: VBoxContainer, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = _rich_tooltip_line_width(text)
	label.add_theme_font_override("font", DATA_FONT)
	label.add_theme_font_size_override("font_size", TOOLTIP_RICH_FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	vbox.add_child(label)


static func _add_rich_tooltip_label(vbox: VBoxContainer, bbcode: String, visible_text: String, color: Color, font_size: int = TOOLTIP_RICH_FONT_SIZE) -> void:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(_rich_tooltip_line_width(visible_text, font_size), 0)
	label.text = bbcode
	label.add_theme_font_override("normal_font", DATA_FONT)
	label.add_theme_font_size_override("normal_font_size", font_size)
	label.add_theme_color_override("default_color", color)
	vbox.add_child(label)


static func _add_extra_tooltip_body_lines(vbox: VBoxContainer, body: String, gear: GearItem, color: Color) -> void:
	var base_lines := "\n".join(gear_tooltip_lines(gear)).split("\n", false)
	var body_lines := body.split("\n", false)
	for i in range(base_lines.size(), body_lines.size()):
		var line := String(body_lines[i])
		if line != "":
			_add_plain_tooltip_label(vbox, line, color)


static func _rich_tooltip_line_width(visible_text: String, font_size: int = TOOLTIP_RICH_FONT_SIZE) -> float:
	var measured := DATA_FONT.get_string_size(visible_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	return minf(ceilf(measured) + 4.0, TOOLTIP_RICH_MAX_WIDTH)


static func _bbcode_for_affix_line(gear: GearItem, affix: StatModifier, line: String) -> String:
	var color := _stat_color_for_affix(affix)
	var escaped := _escape_bbcode(line)
	var colored := "[color=#%s]%s[/color]" % [color.to_html(false), escaped]
	if is_max_value_roll(gear, affix):
		return "[font_size=%d][b]%s[/b][/font_size]" % [TOOLTIP_RICH_MAX_ROLL_FONT_SIZE, colored]
	return colored


static func _font_size_for_affix_line(gear: GearItem, affix: StatModifier) -> int:
	return TOOLTIP_RICH_MAX_ROLL_FONT_SIZE if is_max_value_roll(gear, affix) else TOOLTIP_RICH_FONT_SIZE


static func _stat_color_for_affix(affix: StatModifier) -> Color:
	if affix == null:
		return UIColors.TEXT_NORMAL
	if affix.is_drawback:
		return STAT_COLOR_DRAWBACK
	var stat_id := StatCatalog.canonical_id_for_modifier(affix)
	if StatCatalog.is_special(stat_id):
		return STAT_COLOR_SPECIAL
	if affix.category == StatModifier.StatCategory.RARE:
		return STAT_COLOR_RARE
	return STAT_COLOR_BASIC


static func is_max_value_roll(gear: GearItem, affix: StatModifier) -> bool:
	if gear == null or affix == null or StatCatalog.is_binary(StatCatalog.canonical_id_for_modifier(affix)):
		return false
	var stat_id := StatCatalog.canonical_id_for_modifier(affix)
	var category := _catalog_category_for_affix(affix)
	var result := GearGenerator.max_rolled_value_for_stat_id(
		stat_id,
		gear.slot,
		affix.is_drawback,
		gear.tier,
		gear.generation_value_scale,
		gear.generation_contract_depth,
		category
	)
	return bool(result.get("ok", false)) and is_equal_approx(float(result["value"]), affix.value)


static func _catalog_category_for_affix(affix: StatModifier) -> String:
	if affix == null:
		return StatCatalog.CATEGORY_BASIC
	match affix.category:
		StatModifier.StatCategory.RARE:
			return StatCatalog.CATEGORY_RARE
		StatModifier.StatCategory.SPECIAL:
			return StatCatalog.CATEGORY_SPECIAL
	return StatCatalog.CATEGORY_BASIC


static func _escape_bbcode(text: String) -> String:
	return text.replace("[", "\\[").replace("]", "\\]")


## Tier-colored button stylebox for a shop/reward gear box, muted when
## unaffordable/unstorable (Button.disabled == true) so "can't afford" reads
## without opening the tooltip. Shared by combat_screen.gd's reward-choice
## boxes and shop_overlay.gd's shop-offer boxes.
static func style_shop_item_box(button: Button, offer: GearItem) -> void:
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, make_gear_item_stylebox(offer, false, state))


static func make_pixel_icon(texture: Texture2D, icon_size: Vector2 = SUBCLASS_ICON_SIZE) -> TextureRect:
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = texture
	icon.custom_minimum_size = icon_size
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


static func talent_point_icon() -> Texture2D:
	if _talent_point_icon != null:
		return _talent_point_icon
	_talent_point_icon = load(TALENT_POINT_ICON_PATH) as Texture2D
	return _talent_point_icon


static func configure_icon_button(button: Button, texture: Texture2D, separation: int = 8) -> void:
	button.icon = texture
	button.expand_icon = false
	button.add_theme_constant_override("h_separation", separation)


static func pulse_blocked_control(control: Control, meta_key: String = "feedback_blocked_pulse") -> void:
	if control == null or not control.is_inside_tree():
		return
	control.set_meta(meta_key, true)
	control.pivot_offset = control.size * 0.5
	var original_scale := control.scale
	var original_modulate := control.modulate
	control.modulate = UIColors.FEEDBACK_BLOCKED
	var tween := control.create_tween()
	tween.tween_property(control, "scale", Vector2(1.06, 1.06), 0.08)
	tween.parallel().tween_property(control, "modulate", UIColors.FEEDBACK_BLOCKED, 0.08)
	tween.tween_property(control, "scale", original_scale, 0.18)
	tween.parallel().tween_property(control, "modulate", original_modulate, 0.18)


static func make_icon_label_row(texture: Texture2D, text: String, icon_size: Vector2 = UI_ICON_SIZE) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	row.add_child(make_pixel_icon(texture, icon_size))

	var label := Label.new()
	label.name = "Label"
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	return row


## The selection-card layout used by class/subclass select (large title,
## small descriptive text, action button below) -- shared so
## combat_screen.gd's secondary Rogue tree chooser matches the primary
## subclass select screen exactly instead of approximating it.
static func make_selection_card(title_text: String, body_text: String, action_button: Button, card_width: int = SELECTION_CARD_WIDTH, icon_texture: Texture2D = null) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(card_width, 0)
	card.add_theme_stylebox_override("panel", make_stylebox())

	var card_vbox := VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 10)
	card.add_child(card_vbox)

	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 8)
	card_vbox.add_child(title_row)

	if icon_texture != null:
		title_row.add_child(make_pixel_icon(icon_texture))

	var title_label := Label.new()
	title_label.name = "Title"
	title_label.text = title_text
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.theme_type_variation = &"PanelHeader"
	title_label.add_theme_font_size_override("font_size", SELECTION_CARD_TITLE_FONT_SIZE)
	title_row.add_child(title_label)

	var body_label := Label.new()
	body_label.text = body_text
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	body_label.add_theme_font_size_override("font_size", SELECTION_CARD_BODY_FONT_SIZE)
	card_vbox.add_child(body_label)

	card_vbox.add_child(action_button)
	return card
