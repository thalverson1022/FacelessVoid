extends Control
## Presentation only: Arctic slows the recorded countdown, never this animation.
var active := false
var elapsed := 0.0
var _rim := StyleBoxFlat.new()

func _ready() -> void:
	name = "ArcticClockAura"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 10
	_rim.bg_color = Color(0.1, 0.45, 0.65, 0.06)
	_rim.set_border_width_all(2)
	_rim.set_corner_radius_all(9)
	_rim.shadow_color = Color(0.35, 0.75, 1.0, 0.28)
	_rim.shadow_size = 5
	hide()

func set_active(value: bool) -> void:
	active = value
	elapsed = 0.0
	visible = value and not CombatEffectIcons.reduced_motion
	queue_redraw()

func _process(delta: float) -> void:
	visible = active and not CombatEffectIcons.reduced_motion
	if not visible: return
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	if not visible: return
	var ring := Rect2(Vector2(-3, -3), size + Vector2(6, 6))
	_rim.border_color = Color(0.55, 0.86, 1.0, 0.65 + 0.12 * sin(elapsed * 2.4))
	draw_style_box(_rim, ring)
	for index in 8:
		var phase := float(index) / 8.0 * TAU + elapsed * 0.35
		var point := size * 0.5 + Vector2(cos(phase) * (size.x * 0.5 + 6), sin(phase) * (size.y * 0.5 + 6))
		draw_circle(point, 1.3, Color(0.8, 0.95, 1.0, 0.55 + 0.25 * sin(phase + elapsed)))
