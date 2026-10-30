extends PanelContainer
## Combat dashboard panel: gear, split into an Equipment paper doll and an
## earned inventory grid per the user's mockup.
##
## Equipment doll layout: hood (top), doublet (center, largest), dagger
## (left), gloves below dagger, pants below doublet, necklace above ring.
## These are the seven universal
## equipment slots, filled by rewards/shop inventory decisions.
## Slots render as gray boxes when empty and tier-treated when filled. Hovering
## a slot shows its name, or the item's name and stats.
##
## Inventory contains up to three items bought from the shop or earned from
## rewards. Primary clicks move gear between inventory and equipment; right-
## click action menus expose shop-gated selling.

const CARD_TITLE_FONT_SIZE := 20
const SECTION_LABEL_FONT_SIZE := 15
const GOLD_FONT_SIZE := 28
const GOLD_GHOST_DURATION_SEC := 0.28
const GOLD_GHOST_ARC_HEIGHT := 26.0
const GOLD_REWARD_SETTLE_SEC := 0.22

const HELM_SLOT_SIZE := Vector2(76, 76)
const ARMOR_SLOT_SIZE := Vector2(112, 112)
const WEAPON_SLOT_SIZE := Vector2(88, 88)
const SMALL_SLOT_SIZE := Vector2(60, 60)
const LEGS_SLOT_SIZE := Vector2(88, 88)
const HANDS_SLOT_SIZE := Vector2(68, 68)
const INVENTORY_SLOT_SIZE := Vector2(88, 88)
const ACTION_EQUIP_ID := 1
const ACTION_SELL_ID := 2
const ACTION_UNEQUIP_ID := 3
const ACTION_DESTROY_ID := 4
const GEAR_GHOST_DURATION_SEC := 0.24
const GEAR_GHOST_ARC_HEIGHT := 34.0
const GEAR_LANDING_PULSE_SEC := 0.22
const GOLD_ICON := preload("res://assets/ui/icons/gold.png")
const GearTooltipPanelScript := preload("res://scripts/ui/gear_tooltip_panel.gd")

const EMPTY_SLOT_COLOR := UIColors.SLOT_EMPTY
const SLOT_BORDER_COLOR := UIColors.SLOT_BORDER
var _helm_slot: Panel
var _armor_slot: Panel
var _weapon_slot: Panel
var _trinket_slot: Panel
var _charm_slot: Panel
var _legs_slot: Panel
var _hands_slot: Panel
var _inventory_grid: GridContainer
var _gold_badge: PanelContainer
var _gold_row: HBoxContainer
var _gold_icon: TextureRect
var _gold_label: Label
var _sell_dialog: ConfirmationDialog
var _destroy_dialog: ConfirmationDialog
var _inventory_action_menu: PopupMenu
var _equipped_action_menu: PopupMenu
var _pending_inventory_action_item: GearItem = null
var _pending_equipped_action_slot: int = -1
var _pending_sell_inventory_item: GearItem = null
var _pending_sell_equipped_slot: int = -1
var _pending_destroy_inventory_item: GearItem = null
var _pending_destroy_equipped_slot: int = -1


