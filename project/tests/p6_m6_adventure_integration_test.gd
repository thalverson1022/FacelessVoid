extends SceneTree
var failed:=false
var checks:=0
var state
var registry: BuildContentRegistry
var roundtrips:=0
var debug_saved:=false
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failed=true;push_error("FAILED: "+label)
func fingerprint() -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(SaveSystem._serialize(state),"",true,true)),"",true,true)
func restore(label: String) -> void:
	check(SaveSystem.save_run(state),label+" save: "+SaveSystem.last_error)
	var expected:=fingerprint()
	state.reset()
	check(SaveSystem.load_run_result(state).status=="loaded",label+" load")
	if fingerprint()!=expected and not debug_saved:
		DirAccess.make_dir_recursive_absolute("res://reports/p6_m6_t8")
		SaveSystem.write_json("res://reports/p6_m6_t8/debug_before.json",JSON.parse_string(expected))
		SaveSystem.write_json("res://reports/p6_m6_t8/debug_after.json",JSON.parse_string(fingerprint()))
		debug_saved=true
	check(fingerprint()==expected,label+" exact roundtrip")
	check(not state.build_locked,label+" unlock on load")
	roundtrips+=1
func allocate() -> void:
	for repeat in 45:
		if state.ranked_build.points_spent()==state.earned_talent_points:break
		for tree in state.ranked_build.trees():
			for talent in tree.talents:
				if state.select_talent(talent):break
	check(state.ranked_build.points_spent()==state.earned_talent_points,"Spend earned points legally")
	var skills: Array[Skill]=[state.unlocked_skills()[0]]
	state.set_rotation(skills)
func fixture_win() -> void:
	# Synthetic outcome to exercise lifecycle, not a claim of combat balance.
	state.finish_fight(true)
	restore("result before claim")
	check(state.claim_current_reward(),"Claim actual reward definition")
	check(not state.claim_current_reward(),"No duplicate reward")
	restore("claimed reward")
	if state.has_pending_reward_choice():
		while state.inventory.size()>=3:state.sell_inventory_item(state.inventory[0])
		check(state.choose_pending_reward_gear(state.pending_reward_choices[0]),"Choose generated/owned reward gear")
	if state.should_open_shop_after_current_reward():
		check(state.open_shop_round(),"Open earned shop")
		restore("shop")
		for item in state.shop_offers:
			if state.shop_purchase_price_for(item)<=state.gold and state.inventory.size()<3:
				check(state.buy_shop_offer(item),"Buy affordable item")
				check(state.equip_from_inventory(item),"Equip owned item")
				break
		check(state.close_shop_round(),"Close shop")
	check(state.continue_after_win(),"Continue victory")
func pair(main: String,secondary: String) -> void:
	state.reset();state.set_adventure_seed(217001)
	state.set_class(registry.classes["class.rogue"]);state.select_tree(registry.trees[main])
	check(not state.is_test_mode and not SaveSystem.session_only,"Real persistent Adventure")
	check(state.gold==0 and state.earned_talent_points==0 and state.equipped_weapon.id=="gear.crude_dagger","Fresh economy")
	check(state.ranked_build!=null,"Ranked primary")
	check(not state.choose_secondary_tree(registry.trees[secondary]),"No early secondary")
	restore("fresh primary")
	for index in 4:
		allocate();check(state.choose_current_tavern_encounter(),"Choose Tavern")
		state.set_locked(true);check(state.start_fight(),"Start Tavern")
		var result:=CombatResolver.resolve(state.rotation,state.current_player_stats(),state.current_target_monster(),state.current_target_duration_ms(),state.current_combat_rng_seed())
		check(result.is_valid,"Real combat resolver")
		fixture_win()
	check(state.earned_talent_points==6 and state.pending_contract_offer(),"Tavern 1/0/2/3 to six-point offer")
	check(state.pending_contract_offers.size()==3,"Three offers")
	allocate();check(state.can_respec(),"Offer respec")
	check(state.refund_all_talents(),"Refund at offer")
	allocate();restore("offer")
	check(state.accept_contract_offer(),"Accept")
	check(state.choose_secondary_tree(state.selected_class.trees.filter(func(t):return t.id==secondary)[0]),"Contract secondary")
	check(state.return_to_contract_offer(),"Inspect then return")
	restore("offer with fixed secondary")
	check(state.accept_contract_offer(),"Reaccept")
	var steps:=0
	while state.completed_contract_count==0 and steps<15:
		check(state.choose_contract_route_node(state.current_route_node.next_nodes[0]),"Commit adjacent route node")
		check(not state.can_respec() and not state.can_return_to_contract_offer(),"Committed restrictions")
		check(not state.refund_all_talents(),"Reject mid-route refund")
		allocate();restore("generated planning")
		if steps==0:
			state.set_locked(true);check(state.start_fight(),"First attempt")
			state.finish_fight(false);restore("retry available")
			check(state.retry_current_encounter(),"One retry")
		state.set_locked(true);check(state.start_fight(),"Start route fight")
		fixture_win();steps+=1
	check(state.completed_contract_count==1 and state.earned_talent_points==9,"Contract grants three points")
	check(state.ranked_build.primary_tree().id==main and state.ranked_build.secondary_tree().id==secondary,"Roles retained")
	restore("next contract")
	check(state.accept_contract_offer(),"Second contract")
	check(state.choose_contract_route_node(state.current_route_node.next_nodes[0]),"Second contract node")
	allocate()
	for attempt in 2:
		state.set_locked(true);check(state.start_fight(),"Failure attempt")
		state.finish_fight(false)
		if attempt==0:check(state.retry_current_encounter(),"Final retry")
	check(state.run_phase==state.RunPhase.RUN_ENDED and not state.can_retry_current_encounter(),"Terminal loss")
	restore("terminal loss")
