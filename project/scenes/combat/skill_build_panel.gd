extends PanelContainer
## Combat dashboard strip (center column, bottom): the skill macro as a
## wrapping numbered slots in reading order. Skills without
## assigned art still fall back to Skill.icon_letter. Clicking a box
## selects it; right-click removes it. Hover shows current-build information. Adding
## happens in available_skills_panel.gd; both strips sync purely through
## state.rotation.

const CARD_TITLE_FONT_SIZE := 28
const SLOT_SIZE := Vector2(76, 80)
const TEST_ICONS := preload("res://scripts/ui/test_mode_skill_icons.gd")
const TEST_ICON_SHADER := preload("res://scripts/ui/rounded_skill_icon.gdshader")
const SLOT_FONT_SIZE := 26
const SLOT_ICON_SIZE := Vector2(72, 72)
const PANEL_MIN_HEIGHT := 112
const ORDER_BADGE_FONT_SIZE := 18
const REMOVE_BADGE_FONT_SIZE := 14
const SLOT_COUNT_FONT_SIZE := 22
const INTERRUPT_LOCK_ICON_SIZE := Vector2(46, 46)
const INTERRUPT_LOCK_ICON_COLOR := Color(1.0, 0.08, 0.06, 0.92)
const INTERRUPT_LOCK_ICON_OUTLINE := Color(0.12, 0.0, 0.0, 0.9)
const ACTIVE_SLOT_COLOR := UIColors.BUILD_ACTIVE
const ACTIVE_SLOT_BG := UIColors.BUILD_ACTIVE_BG
const PULSE_SLOT_COLOR := UIColors.BUILD_PROC
const PULSE_SLOT_BG := UIColors.BUILD_PROC_BG
const PROGRESS_FILL_COLOR := UIColors.BUILD_PROGRESS_FILL
const PROC_PROGRESS_FILL_COLOR := UIColors.BUILD_PROC_PROGRESS_FILL
const SLOW_PROGRESS_FILL_COLOR := Color(0.38, 0.72, 1.0, 0.48)
const STUNNED_SLOT_MODULATE := Color(0.38, 0.38, 0.38, 0.76)
const UNAVAILABLE_SLOT_MODULATE := Color(0.5, 0.5, 0.5, 1.0)
const STUN_COOLDOWN_FILL := Color(0.02, 0.018, 0.016, 0.64)
const STUN_COOLDOWN_EDGE := Color(0.0, 0.0, 0.0, 0.58)
const LOCK_ICON := preload("res://assets/ui/icons/build_lock.png")
const UNLOCK_ICON := preload("res://assets/ui/icons/build_unlock.png")
const LOCK_BUTTON_SIZE := Vector2(50, 50)
const LOCK_BUTTON_ICON_SIZE := Vector2(32, 32)
const LOCK_BUTTON_CORNER_RADIUS := 25
const SkillTooltipFormatterScript := preload("res://scripts/ui/skill_tooltip_formatter.gd")

## P2:R10: see talent_panel.gd's `state` comment -- same pattern, same
## default, same untyped declaration reason.
var state = BuildState
var _credit_model
var _seen_cooldown_credits := {}
var _cooldown_pulses := {}
var locket_pulse_count := 0

var _content: VBoxContainer
var _title_label: Label
var _macro_row: HBoxContainer
var _slots_box: GridContainer
var _selected_index := -1
var _slot_count_label: Label
var _lock_button: Button
var _lock_button_icon: TextureRect
var _lock_holder: CenterContainer
var _slot_buttons: Array[Button] = []
var _slot_fills: Array[ColorRect] = []
var _slot_interrupt_overlays: Array[Control] = []
var _slot_stun_overlays: Array[StunCooldownOverlay] = []
var _interrupt_locked_skill_ids := {}
var _active_index := -1
var _pulse_tween: Tween
var _stun_tween: Tween
var _combat_interaction_locked := false
var _slow_effect_active := false
var _stun_effect_active := false
var _readiness_available := false
var _readiness_cast_index := -1
var _stun_generation := 0
var stun_effect_count := 0
var last_stun_duration_ms := 0


