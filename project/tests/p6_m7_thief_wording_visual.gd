extends SceneTree
const SkillPanel=preload("res://scripts/ui/skill_hover_panel.gd")
const TalentPanel=preload("res://scripts/ui/talent_hover_panel.gd")
class StressButton extends IconTooltipButton:
	func _make_custom_tooltip(text: String) -> Object:
		if talent_hover_provider.is_valid(): return TalentPanel.build(self,talent_hover_provider.call(),1.25)
		if skill_hover_provider.is_valid(): return SkillPanel.build(self,skill_hover_provider.call(),1.25)
		return super._make_custom_tooltip(text)
var captures:=[]
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
func capture(name: String) -> void:
	await settle()
	root.get_texture().get_image().save_png("res://reports/thief_wording_visual/"+name+".png")
	captures.append(name)
func fonts(node: Node,scale: float) -> void:
	if node is Label:
		if not node.has_meta("original_font_size"): node.set_meta("original_font_size",node.get_theme_font_size("font_size"))
		node.add_theme_font_size_override("font_size",roundi(node.get_meta("original_font_size")*scale))
	elif node is RichTextLabel:
		if not node.has_meta("original_font_size"): node.set_meta("original_font_size",node.get_theme_font_size("normal_font_size"))
		node.add_theme_font_size_override("normal_font_size",roundi(node.get_meta("original_font_size")*scale))
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
func find_skill(node: Node,id: String) -> IconTooltipButton:
	if node is IconTooltipButton and node.skill_hover_provider.is_valid() and node.skill_hover_provider.call().id==id: return node
	for child in node.get_children():
		var found:=find_skill(child,id)
		if found!=null: return found
	return null
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/thief_wording_visual")
	var registry:=BuildContentRegistry.test_mode()
	var state=root.get_node("BuildState")
	var game=load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_contract_test_pressed(1234,45,"tree.thief","tree.bladedancer")
	var ranks:={"talent.keen_eye":5,"talent.sticky_fingers":5,"talent.thief.fast_hands":4,"talent.thief.fill_your_pockets":4,"talent.thief.charisma":3,"talent.thief.load_dice":1,"talent.gilded_blade":1,"talent.thief.bribery":1,"talent.thief.finders_keepers":1,"talent.thief.silvered_edge":1}
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
		else:
			actual.set_primary_tree(registry.trees["tree.thief"])
			actual.set_secondary_tree(registry.trees["tree.bladedancer"])
		assert(actual.ranked_build.configure(registry.trees["tree.thief"],registry.trees["tree.bladedancer"],45,ranks),"Legal Thief fixture")
		actual._finish_rank_edit(true)
		await settle()
		root.size=Vector2i(1280,720)
		var hud=screen.find_child("ActiveTalentsPanel",true,false)
		fonts(hud,1.25)
		await capture(mode+"-active-thief-1280-125")
		for id in ["skill.pick_pocket","skill.mug","skill.steal","skill.big_score"]:
			var button:=find_skill(screen._skill_build_panel.get_parent().get_child(1),id)
			assert(button!=null,"Actual Thief palette skill "+id)
			if id=="skill.pick_pocket":
				var data: Dictionary=button.skill_hover_provider.call()
				assert(data.duration=="" and data.cooldown!="","Pick Pocket retains only cooldown")
			await stress_hover(button,mode+"-"+id.trim_prefix("skill.")+"-1280-125")
		if mode=="practice": screen._talent_overlay.show()
		else: screen._show_talent_overlay()
		await settle()
		fonts(screen._talent_overlay,1.25)
		for width in [1280,1600,1920]:
			root.size=Vector2i(width,width*9/16)
			await capture("%s-thief-primary-%d-125" % [mode,width])
		root.size=Vector2i(1280,720)
		await settle()
		var view=screen._talent_panel._ranked_view if mode=="practice" else screen._talent_overlay._talent_panel._ranked_view
		for id in ["talent.thief.fast_hands","talent.thief.fill_your_pockets","talent.gilded_blade","talent.thief.bribery","talent.thief.finders_keepers","talent.thief.silvered_edge"]:
			await stress_hover(view.actions["buy:"+id],mode+"-"+id.get_slice(".",id.get_slice_count(".")-1)+"-1280-125")
		screen._talent_overlay.hide()
		assert(actual.ranked_build.configure(registry.trees["tree.bladedancer"],registry.trees["tree.thief"],45,ranks))
		actual._finish_rank_edit(true)
		await settle()
		if mode=="practice": screen._talent_overlay.show()
		else: screen._show_talent_overlay()
		await capture(mode+"-thief-secondary-1280-125")
		screen._talent_overlay.hide()
	SaveSystem.write_json("res://reports/thief_wording_visual/captures.json",{"captures":captures})
	game.queue_free()
	await process_frame
	state.reset()
	print("PASS Thief wording actual captures: ",captures.size())
	quit()
