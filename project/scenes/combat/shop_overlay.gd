extends Control
## Tavern Shop overlay: buy/reroll gear offers against current gold.
## Extracted from combat_screen.gd's inline overlay builder
## (docs/Phase_3_Technical_Debt_Architecture_Cleanup.md Phase 3).
##
## Unlike the other extracted overlays, this one is intentionally NOT a
## blocking modal: gear can still be sold from the dashboard's Gear panel
## while the shop is open. Its dimmer leaves a clear, interactive Gear panel.
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
const REVEAL_PREFERENCES := preload("res://scripts/ui/shop_reveal_preferences.gd")
const UPGRADE_EFFECT := preload("res://scripts/ui/gear_upgrade_effect.gd")
const CARD_TITLE_FONT_SIZE := 20
const REVEAL_INITIAL_DELAY_SEC := 0.20
const REVEAL_BASE_HOLD_SEC := 0.10
const REVEAL_UPGRADE_HOLD_SEC := UPGRADE_EFFECT.DURATION_SEC + 0.02
const REVEAL_ITEM_GAP_SEC := 0.06
const REROLL_COST_PULSE_SEC := 0.22
const SHOP_OVERLAY_Z_INDEX := 40
const SHOPKEEPER_TEXTURE := preload("res://assets/backgrounds/shop_dummy_background_2.jpg")
const GOLD_ICON := preload("res://assets/ui/icons/gold.png")

var _shopkeeper_image: TextureRect
var _shop_status_label: Label
var _shop_reroll_button: Button
var _shop_offers_box: GridContainer
var _shop_leave_button: Button
var _shop_skip_animations_button: Button
var _skip_animations := false
var _focus_dimmer: Control
var _upgrade_cards := {}
var _upgrade_effects: Array[Control] = []
var _batch_key := ""
var _batch_offer_ids := {}
var _batch_offers: Array[GearItem] = []
var _revealed_ids := {}
var _display_tiers := {}
var _reveal_active := false
var _reveal_started := false
var _reveal_generation := 0
var _operation_generation := 0
var _reroll_in_progress := false


func _ready() -> void:
	_skip_animations = REVEAL_PREFERENCES.load_skip_animations()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = SHOP_OVERLAY_Z_INDEX
	visible = false
	visibility_changed.connect(func():
		if not visible:
			skip_reveal()
		else:
			_start_reveal.call_deferred()
	)
	_focus_dimmer = preload("res://scripts/ui/play_area_focus.gd").new()
	_focus_dimmer.name = "ShopFocusDimmer"
	add_child(_focus_dimmer)

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
	# Reserve the larger normal/disabled height so unlocking reroll cannot
	# shift the grid when the theme changes the button's content margins.
	var reroll_style_height := 0.0
	for state in ["normal", "disabled", "hover", "pressed"]:
		reroll_style_height = maxf(reroll_style_height, _shop_reroll_button.get_theme_stylebox(state).get_minimum_size().y)
	_shop_reroll_button.custom_minimum_size.y = reroll_style_height + _shop_reroll_button.get_theme_font("font").get_height(_shop_reroll_button.get_theme_font_size("font_size"))

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
	_shop_skip_animations_button = Button.new()
	_shop_skip_animations_button.name = "SkipShopAnimations"
	_shop_skip_animations_button.toggle_mode = true
	_shop_skip_animations_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_shop_skip_animations_button.add_theme_font_override("font", CardStyle.DATA_FONT)
	_shop_skip_animations_button.add_theme_font_size_override("font_size", 16)
	var toggle_style := CardStyle.make_stylebox(3)
	toggle_style.content_margin_left = 7
	toggle_style.content_margin_right = 7
	toggle_style.content_margin_top = 2
	toggle_style.content_margin_bottom = 4
	toggle_style.bg_color = Color("292622")
	toggle_style.border_color = Color("686053")
	toggle_style.border_blend = false
	toggle_style.set_border_width_all(1)
	toggle_style.border_width_top = 0
	toggle_style.border_width_bottom = 2
	toggle_style.shadow_color = Color(0, 0, 0, 0.8)
	toggle_style.shadow_size = 2
	toggle_style.shadow_offset = Vector2(0, 3)
	for mode in ["normal", "hover", "disabled"]:
		_shop_skip_animations_button.add_theme_stylebox_override(mode, toggle_style)
	var pressed_style := toggle_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color("a77b29")
	pressed_style.border_color = Color("49320f")
	pressed_style.border_width_top = 2
	pressed_style.border_width_bottom = 0
	pressed_style.content_margin_top = 4
	pressed_style.content_margin_bottom = 2
	pressed_style.shadow_size = 0
	pressed_style.shadow_offset = Vector2.ZERO
	_shop_skip_animations_button.add_theme_stylebox_override("pressed", pressed_style)
	_shop_skip_animations_button.add_theme_stylebox_override("hover_pressed", pressed_style)
	_shop_skip_animations_button.add_theme_color_override("font_color", Color("b4aa96"))
	_shop_skip_animations_button.add_theme_color_override("font_hover_color", Color("e2d8c4"))
	_shop_skip_animations_button.add_theme_color_override("font_pressed_color", Color("fff0bd"))
	_shop_skip_animations_button.add_theme_color_override("font_hover_pressed_color", Color("fff0bd"))
	_shop_skip_animations_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_shop_skip_animations_button.toggled.connect(_on_skip_animations_toggled)
	button_row.add_child(_shop_skip_animations_button)
	_refresh_skip_animations_button()

	_shop_leave_button = Button.new()
	_shop_leave_button.text = FLOW_TEXT.ACTION_LEAVE_SHOP
	_shop_leave_button.pressed.connect(func(): continue_pressed.emit())
	button_row.add_child(_shop_leave_button)
	# The always-present toggle keeps all card positions fixed.
	var skip_min := _shop_skip_animations_button.get_combined_minimum_size()
	var leave_min := _shop_leave_button.get_combined_minimum_size()
	button_row.custom_minimum_size = Vector2(skip_min.x + leave_min.x + 12, maxf(skip_min.y, leave_min.y))


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
	_shop_reroll_button.disabled = not enabled or is_busy()


