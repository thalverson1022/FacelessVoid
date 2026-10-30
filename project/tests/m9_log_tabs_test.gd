extends SceneTree
const OUT := "res://reports/m9_log_tabs/"
var checks := 0
var geometry: Array = []
func _initialize() -> void: call_deferred("run")
func verify(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		printerr("FAILED: ", message)
		quit(1)
		assert(ok, message)
func settle() -> void:
	for frame in 5: await process_frame
func capture(label: String) -> void:
	await settle()
	if OS.get_cmdline_user_args().has("--visual"):
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png(OUT + label + ".png") == OK)
func fixture() -> Dictionary:
	var stats := BuildResolver.resolve_stats(load("res://data/classes/rogue.tres"), [], [], [])
	var target := Monster.new()
	target.display_name = "Stress Target"
	target.hp = 1000000
	var skills: Array[Skill] = []
	for index in 22:
		var skill: Skill = load("res://data/skills/stab.tres").duplicate(true)
		skill.id = "fixture.skill_%02d" % index
		skill.display_name = "Resolved Skill %02d" % index
		skill.base_execution_ms = 200
		skill.min_execution_ms = 200
		skills.append(skill)
	return {"result": CombatResolver.resolve(skills, stats, target, 44000, 2, true), "target": target}
func exercise(overlay: Control, f: Dictionary, mode: String, history: Array) -> void:
	overlay.set_result(f.result, f.target, "legacy header must not appear")
	overlay.set_run_history(history)
	overlay.show_log()
	await settle()
	verify(overlay._tabs.get_tab_count() == 3, "three tabs")
	for index in 3:
		verify(overlay._tabs.get_tab_title(index) == ["Damage Breakdown", "Event Log", "Run Log"][index], "tab order")
	verify(overlay._inspector._summary_row.get_child_count() == 3, "three summary chips")
	verify(overlay._inspector._damage_chart._rows.size() >= 22, "resolved many-skill fixture")
	verify(overlay._inspector._damage_chart._total_damage == f.result.total_health_loss(), "percent denominator uses ranked resolved damage")
	for resolution in [Vector2i(1600,900),Vector2i(1280,720)]:
		root.content_scale_size = resolution
		root.size = resolution
		await settle()
		var suffix := "%s_%dx%d" % [mode,resolution.x,resolution.y]
		overlay._damage_scroll.scroll_vertical = 0
		overlay._run_scroll.scroll_vertical = 0
		overlay._log_label.scroll_to_line(0)
		overlay._tabs.current_tab = 0
		await capture(suffix + "_damage")
		verify(Rect2(Vector2.ZERO, Vector2(resolution)).encloses(overlay._panel.get_global_rect()), "panel bounded")
		var damage_bar: VScrollBar = overlay._damage_scroll.get_v_scroll_bar()
		verify(damage_bar.max_value > damage_bar.page, "damage content scrolls")
		overlay._damage_scroll.scroll_vertical = int(damage_bar.max_value)
		await capture(suffix + "_damage_bottom")
		verify(overlay._inspector._timeline_chart.get_global_rect().end.y <= overlay._damage_scroll.get_global_rect().end.y + 1, "last timeline row reachable")
		var damage_position: int = overlay._damage_scroll.scroll_vertical
		overlay._tabs.current_tab = 1
		overlay._log_label.scroll_to_line(0)
		await capture(suffix + "_events")
		var event_height: float = overlay._log_label.size.y
		verify(event_height > 350 and event_height < resolution.y - 80, "full-height bounded events")
		verify(not overlay._log_label.text.contains("legacy header") and not overlay._log_label.text.contains("Summary:"), "events only")
		overlay._log_label.get_v_scroll_bar().value = overlay._log_label.get_v_scroll_bar().max_value
		await capture(suffix + "_events_bottom")
		verify(overlay._log_label.get_v_scroll_bar().value > 0, "last event reachable")
		var event_position: float = overlay._log_label.get_v_scroll_bar().value
		overlay._tabs.current_tab = 2
		await capture(suffix + "_run")
		var run_bar: VScrollBar = overlay._run_scroll.get_v_scroll_bar()
		if not history.is_empty():
			verify(run_bar.max_value > run_bar.page, "long history scrolls")
			overlay._run_scroll.scroll_vertical = int(run_bar.max_value)
			await capture(suffix + "_run_bottom")
			verify(overlay._run_list.get_child(-1).get_global_rect().end.y <= overlay._run_scroll.get_global_rect().end.y + 1, "last history row reachable")
		else:
			verify(overlay._run_list.get_child(0).text == "Adventure run history is not recorded in Practice.", "Practice history stays empty")
		var run_position: int = overlay._run_scroll.scroll_vertical
		overlay.hide()
		overlay.show_log()
		overlay._tabs.current_tab = 0
		await settle()
		verify(overlay._damage_scroll.scroll_vertical == damage_position, "damage scroll retained")
		overlay._tabs.current_tab = 1
		await settle()
		verify(is_equal_approx(overlay._log_label.get_v_scroll_bar().value,event_position), "event scroll retained")
		overlay._tabs.current_tab = 2
		await settle()
		verify(overlay._run_scroll.scroll_vertical == run_position, "run scroll retained")
		geometry.append({"mode":mode,"resolution":str(resolution),"event_height":event_height,"damage_rows":overlay._inspector._damage_chart._rows.size(),"history_rows":history.size()})
	# Fewer damage rows cannot change the Event Log viewport.
	var full_event_height: float = overlay._log_label.size.y
	var short_result := CombatResolver.CombatResult.new()
	short_result.duration_ms = f.result.duration_ms
	short_result.cast_events.append(f.result.cast_events[0])
	overlay.set_result(short_result, f.target, "")
	overlay._tabs.current_tab = 1
	await settle()
	verify(is_equal_approx(overlay._log_label.size.y, full_event_height), "event viewport independent of damage row count")
	# A new fight resets all page scrolls, even when their page is hidden.
	overlay.set_result(f.result, f.target, "")
	await settle()
	verify(overlay._damage_scroll.scroll_vertical == 0 and overlay._run_scroll.scroll_vertical == 0 and overlay._log_label.get_v_scroll_bar().value == 0, "new result resets scrolls")
	var empty := CombatResolver.CombatResult.new()
	overlay.set_result(empty, f.target, "")
	overlay._tabs.current_tab = 1
	await capture(mode + "_empty")
	verify(overlay._log_label.text.contains("Nothing happened"), "empty narrative")
	empty.is_valid = false
	empty.failure = {"code":"invalid_macro_schedule","message":"Fixture diagnostic"}
	overlay.set_result(empty,f.target,"")
	await capture(mode + "_invalid")
	verify(overlay._log_label.text.contains("Fixture diagnostic") and overlay._details.text.contains("Fixture diagnostic"), "invalid diagnostic preserved")
	overlay.set_result_text("Text-only fixture [brackets]")
	await capture(mode + "_text")
	verify(not overlay._inspector.visible and not overlay._inspector._summary_row.visible and overlay._log_label.text == "Text-only fixture [brackets]", "text-only result hides stale charts and shared summary")
	overlay.set_result(f.result,f.target,"")
	overlay.category_preview = true
	overlay.refresh_category_preview()
	verify(overlay._log_label.bbcode_enabled and overlay._log_label.text.contains("FULL EVENT LOG"), "category preview policy retained")
	overlay.category_preview = false
	overlay.refresh_category_preview()
	overlay.hide()
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.theme = load("res://assets/ui_theme.tres")
	var f := fixture()
	verify(f.result.is_valid and f.result.cast_events.size() >= 100, "resolved fixture valid and long")
	var real_state = root.get_node("BuildState")
	var before_gold: int = real_state.gold
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_new_game_pressed(1928)
	real_state.set_class(load("res://data/classes/rogue.tres"))
	var registry := BuildContentRegistry.adventure()
	assert(real_state.configure_ranked_build(registry.trees["tree.bladedancer"]))
	game._show_combat_screen()
	await settle()
	var screen = game._current_screen
	for field in ["_contract_overlay", "_map_overlay", "_story_overlay", "_talent_overlay", "_secondary_subclass_overlay"]:
		var modal = screen.get(field)
		if modal != null: modal.hide()
	var overlay = screen._log_overlay
	var history: Array = []
	for index in 45:
		history.append({"fight_number":index+1,"contract_count":index/3+1,"contract_name":"Contract %02d" % (index/3+1),"enemy_name":"Enemy %02d" % index,"player_dps":40.0+index,"is_win":index%4!=0})
	await exercise(overlay,f,"adventure",history)
	game.queue_free()
	await settle()
	before_gold = real_state.gold
	var room = load("res://scenes/training_room/training_room.tscn").instantiate()
	root.add_child(room)
	await settle()
	room._state.last_result = f.result
	room._state.selected_target = f.target
	room._on_combat_view_finished()
	verify(room._log_inspector == room._log_overlay._inspector and room._result_log == room._log_overlay._log_label, "Practice aliases share overlay")
	verify(not room._view_log_button.disabled and room._log_overlay.practice_mode, "Practice finish populates shared log")
	await exercise(room._log_overlay,f,"practice",[])
	room._invalidate_result_review()
	verify(room._view_log_button.disabled and not room._log_overlay.visible and not room._log_inspector._summary_row.visible, "Practice invalidation hides summary and log")
	verify(real_state.gold == before_gold, "Practice review leaves Adventure gold untouched")
	room.queue_free()
	await settle()
	var output := FileAccess.open(OUT + "geometry.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(geometry,"\t"))
	print("M9_LOG_TABS PASS checks=",checks)
	quit()
