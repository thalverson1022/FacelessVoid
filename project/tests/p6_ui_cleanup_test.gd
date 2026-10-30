extends "res://tests/p6_core_journey_test.gd"
## Repeated mode entry/exit must not accumulate detached controls.
func _initialize() -> void:
	super._initialize()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/p6_m4_t11_cleanup")
	var original_orphans := Node.get_orphan_node_ids()
	for cycle in 3:
		var game = load("res://scenes/game_root.tscn").instantiate()
		root.add_child(game)
		await settle()
		game._show_training_room()
		await settle()
		game._current_screen._show_talent_overlay()
		await settle()
		game._on_contract_test_pressed(7, 10)
		await settle()
		game._current_screen._talent_overlay.show_overlay()
		await settle()
		game.queue_free()
		await settle()
		var new_orphans: Array = []
		for id in Node.get_orphan_node_ids():
			if id not in original_orphans: new_orphans.append(id)
		check(new_orphans.is_empty(), "Mode cycle %d leaves no detached controls" % cycle)
	SaveSystem.write_json("res://reports/p6_m4_t11_cleanup/lifecycle.json", {"passed": not failed, "evidence": evidence})
	print("T11 UI lifecycle: %d checks %s" % [checks, "FAIL" if failed else "PASS"])
	quit(1 if failed else 0)
