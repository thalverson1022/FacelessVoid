extends Control
## Tavern Shop overlay: buy/reroll gear offers against current gold.
## Extracted from combat_screen.gd's inline overlay builder
## (docs/Phase_3_Technical_Debt_Architecture_Cleanup.md Phase 3).
##
## Unlike the other extracted overlays, this one is intentionally NOT a
## blocking modal: gear can still be sold from the dashboard's Gear panel
## while the shop is open, so there is no full-screen backdrop here -- only
## the card itself catches clicks (mouse_filter below).
##
## combat_screen.gd still owns show/hide timing and the dashboard-chrome side
## effects (hiding status/recap/log/retry buttons, refreshing the enemy HUD,
## autosaving) since those are cross-cutting dashboard state, not
## shop-internal -- this scene only owns its own construction, its own
## refresh, and the buy/reroll/continue signals combat_screen.gd reacts to.

signal buy_pressed(offer: GearItem, source: Control)
signal reroll_pressed
signal continue_pressed

const FLOW_TEXT := preload("res://scripts/ui/adventure_flow_text.gd")
const CARD_TITLE_FONT_SIZE := 20
const REROLL_OUT_DURATION_SEC := 0.16
const REROLL_IN_DURATION_SEC := 0.2
const REROLL_STAGGER_SEC := 0.045
const REROLL_COST_PULSE_SEC := 0.22
const SHOP_OVERLAY_Z_INDEX := 40
const SHOPKEEPER_TEXTURE := preload("res://assets/backgrounds/shop_dummy_background_2.jpg")
const GOLD_ICON := preload("res://assets/ui/icons/gold.png")

var _shopkeeper_image: TextureRect
var _shop_status_label: Label
var _shop_reroll_button: Button
var _shop_offers_box: GridContainer
var _shop_leave_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = SHOP_OVERLAY_Z_INDEX
	visible = false

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", CardStyle.make_stylebox())
	center.add_child(panel)

	var content := HBoxContainer.new()
	content.custom_minimum_size = Vector2(620, 420)
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)

	var shopkeeper := PanelContainer.new()
	shopkeeper.custom_minimum_size = Vector2(260, 0)
	shopkeeper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var keeper_style := CardStyle.make_stylebox(8)
	keeper_style.bg_color = UIColors.PANEL_DEEP
	shopkeeper.add_theme_stylebox_override("panel", keeper_style)
	content.add_child(shopkeeper)

	var keeper_stage := Control.new()
	keeper_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	keeper_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	keeper_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shopkeeper.add_child(keeper_stage)

	_shopkeeper_image = TextureRect.new()
	_shopkeeper_image.texture = SHOPKEEPER_TEXTURE
	_shopkeeper_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_shopkeeper_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_shopkeeper_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shopkeeper_image.set_anchors_preset(Control.PRESET_FULL_RECT)
	keeper_stage.add_child(_shopkeeper_image)

	var shop_content := VBoxContainer.new()
	shop_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_content.add_theme_constant_override("separation", 12)
	content.add_child(shop_content)

	var header := HBoxContainer.new()
	shop_content.add_child(header)

	var title := Label.new()
	title.text = "Tavern Shop"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.theme_type_variation = &"PanelHeader"
	title.add_theme_font_size_override("font_size", CARD_TITLE_FONT_SIZE)
	header.add_child(title)

	_shop_reroll_button = Button.new()
	_shop_reroll_button.icon = GOLD_ICON
	_shop_reroll_button.expand_icon = true
	_shop_reroll_button.pressed.connect(func(): reroll_pressed.emit())
	header.add_child(_shop_reroll_button)

	_shop_status_label = Label.new()
	_shop_status_label.visible = false
	shop_content.add_child(_shop_status_label)

	_shop_offers_box = GridContainer.new()
	_shop_offers_box.columns = 2
	_shop_offers_box.add_theme_constant_override("h_separation", 10)
	_shop_offers_box.add_theme_constant_override("v_separation", 10)
	shop_content.add_child(_shop_offers_box)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop_content.add_child(spacer)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_END
	button_row.add_theme_constant_override("separation", 12)
	shop_content.add_child(button_row)

	_shop_leave_button = Button.new()
	_shop_leave_button.text = FLOW_TEXT.ACTION_LEAVE_SHOP
	_shop_leave_button.pressed.connect(func(): continue_pressed.emit())
	button_row.add_child(_shop_leave_button)


