extends SceneTree
## One supplemental settled outcome view. This snapshot makes no timing claim.
var failed := false
var checks := 0
const OUT := "res://reports/m11_t4_playback_settled"
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error("FAILED: " + message)
func run() -> void:
	var distinct := {}
	for path in SevenSlotSaveBoundary.paths().values():
		if not String(path).begins_with("res://reports/"):
			quit(1)
			return
		distinct[path] = true
	if distinct.size() != 5 or DisplayServer.get_name() == "headless":
		quit(1)
		return
	root.content_scale_size = Vector2i(1600,900)
	root.size = Vector2i(1600,900)
	check(SevenSlotSaveBoundary.ensure_ready(), "owned epoch ready")
	var state = root.get_node("BuildState")
	state.reset()
	var registry := BuildContentRegistry.adventure()
	check(registry.error.is_empty(), "current registry valid")
	state.set_class(registry.classes["class.rogue"])
	check(state.configure_ranked_build(registry.trees["tree.bladedancer"]), "legal ranked primary")
	state.set_adventure_seed(180032)
	check(state.choose_current_tavern_encounter(), "legal current Tavern target")
	var rotation: Array[Skill] = [load("res://data/skills/stab.tres")]
	state.set_rotation(rotation)
	var screen = load("res://scenes/combat/combat_screen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	screen.instant_playback = false
	state.set_locked(true)
	var monster: Monster = screen._enemy_panel.monster()
	monster.hp = 100000
	screen._enemy_panel.fight_pressed.emit()
	check(screen._playback_active and not state.last_fight_won, "actual current ranked loss presenting")
	screen._playback_controls._skip_button.pressed.emit()
	var deadline := Time.get_ticks_usec()+6000000
	while Time.get_ticks_usec()<deadline:
		await process_frame
		if screen._victory_overlay.visible and screen._victory_stack.modulate.a>=0.999 and screen._victory_combat_dim.modulate.a>=0.999 and screen._victory_stack.scale.is_equal_approx(Vector2.ONE): break
	await RenderingServer.frame_post_draw
	check(screen._victory_overlay.is_visible_in_tree(), "settled overlay visible in tree")
	check(screen._victory_stack.modulate.a>=0.999 and screen._victory_combat_dim.modulate.a>=0.999 and screen._victory_stack.scale.is_equal_approx(Vector2.ONE), "authored reveal tweens settled at full alpha and scale")
	check(screen._victory_title_label.is_visible_in_tree() and screen._victory_title_label.text=="DEFEATED", "defeat heading visible")
	check(screen._outcome_retry_button.is_visible_in_tree(), "retry visible")
	check(screen._victory_recap_label.is_visible_in_tree() and screen._victory_recap_label.text.contains("Total Damage:"), "readable populated recap")
	check(screen._combat_stage.last_player_animation_frame_path.ends_with("/death/frames/frame_005.png"), "retained final death frame")
	check(not screen._view_log_button.disabled and not screen._map_button.disabled, "outcome controls available")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	check(root.get_texture().get_image().save_png(OUT+"/settled_defeat.png")==OK, "1600x900 settled view saved")
	SaveSystem.write_json(OUT+"/evidence.json", {"pass":not failed,"checks":checks,"scope":"Supplemental fully settled outcome screenshot; no timing claim","stack_alpha":screen._victory_stack.modulate.a,"dim_alpha":screen._victory_combat_dim.modulate.a,"stack_scale":str(screen._victory_stack.scale),"title":screen._victory_title_label.text,"retry_visible_in_tree":screen._outcome_retry_button.is_visible_in_tree(),"recap":screen._victory_recap_label.text,"death_frame":screen._combat_stage.last_player_animation_frame_path})
	screen.queue_free()
	await process_frame
	print("M11 T4 settled defeat capture: ", "FAILED" if failed else "PASS", " (", checks, " checks)")
	quit(1 if failed else 0)
