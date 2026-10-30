extends Control
## Combat log overlay: shows the full formatted result text for the last
## resolved fight. Extracted from combat_screen.gd's inline overlay builder
## (docs/Phase_3_Technical_Debt_Architecture_Cleanup.md Phase 3) -- a pure
## informational view, so it stays dismissable on an outside click, matching
## its behavior before extraction.

const CARD_TITLE_FONT_SIZE := 20
const RUN_ROW_FONT_SIZE := 17
const MODAL_Z_INDEX := 930
const INSPECTOR_SCENE := preload("res://scenes/combat/combat_log_inspector.gd")

var practice_mode := false
var category_preview := false
var _tabs: TabContainer
var _damage_scroll: ScrollContainer
var _run_scroll: ScrollContainer
var _details: Label
var _panel: PanelContainer
var _category_result: CombatResolver.CombatResult
var _original_text := ""
var _inspector
var _log_label: RichTextLabel
var _run_chart: RunDpsChart
var _run_list: VBoxContainer
var _run_history: Array[Dictionary] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

	var panel := CardStyle.build_modal_panel(self, true, true)
	_panel = panel
	get_viewport().size_changed.connect(_resize_panel)
	resized.connect(_resize_panel)
	_resize_panel()
	z_index = MODAL_Z_INDEX
	panel.add_theme_stylebox_override("panel", CardStyle.make_stylebox())

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var header := HBoxContainer.new()
	var header_title := Label.new()
	header_title.text = "Combat Log"
	header_title.theme_type_variation = &"PanelHeader"
	header_title.add_theme_font_size_override("font_size", CARD_TITLE_FONT_SIZE)
	header.add_child(header_title)
	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer)
	var close_button := Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(func(): visible = false)
	header.add_child(close_button)
	content.add_child(header)

	_tabs = TabContainer.new()
	_tabs.name = "LogTabs"
	_tabs.use_hidden_tabs_for_min_size = false
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_tabs)

	_damage_scroll = _scroll_tab("Damage Breakdown")
	var damage_content := VBoxContainer.new()
	damage_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_damage_scroll.add_child(damage_content)
	_details = Label.new()
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.add_theme_font_size_override("font_size", 17)
	damage_content.add_child(_details)
	_inspector = INSPECTOR_SCENE.new()
	_inspector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inspector.visible = false
	damage_content.add_child(_inspector)
	# Keep the inspector usable alone, while sharing its summary across tabs here.
	_inspector._summary_row.reparent(content)
	content.move_child(_inspector._summary_row, 1)
	_inspector._summary_row.visible = false

	_log_label = RichTextLabel.new()
	_log_label.name = "Event Log"
	_log_label.custom_minimum_size = Vector2(0, 120)
	_log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(_log_label)

	_run_scroll = _scroll_tab("Run Log")
	var run_tab := VBoxContainer.new()
	run_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	run_tab.add_theme_constant_override("separation", 8)
	_run_scroll.add_child(run_tab)
	var run_title := Label.new()
	run_title.text = "Player DPS By Fight"
	run_title.visible = not practice_mode
	run_title.theme_type_variation = &"PanelHeader"
	run_tab.add_child(run_title)
	_run_chart = RunDpsChart.new()
	_run_chart.custom_minimum_size = Vector2(0, 170)
	_run_chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	run_tab.add_child(_run_chart)
	var list_title := Label.new()
	list_title.text = "Encounter History"
	list_title.visible = not practice_mode
	list_title.theme_type_variation = &"PanelHeader"
	run_tab.add_child(list_title)

	_run_list = VBoxContainer.new()
	_run_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_run_list.add_theme_constant_override("separation", 2)
	run_tab.add_child(_run_list)
	_refresh_run_history()


func _resize_panel() -> void:
	# A fixed viewport bounds the active page; chart minimums stay inside scrolls.
	_panel.custom_minimum_size = Vector2(minf(1040, size.x - 48), maxf(320, size.y - 32))


func _scroll_tab(title: String) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_child(scroll)
	return scroll


func _reset_scrolls() -> void:
	_damage_scroll.scroll_vertical = 0
	_run_scroll.scroll_vertical = 0
	_log_label.scroll_to_line(0)


## Public setter so combat_screen.gd never touches this overlay's internal
## RichTextLabel directly.
func set_result_text(text: String) -> void:
	if _inspector != null:
		_inspector.clear()
	_reset_scrolls()
	_details.text = "No damage breakdown available for this text log."
	_tabs.current_tab = 1
	_category_result = null
	_original_text = text
	_log_label.bbcode_enabled = false
	_log_label.text = text


