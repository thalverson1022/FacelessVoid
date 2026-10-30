extends Control
## Draw-only accent: never changes button minimum size, artwork or hit area.
const Style = preload("res://scripts/ui/skill_category_preview_style.gd")
var state
var skill: Skill
var locked := false
var tree_unlock := false
var macro_slot := false
var last_key := ""
var bottom_bar_height := 2.0
func _ready() -> void:
	name = "CategoryIconAccent"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _process(_delta: float) -> void:
	var mode: int = 1 if macro_slot else (2 if tree_unlock else 1) if state.get("is_test_mode") != true else int(state.get_meta("category_tree_icon_style" if tree_unlock else "category_icon_style", 2 if tree_unlock else 1))
	var hover: bool = get_parent() is BaseButton and get_parent().is_hovered()
	var key := "%s/%d/%s/%s" % [Style.enabled(state), mode, hover, size]
	if key != last_key:
		last_key = key
		queue_redraw()
func _draw() -> void:
	if not Style.enabled(state) or not Style.icon_selected(skill): return
	var mode: int = 1 if macro_slot else (2 if tree_unlock else 1) if state.get("is_test_mode") != true else int(state.get_meta("category_tree_icon_style" if tree_unlock else "category_icon_style", 2 if tree_unlock else 1))
	if mode == 3: return
	var color: Color = Style.COLORS[skill.category]
	var hover: bool = get_parent() is BaseButton and get_parent().is_hovered()
	color = color.darkened(0.65 if locked else 0.0 if hover else 0.2)
	if mode == 0 or mode == 2:
		# Follow the actual button's rounded bounding frame, not the artwork.
		var border := get_parent().get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		if border == null: return
		border.bg_color = Style.COLORS[skill.category].darkened(0.85 if locked else 0.62 if hover else 0.72) if mode == 2 else Color.TRANSPARENT
		border.shadow_color = Color.TRANSPARENT
		border.border_color = color
		draw_style_box(border, Rect2(Vector2.ZERO, size))
	elif bottom_bar_height > 2.0:
		draw_rect(Rect2(5, size.y - bottom_bar_height, size.x - 10, bottom_bar_height), color)
	else:
		draw_line(Vector2(5, size.y - 2), Vector2(size.x - 5, size.y - 2), color, 2.0)
