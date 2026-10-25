extends PanelContainer
## Combat dashboard panel: the subclass talent tree, drawn as a tree per the
## user's mockup rather than a flat list of toggles. Tiers are derived from
## the talent data itself (prerequisite depth: no-prereq talents form the
## base row, each deeper talent sits below the deepest of its prerequisite
## options), so the layout works for any seeded tree without code changes.
## Each node shows one circle per talent-point cost; circles fill green when
## the talent is selected. Clicking a node toggles it; validation stays in
## PassiveAllocator via state.select_talent/deselect_talent -- a
## rejected toggle simply changes nothing. Unavailable nodes (prereqs unmet
## or budget exceeded) render dimmed and disabled.
##
## Root is PanelContainer -- see character_stats_panel.gd's comment for why.

signal secondary_tree_chosen(tree: SubclassTree)

const CARD_TITLE_FONT_SIZE := 20
const SUBCLASS_LABEL_FONT_SIZE := 30
const INTRINSIC_LABEL_FONT_SIZE := 16
const SECONDARY_CHOICE_CARD_WIDTH := 330
const SECONDARY_TREE_CHOICE_COUNT := 2
const SECONDARY_TREE_RNG_CONTEXT := "secondary_tree_choices"
const NODE_FONT_SIZE := 19
const NODE_DETAIL_FONT_SIZE := 15
const NODE_ROW_SEPARATION := 24
const TREE_COLUMN_WIDTH := 400
const TREE_COLUMN_MIN_HEIGHT := 500
const TREE_COLUMN_SEPARATION := 24
const CONNECTOR_COLOR := UIColors.STRUCTURE_LINE_LIGHT
const UNAVAILABLE_ALPHA := 0.45
const TREE_ICON_SIZE := Vector2(54, 54)
const SELECTED_NODE_FILL := UIColors.TALENT_SELECTED_BG
const DEPENDENCY_PULSE_SCALE := Vector2(1.06, 1.06)
const DEPENDENCY_PULSE_COLOR := UIColors.TALENT_DEPENDENCY_PULSE

## P2:R10: the reused build-panel state source. Defaults to the real
## `BuildState` singleton (Adventure's actual behavior, unchanged), but
## Practice Room assigns its own `TrainingRoomState` instance here instead --
## set before this panel enters the tree, so `_ready()` reads the right one.
## Deliberately untyped (`=`, not `:=`/a type annotation): `BuildState` has no
## `class_name`, and this must accept either object interchangeably.
var state = BuildState

var _ranked_view: Control
var _talent_box: VBoxContainer
var _talent_buttons: Dictionary = {}
var _talent_pulse_tweens: Dictionary = {}
var _last_dependency_blocked_talent: Talent = null
var _last_dependency_pulse_talents: Array[Talent] = []


## One circle per point of cost; filled green when selected, outline when
## not. Custom-drawn -- unicode circle glyphs render too inconsistently
## across fonts to trust for a game UI element.
class TalentCircles:
	extends Control

	const RADIUS := 9.0
	const GAP := 6.0
	const FILL_COLOR := UIColors.TEXT_POISON
	const OUTLINE_COLOR := UIColors.TEXT_NORMAL

	var count: int = 1
	var filled: bool = false

	func _init(circle_count: int, is_filled: bool) -> void:
		count = circle_count
		filled = is_filled
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(count * (RADIUS * 2.0 + GAP) - GAP, RADIUS * 2.0 + 2.0)

	func _draw() -> void:
		for i in count:
			var center := Vector2(RADIUS + i * (RADIUS * 2.0 + GAP), size.y / 2.0)
			if filled:
				draw_circle(center, RADIUS, FILL_COLOR)
			else:
				draw_arc(center, RADIUS - 1.0, 0.0, TAU, 24, OUTLINE_COLOR, 2.0)


func _ready() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	add_child(content)

	_talent_box = VBoxContainer.new()
	_talent_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_talent_box.add_theme_constant_override("separation", 2)
	content.add_child(_talent_box)

	state.build_changed.connect(_refresh)
	if state.has_signal("run_state_changed"):
		state.run_state_changed.connect(_refresh)
	_refresh()


