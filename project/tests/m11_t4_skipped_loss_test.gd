extends SceneTree
## Rendered wall-cadence observer. Never manually advances combat or death animation.
## Images are sampled into memory only for repeat1, then encoded after each case.
var failed := false
var checks := 0
var rows: Array = []
var images: Array = []
var observed_screen: Node
var observed_started := 0
var samples: Array = []
var distinct: Array[String] = []
var pose_usec := -1
var last_frame_usec := -1
var overlay_usec := -1
var previous_frame := ""
var case_id := ""
var capture_images := false
var diagnostic := false
var native := false
var native_intro := false
var native_inputs: Array = []
var native_active_exported := false
func rect_data(rect: Rect2) -> Dictionary:
	return {"x":rect.position.x,"y":rect.position.y,"width":rect.size.x,"height":rect.size.y}
func vector_data(value: Vector2i) -> Dictionary: return {"x":value.x,"y":value.y}
func export_native_state(screen, phase: String, with_image: bool = false) -> void:
	var fight = screen._enemy_panel._fight_button
	var skip = screen._playback_controls._skip_button
	var native_handle := -1
	if DisplayServer.has_method("window_get_native_handle") and ClassDB.class_get_integer_constant_list("DisplayServer").has("WINDOW_HANDLE"):
		native_handle = DisplayServer.call("window_get_native_handle", ClassDB.class_get_integer_constant("DisplayServer", "WINDOW_HANDLE"), root.get_window_id())
	var data := {"native_handle":native_handle,"viewport_size":vector_data(Vector2i(root.get_visible_rect().size)),"root_size":vector_data(root.size),"intro_remaining_sec":screen._playback_presenter._intro_remaining_sec,"events_fired":screen._playback_presenter._playback.events_fired() if screen._playback_presenter._playback != null else -1,"screen_process_enabled":screen.is_processing(),"phase":phase,"us":Time.get_ticks_usec(),"pid":OS.get_process_id(),"window_id":root.get_window_id(),"title":root.title,"root_position":vector_data(root.position),"client_position":vector_data(DisplayServer.window_get_position()),"decorated_position":vector_data(DisplayServer.window_get_position_with_decorations()),"client_size":vector_data(DisplayServer.window_get_size()),"decorated_size":vector_data(DisplayServer.window_get_size_with_decorations()),"content_scale_size":vector_data(root.content_scale_size),"fight":{"client_rect":rect_data(fight.get_global_rect()),"visible":fight.is_visible_in_tree(),"disabled":fight.disabled},"skip":{"client_rect":rect_data(skip.get_global_rect()),"visible":skip.is_visible_in_tree(),"disabled":skip.disabled}}
	SaveSystem.write_json(OUT+"/native_state_"+phase+".json", data)
	if with_image:
		root.get_texture().get_image().save_png(OUT+"/native_ready.png")
	print("NATIVE_STATE ", phase, " ", JSON.stringify(data))
func record_native_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		native_inputs.append({"us":Time.get_ticks_usec()-observed_started,"pressed":event.pressed,"button":event.button_index,"position":str(event.position)})
func record_rendered_frame() -> void:
	if not is_instance_valid(observed_screen) or overlay_usec > 0: return
	var now := Time.get_ticks_usec()
	if native and observed_screen._playback_active and not native_active_exported:
		native_active_exported = true
		export_native_state(observed_screen, "playing")
	var stage = observed_screen._combat_stage
	var frame: String = stage.last_player_animation_frame_path
	var defeat: bool = stage.outcome_pose == "defeat"
	var overlay: bool = observed_screen._victory_overlay.visible
	if defeat and pose_usec < 0: pose_usec = now
	if defeat and not distinct.has(frame):
		distinct.append(frame)
		if frame.ends_with("frame_005.png"): last_frame_usec = now
	samples.append({"us":now-observed_started,"frame":frame,"pose":stage.outcome_pose,"overlay":overlay,"retry":observed_screen._outcome_retry_button.visible,"retry_in_tree":observed_screen._outcome_retry_button.is_visible_in_tree(),"view_log_disabled":observed_screen._view_log_button.disabled,"map_disabled":observed_screen._map_button.disabled,"playback_active":observed_screen._playback_active,"stage_process_delta":stage.get_process_delta_time()})
	if capture_images and defeat and (frame != previous_frame or overlay):
		images.append({"path":OUT+"/"+case_id+"_"+("overlay" if overlay else frame.get_file().get_basename())+".png", "image":root.get_texture().get_image()})
	previous_frame = frame
	if overlay: overlay_usec = now

