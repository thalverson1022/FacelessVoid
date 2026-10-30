extends SceneTree
const Checks = preload("res://tests/p6_m7_event_log_roots_test.gd")
const OUT := "res://reports/event_log_roots_visual"
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var helper := Checks.new()
	var data := helper.fixture()
	helper.free()
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_contract_test_pressed(1234,45,"tree.assassin","tree.shadow")
	for mode in ["adventure", "practice"]:
		if mode == "practice": game._show_training_room()
		else:
			root.get_node("BuildState").is_test_mode = false
			game._show_combat_screen()
		await settle()
		var screen = game._current_screen
		if mode == "adventure":
			if screen._story_overlay.visible: screen._story_overlay._on_proceed_pressed()
			screen._contract_overlay.hide()
			screen._map_overlay.hide()
		var overlay = screen._log_overlay
		overlay.set_result(data.result, data.target, CombatResultFormatter.format_practice(data.result, data.target) if mode == "practice" else CombatResultFormatter.format(data.result, data.target))
		overlay.show_log()
		overlay._tabs.current_tab = 1
		for width in [1600,1280]:
			root.content_scale_size = Vector2i(width, 900 if width == 1600 else 720)
			DisplayServer.window_set_size(root.content_scale_size)
			await settle()
			assert(overlay._log_label.text.contains("CAST Quick Cut"))
			assert(overlay._log_label.text.contains("    -> "))
			root.get_texture().get_image().save_png(OUT + "/%s_%d.png" % [mode,width])
			overlay._log_label.scroll_to_line(11)
			await settle()
			root.get_texture().get_image().save_png(OUT + "/%s_%d_nested.png" % [mode,width])
			overlay._log_label.scroll_to_line(0)
	print("Event log roots visual PASS")
	quit()
