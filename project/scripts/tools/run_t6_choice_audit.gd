extends "res://scripts/tools/run_m6_t7.gd"
const Choices=preload("res://scripts/systems/contract_offer_source.gd")
func _initialize() -> void:
	SaveSystem.session_only=true
	call_deferred("run")
func run() -> void:
	registry=BuildContentRegistry.test_mode();state=root.get_node("BuildState")
	var view=load("res://scenes/combat/map_overlay.tscn").instantiate();root.add_child(view)
	await process_frame
	var sets:=[]
	for stage in [1,4,6,10,20]:
		for seed in range(216001,216009):
			var context=Choices.offer_context(seed,stage-1,stage-1,-1,{"route_difficulty":"medium","earned_talent_points":mini(45,6+3*(stage-1))},false,true,3)
			var offers=Choices.contract_offers(context)
			require(offers.size()==3,"Three distinct generated offers")
			var output:=[]
			for offer in offers:
				var nodes:=[];gather(offer.offer_node,{},nodes)
				var rows:=[];var paths:=all_paths(offer.offer_node)
				for n in nodes:
					if n.generated_encounter_payload.is_empty(): continue
					var text: String=view._route_node_button_text(n)
					for tag in n.route_preview.archetype_tags: require(text.contains(str(tag)),"Tags visible on route card")
					var count:=0
					for path in paths:
						if path.has(n.id):count+=1
					rows.append({"id":n.id,"boss":n.node_type==ContractRouteNode.NodeType.BOSS,"tags":n.route_preview.archetype_tags,"paths_containing":count,"payload":n.generated_encounter_payload,"card_text":text})
				output.append({"id":offer.id,"paths":paths,"nodes":rows})
			sets.append({"stage":stage,"seed":seed,"offers":output})
	state.reset();state.set_class(registry.classes["class.rogue"])
	require(state.configure_ranked_build(registry.trees["tree.shadow"]),"Configure ranked build")
	require(state.start_generated_contract_loop_offer(),"Open generated offers")
	require(state.can_respec(),"Respec at offer")
	require(state.pending_contract_offers.size()==3,"Three offers through state")
	require(state.accept_contract_offer(),"Inspect route")
	require(not state.can_respec(),"No respec on route")
	require(state.can_return_to_contract_offer(),"Can leave preview before commitment")
	require(state.return_to_contract_offer(),"Return to offers")
	require(state.can_respec(),"Respec restored at offer")
	require(state.accept_contract_offer(),"Reinspect route")
	require(state.choose_contract_route_node(state.current_route_node.next_nodes[0]),"Commit next node")
	require(not state.can_return_to_contract_offer(),"No escape after committing first node")
	require(not state.can_respec(),"No mid-contract respec")
	if t7_failed: quit(1);return
	DirAccess.make_dir_recursive_absolute("res://reports/p6_m6_t6_optimization")
	SaveSystem.write_json("res://reports/p6_m6_t6_optimization/choices.json",{"complete":true,"checks":checks,"offer_sets":sets})
	state.reset();view.queue_free()
	print("CHOICE AUDIT PASS ",checks);quit(0)
