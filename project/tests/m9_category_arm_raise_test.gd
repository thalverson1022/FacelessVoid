extends SceneTree
const OUT := "res://reports/category_arm_raise"
const Category = preload("res://scripts/ui/skill_category_preview_style.gd")
var failed := false
var rows: Array = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		printerr("FAILED: " + message)
func settle() -> void:
	for i in 4: await process_frame
func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"/"+name+".png")
func path(stage) -> String: return stage.last_player_animation_frame_path.get_file()
func count_audio() -> int:
	var audio = root.get_node("AudioManager")
	var count: int = audio.category_sfx_play_count + audio.exsanguinate_sfx_play_count + audio.gold_steal_sfx_play_count
	for amount in audio.skill_sfx_play_counts.values(): count += int(amount)
	return count
func drive(view, practice: bool, delta: float) -> void:
	if practice: view._process(delta)
	else: view.advance(delta)
func begin(screen, view, practice: bool, result, enemy, speed: float) -> void:
	if practice:
		view._instant_playback = false
		view.play(result,enemy)
		view.set_process(false)
		view._playback_intro_remaining_sec = 0
		view._set_speed(speed)
	else:
		screen._skip_playback_on_fight = false
		screen._begin_playback(result,enemy)
		screen.set_process(false)
		view._intro_remaining_sec = 0
		view.set_speed(speed)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_contract_test_pressed(7,45,"tree.assassin","tree.shadow")
	await settle()
	var screen = game._current_screen
	if screen._story_overlay.visible: screen._story_overlay._on_proceed_pressed()
	screen._contract_overlay.hide()
	screen._map_overlay.hide()
	var room := TrainingRoomCombatView.new()
	root.add_child(room)
	room.size = root.get_visible_rect().size
	room.hide()
	await settle()
	var stats := PlayerStats.new()
	stats.assassin_tree_points = 10
	stats.gold_reward_multiplier = 2.0
	var enemy := Monster.new()
	enemy.display_name = "Mouthy Drunk"
	enemy.hp = 100000
	var status = preload("res://scripts/systems/p6_status_skill_contracts.gd")
	var thief = preload("res://scripts/systems/p6_thief_contracts.gd")
	var skills: Array[Skill] = []
	for kind in ["master_of_poisons","virulent_poison","beguiling_presence","poison_vile","touch_of_darkness"]: skills.append(status.skill(kind))
	skills.append(thief.skill("dance_of_death"))
	skills.append(thief.skill("pick_pocket"))
	skills.append(preload("res://scripts/systems/playable_assassin_content.gd").skill("blinding_powder"))
	skills.append(load("res://data/skills/exsanguinate.tres"))
	for practice in [false,true]:
		game.visible = not practice
		room.visible = practice
		var view = room if practice else screen._playback_presenter
		var stage = view._combat_stage
		var category = room._category_preview if practice else screen._category_preview
		for speed in [1.0,4.0]:
			for skill in skills:
				var capture_pose: bool = DisplayServer.get_name()!="headless" and speed==1.0 and skill.id in ["skill.pick_pocket","skill.master_of_poisons"]
				var image_name: String = "%s_%s"%["practice" if practice else "adventure",skill.id.get_slice(".",1)]
				var rotation: Array[Skill] = [skill]
				var result := CombatResolver.resolve(rotation,stats,enemy,skill.base_execution_ms+300,1234,true)
				check(result.is_valid and not result.cast_events.is_empty(),"Actual category resolver result: "+skill.id)
				var original := JSON.stringify(result.trace.presentation_records)
				var cast: CombatResolver.CastEvent = result.cast_events[0]
				var logical: Array = []
				var audio_at_f3: Array = []
				var audio_at_cast: Array = []
				var on_pose := func(index):
					logical.append(index+1)
					if index==2: audio_at_f3.append(count_audio())
					if index==1 and logical.size()>=4 and logical[-2]==3: audio_at_cast.append(count_audio())
				stage.category_pose_frame_changed.connect(on_pose)
				begin(screen,view,practice,result,enemy,speed)
				var audio_before := count_audio()
				var duration: float = float(cast.time_ms-cast.cast_start_ms)/1000.0/speed
				drive(view,practice,0.001)
				check(path(stage)=="frame_001.png","F1 starts category windup")
				if capture_pose: await capture(image_name+"_F1")
				drive(view,practice,duration*0.10-0.001)
				check(path(stage)=="frame_001.png","F1 remains brief through10percent")
				drive(view,practice,duration*0.05)
				check(path(stage)=="frame_002.png","F2 begins by15percent of windup")
				if capture_pose: await capture(image_name+"_F2")
				drive(view,practice,duration*0.15)
				check(path(stage)=="frame_003.png","F3 hold begins by30percent of windup")
				check(count_audio()==audio_before,"Held F3 is preparation, not early activation")
				drive(view,practice,duration*0.50)
				check(path(stage)=="frame_003.png","F3 lingers through80percent of windup")
				check(count_audio()==audio_before,"No early category audio")
				drive(view,practice,duration*0.10)
				check(path(stage)=="frame_003.png","F3 remains held at90percent before activation")
				var precast_file: String = stage.last_player_animation_frame_path
				check(count_audio()==audio_before,"Windup F3 never dispatches early audio")
				if capture_pose: await capture(image_name+"_F3_windup")
				drive(view,practice,duration*0.10+0.0001)
				check(path(stage)=="frame_002.png","Actual activation is fourth step/sourceF2")
				var activation_file: String = stage.last_player_animation_frame_path
				check(count_audio()>audio_before,"Activation dispatches existing category audio")
				check(audio_at_f3==[audio_before] and audio_at_cast==[audio_before],"PrecastF3 and castF2 both precede activation sound")
				check(category.notice != null and category.notice.text.begins_with(skill.display_name+"\n"),"Existing category name/effect popup survives")
				check(category.notice.get_theme_color("font_color")==Category.COLORS[skill.category],"Existing blue/purple popup color")
				var target = stage.player_actor_anchor if skill.category==Skill.Category.SELF_BUFF else stage.enemy_actor_anchor
				check(target.modulate==Category.COLORS[skill.category],"Existing player/enemy activation flash")
				if DisplayServer.get_name()!="headless" and skill.id in ["skill.pick_pocket","skill.master_of_poisons"]:
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png(OUT+"/%s_%dx_%s_activation.png"%["practice" if practice else "adventure",speed,skill.id.get_slice(".",1)])
					if speed==1.0: check(path(stage)=="frame_002.png","Normal playback renders cast-stepF2 with activation feedback")
				var sequence := ["frame_001.png","frame_002.png","frame_003.png",path(stage)]
				var captured_lower: Array = []
				var deadline := Time.get_ticks_msec()+1000
				while stage._category_tail_tween != null and stage._category_tail_tween.is_valid() and Time.get_ticks_msec()<deadline:
					await process_frame
					if capture_pose:
						await RenderingServer.frame_post_draw
						if stage._player_animation_key=="category_raise" and stage._player_animation_frame_index in [0,1] and not stage._player_animation_frame_index in captured_lower:
							captured_lower.append(stage._player_animation_frame_index)
							root.get_texture().get_image().save_png(OUT+"/"+image_name+"_lower_F%d.png"%(stage._player_animation_frame_index+1))
					if stage._player_animation_key=="category_raise":
						check(stage.last_player_animation_frame_path.contains("/attack1/frames/"),"Gesture references original attack1 art only")
						if sequence[-1]!=path(stage): sequence.append(path(stage))
				check(logical==[1,2,3,2,1],"Exact F1 F2 holdF3 castF2 F1 callbacks; no slash")
				stage.category_pose_frame_changed.disconnect(on_pose)
				check(stage.player_actor_anchor.position.distance_to(stage._player_base_position)<0.1,"Gesture has no bob or lunge")
				check(JSON.stringify(result.trace.presentation_records)==original,"Gesture leaves resolver records unchanged")
				rows.append({"mode":"practice" if practice else "adventure","speed":speed,"skill":skill.id,"logical_sequence":logical,"rendered_sequence":sequence,"windup_thresholds":[0.125,0.25],"pause_fraction":0.75,"pause_step":3,"precast_file":precast_file,"activation_step":4,"activation_file":activation_file,"precast_audio_counts":audio_at_f3,"activation_audio_counts":audio_at_cast})
				if DisplayServer.get_name()!="headless" and skill.id in ["skill.pick_pocket","skill.master_of_poisons"]:
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png(OUT+"/%s_%dx_%s.png"%["practice" if practice else "adventure",speed,skill.id.get_slice(".",1)])
				view._skip() if practice else view.skip()
				check(stage._category_tail_tween==null and stage._category_cast==null,"Skip cancels pose callbacks")
		# Speed changes resume from the actual active windup, reduced motion stays idle.
		var pair: Array[Skill] = [skills[0],skills[1]]
		var chained := CombatResolver.resolve(pair,stats,enemy,1600,1234,true)
		begin(screen,view,practice,chained,enemy,1.0)
		drive(view,practice,0.3)
		check(path(stage)=="frame_003.png","Consecutive category holds raised F3 during windup")
		drive(view,practice,0.15)
		check(path(stage)=="frame_003.png","Consecutive category reaches precastF3")
		drive(view,practice,0.0501)
		check(path(stage)=="frame_002.png" and stage._category_cast.skill.id==pair[1].id,"Next category retains prior fourth-step/sourceF2 cast tail")
		var lowered: Array = []
		var on_lower := func(index): lowered.append(index+1)
		stage.category_pose_frame_changed.connect(on_lower)
		while stage._category_tail_tween != null and stage._category_tail_tween.is_valid(): await process_frame
		stage.category_pose_frame_changed.disconnect(on_lower)
		check(lowered==[1],"Consecutive category preserves final F1 inside next windup")
		drive(view,practice,0.3)
		check(path(stage)=="frame_003.png","Next category resumes F3 hold at actual progress")
		drive(view,practice,0.15)
		check(path(stage)=="frame_003.png","Second category continues F3 hold before activation")
		drive(view,practice,0.05)
		check(path(stage)=="frame_002.png","Second category casts at sourceF2")
		# Toggle on a final tail without an active cast update or UI signal.
		category.reduced_motion = true
		await settle()
		check(stage._category_tail_tween==null,"Local reduced motion cancels final lowering tail")
		category.reduced_motion = false
		view._skip() if practice else view.skip()
		# At ordinary pace a following weapon cast has a delayed windup:
		# preserve the visible apex, then yield to its original attack timing.
		for handoff in [[skills[5],load("res://data/skills/quick_cut.tres")],[skills[6],thief.skill("steal")]]:
			var handoff_rotation: Array[Skill] = []
			handoff_rotation.assign(handoff)
			var handoff_result := CombatResolver.resolve(handoff_rotation,stats,enemy,4000,1234,true)
			begin(screen,view,practice,handoff_result,enemy,1.0)
			var cast_one: CombatResolver.CastEvent = handoff_result.cast_events[0]
			var cast_two: CombatResolver.CastEvent = handoff_result.cast_events[1]
			drive(view,practice,float(cast_one.time_ms)/1000.0+0.0001)
			if DisplayServer.get_name()!="headless": await RenderingServer.frame_post_draw
			check(stage._player_animation_key=="category_raise" and path(stage)=="frame_002.png","Normal category-to-weapon handoff visibly retains castF2 at activation")
			var saw_weapon := false
			var clock = view._playback
			var previous := Time.get_ticks_usec()
			while clock.elapsed_ms()<cast_two.time_ms and view._playback!=null:
				await process_frame
				var now := Time.get_ticks_usec()
				drive(view,practice,(now-previous)/1000000.0)
				previous = now
				if stage._player_animation_key=="attack_physical": saw_weapon = true
			check(saw_weapon,"Following physical attack retains its own animation before contact")
			rows.append({"mode":"practice" if practice else "adventure","handoff":handoff_rotation[0].id+" -> "+handoff_rotation[1].id,"cast_pose_visible":true,"weapon_animation_observed":saw_weapon,"contact_ms":cast_two.time_ms})
			view._skip() if practice else view.skip()
		# Current category casts are interruption-immune. Exercise a real
		# unsuccessful category attempt through its authored cooldown instead.
		var cooldown_rotation: Array[Skill] = [skills[0]]
		var blocked := CombatResolver.resolve(cooldown_rotation,stats,enemy,2000,1234,true)
		check(blocked.cast_events.any(func(c): return c.cooldown_blocked),"Actual resolver cooldown-blocked witness")
		begin(screen,view,practice,blocked,enemy,1.0)
		var previous_event: Callable = view._playback.event_callback
		var failed_events := [0]
		view._playback.event_callback = func(event):
			var before := count_audio()
			previous_event.call(event)
			if not event.is_tick and event.cast.cooldown_blocked:
				failed_events[0] += 1
				check(stage._category_tail_cast!=event.cast,"Blocked event creates no successful cast tail and preserves its predecessor")
				check(count_audio()==before,"Blocked event emits no category activation sound")
		drive(view,practice,20.0)
		check(failed_events[0]>0 and stage._category_tail_tween==null,"Normal finish clears all category callbacks after blocked attempts")
		var rotation: Array[Skill] = [skills[6]]
		var result := CombatResolver.resolve(rotation,stats,enemy,2600,1234,true)
		begin(screen,view,practice,result,enemy,1.0)
		drive(view,practice,1.1)
		view._set_speed(4.0) if practice else view.set_speed(4.0)
		drive(view,practice,0.001)
		check(path(stage)=="frame_003.png","Speed change resumes F3 hold at current category progress")
		CombatEffectIcons.reduced_motion = true
		await settle()
		drive(view,practice,0.1)
		check(stage._category_cast==null and stage._category_tail_tween==null,"Reduced motion cancels gesture")
		view._skip() if practice else view.skip()
		CombatEffectIcons.reduced_motion = false
		# Paused-tail source-pose inspection supplements the unpaused runtime
		# checks above; it is explicitly not a realtime duration measurement.
		if DisplayServer.get_name()!="headless":
			for inspected in [skills[0],skills[6]]:
				var inspect_rotation: Array[Skill] = [inspected]
				var inspect_result := CombatResolver.resolve(inspect_rotation,stats,enemy,inspected.base_execution_ms+300,1234,true)
				begin(screen,view,practice,inspect_result,enemy,1.0)
				drive(view,practice,float(inspect_result.cast_events[0].time_ms)/1000.0+0.0001)
				var tail: Tween = stage._category_tail_tween
				stage._category_tail_clock_enabled = false
				tail.pause()
				var visual: float = (inspect_result.cast_events[0].time_ms-inspect_result.cast_events[0].cast_start_ms)/1000.0
				var inspection_name: String = "%s_%s_paused_tail"%["practice" if practice else "adventure",inspected.id.get_slice(".",1)]
				await capture(inspection_name+"_cast_F2")
				tail.custom_step(clampf(visual*0.06,0.025,0.08)+0.0001)
				check(path(stage)=="frame_001.png","Paused inspection lower F1")
				await capture(inspection_name+"_F1")
				view._skip() if practice else view.skip()
	SaveSystem.write_json(OUT+"/evidence.json",{"rows":rows,"paused_tail_images":"Explicit static pose inspection only. Runtime sync/order and unpaused activation screenshots are checked separately."})
	room.queue_free()
	game.queue_free()
	await settle()
	print("Category arm raise PASS" if not failed else "Category arm raise FAILED")
	quit(1 if failed else 0)
