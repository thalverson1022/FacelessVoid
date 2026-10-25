extends SceneTree
var game
var checks:=0
var failed:=false
var target:=""
var visual:=false
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--snapshot="):target=arg.trim_prefix("--snapshot=")
	visual="--visual" in OS.get_cmdline_user_args()
	call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failed=true;push_error("FAILED "+label)
func settle() -> void:
	for i in 5:await process_frame
func capture(label: String) -> void:
	if not visual:return
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/p6_m6_t9/ui/"+target.trim_suffix(".json")+"_"+label+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/p6_m6_t9/ui")
	SaveSystem.save_path="user://t9_ui_snapshot.json"
	SaveSystem.session_only=false
	var raw:=FileAccess.get_file_as_string("res://reports/p6_m6_t9/snapshots/"+target)
	var copied:=FileAccess.open(SaveSystem.save_path,FileAccess.WRITE)
	copied.store_string(raw);copied.close()
	check(FileAccess.get_file_as_string(SaveSystem.save_path)==raw,"Copy earned snapshot byte for byte")
	game=load("res://scenes/game_root.tscn").instantiate();root.add_child(game);await settle()
	game._current_screen.continue_pressed.emit();await settle()
	var state=root.get_node("BuildState")
	var screen=game._current_screen
	check(screen.get("_enemy_panel")!=null,"Resume actual Adventure screen")
	if failed:print(SaveSystem.last_load_result);quit(1);return
	check(not state.is_test_mode,"Adventure rules")
	var gold: int=state.gold
	var ranks: Dictionary=state.ranked_build.rank_map()
	await capture("combat")
	if target.contains("offer"):
		check(state.can_respec(),"Offer permits preparation")
		screen._contract_overlay.accept_requested.emit(state.contract_offer_key(state.active_contract));await settle()
		check(state.can_return_to_contract_offer(),"Route inspection is reversible")
		screen._contract_overlay.hide()
	screen._show_map_overlay(false);await settle()
	var map=screen._map_overlay
	check(map.visible,"Route displayed")
	await capture("route")
	var guide=map.find_child("ArchetypeGuideButton",true,false)
	check(guide!=null and guide.visible,"Guide accessible")
	guide.pressed.emit();await settle()
	check(map.get_node("ArchetypeGuide").visible,"Guide opens")
	await capture("guide")
	map.get_node("ArchetypeGuide").hide();map.hide();await settle()
	check(state.gold==gold and state.ranked_build.rank_map()==ranks,"Inspection preserves earned state")
	if not target.contains("offer"):
		check(not state.can_respec(),"Committed allocation cannot be refunded")
		var pair:=target.get_slice("_C",0).get_slice("_T",0)
		var run_data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://reports/p6_m6_t9/runs/"+pair+"_informed_233001.json"))
		var expected: Dictionary={}
		for fight in run_data.fights:
			if fight.key==state._current_fight_key() and int(fight.attempt)==0:expected=fight;break
		check(not expected.is_empty(),"Snapshot belongs to earned run")
		screen.instant_playback=true
		screen._skill_build_panel._lock_button.pressed.emit();await settle()
		check(state.build_locked,"Lock through actual UI")
		screen._enemy_panel._fight_button.pressed.emit();await settle()
		check(state.last_combat_result!=null and state.last_combat_result.is_valid,"Real UI fight resolves")
		if state.last_combat_result!=null and not expected.is_empty():check(is_equal_approx(state.last_combat_result.total_damage,float(expected.damage)) and state.last_combat_result.is_win==expected.win,"UI result matches held-out run exactly")
		await capture("result")
	else:
		screen._on_contract_back_requested();await settle()
		check(state.can_respec() and state.pending_contract_offer(),"Return restores offer preparation")
	SaveSystem.write_json("res://reports/p6_m6_t9/ui/"+target,{"passed":not failed,"checks":checks,"visual":visual,"snapshot":target,"agent_automated_ui":true,"human_playtest":false})
	print("T9 UI ","FAIL" if failed else "PASS"," ",target," checks=",checks)
	quit(1 if failed else 0)