class InterruptLockOverlay:
	extends Control

	var icon_color := Color(1.0, 0.08, 0.06, 0.92)
	var outline_color := Color(0.12, 0.0, 0.0, 0.9)

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.42
		draw_arc(center, radius, 0.0, TAU, 56, outline_color, 9.0, true)
		draw_arc(center, radius, 0.0, TAU, 56, icon_color, 6.0, true)
		var diagonal := Vector2(radius * 0.62, radius * 0.62)
		draw_line(center - diagonal, center + diagonal, outline_color, 10.0, true)
		draw_line(center - diagonal, center + diagonal, icon_color, 7.0, true)


class StunCooldownOverlay:
	extends "res://scripts/ui/combat_radial_countdown.gd"

func _ready() -> void:
	var panel_style := CardStyle.make_stylebox()
	# Ten full-size slots must fit Practice without pushing its side panels.
	panel_style.content_margin_left = 8
	panel_style.content_margin_right = 8
	add_theme_stylebox_override("panel", panel_style)
	custom_minimum_size = Vector2(0, PANEL_MIN_HEIGHT)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 8)
	add_child(_content)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 16)
	_content.add_child(title_row)

	_title_label = Label.new()
	_title_label.text = "Skill Build"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title_label.theme_type_variation = &"PanelHeader"
	_title_label.add_theme_font_size_override("font_size", CARD_TITLE_FONT_SIZE)
	title_row.add_child(_title_label)

	var title_spacer := Control.new()
	title_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_spacer)

	_slot_count_label = Label.new()
	_slot_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_slot_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_slot_count_label.add_theme_font_size_override("font_size", SLOT_COUNT_FONT_SIZE)
	_slot_count_label.add_theme_color_override("font_color", UIColors.TEXT_DISABLED)
	title_row.add_child(_slot_count_label)

	_lock_button = Button.new()
	_lock_button.custom_minimum_size = LOCK_BUTTON_SIZE
	_lock_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_lock_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_lock_button.pressed.connect(_on_lock_pressed)

	_lock_button_icon = TextureRect.new()
	_lock_button_icon.name = "LockButtonIcon"
	_lock_button_icon.custom_minimum_size = LOCK_BUTTON_ICON_SIZE
	_lock_button_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_lock_button_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lock_button_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_lock_button_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_lock_button_icon.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_lock_button_icon.anchor_top = 0.5
	_lock_button_icon.anchor_bottom = 0.5
	_lock_button.add_child(_lock_button_icon)

	var row_height: float = SLOT_SIZE.y
	_macro_row = HBoxContainer.new()
	_macro_row.custom_minimum_size.y = row_height
	_macro_row.add_theme_constant_override("separation", 2)
	_content.add_child(_macro_row)

	_slots_box = GridContainer.new()
	_slots_box.columns = 10
	_slots_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slots_box.add_theme_constant_override("h_separation", 4)
	_slots_box.add_theme_constant_override("v_separation", 6)
	# Reserve the complete row even when empty, keeping all columns stable.
	_slots_box.custom_minimum_size = Vector2(SLOT_SIZE.x * 10 + 4 * 9, row_height)
	_macro_row.add_child(_slots_box)

	

	_lock_holder = CenterContainer.new()
	_lock_holder.custom_minimum_size = Vector2(LOCK_BUTTON_SIZE.x, row_height)
	_macro_row.add_child(_lock_holder)
	_lock_holder.add_child(_lock_button)


	state.build_changed.connect(_refresh)
	state.lock_changed.connect(_refresh)
	_update_lock_icon_rect()
	_refresh()


func _on_lock_pressed() -> void:
	if _combat_interaction_locked:
		return
	state.set_locked(not state.build_locked)


func set_combat_interaction_locked(locked: bool) -> void:
	_combat_interaction_locked = locked
	_update_lock_button()


