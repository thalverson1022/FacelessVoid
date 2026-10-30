extends SceneTree
## M11 T4 current ranked Adventure build-panel journey. Original preserved in work/m11_t4_panels.
## Focused check for the five build-facing dashboard panels (talent,
## available skills, skill build/rotation, character stats, gear). Drives the
## real combat_screen.tscn scene against BuildState, same pattern as
## dashboard_header_test.gd. Optional --visual captures inspect the actual1600x900 viewport.


func _initialize() -> void:
	var build_state = root.get_node("BuildState")
	build_state.reset()

	var combat_scene: PackedScene = load("res://scenes/combat/combat_screen.tscn")
	var combat_screen = combat_scene.instantiate()
	root.add_child(combat_screen)
	await process_frame

	root.size = Vector2i(1600, 900)
	root.gui_embed_subwindows = true
	var registry := BuildContentRegistry.adventure()
	_require(registry.error == "", "Current registry validates")
	var rogue: ClassDef = registry.classes["class.rogue"]
	var bladedancer: SubclassTree = registry.trees["tree.bladedancer"]
	build_state.set_class(rogue)
	_require(build_state.configure_ranked_build(bladedancer), "Current ranked Adventure primary")
	await process_frame
	await process_frame
	# Panel-isolated preparation fixture: normal entry/story/map flow is covered by T2/T3.
	# Dismiss those unrelated modal contexts before driving panel controls.
	for field in ["_story_overlay", "_map_overlay", "_contract_overlay", "_secondary_subclass_overlay"]:
		var overlay: Control = combat_screen.get(field)
		if overlay != null: overlay.hide()
	_require(not combat_screen._story_overlay.visible, "Panel fixture clears story modal")
	var talent_panel = combat_screen._talent_overlay._talent_panel
	var active_talents_panel = combat_screen.find_child("ActiveTalentsPanel", true, false)
	var available_skills_panel = combat_screen.find_child("AvailableSkillsPanel", true, false)
	var skill_build_panel = combat_screen.find_child("SkillBuildPanel", true, false)
	var character_stats_panel = combat_screen.find_child("CharacterStatsPanel", true, false)
	var gear_panel = combat_screen.find_child("GearPanel", true, false)
	_require(talent_panel != null and active_talents_panel != null and available_skills_panel != null and skill_build_panel != null and character_stats_panel != null and gear_panel != null, "Expected all build panels to be found.")

	# 1. Current ranked allocation distinguishes budget from lower-tier gates.
	var view = talent_panel._ranked_view
	var foundational: Talent = registry.talents["talent.bladedancer.weakness"]
	var gated: Talent = registry.talents["talent.bladedancer.precision_attacks"]
	_require(view.reason(foundational, "buy") == "No unspent points.", "Zero budget explains lock")
	view.actions["buy:" + foundational.id].pressed.emit()
	_require(build_state.ranked_build.points_spent() == 0, "Blocked budget click changes nothing")
	# -- 2. Points budget display: star icon + "spent/earned", kept stable
	# even when points are unspent so the warning state comes from
	# color/button treatment instead of changing sentence structure. --
	_require(not _talent_panel_text(talent_panel).contains(": 0/0"), "Expected Talent Trees overlay to omit the duplicate points footer.")
	_require(_talent_panel_text(talent_panel).contains("Secondary"), "Expected one-tree Talent panel to explain the future second subclass slot.")
	_require(_talent_panel_text(talent_panel).contains("Primary"), "Expected Talent Trees overlay to frame the chosen tree as the Primary column.")
	_require(_talent_panel_text(talent_panel).contains("Secondary"), "Expected Talent Trees overlay to frame the future second tree as the Secondary column.")
	_require(active_talents_panel._points_label.text == ": 0/0", "Expected active talent summary to show zero points, got: %s" % active_talents_panel._points_label.text)
	_require(active_talents_panel._points_badge != null and active_talents_panel._points_badge is PanelContainer, "Expected Active Talents points readout to sit inside a framed badge.")
	var points_header: Node = active_talents_panel._points_badge.get_parent()
	_require(points_header is HBoxContainer, "Expected Active Talents points badge to live in a header row beside the title.")
	_require(points_header.get_child_count() == 2 and points_header.get_child(1) == active_talents_panel._points_badge, "Expected Active Talents points badge to be right-aligned in the top header row.")
	_require(active_talents_panel._points_label.get_parent().find_child("Icon", true, false) != null, "Expected Active Talents points readout to include the talent-point star icon.")
	_require(points_header.get_child(0).text == "Subclass", "Expected compact Subclass title.")
	_require(active_talents_panel.find_children("*", "ScrollContainer", true, false).is_empty(), "Expected the fixed inline Subclass card to need no scroll area.")
	_require(active_talents_panel._talents_box.get_child_count() == 3, "Expected inline primary, divider and secondary groups.")
	_require(active_talents_panel._talents_box.get_child(0).get_node("SubclassName").text == "Bladedancer", "Expected primary subclass name.")
	var secondary_row: HBoxContainer = active_talents_panel._talents_box.get_child(2)
	_require(secondary_row.get_node("SubclassName").text == "none", "Expected missing secondary subclass to read none.")
	_require(secondary_row.get_node("EmptySubclassIcon") is ColorRect, "Expected gray square for missing secondary subclass.")
	_require(not _active_talents_text(active_talents_panel).contains("Intrinsic:"), "Expected intrinsic information only in Talent Trees.")
	var subclass_height: float = active_talents_panel.size.y
	build_state.add_talent_points(1)
	await process_frame
	await process_frame
	_require(view.reason(gated, "buy").contains("5 points in lower tiers"), "Current gate distinguishes lower-tier requirement from budget")
	_require(view.talent_tooltip(gated).contains(gated.display_name), "Ranked hover identifies gated talent")
	_require(not _talent_panel_text(talent_panel).contains(": 0/1"), "Expected Talent Trees overlay to keep omitting the duplicate points footer after earning a point.")
	_require(active_talents_panel._points_label.text == ": 0/1", "Expected active talent summary to show unspent point budget, got: %s" % active_talents_panel._points_label.text)
	_require(active_talents_panel._open_button.text == "Talent Trees", "Expected Active Talents button copy to stay stable when points are unspent.")
	_require(active_talents_panel._open_button.custom_minimum_size == active_talents_panel.OPEN_BUTTON_SIZE, "Expected Talent Trees button to keep a fixed minimum size.")
	_require(active_talents_panel._button_blink_tween != null and active_talents_panel._button_blink_tween.is_running(), "Expected Active Talents button to blink when points are unspent.")
	_require(not active_talents_panel._open_button.has_theme_stylebox_override("normal"), "Expected unspent-points alert to avoid stylebox overrides that can change button layout.")
	view.actions["buy:" + foundational.id].pressed.emit()
	_require(build_state.ranked_build.rank_of(foundational.id) == 1, "Actual ranked node buys rank1")
	await process_frame
	_require(active_talents_panel._points_label.text == ": 1/1", "Expected active talent summary to update spent points, got: %s" % active_talents_panel._points_label.text)
	_require(active_talents_panel._open_button.text == "Talent Trees", "Expected Active Talents button to return to neutral copy when all points are spent.")
	_require(active_talents_panel._button_blink_tween == null, "Expected Active Talents button blink to stop when all points are spent.")
	_require(not _active_talents_text(active_talents_panel).contains("Weakness"), "Expected allocated talent information to remain in Talent Trees.")
	_require(is_equal_approx(active_talents_panel.size.y, subclass_height), "Expected allocation to preserve compact Subclass height.")
	_require(not combat_screen._talent_overlay.visible, "Expected Talent Trees overlay hidden by default.")
	active_talents_panel._open_button.pressed.emit()
	await process_frame
	_require(combat_screen._talent_overlay.visible, "Expected Active Talents button to open the Talent Trees overlay.")
	combat_screen._talent_overlay.visible = false

	# -- 3. Skill effect summary text is derived from the skill's own
	# SkillEffect resources. P2:R7 playtest feedback (2026-07-18) found T4's
	# always-visible caption redundant with the hover tooltip and removed
	# it -- the summary now lives in the tooltip only; _skill_effect_summary()
	# itself is unchanged and still feeds both the tooltip and this direct
	# check. --
	var hold: Skill = rogue.base_skills[0]
	_require(hold.display_name == "Hold", "Expected rogue.base_skills[0] to be Hold.")
	var stab: Skill = rogue.base_skills[1]
	_require(stab.display_name == "Stab", "Expected rogue.base_skills[1] to be Stab.")
	var heavy_slash: Skill = rogue.base_skills[2]
	_require(heavy_slash.display_name == "Heavy Slash", "Expected rogue.base_skills[2] to be Heavy Slash.")
	var summary: String = available_skills_panel._skill_effect_summary(stab)
	print("Stab effect summary (expect dynamic damage range): %s" % summary)
	_require(summary == "%d-%d physical dmg" % [build_state.current_player_stats().weapon_damage_min, build_state.current_player_stats().weapon_damage_max], "Expected Stab's summary text to use resolved weapon damage, got: %s" % summary)
	var hold_button: Button = available_skills_panel._skills_box.get_child(0)
	_require(hold_button is Button, "Expected each available-skills child to be a bare Button (no always-visible caption wrapper).")
	_require(hold_button._get_tooltip(Vector2.ZERO).contains("Wait without attacking."), "Expected the first available skill button to be Hold, got tooltip: %s" % hold_button.tooltip_text)
	var stab_button: Button = available_skills_panel._skills_box.get_child(1)
	_require(stab_button._get_tooltip(Vector2.ZERO).contains(preload("res://scripts/ui/skill_hover_formatter.gd").model(build_state.unlocked_skills()[1],build_state).damage), "Expected Stab's tooltip to contain its effect summary, got: %s" % stab_button.tooltip_text)
	var hold_summary: String = available_skills_panel._skill_effect_summary(hold)
	_require(hold_summary == "Holds for 1.0s", "Expected Hold's summary text to explain the no-action wait, got: %s" % hold_summary)
	# -- 4. Rotation order + explicit remove control --
	_require(skill_build_panel._slot_count_label.text == "Slots: 0/10", "Expected empty Skill Build to advertise current macro capacity, got: %s" % skill_build_panel._slot_count_label.text)
	var disabled_lock_style: StyleBoxFlat = skill_build_panel._lock_button.get_theme_stylebox("disabled")
	_require(disabled_lock_style.bg_color == UIColors.PANEL_DISABLED, "Expected disabled Lock Build button to use the shared disabled fill.")
	_require(disabled_lock_style.corner_radius_top_left == skill_build_panel.LOCK_BUTTON_CORNER_RADIUS, "Expected disabled Lock Build button to stay circular instead of falling back to a square style.")
	build_state.set_locked(true)
	_require(not build_state.build_locked, "Expected an empty Adventure macro to refuse the lock/ready state.")
	for skill in build_state.unlocked_skills():
		available_skills_panel._on_skill_pressed(skill)
	await process_frame
	_require(build_state.rotation.size() == build_state.unlocked_skills().size(), "Every current unlocked skill enters rotation.")
	_require(build_state.rotation.map(func(skill: Skill): return skill.display_name) == build_state.unlocked_skills().map(func(skill: Skill): return skill.display_name), "Expected macro order to follow the Hold-first UI order.")
	_require(skill_build_panel._slot_count_label.text == "Slots: %d/10" % build_state.rotation.size(), "Expected Skill Build count to update after adding skills, got: %s" % skill_build_panel._slot_count_label.text)
	_require(skill_build_panel._lock_button.text == "", "Expected lock toggle button to be icon-only, got: %s" % skill_build_panel._lock_button.text)
	_require(skill_build_panel._lock_button.custom_minimum_size == skill_build_panel.LOCK_BUTTON_SIZE, "Expected lock toggle to keep a large fixed button size.")
	_require(skill_build_panel._lock_button.icon == null, "Expected Lock Build button to use the custom child icon, not Button.icon.")
	_require(skill_build_panel._lock_button_icon.texture == skill_build_panel.UNLOCK_ICON, "Expected editable Lock Build button to show the open lock icon.")
	_require(skill_build_panel._lock_button_icon.custom_minimum_size == skill_build_panel.LOCK_BUTTON_ICON_SIZE, "Expected Lock Build icon to keep a fixed readable size.")
	_require(skill_build_panel._lock_button_icon.size == skill_build_panel.LOCK_BUTTON_ICON_SIZE, "Expected Lock Build icon rect to obey its fixed size, got: %s" % skill_build_panel._lock_button_icon.size)
	build_state.set_locked(true)
	await process_frame
	skill_build_panel.set_combat_interaction_locked(true)
	_require(skill_build_panel._lock_button.disabled, "Expected the lock button to be disabled during active combat.")
	_require(skill_build_panel._lock_button.tooltip_text.contains("combat"), "Expected combat-locked macro tooltip to explain why unlocking is blocked.")
	skill_build_panel._lock_button.pressed.emit()
	_require(build_state.build_locked, "Expected pressing the disabled combat lock button not to unlock the macro.")
	skill_build_panel.set_combat_interaction_locked(false)
	_require(not skill_build_panel._lock_button.disabled, "Expected the lock button to be usable again after combat ends.")
	skill_build_panel._lock_button.pressed.emit()
	await process_frame
	_require(not build_state.build_locked, "Expected the lock button to unlock normally after combat ends.")
	var first_slot: Button = skill_build_panel._slots_box.get_child(0)
	_require(first_slot.custom_minimum_size == skill_build_panel.SLOT_SIZE, "Expected macro slots to use the approved shared macro slot size.")
	print("first slot tooltip (expect position 1 of 4): %s" % first_slot.tooltip_text)
	_require(first_slot.tooltip_text.contains("Hold"), "Expected the first macro slot to be Hold after the Hold-first Rogue order, got: %s" % first_slot.tooltip_text)
	_require(not first_slot._get_tooltip(Vector2.ZERO).contains("Slot 1"), "Expected the minimal skill tooltip to omit slot instruction clutter, got: %s" % first_slot.tooltip_text)
	var has_remove_badge := false
	for child in first_slot.get_children():
		if child is Label and child.text == "x":
			has_remove_badge = true
	_require(not has_remove_badge, "Minimal macro slots omit an x badge; selection and Remove handle removal.")
	skill_build_panel.highlight_rotation_index(1)
	var highlighted_slot: Button = skill_build_panel._slots_box.get_child(1)
	var highlighted_style: StyleBoxFlat = highlighted_slot.get_theme_stylebox("normal")
	_require(highlighted_style.border_color == skill_build_panel.ACTIVE_SLOT_COLOR, "Expected combat playback to highlight the active macro slot.")
	skill_build_panel.set_cast_progress(1, 0.5)
	_require(is_equal_approx(skill_build_panel._slot_fills[1].anchor_right, 0.5), "Expected active macro slot fill to show cast progress.")
	_require(is_equal_approx(skill_build_panel._slot_fills[0].anchor_right, 0.0), "Expected inactive macro slots to stay empty.")
	skill_build_panel.set_slow_effect_active(true)
	skill_build_panel.set_cast_progress(1, 0.5)
	_require(skill_build_panel._slot_fills[1].color == skill_build_panel.SLOW_PROGRESS_FILL_COLOR, "Expected slowed fights to tint ordinary macro cast progress cold blue.")
	skill_build_panel.set_cast_progress(1, 1.0, true)
	_require(skill_build_panel._slot_fills[1].color == skill_build_panel.PROC_PROGRESS_FILL_COLOR, "Expected proc/min-cast progress to use the purple fill.")
	skill_build_panel.set_slow_effect_active(false)
	skill_build_panel.play_stun_effect(500, false)
	_require(skill_build_panel.stun_effect_count == 1, "Expected non-animated stun playback to still record the stun event.")
	_require(skill_build_panel.last_stun_duration_ms == 500, "Expected the macro stun effect to remember the stun duration.")
	_require(not skill_build_panel.is_stun_effect_active(), "Expected non-animated stun playback not to leave macro slots dimmed.")
	_require(skill_build_panel._slot_buttons[0].modulate == Color.WHITE, "Expected non-animated stun playback to preserve the normal macro slot color.")
	for overlay in skill_build_panel._slot_stun_overlays:
		_require(not overlay.visible and is_equal_approx(overlay.progress, 0.0), "Expected non-animated stun playback not to leave cooldown overlays visible.")
	skill_build_panel.play_stun_effect(80, true)
	_require(skill_build_panel.is_stun_effect_active(), "Expected animated stun playback to gray out the macro bar.")
	for slot in skill_build_panel._slot_buttons:
		_require(slot.modulate == skill_build_panel.STUNNED_SLOT_MODULATE, "Expected every macro slot to use the stunned gray modulate.")
	for overlay in skill_build_panel._slot_stun_overlays:
		_require(overlay.visible, "Expected every macro slot to show the stunned cooldown overlay.")
		_require(is_equal_approx(overlay.progress, 1.0), "Expected stunned cooldown overlays to begin full.")
	await create_timer(0.04).timeout
	var mid_stun_progress: float = skill_build_panel._slot_stun_overlays[0].progress
	_require(mid_stun_progress > 0.0 and mid_stun_progress < 1.0, "Expected stunned cooldown overlay progress to tick down during stun.")
	await create_timer(0.08).timeout
	_require(not skill_build_panel.is_stun_effect_active(), "Expected macro stun gray-out to clear after the stun duration.")
	for slot in skill_build_panel._slot_buttons:
		_require(slot.modulate == Color.WHITE, "Expected macro slots to restore their normal color after stun.")
	for overlay in skill_build_panel._slot_stun_overlays:
		_require(not overlay.visible and is_equal_approx(overlay.progress, 0.0), "Expected stunned cooldown overlays to hide after stun.")
	skill_build_panel.play_stun_effect(200, true, 4.0)
	_require(skill_build_panel.is_stun_effect_active(), "Expected sped-up stun playback to gray out the macro bar.")
	await create_timer(0.08).timeout
	_require(not skill_build_panel.is_stun_effect_active(), "Expected macro stun cooldown to respect playback speed when clearing.")
	for overlay in skill_build_panel._slot_stun_overlays:
		_require(not overlay.visible and is_equal_approx(overlay.progress, 0.0), "Expected sped-up stun cooldown overlays to hide after their scaled duration.")
	skill_build_panel.highlight_rotation_index(1, true)
	highlighted_style = highlighted_slot.get_theme_stylebox("normal")
	_require(highlighted_style.border_color == skill_build_panel.PULSE_SLOT_COLOR, "Expected proc/retrigger playback to pulse the active macro slot.")
	skill_build_panel.set_interrupt_locked_skill(stab, true)
	var stab_slot_index := -1
	for rotation_index in build_state.rotation.size():
		if build_state.rotation[rotation_index].id == stab.id:
			stab_slot_index = rotation_index
			break
	_require(stab_slot_index >= 0, "Expected Stab to be present in the macro before checking its interrupt overlay.")
	_require(skill_build_panel._slot_interrupt_overlays[stab_slot_index].visible, "Expected an interrupted skill to show a no-entry overlay on its macro slot.")
	for overlay_index in skill_build_panel._slot_interrupt_overlays.size():
		if overlay_index != stab_slot_index:
			_require(not skill_build_panel._slot_interrupt_overlays[overlay_index].visible, "Expected unrelated macro slots to stay clear of the interrupt overlay.")
	skill_build_panel.clear_interrupt_locks()
	_require(not skill_build_panel._slot_interrupt_overlays[stab_slot_index].visible, "Expected clearing interrupt locks to hide the no-entry overlay.")
	var quick_cut: Skill = load("res://data/skills/quick_cut.tres")
	var duplicate_interrupt_rotation: Array[Skill] = [stab, quick_cut, stab]
	build_state.set_rotation(duplicate_interrupt_rotation)
	await process_frame
	skill_build_panel.set_interrupt_locked_skill(stab, true)
	_require(skill_build_panel._slot_interrupt_overlays[0].visible and skill_build_panel._slot_interrupt_overlays[2].visible, "Expected interrupt locks to mark every macro slot using the locked skill.")
	_require(not skill_build_panel._slot_interrupt_overlays[1].visible, "Expected different skills between duplicate locked slots to stay unlocked.")
	skill_build_panel.clear_interrupt_locks()
	build_state.set_rotation(build_state.unlocked_skills())
	await process_frame
	highlighted_slot = skill_build_panel._slots_box.get_child(1)
	skill_build_panel.clear_combat_highlight()
	highlighted_style = highlighted_slot.get_theme_stylebox("normal")
	_require(highlighted_style.border_color == CardStyle.ACCENT_COLOR, "Expected clearing playback to restore the normal slot border.")

	# Locking the build hides the remove badge (clicking does nothing then).
	build_state.set_locked(true)
	await process_frame
	_require(skill_build_panel._lock_button.text == "", "Expected locked macro button to remain icon-only, got: %s" % skill_build_panel._lock_button.text)
	_require(skill_build_panel._lock_button_icon.texture == skill_build_panel.LOCK_ICON, "Expected locked Lock Build button to show the closed lock icon.")
	var locked_button_style: StyleBoxFlat = skill_build_panel._lock_button.get_theme_stylebox("normal")
	_require(locked_button_style.bg_color == UIColors.BUTTON_FILL_PRESSED, "Expected locked Lock Build button to use the pushed-in dark fill.")
	first_slot = skill_build_panel._slots_box.get_child(0)
	has_remove_badge = false
	for child in first_slot.get_children():
		if child is Label and child.text == "x":
			has_remove_badge = true
	_require(not has_remove_badge, "Expected the remove badge to disappear once the build is locked.")
	build_state.set_locked(false)
	await process_frame

	var rotation_before: int = build_state.rotation.size()
	skill_build_panel._on_slot_pressed(0)
	_require(build_state.rotation.size() == rotation_before, "Selecting preserves rotation")
	skill_build_panel._remove_selected()
	_require(build_state.rotation.size() == rotation_before - 1, "Expected removing a rotation slot to shrink the rotation.")

	# -- 5. Stat delta from base: Piercing Blades now improves the universal
	# Shred value instead of physical damage. --
	var stats_text: String = character_stats_panel._stats_label.text
	print("")
	print("-- Character stats panel raw text (expect requested compact stat list) --")
	print(stats_text)
	_require(stats_text.contains("Shred Chance: 0%"), "Expected compact stats to keep Shred Chance visible, got: %s" % stats_text)
	_require(not stats_text.contains("Shred: 30"), "Expected compact stats to hide raw Shred value, got: %s" % stats_text)
	_require(not stats_text.contains("from gear/talents"), "Expected character stats to avoid source-bucket explanation text, got: %s" % stats_text)
	var visible_stats_text: String = character_stats_panel._stats_label.get_parsed_text()
	print("visible (parsed) stats text: %s" % visible_stats_text)
	_require(not visible_stats_text.contains("from gear/talents"), "Expected the delta note to stay hidden from visible text, got: %s" % visible_stats_text)
	_require(not visible_stats_text.contains("Shred: 30"), "Expected compact stats to hide the raw Shred value, got: %s" % visible_stats_text)
	var delta: String = character_stats_panel._stat_delta_text(8.0, "%")
	print("stat delta helper output: %s" % delta)
	_require(delta == " (+8%)", "Expected _stat_delta_text() to format a positive delta, got: %s" % delta)
	_require(character_stats_panel._stat_delta_text(0.0, "%") == "", "Expected a ~zero delta to produce no note.")

	# -- 6. Equipped vs inventory gear clarity --
	# This layout fixture needs exactly two inventory items and one free slot.
	# Class selection now grants a starter dagger; exclude it from this fixture
	# so swapping weapons does not add an unintended third inventory item.
	build_state.equipped_weapon = null
	build_state.inventory.clear()
	var dagger: GearItem = load("res://data/gear/placeholder_dagger.tres")
	var lucky_coin: GearItem = load("res://data/gear/lucky_coin.tres")
	var test_inventory_weapon := GearItem.new()
	test_inventory_weapon.id = "test.inventory.weapon_compare"
	test_inventory_weapon.display_name = "Test Inventory Dagger"
	test_inventory_weapon.slot = GearItem.SlotType.WEAPON
	test_inventory_weapon.tier = GearItem.Tier.BASIC
	var test_inventory_mod := StatModifier.new()
	test_inventory_mod.stat = StatModifier.StatType.ATTACK_SPEED
	test_inventory_mod.operation = StatModifier.OperationType.ADD
	test_inventory_mod.value = 0.04
	test_inventory_weapon.affixes = [test_inventory_mod]
	_require(build_state.grant_gear(dagger, true), "Expected the dagger to be granted and auto-equipped.")
	_require(build_state.grant_gear(lucky_coin, false), "Expected Lucky Coin to land in inventory.")
	_require(build_state.grant_gear(test_inventory_weapon, false), "Expected the test comparison weapon to land in inventory.")
	await process_frame

	var equipped_style: StyleBoxFlat = gear_panel._weapon_slot.get_theme_stylebox("panel")
	var empty_style: StyleBoxFlat = gear_panel._helm_slot.get_theme_stylebox("panel")
	print("equipped weapon slot border color (expect CardStyle.ACCENT_COLOR): %s" % equipped_style.border_color)
	_require(equipped_style.border_color == CardStyle.ACCENT_COLOR, "Expected the equipped weapon slot to carry the accent border, got: %s" % equipped_style.border_color)
	_require(equipped_style.border_color != empty_style.border_color, "Expected equipped and empty slots to use different border colors.")
	_require(equipped_style.border_width_top > empty_style.border_width_top, "Expected the equipped slot's border to be thicker than an empty slot's.")

	# P2:R7 gear-art pass: equipped/empty slots show a real icon (over the
	# existing tier-colored background) instead of a blank colored square.
	# Placeholder Dagger has no named icon of its own, so it falls back to
	# the generic Basic Weapon icon.
	var weapon_icon: TextureRect = gear_panel._weapon_slot.get_node("Icon")
	_require(weapon_icon.texture == GearIcons.BASIC_WEAPON_ICON, "Expected the equipped weapon slot to show the generic Basic Weapon icon.")
	var empty_helm_icon: TextureRect = gear_panel._helm_slot.get_node("Icon")
	_require(empty_helm_icon.texture == null, "Expected an empty slot's icon to stay unset.")

	var inventory_slot: Button = gear_panel._inventory_grid.get_child(0)
	var inventory_style: StyleBoxFlat = inventory_slot.get_theme_stylebox("normal")
	_require(UIColors.TIER_BASIC == Color("72B953"), "Expected Basic gear to preserve the original green rarity color.")
	_require(UIColors.TIER_MASTER == Color("4E8AC5"), "Expected Master gear to preserve the original blue rarity color.")
	_require(UIColors.TIER_CURSED == Color("9D73D8"), "Expected Cursed gear to preserve the original purple rarity color.")
	_require(UIColors.TIER_LEGENDARY == Color("E3914C"), "Expected Legendary gear to preserve the original orange rarity color.")
	_require(inventory_style.bg_color == UIColors.TIER_BASIC.darkened(0.08), "Expected rendered Basic inventory slots to derive from the original green rarity color.")
	_require(inventory_style.border_color != CardStyle.ACCENT_COLOR, "Expected inventory items to keep the plain slot border, distinct from equipped items.")

	# Inventory item boxes carry the same icon as shop item boxes, shared via
	# CardStyle.build_gear_box_content() (P2:R7 gear-art pass). Lucky Coin is
	# a fixed Basic Charm with its own named icon. The caption text this used to
	# carry alongside the icon was dropped as redundant once the icon art +
	# tier-colored background conveyed slot/tier on their own.
	var inventory_icon: TextureRect = inventory_slot.get_node("Icon")
	_require(inventory_icon.texture == GearIcons.LUCKY_COIN_ICON, "Expected the inventory box to show Lucky Coin's own named icon.")
	var empty_inventory_slot: Button = gear_panel._inventory_grid.get_child(2)
	_require(empty_inventory_slot.get_node_or_null("Icon") == null, "Expected empty inventory slots to stay icon-free.")

	_require(not gear_panel._weapon_slot.tooltip_text.contains("Left-click to unequip"), "Expected the equipped-slot tooltip to omit the old left-click instruction block, got: %s" % gear_panel._weapon_slot.tooltip_text)
	_require(not gear_panel._weapon_slot.tooltip_text.contains("Right-click for actions"), "Expected the equipped-slot tooltip to omit the old right-click instruction block, got: %s" % gear_panel._weapon_slot.tooltip_text)
	_require(not inventory_slot.tooltip_text.contains("Left-click to equip"), "Expected the inventory-slot tooltip to omit the old control-instruction block, got: %s" % inventory_slot.tooltip_text)
	_require(not inventory_slot.tooltip_text.contains("Right-click for actions"), "Expected the inventory-slot tooltip to omit the old right-click instruction block, got: %s" % inventory_slot.tooltip_text)
	var inventory_compare_slot: Button = gear_panel._inventory_button_for_item(test_inventory_weapon)
	_require(inventory_compare_slot is GearCompareButton, "Expected filled inventory slots to use the same custom comparison tooltip button as shop/reward gear.")
	var inventory_compare_tooltip: Control = inventory_compare_slot._make_custom_tooltip("")
	_require(inventory_compare_tooltip is HBoxContainer, "Expected the inventory comparison tooltip to be a compact HBox.")
	_require(inventory_compare_tooltip.get_child_count() == 1, "D055 shows only hovered item box")
	var hover_text := _labels_text(inventory_compare_tooltip)
	_require(hover_text.contains(test_inventory_weapon.display_name), "Hover identifies carried item")
	_require(not hover_text.contains("Equipped") and not hover_text.contains("On equip"), "D055 omits equipped comparison and projection")
	if "--visual" in OS.get_cmdline_user_args():
		combat_screen.add_child(inventory_compare_tooltip)
		inventory_compare_tooltip.position = Vector2(930, 350)
		await _capture(combat_screen, "inventory_hover_d055")
	inventory_compare_tooltip.free()

	var right_click_event := InputEventMouseButton.new()
	right_click_event.button_index = MOUSE_BUTTON_RIGHT
	right_click_event.pressed = true
	inventory_slot.gui_input.emit(right_click_event)
	await process_frame
	gear_panel._inventory_action_menu.position = Vector2i(1370, 700)
	await _capture(combat_screen, "inventory_actions")
	_require(gear_panel._pending_inventory_action_item == lucky_coin, "Expected right-click to target the clicked inventory item.")
	_require(gear_panel._inventory_action_menu.get_item_count() == 3, "Expected inventory action menu to contain Equip, Sell, and Destroy.")
	_require(gear_panel._inventory_action_menu.get_item_text(0) == "Equip", "Expected first inventory action to be Equip.")
	_require(gear_panel._inventory_action_menu.get_item_text(1) == "Sell", "Expected second inventory action to be Sell.")
	_require(gear_panel._inventory_action_menu.get_item_text(2) == "Destroy", "Expected third inventory action to be Destroy.")
	_require(gear_panel._inventory_action_menu.is_item_disabled(gear_panel._inventory_action_menu.get_item_index(gear_panel.ACTION_SELL_ID)), "Expected Sell to be disabled outside shop.")
	_require(not gear_panel._inventory_action_menu.is_item_disabled(gear_panel._inventory_action_menu.get_item_index(gear_panel.ACTION_DESTROY_ID)), "Expected Destroy to be available outside shop.")
	_require(gear_panel._gold_label.text.ends_with("g"), "Expected the Gear-panel gold stash readout to keep the 'g' suffix, got: %s" % gear_panel._gold_label.text)
	_require(not gear_panel._gold_label.text.contains("Gold:"), "Expected the Gear-panel gold stash readout to use icon + value instead of repeating 'Gold:', got: %s" % gear_panel._gold_label.text)
	_require(gear_panel._gold_badge != null and gear_panel._gold_badge is PanelContainer, "Expected the Gear-panel gold stash readout to sit inside a framed badge.")
	var gold_header: Node = gear_panel._gold_badge.get_parent()
	_require(gold_header is HBoxContainer, "Expected the Gear-panel gold stash badge to live in a header row beside the title.")
	_require(gold_header.get_child_count() == 2 and gold_header.get_child(1) == gear_panel._gold_badge, "Expected the Gear-panel gold stash badge to be right-aligned in the top header row.")
	_require(gear_panel._gold_row.find_child("Icon", true, false) != null, "Expected the Gear-panel gold stash readout to include the gold icon.")
	_require(gear_panel._gold_icon != null and gear_panel._gold_icon.is_inside_tree(), "Expected reward/sale gold motion to target the visible gold icon, not the stretched gold row.")
	var equipment_doll := gear_panel._helm_slot.get_parent().get_parent() as HBoxContainer
	_require(equipment_doll != null and equipment_doll.get_child_count() == 3, "Seven-slot doll has three columns")
	_require(gear_panel._hands_slot.get_parent().get_child(0) == gear_panel._weapon_slot, "Gloves below weapon")
	_require(gear_panel._legs_slot.get_parent().get_child(1) == gear_panel._armor_slot, "Pants below chest")
	_require(gear_panel._charm_slot.get_parent().get_child(1) == gear_panel._trinket_slot, "Charm above trinket")
	_require(gear_panel._equipped_panel_for_slot(GearItem.SlotType.HANDS) == gear_panel._hands_slot, "Gloves route")
	_require(gear_panel._equipped_panel_for_slot(GearItem.SlotType.LEGS) == gear_panel._legs_slot, "Pants route")
	_require(gear_panel._equipped_panel_for_slot(GearItem.SlotType.HELM) == gear_panel._helm_slot, "Expected Helm slot routing to target the live Helm panel.")
	_require(gear_panel._equipped_panel_for_slot(GearItem.SlotType.ARMOR) == gear_panel._armor_slot, "Expected Armor slot routing to target the live Armor panel.")
	_require(gear_panel._equipped_panel_for_slot(GearItem.SlotType.CHARM) == gear_panel._charm_slot, "Expected Charm slot routing to target the live Charm panel.")
	_require(gear_panel._equipped_panel_for_slot(GearItem.SlotType.TRINKET) == gear_panel._trinket_slot, "Expected Trinket slot routing to target the live Trinket panel.")
	gear_panel._inventory_action_menu.hide()
	gear_panel._pending_inventory_action_item = null
	gear_panel._show_inventory_action_menu(null)
	_require(gear_panel._pending_inventory_action_item == null, "Expected empty inventory slots to leave the action-menu target unset.")

	gear_panel._inventory_button_for_item(lucky_coin).pressed.emit()
	await process_frame
	_require(build_state.equipped_trinket == lucky_coin, "Expected left-clicking an inventory item to equip it outside the shop.")
	_require(not build_state.has_inventory_item(lucky_coin), "Expected equipped Lucky Coin to leave inventory after left-click equip.")

	var bandit_blade: GearItem = load("res://data/gear/bandit_blade.tres")
	build_state.equip(bandit_blade)
	await process_frame
	_require(gear_panel._weapon_slot.tooltip_text.contains("+1 Base Physical Damage (max +100) per 10g in stash"), "Expected equipped Bandit Blade tooltip to include Legendary flavor text, got: %s" % gear_panel._weapon_slot.tooltip_text)

	gear_panel._weapon_slot.gui_input.emit(right_click_event)
	await process_frame
	_require(gear_panel._pending_equipped_action_slot == GearItem.SlotType.WEAPON, "Expected right-click to target the equipped weapon slot.")
	_require(gear_panel._equipped_action_menu.get_item_count() == 3, "Expected equipped action menu to contain Unequip, Sell, and Destroy.")
	_require(gear_panel._equipped_action_menu.get_item_text(0) == "Unequip", "Expected first equipped action to be Unequip.")
	_require(gear_panel._equipped_action_menu.get_item_text(1) == "Sell", "Expected second equipped action to be Sell.")
	_require(gear_panel._equipped_action_menu.get_item_text(2) == "Destroy", "Expected third equipped action to be Destroy.")
	_require(not gear_panel._equipped_action_menu.is_item_disabled(gear_panel._equipped_action_menu.get_item_index(gear_panel.ACTION_UNEQUIP_ID)), "Expected Unequip to be enabled when inventory has room.")
	_require(gear_panel._equipped_action_menu.is_item_disabled(gear_panel._equipped_action_menu.get_item_index(gear_panel.ACTION_SELL_ID)), "Expected equipped Sell to be disabled outside shop.")
	_require(not gear_panel._equipped_action_menu.is_item_disabled(gear_panel._equipped_action_menu.get_item_index(gear_panel.ACTION_DESTROY_ID)), "Expected equipped Destroy to be available outside shop.")
	gear_panel._equipped_action_menu.hide()
	gear_panel._pending_equipped_action_slot = -1

	# Clicking the equipped weapon slot outside a shop round now unequips it
	# to inventory (previously a no-op unless swapping in a replacement).
	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	gear_panel._weapon_slot.gui_input.emit(click_event)
	await process_frame
	print("weapon after unequip click (expect null): %s" % build_state.equipped_weapon)
	_require(build_state.equipped_weapon == null, "Expected clicking the equipped weapon slot to unequip it.")
	_require(build_state.has_inventory_item(bandit_blade), "Clicked equipped Bandit Blade returns to inventory")
	_require(build_state.has_inventory_item(dagger), "Expected the unequipped dagger to land back in the inventory.")
	_require(gear_panel._inventory_button_for_item(dagger) != null, "Expected the freshly unequipped dagger to have a stable destination inventory button for movement feedback.")

	# 7. Tier dependency replaces retired legacy OR graph/pulse contract.
	build_state.set_locked(false)
	build_state.add_talent_points(5)
	for rank_index in range(4):
		view.actions["buy:" + foundational.id].pressed.emit()
		await process_frame
		await process_frame
	_require(build_state.ranked_build.rank_of(foundational.id) == 5, "Five legal foundational ranks")
	view.actions["buy:" + gated.id].pressed.emit()
	await process_frame
	await process_frame
	_require(build_state.ranked_build.rank_of(gated.id) == 1, "Tier gate opens after five supporting ranks")
	var refund := InputEventMouseButton.new()
	refund.button_index = MOUSE_BUTTON_RIGHT
	refund.pressed = true
	view.actions["buy:" + foundational.id].gui_input.emit(refund)
	_require(build_state.ranked_build.rank_of(foundational.id) == 5, "Dependency blocks supporting-rank refund")
	_require(view.reason(foundational, "refund") != "", "Blocked refund has explanatory hover reason")
	view.actions["buy:" + gated.id].gui_input.emit(refund)
	await process_frame
	await process_frame
	_require(build_state.ranked_build.rank_of(gated.id) == 0, "Right-click refunds dependent first")
	view.actions["buy:" + foundational.id].gui_input.emit(refund)
	await process_frame
	await process_frame
	_require(build_state.ranked_build.rank_of(foundational.id) == 4, "Supporting rank refunds after dependency removed")
	await _capture(combat_screen, "dashboard")
	active_talents_panel._open_button.pressed.emit()
	await _capture(combat_screen, "ranked_talents")
	combat_screen.queue_free()
	await process_frame


	print("")
	print("M11 T4 build panels PASS: %d checks" % checks)
	quit()


