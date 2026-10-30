extends "res://tests/p6_t10_usability_test.gd"
const Fixtures = preload("res://tests/p6_mixed_gear_integration_test.gd")
const Lab = preload("res://scripts/tools/balance_lab.gd")
var cases: Array = []

func _initialize() -> void:
	super._initialize()

func choose(view, state, slot: int, tree_id: String) -> void:
	var index := 0
	for i in state.selected_class.trees.size():
		if state.selected_class.trees[i].id == tree_id: index = i+1
	var picker: OptionButton = view.actions["PrimaryTreeOption" if slot == 0 else "SecondaryTreeOption"]
	picker.select(index)
	picker.item_selected.emit(index)
	await settle()
	check(state.tree_at_slot(slot).id == tree_id if tree_id != "" else state.tree_at_slot(slot) == null,"UI selects role " + tree_id)

func clear_rotation(scene, state) -> void:
	while not state.rotation.is_empty():
		var remove := InputEventMouseButton.new()
		remove.button_index = MOUSE_BUTTON_RIGHT
		remove.pressed = true
		scene._skill_build_panel._slot_buttons[0].gui_input.emit(remove)
		await settle()

func allocate_ranks(view, state, ranks: Dictionary) -> void:
	var remaining := 45
	while remaining > 0:
		var advanced := false
		for id in ranks:
			if state.ranked_build.rank_of(id) >= ranks[id]: continue
			var probe := RankedBuild.new()
			probe.configure(state.ranked_build.primary_tree(),state.ranked_build.secondary_tree(),45,state.ranked_build.rank_map())
			if not probe.buy(id): continue
			await press_rank(view,"buy:"+id)
			remaining -= 1
			advanced = true
			for tree in state.ranked_build.trees():
				for unlock in tree.automatic_unlocks:
					if unlock.skill != null:
						check(ids(state.unlocked_skills()).has(unlock.skill.id) == (state.ranked_build.tree_points(tree) >= unlock.required_points),"UI allocation unlock boundary " + unlock.skill.id)
			break
		if not advanced:
			check(false,"legal fixture can be purchased")
			return
	check(state.ranked_build.rank_map() == ranks,"actual UI produces exact T9 rank map")

func fight_and_lab(scene, state, label_text: String) -> void:
	scene._talent_overlay.hide()
	if not state.build_locked: scene._skill_build_panel._lock_button.pressed.emit()
	scene._fight_button.pressed.emit()
	scene._combat_view.set_process(false)
	check(state.last_result != null and state.last_result.is_valid,label_text+" fight resolves")
	if state.last_result == null: return
	var damage: float = state.last_result.total_damage
	var gold: int = state.last_result.gold_stolen
	scene._combat_view._playback_intro_remaining_sec = 0
	scene._combat_view._process(3.0)
	if visual and cases.size() % 2 == 0: await capture(label_text+"-combat")
	scene._combat_view._skip()
	var encoded := BuildSaveCodec.encode(state,state.content_registry)
	var target: Dictionary = state.target_defense_snapshot()
	target["hp"] = state.selected_target.hp
	var spec := {"id":label_text,"label":label_text,"ranked_build":encoded,"monster":"res://data/monsters/mouthy_drunk.tres","monster_overrides":target,"gear":[state.equipped_weapon.resource_path],"gold":state.configured_gold,"duration_ms":state.duration_ms,"seed_start":state.fight_seed,"seed_count":1}
	var lab := Lab.run_scenario_spec(spec,state.content_registry)
	check(lab.status == "pass" and is_equal_approx(lab.aggregate.total_damage.mean,damage),label_text+" exact Practice/Lab damage parity")
	scene._fight_button.pressed.emit()
	scene._combat_view.set_process(false)
	check(state.last_result.total_damage == damage and state.last_result.gold_stolen == gold,label_text+" retry clears fight state")
	scene._combat_view._skip()
	cases.append({"case":label_text,"build":encoded,"target":target,"gear":state.equipped_weapon.resource_path,"duration_ms":state.duration_ms,"seed":state.fight_seed,"configured_gold":state.configured_gold,"damage":damage,"gold_stolen":gold,"lab_status":lab.status})
	if state.build_locked: scene._skill_build_panel._lock_button.pressed.emit()
	await settle()

