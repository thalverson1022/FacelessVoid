extends SceneTree
const Core = preload("res://tests/fixtures/p6/bladedancer_core/core.gd")
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		printerr(message)

func _run() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/ui/icon_assignments.json"))
	check(manifest.entries.size() == 93, "Full mapping coverage")
	for id in manifest.entries:
		var icon := GameIcons.icon_for(id)
		check(icon != null and icon.get_size() == Vector2(32, 32), "Missing/wrong size: " + id)
		check(icon.resource_path == manifest.entries[id].path, "Wrong mapping: " + id)
		var pixels := icon.get_image()
		check(pixels.get_pixel(0, 0).is_equal_approx(Color("5e5d61")), "Missing square border: " + id)
		check(pixels.get_pixel(1, 1).is_equal_approx(Color("28282b")), "Missing charcoal inset: " + id)
		if id.begins_with("skill."):
			var skill := Skill.new()
			skill.id = id
			check(skill.icon == icon and skill.duplicate(true).icon == icon, "Skill getter/copy: " + id)
		if id.begins_with("talent."):
			var talent := Talent.new()
			talent.id = id
			check(talent.icon == icon, "Talent lookup: " + id)
	for buff in GameIcons.DATA.BUFF_SOURCES:
		check(GameIcons.icon_for(buff) == GameIcons.icon_for(GameIcons.DATA.BUFF_SOURCES[buff]), "Buff source mismatch")
	check(GameIcons.icon_for("buff.precision") != GameIcons.icon_for("talent.assassin.precision"), "Precision must follow Precision Attacks")
	var button := IconTooltipButton.new()
	button.tooltip_icon = GameIcons.icon_for("skill.parry_strike")
	var tooltip = button._make_custom_tooltip("Parry Strike")
	check(tooltip.get_child(0).get_child(0).texture == button.tooltip_icon, "Tooltip lost its skill icon")
	tooltip.free()
	button.free()
	var mechanic := RuntimeMechanicDef.from_dictionary({"id": "dodge_chance"})
	check(mechanic.icon_path == GameIcons.icon_for("defense.dodge").resource_path, "Generator mechanic icon lookup")
	var registry := Core.registry()
	var build := Core.build(registry)
	var gear: Array[GearItem] = [load("res://data/gear/crude_dagger.tres")]
	var resolved := BuildResolver.resolve_ranked_build(registry.classes["class.rogue"], build, gear)
	var rotation: Array[Skill] = Core.rotation(resolved.skills)
	var monster := Monster.new()
	monster.hp = 100000
	var result := CombatResolver.resolve(rotation, resolved.stats, monster, 20000, 7, false)
	var traced := CombatResolver.resolve(rotation, resolved.stats, monster, 20000, 7, true)
	check(result.total_damage == traced.total_damage and result.rng_final_state == traced.rng_final_state, "Presentation changed combat outcome")
	check(not result.trace.presentation_records.is_empty(), "Lifecycle stream unavailable in normal fights")
	var panel := CombatEffectIcons.new()
	root.add_child(panel)
	panel.begin(result)
	var shown := false
	for time in range(0, 20000, 100):
		panel.advance_to(time)
		shown = shown or panel.visible
	check(shown, "Real core effects never displayed")
	panel.advance_to(20000)
	check(panel.active.is_empty(), "Fight cleanup left buffs")
	# Verify independent instances, charge consumption and expiry without a later event.
	var fixture := CombatResolver.CombatResult.new()
	fixture.trace.presentation_records.assign([
		{"time_ms": 0, "effect_instance_id": "one", "payload": {"effect_id": "virulent_poison", "after": {"charges": 5, "expires_at_ms": -1}}},
		{"time_ms": 0, "effect_instance_id": "two", "payload": {"effect_id": "virulent_poison", "after": {"charges": 5, "expires_at_ms": -1}}},
		{"time_ms": 0, "effect_instance_id": "enemy", "payload": {"effect_id": "potency", "after": {"units": 3, "expires_at_ms": 500}}},
		{"time_ms": 100, "effect_instance_id": "one", "payload": {"effect_id": "virulent_poison", "after": {"charges": 4, "expires_at_ms": -1}}},
		{"time_ms": 200, "effect_instance_id": "two", "payload": {"effect_id": "virulent_poison", "after": {}}},
	])
	panel.begin(fixture)
	check(panel.active.size() == 3, "Independent instances lost")
	panel.advance_to(100)
	check(panel.active.one.state.charges == 4, "Charge consumption not reflected")
	panel.advance_to(500)
	check(panel.active.size() == 1, "Expiry/consumption not reflected")
	panel.clear()
	check(not panel.visible and panel.active.is_empty(), "Retry reset failed")
	panel.queue_free()
	await process_frame
	print("Icon assignment and effect presentation: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
