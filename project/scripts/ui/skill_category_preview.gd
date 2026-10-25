extends Node
const Style = preload("res://scripts/ui/skill_category_preview_style.gd")
var screen
var practice_view := false
var enabled := true
var reduced_motion := false
var selector: OptionButton
var notice: Label
var pulse: Tween
var pulse_target: Control
var pulse_origin := Vector2.ZERO
func _ready() -> void:
	if practice_view: return
	var row := HBoxContainer.new()
	row.name = "CategoryPreviewControls"
	row.hide()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	screen._combat_content.add_child(row)
	screen._combat_content.move_child(row, screen._fight_button_row.get_index() + 1)
	selector = OptionButton.new()
	selector.add_item("Original")
	selector.add_item("Category Preview")
	selector.select(1)
	selector.add_theme_font_override("font", load("res://assets/fonts/VT323-Regular.ttf"))
	selector.add_theme_font_size_override("font_size", 20)
	row.add_child(selector)
	selector.tooltip_text = "Test Mode only: Stab, Venom Jab, Poison Vile and Virulent Poison."
	selector.item_selected.connect(func(index): set_enabled(index == 1))
	var motion := CheckBox.new()
	motion.text = "Reduced motion"
	motion.add_theme_font_override("font", load("res://assets/fonts/VT323-Regular.ttf"))
	motion.add_theme_font_size_override("font_size", 20)
	row.add_child(motion)
	motion.toggled.connect(func(value): reduced_motion = value; clear())
	screen._playback_presenter.category_preview = self
	set_enabled(true)
	screen._sync_combat_play_area_reserved_height()
func set_enabled(value: bool) -> void:
	enabled = value
	screen.get_node("/root/BuildState").set_meta("category_preview", value)
	clear()
	screen._popup_layer.clear_transient_effects()
	screen._combat_stage.clear_transient_effects()
	_refresh_palette(screen)
	screen._log_overlay.category_preview = value and screen.get_node("/root/BuildState").is_test_mode
	screen._log_overlay.refresh_category_preview()
func _refresh_palette(node: Node) -> void:
	if node.get_script() == load("res://scenes/combat/available_skills_panel.gd"):
		node._shown_ids = []
		node._refresh()
	for child in node.get_children(): _refresh_palette(child)
func handles(cast: CombatResolver.CastEvent) -> bool:
	return enabled and Style.selected(cast.skill) and cast.skill.category != Skill.Category.ATTACK
func windup(cast: CombatResolver.CastEvent, speed: float) -> void:
	clear_pulse()
	var stage = screen._combat_stage
	stage._kill_player_tween()
	stage.player_actor_anchor.position = stage._player_base_position
	stage._set_player_animation("idle", true)
	if reduced_motion or CombatEffectIcons.reduced_motion: return
	pulse_target = stage.player_actor_anchor
	pulse_origin = pulse_target.position
	pulse = create_tween()
	var duration := maxf(0.05, (cast.time_ms - cast.cast_start_ms) / 1000.0 / maxf(speed, 0.01))
	pulse.tween_property(pulse_target, "position", pulse_origin + Vector2(0, -5), duration * 0.5)
	pulse.tween_property(pulse_target, "position", pulse_origin, duration * 0.5)
func show_cast(cast: CombatResolver.CastEvent) -> void:
	if cast.cooldown_blocked: return
	clear_pulse()
	var outcome: String = Style.outcome(cast)
	if cast.skill.id == "skill.virulent_poison" and outcome.begins_with("+5"): outcome = "+5 stacks"
	if practice_view:
		notice = screen._spawn_text_popup(cast.skill.display_name + "\n" + outcome, Style.COLORS[cast.skill.category])
	else:
		notice = screen._popup_layer.spawn(cast.skill.display_name + "\n" + outcome, CombatPopupLayer.Kind.NORMAL, Style.COLORS[cast.skill.category], reduced_motion or CombatEffectIcons.reduced_motion, 36)
	if reduced_motion or CombatEffectIcons.reduced_motion or cast.cooldown_blocked or cast.resource_unavailable or cast.was_interrupted or cast.was_dodged: return
	pulse_target = screen._combat_stage.player_actor_anchor if cast.skill.category == Skill.Category.SELF_BUFF else screen._combat_stage.enemy_actor_anchor
	if pulse_target == null: return
	pulse_origin = pulse_target.position
	pulse_target.modulate = Style.COLORS[cast.skill.category]
	pulse = create_tween()
	pulse.tween_property(pulse_target, "modulate", Color.WHITE, 0.35)
func clear_pulse() -> void:
	if pulse != null and pulse.is_valid(): pulse.kill()
	if is_instance_valid(pulse_target):
		pulse_target.position = pulse_origin
		pulse_target.modulate = Color.WHITE
	pulse_target = null
func clear() -> void:
	clear_pulse()
	if is_instance_valid(notice): notice.hide()
	if is_instance_valid(screen) and is_instance_valid(screen._popup_layer) and screen._popup_layer.has_method("clear_transient_effects"):
		screen._popup_layer.clear_transient_effects()
	notice = null
func _exit_tree() -> void: clear_pulse()

func has_feedback() -> bool:
	return is_instance_valid(notice) and notice.visible and not notice.is_queued_for_deletion()
