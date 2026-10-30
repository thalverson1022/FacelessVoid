extends Control

const GEAR_ICON_PATH := "res://assets/ui/icons/settings_gear.png"

const BUTTON_SIZE := Vector2(56, 56)
const SCREEN_MARGIN := 16
const MENU_WIDTH := 360

var _overlay: Control
var _shade: ColorRect
var _center: CenterContainer
var _settings_panel: PanelContainer
var _audio_panel: PanelContainer
var _gear_icon: Texture2D = null
var _return_focus: Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 1000
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	_sync_to_viewport()
	get_viewport().size_changed.connect(_sync_to_viewport)
	_build_settings_button()
	_build_overlay()
	set_process_unhandled_key_input(true)


func _sync_to_viewport() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	if _overlay != null:
		_overlay.position = Vector2.ZERO
		_overlay.size = size
	if _shade != null:
		_shade.position = Vector2.ZERO
		_shade.size = size
	if _center != null:
		_center.position = Vector2.ZERO
		_center.size = size


func _unhandled_key_input(event: InputEvent) -> void:
	if _overlay.visible and event.is_action_pressed("ui_cancel"):
		_hide_overlay()
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if not _overlay.visible or not event is InputEventKey or not event.pressed or event.echo or event.keycode != KEY_TAB:
		return
	var controls: Array[Control] = []
	for control in _overlay.find_children("*", "Control", true, false):
		if control.is_visible_in_tree() and control.focus_mode == Control.FOCUS_ALL and not (control is BaseButton and control.disabled):
			controls.append(control)
	if controls.is_empty(): return
	var current := controls.find(get_viewport().gui_get_focus_owner())
	controls[posmod(current + (-1 if event.shift_pressed else 1), controls.size())].grab_focus()
	get_viewport().set_input_as_handled()


func _build_settings_button() -> void:
	var button := Button.new()
	button.name = "SettingsButton"
	button.custom_minimum_size = BUTTON_SIZE
	button.icon = _load_gear_icon()
	button.expand_icon = true
	button.tooltip_text = "Settings"
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(_show_overlay)
	button.add_theme_stylebox_override("normal", _round_button_style(UIColors.BUTTON_FILL, UIColors.PANEL_BORDER))
	button.add_theme_stylebox_override("hover", _round_button_style(UIColors.BUTTON_TOP_LIGHT, UIColors.PANEL_BORDER))
	button.add_theme_stylebox_override("pressed", _round_button_style(UIColors.BUTTON_FILL_PRESSED, UIColors.PANEL_BORDER))
	var focus_outline := _round_button_style(Color.TRANSPARENT, UIColors.TEXT_NORMAL)
	focus_outline.set_border_width_all(2)
	focus_outline.set_expand_margin_all(3)
	focus_outline.set_corner_radius_all(31)
	button.add_theme_stylebox_override("focus", focus_outline)
	add_child(button)
	button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	button.offset_left = -SCREEN_MARGIN - BUTTON_SIZE.x
	button.offset_top = SCREEN_MARGIN
	button.offset_right = -SCREEN_MARGIN
	button.offset_bottom = SCREEN_MARGIN + BUTTON_SIZE.y


func _build_overlay() -> void:
	_overlay = Control.new()
	_overlay.name = "SettingsOverlay"
	_overlay.visible = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)
	_overlay.set_anchors_preset(Control.PRESET_TOP_LEFT)

	_shade = ColorRect.new()
	_shade.name = "SettingsBlackout"
	_shade.color = Color(0.0, 0.0, 0.0, 0.86)
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(_shade)
	_shade.set_anchors_preset(Control.PRESET_TOP_LEFT)

	_center = CenterContainer.new()
	_center.name = "SettingsCenter"
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_center)
	_center.set_anchors_preset(Control.PRESET_TOP_LEFT)

	_settings_panel = _build_settings_panel()
	_center.add_child(_settings_panel)
	_audio_panel = _build_audio_panel()
	_audio_panel.visible = false
	_center.add_child(_audio_panel)
	_sync_to_viewport()


