extends "res://tests/p6_m7_mixed_cues_visual.gd"
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/contrast")
	var game=load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_contract_test_pressed(1234,45,"tree.bladedancer","tree.thief")
	var state=root.get_node("BuildState")
	var enemy:=Monster.new()
	enemy.hp=100000
	enemy.block=25
	enemy.dodge_chance=0.2
	enemy.crit_negation=0.25
	var stats:=PlayerStats.new()
	stats.shred_chance=1.0
	var result=CombatResolver.resolve([load("res://data/skills/stab.tres")],stats,enemy,10000,7,true)
	var labels:Array=[]
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
		begin(screen,view,mode,result,enemy,1.0)
		drive(screen,view,mode,4.0)
		await settle()
		for label in screen.find_children("Text","Label",true,false):
			if label.is_visible_in_tree():labels.append({"mode":mode,"text":label.text,"color":label.get_theme_color("font_color").to_html(),"rect":str(label.get_global_rect()),"modulate":str(label.modulate),"self_modulate":str(label.self_modulate)})
		root.get_texture().get_image().save_png("res://reports/contrast/"+mode+"_active.png")
	SaveSystem.write_json("res://reports/contrast/labels.json",{"labels":labels})
	game.queue_free()
	await settle()
	print("T8 contrast capture PASS")
	quit()