const OUT := "res://reports/m11_t4_skipped_loss"
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error("FAILED: " + message)
func run() -> void:
	var distinct_paths := {}
	for path in SevenSlotSaveBoundary.paths().values():
		if not String(path).begins_with("res://reports/"):
			push_error("FAILED: refusing nonisolated path")
			quit(1)
			return
		distinct_paths[path] = true
	if distinct_paths.size() != 5 or DisplayServer.get_name() == "headless":
		push_error("FAILED: five isolated paths and rendered display required")
		quit(1)
		return
	native = OS.get_cmdline_user_args().has("--native")
	native_intro = OS.get_cmdline_user_args().has("--native-intro")
	if native: root.title = "FacelessVoid M11 T4 Native Probe"
	root.content_scale_size = Vector2i(1600, 900)
	root.size = Vector2i(1600, 900)
	if native:
		root.mode = Window.MODE_WINDOWED
		root.position = Vector2i(60, 60)
		root.show()
		DisplayServer.window_move_to_foreground()
		print("NATIVE_WINDOW visible=", root.visible, " title=", root.title, " display=", DisplayServer.get_name())
	check(SevenSlotSaveBoundary.ensure_ready(), "isolated boundary ready")
	diagnostic = OS.get_cmdline_user_args().has("--diagnostic")
	native = OS.get_cmdline_user_args().has("--native")
	if native:
		root.title = "FacelessVoid M11 T4 Native Probe"
		if root.has_signal("window_input"): root.connect("window_input", record_native_input)
	RenderingServer.frame_post_draw.connect(record_rendered_frame)
	for speed in ([1.0] if native else [1.0, 4.0]):
		for mode in (["native_intro" if native_intro else "native"] if native else (["skip", "intro_skip", "postdraw_skip"] if diagnostic else ["natural", "skip", "intro_skip"])):
			for repeat in range(1, 2 if diagnostic or native else 4):
				await observe_case(speed, mode, repeat)
	SaveSystem.write_json(OUT + "/observations.json", {"checks":checks,"pass":not failed,"cases":rows,"timing_basis":"Persistent frame_post_draw observer beforeactions; final contract: exact consecutive5 deathframes, finalposehold>=.95s (frame tolerance for existing1s), deferredUI, singlecompletion, unchanged accounting. Totalwall/firstframe dwell are measurements; exploratory1.45s gate retired after adopted-contract review. Handler phase and native-input phases are labeled separately."})
	print("M11 T4 skipped-loss rendered matrix: ", "FAILED" if failed else "PASS", " (", checks, " checks; ", rows.size(), " cases)")
	quit(1 if failed else 0)