func refresh_panel() -> void:
	_refresh()


func _refresh() -> void:
	if state.ranked_build != null:
		if not is_instance_valid(_ranked_view):
			for child in _talent_box.get_children():
				_talent_box.remove_child(child)
				child.queue_free()
			_ranked_view = preload("res://scripts/ui/ranked_talent_view.gd").new()
			_ranked_view.state = state
			_talent_box.add_child(_ranked_view)
		return

	_talent_buttons.clear()
	_last_dependency_blocked_talent = null
	_last_dependency_pulse_talents.clear()
	for child in _talent_box.get_children():
		child.queue_free()
	if _uses_practice_tree_slots():
		_build_practice_tree_slots()
		return
	if state.selected_trees.is_empty():
		_build_empty_state()
		return
	_talent_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var tree_row := HBoxContainer.new()
	tree_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tree_row.add_theme_constant_override("separation", TREE_COLUMN_SEPARATION)
	_talent_box.add_child(tree_row)
	for i in state.selected_trees.size():
		_build_tree(state.selected_trees[i], tree_row, "Primary" if i == 0 else "Secondary")
	if state.selected_trees.size() < 2:
		_build_locked_secondary_column(tree_row)


func _uses_practice_tree_slots() -> bool:
	return state.has_method("set_primary_tree") and state.has_method("set_secondary_tree") and state.has_method("tree_at_slot")


func _build_practice_tree_slots() -> void:
	_talent_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var tree_row := HBoxContainer.new()
	tree_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tree_row.add_theme_constant_override("separation", TREE_COLUMN_SEPARATION)
	_talent_box.add_child(tree_row)

	_build_practice_tree_slot(0, "Primary", tree_row)
	_build_practice_tree_slot(1, "Secondary", tree_row)


func _build_practice_tree_slot(slot_index: int, role: String, parent: Container) -> void:
	var tree: SubclassTree = state.tree_at_slot(slot_index)
	var section_panel := _build_tree_column_frame(role, tree == null)
	parent.add_child(section_panel)

	var section := section_panel.get_node("Content") as VBoxContainer
	section.add_theme_constant_override("separation", 12)
	section.add_child(_build_practice_tree_picker(slot_index))
	if tree == null:
		return
	_populate_tree_column_content(tree, section)


func _build_practice_tree_picker(slot_index: int) -> OptionButton:
	var option := OptionButton.new()
	option.name = "PrimaryTreeOption" if slot_index == 0 else "SecondaryTreeOption"
	option.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	option.custom_minimum_size = Vector2(160, 0)
	option.add_item("None")
	if state.selected_class != null:
		for tree in state.selected_class.trees:
			option.add_item(tree.display_name)
	var selected_tree: SubclassTree = state.tree_at_slot(slot_index)
	if selected_tree == null or state.selected_class == null:
		option.select(0)
	else:
		option.select(state.selected_class.trees.find(selected_tree) + 1)
	option.item_selected.connect(func(index: int):
		var tree: SubclassTree = null if index == 0 else state.selected_class.trees[index - 1]
		if slot_index == 0:
			state.set_primary_tree(tree)
		else:
			state.set_secondary_tree(tree)
	)
	return option


func _build_empty_state() -> void:
	_talent_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var empty_label := Label.new()
	empty_label.text = "No subclass selected."
	empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_label.add_theme_font_size_override("font_size", INTRINSIC_LABEL_FONT_SIZE)
	empty_label.add_theme_color_override("font_color", UIColors.TEXT_DISABLED)
	_talent_box.add_child(empty_label)


func _build_tree(tree: SubclassTree, parent: Container, role: String) -> void:
	var section_panel := _build_tree_column_frame(role, false)
	parent.add_child(section_panel)

	var section := section_panel.get_node("Content") as VBoxContainer
	section.add_theme_constant_override("separation", 12)
	_populate_tree_column_content(tree, section)