func _update_lock_button() -> void:
	var disabled_empty_lock: bool = state.rotation.is_empty() and not state.build_locked
	var disabled_combat_lock := _combat_interaction_locked
	_lock_button.text = ""
	_lock_button.icon = null
	_lock_button.add_theme_constant_override("icon_max_width", 0)
	_lock_button.add_theme_constant_override("h_separation", 0)
	_lock_button.add_theme_constant_override("text_outline_size", 0)
	_lock_button.add_theme_constant_override("padding_left", 0)
	_lock_button.add_theme_constant_override("padding_right", 0)
	_lock_button.add_theme_constant_override("padding_top", 0)
	_lock_button.add_theme_constant_override("padding_bottom", 0)
	_lock_button_icon.texture = LOCK_ICON if state.build_locked else UNLOCK_ICON
	_lock_button.tooltip_text = (
		"Skill macro is locked during combat"
		if disabled_combat_lock
		else
		"Unlock your skill macro so you can edit it"
		if state.build_locked
		else "Slot at least one skill before locking your macro"
		if disabled_empty_lock
		else "Lock this skill macro so you can start the fight"
	)
	_lock_button_icon.modulate = UIColors.ICON_DISABLED if disabled_empty_lock or disabled_combat_lock else Color.WHITE
	_apply_lock_button_style()
	# Can't lock an empty macro -- fighting with no skills is a guaranteed
	# zero-damage loss.
	_lock_button.disabled = disabled_empty_lock or disabled_combat_lock


func _refresh() -> void:
	_update_lock_button()
	_update_slot_count_label()
	_selected_index = mini(_selected_index, state.rotation.size() - 1)
	_slot_buttons = []
	_slot_fills = []
	_slot_interrupt_overlays = []
	_slot_stun_overlays = []
	for child in _slots_box.get_children():
		if child is Button:
			child.disabled = state.build_locked
		_slots_box.remove_child(child)
		child.queue_free()

	if state.rotation.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Click a skill above to add it."
		_slots_box.add_child(empty_label)
		return

	for i in state.rotation.size():
		var skill: Skill = state.rotation[i]
		var slot := IconTooltipButton.new()
		slot.tooltip_icon = skill.icon
		slot.text = _glyph_for(skill)
		slot.custom_minimum_size = SLOT_SIZE
		slot.add_theme_font_size_override("font_size", SLOT_FONT_SIZE)
		slot.add_theme_color_override("font_color", CardStyle.ACCENT_COLOR)
		slot.disabled = false
		slot.tooltip_text = _slot_tooltip(skill, i)
		slot.tooltip_provider = func(): return _slot_tooltip(skill, i)
		slot.skill_hover_provider = func(): return preload("res://scripts/ui/skill_hover_formatter.gd").model(skill,state)
		slot.gui_input.connect(_on_slot_input.bind(i))
		slot.pressed.connect(_on_slot_pressed.bind(i))
		_apply_slot_style(slot, i == _active_index, false)
		_add_skill_icon(slot, skill)
		var category_style = preload("res://scripts/ui/skill_category_preview_style.gd")
		if category_style.icon_selected(skill):
			var accent = preload("res://scripts/ui/skill_category_icon_accent.gd").new()
			accent.state = state
			accent.skill = skill
			accent.macro_slot = true
			accent.bottom_bar_height = 6.0
			accent.z_index = 9
			slot.add_child(accent)

		var fill := ColorRect.new()
		fill.name = "CastProgressFill"
		fill.color = _progress_fill_color(false)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fill.anchor_left = 0.0
		fill.anchor_top = 0.0
		fill.anchor_right = 0.0
		fill.anchor_bottom = 1.0
		fill.offset_left = 0.0
		fill.offset_top = 0.0
		fill.offset_right = 0.0
		fill.offset_bottom = 0.0
		fill.z_index = 3
		slot.add_child(fill)
		var interrupt_overlay := _make_interrupt_lock_overlay()
		interrupt_overlay.visible = _interrupt_locked_skill_ids.has(_skill_lock_key(skill))
		slot.add_child(interrupt_overlay)
		var stun_overlay := _make_stun_cooldown_overlay()
		slot.add_child(stun_overlay)

		# Cast-order number, top-left corner -- makes the left-to-right
		# rotation order explicit rather than only implied by position.
		# mouse_filter=IGNORE (same overlay pattern as available_skills_panel
		# and talent_panel) so the badge doesn't steal the slot's click.
		var order_badge := Label.new()
		order_badge.text = str(i + 1)
		order_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		order_badge.z_index = 4
		order_badge.add_theme_font_size_override("font_size", ORDER_BADGE_FONT_SIZE)
		order_badge.add_theme_color_override("font_color", UIColors.TEXT_DISABLED)
		order_badge.set_anchors_preset(Control.PRESET_TOP_LEFT)
		order_badge.position = Vector2(3, 1)
		slot.add_child(order_badge)


		var cooldown := Label.new()
		cooldown.name = "CooldownLabel"
		cooldown.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cooldown.position = Vector2(3, 25)
		cooldown.add_theme_font_size_override("font_size", 18)
		cooldown.add_theme_color_override("font_color", UIColors.TEXT_GOLD)
		var cooldown_style := StyleBoxFlat.new()
		cooldown_style.bg_color = Color(0.03, 0.025, 0.02, 0.95)
		cooldown.add_theme_stylebox_override("normal", cooldown_style)
		cooldown.z_index = 8
		slot.add_child(cooldown)
		_slots_box.add_child(slot)
		_slot_buttons.append(slot)
		_slot_fills.append(fill)
		_slot_interrupt_overlays.append(interrupt_overlay)
		_slot_stun_overlays.append(stun_overlay)
		_apply_slot_stun_modulate(slot)