var checks := 0

func _require(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		push_error(message)
		assert(condition, message)


func _active_talents_text(active_talents_panel) -> String:
	var parts: PackedStringArray = []
	for label in active_talents_panel.find_children("*", "Label", true, false):
		parts.append(label.text)
	return "\n".join(parts)


func _labels_text(root_node: Node) -> String:
	var parts: PackedStringArray = []
	for label in root_node.find_children("*", "Label", true, false):
		parts.append((label as Label).text)
	for label in root_node.find_children("*", "RichTextLabel", true, false):
		parts.append((label as RichTextLabel).get_parsed_text())
	return "\n".join(parts)


func _talent_panel_text(talent_panel) -> String:
	var parts: PackedStringArray = []
	for label in talent_panel.find_children("*", "Label", true, false):
		parts.append(label.text)
	return "\n".join(parts)


func _talent_node_buttons(talent_panel) -> Dictionary:
	var buttons := {}
	for node in talent_panel.find_children("*", "Button", true, false):
		if node.has_meta("talent_id"):
			buttons[node.get_meta("talent_id")] = node
	return buttons


func _capture(_screen: Node, label: String) -> void:
	if not "--visual" in OS.get_cmdline_user_args(): return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	_require(root.get_texture().get_image().save_png("res://reports/m11_t4_panels_capture/" + label + ".png") == OK, "Actual1600x900 capture")

