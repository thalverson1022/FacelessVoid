extends RefCounted
## Shared talent runs: named buffs cyan, ordinary copy cream, separate values gold.
const Keywords=preload("res://scripts/ui/presentation_keywords.gd")
const FONT=preload("res://assets/fonts/VT323-Regular.ttf")
const BASIC=CardStyle.STAT_COLOR_BASIC
const GOLD=UIColors.TEXT_GOLD
const GROUP_GAP=4.0

static func text_runs(item: Dictionary) -> Array:
	var runs: Array=Keywords.runs(item.label,not str(item.key).begins_with("unlock_"))
	if item.value!="": runs.append({"text":": ","color":BASIC,"id":"","kind":"text"})
	if item.value!="": runs.append({"text":item.value,"color":GOLD,"id":"","kind":"value"})
	return runs

static func make_row(item: Dictionary,font_size: int,min_width: float=0,max_width: float=0) -> RichTextLabel:
	var body:=RichTextLabel.new()
	body.fit_content=true
	body.scroll_active=false
	body.bbcode_enabled=false
	body.mouse_filter=Control.MOUSE_FILTER_IGNORE
	body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_override("normal_font",FONT)
	body.add_theme_font_size_override("normal_font_size",font_size)
	body.add_theme_color_override("default_color",BASIC)
	Keywords.append_runs(body,text_runs(item))
	body.set_meta("effect_key",item.key)
	if max_width>0:
		var text: String=preload("res://scripts/ui/talent_hover_formatter.gd").row_text(item)
		body.custom_minimum_size.x=clampf(FONT.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x,min_width,max_width)
	return body

static func add_to(column: VBoxContainer,rows: Array,font_size: int,min_width: float=0,max_width: float=0,gap_scale: float=1.0,row_name: String="TalentHoverEffect") -> void:
	var previous_kind: int=-1
	for item in rows:
		var kind:=0 if item.value=="" else 1
		if previous_kind>=0 and kind!=previous_kind:
			var gap:=Control.new()
			gap.name="TalentEffectGroupGap"
			gap.mouse_filter=Control.MOUSE_FILTER_IGNORE
			gap.custom_minimum_size.y=GROUP_GAP*gap_scale
			column.add_child(gap)
		var body:=make_row(item,font_size,min_width,max_width)
		body.name=row_name
		column.add_child(body,true)
		previous_kind=kind
