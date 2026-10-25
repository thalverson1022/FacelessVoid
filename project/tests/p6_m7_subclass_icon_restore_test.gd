extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://reports/subclass_icons")
	for registry in [BuildContentRegistry.adventure(), BuildContentRegistry.test_mode()]:
		assert(registry.error == "", registry.error)
		for tree in registry.classes["class.rogue"].trees:
			assert(tree.icon != null, "Missing subclass icon: " + tree.id)
	var state = root.get_node("BuildState")
	state.selected_class = BuildContentRegistry.adventure().classes["class.rogue"]
	var menu = load("res://scenes/subclass_select/subclass_select.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	await process_frame
	assert(menu._card_box.get_child_count() == 4, "All four subclass cards")
	for card in menu._card_box.get_children():
		var icon = card.find_child("Icon", true, false)
		assert(icon != null and icon.texture != null, "Subclass card shows its icon")
	root.size = Vector2i(1600,900)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://reports/subclass_icons/restored-menu.png")
	print("Subclass icon restoration: PASS")
	quit(0)