## Public so combat_screen.gd's buy/reroll handlers (which also autosave and
## call BuildState -- cross-cutting concerns that stay in combat_screen.gd)
## can set feedback text without reaching into the private label.
func set_status_text(text: String) -> void:
	_shop_status_label.text = text
	_shop_status_label.visible = text != ""


func reroll_action_rect() -> Rect2:
	if _shop_reroll_button == null or not _shop_reroll_button.is_inside_tree():
		return Rect2()
	return _shop_reroll_button.get_global_rect()


func set_reroll_enabled(enabled: bool) -> void:
	_shop_reroll_button.disabled = not enabled


func pulse_reroll_blocked() -> void:
	CardStyle.pulse_blocked_control(_shop_reroll_button, "reroll_blocked_pulse")


func play_reroll_offers_out() -> void:
	for child in _shop_offers_box.get_children():
		if child is Control:
			var control := child as Control
			control.pivot_offset = control.size * 0.5
			var tween := create_tween()
			tween.set_parallel(true)
			tween.tween_property(control, "scale", Vector2(0.9, 0.9), REROLL_OUT_DURATION_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_property(control, "modulate:a", 0.0, REROLL_OUT_DURATION_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(REROLL_OUT_DURATION_SEC).timeout


func play_reroll_offers_in() -> void:
	var max_delay := 0.0
	for i in _shop_offers_box.get_child_count():
		var child := _shop_offers_box.get_child(i)
		if child is Control:
			var control := child as Control
			var delay := float(i) * REROLL_STAGGER_SEC
			max_delay = maxf(max_delay, delay)
			control.pivot_offset = control.size * 0.5
			control.scale = Vector2(0.9, 0.9)
			control.modulate = UIColors.FEEDBACK_REWARD_PULSE_TRANSPARENT
			var tween := create_tween()
			tween.set_parallel(true)
			tween.tween_property(control, "modulate", Color.WHITE, REROLL_IN_DURATION_SEC).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(control, "scale", Vector2.ONE, REROLL_IN_DURATION_SEC).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pulse_reroll_cost()
	await get_tree().create_timer(max_delay + REROLL_IN_DURATION_SEC).timeout


## Rebuilds gold/status/reroll-button/offers-grid from current BuildState.
## Called by combat_screen.gd on open, after buy/reroll, and whenever
## BuildState changes while the shop is visible (gear can be sold from the
## dashboard's Gear panel while the shop stays open).
func refresh() -> void:
	_shop_status_label.text = ""
	_shop_status_label.visible = false
	_shop_reroll_button.text = "Reroll %dg" % BuildState.shop_reroll_cost
	_shop_reroll_button.disabled = not BuildState.can_reroll_shop_offers()
	_shop_reroll_button.tooltip_text = _reroll_tooltip()
	for child in _shop_offers_box.get_children():
		child.queue_free()
	for offer in BuildState.shop_offers:
		_shop_offers_box.add_child(_make_shop_offer_row(offer))


func _make_shop_offer_row(offer: GearItem) -> Control:
	var item_box := GearCompareButton.new()
	item_box.custom_minimum_size = Vector2(88, 88)
	item_box.tooltip_text = _shop_offer_text(offer)
	item_box.tooltip_builder = func(): return CardStyle.build_gear_compare_tooltip(self, _shop_offer_text(offer), BuildState.equipped_item_for_slot(offer.slot), offer)
	item_box.disabled = BuildState.shop_purchase_price_for(offer) > BuildState.gold or not BuildState.can_store_shop_offer(offer)
	item_box.pressed.connect(func(): buy_pressed.emit(offer, item_box))
	CardStyle.style_shop_item_box(item_box, offer)
	CardStyle.build_gear_box_content(item_box, offer)
	_add_price_badge(item_box, offer)
	return item_box


func _add_price_badge(item_box: Button, offer: GearItem) -> void:
	var price := BuildState.shop_purchase_price_for(offer)
	var badge := PanelContainer.new()
	badge.name = "PriceBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	badge.offset_left = -66
	badge.offset_top = -30
	badge.offset_right = -4
	badge.offset_bottom = -4
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = UIColors.BADGE_BACKDROP
	badge_style.border_color = UIColors.TEXT_DISABLED if item_box.disabled else UIColors.TEXT_GOLD
	badge_style.set_border_width_all(1)
	badge_style.set_corner_radius_all(4)
	badge_style.set_content_margin_all(3)
	badge.add_theme_stylebox_override("panel", badge_style)
	item_box.add_child(badge)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 3)
	badge.add_child(row)
	var price_icon := CardStyle.make_pixel_icon(GOLD_ICON, Vector2(11, 11))
	price_icon.name = "GoldIcon"
	row.add_child(price_icon)
	var label := Label.new()
	label.name = "PriceLabel"
	label.text = "%dg" % price
	label.add_theme_color_override("font_color", UIColors.TEXT_DISABLED if item_box.disabled else UIColors.TEXT_GOLD)
	label.add_theme_color_override("font_outline_color", UIColors.TEXT_OUTLINE)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_font_size_override("font_size", 16)
	row.add_child(label)


## The shop-offer gear box's regular tooltip text: slot/name, tier, affixes,
## the price, and an explicit afford/inventory-space/click hint (P2:R7:T6).
## Rendered inside the first of CardStyle.build_gear_compare_tooltip()'s two
## tooltip-styled boxes, and kept on Button.tooltip_text as the plain-text
## fallback/accessibility copy.
func _shop_offer_text(offer: GearItem) -> String:
	var lines := CardStyle.gear_tooltip_lines(offer)
	lines.append_array(_shop_offer_footer_lines(offer))
	return "\n".join(lines)


## Price + afford/inventory-space/click hint for a shop offer, appended to
## _shop_offer_text()'s item lines.
func _shop_offer_footer_lines(offer: GearItem) -> PackedStringArray:
	var lines: PackedStringArray = []
	var price := BuildState.shop_purchase_price_for(offer)
	lines.append("Price: %dg" % price)
	var reason := preload("res://scripts/ui/gear_action_feedback.gd").legendary_reason(BuildState, offer)
	if reason != "":
		lines.append(reason)
	elif not BuildState.can_store_shop_offer(offer):
		lines.append("Inventory full -- make space first.")
	elif price > BuildState.gold:
		lines.append("Not enough gold.")
	else:
		lines.append("Click to buy. Bought items enter your inventory.")
	lines.append("Comparison assumes equipping with your current gold.")
	return lines


func _reroll_tooltip() -> String:
	var cost := BuildState.shop_reroll_cost
	if not BuildState.shop_round_pending:
		return "Reroll is only available while the shop is open."
	if BuildState.gold < cost:
		return "Need %dg to reroll shop offers." % cost
	return "Spend %dg to refresh the shop offers." % cost


func _pulse_reroll_cost() -> void:
	if _shop_reroll_button == null or not _shop_reroll_button.is_inside_tree():
		return
	var original_modulate := _shop_reroll_button.modulate
	_shop_reroll_button.modulate = UIColors.FEEDBACK_ACTION_PULSE
	var tween := create_tween()
	tween.tween_property(_shop_reroll_button, "modulate", original_modulate, REROLL_COST_PULSE_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
