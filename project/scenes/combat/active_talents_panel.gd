extends PanelContainer
## Fixed subclass summary; talent details and allocation live in Talent Trees.

signal open_talents_pressed

const CARD_TITLE_FONT_SIZE := 20
const POINTS_FONT_SIZE := 28
const OPEN_BUTTON_SIZE := Vector2(176, 36)
const TALENT_GHOST_DURATION_SEC := 0.28
const TALENT_GHOST_ARC_HEIGHT := 26.0
const TALENT_GHOST_SETTLE_SEC := 0.10

## Same pattern as talent_panel.gd: defaults to Adventure's BuildState but
## stays untyped so a future practice state can reuse this panel.
var state = BuildState
var enable_open_button_attention := true

var _points_badge: PanelContainer
var _points_row: HBoxContainer
var _points_icon: TextureRect
var _points_label: Label
var _talents_box: HBoxContainer
var _open_button: Button
var _button_blink_tween: Tween


func _ready() -> void:
	add_theme_stylebox_override("panel", CardStyle.make_stylebox())

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	add_child(content)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	content.add_child(header)

	var title := Label.new()
	title.text = "Subclass"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	title.theme_type_variation = &"PanelHeader"
	title.add_theme_font_size_override("font_size", CARD_TITLE_FONT_SIZE)
	header.add_child(title)

	_points_badge = PanelContainer.new()
	_points_badge.tooltip_text = "Talent points spent / earned"
	_points_badge.size_flags_horizontal = Control.SIZE_SHRINK_END
	var points_badge_style := CardStyle.make_action_button_stylebox(UIColors.PANEL_DEEP, UIColors.PANEL_BORDER, "normal")
	points_badge_style.content_margin_left = 8
	points_badge_style.content_margin_right = 10
	points_badge_style.content_margin_top = 4
	points_badge_style.content_margin_bottom = 6
	_points_badge.add_theme_stylebox_override("panel", points_badge_style)
	header.add_child(_points_badge)

	_points_row = HBoxContainer.new()
	_points_row.alignment = BoxContainer.ALIGNMENT_END
	_points_row.add_theme_constant_override("separation", 7)
	_points_row.tooltip_text = "Talent points spent / earned"
	_points_badge.add_child(_points_row)

	_points_icon = CardStyle.make_pixel_icon(CardStyle.talent_point_icon(), Vector2(34, 34))
	_points_row.add_child(_points_icon)

	_points_label = Label.new()
	_points_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_points_label.add_theme_color_override("font_outline_color", UIColors.TEXT_OUTLINE)
	_points_label.add_theme_constant_override("outline_size", 4)
	_points_label.add_theme_font_size_override("font_size", POINTS_FONT_SIZE)
	_points_row.add_child(_points_label)

	_talents_box = HBoxContainer.new()
	_talents_box.name = "SubclassList"
	_talents_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_talents_box.add_theme_constant_override("separation", 6)
	content.add_child(_talents_box)

	_open_button = Button.new()
	_open_button.custom_minimum_size = OPEN_BUTTON_SIZE
	_open_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_open_button.pressed.connect(func(): open_talents_pressed.emit())
	content.add_child(_open_button)

	state.build_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var spent: int = state.ranked_build.points_spent() if state.ranked_build != null else PassiveAllocator.points_spent(state.selected_talents)
	var earned: int = state.earned_talent_points
	var remaining: int = earned - spent
	_points_label.text = ": %d/%d" % [spent, earned]
	_points_label.add_theme_color_override(
		"font_color", UIColors.TEXT_GOLD if remaining > 0 else UIColors.TEXT_NORMAL
	)
	_open_button.text = "Talent Trees"
	_open_button.tooltip_text = "Open Talent Trees to spend earned points" if remaining > 0 else "Open Talent Trees"
	_set_open_button_attention(enable_open_button_attention and remaining > 0)

	for child in _talents_box.get_children():
		_talents_box.remove_child(child)
		child.queue_free()
	for slot in range(2):
		if slot == 1:
			var divider := Label.new()
			divider.name = "SubclassDivider"
			divider.text = "|"
			divider.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			divider.add_theme_color_override("font_color", UIColors.TEXT_DISABLED)
			_talents_box.add_child(divider)
		var tree: SubclassTree = null
		if state.ranked_build != null:
			tree = state.ranked_build.primary_tree() if slot == 0 else state.ranked_build.secondary_tree()
		elif slot < state.selected_trees.size():
			tree = state.selected_trees[slot]
		_talents_box.add_child(_build_subclass_row(tree, slot))


