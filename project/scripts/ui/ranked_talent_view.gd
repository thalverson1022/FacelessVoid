extends VBoxContainer
## Shared ranked allocation view. Transactions stay in the state/model.
var state
var feedback := ""
var pending := false
var focus_key := ""
var actions: Dictionary = {}

class Links extends Control:
	var slots: Dictionary = {}
	var columns := 1
	var tier_count := 5

	func arrange() -> void:
		for id in nodes:
			var slot: Vector2 = slots[id]
			nodes[id].position = Vector2(slot.x * size.x - 30, (tier_count - 1 - slot.y) * 68)
			nodes[id].size = Vector2(60, 60)
		queue_redraw()

	var nodes: Dictionary = {}
	var edges: Array = []
	func _draw() -> void:
		for edge in edges:
			if not nodes.has(edge[0]) or not nodes.has(edge[1]):
				continue
			var source: Control = nodes[edge[0]]
			var target: Control = nodes[edge[1]]
			var a := source.global_position - global_position + Vector2(source.size.x / 2, 0)
			var b := target.global_position - global_position + Vector2(target.size.x / 2, target.size.y)
			draw_line(a, b, UIColors.STRUCTURE_LINE_LIGHT, 2, true)

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 14)
	state.build_changed.connect(schedule_refresh)
	state.lock_changed.connect(schedule_refresh)
	if state.has_signal("run_state_changed"):
		state.run_state_changed.connect(schedule_refresh)
	refresh()

func schedule_refresh() -> void:
	if pending:
		return
	pending = true
	refresh.call_deferred()

func label(text: String, parent: Node, font_size: int = 17) -> Label:
	var value := Label.new()
	value.text = text
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value.add_theme_font_size_override("font_size", font_size)
	parent.add_child(value)
	return value

func friendly(text: String) -> String:
	for tree in state.selected_class.trees:
		text = text.replace(tree.id, tree.display_name)
		for talent in tree.talents:
			text = text.replace(talent.id, talent.display_name)
	return text

func practice() -> bool:
	return state is TrainingRoomState

func edit_block() -> String:
	if practice():
		return "Finish or skip playback before editing." if state.allocation_locked else ""
	if state.run_phase not in [state.RunPhase.PLANNING, state.RunPhase.CONTRACT_ROUTE, state.RunPhase.CONTRACT_OFFER]:
		return "Talent editing is available during planning."
	return ""

func refresh() -> void:
	pending = false
	if state.ranked_build == null:
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and is_ancestor_of(focused):
		focus_key = focused.get_meta("action_key", focus_key)
	for child in get_children():
		remove_child(child)
		child.queue_free()
	actions.clear()
	var model: RankedBuild = state.ranked_build
	var toolbar := HBoxContainer.new()
	toolbar.visible = not practice()
	add_child(toolbar)
	var summary := Control.new()
	toolbar.add_child(summary)
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not practice() and state.get("is_test_mode") == true:
		var comparison := OptionButton.new()
		comparison.name = "CategoryTreeIconStyle"
		for text in ["Unlocks: Outline", "Unlocks: Bottom edge", "Unlocks: Filled box", "Unlocks: Off"]:
			comparison.add_item(text)
		comparison.select(int(state.get_meta("category_tree_icon_style", 2)))
		comparison.add_theme_font_override("font", preload("res://assets/fonts/VT323-Regular.ttf"))
		comparison.add_theme_font_size_override("font_size", 18)
		toolbar.add_child(comparison)
		comparison.item_selected.connect(func(index): state.set_meta("category_tree_icon_style", index))
	var notice := label(feedback, self)
	notice.name = "AllocationFeedback"
	notice.visible = feedback != "" and feedback not in ["Allocation updated.", "Secondary selected.", "Tree selection updated."]
	notice.add_theme_color_override("font_color", UIColors.TEXT_GOLD)
	var trees := HBoxContainer.new()
	trees.name = "TreesSideBySide"
	trees.add_theme_constant_override("separation", 16)
	add_child(trees)
	build_tree(model.primary_tree(), trees, "Primary")
	build_tree(model.secondary_tree(), trees, "Secondary")
	var restriction := edit_block()
	if restriction == "" and not practice() and not state.can_respec():
		restriction = "Refunds are available during Tavern planning and between contracts. Purchases remain available during planning."
	var reset_notice := label(restriction, self, 16)
	reset_notice.name = "ResetPointsNotice"
	reset_notice.visible = restriction != ""
	if actions.has(focus_key):
		actions[focus_key].grab_focus.call_deferred()

