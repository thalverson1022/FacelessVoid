extends PanelContainer
## Compact Adventure dashboard summary of the currently selected talents.
## The full talent tree still exists, but it opens in combat_screen.gd's
## Talent Trees overlay so the left column reads as "what is active now"
## instead of inviting constant per-fight tree tweaking.

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
var _talents_scroll: ScrollContainer
var _talents_box: VBoxContainer
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
	title.text = "Active Talents"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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

	_talents_scroll = ScrollContainer.new()
	_talents_scroll.name = "ActiveTalentsScroll"
	_talents_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_talents_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_talents_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_talents_scroll)

	_talents_box = VBoxContainer.new()
	_talents_box.name = "ActiveTalentsList"
	_talents_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_talents_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_talents_box.add_theme_constant_override("separation", 6)
	_talents_scroll.add_child(_talents_box)

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
		child.queue_free()

	if state.selected_trees.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No subclass selected."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_color_override("font_color", UIColors.TEXT_DISABLED)
		_talents_box.add_child(empty_label)
		return

	for tree in state.selected_trees:
		_talents_box.add_child(_build_tree_section(tree))


func _build_tree_section(tree: SubclassTree) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 4)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_BEGIN
	header.add_theme_constant_override("separation", 8)
	section.add_child(header)

	if tree.icon != null:
		header.add_child(CardStyle.make_pixel_icon(tree.icon, Vector2(32, 32)))

	var tree_label := Label.new()
	tree_label.text = tree.display_name
	tree_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tree_label.add_theme_color_override("font_color", CardStyle.ACCENT_COLOR)
	header.add_child(tree_label)

	var intrinsic_label := Label.new()
	intrinsic_label.text = "Intrinsic: %s" % _intrinsic_description(tree)
	intrinsic_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intrinsic_label.add_theme_font_size_override("font_size", 13)
	section.add_child(intrinsic_label)

	var talents_label := Label.new()
	talents_label.text = "%s Talents" % tree.display_name
	talents_label.add_theme_font_size_override("font_size", 13)
	talents_label.add_theme_color_override("font_color", UIColors.TEXT_GOLD)
	section.add_child(talents_label)

	var selected_for_tree: Array[Talent] = []
	var candidates: Array[Talent] = tree.talents if state.ranked_build != null else state.selected_talents
	for talent in candidates:
		if tree.talents.has(talent) and (state.ranked_build == null or state.ranked_build.rank_of(talent.id) > 0):
			selected_for_tree.append(talent)
	if selected_for_tree.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No %s talents selected." % tree.display_name
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_font_size_override("font_size", 13)
		empty_label.add_theme_color_override("font_color", UIColors.TEXT_DISABLED)
		section.add_child(empty_label)
	else:
		for talent in selected_for_tree:
			section.add_child(_build_talent_row(talent))

	return section


func _build_talent_row(talent: Talent) -> VBoxContainer:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 1)

	var name_label := Label.new()
	name_label.text = talent.display_name + (" %d/%d" % [state.ranked_build.rank_of(talent.id), talent.max_ranks] if state.ranked_build != null else "")
	name_label.add_theme_color_override("font_color", CardStyle.ACCENT_COLOR)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(name_label)

	if state.ranked_build != null:
		var formatter=preload("res://scripts/ui/talent_hover_formatter.gd")
		var rank: int=state.ranked_build.rank_of(talent.id)
		preload("res://scripts/ui/talent_effect_rows.gd").add_to(row,formatter.rank_rows(talent,rank),13,0,0,1.0,"ActiveTalentEffect")
	else:
		var detail_label:=Label.new()
		detail_label.text=_talent_summary(talent)
		detail_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		detail_label.add_theme_font_size_override("font_size",13)
		row.add_child(detail_label)
	return row


func _intrinsic_description(tree: SubclassTree) -> String:
	var override_text:=preload("res://scripts/ui/talent_hover_formatter.gd").intrinsic_override(tree)
	if override_text!="": return preload("res://scripts/ui/presentation_keywords.gd").normalize(override_text)
	if tree.intrinsic_text != "":
		return preload("res://scripts/ui/presentation_keywords.gd").normalize(tree.intrinsic_text)
	var lines: PackedStringArray = []
	for skill in tree.unlocked_skills:
		lines.append("Unlocks %s" % skill.display_name)
	for modifier in tree.innate_modifiers:
		lines.append(StatModifierFormatter.format(modifier))
	for augment in tree.skill_augments:
		lines.append(_skill_augment_description(augment))
	if lines.is_empty():
		return "None"
	return preload("res://scripts/ui/presentation_keywords.gd").normalize(", ".join(lines))


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


func _skill_augment_description(augment: SkillAugment) -> String:
	var target_names: PackedStringArray = []
	for target_id in augment.target_skill_ids:
		target_names.append(_skill_name_for_id(target_id))
	var effect_names: PackedStringArray = []
	for effect in augment.extra_effects:
		if effect is PoisonDamageEffect:
			var poison_effect: PoisonDamageEffect = effect
			effect_names.append("+%d poison stack%s" % [poison_effect.stacks_applied, "" if poison_effect.stacks_applied == 1 else "s"])
		elif effect is PoisonResistanceReductionEffect:
			var resist_effect: PoisonResistanceReductionEffect = effect
			effect_names.append("-%d%% resistance" % roundi(resist_effect.reduction_fraction * 100.0))
		elif effect is StackScalingPhysicalDamageEffect:
			var stack_effect: StackScalingPhysicalDamageEffect = effect
			effect_names.append("+%.0f damage per poison stack" % stack_effect.damage_per_stack)
		elif effect is StealGoldOnCritEffect:
			var steal_effect: StealGoldOnCritEffect = effect
			effect_names.append("crits steal %dg" % steal_effect.amount)
	if target_names.is_empty() or effect_names.is_empty():
		return "Enhances selected skills"
	return "%s gain %s" % [", ".join(target_names), ", ".join(effect_names)]


func _skill_name_for_id(skill_id: String) -> String:
	if state.selected_class != null:
		for skill in state.selected_class.base_skills:
			if skill.id == skill_id:
				return skill.display_name
		for tree in state.selected_class.trees:
			for skill in tree.unlocked_skills:
				if skill.id == skill_id:
					return skill.display_name
			for talent in tree.talents:
				for skill in talent.unlocked_skills:
					if skill.id == skill_id:
						return skill.display_name
	return skill_id


func _talent_summary(talent: Talent) -> String:
	var lines: PackedStringArray = []
	for modifier in talent.stat_modifiers:
		lines.append(StatModifierFormatter.format(modifier))
	for skill in talent.unlocked_skills:
		lines.append("Unlocks %s" % skill.display_name)
	for trigger in talent.triggered_skill_effects:
		if trigger != null and trigger.skill != null:
			lines.append("%d%% chance: %s" % [roundi(trigger.chance * 100.0), trigger.skill.display_name])
	if lines.is_empty():
		return "No effect yet"
	return ", ".join(lines)


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
