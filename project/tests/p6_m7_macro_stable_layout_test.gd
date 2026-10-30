extends SceneTree

var measurements: Array = []
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func settle() -> void:
	for i in 12:
		await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw

func bounds(control: Control) -> Dictionary:
	var rect := control.get_global_rect()
	var transform := control.get_global_transform_with_canvas()
	return {
		"rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
		"minimum": [control.get_combined_minimum_size().x, control.get_combined_minimum_size().y],
		"canvas_origin": [transform.origin.x, transform.origin.y],
		"canvas_scale": [transform.get_scale().x, transform.get_scale().y],
	}

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/macro_layout")
	var state = root.get_node("BuildState")
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_contract_test_pressed(1234, 45, "tree.assassin", "tree.shadow")
	await settle()
	if not state.ranked_build.configure(state.selected_trees[0], state.selected_trees[1], 45, {"talent.assassin.quick_hands":5,"talent.assassin.precision":5,"talent.assassin.hastened_poison":2,"talent.assassin.poison_strike":1}):
		failed = true
	state._finish_rank_edit(true)
	state.set_locked(false)
	var skill: Skill = state.unlocked_skills()[0]
	for mode in ["test", "adventure", "practice"]:
		if mode == "practice":
			game._show_training_room()
		else:
			state.is_test_mode = mode == "test"
			game._show_combat_screen()
		await settle()
		var screen = game._current_screen
		var mode_state = screen._state if mode == "practice" else state
		mode_state.set_locked(false)
		if mode != "practice":
			screen._contract_overlay.hide()
			screen._map_overlay.hide()
		for width in [1600, 1280, 1920]:
			root.size = Vector2i(width, width * 9 / 16)
			for variant in [mode]:
				var empty: Array[Skill] = []
				mode_state.set_rotation(empty)
				await settle()
				var panel = screen._skill_build_panel
				await settle()
				var reference := {}
				for count in [0, 1, 9, 10]:
					var rotation: Array[Skill] = []
					for i in count:
						rotation.append(skill)
					mode_state.set_rotation(rotation)
					await settle()
					if mode_state.rotation.size() != count:
						failed = true
					var center: Control = panel.get_parent()
					var columns: Control = center.get_parent()
					var row := {
						"width": width, "variant": variant, "count": count,
						"viewport": [root.get_visible_rect().size.x, root.get_visible_rect().size.y],
						"screen": bounds(screen), "panel": bounds(panel),
						"center": bounds(center), "columns": bounds(columns),
						"left": bounds(columns.get_child(0)), "right": bounds(columns.get_child(2)),
						"combat": bounds(screen._combat_view if mode == "practice" else screen._combat_window), "available": bounds(center.get_child(1)),
						"row": bounds(panel._macro_row), "grid": bounds(panel._slots_box),
						"lock_holder": bounds(panel._lock_holder), "lock_button": bounds(panel._lock_button),
						"title": bounds(panel._title_label), "counter": bounds(panel._slot_count_label),
					}
					if count > 0:
						row["first"] = bounds(panel._slot_buttons[0])
						row["last"] = bounds(panel._slot_buttons[-1])
						row["icon"] = bounds(panel._slot_buttons[0].get_node("SkillIcon"))
					if panel._slots_box.custom_minimum_size != Vector2(796,80):
						failed = true
						printerr("FAILED: Full macro grid space must be reserved in " + mode)
					for button in panel._slot_buttons:
						if button.size != Vector2(76,80) or button.get_node("SkillIcon").size != Vector2(72,72):
							failed = true
							printerr("FAILED: Slot or art was rescaled in " + mode)
						if button.get_global_rect().end.x > panel._lock_holder.global_position.x:
							failed = true
							printerr("FAILED: Macro slot overlaps lock in " + mode)
					if columns.get_global_rect().end.x > screen.size.x:
						failed = true
						printerr("FAILED: Screen columns overflow in " + mode)
					if count == 0:
						reference = row
					else:
						for key in ["panel", "center", "left", "right", "combat", "available", "row", "grid", "lock_button"]:
							if row[key]["rect"] != reference[key]["rect"]:
								failed = true
								printerr("FAILED: Layout moved for %s at %d skills / %d width" % [key, count, width])
					measurements.append(row)
					print("MEASUREMENT " + JSON.stringify(row))
					if DisplayServer.get_name() != "headless":
						root.get_texture().get_image().save_png("res://reports/macro_layout/%s_%d_%d.png" % [variant, width, count])
	var file := FileAccess.open("res://reports/macro_layout/measurements.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(measurements, "\t"))
	print("Macro stable layout: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