func build_tree_picker(slot: int, parent: Container) -> void:
	var picker := OptionButton.new()
	picker.name = "PrimaryTreeOption" if slot == 0 else "SecondaryTreeOption"
	picker.add_item("None")
	var selected: SubclassTree = state.tree_at_slot(slot)
	for tree in state.selected_class.trees:
		picker.add_item(tree.display_name)
		var other: SubclassTree = state.tree_at_slot(1 - slot)
		picker.set_item_disabled(picker.item_count - 1, other != null and other.id == tree.id)
		if selected != null and selected.id == tree.id:
			picker.select(picker.item_count - 1)
	picker.set_meta("action_key", picker.name)
	actions[picker.name] = picker
	picker.disabled = edit_block() != "" or (slot == 1 and state.tree_at_slot(0) == null)
	picker.item_selected.connect(func(index: int):
		var tree: SubclassTree = null if index == 0 else state.selected_class.trees[index - 1]
		var ok: bool = state.set_primary_tree(tree) if slot == 0 else state.set_secondary_tree(tree)
		feedback = "Tree selection updated." if ok else friendly(state.last_build_error)
		schedule_refresh()
	)
	parent.add_child(picker)

static func effects(talent: Talent, rank: int) -> String:
	if rank == 0:
		return "Not allocated"
	var data: TalentRank = talent.ranks[rank - 1]
	var parts: PackedStringArray = []
	for modifier in data.stat_modifiers:
		if data.toxic_tradeoff_rank > 0 and modifier.stat_id == "percent_physical_damage":
			continue # Explained once with the paired Poison bonus below.
		if modifier.stat_id == "shred_value":
			parts.append("+%d Shred Value (armor removed per stack)" % roundi(modifier.value))
		else:
			parts.append(StatModifierFormatter.format(modifier))
	if data.hastened_poison_rank > 0:
		parts.append("Apply %d%% of increased attack speed to Poison tick rate. Adds with Accelerant." % (10 * data.hastened_poison_rank))
	if data.accelerant_rank > 0:
		parts.append("Apply an additional %d%% of increased attack speed to Poison tick rate." % (10 * data.accelerant_rank))
	if data.echoing_toxin_rank > 0:
		parts.append("Natural and forced Poison ticks use up to 2 stacks, with no bonus damage. Adds %d%% Suppression to natural ticks. Forced ticks are not delayed. Tick depletion is not Consume." % (50 - 10 * data.echoing_toxin_rank))
	if data.resonance_rank > 0:
		parts.append("Poison ticks use up to 3 stacks instead of 2 and deal %d%% more damage per stack used. Echoing Toxin's Suppression still applies." % (5 * data.resonance_rank))
	if data.toxic_tradeoff_rank > 0:
		parts.append("Poison ticks deal %d%% more damage; physical damage deals %d%% less. Separate factors before conversion. Other elemental damage is unchanged." % [10 * data.toxic_tradeoff_rank, 10 * data.toxic_tradeoff_rank])
	if data.critical_poison_enabled:
		parts.append("Each fueled natural or forced Poison tick can crit using current critical chance and damage. No direct-hit critical triggers.")
	if data.bypass_enabled:
		parts.append("Stab grants Bypass after child effects: 3 seconds, max 3 stacks. Each adds 10% elemental damage, up to 30%. Grants refresh the shared timer.")
	if data.death_pact_rank > 0:
		parts.append("Consuming Poison or Decay grants the actual consumed count to both Penetration and Potency. Both last %d seconds, regardless of source. Tick depletion is not Consume." % (3 + data.death_pact_rank))
	if data.death_blade_rank > 0:
		parts.append("Each Poison application that adds stacks has a %d%% chance to trigger Stab. Stab cannot apply Poison from any source; ordinary Retrigger rules still apply." % (40 * data.death_blade_rank))
	if data.dusk_strike_enabled:
		parts.append("Positive Decay applications also apply 1 base Shred, independently modified by Shred stack bonuses and doubling.")
	if data.umbral_presence_enabled:
		parts.append("Raises the Poison stack cap to 80.")
	for augment in data.skill_augments:
		if augment.poison_stacks_applied > 0:
			parts.append("Stab and Heavy Slash apply %d base Poison on connected hits. Stack bonuses apply; Death Blade suppresses all Stab Poison." % augment.poison_stacks_applied)
	if data.footwork_rank > 0:
		parts.append("Quick Cut grants Footwork (3s, max 5 stacks). Leaping Plunge consumes stacks for %d%% less windup per stack, respecting the minimum cast time." % (data.footwork_rank * 4))
	if data.precision_enabled:
		parts.append("Quick Cut hits grant Precision before child effects (untimed, max 1). Stab or Heavy Slash consumes it for one guaranteed Retrigger if it hits. Dance does not add a second guarantee.")
	if data.riposte_rank > 0:
		parts.append("Each Footwork stack consumed increases that Leaping Plunge's damage by %d%%." % (20 * data.riposte_rank))
	if data.side_step_enabled:
		parts.append("Parry Strike has 100% crit chance. Enemy critical-damage negation still applies.")
	if data.shred_cleanse_immune:
		parts.append("Your Shred cannot be cleansed. Bonus stacks increase each eligible application, not the 500-stack cap.")
	if data.bribery_base_stacks > 0:
		parts.append("Each theft that credits gold applies %d base Shred stacks, regardless of gold amount. Stack bonuses apply." % data.bribery_base_stacks)
	if data.finders_keepers_rank > 0:
		parts.append("Enemies begin combat with %d%% less block. Later Penetration can reduce it further." % (50 * data.finders_keepers_rank))
	if data.gilded_blade_enabled:
		parts.append("Each gold in your stash adds 1% crit damage, counting up to 500 gold.")
	if data.silvered_edge_rank > 0:
		parts.append("Each gold stolen this fight adds 1%% crit chance, up to %d%% from this talent. Starting gold and rewards do not count." % (25 * data.silvered_edge_rank))
	if talent.id == "talent.sticky_fingers":
		parts.append("Multiplies with your Thief intrinsic and gear gold multiplier.")
	if talent.id == "talent.thief.charisma":
		parts.append("Adds to gear discounts. Positive-price items cost at least 1 gold.")
	if talent.id == "talent.thief.load_dice":
		parts.append("Increases eligible gear-quality upgrade chances; does not add extra drops.")
	for rule in data.stat_derivations:
		match rule.kind:
			"shadow_mastery": parts.append("Copy %d%% of flat elemental bonuses into physical base and of the effective elemental percentage bonus into a separate physical multiplier. Elemental bonuses remain. Excludes class base Poison and Poison-only damage bonuses." % roundi(rule.fraction * 100))
			"fast_hands": parts.append("Gain attack speed equal to %d%% of your total Increased Gold bonus." % roundi(rule.fraction * 100))
			"fill_your_pockets": parts.append("Gain a separate elemental damage bonus equal to %d%% of your Magic Find." % roundi(rule.fraction * 100))
			"double_dip": parts.append("Gain crit chance equal to %d%% of numeric Retrigger Chance. Guaranteed Retriggers do not count." % roundi(rule.fraction * 100))
			"sharpened_edge": parts.append("Stab and Heavy Slash deal %d%% more physical damage, before conversion." % roundi(rule.fraction * 100))
	for skill in talent.unlocked_skills:
		parts.append("Unlocks " + skill.display_name)
	for trigger in data.triggered_skill_effects:
		parts.append("Quick Cut: %d%% chance to trigger %s on a connected hit." % [roundi(trigger.chance * 100), trigger.skill.display_name])
	return "; ".join(parts) if not parts.is_empty() else "See skill effects and combat details."

