extends "res://scripts/tools/run_m6_t7.gd"
## Complete earned-resource runs. Policy preparation never reads rolled enemy stats.
const T9_OUT := "res://reports/p6_m6_t9/runs"
var policy := "coherent"
var decisions := []
var practice_macro := []
var fixed_contract_ranks := {}
var planned_path := []
var allocation_log := []
var training_count := 0
var omitted_controls := []
var physical_share:=0.5

func require(ok: bool, message: String) -> void:
	# The production continuation API returns false on the legitimate final victory.
	if not ok and message=="Continue real victory" and state!=null and state.all_generated_bosses_defeated() and state.run_phase==state.RunPhase.RUN_ENDED:
		ok=true
	super.require(ok,message)

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tree="): main_name=arg.trim_prefix("--tree=")
		if arg.begins_with("--secondary="): partner=arg.trim_prefix("--secondary=")
		if arg.begins_with("--policy="): policy=arg.trim_prefix("--policy=")
		if arg.begins_with("--seed="): run_seed=int(arg.trim_prefix("--seed="))
	SaveSystem.session_only=true
	DirAccess.make_dir_recursive_absolute(T9_OUT)
	call_deferred("run")

func informed() -> bool:
	return policy.begins_with("informed")

func practice_target() -> Monster:
	var m:=Monster.new()
	m.hp=1000000
	return m

func visible_target() -> Monster:
	var src: Monster=state.current_target_monster()
	var m: Monster=src.duplicate(true)
	for key in ["poison_resistance","dodge_chance","crit_negation","slow","suppress"]:m.set(key,roundf(src.get(key)*100.0)/100.0)
	for key in ["block","absorb"]:m.set(key,roundf(src.get(key)*10.0)/10.0)
	m.stun_duration_ms=roundi(m.stun_duration_ms/100.0)*100
	return m

func practice_search(c: Dictionary, broad: bool=false, target: Monster=null, duration: int=30000) -> Dictionary:
	var best:={"score":-1.0,"macro":legal_ids(config.reasonable_macros[main_name],c)}
	var pool:=macros(c,broad)
	var limit:=32 if broad else 12
	if pool.size()>limit:
		var spaced:=[]
		for i in limit:spaced.append(pool[roundi(float(i)*(pool.size()-1)/(limit-1))])
		pool=spaced
	for ids in pool:
		var score:=0.0
		for seed in [4301,4302]:
			score+=simulate(ids,c,target if target!=null else practice_target(),duration,seed).total_damage
			training_count+=1
		if score>float(best.score):best={"score":score,"macro":ids}
	return best

func spend_points(respec: bool) -> void:
	if respec:require(state.refund_all_talents(),"Respec only at offer")
	var secondary: String=partner if state.ranked_build.secondary_tree()!=null else ""
	var desired: Dictionary=allocate(main_name,secondary,state.earned_talent_points).rank_map()
	var s:={"secondary":secondary,"budget":state.earned_talent_points,"gold":state.gold,"gear":SaveSystem._gear_list_to_data(state.equipped_gear()),"ranks":desired}
	# Tavern has no refunds: choose only allocations extending what was already bought.
	var pool:=rank_candidates(s)
	var eligible:=[]
	for ranks in pool:
		var extends_current:=true
		for id in state.ranked_build.rank_map():
			if int(ranks.get(id,0))<state.ranked_build.rank_of(id):extends_current=false
		var m:=model_for(s,ranks)
		if extends_current and m.tree_points(registry.trees["tree."+main_name])>=ceili(float(s.budget)*2.0/3.0):eligible.append(ranks)
	if eligible.is_empty():
		var m:=model_for(s,state.ranked_build.rank_map())
		for pass_index in 45:
			for tree in m.trees():
				for talent in tree.talents:m.buy(talent.id)
		eligible.append(m.rank_map())
	desired=eligible[0]
	if policy=="weak":desired=eligible[mini(1,eligible.size()-1)]
	if informed():
		var best_score:=-1.0
		for ranks in eligible.slice(0,8):
			var result:=practice_search(resolved(s,ranks),false,visible_target() if stage_label.begins_with("T") else null,state.current_target_duration_ms() if stage_label.begins_with("T") else 30000)
			if float(result.score)>best_score:
				best_score=float(result.score);desired=ranks;practice_macro=result.macro
		practice_macro=practice_search(resolved(s,desired),true,visible_target() if stage_label.begins_with("T") else null,state.current_target_duration_ms() if stage_label.begins_with("T") else 30000).macro
	for repeat in 45:
		for tree in state.ranked_build.trees():
			for talent in tree.talents:
				if state.ranked_build.rank_of(talent.id)<int(desired.get(talent.id,0)):state.select_talent(talent)
	require(state.ranked_build.rank_map()==desired,"Exact legal allocation")
	require(state.ranked_build.points_spent()==state.earned_talent_points,"All earned points used")
	allocation_log.append({"stage":stage_label,"ranks":desired,"budget":state.earned_talent_points,"search_candidates":mini(8,eligible.size()) if informed() else 0})