func _ready() -> void:
	add_theme_stylebox_override("panel", CardStyle.make_stylebox())

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(content)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	content.add_child(header)

	var title := Label.new()
	title.text = "Gear"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.theme_type_variation = &"PanelHeader"
	title.add_theme_font_size_override("font_size", CARD_TITLE_FONT_SIZE)
	header.add_child(title)

	_gold_badge = PanelContainer.new()
	_gold_badge.tooltip_text = "Gold stash"
	_gold_badge.size_flags_horizontal = Control.SIZE_SHRINK_END
	var gold_badge_style := CardStyle.make_action_button_stylebox(UIColors.PANEL_DEEP, UIColors.PANEL_BORDER, "normal")
	gold_badge_style.content_margin_left = 8
	gold_badge_style.content_margin_right = 10
	gold_badge_style.content_margin_top = 4
	gold_badge_style.content_margin_bottom = 6
	_gold_badge.add_theme_stylebox_override("panel", gold_badge_style)
	header.add_child(_gold_badge)

	_gold_row = HBoxContainer.new()
	_gold_row.alignment = BoxContainer.ALIGNMENT_END
	_gold_row.add_theme_constant_override("separation", 7)
	_gold_row.tooltip_text = "Gold stash"
	_gold_badge.add_child(_gold_row)

	_gold_icon = CardStyle.make_pixel_icon(GOLD_ICON, Vector2(34, 34))
	_gold_row.add_child(_gold_icon)
	_gold_label = Label.new()
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_gold_label.add_theme_color_override("font_color", UIColors.TEXT_GOLD)
	_gold_label.add_theme_color_override("font_outline_color", UIColors.TEXT_OUTLINE)
	_gold_label.add_theme_constant_override("outline_size", 4)
	_gold_label.add_theme_font_size_override("font_size", GOLD_FONT_SIZE)
	_gold_row.add_child(_gold_label)

	var equipment_label := Label.new()
	equipment_label.text = "Equipment"
	equipment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	equipment_label.add_theme_font_size_override("font_size", SECTION_LABEL_FONT_SIZE)
	content.add_child(equipment_label)

	var doll := _build_doll()
	doll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(doll)

	var inventory_label := Label.new()
	inventory_label.text = "Inventory"
	inventory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inventory_label.add_theme_font_size_override("font_size", SECTION_LABEL_FONT_SIZE)
	content.add_child(inventory_label)


	var inventory := PanelContainer.new()
	inventory.custom_minimum_size = Vector2(0, 120)
	inventory.tooltip_text = "Inventory -- storage for unequipped gear"
	var inventory_style := CardStyle.make_stylebox(8)
	inventory_style.bg_color = UIColors.PANEL_DEEP
	inventory.add_theme_stylebox_override("panel", inventory_style)
	content.add_child(inventory)

	var inventory_margin := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		inventory_margin.add_theme_constant_override(side, 8)
	inventory.add_child(inventory_margin)

	_inventory_grid = GridContainer.new()
	_inventory_grid.columns = 3
	_inventory_grid.add_theme_constant_override("h_separation", 8)
	_inventory_grid.add_theme_constant_override("v_separation", 8)
	_inventory_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_margin.add_child(_inventory_grid)

	BuildState.build_changed.connect(_refresh)
	if BuildState.has_signal("stats_preview_changed"):
		BuildState.stats_preview_changed.connect(_refresh)
	_build_sell_dialog()
	_build_destroy_dialog()
	_build_inventory_action_menu()
	_build_equipped_action_menu()
	_refresh()


## Seven-slot arrangement shared with Practice: weapon/gloves on the left,
## helm/chest/pants in the center, charm/trinket on the right.
func _build_doll() -> HBoxContainer:
	var doll := HBoxContainer.new()
	doll.alignment = BoxContainer.ALIGNMENT_CENTER
	doll.add_theme_constant_override("separation", 10)
	var left := VBoxContainer.new()
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_theme_constant_override("separation", 8)
	doll.add_child(left)
	_weapon_slot = _make_slot(WEAPON_SLOT_SIZE, GearItem.SlotType.WEAPON)
	_hands_slot = _make_slot(HANDS_SLOT_SIZE, GearItem.SlotType.HANDS)
	left.add_child(_weapon_slot)
	left.add_child(_hands_slot)
	var center := VBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 8)
	doll.add_child(center)
	_helm_slot = _make_slot(HELM_SLOT_SIZE, GearItem.SlotType.HELM)
	_armor_slot = _make_slot(ARMOR_SLOT_SIZE, GearItem.SlotType.ARMOR)
	_legs_slot = _make_slot(LEGS_SLOT_SIZE, GearItem.SlotType.LEGS)
	center.add_child(_helm_slot)
	center.add_child(_armor_slot)
	center.add_child(_legs_slot)
	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 6)
	doll.add_child(right)
	_charm_slot = _make_slot(SMALL_SLOT_SIZE, GearItem.SlotType.CHARM)
	_trinket_slot = _make_slot(SMALL_SLOT_SIZE, GearItem.SlotType.TRINKET)
	right.add_child(_charm_slot)
	right.add_child(_trinket_slot)
	return doll


