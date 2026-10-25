extends SceneTree
const OUT := "res://reports/t6_effects"
const IDS := ["footwork", "readiness", "precision", "dance", "bypass", "virulent_poison", "master_of_poisons", "touch.1", "beguiling_presence", "greed"]
var rows: Array = []
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in 8: await process_frame
	if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw
func fixture(count: int):
	var result := CombatResolver.CombatResult.new()
	result.duration_ms = 20000
	for i in count:
		var id: String = IDS[i] if i < IDS.size() else "synthetic_%d" % i
		result.trace.record("effect_lifecycle", 0, {"effect_instance_id": "fixture%d" % i, "source_id": "skill.quick_cut"}, {"effect_id": id, "after": {"units": 5 if i == 5 else 1, "expires_at_ms": -1 if i in [1,2,5,9] else 10000 + i * 100, "magnitude": 0.1}})
	return result
func check(condition: bool, message: String) -> void:
	assert(condition, message)
func shot(name: String) -> void:
	await settle()
	if DisplayServer.get_name() != "headless": root.get_texture().get_image().save_png(OUT + "/" + name + ".png")
func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	root.push_input(event, true)
	await process_frame
	event = InputEventKey.new()
	event.keycode = code
	root.push_input(event, true)
	await settle()
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var panel := CombatEffectIcons.new()
	root.add_child(panel)
	await settle()
	for count in [5,10,12]:
		panel.begin(fixture(count))
		panel.advance_to(1500)
		check(panel.active.size() == count, "All fixture instances retained")
		check(panel._chips.size() == 4, "Retained four visible groups")
		panel._open_inspector()
		check(panel._details.text.count("Source:") == count, "Every independent instance inspectable")
		panel.begin(fixture(count))
		check(not panel._dialog.visible, "Retry closes prior inspector")
	panel.begin(fixture(10))
	panel._inspect.grab_focus()
	await key(KEY_ENTER)
	check(panel._dialog.visible, "Keyboard Enter activates overflow")
	await key(KEY_ESCAPE)
	check(not panel._dialog.visible and panel._inspect.has_focus(), "Escape returns focus to overflow opener")
	var chip: Button = panel._chips["buff.footwork"]
	chip.grab_focus()
	await key(KEY_ENTER)
	check(panel._dialog.visible, "Keyboard Enter activates chip")
	await key(KEY_ESCAPE)
	check(chip.has_focus(), "Close restores originating chip focus")
	panel.advance_to(10001)
	check(root.gui_get_focus_owner() != null, "Expiring focused chip retains accessible focus")
	panel._open_inspector()
	panel.finish(fixture(10))
	check(not panel._dialog.visible and panel._chips.is_empty(), "Finish/skip closes inspector and chips")
	panel.begin(fixture(10))
	panel._open_inspector()
	panel.clear()
	check(not panel._dialog.visible and panel.active.is_empty(), "Reset closes inspector")
	# Exact consumption and held-until-impact state, including old deadline crossing.
	var held := CombatResolver.CombatResult.new()
	held.duration_ms = 1000
	held.trace.record("effect_lifecycle", 0, {"effect_instance_id":"f"}, {"effect_id":"footwork","after":{"units":3,"expires_at_ms":200}})
	held.trace.record("effect_lifecycle", 100, {"effect_instance_id":"f","cast_id":1}, {"effect_id":"footwork","consumed":3,"after":{}})
	held.trace.record("cast_resolved", 500, {"cast_id":1}, {})
	panel.begin(held)
	panel.advance_to(300)
	panel._open_inspector()
	check(panel.active.is_empty() and panel._details.text.contains("Spent"), "Held units inspectable after authoritative expiry")
	check(not panel._chips["buff.footwork"].get_node("Countdown").visible, "Held units have no misleading expiry clock")
	panel.advance_to(500)
	check(panel._chips.is_empty() and not panel._details.text.contains("Source:"), "Impact clears held inspector entry")
	# State-only activations must not show the resolver's zero charge field.
	var active = fixture(10)
	for event in active.trace.presentation_records:
		if event.payload.effect_id in ["dance","master_of_poisons"]: event.payload.after.units = 0
	panel.begin(active)
	check(panel._chips["buff.dance"].get_node("StackCount").text == "1", "Dance active count is one")
	panel.queue_free()
	await settle()
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_contract_test_pressed(1234, 45, "tree.assassin", "tree.shadow")
	var state = root.get_node("BuildState")
	for mode in ["test", "adventure", "practice"]:
		if mode == "practice": game._show_training_room()
		else:
			state.is_test_mode = mode == "test"
			game._show_combat_screen()
		await settle()
		var screen = game._current_screen
		if mode != "practice":
			if screen._story_overlay.visible:
				screen._story_overlay._on_proceed_pressed()
				await settle()
			screen._contract_overlay.hide()
			screen._map_overlay.hide()
			check(not screen._story_overlay.visible, "Adventure story proceeded before HUD captures")
		var icons = screen._combat_view._effect_icons if mode == "practice" else screen._effect_icons
		for width in [1280,1600,1920]:
			root.size = Vector2i(width,width * 9 / 16)
			for scale in [1.0,1.25]:
				for count in [5,10,12]:
					icons.begin(fixture(count))
					icons.advance_to(1500)
					icons._inspect.add_theme_font_size_override("font_size",roundi(22 * scale))
					icons._details.add_theme_font_size_override("normal_font_size",roundi(20 * scale))
					await settle()
					check(icons._inspect.size.x >= icons._inspect.get_minimum_size().x, "125% overflow text fits")
					check(icons._grid.size.x <= icons.size.x, "Chip row fits")
					var r: Rect2 = icons.get_global_rect()
					check(r.position.x >= 0 and r.end.x <= root.size.x and r.end.y <= root.size.y, "Effects within viewport")
					await shot("%s_%d_%d_hud_%d" % [mode,width,count,roundi(scale*100)])
					icons._open_inspector()
					await settle()
					check(icons._dialog.size.x <= width and icons._dialog.size.y <= root.size.y, "Inspector fits viewport")
					check(icons._details.text.count("Source:") == count, "Cross-mode independent instance count")
					rows.append({"mode":mode,"width":width,"instances":count,"groups":icons._groups().size(),"overflow":icons._inspect.text,"font_scale":scale,"inspector_entries":icons._details.text.count("Source:")})
					await shot("%s_%d_%d_inspector_%d" % [mode,width,count,roundi(scale*100)])
					if count == 12 and width == 1280 and scale == 1.25:
						icons._details.get_v_scroll_bar().value = icons._details.get_v_scroll_bar().max_value
						await shot(mode + "_1280_12_inspector_bottom_125")
					icons._dialog.hide()
		# Real resolver playback uses the existing Bladedancer fixture, not injected state.
		var core = load("res://tests/fixtures/p6/bladedancer_core/core.gd")
		var registry = core.registry()
		var resolved = BuildResolver.resolve_ranked_build(registry.classes["class.rogue"], core.build(registry), [load("res://data/gear/crude_dagger.tres")])
		var enemy := Monster.new()
		enemy.hp = 100000
		var result := CombatResolver.resolve(core.rotation(resolved.skills), resolved.stats, enemy, 20000, 7, true)
		if mode == "practice":
			screen._state.last_result = result
			screen._state.selected_target = enemy
			screen._combat_view._instant_playback = false
			screen._combat_view.play(result, enemy)
			screen._combat_view.set_process(false)
			screen._combat_view._playback_intro_remaining_sec = 0
			screen._combat_view._process(1.69)
		else:
			screen._playback_presenter.start(result,enemy,false,false,false)
			screen.set_process(false)
			screen._playback_presenter.advance(1.69)
		await shot(mode + "_real_resolver_playback")
		icons._open_inspector()
		if mode == "practice": screen._combat_view._skip()
		else: screen._playback_presenter.skip()
		check(not icons._dialog.visible and icons._chips.is_empty(), "Integrated playback skip closes inspector")
		icons.begin(fixture(10))
		# Actual parent ownership ensures mode exit destroys any open inspector.
		icons._open_inspector()
		var old_dialog: WeakRef = weakref(icons._dialog)
		game._on_main_menu_pressed()
		await settle()
		check(old_dialog.get_ref() == null, "Mode exit frees open inspector")
	var f := FileAccess.open(OUT + "/measurements.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(rows,"\t"))
	print("T6 temporary effects PASS: 54 cross-mode font cases, 108 captures when rendered; lifecycle boundaries")
	game.queue_free()
	await settle()
	quit()
