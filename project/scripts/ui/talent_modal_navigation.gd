extends Node
## Keyboard containment for the two talent modal implementations.
var modal: Control
var previous_focus: Control
var marked: Control
var details: AcceptDialog
var keyboard_active := false

func _ready() -> void:
	modal = get_parent()
	modal.visibility_changed.connect(_visibility_changed)
	details = AcceptDialog.new()
	details.title = "Talent details"
	details.dialog_autowrap = true
	var close_key := InputEventKey.new()
	close_key.keycode = KEY_ESCAPE
	var close_shortcut := Shortcut.new()
	close_shortcut.events = [close_key]
	details.get_ok_button().shortcut = close_shortcut
	modal.add_child(details)

func _visibility_changed() -> void:
	if modal.visible:
		previous_focus = get_viewport().gui_get_focus_owner()
		_focus_first.call_deferred()
	elif is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree():
		previous_focus.grab_focus()

func controls() -> Array[Control]:
	var result: Array[Control] = []
	for node in modal.find_children("*", "Control", true, false):
		if node is Control and node.is_visible_in_tree() and node.focus_mode == Control.FOCUS_ALL and not (node is BaseButton and node.disabled):
			if node is Button and node.flat and node.get_parent() == modal: continue
			result.append(node)
	return result

func _focus_first() -> void:
	var items := controls()
	if not items.is_empty(): items[0].grab_focus()

func mark(control: Control) -> void:
	if is_instance_valid(marked):
		marked.remove_theme_stylebox_override("focus")
		if marked.has_meta("action_key"): marked.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	marked = control
	if control == null: return
	var outline := StyleBoxFlat.new()
	outline.bg_color = Color.TRANSPARENT
	outline.border_color = UIColors.TEXT_NORMAL
	outline.set_border_width_all(2)
	control.add_theme_stylebox_override("focus", outline)

func _process(_delta: float) -> void:
	if keyboard_active and modal.is_visible_in_tree() and not details.visible:
		var focus := get_viewport().gui_get_focus_owner()
		if focus != null and modal.is_ancestor_of(focus) and (not is_instance_valid(marked) or focus != marked):
			mark(focus)

func _input(event: InputEvent) -> void:
	if not modal.is_visible_in_tree() or details.visible: return
	if event is InputEventMouseButton:
		keyboard_active = false
		mark(null)
		return
	if not event is InputEventKey or not event.pressed or event.echo: return
	keyboard_active = true
	var focus := get_viewport().gui_get_focus_owner()
	if event.keycode == KEY_ESCAPE:
		modal.hide()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_TAB:
		var items := controls()
		if items.is_empty(): return
		var index := items.find(focus)
		var next := items[posmod(index + (-1 if event.shift_pressed else 1), items.size())]
		next.grab_focus()
		mark(next)
		get_viewport().set_input_as_handled()
	elif focus != null and modal.is_ancestor_of(focus):
		mark(focus)
		if event.keycode == KEY_F1 and focus is IconTooltipButton:
			details.dialog_text = focus._get_tooltip(Vector2.ZERO)
			details.popup_centered(Vector2i(520, 380))
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_DELETE and str(focus.get_meta("action_key", "")).begins_with("buy:"):
			var view = focus
			while view != null and not view.has_method("transact"): view = view.get_parent()
			if view != null:
				var key: String = focus.get_meta("action_key")
				view.transact("refund", key.trim_prefix("buy:"), key)
			get_viewport().set_input_as_handled()