func observe_case(speed: float, mode: String, repeat: int) -> void:
	var state = root.get_node("BuildState")
	state.reset()
	var registry := BuildContentRegistry.adventure()
	check(registry.error.is_empty(), "current registry")
	state.set_class(registry.classes["class.rogue"])
	check(state.configure_ranked_build(registry.trees["tree.bladedancer"]), "ranked primary")
	state.set_adventure_seed(180032)
	check(state.choose_current_tavern_encounter(), "legal Tavern target")
	var rotation: Array[Skill] = [load("res://data/skills/stab.tres")]
	state.set_rotation(rotation)
	var screen = load("res://scenes/combat/combat_screen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	screen.instant_playback = false
	screen._last_playback_speed = speed
	state.set_locked(true)
	var monster: Monster = screen._enemy_panel.monster()
	monster.hp = 100000
	check(SaveSystem.delete_save(), "owned save cleared")
	var completion := [0]
	var native_clocks := {"fight_button_down":-1,"fight_handler_return":-1,"skip_button_down":-1,"skip_handler_return":-1}
	if native:
		screen._enemy_panel._fight_button.button_down.connect(func(): native_clocks.fight_button_down = Time.get_ticks_usec())
		screen._enemy_panel.fight_pressed.connect(func(): native_clocks.fight_handler_return = Time.get_ticks_usec())
		screen._playback_controls._skip_button.button_down.connect(func(): native_clocks.skip_button_down = Time.get_ticks_usec())
		screen._playback_controls._skip_button.pressed.connect(func(): native_clocks.skip_handler_return = Time.get_ticks_usec())
	var was_skipped := [false]
	var finish_usec := [-1]
	screen._playback_presenter.finished.connect(func(_r, _m, _s):
		completion[0] += 1
		was_skipped[0] = _s
		finish_usec[0] = Time.get_ticks_usec())
	var seed: int = state.current_combat_rng_seed()
	var started := Time.get_ticks_usec()
	observed_screen = screen
	observed_started = started
	samples = []
	distinct = []
	pose_usec = -1
	last_frame_usec = -1
	overlay_usec = -1
	previous_frame = ""
	case_id = "%s_%dx_repeat%d" % [mode, int(speed), repeat]
	capture_images = repeat == 1
	if native_intro:
		# Diagnostic setup only: pause the presenter before its first event so
		# external native-input latency cannot reduce the remaining flush.
		screen._enemy_panel.fight_pressed.emit()
		screen.set_process(false)
		check(screen._playback_presenter._intro_remaining_sec > 0 and screen._playback_presenter._playback.events_fired() == 0, "paused intro starts before any event")
		await RenderingServer.frame_post_draw
		export_native_state(screen, "ready", true)
		print("NATIVE_READY actual Skip only requested; presenter paused in original intro with0events andfull12s remaining")
	elif native:
		await RenderingServer.frame_post_draw
		export_native_state(screen, "ready", true)
		print("NATIVE_READY actual Fight then Skip requested at1600x900; observer attached beforeinput")
		var fight_deadline := Time.get_ticks_usec() + 240000000
		while not screen._playback_active and Time.get_ticks_usec() < fight_deadline: await process_frame
		if not screen._playback_active:
			check(false, "native Fight timeout")
			observed_screen = null
			screen.queue_free()
			return
		print("NATIVE_FIGHT_ACTIVE actual button input received")
	else:
		screen._enemy_panel.fight_pressed.emit()
	check(screen._playback_active and not screen._victory_overlay.visible, "live playback defers overlay")
	check(not state.last_fight_won and state.run_phase != state.RunPhase.FIGHTING, "authoritative controlled loss applied immediately")
	check(SaveSystem.has_save() and SaveSystem.last_error.is_empty(), "current ranked Fight autosaved")
	var saved := FileAccess.get_file_as_string(SaveSystem.save_path)
	var history_count: int = state.run_encounter_history.size()
	var gold: int = state.gold
	var result = screen._playback_presenter._result
	check(result.is_valid and not result.is_win, "valid resolver loss")
	var timeline: int = screen._playback_presenter._playback.timeline_end_ms()
	check(timeline == screen._enemy_panel.duration_ms(), "loss retains full authored window")
	var skip_started := -1
	var skip_finished := -1
	if mode == "intro_skip":
		check(screen._playback_presenter._intro_remaining_sec > 0 and screen._playback_presenter._playback.events_fired() == 0, "intro skip precedes first event")
		skip_started = Time.get_ticks_usec()
		screen._playback_controls._skip_button.pressed.emit()
		skip_finished = Time.get_ticks_usec()
	var skipped := mode == "intro_skip"
	var deadline := Time.get_ticks_usec() + (240000000 if native_intro else int((float(timeline) / 1000.0 / speed + 8.0) * 1000000.0))
	while overlay_usec < 0 and Time.get_ticks_usec() < deadline:
		await process_frame
		if mode == "postdraw_skip": await RenderingServer.frame_post_draw
		if mode in ["skip", "postdraw_skip"] and not skipped and screen._playback_presenter._playback != null and screen._playback_presenter._playback.events_fired() > 0:
			check(screen._playback_presenter._intro_remaining_sec <= 0, "normal skip follows intro and actual event")
			skip_started = Time.get_ticks_usec()
			screen._playback_controls._skip_button.pressed.emit()
			skip_finished = Time.get_ticks_usec()
			skipped = true
	check(overlay_usec > 0, case_id + " bounded outcome reveal")
	check(completion[0] == 1, case_id + " single presenter completion")
	if native: check(was_skipped[0], "actual native Skip input completed playback")
	var expected: Array[String] = []
	for index in range(1, 6): expected.append("res://assets/placeholder_combat_sprites/rogue_bandit/animations/death/frames/frame_%03d.png" % index)
	var consecutive: Array[String] = []
	for sample in samples:
		if sample.pose == "defeat" and (consecutive.is_empty() or consecutive[-1] != sample.frame): consecutive.append(sample.frame)
	check(consecutive == expected, case_id + " rendered exact consecutive five death frames in order")
	# Total wall duration is measured, not gated: the exploratory1.45s
	# threshold had no adopted contract basis. Ordered frames, final pose hold,
	# deferred UI and authoritative accounting remain required.
	check(finish_usec[0] > 0, case_id + " completion timestamp observed")
	var early_ui := samples.any(func(sample): return (sample.playback_active or sample.pose == "defeat") and not sample.overlay and (sample.retry_in_tree or not sample.view_log_disabled or not sample.map_disabled))
	check(not early_ui, case_id + " retry and outcome controls remain deferred through pose hold")
	check(last_frame_usec > 0 and overlay_usec-last_frame_usec >= 950000, case_id + " final death frame readable through pose hold")
	check(screen._victory_title_label.text == "DEFEATED" and screen._outcome_retry_button.visible and screen._victory_recap_label.text.contains("Total Damage:"), case_id + " defeat retry recap revealed")
	check(not screen._view_log_button.disabled and not screen._map_button.disabled, case_id + " controls unlock after reveal")
	check(state.run_encounter_history.size() == history_count and state.gold == gold and FileAccess.get_file_as_string(SaveSystem.save_path) == saved, case_id + " presentation leaves authoritative accounting/save unchanged")
	screen._skip_playback()
	await process_frame
	check(completion[0] == 1, case_id + " redundant skip does not refinish")
	var transitions: Array = []
	for sample in samples:
		if sample.pose == "defeat" and (transitions.is_empty() or transitions[-1].frame != sample.frame): transitions.append({"frame":sample.frame,"us":sample.us})
	var first_frame_dwell_us: int = transitions[1].us-transitions[0].us if transitions.size()>1 else -1
	rows.append({"first_frame_dwell_us":first_frame_dwell_us,"death_transitions":transitions,"finish_to_overlay_us":overlay_usec-finish_usec[0],"firstpaint_to_overlay_us":overlay_usec-pose_usec,"final_frame_hold_us":overlay_usec-last_frame_usec,"nominal_defeat_delay_sec":maxf(screen.PLAYBACK_OUTCOME_REVEAL_DELAY_SEC,screen._combat_stage.player_defeat_animation_duration_sec()+screen.PLAYER_DEFEAT_POSE_HOLD_SEC),"id":case_id,"speed":speed,"mode":mode,"repeat":repeat,"effective_seed":seed,"timeline_ms":timeline,"pose_us":pose_usec-started,"finish_signal_us":finish_usec[0]-started,"skip_started_us":skip_started-started if skip_started>0 else -1,"skip_finished_us":skip_finished-started if skip_finished>0 else -1,"overlay_us":overlay_usec-started,"final_frame_us":last_frame_usec-started,"death_frames":distinct,"consecutive_death_frames":consecutive,"native_inputs":native_inputs,"native_clocks_absolute_us":native_clocks,"was_skipped":was_skipped[0],"native_intro_paused_before_input":native_intro,"completion_count":completion[0],"history_count":history_count,"samples":samples})
	observed_screen = null
	for item in images:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(item.path.get_base_dir()))
		item.image.save_png(item.path)
	images.clear()
	print("OBSERVED ", case_id, " frames=", distinct.size(), " pose_to_overlay_us=", overlay_usec-pose_usec, " last_to_overlay_us=", overlay_usec-last_frame_usec)
	screen.queue_free()
	await process_frame