func _build_settings_panel() -> PanelContainer:
	var panel := _panel("SettingsPanel")

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.name = "SettingsStack"
	stack.add_theme_constant_override("separation", 12)
	margin.add_child(stack)

	var title := Label.new()
	title.name = "SettingsTitle"
	title.text = "Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	stack.add_child(title)

	var options := [
		"Gameplay",
		"Video",
	]
	for option in options:
		var disabled_button := _menu_button(option)
		disabled_button.disabled = true
		disabled_button.tooltip_text = "%s settings will be added later." % option
		stack.add_child(disabled_button)

	var audio_button := _menu_button("Audio")
	audio_button.name = "AudioButton"
	audio_button.pressed.connect(_show_audio_panel)
	stack.add_child(audio_button)

	var credits_button := _menu_button("Credits")
	credits_button.disabled = true
	credits_button.tooltip_text = "Credits settings will be added later."
	stack.add_child(credits_button)

	var close_button := _menu_button("Close")
	close_button.name = "CloseSettingsButton"
	close_button.pressed.connect(_hide_overlay)
	stack.add_child(close_button)
	return panel


func _build_audio_panel() -> PanelContainer:
	var panel := _panel("AudioSettingsPanel")

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.name = "AudioSettingsStack"
	stack.add_theme_constant_override("separation", 12)
	margin.add_child(stack)

	var title := Label.new()
	title.name = "AudioSettingsTitle"
	title.text = "Audio"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	stack.add_child(title)

	stack.add_child(_volume_row("Master", "MasterVolumeSlider", AudioManager.master_volume, AudioManager.set_master_volume))
	stack.add_child(_volume_row("Music", "MusicVolumeSlider", AudioManager.music_volume, AudioManager.set_music_volume))
	stack.add_child(_volume_row("Effects", "EffectsVolumeSlider", AudioManager.effects_volume, AudioManager.set_effects_volume))

	var main_menu_button := _menu_button("Main Menu")
	main_menu_button.name = "AudioMainMenuButton"
	main_menu_button.pressed.connect(_show_settings_panel)
	stack.add_child(main_menu_button)
	return panel


func _show_overlay() -> void:
	_return_focus = get_viewport().gui_get_focus_owner()
	_sync_to_viewport()
	_show_settings_panel()
	_overlay.visible = true
	var close_button := _overlay.find_child("CloseSettingsButton", true, false) as Button
	if close_button != null:
		close_button.grab_focus()


func _hide_overlay() -> void:
	_overlay.visible = false
	if is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree():
		_return_focus.grab_focus()


func _show_settings_panel() -> void:
	if _settings_panel != null:
		_settings_panel.visible = true
	if _audio_panel != null:
		_audio_panel.visible = false
	var audio_button := _overlay.find_child("AudioButton", true, false) as Button
	if audio_button != null:
		audio_button.grab_focus()


func _show_audio_panel() -> void:
	if _settings_panel != null:
		_settings_panel.visible = false
	if _audio_panel != null:
		_audio_panel.visible = true
	var main_menu_button := _overlay.find_child("AudioMainMenuButton", true, false) as Button
	if main_menu_button != null:
		main_menu_button.grab_focus()


func _panel(panel_name: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.custom_minimum_size = Vector2(MENU_WIDTH, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _panel_style())
	return panel


func _menu_button(label: String) -> Button:
	var button := Button.new()
	button.name = "%sButton" % label.replace(" ", "")
	button.text = label
	button.custom_minimum_size = Vector2(0, 48)
	button.focus_mode = Control.FOCUS_ALL
	return button


func _volume_row(label_text: String, slider_name: String, value: float, setter: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "%sRow" % slider_name
	row.add_theme_constant_override("separation", 10)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(86, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	var slider := HSlider.new()
	slider.name = slider_name
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = roundi(clampf(value, 0.0, 1.0) * 100.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)

	var percent := Label.new()
	percent.name = "%sPercent" % slider_name
	percent.text = "%d%%" % int(slider.value)
	percent.custom_minimum_size = Vector2(48, 0)
	percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	percent.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(percent)

	slider.value_changed.connect(func(new_value: float) -> void:
		percent.text = "%d%%" % int(new_value)
		setter.call(new_value / 100.0)
	)
	return row


func _round_button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(int(BUTTON_SIZE.x / 2.0))
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 2)
	return style


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.10, 0.08, 0.98)
	style.border_color = Color(0.79, 0.64, 0.35, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.58)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 6)
	return style


func _load_gear_icon() -> Texture2D:
	if _gear_icon != null:
		return _gear_icon
	_gear_icon = load(GEAR_ICON_PATH) as Texture2D
	return _gear_icon
