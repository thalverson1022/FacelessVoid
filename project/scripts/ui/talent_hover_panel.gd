extends RefCounted
const FONT=preload("res://assets/fonts/VT323-Regular.ttf")
const Rows=preload("res://scripts/ui/talent_effect_rows.gd")
const NEXT_SECTION_GAP=12.0
const Basic=CardStyle.STAT_COLOR_BASIC
static func build(owner: Control,data: Dictionary,text_scale: float=1.0) -> Control:
	var panel:=PanelContainer.new()
	panel.name="TalentHover"
	panel.add_theme_stylebox_override("panel",owner.get_theme_stylebox("panel","TooltipPanel"))
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",4)
	panel.add_child(column)
	var header:=HBoxContainer.new()
	header.add_theme_constant_override("separation",8)
	column.add_child(header)
	if data.icon!=null:
		var art:=CardStyle.make_pixel_icon(data.icon,Vector2(32,32))
		art.name="TalentHoverIcon"
		art.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
		header.add_child(art)
	var title:=label(data.name,22,Basic,text_scale)
	title.name="TalentHoverName"
	title.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	header.add_child(title)
	column.add_child(label("%s | Rank %d/%d" % [data.tree,data.rank,data.max],18,Basic,text_scale))
	add_rows(column,data.base_rows,text_scale)
	add_rows(column,data.current_rows,text_scale)
	if not data.next_rows.is_empty():
		if not data.base_rows.is_empty() or not data.current_rows.is_empty():
			var gap:=Control.new()
			gap.name="TalentHoverNextRankGap"
			gap.custom_minimum_size.y=NEXT_SECTION_GAP*text_scale
			column.add_child(gap)
		var next_section:=VBoxContainer.new()
		next_section.name="TalentHoverNextRank"
		next_section.add_theme_constant_override("separation",4)
		column.add_child(next_section)
		var heading:=label("Next rank:",18,Basic,text_scale)
		heading.name="TalentHoverNextRankHeading"
		next_section.add_child(heading)
		add_rows(next_section,data.next_rows,text_scale)
	return panel

static func add_rows(column: VBoxContainer,rows: Array,text_scale: float) -> void:
	Rows.add_to(column,rows,roundi(20*text_scale),280*text_scale,480*text_scale,text_scale)
static func label(text: String,size: int,color: Color,text_scale: float) -> Label:
	var value:=Label.new()
	value.text=text
	value.add_theme_font_override("font",FONT)
	value.add_theme_font_size_override("font_size",roundi(size*text_scale))
	value.add_theme_color_override("font_color",color)
	return value
