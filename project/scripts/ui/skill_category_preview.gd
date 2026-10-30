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
var pulse_moves_target := false
func _process(_delta: float) -> void:
	if (reduced_motion or CombatEffectIcons.reduced_motion) and is_instance_valid(screen) and is_instance_valid(screen._combat_stage):
		screen._combat_stage.cancel_category_pose()
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
	selector.tooltip_text = "Test Mode only: Stab, Venom Jab, Poison Vile, Virulent Poison and Blinding Powder."
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
	return enabled and Style.popup_selected(cast.skill) and cast.skill.category != Skill.Category.ATTACK
func windup(cast: CombatResolver.CastEvent, speed: float) -> void:
	var stage = screen._combat_stage
	stage.begin_category_windup(cast,speed,not reduced_motion and not CombatEffectIcons.reduced_motion)
func update_cast_progress(cast: CombatResolver.CastEvent, progress: float, speed: float) -> void:
	if not handles(cast):
		screen._combat_stage.update_category_attack_handoff(cast,progress,speed)
	elif not cast.cooldown_blocked and not cast.resource_unavailable:
		screen._combat_stage.update_category_progress(cast,progress,speed,not reduced_motion and not CombatEffectIcons.reduced_motion)
func activate(cast: CombatResolver.CastEvent, speed: float, animate: bool = true) -> void:
	var successful := not cast.cooldown_blocked and not cast.resource_unavailable and not cast.was_interrupted and not cast.was_dodged
	if not animate or reduced_motion or CombatEffectIcons.reduced_motion:
		screen._combat_stage.cancel_category_pose()
	elif successful:
		screen._combat_stage.activate_category_pose(cast,speed,true)
	else:
		screen._combat_stage.reject_category_pose(cast)
func show_cast(cast: CombatResolver.CastEvent) -> void:
	if cast.cooldown_blocked: return
	clear_pulse()
	var outcome: String = Style.outcome(cast)
	if cast.skill.id == "skill.virulent_poison" and outcome.begins_with("+5"): outcome = "+5 stacks"
	if practice_view:
		notice = screen._spawn_text_popup(cast.skill.display_name + "\n" + outcome, Style.COLORS[cast.skill.category])
	else:
		notice = screen._popup_layer.spawn(cast.skill.display_name + "\n" + outcome, CombatPopupLayer.Kind.NORMAL, Style.COLORS[cast.skill.category], reduced_motion or CombatEffectIcons.reduced_motion, 36)
	if notice != null and preload("res://scripts/ui/combat_effect_text.gd").is_health_removal(cast): notice.set_meta("health_removal_initial", true)
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
		if pulse_moves_target: pulse_target.position = pulse_origin
		pulse_target.modulate = Color.WHITE
	pulse_target = null
	pulse_moves_target = false
func clear() -> void:
	if is_instance_valid(screen) and is_instance_valid(screen._combat_stage): screen._combat_stage.cancel_category_pose()
	clear_feedback()
func clear_feedback() -> void:
	clear_pulse()
	if is_instance_valid(notice): notice.hide()
	if is_instance_valid(screen) and is_instance_valid(screen._popup_layer) and screen._popup_layer.has_method("clear_transient_effects"):
		screen._popup_layer.clear_transient_effects()
	notice = null
func _exit_tree() -> void: clear_pulse()

func has_feedback() -> bool:
	return is_instance_valid(notice) and notice.visible and not notice.is_queued_for_deletion()
