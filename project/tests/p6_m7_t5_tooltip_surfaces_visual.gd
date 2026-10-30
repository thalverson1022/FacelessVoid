extends SceneTree
const View = preload("res://scripts/ui/ranked_talent_view.gd")
class EnlargedButton extends IconTooltipButton:
	func _make_custom_tooltip(text: String) -> Object:
		var panel = super._make_custom_tooltip(text)
		var row = panel.get_child(0)
		row.get_child(row.get_child_count()-1).add_theme_font_size_override("font_size",28)
		return panel
var failed := false
var cases: Array = []
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
func capture(name: String) -> void:
	await settle()
	root.get_texture().get_image().save_png("res://reports/t5_surfaces/"+name+".png")
func show_component(button: IconTooltipButton, text: String, name: String) -> void:
	var popup: Control = button._make_custom_tooltip(text)
	root.add_child(popup)
	popup.position = Vector2(32,60)
	var row = popup.get_child(0)
	var label: Label = row.get_child(row.get_child_count()-1)
	label.add_theme_font_size_override("font_size",28)
	await settle()
	var rect := popup.get_global_rect()
	cases.append({"name":name,"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"fits":rect.end.x<=root.size.x and rect.end.y<=root.size.y})
	if rect.end.y>root.size.y or rect.end.x>root.size.x: failed=true
	await capture(name)
	popup.queue_free()
	await settle()
func enlarge_live_button(button: IconTooltipButton) -> void:
	var art := button.tooltip_icon
	var provider := button.tooltip_provider
	var text := button.tooltip_text
	button.set_script(EnlargedButton)
	button.tooltip_icon = art
	button.tooltip_provider = provider
	button.tooltip_text = text
func find_action(node: Node, key: String) -> Control:
	if node.get_meta("action_key", "") == key: return node
	for child in node.get_children():
		var found := find_action(child,key)
		if found != null: return found
	return null
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/t5_surfaces")
	root.size = Vector2i(1280,720)
	var state = root.get_node("BuildState")
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._on_contract_test_pressed(1234,45,"tree.shadow","tree.thief")
	await settle()
	var screen = game._current_screen
	screen._contract_overlay.hide()
	screen._map_overlay.hide()
	var registry := BuildContentRegistry.test_mode()
	var skills := {}
	for tree in registry.trees.values():
		for unlock in tree.automatic_unlocks:
			if unlock.skill!=null: skills[unlock.skill.id]=unlock.skill
	var button := EnlargedButton.new()
	button.position=root.get_visible_rect().size-Vector2(60,65)
	button.size=Vector2(48,48)
	root.add_child(button)
	for id in ["skill.killers_mark","skill.mug","skill.pick_pocket","skill.big_score","skill.virulent_poison","skill.touch_of_darkness","skill.beguiling_presence"]:
		button.tooltip_icon=skills[id].icon
		await show_component(button,SkillTooltipFormatter.compact_tooltip(skills[id],state),id.replace(".","_")+"-125")
	var view = View.new()
	view.state=state
	for id in ["talent.shadow.shadow_mastery","talent.shadow.death_touch","talent.assassin.toxic_tradeoff","talent.bladedancer.fancy_footwork","talent.keen_eye"]:
		var talent: Talent=registry.talents[id]
		button.tooltip_icon=talent.icon
		await show_component(button,view.talent_tooltip(talent),id.replace(".","_")+"-125")

	var shadow: SubclassTree=registry.trees["tree.shadow"]
	var thief: SubclassTree=registry.trees["tree.thief"]
	var ranks := {"talent.shadow.blind_spot":5,"talent.shadow.snake_oil":4,"talent.shadow.coated_weapons":1,"talent.shadow.deception":5,"talent.shadow.shadow_mastery":4,"talent.keen_eye":5,"talent.sticky_fingers":5,"talent.thief.fast_hands":2}
	assert(state.ranked_build.configure(shadow,thief,45,ranks), "Legal invested tooltip fixture")
	state._finish_rank_edit(true)
	var mastery: Talent=registry.talents["talent.shadow.shadow_mastery"]
	var mastery_text: String=view.talent_tooltip(mastery)
	assert(mastery_text.contains("Current:") and mastery_text.contains("Next:"))
	button.tooltip_icon=mastery.icon
	await show_component(button,mastery_text,"shadow-mastery-current4-next5-125")

	screen._show_talent_overlay()
	await settle()
	var live_mastery := find_action(screen._talent_overlay,"buy:talent.shadow.shadow_mastery")
	assert(live_mastery!=null)
	enlarge_live_button(live_mastery)
	var live_motion:=InputEventMouseMotion.new()
	live_motion.position=live_mastery.get_global_rect().get_center()
	root.push_input(live_motion,true)
	await create_timer(1.0).timeout
	await capture("live-tree-mastery-current4-next5-hover-125")
	screen._talent_overlay.hide()
	var rotation: Array[Skill]=[skills["skill.killers_mark"],skills["skill.mug"],skills["skill.pick_pocket"],skills["skill.big_score"]]
	state.set_rotation(rotation)
	assert(state.rotation.size()==4,"Unlocked four-skill live macro")
	await settle()
	var live_macro: IconTooltipButton=screen._skill_build_panel._slot_buttons[2]
	enlarge_live_button(live_macro)
	live_motion.position=live_macro.get_global_rect().get_center()
	root.push_input(live_motion,true)
	await create_timer(1.0).timeout
	await capture("live-macro-pick-pocket-hover-125")
	button.tooltip_text=mastery_text
	button.position=root.get_visible_rect().size-Vector2(60,65)
	var exit_motion:=InputEventMouseMotion.new()
	exit_motion.position=Vector2(700,500)
	root.push_input(exit_motion,true)
	await create_timer(0.2).timeout
	var mastery_motion:=InputEventMouseMotion.new()
	mastery_motion.position=button.position+Vector2(20,20)
	root.push_input(mastery_motion,true)
	await create_timer(1.0).timeout
	await capture("engine-hover-mastery-current4-next5-bottom-right-125")
	# Engine-controlled popup positioned at the bottom-right screen edge.
	button.tooltip_text=SkillTooltipFormatter.compact_tooltip(skills["skill.pick_pocket"],state)
	button.tooltip_icon=skills["skill.pick_pocket"].icon
	var motion := InputEventMouseMotion.new()
	motion.position=button.position+Vector2(20,20)
	motion.global_position=motion.position
	root.push_input(motion,true)
	await create_timer(1.0).timeout
	print("Hovered: ",root.gui_get_hovered_control())
	await capture("engine-hover-bottom-right-1280")
	# Review the actual live tree controls for all four trees.
	for pair in [["tree.shadow","tree.assassin"],["tree.bladedancer","tree.thief"]]:
		game._on_contract_test_pressed(1234,45,pair[0],pair[1])
		await settle()
		screen=game._current_screen
		screen._contract_overlay.hide()
		screen._map_overlay.hide()
		screen._show_talent_overlay()
		await capture("tree-"+pair[0].replace(".","_")+"-"+pair[1].replace(".","_"))
		screen._talent_overlay.hide()
	var effects:=CombatEffectIcons.new()
	root.add_child(effects)
	effects.model.running=true
	effects.model.time_ms=1000
	var snapshots := {
		"footwork": {"source":"talent.bladedancer.fancy_footwork","units":2,"magnitude":0.16,"unit":"stacks","expires_at_ms":4000},
		"readiness": {"source":"skill.parry_strike","units":1,"unit":"charges","expires_at_ms":-1},
		"precision": {"source":"talent.bladedancer.precision_attacks","units":1,"unit":"charges","expires_at_ms":-1},
		"dance": {"source":"skill.dance_of_death","units":1,"unit":"charges","expires_at_ms":6000},
		"bypass": {"source":"talent.assassin.bypass","units":2,"magnitude":0.2,"unit":"stacks","expires_at_ms":4000},
		"virulent_poison": {"source":"skill.virulent_poison","charges":5,"expires_at_ms":-1},
		"master_of_poisons": {"source":"skill.master_of_poisons","charges":0,"expires_at_ms":6000},
		"touch_of_darkness": {"source":"skill.touch_of_darkness","units":2,"magnitude":0.2,"unit":"stacks","expires_at_ms":13000},
		"beguiling_presence": {"source":"skill.beguiling_presence","units":2,"magnitude":2.0,"crit_chance_bonus":0.04,"unit":"Decay stacks absorbed","expires_at_ms":11000},
		"greed": {"source":"combat.theft","units":2,"unit":"stacks","expires_at_ms":-1},
	}
	for id in snapshots:
		effects.active[id]={"id":"buff."+id,"source":snapshots[id].source,"state":snapshots[id]}
	for id in ["penetration","potency"]:
		effects.active[id]={"id":"status."+id,"source":"talent.shadow.death_pact","state":{"units":2,"unit":"stacks","expires_at_ms":5000}}
	effects._render()
	effects._open_inspector()
	effects._details.add_theme_font_size_override("normal_font_size",25)
	await capture("effect-inspector-125")
	effects._details.scroll_to_line(1000)
	await capture("effect-inspector-bottom-125")
	effects._dialog.hide()
	SaveSystem.write_json("res://reports/t5_surfaces/geometry.json",{"cases":cases})
	view.free()
	button.queue_free()
	effects.queue_free()
	game.queue_free()
	await process_frame
	state.reset()
	print("PASS T5 tooltip surfaces" if not failed else "FAILED T5 long tooltip clipping")
	quit(1 if failed else 0)
