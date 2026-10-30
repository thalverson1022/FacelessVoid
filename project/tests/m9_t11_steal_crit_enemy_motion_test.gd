extends "res://tests/m9_t11_tavern_enemy_motion_test.gd"
func _initialize() -> void:
	OS.set_environment("FV_TAVERN_STEAL_CRIT", "1")
	super._initialize()
