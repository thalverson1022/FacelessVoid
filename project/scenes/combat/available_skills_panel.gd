extends PanelContainer
## Compact skill palette: click to append, hover for current-build information.

const CARD_TITLE_FONT_SIZE := 20
const SKILL_ICON_SIZE := Vector2(40, 40)
const BUTTON_MIN_SIZE := Vector2(48, 48)
const BUTTON_CORNER_RADIUS := 6
const TEST_ICONS := preload("res://scripts/ui/test_mode_skill_icons.gd")
const TEST_ICON_SHADER := preload("res://scripts/ui/rounded_skill_icon.gdshader")
const SkillTooltipFormatterScript := preload("res://scripts/ui/skill_tooltip_formatter.gd")

## P2:R10: see talent_panel.gd's `state` comment -- same pattern, same
## default, same untyped declaration reason.
var state = BuildState

var _skills_box: HFlowContainer
var _shown_ids: Array = []



func _ready() -> void:
	add_theme_stylebox_override("panel", CardStyle.make_stylebox())

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	add_child(content)

	var title := Label.new()
	title.text = "Available Skills"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.theme_type_variation = &"PanelHeader"
	title.add_theme_font_size_override("font_size", CARD_TITLE_FONT_SIZE)
	var header := HBoxContainer.new()
	content.add_child(header)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	if state.get("is_test_mode") == true:
		var comparison := OptionButton.new()
		comparison.name = "CategoryIconStyle"
		comparison.add_item("Outline")
		comparison.add_item("Bottom edge")
		comparison.add_item("Filled box")
		comparison.add_item("Off")
		comparison.select(int(state.get_meta("category_icon_style", 1)))
		comparison.tooltip_text = "Test Mode icon accents: Attack red, Debuff violet, Self Buff blue."
		comparison.add_theme_font_override("font", preload("res://assets/fonts/VT323-Regular.ttf"))
		comparison.add_theme_font_size_override("font_size", 18)
		header.add_child(comparison)
		comparison.item_selected.connect(func(index): state.set_meta("category_icon_style", index))

	_skills_box = HFlowContainer.new()
	_skills_box.add_theme_constant_override("h_separation", 8)
	_skills_box.add_theme_constant_override("v_separation", 8)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 60
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	content.add_child(scroll)
	_skills_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_skills_box)

	state.build_changed.connect(_refresh)
	state.lock_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var skills: Array[Skill] = state.unlocked_skills()
	var ids: Array = skills.map(func(value): return value.id)
	if ids == _shown_ids and _skills_box.get_child_count() == skills.size():
		for i in skills.size():
			_skills_box.get_child(i).tooltip_text = _tooltip_for(skills[i])
		return
	_shown_ids = ids
	var at_cap: bool = state.rotation.size() >= BuildResolver.MAX_ROTATION_SIZE
	for child in _skills_box.get_children():
		if child is Button:
			child.disabled = false
		_skills_box.remove_child(child)
		child.queue_free()
	for skill in state.unlocked_skills():
		_skills_box.add_child(_build_button(skill, at_cap))


