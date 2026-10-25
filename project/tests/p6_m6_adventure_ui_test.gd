extends SceneTree
var failed:=false
var checks:=0
var visual:=false
var game
func _initialize() -> void:
	visual="--visual" in OS.get_cmdline_user_args()
	call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failed=true;push_error("FAILED: "+label)
func settle() -> void:
	for i in 4:await process_frame
func capture(label: String) -> void:
	if not visual:return
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/p6_m6_t8/"+label+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/p6_m6_t8")
	var state=root.get_node("BuildState")
	SaveSystem.session_only=false;SaveSystem.delete_save()
	SaveSystem.write_json(SaveSystem.LEGACY_SAVE_PATH,{"untouched":"old"})
	var legacy:=FileAccess.get_file_as_bytes(SaveSystem.LEGACY_SAVE_PATH)
	game=load("res://scenes/game_root.tscn").instantiate();root.add_child(game);await settle()
	var title=game._current_screen
	check(not title.find_child("AdventureButton",true,false).disabled,"New Adventure enabled")
	check(title.find_child("ResumeAdventureButton",true,false).disabled,"Missing new save disables resume")
	await capture("title")
	for tree_id in ["tree.bladedancer","tree.thief","tree.assassin","tree.shadow"]:
		title=game._current_screen
		title._random_seed_check_box.button_pressed=false;title._seed_spin_box.value=217777
		title.adventure_pressed.emit();await settle()
		var class_screen=game._current_screen
		var selects: Array=class_screen.find_children("*","Button",true,false).filter(func(b):return b.text=="Select")
		check(selects.size()==1,"One playable class")
		selects[0].pressed.emit();await settle()
		var subclass=game._current_screen
		check(state.selected_class.trees.size()==4,"Four reviewed subclasses")
		var trees: Array=state.selected_class.trees
		var index: int=trees.find(trees.filter(func(t):return t.id==tree_id)[0])
		var buttons: Array=subclass.find_children("*","Button",true,false).filter(func(b):return b.text=="Select")
		buttons[index].pressed.emit();await settle()
		check(state.ranked_build.primary_tree().id==tree_id and state.adventure_seed==217777,"UI starts selected ranked primary with chosen seed")
		check(state.earned_talent_points==0 and state.gold==0 and state.equipped_weapon.id=="gear.crude_dagger","No Test Mode starting rewards")
		check(SaveSystem.has_save(),"Selection autosaved")
		var before:=FileAccess.get_file_as_bytes(SaveSystem.save_path)
		game._on_main_menu_pressed();await settle()
		check(not game._current_screen.find_child("ResumeAdventureButton",true,false).disabled,"Saved run enables resume")
		game._current_screen.continue_pressed.emit();await settle()
		check(state.ranked_build.primary_tree().id==tree_id and not state.is_test_mode,"Resume through title")
		check(FileAccess.get_file_as_bytes(SaveSystem.save_path)==before,"Resume nondestructive")
		check(state.choose_current_tavern_encounter(),"Choose actual first fight")
		var rotation: Array[Skill]=[state.unlocked_skills().filter(func(s):return s.id=="skill.stab")[0]]
		state.set_rotation(rotation);state.set_locked(true);await settle()
		game._current_screen.instant_playback=true
		game._current_screen._enemy_panel._fight_button.pressed.emit();await settle()
		check(state.last_combat_result!=null and state.last_combat_result.is_valid,"Real Adventure UI combat resolves")
		check(SaveSystem.last_error=="","Fight autosave succeeds")
		game._on_main_menu_pressed();await settle()
	# Test Mode still cannot overwrite/delete the new Adventure save.
	var saved:=FileAccess.get_file_as_bytes(SaveSystem.save_path)
	game._on_contract_test_pressed(42,6);await settle()
	check(state.is_test_mode and SaveSystem.session_only,"Test Mode isolated")
	SaveSystem.save_run(state);SaveSystem.delete_save()
	check(FileAccess.get_file_as_bytes(SaveSystem.save_path)==saved,"Test Mode preserves Adventure")
	game._on_main_menu_pressed();await settle()
	game._current_screen.continue_pressed.emit();await settle()
	# Use an isolated checkpoint to exercise the real map and guide widgets.
	state.earned_talent_points=6;state.ranked_build.set_budget(6)
	check(state.start_generated_contract_loop_offer(),"Offers available")
	check(state.accept_contract_offer(),"Inspect route")
	var screen=game._current_screen
	screen._show_map_overlay(false);await settle()
	var map=screen._map_overlay
	await capture("route")
	var guide=map.find_child("ArchetypeGuideButton",true,false)
	check(guide!=null and not guide.visible,"Guide entry hidden on map")
	guide.pressed.emit();await settle()
	var dialog=map.get_node("ArchetypeGuide")
	check(dialog.visible,"Guide opens")
	var text=dialog.get_node("GuideText")
	for phrase in ["Ward", "Hex", "before committing", "cannot switch contracts"]:
		check(text.text.contains(phrase),"Guide explains "+phrase)
	check(text.scroll_active and text.size.x>400 and text.size.y>200,"Scrollable guide fits dialog")
	await capture("guide")
	dialog.hide()
	check(state.can_return_to_contract_offer(),"Guide does not commit route")
	check(state.return_to_contract_offer() and state.can_respec(),"Back restores offer respec")
	# Restart stays persistent and resets economy; it does not restart Test Mode.
	game._on_adventure_restart_pressed();await settle()
	check(not state.is_test_mode and not SaveSystem.session_only and state.gold==0 and state.earned_talent_points==0,"Real restart reset")
	check(not SaveSystem.has_save(),"Restart clears only current run")
	check(FileAccess.get_file_as_bytes(SaveSystem.LEGACY_SAVE_PATH)==legacy,"Legacy run preserved across UI flows")
	SaveSystem.write_json("res://reports/p6_m6_t8/ui.json",{"passed":not failed,"checks":checks,"visual":visual})
	game.queue_free();await settle()
	if failed:quit(1);return
	print("M6 ADVENTURE UI PASS ",checks);quit(0)


