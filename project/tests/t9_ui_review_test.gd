extends SceneTree
## Actual production surfaces, fixtures and explicit capture placement; isolated runner only.
var checks := 0
var shots: Array[String] = []
var geometry: Array = []
const OUT := "res://reports/t9_ui_review"
func _initialize() -> void: call_deferred("run")
func ck(ok: bool, message: String) -> void:
	assert(ok, message)
	checks += 1
func labels(node: Node) -> String:
	var text := ""
	if node is Label: text += node.text + "\n"
	if node is RichTextLabel: text += node.get_parsed_text() + "\n"
	for child in node.get_children(): text += labels(child)
	return text
func capture(name: String) -> void:
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png(OUT + "/" + name + ".png")
		shots.append(name)
func fits(node: Control, name: String) -> void:
	var rect := node.get_global_rect()
	geometry.append({"name":name,"x":rect.position.x,"y":rect.position.y,"width":rect.size.x,"height":rect.size.y})
	print("GEOMETRY ",name," ",rect)
	ck(Rect2(Vector2.ZERO,Vector2(1280,720)).grow(1).encloses(rect),name + " fits1280x720")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	DirAccess.make_dir_recursive_absolute("res://prototype_saves/t9")
	SaveSystem.save_path = "res://prototype_saves/t9/adventure_ui.json"
	PracticeSaveSystem.core_save_path = "res://prototype_saves/t9/practice_ui.json"
	var s = root.get_node("BuildState")
	var game = load("res://scenes/game_root.tscn").instantiate()
	root.add_child(game)
	await process_frame
	s.set_class(load("res://data/classes/rogue.tres"))
	s.gold = 631
	var adventure_before := JSON.stringify(SaveSystem._serialize(s))
	game._current_screen.training_room_pressed.emit()
	await process_frame
	var room = game._current_screen
	for item in LegendaryCatalog.all_items():
		var custom: GearItem
		match item.slot:
			GearItem.SlotType.WEAPON: custom = room._state.practice_weapon
			GearItem.SlotType.HELM: custom = room._state.practice_helm
			GearItem.SlotType.ARMOR: custom = room._state.practice_armor
			GearItem.SlotType.CHARM: custom = room._state.practice_charm
			GearItem.SlotType.TRINKET: custom = room._state.practice_trinket
		room._show_gear_slot_editor(GearGenerator.universal_slot_label(item.slot),custom,item.slot == GearItem.SlotType.WEAPON)
		room._state.equip_legendary(item)
		room._refresh_gear_editor()
		room._gear_legendary_option.grab_focus()
		await process_frame
		ck(room._legendary_details.visible and labels(room._legendary_details).contains("Legendary Effect:"),"fixed details visible " + item.id)
		ck(labels(room._legendary_details).contains(LegendaryCatalog.effect_text(item)),"actual selector effect text " + item.id)
		ck(get_root().gui_get_focus_owner() == room._gear_legendary_option,"selector keyboard focus " + item.id)
		fits(room._legendary_details,item.id)
		await capture("practice_"+item.id.trim_prefix("gear.legendary."))
	ck(JSON.stringify(SaveSystem._serialize(s)) == adventure_before,"Practice presentation preserves Adventure snapshot")
	game.queue_free()
	await process_frame
	# Actual Adventure dashboard, shop cards and production comparison tooltips.
	s.reset()
	s.set_class(load("res://data/classes/rogue.tres"))
	s.gold = 5000
	s.current_encounter_index = 1
	s.shop_round_pending = true
	s.mysterious_coin_unlocked = true
	s.equipped_weapon = load("res://data/gear/decrepit_blade.tres")
	s.equipped_helm = load("res://data/gear/crown_of_concertation.tres")
	s.equipped_armor = load("res://data/gear/deaths_door.tres")
	s.equipped_charm = load("res://data/gear/lolzorzs_locket.tres")
	s.equipped_trinket = load("res://data/gear/wingjammer.tres")
	s.shop_offers.assign([load("res://data/gear/signet_of_the_old_kings.tres"),load("res://data/gear/nightkiss_kitana.tres"),load("res://data/gear/helm_of_the_samurai.tres")])
	var screen = load("res://scenes/combat/combat_screen.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	var shop = screen._shop_overlay
	screen._map_overlay.hide()
	shop.show()
	shop.refresh()
	await process_frame
	await process_frame
	await capture("adventure_shop")
	var before := JSON.stringify(SaveSystem._serialize(s))
	var button = shop._shop_offers_box.get_child(0)
	var tip = button._make_custom_tooltip(button.tooltip_text)
	var tooltip_layer := CanvasLayer.new()
	tooltip_layer.layer = 200
	screen.add_child(tooltip_layer)
	tooltip_layer.add_child(tip)
	tip.position = Vector2(12,12)
	await process_frame
	await process_frame
	await capture("signet_compare_inspection")
	fits(tip,"actual shop Signet comparison")
	ck(labels(tip).contains("Cannot crit"),"actual Signet comparison explains crit suppression")
	await capture("adventure_signet_comparison")
	ck(JSON.stringify(SaveSystem._serialize(s)) == before,"tooltip and compare rendering cannot change gameplay state")
	tip.queue_free()
	await process_frame
	var mystery: GearItem = load("res://data/gear/mysterious_lucky_coin.tres")
	s.mysterious_coin_unlocked = false
	s.shop_offers.assign([mystery])
	shop.refresh()
	await process_frame
	await process_frame
	var locked = shop._shop_offers_box.get_child(0)
	ck(locked.disabled and locked.tooltip_text.contains("Not unlocked for this run.") and not locked.tooltip_text.contains("Inventory full"),"locked offer has correct disabled feedback")
	s.mysterious_coin_unlocked = true
	s.inventory.assign([mystery])
	shop.refresh()
	await process_frame
	await process_frame
	ck(shop._shop_offers_box.get_child(0).disabled and shop._shop_offers_box.get_child(0).tooltip_text.contains("Already owned."),"owned offer has correct disabled feedback")
	s.inventory.clear()
	s.mysterious_coin_unlocked = false
	var ordinary: GearItem = load("res://data/gear/lucky_coin.tres")
	s.inventory.append(ordinary)
	var gear = screen._gear_panel
	gear._refresh()
	gear._confirm_destroy_inventory_item(ordinary)
	gear._on_destroy_confirmed()
	ck(s.mysterious_coin_unlocked and not s.inventory.has(ordinary) and gear.find_child("LegendaryDiscoveryNotice",true,false) == null,"actual Coin destruction unlocks silently")
	await capture("coin_discovery")
	s.reset()
	gear._refresh()
	ck(not s.mysterious_coin_unlocked and gear.find_child("LegendaryDiscoveryNotice",true,false) == null,"new run resets unlock without a stale discovery message")
	var file := FileAccess.open(OUT+"/witness.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"shots":shots,"geometry":geometry},"\t"))
	print("PASS T9 actual UI checks=",checks," screenshots=",shots.size())
	screen.queue_free()
	await process_frame
	quit()
