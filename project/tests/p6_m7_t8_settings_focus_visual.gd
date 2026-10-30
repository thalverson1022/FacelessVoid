extends SceneTree
func _initialize() -> void:call_deferred("run")
func settle() -> void:
	for i in 6:await process_frame
	await RenderingServer.frame_post_draw
func key(code: Key) -> void:
	var e:=InputEventKey.new()
	e.keycode=code
	e.pressed=true
	root.push_input(e,true)
	await process_frame
	e=InputEventKey.new()
	e.keycode=code
	root.push_input(e,true)
	await settle()
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/settings_focus")
	var game=load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	var layer=game._settings_menu_layer
	var button:Button=layer.get_node("SettingsButton")
	for step in 40:
		if button.has_focus():break
		await key(KEY_TAB)
	assert(button.has_focus(),"Actual Tab reaches Settings gear")
	root.get_texture().get_image().save_png("res://reports/settings_focus/gear_tab_focus.png")
	var normal:StyleBoxFlat=button.get_theme_stylebox("normal")
	var focus:StyleBoxFlat=button.get_theme_stylebox("focus")
	var disabled:Button=layer._overlay.find_child("GameplayButton",true,false)
	var colors={"normal_border":normal.border_color.to_html(),"focus_border":focus.border_color.to_html(),"focus_fill":focus.bg_color.to_html(),"focus_expand":focus.expand_margin_left,"logical_rect":str(button.get_global_rect()),"logical_viewport":str(root.get_visible_rect()),"physical":str(root.size),"disabled_font_color":disabled.get_theme_color("font_disabled_color").to_html(),"disabled_font_pixels":disabled.get_theme_font_size("font_size"),"user_data_dir":OS.get_user_data_dir()}
	await key(KEY_ENTER)
	assert(layer._overlay.visible,"Enter opens settings")
	await key(KEY_ESCAPE)
	assert(not layer._overlay.visible and button.has_focus(),"Escape restores visible gear focus")
	root.get_texture().get_image().save_png("res://reports/settings_focus/gear_restored_focus.png")
	SaveSystem.write_json("res://reports/settings_focus/measurements.json",colors)
	game.queue_free()
	await settle()
	print("T8 settings focus PASS")
	quit()
