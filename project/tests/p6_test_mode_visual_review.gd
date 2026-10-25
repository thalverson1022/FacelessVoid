extends SceneTree
const Core = preload("res://tests/fixtures/p6/bladedancer_core/core.gd")

func _initialize() -> void:
	call_deferred("_run")

func capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/p6_m4_t4_visual/" + label + ".png")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/p6_m4_t4_visual")
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
	for size in [Vector2i(1280,720), Vector2i(1600,900), Vector2i(1920,1080)]:
		root.size = size
		await capture("planning-%d" % size.x)
	game._current_screen.instant_playback = true
	state.set_locked(true)
	game._current_screen._on_fight_pressed()
	await create_timer(0.5).timeout
	await capture("combat-result")
	game.queue_free()
	await process_frame
	state.reset()
	quit()
