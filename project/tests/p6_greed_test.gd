extends SceneTree
const Contracts = preload("res://scripts/systems/p6_thief_contracts.gd")
var failed := false
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, label: String) -> void:
	if not ok:
		failed=true
		printerr("FAILED: "+label)
func _run() -> void:
	var stats := PlayerStats.new()
	stats.current_gold=499
	stats.gold_reward_multiplier=1.5
	stats.crit_chance=1.0
	stats.retrigger_chance=1.0
	var target := Monster.new()
	target.hp=1000000
	var rotation: Array[Skill] = [Contracts.skill("pick_pocket"),Contracts.skill("steal")]
	var result := CombatResolver.resolve(rotation,stats,target,5000,7,true)
	var panel := CombatEffectIcons.new()
	root.add_child(panel)
	panel.begin(result)
	check(panel.model.units("buff.greed")==0 and not panel._chips.has("buff.greed"),"Starting stash gives no Greed")
	panel.advance_to(1799)
	check(panel.model.units("buff.greed")==0,"No Greed before theft impact")
	panel.advance_to(1800)
	check(panel.model.units("buff.greed")==15,"Greed uses Increased Gold credit once")
	check(panel._chips.has("buff.greed") and panel._chips["buff.greed"].get_node("StackCount").text=="15","Live icon shows credited count")
	check(panel._chips["buff.greed"].get_node("BuffIcon").texture==GameIcons.icon_for("buff.greed"),"Supplied Greed icon")
	check(not panel._chips["buff.greed"].get_node("Countdown").visible,"Greed has no expiry countdown")
	panel.advance_to(3100)
	check(panel.model.stolen>15 and panel.model.units("buff.greed")==panel.model.stolen,"Steal and repeated theft update absolute total")
	panel.model.apply({"kind":"gold_transaction","time_ms":3100,"payload":{"credited_amount":0,"stash_after":1,"stolen_after":1500}})
	panel._render()
	check(panel._chips["buff.greed"].get_node("StackCount").text=="1500","Count uncapped and independent of stash")
	panel._refresh_inspector()
	check("Greed | 1500 stacks" in panel._details.text,"Inspector describes Greed stacks")
	panel.finish(result)
	check(not panel.visible and panel.model.units("buff.greed")==0,"Finish removes Greed")
	panel.begin(result)
	check(panel.model.units("buff.greed")==0,"Retry resets Greed")
	panel.advance_to(1800)
	check(panel.model.units("buff.greed")==15,"Retry deterministically rebuilds Greed")
	panel.clear()
	check(panel._chips.is_empty() and panel.model.stolen==0,"Exit/reset clears stacks")
	panel.queue_free()
	await process_frame
	print("Greed presentation: "+("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
