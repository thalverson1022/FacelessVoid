extends SceneTree
const SkillRenderer=preload("res://scripts/ui/skill_hover_panel.gd")
const Renderer=preload("res://scripts/ui/talent_hover_panel.gd")
class StressButton extends IconTooltipButton:
	var hover_scale:=1.0
	func _make_custom_tooltip(text: String) -> Object:
		if talent_hover_provider.is_valid(): return Renderer.build(self,talent_hover_provider.call(),hover_scale)
		if skill_hover_provider.is_valid(): return SkillRenderer.build(self,skill_hover_provider.call(),hover_scale)
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
	if node.name in ["TalentHover","SkillHover"]: return node
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
	await check_rich(popup,roundi(20*scale))
	assert(window.size.x<=root.size.x and window.size.y<=root.size.y,"Popup dimensions fit viewport")
	root.get_texture().get_image().save_png("res://reports/keyword_coding_visual/"+name+".png")
func fonts(node: Node,scale: float) -> void:
	if node is Label:
		if not node.has_meta("original_font_size"): node.set_meta("original_font_size",node.get_theme_font_size("font_size"))
		node.add_theme_font_size_override("font_size",roundi(node.get_meta("original_font_size")*scale))
	elif node is RichTextLabel:
		if not node.has_meta("original_font_size"): node.set_meta("original_font_size",node.get_theme_font_size("normal_font_size"))
		node.add_theme_font_size_override("normal_font_size",roundi(node.get_meta("original_font_size")*scale))
	for child in node.get_children(): fonts(child,scale)
func check_rich(node: Node,size: int) -> void:
	var bodies:=node.find_children("*","RichTextLabel",true,false)
	var heights:=[]
	for body in bodies:
		assert(body.get_theme_font_size("normal_font_size")==size,"Actual rich font stress size")
		assert(body.size.y+1>=body.get_content_height(),"Fitted height includes all wrapped lines")
		heights.append(body.size.y)
	await settle()
	for index in bodies.size(): assert(is_equal_approx(bodies[index].size.y,heights[index]),"Settled rich height remains stable")
func show_tree(screen,mode: String) -> void:
	if mode=="practice": screen._talent_overlay.show()
	else: screen._show_talent_overlay()
func hud_shot(screen,name: String,scale: float) -> void:
	var hud=screen.find_child("ActiveTalentsPanel",true,false)
	fonts(hud,scale)
	await settle()
	await check_rich(hud,roundi(13*scale))
	root.get_texture().get_image().save_png("res://reports/keyword_coding_visual/"+name+".png")
	captures.append({"name":name})
func find_skill(node: Node,id: String) -> IconTooltipButton:
	if node is IconTooltipButton and node.skill_hover_provider.is_valid() and node.skill_hover_provider.call().id==id: return node
	for child in node.get_children():
		var found:=find_skill(child,id)
		if found!=null: return found
	return null
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/keyword_coding_visual")
	var registry:=BuildContentRegistry.test_mode()
	var state=root.get_node("BuildState")
	var game=load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_contract_test_pressed(1234,45,"tree.bladedancer","tree.thief")
	var ranks:={"talent.bladedancer.wet_stone":5,"talent.bladedancer.weakness":5,"talent.bladedancer.fancy_footwork":2,"talent.bladedancer.precision_attacks":1}
	for mode in ["test","adventure","practice"]:
		if mode=="practice": game._show_training_room()
		else:
			state.is_test_mode=mode=="test"
			game._show_combat_screen()
		await settle()
		var screen=game._current_screen
		var actual=screen._state if mode=="practice" else state
		if mode=="practice":
			actual.set_primary_tree(registry.trees["tree.bladedancer"])
			actual.set_secondary_tree(registry.trees["tree.thief"])
		else:
			screen._contract_overlay.hide()
			screen._map_overlay.hide()
		assert(actual.ranked_build.configure(registry.trees["tree.bladedancer"],registry.trees["tree.thief"],45,ranks),"Legal Precision fixture")
		actual._finish_rank_edit(true)
		root.size=Vector2i(1280,720)
		await settle()
		show_tree(screen,mode)
		await settle()
		await shot(find(screen._talent_overlay,"buy:talent.bladedancer.precision_attacks"),mode+"-precision-attacks-1280-125",1.25)
		screen._talent_overlay.hide()
	SaveSystem.write_json("res://reports/keyword_coding_visual/geometry.json",{"captures":captures})
	game.queue_free()
	await process_frame
	state.reset()
	print("PASS Precision keyword actual captures: ",captures.size())
	quit()
