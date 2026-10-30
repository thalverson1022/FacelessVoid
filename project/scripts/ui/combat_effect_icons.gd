class_name CombatEffectIcons
extends VBoxContainer
const EffectText = preload("res://scripts/ui/combat_effect_text.gd")
## Shared presentation observer. Active buff types wrap in four-icon rows.
const RadialCountdown = preload("res://scripts/ui/combat_radial_countdown.gd")
const BODY_FONT = preload("res://assets/fonts/VT323-Regular.ttf")
const PresentationState = preload("res://scripts/ui/combat_presentation_state.gd")
signal motion_changed(enabled: bool)
static var reduced_motion := false
var _motion: CheckButton
var model = PresentationState.new()
var active: Dictionary:
	get: return model.active
var records: Array:
	get: return model.records
var cursor: int:
	get: return model.cursor
var _grid: GridContainer
var _dialog: AcceptDialog
var _details: RichTextLabel
var _signature := ""
var _chips: Dictionary = {}
var _time_bucket := -1
var _return_focus_id := ""

func _ready() -> void:
	custom_minimum_size.x = 220
	add_theme_constant_override("separation", 3)
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 4)
	add_child(_grid)
	_dialog = AcceptDialog.new()
	_dialog.title = "Combat effects and event history"
	_dialog.get_ok_button().text = "Close"
	_dialog.add_theme_stylebox_override("panel", CardStyle.make_stylebox())
	add_child(_dialog)
	var box := VBoxContainer.new()
	_dialog.add_child(box)
	var motion := CheckButton.new()
	_motion = motion
	motion.text = "Reduced motion (all modes, this session)"
	motion.button_pressed = reduced_motion
	motion.toggled.connect(func(value):
		reduced_motion = value
		motion_changed.emit(value)
	)
	box.add_child(motion)
	_details = RichTextLabel.new()
	_details.custom_minimum_size = Vector2(560, 320)
	_details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_details.add_theme_font_size_override("normal_font_size", 20)
	_details.add_theme_font_override("normal_font", BODY_FONT)
	_details.focus_mode = Control.FOCUS_ALL
	box.add_child(_details)
	_dialog.visibility_changed.connect(func():
		if not _dialog.visible and visible:
			if _chips.has(_return_focus_id): _chips[_return_focus_id].grab_focus()
			elif not _chips.is_empty(): _chips.values()[0].grab_focus()
	)
	hide()

func begin(result) -> void:
	if _dialog != null: _dialog.hide()
	model.begin(result)
	_signature = ""
	_time_bucket = -1
	_render()

func clear() -> void:
	model.clear()
	_signature = ""
	_time_bucket = -1
	if _dialog != null:
		_dialog.hide()
	for child in _grid.get_children() if _grid != null else []:
		_grid.remove_child(child)
		child.queue_free()
	_chips.clear()
	hide()

func advance_to(time_ms: int, through_sequence: int = 9223372036854775807) -> void:
	model.advance_to(time_ms, through_sequence)
	_render()

func _groups() -> Dictionary:
	var groups := {}
	for value in model.display_effects():
		var id: String = value.id
		if not id.begins_with("buff."):
			continue
		if not groups.has(id):
			groups[id] = []
		groups[id].append(value)
	return groups

func _ordered_ids(groups: Dictionary) -> Array:
	var ids: Array = groups.keys()
	ids.sort()
	for id in ["buff.greed", "buff.dance", "buff.readiness", "buff.footwork"]:
		if ids.has(id):
			ids.erase(id)
			ids.push_front(id)
	return ids