func _populate_tree_column_content(tree: SubclassTree, section: VBoxContainer) -> void:
	var tree_header := HBoxContainer.new()
	tree_header.alignment = BoxContainer.ALIGNMENT_CENTER
	tree_header.add_theme_constant_override("separation", 12)
	section.add_child(tree_header)

	if tree.icon != null:
		tree_header.add_child(CardStyle.make_pixel_icon(tree.icon, TREE_ICON_SIZE))

	var tree_name := Label.new()
	tree_name.text = tree.display_name
	tree_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tree_name.add_theme_font_size_override("font_size", SUBCLASS_LABEL_FONT_SIZE)
	tree_name.add_theme_color_override("font_color", CardStyle.ACCENT_COLOR)
	tree_header.add_child(tree_name)

	var intrinsic := Label.new()
	intrinsic.text = "Intrinsic: %s" % _intrinsic_description(tree)
	intrinsic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intrinsic.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intrinsic.add_theme_font_size_override("font_size", INTRINSIC_LABEL_FONT_SIZE)
	section.add_child(intrinsic)

	if state.ranked_build != null:
		_populate_ranked_tree(tree, section)
		return

	var memo := {}
	var tiers := {}
	var max_tier := 0
	for talent in tree.talents:
		var tier := _tier_of(talent, memo)
		if not tiers.has(tier):
			tiers[tier] = []
		tiers[tier].append(talent)
		max_tier = maxi(max_tier, tier)

	for tier in range(max_tier + 1):
		if not tiers.has(tier):
			continue
		if tier > 0:
			section.add_child(_build_connector())
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", NODE_ROW_SEPARATION)
		for talent in tiers[tier]:
			row.add_child(_build_node(talent))
		section.add_child(row)


func _build_locked_secondary_column(parent: Container) -> void:
	var section := _build_tree_column_frame("Secondary", true)
	parent.add_child(section)

	var content := section.get_node("Content") as VBoxContainer
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 16)

	var title := Label.new()
	title.text = "Second Subclass"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", SUBCLASS_LABEL_FONT_SIZE)
	title.add_theme_color_override("font_color", UIColors.TEXT_DISABLED)
	content.add_child(title)

	if _should_show_secondary_tree_choices():
		title.add_theme_color_override("font_color", CardStyle.ACCENT_COLOR)
		_build_secondary_tree_choices(content)
		return

	var body := Label.new()
	body.text = "Unlocks later in the Adventure."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", INTRINSIC_LABEL_FONT_SIZE)
	body.add_theme_color_override("font_color", UIColors.TEXT_DISABLED)
	content.add_child(body)


func _build_tree_column_frame(role: String, locked: bool) -> PanelContainer:
	var section := PanelContainer.new()
	section.name = "%sTalentColumn" % role
	section.custom_minimum_size = Vector2(TREE_COLUMN_WIDTH, TREE_COLUMN_MIN_HEIGHT)
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := CardStyle.make_stylebox()
	style.bg_color = UIColors.PANEL_DISABLED if locked else UIColors.PANEL_DEEP
	style.border_color = UIColors.STRUCTURE_LINE_LIGHT if locked else CardStyle.ACCENT_COLOR
	style.set_border_width_all(2)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 16
	section.add_theme_stylebox_override("panel", style)

	var content := VBoxContainer.new()
	content.name = "Content"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	section.add_child(content)

	var role_label := Label.new()
	role_label.name = "ColumnRoleLabel"
	role_label.text = role
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_label.theme_type_variation = &"PanelHeader"
	role_label.add_theme_font_size_override("font_size", CARD_TITLE_FONT_SIZE)
	role_label.add_theme_color_override("font_color", UIColors.TEXT_DISABLED if locked else UIColors.TEXT_GOLD)
	content.add_child(role_label)
	return section


func _should_show_secondary_tree_choices() -> bool:
	return (
		state.has_method("choose_secondary_tree")
		and state.active_contract != null
		and state.selected_class != null
		and state.selected_trees.size() < PassiveAllocator.MAX_TREES
	)


func _build_secondary_tree_choices(parent: Container) -> void:
	var body := Label.new()
	body.text = "Choose a second Rogue tree for the contract."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", INTRINSIC_LABEL_FONT_SIZE)
	body.add_theme_color_override("font_color", UIColors.TEXT_NORMAL)
	parent.add_child(body)

	var choices := VBoxContainer.new()
	choices.name = "SecondaryTreeChoices"
	choices.alignment = BoxContainer.ALIGNMENT_CENTER
	choices.add_theme_constant_override("separation", 12)
	parent.add_child(choices)

	for tree in _secondary_tree_choices():
		choices.add_child(_make_secondary_tree_choice_card(tree))


