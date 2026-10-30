class_name CombatLogInspector
extends VBoxContainer
## Static first-pass visual Combat Log inspector: compact result chips, a
## Gantt-like skill timeline, and ranked damage-by-skill bars.


const SUMMARY_FONT_SIZE := 18
const SECTION_FONT_SIZE := 16
const InspectorData := preload("res://scripts/systems/combat_log_inspector_data.gd")

var _summary_row: HBoxContainer
var _timeline_chart: TimelineChart
var _damage_chart: DamageChart


func _ready() -> void:
	add_theme_constant_override("separation", 8)

	_summary_row = HBoxContainer.new()
	_summary_row.add_theme_constant_override("separation", 8)
	add_child(_summary_row)

	var damage_title := _section_label("Damage By Skill")
	add_child(damage_title)
	_damage_chart = DamageChart.new()
	_damage_chart.custom_minimum_size = Vector2(0, 160)
	_damage_chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_damage_chart)

	var timeline_title := _section_label("Skill Timeline")
	add_child(timeline_title)
	_timeline_chart = TimelineChart.new()
	_timeline_chart.custom_minimum_size = Vector2(0, 230)
	_timeline_chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_timeline_chart)


func set_result(result: CombatResolver.CombatResult, monster: Monster, practice_mode: bool = false) -> void:
	var inspector := InspectorData.build(result, null if practice_mode else monster)
	_set_summary(inspector, practice_mode)
	_timeline_chart.set_rows(inspector["timeline_rows"], result.duration_ms, float(inspector["max_event_damage"]))
	_damage_chart.set_rows(inspector["damage_rows"])
	_summary_row.visible = true
	visible = true


func clear() -> void:
	for child in _summary_row.get_children():
		_summary_row.remove_child(child)
		child.queue_free()
	_timeline_chart.set_rows([], 0)
	_damage_chart.set_rows([])
	_summary_row.visible = false
	visible = false


func _set_summary(inspector: Dictionary, practice_mode: bool) -> void:
	for child in _summary_row.get_children():
		_summary_row.remove_child(child)
		child.queue_free()
	var summary: Dictionary = inspector["summary"]
	if not bool(inspector.get("is_valid", true)):
		_summary_row.add_child(_summary_chip("Result", "Invalid simulation"))
		_summary_row.add_child(_summary_chip("Partial damage", "%.1f" % summary["total_damage"]))
		return
	_summary_row.add_child(_summary_chip("Damage", "%.1f" % summary["total_damage"]))
	_summary_row.add_child(_summary_chip("DPS", "%.1f" % summary["actual_dps"]))
	var duration_chip := _summary_chip("Elapsed", "%ss" % LegendaryCatalog.number_text(float(summary["duration_ms"]) / 1000.0))
	duration_chip.tooltip_text = "Actual combat duration; countdown budget %ss at %.0f%% speed." % [LegendaryCatalog.number_text(float(summary["nominal_duration_ms"]) / 1000.0), float(summary["countdown_rate"]) * 100.0]
	_summary_row.add_child(duration_chip)


func _summary_chip(label_text: String, value_text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", CardStyle.make_stylebox())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", SUMMARY_FONT_SIZE - 2)
	row.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", SUMMARY_FONT_SIZE)
	value.add_theme_color_override("font_color", UIColors.TEXT_GOLD)
	row.add_child(value)
	return panel


func _section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"PanelHeader"
	label.add_theme_font_size_override("font_size", SECTION_FONT_SIZE)
	return label