func risk(tags: Array) -> float:
	# General tag tendencies weighted by the build's own practice damage mix.
	var weights:={"fortified":1.0+3.0*physical_share,"nimble":2.0,"devious":2.0,"arcane":1.5,"warded":1.0+4.0*(1.0-physical_share),"hexed":1.0+4.0*(1.0-physical_share),"relentless":2.0,"unstable":2.5,"armored":1.0+2.0*physical_share,"resistant":1.0+2.0*(1.0-physical_share),"aegis":1.0+3.0*physical_share,"nullify":1.0+3.0*(1.0-physical_share),"spiteful":1.0+4.0*(1.0-physical_share),"riftbound":2.0}
	var value:=0.0
	for tag in tags:
		require(weights.has(tag),"Every visible tag covered by policy")
		value+=float(weights.get(tag,1.0))
	return value

func choose_plan() -> String:
	var c:=BuildResolver.resolve_ranked_build(state.selected_class,state.ranked_build,state.equipped_gear(),state.gold)
	var ids:=legal_ids(practice_macro if not practice_macro.is_empty() else config.reasonable_macros[main_name],c)
	var sample=simulate(ids,c,practice_target(),30000,4301)
	var physical:=0.0
	for cast in sample.cast_events:physical+=cast.physical_damage
	physical_share=clampf(physical/maxf(1.0,sample.total_damage),0.0,1.0)
	var options:=[]
	for contract in state.pending_contract_offers:
		var nodes:=[]
		gather(contract.offer_node,{},nodes)
		var costs:={}
		var previews:=[]
		for node in nodes:
			var tags: Array=node.route_preview.get("archetype_tags",[])
			costs[node.id]=risk(tags) if not tags.is_empty() else 0.0
			previews.append({"id":node.id,"tags":tags,"role":int(node.node_type)})
		for path in all_paths(contract.offer_node):
			var cost:=0.0
			for id in path:cost+=float(costs[id])
			options.append({"offer":state.contract_offer_key(contract),"boss":state.generated_boss_id_for_contract(contract),"path":path,"risk":cost,"preview":previews})
	var selected: Dictionary=options[0]
	if informed() and policy!="informed_first_route":
		for option in options:
			if float(option.risk)<float(selected.risk):selected=option
	planned_path=selected.path
	if policy=="informed" and run_seed==233001 and stage_label in ["C1","C6","C10","C20","C30"]:
		DirAccess.make_dir_recursive_absolute("res://reports/p6_m6_t9/snapshots")
		SaveSystem.write_json("res://reports/p6_m6_t9/snapshots/%s_%s_%s_offer.json"%[main_name,partner,stage_label],SaveSystem._serialize(state))
	decisions.append({"stage":stage_label,"remaining_bosses":state.generated_bosses_total_count()-state.defeated_generated_boss_count(),"offer_count":state.pending_contract_offers.size(),"options":options,"selected":selected})
	return str(selected.offer)

