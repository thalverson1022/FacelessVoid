class_name TrainingTargetPanel
extends PanelContainer
## Practice Room's target stats card (visual parity with Adventure's
## enemy_panel.gd's card look): adjustable functional defense values for the
## practice target. Training Room only measures damage dealt in a fixed window,
## never whether the target is "killed", so HP/required-DPS never belongs here.
##
## Never touches TrainingRoomState directly -- training_room.gd owns the
## practice target and pushes its current stats in via refresh(), same
## "owner pushes data in" pattern the other reused dashboard panels use via
## their `state` property.

signal armor_changed(value: int)
signal poison_resist_changed(value: float)
signal defense_changed(field: String, value: Variant)
signal preset_selected(preset_id: String)
signal generated_roll_requested(contract_level: int, difficulty_id: int, monster_kind: String, archetype_a_id: String, archetype_b_id: String)

const CARD_TITLE_FONT_SIZE := 20
const PANEL_MIN_HEIGHT := 300
const RuntimeArchetypeLibraryLoaderScript := preload("res://scripts/systems/runtime_monster_generator/runtime_archetype_library_loader.gd")
const PERCENT_FIELDS := ["poison_resistance", "dodge_chance", "crit_negation", "suppress", "slow"]
const DEFENSE_LABELS := {
	"armor": "Armor",
	"poison_resistance": "Resist",
	"dodge_chance": "Dodge",
	"crit_negation": "Crit Negate",
	"block": "Block",
	"absorb": "Absorb",
	"cleanse_threshold": "Cleanse",
	"suppress": "Suppress",
	"slow": "Slow",
	"stun_duration_ms": "Stun",
	"interrupt_skip_count": "Interrupt",
}
const DIFFICULTY_LABELS := {
	1: "Easy",
	2: "Medium",
	3: "Hard",
	4: "Ultra",
	5: "Nightmare",
}
const MONSTER_KIND_OPTIONS := ["normal", "captain", "elite", "boss"]

var _armor_spin: SpinBox
var _poison_resist_spin: SpinBox
var _defense_spins: Dictionary = {}
var _primary_archetype_option: OptionButton
var _secondary_archetype_option: OptionButton
var _generator_contract_level_spin: SpinBox
var _generator_difficulty_option: OptionButton
var _generator_type_option: OptionButton
var _refreshing_defenses := false


func _ready() -> void:
	add_theme_stylebox_override("panel", CardStyle.make_stylebox())
	custom_minimum_size = Vector2(0, PANEL_MIN_HEIGHT)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	add_child(content)

	var title := Label.new()
	title.text = "Target"
	title.theme_type_variation = &"PanelHeader"
	title.add_theme_font_size_override("font_size", CARD_TITLE_FONT_SIZE)
	content.add_child(title)

	var contract_level_row := _build_labeled_row(content, "Contract Level")
	_generator_contract_level_spin = SpinBox.new()
	_generator_contract_level_spin.name = "GeneratedContractLevelSpin"
	_generator_contract_level_spin.min_value = 1
	_generator_contract_level_spin.max_value = 30
	_generator_contract_level_spin.step = 1
	_generator_contract_level_spin.rounded = true
	_generator_contract_level_spin.value = 1
	_generator_contract_level_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contract_level_row.add_child(_generator_contract_level_spin)

	var generator_row := HBoxContainer.new()
	generator_row.add_theme_constant_override("separation", 8)
	content.add_child(generator_row)

	_generator_difficulty_option = OptionButton.new()
	_generator_difficulty_option.name = "GeneratedDifficultyOption"
	_generator_difficulty_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_generator_difficulty_option.item_selected.connect(func(_index: int): _refresh_archetype_options())
	_add_dropdown_column(generator_row, "Difficulty", _generator_difficulty_option)
	for difficulty_id in DIFFICULTY_LABELS:
		_generator_difficulty_option.add_item(DIFFICULTY_LABELS[difficulty_id], difficulty_id)

	_generator_type_option = OptionButton.new()
	_generator_type_option.name = "GeneratedTypeOption"
	_generator_type_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_generator_type_option.item_selected.connect(func(_index: int): _refresh_archetype_options())
	_add_dropdown_column(generator_row, "Type", _generator_type_option)
	for monster_kind in MONSTER_KIND_OPTIONS:
		_generator_type_option.add_item(monster_kind)
		_generator_type_option.set_item_metadata(_generator_type_option.item_count - 1, monster_kind)

	var archetype_row := HBoxContainer.new()
	archetype_row.add_theme_constant_override("separation", 8)
	content.add_child(archetype_row)

	_primary_archetype_option = OptionButton.new()
	_primary_archetype_option.name = "PrimaryArchetypeOption"
	_primary_archetype_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_dropdown_column(archetype_row, "Main", _primary_archetype_option)

	_secondary_archetype_option = OptionButton.new()
	_secondary_archetype_option.name = "SecondaryArchetypeOption"
	_secondary_archetype_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_dropdown_column(archetype_row, "Secondary", _secondary_archetype_option)
	_refresh_archetype_options()

	var roll_button := Button.new()
	roll_button.name = "RollGeneratedMonsterButton"
	roll_button.text = "Reroll"
	roll_button.tooltip_text = "Roll a new random generated Practice Room target"
	roll_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roll_button.pressed.connect(_on_roll_generated_pressed)
	content.add_child(roll_button)

	_add_defense_spin(content, "armor", "Armor", 0, 999, 1, true)
	_add_defense_spin(content, "block", "Block", 0, 100, 1, false)
	_add_defense_spin(content, "dodge_chance", "Dodge %", 0, 100, 1, true)
	_add_defense_spin(content, "crit_negation", "Crit Negate %", 0, 100, 1, true)
	_add_defense_spin(content, "poison_resistance", "Resist %", 0, 100, 1, true)
	_add_defense_spin(content, "absorb", "Absorb", 0, 100, 1, false)
	_add_defense_spin(content, "suppress", "Suppress %", 0, 100, 1, true)
	_add_defense_spin(content, "slow", "Slow %", 0, 100, 1, true)
	_add_defense_spin(content, "cleanse_threshold", "Cleanse", 0, 20, 1, true)
	_add_defense_spin(content, "stun_duration_ms", "Stun ms", 0, 5000, 50, true)
	_add_defense_spin(content, "interrupt_skip_count", "Interrupt", 0, 5, 1, true)


