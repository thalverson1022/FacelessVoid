extends RefCounted
const Keywords=preload("res://scripts/ui/presentation_keywords.gd")
const FONT = preload("res://assets/fonts/VT323-Regular.ttf")
const CREAM = Color("F0E2C5")

static func build(owner: Control, data: Dictionary, text_scale: float = 1.0) -> Control:
	var panel := PanelContainer.new()
	panel.name = "SkillHover"
	# Exact item-tooltip background from this button's theme chain.
	panel.add_theme_stylebox_override("panel",owner.get_theme_stylebox("panel","TooltipPanel"))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",4)
	panel.add_child(column)
	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_BEGIN
	header.add_theme_constant_override("separation",8)
	column.add_child(header)
	if data.icon != null:
		var art := CardStyle.make_pixel_icon(data.icon,Vector2(32,32))
		art.name = "SkillHoverIcon"
		art.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		header.add_child(art)
	var name_label := text_label(data.name,22,CREAM,text_scale)
	name_label.name = "SkillHoverName"
	name_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	header.add_child(name_label)
	var category := text_label("%s [%s]" % [data.category,data.cast],18,data.color,text_scale)
	category.name = "SkillHoverCategory"
	column.add_child(category)
	if data.cooldown != "":
		var cooldown := text_label(data.cooldown,18,CREAM,text_scale)
		cooldown.name = "SkillHoverCooldown"
		column.add_child(cooldown)
	if data.duration != "":
		var duration := text_label(data.duration,18,CREAM,text_scale)
		duration.name = "SkillHoverDuration"
		column.add_child(duration)
	if data.damage != "":
		var damage := text_label(data.damage,20,CREAM,text_scale)
		damage.name = "SkillHoverDamage"
		column.add_child(damage)
	if data.effect != "":
		var effect:=RichTextLabel.new()
		effect.fit_content=true
		effect.scroll_active=false
		effect.bbcode_enabled=false
		effect.mouse_filter=Control.MOUSE_FILTER_IGNORE
		effect.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		effect.add_theme_font_override("normal_font",FONT)
		effect.add_theme_font_size_override("normal_font_size",roundi(20*text_scale))
		effect.add_theme_color_override("default_color",CREAM)
		Keywords.append_runs(effect,Keywords.runs(data.effect))
		effect.name = "SkillHoverEffect"
		effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var longest := 0.0
		for line in str(data.effect).split("\n"):
			longest = maxf(longest,FONT.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,roundi(20*text_scale)).x)
		effect.custom_minimum_size.x = clampf(longest,260*text_scale,480*text_scale)
		column.add_child(effect)
	return panel

static func text_label(text: String, pixels: int, color: Color, text_scale: float) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font",FONT)
	label.add_theme_font_size_override("font_size",roundi(pixels*text_scale))
	label.add_theme_color_override("font_color",color)
	return label
