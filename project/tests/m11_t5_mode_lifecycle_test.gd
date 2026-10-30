extends SceneTree
## Drives existing screen signals/handlers; production main scene remains unchanged.
var checks := 0
var failed := false
var mode := "adventure"
var game: Control
var observations: Array = []

func _initialize() -> void:
	print("ISOLATED_USER_DATA_DIR=", OS.get_user_data_dir())
	SaveSystem.save_path = "user://t5_adventure.json"
	PracticeSaveSystem.save_path = "user://t5_practice.json"
	PracticeSaveSystem.core_save_path = "user://t5_core.json"
	SevenSlotSaveBoundary.legacy_path = "user://t5_legacy.json"
	SevenSlotSaveBoundary.marker_path = "user://t5_epoch.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mode="): mode = arg.trim_prefix("--mode=")
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	observations.append({"check":message,"pass":value})
	if not value:
		failed = true
		push_error("FAILED: " + message)

func settle() -> void:
	await create_timer(0.7).timeout
	await process_frame

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.get_size() == Vector2i(1600, 900), "actual size " + label)
	check(image.save_png("user://" + label + ".png") == OK, "capture " + label)

func run() -> void:
	var state = root.get_node("BuildState")
	root.size = Vector2i(1600,900)
	root.content_scale_size = Vector2i(1600,900)
	var owned_paths := SevenSlotSaveBoundary.paths()
	var unique := {}
	for path in owned_paths.values(): unique[ProjectSettings.globalize_path(path)] = true
	check(owned_paths.size() == 5 and unique.size() == 5, "five distinct isolated gameplay paths")
	print("T5_SAVE_PATHS=", JSON.stringify(owned_paths))
	print("T5_ENV=", JSON.stringify({"renderer":RenderingServer.get_current_rendering_method(),"driver":RenderingServer.get_current_rendering_driver_name(),"display":DisplayServer.get_name(),"audio":AudioServer.get_driver_name(),"adapter":RenderingServer.get_video_adapter_name()}))
	game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await settle()
	check(game._current_screen.get_script().resource_path.ends_with("title.gd"), "normal title loaded")
	await capture("title")
	match mode:
		"adventure":
			game._current_screen.adventure_pressed.emit()
			await settle()
			check(game._current_screen.get_script().resource_path.ends_with("class_select.gd"), "Adventure class entry")
			game._current_screen._on_class_selected(BuildContentRegistry.adventure().classes["class.rogue"])
			await settle()
			check(game._current_screen.get_script().resource_path.ends_with("subclass_select.gd"), "Adventure subclass entry")
			game._current_screen._on_tree_selected(state.selected_class.trees[0])
			await settle()
			check(not state.is_test_mode and not SaveSystem.session_only, "Adventure persisted mode")
			check(FileAccess.file_exists(SaveSystem.save_path), "Adventure normal autosave exists")
		"test":
			game._on_contract_test_pressed(110530, 10, "tree.bladedancer", "")
			await settle()
			check(state.is_test_mode and SaveSystem.session_only, "Test memory only mode")
			check(not FileAccess.file_exists(SaveSystem.save_path), "Test creates no Adventure save")
		"practice":
			game._current_screen.training_room_pressed.emit()
			await settle()
			check(game._current_screen.get_script().resource_path.ends_with("training_room.gd"), "Practice normal entry")
			check(not FileAccess.file_exists(SaveSystem.save_path), "Practice creates no Adventure save")
	check(game._current_screen != null and game._current_screen.is_inside_tree(), "mode screen alive")
	await capture(mode)
	if mode == "practice": game._current_screen.back_pressed.emit()
	else:
		check(game._current_screen.get_script().resource_path.ends_with("combat_screen.gd"), "combat screen entry")
		game._current_screen.save_and_quit_pressed.emit()
	await settle()
	check(game._current_screen.get_script().resource_path.ends_with("title.gd"), "normal return to title")
	await capture("returned_title")
	var f := FileAccess.open("user://witness.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"mode":mode,"checks":checks,"failed":failed,"observations":observations},"\t"))
	f.close()
	print("T5_COMPLETE mode=", mode, " checks=", checks, " failed=", failed)
	# Match normal SceneTree shutdown: no manual node/resource cleanup.
	quit(1 if failed else 0)
