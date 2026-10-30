extends Control

var fill_color := Color(0.02, 0.018, 0.016, 0.64)
var edge_color := Color(0.0, 0.0, 0.0, 0.58)
var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	if progress <= 0.0:
		return
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.68
	var points := PackedVector2Array([center])
	var start_angle := -PI * 0.5
	var sweep := TAU * progress
	var steps := maxi(8, ceili(48.0 * progress))
	for i in range(steps + 1):
		var angle := start_angle + sweep * (float(i) / float(steps))
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, fill_color)
	draw_arc(center, radius, start_angle, start_angle + sweep, steps, edge_color, 3.0, true)
