extends SceneTree
const Hover = preload("res://scripts/ui/skill_hover_formatter.gd")
const Renderer = preload("res://scripts/ui/skill_hover_panel.gd")
class StressButton extends IconTooltipButton:
	var hover_scale := 1.0
	func _make_custom_tooltip(text: String) -> Object:
		if skill_hover_provider.is_valid(): return Renderer.build(self,skill_hover_provider.call(),hover_scale)
		return super._make_custom_tooltip(text)
var cases: Array = []
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
func buttons(node: Node, id: String) -> Array:
	var result := []
	if node is IconTooltipButton and node.skill_hover_provider.is_valid() and node.skill_hover_provider.call().id==id: result.append(node)
	for child in node.get_children(): result.append_array(buttons(child,id))
	return result
func hover_panel(node: Node) -> Control:
	if node.name=="SkillHover": return node
	for child in node.get_children(true):
		var found:=hover_panel(child)
		if found!=null: return found
	return null
func scaled_button(button: IconTooltipButton, scale: float) -> void:
	var provider:=button.skill_hover_provider
	var icon:=button.tooltip_icon
	var plain:=button.tooltip_provider
	var text:=button.tooltip_text
	button.set_script(StressButton)
	button.skill_hover_provider=provider
	button.tooltip_icon=icon
	button.tooltip_provider=plain
	button.tooltip_text=text
	button.hover_scale=scale
func shot(button: IconTooltipButton, label: String, scale: float) -> void:
	scaled_button(button,scale)
	var motion:=InputEventMouseMotion.new()
	motion.position=Vector2(800,50)
	root.push_input(motion,true)
	await create_timer(0.15).timeout
	motion=InputEventMouseMotion.new()
	motion.position=button.get_global_rect().get_center()
	root.push_input(motion,true)
	await create_timer(0.8).timeout
	assert(root.gui_get_hovered_control()==button,"Actual surface hovered")
	var panel:=hover_panel(root)
	assert(panel!=null,"Actual engine tooltip visible")
	var window:=panel.get_window()
	cases.append({"name":label,"window_position":[window.position.x,window.position.y],"window_size":[window.size.x,window.size.y],"text":button._get_tooltip(Vector2.ZERO)})
	await settle()
	root.get_texture().get_image().save_png("res://reports/minimal_skill_hover/"+label+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/minimal_skill_hover")
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
		var actual_state=screen._state if mode=="practice" else state
		actual_state.set_locked(false)
		var registry:=BuildContentRegistry.test_mode()
		if mode=="practice":
			actual_state.set_primary_tree(registry.trees["tree.assassin"])
			actual_state.set_secondary_tree(registry.trees["tree.shadow"])
		var ranks:={"talent.assassin.quick_hands":5,"talent.assassin.precision":5,"talent.assassin.hastened_poison":2,"talent.shadow.blind_spot":5,"talent.shadow.snake_oil":4,"talent.shadow.coated_weapons":1,"talent.shadow.deception":2}
		assert(actual_state.ranked_build.configure(registry.trees["tree.assassin"],registry.trees["tree.shadow"],45,ranks))
		actual_state._finish_rank_edit(true)
		if mode!="practice":
			screen._contract_overlay.hide()
			screen._map_overlay.hide()
		var skills:={}
		for skill in actual_state.unlocked_skills(): skills[skill.id]=skill
		var ids:=["skill.venom_jab","skill.poison_vile","skill.virulent_poison"]
		var rotation: Array[Skill]=[skills[ids[0]],skills[ids[1]],skills[ids[2]]]
		actual_state.set_rotation(rotation)
		await settle()
		for width in [1280,1600,1920]:
			root.size=Vector2i(width,width*9/16)
			await settle()
			for scale in [1.0,1.25]:
				for id in ids:
					# Palette is the actual second center-column panel.
					var palette=screen._skill_build_panel.get_parent().get_child(1)
					var button: IconTooltipButton=buttons(palette,id)[0]
					await shot(button,"%s-palette-%s-%d-%d" % [mode,id.replace("skill.",""),width,roundi(scale*100)],scale)
		root.size=Vector2i(1280,720)
		await settle()
		for i in 3:
			await shot(screen._skill_build_panel._slot_buttons[i],"%s-macro-%s-1280-125" % [mode,ids[i].replace("skill.","")],1.25)
		for id in ["skill.killers_mark","skill.touch_of_darkness"]:
			var palette=screen._skill_build_panel.get_parent().get_child(1)
			await shot(buttons(palette,id)[0],"%s-basic-%s-1280-125" % [mode,id.replace("skill.","")],1.25)
		if mode=="practice": screen._talent_overlay.show()
		else: screen._show_talent_overlay()
		await settle()
		for id in ids:
			await shot(buttons(screen._talent_overlay,id)[0],"%s-tree-%s-1280-125" % [mode,id.replace("skill.","")],1.25)
		screen._talent_overlay.hide()
	SaveSystem.write_json("res://reports/minimal_skill_hover/geometry.json",{"cases":cases})
	game.queue_free()
	await process_frame
	state.reset()
	print("PASS actual minimal skill hover renders: ",cases.size())
	quit()
