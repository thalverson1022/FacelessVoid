extends "res://tests/p6_m7_t8_integrated_test.gd"
func record(test: String, ok: bool, data = {}) -> void:
	evidence.append({"test":test,"pass":ok,"data":data})
	check(ok,test)
func capture(name: String) -> void:
	await settle()
	root.get_texture().get_image().save_png("res://reports/footer/"+name+".png")
	captures.append(name)
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/footer")
	var game=load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._show_training_room()
	await settle()
	var screen=game._current_screen
	var actual=screen._state
	var registry:=BuildContentRegistry.test_mode()
	actual.ranked_build.configure(registry.trees["tree.assassin"],registry.trees["tree.shadow"],45,RANKS_AS)
	actual._finish_rank_edit(true)
	await settle()
	var resolved=BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],actual.ranked_build,[load("res://data/gear/crude_dagger.tres")])
	var rotation:Array[Skill]=[]
	for skill in resolved.skills:
		if skill.id in ["skill.venom_jab","skill.poison_strike","skill.stab"]:rotation.append(skill)
	actual.set_rotation(rotation)
	var enemy:=Monster.new()
	enemy.hp=100000
	enemy.display_name="Mouthy Drunk"
	var result=CombatResolver.resolve(rotation,resolved.stats,enemy,10000,7,true)
	var view=screen._combat_view
	for width in [1280,1600,1920]:
		root.size=Vector2i(width,width*9/16)
		for scale in [1.0,1.25]:
			fonts(screen.find_child("ActiveTalentsPanel",true,false),scale)
			await settle()
			begin(screen,view,"practice",result,enemy,1.0)
			drive(screen,view,"practice",1.8)
			emit(view,"practice",diagnostic(1))
			emit(view,"practice",diagnostic(2))
			var tick:=CombatPlayback.PlaybackEvent.new()
			tick.is_tick=true
			tick.tick=CombatResolver.TickEvent.new()
			tick.tick.damage=15.5
			tick.tick.had_active_stack=true
			tick.damage=15.5
			emit(view,"practice",tick)
			for sample in [0.0,0.04,0.12,0.3]:
				if sample>0:await create_timer(sample).timeout
				var live:Array[Rect2]=[]
				for popup in view._popup_layer.get_children():
					if popup is Control and popup.visible and popup.has_meta("cue_lane"):
						var r:Rect2=popup.get_global_rect()
						for button in [screen._fight_button,screen._view_log_button]:
							record("Practice popup clears footer",not r.intersects(button.get_global_rect()),{"width":width,"font_scale":scale,"sample":sample,"lane":popup.get_meta("cue_lane"),"popup":str(r),"button":str(button.get_global_rect())})
						for other in live:record("Practice normal/tick lanes separate",not r.intersects(other))
						live.append(r)
				await capture("practice_%d_%d_%d" % [width,roundi(scale*100),roundi(sample*1000)])
			view._skip()
	SaveSystem.write_json("res://reports/footer/measurements.json",{"checks":evidence,"captures":captures,"disclosure":"Six Practice physical-size/diagnostic-font cases; legal resolver build plus synthetic wide crit-negation/gold/tick injections; actual button-rectangle checks at punch start, during punch, settled scale and later rise. Actors and ghost placement unchanged."})
	game.queue_free()
	await settle()
	print("T8 footer PASS" if not failed else "T8 footer FAILED")
	quit(1 if failed else 0)
