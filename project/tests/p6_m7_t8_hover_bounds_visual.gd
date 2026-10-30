extends "res://tests/p6_m7_t8_integrated_test.gd"
func capture(name: String) -> void:
	await settle()
	root.get_texture().get_image().save_png("res://reports/integrated/"+name+".png")
	captures.append(name)
func record(test: String, ok: bool, data = {}) -> void:
	evidence.append({"test":test,"pass":ok,"data":data})
	check(ok,test)
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/integrated")
	var game=load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_contract_test_pressed(1234,45,"tree.assassin","tree.shadow")
	await settle()
	var state=root.get_node("BuildState")
	var registry:=BuildContentRegistry.test_mode()
	state.ranked_build.configure(registry.trees["tree.assassin"],registry.trees["tree.shadow"],45,RANKS_AS)
	state._finish_rank_edit(true)
	var button:=IconTooltipButton.new()
	button.theme=load("res://assets/ui_theme.tres")
	button.size=Vector2(48,48)
	button.text="?"
	root.add_child(button)
	for width in [1280,1600,1920]:
		root.size=Vector2i(width,width*9/16)
		await settle()
		button.position=root.get_visible_rect().end-Vector2(60,60)
		for scale in [1.0,1.25]:
			for kind in ["talent","skill"]:
				button.set_script(IconTooltipButton if scale==1 else StressButton)
				button.talent_hover_provider=Callable()
				button.skill_hover_provider=Callable()
				if kind=="talent":button.talent_hover_provider=func():return preload("res://scripts/ui/talent_hover_formatter.gd").model(registry.talents["talent.shadow.shadow_mastery"],registry.trees["tree.shadow"],state.ranked_build)
				else:button.skill_hover_provider=func():return preload("res://scripts/ui/skill_hover_formatter.gd").model(load("res://data/skills/poison_strike.tres"),state)
				await hover(button,scale,"edge_%d_%d_%s" % [width,roundi(scale*100),kind])
				var windows:Array=[]
				if root.has_method("get_embedded_subwindows"):windows=root.call("get_embedded_subwindows")
				var measured:=false
				for window in windows:
					if window.visible:
						measured=true
						record("actual engine tooltip window contained",root.get_visible_rect().encloses(Rect2(window.position,window.size)),{"width":width,"scale":scale,"kind":kind,"logical_position":str(window.position),"logical_size":str(window.size),"physical":str(root.size),"physical_bounds":str(root.get_final_transform()*Rect2(window.position,window.size))})
				record("actual engine tooltip window measured",measured)
	SaveSystem.write_json("res://reports/integrated/hover_geometry.json",{"checks":evidence,"captures":captures,"disclosure":"Bottom-right boundary fixture uses actual shared skill/talent providers and panels; mode live targets captured in main matrix. Embedded Window and Control geometry logical1600x900; final canvas transform gives physical bounds."})
	button.queue_free()
	game.queue_free()
	await settle()
	print("T8 hover bounds PASS" if not failed else "T8 hover bounds FAILED")
	quit(1 if failed else 0)
