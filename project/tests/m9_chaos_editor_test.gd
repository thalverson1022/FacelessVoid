extends SceneTree
## Independent Chaos row choices through actual UI signals and persisted fields.
const OUT := "res://reports/m9_chaos_editor/"
const TYPES := [StatModifier.StatCategory.BASIC, StatModifier.StatCategory.RARE, StatModifier.StatCategory.DRAWBACK]
var checks := 0
var evidence := {}

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	SaveSystem.save_path = OUT + "adventure.json"
	PracticeSaveSystem.save_path = OUT + "practice.json"
	PracticeSaveSystem.core_save_path = OUT + "core.json"
	SevenSlotSaveBoundary.legacy_path = OUT + "legacy.json"
	SevenSlotSaveBoundary.marker_path = OUT + "marker.json"
	for path in SevenSlotSaveBoundary.paths().values():
		assert(path.begins_with(OUT))
		for candidate in [path,path+".tmp"]:
			if FileAccess.file_exists(candidate): assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(candidate)) == OK)
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	assert(ok,label)

func settle() -> void:
	for i in 4: await process_frame

func capture(room: Node, label: String) -> void:
	await settle()
	var panel: Control = room._gear_editor_title.get_parent().get_parent().get_parent()
	check(Rect2(0,0,1600,900).encloses(panel.get_global_rect()),"Editor viewport fit")
	for row: Control in room._gear_affix_column.get_children():
		check(Rect2(0,0,1600,900).encloses(row.get_global_rect()),"Affix row viewport fit")
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+label+".png") == OK,"Render saved")

func pool(slot: int, category: int) -> Array[String]:
	if category == StatModifier.StatCategory.DRAWBACK: return StatCatalog.drawback_stat_ids_for_slot(slot)
	return StatCatalog.stat_ids_for_slot(slot,"rare" if category == StatModifier.StatCategory.RARE else "basic")

func mod_snapshot(modifier: StatModifier) -> String:
	return JSON.stringify([modifier.stat_id,modifier.category,modifier.is_drawback,modifier.operation,modifier.value])

func snapshot(item: GearItem) -> String:
	return JSON.stringify(SaveSystem._gear_entry_to_data(item))

func row_type(room: Node, index: int, category: int) -> void:
	var option: OptionButton = room._gear_affix_column.get_child(index).get_node("AffixTypeOption")
	var selected := option.get_item_index(category)
	check(selected >= 0,"Category available on every row")
	option.select(selected)
	option.item_selected.emit(selected)
	await settle()

func row_stat(room: Node, index: int, id: String) -> void:
	var option: OptionButton = room._gear_affix_column.get_child(index).get_child(0)
	for i in option.item_count:
		if option.get_item_metadata(i) == id:
			option.select(i)
			option.item_selected.emit(i)
			await settle()
			return
	check(false,"Stat available in selected pool: " + id)

func check_row(room: Node, item: GearItem, index: int, category: int) -> void:
	var row: Node = room._gear_affix_column.get_child(index)
	var type_option: OptionButton = row.get_node("AffixTypeOption")
	check(type_option.item_count == 3,"Only three legal Chaos roll types")
	check(type_option.get_selected_id() == category,"Selected type reflects modifier")
	var option: OptionButton = row.get_child(0)
	var actual: Array[String] = []
	for i in option.item_count: actual.append(option.get_item_metadata(i))
	check(actual == pool(item.slot,category),"Exact category-specific stat pool")
	var modifier: StatModifier = item.affixes[index]
	check(modifier.category == category and modifier.is_drawback == (category == StatModifier.StatCategory.DRAWBACK),"Category and sign agree")
	var maximum := GearGenerator.max_rolled_value_for_stat_id(modifier.stat_id,item.slot,modifier.is_drawback,GearItem.Tier.CHAOS,1.0,0,"rare" if category == StatModifier.StatCategory.RARE else "basic")
	check(maximum.ok and is_equal_approx(modifier.value,maximum.value),"Stat seeds the actual category/sign Chaos value")
	check(StatCatalog.modifier_validation_error(modifier) == "","Modifier domain valid")