func _run() -> void:
	report = "res://reports/p6_m5_t10_combined"
	visual = "--visual" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(report)
	SaveSystem.save_path = report+"/adventure.json"
	PracticeSaveSystem.save_path = report+"/legacy.json"
	PracticeSaveSystem.core_save_path = report+"/practice.json"
	if FileAccess.file_exists(PracticeSaveSystem.core_save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(PracticeSaveSystem.core_save_path))
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._show_training_room()
	await settle()
	for i in Fixtures.TREES.size():
		for j in range(i+1,Fixtures.TREES.size()):
			var first: String = Fixtures.TREES[i]
			var second: String = Fixtures.TREES[j]
			var scene = game._current_screen
			var state = scene._state
			var view = scene._talent_panel._ranked_view
			scene._show_talent_overlay()
			await settle()
			await choose(view,state,0,"")
			check(state.set_talent_budget(10), "Set isolated ten-point model fixture")
			await settle()
			check(state.earned_talent_points == 10,"Practice budget model accepts ten")
			check(state.set_talent_budget(45), "Set isolated full-budget model fixture")
			await settle()
			await choose(view,state,0,"tree."+first)
			await choose(view,state,1,"tree."+second)
			var ranks: Dictionary = Fixtures.DEEP[first].duplicate(true)
			var other: Dictionary = Fixtures.DEEP[second].duplicate(true)
			if second == "thief": other["talent.thief.fill_your_pockets"] += 1
			if second == "assassin": other["talent.assassin.hastened_poison"] += 1
			ranks.merge(other)
			await allocate_ranks(view,state,ranks)
			check(not state.set_talent_budget(44), "Model rejects reduction below spent ranks")
			await settle()
			check(state.earned_talent_points == 45 and state.ranked_build.rank_map() == ranks,"invalid budget reduction atomic")
			for id in ranks:
				check(not view.actions.has("preview:"+id) and not view.talent_tooltip(state.content_registry.talents[id]).contains("Preview"),"truthful playable tooltip " + id)
			geometry(view,first+"/"+second)
			await capture(first+"-"+second+"-trees")
			scene._talent_overlay.hide()
			scene._on_weapon_legendary_selected(2)
			scene._on_practice_gold_changed(123)
			scene._on_duration_changed(30)
			scene._on_fight_seed_changed(7)
			scene._on_random_fight_seed_toggled(false)
			state.apply_target_preset("blank")
			await clear_rotation(scene,state)
			var panel = available_panel(scene)
			for tree in [first,second]:
				for id in Fixtures.MACROS[tree]:
					if ids(state.unlocked_skills()).has(id): await add_skill(panel,id)
			await add_skill(panel,"skill.stab")
			while state.rotation.size() < 10: await add_skill(panel,"skill.stab")
			var original: Array = ids(state.rotation)
			await add_skill(panel,"skill.stab")
			check(ids(state.rotation) == original,"eleventh slot rejected")
			var remove := InputEventMouseButton.new()
			remove.button_index = MOUSE_BUTTON_RIGHT
			remove.pressed = true
			scene._skill_build_panel._slot_buttons[9].gui_input.emit(remove)
			await settle()
			check(state.rotation.size() == 9,"right-click removes selected slot")
			await add_skill(panel,"skill.stab")
			check(ids(state.rotation) == original,"duplicate re-added in correct order")
			for reverse in [false,true]:
				if reverse:
					scene._show_talent_overlay()
					await settle()
					await press_rank(view,"swap")
					check(state.ranked_build.primary_tree().id == "tree."+second and state.ranked_build.rank_map() == ranks,"swap retains allocations and updates roles")
				await fight_and_lab(scene,state,first+"_"+second+("_reverse" if reverse else "_forward"))
				for button in scene.find_children("*","Button",true,false):
					if button.text == "Save Setup": button.pressed.emit()
				await settle()
				var saved := BuildSaveCodec.encode(state,state.content_registry)
				game._on_main_menu_pressed()
				await settle()
				game._show_training_room()
				await settle()
				scene = game._current_screen
				state = scene._state
				view = scene._talent_panel._ranked_view
				check(BuildSaveCodec.encode(state,state.content_registry) == saved,"mixed roles/ranks/rotation reopen exactly")
				check(state.equipped_weapon.id == "gear.legendary.bandit_blade" and state.configured_gold == 123 and state.fight_seed == 7 and state.duration_ms == 30000,"equipment and fight configuration reopen")
			# Shadow skill survives tree refund while its independent gear grant exists.
			if second == "shadow":
				scene._on_weapon_legendary_selected(3)
				await clear_rotation(scene,state)
				await add_skill(available_panel(scene),"skill.killers_mark")
				await press_rank(view,"reset:tree.shadow")
				check(ids(state.rotation) == ["skill.killers_mark"],"alternate gear grant survives Shadow reset")
				scene._on_weapon_legendary_selected(2)
				await settle()
				check(state.rotation.is_empty(),"last grant removal prunes skill")
				for transition in ["custom","rarity","clear"]:
					scene._on_weapon_legendary_selected(3)
					await settle()
					await add_skill(available_panel(scene),"skill.killers_mark")
					if transition == "custom": state.use_custom_weapon()
					elif transition == "rarity": state.set_slot_rarity(state.practice_weapon,GearItem.Tier.CRUDE)
					else:
						state.equip_legendary(state.equipped_weapon.duplicate(true))
						state.clear_slot(state.equipped_weapon)
					await settle()
					check(state.rotation.is_empty(),transition+" removes last gear grant")
			else:
				await press_rank(view,"reset:tree."+first)
				for s in state.rotation: check(ids(state.unlocked_skills()).has(s.id),"tree reset prunes every unavailable slot")
	game.queue_free()
	await settle()
	SaveSystem.write_json(report+("/visual-checks.json" if visual else "/checks.json"),{"passed":not failed,"count":checks,"evidence":evidence,"cases":cases})
	print("M5 T10 combined journeys: %d checks %s" % [checks,"FAIL" if failed else "PASS"])
	quit(1 if failed else 0)