func pulse_reroll_blocked() -> void:
	CardStyle.pulse_blocked_control(_shop_reroll_button, "reroll_blocked_pulse")


func is_revealing() -> bool:
	return _reveal_active


func is_busy() -> bool:
	return _reveal_active or _reroll_in_progress


func begin_reroll() -> int:
	_operation_generation += 1
	_reroll_in_progress = true
	_refresh_action_state()
	return _operation_generation


func is_reroll_current(generation: int) -> bool:
	return generation == _operation_generation and _reroll_in_progress and visible and BuildState.shop_round_pending


func end_reroll(generation: int) -> void:
	if generation == _operation_generation:
		_reroll_in_progress = false
		_refresh_action_state()


## Reconciles affordability and stable cards against current BuildState.
## Called by combat_screen.gd on open, after buy/reroll, and whenever
## BuildState changes while the shop is visible (gear can be sold from the
## dashboard's Gear panel while the shop stays open).
func refresh() -> void:
	set_status_text("")
	var key := "%d:%d" % [BuildState.shop_round_index, BuildState.shop_reroll_count]
	var new_batch := key != _batch_key
	for offer in BuildState.shop_offers:
		if not _batch_offer_ids.has(offer.id): new_batch = true
	if new_batch:
		_reveal_generation += 1
		_cancel_upgrade_effects()
		AudioManager.cancel_magic_find_sfx()
		_batch_key = key
		_batch_offer_ids.clear()
		_batch_offers.assign(BuildState.shop_offers)
		_revealed_ids.clear()
		_display_tiers.clear()
		for child in _shop_offers_box.get_children():
			_shop_offers_box.remove_child(child)
			child.queue_free()
		_upgrade_cards.clear()
		for offer in _batch_offers:
			_batch_offer_ids[offer.id] = true
			var card := _make_shop_placeholder(offer)
			_upgrade_cards[offer.id] = card
			_shop_offers_box.add_child(card)
		_reveal_active = not _batch_offers.is_empty()
		_reveal_started = false
		set_status_text("")
	# Purchase/sale notifications reconcile in place; they cannot restart the
	# story or replace a card underneath an active shimmer.
	var current_ids := {}
	for offer in BuildState.shop_offers: current_ids[offer.id] = true
	for id in _upgrade_cards.keys():
		if not current_ids.has(id):
			var card: Control = _upgrade_cards[id]
			_shop_offers_box.remove_child(card)
			card.queue_free()
			_upgrade_cards.erase(id)
	_refresh_action_state()
	if visible: _start_reveal.call_deferred()


