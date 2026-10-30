extends SceneTree
const TalentPanel=preload("res://scripts/ui/talent_hover_panel.gd")
class StressButton extends IconTooltipButton:
	func _make_custom_tooltip(text: String) -> Object:
		if talent_hover_provider.is_valid(): return TalentPanel.build(self,talent_hover_provider.call(),1.25)
		return super._make_custom_tooltip(text)
var captures:=[]
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
func capture(name: String) -> void:
	await settle()
	root.get_texture().get_image().save_png("res://reports/tree_background_visual/"+name+".png")
	captures.append(name)
func fonts(node: Node,scale: float) -> void:
	if node is Label:
		if not node.has_meta("original_font_size"): node.set_meta("original_font_size",node.get_theme_font_size("font_size"))
		node.add_theme_font_size_override("font_size",roundi(node.get_meta("original_font_size")*scale))
	for child in node.get_children(): fonts(child,scale)
func stress_hover(button: IconTooltipButton,name: String) -> void:
	var art:=button.tooltip_icon
	var talent:=button.talent_hover_provider
	var skill:=button.skill_hover_provider
	var text:=button.tooltip_text
	var plain:=button.tooltip_provider
	button.set_script(StressButton)
	button.tooltip_icon=art
	button.talent_hover_provider=talent
	button.skill_hover_provider=skill
	button.tooltip_text=text
	button.tooltip_provider=plain
	var motion:=InputEventMouseMotion.new()
	motion.position=Vector2(30,30)
	root.push_input(motion,true)
	await create_timer(0.1).timeout
	motion=InputEventMouseMotion.new()
	motion.position=button.get_global_rect().get_center()
	root.push_input(motion,true)
	await create_timer(0.75).timeout
	assert(root.gui_get_hovered_control()==button)
	await capture(name)
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/tree_background_visual")
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
		for pair in [["tree.assassin","tree.shadow"],["tree.bladedancer","tree.thief"]]:
			if mode=="practice":
				actual.set_primary_tree(registry.trees[pair[0]])
				actual.set_secondary_tree(registry.trees[pair[1]])
			var ranks:={"talent.assassin.quick_hands":5,"talent.assassin.precision":3,"talent.assassin.hastened_poison":5,"talent.assassin.echoing_toxin":1,"talent.assassin.poison_strike":1,"talent.assassin.toxic_tradeoff":2,"talent.assassin.bypass":1,"talent.shadow.blind_spot":5,"talent.shadow.snake_oil":4,"talent.shadow.coated_weapons":1,"talent.shadow.deception":5,"talent.shadow.shadow_mastery":4}
			if pair[0]=="tree.bladedancer":
				ranks={"talent.bladedancer.wet_stone":5,"talent.bladedancer.rending_slash":1,"talent.bladedancer.fancy_footwork":2,"talent.bladedancer.weakness":5,"talent.bladedancer.opportunity":2,"talent.bladedancer.cloak_and_dagger":2,"talent.keen_eye":5,"talent.sticky_fingers":5,"talent.thief.fast_hands":2,"talent.thief.charisma":2,"talent.thief.silvered_edge":1}
			assert(actual.ranked_build.configure(registry.trees[pair[0]],registry.trees[pair[1]],45,ranks))
			actual._finish_rank_edit(true)
			await settle()
			var hud=screen.find_child("ActiveTalentsPanel",true,false)
			var name: String=pair[0].trim_prefix("tree.")+"-"+pair[1].trim_prefix("tree.")
			for width in [1280,1600,1920]:
				root.size=Vector2i(width,width*9/16)
				await settle()
				for scale in [1.0,1.25]:
					fonts(hud,scale)
					await capture("%s-active-%s-%d-%d" % [mode,name,width,roundi(scale*100)])
					if mode=="practice": screen._talent_overlay.show()
					else: screen._show_talent_overlay()
					fonts(screen._talent_overlay,scale)
					await capture("%s-trees-%s-%d-%d" % [mode,name,width,roundi(scale*100)])
					screen._talent_overlay.hide()
			root.size=Vector2i(1280,720)
			await settle()
			if mode=="practice": screen._talent_overlay.show()
			else: screen._show_talent_overlay()
			await settle()
			var view=screen._talent_panel._ranked_view if mode=="practice" else screen._talent_overlay._talent_panel._ranked_view
			var id: String="talent.shadow.shadow_mastery" if pair[0]=="tree.assassin" else "talent.bladedancer.fancy_footwork"
			await stress_hover(view.actions["buy:"+id],"%s-hover-%s-1280-125" % [mode,name])
			screen._talent_overlay.hide()
			assert(actual.ranked_build.configure(registry.trees[pair[1]],registry.trees[pair[0]],45,ranks))
			actual._finish_rank_edit(true)
			await settle()
			if mode=="practice": screen._talent_overlay.show()
			else: screen._show_talent_overlay()
			await capture("%s-swapped-%s-1280" % [mode,name])
			screen._talent_overlay.hide()
		assert(actual.ranked_build.configure(registry.trees["tree.assassin"],null,45,{}))
		actual._finish_rank_edit(true)
		await settle()
		if mode=="practice": screen._talent_overlay.show()
		else: screen._show_talent_overlay()
		await capture("%s-empty-secondary-1280" % mode)
		screen._talent_overlay.hide()
	SaveSystem.write_json("res://reports/tree_background_visual/captures.json",{"captures":captures})
	game.queue_free()
	await process_frame
	state.reset()
	print("PASS tree backgrounds/current Active Talents rendered captures: ",captures.size())
	quit()
