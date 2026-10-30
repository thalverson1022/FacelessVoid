extends SceneTree
const Backdrop=preload("res://scripts/ui/talent_tree_backdrop.gd")
var checks:=0
var failed:=false
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok:
		failed=true
		printerr("FAILED: "+text)
func settle() -> void:
	for i in 7: await process_frame
func geometry(panel: Control) -> Dictionary:
	var data:={"minimum":panel.get_combined_minimum_size(),"size":panel.size}
	for control in panel.find_children("*","Control",true,false):
		data[str(panel.get_path_to(control))]=control.get_global_rect()
	return data
func run() -> void:
	var registry:=BuildContentRegistry.test_mode()
	# Dashboard now shows subclass identity only; full talent text stays in trees.
	var hud=load("res://scenes/combat/active_talents_panel.gd").new()
	for tree in registry.trees.values():
		var row: HBoxContainer=hud._build_subclass_row(tree,0)
		check(row.get_node("SubclassName").text==tree.display_name,tree.id+" subclass name")
		check(row.get_node("SubclassIcon") is TextureRect,tree.id+" subclass icon")
		check(row.get_child_count()==2,tree.id+" only icon and name")
		row.free()
	var empty: HBoxContainer=hud._build_subclass_row(null,1)
	check(empty.get_node("SubclassName").text=="none","Missing secondary reads none")
	check(empty.get_node("EmptySubclassIcon") is ColorRect,"Missing secondary gray square")
	empty.free()
	hud.free()
	for id in Backdrop.PATHS:
		var texture: Texture2D=load(Backdrop.PATHS[id])
		check(texture!=null and texture.get_size()==Vector2(848,1264),id+" original dimensions")
	for size in [Vector2(440,520),Vector2(700,350),Vector2(200,900)]:
		var source:=Backdrop.cover_source(Vector2(848,1264),size)
		check(is_equal_approx(source.size.x/source.size.y,size.x/size.y),"Cover preserves aspect")
		check(Rect2(Vector2.ZERO,Vector2(848,1264)).encloses(source),"Crop within original")
		check(is_equal_approx(source.get_center().x,424) and is_equal_approx(source.get_center().y,632),"Centered cover crop")
	var state=root.get_node("BuildState")
	var game=load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_contract_test_pressed(1234,45,"tree.bladedancer","tree.thief")
	await settle()
	for mode in ["test","adventure","practice"]:
		if mode=="practice": game._show_training_room()
		else:
			state.is_test_mode=mode=="test"
			game._show_combat_screen()
		await settle()
		var screen=game._current_screen
		var actual=screen._state if mode=="practice" else state
		for pair in [["tree.bladedancer","tree.thief"],["tree.assassin","tree.shadow"],["tree.shadow","tree.assassin"],["tree.thief","tree.bladedancer"]]:
			if mode=="practice":
				actual.set_primary_tree(registry.trees[pair[0]])
				actual.set_secondary_tree(registry.trees[pair[1]])
			check(actual.ranked_build.configure(registry.trees[pair[0]],registry.trees[pair[1]],45,{}),"Legal role fixture")
			actual._finish_rank_edit(true)
			await settle()
			for index in 2:
				var role: String="Primary" if index==0 else "Secondary"
				var panel: Control=screen.find_child(role+"TreePanel",true,false)
				var bg=panel.get_node("TalentTreeBackdrop")
				check(bg.tree_id==pair[index] and bg.texture.resource_path==Backdrop.PATHS[pair[index]],mode+" role uses stable treeID")
				check(not bg is Control,mode+" decoration cannot enter sizing/input")
				for width in [1280,1600,1920]:
					root.size=Vector2i(width,width*9/16)
					await settle()
					var before:=geometry(panel)
					panel.remove_child(bg)
					await settle()
					check(geometry(panel)==before,mode+" unchanged min/graph/buttons without backdrop")
					panel.add_child(bg)
					panel.move_child(bg,0)
					await settle()
					check(geometry(panel)==before,mode+" unchanged min/graph/buttons with backdrop")
				check(bg.interior.position==Vector2(2,2) and bg.interior.end==panel.size-Vector2(4,5),"Interior preserves borders/includes padding")
		if mode=="practice": screen._talent_overlay.show()
		else:
			screen._contract_overlay.hide()
			screen._map_overlay.hide()
			screen._show_talent_overlay()
		await settle()
		var button=screen.find_child("TalentGraph_tree_bladedancer",true,false).nodes["talent.bladedancer.wet_stone"]
		var motion:=InputEventMouseMotion.new()
		motion.position=button.get_global_rect().get_center()
		root.push_input(motion,true)
		check(root.gui_get_hovered_control()==button,"Backdrop does not intercept hover")
		for pressed in [true,false]:
			var click:=InputEventMouseButton.new()
			click.position=motion.position
			click.button_index=MOUSE_BUTTON_LEFT
			click.pressed=pressed
			root.push_input(click,true)
		await settle()
		check(actual.ranked_build.rank_of("talent.bladedancer.wet_stone")==1,"Backdrop does not intercept allocation")
		screen._talent_overlay.hide()
		check(actual.ranked_build.configure(registry.trees["tree.assassin"],null,45,{}),"Empty secondary legal")
		actual._finish_rank_edit(true)
		await settle()
		check(screen.find_child("SecondaryTreePanel",true,false).find_child("TalentTreeBackdrop",true,false)==null,"Empty secondary unchanged")
	game.queue_free()
	await process_frame
	state.reset()
	print("PASS tree background/compact Subclass checks: ",checks)
	quit(1 if failed else 0)
