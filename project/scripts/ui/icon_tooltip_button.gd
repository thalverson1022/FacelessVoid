class_name IconTooltipButton
extends Button
var tooltip_icon: Texture2D
var tooltip_provider: Callable
var skill_hover_provider: Callable
var talent_hover_provider: Callable

func _get_tooltip(_at_position: Vector2) -> String:
	if skill_hover_provider.is_valid(): return preload("res://scripts/ui/skill_hover_formatter.gd").plain_text(skill_hover_provider.call())
	if talent_hover_provider.is_valid(): return preload("res://scripts/ui/talent_hover_formatter.gd").plain_text(talent_hover_provider.call())
	return str(tooltip_provider.call()) if tooltip_provider.is_valid() else tooltip_text

func _make_custom_tooltip(for_text: String) -> Object:
	if skill_hover_provider.is_valid():
		return preload("res://scripts/ui/skill_hover_panel.gd").build(self,skill_hover_provider.call())
	if talent_hover_provider.is_valid():
		return preload("res://scripts/ui/talent_hover_panel.gd").build(self,talent_hover_provider.call())
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", CardStyle.make_stylebox())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	if tooltip_icon != null:
		row.add_child(CardStyle.make_pixel_icon(tooltip_icon, Vector2(32, 32)))
	var label := Label.new()
	label.text = for_text
	label.custom_minimum_size.x = 540 if for_text.length() > 600 else 360
	label.add_theme_font_size_override("font_size", 22)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)
	return panel