func _secondary_tree_choices() -> Array[SubclassTree]:
	return state.secondary_subclass_choices()


func _secondary_tree_choice_seed() -> int:
	var value: Variant = state.get("adventure_seed")
	return int(value) if value != null else 1


func _secondary_tree_choice_parts() -> Array:
	var parts: Array = []
	if state.selected_class != null:
		parts.append(state.selected_class.id)
	for tree in state.selected_trees:
		parts.append(tree.id)
	return parts


func _make_secondary_tree_choice_card(tree: SubclassTree) -> PanelContainer:
	var choose_button := Button.new()
	choose_button.text = "Choose"
	choose_button.pressed.connect(_on_secondary_tree_choice_pressed.bind(tree))
	return CardStyle.make_selection_card(
		tree.display_name,
		"Intrinsic: %s" % _intrinsic_description(tree),
		choose_button,
		SECONDARY_CHOICE_CARD_WIDTH,
		tree.icon
	)


func _on_secondary_tree_choice_pressed(tree: SubclassTree) -> void:
	if BuildState.choose_secondary_tree(tree):
		secondary_tree_chosen.emit(tree)


## Prerequisite depth: 0 for no-prereq (base row) talents, otherwise one
## below the deepest prerequisite option.
func _tier_of(talent: Talent, memo: Dictionary) -> int:
	if memo.has(talent):
		return memo[talent]
	var tier := 0
	for group in talent.prerequisites:
		for option in group.options:
			tier = maxi(tier, _tier_of(option, memo) + 1)
	memo[talent] = tier
	return tier


func _build_connector() -> ColorRect:
	var connector := ColorRect.new()
	connector.color = CONNECTOR_COLOR
	connector.custom_minimum_size = Vector2(4, 18)
	connector.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return connector


## Flat clickable node: cost circles + name. Same Button-with-child-content
## pattern (and the same measured-minimum-size requirement) as
## available_skills_panel.gd's _build_button.
##
## P2:R7 playtest-feedback pass (2026-07-18, revises T4): T4 originally also
## rendered an unavailable talent's unmet-prerequisite/budget reason as an
## always-visible caption Label under the node. Playtesting found that
## redundant with the hover tooltip (which already includes the same reason
## via _talent_tooltip()'s lock_reason parameter) and it added vertical bulk
## the talent tree didn't have to spare -- see the overflow-bug notes in
## docs/Phase_2_R7_Game_Like_UI_Pass.md. The caption is removed;
## _talent_lock_reason() itself is unchanged and still feeds the tooltip.
func _build_node(talent: Talent) -> Button:
	var selected: bool = state.selected_talents.has(talent)
	var selectable: bool = PassiveAllocator.can_select_talent(
		state.selected_trees, state.selected_talents, talent, state.earned_talent_points
	)
	var dependency_protected := selected and not PassiveAllocator.can_deselect_talent(state.selected_talents, talent)
	var lock_reason: String = "" if (selected or selectable) else _talent_lock_reason(talent)

	var node_col := VBoxContainer.new()
	node_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node_col.alignment = BoxContainer.ALIGNMENT_CENTER
	node_col.add_theme_constant_override("separation", 3)

	var node_row := HBoxContainer.new()
	node_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node_row.alignment = BoxContainer.ALIGNMENT_CENTER
	node_row.add_theme_constant_override("separation", 8)

	node_row.add_child(TalentCircles.new(talent.cost, selected))
	if talent.icon != null:
		node_row.add_child(CardStyle.make_pixel_icon(talent.icon, Vector2(32, 32)))

	var name_label := Label.new()
	name_label.text = talent.display_name
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_size_override("font_size", NODE_FONT_SIZE)
	node_row.add_child(name_label)
	node_col.add_child(node_row)

	var detail_label := Label.new()
	detail_label.text = _talent_visible_details(talent)
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_label.add_theme_font_size_override("font_size", NODE_DETAIL_FONT_SIZE)
	node_col.add_child(detail_label)

	var button := IconTooltipButton.new()
	button.tooltip_icon = talent.icon
	button.set_meta("talent_id", talent.id)
	button.set_meta("dependency_protected", dependency_protected)
	button.tooltip_text = _talent_tooltip(talent, lock_reason)
	button.pressed.connect(_on_node_pressed.bind(talent))
	button.add_child(node_col)

	var content_min: Vector2 = node_col.get_combined_minimum_size()
	button.custom_minimum_size = content_min + Vector2(22, 14)
	node_col.set_anchors_preset(Control.PRESET_FULL_RECT)

	if not selected and not selectable:
		button.disabled = true
		button.modulate.a = UNAVAILABLE_ALPHA
		name_label.add_theme_color_override("font_color", UIColors.TEXT_DISABLED)
		detail_label.add_theme_color_override("font_color", UIColors.TEXT_DISABLED)
		_apply_node_style(button, UIColors.PANEL_DISABLED, UIColors.STRUCTURE_LINE_LIGHT, 1)
	elif selected:
		name_label.add_theme_color_override("font_color", UIColors.TEXT_GOLD)
		detail_label.add_theme_color_override("font_color", UIColors.TEXT_NORMAL)
		_apply_node_style(button, SELECTED_NODE_FILL, UIColors.TALENT_SELECTED_BORDER, 3)
	else:
		name_label.add_theme_color_override("font_color", UIColors.TEXT_NORMAL)
		detail_label.add_theme_color_override("font_color", UIColors.TEXT_NORMAL)
		_apply_node_style(button, UIColors.PANEL_DEEP, CardStyle.ACCENT_COLOR, 2)

	_talent_buttons[talent] = button
	return button