## Compact icon button; the hover provider resolves current build values.
func _build_button(skill: Skill, _at_cap: bool = false) -> Button:
	var padding: Vector2 = Vector2(4, 2)
	var bottom_padding: float = 6.0
	var content_disabled := false
	var content := MarginContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("margin_left", int(padding.x))
	content.add_theme_constant_override("margin_top", int(padding.y))
	content.add_theme_constant_override("margin_right", int(padding.x))
	content.add_theme_constant_override("margin_bottom", int(bottom_padding))

	var label_row := HBoxContainer.new()
	label_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_row.alignment = BoxContainer.ALIGNMENT_CENTER
	label_row.add_theme_constant_override("separation", 8)
	content.add_child(label_row)

	if skill.icon != null:
		var icon := TextureRect.new()
		icon.name = "SkillIcon"
		icon.texture = TEST_ICONS.icon_for(skill.id, skill.icon)
		icon.custom_minimum_size = SKILL_ICON_SIZE
		var rounded := ShaderMaterial.new()
		rounded.shader = TEST_ICON_SHADER
		icon.material = rounded
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = UIColors.ICON_DISABLED if content_disabled else Color.WHITE
		label_row.add_child(icon)
	else:
		var first_letter := Label.new()
		first_letter.text = skill.display_name.substr(0, 1)
		first_letter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		first_letter.add_theme_color_override("font_color", UIColors.TEXT_DISABLED if content_disabled else CardStyle.ACCENT_COLOR)
		label_row.add_child(first_letter)

	var button := IconTooltipButton.new()
	button.tooltip_icon = skill.icon
	button.pressed.connect(func(): _on_skill_pressed(skill))
	button.tooltip_provider = func(): return _tooltip_for(skill)
	button.skill_hover_provider = func(): return preload("res://scripts/ui/skill_hover_formatter.gd").model(skill,state)
	button.tooltip_text = _tooltip_for(skill)
	button.disabled = content_disabled
	button.add_child(content)
	_apply_button_style(button)
	var category_style = preload("res://scripts/ui/skill_category_preview_style.gd")
	if category_style.icon_selected(skill):
		var accent = preload("res://scripts/ui/skill_category_icon_accent.gd").new()
		accent.state = state
		accent.skill = skill
		accent.bottom_bar_height = 6.0
		button.add_child(accent)
		button.move_child(accent, 0)

	var content_min: Vector2 = label_row.get_combined_minimum_size()
	var minimum_size: Vector2 = BUTTON_MIN_SIZE
	button.custom_minimum_size = Vector2(
		maxf(minimum_size.x, content_min.x + padding.x * 2.0),
		maxf(minimum_size.y, content_min.y + padding.y + bottom_padding)
	)
	content.set_anchors_preset(Control.PRESET_FULL_RECT)

	return button


func _tooltip_for(skill: Skill) -> String:
	return preload("res://scripts/ui/skill_hover_formatter.gd").plain_text(preload("res://scripts/ui/skill_hover_formatter.gd").model(skill,state))


## Short, comma-joined effect summary derived straight from the skill's own
## SkillEffect resources -- shown in the hover tooltip (see _tooltip_for())
## only, not as an always-visible caption (removed in the P2:R7
## playtest-feedback pass, see this file's header comment). Never hardcodes
## numbers -- every value is read off `effect`.
func _skill_effect_summary(skill: Skill) -> String:
	return SkillTooltipFormatterScript.effect_summary(skill, state)


func _on_skill_pressed(skill: Skill) -> void:
	if state.build_locked or state.rotation.size() >= BuildResolver.MAX_ROTATION_SIZE or (state is TrainingRoomState and state.allocation_locked):
		return
	var rotation: Array[Skill] = state.rotation.duplicate()
	rotation.append(skill)
	state.set_rotation(rotation)


func _apply_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _make_button_style(UIColors.PANEL_DEEP, UIColors.STRUCTURE_LINE_LIGHT, 1, "normal"))
	button.add_theme_stylebox_override("hover", _make_button_style(UIColors.PANEL, UIColors.ACCENT, 2, "hover"))
	button.add_theme_stylebox_override("pressed", _make_button_style(UIColors.BUTTON_FILL_PRESSED, UIColors.ACCENT, 2, "pressed"))
	button.add_theme_stylebox_override("focus", _make_button_style(UIColors.PANEL, UIColors.ACCENT, 2, "focus"))
	button.add_theme_stylebox_override("disabled", _make_button_style(UIColors.PANEL_DISABLED, UIColors.STRUCTURE_LINE, 1, "disabled"))

	var normal := button.get_theme_stylebox("normal") as StyleBoxFlat
	normal.bg_color = Color("28282b")


func _make_button_style(bg_color: Color, border_color: Color, border_width: int, state_name: String) -> StyleBoxFlat:
	return CardStyle.make_slot_stylebox(bg_color, border_color, border_width, state_name)
