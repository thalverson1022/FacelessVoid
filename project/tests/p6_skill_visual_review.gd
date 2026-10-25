extends SceneTree
const Core = preload("res://tests/fixtures/p6/bladedancer_core/core.gd")

func _initialize() -> void:
	call_deferred("_run")

func capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/p6_m4_t6_visual/" + label + ".png")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/p6_m4_t6_visual")
	PracticeSaveSystem.core_save_path = "res://reports/p6_m4_t6_visual/practice.json"
	if FileAccess.file_exists(PracticeSaveSystem.core_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PracticeSaveSystem.core_save_path))
	SaveSystem.save_path = "res://reports/p6_m4_t6_visual/adventure.json"
	PracticeSaveSystem.save_path = "res://reports/p6_m4_t6_visual/legacy.json"
	var state = root.get_node("BuildState")
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await process_frame
	for size in [Vector2i(1280,720), Vector2i(1600,900), Vector2i(1920,1080)]:
		root.size = size
		await capture("title-%d" % size.x)
	game._on_contract_test_pressed(424242, 10)
	await create_timer(0.4).timeout
	for size in [Vector2i(1280,720), Vector2i(1600,900), Vector2i(1920,1080)]:
		root.size = size
		await capture("contracts-%d" % size.x)
	var registry := BuildContentRegistry.test_mode()
	for id in Core.RANKS:
		for rank in Core.RANKS[id]:
			state.select_talent(registry.talents[id])
	state.set_rotation(Core.rotation(state.unlocked_skills()))
	state.accept_contract_offer()
	state.choose_contract_route_node(state.current_route_node.next_nodes[0])
	game._current_screen._contract_overlay.hide()
	game._current_screen._map_overlay.hide()
	var macro = game._current_screen._skill_build_panel
	var all_skills: Array[Skill] = state.unlocked_skills()
	var full: Array[Skill] = []
	for i in 10:
		full.append(all_skills[i % all_skills.size()])
	state.set_rotation(full)
	macro._on_slot_pressed(5)
	for size in [Vector2i(1280,720), Vector2i(1600,900), Vector2i(1920,1080)]:
		root.size = size
		await capture("rotation-%d" % size.x)
		macro._inspect_selected()
		await capture("details-%d" % size.x)
		macro._details.hide()
	game._on_main_menu_pressed()
	await create_timer(0.3).timeout
	game._show_training_room()
	await create_timer(0.3).timeout
	var practice = game._current_screen
	for id in Core.RANKS:
		for rank in Core.RANKS[id]:
			practice._state.select_talent(registry.talents[id])
	practice._state.set_rotation(full)
	for size in [Vector2i(1280,720), Vector2i(1600,900), Vector2i(1920,1080)]:
		root.size = size
		await capture("practice-rotation-%d" % size.x)
		practice._skill_build_panel._on_slot_pressed(4)
		practice._skill_build_panel._inspect_selected()
		await capture("practice-details-%d" % size.x)
		practice._skill_build_panel._details.hide()
	root.size = Vector2i(1280,720)
	practice._skill_build_panel._inspect_selected()
	practice._skill_build_panel._details._text.add_theme_font_size_override("normal_font_size", 25)
	await capture("details-text-stress-1280")
	practice._skill_build_panel._details._text.scroll_to_line(1000)
	await capture("details-text-stress-bottom-1280")
	game.queue_free()
	await process_frame
	state.reset()
	quit()
