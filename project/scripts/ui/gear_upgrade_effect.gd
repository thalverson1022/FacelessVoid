class_name GearUpgradeEffect
extends Control
## Shared shop/reward upgrade accent. All geometry stays inside the card.

signal finished

const DURATION_SEC := 0.30
const PEAK_SEC := 0.135
const GOLD := Color(1.0, 0.79, 0.30)

var _tier := GearItem.Tier.BASIC
var _progress := 0.0
var _reduced_motion := false
var _cancelled := false
var _peak_played := false
var _tween: Tween


static func play(card: Control, tier: int, delay: float = 0.0) -> Control:
	if not is_instance_valid(card):
		return null
	var effect = load("res://scripts/ui/gear_upgrade_effect.gd").new()
	effect.name = "GearUpgradeEffect"
	effect._tier = tier
	effect._reduced_motion = CombatEffectIcons.reduced_motion
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect.focus_mode = Control.FOCUS_NONE
	effect.z_index = 10
	card.add_child(effect)
	effect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effect._begin(maxf(delay, 0.0))
	return effect


func _begin(delay: float) -> void:
	_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_ignore_time_scale(true)
	if delay > 0.0:
		_tween.tween_interval(delay)
	_tween.tween_method(_set_progress, 0.0, 0.5, PEAK_SEC)
	_tween.tween_callback(_play_peak)
	_tween.tween_method(_set_progress, 0.5, 1.0, DURATION_SEC - PEAK_SEC)
	_tween.tween_callback(_complete)


func _set_progress(value: float) -> void:
	_progress = clampf(value, 0.0, 1.0)
	queue_redraw()


func _play_peak() -> void:
	if _cancelled or _peak_played:
		return
	if not is_visible_in_tree():
		cancel()
		return
	_peak_played = true
	get_node("/root/AudioManager").play_magic_find_sfx()


func cancel() -> void:
	if _cancelled:
		return
	_cancelled = true
	if _tween != null and _tween.is_valid():
		_tween.kill()
	hide()
	queue_free()


func _complete() -> void:
	if _cancelled:
		return
	finished.emit()
	queue_free()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var strength := sin(_progress * PI)
	if strength <= 0.001:
		return
	var bounds := Rect2(Vector2.ZERO, size)
	if not _reduced_motion:
		var clip := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
		var center := lerpf(-0.7 * size.x, 1.7 * size.x, _progress)
		var width := maxf(size.x * 0.10, 4.0)
		var lean := size.y * 0.42
		# Layered narrow bands soften the stripe without a shader or texture.
		for band in range(-3, 4):
			var left := center + float(band) * width
			var polygon := PackedVector2Array([
				Vector2(left + lean, 0), Vector2(left + width + lean, 0),
				Vector2(left + width - lean, size.y), Vector2(left - lean, size.y)])
			var alpha := strength * (0.48 if band == 0 else 0.25 / float(absi(band)))
			for clipped in Geometry2D.intersect_polygons(polygon, clip):
				# At entry/exit the intersection can collapse to an edge or
				# repeated vertex. Such zero-area fragments cannot be filled.
				if clipped.size() >= 3 and not Geometry2D.triangulate_polygon(clipped).is_empty():
					draw_colored_polygon(clipped, Color(GOLD, alpha))
	var border := StyleBoxFlat.new()
	border.draw_center = false
	border.border_color = Color(CardStyle.rarity_border_color(_tier).lerp(GOLD, 0.65).lightened(0.15), strength)
	border.set_border_width_all(3)
	border.set_corner_radius_all(4)
	draw_style_box(border, bounds)