func highlight_rotation_index(index: int, pulse: bool = false) -> void:
	if state.rotation.is_empty():
		clear_combat_highlight()
		return
	_active_index = posmod(index, state.rotation.size())
	for i in _slot_buttons.size():
		_apply_slot_style(_slot_buttons[i], i == _active_index, false)
	if pulse and not CombatEffectIcons.reduced_motion and _active_index >= 0 and _active_index < _slot_buttons.size():
		_pulse_slot(_slot_buttons[_active_index])


func set_cast_progress(index: int, progress: float, proc: bool = false) -> void:
	if state.rotation.is_empty():
		clear_combat_highlight()
		return
	_active_index = posmod(index, state.rotation.size())
	for i in _slot_buttons.size():
		_apply_slot_style(_slot_buttons[i], i == _active_index, false)
		var fill: ColorRect = _slot_fills[i]
		var clamped := clampf(progress if i == _active_index else 0.0, 0.0, 1.0)
		fill.anchor_right = clamped
		fill.color = _progress_fill_color(proc and i == _active_index)


func clear_combat_highlight() -> void:
	_active_index = -1
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	for i in _slot_buttons.size():
		_apply_slot_style(_slot_buttons[i], false, false)
		if i < _slot_fills.size():
			_slot_fills[i].anchor_right = 0.0


func play_stun_effect(duration_ms: int, animate: bool = true, playback_speed: float = 1.0) -> void:
	stun_effect_count += 1
	last_stun_duration_ms = duration_ms
	_stun_generation += 1
	var generation := _stun_generation
	_stun_effect_active = animate and duration_ms > 0
	_apply_stun_visuals()
	if _stun_tween != null and _stun_tween.is_valid():
		_stun_tween.kill()
	if not _stun_effect_active:
		_set_stun_overlay_progress(0.0)
		return
	_set_stun_overlay_progress(1.0)
	_stun_tween = create_tween()
	var visual_duration_sec := float(duration_ms) / 1000.0 / maxf(playback_speed, 0.001)
	_stun_tween.tween_method(_set_stun_overlay_progress, 1.0, 0.0, visual_duration_sec)
	_stun_tween.tween_callback(func():
		if generation == _stun_generation:
			clear_stun_effect()
	)


func clear_stun_effect() -> void:
	_stun_generation += 1
	if _stun_tween != null and _stun_tween.is_valid():
		_stun_tween.kill()
	_stun_tween = null
	_stun_effect_active = false
	_set_stun_overlay_progress(0.0)
	_apply_stun_visuals()


