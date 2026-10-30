extends SceneTree
## Presentation totals use resolved health loss without changing native counters.
const Fixtures = preload("res://tests/t9_combat_feedback_test.gd")
var failures: Array[String] = []
var checks := 0

func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("FAILED: " + message)

static func fixture() -> Dictionary:
	var base := Fixtures.fixture("nightkiss")
	var ex: Skill = base.result.cast_events.filter(func(event): return event.skill.id == "skill.exsanguinate")[0].skill.duplicate(true)
	var setup := Skill.new()
	setup.id = "fixture.mixed_setup"
	setup.display_name = "Mixed setup"
	setup.base_execution_ms = 300
	setup.min_execution_ms = 300
	var damage := PhysicalDamageEffect.new()
	damage.amount = 80
	var poison := PoisonDamageEffect.new()
	poison.stacks_applied = 4
	var shred := ArmorReductionEffect.new()
	shred.amount = 1
	setup.effects = [damage, poison, shred]
	# Exercise ordinary attack and Poison repeats beside the non-repeating Debuff.
	base.stats.special_effects.legendary["coil"] = true
	var skills: Array[Skill] = [ex, setup, ex]
	return {"result": CombatResolver.resolve(skills, base.stats, base.target, 1200, 7, true), "target": base.target}

func run() -> void:
	var f := fixture()
	var r: CombatResolver.CombatResult = f.result
	check(r.is_valid, "mixed resolver fixture is valid")
	var native_damage := r.total_damage
	var native_removal := r.total_health_removed
	var native_dps := r.dps
	check(native_damage > 0 and native_removal > 0 and r.tick_events.any(func(tick): return tick.damage > 0), "fixture contains physical, Poison and Exsanguinate damage")
	var ex_events := r.cast_events.filter(func(event): return event.skill.id == "skill.exsanguinate")
	check(ex_events.any(func(event): return event.origin_kind == "macro" and event.health_removed > 0), "fixture contains positive Exsanguinate root")
	check(ex_events.all(func(event): return event.origin_kind == "macro" and event.retrigger_depth == 0), "Exsanguinate has no repeated contacts at100 percent Retrigger")
	check(ex_events.any(func(event): return event.health_removed == 0), "fixture contains zero-Shred Exsanguinate")
	check(r.cast_events.any(func(event): return event.skill.id == "fixture.mixed_setup" and event.origin_kind == "random_repeat"), "ordinary attacks still repeat beside Exsanguinate")
	check(r.tick_events.any(func(tick): return tick.origin_kind == "poison_repeat"), "Poison still repeats beside Exsanguinate")
	var data := CombatLogInspectorData.build(r, f.target)
	check(is_equal_approx(data.summary.total_damage, native_damage + native_removal), "log total adds removal exactly once")
	check(is_equal_approx(data.summary.actual_dps, (native_damage + native_removal) / 1.2), "log DPS includes removal exactly once")
	var ranked_total := 0.0
	for row in data.damage_rows: ranked_total += row.damage
	check(is_equal_approx(ranked_total, data.summary.total_damage), "mixed damage ranking sums to log total")
	var ex_rows: Array = data.damage_rows.filter(func(row): return row.name == "Exsanguinate")
	check(ex_rows.size() == 1 and ex_rows[0].kind == "cast" and is_equal_approx(ex_rows[0].damage, native_removal), "Exsanguinate roots use normal skill ranking")
	var timeline: Array = data.timeline_rows.filter(func(row): return row.label == "Exsanguinate")
	check(timeline.size() == 1 and timeline[0].kind == "cast" and timeline[0].events.size() == ex_events.size(), "timeline includes every Exsanguinate contact once")
	var timeline_removal := 0.0
	var biggest_removal := 0.0
	for event in timeline[0].events:
		timeline_removal += event.damage
		biggest_removal = maxf(biggest_removal, event.damage)
	check(is_equal_approx(timeline_removal, native_removal) and data.max_event_damage >= biggest_removal, "timeline amounts and scaling include removal")
	var inspector := CombatLogInspector.new()
	root.add_child(inspector)
	inspector.set_result(r, f.target)
	check(inspector.get_child_count() == 5 and inspector._summary_row.get_child_count() == 3, "actual inspector has one damage chart and three normal summary chips")
	var chip_text := ""
	for chip in inspector._summary_row.get_children():
		for label in chip.get_child(0).get_children(): chip_text += label.text + " "
	check(chip_text.contains("%.1f" % data.summary.total_damage) and not chip_text.contains(" / ") and not chip_text.contains("Health removed"), "Adventure chip combines actual damage without target comparison")
	var chart_tip := inspector._damage_chart._get_tooltip(Vector2(100, 7 + data.damage_rows.find(ex_rows[0]) * 28))
	check(chart_tip == "Exsanguinate: %.1f damage" % native_removal, "normal damage chart tooltip describes Exsanguinate")
	var row_y: int = 27 + data.timeline_rows.find(timeline[0]) * 34
	var timeline_tip := inspector._timeline_chart._get_tooltip(Vector2(100, row_y))
	check(timeline_tip.contains("0.0 damage") and not timeline_tip.contains("health removed"), "timeline tooltip uses damage including zero-Shred contacts")
	check(inspector._damage_chart._color_for_kind(ex_rows[0].kind) == UIColors.COMBAT_CHART_CAST, "Exsanguinate ranking uses normal cast color")
	var expected_summary := "Damage: %.1f in %ss -- %.1f DPS." % [data.summary.total_damage, LegendaryCatalog.number_text(r.duration_ms / 1000.0), data.summary.actual_dps]
	for narrative in [CombatResultFormatter.format(r, f.target), CombatResultFormatter.format_practice(r, f.target)]:
		check(narrative.contains(expected_summary) and narrative.contains("Exsanguinate hits for 0.0") and not narrative.contains("Health removed:") and not narrative.contains("removes "), "narrative combines damage and describes zero removal as damage")
	check(r.total_damage == native_damage and r.total_health_removed == native_removal and r.dps == native_dps, "presentation leaves native resolver totals and DPS unchanged")
	var empty := CombatResolver.CombatResult.new()
	empty.duration_ms = 0
	check(CombatLogInspectorData.build(empty).summary.actual_dps == 0 and CombatResultFormatter.format_practice(empty, f.target).contains("0.0 DPS"), "zero-duration presentation avoids division by zero")
	if OS.get_cmdline_user_args().has("--visual"):
		inspector.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for frame in 5: await process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://reports/t9_exsanguinate_log")
		root.get_texture().get_image().save_png("res://reports/t9_exsanguinate_log/mixed_damage.png")
	inspector.queue_free()
	await process_frame
	print("T9_EXSANGUINATE_LOG ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
