extends "res://tests/m9_poison_crit_presentation_test.gd"
## Exercise the actual popup handlers with resolver-produced debuff casts.
const REPORT := "res://reports/m9_all_debuff/"
const CategoryStyle = preload("res://scripts/ui/skill_category_preview_style.gd")

func _initialize() -> void:
	SaveSystem.save_path = REPORT + "adventure.json"
	PracticeSaveSystem.save_path = REPORT + "practice.json"
	PracticeSaveSystem.core_save_path = REPORT + "core.json"
	SevenSlotSaveBoundary.legacy_path = REPORT + "legacy.json"
	SevenSlotSaveBoundary.marker_path = REPORT + "marker.json"
	call_deferred("run")

func check_debuff(screen: Node, mode: String, kind: String) -> void:
	var skill: Skill
	if kind == "pick_pocket": skill = preload("res://scripts/systems/p6_thief_contracts.gd").skill(kind)
	elif kind == "exsanguinate": skill = preload("res://data/skills/exsanguinate.tres")
	elif kind == "future_debuff":
		skill = Skill.new()
		skill.id = "test.future_debuff"
		skill.display_name = "Future Debuff"
		skill.category = Skill.Category.DEBUFF
		skill.base_execution_ms = 500
	else: skill = preload("res://scripts/systems/playable_assassin_content.gd").skill(kind)
	var stats := PlayerStats.new()
	stats.assassin_tree_points = 10
	stats.gold_reward_multiplier = 2.0
	var enemy := Monster.new()
	enemy.hp = 100000
	var rotation: Array[Skill] = [skill]
	if kind == "exsanguinate":
		var fuel := Skill.new()
		fuel.id = "test.shred_fuel"
		fuel.display_name = "Shred Fuel"
		fuel.base_execution_ms = 100
		var effect := preload("res://scripts/resources/armor_reduction_effect.gd").new()
		effect.amount = 7
		fuel.effects.append(effect)
		rotation.push_front(fuel)
	var result := CombatResolver.resolve(rotation, stats, enemy, 6000, 1234)
	assert(result.is_valid and not result.cast_events.is_empty(), "Real debuff resolves")
	var cast: CombatResolver.CastEvent = result.cast_events[1 if kind == "exsanguinate" else 0]
	assert(CategoryStyle.popup_selected(skill), "Every DEBUFF automatically selects popup feedback")
	if kind == "pick_pocket":
		assert(cast.gold_stolen == 20 and CategoryStyle.outcome(cast) == "+20 Gold Stolen", "Actual credited theft with gold multiplier")
	if kind == "exsanguinate":
		assert(cast.health_removed > 0 and CategoryStyle.outcome(cast) == "Removes %.0f Health" % cast.health_removed, "Actual recorded health removal")
	if kind == "future_debuff": assert(CategoryStyle.outcome(cast) == "Debuff Applied", "Future category fallback contains no fake damage")
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
	assert_effect_popup(label, cast)
	assert(not "damage" in label.text.to_lower(), "No damage wording")
	assert(label.get_theme_color("font_color") == CategoryStyle.COLORS[Skill.Category.DEBUFF], "Purple debuff color")
	await settle()
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().get_size() == Vector2i(1600,900))
	assert(root.get_texture().get_image().save_png(REPORT + mode + "_" + kind + ".png") == OK)
	evidence[mode + "_" + kind] = {"text": label.text, "color": label.get_theme_color("font_color").to_html(), "rect": str(label.get_global_rect())}
	if kind == "exsanguinate": assert(label.get_meta("health_removal_initial", false), "Initial health removal popup metadata")
	# Echo text follows the same category contract, including credited gold.
	for old in layer.get_children(): old.hide()
	var echo: Label
	if mode == "adventure": echo = layer.spawn_retrigger(cast, 2)
	else:
		event.chain_index = 2
		echo = screen._spawn_retrigger_popup(event)
	assert(echo != null)
	assert_effect_popup(echo, cast)
	assert(echo.get_theme_color("font_color") == CategoryStyle.COLORS[Skill.Category.DEBUFF], "Echo stays purple")
	cast.was_interrupted = true
	assert(CategoryStyle.outcome(cast) == "Interrupted - no effect", "Interrupted cast retains failure feedback")
	cast.was_interrupted = false
	# Failed casts still use the two-line purple feedback through the handler.
	for old in layer.get_children(): old.hide()
	cast.was_dodged = true
	deliver(screen, mode, event)
	assert(visible_popups(layer)[0].text.ends_with("Dodged - no effect"))
	cast.was_dodged = false
	cast.resource_unavailable = true
	assert(CategoryStyle.outcome(cast) == "Missing resource - no effect", "Unavailable cast retains failure feedback")
	cast.resource_unavailable = false
	cast.cooldown_blocked = true
	for old in layer.get_children(): old.hide()
	deliver(screen, mode, event)
	assert(visible_popups(layer).is_empty(), "Cooldown casts produce no popup")
	cast.cooldown_blocked = false
	if mode == "adventure": owner_view.skipping = true
	else: screen._playback_skipping = true
	deliver(screen, mode, event)
	assert(visible_popups(layer).is_empty(), "Skip suppresses debuff popups")
	if mode == "adventure": owner_view.skipping = false
	else: screen._playback_skipping = false