func set_result(result: CombatResolver.CombatResult, monster: Monster, text: String) -> void:
	if result == null:
		set_result_text(text)
		return
	_reset_scrolls()
	_tabs.current_tab = 0
	_inspector.set_result(result, monster, practice_mode)
	_details.text = _result_details(result, monster)
	_category_result = result
	_original_text = CombatResultFormatter.event_log(result) if result != null else text
	refresh_category_preview()


func _result_details(result: CombatResolver.CombatResult, monster: Monster) -> String:
	if not result.is_valid:
		return CombatResultFormatter.invalid_simulation_message(result)
	var details: PackedStringArray = []
	if monster != null:
		if not practice_mode:
			details.append("%s | %s | %d HP" % ["Victory" if result.is_win else "Defeat", monster.display_name, monster.hp])
		else:
			details.append("Practice | %s" % monster.display_name)
		details.append("%d Armor | %.0f%% Resist" % [monster.armor, monster.poison_resistance * 100.0])
	if result.countdown_rate != 1.0:
		details.append("Countdown %ss at %.0f%% speed" % [LegendaryCatalog.number_text(result.nominal_duration_ms / 1000.0), result.countdown_rate * 100.0])
	if result.gold_stolen > 0:
		details.append("Gold stolen %d" % result.gold_stolen)
	return " | ".join(details)


func show_log() -> void:
	z_index = MODAL_Z_INDEX
	move_to_front()
	visible = true


func set_run_history(history: Array) -> void:
	_run_history = []
	for value in history:
		if value is Dictionary:
			_run_history.append((value as Dictionary).duplicate(true))
	_refresh_run_history()


func _refresh_run_history() -> void:
	if _run_chart != null:
		_run_chart.set_rows(_run_history)
		_run_chart.visible = not practice_mode
	if _run_list == null:
		return
	for child in _run_list.get_children():
		child.queue_free()
	if not practice_mode:
		_run_list.add_child(_history_header_row())
	if _run_history.is_empty():
		var empty := Label.new()
		empty.text = "Adventure run history is not recorded in Practice." if practice_mode else "No encounters recorded yet."
		empty.add_theme_color_override("font_color", UIColors.TEXT_DISABLED)
		_run_list.add_child(empty)
		return
	for row in _run_history:
		_run_list.add_child(_history_row(row))


func _history_header_row() -> HBoxContainer:
	var row := _base_history_row()
	row.add_child(_history_cell("Fight Number", 112, UIColors.TEXT_GOLD))
	row.add_child(_history_cell("Contract", 86, UIColors.TEXT_GOLD))
	row.add_child(_history_cell("Name", 180, UIColors.TEXT_GOLD))
	row.add_child(_history_cell("Enemy", 210, UIColors.TEXT_GOLD))
	row.add_child(_history_cell("DPS", 78, UIColors.TEXT_GOLD, HORIZONTAL_ALIGNMENT_RIGHT))
	row.add_child(_history_cell("Result", 70, UIColors.TEXT_GOLD))
	return row


func _history_row(entry: Dictionary) -> HBoxContainer:
	var row := _base_history_row()
	row.add_child(_history_cell("%d" % int(entry.get("fight_number", 0)), 112))
	var contract_count := int(entry.get("contract_count", 0))
	var contract_count_text := "%d" % contract_count if contract_count > 0 else "-"
	row.add_child(_history_cell(contract_count_text, 86))
	row.add_child(_history_cell(String(entry.get("contract_name", "")), 180))
	row.add_child(_enemy_cell(entry))
	row.add_child(_history_cell("%.1f" % float(entry.get("player_dps", 0.0)), 78, UIColors.TEXT_NORMAL, HORIZONTAL_ALIGNMENT_RIGHT))
	row.add_child(_history_cell("Win" if bool(entry.get("is_win", false)) else "Loss", 70, UIColors.TEXT_POISON if bool(entry.get("is_win", false)) else UIColors.TEXT_WARNING))
	return row


func _base_history_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	return row