func _build_labeled_row(parent: VBoxContainer, label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(120, 0)
	row.add_child(label)
	return row


func _add_dropdown_column(parent: HBoxContainer, label_text: String, dropdown: OptionButton) -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(column)
	var label := Label.new()
	label.text = label_text
	column.add_child(label)
	column.add_child(dropdown)


func _refresh_archetype_options() -> void:
	_populate_archetype_options(_primary_archetype_option, _selected_archetype_id(_primary_archetype_option))
	_populate_archetype_options(_secondary_archetype_option, _selected_archetype_id(_secondary_archetype_option))


func _populate_archetype_options(dropdown: OptionButton, selected_archetype_id: String = "") -> void:
	if dropdown == null:
		return
	dropdown.clear()
	dropdown.add_item("None")
	dropdown.set_item_metadata(dropdown.item_count - 1, "")
	var library := RuntimeArchetypeLibraryLoaderScript.load_default()
	if library.has_errors():
		return
	for archetype in library.available_for(_selected_generated_difficulty_id(), _selected_generated_monster_kind()):
		dropdown.add_item(archetype.name)
		dropdown.set_item_metadata(dropdown.item_count - 1, archetype.id)
	if selected_archetype_id == "":
		dropdown.select(0)
		return
	for index in range(dropdown.item_count):
		if str(dropdown.get_item_metadata(index)) == selected_archetype_id:
			dropdown.select(index)
			return
	dropdown.select(0)


func _add_defense_spin(parent: VBoxContainer, field: String, label_text: String, min_value: float, max_value: float, step: float, rounded: bool) -> void:
	var row := _build_labeled_row(parent, label_text)
	var spin := SpinBox.new()
	spin.name = "%sSpin" % field.to_pascal_case()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.rounded = rounded
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin.value_changed.connect(_on_defense_spin_changed.bind(field))
	row.add_child(spin)
	_defense_spins[field] = spin
	if field == "armor":
		_armor_spin = spin
	elif field == "poison_resistance":
		_poison_resist_spin = spin


func _on_defense_spin_changed(value: float, field: String) -> void:
	if _refreshing_defenses:
		return
	if field == "armor":
		armor_changed.emit(roundi(value))
	elif field == "poison_resistance":
		poison_resist_changed.emit(value / 100.0)
	if PERCENT_FIELDS.has(field):
		defense_changed.emit(field, value / 100.0)
	elif field == "armor" or field == "cleanse_threshold" or field == "stun_duration_ms" or field == "interrupt_skip_count":
		defense_changed.emit(field, roundi(value))
	else:
		defense_changed.emit(field, value)


func _on_roll_generated_pressed() -> void:
	var archetype_a_id := _selected_archetype_id(_primary_archetype_option)
	var archetype_b_id := _selected_archetype_id(_secondary_archetype_option)
	if archetype_a_id == "" and archetype_b_id == "":
		return
	generated_roll_requested.emit(
		_selected_generated_contract_level(),
		_selected_generated_difficulty_id(),
		_selected_generated_monster_kind(),
		archetype_a_id,
		archetype_b_id
	)


func _selected_generated_contract_level() -> int:
	if _generator_contract_level_spin == null:
		return 1
	return clampi(roundi(_generator_contract_level_spin.value), 1, 30)


func _selected_generated_difficulty_id() -> int:
	var difficulty_id := 1
	if _generator_difficulty_option != null and _generator_difficulty_option.item_count > 0 and _generator_difficulty_option.selected >= 0:
		difficulty_id = _generator_difficulty_option.get_item_id(_generator_difficulty_option.selected)
	return difficulty_id


func _selected_generated_monster_kind() -> String:
	if _generator_type_option == null or _generator_type_option.item_count <= 0 or _generator_type_option.selected < 0:
		return "normal"
	return str(_generator_type_option.get_item_metadata(_generator_type_option.selected))


func _selected_archetype_id(dropdown: OptionButton) -> String:
	if dropdown == null or dropdown.item_count <= 0 or dropdown.selected < 0:
		return ""
	return str(dropdown.get_item_metadata(dropdown.selected))


## Pushes the target's current stats into the spinboxes. Safe to call after
## every edit (including this panel's own, via training_room.gd's
## fight_setup_changed round-trip) -- SpinBox.value only emits value_changed
## on an actual change, so refreshing with the value that's already current
## is a no-op signal-wise, same as the Duration/Gold controls.
func refresh(armor: int, poison_resistance: float) -> void:
	refresh_defenses({
		"armor": armor,
		"poison_resistance": poison_resistance,
	})


func refresh_defenses(defenses: Dictionary) -> void:
	_refreshing_defenses = true
	for field in _defense_spins:
		var spin: SpinBox = _defense_spins[field]
		var value: Variant = defenses.get(field, 0)
		spin.value = roundi(float(value) * 100.0) if PERCENT_FIELDS.has(field) else float(value)
	_refreshing_defenses = false


func refresh_generated_info(_draft: GeneratedMonsterDraft) -> void:
	pass