func _render() -> void:
	if _grid == null:
		return
	visible = model.running
	var groups := _groups()
	var ids := _ordered_ids(groups)
	var signature := JSON.stringify(ids)
	var focused_id := ""
	for id in _chips:
		if _chips[id].has_focus(): focused_id = id
	var changed := signature != _signature
	if changed:
		_signature = signature
		for child in _grid.get_children():
			_grid.remove_child(child)
			child.queue_free()
		_chips.clear()
		for id in ids:
			var chip := IconTooltipButton.new()
			chip.custom_minimum_size = Vector2(52, 52)
			chip.clip_contents = true
			chip.tooltip_icon = GameIcons.icon_for(id)
			for style in ["normal", "hover", "pressed", "disabled"]:
				chip.add_theme_stylebox_override(style, StyleBoxEmpty.new())
			var art := TextureRect.new()
			art.name = "BuffIcon"
			art.texture = GameIcons.icon_for(id)
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			chip.add_child(art)
			var clock := RadialCountdown.new()
			clock.name = "Countdown"
			clock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			chip.add_child(clock)
			var count := Label.new()
			count.name = "StackCount"
			count.mouse_filter = Control.MOUSE_FILTER_IGNORE
			count.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			count.add_theme_font_override("font", BODY_FONT)
			count.add_theme_font_size_override("font_size", 30)
			count.add_theme_color_override("font_color", Color.WHITE)
			count.add_theme_color_override("font_outline_color", Color.BLACK)
			count.add_theme_constant_override("outline_size", 6)
			chip.add_child(count)
			chip.set_meta("entity_id", id)
			chip.pressed.connect(func():
				_return_focus_id = id
				_open_inspector()
			)
			_grid.add_child(chip)
			_chips[id] = chip
	if changed and focused_id != "":
		if _chips.has(focused_id): _chips[focused_id].grab_focus()
		elif not _chips.is_empty(): _chips.values()[0].grab_focus()
	for id in _chips:
		var values: Array = groups[id]
		var next: Dictionary = {}
		var units := 0
		for value in values:
			units += int(value.state.get("units", value.state.get("charges", 0)))
			var expiry := int(value.state.get("expires_at_ms", -1))
			if not value.has("cast_id") and expiry >= 0 and (next.is_empty() or expiry < int(next.state.expires_at_ms)):
				next = value
		if id in ["buff.dance", "buff.master_of_poisons"]: units = values.size()
		_chips[id].get_node("StackCount").text = str(units)
		_chips[id].get_node("StackCount").add_theme_font_size_override("font_size", mini(30, maxi(12, 90 / str(units).length())))
		var deadline := int(next.get("state", {}).get("expires_at_ms", -1))
		var duration := deadline - int(next.get("timer_started_ms", model.time_ms))
		var clock = _chips[id].get_node("Countdown")
		clock.visible = deadline >= 0 and duration > 0
		clock.progress = clampf(float(deadline - model.time_ms) / duration, 0.0, 1.0) if clock.visible else 0.0
		_chips[id].tooltip_text = _summary(id, values) + "\nClick to inspect"
	visible = model.running and not ids.is_empty()
	if _dialog.visible and _time_bucket != model.time_ms / 100:
		_refresh_inspector()
	_time_bucket = model.time_ms / 100

func _summary(id: String, values: Array) -> String:
	var units := 0
	var expiry := -1
	var held := false
	var magnitudes: PackedStringArray = []
	for index in values.size():
		var item: Dictionary = values[index]
		units += int(item.state.get("units", item.state.get("charges", 0)))
		held = held or item.has("cast_id")
		var deadline := int(item.state.get("expires_at_ms", -1))
		if not item.has("cast_id") and deadline >= 0 and (expiry < 0 or deadline < expiry): expiry = deadline
		var magnitude: String = EffectText.magnitude_for(id, item.state)
		if magnitude != "": magnitudes.append(("Instance %d: " % (index + 1) if values.size() > 1 else "") + magnitude)
	var unit := "stacks"
	if id == "buff.greed": unit = "credited gold stolen this fight"
	elif id == "buff.beguiling_presence": unit = "Decay stacks absorbed"
	elif id == "buff.touch_of_darkness": unit = "Poison stacks consumed"
	elif id == "buff.master_of_poisons": unit = "active resistance-ignore instance(s)"
	var count_text := "%d %s" % [units, unit]
	if id in ["buff.meditation", "buff.dash"]:
		count_text = "%d/%d stacks" % [units, int(values[0].state.get("cap", 0))]
	if id == "buff.master_of_poisons": count_text = "%d active resistance-ignore instances" % values.size()
	elif id == "buff.dance": count_text = "Macro repeat guarantee active"
	if values.size() > 1: count_text += " across %d instances" % values.size()
	if held: count_text += " (includes spent units held until impact)"
	var timing := ("Until impact" if held else "Untimed") if expiry < 0 else "Nearest expiry: %.1fs" % (maxi(0, expiry - model.time_ms) / 1000.0)
	return "%s\n%s | %s\n%s\n%s" % [_name(id), count_text, timing, "\n".join(magnitudes), EffectText.rule_for(id)]

