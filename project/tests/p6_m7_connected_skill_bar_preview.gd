extends SceneTree
const Accent = preload("res://scripts/ui/skill_category_icon_accent.gd")
var failed := false
func _initialize() -> void: call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		printerr("FAILED: " + message)
func accents(node: Node) -> Array:
	var result := []
	for child in node.get_children():
		if child.get_script() == Accent: result.append(child)
		result.append_array(accents(child))
	return result
func shot(name: String) -> void:
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://reports/icon_accents/" + name + ".png")
func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/charcoal_preview")
	var state = root.get_node("BuildState")
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._on_contract_test_pressed(1234,45,"tree.assassin","tree.shadow")
	await process_frame
	var screen = game._current_screen
	check(state.ranked_build.configure(state.selected_trees[0],state.selected_trees[1],45,{"talent.assassin.quick_hands":5,"talent.assassin.precision":5,"talent.assassin.hastened_poison":2,"talent.assassin.poison_strike":1}),"Legal representative unlocks")
	state._finish_rank_edit(true)
	state.rotation.assign(state.unlocked_skills().filter(func(skill): return preload("res://scripts/ui/skill_category_preview_style.gd").icon_selected(skill)))
	state.build_changed.emit()
	screen._contract_overlay.hide()
	screen._map_overlay.hide()
	await process_frame
	var selector = screen.find_child("CategoryIconStyle",true,false)
	check(selector != null, "Test-only comparison available")
	check(selector.selected == 1, "Available Skills defaults to bottom edge")
	check(int(state.get_meta("category_tree_icon_style",2)) == 2, "Tree defaults independently to filled box")
	check(accents(screen._skill_build_panel).size() == state.rotation.size(), "Every macro skill gets an accent")
	root.size = Vector2i(1600, 900)
	var panel = selector.get_parent().get_parent().get_parent()
	selector.hide()
	await capture(panel, "current-framed-art")
	for button in panel._skills_box.get_children():
		var icon = button.find_child("SkillIcon", true, false)
		var original_path: String = icon.texture.resource_path.replace("/assigned_flat/", "/assigned/")
		var original = load(original_path) as Texture2D
		check(original != null, "Original artwork available")
		var source := original.get_image()
		source.convert(Image.FORMAT_RGBA8)
		var tile := Image.create(40, 40, false, Image.FORMAT_RGBA8)
		tile.fill(Color("28282b"))
		tile.blend_rect(source, Rect2i(0, 0, 32, 32), Vector2i(4, 4))
		icon.texture = ImageTexture.create_from_image(tile)
	await capture(panel, "preserved-native-art")
	for button in panel._skills_box.get_children():
		var icon = button.find_child("SkillIcon", true, false)
		var margin = icon.get_parent().get_parent()
		margin.add_theme_constant_override("margin_left", 4)
		margin.add_theme_constant_override("margin_right", 4)
		margin.add_theme_constant_override("margin_top", 2)
		margin.add_theme_constant_override("margin_bottom", 6)
		button.custom_minimum_size = Vector2(48, 48)
	await process_frame
	await process_frame
	for button in panel._skills_box.get_children():
		var accent = button.get_node_or_null("CategoryIconAccent")
		if accent != null:
			accent.bottom_bar_height = 6.0
			accent.queue_redraw()
	await capture(panel, "compact-connected-bar")
	for button in panel._skills_box.get_children():
		check(button.size == Vector2(48, 48), "Compact button bounds")
		check(button.find_child("SkillIcon", true, false).size == Vector2(40, 40), "Native artwork frame remains unscaled")

	state.is_test_mode = false
	game._show_combat_screen()
	await process_frame
	var ordinary_panel = find_palette(game._current_screen)
	for button in ordinary_panel._skills_box.get_children():
		check(button.find_child("SkillIcon", true, false).material == null, "Adventure retains original icons")
		check(button.get_theme_stylebox("normal").bg_color != Color("28282b"), "Charcoal remains Test Mode only")
	print("Test Mode skill styling: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)

func find_palette(node: Node):
	if node.get_script() == load("res://scenes/combat/available_skills_panel.gd"):
		return node
	for child in node.get_children():
		var found = find_palette(child)
		if found != null: return found
	return null

func capture(panel: Control, variant: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot = root.get_texture().get_image()
	screenshot.save_png("res://reports/charcoal_preview/" + variant + "-context.png")
	var transform = panel.get_global_transform_with_canvas()
	var area = Rect2i(transform.origin - Vector2(8,8), panel.size * transform.get_scale() + Vector2(16,16))
	screenshot.get_region(area).save_png("res://reports/charcoal_preview/" + variant + "-bar.png")
