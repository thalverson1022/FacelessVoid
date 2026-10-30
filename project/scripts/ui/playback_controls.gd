class_name PlaybackControls
extends HBoxContainer
## The playback control strip: 1x/2x/4x speed buttons plus Skip as a
## persistent speed-mode choice.
## Extracted from combat_screen.gd's inline playback/VFX layer
## (docs/Phase_3_Technical_Debt_Architecture_Cleanup.md Phase 4).
##
## This widget owns its own construction and visual state (which speed
## button reads as "active", the time label's text) but not the actual
## playback speed/skip logic -- combat_screen.gd (soon a dedicated playback
## presenter, in a later step of this same extraction) owns the
## CombatPlayback instance and decides what a speed selection or skip
## actually does, then calls back into set_active_speed()/set_time_text() to
## reflect it. `speed_selected`/`skip_pressed` are the only way in.

signal speed_selected(speed: float)
signal skip_pressed

## Selectable playback speed multipliers, in button order. First entry is
## the default every playback starts at.
const SPEED_OPTIONS: Array[float] = [1.0, 2.0, 4.0]

var _time_label: Label
var _playback_label: Label
var _speed_buttons: Array[Button] = []
var _skip_button: Button


func _ready() -> void:
	visible = true
	add_theme_constant_override("separation", 6)

	_time_label = Label.new()
	_time_label.visible = false
	add_child(_time_label)

	_playback_label = Label.new()
	_playback_label.name = "PlaybackLabel"
	_playback_label.text = "playback:"
	_playback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_playback_label.add_theme_font_size_override("font_size", 18)
	_playback_label.add_theme_color_override("font_color", UIColors.TEXT_NORMAL)
	add_child(_playback_label)

	_speed_buttons = []
	for speed in SPEED_OPTIONS:
		var speed_button := Button.new()
		speed_button.text = "%dx" % int(speed)
		_style_mode_button(speed_button)
		speed_button.pressed.connect(func(): speed_selected.emit(speed))
		_speed_buttons.append(speed_button)
		add_child(speed_button)

	_skip_button = Button.new()
	_skip_button.name = "SkipButton"
	_skip_button.text = "Skip"
	_style_mode_button(_skip_button)
	_skip_button.pressed.connect(func(): skip_pressed.emit())
	add_child(_skip_button)
	set_active_speed(SPEED_OPTIONS[0])


## Reflects `speed` as the active selection by disabling its matching button,
## so the active speed is visible at a glance.
func set_active_speed(speed: float) -> void:
	for i in _speed_buttons.size():
		_speed_buttons[i].disabled = is_equal_approx(SPEED_OPTIONS[i], speed)
	if _skip_button != null:
		_skip_button.disabled = false


func set_skip_mode_active(is_active: bool) -> void:
	for button in _speed_buttons:
		button.disabled = false
	if _skip_button != null:
		_skip_button.disabled = is_active


func set_time_text(text: String) -> void:
	_time_label.text = text


func _style_mode_button(button: Button) -> void:
	button.custom_minimum_size = Vector2(42, 22)
	button.add_theme_font_size_override("font_size", 11)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = UIColors.PANEL_DEEP if state == "normal" else UIColors.BUTTON_FILL
		if state == "disabled":
			style.bg_color = UIColors.BUTTON_FILL
		style.border_color = UIColors.PANEL_BORDER if state != "disabled" else UIColors.BUTTON_EDGE_LIGHT
		style.set_border_width_all(1)
		style.border_width_bottom = 2
		style.set_corner_radius_all(4)
		style.content_margin_left = 6
		style.content_margin_right = 6
		style.content_margin_top = 2
		style.content_margin_bottom = 3
		button.add_theme_stylebox_override(state, style)
