extends SceneTree
const Style = preload("res://scripts/ui/skill_category_preview_style.gd")
var failed := false
func _initialize() -> void: call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		printerr("FAILED: " + message)
func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/category_preview/" + name + ".png")
func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/category_preview")
	var state = root.get_node("BuildState")
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._on_contract_test_pressed(1234, 45, "tree.assassin", "tree.shadow")
	await process_frame
	var screen = game._current_screen
	var preview = screen._category_preview
	check(preview != null and Style.enabled(state), "Only Test Mode activates prototype")
	check(not preview.selector.is_visible_in_tree(), "Preview and reduced-motion toolbar hidden")
	var ranks := {"talent.assassin.quick_hands":5,"talent.assassin.precision":5,"talent.assassin.hastened_poison":2}
	check(state.ranked_build.configure(state.selected_trees[0],state.selected_trees[1],45,ranks), "Legal twelve-point Assassin build")
	state._finish_rank_edit(true)
	var selected := {}
	for skill in state.unlocked_skills(): selected[skill.id] = skill
	var rotation: Array[Skill] = [selected["skill.virulent_poison"],selected["skill.poison_vile"],selected["skill.venom_jab"],selected["skill.stab"],selected["skill.virulent_poison"]]
	var resolved := BuildResolver.resolve_ranked_build(state.selected_class,state.ranked_build,[load("res://data/gear/crude_dagger.tres")])
	var enemy := Monster.new()
	enemy.hp = 100000
	enemy.display_name = "Category preview fixture"
	var result := CombatResolver.resolve(rotation,resolved.stats,enemy,15000,7,false)
	check(result.is_valid, "Fixture valid")
	check(Style.tooltip(rotation[0], state).contains("Cooldown: 10.0s"), "Cooldown distinct from charges")
	check(Style.tooltip(rotation[1], state).contains("No direct damage"), "Debuff tooltip explicit")
	var buff = result.cast_events[0]
	check(Style.outcome(buff).contains("+5 stacks"), "Successful self buff explains charges")
	var blocked = null
	var debuff = null
	for cast in result.cast_events:
		if cast.cooldown_blocked: blocked = cast
		if cast.skill.id == "skill.poison_vile": debuff = cast
	check(blocked != null and Style.outcome(blocked).contains("On cooldown"), "Blocked buff never claims activation")
	check(debuff != null and Style.outcome(debuff).contains(str(debuff.poison_stacks_applied)), "Debuff reports resolved stack count")
	state.accept_contract_offer()
	screen._contract_overlay.hide()
	screen._map_overlay.hide()
	screen.instant_playback = true
	screen._begin_playback(result,enemy)
	screen.set_process(false)
	screen._playback_presenter.advance(0.51)
	check(preview.has_feedback() and preview.notice.text.contains("Virulent Poison"), "Self buff cue rendered")
	check(preview.notice.get_parent() == screen._popup_layer and not preview.notice.has_theme_stylebox_override("normal"), "Category uses unboxed floating text")
	check(preview.notice.get_theme_color("font_color") == Style.COLORS[Skill.Category.SELF_BUFF], "Self buff floating text uses category colour")
	check(screen._combat_stage.player_actor_anchor.position.x == screen._combat_stage._player_base_position.x, "No self-buff forward lunge")
	for resolution in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
		root.size = resolution
		preview.clear()
		await process_frame
		preview.show_cast(buff)
		await capture("buff-%d" % resolution.x)
		preview.clear()
		await process_frame
		preview.show_cast(debuff)
		await capture("debuff-%d" % resolution.x)
	preview.reduced_motion = true
	preview.show_cast(buff)
	check(preview.has_feedback() and preview.pulse_target == null, "Reduced motion retains outcome without pulse")
	preview.clear()
	preview.show_cast(blocked)
	check(not preview.has_feedback(), "Cooldown cast produces no floating text")
	screen._playback_presenter._spawn_cast_popups(blocked)
	check(not preview.has_feedback(), "Presenter also suppresses cooldown text")
	preview.set_enabled(false)
	check(not Style.enabled(state) and not preview.has_feedback(), "Original clears and disables preview")
	check(not SkillTooltipFormatter.compact_tooltip(rotation[0],state).contains("[+ Self Buff]"), "Original tooltip restored")
	preview.set_enabled(true)
	screen._log_overlay.set_result(result,enemy,CombatResultFormatter.format(result,enemy))
	check(screen._log_overlay._log_label.text.contains("[+ Self Buff]") and screen._log_overlay._log_label.text.contains("On cooldown"), "Log uses category and outcome language")
	screen._log_overlay.show_log()
	for resolution in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
		root.size = resolution
		await capture("log-%d" % resolution.x)
	screen._log_overlay.hide()
	preview.set_enabled(false)
	check(not screen._log_overlay._log_label.bbcode_enabled and not screen._log_overlay._log_label.text.begins_with("CATEGORY PREVIEW"), "Original log restored")
	preview.set_enabled(true)
	screen._playback_presenter.skip()
	check(not preview.has_feedback() and preview.pulse_target == null, "Skip clears category feedback")
	screen._begin_playback(result,enemy)
	screen.set_process(false)
	check(not preview.has_feedback(), "Retry clears previous outcome")
	screen._playback_presenter.advance(0.51)
	screen._playback_presenter.set_speed(4.0)
	check(preview.pulse_target == null, "Speed change cancels category movement")
	screen._playback_presenter.advance(15.0)
	check(not preview.has_feedback(), "Completion clears category feedback")
	var unchanged := CombatResolver.resolve(rotation,resolved.stats,enemy,15000,7,false)
	check(unchanged.total_damage == result.total_damage and unchanged.rng_final_state == result.rng_final_state, "Presentation preserves combat result")
	state.is_test_mode = false
	game._show_combat_screen()
	await process_frame
	check(game._current_screen._category_preview != null and Style.enabled(state), "Adventure uses approved category feedback")
	check(not game._current_screen._log_overlay.category_preview, "Adventure excludes experimental log")
	# Practice uses the same accepted non-attack cues and existing plain log.
	var practice_view := TrainingRoomCombatView.new()
	root.add_child(practice_view)
	await process_frame
	check(practice_view._category_preview != null, "Practice category feedback installed")
	practice_view._category_preview.show_cast(buff)
	check(practice_view._category_preview.notice.text.contains("+5 stacks"), "Practice self-buff shows charges rather than damage")
	check(practice_view._category_preview.notice.get_theme_color("font_color") == Style.COLORS[Skill.Category.SELF_BUFF], "Practice uses approved buff color")
	practice_view._category_preview.clear()
	practice_view._category_preview.show_cast(blocked)
	check(not practice_view._category_preview.has_feedback(), "Practice cooldown produces no floating text")
	practice_view._category_preview.windup(buff, 1.0)
	check(practice_view._combat_stage.player_actor_anchor.position.x == practice_view._combat_stage._player_base_position.x, "Practice buff avoids forward lunge")
	practice_view._set_speed(2.0)
	check(practice_view._category_preview.pulse_target == null, "Practice speed change clears category motion")
	practice_view.queue_free()
	game.queue_free()
	await process_frame
	state.reset()
	print("Category preview: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