func _build_subclass_row(tree: SubclassTree, slot: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "PrimarySubclass" if slot == 0 else "SecondarySubclass"
	row.custom_minimum_size.y = 32
	row.add_theme_constant_override("separation", 4)
	if tree != null and tree.icon != null:
		var icon := CardStyle.make_pixel_icon(tree.icon, Vector2(32, 32))
		icon.name = "SubclassIcon"
		row.add_child(icon)
	else:
		var empty_icon := ColorRect.new()
		empty_icon.name = "EmptySubclassIcon"
		empty_icon.color = Color(0.45, 0.45, 0.45)
		empty_icon.custom_minimum_size = Vector2(32, 32)
		empty_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(empty_icon)
	var label := Label.new()
	label.name = "SubclassName"
	label.text = tree.display_name if tree != null else "none"
	label.add_theme_font_size_override("font_size", 14)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", CardStyle.ACCENT_COLOR if tree != null else UIColors.TEXT_DISABLED)
	row.add_child(label)
	return row



func _set_open_button_attention(enabled: bool) -> void:
	if _open_button == null:
		return
	if not enabled:
		if _button_blink_tween != null:
			_button_blink_tween.kill()
			_button_blink_tween = null
		_open_button.modulate = Color.WHITE
		return
	if _button_blink_tween != null and _button_blink_tween.is_running():
		return
	_open_button.modulate = Color.WHITE
	_button_blink_tween = create_tween()
	_button_blink_tween.set_loops()
	_button_blink_tween.tween_property(_open_button, "modulate", UIColors.FEEDBACK_WARNING_PULSE, 0.25)
	_button_blink_tween.tween_property(_open_button, "modulate", Color.WHITE, 0.25)



func animate_talent_points_from_rect(source_rect: Rect2, amount: int, wait_for_completion: bool = false) -> void:
	if amount <= 0:
		return
	await get_tree().process_frame
	var played := _play_talent_point_motion(source_rect, _global_rect_for(_points_icon), amount)
	_pulse_points_badge()
	if wait_for_completion and played:
		await get_tree().create_timer(TALENT_GHOST_DURATION_SEC + TALENT_GHOST_SETTLE_SEC).timeout


func _play_talent_point_motion(from_rect: Rect2, to_rect: Rect2, amount: int) -> bool:
	if from_rect.size == Vector2.ZERO or to_rect.size == Vector2.ZERO:
		return false
	var ghost := HBoxContainer.new()
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.modulate = Color(1, 1, 1, 0.88)
	ghost.z_index = 220
	ghost.top_level = true
	ghost.add_theme_constant_override("separation", 4)
	ghost.add_child(CardStyle.make_pixel_icon(CardStyle.talent_point_icon(), Vector2(22, 22)))
	var label := Label.new()
	label.text = "x %d" % amount
	label.add_theme_color_override("font_color", UIColors.TEXT_GOLD)
	label.add_theme_color_override("font_outline_color", UIColors.TEXT_OUTLINE)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_font_size_override("font_size", 18)
	ghost.add_child(label)
	add_child(ghost)
	ghost.global_position = from_rect.get_center() - Vector2(18, 12)

	var target := to_rect.get_center() - Vector2(18, 12)
	var midpoint := (ghost.global_position + target) * 0.5 + Vector2(0, -TALENT_GHOST_ARC_HEIGHT)
	var start := ghost.global_position
	var motion := func(t: float) -> void:
		if is_instance_valid(ghost):
			ghost.global_position = _quadratic_bezier(start, midpoint, target, t)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_method(motion, 0.0, 1.0, TALENT_GHOST_DURATION_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "scale", Vector2(0.85, 0.85), TALENT_GHOST_DURATION_SEC).from(Vector2(1.12, 1.12))
	tween.tween_property(ghost, "modulate:a", 0.0, TALENT_GHOST_DURATION_SEC).from(0.88).set_delay(TALENT_GHOST_DURATION_SEC * 0.58)
	tween.set_parallel(false)
	tween.tween_callback(func() -> void:
		if is_instance_valid(ghost):
			ghost.queue_free()
	)
	return true


func _pulse_points_badge() -> void:
	if _points_badge == null or not _points_badge.is_inside_tree():
		return
	var tween := create_tween()
	tween.tween_property(_points_badge, "scale", Vector2(1.08, 1.08), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_points_badge, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _global_rect_for(node: Control) -> Rect2:
	if node == null or not node.is_inside_tree():
		return Rect2()
	return node.get_global_rect()


func _quadratic_bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var first := a.lerp(b, t)
	var second := b.lerp(c, t)
	return first.lerp(second, t)
