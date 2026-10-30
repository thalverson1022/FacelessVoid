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
	await capture(panel, "current")
	for button in panel._skills_box.get_children():
		var style = button.get_theme_stylebox("normal").duplicate()
		style.bg_color = Color("28282b")
		button.add_theme_stylebox_override("normal", style)
	await capture(panel, "charcoal")
	var sizes := []
	for button in panel._skills_box.get_children():
		sizes.append(button.size)
		var icon = button.find_child("SkillIcon", true, false)
		icon.custom_minimum_size = Vector2(48, 48)
		var margin = icon.get_parent().get_parent()
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_bottom", 4)
	await capture(panel, "charcoal-larger")
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec2 icon_size = vec2(48.0);
uniform float radius = 6.0;
void fragment() {
    vec4 artwork = COLOR;
    vec2 q = abs((UV - vec2(0.5)) * icon_size) - (icon_size * 0.5 - vec2(radius));
    float distance_to_edge = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
    float mask = 1.0 - smoothstep(-0.5, 0.5, distance_to_edge);
    float border = smoothstep(-2.0, -1.0, distance_to_edge);
    artwork.rgb = mix(artwork.rgb, vec3(0.368627, 0.364706, 0.380392), border);
    COLOR = vec4(artwork.rgb, artwork.a * mask);
}
"""
	for button in panel._skills_box.get_children():
		var icon = button.find_child("SkillIcon", true, false)
		var material := ShaderMaterial.new()
		material.shader = shader
		icon.material = material
	await capture(panel, "charcoal-larger-rounded")
	for i in panel._skills_box.get_child_count():
		check(panel._skills_box.get_child(i).size == sizes[i], "Button size preserved")
	print("Rounded icon preview: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)

func capture(panel: Control, variant: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot = root.get_texture().get_image()
	screenshot.save_png("res://reports/charcoal_preview/" + variant + "-context.png")
	var transform = panel.get_global_transform_with_canvas()
	var area = Rect2i(transform.origin - Vector2(8,8), panel.size * transform.get_scale() + Vector2(16,16))
	screenshot.get_region(area).save_png("res://reports/charcoal_preview/" + variant + "-bar.png")