func _apply_node_style(button: Button, fill: Color, border: Color, border_width: int) -> void:
	for state_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = fill
		style.border_color = border
		style.set_border_width_all(border_width)
		style.set_corner_radius_all(8)
		button.add_theme_stylebox_override(state_name, style)


## Why an unavailable (not selected, not selectable) talent is locked --
## wrong/no active tree, an unmet OR-group prerequisite (named), or not
## enough remaining talent points. Empty string means the talent is either
## already selected or currently selectable, so no reason applies. Reads
## PassiveAllocator/BuildState directly rather than re-deriving the rules,
## per docs/Conventions.md's UI architecture principle.
func _talent_lock_reason(talent: Talent) -> String:
	var in_selected_tree: bool = false
	for tree in state.selected_trees:
		if tree.talents.has(talent):
			in_selected_tree = true
			break
	if not in_selected_tree:
		return "Not in an active subclass tree"

	if not PassiveAllocator.prerequisites_satisfied(state.selected_talents, talent):
		var unmet_groups: PackedStringArray = []
		for group in talent.prerequisites:
			if group.options.is_empty():
				continue
			var satisfied: bool = false
			for option in group.options:
				if state.selected_talents.has(option):
					satisfied = true
					break
			if satisfied:
				continue
			var option_names: PackedStringArray = []
			for option in group.options:
				option_names.append(option.display_name)
			unmet_groups.append("Requires " + " or ".join(option_names))
		return " and ".join(unmet_groups) if not unmet_groups.is_empty() else "Prerequisite not met"

	var remaining: int = state.earned_talent_points - PassiveAllocator.points_spent(state.selected_talents)
	if talent.cost > remaining:
		return "Needs %d point%s (%d available)" % [talent.cost, "" if talent.cost == 1 else "s", remaining]

	return ""


func _on_node_pressed(talent: Talent) -> void:
	if state.selected_talents.has(talent):
		if not state.deselect_talent(talent):
			_pulse_dependency_block(talent)
	else:
		state.select_talent(talent)


func _pulse_dependency_block(talent: Talent) -> void:
	var dependents := _dependency_blocked_dependents(talent)
	_last_dependency_blocked_talent = talent
	_last_dependency_pulse_talents = dependents.duplicate()
	_pulse_talent_button(talent, true)
	for dependent in dependents:
		_pulse_talent_button(dependent, false)