func set_interrupt_locked_skill(skill: Skill, locked: bool) -> void:
	var key := _skill_lock_key(skill)
	if key == "":
		return
	if locked:
		_interrupt_locked_skill_ids[key] = true
	else:
		_interrupt_locked_skill_ids.erase(key)
	_apply_interrupt_locks()


func clear_interrupt_locks() -> void:
	_interrupt_locked_skill_ids.clear()
	_apply_interrupt_locks()


func set_slow_effect_active(active: bool) -> void:
	_slow_effect_active = active
	for fill in _slot_fills:
		fill.color = _progress_fill_color(false)


func is_stun_effect_active() -> bool:
	return _stun_effect_active


func _glyph_for(skill: Skill) -> String:
	if skill.icon != null:
		return ""
	if skill.icon_letter != "":
		return skill.icon_letter
	# Fallback for any skill data that hasn't been assigned a letter yet.
	return skill.display_name.left(1).to_upper()


func _add_skill_icon(slot: Button, skill: Skill) -> void:
	if skill.icon == null:
		return
	var icon := TextureRect.new()
	icon.name = "SkillIcon"
	icon.custom_minimum_size = SLOT_ICON_SIZE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.texture = TEST_ICONS.icon_for(skill.id, skill.icon, 2)
	icon.offset_left = 2
	icon.offset_right = -2
	icon.offset_top = 2
	icon.offset_bottom = -6
	var rounded := ShaderMaterial.new()
	rounded.shader = TEST_ICON_SHADER
	rounded.set_shader_parameter("icon_size", Vector2(72, 72))
	icon.material = rounded
	icon.z_index = 2
	slot.add_child(icon)


func _make_interrupt_lock_overlay() -> Control:
	var overlay := InterruptLockOverlay.new()
	overlay.name = "InterruptLockOverlay"
	overlay.icon_color = INTERRUPT_LOCK_ICON_COLOR
	overlay.outline_color = INTERRUPT_LOCK_ICON_OUTLINE
	overlay.custom_minimum_size = INTERRUPT_LOCK_ICON_SIZE
	overlay.set_anchors_preset(Control.PRESET_CENTER)
	overlay.offset_left = -INTERRUPT_LOCK_ICON_SIZE.x * 0.5
	overlay.offset_right = INTERRUPT_LOCK_ICON_SIZE.x * 0.5
	overlay.offset_top = -INTERRUPT_LOCK_ICON_SIZE.y * 0.5
	overlay.offset_bottom = INTERRUPT_LOCK_ICON_SIZE.y * 0.5
	overlay.z_index = 7
	overlay.visible = false
	return overlay


func _make_stun_cooldown_overlay() -> StunCooldownOverlay:
	var overlay := StunCooldownOverlay.new()
	overlay.name = "StunCooldownOverlay"
	overlay.fill_color = STUN_COOLDOWN_FILL
	overlay.edge_color = STUN_COOLDOWN_EDGE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.offset_left = 0.0
	overlay.offset_top = 0.0
	overlay.offset_right = 0.0
	overlay.offset_bottom = 0.0
	overlay.z_index = 6
	overlay.visible = _stun_effect_active
	overlay.progress = 1.0 if _stun_effect_active else 0.0
	return overlay


func _apply_interrupt_locks() -> void:
	for i in _slot_interrupt_overlays.size():
		var overlay := _slot_interrupt_overlays[i]
		if overlay == null:
			continue
		var skill: Skill = state.rotation[i] if i < state.rotation.size() else null
		overlay.visible = _interrupt_locked_skill_ids.has(_skill_lock_key(skill))


func _apply_stun_visuals() -> void:
	for slot in _slot_buttons:
		_apply_slot_stun_modulate(slot)
	for overlay in _slot_stun_overlays:
		if overlay == null:
			continue
		overlay.visible = _stun_effect_active