func run() -> void:
	root.size = Vector2i(1600,900)
	root.gui_embed_subwindows = true
	var room = load("res://scenes/training_room/training_room.tscn").instantiate()
	root.add_child(room)
	await settle()
	room._setup_autosave = false
	var state: TrainingRoomState = room._state
	for slot in GearItem.universal_slot_order():
		room._gear_slot_buttons[slot].pressed.emit()
		room._gear_rarity_option.item_selected.emit(room._gear_rarity_option.get_item_index(GearItem.Tier.CHAOS))
		await settle()
		var item: GearItem = room._editing_gear_item
		check(item.affixes.size() == 4,"Chaos has four editable rows")
		for index in 4:
			for category in TYPES:
				var before: Array = item.affixes.map(mod_snapshot)
				await row_type(room,index,category)
				check_row(room,item,index,category)
				for other in 4:
					if other != index: check(mod_snapshot(item.affixes[other]) == before[other],"Other rows unchanged by type selection")
				await row_stat(room,index,pool(slot,category)[-1])
				check_row(room,item,index,category)
		# No hidden position restrictions: four Rare and four negative duplicates.
		for category in [StatModifier.StatCategory.RARE,StatModifier.StatCategory.DRAWBACK]:
			for index in 4:
				await row_type(room,index,category)
				await row_stat(room,index,pool(slot,category)[0])
			check(item.affixes.all(func(m):return m.category == category and m.stat_id == pool(slot,category)[0]),"Four duplicate affixes of independently selected type")
			if slot == GearItem.SlotType.ARMOR:
				await capture(room,"chest_all_rare" if category == StatModifier.StatCategory.RARE else "chest_all_negative")
	# Same ID in Pants Basic and Rare must keep different ranges and selected type.
	room._legs_slot_button.pressed.emit()
	await settle()
	var pants: GearItem = room._editing_gear_item
	for tuple in [[0,StatModifier.StatCategory.BASIC,0.9],[1,StatModifier.StatCategory.RARE,3.0],[2,StatModifier.StatCategory.DRAWBACK,-0.9]]:
		await row_type(room,tuple[0],tuple[1])
		await row_stat(room,tuple[0],"increased_gold")
		check(is_equal_approx(pants.affixes[tuple[0]].value,tuple[2]),"Pants category-overlap gold uses correct range")
	await row_type(room,3,StatModifier.StatCategory.RARE)
	await row_stat(room,3,"increased_magic_find")
	check(is_equal_approx(pants.affixes[3].value,0.6),"Pants Rare MF retains lower range")
	await capture(room,"pants_mixed_types")
	# Explicit numeric edits and reselecting Chaos preserve row identities/types.
	var value_spin: SpinBox = room._gear_affix_column.get_child(0).get_child(1)
	value_spin.value = 12.34
	await settle()
	check(is_equal_approx(pants.affixes[0].value,0.1234),"Manual numeric value remains editable")
	var custom := snapshot(pants)
	state.set_slot_rarity(pants,GearItem.Tier.CHAOS)
	check(snapshot(pants) == custom,"Same Chaos rarity does not overwrite choices/values")
	state.allocation_locked = true
	state.set_chaos_affix_type(pants,0,StatModifier.StatCategory.DRAWBACK)
	state.set_affix_stat(pants,0,"crit_damage")
	check(snapshot(pants) == custom,"Playback lock blocks type/stat edits")
	state.allocation_locked = false
	state.set_chaos_affix_type(pants,0,StatModifier.StatCategory.SPECIAL)
	check(snapshot(pants) == custom,"Chaos cannot select Special")
	# Save fields already carry category/sign/value; load/reopen must not restamp.
	check(PracticeSaveSystem.save_setup(state,true),PracticeSaveSystem.last_error)
	var loaded := TrainingRoomState.new()
	loaded.content_registry = state.content_registry
	loaded.content_registry = state.content_registry
	loaded.practice_save_path = PracticeSaveSystem.core_save_path
	check(PracticeSaveSystem.load_setup(loaded).status == "loaded",PracticeSaveSystem.last_error)
	check(snapshot(loaded.practice_legs) == custom and loaded.practice_legs != pants,"Detached save round trip preserves custom Chaos")
	check(PracticeSaveSystem.load_setup(state).status == "loaded",PracticeSaveSystem.last_error)
	room._legs_slot_button.pressed.emit()
	await settle()
	check(snapshot(room._editing_gear_item) == custom,"Reopening restored current shell preserves custom Chaos")
	await capture(room,"restored_custom_chaos")
	var carried := state.add_carried_item()
	check(carried != null,"Carried fixture acquired")
	check(state.set_carried_slot(carried,GearItem.SlotType.ARMOR),"Carried Chest slot selected")
	state.set_slot_rarity(carried,GearItem.Tier.CHAOS)
	state.set_chaos_affix_type(carried,2,StatModifier.StatCategory.RARE)
	state.set_affix_stat(carried,2,"increased_buff_duration")
	room._show_gear_slot_editor("Carried 1",carried,false)
	await settle()
	check_row(room,carried,2,StatModifier.StatCategory.RARE)
	check(not state.equipped_gear().has(carried),"Carried editing does not equip item")
	# Other rarities keep authored shape and have no Chaos selector.
	room._weapon_slot_button.pressed.emit()
	for tuple in [[GearItem.Tier.BASIC,1],[GearItem.Tier.MASTER,2],[GearItem.Tier.EPIC,3],[GearItem.Tier.CURSED,4],[GearItem.Tier.UNIQUE,5]]:
		room._gear_rarity_option.item_selected.emit(room._gear_rarity_option.get_item_index(tuple[0]))
		await settle()
		check(room._editing_gear_item.affixes.size() == tuple[1],"Other rarity count unchanged")
		for row in room._gear_affix_column.get_children(): check(row.find_child("AffixTypeOption",true,false) == null,"Other rarities have no Chaos type selector")
	evidence = {"checks":checks,"slots":7,"rows_per_slot":4,"types_per_row":3,"pants_snapshot":JSON.parse_string(custom),"save_version":PracticeSaveSystem.SAVE_VERSION,"generator_changed":false}
	check(SaveSystem.write_json(OUT+"evidence.json",evidence),"Evidence saved")
	room.queue_free()
	await settle()
	print("M9 CHAOS EDITOR PASS (%d checks)" % checks)
	quit()
