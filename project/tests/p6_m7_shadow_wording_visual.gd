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
	root.get_texture().get_image().save_png("res://reports/shadow_wording_visual/"+name+".png")
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
func find_skill(node: Node,id: String) -> IconTooltipButton:
	if node is IconTooltipButton and node.skill_hover_provider.is_valid() and node.skill_hover_provider.call().id==id: return node
	for child in node.get_children():
		var found:=find_skill(child,id)
		if found!=null: return found
	return null
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/shadow_wording_visual")
	var registry:=BuildContentRegistry.test_mode()
	var state=root.get_node("BuildState")
	var game=load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_contract_test_pressed(1234,45,"tree.shadow","tree.assassin")
	var ranks:={"talent.shadow.blind_spot":5,"talent.shadow.snake_oil":4,"talent.shadow.coated_weapons":1,"talent.shadow.deception":4,"talent.shadow.death_from_the_shadows":1,"talent.shadow.death_touch":2,"talent.shadow.death_pact":2,"talent.shadow.death_blade":1,"talent.shadow.dusk_strike":1,"talent.shadow.shadow_mastery":4,"talent.umbral_pressure":1}
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
			actual.set_primary_tree(registry.trees["tree.shadow"])
			actual.set_secondary_tree(registry.trees["tree.assassin"])
		for property in ["equipped_weapon","equipped_helm","equipped_armor","equipped_charm","equipped_trinket"]: actual.set(property,null)
		assert(actual.ranked_build.configure(registry.trees["tree.shadow"],registry.trees["tree.assassin"],45,ranks),"Legal Shadow fixture")
		actual._finish_rank_edit(true)
		await settle()
		root.size=Vector2i(1280,720)
		var hud=screen.find_child("ActiveTalentsPanel",true,false)
		fonts(hud,1.25)
		await capture(mode+"-active-shadow-1280-125")
		for id in ["skill.toxic_flurry","skill.killers_mark","skill.distilled_corruption","skill.touch_of_darkness","skill.beguiling_presence"]:
			var button:=find_skill(screen._skill_build_panel.get_parent().get_child(1),id)
			assert(button!=null,"Actual Shadow palette skill "+id)
			await stress_hover(button,mode+"-"+id.trim_prefix("skill.")+"-1280-125")
		var dynamic_ranks:=ranks.duplicate()
		dynamic_ranks.erase("talent.shadow.death_touch")
		assert(actual.ranked_build.configure(registry.trees["tree.shadow"],registry.trees["tree.assassin"],45,dynamic_ranks))
		actual._finish_rank_edit(true)
		var gear:=GearItem.new()
		gear.id="test.dynamic_stack_weapon"
		gear.display_name="Dynamic stack fixture"
		var bonus:=StatModifier.new()
		bonus.stat_id="increased_all_stacks"
		bonus.value=2
		gear.affixes=[bonus]
		for stage in 4:
			if stage==1:
				if mode=="practice": actual.equip_legendary(gear)
				else: actual.equip(gear)
			elif stage==2:
				dynamic_ranks["talent.shadow.death_touch"]=2
				assert(actual.ranked_build.configure(registry.trees["tree.shadow"],registry.trees["tree.assassin"],45,dynamic_ranks))
				actual._finish_rank_edit(true)
			elif stage==3:
				var doubled:=StatModifier.new()
				doubled.stat_id="double_applied_stacks"
				doubled.value=1
				gear.affixes.append(doubled)
				if mode=="practice": actual.equip_legendary(gear)
				else: actual.equip(gear)
			await settle()
			var maximum: int=[5,7,13,26][stage]
			var button:=find_skill(screen._skill_build_panel.get_parent().get_child(1),"skill.distilled_corruption")
			assert(button.skill_hover_provider.call().effect=="Consume up to 5 stacks of Decay to apply up to %d stacks of Poison" % maximum,"Live Distilled refresh")
			await stress_hover(button,"%s-distilled-refresh-%d-1280-125" % [mode,maximum])
		if mode=="practice": screen._talent_overlay.show()
		else: screen._show_talent_overlay()
		await settle()
		fonts(screen._talent_overlay,1.25)
		for width in [1280,1600,1920]:
			root.size=Vector2i(width,width*9/16)
			await capture("%s-shadow-primary-%d-125" % [mode,width])
		root.size=Vector2i(1280,720)
		await settle()
		var view=screen._talent_panel._ranked_view if mode=="practice" else screen._talent_overlay._talent_panel._ranked_view
		for id in ["talent.shadow.coated_weapons","talent.shadow.deception","talent.shadow.death_touch","talent.shadow.death_pact","talent.shadow.death_blade","talent.shadow.dusk_strike","talent.shadow.shadow_mastery","talent.umbral_pressure"]:
			await stress_hover(view.actions["buy:"+id],mode+"-"+id.get_slice(".",id.get_slice_count(".")-1)+"-1280-125")
		screen._talent_overlay.hide()
		assert(actual.ranked_build.configure(registry.trees["tree.assassin"],registry.trees["tree.shadow"],45,ranks))
		actual._finish_rank_edit(true)
		await settle()
		if mode=="practice": screen._talent_overlay.show()
		else: screen._show_talent_overlay()
		await capture(mode+"-shadow-secondary-1280-125")
		screen._talent_overlay.hide()
	SaveSystem.write_json("res://reports/shadow_wording_visual/captures.json",{"captures":captures})
	game.queue_free()
	await process_frame
	state.reset()
	print("PASS Shadow wording actual captures: ",captures.size())
	quit()