func _apply_slot_stun_modulate(slot: Button) -> void:
	if slot == null:
		return
	slot.modulate = STUNNED_SLOT_MODULATE if _stun_effect_active else Color.WHITE
	var index := _slot_buttons.find(slot)
	if index < 0 or index >= state.rotation.size():
		return
	var skill: Skill = state.rotation[index]
	var unavailable := skill.enables_readiness and skill.id == "skill.parry_strike" and not _readiness_available and index != _readiness_cast_index
	if unavailable:
		slot.modulate *= UNAVAILABLE_SLOT_MODULATE
	var icon := slot.get_node_or_null("SkillIcon") as TextureRect
	if icon != null:
		(icon.material as ShaderMaterial).set_shader_parameter("grayscale", unavailable)


func _set_stun_overlay_progress(progress: float) -> void:
	for overlay in _slot_stun_overlays:
		if overlay == null:
			continue
		overlay.progress = progress


func _progress_fill_color(proc: bool) -> Color:
	if proc:
		return PROC_PROGRESS_FILL_COLOR
	return SLOW_PROGRESS_FILL_COLOR if _slow_effect_active else PROGRESS_FILL_COLOR


func _skill_lock_key(skill: Skill) -> String:
	if skill == null:
		return ""
	if skill.id != "":
		return skill.id
	return skill.resource_path if skill.resource_path != "" else skill.display_name


func _on_slot_pressed(index: int) -> void:
	_selected_index = index


func _slot_tooltip(skill: Skill, index: int) -> String:
	return preload("res://scripts/ui/skill_hover_formatter.gd").plain_text(preload("res://scripts/ui/skill_hover_formatter.gd").model(skill,state))

func _on_slot_input(event: InputEvent, index: int) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed) or (event is InputEventKey and event.keycode == KEY_DELETE and event.pressed and not event.echo):
		_selected_index = index
		_remove_selected()
		accept_event()

func _remove_selected() -> void:
	if state.build_locked or _combat_interaction_locked or _selected_index < 0 or _selected_index >= state.rotation.size():
		return
	var rotation: Array[Skill] = state.rotation.duplicate()
	rotation.remove_at(_selected_index)
	state.set_rotation(rotation)
	if not _slot_buttons.is_empty(): _slot_buttons[mini(_selected_index, _slot_buttons.size() - 1)].grab_focus()

func _apply_slot_style(slot: Button, active: bool, pulse: bool) -> void:
	var border_color := PULSE_SLOT_COLOR if pulse else (ACTIVE_SLOT_COLOR if active else CardStyle.ACCENT_COLOR)
	var bg_color := PULSE_SLOT_BG if pulse else (ACTIVE_SLOT_BG if active else UIColors.PANEL_DEEP)
	for state_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := CardStyle.make_slot_stylebox(bg_color, border_color, 3 if active or pulse else 1, state_name)
		if not active and not pulse and state_name == "normal":
			style.bg_color = Color("28282b")
		slot.add_theme_stylebox_override(state_name, style)
	slot.add_theme_color_override("font_color", border_color)


func _apply_lock_button_style() -> void:
	var fill := UIColors.BUTTON_FILL_PRESSED if state.build_locked else UIColors.BUTTON_FILL
	var border := UIColors.TEXT_DISABLED if state.build_locked else UIColors.PANEL_BORDER
	for state_name in ["normal", "hover", "pressed", "focus"]:
		var style := CardStyle.make_action_button_stylebox(fill, border, state_name)
		style.set_corner_radius_all(LOCK_BUTTON_CORNER_RADIUS)
		_lock_button.add_theme_stylebox_override(state_name, style)
	var disabled_style := CardStyle.make_action_button_stylebox(UIColors.PANEL_DISABLED, UIColors.STRUCTURE_LINE_LIGHT, "disabled")
	disabled_style.set_corner_radius_all(LOCK_BUTTON_CORNER_RADIUS)
	_lock_button.add_theme_stylebox_override("disabled", disabled_style)


func _update_slot_count_label() -> void:
	var count: int = state.rotation.size()
	_slot_count_label.text = "Slots: %d/%d" % [count, BuildResolver.MAX_ROTATION_SIZE]
	_slot_count_label.add_theme_color_override("font_color", UIColors.TEXT_GOLD if count >= BuildResolver.MAX_ROTATION_SIZE else UIColors.TEXT_DISABLED)