func centered_label(text: String, parent: Node, font_size: int) -> Label:
	var value := label(text, parent, font_size)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return value

func tree_identity(tree: SubclassTree, parent: Container) -> Label:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var icon: Texture2D = tree.icon
	if icon == null:
		var icons := {
			"tree.bladedancer": preload("res://assets/subclass_icons/rogue/bladedancer.png"),
			"tree.thief": preload("res://assets/subclass_icons/rogue/thief.png"),
		}
		icon = icons.get(tree.id)
	if icon != null:
		row.add_child(CardStyle.make_pixel_icon(icon, Vector2(48, 48)))
	var title := label(tree.display_name, row, 28)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.add_theme_color_override("font_color", UIColors.TEXT_GOLD)
	return title

func intrinsic_summary(tree: SubclassTree) -> String:
	var override_text:=preload("res://scripts/ui/talent_hover_formatter.gd").intrinsic_override(tree)
	if override_text!="": return "Intrinsic: "+override_text
	var parts: PackedStringArray = []
	for modifier in tree.innate_modifiers:
		parts.append(tree_modifier_text(modifier))
	return preload("res://scripts/ui/presentation_keywords.gd").normalize("Intrinsic: " + (", ".join(parts) if not parts.is_empty() else "No base stat bonus"))

func tree_modifier_text(modifier: StatModifier) -> String:
	var text := StatModifierFormatter.format(modifier).replace("Chance for Retrigger", "Retrigger chance")
	var catalog = preload("res://scripts/systems/stat_catalog.gd")
	var kind: String = catalog.value_kind_for(catalog.canonical_id_for_modifier(modifier))
	if kind in [catalog.VALUE_PERCENT, catalog.VALUE_CHANCE]:
		var number := String.num(modifier.value * 100.0, 3).trim_suffix(".0")
		text = ("+" if modifier.value >= 0 else "") + number + "% " + text.split(" ", true, 1)[1]
	elif kind == catalog.VALUE_FLAT and not is_equal_approx(modifier.value, roundf(modifier.value)):
		var number := String.num(modifier.value, 3).trim_suffix(".0")
		text = ("+" if modifier.value >= 0 else "") + number + " " + text.split(" ", true, 1)[1]
	return text

