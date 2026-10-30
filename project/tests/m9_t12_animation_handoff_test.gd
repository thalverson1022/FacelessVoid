extends SceneTree
## T12 rendered regression: resolver-backed casts at uninterrupted wall cadence.
const OUT := "res://reports/t12_animation_handoff"
const Content = preload("res://scripts/systems/playable_assassin_content.gd")
var rows: Array = []
var failed := false
var capture_mode := OS.get_environment("FACELESSVOID_T12_CAPTURE")=="1"
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		printerr("FAILED: "+message)
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in 4: await process_frame
func count_audio() -> int:
	var audio = root.get_node("AudioManager")
	var count: int = audio.category_sfx_play_count+audio.exsanguinate_sfx_play_count+audio.gold_steal_sfx_play_count
	for amount in audio.skill_sfx_play_counts.values(): count += int(amount)
	return count
func snapshot(stage, clock) -> Dictionary:
	return {"audio_count":count_audio(),"wall_us":Time.get_ticks_usec(),"resolver_ms":clock.elapsed_ms(),"presentation_ms":clock._presentation_ms,"key":stage._player_animation_key,"frame":stage._player_animation_frame_index+1,"source":stage.last_player_animation_frame_path,"tail_speed_scale":stage._category_tail_speed_scale,"tail":stage._category_tail_tween!=null,"owner":stage._category_cast.skill.id if stage._category_cast!=null else "","active":clock.active_cast().skill.id if clock.active_cast()!=null else "","progress":clock.active_cast_progress()}
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
	await settle()
	var enemy := Monster.new()
	enemy.display_name = "Mouthy Drunk"
	enemy.hp = 100000
	var specs := [
		["user_rotation",["virulent_poison","venom_jab","blinding_powder","blinding_powder"],0.0,0.0],
		["speed_change",["virulent_poison","venom_jab","blinding_powder","blinding_powder"],0.0,0.0],
		["weapon_speed_change",["virulent_poison","venom_jab","blinding_powder","blinding_powder"],0.0,0.0],
		["blocked_virulent",["virulent_poison"],0.0,0.0],
		["consecutive_buffs",["master_of_poisons","virulent_poison"],0.0,0.0],
		["physical_poison_control",["stab","venom_jab"],0.0,0.0],
		["physical_handoff",["virulent_poison","stab"],0.0,0.0],
		["weapon_cleanup",["virulent_poison","venom_jab"],0.0,0.0]
	]
	if OS.get_environment("FACELESSVOID_T12_TARGETED")=="1": specs = [specs[2],specs[-1]]
	if capture_mode: specs = [specs[0]]
	if OS.get_environment("FACELESSVOID_T12_FAST_ONLY")=="1": specs = [["fast_handoff",["virulent_poison","venom_jab"],3.0,0.0]]
	for practice in [false,true]:
		game.visible = not practice
		room.visible = practice
		var view = room if practice else screen._playback_presenter
		var stage = view._combat_stage
		var category = room._category_preview if practice else screen._category_preview
		for speed in ([8.0] if OS.get_environment("FACELESSVOID_T12_FAST_ONLY")=="1" else [1.0,4.0]):
			for spec in specs:
				var stats := PlayerStats.new()
				stats.assassin_tree_points = 10
				stats.attack_speed = spec[2]
				stats.retrigger_chance = spec[3]
				var rotation: Array[Skill] = []
				for kind in spec[1]: rotation.append(load("res://data/skills/stab.tres") if kind=="stab" else Content.skill(kind))
				var result := CombatResolver.resolve(rotation,stats,enemy,4600 if spec[0] in ["user_rotation","speed_change","weapon_speed_change","physical_poison_control"] else 2200,7,true)
				var target: CombatResolver.CastEvent
				var casts: Array = []
				for cast in result.cast_events:
					casts.append({"id":cast.skill.id,"start":cast.cast_start_ms,"impact":cast.time_ms,"origin":cast.origin_kind,"depth":cast.retrigger_depth,"blocked":cast.cooldown_blocked})
					if target == null: target=cast
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
				var clock = view._playback
				var original_records := JSON.stringify(result.trace.presentation_records)
				var changed_speed := false
				var frames: Array = []
				var pending_images: Array = []
				var events: Array = []
				var poses: Array = []
				var on_pose := func(index): poses.append({"index":index+1,"wall_us":Time.get_ticks_usec(),"resolver_ms":clock.elapsed_ms()})
				stage.category_pose_frame_changed.connect(on_pose)
				var prior: Callable = clock.event_callback
				clock.event_callback = func(event):
					var before := snapshot(stage,clock)
					prior.call(event)
					if not event.is_tick: events.append({"skill":event.cast.skill.id,"time_ms":event.cast.time_ms,"contact_frame":stage._player_animation_cache.get("attack_poison",{}).get("frames",[]).size()-1,"blocked":event.cast.cooldown_blocked,"chain_index":event.chain_index,"chain_count":event.chain_count,"before":before,"after":snapshot(stage,clock),"previous_render":frames[-1] if not frames.is_empty() else {}})
				var previous := Time.get_ticks_usec()
				var deadline := previous+int(9.0*1000000.0)
				while view._playback!=null and clock.elapsed_ms()<(4500 if spec[0] in ["user_rotation","speed_change","weapon_speed_change","physical_poison_control"] else 2100) and Time.get_ticks_usec()<deadline:
					await process_frame
					var now := Time.get_ticks_usec()
					var delta := (now-previous)/1000000.0
					previous = now
					if practice: view._process(delta)
					else: view.advance(delta)
					if not changed_speed and ((spec[0]=="speed_change" and stage._category_tail_tween!=null) or (spec[0]=="weapon_speed_change" and stage._category_weapon_cast!=null and clock.active_cast_progress()>0.4)):
						if practice: view._set_speed(4.0 if speed==1.0 else 1.0)
						else: view.set_speed(4.0 if speed==1.0 else 1.0)
						changed_speed = true
					if spec[0]=="weapon_cleanup" and not changed_speed and stage._category_weapon_cast!=null and clock.active_cast_progress()>0.4:
						category.reduced_motion = true
						await process_frame
						check(stage._player_animation_key=="idle" and stage._category_weapon_cast==null,"Reduced motion restores idle from reserved attack")
						stage.clear_transient_effects()
						check(stage._player_animation_key=="idle","Global cleanup retains idle after reserved attack")
						changed_speed = true
					await RenderingServer.frame_post_draw
					var rendered := snapshot(stage,clock)
					var changed: bool = frames.is_empty() or frames[-1].key!=rendered.key or frames[-1].frame!=rendered.frame
					if capture_mode and changed and spec[0]=="user_rotation" and (clock.elapsed_ms()<700 or (clock.elapsed_ms()>1350 and clock.elapsed_ms()<1550) or (clock.elapsed_ms()>2600 and clock.elapsed_ms()<2850) or (clock.elapsed_ms()>3850 and clock.elapsed_ms()<4100)):
						var image_path := OUT+"/%s_%dx_%s_F%d_%dms.png"%["practice" if practice else "adventure",speed,rendered.key,rendered.frame,clock.elapsed_ms()]
						pending_images.append({"path":image_path,"image":root.get_texture().get_image()})
						rendered["screenshot"] = image_path
					frames.append(rendered)
				for pending in pending_images: pending.image.save_png(pending.path)
				var compressed: Array = []
				for frame in frames:
					if compressed.is_empty() or compressed[-1].key!=frame.key or compressed[-1].frame!=frame.frame: compressed.append(frame)
				# Every successful category activation must render its returning F2
				# and F1 before a later animation takes ownership.
				for event in events:
					if event.skill=="skill.venom_jab" and spec[0] in ["user_rotation","speed_change","weapon_speed_change"]:
						check(event.after.key=="attack_poison" and event.after.frame==event.contact_frame,"Incoming Poison uses exact source contact frame at original impact callback: "+str(event.after))
						check(event.before.key=="attack_poison" and event.before.frame>=event.contact_frame-1,"Incoming Poison immediately precedes contact within one source frame: "+str(event.before))
					if event.skill not in ["skill.virulent_poison","skill.master_of_poisons","skill.blinding_powder"]: continue
					if event.blocked:
						check(event.after.audio_count==event.before.audio_count,"Blocked attempt has no activation audio")
						continue
					check(event.after.audio_count>event.before.audio_count,"Successful category audio stays on resolver activation")
					var release: Array = []
					for frame in frames:
						if frame.wall_us<event.after.wall_us: continue
						if frame.wall_us>event.after.wall_us+220000: break
						if frame.key=="category_raise" and frame.frame in [1,2] and (release.is_empty() or release[-1]!=frame.frame): release.append(frame.frame)
					check(release.size()>=2 and release[0]==2 and release[1]==1,"%s %sx %s %s rendered release F2 F1: %s"%["practice" if practice else "adventure",speed,spec[0],event.skill,release])
				check(result.is_valid,"Resolver result valid")
				check(JSON.stringify(result.trace.presentation_records)==original_records,"No resolver records changed")
				if spec[0] in ["user_rotation","speed_change","weapon_speed_change","physical_poison_control"]:
					check(frames.any(func(frame): return frame.key=="attack_poison"),"Incoming Poison animation renders")
				if spec[0] in ["physical_poison_control","physical_handoff"]: check(frames.any(func(frame): return frame.key=="attack_physical"),"Physical control renders")
				rows.append({"mode":"practice" if practice else "adventure","speed":speed,"case":spec[0],"valid":result.is_valid,"casts":casts,"events":events,"pose_callbacks":poses,"rendered_changes":compressed,"frames":frames})
				print("CASE ", rows[-1].mode," ", speed,"x ",spec[0]," frames=",frames.size())
				stage.category_pose_frame_changed.disconnect(on_pose)
				clock.event_callback = prior
				if practice: view._skip()
				else: view.skip()
				check(stage._category_tail_tween==null and stage._category_pending_weapon.is_empty() and stage._category_weapon_cast==null,"Skip removes release and incoming cast ownership")
				category.reduced_motion = false
				var previous_key: String = stage._player_animation_key
				stage.update_category_progress(target,1.0,speed,true)
				check(stage._player_animation_key==previous_key,"Stale completed progress cannot resurrect a cast")
				if OS.get_environment("FACELESSVOID_T12_TARGETED")=="1":
					# Callback robustness witness: a slow advance can cross impact
					# without an intervening presentation-progress update.
					for cast in result.cast_events:
						if cast.skill.id!="skill.venom_jab": continue
						stage._start_weapon_windup(cast,stage.animation_kind_for_cast(cast),0.2,true,0.4)
						check(stage._category_weapon_cast==cast and stage._player_animation_key=="idle","Reserved weapon awaits progress update")
						stage.play_cast_impact(cast)
						var expected: String = stage._player_animation_key_for_kind(stage.animation_kind_for_cast(cast))
						check(stage._player_animation_key==expected and stage._player_animation_frame_index==stage._player_animation_cache[expected].frames.size()-2,"Impact with skipped progress selects actual attack contact art")
						stage.clear_transient_effects()
						break
	SaveSystem.write_json(OUT+"/evidence.json",{"capture_mode":capture_mode,"rows":rows,"contact_evidence":"Exact owned contact source frame at impact callback. Previous source frame is allowed one art frame before contact because playback dispatch follows process/render cadence; next category may supersede within the same advance. PNG capture pass is separate from cadence matrix.","description":"Continuous rendered regression at wall-clock cadence; resolver-backed rotations; isolated saves. No pose pauses or manual tween stepping."})
	room.queue_free()
	game.queue_free()
	await settle()
	print("T12 animation handoff PASS" if not failed else "T12 animation handoff FAILED")
	quit(1 if failed else 0)
