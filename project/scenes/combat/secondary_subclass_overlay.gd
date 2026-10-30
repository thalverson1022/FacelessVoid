extends Control
## Secondary Rogue tree choice, earned after completing the first
## contract. Extracted from combat_screen.gd's inline overlay builder
## (docs/Phase_3_Technical_Debt_Architecture_Cleanup.md Phase 3) -- gates a
## real decision (Choose) with no defined "cancel" behavior, so it stays
## locked (no dismiss on outside click), matching its behavior before
## extraction.

signal tree_chosen(tree: SubclassTree)

const CARD_TITLE_FONT_SIZE := 20
const CONTRACT_SUBCLASS_PROMPT_TEXT := "First contract complete! Choose a second subclass."
const SECONDARY_TREE_CHOICE_COUNT := 2
const SECONDARY_TREE_RNG_CONTEXT := "secondary_tree_choices"

var _body_label: Label
var _options: HBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false

	var panel := CardStyle.build_modal_panel(self, false)
	panel.add_theme_stylebox_override("panel", CardStyle.make_stylebox(18))

	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(640, 300)
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)

	var title := Label.new()
	title.text = "Choose a Second Rogue Tree"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_type_variation = &"PanelHeader"
	title.add_theme_font_size_override("font_size", CARD_TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", CardStyle.ACCENT_COLOR)
	content.add_child(title)

	_body_label = Label.new()
	_body_label.text = CONTRACT_SUBCLASS_PROMPT_TEXT
	_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_body_label)

	_options = HBoxContainer.new()
	_options.alignment = BoxContainer.ALIGNMENT_CENTER
	_options.add_theme_constant_override("separation", 20)
	content.add_child(_options)


## Public entry point: refreshes the available second-tree options against
## the current build, then shows the overlay. combat_screen.gd calls this
## instead of toggling `.visible` directly so the options can never go stale.
func show_overlay() -> void:
	_refresh_options()
	visible = true


func _refresh_options() -> void:
	for child in _options.get_children():
		child.queue_free()
	if BuildState.selected_class == null:
		return
	for tree in _secondary_tree_choices():
		_options.add_child(_make_tree_card(tree))


func _secondary_tree_choices() -> Array[SubclassTree]:
	return BuildState.secondary_subclass_choices()


func _secondary_tree_choice_parts() -> Array:
	var parts: Array = []
	if BuildState.selected_class != null:
		parts.append(BuildState.selected_class.id)
	for tree in BuildState.selected_trees:
		parts.append(tree.id)
	return parts


## One selectable tree card, built through the same shared
## CardStyle.make_selection_card() layout the primary subclass select screen
## uses (P2:R7 second playtest-feedback pass, item 5) so the two choosers
## read as the same UI.
func _make_tree_card(tree: SubclassTree) -> PanelContainer:
	var choose_button := Button.new()
	choose_button.text = "Choose"
	choose_button.pressed.connect(func(): tree_chosen.emit(tree))
	return CardStyle.make_selection_card(
		tree.display_name,
		"Intrinsic: %s" % _intrinsic_description(tree),
		choose_button,
		CardStyle.SELECTION_CARD_WIDTH,
		tree.icon
	)


func _intrinsic_description(tree: SubclassTree) -> String:
	if tree.intrinsic_text != "":
		return tree.intrinsic_text
	var parts: PackedStringArray = []
	for skill in tree.unlocked_skills:
		parts.append("Unlocks %s" % skill.display_name)
	for modifier in tree.innate_modifiers:
		parts.append(StatModifierFormatter.format(modifier))
	for augment in tree.skill_augments:
		parts.append(_skill_augment_description(augment))
	if parts.is_empty():
		return "None"
	return ", ".join(parts)


func _skill_augment_description(augment: SkillAugment) -> String:
	if augment == null:
		return ""
	var target_names: PackedStringArray = []
	for target_id in augment.target_skill_ids:
		target_names.append(_skill_name_for_id(target_id))
	var effect_names: PackedStringArray = []
	for effect in augment.extra_effects:
		if effect is PoisonDamageEffect:
			var poison_effect: PoisonDamageEffect = effect
			effect_names.append("+%d poison stack%s" % [poison_effect.stacks_applied, "" if poison_effect.stacks_applied == 1 else "s"])
	if target_names.is_empty() or effect_names.is_empty():
		return "Enhances selected skills"
	return "%s gain %s" % [", ".join(target_names), ", ".join(effect_names)]


func _skill_name_for_id(skill_id: String) -> String:
	if BuildState.selected_class != null:
		for skill in BuildState.selected_class.base_skills:
			if skill.id == skill_id:
				return skill.display_name
		for tree in BuildState.selected_class.trees:
			for skill in tree.unlocked_skills:
				if skill.id == skill_id:
					return skill.display_name
			for talent in tree.talents:
				for talent_skill in talent.unlocked_skills:
					if talent_skill.id == skill_id:
						return talent_skill.display_name
	return skill_id
