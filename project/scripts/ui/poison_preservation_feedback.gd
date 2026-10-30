extends RefCounted
## Shared visual cue for a resolved Serpent's Scales stack preservation.
## Call after popup placement. Only x and outline/shadow styling are animated;
## the caller retains the rise, fade, font size and critical punch.

const WIGGLE_PX := 3.0
const WIGGLE_STEP_SEC := 0.055
const GLOW_HOLD_SEC := 0.16
const GLOW_FADE_SEC := 0.26
const GLOW_COLOR := Color(0.30, 1.0, 0.12, 1.0)
const HALO_COLOR := Color(0.20, 1.0, 0.08, 0.48)


static func apply(label: Label) -> void:
	if not is_instance_valid(label) or not label.is_inside_tree():
		return
	if label.has_meta("poison_stack_preserved"):
		return
	label.set_meta("poison_stack_preserved", true)
	label.set_meta("poison_preservation_active", true)
	var origin_x := label.position.x
	var outline_color := label.get_theme_color("font_outline_color")
	var shadow_color := label.get_theme_color("font_shadow_color")
	var had_outline := label.has_theme_color_override("font_outline_color")
	var had_shadow := label.has_theme_color_override("font_shadow_color")
	var outline_size := label.get_theme_constant("outline_size")
	var shadow_size := label.get_theme_constant("shadow_outline_size")
	var had_outline_size := label.has_theme_constant_override("outline_size")
	var had_shadow_size := label.has_theme_constant_override("shadow_outline_size")
	label.add_theme_constant_override("outline_size", maxi(outline_size, 4))
	label.add_theme_constant_override("shadow_outline_size", maxi(shadow_size, 7))
	label.add_theme_color_override("font_outline_color", GLOW_COLOR)
	label.add_theme_color_override("font_shadow_color", HALO_COLOR)
	var wiggle := label.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Two short sideways oscillations. The rise owns position:y independently.
	for x in [origin_x - WIGGLE_PX, origin_x + WIGGLE_PX, origin_x - WIGGLE_PX, origin_x + WIGGLE_PX, origin_x]:
		wiggle.tween_property(label, "position:x", x, WIGGLE_STEP_SEC)
	var glow := label.create_tween()
	glow.tween_interval(GLOW_HOLD_SEC)
	glow.tween_method(func(weight: float) -> void:
		label.add_theme_color_override("font_outline_color", GLOW_COLOR.lerp(outline_color, weight))
		label.add_theme_color_override("font_shadow_color", HALO_COLOR.lerp(shadow_color, weight))
	, 0.0, 1.0, GLOW_FADE_SEC)
	glow.tween_callback(func() -> void:
		if had_outline: label.add_theme_color_override("font_outline_color", outline_color)
		else: label.remove_theme_color_override("font_outline_color")
		if had_shadow: label.add_theme_color_override("font_shadow_color", shadow_color)
		else: label.remove_theme_color_override("font_shadow_color")
		if had_outline_size: label.add_theme_constant_override("outline_size", outline_size)
		else: label.remove_theme_constant_override("outline_size")
		if had_shadow_size: label.add_theme_constant_override("shadow_outline_size", shadow_size)
		else: label.remove_theme_constant_override("shadow_outline_size")
		label.set_meta("poison_preservation_active", false)
	)
