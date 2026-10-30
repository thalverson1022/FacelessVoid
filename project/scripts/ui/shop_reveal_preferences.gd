extends RefCounted
## Session-only preference: every game launch starts with reveals enabled.

static var _skip_animations := false


static func load_skip_animations() -> bool:
	return _skip_animations


static func save_skip_animations(skip: bool) -> void:
	_skip_animations = skip
