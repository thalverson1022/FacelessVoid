extends "res://tests/m9_poison_crit_presentation_test.gd"
const SELF_REPORT := "res://reports/m9_self_buff_feedback/"
const Style = preload("res://scripts/ui/skill_category_preview_style.gd")

func _initialize() -> void:
	SaveSystem.save_path = SELF_REPORT + "adventure.json"
	PracticeSaveSystem.save_path = SELF_REPORT + "practice.json"
	PracticeSaveSystem.core_save_path = SELF_REPORT + "core.json"
	SevenSlotSaveBoundary.legacy_path = SELF_REPORT + "legacy.json"
	SevenSlotSaveBoundary.marker_path = SELF_REPORT + "marker.json"
	call_deferred("run")

func verify_buff(screen: Node, mode: String, kind: String) -> void:
	var skill: Skill
	if kind == "dance_of_death": skill = preload("res://scripts/systems/p6_thief_contracts.gd").skill(kind)
	elif kind == "future":
		skill = Skill.new()
		skill.id = "test.future_buff"
		skill.display_name = "Future Buff"
		skill.category = Skill.Category.SELF_BUFF
		skill.base_execution_ms = 500
	else: skill = preload("res://scripts/systems/p6_status_skill_contracts.gd").skill(kind)
	var fuel := Skill.new()
	fuel.id = "test.buff_fuel"
	fuel.display_name = "Buff Fuel"
	fuel.base_execution_ms = 100
	fuel.poison_stacks_applied = 20
	var decay := PoisonResistanceReductionEffect.new()
	decay.reduction_fraction = 0.1
	fuel.effects.append(decay)
	var stats := PlayerStats.new()
	stats.dance_duration_ms = skill.dance_duration_ms
	var enemy := Monster.new()
	enemy.hp = 100000
	var rotation: Array[Skill] = [fuel, skill]
	var result := CombatResolver.resolve(rotation, stats, enemy, 2000, 1234)
	assert(result.is_valid and result.cast_events.size() > 1)
	var cast: CombatResolver.CastEvent = result.cast_events[1]
	assert(cast.skill.id == skill.id and Style.popup_selected(skill))
	assert(not Style.outcome(cast).to_lower().ends_with(" damage"))
	if kind == "beguiling_presence": assert(Style.outcome(cast) == "Elemental Damage Buff")
	if kind == "touch_of_darkness": assert(Style.outcome(cast) == "Attack Speed Buff")
	if kind == "dance_of_death": assert(Style.outcome(cast) == "Guaranteed Retriggers")
	var owner: Node = screen._playback_presenter if mode == "adventure" else screen
	if owner._playback == null: owner._playback = CombatPlayback.new()
	for old in screen._popup_layer.get_children(): old.hide()
	var event := CombatPlayback.PlaybackEvent.new()
	event.cast = cast
	event.chain_count = 1
	deliver(screen, mode, event)
	var labels := visible_popups(screen._popup_layer)
	assert(labels.size() == 1)
	var label := labels[0]
	assert(label.text.begins_with(skill.display_name + "\n") and not label.text.to_lower().ends_with(" damage"))
	assert(label.get_theme_color("font_color") == Style.COLORS[Skill.Category.SELF_BUFF])
	await settle()
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(SELF_REPORT + mode + "_" + kind + ".png") == OK)
	for old in screen._popup_layer.get_children(): old.hide()
	var echo: Label
	if mode == "adventure": echo = screen._popup_layer.spawn_retrigger(cast, 2)
	else:
		event.chain_index = 2
		echo = screen._spawn_retrigger_popup(event)
	assert(echo.text == skill.display_name + "\n" + Style.outcome(cast))
	assert(echo.get_theme_color("font_color") == Style.COLORS[Skill.Category.SELF_BUFF])
	cast.was_interrupted = true
	assert(Style.outcome(cast) == "Interrupted - no effect")
	cast.was_interrupted = false
	cast.status_transactions.clear()
	if kind == "touch_of_darkness": assert(Style.outcome(cast) == "No Poison Consumed")
	if kind == "beguiling_presence": assert(Style.outcome(cast) == "No Decay Consumed")

func check_self_buffs(screen: Node, mode: String) -> void:
	for kind in ["dance_of_death", "master_of_poisons", "virulent_poison", "beguiling_presence", "touch_of_darkness", "future"]:
		await verify_buff(screen, mode, kind)

func run() -> void:
	root.size = Vector2i(1600,900)
	root.gui_embed_subwindows = true
	CombatEffectIcons.reduced_motion = false
	state = root.get_node("BuildState")
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_new_game_pressed(1928)
	state.set_class(BuildContentRegistry.adventure().classes["class.rogue"])
	assert(state.configure_ranked_build(BuildContentRegistry.adventure().trees["tree.thief"]))
	game._show_combat_screen()
	await settle()
	var screen: Node = game._current_screen
	screen._playback_presenter._monster = Monster.new()
	screen._playback_presenter._monster.hp = 100000
	screen._playback_presenter._hp = 100000.0
	dismiss(screen)
	await check_self_buffs(screen, "adventure")
	game.queue_free()
	await settle()
	state.reset()
	var room = load("res://scenes/training_room/training_room.tscn").instantiate()
	root.add_child(room)
	await settle()
	room._setup_autosave = false
	await check_self_buffs(room._combat_view, "practice")
	room.queue_free()
	await settle()
	state.reset()
	print("M9 SELF BUFF FEEDBACK PASS")
	quit()