func _make_slot(slot_size: Vector2, gear_slot: int) -> Panel:
	var slot: Panel = GearTooltipPanelScript.new()
	slot.custom_minimum_size = slot_size
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot.mouse_filter = Control.MOUSE_FILTER_STOP

	var slot_background := TextureRect.new()
	slot_background.name = "SlotTypeBackground"
	slot_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	slot_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot_background.texture = GearIcons.slot_background_for(gear_slot)
	slot_background.modulate = Color(1, 1, 1, 0.46)
	slot_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	if gear_slot in [GearItem.SlotType.LEGS, GearItem.SlotType.HANDS]:
		slot_background.offset_left = 4
		slot_background.offset_top = 4
		slot_background.offset_right = -4
		slot_background.offset_bottom = -4
	slot.add_child(slot_background)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Nearest-neighbor keeps the 32x32 pixel art crisp when scaled up to fill
	# the slot, instead of blurring like the project's photographic
	# backgrounds (which use the default linear filter).
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	if gear_slot in [GearItem.SlotType.LEGS, GearItem.SlotType.HANDS]:
		icon.offset_left = 4
		icon.offset_top = 4
		icon.offset_right = -4
		icon.offset_bottom = -4
	slot.add_child(icon)
	return slot


func _refresh() -> void:
	_gold_label.text = "%dg" % BuildState.gold
	_update_slot(_helm_slot, "Hood", BuildState.equipped_helm)
	_update_slot(_armor_slot, "Doublet", BuildState.equipped_armor)
	_update_slot(_weapon_slot, "Dagger", BuildState.equipped_weapon)
	_update_slot(_charm_slot, "Necklace", BuildState.equipped_charm)
	_update_slot(_trinket_slot, "Ring", BuildState.equipped_trinket)
	_update_slot(_legs_slot, "Pants", BuildState.equipped_legs)
	_update_slot(_hands_slot, "Gloves", BuildState.equipped_hands)
	_refresh_inventory()


func _refresh_inventory() -> void:
	for child in _inventory_grid.get_children():
		child.queue_free()
	for index in BuildState.INVENTORY_CAPACITY:
		var gear: GearItem = BuildState.inventory[index] if index < BuildState.inventory.size() else null
		_inventory_grid.add_child(_make_inventory_slot(gear))


func _make_inventory_slot(gear: GearItem) -> Button:
	var slot: Button = GearCompareButton.new() if gear != null else Button.new()
	slot.custom_minimum_size = INVENTORY_SLOT_SIZE
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.focus_mode = Control.FOCUS_NONE
	slot.text = ""
	_style_box_button(slot, gear)
	if gear == null:
		slot.disabled = true
		slot.tooltip_text = "Empty inventory slot"
	else:
		# Icon + slot/tier caption, same box content the shop item boxes
		# carry (shared via CardStyle rather than duplicated -- P2:R7 second
		# playtest-feedback pass, item 2; art added in the P2:R7 gear-art
		# pass).
		CardStyle.build_gear_box_content(slot, gear)
		slot.set_meta("gear_item", gear)
		slot.tooltip_text = _inventory_tooltip(gear)
		var compare_slot := slot as GearCompareButton
		compare_slot.tooltip_builder = func() -> Control:
			return CardStyle.build_gear_compare_tooltip(
				self,
				_inventory_tooltip(gear),
				BuildState.equipped_item_for_slot(gear.slot),
				gear
			)
		slot.pressed.connect(_on_inventory_slot_pressed.bind(gear, slot))
		slot.gui_input.connect(_on_inventory_slot_gui_input.bind(gear))
	return slot


func _on_inventory_slot_pressed(gear: GearItem, source_slot: Control = null) -> void:
	_equip_from_inventory_with_animation(gear, source_slot)


func _on_inventory_slot_gui_input(event: InputEvent, gear: GearItem) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT):
		return
	_show_inventory_action_menu(gear)


