extends RefCounted
## Enemy debuff lifetime; separate from player buffs and per-attack counters.
const MAX_STACKS := 50
const Effects = preload("res://scripts/systems/combat_effect_state.gd")
const TimerMath = preload("res://scripts/systems/combat_timer_math.gd")
var state
var starting_block := 0.0
var starting_absorb := 0.0
var initialization_error := ""

func _init(player: PlayerStats, block: float, absorb: float, trace = null) -> void:
	state = Effects.new(null, trace)
	if player.finders_keepers_rank < 0 or player.finders_keepers_rank > 2 or player.death_pact_rank < 0 or player.death_pact_rank > 3:
		initialization_error = "Invalid Finders Keepers or Death Pact rank."
		return
	starting_block = block * (1.0 - 0.5 * player.finders_keepers_rank)
	starting_absorb = absorb
	var timer := TimerMath.scaled_duration(3000 + 1000 * player.death_pact_rank, player.increased_buff_duration)
	if timer.error != "":
		initialization_error = timer.error
		return
	for status in ["penetration", "potency"]:
		initialization_error = state.define(status, {"source_id": "status." + status,
			"duration_ms": timer.duration_ms, "cap": MAX_STACKS,
			"mode": "add", "unit": "stacks", "owner_id": "enemy"})
		if initialization_error != "":
			return

func grant(status: String, base: int, player: PlayerStats, time_ms: int, context: Dictionary, is_conversion: bool = false) -> Dictionary:
	var units := maxi(0, base)
	if units > 0 and not is_conversion:
		units += maxi(0, player.bonus_penetration_stacks if status == "penetration" else player.bonus_potency_stacks)
		if bool(player.special_effects.get("double_applied_stacks", false)):
			units *= 2
	return state.grant(status, units, time_ms, context)

func values() -> Dictionary:
	return {"block": starting_block - int(state.snapshot("penetration").get("stacks", 0)),
		"absorb": starting_absorb - int(state.snapshot("potency").get("stacks", 0))}

func cleanse(time_ms: int, context: Dictionary) -> String:
	for status in ["penetration", "potency"]:
		var error: String = state.clear_effect(status, time_ms, "cleansed", context)
		if error != "":
			return error
	return ""
