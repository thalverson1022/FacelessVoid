extends "res://tests/m9_log_tabs_test.gd"
const FIT_OUT := "res://reports/practice_talent_fit/"
func run() -> void:
	DirAccess.make_dir_recursive_absolute(FIT_OUT)
	root.size = Vector2i(1600,900)
	root.content_scale_size = Vector2i(1600,900)
	root.theme = load("res://assets/ui_theme.tres")
	var room = load("res://scenes/training_room/training_room.tscn").instantiate()
	root.add_child(room)
	await settle()
	var state = room._state
	var trees: Array = state.selected_class.trees
	for i in trees.size():
		assert(state.set_primary_tree(null))
		assert(state.set_primary_tree(trees[i]))
		assert(state.set_secondary_tree(trees[(i+1)%trees.size()]))
		room._show_talent_overlay()
		await settle()
		var scroll: ScrollContainer = room._talent_overlay_scroll
		var bar := scroll.get_v_scroll_bar()
		print("FIT ",trees[i].display_name," content=",room._talent_panel.get_combined_minimum_size()," scroll=",scroll.size," range=",bar.max_value-bar.page)
		verify(bar.max_value-bar.page <= 1.0,"full Practice tree fits without scrolling at1600x900")
		var panel: Control = room._talent_overlay_content.get_parent()
		verify(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(panel.get_global_rect()),"talent panel within viewport")
		verify(panel.get_global_rect().position.y>=room.find_child("TopActionBar",true,false).get_global_rect().end.y,"system bar clear")
		if OS.get_cmdline_user_args().has("--visual"):
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(FIT_OUT+trees[i].id+".png")
	# Small windows retain scrolling instead of covering system controls.
	root.size=Vector2i(1280,720)
	root.content_scale_size=Vector2i(1280,720)
	await settle()
	var panel: Control = room._talent_overlay_content.get_parent()
	verify(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(panel.get_global_rect()),"small viewport remains bounded")
	verify(panel.get_global_rect().position.y>=room.find_child("TopActionBar",true,false).get_global_rect().end.y,"small viewport system bar clear")
	room.queue_free()
	await settle()
	print("PASS Practice talent fit: ",checks)
	quit()