func _build_inventory_action_menu() -> void:
	_inventory_action_menu = PopupMenu.new()
	_inventory_action_menu.add_item("Equip", ACTION_EQUIP_ID)
	_inventory_action_menu.add_item("Sell", ACTION_SELL_ID)
	_inventory_action_menu.add_item("Destroy", ACTION_DESTROY_ID)
	_inventory_action_menu.id_pressed.connect(_on_inventory_action_selected)
	add_child(_inventory_action_menu)


func _show_inventory_action_menu(gear: GearItem) -> void:
	if gear == null:
		return
	_pending_inventory_action_item = gear
	_inventory_action_menu.set_item_disabled(_inventory_action_menu.get_item_index(ACTION_EQUIP_ID), BuildState.build_locked)
	_inventory_action_menu.set_item_disabled(_inventory_action_menu.get_item_index(ACTION_DESTROY_ID), BuildState.build_locked)
	_inventory_action_menu.set_item_text(_inventory_action_menu.get_item_index(ACTION_SELL_ID), _sell_action_text(gear))
	_inventory_action_menu.set_item_disabled(_inventory_action_menu.get_item_index(ACTION_SELL_ID), not BuildState.shop_round_pending or BuildState.build_locked)
	_inventory_action_menu.position = Vector2i(get_viewport().get_mouse_position())
	_inventory_action_menu.popup()


func _on_inventory_action_selected(action_id: int) -> void:
	if BuildState.build_locked:
		return
	var gear := _pending_inventory_action_item
	_pending_inventory_action_item = null
	if gear == null:
		return
	match action_id:
		ACTION_EQUIP_ID:
			_equip_from_inventory_with_animation(gear, _inventory_button_for_item(gear))
		ACTION_SELL_ID:
			if BuildState.shop_round_pending:
				_confirm_sell_inventory_item(gear)
		ACTION_DESTROY_ID:
			_confirm_destroy_inventory_item(gear)


func _build_equipped_action_menu() -> void:
	_equipped_action_menu = PopupMenu.new()
	_equipped_action_menu.add_item("Unequip", ACTION_UNEQUIP_ID)
	_equipped_action_menu.add_item("Sell", ACTION_SELL_ID)
	_equipped_action_menu.add_item("Destroy", ACTION_DESTROY_ID)
	_equipped_action_menu.id_pressed.connect(_on_equipped_action_selected)
	add_child(_equipped_action_menu)


func _show_equipped_action_menu(gear_slot: GearItem.SlotType) -> void:
	var gear := BuildState.equipped_item_for_slot(gear_slot)
	if gear == null:
		return
	_pending_equipped_action_slot = gear_slot
	_equipped_action_menu.set_item_disabled(_equipped_action_menu.get_item_index(ACTION_DESTROY_ID), BuildState.build_locked)
	_equipped_action_menu.set_item_text(_equipped_action_menu.get_item_index(ACTION_SELL_ID), _sell_action_text(gear))
	_equipped_action_menu.set_item_disabled(_equipped_action_menu.get_item_index(ACTION_UNEQUIP_ID), not _can_unequip_to_inventory())
	_equipped_action_menu.set_item_tooltip(_equipped_action_menu.get_item_index(ACTION_UNEQUIP_ID), "Inventory full -- make space first." if not _can_unequip_to_inventory() else "Move this item to inventory.")
	_equipped_action_menu.set_item_disabled(_equipped_action_menu.get_item_index(ACTION_SELL_ID), not BuildState.shop_round_pending or BuildState.build_locked)
	_equipped_action_menu.position = Vector2i(get_viewport().get_mouse_position())
	_equipped_action_menu.popup()


func _on_equipped_action_selected(action_id: int) -> void:
	if BuildState.build_locked:
		return
	var gear_slot := _pending_equipped_action_slot
	_pending_equipped_action_slot = -1
	if gear_slot == -1:
		return
	match action_id:
		ACTION_UNEQUIP_ID:
			_unequip_to_inventory_with_animation(gear_slot)
		ACTION_SELL_ID:
			if BuildState.shop_round_pending:
				_confirm_sell_equipped_item(gear_slot)
		ACTION_DESTROY_ID:
			_confirm_destroy_equipped_item(gear_slot)