func assert_effect_popup(label: Label, cast: CombatResolver.CastEvent) -> void:
	var expected := cast.skill.display_name + "\n" + CategoryStyle.outcome(cast)
	if "Gold Stolen" in expected:
		assert(not "Gold Stolen" in label.text, "Gold icon replaces wording")
		assert(label.text.begins_with(cast.skill.display_name + "\n+%d " % cast.gold_stolen), "Credited amount remains visible")
		var icon: TextureRect = label.get_node("GoldAmountIcon")
		assert(icon.texture == preload("res://assets/ui/icons/gold.png"), "Use actual shared gold artwork")
		assert(Rect2(Vector2.ZERO, label.size).encloses(Rect2(icon.position, icon.size)), "Gold icon fits within popup")
	else:
		assert(label.text == expected, "Name and effect on separate lines")

func check_category_contract() -> void:
	var future := Skill.new()
	future.id = "test.future_debuff"
	future.category = Skill.Category.DEBUFF
	assert(CategoryStyle.popup_selected(future) and not CategoryStyle.selected(future), "Popup adoption leaves tooltip and log selection unchanged")
	var cast := CombatResolver.CastEvent.new()
	cast.skill = future
	cast.poison_stacks_applied = 2
	cast.potency_stacks_applied = 3
	cast.shred_stacks_applied = 4
	cast.decay_stacks_applied = 5
	cast.gold_stolen = 6
	cast.health_removed = 7
	assert(CategoryStyle.outcome(cast) == "+2 Poison stacks | +3 Potency Stacks | +4 Shred stacks | +5 Decay stacks | +6 Gold Stolen | Removes 7 Health", "Future Debuff uses all recorded effect fields")
	cast.skill = preload("res://scripts/systems/p6_thief_contracts.gd").skill("pick_pocket")
	cast.gold_stolen = 0
	assert(CategoryStyle.outcome(cast) == "+0 Gold Stolen", "Zero credited theft is truthful")
	cast.skill = preload("res://data/skills/exsanguinate.tres")
	cast.health_removed = 0
	assert(CategoryStyle.outcome(cast) == "Removes 0 Health", "Zero Shred remains health removal")
	var buff := Skill.new()
	buff.category = Skill.Category.SELF_BUFF
	assert(CategoryStyle.popup_selected(buff), "Self Buff category now has its own popup adoption")

func run() -> void:
	check_category_contract()
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
	for kind in ["blinding_powder", "poison_vile", "pick_pocket", "exsanguinate", "future_debuff"]:
		await check_debuff(screen, "adventure", kind)
	game.queue_free()
	await settle()
	state.reset()
	var room = load("res://scenes/training_room/training_room.tscn").instantiate()
	root.add_child(room)
	await settle()
	room._setup_autosave = false
	for kind in ["blinding_powder", "poison_vile", "pick_pocket", "exsanguinate", "future_debuff"]:
		await check_debuff(room._combat_view, "practice", kind)
	SaveSystem.write_json(REPORT + "evidence.json", evidence)
	room.queue_free()
	await settle()
	state.reset()
	print("M9 ALL DEBUFF FEEDBACK PASS")
	quit()