func bonus_summary(tree: SubclassTree, primary: bool) -> String:
	if not primary or tree.primary_point_modifiers.is_empty():
		return "Bonus: NONE"
	var parts: PackedStringArray = []
	for modifier in tree.primary_point_modifiers:
		parts.append(tree_modifier_text(modifier) + " per invested point" + ("" if tree.id in ["tree.thief","tree.assassin","tree.shadow"] else " (primary only)"))
	return preload("res://scripts/ui/presentation_keywords.gd").normalize("Bonus: " + ", ".join(parts))

func unlock_tooltip(skill: Skill) -> String:
	if skill.get_meta("display_only", false):
		return skill.display_name + "\nDraft: " + str(skill.get_meta("draft_description", "Description pending.")) + "\nPreview - not yet playable"
	return preload("res://scripts/ui/skill_hover_formatter.gd").plain_text(preload("res://scripts/ui/skill_hover_formatter.gd").model(skill,state))


func build_tree(tree: SubclassTree, parent: Container, role: String) -> void:
	var model: RankedBuild = state.ranked_build
	var panel := PanelContainer.new()
	panel.name = role + "TreePanel"
	panel.custom_minimum_size = Vector2(450, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var panel_style := CardStyle.make_stylebox(12)
	panel_style.bg_color = Color("100d09")
	panel.add_theme_stylebox_override("panel", panel_style)
	parent.add_child(panel)
	var column := VBoxContainer.new()
	column.name = "TreeColumn_" + (tree.id.replace(".", "_") if tree != null else role.to_lower())
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	if practice(): build_tree_picker(0 if role == "Primary" else 1, column)
	if tree == null:
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		centered_label(role, column, 26).theme_type_variation = &"PanelHeader"
		if practice() and role == "Secondary":
			centered_label("Choose a secondary subclass", column, 16)
			return
		centered_label("Second Subclass" if role == "Secondary" else "Primary Subclass", column, 28)
		centered_label(("Choose one of your earned subclass offers." if practice() or state.needs_secondary_subclass_choice() else "Complete your first contract to unlock a second subclass.") if role == "Secondary" else "Choose a primary tree to begin.", column, 16)
		if role == "Secondary" and state.needs_secondary_subclass_choice() and model.primary_tree() != null:
			for choice in state.secondary_subclass_choices():
				if choice == model.primary_tree(): continue
				var card := PanelContainer.new()
				card.name = "SecondaryChoice_" + choice.id.replace(".", "_")
				card.add_theme_stylebox_override("panel", CardStyle.make_stylebox(12))
				column.add_child(card)
				var details := VBoxContainer.new()
				details.add_theme_constant_override("separation", 12)
				card.add_child(details)
				tree_identity(choice, details)
				centered_label(intrinsic_summary(choice), details, 16)
				centered_label(bonus_summary(choice, false), details, 16)
				var choose := Button.new()
				choose.text = "Choose"
				choose.tooltip_text = "Choose " + choice.display_name + " as your secondary tree."
				choose.disabled = edit_block() != ""
				actions["secondary:" + choice.id] = choose
				choose.pressed.connect(func():
					var ok: bool = state.set_secondary_tree(choice) if practice() else state.choose_secondary_tree(choice)
					feedback = "Secondary selected." if ok else friendly(state.last_build_error)
					schedule_refresh()
				)
				details.add_child(choose)
		return
	var backdrop:=preload("res://scripts/ui/talent_tree_backdrop.gd").new()
	backdrop.tree_id=tree.id
	panel.add_child(backdrop)
	panel.move_child(backdrop,0)
	var header := VBoxContainer.new()
	header.custom_minimum_size.y = 102
	header.add_theme_constant_override("separation", 2)
	column.add_child(header)
	var role_label := centered_label(role, header, 24)
	role_label.theme_type_variation = &"PanelHeader"
	if tree != null:
		var capacity := 0
		for talent in tree.talents:
			capacity += talent.max_ranks
		var counter := PanelContainer.new()
		counter.name = "TreePointCounter"
		counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		role_label.add_child(counter)
		counter.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		counter.offset_left = -56
		counter.offset_bottom = 26
		var counter_style := CardStyle.make_stylebox(3)
		counter_style.content_margin_left = 7
		counter_style.content_margin_right = 7
		counter.add_theme_stylebox_override("panel", counter_style)
		var count := Label.new()
		count.name = "TreePoints"
		count.text = "%d/%d" % [model.tree_points(tree), capacity]
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		count.add_theme_font_override("font", CardStyle.DATA_FONT)
		count.add_theme_font_size_override("font_size", 16)
		counter.add_child(count)
	var heading := tree_identity(tree, header)
	centered_label(intrinsic_summary(tree), header, 16)
	centered_label(bonus_summary(tree, role == "Primary"), header, 16)
	var information: PackedStringArray = []
	for modifier in tree.innate_modifiers: information.append(StatModifierFormatter.format(modifier))
	for modifier in tree.primary_point_modifiers:
		information.append("Per primary point: " + tree_modifier_text(modifier))
	information.append("Primary scaling applies to %d points; secondary receives base benefits only." % (model.tree_points(tree) if tree == model.primary_tree() else 0))
	for unlock in tree.automatic_unlocks:
		if unlock.skill != null: information.append("%d points: %s" % [unlock.required_points, unlock.skill.display_name])
	heading.tooltip_text = "\n".join(information)
	# Only the view sees the full draft structure. State retains playable resources.
	var display := preload("res://scripts/ui/full_tree_display.gd").tree_for(tree)
	var graph := Links.new()
	graph.name = "TalentGraph_" + tree.id.replace(".", "_")
	column.add_child(graph)
	# Reserve the entire span of each dependency before placing unrelated nodes.
	# This keeps long links straight and prevents a skipped tier blocking a link.
	var occupied := {}
	var groups: Array = []
	for talent in display.talents:
		var group: Array = [talent.id]
		for prerequisite in talent.prerequisite_ids:
			group.append(prerequisite)
			graph.edges.append([prerequisite, talent.id])
		var merged := true
		while merged:
			merged = false
			for existing in groups.duplicate():
				if group.any(func(id): return id in existing):
					for id in existing:
						if id not in group: group.append(id)
					groups.erase(existing)
					merged = true
		groups.append(group)
	groups.sort_custom(func(a, b): return a.size() > b.size())
	for group in groups:
		var low := 1000
		var high := 0
		for id in group:
			var tier := tier_for(RankedBuild._talent(display, id), display)
			low = mini(low, tier)
			high = maxi(high, tier)
		var lane := 0
		while true:
			var free := true
			for tier in range(low, high + 1):
				if occupied.has(Vector2i(lane, tier)): free = false
			if free: break
			lane += 1
		for tier in range(low, high + 1): occupied[Vector2i(lane, tier)] = true
		graph.columns = maxi(graph.columns, lane + 1)
		graph.tier_count = maxi(graph.tier_count, high + 1)
		for id in group:
			graph.slots[id] = Vector2i(lane, tier_for(RankedBuild._talent(display, id), display))
	var authored: Dictionary = display.get_meta("authored_layout", {})
	for id in graph.slots:
		var fallback: Vector2i = graph.slots[id]
		graph.slots[id] = authored.get(id, Vector2((fallback.x + 0.5) / graph.columns, fallback.y))
	for talent in display.talents:
		var card := talent_card(talent, tree)
		graph.add_child(card)
		graph.nodes[talent.id] = card
	graph.custom_minimum_size = Vector2(426 if not authored.is_empty() else graph.columns * 92, (graph.tier_count - 1) * 68 + 60)
	graph.resized.connect(graph.arrange)
	graph.arrange.call_deferred()
	build_skill_unlocks(display, column)
	var reset := Button.new()
	reset.text = "reset"
	reset.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	reset.add_theme_font_override("font", CardStyle.DATA_FONT)
	reset.add_theme_font_size_override("font_size", 16)
	var reset_style := CardStyle.make_stylebox(3)
	reset_style.content_margin_left = 7
	reset_style.content_margin_right = 7
	for mode in ["normal", "hover", "pressed", "disabled"]:
		reset.add_theme_stylebox_override(mode, reset_style)
	reset.size_flags_horizontal = Control.SIZE_SHRINK_END
	var key := "reset:" + tree.id
	reset.set_meta("action_key", key)
	actions[key] = reset
	reset.disabled = edit_block() != "" or (not practice() and not state.can_respec())
	reset.tooltip_text = "Reset points in " + tree.display_name + " only."
	reset.pressed.connect(func():
		focus_key = key
		feedback = "Allocation updated." if state.refund_tree_talents(tree.id) else friendly(state.last_build_error)
		schedule_refresh()
	)
	column.add_child(reset)

func build_skill_unlocks(tree: SubclassTree, parent: Container) -> void:
	centered_label("Skill unlocks", parent, 14)
	var row := HFlowContainer.new()
	row.name = "SkillUnlocks_" + tree.id.replace(".", "_")
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("h_separation", 14)
	row.add_theme_constant_override("v_separation", 12)
	parent.add_child(row)
	var unlocks := tree.automatic_unlocks.duplicate()
	unlocks.sort_custom(func(a, b): return a.required_points < b.required_points)
	for unlock in unlocks:
		if unlock.skill == null:
			continue
		var preview: bool = unlock.skill.get_meta("display_only", false)
		var available: bool = not preview and state.ranked_build.tree_points(tree) >= unlock.required_points
		var chip := IconTooltipButton.new()
		chip.custom_minimum_size = Vector2(44, 44)
		chip.tooltip_icon = unlock.skill.icon
		chip.tooltip_text = unlock_tooltip(unlock.skill)
		chip.tooltip_provider = func(): return unlock_tooltip(unlock.skill)
		if not preview:
			chip.skill_hover_provider = func(): return preload("res://scripts/ui/skill_hover_formatter.gd").model(unlock.skill,state)
		chip.mouse_default_cursor_shape = Control.CURSOR_ARROW
		var style := CardStyle.make_stylebox(4)
		style.border_color = UIColors.TEXT_GOLD if available else Color("3b3b3b")
		if not available: style.bg_color = Color("141414")
		for mode in ["normal", "hover", "pressed"]:
			chip.add_theme_stylebox_override(mode, style)
		chip.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		row.add_child(chip)
		var icon := CardStyle.make_pixel_icon(unlock.skill.icon, Vector2(24, 24))
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.size = Vector2(24, 24)
		icon.position = Vector2(10, 4)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not available:
			var gray := ShaderMaterial.new()
			gray.shader = preload("res://scripts/ui/talent_grayscale.gdshader")
			icon.material = gray
			icon.modulate.a = 0.3 if preview else 0.35
		chip.add_child(icon)
		var category_style = preload("res://scripts/ui/skill_category_preview_style.gd")
		if category_style.icon_selected(unlock.skill):
			var accent = preload("res://scripts/ui/skill_category_icon_accent.gd").new()
			accent.state = state
			accent.skill = unlock.skill
			accent.locked = not available
			accent.tree_unlock = true
			chip.add_child(accent)
			chip.move_child(accent, 0)
		var badge := Label.new()
		badge.text = str(unlock.required_points)
		badge.add_theme_color_override("font_color", UIColors.TEXT_NORMAL if available else Color("858585"))
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		badge.offset_top = -16
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.add_theme_font_size_override("font_size", 14)
		chip.add_child(badge)

func tier_for(talent: Talent, tree: SubclassTree) -> int:
	var tier := talent.required_tree_points / 5
	for id in talent.prerequisite_ids:
		var prerequisite := RankedBuild._talent(tree, id)
		if prerequisite != null:
			tier = maxi(tier, tier_for(prerequisite, tree) + 1)
	return tier

func reason(talent: Talent, action: String) -> String:
	if edit_block() != "":
		return edit_block()
	var current: RankedBuild = state.ranked_build
	var candidate := RankedBuild.new()
	candidate.configure(current.primary_tree(), current.secondary_tree(), current.budget(), current.rank_map())
	var ok: bool
	if action == "buy":
		if current.rank_of(talent.id) >= talent.max_ranks:
			return "Maximum rank reached."
		if current.unspent_points() == 0:
			return "No unspent points."
		ok = candidate.buy(talent.id)
	else:
		ok = candidate.refund(talent.id, practice() or state.can_respec())
	return "" if ok else friendly(candidate.last_error)

func talent_card(talent: Talent, _tree: SubclassTree) -> Button:
	if talent.get_meta("display_only", false):
		return preview_card(talent)
	var button := IconTooltipButton.new()
	button.custom_minimum_size = Vector2(60, 60)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.tooltip_icon = talent.icon
	var rank: int = state.ranked_build.rank_of(talent.id)
	var available := reason(talent, "buy") == ""
	var locked := rank == 0 and not available
	var key := "buy:" + talent.id
	button.set_meta("action_key", key)
	actions[key] = button
	button.tooltip_text = talent_tooltip(talent)
	button.tooltip_provider = func(): return talent_tooltip(talent)
	button.talent_hover_provider = func(): return preload("res://scripts/ui/talent_hover_formatter.gd").model(talent,_tree,state.ranked_build)
	var style := CardStyle.make_stylebox(6)
	style.border_color = UIColors.TEXT_GOLD if rank > 0 or available else Color("454545")
	if locked:
		style.bg_color = Color("141414")
	for mode in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(mode, style)
	if talent.icon != null:
		var icon := CardStyle.make_pixel_icon(talent.icon, Vector2(36,36))
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.position = Vector2(12,4)
		if locked:
			var gray := ShaderMaterial.new()
			gray.shader = preload("res://scripts/ui/talent_grayscale.gdshader")
			icon.material = gray
			icon.modulate.a = 0.35
		button.add_child(icon)
	else:
		button.text = "?"
	var badge := Label.new()
	badge.text = "%d/%d" % [rank, talent.max_ranks]
	badge.add_theme_color_override("font_color", Color("858585") if locked else UIColors.TEXT_NORMAL)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	badge.offset_top = -18
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 16)
	button.add_child(badge)
	var category_style = preload("res://scripts/ui/skill_category_preview_style.gd")
	if not talent.unlocked_skills.is_empty():
		for skill in talent.unlocked_skills:
			if not category_style.icon_selected(skill): continue
			var accent = preload("res://scripts/ui/skill_category_icon_accent.gd").new()
			accent.state = state
			accent.skill = skill
			accent.locked = rank == 0
			accent.tree_unlock = true
			button.add_child(accent)
			button.move_child(accent, 0)
			break
	button.pressed.connect(func(): transact("buy", talent.id, key))
	button.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			transact("refund", talent.id, key)
			button.accept_event()
	)
	return button