class TimelineChart:
	extends Control

	const LEFT_PAD := 78.0
	const RIGHT_PAD := 28.0
	const TOP_PAD := 26.0
	const ROW_H := 34.0
	const MIN_BAR_H := 4.0
	const MAX_BAR_H := 22.0
	const MIN_DOT_RADIUS := 3.0
	const MAX_DOT_RADIUS := 8.0
	const CAST_COLOR := UIColors.COMBAT_CHART_CAST
	const POISON_COLOR := UIColors.COMBAT_CHART_POISON
	const PROC_COLOR := UIColors.COMBAT_CHART_PROC
	const GRID_COLOR := UIColors.COMBAT_CHART_GRID
	const LINE_COLOR := UIColors.COMBAT_CHART_LINE
	const TEXT_COLOR := UIColors.COMBAT_CHART_TEXT
	const CRIT_COLOR := UIColors.COMBAT_CHART_CRIT
	const CONTACT_COLOR := UIColors.COMBAT_CHART_CONTACT

	var _rows: Array = []
	var _duration_ms := 0
	var _max_event_damage := 0.0

	func set_rows(rows: Array, duration_ms: int, max_event_damage: float = 0.0) -> void:
		_rows = rows
		_duration_ms = duration_ms
		_max_event_damage = max_event_damage
		custom_minimum_size.y = TOP_PAD + max(1, _rows.size()) * ROW_H + 18.0
		queue_redraw()

	func _get_tooltip(at_position: Vector2) -> String:
		var index := floori((at_position.y - TOP_PAD) / ROW_H)
		if index < 0 or index >= _rows.size(): return ""
		var row: Dictionary = _rows[index]
		var lines: PackedStringArray = [str(row["label"])]
		for entry in row["events"]:
			var amount := "%.1f damage" % float(entry.get("damage", 0))
			var detail := ""
			if entry.get("origin_kind", "") == "lightning_repeat": detail = " | Hands of the Lightning Lord Retrigger"
			if row.kind == InspectorData.KIND_POISON:
				detail = " | Free Retrigger; current buffs; no Consume" if entry.get("free_retrigger", false) else (" | Consume %d" if entry.get("keyword_consume", false) else " | %d depleted, not Consume") % int(entry.get("stacks_depleted", 0))
				if entry.get("origin_kind", "") == "lightning_poison_repeat": detail += " | Hands of the Lightning Lord"
				if entry.get("stacks_preserved", false): detail = " | Serpent's Scales: preserved %d stacks; damage fuel %d; 0 consumed" % [int(entry.get("damage_fuel",0)),int(entry.get("damage_fuel",0))]
			lines.append("%.3fs: %s%s" % [int(entry.get("contact_ms", entry.get("time_ms", 0))) / 1000.0, amount, detail])
		return "\n".join(lines)

	func _draw() -> void:
		var chart_rect := Rect2(Vector2(LEFT_PAD, TOP_PAD), Vector2(maxf(size.x - LEFT_PAD - RIGHT_PAD, 1.0), maxf(size.y - TOP_PAD - 8.0, 1.0)))
		var font := get_theme_default_font()
		var font_size := get_theme_default_font_size()
		_draw_time_axis(chart_rect, font, font_size)
		if _rows.is_empty():
			draw_string(font, Vector2(12, TOP_PAD + 28), "No skill casts to chart.", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, TEXT_COLOR)
			return
		for i in range(_rows.size()):
			var row: Dictionary = _rows[i]
			var y := TOP_PAD + float(i) * ROW_H + ROW_H * 0.5
			draw_line(Vector2(0, y + ROW_H * 0.45), Vector2(size.x, y + ROW_H * 0.45), LINE_COLOR, 1.0)
			_draw_row_icon(row, Vector2(24.0, y - 12.0), font, font_size)
			var kind := String(row["kind"])
			for entry in row["events"]:
				if kind == InspectorData.KIND_POISON:
					var tick_x := _x_for_time(chart_rect, int(entry["time_ms"]))
					draw_circle(Vector2(tick_x, y), _dot_radius(float(entry["damage"])), POISON_COLOR)
				else:
					var start_x := _x_for_time(chart_rect, int(entry["start_ms"]))
					var end_x := _x_for_time(chart_rect, int(entry["end_ms"]))
					var color := PROC_COLOR if kind == InspectorData.KIND_PROC or bool(entry["min_cast_proc"]) else CAST_COLOR
					if bool(entry["has_poison_apply"]):
						color = POISON_COLOR
					var bar_h := _bar_height(float(entry["damage"]))
					var bar_rect := Rect2(Vector2(start_x, y - bar_h * 0.5), Vector2(maxf(end_x - start_x, 3.0), bar_h))
					draw_rect(bar_rect, color, true)
					draw_rect(bar_rect, UIColors.COMBAT_CHART_BAR_BORDER, false, 1.0)
					draw_line(Vector2(end_x, y - maxf(bar_h * 0.7, 8.0)), Vector2(end_x, y + maxf(bar_h * 0.7, 8.0)), CONTACT_COLOR, 2.0)
					if bool(entry["has_armor"]):
						_draw_mechanic_pip(Vector2(end_x - 7.0, y - bar_h * 0.5 - 8.0), UIColors.COMBAT_CHART_ARMOR)
					if bool(entry["is_crit"]):
						_draw_star(Vector2(end_x + 10.0, y - bar_h * 0.5 - 8.0), 6.0)

	func _bar_height(damage: float) -> float:
		if _max_event_damage <= 0.0 or damage <= 0.0:
			return MIN_BAR_H
		return lerpf(MIN_BAR_H, MAX_BAR_H, clampf(damage / _max_event_damage, 0.0, 1.0))

	func _dot_radius(damage: float) -> float:
		if _max_event_damage <= 0.0 or damage <= 0.0:
			return MIN_DOT_RADIUS
		return lerpf(MIN_DOT_RADIUS, MAX_DOT_RADIUS, clampf(damage / _max_event_damage, 0.0, 1.0))

	func _draw_time_axis(chart_rect: Rect2, font: Font, font_size: int) -> void:
		var seconds := maxf(float(_duration_ms) / 1000.0, 1.0)
		var marks := _time_marks(seconds)
		for mark in marks:
			var x: float = chart_rect.position.x + (mark / seconds) * chart_rect.size.x
			draw_line(Vector2(x, TOP_PAD - 6.0), Vector2(x, size.y), GRID_COLOR, 1.0)
			draw_string(font, Vector2(x - 10.0, TOP_PAD - 8.0), "%ds" % roundi(mark), HORIZONTAL_ALIGNMENT_LEFT, 44, font_size, TEXT_COLOR)

	func _time_marks(seconds: float) -> Array[float]:
		var end_second := ceili(seconds)
		var step := maxi(1, ceili(float(end_second) / 4.0))
		var marks: Array[float] = [0.0]
		var mark := step
		while mark < end_second:
			marks.append(float(mark))
			mark += step
		if not is_equal_approx(marks[marks.size() - 1], seconds):
			marks.append(seconds)
		return marks

	func _x_for_time(chart_rect: Rect2, time_ms: int) -> float:
		if _duration_ms <= 0:
			return chart_rect.position.x
		var pct := clampf(float(time_ms) / float(_duration_ms), 0.0, 1.0)
		return chart_rect.position.x + pct * chart_rect.size.x

	func _draw_star(center: Vector2, radius: float) -> void:
		draw_circle(center, radius, CRIT_COLOR)
		draw_circle(center, radius * 0.45, UIColors.COMBAT_CHART_CRIT_INNER)

	func _draw_mechanic_pip(center: Vector2, color: Color) -> void:
		var points := PackedVector2Array([
			center + Vector2(0, -5),
			center + Vector2(5, -1),
			center + Vector2(3, 5),
			center + Vector2(-3, 5),
			center + Vector2(-5, -1),
		])
		draw_colored_polygon(points, color)

	func _draw_row_icon(row: Dictionary, position: Vector2, font: Font, font_size: int) -> void:
		var icon = row.get("icon", null)
		if icon is Texture2D:
			draw_texture_rect(icon, Rect2(position, Vector2(24, 24)), false)
			return
		var label := String(row["label"])
		var glyph := label.left(1).to_upper() if label != "" else "?"
		var fill := PROC_COLOR if String(row["kind"]) == InspectorData.KIND_PROC else CAST_COLOR
		draw_rect(Rect2(position, Vector2(24, 24)), fill, true)
		draw_rect(Rect2(position, Vector2(24, 24)), TEXT_COLOR, false, 1.0)
		draw_string(font, position + Vector2(7, 17), glyph, HORIZONTAL_ALIGNMENT_LEFT, 24, font_size, UIColors.COMBAT_CHART_ICON_TEXT)


