extends SceneTree
const Core = preload("res://tests/fixtures/p6/bladedancer_core/core.gd")
const Presentation = preload("res://scripts/ui/combat_presentation_state.gd")
var failed := false
var visual := false

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if not ok:
		failed = true
		printerr("FAILED: " + label)

func capture(label: String) -> void:
	if not visual: return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/p6_macro_readiness/" + label + ".png")

func _run() -> void:
	visual = "--visual" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute("res://reports/p6_macro_readiness")
	var registry := BuildContentRegistry.test_mode()
	var state := TrainingRoomState.new()
	state.practice_save_path = "res://reports/p6_macro_readiness/practice.json"
	state.content_registry = registry
	state.set_class(registry.classes["class.rogue"])
	state.configure_ranked_build(registry.trees["tree.bladedancer"])
	for id in Core.RANKS:
		for rank in Core.RANKS[id]: state.select_talent(registry.talents[id])
	var resolved := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"], state.ranked_build)
	var parry: Skill
	var stab: Skill
	for skill in resolved.skills:
		if skill.id == "skill.parry_strike": parry = skill
		if skill.id == "skill.stab": stab = skill
	state.set_rotation([parry, stab, parry])
	var panel = load("res://scenes/combat/skill_build_panel.tscn").instantiate()
	panel.state = state
	root.add_child(panel)
	panel.position = Vector2(40,40)
	panel.size = Vector2(760,160)
	await process_frame
	for index in [0,2]:
		check(panel._slot_buttons[index].modulate == panel.UNAVAILABLE_SLOT_MODULATE and panel._slot_buttons[index].get_node("SkillIcon").material.get_shader_parameter("grayscale") == true, "Every Parry starts gray without Readiness")
	check(panel._slot_buttons[1].modulate == Color.WHITE and not panel._slot_buttons[0].disabled, "Other skills and macro editing unaffected")
	await capture("no-readiness")
	var enemy := Monster.new()
	enemy.hp = 1000000
	var result := CombatResolver.resolve(Core.rotation(resolved.skills),resolved.stats,enemy,20000,7)
	check(result.is_valid,"Actual core combat resolves")
	var model := Presentation.new()
	model.begin(result)
	var saw_ready := false
	var saw_spent := false
	for record in result.trace.presentation_records:
		if int(record.time_ms) < model.time_ms: continue
		model.advance_to(int(record.time_ms))
		panel.update_presentation(model)
		var ready := model.units("buff.readiness") > 0
		for index in [0,2]:
			var spending: bool = int(model.attempt.get("rotation_index",-1)) == index and model.time_ms < int(model.attempt.get("end_ms",0)) and int(model.attempt.get("lifecycle",{}).get("readiness_consumed",0)) > 0
			check((panel._slot_buttons[index].modulate == Color.WHITE) == (ready or spending), "Parry follows charge or accepted cast at each replay boundary")
		if ready and not saw_ready:
			saw_ready = true
			panel._refresh()
			check(panel._slot_buttons[0].modulate == Color.WHITE, "Build redraw retains live availability")
			await capture("readiness-ready")
			panel.play_stun_effect(1000,true)
			check(panel._slot_buttons[0].modulate == panel.STUNNED_SLOT_MODULATE,"Stun still dims ready Parry")
			panel.clear_stun_effect()
			check(panel._slot_buttons[0].modulate == Color.WHITE,"Clearing stun restores ready Parry")
		if saw_ready and not ready and not saw_spent:
			saw_spent = true
			await capture("readiness-spent")
	check(saw_ready and saw_spent,"Actual replay includes grant and consumption")
	panel.clear_presentation()
	panel.clear_stun_effect()
	check(panel._slot_buttons[0].modulate == panel.UNAVAILABLE_SLOT_MODULATE,"Finish/stun cleanup leaves Parry unavailable")
	model.begin(result)
	panel.update_presentation(model)
	check(panel._slot_buttons[0].modulate == panel.UNAVAILABLE_SLOT_MODULATE,"Retry begins with no charge")
	panel._on_slot_pressed(0)
	panel._remove_selected()
	check(state.rotation.size()==2 and state.rotation[1].id==parry.id,"Unavailable Parry remains removable from macro")
	# User sequence: Precision from Quick Cut, Stab repeats, then Parry spends
	# that Readiness at the exact timestamp it was granted. No idle charge frame.
	check(state.select_talent(registry.talents["talent.bladedancer.precision_attacks"]), "Allocate actual Precision talent")
	resolved = BuildResolver.resolve_ranked_build(registry.classes["class.rogue"],state.ranked_build)
	var quick: Skill
	for skill in resolved.skills:
		if skill.id == "skill.quick_cut": quick = skill
	state.set_rotation([quick,stab,parry,parry])
	result = CombatResolver.resolve(state.rotation,resolved.stats,enemy,10000,7)
	model.begin(result)
	var verified_cast := false
	for event in result.cast_events:
		if event.skill.id != parry.id or event.rotation_index != 2 or event.resource_unavailable: continue
		model.advance_to(event.cast_start_ms)
		panel.update_presentation(model)
		check(model.units("buff.readiness")==0, "Charge already consumed at Parry start")
		check(panel._slot_buttons[2].modulate==Color.WHITE and panel._slot_buttons[2].get_node("SkillIcon").material.get_shader_parameter("grayscale")==false,"Accepted Parry lights up despite instant consumption")
		check(panel._slot_buttons[3].modulate==panel.UNAVAILABLE_SLOT_MODULATE,"Duplicate Parry cannot reuse spent charge")
		await capture("precision-parry-casting")
		model.advance_to(event.time_ms-1)
		panel.update_presentation(model)
		check(panel._slot_buttons[2].modulate==Color.WHITE,"Parry stays lit throughout windup")
		model.advance_to(event.time_ms)
		panel.update_presentation(model)
		check(panel._readiness_cast_index != 2,"Completed Parry loses its casting highlight")
		panel.clear_presentation()
		check(panel._slot_buttons[2].modulate==panel.UNAVAILABLE_SLOT_MODULATE,"Skip/end clears casting availability")
		verified_cast = true
		break
	check(verified_cast,"Exact Precision sequence exercises accepted Parry")
	panel.queue_free()
	await process_frame
	print("Macro Readiness: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)

