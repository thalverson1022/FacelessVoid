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
	var dance: Skill = Contracts.skill("dance_of_death")
	var stats := PlayerStats.new()
	stats.dance_duration_ms=dance.dance_duration_ms
	var target := Monster.new()
	target.hp=1000000
	var result := CombatResolver.resolve([dance],stats,target,50000,7,true)
	var panel := CombatEffectIcons.new()
	root.add_child(panel)
	panel.position=Vector2(40,40)
	panel.begin(result)
	var grants := []
	for row in result.trace.presentation_records:
		if row.get("kind")=="effect_lifecycle" and row.get("source_id")==dance.id and row.get("lifecycle_reason")=="granted":
			grants.append(row)
	check(grants.size()==3,"Three real Dance activations in one fight")
	for index in grants.size():
		var row: Dictionary = grants[index]
		var start: int = row.time_ms
		var expiry: int = row.payload.after.expires_at_ms
		panel.advance_to(start)
		check(panel._chips.size()==1 and panel._chips.has("buff.dance"),"Recast retains canonical Dance display")
		if not panel._chips.has("buff.dance"): continue
		var chip = panel._chips["buff.dance"]
		check(chip.get_node("BuffIcon").texture!=null and chip.get_node("BuffIcon").texture==GameIcons.icon_for("buff.dance"),"Recast icon matches original")
		check(chip.tooltip_icon==GameIcons.icon_for("buff.dance") and "5.0s" in chip.tooltip_text,"Tooltip icon and new five-second duration")
		var clock = chip.get_node("Countdown")
		check(clock.visible and is_equal_approx(clock.progress,1.0),"Every activation starts full countdown")
		panel.advance_to(start+2500)
		check(is_equal_approx(clock.progress,.5),"Each activation has independent halfway timer")
		if index==1 and "--visual" in OS.get_cmdline_user_args():
			await process_frame
			await RenderingServer.frame_post_draw
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reports/p6_dance_recast"))
			root.get_texture().get_image().save_png("res://reports/p6_dance_recast/second-cast.png")
		panel.advance_to(expiry)
		check(panel._chips.is_empty(),"Recast expires cleanly")
	panel.begin(result)
	check(panel._chips.is_empty(),"Retry clears recast state")
	panel.advance_to(grants[0].time_ms)
	check(panel._chips.has("buff.dance"),"Retry restores first icon")
	panel.finish(result)
	check(panel._chips.is_empty() and not panel.visible,"Finish clears display")
	panel.queue_free()
	await process_frame
	print("Dance recast display: "+("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