func _build_sell_dialog() -> void:
	_sell_dialog = ConfirmationDialog.new()
	_sell_dialog.title = "Sell Gear"
	_sell_dialog.confirmed.connect(_on_sell_confirmed)
	add_child(_sell_dialog)


func _build_destroy_dialog() -> void:
	_destroy_dialog = ConfirmationDialog.new()
	_destroy_dialog.title = "Destroy Gear"
	_destroy_dialog.confirmed.connect(_on_destroy_confirmed)
	add_child(_destroy_dialog)


func _confirm_sell_inventory_item(gear: GearItem) -> void:
	_pending_sell_inventory_item = gear
	_pending_sell_equipped_slot = -1
	_sell_dialog.dialog_text = "Sell %s for %dg?" % [gear.display_name, BuildState.sell_value_for(gear)]
	_sell_dialog.popup_centered()


func _confirm_sell_equipped_item(slot: GearItem.SlotType) -> void:
	var gear: GearItem = BuildState.equipped_item_for_slot(slot)
	if gear == null:
		return
	_pending_sell_inventory_item = null
	_pending_sell_equipped_slot = slot
	_sell_dialog.dialog_text = "Sell equipped %s for %dg?" % [gear.display_name, BuildState.sell_value_for(gear)]
	_sell_dialog.popup_centered()


func _confirm_destroy_inventory_item(gear: GearItem) -> void:
	if gear == null:
		return
	_pending_destroy_inventory_item = gear
	_pending_destroy_equipped_slot = -1
	_destroy_dialog.dialog_text = "Destroy %s? This cannot be undone." % gear.display_name
	_destroy_dialog.popup_centered()


func _confirm_destroy_equipped_item(slot: GearItem.SlotType) -> void:
	var gear: GearItem = BuildState.equipped_item_for_slot(slot)
	if gear == null:
		return
	_pending_destroy_inventory_item = null
	_pending_destroy_equipped_slot = slot
	_destroy_dialog.dialog_text = "Destroy equipped %s? This cannot be undone." % gear.display_name
	_destroy_dialog.popup_centered()


func _on_sell_confirmed() -> void:
	if BuildState.build_locked or not BuildState.shop_round_pending:
		return
	var sold_gear: GearItem = null
	var source_rect := Rect2()
	var sale_value := 0
	var sold := false
	if _pending_sell_inventory_item != null:
		sold_gear = _pending_sell_inventory_item
		sale_value = BuildState.sell_value_for(sold_gear)
		source_rect = _global_rect_for(_inventory_button_for_item(_pending_sell_inventory_item))
		sold = BuildState.sell_inventory_item(_pending_sell_inventory_item)
	elif _pending_sell_equipped_slot != -1:
		sold_gear = BuildState.equipped_item_for_slot(_pending_sell_equipped_slot)
		sale_value = BuildState.sell_value_for(sold_gear)
		source_rect = _global_rect_for(_equipped_panel_for_slot(_pending_sell_equipped_slot))
		sold = BuildState.sell_equipped_item(_pending_sell_equipped_slot)
	_pending_sell_inventory_item = null
	_pending_sell_equipped_slot = -1
	_sell_dialog.hide()
	if sold:
		var audio_manager := get_node_or_null("/root/AudioManager")
		if audio_manager != null and audio_manager.has_method("play_shop_change_sfx"):
			audio_manager.play_shop_change_sfx()
	if sold_gear != null and sold:
		await animate_gold_from_rect(source_rect, sale_value)


func _on_destroy_confirmed() -> void:
	if BuildState.build_locked:
		return
	var destroyed := false
	if _pending_destroy_inventory_item != null:
		destroyed = BuildState.destroy_inventory_item(_pending_destroy_inventory_item)
	elif _pending_destroy_equipped_slot != -1:
		destroyed = BuildState.destroy_equipped_item(_pending_destroy_equipped_slot)
	_pending_destroy_inventory_item = null
	_pending_destroy_equipped_slot = -1
	_destroy_dialog.hide()
	if destroyed:
		var audio_manager := get_node_or_null("/root/AudioManager")
		if audio_manager != null and audio_manager.has_method("play_shop_change_sfx"):
			audio_manager.play_shop_change_sfx()


