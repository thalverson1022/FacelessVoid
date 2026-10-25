extends "res://scripts/tools/run_m6_t5_search.gd"
## Require all available points in the named primary to distinguish mixed-tree rescue.
func run() -> void:
	config=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/m6_tavern_1023_protocol.json"))
	protocol=JSON.parse_string(FileAccess.get_file_as_string("res://data/balance_lab/subclass_protocol.json"))
	registry=BuildContentRegistry.test_mode()
	state=root.get_node("BuildState")
	snapshots=JSON.parse_string(FileAccess.get_file_as_string(OUT+"/"+main_name+"/fixtures.json")).snapshots
	encounters=JSON.parse_string(FileAccess.get_file_as_string(OUT+"/"+main_name+"/encounters.json")).encounters
	for stage in (["C4","C6","C8"] if main_name=="shadow" else ["C1","C4","C10"]):
		investigate(stage)
		SaveSystem.write_json(DEST+"/"+main_name+"_primary.json",{"complete":false,"search":search_log,"winners":winners,"measurements":measurements,"checks":checks})
		print("Primary-only ",main_name," ",stage," complete")
	SaveSystem.write_json(DEST+"/"+main_name+"_primary.json",{"complete":true,"search":search_log,"winners":winners,"measurements":measurements,"checks":checks})
	print("Primary-only PASS ",main_name," checks=",checks)
	quit(0)

func rank_candidates(s: Dictionary) -> Array:
	var primary_only:=s.duplicate(true)
	primary_only.secondary=""
	primary_only.ranks=allocate(main_name,"",int(s.budget)).rank_map()
	return super.rank_candidates(primary_only)
