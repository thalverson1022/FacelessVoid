extends SceneTree

const Effect := preload("res://scripts/ui/gear_upgrade_effect.gd")
const OUT := "res://reports/m9_gear_upgrade_effect/"
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func wait_ui(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout

func snapshot(label: String) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.save_png(OUT + label + ".png") == OK, "Render saved: " + label)
	return image

func run() -> void:
	await process_frame
	root.content_scale_size = root.size
	DirAccess.make_dir_recursive_absolute(OUT)
	var audio = root.get_node("AudioManager")
	var card := Button.new()
	card.position = Vector2(100, 70)
	card.size = Vector2(112, 112)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var item := GearItem.new()
	item.tier = GearItem.Tier.MASTER
	CardStyle.style_shop_item_box(card, item)
	root.add_child(card)
	var position_before := card.position
	var scale_before := card.scale
	var style_before := card.get_theme_stylebox("normal")
	var baseline := await snapshot("baseline")
	var before: int = audio.magic_find_sfx_play_count
	CombatEffectIcons.reduced_motion = false
	var effect = Effect.play(card, GearItem.Tier.MASTER)
	effect._tween.pause()
	effect._set_progress(0.5)
	var peak := await snapshot("peak_shimmer")
	check(effect.mouse_filter == Control.MOUSE_FILTER_IGNORE and effect.focus_mode == Control.FOCUS_NONE, "Accent cannot intercept mouse or focus")
	check(effect.position == Vector2.ZERO and effect.size == card.size, "Accent exactly follows the card bounds")
	check(card.position == position_before and card.scale == scale_before and card.get_theme_stylebox("normal") == style_before, "Card position, scale and style remain unchanged")
	var changed_inside := 0
	var changed_outside := 0
	var bounds := card.get_global_rect()
	for y in baseline.get_height():
		for x in baseline.get_width():
			if baseline.get_pixel(x, y) != peak.get_pixel(x, y):
				if bounds.has_point(Vector2(x, y)): changed_inside += 1
				else: changed_outside += 1
	check(changed_inside > 200 and changed_outside == 0, "Actual rendered shimmer/pulse is visible and clipped to card bounds")
	# Exercise clipped stripes entering/leaving every edge, including the
	# zero-area intersections that occur between the saved keyframes.
	for step in range(131):
		effect._set_progress(float(step) / 130.0)
		await RenderingServer.frame_post_draw
	effect._set_progress(1.0)
	var ended := await snapshot("pulse_end")
	check(ended.get_data() == baseline.get_data(), "Completed pulse leaves no visual residue")
	effect.cancel()
	await process_frame
	CombatEffectIcons.reduced_motion = true
	effect = Effect.play(card, GearItem.Tier.MASTER)
	effect._tween.pause()
	effect._set_progress(0.5)
	var reduced := await snapshot("reduced_motion")
	check(reduced.get_pixel(156, 126) == baseline.get_pixel(156, 126), "Reduced motion leaves the interior untouched")
	check(reduced.get_data() != baseline.get_data(), "Reduced motion still provides border feedback")
	effect.cancel()
	await process_frame
	check(audio.magic_find_sfx_play_count == before, "Static visual inspection has not triggered sound")
	CombatEffectIcons.reduced_motion = false
	effect = Effect.play(card, GearItem.Tier.EPIC, 0.3)
	await wait_ui(0.12)
	effect.cancel()
	await wait_ui(0.7)
	check(audio.magic_find_sfx_play_count == before, "Cancel before delayed peak suppresses sound")
	check(not is_instance_valid(effect), "Cancelled accent removes itself")
	Engine.time_scale = 0.25
	effect = Effect.play(card, GearItem.Tier.EPIC)
	var completion := [0]
	effect.finished.connect(func(): completion[0] += 1)
	await wait_ui(Effect.PEAK_SEC * 0.4)
	check(audio.magic_find_sfx_play_count == before, "Sound waits for brightest point")
	await wait_ui(Effect.PEAK_SEC * 0.8)
	check(audio.magic_find_sfx_play_count == before + 1 and effect._peak_played, "Brightest point plays exactly one cue")
	await wait_ui(0.3)
	check(not is_instance_valid(effect) and completion[0] == 1, "UI-time effect finishes once despite combat speed")
	check(audio.magic_find_sfx_play_count == before + 1, "Completion does not duplicate peak sound")
	Engine.time_scale = 1.0
	CombatEffectIcons.reduced_motion = true
	effect = Effect.play(card, GearItem.Tier.EPIC)
	await wait_ui(0.5)
	check(not is_instance_valid(effect) and audio.magic_find_sfx_play_count == before + 2, "Reduced-motion border fade keeps one peak cue")
	CombatEffectIcons.reduced_motion = false
	audio.cancel_magic_find_sfx()
	card.queue_free()
	await process_frame
	if failures.is_empty(): print("PASS: rendered clipped shimmer, static card/style, reduced-motion fade, peak timing, UI time and cancellation")
	else: print("FAILED: ", failures)
	quit(0 if failures.is_empty() else 1)