## Equipped slots use a thicker accent-colored border (vs. the neutral
## SLOT_BORDER_COLOR on empty slots and inventory items) so "this is worn"
## reads as visually distinct from "this is in the bag," per the task's
## equipped-vs-inventory clarity requirement -- inventory slots keep the
## plain border via _style_box_button() below.
func _update_slot(slot: Panel, slot_name: String, gear: GearItem) -> void:
	var style := CardStyle.make_gear_item_stylebox(gear, gear != null)
	slot.add_theme_stylebox_override("panel", style)
	(slot.get_node("Icon") as TextureRect).texture = GearIcons.icon_for(gear)
	(slot.get_node("SlotTypeBackground") as TextureRect).modulate = Color(1, 1, 1, 0.28 if gear != null else 0.56)

	if gear == null:
		slot.tooltip_text = "%s: Empty" % slot_name
		if slot.get_script() == GearTooltipPanelScript:
			slot.set("tooltip_builder", Callable())
		return
	slot.tooltip_text = _equipped_tooltip(gear)
	if slot.get_script() == GearTooltipPanelScript:
		slot.set("tooltip_builder", func() -> Control:
			return CardStyle.build_gear_tooltip(self, gear)
		)
	if slot == _weapon_slot:
		_connect_equipped_slot_click(slot, GearItem.SlotType.WEAPON)
	elif slot == _helm_slot:
		_connect_equipped_slot_click(slot, GearItem.SlotType.HELM)
	elif slot == _armor_slot:
		_connect_equipped_slot_click(slot, GearItem.SlotType.ARMOR)
	elif slot == _trinket_slot:
		_connect_equipped_slot_click(slot, GearItem.SlotType.TRINKET)
	elif slot == _charm_slot:
		_connect_equipped_slot_click(slot, GearItem.SlotType.CHARM)

	elif slot == _legs_slot:
		_connect_equipped_slot_click(slot, GearItem.SlotType.LEGS)
	elif slot == _hands_slot:
		_connect_equipped_slot_click(slot, GearItem.SlotType.HANDS)


func _connect_equipped_slot_click(slot: Panel, gear_slot: GearItem.SlotType) -> void:
	if not slot.has_meta("sell_click_connected"):
		slot.gui_input.connect(_on_equipped_slot_gui_input.bind(gear_slot))
		slot.set_meta("sell_click_connected", true)


## Left-clicking equipped gear sends it back to inventory. Right-clicking
## opens the explicit action menu, where selling stays shop-gated behind the
## existing confirmation dialog.
func _on_equipped_slot_gui_input(event: InputEvent, gear_slot: GearItem.SlotType) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			_unequip_to_inventory_with_animation(gear_slot)
		MOUSE_BUTTON_RIGHT:
			_show_equipped_action_menu(gear_slot)


func _can_unequip_to_inventory() -> bool:
	return not BuildState.build_locked and BuildState.can_add_inventory_item()


func _unequip_to_inventory(gear_slot: GearItem.SlotType) -> void:
	if _can_unequip_to_inventory():
		BuildState.unequip(gear_slot)


func animate_gain_from_source(gear: GearItem, source: Control) -> void:
	if gear == null:
		return
	var source_rect := _global_rect_for(source)
	await get_tree().process_frame
	var destination := _destination_control_for_item(gear)
	_play_gear_motion(gear, source_rect, _global_rect_for(destination))
	_pulse_slot(destination)


func animate_gold_from_source(source: Control, amount: int) -> void:
	await animate_gold_from_rect(_global_rect_for(source), amount)


func animate_gold_from_rect(source_rect: Rect2, amount: int, wait_for_completion: bool = false) -> void:
	if amount <= 0:
		return
	await get_tree().process_frame
	var played := _play_gold_motion(source_rect, _global_rect_for(_gold_icon), amount, "+")
	_pulse_slot(_gold_badge)
	if wait_for_completion and played:
		await get_tree().create_timer(GOLD_GHOST_DURATION_SEC).timeout
		await get_tree().create_timer(GOLD_REWARD_SETTLE_SEC).timeout