func _pulse_talent_button(talent: Talent, is_clicked_talent: bool) -> void:
	if not _talent_buttons.has(talent):
		return
	var button: Button = _talent_buttons[talent]
	if button == null or not is_instance_valid(button):
		return
	if _talent_pulse_tweens.has(button):
		var previous: Tween = _talent_pulse_tweens[button]
		if previous != null and previous.is_valid():
			previous.kill()
	button.pivot_offset = button.size * 0.5
	var original_scale := button.scale
	var original_modulate := button.modulate
	var pulse_color := UIColors.TALENT_BLOCKED_PULSE if is_clicked_talent else DEPENDENCY_PULSE_COLOR
	button.modulate = pulse_color
	var tween := create_tween()
	_talent_pulse_tweens[button] = tween
	tween.tween_property(button, "scale", DEPENDENCY_PULSE_SCALE, 0.08)
	tween.parallel().tween_property(button, "modulate", pulse_color, 0.08)
	tween.tween_property(button, "scale", original_scale, 0.18)
	tween.parallel().tween_property(button, "modulate", original_modulate, 0.18)
	tween.finished.connect(
		_on_dependency_pulse_finished.bind(weakref(button), original_scale, original_modulate)
	)


func _on_dependency_pulse_finished(button_ref: WeakRef, original_scale: Vector2, original_modulate: Color) -> void:
	var button: Button = button_ref.get_ref()
	if button == null:
		return
	button.scale = original_scale
	button.modulate = original_modulate
	_talent_pulse_tweens.erase(button)


func _dependency_blocked_dependents(talent: Talent) -> Array[Talent]:
	var dependents: Array[Talent] = []
	var frontier: Array[Talent] = [talent]
	while not frontier.is_empty():
		var support: Talent = frontier.pop_front()
		for selected_talent in state.selected_talents:
			if selected_talent == support or dependents.has(selected_talent):
				continue
			if _selected_talent_requires_support(selected_talent, support):
				dependents.append(selected_talent)
				frontier.append(selected_talent)
	return dependents


func _selected_talent_requires_support(selected_talent: Talent, support: Talent) -> bool:
	for group in selected_talent.prerequisites:
		if not group.options.has(support):
			continue
		for option in group.options:
			if option != support and state.selected_talents.has(option):
				return false
		return true
	return false


## Everything the tree grants just for being selected, with no talent
## points spent -- the tree's own unlocked_skills plus any innate stat
## modifiers and skill augments.
func _intrinsic_description(tree: SubclassTree) -> String:
	if tree.intrinsic_text != "":
		return tree.intrinsic_text
	var lines: PackedStringArray = []
	for skill in tree.unlocked_skills:
		lines.append("Unlocks %s" % skill.display_name)
	for modifier in tree.innate_modifiers:
		lines.append(StatModifierFormatter.format(modifier))
	for augment in tree.skill_augments:
		lines.append(_skill_augment_description(augment))
	if lines.is_empty():
		return "None"
	return ", ".join(lines)


func _skill_augment_description(augment: SkillAugment) -> String:
	var target_names: PackedStringArray = []
	for target_id in augment.target_skill_ids:
		target_names.append(_skill_name_for_id(target_id))
	var effect_names: PackedStringArray = []
	for effect in augment.extra_effects:
		if effect is PoisonDamageEffect:
			var poison_effect: PoisonDamageEffect = effect
			effect_names.append("+%d poison stack%s" % [poison_effect.stacks_applied, "" if poison_effect.stacks_applied == 1 else "s"])
		elif effect is PoisonResistanceReductionEffect:
			var resist_effect: PoisonResistanceReductionEffect = effect
			effect_names.append("-%d%% resistance" % roundi(resist_effect.reduction_fraction * 100.0))
		elif effect is StackScalingPhysicalDamageEffect:
			var stack_effect: StackScalingPhysicalDamageEffect = effect
			effect_names.append("+%.0f damage per poison stack" % stack_effect.damage_per_stack)
		elif effect is StealGoldOnCritEffect:
			var steal_effect: StealGoldOnCritEffect = effect
			effect_names.append("crits steal %dg" % steal_effect.amount)
	if target_names.is_empty() or effect_names.is_empty():
		return "Enhances selected skills"
	return "%s gain %s" % [", ".join(target_names), ", ".join(effect_names)]


