extends PanelContainer
## Combat dashboard panel: displays the resolved PlayerStats live. This
## didn't exist as a visible display anywhere before -- the UI mockups
## surfaced it as a real gap, not just a cosmetic one.
##
## Root is PanelContainer (card look via CardStyle) wrapping an inner
## VBoxContainer for content -- matches the card pattern established on
## title/class_select/subclass_select.

const CARD_TITLE_FONT_SIZE := 20
const CONTRACT_ICON := preload("res://assets/ui/icons/contract.png")
const CONTRACT_BADGE_ICON_SIZE := Vector2(20, 20)
const CONTRACT_BADGE_FONT_SIZE := 26
const CONTRACT_BADGE_SIZE := Vector2(64, 26)

## P2:R10: see talent_panel.gd's `state` comment -- same pattern, same
## default, same untyped declaration reason.
var state = BuildState

var _stats_label: RichTextLabel
var _title_label: Label
var _contract_badge: PanelContainer
var _contract_label: Label


func _ready() -> void:
	add_theme_stylebox_override("panel", CardStyle.make_stylebox())

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	add_child(content)

	var title_row := HBoxContainer.new()
	title_row.name = "CharacterStatsTitleRow"
	title_row.add_theme_constant_override("separation", 8)
	content.add_child(title_row)

	_title_label = Label.new()
	_title_label.text = "Character Stats"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title_label.theme_type_variation = &"PanelHeader"
	_title_label.add_theme_font_size_override("font_size", CARD_TITLE_FONT_SIZE)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.clip_text = true
	title_row.add_child(_title_label)

	title_row.add_child(_build_contract_badge())

	# RichTextLabel (not Label) so the poison-damage lines can carry the
	# semantic poison-text color (P2:R7:T2) without a second label node.
	_stats_label = RichTextLabel.new()
	_stats_label.bbcode_enabled = true
	_stats_label.fit_content = true
	_stats_label.scroll_active = false
	_stats_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_stats_label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_stats_label.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_show_stat_details()
	)
	content.add_child(_stats_label)

	state.build_changed.connect(_refresh)
	if state.has_signal("stats_preview_changed"):
		state.stats_preview_changed.connect(_refresh)
	if state.has_signal("run_state_changed"):
		state.run_state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	_refresh_contract_badge()
	if state == null or state.selected_class == null:
		_stats_label.text = ""
		return
	var stats := state.current_player_stats()
	stats = preload("res://scripts/systems/legendary_live_stats.gd").resolve(stats, state.gold, _state_combat_stolen_gold())
	var base_stats := BuildResolver.resolve_stats(state.selected_class, [], [], [])
	var lines: PackedStringArray = []
	lines.append(_stat_line(
		"Weapon Damage", _weapon_damage_text(stats),
		0.0, "",
		false, null, false
	))
	lines.append(_stat_line(
		"Bonus Physical Damage", "%+.0f" % stats.bonus_physical_damage,
		stats.bonus_physical_damage - base_stats.bonus_physical_damage, ""
	))
	lines.append(_stat_line(
		"Physical Damage Increase", "%+.0f%%" % ((stats.physical_damage_multiplier - 1.0) * 100.0),
		(stats.physical_damage_multiplier - base_stats.physical_damage_multiplier) * 100.0, "%",
		false, null
	))
	lines.append(_stat_line(
		"Attack Speed", "%.0f%%" % (stats.attack_speed * 100.0),
		(stats.attack_speed - base_stats.attack_speed) * 100.0, "%"
	))
	var gold_crit_chance_bonus := float(_state_combat_stolen_gold()) * stats.crit_chance_per_stolen_gold * 100.0
	var crit_chance_text := "Cannot crit (converted)" if stats.legendary_signet else "%.0f%%" % (stats.crit_chance * 100.0)
	if stats.crit_chance_per_stolen_gold > 0.0 and not stats.legendary_signet:
		crit_chance_text += " %s" % _gold_bonus_text("+%.0f%%" % gold_crit_chance_bonus)
	lines.append(_stat_line(
		"Crit Chance", crit_chance_text,
		(stats.crit_chance - base_stats.crit_chance) * 100.0, "%"
	))
	var crit_multiplier_text := "%.1fx" % stats.crit_multiplier
	if stats.legendary_signet:
		crit_multiplier_text = "Converted (cannot crit)"
	elif stats.crit_multiplier_per_current_gold > 0.0:
		var gold_crit_multiplier_bonus := stats.current_gold * stats.crit_multiplier_per_current_gold
		crit_multiplier_text += " %s" % _gold_bonus_text("+%.1fx" % gold_crit_multiplier_bonus)
	lines.append(_stat_line(
		"Crit Damage", crit_multiplier_text,
		stats.crit_multiplier - base_stats.crit_multiplier, "x"
	))
	lines.append(_stat_line(
		"Retrigger Chance", "%.0f%%" % (stats.retrigger_chance * 100.0),
		(stats.retrigger_chance - base_stats.retrigger_chance) * 100.0, "%"
	))
	lines.append(_stat_line(
		"Shred Chance", "%.0f%%" % (stats.shred_chance * 100.0),
		(stats.shred_chance - base_stats.shred_chance) * 100.0, "%"
	))
	lines.append(_stat_line(
		"Decay Chance", "%.0f%%" % (stats.decay_chance * 100.0),
		(stats.decay_chance - base_stats.decay_chance) * 100.0, "%"
	))
	lines.append(_stat_line(
		"Poison Proc Chance", "%.0f%%" % (stats.elemental_proc_chance * 100.0),
		(stats.elemental_proc_chance - base_stats.elemental_proc_chance) * 100.0, "%"
	))
	lines.append(_stat_line(
		"Bonus Stacks", "%+d" % stats.bonus_poison_stacks,
		stats.bonus_poison_stacks - base_stats.bonus_poison_stacks, ""
	))
	lines.append(_stat_line(
		"Increased Gold", "%+.0f%%" % ((stats.gold_reward_multiplier - 1.0) * 100.0),
		(stats.gold_reward_multiplier - base_stats.gold_reward_multiplier) * 100.0, "%"
	))
	lines.append(_stat_line(
		"Shop Discount", "%+.0f%%" % (stats.shop_discount * 100.0),
		(stats.shop_discount - base_stats.shop_discount) * 100.0, "%"
	))
	lines.append(_stat_line(
		"Magic Find", "%+.0f%%" % (stats.magic_find * 100.0),
		(stats.magic_find - base_stats.magic_find) * 100.0, "%"
	))
	lines.append(_stat_line(
		"Base Poison Damage", _base_poison_damage_text(stats),
		(stats.base_poison_damage + stats.bonus_base_elemental_damage) - (base_stats.base_poison_damage + base_stats.bonus_base_elemental_damage),
		"", true, UIColors.TEXT_POISON
	))
	lines.append(_stat_line(
		"Poison Damage Increase", "%+.0f%%" % ((stats.elemental_damage_multiplier * stats.poison_tick_damage_multiplier - 1.0) * 100.0),
		(stats.elemental_damage_multiplier * stats.poison_tick_damage_multiplier - base_stats.elemental_damage_multiplier * base_stats.poison_tick_damage_multiplier) * 100.0, "%",
		false, UIColors.TEXT_POISON
	))
	lines.append("Cooldown Reduction: %.4f%%" % (stats.cooldown_reduction * 100.0))
	lines.append("Buff Duration: %+.2f%%" % (stats.increased_buff_duration * 100.0))
	lines.append("Crit to Penetration: %.2f%%" % (stats.crit_applies_penetration * 100.0))
	lines.append("Crit to Potency: %.2f%%" % (stats.crit_applies_potency * 100.0))
	if stats.derivation_error != "": lines.append("Invalid stats: " + stats.derivation_error)
	_stats_label.text = "\n".join(lines)
	_stats_label.tooltip_text = "Click for timing, Legendary effects, owned gear sources and derived combat outputs."