func animate_gold_to_rect(destination_rect: Rect2, amount: int, wait_for_completion: bool = false) -> void:
	if amount <= 0:
		return
	await get_tree().process_frame
	var played := _play_gold_motion(_global_rect_for(_gold_icon), destination_rect, amount, "-")
	_pulse_slot(_gold_badge)
	if wait_for_completion and played:
		await get_tree().create_timer(GOLD_GHOST_DURATION_SEC).timeout


func _equip_from_inventory_with_animation(gear: GearItem, source_slot: Control = null) -> void:
	if BuildState.build_locked or gear == null or not BuildState.has_inventory_item(gear):
		return
	var target_slot := _equipped_panel_for_slot(gear.slot)
	var source_rect := _global_rect_for(source_slot if source_slot != null else _inventory_button_for_item(gear))
	var target_rect := _global_rect_for(target_slot)
	var replaced: GearItem = BuildState.equipped_item_for_slot(gear.slot)
	var replaced_source_rect := target_rect
	if not BuildState.equip_from_inventory(gear):
		return
	await get_tree().process_frame
	_play_gear_motion(gear, source_rect, _global_rect_for(target_slot))
	_pulse_slot(target_slot)
	if replaced != null and replaced != gear:
		var replaced_destination := _inventory_button_for_item(replaced)
		_play_gear_motion(replaced, replaced_source_rect, _global_rect_for(replaced_destination))
		_pulse_slot(replaced_destination)


func _unequip_to_inventory_with_animation(gear_slot: GearItem.SlotType) -> void:
	if not _can_unequip_to_inventory():
		return
	var gear: GearItem = BuildState.equipped_item_for_slot(gear_slot)
	if gear == null:
		return
	var source_slot := _equipped_panel_for_slot(gear_slot)
	var source_rect := _global_rect_for(source_slot)
	BuildState.unequip(gear_slot)
	await get_tree().process_frame
	var destination_slot := _inventory_button_for_item(gear)
	_play_gear_motion(gear, source_rect, _global_rect_for(destination_slot))
	_pulse_slot(destination_slot)


func _inventory_button_for_item(gear: GearItem) -> Button:
	if gear == null:
		return null
	for child in _inventory_grid.get_children():
		if child is Button and not child.is_queued_for_deletion() and child.has_meta("gear_item") and child.get_meta("gear_item") == gear:
			return child
	return null


func _destination_control_for_item(gear: GearItem) -> Control:
	var inventory_button := _inventory_button_for_item(gear)
	if inventory_button != null:
		return inventory_button
	if BuildState.equipped_item_for_slot(gear.slot) == gear:
		return _equipped_panel_for_slot(gear.slot)
	return null


func _equipped_panel_for_slot(gear_slot: GearItem.SlotType) -> Panel:
	match gear_slot:
		GearItem.SlotType.WEAPON:
			return _weapon_slot
		GearItem.SlotType.HELM:
			return _helm_slot
		GearItem.SlotType.ARMOR:
			return _armor_slot
		GearItem.SlotType.TRINKET:
			return _trinket_slot
		GearItem.SlotType.CHARM:
			return _charm_slot
		GearItem.SlotType.LEGS:
			return _legs_slot
		GearItem.SlotType.HANDS:
			return _hands_slot
	return null


func _global_rect_for(node: Control) -> Rect2:
	if node == null or not node.is_inside_tree():
		return Rect2()
	return node.get_global_rect()


