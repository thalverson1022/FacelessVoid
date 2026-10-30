extends "res://scripts/tools/run_t6_optimization_review.gd"
const OfferSource=preload("res://scripts/systems/contract_offer_source.gd")
func tag_risk(tags: Array) -> int:
	var weights: Dictionary={"bladedancer":{"fortified":2,"nimble":2,"devious":1},"thief":{"devious":2,"arcane":2,"fortified":1},"assassin":{"fortified":2,"nimble":2},"shadow":{"warded":2,"hexed":2,"relentless":1}}[main_name]
	var score:=0
	for tag in tags:score+=int(weights.get(str(tag),0))
	return score
func run() -> void:
	config=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/m6_tavern_1023_protocol.json"))
	protocol=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/subclass_protocol.json"))
	registry=BuildContentRegistry.test_mode();state=root.get_node("BuildState")
	var rows:=[]
	for tree in TREES:
		main_name=tree
		for stage in [1,4,6,10]:
			var entries:=[]
			for file in DirAccess.get_files_at(T7_OUT):
				if not file.ends_with(".json"):continue
				var d: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(T7_OUT+"/"+file))
				if d.primary!=tree or d.policy!="typical" or int(d.seed)<84001 or int(d.seed)>84008:continue
				for f in d.fights:
					if f.stage=="C"+str(stage):
						entries.append({"source":file,"snapshot":{"secondary":d.secondary,"budget":int(f.points),"ranks":f.ranks,"gold":int(f.gold),"gear":f.gear}});break
				if entries.size()==2:break
			for entry in entries:
				var s: Dictionary=entry.snapshot
				var dummy:=Monster.new();dummy.hp=1000
				var chosen:=select_macro(resolved(s,s.ranks),dummy,30000,true)
				var arm:={"id":"neutral_trained","ranks":s.ranks,"macro":chosen.macro}
				for seed in range(216001,216005):
					var context=OfferSource.offer_context(seed,stage-1,stage-1,-1,{"route_difficulty":"medium","earned_talent_points":int(s.budget)},false,true,3)
					var offers=OfferSource.contract_offers(context)
					var bosses:=[]
					var picked:=0
					for i in offers.size():
						var nodes:=[];gather(offers[i].offer_node,{},nodes)
						for n in nodes:
							if n.node_type!=ContractRouteNode.NodeType.BOSS:continue
							bosses.append(n)
							if tag_risk(n.route_preview.archetype_tags)<tag_risk(bosses[picked].route_preview.archetype_tags):picked=i
					for i in bosses.size():
						var n: ContractRouteNode=bosses[i]
						var e:=GeneratedMonsterDraft.from_dictionary(n.generated_encounter_payload).to_monster()
						rows.append({"primary":tree,"stage":stage,"seed":seed,"source":entry.source,"offer_index":i,"tag_choice":picked,"tags":n.route_preview.archetype_tags,"risk":tag_risk(n.route_preview.archetype_tags),"snapshot":s,"arm":arm,"enemy":stat_record(e),"node":n.id,"duration":int(n.generated_encounter_payload.duration_ms),"samples":measure_quality(s,arm,e,int(n.generated_encounter_payload.duration_ms),n.id)})
			print("Tag choice ",tree," C",stage," rows=",rows.size())
			SaveSystem.write_json(REVIEW_OUT+"/tag_choice.json",{"complete":false,"rows":rows,"checks":checks})
	if t7_failed:quit(1);return
	SaveSystem.write_json(REVIEW_OUT+"/tag_choice.json",{"complete":true,"rows":rows,"checks":checks})
	print("TAG CHOICE PASS ",checks);quit(0)