func _build_contract_badge() -> PanelContainer:
	var badge := PanelContainer.new()
	badge.name = "ContractNumberBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_STOP
	badge.custom_minimum_size = CONTRACT_BADGE_SIZE
	var badge_style := CardStyle.make_stylebox(8)
	badge_style.bg_color = UIColors.BADGE_BACKDROP
	badge_style.border_color = UIColors.PANEL_BORDER
	badge_style.content_margin_left = 6
	badge_style.content_margin_right = 7
	badge_style.content_margin_top = 0
	badge_style.content_margin_bottom = 1
	badge.add_theme_stylebox_override("panel", badge_style)
	_contract_badge = badge

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	badge.add_child(row)

	var icon := CardStyle.make_pixel_icon(CONTRACT_ICON, CONTRACT_BADGE_ICON_SIZE)
	icon.name = "ContractNumberIcon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	_contract_label = Label.new()
	_contract_label.name = "ContractNumberLabel"
	_contract_label.text = "0"
	_contract_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_contract_label.add_theme_font_size_override("font_size", CONTRACT_BADGE_FONT_SIZE)
	_contract_label.add_theme_color_override("font_color", UIColors.TEXT_NORMAL)
	_contract_label.add_theme_color_override("font_outline_color", UIColors.TEXT_OUTLINE_STRONG)
	_contract_label.add_theme_constant_override("outline_size", 3)
	row.add_child(_contract_label)
	return badge


