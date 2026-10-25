extends SceneTree
var failed := false
func _initialize() -> void: call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		printerr("FAILED: " + message)
func check_row(row: Container) -> void:
	var chips := {}
	for child in row.find_children("*", "HBoxContainer", true, false):
		var icon = child.get_node_or_null("Icon")
		if icon != null: chips[icon.texture] = child
	for pair in [["status.shred","status.penetration"],["status.decay","status.potency"]]:
		if not chips.has(GameIcons.icon_for(pair[0])) or not chips.has(GameIcons.icon_for(pair[1])):
			check(false, "Expected both paired counters")
			continue
		var top = chips[GameIcons.icon_for(pair[0])]
		var bottom = chips[GameIcons.icon_for(pair[1])]
		check(absf(top.global_position.x - bottom.global_position.x) < 1, "Aligned icon columns")
		check(bottom.global_position.y >= top.get_global_rect().end.y, "Lower counter is below upper without overlap")
		check(bottom.get_node("Text").text == "x0", "Inactive count remains visible")
func capture(row: Container, mode: String) -> void:
	for resolution in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
		root.size = resolution
		await process_frame
		await process_frame
		check_row(row)
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://reports/status_columns/%s-%d.png" % [mode,resolution.x])
func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/status_columns")
	var state = root.get_node("BuildState")
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._on_contract_test_pressed(1234,45,"tree.assassin","tree.thief")
	await process_frame
	state.accept_contract_offer()
	var screen = game._current_screen
	screen._contract_overlay.hide()
	screen._map_overlay.hide()
	seed_hud(screen)
	await capture(screen._hud_status_row,"test")
	state.is_test_mode = false
	game._show_combat_screen()
	await process_frame
	screen = game._current_screen
	screen._contract_overlay.hide()
	screen._map_overlay.hide()
	seed_hud(screen)
	await capture(screen._hud_status_row,"adventure")
	game.queue_free()
	await process_frame
	var practice := TrainingRoomCombatView.new()
	root.add_child(practice)
	practice.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	await capture(practice._status_row,"practice")
	practice.queue_free()
	await process_frame
	state.reset()
	print("Status column placement: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)

func seed_hud(screen) -> void:
	screen._set_enemy_hud_display("Status layout fixture",100.0,100,0,0.0)
	screen._enemy_hud.show()
	screen._clear_hud_status_chips()
	CombatStatusIcons.add_timed_defense_chips(null, screen._add_hud_status_chip)
	for id in ["status.poison", "status.shred", "status.decay"]:
		screen._add_hud_status_chip("x0", Color.WHITE, GameIcons.icon_for(id))