func _refresh_action_state() -> void:
	_shop_reroll_button.text = "Reroll %dg" % BuildState.shop_reroll_cost
	_shop_reroll_button.disabled = is_busy() or not BuildState.can_reroll_shop_offers()
	_shop_reroll_button.tooltip_text = _reroll_tooltip()
	for offer in BuildState.shop_offers:
		var card: Button = _upgrade_cards.get(offer.id)
		if is_instance_valid(card): _refresh_card_affordance(card, offer)


func _start_reveal() -> void:
	if not visible or not _reveal_active or _reveal_started:
		return
	if _skip_animations:
		_settle_reveal()
		return
	_reveal_started = true
	var generation := _reveal_generation
	await get_tree().create_timer(REVEAL_INITIAL_DELAY_SEC, true, false, true).timeout
	for offer in _batch_offers:
		if not _reveal_current(generation): return
		var card: Button = _upgrade_cards.get(offer.id)
		if not is_instance_valid(card): continue
		var steps := _tier_steps(offer)
		_revealed_ids[offer.id] = true
		_set_card_visual(card, offer, steps[0])
		await get_tree().create_timer(REVEAL_BASE_HOLD_SEC, true, false, true).timeout
		for index in range(1, steps.size()):
			if not _reveal_current(generation): return
			_set_card_visual(card, offer, steps[index])
			_upgrade_effects.append(UPGRADE_EFFECT.play(card, steps[index]))
			await get_tree().create_timer(REVEAL_UPGRADE_HOLD_SEC, true, false, true).timeout
		if not _reveal_current(generation): return
		await get_tree().create_timer(REVEAL_ITEM_GAP_SEC, true, false, true).timeout
	if _reveal_current(generation):
		_reveal_active = false
		_refresh_action_state()


func _reveal_current(generation: int) -> bool:
	return generation == _reveal_generation and _reveal_active and visible and BuildState.shop_round_pending


func _tier_steps(offer: GearItem) -> Array[int]:
	var steps: Array[int] = offer.reward_tier_steps.duplicate()
	if steps.is_empty(): steps.append(offer.tier)
	return steps


func skip_reveal() -> void:
	_operation_generation += 1
	_reroll_in_progress = false
	_settle_reveal()


func _on_skip_animations_toggled(skip: bool) -> void:
	_skip_animations = skip
	REVEAL_PREFERENCES.save_skip_animations(skip)
	_refresh_skip_animations_button()
	if skip:
		# Presentation cancellation must not invalidate a paid reroll's gold flight.
		_settle_reveal()


