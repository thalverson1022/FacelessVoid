extends "res://tests/m9_poison_crit_presentation_test.gd"
## Exercise the actual popup handlers with resolver-produced debuff casts.
const REPORT := "res://reports/m9_blinding_powder/"
const CategoryStyle = preload("res://scripts/ui/skill_category_preview_style.gd")

func _initialize() -> void:
	SaveSystem.save_path = REPORT + "adventure.json"
	PracticeSaveSystem.save_path = REPORT + "practice.json"
	PracticeSaveSystem.core_save_path = REPORT + "core.json"
	SevenSlotSaveBoundary.legacy_path = REPORT + "legacy.json"
	SevenSlotSaveBoundary.marker_path = REPORT + "marker.json"
	call_deferred("run")

func check_debuff(screen: Node, mode: String, kind: String) -> void:
	var skill: Skill = preload("res://scripts/systems/playable_assassin_content.gd").skill(kind)
	var stats := PlayerStats.new()
	stats.assassin_tree_points = 10
	var enemy := Monster.new()
	enemy.hp = 100000
	var rotation: Array[Skill] = [skill]
	var result := CombatResolver.resolve(rotation, stats, enemy, 6000, 1234)
	assert(result.is_valid and not result.cast_events.is_empty(), "Real debuff resolves")
	var cast: CombatResolver.CastEvent = result.cast_events[0]
	assert(cast.physical_damage == 0.0, "Debuff has no physical damage")
	if kind == "blinding_powder":
		assert(cast.potency_stacks_applied == 10, "Record actual Potency grant")
		assert(CategoryStyle.outcome(cast) == "+10 Potency Stacks", "Show numeric Potency stacks")
		stats.bonus_potency_stacks = 3
		stats.special_effects["double_applied_stacks"] = true
		var modified := CombatResolver.resolve(rotation, stats, enemy, 6000, 1234)
		assert(modified.cast_events[0].potency_stacks_applied == 26, "Stack bonuses and doubling recorded")
		assert(modified.cast_events[1].potency_stacks_applied == 24, "Partial grant respects 50-stack cap")
		assert(modified.cast_events[2].potency_stacks_applied == 0, "Full cap records no added stacks")
	var layer: Control = screen._popup_layer
	var owner_view: Node = screen._playback_presenter if mode == "adventure" else screen
	if owner_view._playback == null:
		owner_view._playback = CombatPlayback.new()
	for old in layer.get_children(): old.hide()
	var event := CombatPlayback.PlaybackEvent.new()
	event.cast = cast
	event.chain_count = 1
	event.visual_beat = true
	deliver(screen, mode, event)
	var labels := visible_popups(layer)
	assert(labels.size() == 1, "Exactly one category popup")
	var label := labels[0]
	assert(label.text == skill.display_name + "\n" + CategoryStyle.outcome(cast), "Name and effect on separate lines")
	assert(not "damage" in label.text.to_lower(), "No damage wording")
	assert(label.get_theme_color("font_color") == CategoryStyle.COLORS[Skill.Category.DEBUFF], "Purple debuff color")
	await settle()
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(REPORT + mode + "_" + kind + ".png") == OK)
	evidence[mode + "_" + kind] = {"text": label.text, "color": label.get_theme_color("font_color").to_html(), "rect": str(label.get_global_rect())}
	cast.was_interrupted = true
	assert(CategoryStyle.outcome(cast) == "Interrupted - no effect", "Interrupted cast retains failure feedback")
	cast.was_interrupted = false
	cast.resource_unavailable = true
	assert(CategoryStyle.outcome(cast) == "Missing resource - no effect", "Unavailable cast retains failure feedback")

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
	assert(state.configure_ranked_build(BuildContentRegistry.adventure().trees["tree.assassin"]))
	game._show_combat_screen()
	await settle()
	var screen: Node = game._current_screen
	screen._playback_presenter._monster = Monster.new()
	screen._playback_presenter._monster.hp = 100000
	screen._playback_presenter._hp = 100000.0
	dismiss(screen)
	for kind in ["blinding_powder", "poison_vile"]:
		await check_debuff(screen, "adventure", kind)
	game.queue_free()
	await settle()
	state.reset()
	var room = load("res://scenes/training_room/training_room.tscn").instantiate()
	root.add_child(room)
	await settle()
	room._setup_autosave = false
	for kind in ["blinding_powder", "poison_vile"]:
		await check_debuff(room._combat_view, "practice", kind)
	SaveSystem.write_json(REPORT + "evidence.json", evidence)
	room.queue_free()
	await settle()
	state.reset()
	print("M9 BLINDING POWDER FEEDBACK PASS")
	quit()