func run() -> void:
	state=root.get_node("BuildState");registry=BuildContentRegistry.adventure()
	check(registry.error=="" and registry.trees.size()==4 and registry.talents.size()==44,"Reviewed complete registry")
	check(SaveSystem.registry().revision=="p6.adventure.1","Adventure registry default")
	check(BuildContentRegistry.test_mode().revision=="p6.playable.shadow.1","Practice revision retained")
	check(SaveSystem.save_path!=SaveSystem.LEGACY_SAVE_PATH,"Separate save slot")
	SaveSystem.write_json(SaveSystem.LEGACY_SAVE_PATH,{"preserve":"legacy"})
	SaveSystem.write_json(PracticeSaveSystem.core_save_path,{"preserve":"practice"})
	var legacy:=FileAccess.get_file_as_bytes(SaveSystem.LEGACY_SAVE_PATH)
	var practice:=FileAccess.get_file_as_bytes(PracticeSaveSystem.core_save_path)
	for a in registry.trees:
		for b in registry.trees:
			if a!=b:pair(a,b)
	# Failed loads preserve both file and active state.
	var valid:=SaveSystem._serialize(state)
	for mode in ["legacy","future","malformed","old_revision","practice_revision"]:
		var bad: Dictionary=valid.duplicate(true)
		if mode=="legacy":bad.save_version=1
		if mode=="future":bad.save_version=99
		if mode=="old_revision":bad.build.content_revision="p6.compat.1"
		if mode=="practice_revision":bad.build.content_revision="p6.playable.shadow.1"
		if mode=="malformed":bad.build.talent_ranks={"missing.talent":1}
		SaveSystem.write_json(SaveSystem.save_path,bad)
		var bytes:=FileAccess.get_file_as_bytes(SaveSystem.save_path);var before:=fingerprint()
		check(SaveSystem.load_run_result(state).status=="failed",mode+" rejected")
		check(FileAccess.get_file_as_bytes(SaveSystem.save_path)==bytes and fingerprint()==before,mode+" nondestructive")
	check(FileAccess.get_file_as_bytes(SaveSystem.LEGACY_SAVE_PATH)==legacy,"Legacy save unchanged")
	check(FileAccess.get_file_as_bytes(PracticeSaveSystem.core_save_path)==practice,"Practice save unchanged")
	DirAccess.make_dir_recursive_absolute("res://reports/p6_m6_t8")
	SaveSystem.write_json("res://reports/p6_m6_t8/integration.json",{"passed":not failed,"checks":checks,"roundtrips":roundtrips,"pairs":12,"synthetic_progression":true})
	state.reset()
	if failed:quit(1);return
	print("M6 ADVENTURE INTEGRATION PASS ",checks," checks; ",roundtrips," roundtrips");quit(0)