func _refresh_contract_badge() -> void:
	if _contract_badge == null or _contract_label == null:
		return
	var contract_count := _current_contract_count()
	_contract_label.text = str(contract_count)
	_contract_badge.tooltip_text = "Contract Number: %d" % contract_count


func _current_contract_count() -> int:
	if state == null:
		return 0
	var value = state.get("completed_contract_count")
	if value == null:
		return 0
	return maxi(0, int(value))


func _weapon_damage_text(stats: PlayerStats) -> String:
	var range_text := "%d" % stats.weapon_damage_min if stats.weapon_damage_min == stats.weapon_damage_max else "%d-%d" % [stats.weapon_damage_min, stats.weapon_damage_max]
	if stats.weapon_damage_uses_fallback and stats.weapon_damage_fallback_reason == "missing_weapon":
		return "%s (unarmed)" % range_text
	return range_text


func _base_poison_damage_text(stats: PlayerStats) -> String:
	var base_damage := stats.base_poison_damage + stats.bonus_base_elemental_damage
	if stats.base_poison_damage > 0.0 or stats.bonus_base_elemental_damage != 0.0:
		base_damage = maxf(PlayerStats.MIN_DAMAGE_BASE, base_damage)
	return "%.1f" % base_damage


## Renders one "Label: value" stat line, optionally color-wrapped.
func _stat_line(label: String, value_text: String, _delta: float, _suffix: String, _one_decimal: bool = false, color: Variant = null, _show_plus_sign: bool = true) -> String:
	var text := "%s: %s" % [label, value_text]
	if color != null:
		text = "[color=#%s]%s[/color]" % [color.to_html(false), text]
	return text


func _gold_bonus_text(text: String) -> String:
	return "[color=#%s]%s[/color]" % [UIColors.TEXT_GOLD.to_html(false), text]


func _state_combat_stolen_gold() -> int:
	if state == null:
		return 0
	return int(state.get("combat_stolen_gold"))


func _stat_delta_text(delta: float, suffix: String, one_decimal: bool = false, show_plus_sign: bool = true) -> String:
	if absf(delta) < 0.05:
		return ""
	var sign := "+" if (delta > 0 and show_plus_sign) else ""
	if one_decimal:
		return " (%s%.1f%s)" % [sign, delta, suffix]
	return " (%s%d%s)" % [sign, roundi(delta), suffix]


