extends "res://tests/m9_log_tabs_test.gd"
const DIM_OUT := "res://reports/m9_t11_backdrop/"

func inspect_modal(screen: Control, modal: Control, state, mode: String) -> void:
	modal.show()
	await settle()
	var backdrop := modal.get_child(0) as Button
	verify(backdrop.focus_mode == Control.FOCUS_NONE,"backdrop excluded from keyboard focus")
	verify(backdrop.get_theme_stylebox("focus") is StyleBoxEmpty,"focus cannot paint second black layer")
	var before: Image
	if OS.get_cmdline_user_args().has("--visual"):
		await RenderingServer.frame_post_draw
		before = root.get_texture().get_image()
		before.save_png(DIM_OUT+mode+"_opened.png")
	var changed := false
	var view = screen._talent_panel._ranked_view if state is TrainingRoomState else modal._talent_panel._ranked_view
	for talent in state.ranked_build.primary_tree().talents:
		var button: Button = view.actions.get("buy:"+talent.id)
		if button == null or button.disabled: continue
		var old_rank: int = state.ranked_build.rank_of(talent.id)
		button.grab_focus()
		button.pressed.emit()
		changed = state.ranked_build.rank_of(talent.id) == old_rank+1
		break
	verify(changed,"real legal talent purchase")
	await settle()
	if before != null:
		await RenderingServer.frame_post_draw
		var after := root.get_texture().get_image()
		after.save_png(DIM_OUT+mode+"_allocated.png")
		# Left play-area gutter has no stat text or focus outline.
		var point := Vector2i(8,int(modal.get_global_rect().position.y)+100)
		verify(before.get_pixelv(point) == after.get_pixelv(point),"dimming unchanged after allocation")
		verify(before.get_pixel(8,8)==after.get_pixel(8,8),"upper bar unchanged")
	var navigation := modal.get_node("TalentKeyboardNavigation")
	verify(not navigation.controls().has(backdrop),"Tab navigation skips backdrop")
	modal.hide()
	await settle()
	modal.show()
	await settle()
	verify(root.gui_get_focus_owner()!=backdrop,"reopen does not focus backdrop")
	backdrop.pressed.emit()
	verify(not modal.visible,"outside-click dismissal retained")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(DIM_OUT)
	root.size = Vector2i(1600,900)
	root.content_scale_size = Vector2i(1600,900)
	root.theme = load("res://assets/ui_theme.tres")
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_new_game_pressed(1928)
	var state = root.get_node("BuildState")
	state.set_class(load("res://data/classes/rogue.tres"))
	var registry := BuildContentRegistry.adventure()
	assert(state.configure_ranked_build(registry.trees["tree.bladedancer"]))
	state.add_talent_points(3)
	game._show_combat_screen()
	await settle()
	var screen = game._current_screen
	for field in ["_contract_overlay","_map_overlay","_story_overlay","_secondary_subclass_overlay"]:
		screen.get(field).hide()
	await inspect_modal(screen,screen._talent_overlay,state,"adventure")
	game.queue_free()
	await settle()
	var room = load("res://scenes/training_room/training_room.tscn").instantiate()
	root.add_child(room)
	await settle()
	await inspect_modal(room,room._talent_overlay,room._state,"practice")
	room.queue_free()
	await settle()
	print("PASS backdrop stability: ",checks)
	quit()
