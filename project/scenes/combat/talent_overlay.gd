extends Control
## Talent Trees modal: the full talent tree lives here, opened on demand from
## the Active Talents dashboard summary. Extracted from combat_screen.gd's
## inline overlay builder (docs/Phase_3_Technical_Debt_Architecture_Cleanup.md
## Phase 3) -- a pure informational/allocation view, so it stays dismissable
## on an outside click, matching its behavior before extraction.

signal secondary_tree_chosen(tree: SubclassTree)

const TALENT_SCENE := preload("res://scenes/combat/talent_panel.tscn")
const CONTENT_BASE_SIZE := Vector2(940, 740)
const SCROLL_BASE_SIZE := Vector2(900, 660)
const VIEWPORT_PADDING := Vector2(96, 96)
const CONTENT_MIN_SIZE := Vector2(560, 360)
const SCROLL_CHROME_SIZE := Vector2(40, 80)

var _talent_panel
var _content: VBoxContainer
var _scroll: ScrollContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

	var panel := CardStyle.build_modal_panel(self, true, true)
	var style := CardStyle.make_stylebox(18)
	style.set_border_width_all(3)
	panel.add_theme_stylebox_override("panel", style)

	_content = VBoxContainer.new()
	_content.custom_minimum_size = CONTENT_BASE_SIZE
	_content.add_theme_constant_override("separation", 10)
	panel.add_child(_content)

	var header := HBoxContainer.new()
	var title := Label.new()
	title.text = "Talent Trees"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.theme_type_variation = &"PanelHeader"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", CardStyle.ACCENT_COLOR)
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(func(): visible = false)
	header.add_child(close_button)
	_content.add_child(header)

	_scroll = ScrollContainer.new()
	_scroll.name = "TalentTreeScroll"
	_scroll.custom_minimum_size = SCROLL_BASE_SIZE
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_child(_scroll)

	_talent_panel = TALENT_SCENE.instantiate()
	_talent_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_talent_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_talent_panel.secondary_tree_chosen.connect(func(tree): secondary_tree_chosen.emit(tree))
	_scroll.add_child(_talent_panel)
	var navigation := preload("res://scripts/ui/talent_modal_navigation.gd").new()
	navigation.name = "TalentKeyboardNavigation"
	self.add_child(navigation)
	_talent_panel.minimum_size_changed.connect(_resize_to_viewport.call_deferred)
	if get_viewport() != null:
		get_viewport().size_changed.connect(_resize_to_viewport)
	resized.connect(_resize_to_viewport)
	_resize_to_viewport()


func show_overlay() -> void:
	if _talent_panel != null and _talent_panel.has_method("refresh_panel"):
		_talent_panel.refresh_panel()
	_resize_to_viewport()
	visible = true


func _resize_to_viewport() -> void:
	if _content == null or _scroll == null:
		return
	var available := size - VIEWPORT_PADDING
	_content.custom_minimum_size = Vector2(minf(CONTENT_BASE_SIZE.x, available.x), 0)
	var chrome: float = _content.get_child(0).get_combined_minimum_size().y + 10
	_scroll.custom_minimum_size = Vector2(0, minf(_talent_panel.get_combined_minimum_size().y, maxf(180, available.y - chrome)))
