extends SceneTree
## Diagnostic only: actual resolver rotations, normal rendered frame cadence.
const OUT := "res://reports/virulent_animation_probe"
const Content = preload("res://scripts/systems/playable_assassin_content.gd")
var rows: Array = []
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in 4: await process_frame
func snapshot(stage, clock) -> Dictionary:
	return {"wall_us":Time.get_ticks_usec(),"resolver_ms":clock.elapsed_ms(),"presentation_ms":clock._presentation_ms,"key":stage._player_animation_key,"frame":stage._player_animation_frame_index+1,"source":stage.last_player_animation_frame_path,"tail":stage._category_tail_tween!=null,"owner":stage._category_cast.skill.id if stage._category_cast!=null else "","active":clock.active_cast().skill.id if clock.active_cast()!=null else "","progress":clock.active_cast_progress()}
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
		["alone",["virulent_poison"],0.0,0.0],
		["buff_then_virulent",["master_of_poisons","virulent_poison"],0.0,0.0],
		["venom_then_virulent",["venom_jab","virulent_poison"],0.0,0.0],
		["fast_venom_then_virulent",["venom_jab","virulent_poison"],3.0,0.0],
		["repeated_venom_then_virulent",["venom_jab","virulent_poison"],0.0,1.0],
		["virulent_then_venom",["virulent_poison","venom_jab"],0.0,0.0]
	]
	var capture_mode := OS.get_environment("FACELESSVOID_VIRULENT_CAPTURE")=="1"
	if capture_mode: specs = [specs[2]]
	for practice in [false,true]:
		game.visible = not practice
		room.visible = practice
		var view = room if practice else screen._playback_presenter
		var stage = view._combat_stage
		for speed in [1.0,4.0]:
			for spec in specs:
				var stats := PlayerStats.new()
				stats.assassin_tree_points = 10
				stats.attack_speed = spec[2]
				stats.retrigger_chance = spec[3]
				var rotation: Array[Skill] = []
				for kind in spec[1]: rotation.append(Content.skill(kind))
				var result := CombatResolver.resolve(rotation,stats,enemy,3500,7,true)
				var target: CombatResolver.CastEvent
				var casts: Array = []
				for cast in result.cast_events:
					casts.append({"id":cast.skill.id,"start":cast.cast_start_ms,"impact":cast.time_ms,"origin":cast.origin_kind,"depth":cast.retrigger_depth,"blocked":cast.cooldown_blocked})
					if target == null and cast.skill.id=="skill.virulent_poison": target=cast
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
				var frames: Array = []
				var events: Array = []
				var poses: Array = []
				var on_pose := func(index): poses.append({"index":index+1,"wall_us":Time.get_ticks_usec(),"resolver_ms":clock.elapsed_ms()})
				stage.category_pose_frame_changed.connect(on_pose)
				var prior: Callable = clock.event_callback
				clock.event_callback = func(event):
					var before := snapshot(stage,clock)
					prior.call(event)
					if not event.is_tick: events.append({"skill":event.cast.skill.id,"chain_index":event.chain_index,"chain_count":event.chain_count,"before":before,"after":snapshot(stage,clock)})
				var previous := Time.get_ticks_usec()
				var deadline := previous+int(5.0*1000000.0)
				while view._playback!=null and clock.elapsed_ms()<target.time_ms+250 and Time.get_ticks_usec()<deadline:
					await process_frame
					var now := Time.get_ticks_usec()
					var delta := (now-previous)/1000000.0
					previous = now
					if practice: view._process(delta)
					else: view.advance(delta)
					await RenderingServer.frame_post_draw
					var rendered := snapshot(stage,clock)
					var changed: bool = frames.is_empty() or frames[-1].key!=rendered.key or frames[-1].frame!=rendered.frame
					if capture_mode and changed and clock.elapsed_ms()>=target.cast_start_ms and clock.elapsed_ms()<target.time_ms+40:
						var image_path := OUT+"/%s_%dx_%s_F%d_%dms.png"%["practice" if practice else "adventure",speed,rendered.key,rendered.frame,clock.elapsed_ms()]
						root.get_texture().get_image().save_png(image_path)
						rendered["screenshot"] = image_path
					frames.append(rendered)
				var compressed: Array = []
				for frame in frames:
					if compressed.is_empty() or compressed[-1].key!=frame.key or compressed[-1].frame!=frame.frame: compressed.append(frame)
				rows.append({"mode":"practice" if practice else "adventure","speed":speed,"case":spec[0],"valid":result.is_valid,"casts":casts,"events":events,"pose_callbacks":poses,"rendered_changes":compressed,"frames":frames})
				print("PROBE ", rows[-1].mode," ", speed,"x ",spec[0]," frames=",frames.size()," changes=",JSON.stringify(compressed))
				stage.category_pose_frame_changed.disconnect(on_pose)
				clock.event_callback = prior
				if practice: view._skip()
				else: view.skip()
	SaveSystem.write_json(OUT+"/evidence.json",{"rows":rows,"description":"Diagnostic: actual rendered frame samples at wall-clock cadence. No production source edits; resolver-backed rotations; isolated saves."})
	room.queue_free()
	game.queue_free()
	await settle()
	print("Virulent animation diagnostic PASS")
	quit(0)