func _update_lock_icon_rect() -> void:
	_lock_button_icon.custom_minimum_size = LOCK_BUTTON_ICON_SIZE
	_lock_button_icon.offset_left = (LOCK_BUTTON_SIZE.x - LOCK_BUTTON_ICON_SIZE.x) / 2.0
	_lock_button_icon.offset_right = (LOCK_BUTTON_SIZE.x + LOCK_BUTTON_ICON_SIZE.x) / 2.0
	_lock_button_icon.offset_top = -LOCK_BUTTON_ICON_SIZE.y / 2.0
	_lock_button_icon.offset_bottom = LOCK_BUTTON_ICON_SIZE.y / 2.0


func _pulse_slot(slot: Button) -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_apply_slot_style(slot, true, true)
	_pulse_tween = create_tween()
	_pulse_tween.tween_interval(0.16)
	_pulse_tween.tween_callback(func(): _apply_slot_style(slot, true, false))


func update_presentation(model, animate: bool = true) -> void:
	if _credit_model != model:
		clear_legendary_feedback()
		_credit_model = model
		_seen_cooldown_credits.clear()
	_readiness_available = model.units("buff.readiness") > 0
	# A charge can be granted and spent at the same timeline instant. Keep the
	# accepted Parry lit through windup, like the HUD's held Readiness display.
	_readiness_cast_index = -1
	if model.time_ms < int(model.attempt.get("end_ms", 0)) and int(model.attempt.get("lifecycle", {}).get("readiness_consumed", 0)) > 0:
		_readiness_cast_index = int(model.attempt.get("rotation_index", -1))
	for i in _slot_buttons.size():
		_apply_slot_stun_modulate(_slot_buttons[i])
		var skill: Skill = state.rotation[i]
		var label: Label = _slot_buttons[i].get_node("CooldownLabel")
		var credits := int(model.cooldown_credits.get(skill.id, 0))
		if credits > int(_seen_cooldown_credits.get(skill.id, 0)) and animate and not CombatEffectIcons.reduced_motion:
			_pulse_cooldown(label)
		label.text = "%.1fs" % ((int(model.cooldowns[skill.id]) - model.time_ms) / 1000.0) if model.cooldowns.has(skill.id) else ""
		if label.text.is_empty() and _cooldown_pulses.has(label): label.text = "0.0s"
		if i == int(model.attempt.get("rotation_index", -1)) and model.time_ms < int(model.attempt.get("end_ms", 0)) and model.attempt.get("reason") == "missing_readiness":
			label.text = "No stack"
		label.visible = not label.text.is_empty()
	_seen_cooldown_credits = model.cooldown_credits.duplicate()
	if not animate or CombatEffectIcons.reduced_motion: clear_legendary_feedback()

func _pulse_cooldown(label: Label) -> void:
	if _cooldown_pulses.has(label): _cooldown_pulses[label].kill()
	locket_pulse_count += 1
	label.set_meta("locket_pulse", true)
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2.ONE * 1.3
	label.modulate = Color(1.0, 1.0, 0.65)
	var tween := label.create_tween().set_parallel(true)
	_cooldown_pulses[label] = tween
	tween.tween_property(label, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate", Color.WHITE, 0.28)
	tween.chain().tween_callback(func():
		_cooldown_pulses.erase(label)
		label.set_meta("locket_pulse", false)
	)

func clear_legendary_feedback() -> void:
	for label in _cooldown_pulses:
		_cooldown_pulses[label].kill()
		if is_instance_valid(label):
			label.scale = Vector2.ONE
			label.modulate = Color.WHITE
			label.set_meta("locket_pulse", false)
	_cooldown_pulses.clear()

func clear_presentation() -> void:
	clear_legendary_feedback()
	_credit_model = null
	_seen_cooldown_credits.clear()
	state.remove_meta("combat_presentation")
	_readiness_available = false
	_readiness_cast_index = -1
	for slot in _slot_buttons:
		_apply_slot_stun_modulate(slot)
		slot.get_node("CooldownLabel").text = ""