func actual_fight() -> bool:
	for attempt in 100:
		if stage_label.begins_with("C"):require(state.ranked_build.rank_map()==fixed_contract_ranks,"No respec within contract")
		var c:=BuildResolver.resolve_ranked_build(state.selected_class,state.ranked_build,state.equipped_gear(),state.gold)
		var ids:=legal_ids(config.reasonable_macros[main_name],c)
		if informed() and policy!="informed_default_macro":ids=practice_search(c,false,visible_target(),roundi(state.current_target_duration_ms()/1000.0)*1000).macro
		# Evaluation begins only after the preparation decision is frozen.
		var enemy: Monster=state.current_target_monster()
		var duration: int=state.current_target_duration_ms()
		state.set_rotation(rotation(ids,c));state.set_locked(true)
		if policy=="informed" and run_seed==233001 and attempt==0 and stage_label in ["T3","C1","C6","C10","C20","C30"]:
			DirAccess.make_dir_recursive_absolute("res://reports/p6_m6_t9/snapshots")
			SaveSystem.write_json("res://reports/p6_m6_t9/snapshots/%s_%s_%s.json"%[main_name,partner,stage_label],SaveSystem._serialize(state))
		var before: int=state.gold
		var seed: int=state.current_combat_rng_seed()
		require(state.start_fight(),"Start actual fight")
		var result=simulate(ids,c,enemy,duration,seed)
		state.record_combat_stolen_gold(result.gold_stolen)
		account("theft",before,{"amount":result.gold_stolen,"win":result.is_win})
		state.record_fight_result(result,enemy);state.finish_fight(result.is_win)
		var f:={"stage":stage_label,"key":state._current_fight_key(),"attempt":attempt,"seed":seed,"duration":duration,"gold":before,"gear":SaveSystem._gear_list_to_data(state.equipped_gear()),"ranks":state.ranked_build.rank_map(),"points":state.earned_talent_points,"macro":ids,"enemy":stat_record(enemy),"damage":result.total_damage,"win":result.is_win,"theft":result.gold_stolen,"overkill":result.overkill_damage,"tags":state.current_route_node.route_preview.get("archetype_tags",[]) if state.current_route_node!=null else [],"role":int(state.current_route_node.node_type) if state.current_route_node!=null else -1}
		fights.append(f)
		# Local paired mistake control: omit first used skill, no feedback to policy/run.
		if informed() and attempt==0 and stage_label in ["C1","C4","C6","C10","C20","C30"]:
			var omitted: Array=ids.filter(func(x):return x!=ids[0])
			if omitted.is_empty():omitted=legal_ids(["stab"],c)
			var ctrl=simulate(omitted,c,enemy,duration,seed)
			omitted_controls.append({"fight":fights.size()-1,"removed":ids[0],"macro":omitted,"win":ctrl.is_win,"damage":ctrl.total_damage,"same_macro":omitted==ids})
		if result.is_win:return true
		if not state.can_retry_current_encounter():return false
		require(state.retry_current_encounter(),"Legal retry")
	require(false,"Technical cap is not run defeat")
	return false

func run() -> void:
	config=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/m6_tavern_1023_protocol.json"))
	protocol=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/subclass_protocol.json"))
	registry=BuildContentRegistry.adventure();state=root.get_node("BuildState")
	SaveSystem.registry_override=registry
	state.reset();SaveSystem.session_only=true
	state.set_adventure_seed(run_seed);state.set_class(registry.classes["class.rogue"])
	require(state.configure_ranked_build(registry.trees["tree."+main_name]),"Primary configured")
	spend_policy="weak" if policy=="weak" else "strong" if informed() and policy!="informed_typical_shop" else "typical"
	var alive:=true
	for index in 4:
		stage_label="T"+str(index)
		require(state.choose_current_tavern_encounter(),"Tavern choice")
		spend_points(false)
		if not actual_fight():alive=false;break
		actual_reward()
	if alive:
		for stage in range(1,31):
			print("T9 progress ",main_name,"/",partner," ",policy," C",stage)
			stage_label="C"+str(stage)
			require(state.pending_contract_offer(),"Real pending offer")
			if state.ranked_build.secondary_tree()==null:
				require(state.accept_contract_offer(),"Preview before secondary")
				require(state.choose_secondary_tree(registry.trees["tree."+partner]),"Legal secondary gate")
				require(state.return_to_contract_offer(),"Return before commitment")
			spend_points(true)
			var selected:=choose_plan()
			require(state.accept_contract_offer(selected),"Accept chosen visible offer")
			fixed_contract_ranks=state.ranked_build.rank_map().duplicate()
			var done:=false
			while not done:
				var choices: Array=state.current_route_node.next_nodes
				var next: ContractRouteNode=choices[0]
				for node in choices:
					if planned_path.has(node.id):next=node;break
				require(state.choose_contract_route_node(next),"Legal planned path")
				done=next.next_nodes.is_empty()
				if not actual_fight():alive=false;break
				actual_reward()
			if not alive or state.run_phase==state.RunPhase.RUN_ENDED:break
	var ending: String="catalog_complete" if state.all_generated_bosses_defeated() else "defeat" if not alive else "technical_horizon"
	require(ending!="technical_horizon","Natural endpoint")
	var report:={"complete":not t7_failed,"primary":main_name,"secondary":partner,"policy":policy,"seed":run_seed,"ending":ending,"completed_contracts":state.completed_contract_count,"last_stage":stage_label,"ending_gold":state.gold,"points":state.earned_talent_points,"events":events,"fights":fights,"decisions":decisions,"allocations":allocation_log,"training_simulations":training_count,"omission_controls":omitted_controls,"checks":checks,"revision":BuildContentRegistry.ADVENTURE_REVISION}
	SaveSystem.write_json(T9_OUT+"/%s_%s_%s_%d.json"%[main_name,partner,policy,run_seed],report)
	print("T9 ","FAIL" if t7_failed else "PASS"," ",main_name,"/",partner," ",policy," ",run_seed," endpoint=",ending," contracts=",state.completed_contract_count," fights=",fights.size())
	quit(1 if t7_failed else 0)
