class_name CombatPopupLayout
extends RefCounted
## Bounded normal/tick lanes below status values, separate from accepted echo lanes.
## Existing outcomes, colors, crit cross-out and numeric conventions stay intact.
static func place(popup: Control, layer: Control, stage, tick: bool) -> float:
	var area := Rect2(Vector2.ZERO,layer.size)
	if stage != null:
		var global_area: Rect2 = stage.play_area_global_rect()
		area = Rect2(layer.get_global_transform().affine_inverse() * global_area.position,global_area.size)
	# Practice places real action buttons over the bottom of the stage art.
	# Keep both normal lanes above that live footer; the right-side tick band
	# remains separate from the centered buttons and accepted ghost labels.
	var footer = layer.get_meta("footer_row") if layer.has_meta("footer_row") else null
	if not tick and is_instance_valid(footer) and footer.is_visible_in_tree():
		var footer_top: float = (layer.get_global_transform().affine_inverse() * footer.get_global_rect().position).y
		area.size.y = minf(area.size.y, footer_top - area.position.y - 8.0)
	var lane := 2 if tick else int(layer.get_meta("popup_lane",0)) % 2
	if not tick: layer.set_meta("popup_lane",lane+1)
	# Normal messages use the left band; Poison has a dedicated right band.
	var width := area.size.x * (0.20 if tick else 0.62) - 20.0
	var fit := minf(1.0,minf(width / (maxf(popup.size.x,1.0)*1.35),60.0/maxf(popup.size.y,1.0)))
	# Centered punch pivots shift the visible rectangle when a wide composite
	# is fitted down. Reserve both scale endpoints rather than its base size.
	var low := 0.92 * fit
	var high := 1.35 * fit
	var low_origin := popup.pivot_offset * (1.0 - low)
	var high_origin := popup.pivot_offset * (1.0 - high)
	var left := minf(low_origin.x, high_origin.x)
	var top := minf(low_origin.y, high_origin.y)
	var bottom := maxf(low_origin.y + popup.size.y * low, high_origin.y + popup.size.y * high)
	var x := area.position.x + (area.size.x * 0.78 if tick else 32.0) - left
	var y := area.end.y - bottom - (16.0 if lane != 0 else 104.0)
	popup.position = Vector2(x,maxf(area.position.y+190.0-top,y))
	popup.set_meta("cue_lane",lane)
	# A new message replaces the oldest message in its lane. Hidden old nodes
	# finish their existing tweens so shared active-count bookkeeping stays exact.
	for old in layer.get_children():
		if old != popup and old is Control and old.has_meta("cue_lane") and old.get_meta("cue_lane") == lane:
			old.hide()
	return fit