func preview_card(talent: Talent) -> Button:
	var button := IconTooltipButton.new()
	button.custom_minimum_size = Vector2(60, 60)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.tooltip_icon = talent.icon
	var style := CardStyle.make_stylebox(6)
	style.bg_color = Color("141414")
	style.border_color = Color("3b3b3b")
	for mode in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(mode, style)
	button.tooltip_text = "%s\nPreview â€” not yet playable\n%d ranks | Requires %d invested points\nLayout preview only; cannot allocate points or grant effects." % [talent.display_name, talent.max_ranks, talent.required_tree_points]
	button.set_meta("display_only", true)
	button.set_meta("entity_id", talent.id)
	button.set_meta("action_key", "preview:" + talent.id)
	actions["preview:" + talent.id] = button
	if talent.icon != null:
		var art := CardStyle.make_pixel_icon(talent.icon, Vector2(36,36))
		art.position = Vector2(12, 4)
		art.modulate.a = 0.3
		var gray := ShaderMaterial.new()
		gray.shader = preload("res://scripts/ui/talent_grayscale.gdshader")
		art.material = gray
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(art)
	var badge := Label.new()
	badge.text = "Preview"
	badge.add_theme_color_override("font_color", Color("858585"))
	badge.add_theme_font_size_override("font_size", 14)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	badge.offset_top = -18
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(badge)
	return button

func talent_tooltip(talent: Talent) -> String:
	var tree: SubclassTree=state.ranked_build._owner(talent.id)
	return preload("res://scripts/ui/talent_hover_formatter.gd").plain_text(preload("res://scripts/ui/talent_hover_formatter.gd").model(talent,tree,state.ranked_build))


func transact(action: String, id: String, key: String) -> void:
	focus_key = key
	# Blocked node clicks stay silent and do not rebuild/reflow the tree.
	# Reasons remain available from talent_tooltip()/reason().
	if edit_block() != "":
		feedback = ""
		return
	var talent: Talent
	for tree in state.ranked_build.trees():
		var found := RankedBuild._talent(tree, id)
		if found != null:
			talent = found
	if talent != null and reason(talent, action) != "":
		feedback = ""
		return
	var ok: bool = state.refund_all_talents() if action == "reset" else state.select_talent(talent) if action == "buy" else state.deselect_talent(talent)
	if not ok:
		feedback = ""
		return
	feedback = "Allocation updated."
	schedule_refresh()