func _refresh_skip_animations_button() -> void:
	_shop_skip_animations_button.set_pressed_no_signal(_skip_animations)
	_shop_skip_animations_button.text = "skip"
	_shop_skip_animations_button.tooltip_text = "Skip shop animations: %s. Applies now and on future visits. Rewards keep their animations." % ("ON" if _skip_animations else "OFF")
	# Match the talent tree's small reset action in both toggle states.
	var width := CardStyle.DATA_FONT.get_string_size("reset", HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	_shop_skip_animations_button.custom_minimum_size.x = width + _shop_skip_animations_button.get_theme_stylebox("normal").get_minimum_size().x


func _settle_reveal() -> void:
	_reveal_generation += 1
	_reveal_active = false
	_reveal_started = false
	_cancel_upgrade_effects()
	AudioManager.cancel_magic_find_sfx()
	for offer in BuildState.shop_offers:
		var card: Button = _upgrade_cards.get(offer.id)
		if is_instance_valid(card):
			_revealed_ids[offer.id] = true
			_set_card_visual(card, offer, offer.tier)
	_refresh_action_state()


func _make_shop_placeholder(offer: GearItem) -> Button:
	var card := GearCompareButton.new()
	card.custom_minimum_size = Vector2(88, 88)
	card.disabled = true
	card.focus_mode = Control.FOCUS_NONE
	card.pressed.connect(func():
		if not is_busy(): buy_pressed.emit(offer, card)
	)
	CardStyle.style_shop_item_box(card, null)
	return card


func _set_card_visual(card: Button, offer: GearItem, tier: int) -> void:
	for child in card.get_children():
		card.remove_child(child)
		child.queue_free()
	var proxy := GearItem.new()
	proxy.id = offer.id
	proxy.slot = offer.slot
	proxy.tier = tier
	proxy.item_family = offer.item_family
	proxy.class_family = offer.class_family
	proxy.source_kind = offer.source_kind
	proxy.is_unidentified = offer.is_unidentified and tier == GearItem.Tier.CHAOS
	_display_tiers[offer.id] = tier
	CardStyle.style_shop_item_box(card, proxy)
	CardStyle.build_gear_box_content(card, proxy)
	_refresh_card_affordance(card, offer)


func _refresh_card_affordance(card: Button, offer: GearItem) -> void:
	card.disabled = is_busy() or BuildState.shop_purchase_price_for(offer) > BuildState.gold or not BuildState.can_store_shop_offer(offer)
	card.focus_mode = Control.FOCUS_NONE if is_busy() else Control.FOCUS_ALL
	if not _revealed_ids.has(offer.id):
		card.tooltip_text = ""
		card.tooltip_builder = Callable()
		return
	if int(_display_tiers.get(offer.id, -1)) != offer.tier:
		card.tooltip_text = "Revealing item..."
		card.tooltip_builder = Callable()
		return
	card.tooltip_text = _shop_offer_text(offer)
	card.tooltip_builder = func(): return CardStyle.build_gear_compare_tooltip(self, _shop_offer_text(offer), BuildState.equipped_item_for_slot(offer.slot), offer, BuildState.is_test_mode)
	var badge := card.get_node_or_null("PriceBadge")
	if badge != null:
		card.remove_child(badge)
		badge.queue_free()
	_add_price_badge(card, offer)


func _cancel_upgrade_effects() -> void:
	for effect in _upgrade_effects:
		if is_instance_valid(effect): effect.cancel()
	_upgrade_effects.clear()


func _exit_tree() -> void:
	_reveal_generation += 1
	_operation_generation += 1
	_reveal_active = false
	_reroll_in_progress = false
	_cancel_upgrade_effects()
	AudioManager.cancel_magic_find_sfx()


func _make_shop_offer_row(offer: GearItem) -> Control:
	var item_box := GearCompareButton.new()
	item_box.custom_minimum_size = Vector2(88, 88)
	item_box.tooltip_text = _shop_offer_text(offer)
	item_box.tooltip_builder = func(): return CardStyle.build_gear_compare_tooltip(self, _shop_offer_text(offer), BuildState.equipped_item_for_slot(offer.slot), offer, BuildState.is_test_mode)
	item_box.disabled = BuildState.shop_purchase_price_for(offer) > BuildState.gold or not BuildState.can_store_shop_offer(offer)
	item_box.pressed.connect(func():
		if not is_busy(): buy_pressed.emit(offer, item_box)
	)
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
## Rendered inside CardStyle.build_gear_compare_tooltip()'s single item
## box, and kept on Button.tooltip_text as the plain-text
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
	if is_busy():
		lines.append("Purchases unlock after the reveal. Turn on Skip animations to finish now.")
		return lines
	var reason := preload("res://scripts/ui/gear_action_feedback.gd").legendary_reason(BuildState, offer)
	if reason != "":
		lines.append(reason)
	elif not BuildState.can_store_shop_offer(offer):
		lines.append("Inventory full -- make space first.")
	elif price > BuildState.gold:
		lines.append("Not enough gold.")
	else:
		lines.append("Click to buy.")
	return lines


func _reroll_tooltip() -> String:
	var cost := BuildState.shop_reroll_cost
	if is_busy():
		return "Wait for the reveal or turn on Skip animations before rerolling."
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