## Exact factors and sources stay in detail to keep the M7 card compact.
static func stat_detail_text(stats: PlayerStats) -> String:
	var lines: PackedStringArray = []
	lines.append_array(CardStyle.legendary_stat_lines(stats))
	var flags: Dictionary = stats.special_effects.get("legendary", {})
	for item in LegendaryCatalog.all_items():
		if flags.get(item.legendary_effect_id, false):
			lines.append(item.display_name + ": " + LegendaryCatalog.effect_text(item))
	if flags.get("locket", false):
		lines.append("Locket includes Poison critical hits. Reduces running skill cooldowns only, to zero; no stored credit.")
	if stats.legendary_signet:
		lines.append("Signet converts all uncapped sources once, including temporary and gold bonuses. 150% Crit Chance gives +300% Attack Speed; x2.5 Crit Damage gives +300% Increased Physical Damage.")
	lines.append("Combined cooldown reduction %.6f%%; factor %.9f. Per-affix factors multiply." % [stats.cooldown_reduction * 100.0, stats.cooldown_factor])
	lines.append("Positive cooldowns use ceil(authored x factor), minimum 1ms; authored zero stays zero.")
	lines.append("Duration is additive, with no aggregate cap; Pact extends base before scaling.")
	lines.append("Crit procs: independent chance per critical direct contribution; base 1 stack, then bonus stacks, doubling and cap 50.")
	var timer_math = preload("res://scripts/systems/combat_timer_math.gd")
	var durations := {"Master of Poisons": 5000, "Beguiling Presence": 10000, "Penetration / Potency (Pact included)": 3000 + 1000 * stats.death_pact_rank, "Bypass": 3000, "Touch of Darkness": 12000, "Fancy Footwork": 3000}
	if flags.get("samurai", false): durations["Meditation (all stacks refresh)"] = 3000
	if flags.get("wingjammer", false): durations["Dash (all stacks refresh)"] = 3000
	for label in durations:
		var timer: Dictionary = timer_math.scaled_duration(durations[label], stats.increased_buff_duration)
		lines.append("%s: %s" % [label, str(timer.duration_ms) + "ms" if timer.error == "" else "invalid timer: " + str(timer.error)])
	if stats.dance_duration_ms > 0:
		var dance: Dictionary = timer_math.scaled_duration(stats.dance_duration_ms, stats.increased_buff_duration)
		lines.append("Dance of Death: " + (str(dance.duration_ms) + "ms" if dance.error == "" else "invalid timer"))
	lines.append("Untimed Precision, Readiness and Virulent charges retain their authored lifetime.")
	for detail in stats.derivation_details:
		lines.append("Derived combat output: " + str(detail))
	for source in stats.stat_sources:
		if source.get("stat_id", "") != "":
			var stat_id := String(source.stat_id)
			var raw := float(source.get("value", 0.0))
			var name := "%s [%s] %s" % [source.get("source_id", ""), source.get("source_kind", ""), stat_id]
			lines.append("%s: raw %.6f" % [name, raw])
		elif source.get("source_kind", "") == "gear_aggregate":
			for contribution in source.get("cooldown_contributions", []):
				lines.append("CDR %s slot %s affix %s: raw %.6f, effective %.6f, retained factor %.9f" % [contribution.get("source_item", ""), contribution.get("source_slot", ""), contribution.get("affix_index", ""), contribution.get("raw_value", 0.0), contribution.get("effective_reduction", 0.0), contribution.get("retained_factor", 1.0)])
			for contribution in source.get("contribution_sources", []):
				lines.append("%s index %s slot %s affix %s: %s raw %.6f" % [contribution.get("source_kind", ""), contribution.get("source_index", -1), contribution.get("source_slot", ""), contribution.get("affix_index", ""), contribution.get("stat_id", ""), contribution.get("raw_value", 0.0)])
			lines.append("Gear raw buckets: " + str(source.get("raw_values", {})))
			lines.append("Gear effective buckets (All Stats once): " + str(source.get("values", {})))
		elif source.get("source_kind", "") == "derivation":
			lines.append("Derived: " + str(source))
	return "\n".join(lines)


func _show_stat_details() -> Control:
	var overlay := Control.new()
	overlay.name = "StatDetailsOverlay"
	get_tree().root.add_child(overlay)
	var panel := CardStyle.build_modal_panel(overlay, true)
	overlay.visibility_changed.connect(func():
		if not overlay.visible: overlay.queue_free()
	)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "Timing and Owned Stat Sources"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.text = "Done"
	close.pressed.connect(func(): overlay.hide())
	header.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(minf(740, get_viewport_rect().size.x - 80), minf(460, get_viewport_rect().size.y - 120))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var text := Label.new()
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_font_size_override("font_size", 16)
	var stats: PlayerStats = state.current_player_stats()
	stats = preload("res://scripts/systems/legendary_live_stats.gd").resolve(stats, state.gold, _state_combat_stolen_gold())
	text.text = stat_detail_text(stats)
	scroll.add_child(text)
	return overlay
