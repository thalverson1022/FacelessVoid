extends SceneTree
const Core = preload("res://tests/fixtures/p6/bladedancer_core/core.gd")

func _initialize() -> void:
	call_deferred("_run")

func capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/p6_m4_t5_visual/" + label + ".png")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/p6_m4_t5_visual")
	PracticeSaveSystem.core_save_path = "res://reports/p6_m4_t5_visual/practice.json"
	if FileAccess.file_exists(PracticeSaveSystem.core_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PracticeSaveSystem.core_save_path))
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
	game._current_screen._talent_overlay.show_overlay()
	for size in [Vector2i(1280,720), Vector2i(1600,900), Vector2i(1920,1080)]:
		root.size = size
		await capture("talents-%d" % size.x)
	game._on_main_menu_pressed()
	await create_timer(0.3).timeout
	game._show_training_room()
	await create_timer(0.3).timeout
	game._current_screen._talent_overlay.visible = true
	for size in [Vector2i(1280,720), Vector2i(1600,900), Vector2i(1920,1080)]:
		root.size = size
		await capture("practice-talents-%d" % size.x)
	# Labelled UI-only stress fixture; never saved or added to playable content.
	var practice = game._current_screen
	practice._setup_autosave = false
	var p: TrainingRoomState = practice._state
	var synthetic: SubclassTree = p.selected_class.trees[0].duplicate(true)
	var source: Talent = synthetic.talents[0]
	synthetic.talents = []
	for i in 20:
		var talent: Talent = source.duplicate(true)
		talent.id = "layout.talent_%d" % i
		talent.display_name = "Synthetic long talent name %d" % i
		talent.required_tree_points = (i / 4) * 5
		if i >= 4:
			talent.prerequisite_ids = ["layout.talent_%d" % (i - 4)]
		synthetic.talents.append(talent)
	p.selected_class.trees = [synthetic]
	p.ranked_build.configure(synthetic, null, 45)
	p.selected_trees = [synthetic]
	practice._talent_panel._ranked_view.feedback = "SYNTHETIC layout fixture — not playable content."
	p.build_changed.emit()
	root.size = Vector2i(1280,720)
	await capture("synthetic-top-1280")
	practice._talent_overlay_scroll.scroll_vertical = 100000
	await capture("synthetic-bottom-1280")
	game.queue_free()
	await process_frame
	state.reset()
	quit()
