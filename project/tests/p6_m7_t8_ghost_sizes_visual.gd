extends "res://tests/p6_m7_mixed_cues_visual.gd"
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
	DirAccess.make_dir_recursive_absolute("res://reports/ghost_sizes")
	var game=load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_contract_test_pressed(1234,45,"tree.assassin","tree.shadow")
	var state=root.get_node("BuildState")
	var enemy:=Monster.new()
	enemy.hp=100000
	var stats:=PlayerStats.new()
	stats.weapon_damage_min=100
	stats.weapon_damage_max=100
	stats.retrigger_chance=1.0
	stats.poison_damage_per_tick=10
	stats.readiness_enabled=true
	var result=CombatResolver.resolve([load("res://data/skills/venom_jab.tres"),preload("res://scripts/systems/p6_poison_contracts.gd").poison_strike()],stats,enemy,4000,7,true)
	var measurements:Array=[]
	for mode in ["test","adventure","practice"]:
		if mode=="practice":game._show_training_room()
		else:
			state.is_test_mode=mode=="test"
			game._show_combat_screen()
		await settle()
		var screen=game._current_screen
		if mode!="practice":
			if screen._story_overlay.visible:screen._story_overlay._on_proceed_pressed()
			screen._contract_overlay.hide()
			screen._map_overlay.hide()
		var view=screen._combat_view if mode=="practice" else screen._playback_presenter
		if mode!="practice":view.finished.disconnect(screen._on_playback_finished)
		for width in [1280,1600,1920]:
			root.size=Vector2i(width,width*9/16)
			await settle()
			begin(screen,view,mode,result,enemy,4.0)
			drive(screen,view,mode,1.261/4.0)
			for i in 3:
				await create_timer(0.04).timeout
				drive(screen,view,mode,0.04)
			var tick:=CombatPlayback.PlaybackEvent.new()
			tick.is_tick=true
			tick.tick=CombatResolver.TickEvent.new()
			tick.tick.damage=15.5
			tick.tick.had_active_stack=true
			tick.damage=15.5
			emit(view,mode,tick)
			await settle()
			var labels:Array=[]
			var echoes:Array[Rect2]=[]
			var ticks:Array[Rect2]=[]
			for label in view._popup_layer.get_children():
				if label is Control and label.visible and not label.is_queued_for_deletion():
					var r:Rect2=label.get_global_rect()
					labels.append({"rect":str(r),"echo":label.has_meta("retrigger_hit"),"lane":label.get_meta("cue_lane",-1),"alpha":label.modulate.a})
					check(view._combat_stage.play_area_global_rect().encloses(r),"visible popup fits stage")
					if label.has_meta("retrigger_hit"):echoes.append(r)
					if label.get_meta("cue_lane",-1)==2:ticks.append(r)
			for a in echoes:
				for b in ticks:check(not a.intersects(b),"Poison clear of ghost label")
			check(not ghost_clear(view._combat_stage),"ghost visible at mixed size sample")
			check(not echoes.is_empty() and not ticks.is_empty(),"echo and Poison sampled together")
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://reports/ghost_sizes/%s_%d_mixed.png" % [mode,width])
			measurements.append({"mode":mode,"physical":str(root.size),"logical":str(root.get_visible_rect()),"stage":str(view._combat_stage.play_area_global_rect()),"labels":labels})
			var icons=screen._combat_view._effect_icons if mode=="practice" else screen._effect_icons
			if true:
				icons._open_inspector()
				for step in 10:
					if icons._motion.has_focus():break
					await key(KEY_TAB)
				check(icons._motion.has_focus(),"Tab reaches existing inspector motion toggle")
				await key(KEY_SPACE)
				check(CombatEffectIcons.reduced_motion,"Space enables existing reduced-motion toggle")
			
			drive(screen,view,mode,0.04)
			check(ghost_clear(view._combat_stage),"reduced motion clears ghost")
			check(view._popup_layer.get_children().filter(func(n):return n.visible and not n.is_queued_for_deletion()).is_empty(),"reduced motion clears transient text")
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://reports/ghost_sizes/%s_%d_reduced.png" % [mode,width])
			if true:
				await key(KEY_SPACE)
				check(not CombatEffectIcons.reduced_motion,"Space restores motion preference")
				await key(KEY_ESCAPE)
			
			if mode=="practice":view._skip()
			else:view.skip()
	SaveSystem.write_json("res://reports/ghost_sizes/measurements.json",{"rows":measurements,"disclosure":"Guaranteed-retrigger resolver fixture with synthetic stats; Poison event injected alongside real ghost, 4x viewing. Reduced motion diagnostic static, no new setting. No font override is applied to accepted ghost labels."})
	game.queue_free()
	await settle()
	print("T8 ghost sizes PASS" if not failed else "T8 ghost sizes FAILED")
	quit(1 if failed else 0)