func _history_cell(text: String, width: float, color: Color = UIColors.TEXT_NORMAL, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(width, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", RUN_ROW_FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	return label


func _enemy_cell(entry: Dictionary) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.custom_minimum_size = Vector2(210, 28)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("normal_font_size", RUN_ROW_FONT_SIZE)
	var color := _enemy_color_for_entry(entry).to_html(false)
	var name := String(entry.get("enemy_name", "Unknown"))
	label.text = "[color=#%s]%s[/color]" % [color, name]
	return label


func _enemy_color_for_entry(entry: Dictionary) -> Color:
	match String(entry.get("enemy_role", "")).to_lower():
		"boss":
			return UIColors.TEXT_WARNING
		"elite":
			return UIColors.TEXT_MAGIC
		"captain":
			return UIColors.TIER_MASTER
		"normal", "fight", "tavern":
			return UIColors.TEXT_POISON
		_:
			var saved_color := String(entry.get("enemy_color", ""))
			if saved_color != "" and Color.html_is_valid("#%s" % saved_color):
				return Color("#%s" % saved_color)
			return UIColors.TEXT_POISON


class RunDpsChart:
	extends Control

	const LEFT_PAD := 48.0
	const RIGHT_PAD := 18.0
	const TOP_PAD := 16.0
	const BOTTOM_PAD := 30.0
	const MIN_BAR_W := 3.0
	const BAR_GAP := 4.0

	var _rows: Array[Dictionary] = []

	func set_rows(rows: Array) -> void:
		_rows = []
		for value in rows:
			if value is Dictionary:
				_rows.append((value as Dictionary).duplicate(true))
		queue_redraw()

	func _draw() -> void:
		var font := get_theme_default_font()
		var font_size := get_theme_default_font_size()
		var chart := Rect2(
			Vector2(LEFT_PAD, TOP_PAD),
			Vector2(maxf(size.x - LEFT_PAD - RIGHT_PAD, 1.0), maxf(size.y - TOP_PAD - BOTTOM_PAD, 1.0))
		)
		draw_line(Vector2(chart.position.x, chart.position.y), Vector2(chart.position.x, chart.end.y), UIColors.COMBAT_CHART_LINE, 2.0)
		draw_line(Vector2(chart.position.x, chart.end.y), Vector2(chart.end.x, chart.end.y), UIColors.COMBAT_CHART_LINE, 2.0)
		if _rows.is_empty():
			draw_string(font, chart.position + Vector2(12, 34), "No player DPS recorded yet.", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UIColors.TEXT_DISABLED)
			return
		var max_dps := _max_dps()
		_draw_y_marks(chart, max_dps, font, font_size)
		var count := _rows.size()
		var slots := maxi(10, count)
		var slot_w := chart.size.x / float(slots)
		var bar_w := maxf(MIN_BAR_W, slot_w - BAR_GAP)
		for i in range(count):
			var entry: Dictionary = _rows[i]
			var dps := float(entry.get("player_dps", 0.0))
			var ratio := clampf(dps / max_dps, 0.0, 1.0)
			var x := chart.position.x + float(i) * slot_w + maxf((slot_w - bar_w) * 0.5, 0.0)
			var h := maxf(2.0, ratio * chart.size.y)
			var rect := Rect2(Vector2(x, chart.end.y - h), Vector2(bar_w, h))
			var color := UIColors.TEXT_POISON if i == count - 1 else UIColors.COMBAT_CHART_POISON
			draw_rect(rect, UIColors.COMBAT_CHART_BAR_BG, true)
			draw_rect(rect, color, true)
			draw_rect(rect, UIColors.COMBAT_CHART_BAR_BORDER_SOFT, false, 1.0)
		_draw_x_labels(chart, slots, count, font, font_size)

	func _max_dps() -> float:
		var max_value := 1.0
		for entry in _rows:
			max_value = maxf(max_value, float(entry.get("player_dps", 0.0)))
		return max_value

	func _draw_y_marks(chart: Rect2, max_dps: float, font: Font, font_size: int) -> void:
		for i in range(1, 4):
			var ratio := float(i) / 3.0
			var y := chart.end.y - chart.size.y * ratio
			draw_line(Vector2(chart.position.x, y), Vector2(chart.end.x, y), UIColors.COMBAT_CHART_GRID, 1.0)
			draw_string(font, Vector2(4, y + 5), "%.0f" % (max_dps * ratio), HORIZONTAL_ALIGNMENT_RIGHT, LEFT_PAD - 10.0, font_size, UIColors.COMBAT_CHART_TEXT)

	func _draw_x_labels(chart: Rect2, slots: int, count: int, font: Font, font_size: int) -> void:
		var step := 1
		if slots > 30:
			step = 5
		elif slots > 10:
			step = 2
		var slot_w := chart.size.x / float(slots)
		for i in range(slots):
			var fight_number := i + 1
			if fight_number != 1 and fight_number != slots and fight_number % step != 0:
				continue
			var x := chart.position.x + float(i) * slot_w + slot_w * 0.5
			var color := UIColors.TEXT_GOLD if fight_number <= count else UIColors.TEXT_DISABLED
			draw_string(font, Vector2(x - 12.0, chart.end.y + 20.0), "%d" % fight_number, HORIZONTAL_ALIGNMENT_CENTER, 24.0, font_size, color)

func refresh_category_preview() -> void:
	if _log_label == null: return
	_log_label.bbcode_enabled = category_preview and _category_result != null
	_log_label.text = preload("res://scripts/ui/skill_category_preview_style.gd").log_text(_category_result) + "\n\nFULL EVENT LOG\n" + _original_text.replace("[", "[lb]") if category_preview and _category_result != null else _original_text
