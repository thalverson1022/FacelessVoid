extends SceneTree
const Fixtures = preload("res://tests/t9_combat_feedback_test.gd")
const OUT := "res://reports/t9_combat_feedback_visual"
var snapshots: Array = []
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
func shot(name: String, view) -> void:
	await settle()
	root.get_texture().get_image().save_png(OUT + "/" + name + ".png")
	snapshots.append({"name": name, "damage": view._damage_dealt, "health_removed": view._health_removed, "shred": view._shred_stacks, "armor": view._monster.armor - view._armor_reduced, "effects": view._effect_icons.model.active, "clock": view._playback.elapsed_ms() if view._playback != null else -1})
func drive(view, seconds: float) -> void:
	for i in ceili(seconds * 60.0):
		await create_timer(1.0 / 60.0).timeout
		view._process(1.0 / 60.0)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._show_training_room()
	await settle()
	var screen = game._current_screen
	var view = screen._combat_view
	for kind in ["nightkiss", "empty", "poison"]:
		var f: Dictionary = Fixtures.fixture(kind)
		for gear in f.gear: screen._state.equip_legendary(gear)
		screen._state.last_result = f.result
		screen._state.selected_target = f.target
		view._instant_playback = false
		view.play(f.result, f.target, f.gear, f.stats.shred_value)
		view.set_process(false)
		view._playback_intro_remaining_sec = 0
		view._set_speed(1.0)
		if kind == "nightkiss":
			await drive(view, 0.31)
			await shot("nightkiss_before_consume", view)
			await drive(view, 0.81)
			await shot("nightkiss_repeated_removal", view)
		elif kind == "empty":
			await drive(view, 0.6)
			await shot("zero_shred_removal", view)
		else:
			await drive(view, 0.301)
			await shot("crown_live_dash", view)
			view._effect_icons._open_inspector()
			await shot("crown_effect_inspector", view)
			view._effect_icons._dialog.hide()
		view._skip()
		await settle()
	# The actual shared inspector, using the same resolved Nightkiss result.
	var f: Dictionary = Fixtures.fixture("nightkiss")
	var overlay := PanelContainer.new()
	overlay.z_index = 100
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_theme_stylebox_override("panel", CardStyle.make_stylebox())
	root.add_child(overlay)
	var scroll := ScrollContainer.new()
	overlay.add_child(scroll)
	var inspector := CombatLogInspector.new()
	inspector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(inspector)
	inspector.set_result(f.result, f.target, true)
	await shot("nightkiss_separate_chart", view)
	var file := FileAccess.open(OUT + "/snapshots.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(snapshots, "\t"))
	print("T9_COMBAT_VISUAL PASS snapshots=", snapshots.size())
	quit()