func _name(id: String) -> String:
	return EffectText.name_for(id)

func _open_inspector() -> void:
	_motion.set_pressed_no_signal(reduced_motion)
	_refresh_inspector()
	_dialog.popup_centered(Vector2i(600, 440))
	_details.grab_focus()

func _refresh_inspector() -> void:
	var old_scroll := _details.get_v_scroll_bar().value
	var lines: PackedStringArray = ["Player effects (simulation %.2fs)" % (model.time_ms / 1000.0)]
	for prefix in ["buff.", "status."]:
		if prefix == "status.":
			lines.append("\nEnemy temporary debuffs")
		var instances := {}
		for item in model.display_effects():
			if not item.id.begins_with(prefix): continue
			instances[item.id] = int(instances.get(item.id, 0)) + 1
			var value: Dictionary = item.state
			var held: bool = item.has("cast_id")
			var remaining := "Spent - held until impact" if held else ("Untimed" if int(value.get("expires_at_ms", -1)) < 0 else "%.2fs remaining" % (maxi(0, int(value.expires_at_ms) - model.time_ms) / 1000.0))
			lines.append("%s - Instance %d | %s | %s\nSource: %s | %s\n%s\n" % [_name(item.id), instances[item.id], EffectText.count_for(item.id, value), remaining, _name(str(item.get("source", "unknown"))), EffectText.magnitude_for(item.id, value), EffectText.rule_for(item.id)])
	lines.append("\nEnemy statuses: Poison %d | Shred %d | Decay %d" % [int(model.statuses.get("poison", 0)), int(model.statuses.get("shred", 0)), int(model.statuses.get("decay", 0))])
	var mug: Skill = preload("res://scripts/systems/p6_thief_contracts.gd").skill("mug")
	lines.append("Stash: %d | Stolen this fight: %d | Mug bonus: +%d/%d" % [model.stash, model.stolen, mug.stolen_gold_damage_bonus(model.stolen), mug.stolen_gold_base_cap])
	lines.append("Gilded counted stash: %d/500 | Gilded crit damage contribution: +%.0f%%\nSilvered crit chance contribution: +%.0f%% (cap %.0f%%)" % [int(model.gold_stats.get("gilded_counted_gold", 0)), float(model.gold_stats.get("gilded_crit_bonus", 0)) * 100, float(model.gold_stats.get("silvered_crit_bonus", 0)) * 100, float(model.gold_stats.get("silvered_cap", 0)) * 100])
	if model.gold_stats.has("crit_chance"):
		lines.append("Total crit chance: %.1f%% | Total crit damage: %.2fx" % [float(model.gold_stats.crit_chance) * 100, float(model.gold_stats.crit_multiplier)])
	lines.append("\nShared skill cooldowns")
	for id in model.cooldowns:
		lines.append("%s: %.1fs" % [_name(id), (int(model.cooldowns[id]) - model.time_ms) / 1000.0])
	lines.append(model.attempt_text())
	lines.append("\nOrdered events (tick depletion is distinct from Consume)")
	lines.append("\n".join(model.journal))
	_details.text = "\n".join(lines)
	_details.get_v_scroll_bar().set_deferred("value", old_scroll)


func finish(result) -> void:
	if _dialog != null: _dialog.hide()
	model.advance_to(result.duration_ms)
	model.active.clear()
	model.held_effects.clear()
	model.cooldowns.clear()
	model.attempt.clear()
	_render()
	model.running = false
	hide()