class DamageChart:
	extends Control

	const LEFT_PAD := 78.0
	const RIGHT_PAD := 148.0
	const TOP_PAD := 6.0
	const ROW_H := 28.0
	const BAR_H := 14.0
	const CAST_COLOR := UIColors.COMBAT_CHART_CAST
	const POISON_COLOR := UIColors.COMBAT_CHART_POISON
	const PROC_COLOR := UIColors.COMBAT_CHART_PROC
	const TEXT_COLOR := UIColors.COMBAT_CHART_TEXT
	const VALUE_COLOR := UIColors.COMBAT_CHART_VALUE
	const LINE_COLOR := UIColors.COMBAT_CHART_LINE_SOFT

	var _rows: Array = []
	var _total_damage := 0.0


	func set_rows(rows: Array) -> void:
		_rows = rows
		_total_damage = 0.0
		for row in _rows:
			_total_damage += float(row["damage"])
		custom_minimum_size.y = TOP_PAD + max(1, _rows.size()) * ROW_H + 8.0
		queue_redraw()

	func _get_tooltip(at_position: Vector2) -> String:
		var index := floori((at_position.y - TOP_PAD) / ROW_H)
		if index < 0 or index >= _rows.size(): return ""
		var row: Dictionary = _rows[index]
		return "%s: %.1f damage" % [row.name, float(row["damage"])]

	func _draw() -> void:
		var font := get_theme_default_font()
		var font_size := get_theme_default_font_size()
		if _rows.is_empty():
			draw_string(font, Vector2(12, TOP_PAD + 22), "No damage dealt.", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, TEXT_COLOR)
			return
		var max_damage := maxf(float(_rows[0]["damage"]), 1.0)
		var bar_width := maxf(size.x - LEFT_PAD - RIGHT_PAD, 1.0)
		for i in range(_rows.size()):
			var row: Dictionary = _rows[i]
			var y := TOP_PAD + float(i) * ROW_H + ROW_H * 0.5
			draw_line(Vector2(0, y + ROW_H * 0.45), Vector2(size.x, y + ROW_H * 0.45), LINE_COLOR, 1.0)
			_draw_row_icon(row, Vector2(24.0, y - 12.0), font, font_size)
			var damage := float(row["damage"])
			var fill_width := maxf((damage / max_damage) * bar_width, 3.0)
			var color := _color_for_kind(String(row["kind"]))
			var rect := Rect2(Vector2(LEFT_PAD, y - BAR_H * 0.5), Vector2(fill_width, BAR_H))
			draw_rect(Rect2(Vector2(LEFT_PAD, y - BAR_H * 0.5), Vector2(bar_width, BAR_H)), UIColors.COMBAT_CHART_BAR_BG, true)
			draw_rect(rect, color, true)
			draw_rect(rect, UIColors.COMBAT_CHART_BAR_BORDER_SOFT, false, 1.0)
			draw_string(font, Vector2(LEFT_PAD + bar_width + 12.0, y + 5), "%.0f  (%.1f%%)" % [damage, 100.0 * damage / _total_damage if _total_damage > 0 else 0.0], HORIZONTAL_ALIGNMENT_LEFT, RIGHT_PAD - 12.0, font_size, VALUE_COLOR)

	func _color_for_kind(kind: String) -> Color:
		if kind == InspectorData.KIND_POISON:
			return POISON_COLOR
		if kind == InspectorData.KIND_PROC:
			return PROC_COLOR
		return CAST_COLOR

	func _draw_row_icon(row: Dictionary, position: Vector2, font: Font, font_size: int) -> void:
		var icon = row.get("icon", null)
		if icon is Texture2D:
			draw_texture_rect(icon, Rect2(position, Vector2(24, 24)), false)
			return
		var label := String(row["name"])
		var glyph := label.left(1).to_upper() if label != "" else "?"
		var fill := _color_for_kind(String(row["kind"]))
		draw_rect(Rect2(position, Vector2(24, 24)), fill, true)
		draw_rect(Rect2(position, Vector2(24, 24)), TEXT_COLOR, false, 1.0)
		draw_string(font, position + Vector2(7, 17), glyph, HORIZONTAL_ALIGNMENT_LEFT, 24, font_size, UIColors.COMBAT_CHART_ICON_TEXT)
