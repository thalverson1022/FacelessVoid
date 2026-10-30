extends Control
## Shop's four dimmed/input-blocking regions leave the Gear panel usable.
var clear_control: Control
var _regions: Array[ColorRect] = []

static func fit_below(overlay: Control, play_area: Control, after_control: bool = false) -> void:
	var update := func():
		if is_instance_valid(overlay) and is_instance_valid(play_area):
			var edge := play_area.get_global_rect().end.y if after_control else play_area.get_global_rect().position.y
			overlay.offset_top = maxf(0.0, edge - overlay.get_parent().get_global_rect().position.y)
	play_area.item_rect_changed.connect(update)
	overlay.get_parent().resized.connect(update)
	update.call_deferred()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in 4:
		var region := ColorRect.new()
		region.color = Color(0, 0, 0, 0.6)
		region.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(region)
		_regions.append(region)

func _process(_delta: float) -> void:
	var hole := Rect2()
	if is_instance_valid(clear_control) and clear_control.is_visible_in_tree():
		hole = Rect2(clear_control.get_global_rect().position - global_position, clear_control.size).intersection(Rect2(Vector2.ZERO, size))
	var boxes := [Rect2(0,0,size.x,hole.position.y),
		Rect2(0,hole.end.y,size.x,maxf(0,size.y-hole.end.y)),
		Rect2(0,hole.position.y,hole.position.x,hole.size.y),
		Rect2(hole.end.x,hole.position.y,maxf(0,size.x-hole.end.x),hole.size.y)]
	for i in 4:
		_regions[i].position = boxes[i].position
		_regions[i].size = boxes[i].size