func _skill_name_for_id(skill_id: String) -> String:
	if state.selected_class != null:
		for skill in state.selected_class.base_skills:
			if skill.id == skill_id:
				return skill.display_name
		for tree in state.selected_class.trees:
			for skill in tree.unlocked_skills:
				if skill.id == skill_id:
					return skill.display_name
			for talent in tree.talents:
				for skill in talent.unlocked_skills:
					if skill.id == skill_id:
						return skill.display_name
	return skill_id


func _talent_tooltip(talent: Talent, lock_reason: String = "") -> String:
	var lines: PackedStringArray = []
	lines.append("Cost: %d" % talent.cost)
	for modifier in talent.stat_modifiers:
		lines.append(StatModifierFormatter.format(modifier))
	for skill in talent.unlocked_skills:
		lines.append("Unlocks: %s" % skill.display_name)
	for trigger in talent.triggered_skill_effects:
		var trigger_text := _trigger_description(trigger)
		if trigger_text != "":
			lines.append(trigger_text)
	if lines.size() == 1:
		lines.append("No effect yet")
	if lock_reason != "":
		lines.append("Locked: %s" % lock_reason)
	return "\n".join(lines)


func _talent_visible_details(talent: Talent) -> String:
	var lines: PackedStringArray = []
	for modifier in talent.stat_modifiers:
		lines.append(StatModifierFormatter.format(modifier))
	for skill in talent.unlocked_skills:
		lines.append("Unlocks %s" % skill.display_name)
	for trigger in talent.triggered_skill_effects:
		var trigger_text := _trigger_description(trigger)
		if trigger_text != "":
			lines.append(trigger_text)
	if lines.is_empty():
		return "No effect yet"
	return "\n".join(lines)


func _trigger_description(trigger: TriggeredSkillEffect) -> String:
	if trigger == null or trigger.skill == null:
		return ""
	var chance_text := "%d%% chance to trigger %s" % [roundi(trigger.chance * 100.0), trigger.skill.display_name]
	if trigger.source_skill_ids.is_empty():
		return chance_text
	var source_names: PackedStringArray = []
	for source_id in trigger.source_skill_ids:
		source_names.append(_skill_name_for_id(source_id))
	return "%s: %s" % [" & ".join(source_names), chance_text]


func _populate_ranked_tree(tree: SubclassTree, section: VBoxContainer) -> void:
	var explanation := Label.new()
	explanation.text = "Invested: %d — each rank costs one point" % state.ranked_build.tree_points(tree)
	section.add_child(explanation)
	var feedback := Label.new()
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.text = state.last_build_error
	feedback.hide()
	section.add_child(feedback)
	for talent in tree.talents:
		var row := HBoxContainer.new()
		section.add_child(row)
		var rank: int = state.ranked_build.rank_of(talent.id)
		if talent.icon != null:
			row.add_child(CardStyle.make_pixel_icon(talent.icon, Vector2(32, 32)))
		var label := Label.new()
		label.text = "%s  %d/%d (requires %d tree points)" % [talent.display_name, rank, talent.max_ranks, talent.required_tree_points]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var add := Button.new()
		add.text = "+"
		add.disabled = rank >= talent.max_ranks
		add.pressed.connect(func():
			if not state.select_talent(talent):
				feedback.text = state.last_build_error
		)
		row.add_child(add)
		var refund := Button.new()
		refund.text = "−"
		refund.disabled = rank == 0
		refund.pressed.connect(func():
			if not state.deselect_talent(talent):
				feedback.text = state.last_build_error
		)
		row.add_child(refund)
		var detail := Label.new()
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var lines: PackedStringArray = []
		if rank > 0:
			for modifier in talent.ranks[rank - 1].stat_modifiers:
				lines.append(StatModifierFormatter.format(modifier))
		detail.text = ", ".join(lines)
		section.add_child(detail)
	var reset := Button.new()
	reset.text = "Refund all talent ranks"
	reset.pressed.connect(func():
		if not state.refund_all_talents():
			feedback.text = state.last_build_error
	)
	section.add_child(reset)
