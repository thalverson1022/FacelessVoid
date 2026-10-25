extends AcceptDialog
## Persistent keyboard-accessible inspection, shared by both build panels/modes.
const Formatter = preload("res://scripts/ui/skill_tooltip_formatter.gd")
var state
var skill: Skill
var editing_blocked: Callable
var _text: RichTextLabel
var _add: Button
var _icon: TextureRect
var _reason: Label
var _return_focus: WeakRef
var _last_playback_bucket := -1

func _ready() -> void:
	title = "Skill details"
	add_theme_stylebox_override("panel", CardStyle.make_stylebox())
	get_ok_button().text = "Close"
	var box := VBoxContainer.new()
	add_child(box)
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(48, 48)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(_icon)
	_text = RichTextLabel.new()
	_text.custom_minimum_size = Vector2(540, 300)
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", 20)
	_text.focus_mode = Control.FOCUS_ALL
	box.add_child(_text)
	_reason = Label.new()
	_reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reason.custom_minimum_size.x = 540
	_reason.size.x = 540
	_reason.add_theme_font_size_override("font_size", 18)
	box.add_child(_reason)
	_add = add_button("Add to rotation", false, "add")
	custom_action.connect(func(_action): _append())
	state.build_changed.connect(refresh)
	state.lock_changed.connect(refresh)
	visibility_changed.connect(func():
		if not visible:
			_restore_focus()
	)

func inspect(value: Skill, source: Control) -> void:
	skill = value
	_return_focus = weakref(source)
	refresh()
	popup_centered(Vector2i(600, 440))
	_text.grab_focus()

func blocked_reason() -> String:
	if editing_blocked.is_valid() and editing_blocked.call():
		return "Finish or skip combat playback before editing."
	if state.build_locked:
		return "Unlock the rotation to edit. Inspection remains available."
	if state.rotation.size() >= BuildResolver.MAX_ROTATION_SIZE:
		return "Rotation is full (10 slots). Remove a slot before adding."
	if skill != null and not state.unlocked_skills().any(func(value): return value.id == skill.id):
		return "This skill is no longer unlocked."
	return ""

func refresh() -> void:
	if skill == null or _text == null:
		return
	for current in state.unlocked_skills():
		if current.id == skill.id:
			skill = current
			break
	_icon.texture = skill.icon
	var reason := blocked_reason()
	var scroll := _text.get_v_scroll_bar().value
	_text.text = Formatter.details_for(skill, state)
	if state.has_meta("combat_presentation"):
		_text.text = state.get_meta("combat_presentation").details_for(skill) + "\n\nPlanning reference (not a live damage prediction)\n" + _text.text
	_text.get_v_scroll_bar().set_deferred("value", scroll)
	_reason.text = reason
	_reason.visible = not reason.is_empty()
	_add.disabled = not reason.is_empty()
	_add.tooltip_text = reason

func _append() -> void:
	if skill == null or not blocked_reason().is_empty():
		return
	var rotation: Array[Skill] = state.rotation.duplicate()
	rotation.append(skill)
	state.set_rotation(rotation)
	refresh()

func _restore_focus() -> void:
	if _return_focus != null and is_instance_valid(_return_focus.get_ref()):
		_return_focus.get_ref().grab_focus()


func _process(_delta: float) -> void:
	if visible and state.has_meta("combat_presentation"):
		var bucket: int = state.get_meta("combat_presentation").time_ms / 100
		if bucket != _last_playback_bucket:
			_last_playback_bucket = bucket
			refresh()
	elif visible and _last_playback_bucket >= 0:
		_last_playback_bucket = -1
		refresh()