func _play_gear_motion(gear: GearItem, from_rect: Rect2, to_rect: Rect2) -> void:
	if gear == null or from_rect.size == Vector2.ZERO or to_rect.size == Vector2.ZERO:
		return
	var ghost := Button.new()
	ghost.text = ""
	ghost.disabled = true
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.custom_minimum_size = from_rect.size
	ghost.size = from_rect.size
	ghost.modulate = Color(1, 1, 1, 0.72)
	ghost.z_index = 200
	ghost.top_level = true
	_style_box_button(ghost, gear)
	CardStyle.build_gear_box_content(ghost, gear)
	add_child(ghost)
	ghost.global_position = from_rect.position

	var midpoint := (from_rect.position + to_rect.position) * 0.5 + Vector2(0, -GEAR_GHOST_ARC_HEIGHT)
	var motion := func(t: float) -> void:
		if is_instance_valid(ghost):
			ghost.global_position = _quadratic_bezier(from_rect.position, midpoint, to_rect.position, t)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_method(motion, 0.0, 1.0, GEAR_GHOST_DURATION_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "scale", Vector2(0.9, 0.9), GEAR_GHOST_DURATION_SEC).from(Vector2(1.04, 1.04))
	tween.tween_property(ghost, "modulate:a", 0.0, GEAR_GHOST_DURATION_SEC).from(0.72).set_delay(GEAR_GHOST_DURATION_SEC * 0.55)
	tween.set_parallel(false)
	tween.tween_callback(func() -> void:
		if is_instance_valid(ghost):
			ghost.queue_free()
	)


func _play_gold_motion(from_rect: Rect2, to_rect: Rect2, amount: int, sign: String = "+") -> bool:
	if from_rect.size == Vector2.ZERO or to_rect.size == Vector2.ZERO:
		return false
	var ghost := HBoxContainer.new()
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.modulate = Color(1, 1, 1, 0.86)
	ghost.z_index = 220
	ghost.top_level = true
	ghost.add_theme_constant_override("separation", 4)
	ghost.add_child(CardStyle.make_pixel_icon(GOLD_ICON, Vector2(20, 20)))
	var label := Label.new()
	label.text = "%s%dg" % [sign, amount]
	label.add_theme_color_override("font_color", UIColors.TEXT_GOLD)
	label.add_theme_color_override("font_outline_color", UIColors.TEXT_OUTLINE)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_font_size_override("font_size", 18)
	ghost.add_child(label)
	add_child(ghost)
	ghost.global_position = from_rect.get_center() - Vector2(18, 12)

	var target := to_rect.get_center() - Vector2(18, 12)
	var midpoint := (ghost.global_position + target) * 0.5 + Vector2(0, -GOLD_GHOST_ARC_HEIGHT)
	var start := ghost.global_position
	var motion := func(t: float) -> void:
		if is_instance_valid(ghost):
			ghost.global_position = _quadratic_bezier(start, midpoint, target, t)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_method(motion, 0.0, 1.0, GOLD_GHOST_DURATION_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "scale", Vector2(0.85, 0.85), GOLD_GHOST_DURATION_SEC).from(Vector2(1.12, 1.12))
	tween.tween_property(ghost, "modulate:a", 0.0, GOLD_GHOST_DURATION_SEC).from(0.86).set_delay(GOLD_GHOST_DURATION_SEC * 0.58)
	tween.set_parallel(false)
	tween.tween_callback(func() -> void:
		if is_instance_valid(ghost):
			ghost.queue_free()
	)
	return true


func _pulse_slot(slot: Control) -> void:
	if slot == null or not slot.is_inside_tree():
		return
	var original_modulate := slot.modulate
	slot.modulate = UIColors.FEEDBACK_REWARD_PULSE
	var tween := create_tween()
	tween.tween_property(slot, "modulate", original_modulate, GEAR_LANDING_PULSE_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _quadratic_bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var ab := a.lerp(b, t)
	var bc := b.lerp(c, t)
	return ab.lerp(bc, t)


func _style_box_button(button: Button, gear: GearItem) -> void:
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, CardStyle.make_gear_item_stylebox(gear, false, state))


func _inventory_tooltip(gear: GearItem) -> String:
	return _gear_tooltip(gear)


func _equipped_tooltip(gear: GearItem) -> String:
	return _gear_tooltip(gear)


func _gear_tooltip(gear: GearItem) -> String:
	return "\n".join(CardStyle.gear_tooltip_lines(gear))


func _sell_action_text(gear: GearItem) -> String:
	return "Sell for %dg" % BuildState.sell_value_for(gear) if BuildState.shop_round_pending else "Sell"
