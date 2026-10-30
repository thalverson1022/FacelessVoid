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
	await verify_palette(screen)
	var chosen: Array[Skill] = state.rotation.duplicate()
	chosen.append(chosen[1])
	state.set_rotation(chosen)
	await process_frame
	var panel = screen._skill_build_panel
	for width in [1600,1280,1920]:
		root.size = Vector2i(width,width*9/16)
		await capture(panel,"test-macro-%d" % width)
		for button in panel._slot_buttons:
			check(button.get_node("SkillIcon").size == Vector2(72,72),"Test Mode preserves exact 2x artwork")
			check(button.get_global_rect().end.x <= panel._lock_holder.global_position.x,"Ten slots fit before lock")
	root.size = Vector2i(1600,900)
	panel.set_cast_progress(1,0.55)
	await capture(panel,"test-casting")
	panel.play_stun_effect(1000,false)
	await capture(panel,"test-stunned")
	panel.clear_stun_effect()
	game._show_training_room()
	await process_frame
	await process_frame
	var practice = game._current_screen
	practice._state.rotation = chosen
	practice._state.build_changed.emit()
	await process_frame
	await process_frame
	for button in practice._skill_build_panel._slot_buttons:
		check(button.custom_minimum_size == Vector2(76,80), "Practice uses approved slot size")
		check(button.get_node("SkillIcon").material.shader == preload("res://scripts/ui/rounded_skill_icon.gdshader"), "Practice uses rounded frame")
		check(button.get_theme_stylebox("normal").bg_color == Color("28282b"), "Practice uses charcoal fill")
	check(practice.find_child("CategoryIconStyle",true,false) == null, "Practice has no comparison selector")
	await verify_palette(practice)
	await capture(practice._skill_build_panel,"practice-promoted")
	state.is_test_mode = false
	game._show_combat_screen()
	await process_frame
	check(game._current_screen.find_child("CategoryIconStyle",true,false) == null, "Adventure has no comparison selector")
	await verify_palette(game._current_screen)
	for button in game._current_screen._skill_build_panel._slot_buttons:
		check(button.custom_minimum_size == Vector2(76,80), "Adventure uses approved slot size")
	print("Macro styling scope: " + ("FAIL" if failed else "PASS"))
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
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var screenshot = root.get_texture().get_image()
	screenshot.save_png("res://reports/charcoal_preview/" + variant + "-context.png")
	var transform = panel.get_global_transform_with_canvas()
	var area = Rect2i(transform.origin - Vector2(8,8), panel.size * transform.get_scale() + Vector2(16,16))
	screenshot.get_region(area).save_png("res://reports/charcoal_preview/" + variant + "-bar.png")

func verify_palette(screen: Node) -> void:
	var palette = find_palette(screen)
	check(palette != null, "Real screen has available skills")
	for button in palette._skills_box.get_children():
		var icon = button.find_child("SkillIcon", true, false)
		if icon == null: continue
		check(button.custom_minimum_size == Vector2(48,48), "Shared compact available button")
		check(icon.size == Vector2(40,40), "Shared forty pixel available frame")
		check(icon.material.shader == preload("res://scripts/ui/rounded_skill_icon.gdshader"), "Available frame remains rounded")
		var accent = button.get_node_or_null("CategoryIconAccent")
		if accent != null: check(accent.bottom_bar_height == 6.0, "Shared six pixel category bar")
