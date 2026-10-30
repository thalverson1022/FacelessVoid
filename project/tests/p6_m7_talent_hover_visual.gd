extends SceneTree
const Renderer=preload("res://scripts/ui/talent_hover_panel.gd")
class StressButton extends IconTooltipButton:
	var hover_scale:=1.0
	func _make_custom_tooltip(text: String) -> Object:
		if talent_hover_provider.is_valid(): return Renderer.build(self,talent_hover_provider.call(),hover_scale)
		return super._make_custom_tooltip(text)
var captures: Array=[]
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in 7: await process_frame
	await RenderingServer.frame_post_draw
func find(node: Node,key: String) -> IconTooltipButton:
	if node is IconTooltipButton and node.get_meta("action_key","")==key: return node
	for child in node.get_children():
		var found:=find(child,key)
		if found!=null: return found
	return null
func panel(node: Node) -> Control:
	if node.name=="TalentHover": return node
	for child in node.get_children(true):
		var found:=panel(child)
		if found!=null: return found
	return null
func shot(button: IconTooltipButton,name: String,scale: float) -> void:
	var icon:=button.tooltip_icon
	var talent:=button.talent_hover_provider
	var skill:=button.skill_hover_provider
	var text:=button.tooltip_text
	var plain:=button.tooltip_provider
	button.set_script(StressButton)
	button.tooltip_icon=icon
	button.talent_hover_provider=talent
	button.skill_hover_provider=skill
	button.tooltip_text=text
	button.tooltip_provider=plain
	button.hover_scale=scale
	var motion:=InputEventMouseMotion.new()
	motion.position=Vector2(40,40)
	root.push_input(motion,true)
	await create_timer(0.1).timeout
	motion=InputEventMouseMotion.new()
	motion.position=button.get_global_rect().get_center()
	root.push_input(motion,true)
	await create_timer(0.75).timeout
	assert(root.gui_get_hovered_control()==button,"Live talent hovered")
	var popup:=panel(root)
	assert(popup!=null,"Engine talent popup visible")
	var window:=popup.get_window()
	captures.append({"name":name,"text":button._get_tooltip(Vector2.ZERO),"window_position":[window.position.x,window.position.y],"window_size":[window.size.x,window.size.y]})
	await settle()
	root.get_texture().get_image().save_png("res://reports/talent_hover_visual/"+name+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/talent_hover_visual")
	var registry:=BuildContentRegistry.test_mode()
	var state=root.get_node("BuildState")
	var game=load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_contract_test_pressed(1234,45,"tree.assassin","tree.shadow")
	await settle()
	for mode in ["test","adventure","practice"]:
		if mode=="practice": game._show_training_room()
		else:
			state.is_test_mode=mode=="test"
			game._show_combat_screen()
		await settle()
		var screen=game._current_screen
		var actual=screen._state if mode=="practice" else state
		if mode!="practice":
			screen._contract_overlay.hide()
			screen._map_overlay.hide()
		var pair:=["tree.assassin","tree.shadow"]
		if mode=="practice":
			actual.set_primary_tree(registry.trees[pair[0]])
			actual.set_secondary_tree(registry.trees[pair[1]])
		var ranks:={"talent.assassin.quick_hands":5,"talent.assassin.precision":3,"talent.assassin.hastened_poison":5,"talent.assassin.echoing_toxin":1,"talent.assassin.poison_strike":1,"talent.assassin.toxic_tradeoff":2,"talent.assassin.bypass":1,"talent.shadow.blind_spot":5,"talent.shadow.snake_oil":4,"talent.shadow.coated_weapons":1,"talent.shadow.deception":5,"talent.shadow.shadow_mastery":4}
		assert(actual.ranked_build.configure(registry.trees[pair[0]],registry.trees[pair[1]],45,ranks),"Legal partial/max fixture")
		actual._finish_rank_edit(true)
		await settle()
		if mode=="practice": screen._talent_overlay.show()
		else: screen._show_talent_overlay()
		await settle()
		for width in [1280,1600,1920]:
			root.size=Vector2i(width,width*9/16)
			await settle()
			for scale in [1.0,1.25]:
				for id in ["talent.assassin.precision","talent.assassin.toxic_tradeoff","talent.shadow.shadow_mastery"]:
					await shot(find(screen._talent_overlay,"buy:"+id),"%s-%s-%d-%d" % [mode,id.get_slice(".",2),width,roundi(scale*100)],scale)
		root.size=Vector2i(1280,720)
		await settle()
		for id in ["talent.assassin.quick_hands","talent.assassin.poison_strike","talent.assassin.echoing_toxin"]:
			await shot(find(screen._talent_overlay,"buy:"+id),"%s-state-%s-1280-125" % [mode,id.get_slice(".",2)],1.25)
		screen._talent_overlay.hide()
		assert(actual.ranked_build.configure(registry.trees[pair[0]],registry.trees[pair[1]],45,{}))
		actual._finish_rank_edit(true)
		await settle()
		if mode=="practice": screen._talent_overlay.show()
		else: screen._show_talent_overlay()
		await settle()
		await shot(find(screen._talent_overlay,"buy:talent.shadow.shadow_mastery"),"%s-requires-shadow-mastery-1280-125" % mode,1.25)
		screen._talent_overlay.hide()
		pair=["tree.bladedancer","tree.thief"]
		if mode=="practice":
			actual.set_primary_tree(registry.trees[pair[0]])
			actual.set_secondary_tree(registry.trees[pair[1]])
		ranks={"talent.bladedancer.wet_stone":5,"talent.bladedancer.rending_slash":1,"talent.bladedancer.fancy_footwork":2,"talent.bladedancer.weakness":5,"talent.bladedancer.opportunity":2,"talent.bladedancer.cloak_and_dagger":2,"talent.keen_eye":5,"talent.sticky_fingers":5,"talent.thief.fast_hands":2,"talent.thief.charisma":2,"talent.thief.silvered_edge":1}
		assert(actual.ranked_build.configure(registry.trees[pair[0]],registry.trees[pair[1]],45,ranks),"Legal Bladedancer/Thief fixture")
		actual._finish_rank_edit(true)
		await settle()
		if mode=="practice": screen._talent_overlay.show()
		else: screen._show_talent_overlay()
		await settle()
		for width in [1280,1600,1920]:
			root.size=Vector2i(width,width*9/16)
			await settle()
			for id in ["talent.bladedancer.fancy_footwork","talent.thief.silvered_edge"]:
				await shot(find(screen._talent_overlay,"buy:"+id),"%s-%s-%d-125" % [mode,id.get_slice(".",2),width],1.25)
		screen._talent_overlay.hide()
	SaveSystem.write_json("res://reports/talent_hover_visual/geometry.json",{"captures":captures})
	game.queue_free()
	await process_frame
	state.reset()
	print("PASS compact talent actual hover captures: ",captures.size())
	quit()
