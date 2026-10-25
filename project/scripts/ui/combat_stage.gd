class_name CombatStage
extends Control
## Shared presentation-only combat stage for Adventure and Practice Room.
## It defines stable actor/effect/status anchors so later sprite animation
## work has a physical layer to target without touching combat resolution.

# A single reusable echo owns its real-time animation and fade. It never
# changes the main actor, nor schedules deferred attacks into another cast.
class RetriggerGhost:
	extends TextureRect
	var textures: Array[Texture2D] = []
	var elapsed := 0.0
	var duration := 0.2
	var start_position := Vector2.ZERO
	var drift := Vector2.ZERO
	func _process(delta: float) -> void:
		if CombatEffectIcons.reduced_motion:
			stop()
			return
		elapsed += delta
		var progress := clampf(elapsed / duration, 0.0, 1.0)
		if progress >= 1.0 or textures.is_empty():
			stop()
			return
		texture = textures[mini(int(progress * textures.size()), textures.size() - 1)]
		position = start_position + drift * sin(progress * PI * 0.5)
		modulate.a = 0.48 * (1.0 - smoothstep(0.65, 1.0, progress))
	func stop() -> void:
		hide()
		modulate.a = 0.0
		set_process(false)

var _flurry_contact_centers := {}
var _retrigger_ghost: RetriggerGhost
const RETRIGGER_GHOST_MIN_REAL_SEC := 0.125
const RETRIGGER_GHOST_SEC := 0.16

class DebugGridOverlay:
	extends Control

	var combat_stage

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)

	func _draw() -> void:
		if combat_stage == null:
			return
		var stage_size: Vector2 = size
		if stage_size.x <= 0.0 or stage_size.y <= 0.0:
			return

		var grid_color := Color(0.45, 0.85, 1.0, 0.22)
		var axis_color := Color(0.45, 0.85, 1.0, 0.55)
		for index in 11:
			var x := stage_size.x * float(index) / 10.0
			var y := stage_size.y * float(index) / 10.0
			var is_axis := index == 5
			draw_line(Vector2(x, 0.0), Vector2(x, stage_size.y), axis_color if is_axis else grid_color, 2.0 if is_axis else 1.0)
			draw_line(Vector2(0.0, y), Vector2(stage_size.x, y), axis_color if is_axis else grid_color, 2.0 if is_axis else 1.0)

		_draw_marker(combat_stage._stage_point_for_grid(combat_stage.PLAYER_STAGE_GRID), Color(0.35, 1.0, 0.45, 0.9), 9.0)
		_draw_marker(combat_stage._stage_point_for_grid(combat_stage.ENEMY_STAGE_GRID), Color(1.0, 0.35, 0.35, 0.9), 9.0)
		_draw_sprite_frame(combat_stage.player_actor_anchor, combat_stage._player_sprite)
		_draw_sprite_frame(combat_stage.enemy_actor_anchor, combat_stage._enemy_sprite)
		_draw_marker(combat_stage._sprite_anchor_point(combat_stage.player_actor_anchor, combat_stage._player_sprite, combat_stage._player_current_anchor_point), Color(1.0, 1.0, 0.25, 0.95), 5.0)
		_draw_marker(combat_stage._sprite_anchor_point(combat_stage.enemy_actor_anchor, combat_stage._enemy_sprite, combat_stage.PEASANT_ANCHOR_POINT), Color(1.0, 1.0, 0.25, 0.95), 5.0)
		_draw_slow_snow_anchor()

	func _draw_marker(point: Vector2, color: Color, radius: float) -> void:
		draw_circle(point, radius, color)
		draw_line(point + Vector2(-radius * 1.8, 0.0), point + Vector2(radius * 1.8, 0.0), color, 2.0)
		draw_line(point + Vector2(0.0, -radius * 1.8), point + Vector2(0.0, radius * 1.8), color, 2.0)

	func _draw_sprite_frame(anchor: Control, sprite: TextureRect) -> void:
		if anchor == null or sprite == null or not sprite.visible:
			return
		var frame_rect := Rect2(anchor.position + combat_stage._sprite_render_top_left(sprite), sprite.size * sprite.scale)
		draw_rect(frame_rect, Color(1.0, 0.0, 0.0, 0.9), false, 2.0)

	func _draw_slow_snow_anchor() -> void:
		if combat_stage.player_actor_anchor == null:
			return
		var snow_rect: Rect2 = combat_stage._slow_snow_field_rect()
		var anchor_point: Vector2 = snow_rect.position + snow_rect.size * 0.5
		var color := Color(0.55, 0.9, 1.0, 0.95)
		draw_rect(snow_rect, Color(color.r, color.g, color.b, 0.16), false, 2.0)
		_draw_marker(anchor_point, color, 7.0)


class ContactShadow:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var radius := size.x * 0.5
		if radius <= 0.0:
			return
		draw_set_transform(size * 0.5, 0.0, Vector2(1.0, 0.32))
		for index in 5:
			var progress := float(index) / 4.0
			var layer_radius := lerpf(radius, radius * 0.36, progress)
			var alpha := lerpf(0.04, 0.22, progress)
			draw_circle(Vector2.ZERO, layer_radius, Color(0.0, 0.0, 0.0, alpha), true, -1.0, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


class StunStarsEffect:
	extends Control

	const STAR_COLOR := Color(1.0, 0.86, 0.22, 0.96)
	const STAR_OUTLINE := Color(0.18, 0.08, 0.0, 0.82)
	const ORBIT_CENTER := Vector2(75.0, 42.0)
	const ORBIT_RADIUS := Vector2(44.0, 12.0)
	const STAR_RADIUS := 10.0
	const STAR_COUNT := 3
	const ROTATION_SPEED := 5.4

	var elapsed_sec := 0.0
	var duration_sec := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(true)

	func _process(delta: float) -> void:
		elapsed_sec += delta
		queue_redraw()
		if duration_sec > 0.0 and elapsed_sec >= duration_sec:
			queue_free()

	func _draw() -> void:
		var pulse := 0.86 + sin(elapsed_sec * 9.0) * 0.14
		for index in STAR_COUNT:
			var angle := elapsed_sec * ROTATION_SPEED + TAU * float(index) / float(STAR_COUNT)
			var depth := 0.72 + 0.28 * sin(angle)
			var point := ORBIT_CENTER + Vector2(cos(angle) * ORBIT_RADIUS.x, sin(angle) * ORBIT_RADIUS.y)
			_draw_star(point, STAR_RADIUS * pulse * depth)

	func _draw_star(center: Vector2, radius: float) -> void:
		var points := PackedVector2Array()
		for index in 10:
			var angle := -PI * 0.5 + TAU * float(index) / 10.0
			var point_radius := radius if index % 2 == 0 else radius * 0.46
			points.append(center + Vector2(cos(angle), sin(angle)) * point_radius)
		draw_colored_polygon(points, STAR_OUTLINE)
		var inner := PackedVector2Array()
		for point in points:
			inner.append(center + (point - center) * 0.76)
		draw_colored_polygon(inner, STAR_COLOR)


class CleanseBurstEffect:
	extends Control

	const BURST_COLOR := Color(0.78, 0.92, 1.0, 0.92)
	const BURST_CORE := Color(1.0, 1.0, 1.0, 0.78)
	const DURATION_SEC := 0.72
	const MAX_RADIUS := 108.0
	const SECOND_PULSE_DELAY := 0.28

	var elapsed_sec := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(true)

	func _process(delta: float) -> void:
		elapsed_sec += delta
		queue_redraw()
		if elapsed_sec >= DURATION_SEC:
			queue_free()

	func _draw() -> void:
		var center := size * 0.5
		_draw_pulse(center, clampf(elapsed_sec / 0.46, 0.0, 1.0), 1.0)
		if elapsed_sec >= SECOND_PULSE_DELAY:
			_draw_pulse(center, clampf((elapsed_sec - SECOND_PULSE_DELAY) / 0.44, 0.0, 1.0), 0.82)
		var core_alpha := maxf(0.0, 1.0 - elapsed_sec / DURATION_SEC)
		draw_circle(center, lerpf(9.0, 2.0, clampf(elapsed_sec / DURATION_SEC, 0.0, 1.0)), Color(BURST_CORE.r, BURST_CORE.g, BURST_CORE.b, 0.34 * core_alpha), true)

	func _draw_pulse(center: Vector2, progress: float, strength: float) -> void:
		var eased := 1.0 - pow(1.0 - progress, 2.0)
		var alpha := 1.0 - progress
		var ring_radius := lerpf(18.0, MAX_RADIUS, eased)
		draw_arc(center, ring_radius, 0.0, TAU, 72, Color(BURST_COLOR.r, BURST_COLOR.g, BURST_COLOR.b, BURST_COLOR.a * alpha * strength), 5.0, true)
		draw_arc(center, ring_radius * 0.6, 0.0, TAU, 72, Color(BURST_CORE.r, BURST_CORE.g, BURST_CORE.b, BURST_CORE.a * alpha * strength), 2.5, true)


class InterruptSlashEffect:
	extends Control

	const DURATION_SEC := 0.38
	const SLASH_COLOR := Color(1.0, 0.18, 0.12, 0.96)
	const SLASH_CORE := Color(1.0, 0.78, 0.48, 0.86)
	const RING_COLOR := Color(0.95, 0.12, 0.2, 0.58)

	var elapsed_sec := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(true)

	func _process(delta: float) -> void:
		elapsed_sec += delta
		queue_redraw()
		if elapsed_sec >= DURATION_SEC:
			queue_free()

	func _draw() -> void:
		var center := size * 0.5
		var progress := clampf(elapsed_sec / DURATION_SEC, 0.0, 1.0)
		var snap := sin(progress * PI)
		var alpha := 1.0 - progress
		var slash_extent := lerpf(30.0, 70.0, minf(progress * 2.0, 1.0))
		var slash_width := lerpf(8.0, 3.0, progress)
		_draw_slash(center, Vector2(-slash_extent, -34.0), Vector2(slash_extent, 34.0), slash_width, alpha)
		_draw_slash(center, Vector2(-slash_extent, 34.0), Vector2(slash_extent, -34.0), slash_width, alpha)
		draw_arc(center, lerpf(18.0, 58.0, progress), 0.0, TAU, 44, Color(RING_COLOR.r, RING_COLOR.g, RING_COLOR.b, RING_COLOR.a * alpha), 3.0, true)
		for index in 6:
			var angle := TAU * float(index) / 6.0 + elapsed_sec * 9.0
			var spark_start := center + Vector2(cos(angle), sin(angle)) * lerpf(16.0, 42.0, progress)
			var spark_end := spark_start + Vector2(cos(angle), sin(angle)) * (8.0 + 8.0 * snap)
			draw_line(spark_start, spark_end, Color(SLASH_CORE.r, SLASH_CORE.g, SLASH_CORE.b, alpha * 0.8), 2.0, true)

	func _draw_slash(center: Vector2, start_offset: Vector2, end_offset: Vector2, width: float, alpha: float) -> void:
		draw_line(center + start_offset, center + end_offset, Color(0.18, 0.02, 0.02, alpha * 0.92), width + 5.0, true)
		draw_line(center + start_offset, center + end_offset, Color(SLASH_COLOR.r, SLASH_COLOR.g, SLASH_COLOR.b, SLASH_COLOR.a * alpha), width, true)
		draw_line(center + start_offset * 0.84, center + end_offset * 0.84, Color(SLASH_CORE.r, SLASH_CORE.g, SLASH_CORE.b, SLASH_CORE.a * alpha), maxf(1.5, width * 0.34), true)


class SlowAuraEffect:
	extends Control

	const FROST_COLOR := Color(0.55, 0.86, 1.0, 0.62)
	const FROST_CORE := Color(0.88, 0.97, 1.0, 0.48)
	const BREATH_COLOR := Color(0.86, 0.96, 1.0, 0.58)
	const BREATH_INTERVAL_SEC := 1.1
	const BREATH_LIFETIME_SEC := 1.05
	const MOTE_COUNT := 14

	var elapsed_sec := 0.0
	var strength := 0.0
	var breath_emit_sec := 0.0
	var breaths: Array[Dictionary] = []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(true)

	func _process(delta: float) -> void:
		elapsed_sec += delta
		breath_emit_sec += delta
		if breath_emit_sec >= BREATH_INTERVAL_SEC:
			breath_emit_sec = 0.0
			breaths.append({"age": 0.0, "offset": sin(elapsed_sec * 2.7) * 5.0})
		for breath in breaths:
			breath["age"] = float(breath.get("age", 0.0)) + delta
		breaths = breaths.filter(func(breath): return float(breath.get("age", 0.0)) < BREATH_LIFETIME_SEC)
		queue_redraw()

	func _draw() -> void:
		var slow_alpha := clampf(0.38 + strength * 0.5, 0.38, 0.82)
		var foot_center := Vector2(size.x * 0.48, size.y * 0.78)
		draw_set_transform(foot_center, 0.0, Vector2(1.0, 0.34))
		draw_arc(Vector2.ZERO, 48.0, 0.0, TAU, 64, Color(FROST_COLOR.r, FROST_COLOR.g, FROST_COLOR.b, FROST_COLOR.a * slow_alpha), 4.0, true)
		draw_arc(Vector2.ZERO, 30.0 + sin(elapsed_sec * 3.2) * 3.0, 0.0, TAU, 64, Color(FROST_CORE.r, FROST_CORE.g, FROST_CORE.b, FROST_CORE.a * slow_alpha), 2.0, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		for index in MOTE_COUNT:
			var seed := float(index) * 12.9898
			var x := 24.0 + fposmod(seed * 19.17, size.x - 48.0)
			var y := 16.0 + fposmod(elapsed_sec * (18.0 + float(index % 5) * 3.0) + seed * 7.31, size.y * 0.66)
			var twinkle := 0.5 + sin(elapsed_sec * 4.0 + seed) * 0.5
			draw_circle(Vector2(x + sin(elapsed_sec * 1.7 + seed) * 5.0, y), 1.5 + twinkle * 1.2, Color(FROST_CORE.r, FROST_CORE.g, FROST_CORE.b, 0.18 + 0.32 * twinkle * slow_alpha), true)

		var mouth := Vector2(size.x * 0.58, size.y * 0.30)
		for breath in breaths:
			var age := float(breath.get("age", 0.0))
			var progress := clampf(age / BREATH_LIFETIME_SEC, 0.0, 1.0)
			var alpha := (1.0 - progress) * 0.58
			var center := mouth + Vector2(18.0 + progress * 34.0, -8.0 - progress * 18.0 + float(breath.get("offset", 0.0)))
			var radius := lerpf(4.0, 15.0, progress)
			draw_circle(center, radius, Color(BREATH_COLOR.r, BREATH_COLOR.g, BREATH_COLOR.b, alpha), true)
			draw_circle(center + Vector2(radius * 0.5, -radius * 0.24), radius * 0.55, Color(BREATH_COLOR.r, BREATH_COLOR.g, BREATH_COLOR.b, alpha * 0.6), true)


const ACTOR_SIZE := Vector2(160, 148)
const ACTOR_LOCAL_ANCHOR := Vector2(80, 140)
const CONTACT_SIZE := Vector2(96, 96)
const STATUS_SIZE := Vector2(150, 42)
const ROGUE_FRAME_SIZE := Vector2i(48, 48)
const PEASANT_FRAME_SIZE := Vector2i(32, 32)
const ROGUE_VISIBLE_BOUNDS := Rect2(Vector2(15, 9), Vector2(22, 28))
const PEASANT_VISIBLE_BOUNDS := Rect2(Vector2(7, 11), Vector2(17, 21))
const ROGUE_ANCHOR_POINT := Vector2(24, 24)
const PEASANT_ANCHOR_POINT := Vector2(16, 16)
const ROGUE_SPRITE_SCALE := 4.0
const PEASANT_SPRITE_SCALE := 5.0
const PRACTICE_DUMMY_SPRITE_SCALE := 4.15
const ENEMY_COMBAT_ROLE_NORMAL := "normal"
const ENEMY_COMBAT_ROLE_CAPTAIN := "captain"
const ENEMY_COMBAT_ROLE_ELITE := "elite"
const ENEMY_COMBAT_ROLE_BOSS := "boss"
const ENEMY_COMBAT_ROLE_SCALE := {
	ENEMY_COMBAT_ROLE_NORMAL: 0.9,
	ENEMY_COMBAT_ROLE_CAPTAIN: 1.05,
	ENEMY_COMBAT_ROLE_ELITE: 1.12,
	ENEMY_COMBAT_ROLE_BOSS: 1.35,
}
const PRACTICE_DUMMY_ANCHOR_POINT := Vector2(16, 32)
const PRACTICE_DUMMY_STAGE_GRID := Vector2(0.62, 1.0)
const PRACTICE_DUMMY_STAGE_OFFSET := Vector2(38.0, 0.0)
const PRACTICE_ROGUE_SPRITE_OFFSET := Vector2(0.0, -28.0)
const PRACTICE_DUMMY_SPRITE_OFFSET := Vector2(0.0, 88.0)
const PRACTICE_DUMMY_SHADOW_OFFSET := Vector2(0.0, -16.0)
const PLAYER_VISUAL_KEY := "rogue"
const MOUTHY_DRUNK_VISUAL_KEY := "mouthy_drunk"
const DRUNK_BUDDY_VISUAL_KEY := "drunk_buddy"
const TAVERN_BOUNCER_VISUAL_KEY := "tavern_bouncer"
const HIRED_GOON_VISUAL_KEY := "hired_goon"
const VYRA_VISUAL_KEY := "vyra"
const KNIVES_VISUAL_KEY := "knives"
const PRACTICE_DUMMY_VISUAL_KEY := "practice_dummy"
const STATIC_ENEMY_SPRITE_SCALE := 0.145
const STATIC_ENEMY_LAYOUT_FRAME_SIZE := Vector2(1254, 1254)
const STATIC_ENEMY_ANCHOR_RATIO := Vector2(0.5, 0.42)
const SWAMP_GREEN_SLIME_VISUAL_KEY := "swamp_green_slime"
const SWAMP_GOBLIN_VISUAL_KEY := "swamp_goblin"
const SWAMP_BOG_RAT_VISUAL_KEY := "swamp_bog_rat"
const SWAMP_GIANT_LEECH_VISUAL_KEY := "swamp_giant_leech"
const SWAMP_POISON_FROG_VISUAL_KEY := "swamp_poison_frog"
const SWAMP_TROLL_VISUAL_KEY := "swamp_troll"
const SWAMP_BOG_WITCH_VISUAL_KEY := "swamp_bog_witch"
const SWAMP_HYDRA_SPAWN_VISUAL_KEY := "swamp_hydra_spawn"
const SWAMP_MIRE_KNIGHT_VISUAL_KEY := "swamp_mire_knight"
const SWAMP_GREEN_HAG_VISUAL_KEY := "swamp_green_hag"
const SWAMP_HYDRA_VISUAL_KEY := "swamp_hydra"
const SWAMP_ANCIENT_TROLL_VISUAL_KEY := "swamp_ancient_troll"
const SWAMP_SLIME_QUEEN_VISUAL_KEY := "swamp_slime_queen"
const SWAMP_DROWNED_MATRIARCH_VISUAL_KEY := "swamp_drowned_matriarch"
const SWAMP_BOGHEART_COLOSSUS_VISUAL_KEY := "swamp_bogheart_colossus"
const CAVE_VAMPIRE_BAT_VISUAL_KEY := "cave_vampire_bat"
const CAVE_WOLF_SPIDER_VISUAL_KEY := "cave_wolf_spider"
const CAVE_GOBLIN_VISUAL_KEY := "cave_goblin"
const CAVE_TROGLODYTE_VISUAL_KEY := "cave_troglodyte"
const CAVE_OGRE_VISUAL_KEY := "cave_ogre"
const CAVE_TROLL_VISUAL_KEY := "cave_troll"
const CAVE_GIANT_CENTIPEDE_VISUAL_KEY := "cave_giant_centipede"
const CAVE_BASILISK_VISUAL_KEY := "cave_basilisk"
const CAVE_BRUTE_VISUAL_KEY := "cave_brute"
const CAVE_ECHOING_SEER_VISUAL_KEY := "cave_echoing_seer"
const CAVE_PURPLE_WYRM_VISUAL_KEY := "cave_purple_wyrm"
const CAVE_GOBLIN_KING_VISUAL_KEY := "cave_goblin_king"
const CAVE_ANCIENT_BASILISK_VISUAL_KEY := "cave_ancient_basilisk"
const CAVE_DEEP_MAW_VISUAL_KEY := "cave_deep_maw"
const CAVE_GEMVEIN_TYRANT_VISUAL_KEY := "cave_gemvein_tyrant"
const GRAVEYARD_RESTLESS_SPIRIT_VISUAL_KEY := "graveyard_restless_spirit"
const GRAVEYARD_GIANT_RAT_VISUAL_KEY := "graveyard_giant_rat"
const GRAVEYARD_WOLF_VISUAL_KEY := "graveyard_wolf"
const GRAVEYARD_SKELETON_VISUAL_KEY := "graveyard_skeleton"
const GRAVEYARD_ZOMBIE_VISUAL_KEY := "graveyard_zombie"
const GRAVEYARD_FLESH_GOLEM_VISUAL_KEY := "graveyard_flesh_golem"
const GRAVEYARD_GRAVE_ROBBER_VISUAL_KEY := "graveyard_grave_robber"
const GRAVEYARD_WIGHT_VISUAL_KEY := "graveyard_wight"
const GRAVEYARD_NECROMANCER_VISUAL_KEY := "graveyard_necromancer"
const GRAVEYARD_MIRE_KNIGHT_VISUAL_KEY := "graveyard_mire_knight"
const GRAVEYARD_BONE_COLOSSUS_VISUAL_KEY := "graveyard_bone_colossus"
const GRAVEYARD_LICH_VISUAL_KEY := "graveyard_lich"
const GRAVEYARD_HEADLESS_KNIGHT_VISUAL_KEY := "graveyard_headless_knight"
const GRAVEYARD_BELL_TOWER_REVENANT_VISUAL_KEY := "graveyard_bell_tower_revenant"
const GRAVEYARD_KING_LEORIC_VISUAL_KEY := "graveyard_king_leoric"
const FOREST_SPIDER_VISUAL_KEY := "forest_spider"
const FOREST_GOBLIN_VISUAL_KEY := "forest_goblin"
const FOREST_WISP_VISUAL_KEY := "forest_wisp"
const FOREST_TREANT_SAPLING_VISUAL_KEY := "forest_treant_sapling"
const FOREST_DIRE_WOLF_VISUAL_KEY := "forest_dire_wolf"
const FOREST_WEREWOLF_VISUAL_KEY := "forest_werewolf"
const FOREST_TREANT_VISUAL_KEY := "forest_treant"
const FOREST_ANCIENT_TREANT_VISUAL_KEY := "forest_ancient_treant"
const FOREST_GREEN_HAG_VISUAL_KEY := "forest_green_hag"
const FOREST_NIGHT_STALKER_VISUAL_KEY := "forest_night_stalker"
const FOREST_HOLLOW_EYED_WITCH_VISUAL_KEY := "forest_hollow_eyed_witch"
const FOREST_ROOT_CROWNED_WIDOW_VISUAL_KEY := "forest_root_crowned_widow"
const FOREST_MOONLESS_HUNTMASTER_VISUAL_KEY := "forest_moonless_huntmaster"
const FOREST_GREAT_WAREBEAR_VISUAL_KEY := "forest_great_warebear"
const KEEP_RAT_VISUAL_KEY := "keep_rat"
const KEEP_UNDEAD_GUARD_VISUAL_KEY := "keep_undead_guard"
const KEEP_BANDIT_VISUAL_KEY := "keep_bandit"
const KEEP_CULTIST_VISUAL_KEY := "keep_cultist"
const KEEP_ANIMATED_ARMOR_VISUAL_KEY := "keep_animated_armor"
const KEEP_GARGOYLE_VISUAL_KEY := "keep_gargoyle"
const KEEP_WARLOCK_VISUAL_KEY := "keep_warlock"
const KEEP_DARK_KNIGHT_VISUAL_KEY := "keep_dark_knight"
const KEEP_OATHBREAKER_CAPTAIN_VISUAL_KEY := "keep_oathbreaker_captain"
const KEEP_ARCANE_GOLEM_VISUAL_KEY := "keep_arcane_golem"
const KEEP_FALLEN_KING_VISUAL_KEY := "keep_fallen_king"
const KEEP_BEJEWELED_IRON_GOLEM_VISUAL_KEY := "keep_bejeweled_iron_golem"
const KEEP_HALF_BLOOD_PRINCE_VISUAL_KEY := "keep_half_blood_prince"
const KEEP_LAST_CASTELLAN_VISUAL_KEY := "keep_last_castellan"
const KEEP_FAITHLESS_EXECUTIONER_VISUAL_KEY := "keep_faithless_executioner"
const RUINS_CULTIST_VISUAL_KEY := "ruins_cultist"
const RUINS_ANIMATED_STATUE_VISUAL_KEY := "ruins_animated_statue"
const RUINS_SCARAB_VISUAL_KEY := "ruins_scarab"
const RUINS_WISP_VISUAL_KEY := "ruins_wisp"
const RUINS_MINOTAUR_VISUAL_KEY := "ruins_minotaur"
const RUINS_GUARDIAN_CONSTRUCT_VISUAL_KEY := "ruins_guardian_construct"
const RUINS_ARCANE_GOLEM_VISUAL_KEY := "ruins_arcane_golem"
const RUINS_RUNEMARK_SENTINEL_VISUAL_KEY := "ruins_runemark_sentinel"
const RUINS_SCARAB_QUEEN_VISUAL_KEY := "ruins_scarab_queen"
const RUINS_ANCIENT_GUARDIAN_VISUAL_KEY := "ruins_ancient_guardian"
const RUINS_SPHINX_VISUAL_KEY := "ruins_sphinx"
const RUINS_RUNIC_COLOSSUS_VISUAL_KEY := "ruins_runic_colossus"
const RUINS_FIRST_IDOL_VISUAL_KEY := "ruins_first_idol"
const RUINS_ANCIENT_ARCHIVIST_VISUAL_KEY := "ruins_ancient_archivist"
const ANIMATION_PHYSICAL := "physical"
const ANIMATION_POISON := "poison"
const ANIMATION_HOLD := "hold"
const ANIMATION_TICK := "poison_tick"
const OUTCOME_VICTORY := "victory"
const OUTCOME_DEFEAT := "defeat"
const LUNGE_DISTANCE_PX := 34.0
const RECOIL_DISTANCE_PX := 18.0
const CRIT_RECOIL_DISTANCE_PX := 6.0
const CONTRACT_RUN_IN_DELAY_SEC := 0.18
const CONTRACT_RUN_IN_SEC := 0.95
const CONTRACT_RUN_OUT_SEC := 0.85
const STAGE_GRID_MIN := -5.0
const STAGE_GRID_MAX := 5.0
const STAGE_GRID_MARGIN_PX := 12.0
const PLAYER_STAGE_GRID := Vector2(-1.0, 2.0)
const STUN_STAR_STAGE_GRID_Y := 0.0
const ENEMY_STAGE_GRID := Vector2(1.0, 1.0)
const ACTOR_GROUP_STAGE_OFFSET_PX := Vector2(38.0, 0.0)
const CONTACT_SHADOW_MIN_SIZE := Vector2(54.0, 18.0)
const CONTACT_SHADOW_WIDTH_SCALE := 1.24
const MIN_CAST_ANIMATION_SEC := 0.18
const MAX_CAST_ANIMATION_SEC := 0.42
const TRIGGERED_FOLLOWUP_ANIMATION_SEC := 0.18
const TICK_PULSE_SEC := 0.22
const POISON_VISIBLE_STACK_CAP := 5
const STUN_JOLT_SEC := 0.08
const STUN_JOLT_OFFSET := Vector2(-7.0, 0.0)
const DODGE_AFTERIMAGE_SEC := 0.28
const DODGE_AFTERIMAGE_ALPHA := 0.38
const DODGE_AFTERIMAGE_OFFSETS := [Vector2(-26.0, 0.0), Vector2(0.0, -2.0), Vector2(26.0, 0.0)]
const DODGE_SHIFT_OFFSET := Vector2(18.0, 0.0)
const DODGE_SHIFT_SEC := 0.09
const OUTCOME_POSE_SEC := 0.24
const FIGHT_INTRO_SEC := 0.42
const FIGHT_INTRO_PLAYER_OFFSET := Vector2.ZERO
const FIGHT_INTRO_ENEMY_OFFSET := Vector2.ZERO
const BANDIT_BLADE_ID := "gear.legendary.bandit_blade"
const BANDIT_COIN_TEXTURE := preload("res://assets/Items/Rogue/Lucky_Coin.png")
const BANDIT_COIN_NORMAL_COUNT := 3
const BANDIT_COIN_CRIT_COUNT := 5
const BANDIT_COIN_SIZE_RANGE := Vector2(8.0, 13.0)
const BANDIT_COIN_LIFETIME_SEC := 0.48
const BANDIT_COIN_FADE_DELAY_SEC := 0.1
const BANDIT_COIN_START_ALPHA := 0.82
const BANDIT_COIN_SPRITE_CONTACT_OFFSET := Vector2(-10.0, -12.0)
const BANDIT_COIN_FALLBACK_IMPACT_OFFSET := Vector2(80.0, 82.0)
const BANDIT_COIN_SPREAD_X_RANGE := Vector2(-34.0, 20.0)
const BANDIT_COIN_SPREAD_Y_RANGE := Vector2(-38.0, 14.0)
const ADVENTURE_ENEMY_HIT_EFFECT_OFFSET := Vector2(0.0, 40.0)
const MECHANIC_TEXT_FONT := preload("res://assets/fonts/PirataOne-Regular.ttf")
const MECHANIC_TEXT_FONT_SIZE := 24
const MECHANIC_TEXT_FLOAT_SEC := 0.58
const MECHANIC_TEXT_RISE_PX := 24.0
const CLEANSE_BURST_SIZE := Vector2(236, 236)
const INTERRUPT_SLASH_SIZE := Vector2(166, 128)
const INTERRUPT_PLAYER_EFFECT_OFFSET := Vector2(36.0, -28.0)
const SLOW_AURA_SIZE := Vector2(210, 190)
const SLOW_AURA_OFFSET_X := -26.0
const SLOW_SNOW_STAGE_GRID_Y := 0.0
const PLAYER_ANIMATION_MANIFEST_PATHS := {
	"idle": "res://assets/placeholder_combat_sprites/rogue_bandit/animations/idle/animation_manifest.json",
	"attack_physical": "res://assets/placeholder_combat_sprites/rogue_bandit/animations/attack1/animation_manifest.json",
	"attack_poison": "res://assets/placeholder_combat_sprites/rogue_bandit/animations/attack2/animation_manifest.json",
	"walk": "res://assets/placeholder_combat_sprites/rogue_bandit/animations/walk/animation_manifest.json",
	"hurt": "res://assets/placeholder_combat_sprites/rogue_bandit/animations/idle/animation_manifest.json",
	"defeat": "res://assets/placeholder_combat_sprites/rogue_bandit/animations/death/animation_manifest.json",
}
const ENEMY_ANIMATION_PATHS := {
	PRACTICE_DUMMY_VISUAL_KEY: {
		"idle": "res://assets/characters/practice_dummy/dummy_bounce/frames/frame_001.png",
		"hurt": "res://assets/characters/practice_dummy/dummy_bounce/frames/frame_001.png",
		"defeat": "res://assets/characters/practice_dummy/dummy_bounce/frames/frame_001.png",
	},
	MOUTHY_DRUNK_VISUAL_KEY: {
		"idle": "res://assets/placeholder_combat_sprites/townsfolk/peasants_sprite_sheet.png",
		"hurt": "res://assets/placeholder_combat_sprites/townsfolk/peasants_sprite_sheet.png",
		"defeat": "res://assets/placeholder_combat_sprites/townsfolk/peasants_sprite_sheet.png",
	},
	DRUNK_BUDDY_VISUAL_KEY: {
		"idle": "res://assets/placeholder_combat_sprites/townsfolk/peasants_sprite_sheet.png",
		"hurt": "res://assets/placeholder_combat_sprites/townsfolk/peasants_sprite_sheet.png",
		"defeat": "res://assets/placeholder_combat_sprites/townsfolk/peasants_sprite_sheet.png",
	},
	TAVERN_BOUNCER_VISUAL_KEY: {
		"idle": "res://assets/placeholder_combat_sprites/townsfolk/medieval_townsfolk_sprite_sheet.png",
		"hurt": "res://assets/placeholder_combat_sprites/townsfolk/medieval_townsfolk_sprite_sheet.png",
		"defeat": "res://assets/placeholder_combat_sprites/townsfolk/medieval_townsfolk_sprite_sheet.png",
	},
	HIRED_GOON_VISUAL_KEY: {
		"idle": "res://assets/placeholder_combat_sprites/townsfolk/medieval_townsfolk_2_sprite_sheet.png",
		"hurt": "res://assets/placeholder_combat_sprites/townsfolk/medieval_townsfolk_2_sprite_sheet.png",
		"defeat": "res://assets/placeholder_combat_sprites/townsfolk/medieval_townsfolk_2_sprite_sheet.png",
	},
	VYRA_VISUAL_KEY: {
		"idle": "res://assets/placeholder_combat_sprites/townsfolk/medieval_townsfolk_3_sprite_sheet.png",
		"hurt": "res://assets/placeholder_combat_sprites/townsfolk/medieval_townsfolk_3_sprite_sheet.png",
		"defeat": "res://assets/placeholder_combat_sprites/townsfolk/medieval_townsfolk_3_sprite_sheet.png",
	},
	KNIVES_VISUAL_KEY: {
		"idle": "res://assets/placeholder_combat_sprites/townsfolk/medieval_thief_sprite_sheet.png",
		"hurt": "res://assets/placeholder_combat_sprites/townsfolk/medieval_thief_sprite_sheet.png",
		"defeat": "res://assets/placeholder_combat_sprites/townsfolk/medieval_thief_sprite_sheet.png",
	},
	SWAMP_GREEN_SLIME_VISUAL_KEY: {"idle": "res://assets/enemies/swamp/slime.png", "hurt": "res://assets/enemies/swamp/slime.png", "defeat": "res://assets/enemies/swamp/slime.png"},
	SWAMP_GOBLIN_VISUAL_KEY: {"idle": "res://assets/enemies/swamp/goblin.png", "hurt": "res://assets/enemies/swamp/goblin.png", "defeat": "res://assets/enemies/swamp/goblin.png"},
	SWAMP_BOG_RAT_VISUAL_KEY: {"idle": "res://assets/enemies/swamp/rat.png", "hurt": "res://assets/enemies/swamp/rat.png", "defeat": "res://assets/enemies/swamp/rat.png"},
	SWAMP_GIANT_LEECH_VISUAL_KEY: {"idle": "res://assets/enemies/swamp/leech.png", "hurt": "res://assets/enemies/swamp/leech.png", "defeat": "res://assets/enemies/swamp/leech.png"},
	SWAMP_POISON_FROG_VISUAL_KEY: {"idle": "res://assets/enemies/swamp/frog.png", "hurt": "res://assets/enemies/swamp/frog.png", "defeat": "res://assets/enemies/swamp/frog.png"},
	SWAMP_TROLL_VISUAL_KEY: {"idle": "res://assets/enemies/swamp/Troll.png", "hurt": "res://assets/enemies/swamp/Troll.png", "defeat": "res://assets/enemies/swamp/Troll.png"},
	SWAMP_BOG_WITCH_VISUAL_KEY: {"idle": "res://assets/enemies/swamp/witch.png", "hurt": "res://assets/enemies/swamp/witch.png", "defeat": "res://assets/enemies/swamp/witch.png"},
	SWAMP_HYDRA_SPAWN_VISUAL_KEY: {"idle": "res://assets/enemies/swamp/baby_hydra.png", "hurt": "res://assets/enemies/swamp/baby_hydra.png", "defeat": "res://assets/enemies/swamp/baby_hydra.png"},
	SWAMP_MIRE_KNIGHT_VISUAL_KEY: {"idle": "res://assets/enemies/swamp/Mire_Knight.png", "hurt": "res://assets/enemies/swamp/Mire_Knight.png", "defeat": "res://assets/enemies/swamp/Mire_Knight.png"},
	SWAMP_GREEN_HAG_VISUAL_KEY: {"idle": "res://assets/enemies/swamp/Green_Hag.png", "hurt": "res://assets/enemies/swamp/Green_Hag.png", "defeat": "res://assets/enemies/swamp/Green_Hag.png"},
	SWAMP_HYDRA_VISUAL_KEY: {"idle": "res://assets/enemies/swamp/Big_Hydra.png", "hurt": "res://assets/enemies/swamp/Big_Hydra.png", "defeat": "res://assets/enemies/swamp/Big_Hydra.png"},
	SWAMP_ANCIENT_TROLL_VISUAL_KEY: {"idle": "res://assets/enemies/swamp/Troll_Boss.png", "hurt": "res://assets/enemies/swamp/Troll_Boss.png", "defeat": "res://assets/enemies/swamp/Troll_Boss.png"},
	SWAMP_SLIME_QUEEN_VISUAL_KEY: {"idle": "res://assets/enemies/swamp/Slime_Queen.png", "hurt": "res://assets/enemies/swamp/Slime_Queen.png", "defeat": "res://assets/enemies/swamp/Slime_Queen.png"},
	SWAMP_DROWNED_MATRIARCH_VISUAL_KEY: {"idle": "res://assets/enemies/swamp/Downed_Matriarch.png", "hurt": "res://assets/enemies/swamp/Downed_Matriarch.png", "defeat": "res://assets/enemies/swamp/Downed_Matriarch.png"},
	SWAMP_BOGHEART_COLOSSUS_VISUAL_KEY: {"idle": "res://assets/enemies/swamp/Bog_Colossus.png", "hurt": "res://assets/enemies/swamp/Bog_Colossus.png", "defeat": "res://assets/enemies/swamp/Bog_Colossus.png"},
	CAVE_VAMPIRE_BAT_VISUAL_KEY: {"idle": "res://assets/enemies/cave/bat.png", "hurt": "res://assets/enemies/cave/bat.png", "defeat": "res://assets/enemies/cave/bat.png"},
	CAVE_WOLF_SPIDER_VISUAL_KEY: {"idle": "res://assets/enemies/cave/spider.png", "hurt": "res://assets/enemies/cave/spider.png", "defeat": "res://assets/enemies/cave/spider.png"},
	CAVE_GOBLIN_VISUAL_KEY: {"idle": "res://assets/enemies/cave/goblin.png", "hurt": "res://assets/enemies/cave/goblin.png", "defeat": "res://assets/enemies/cave/goblin.png"},
	CAVE_TROGLODYTE_VISUAL_KEY: {"idle": "res://assets/enemies/cave/troglodyte.png", "hurt": "res://assets/enemies/cave/troglodyte.png", "defeat": "res://assets/enemies/cave/troglodyte.png"},
	CAVE_OGRE_VISUAL_KEY: {"idle": "res://assets/enemies/cave/Ogre.png", "hurt": "res://assets/enemies/cave/Ogre.png", "defeat": "res://assets/enemies/cave/Ogre.png"},
	CAVE_TROLL_VISUAL_KEY: {"idle": "res://assets/enemies/cave/Troll.png", "hurt": "res://assets/enemies/cave/Troll.png", "defeat": "res://assets/enemies/cave/Troll.png"},
	CAVE_GIANT_CENTIPEDE_VISUAL_KEY: {"idle": "res://assets/enemies/cave/Giant_Centipede.png", "hurt": "res://assets/enemies/cave/Giant_Centipede.png", "defeat": "res://assets/enemies/cave/Giant_Centipede.png"},
	CAVE_BASILISK_VISUAL_KEY: {"idle": "res://assets/enemies/cave/Basilisk.png", "hurt": "res://assets/enemies/cave/Basilisk.png", "defeat": "res://assets/enemies/cave/Basilisk.png"},
	CAVE_BRUTE_VISUAL_KEY: {"idle": "res://assets/enemies/cave/cave_brute.png", "hurt": "res://assets/enemies/cave/cave_brute.png", "defeat": "res://assets/enemies/cave/cave_brute.png"},
	CAVE_ECHOING_SEER_VISUAL_KEY: {"idle": "res://assets/enemies/cave/echoing_seer.png", "hurt": "res://assets/enemies/cave/echoing_seer.png", "defeat": "res://assets/enemies/cave/echoing_seer.png"},
	CAVE_PURPLE_WYRM_VISUAL_KEY: {"idle": "res://assets/enemies/cave/Purple_cave_wyrm.png", "hurt": "res://assets/enemies/cave/Purple_cave_wyrm.png", "defeat": "res://assets/enemies/cave/Purple_cave_wyrm.png"},
	CAVE_GOBLIN_KING_VISUAL_KEY: {"idle": "res://assets/enemies/cave/Goblin_king.png", "hurt": "res://assets/enemies/cave/Goblin_king.png", "defeat": "res://assets/enemies/cave/Goblin_king.png"},
	CAVE_ANCIENT_BASILISK_VISUAL_KEY: {"idle": "res://assets/enemies/cave/Ancient_basilisk.png", "hurt": "res://assets/enemies/cave/Ancient_basilisk.png", "defeat": "res://assets/enemies/cave/Ancient_basilisk.png"},
	CAVE_DEEP_MAW_VISUAL_KEY: {"idle": "res://assets/enemies/cave/Deep_maw.png", "hurt": "res://assets/enemies/cave/Deep_maw.png", "defeat": "res://assets/enemies/cave/Deep_maw.png"},
	CAVE_GEMVEIN_TYRANT_VISUAL_KEY: {"idle": "res://assets/enemies/cave/Gemvein_tyrant.png", "hurt": "res://assets/enemies/cave/Gemvein_tyrant.png", "defeat": "res://assets/enemies/cave/Gemvein_tyrant.png"},
	GRAVEYARD_RESTLESS_SPIRIT_VISUAL_KEY: {"idle": "res://assets/enemies/graveyard/Restless_Spirit.png", "hurt": "res://assets/enemies/graveyard/Restless_Spirit.png", "defeat": "res://assets/enemies/graveyard/Restless_Spirit.png"},
	GRAVEYARD_GIANT_RAT_VISUAL_KEY: {"idle": "res://assets/enemies/graveyard/rat.png", "hurt": "res://assets/enemies/graveyard/rat.png", "defeat": "res://assets/enemies/graveyard/rat.png"},
	GRAVEYARD_WOLF_VISUAL_KEY: {"idle": "res://assets/enemies/graveyard/wolf.png", "hurt": "res://assets/enemies/graveyard/wolf.png", "defeat": "res://assets/enemies/graveyard/wolf.png"},
	GRAVEYARD_SKELETON_VISUAL_KEY: {"idle": "res://assets/enemies/graveyard/skeleton.png", "hurt": "res://assets/enemies/graveyard/skeleton.png", "defeat": "res://assets/enemies/graveyard/skeleton.png"},
	GRAVEYARD_ZOMBIE_VISUAL_KEY: {"idle": "res://assets/enemies/graveyard/zombie.png", "hurt": "res://assets/enemies/graveyard/zombie.png", "defeat": "res://assets/enemies/graveyard/zombie.png"},
	GRAVEYARD_FLESH_GOLEM_VISUAL_KEY: {"idle": "res://assets/enemies/graveyard/Flesh_Golem.png", "hurt": "res://assets/enemies/graveyard/Flesh_Golem.png", "defeat": "res://assets/enemies/graveyard/Flesh_Golem.png"},
	GRAVEYARD_GRAVE_ROBBER_VISUAL_KEY: {"idle": "res://assets/enemies/graveyard/grave_robber.png", "hurt": "res://assets/enemies/graveyard/grave_robber.png", "defeat": "res://assets/enemies/graveyard/grave_robber.png"},
	GRAVEYARD_WIGHT_VISUAL_KEY: {"idle": "res://assets/enemies/graveyard/wight.png", "hurt": "res://assets/enemies/graveyard/wight.png", "defeat": "res://assets/enemies/graveyard/wight.png"},
	GRAVEYARD_NECROMANCER_VISUAL_KEY: {"idle": "res://assets/enemies/graveyard/necromancer.png", "hurt": "res://assets/enemies/graveyard/necromancer.png", "defeat": "res://assets/enemies/graveyard/necromancer.png"},
	GRAVEYARD_MIRE_KNIGHT_VISUAL_KEY: {"idle": "res://assets/enemies/graveyard/Mire_Knight.png", "hurt": "res://assets/enemies/graveyard/Mire_Knight.png", "defeat": "res://assets/enemies/graveyard/Mire_Knight.png"},
	GRAVEYARD_BONE_COLOSSUS_VISUAL_KEY: {"idle": "res://assets/enemies/graveyard/Bone_colossus.png", "hurt": "res://assets/enemies/graveyard/Bone_colossus.png", "defeat": "res://assets/enemies/graveyard/Bone_colossus.png"},
	GRAVEYARD_LICH_VISUAL_KEY: {"idle": "res://assets/enemies/graveyard/Lich.png", "hurt": "res://assets/enemies/graveyard/Lich.png", "defeat": "res://assets/enemies/graveyard/Lich.png"},
	GRAVEYARD_HEADLESS_KNIGHT_VISUAL_KEY: {"idle": "res://assets/enemies/graveyard/Headless_Knight.png", "hurt": "res://assets/enemies/graveyard/Headless_Knight.png", "defeat": "res://assets/enemies/graveyard/Headless_Knight.png"},
	GRAVEYARD_BELL_TOWER_REVENANT_VISUAL_KEY: {"idle": "res://assets/enemies/graveyard/The_Bell-Tower_Revenant.png", "hurt": "res://assets/enemies/graveyard/The_Bell-Tower_Revenant.png", "defeat": "res://assets/enemies/graveyard/The_Bell-Tower_Revenant.png"},
	GRAVEYARD_KING_LEORIC_VISUAL_KEY: {"idle": "res://assets/enemies/graveyard/King_Leoric.png", "hurt": "res://assets/enemies/graveyard/King_Leoric.png", "defeat": "res://assets/enemies/graveyard/King_Leoric.png"},
	FOREST_SPIDER_VISUAL_KEY: {"idle": "res://assets/enemies/forest/spider.png", "hurt": "res://assets/enemies/forest/spider.png", "defeat": "res://assets/enemies/forest/spider.png"},
	FOREST_GOBLIN_VISUAL_KEY: {"idle": "res://assets/enemies/forest/goblin.png", "hurt": "res://assets/enemies/forest/goblin.png", "defeat": "res://assets/enemies/forest/goblin.png"},
	FOREST_WISP_VISUAL_KEY: {"idle": "res://assets/enemies/forest/wisp.png", "hurt": "res://assets/enemies/forest/wisp.png", "defeat": "res://assets/enemies/forest/wisp.png"},
	FOREST_TREANT_SAPLING_VISUAL_KEY: {"idle": "res://assets/enemies/forest/sapling.png", "hurt": "res://assets/enemies/forest/sapling.png", "defeat": "res://assets/enemies/forest/sapling.png"},
	FOREST_DIRE_WOLF_VISUAL_KEY: {"idle": "res://assets/enemies/forest/wolf.png", "hurt": "res://assets/enemies/forest/wolf.png", "defeat": "res://assets/enemies/forest/wolf.png"},
	FOREST_WEREWOLF_VISUAL_KEY: {"idle": "res://assets/enemies/forest/Warewolf.png", "hurt": "res://assets/enemies/forest/Warewolf.png", "defeat": "res://assets/enemies/forest/Warewolf.png"},
	FOREST_TREANT_VISUAL_KEY: {"idle": "res://assets/enemies/forest/treant.png", "hurt": "res://assets/enemies/forest/treant.png", "defeat": "res://assets/enemies/forest/treant.png"},
	FOREST_ANCIENT_TREANT_VISUAL_KEY: {"idle": "res://assets/enemies/forest/Ancient_Treant.png", "hurt": "res://assets/enemies/forest/Ancient_Treant.png", "defeat": "res://assets/enemies/forest/Ancient_Treant.png"},
	FOREST_GREEN_HAG_VISUAL_KEY: {"idle": "res://assets/enemies/forest/Green_Hag.png", "hurt": "res://assets/enemies/forest/Green_Hag.png", "defeat": "res://assets/enemies/forest/Green_Hag.png"},
	FOREST_NIGHT_STALKER_VISUAL_KEY: {"idle": "res://assets/enemies/forest/night_stalker.png", "hurt": "res://assets/enemies/forest/night_stalker.png", "defeat": "res://assets/enemies/forest/night_stalker.png"},
	FOREST_HOLLOW_EYED_WITCH_VISUAL_KEY: {"idle": "res://assets/enemies/forest/Hallow_Eyed__Witch.png", "hurt": "res://assets/enemies/forest/Hallow_Eyed__Witch.png", "defeat": "res://assets/enemies/forest/Hallow_Eyed__Witch.png"},
	FOREST_ROOT_CROWNED_WIDOW_VISUAL_KEY: {"idle": "res://assets/enemies/forest/Root_Crowned_Widow.png", "hurt": "res://assets/enemies/forest/Root_Crowned_Widow.png", "defeat": "res://assets/enemies/forest/Root_Crowned_Widow.png"},
	FOREST_MOONLESS_HUNTMASTER_VISUAL_KEY: {"idle": "res://assets/enemies/forest/Moonless_Huntmaster.png", "hurt": "res://assets/enemies/forest/Moonless_Huntmaster.png", "defeat": "res://assets/enemies/forest/Moonless_Huntmaster.png"},
	FOREST_GREAT_WAREBEAR_VISUAL_KEY: {"idle": "res://assets/enemies/forest/Great_Warebear.png", "hurt": "res://assets/enemies/forest/Great_Warebear.png", "defeat": "res://assets/enemies/forest/Great_Warebear.png"},
	KEEP_RAT_VISUAL_KEY: {"idle": "res://assets/enemies/keep/rat.png", "hurt": "res://assets/enemies/keep/rat.png", "defeat": "res://assets/enemies/keep/rat.png"},
	KEEP_UNDEAD_GUARD_VISUAL_KEY: {"idle": "res://assets/enemies/keep/undead_guard.png", "hurt": "res://assets/enemies/keep/undead_guard.png", "defeat": "res://assets/enemies/keep/undead_guard.png"},
	KEEP_BANDIT_VISUAL_KEY: {"idle": "res://assets/enemies/keep/bandit.png", "hurt": "res://assets/enemies/keep/bandit.png", "defeat": "res://assets/enemies/keep/bandit.png"},
	KEEP_CULTIST_VISUAL_KEY: {"idle": "res://assets/enemies/keep/cultist.png", "hurt": "res://assets/enemies/keep/cultist.png", "defeat": "res://assets/enemies/keep/cultist.png"},
	KEEP_ANIMATED_ARMOR_VISUAL_KEY: {"idle": "res://assets/enemies/keep/animated_armor.png", "hurt": "res://assets/enemies/keep/animated_armor.png", "defeat": "res://assets/enemies/keep/animated_armor.png"},
	KEEP_GARGOYLE_VISUAL_KEY: {"idle": "res://assets/enemies/keep/Gargoyle.png", "hurt": "res://assets/enemies/keep/Gargoyle.png", "defeat": "res://assets/enemies/keep/Gargoyle.png"},
	KEEP_WARLOCK_VISUAL_KEY: {"idle": "res://assets/enemies/keep/warlock.png", "hurt": "res://assets/enemies/keep/warlock.png", "defeat": "res://assets/enemies/keep/warlock.png"},
	KEEP_DARK_KNIGHT_VISUAL_KEY: {"idle": "res://assets/enemies/keep/Dark_Knight.png", "hurt": "res://assets/enemies/keep/Dark_Knight.png", "defeat": "res://assets/enemies/keep/Dark_Knight.png"},
	KEEP_OATHBREAKER_CAPTAIN_VISUAL_KEY: {"idle": "res://assets/enemies/keep/Oathbreaker_Captain.png", "hurt": "res://assets/enemies/keep/Oathbreaker_Captain.png", "defeat": "res://assets/enemies/keep/Oathbreaker_Captain.png"},
	KEEP_ARCANE_GOLEM_VISUAL_KEY: {"idle": "res://assets/enemies/keep/Arcane_Golem.png", "hurt": "res://assets/enemies/keep/Arcane_Golem.png", "defeat": "res://assets/enemies/keep/Arcane_Golem.png"},
	KEEP_FALLEN_KING_VISUAL_KEY: {"idle": "res://assets/enemies/keep/Fallen_King.png", "hurt": "res://assets/enemies/keep/Fallen_King.png", "defeat": "res://assets/enemies/keep/Fallen_King.png"},
	KEEP_BEJEWELED_IRON_GOLEM_VISUAL_KEY: {"idle": "res://assets/enemies/keep/Bejeweled_Iron_Golem.png", "hurt": "res://assets/enemies/keep/Bejeweled_Iron_Golem.png", "defeat": "res://assets/enemies/keep/Bejeweled_Iron_Golem.png"},
	KEEP_HALF_BLOOD_PRINCE_VISUAL_KEY: {"idle": "res://assets/enemies/keep/Half_Blood_Prince.png", "hurt": "res://assets/enemies/keep/Half_Blood_Prince.png", "defeat": "res://assets/enemies/keep/Half_Blood_Prince.png"},
	KEEP_LAST_CASTELLAN_VISUAL_KEY: {"idle": "res://assets/enemies/keep/Last_Castellan.png", "hurt": "res://assets/enemies/keep/Last_Castellan.png", "defeat": "res://assets/enemies/keep/Last_Castellan.png"},
	KEEP_FAITHLESS_EXECUTIONER_VISUAL_KEY: {"idle": "res://assets/enemies/keep/Faithless_Executioner.png", "hurt": "res://assets/enemies/keep/Faithless_Executioner.png", "defeat": "res://assets/enemies/keep/Faithless_Executioner.png"},
	RUINS_CULTIST_VISUAL_KEY: {"idle": "res://assets/enemies/ruins/cultist.png", "hurt": "res://assets/enemies/ruins/cultist.png", "defeat": "res://assets/enemies/ruins/cultist.png"},
	RUINS_ANIMATED_STATUE_VISUAL_KEY: {"idle": "res://assets/enemies/ruins/Animated_Statue.png", "hurt": "res://assets/enemies/ruins/Animated_Statue.png", "defeat": "res://assets/enemies/ruins/Animated_Statue.png"},
	RUINS_SCARAB_VISUAL_KEY: {"idle": "res://assets/enemies/ruins/scrarab.png", "hurt": "res://assets/enemies/ruins/scrarab.png", "defeat": "res://assets/enemies/ruins/scrarab.png"},
	RUINS_WISP_VISUAL_KEY: {"idle": "res://assets/enemies/ruins/wisp.png", "hurt": "res://assets/enemies/ruins/wisp.png", "defeat": "res://assets/enemies/ruins/wisp.png"},
	RUINS_MINOTAUR_VISUAL_KEY: {"idle": "res://assets/enemies/ruins/Minotaur.png", "hurt": "res://assets/enemies/ruins/Minotaur.png", "defeat": "res://assets/enemies/ruins/Minotaur.png"},
	RUINS_GUARDIAN_CONSTRUCT_VISUAL_KEY: {"idle": "res://assets/enemies/ruins/Guardian_Construct.png", "hurt": "res://assets/enemies/ruins/Guardian_Construct.png", "defeat": "res://assets/enemies/ruins/Guardian_Construct.png"},
	RUINS_ARCANE_GOLEM_VISUAL_KEY: {"idle": "res://assets/enemies/ruins/Arcane_Golem.png", "hurt": "res://assets/enemies/ruins/Arcane_Golem.png", "defeat": "res://assets/enemies/ruins/Arcane_Golem.png"},
	RUINS_RUNEMARK_SENTINEL_VISUAL_KEY: {"idle": "res://assets/enemies/ruins/Runemark_sentinal.png", "hurt": "res://assets/enemies/ruins/Runemark_sentinal.png", "defeat": "res://assets/enemies/ruins/Runemark_sentinal.png"},
	RUINS_SCARAB_QUEEN_VISUAL_KEY: {"idle": "res://assets/enemies/ruins/Scarab_Queen.png", "hurt": "res://assets/enemies/ruins/Scarab_Queen.png", "defeat": "res://assets/enemies/ruins/Scarab_Queen.png"},
	RUINS_ANCIENT_GUARDIAN_VISUAL_KEY: {"idle": "res://assets/enemies/ruins/Ancient_Guardian.png", "hurt": "res://assets/enemies/ruins/Ancient_Guardian.png", "defeat": "res://assets/enemies/ruins/Ancient_Guardian.png"},
	RUINS_SPHINX_VISUAL_KEY: {"idle": "res://assets/enemies/ruins/Sphinx.png", "hurt": "res://assets/enemies/ruins/Sphinx.png", "defeat": "res://assets/enemies/ruins/Sphinx.png"},
	RUINS_RUNIC_COLOSSUS_VISUAL_KEY: {"idle": "res://assets/enemies/ruins/Runic_Collosus.png", "hurt": "res://assets/enemies/ruins/Runic_Collosus.png", "defeat": "res://assets/enemies/ruins/Runic_Collosus.png"},
	RUINS_FIRST_IDOL_VISUAL_KEY: {"idle": "res://assets/enemies/ruins/First_idol.png", "hurt": "res://assets/enemies/ruins/First_idol.png", "defeat": "res://assets/enemies/ruins/First_idol.png"},
	RUINS_ANCIENT_ARCHIVIST_VISUAL_KEY: {"idle": "res://assets/enemies/ruins/Ancient_Archivist.png", "hurt": "res://assets/enemies/ruins/Ancient_Archivist.png", "defeat": "res://assets/enemies/ruins/Ancient_Archivist.png"},
}
const STATIC_ENEMY_VISUAL_KEYS := [
	SWAMP_GREEN_SLIME_VISUAL_KEY,
	SWAMP_GOBLIN_VISUAL_KEY,
	SWAMP_BOG_RAT_VISUAL_KEY,
	SWAMP_GIANT_LEECH_VISUAL_KEY,
	SWAMP_POISON_FROG_VISUAL_KEY,
	SWAMP_TROLL_VISUAL_KEY,
	SWAMP_BOG_WITCH_VISUAL_KEY,
	SWAMP_HYDRA_SPAWN_VISUAL_KEY,
	SWAMP_MIRE_KNIGHT_VISUAL_KEY,
	SWAMP_GREEN_HAG_VISUAL_KEY,
	SWAMP_HYDRA_VISUAL_KEY,
	SWAMP_ANCIENT_TROLL_VISUAL_KEY,
	SWAMP_SLIME_QUEEN_VISUAL_KEY,
	SWAMP_DROWNED_MATRIARCH_VISUAL_KEY,
	SWAMP_BOGHEART_COLOSSUS_VISUAL_KEY,
	CAVE_VAMPIRE_BAT_VISUAL_KEY,
	CAVE_WOLF_SPIDER_VISUAL_KEY,
	CAVE_GOBLIN_VISUAL_KEY,
	CAVE_TROGLODYTE_VISUAL_KEY,
	CAVE_OGRE_VISUAL_KEY,
	CAVE_TROLL_VISUAL_KEY,
	CAVE_GIANT_CENTIPEDE_VISUAL_KEY,
	CAVE_BASILISK_VISUAL_KEY,
	CAVE_BRUTE_VISUAL_KEY,
	CAVE_ECHOING_SEER_VISUAL_KEY,
	CAVE_PURPLE_WYRM_VISUAL_KEY,
	CAVE_GOBLIN_KING_VISUAL_KEY,
	CAVE_ANCIENT_BASILISK_VISUAL_KEY,
	CAVE_DEEP_MAW_VISUAL_KEY,
	CAVE_GEMVEIN_TYRANT_VISUAL_KEY,
	GRAVEYARD_RESTLESS_SPIRIT_VISUAL_KEY,
	GRAVEYARD_GIANT_RAT_VISUAL_KEY,
	GRAVEYARD_WOLF_VISUAL_KEY,
	GRAVEYARD_SKELETON_VISUAL_KEY,
	GRAVEYARD_ZOMBIE_VISUAL_KEY,
	GRAVEYARD_FLESH_GOLEM_VISUAL_KEY,
	GRAVEYARD_GRAVE_ROBBER_VISUAL_KEY,
	GRAVEYARD_WIGHT_VISUAL_KEY,
	GRAVEYARD_NECROMANCER_VISUAL_KEY,
	GRAVEYARD_MIRE_KNIGHT_VISUAL_KEY,
	GRAVEYARD_BONE_COLOSSUS_VISUAL_KEY,
	GRAVEYARD_LICH_VISUAL_KEY,
	GRAVEYARD_HEADLESS_KNIGHT_VISUAL_KEY,
	GRAVEYARD_BELL_TOWER_REVENANT_VISUAL_KEY,
	GRAVEYARD_KING_LEORIC_VISUAL_KEY,
	FOREST_SPIDER_VISUAL_KEY,
	FOREST_GOBLIN_VISUAL_KEY,
	FOREST_WISP_VISUAL_KEY,
	FOREST_TREANT_SAPLING_VISUAL_KEY,
	FOREST_DIRE_WOLF_VISUAL_KEY,
	FOREST_WEREWOLF_VISUAL_KEY,
	FOREST_TREANT_VISUAL_KEY,
	FOREST_ANCIENT_TREANT_VISUAL_KEY,
	FOREST_GREEN_HAG_VISUAL_KEY,
	FOREST_NIGHT_STALKER_VISUAL_KEY,
	FOREST_HOLLOW_EYED_WITCH_VISUAL_KEY,
	FOREST_ROOT_CROWNED_WIDOW_VISUAL_KEY,
	FOREST_MOONLESS_HUNTMASTER_VISUAL_KEY,
	FOREST_GREAT_WAREBEAR_VISUAL_KEY,
	KEEP_RAT_VISUAL_KEY,
	KEEP_UNDEAD_GUARD_VISUAL_KEY,
	KEEP_BANDIT_VISUAL_KEY,
	KEEP_CULTIST_VISUAL_KEY,
	KEEP_ANIMATED_ARMOR_VISUAL_KEY,
	KEEP_GARGOYLE_VISUAL_KEY,
	KEEP_WARLOCK_VISUAL_KEY,
	KEEP_DARK_KNIGHT_VISUAL_KEY,
	KEEP_OATHBREAKER_CAPTAIN_VISUAL_KEY,
	KEEP_ARCANE_GOLEM_VISUAL_KEY,
	KEEP_FALLEN_KING_VISUAL_KEY,
	KEEP_BEJEWELED_IRON_GOLEM_VISUAL_KEY,
	KEEP_HALF_BLOOD_PRINCE_VISUAL_KEY,
	KEEP_LAST_CASTELLAN_VISUAL_KEY,
	KEEP_FAITHLESS_EXECUTIONER_VISUAL_KEY,
	RUINS_CULTIST_VISUAL_KEY,
	RUINS_ANIMATED_STATUE_VISUAL_KEY,
	RUINS_SCARAB_VISUAL_KEY,
	RUINS_WISP_VISUAL_KEY,
	RUINS_MINOTAUR_VISUAL_KEY,
	RUINS_GUARDIAN_CONSTRUCT_VISUAL_KEY,
	RUINS_ARCANE_GOLEM_VISUAL_KEY,
	RUINS_RUNEMARK_SENTINEL_VISUAL_KEY,
	RUINS_SCARAB_QUEEN_VISUAL_KEY,
	RUINS_ANCIENT_GUARDIAN_VISUAL_KEY,
	RUINS_SPHINX_VISUAL_KEY,
	RUINS_RUNIC_COLOSSUS_VISUAL_KEY,
	RUINS_FIRST_IDOL_VISUAL_KEY,
	RUINS_ANCIENT_ARCHIVIST_VISUAL_KEY,
]
const STATIC_ENEMY_FLIP_H_BY_VISUAL_KEY := {
	SWAMP_GREEN_SLIME_VISUAL_KEY: true,
	SWAMP_GOBLIN_VISUAL_KEY: false,
	SWAMP_BOG_RAT_VISUAL_KEY: false,
	SWAMP_GIANT_LEECH_VISUAL_KEY: true,
	SWAMP_POISON_FROG_VISUAL_KEY: false,
	SWAMP_TROLL_VISUAL_KEY: true,
	SWAMP_BOG_WITCH_VISUAL_KEY: false,
	SWAMP_HYDRA_SPAWN_VISUAL_KEY: true,
	SWAMP_MIRE_KNIGHT_VISUAL_KEY: false,
	SWAMP_GREEN_HAG_VISUAL_KEY: true,
	SWAMP_HYDRA_VISUAL_KEY: true,
	SWAMP_ANCIENT_TROLL_VISUAL_KEY: true,
	SWAMP_SLIME_QUEEN_VISUAL_KEY: true,
	SWAMP_DROWNED_MATRIARCH_VISUAL_KEY: false,
	SWAMP_BOGHEART_COLOSSUS_VISUAL_KEY: true,
	CAVE_VAMPIRE_BAT_VISUAL_KEY: false,
	CAVE_WOLF_SPIDER_VISUAL_KEY: false,
	CAVE_GOBLIN_VISUAL_KEY: false,
	CAVE_TROGLODYTE_VISUAL_KEY: false,
	CAVE_OGRE_VISUAL_KEY: true,
	CAVE_TROLL_VISUAL_KEY: true,
	CAVE_GIANT_CENTIPEDE_VISUAL_KEY: false,
	CAVE_BASILISK_VISUAL_KEY: false,
	CAVE_BRUTE_VISUAL_KEY: false,
	CAVE_ECHOING_SEER_VISUAL_KEY: false,
	CAVE_PURPLE_WYRM_VISUAL_KEY: true,
	CAVE_GOBLIN_KING_VISUAL_KEY: true,
	CAVE_ANCIENT_BASILISK_VISUAL_KEY: false,
	CAVE_DEEP_MAW_VISUAL_KEY: false,
	CAVE_GEMVEIN_TYRANT_VISUAL_KEY: false,
	GRAVEYARD_WOLF_VISUAL_KEY: true,
	GRAVEYARD_SKELETON_VISUAL_KEY: true,
	GRAVEYARD_WIGHT_VISUAL_KEY: true,
	GRAVEYARD_NECROMANCER_VISUAL_KEY: true,
	GRAVEYARD_MIRE_KNIGHT_VISUAL_KEY: true,
	GRAVEYARD_HEADLESS_KNIGHT_VISUAL_KEY: true,
	GRAVEYARD_BELL_TOWER_REVENANT_VISUAL_KEY: true,
	GRAVEYARD_KING_LEORIC_VISUAL_KEY: true,
	FOREST_WISP_VISUAL_KEY: true,
	FOREST_TREANT_SAPLING_VISUAL_KEY: true,
	FOREST_WEREWOLF_VISUAL_KEY: true,
	FOREST_TREANT_VISUAL_KEY: true,
	FOREST_ANCIENT_TREANT_VISUAL_KEY: true,
	FOREST_GREEN_HAG_VISUAL_KEY: true,
	FOREST_NIGHT_STALKER_VISUAL_KEY: true,
	FOREST_GREAT_WAREBEAR_VISUAL_KEY: true,
	KEEP_BANDIT_VISUAL_KEY: true,
	KEEP_CULTIST_VISUAL_KEY: true,
	KEEP_ANIMATED_ARMOR_VISUAL_KEY: true,
	KEEP_GARGOYLE_VISUAL_KEY: true,
	KEEP_DARK_KNIGHT_VISUAL_KEY: true,
	KEEP_OATHBREAKER_CAPTAIN_VISUAL_KEY: true,
	KEEP_FALLEN_KING_VISUAL_KEY: true,
	KEEP_BEJEWELED_IRON_GOLEM_VISUAL_KEY: true,
	KEEP_HALF_BLOOD_PRINCE_VISUAL_KEY: true,
	KEEP_LAST_CASTELLAN_VISUAL_KEY: true,
	KEEP_FAITHLESS_EXECUTIONER_VISUAL_KEY: true,
	RUINS_CULTIST_VISUAL_KEY: true,
	RUINS_ANIMATED_STATUE_VISUAL_KEY: true,
	RUINS_WISP_VISUAL_KEY: true,
	RUINS_MINOTAUR_VISUAL_KEY: true,
	RUINS_GUARDIAN_CONSTRUCT_VISUAL_KEY: true,
}
const ENEMY_ANIMATION_REGIONS := {
	PRACTICE_DUMMY_VISUAL_KEY: {
		"idle": Rect2(Vector2(0, 0), Vector2(32, 32)),
		"hurt": Rect2(Vector2(0, 0), Vector2(32, 32)),
		"defeat": Rect2(Vector2(0, 0), Vector2(32, 32)),
	},
	MOUTHY_DRUNK_VISUAL_KEY: {
		"idle": Rect2(Vector2(0, 0), Vector2(32, 32)),
		"hurt": Rect2(Vector2(0, 64), Vector2(32, 32)),
		"defeat": Rect2(Vector2(0, 96), Vector2(32, 32)),
	},
	DRUNK_BUDDY_VISUAL_KEY: {
		"idle": Rect2(Vector2(0, 256), Vector2(32, 32)),
		"hurt": Rect2(Vector2(0, 320), Vector2(32, 32)),
		"defeat": Rect2(Vector2(0, 352), Vector2(32, 32)),
	},
	TAVERN_BOUNCER_VISUAL_KEY: {
		"idle": Rect2(Vector2(0, 320), Vector2(32, 32)),
		"hurt": Rect2(Vector2(0, 384), Vector2(32, 32)),
		"defeat": Rect2(Vector2(0, 448), Vector2(32, 32)),
	},
	HIRED_GOON_VISUAL_KEY: {
		"idle": Rect2(Vector2(0, 320), Vector2(32, 32)),
		"hurt": Rect2(Vector2(0, 384), Vector2(32, 32)),
		"defeat": Rect2(Vector2(0, 448), Vector2(32, 32)),
	},
	VYRA_VISUAL_KEY: {
		"idle": Rect2(Vector2(0, 320), Vector2(32, 32)),
		"hurt": Rect2(Vector2(0, 384), Vector2(32, 32)),
		"defeat": Rect2(Vector2(0, 448), Vector2(32, 32)),
	},
	KNIVES_VISUAL_KEY: {
		"idle": Rect2(Vector2(0, 0), Vector2(32, 32)),
		"hurt": Rect2(Vector2(0, 160), Vector2(32, 32)),
		"defeat": Rect2(Vector2(0, 224), Vector2(32, 32)),
	},
}
const ENEMY_VISUAL_KEYS_BY_NAME := {
	"Mouthy Drunk": MOUTHY_DRUNK_VISUAL_KEY,
	"Drunk Buddy": DRUNK_BUDDY_VISUAL_KEY,
	"Tavern Bouncer": TAVERN_BOUNCER_VISUAL_KEY,
	"Hired Goon": HIRED_GOON_VISUAL_KEY,
	"Door Guard": HIRED_GOON_VISUAL_KEY,
	"Cloaked Watchmen": HIRED_GOON_VISUAL_KEY,
	"Armored Guard": HIRED_GOON_VISUAL_KEY,
	"Sleeping Henchman": HIRED_GOON_VISUAL_KEY,
	"Portly Cook": HIRED_GOON_VISUAL_KEY,
	"Patrolling Guard": HIRED_GOON_VISUAL_KEY,
	"Lazy Henchman": HIRED_GOON_VISUAL_KEY,
	"Venom-Resistant Slime": HIRED_GOON_VISUAL_KEY,
	"Training Dummy": HIRED_GOON_VISUAL_KEY,
	"Placeholder Dummy": HIRED_GOON_VISUAL_KEY,
	"Vyra": VYRA_VISUAL_KEY,
	"Knives": KNIVES_VISUAL_KEY,
	"Practice Target": PRACTICE_DUMMY_VISUAL_KEY,
	"Green Slime": SWAMP_GREEN_SLIME_VISUAL_KEY,
	"Swamp Goblin": SWAMP_GOBLIN_VISUAL_KEY,
	"Bog Rat": SWAMP_BOG_RAT_VISUAL_KEY,
	"Giant Leech": SWAMP_GIANT_LEECH_VISUAL_KEY,
	"Poison Frog": SWAMP_POISON_FROG_VISUAL_KEY,
	"Troll": SWAMP_TROLL_VISUAL_KEY,
	"Bog Witch": SWAMP_BOG_WITCH_VISUAL_KEY,
	"Swamp Troll": SWAMP_TROLL_VISUAL_KEY,
	"Hydra Spawn": SWAMP_HYDRA_SPAWN_VISUAL_KEY,
	"Mire Knight": SWAMP_MIRE_KNIGHT_VISUAL_KEY,
	"Green Hag": SWAMP_GREEN_HAG_VISUAL_KEY,
	"Swamp Hydra": SWAMP_HYDRA_VISUAL_KEY,
	"Ancient Troll": SWAMP_ANCIENT_TROLL_VISUAL_KEY,
	"Slime Queen": SWAMP_SLIME_QUEEN_VISUAL_KEY,
	"The Drowned Matriarch": SWAMP_DROWNED_MATRIARCH_VISUAL_KEY,
	"Drowned Matriarch": SWAMP_DROWNED_MATRIARCH_VISUAL_KEY,
	"Bogheart Colossus": SWAMP_BOGHEART_COLOSSUS_VISUAL_KEY,
	"Vampire Bat": CAVE_VAMPIRE_BAT_VISUAL_KEY,
	"Wolf Spider": CAVE_WOLF_SPIDER_VISUAL_KEY,
	"Goblin": CAVE_GOBLIN_VISUAL_KEY,
	"Troglodyte": CAVE_TROGLODYTE_VISUAL_KEY,
	"Ogre": CAVE_OGRE_VISUAL_KEY,
	"Cave Troll": CAVE_TROLL_VISUAL_KEY,
	"Giant Centipede": CAVE_GIANT_CENTIPEDE_VISUAL_KEY,
	"Basilisk": CAVE_BASILISK_VISUAL_KEY,
	"Cave Brute": CAVE_BRUTE_VISUAL_KEY,
	"Echoing Seer": CAVE_ECHOING_SEER_VISUAL_KEY,
	"Purple Cave Wyrm": CAVE_PURPLE_WYRM_VISUAL_KEY,
	"The Goblin King": CAVE_GOBLIN_KING_VISUAL_KEY,
	"Goblin King": CAVE_GOBLIN_KING_VISUAL_KEY,
	"Ancient Basilisk": CAVE_ANCIENT_BASILISK_VISUAL_KEY,
	"The Deep Maw": CAVE_DEEP_MAW_VISUAL_KEY,
	"Deep Maw": CAVE_DEEP_MAW_VISUAL_KEY,
	"Gemvein Tyrant": CAVE_GEMVEIN_TYRANT_VISUAL_KEY,
	"Restless Spirit": GRAVEYARD_RESTLESS_SPIRIT_VISUAL_KEY,
	"Giant Rat": GRAVEYARD_GIANT_RAT_VISUAL_KEY,
	"Wolf": GRAVEYARD_WOLF_VISUAL_KEY,
	"Skeleton": GRAVEYARD_SKELETON_VISUAL_KEY,
	"Zombie": GRAVEYARD_ZOMBIE_VISUAL_KEY,
	"Flesh Golem": GRAVEYARD_FLESH_GOLEM_VISUAL_KEY,
	"Golem": GRAVEYARD_FLESH_GOLEM_VISUAL_KEY,
	"Grave Robber": GRAVEYARD_GRAVE_ROBBER_VISUAL_KEY,
	"Wight": GRAVEYARD_WIGHT_VISUAL_KEY,
	"Necromancer": GRAVEYARD_NECROMANCER_VISUAL_KEY,
	"Graveyard Mire Knight": GRAVEYARD_MIRE_KNIGHT_VISUAL_KEY,
	"Bone Colossus": GRAVEYARD_BONE_COLOSSUS_VISUAL_KEY,
	"Lich": GRAVEYARD_LICH_VISUAL_KEY,
	"Headless Knight": GRAVEYARD_HEADLESS_KNIGHT_VISUAL_KEY,
	"The Bell-Tower Revenant": GRAVEYARD_BELL_TOWER_REVENANT_VISUAL_KEY,
	"Bell-Tower Revenant": GRAVEYARD_BELL_TOWER_REVENANT_VISUAL_KEY,
	"King Leoric": GRAVEYARD_KING_LEORIC_VISUAL_KEY,
	"Spider": FOREST_SPIDER_VISUAL_KEY,
	"Haunted Forest Spider": FOREST_SPIDER_VISUAL_KEY,
	"Haunted Forest Giant Spider": FOREST_SPIDER_VISUAL_KEY,
	"Forest Goblin": FOREST_GOBLIN_VISUAL_KEY,
	"Haunted Forest Forest Goblin": FOREST_GOBLIN_VISUAL_KEY,
	"Haunted Forest Veteran Forest Goblin": FOREST_GOBLIN_VISUAL_KEY,
	"Haunted Forest Wisp": FOREST_WISP_VISUAL_KEY,
	"Haunted Forest Ancient Wisp": FOREST_WISP_VISUAL_KEY,
	"Treant Sapling": FOREST_TREANT_SAPLING_VISUAL_KEY,
	"Haunted Forest Treant Sapling": FOREST_TREANT_SAPLING_VISUAL_KEY,
	"Haunted Forest Ancient Treant Sapling": FOREST_TREANT_SAPLING_VISUAL_KEY,
	"Dire Wolf": FOREST_DIRE_WOLF_VISUAL_KEY,
	"Haunted Forest Dire Wolf": FOREST_DIRE_WOLF_VISUAL_KEY,
	"Haunted Forest Alpha Dire Wolf": FOREST_DIRE_WOLF_VISUAL_KEY,
	"Werewolf": FOREST_WEREWOLF_VISUAL_KEY,
	"Haunted Forest Werewolf": FOREST_WEREWOLF_VISUAL_KEY,
	"Treant": FOREST_TREANT_VISUAL_KEY,
	"Ancient Treant": FOREST_ANCIENT_TREANT_VISUAL_KEY,
	"Haunted Forest Treant": FOREST_TREANT_VISUAL_KEY,
	"Haunted Forest Ancient Treant": FOREST_ANCIENT_TREANT_VISUAL_KEY,
	"Haunted Forest Green Hag": FOREST_GREEN_HAG_VISUAL_KEY,
	"Night Stalker": FOREST_NIGHT_STALKER_VISUAL_KEY,
	"Haunted Forest Night Stalker": FOREST_NIGHT_STALKER_VISUAL_KEY,
	"Hollow-Eyed Witch": FOREST_HOLLOW_EYED_WITCH_VISUAL_KEY,
	"Forest Witch": FOREST_HOLLOW_EYED_WITCH_VISUAL_KEY,
	"Haunted Forest Hollow-Eyed Witch": FOREST_HOLLOW_EYED_WITCH_VISUAL_KEY,
	"Haunted Forest Forest Witch": FOREST_HOLLOW_EYED_WITCH_VISUAL_KEY,
	"The Root-Crowned Widow": FOREST_ROOT_CROWNED_WIDOW_VISUAL_KEY,
	"Root-Crowned Widow": FOREST_ROOT_CROWNED_WIDOW_VISUAL_KEY,
	"Haunted Forest The Root-Crowned Widow": FOREST_ROOT_CROWNED_WIDOW_VISUAL_KEY,
	"Haunted Forest Root-Crowned Widow": FOREST_ROOT_CROWNED_WIDOW_VISUAL_KEY,
	"Moonless Huntmaster": FOREST_MOONLESS_HUNTMASTER_VISUAL_KEY,
	"Haunted Forest Moonless Huntmaster": FOREST_MOONLESS_HUNTMASTER_VISUAL_KEY,
	"Great Warebear": FOREST_GREAT_WAREBEAR_VISUAL_KEY,
	"Haunted Forest Great Warebear": FOREST_GREAT_WAREBEAR_VISUAL_KEY,
	"Rat": KEEP_RAT_VISUAL_KEY,
	"Ruined Keep Rat": KEEP_RAT_VISUAL_KEY,
	"Ruined Keep Giant Rat": KEEP_RAT_VISUAL_KEY,
	"Undead Guard": KEEP_UNDEAD_GUARD_VISUAL_KEY,
	"Ruined Keep Undead Guard": KEEP_UNDEAD_GUARD_VISUAL_KEY,
	"Ruined Keep Ancient Undead Guard": KEEP_UNDEAD_GUARD_VISUAL_KEY,
	"Bandit": KEEP_BANDIT_VISUAL_KEY,
	"Ruined Keep Bandit": KEEP_BANDIT_VISUAL_KEY,
	"Ruined Keep Veteran Bandit": KEEP_BANDIT_VISUAL_KEY,
	"Cultist": KEEP_CULTIST_VISUAL_KEY,
	"Ruined Keep Cultist": KEEP_CULTIST_VISUAL_KEY,
	"Ruined Keep Veteran Cultist": KEEP_CULTIST_VISUAL_KEY,
	"Animated Armor": KEEP_ANIMATED_ARMOR_VISUAL_KEY,
	"Ruined Keep Animated Armor": KEEP_ANIMATED_ARMOR_VISUAL_KEY,
	"Ruined Keep Ancient Animated Armor": KEEP_ANIMATED_ARMOR_VISUAL_KEY,
	"Gargoyle": KEEP_GARGOYLE_VISUAL_KEY,
	"Ruined Keep Gargoyle": KEEP_GARGOYLE_VISUAL_KEY,
	"Warlock": KEEP_WARLOCK_VISUAL_KEY,
	"Ruined Keep Warlock": KEEP_WARLOCK_VISUAL_KEY,
	"Dark Knight": KEEP_DARK_KNIGHT_VISUAL_KEY,
	"Ruined Keep Dark Knight": KEEP_DARK_KNIGHT_VISUAL_KEY,
	"Oathbreaker Captain": KEEP_OATHBREAKER_CAPTAIN_VISUAL_KEY,
	"Ruined Keep Oathbreaker Captain": KEEP_OATHBREAKER_CAPTAIN_VISUAL_KEY,
	"Arcane Golem": KEEP_ARCANE_GOLEM_VISUAL_KEY,
	"Ruined Keep Arcane Golem": KEEP_ARCANE_GOLEM_VISUAL_KEY,
	"Fallen King": KEEP_FALLEN_KING_VISUAL_KEY,
	"Ruined Keep Fallen King": KEEP_FALLEN_KING_VISUAL_KEY,
	"Bejeweled Iron Golem": KEEP_BEJEWELED_IRON_GOLEM_VISUAL_KEY,
	"Ruined Keep Bejeweled Iron Golem": KEEP_BEJEWELED_IRON_GOLEM_VISUAL_KEY,
	"The Half-blood Prince": KEEP_HALF_BLOOD_PRINCE_VISUAL_KEY,
	"Ruined Keep The Half-blood Prince": KEEP_HALF_BLOOD_PRINCE_VISUAL_KEY,
	"The Last Castellan": KEEP_LAST_CASTELLAN_VISUAL_KEY,
	"Ruined Keep The Last Castellan": KEEP_LAST_CASTELLAN_VISUAL_KEY,
	"Faithless Executioner": KEEP_FAITHLESS_EXECUTIONER_VISUAL_KEY,
	"Ruined Keep Faithless Executioner": KEEP_FAITHLESS_EXECUTIONER_VISUAL_KEY,
	"Ancient Ruins Cultist": RUINS_CULTIST_VISUAL_KEY,
	"Ancient Ruins Veteran Cultist": RUINS_CULTIST_VISUAL_KEY,
	"Animated Statue": RUINS_ANIMATED_STATUE_VISUAL_KEY,
	"Ancient Ruins Animated Statue": RUINS_ANIMATED_STATUE_VISUAL_KEY,
	"Ancient Ruins Ancient Animated Statue": RUINS_ANIMATED_STATUE_VISUAL_KEY,
	"Scarab": RUINS_SCARAB_VISUAL_KEY,
	"Ancient Ruins Scarab": RUINS_SCARAB_VISUAL_KEY,
	"Ancient Ruins Giant Scarab": RUINS_SCARAB_VISUAL_KEY,
	"Wisp": RUINS_WISP_VISUAL_KEY,
	"Ancient Ruins Wisp": RUINS_WISP_VISUAL_KEY,
	"Ancient Ruins Ancient Wisp": RUINS_WISP_VISUAL_KEY,
	"Minotaur": RUINS_MINOTAUR_VISUAL_KEY,
	"Ancient Ruins Minotaur": RUINS_MINOTAUR_VISUAL_KEY,
	"Guardian Construct": RUINS_GUARDIAN_CONSTRUCT_VISUAL_KEY,
	"Ancient Ruins Guardian Construct": RUINS_GUARDIAN_CONSTRUCT_VISUAL_KEY,
	"Ancient Ruins Arcane Golem": RUINS_ARCANE_GOLEM_VISUAL_KEY,
	"Runemark Sentinel": RUINS_RUNEMARK_SENTINEL_VISUAL_KEY,
	"Ancient Ruins Runemark Sentinel": RUINS_RUNEMARK_SENTINEL_VISUAL_KEY,
	"Scarab Queen": RUINS_SCARAB_QUEEN_VISUAL_KEY,
	"Ancient Ruins Scarab Queen": RUINS_SCARAB_QUEEN_VISUAL_KEY,
	"Ancient Guardian": RUINS_ANCIENT_GUARDIAN_VISUAL_KEY,
	"Ancient Ruins Ancient Guardian": RUINS_ANCIENT_GUARDIAN_VISUAL_KEY,
	"Sphinx": RUINS_SPHINX_VISUAL_KEY,
	"Ancient Ruins Sphinx": RUINS_SPHINX_VISUAL_KEY,
	"Runic Colossus": RUINS_RUNIC_COLOSSUS_VISUAL_KEY,
	"Ancient Ruins Runic Colossus": RUINS_RUNIC_COLOSSUS_VISUAL_KEY,
	"The First Idol": RUINS_FIRST_IDOL_VISUAL_KEY,
	"First Idol": RUINS_FIRST_IDOL_VISUAL_KEY,
	"Ancient Ruins The First Idol": RUINS_FIRST_IDOL_VISUAL_KEY,
	"Ancient Archivist": RUINS_ANCIENT_ARCHIVIST_VISUAL_KEY,
	"Ancient Ruins Ancient Archivist": RUINS_ANCIENT_ARCHIVIST_VISUAL_KEY,
}
const ENEMY_PRESENTATION_VISUAL_ALIASES := {
	"Giant Green Slime": "Green Slime",
	"Veteran Swamp Goblin": "Swamp Goblin",
	"Giant Bog Rat": "Bog Rat",
	"Elder Leech": "Giant Leech",
	"Giant Poison Frog": "Poison Frog",
	"Giant Vampire Bat": "Vampire Bat",
	"Giant Wolf Spider": "Wolf Spider",
	"Veteran Goblin": "Goblin",
	"Veteran Troglodyte": "Troglodyte",
	"Veteran Ogre": "Ogre",
	"Ancient Restless Spirit": "Restless Spirit",
	"Dire Rat": "Giant Rat",
	"Giant Wolf": "Wolf",
	"Ancient Skeleton": "Skeleton",
	"Ancient Zombie": "Zombie",
	"Giant Spider": "Spider",
	"Veteran Forest Goblin": "Forest Goblin",
	"Ancient Wisp": "Wisp",
	"Ancient Treant Sapling": "Treant Sapling",
	"Alpha Dire Wolf": "Dire Wolf",
	"Giant Rat": "Rat",
	"Ancient Undead Guard": "Undead Guard",
	"Veteran Bandit": "Bandit",
	"Veteran Cultist": "Cultist",
	"Ancient Animated Armor": "Animated Armor",
	"Ancient Animated Statue": "Animated Statue",
	"Giant Scarab": "Scarab",
}
const PRACTICE_DUMMY_REACTION_FRAME_PATHS := [
	[
		"res://assets/characters/practice_dummy/dummy_bounce/frames/frame_001.png",
		"res://assets/characters/practice_dummy/dummy_bounce/frames/frame_002.png",
		"res://assets/characters/practice_dummy/dummy_bounce/frames/frame_003.png",
		"res://assets/characters/practice_dummy/dummy_bounce/frames/frame_004.png",
	],
	[
		"res://assets/characters/practice_dummy/dummy_knock/frames/frame_009.png",
		"res://assets/characters/practice_dummy/dummy_knock/frames/frame_010.png",
		"res://assets/characters/practice_dummy/dummy_knock/frames/frame_012.png",
		"res://assets/characters/practice_dummy/dummy_knock/frames/frame_013.png",
	],
	[
		"res://assets/characters/practice_dummy/dummy_spin/frames/frame_017.png",
		"res://assets/characters/practice_dummy/dummy_spin/frames/frame_018.png",
		"res://assets/characters/practice_dummy/dummy_spin/frames/frame_019.png",
		"res://assets/characters/practice_dummy/dummy_spin/frames/frame_020.png",
		"res://assets/characters/practice_dummy/dummy_spin/frames/frame_021.png",
		"res://assets/characters/practice_dummy/dummy_spin/frames/frame_022.png",
		"res://assets/characters/practice_dummy/dummy_spin/frames/frame_023.png",
	],
]
const PRACTICE_DUMMY_REACTION_FRAME_SEC := 0.075

var safe_top_px := 96.0
var safe_bottom_px := 36.0
var actor_names_visible := true:
	set(value):
		actor_names_visible = value
		_apply_actor_name_visibility()
var reserved_bottom_px := 0.0:
	set(value):
		reserved_bottom_px = maxf(value, 0.0)
		_layout_stage()

var player_actor_anchor: Control
var enemy_actor_anchor: Control
var contact_effect_anchor: Control
var floating_text_anchor: Control
var player_status_anchor: Control
var enemy_status_anchor: Control

var _player_name_label: Label
var _enemy_name_label: Label
var _player_actor_card: PanelContainer
var _enemy_actor_card: PanelContainer
var _player_sprite: TextureRect
var _enemy_sprite: TextureRect
var _player_contact_shadow: ContactShadow
var _enemy_contact_shadow: ContactShadow
var _debug_grid_overlay: DebugGridOverlay
var _player_animation_cache := {}
var _player_animation_key := ""
var _player_animation_frame_index := 0
var _player_animation_elapsed := 0.0
var _player_animation_frame_sec := 0.125
var _player_animation_loop := false
var _player_animation_playing := false
var _player_current_visible_bounds := ROGUE_VISIBLE_BOUNDS
var _player_current_anchor_point := ROGUE_ANCHOR_POINT
var _player_visual_key := PLAYER_VISUAL_KEY
var _enemy_visual_key := ""
var _enemy_combat_role := ENEMY_COMBAT_ROLE_NORMAL
var _player_base_position := Vector2.ZERO
var _enemy_base_position := Vector2.ZERO
var _player_tween: Tween
var _enemy_tween: Tween
var _stun_stars_effect: StunStarsEffect
var _slow_aura_effect: SlowAuraEffect
var _player_stun_freeze_until_msec := 0
var _player_exited_right := false
var _effect_rng := RandomNumberGenerator.new()
var _effect_generation := 0
var bandit_blade_effect_active := false

var last_cast_animation_kind := ""
var last_cast_min_cast_proc_was_timing_event := false
var last_enemy_recoil_delay_sec := 0.0
var last_enemy_recoil_distance_px := 0.0
var contact_feedback_count := 0
var last_contact_feedback_was_crit := false
var last_contact_feedback_delay_sec := 0.0
var last_cast_contact_delay_sec := 0.0
var last_cast_triggered_followup_count := 0
var last_cast_windup_duration_sec := 0.0
var last_cast_animation_start_delay_sec := 0.0
var cast_windup_count := 0
var cast_impact_count := 0
var fight_intro_count := 0
var last_fight_intro_duration_sec := 0.0
var cast_animation_count := 0
var poison_tick_pulse_count := 0
var poison_stack_tint_updates := 0
var last_poison_stack_tint_stacks := 0
var stun_effect_count := 0
var last_stun_duration_ms := 0
var cleanse_effect_count := 0
var interrupt_effect_count := 0
var slow_effect_active := false
var slow_effect_count := 0
var last_slow_strength := 0.0
var mechanic_text_count := 0
var last_mechanic_text := ""
var dodge_effect_count := 0
var dodge_afterimage_count := 0
var outcome_pose := ""
var last_enemy_animation_key := ""
var last_player_animation_key := ""
var last_player_animation_frame_count := 0
var last_player_animation_frame_path := ""
var bandit_coin_spray_count := 0
var last_bandit_coin_count := 0
var practice_dummy_reaction_count := 0
var last_practice_dummy_reaction_index := -1
var last_practice_dummy_reaction_frame_count := 0
var player_run_in_count := 0
var player_run_out_count := 0
var last_player_run_in_duration_sec := 0.0
var last_player_run_out_duration_sec := 0.0
var debug_grid_visible := false:
	set(value):
		debug_grid_visible = value
		if _debug_grid_overlay != null:
			_debug_grid_overlay.visible = value
			_debug_grid_overlay.queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	clip_contents = true
	set_process(false)
	_effect_rng.randomize()
	_build_stage()
	_layout_stage()


func _process(delta: float) -> void:
	if not _player_animation_playing:
		set_process(false)
		return
	if _player_stun_freeze_until_msec > 0:
		if Time.get_ticks_msec() < _player_stun_freeze_until_msec:
			return
		_player_stun_freeze_until_msec = 0
		if _player_animation_key == "idle":
			_set_player_animation("idle", true)
			return
	_player_animation_elapsed += delta
	if _player_animation_elapsed < _player_animation_frame_sec:
		return
	_player_animation_elapsed = 0.0
	_player_animation_frame_index += 1
	var animation: Dictionary = _player_animation_cache.get(_player_animation_key, {})
	var frames: Array = animation.get("frames", [])
	if frames.is_empty():
		_player_animation_playing = false
		set_process(false)
		return
	if _player_animation_frame_index >= frames.size():
		if _player_animation_loop:
			_player_animation_frame_index = 0
		else:
			if _player_animation_key == "defeat":
				_player_animation_frame_index = frames.size() - 1
				_apply_player_animation_frame()
				_player_animation_playing = false
				set_process(false)
				return
			_set_player_animation("idle", true)
			return
	_apply_player_animation_frame()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_stage()


func configure(player_name: String, enemy_name: String, enemy_visual_name: String = "", enemy_combat_role: String = ENEMY_COMBAT_ROLE_NORMAL) -> void:
	_clear_flurry()
	_kill_actor_tweens()
	_clear_status_visuals()
	_player_exited_right = false
	if player_actor_anchor != null:
		player_actor_anchor.visible = true
	if enemy_actor_anchor != null:
		enemy_actor_anchor.visible = true
	if _player_name_label != null:
		_player_name_label.text = player_name
	if _enemy_name_label != null:
		_enemy_name_label.text = enemy_name
	_apply_actor_name_visibility()
	_player_visual_key = PLAYER_VISUAL_KEY
	_enemy_visual_key = enemy_visual_key_for(enemy_visual_name if enemy_visual_name != "" else enemy_name)
	_enemy_combat_role = normalized_enemy_combat_role(enemy_combat_role)
	_set_player_animation("idle", true)
	_apply_enemy_visual("idle")
	_layout_stage()


func clear_target() -> void:
	_clear_flurry()
	_kill_actor_tweens()
	_clear_status_visuals()
	_player_exited_right = false
	outcome_pose = ""
	if player_actor_anchor != null:
		player_actor_anchor.visible = false
	if enemy_actor_anchor != null:
		enemy_actor_anchor.visible = false
	if _player_actor_card != null:
		_player_actor_card.visible = false
	if _enemy_actor_card != null:
		_enemy_actor_card.visible = false
	if _player_contact_shadow != null:
		_player_contact_shadow.visible = false
	if _enemy_contact_shadow != null:
		_enemy_contact_shadow.visible = false


func reset_state() -> void:
	_clear_flurry()
	_kill_actor_tweens()
	_effect_generation += 1
	_clear_bandit_coin_particles()
	_clear_status_visuals()
	_player_exited_right = false
	modulate = Color.WHITE
	last_cast_animation_kind = ""
	last_cast_min_cast_proc_was_timing_event = false
	last_enemy_recoil_delay_sec = 0.0
	last_enemy_recoil_distance_px = 0.0
	contact_feedback_count = 0
	last_contact_feedback_was_crit = false
	last_contact_feedback_delay_sec = 0.0
	last_cast_contact_delay_sec = 0.0
	last_cast_triggered_followup_count = 0
	last_cast_windup_duration_sec = 0.0
	last_cast_animation_start_delay_sec = 0.0
	cast_windup_count = 0
	cast_impact_count = 0
	fight_intro_count = 0
	last_fight_intro_duration_sec = 0.0
	cast_animation_count = 0
	poison_tick_pulse_count = 0
	poison_stack_tint_updates = 0
	last_poison_stack_tint_stacks = 0
	stun_effect_count = 0
	last_stun_duration_ms = 0
	cleanse_effect_count = 0
	interrupt_effect_count = 0
	slow_effect_active = false
	slow_effect_count = 0
	last_slow_strength = 0.0
	mechanic_text_count = 0
	last_mechanic_text = ""
	dodge_effect_count = 0
	dodge_afterimage_count = 0
	outcome_pose = ""
	last_enemy_animation_key = ""
	last_player_animation_key = ""
	last_player_animation_frame_count = 0
	last_player_animation_frame_path = ""
	bandit_coin_spray_count = 0
	last_bandit_coin_count = 0
	practice_dummy_reaction_count = 0
	last_practice_dummy_reaction_index = -1
	last_practice_dummy_reaction_frame_count = 0
	player_run_in_count = 0
	player_run_out_count = 0
	last_player_run_in_duration_sec = 0.0
	last_player_run_out_duration_sec = 0.0
	_set_player_animation("idle", true)
	_apply_enemy_visual("idle")
	_restore_actor_layout()


func play_fight_intro(animate: bool = true) -> float:
	fight_intro_count += 1
	last_fight_intro_duration_sec = FIGHT_INTRO_SEC
	_kill_actor_tweens()
	_set_player_animation("idle", true)
	_set_enemy_animation("idle")
	_restore_actor_layout()
	if not animate:
		return 0.0
	if _is_practice_dummy_target():
		return FIGHT_INTRO_SEC
	player_actor_anchor.position = _player_base_position + FIGHT_INTRO_PLAYER_OFFSET
	enemy_actor_anchor.position = _enemy_base_position + FIGHT_INTRO_ENEMY_OFFSET
	player_actor_anchor.modulate = Color(1.0, 1.0, 1.0, 0.72)
	enemy_actor_anchor.modulate = Color(1.0, 1.0, 1.0, 0.72)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(player_actor_anchor, "position", _player_base_position, FIGHT_INTRO_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(enemy_actor_anchor, "position", _enemy_base_position, FIGHT_INTRO_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(player_actor_anchor, "modulate", Color.WHITE, FIGHT_INTRO_SEC)
	tween.tween_property(enemy_actor_anchor, "modulate", Color.WHITE, FIGHT_INTRO_SEC)
	_player_tween = tween
	_enemy_tween = tween
	return FIGHT_INTRO_SEC


func play_player_run_in(animate: bool = true) -> float:
	player_run_in_count += 1
	var total_duration := CONTRACT_RUN_IN_DELAY_SEC + CONTRACT_RUN_IN_SEC
	last_player_run_in_duration_sec = total_duration
	_kill_player_tween()
	if player_actor_anchor == null:
		return 0.0
	_clear_stun_effect()
	_player_exited_right = false
	player_actor_anchor.position = _player_offscreen_left_position()
	player_actor_anchor.modulate = Color.WHITE
	player_actor_anchor.visible = true
	if enemy_actor_anchor != null:
		enemy_actor_anchor.visible = true
	_set_player_animation("walk", animate)
	if not animate:
		player_actor_anchor.position = _player_base_position
		_set_player_animation("idle", true)
		return 0.0
	_player_tween = create_tween()
	_player_tween.tween_interval(CONTRACT_RUN_IN_DELAY_SEC)
	_player_tween.tween_property(player_actor_anchor, "position", _player_base_position, CONTRACT_RUN_IN_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_player_tween.tween_callback(func(): _set_player_animation("idle", true))
	return total_duration


func play_player_run_out(animate: bool = true) -> float:
	player_run_out_count += 1
	last_player_run_out_duration_sec = CONTRACT_RUN_OUT_SEC
	_kill_player_tween()
	if player_actor_anchor == null:
		return 0.0
	_clear_stun_effect()
	_player_exited_right = false
	player_actor_anchor.position = _player_base_position
	player_actor_anchor.modulate = Color.WHITE
	player_actor_anchor.visible = true
	_set_player_animation("walk", animate)
	if not animate:
		player_actor_anchor.position = _player_offscreen_right_position()
		_hide_player_after_run_out()
		return 0.0
	_player_tween = create_tween()
	_player_tween.tween_property(player_actor_anchor, "position", _player_offscreen_right_position(), CONTRACT_RUN_OUT_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_player_tween.tween_callback(_hide_player_after_run_out)
	return CONTRACT_RUN_OUT_SEC


func show_enemy_waiting_for_player() -> void:
	_kill_player_tween()
	_clear_stun_effect()
	_player_exited_right = false
	if enemy_actor_anchor != null:
		enemy_actor_anchor.visible = true
		enemy_actor_anchor.position = _enemy_base_position
		enemy_actor_anchor.modulate = _enemy_poison_modulate()
	if player_actor_anchor != null:
		player_actor_anchor.position = _player_offscreen_left_position()
		player_actor_anchor.modulate = Color.WHITE
		_set_player_animation("idle", false)
		player_actor_anchor.visible = false
	_set_enemy_animation("idle")


func _hide_player_after_run_out() -> void:
	_player_exited_right = true
	if player_actor_anchor == null:
		return
	player_actor_anchor.position = _player_offscreen_right_position()
	player_actor_anchor.modulate = Color.WHITE
	_set_player_animation("idle", false)
	player_actor_anchor.visible = false


func restore_practice_idle_pose() -> void:
	_kill_actor_tweens()
	_clear_stun_effect()
	_clear_slow_effect()
	_player_exited_right = false
	clear_transient_effects()
	_set_player_animation("idle", true)
	_set_enemy_animation("idle")
	_restore_actor_layout()
	outcome_pose = ""


func clear_transient_effects() -> void:
	_clear_flurry()
	_kill_actor_tweens()
	_restore_actor_layout()
	_clear_bandit_coin_particles()


func set_slow_effect_active(active: bool, strength: float = 0.0, announce: bool = false) -> void:
	last_slow_strength = maxf(strength, 0.0) if active else 0.0
	slow_effect_active = active and last_slow_strength > 0.0
	_clear_slow_effect()
	if not slow_effect_active or player_actor_anchor == null:
		return
	var effect := SlowAuraEffect.new()
	effect.name = "SlowAuraEffect"
	effect.size = SLOW_AURA_SIZE
	effect.position = _slow_aura_position()
	effect.strength = clampf(last_slow_strength, 0.0, 1.0)
	effect.z_index = 12
	_slow_aura_effect = effect
	player_actor_anchor.add_child(effect)
	slow_effect_count += 1
	if announce:
		_spawn_mechanic_text("Slowed", _player_effect_anchor_point() + Vector2(0.0, -64.0), Color(0.62, 0.86, 1.0, 1.0), true)


func play_cast_presentation(cast: CombatResolver.CastEvent, playback_speed: float = 1.0, animate: bool = true) -> float:
	var contact_delay := play_cast_windup(cast, playback_speed, animate)
	if not animate:
		return 0.0
	var impact_delay := contact_delay
	var tween := create_tween()
	tween.tween_interval(contact_delay)
	tween.tween_callback(func(): play_cast_impact(cast, true))
	return impact_delay + _triggered_followup_contact_delay(cast)


func play_cast_windup(cast: CombatResolver.CastEvent, playback_speed: float = 1.0, animate: bool = true) -> float:
	_clear_flurry()
	last_cast_animation_kind = animation_kind_for_cast(cast)
	last_cast_min_cast_proc_was_timing_event = cast != null and cast.min_cast_time_proc_applied
	last_cast_triggered_followup_count = cast.triggered_skill_names.size() if cast != null else 0
	cast_windup_count += 1
	var animation_key := _player_animation_key_for_kind(last_cast_animation_kind)
	var windup_sec := _cast_windup_duration_sec(cast, playback_speed)
	if last_cast_animation_kind == ANIMATION_HOLD:
		last_cast_windup_duration_sec = windup_sec
		last_cast_animation_start_delay_sec = 0.0
		last_cast_contact_delay_sec = windup_sec
		if animate:
			_kill_player_tween()
			if player_actor_anchor != null:
				player_actor_anchor.position = _player_base_position
			_set_player_animation("idle", true)
		return windup_sec if animate else 0.0
	cast_animation_count += 1
	var timing := _windup_animation_timing(cast, animation_key, windup_sec)
	var start_delay: float = timing["start_delay"]
	var duration: float = timing["duration"]
	var contact_sec: float = timing["contact"]
	last_cast_windup_duration_sec = windup_sec
	last_cast_animation_start_delay_sec = start_delay
	last_cast_contact_delay_sec = windup_sec
	if not animate:
		_set_player_animation(last_cast_animation_kind, false, duration)
		return 0.0
	var lunge_target := _player_base_position + Vector2(LUNGE_DISTANCE_PX, 0.0)
	var recovery_sec := duration - contact_sec
	var previous_player_tween := _player_tween
	var animation_kind := last_cast_animation_kind
	var windup_tween := create_tween()
	_player_tween = windup_tween
	if start_delay > 0.0:
		windup_tween.tween_interval(start_delay)
	windup_tween.tween_callback(func():
		if previous_player_tween != null and previous_player_tween.is_valid():
			previous_player_tween.kill()
		_set_player_animation(animation_kind, true, duration)
	)
	windup_tween.tween_property(player_actor_anchor, "position", lunge_target, contact_sec).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	windup_tween.tween_property(player_actor_anchor, "position", _player_base_position, recovery_sec).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	windup_tween.tween_callback(func(): _set_player_animation("idle", true))
	return windup_sec


func play_cast_impact(cast: CombatResolver.CastEvent, animate: bool = true, include_followups: bool = true) -> float:
	cast_impact_count += 1
	if cast == null:
		return 0.0
	if not animate:
		if cast.was_interrupted:
			play_interrupt_effect(false)
		if cast.was_dodged:
			play_dodge_effect(false)
		return 0.0
	if cast.was_interrupted:
		play_interrupt_effect(animate)
	elif cast.was_dodged:
		play_dodge_effect(animate)
	elif cast.physical_damage > 0.0 or cast.blocked_amount > 0.0 or cast.poison_stacks_applied > 0:
		_play_enemy_recoil(0.0, cast.is_crit)
	if bandit_blade_effect_active and cast.physical_damage > 0.0:
		_play_bandit_coin_spray(0.0, cast.is_crit)
	if include_followups and cast != null and not cast.triggered_skill_names.is_empty():
		_play_triggered_followup(animation_kind_for_cast(cast))
		return _triggered_followup_contact_delay(cast)
	return 0.0


func _cast_windup_duration_sec(cast: CombatResolver.CastEvent, playback_speed: float) -> float:
	if cast == null:
		return 0.0
	var cast_ms := maxi(cast.time_ms - cast.cast_start_ms, 0)
	return float(cast_ms) / 1000.0 / maxf(playback_speed, 0.001)


func _windup_animation_timing(cast: CombatResolver.CastEvent, animation_key: String, windup_sec: float) -> Dictionary:
	var natural_duration := _presentation_duration_for_cast(cast, 1.0, animation_key)
	var natural_contact := _contact_delay_for_cast(cast, animation_key, natural_duration, false)
	if windup_sec <= 0.0 or natural_contact <= 0.0:
		return {
			"start_delay": 0.0,
			"duration": maxf(natural_duration, MIN_CAST_ANIMATION_SEC),
			"contact": 0.0,
		}
	if windup_sec >= natural_contact:
		return {
			"start_delay": windup_sec - natural_contact,
			"duration": natural_duration,
			"contact": natural_contact,
		}
	var scale := windup_sec / natural_contact
	return {
		"start_delay": 0.0,
		"duration": maxf(natural_duration * scale, MIN_CAST_ANIMATION_SEC),
		"contact": windup_sec,
	}


func _triggered_followup_contact_delay(cast: CombatResolver.CastEvent) -> float:
	if cast == null or cast.triggered_skill_names.is_empty():
		return 0.0
	return TRIGGERED_FOLLOWUP_ANIMATION_SEC * 0.45


func _play_triggered_followup(animation_kind: String) -> void:
	_kill_player_tween()
	var lunge_target := _player_base_position + Vector2(LUNGE_DISTANCE_PX, 0.0)
	var followup_contact_sec := TRIGGERED_FOLLOWUP_ANIMATION_SEC * 0.45
	var followup_recovery_sec := TRIGGERED_FOLLOWUP_ANIMATION_SEC - followup_contact_sec
	_player_tween = create_tween()
	_player_tween.tween_callback(func(): _set_player_animation(animation_kind, true, TRIGGERED_FOLLOWUP_ANIMATION_SEC))
	_player_tween.tween_property(player_actor_anchor, "position", lunge_target, followup_contact_sec).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_player_tween.tween_property(player_actor_anchor, "position", _player_base_position, followup_recovery_sec).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_player_tween.tween_callback(func(): _set_player_animation("idle", true))


func set_bandit_blade_effect_active(active: bool) -> void:
	bandit_blade_effect_active = active


func play_poison_tick_pulse(animate: bool = true) -> void:
	poison_tick_pulse_count += 1
	if not animate:
		return
	_kill_enemy_tween(true)
	_enemy_tween = create_tween()
	_enemy_tween.tween_property(enemy_actor_anchor, "modulate", UIColors.COMBAT_POISON_TICK_FLASH, TICK_PULSE_SEC * 0.5)
	_enemy_tween.tween_property(enemy_actor_anchor, "modulate", _enemy_poison_modulate(), TICK_PULSE_SEC * 0.5)


func set_poison_stacks(stacks: int, _animate: bool = true) -> void:
	poison_stack_tint_updates += 1
	last_poison_stack_tint_stacks = maxi(stacks, 0)
	if enemy_actor_anchor == null:
		return
	enemy_actor_anchor.modulate = _enemy_poison_modulate()


func play_stun_effect(duration_ms: int, animate: bool = true, anchored: bool = false) -> void:
	stun_effect_count += 1
	last_stun_duration_ms = duration_ms
	if duration_ms <= 0 or player_status_anchor == null:
		return
	_clear_stun_effect()
	var effect := StunStarsEffect.new()
	effect.name = "StunStarsEffect"
	effect.duration_sec = float(duration_ms) / 1000.0
	effect.size = STATUS_SIZE
	effect.z_index = 20
	_stun_stars_effect = effect
	player_status_anchor.add_child(effect)
	_freeze_player_idle_for_stun(duration_ms, animate)
	_spawn_mechanic_text("Stunned", _stun_star_anchor_point() + Vector2(0.0, 20.0), Color(1.0, 0.86, 0.22, 1.0), animate)
	if animate and not anchored and player_actor_anchor != null:
		_play_stun_jolt()


func play_cleanse_effect(animate: bool = true) -> void:
	cleanse_effect_count += 1
	var center := _enemy_effect_anchor_point()
	if center == Vector2.ZERO:
		return
	var burst := CleanseBurstEffect.new()
	burst.name = "CleanseBurstEffect"
	burst.size = CLEANSE_BURST_SIZE
	burst.position = center - CLEANSE_BURST_SIZE * 0.5
	burst.z_index = 18
	add_child(burst)
	_spawn_mechanic_text("Cleansed", center + Vector2(0.0, -48.0), Color(0.78, 0.92, 1.0, 1.0), animate)
	if animate:
		_play_cleanse_enemy_flash()


func play_interrupt_effect(animate: bool = true, anchored: bool = false) -> void:
	interrupt_effect_count += 1
	var center := _player_effect_anchor_point()
	if center == Vector2.ZERO:
		return
	var slash := InterruptSlashEffect.new()
	slash.name = "InterruptSlashEffect"
	slash.size = INTERRUPT_SLASH_SIZE
	slash.position = center - INTERRUPT_SLASH_SIZE * 0.5
	slash.z_index = 28
	add_child(slash)
	_spawn_mechanic_text("Interrupted", center + Vector2(0.0, -62.0), Color(1.0, 0.34, 0.24, 1.0), animate)
	if animate and not anchored:
		_play_interrupt_player_flash()


func play_dodge_effect(animate: bool = true) -> void:
	dodge_effect_count += 1
	var center := _enemy_effect_anchor_point()
	if center != Vector2.ZERO:
		_spawn_mechanic_text("Dodged", center + Vector2(0.0, -54.0), Color(0.86, 0.92, 1.0, 1.0), animate)
	if not animate:
		return
	_spawn_dodge_afterimages()
	_play_dodge_shift()


func play_outcome_pose(victory: bool, animate: bool = true) -> void:
	_clear_flurry()
	outcome_pose = OUTCOME_VICTORY if victory else OUTCOME_DEFEAT
	_clear_stun_effect()
	if victory:
		_set_enemy_animation("defeat")
	else:
		_set_player_animation("defeat", animate)
	if not animate:
		return
	_kill_actor_tweens()
	if victory and _is_practice_dummy_target():
		_set_enemy_animation("idle")
		if enemy_actor_anchor != null:
			enemy_actor_anchor.position = _enemy_base_position
			enemy_actor_anchor.modulate = _enemy_poison_modulate()
		return
	var target_anchor := enemy_actor_anchor if victory else player_actor_anchor
	var target_position := (_enemy_base_position if victory else _player_base_position) + Vector2(0.0, 10.0)
	var target_modulate := UIColors.COMBAT_DEFEATED_ACTOR_MODULATE if victory else Color.WHITE
	var tween := create_tween()
	if victory:
		_enemy_tween = tween
	else:
		_player_tween = tween
	tween.set_parallel(true)
	tween.tween_property(target_anchor, "position", target_position, OUTCOME_POSE_SEC)
	tween.tween_property(target_anchor, "modulate", target_modulate, OUTCOME_POSE_SEC)


static func animation_kind_for_cast(cast: CombatResolver.CastEvent) -> String:
	if cast == null:
		return ANIMATION_PHYSICAL
	if cast.skill != null and cast.skill.id == "skill.hold":
		return ANIMATION_HOLD
	if cast.poison_stacks_applied > 0 or cast.poison_resistance_reduction_applied > 0.0:
		return ANIMATION_POISON
	if _skill_has_poison_damage(cast.skill):
		return ANIMATION_POISON
	if _skill_is_poison_themed(cast.skill):
		return ANIMATION_POISON
	return ANIMATION_PHYSICAL


static func _skill_has_poison_damage(skill: Skill) -> bool:
	if skill == null:
		return false
	if skill.poison_stacks_applied > 0:
		return true
	for effect in skill.effects:
		if effect is PoisonDamageEffect:
			return true
	return false


static func _skill_is_poison_themed(skill: Skill) -> bool:
	if skill == null:
		return false
	if _skill_has_poison_damage(skill):
		return true
	var id_text := skill.id.to_lower()
	var display_text := skill.display_name.to_lower()
	if id_text.contains("poison") or id_text.contains("toxic") or display_text.contains("poison") or display_text.contains("toxic"):
		return true
	for effect in skill.effects:
		if effect is PoisonDamageEffect or effect is PoisonResistanceReductionEffect:
			return true
	return false


func player_sprite_available() -> bool:
	return _player_sprite != null and _player_sprite.texture != null


func enemy_sprite_available() -> bool:
	return _enemy_sprite != null and _enemy_sprite.texture != null


func enemy_popup_global_position() -> Vector2:
	if enemy_actor_anchor == null:
		return global_position
	return enemy_actor_anchor.global_position + ACTOR_SIZE * Vector2(0.5, 0.32)


func play_area_global_rect() -> Rect2:
	var stage_rect := get_global_rect()
	stage_rect.size.y = _effective_stage_size().y
	return stage_rect


func expected_player_sprite_paths() -> PackedStringArray:
	var paths := PackedStringArray()
	for animation_key in PLAYER_ANIMATION_MANIFEST_PATHS.keys():
		for path in _player_animation_frame_paths(animation_key):
			paths.append(path)
	return paths


func expected_enemy_sprite_paths(enemy_name: String) -> PackedStringArray:
	return PackedStringArray(_enemy_animation_paths_for(enemy_visual_key_for(enemy_name)).values())


func expected_enemy_sprite_region(enemy_name: String, animation_key: String) -> Rect2:
	var visual_key := enemy_visual_key_for(enemy_name)
	if _is_static_enemy_visual_key(visual_key):
		var texture := _texture_from_path(_enemy_animation_paths_for(visual_key).get(animation_key, _enemy_animation_paths_for(visual_key).get("idle", "")))
		return Rect2(Vector2.ZERO, texture.get_size() if texture != null else STATIC_ENEMY_LAYOUT_FRAME_SIZE)
	return _animation_region_for(_enemy_animation_regions_for(visual_key), animation_key, PEASANT_FRAME_SIZE)


func _build_stage() -> void:
	player_actor_anchor = _make_anchor("PlayerActorAnchor", ACTOR_SIZE)
	player_actor_anchor.z_index = 3
	add_child(player_actor_anchor)
	_player_actor_card = _make_actor_card("PlayerActor", "Rogue", UIColors.TEXT_NORMAL)
	player_actor_anchor.add_child(_player_actor_card)
	_player_name_label = _player_actor_card.find_child("ActorLabel", true, false) as Label
	_player_contact_shadow = _make_contact_shadow("PlayerContactShadow")
	player_actor_anchor.add_child(_player_contact_shadow)
	_player_sprite = _make_actor_sprite("PlayerSprite", false)
	player_actor_anchor.add_child(_player_sprite)

	enemy_actor_anchor = _make_anchor("EnemyActorAnchor", ACTOR_SIZE)
	enemy_actor_anchor.z_index = 2
	add_child(enemy_actor_anchor)
	_enemy_actor_card = _make_actor_card("EnemyActor", "Enemy", UIColors.TEXT_WARNING)
	enemy_actor_anchor.add_child(_enemy_actor_card)
	_enemy_name_label = _enemy_actor_card.find_child("ActorLabel", true, false) as Label
	_apply_actor_name_visibility()
	_enemy_contact_shadow = _make_contact_shadow("EnemyContactShadow")
	enemy_actor_anchor.add_child(_enemy_contact_shadow)
	_enemy_sprite = _make_actor_sprite("EnemySprite", true)
	enemy_actor_anchor.add_child(_enemy_sprite)

	contact_effect_anchor = _make_anchor("ContactEffectAnchor", CONTACT_SIZE)
	add_child(contact_effect_anchor)

	floating_text_anchor = _make_anchor("FloatingTextAnchor", CONTACT_SIZE)
	add_child(floating_text_anchor)

	player_status_anchor = _make_anchor("PlayerStatusAnchor", STATUS_SIZE)
	add_child(player_status_anchor)

	enemy_status_anchor = _make_anchor("EnemyStatusAnchor", STATUS_SIZE)
	add_child(enemy_status_anchor)

	_debug_grid_overlay = DebugGridOverlay.new()
	_debug_grid_overlay.name = "DebugGridOverlay"
	_debug_grid_overlay.combat_stage = self
	_debug_grid_overlay.visible = debug_grid_visible
	add_child(_debug_grid_overlay)
	clear_target()


func _make_anchor(anchor_name: String, anchor_size: Vector2) -> Control:
	var anchor := Control.new()
	anchor.name = anchor_name
	anchor.custom_minimum_size = anchor_size
	anchor.size = anchor_size
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return anchor


func _make_actor_card(card_name: String, label_text: String, accent_color: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = card_name
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.set_anchors_preset(Control.PRESET_FULL_RECT)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(UIColors.PANEL_DEEP.r, UIColors.PANEL_DEEP.g, UIColors.PANEL_DEEP.b, 0.64)
	style.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	card.add_theme_stylebox_override("panel", style)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.add_child(center)

	var actor_label := Label.new()
	actor_label.name = "ActorLabel"
	actor_label.text = label_text
	actor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	actor_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	actor_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	actor_label.add_theme_color_override("font_color", accent_color)
	center.add_child(actor_label)
	return card


func _apply_actor_name_visibility() -> void:
	if _player_name_label != null:
		_player_name_label.visible = actor_names_visible
	if _enemy_name_label != null:
		_enemy_name_label.visible = actor_names_visible


func _make_actor_sprite(sprite_name: String, flip_h: bool) -> TextureRect:
	var sprite := TextureRect.new()
	sprite.name = sprite_name
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.flip_h = flip_h
	sprite.visible = false
	return sprite


func _make_contact_shadow(shadow_name: String) -> ContactShadow:
	var shadow := ContactShadow.new()
	shadow.name = shadow_name
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.z_index = -1
	shadow.visible = false
	return shadow


static func enemy_visual_key_for(enemy_name: String) -> String:
	var normalized_name := enemy_name.strip_edges()
	if ENEMY_VISUAL_KEYS_BY_NAME.has(normalized_name):
		return ENEMY_VISUAL_KEYS_BY_NAME[normalized_name]
	if ENEMY_PRESENTATION_VISUAL_ALIASES.has(normalized_name):
		var alias_name := String(ENEMY_PRESENTATION_VISUAL_ALIASES[normalized_name])
		if ENEMY_VISUAL_KEYS_BY_NAME.has(alias_name):
			return ENEMY_VISUAL_KEYS_BY_NAME[alias_name]
	for prefix in ["Veteran "]:
		if normalized_name.begins_with(prefix):
			var base_name := normalized_name.trim_prefix(prefix)
			if ENEMY_VISUAL_KEYS_BY_NAME.has(base_name):
				return ENEMY_VISUAL_KEYS_BY_NAME[base_name]
	return ""


static func normalized_enemy_combat_role(role: String) -> String:
	var normalized_role := role.strip_edges().to_lower()
	return normalized_role if ENEMY_COMBAT_ROLE_SCALE.has(normalized_role) else ENEMY_COMBAT_ROLE_NORMAL


static func enemy_combat_role_scale(role: String) -> float:
	return float(ENEMY_COMBAT_ROLE_SCALE.get(normalized_enemy_combat_role(role), ENEMY_COMBAT_ROLE_SCALE[ENEMY_COMBAT_ROLE_NORMAL]))


func _enemy_animation_paths_for(visual_key: String) -> Dictionary:
	return ENEMY_ANIMATION_PATHS.get(visual_key, {})


func _enemy_animation_regions_for(visual_key: String) -> Dictionary:
	return ENEMY_ANIMATION_REGIONS.get(visual_key, {})


func _apply_actor_visual(sprite: TextureRect, fallback_card: PanelContainer, animation_paths: Dictionary, animation_regions: Dictionary, animation_key: String, frame_size: Vector2i, sprite_scale: float, flip_h: bool, anchor_point: Vector2 = PEASANT_ANCHOR_POINT) -> void:
	if sprite == null or fallback_card == null:
		return
	var region := _animation_region_for(animation_regions, animation_key, frame_size)
	var texture := _frame_texture(animation_paths.get(animation_key, animation_paths.get("idle", "")), region)
	sprite.texture = texture
	sprite.flip_h = flip_h
	sprite.size = region.size
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.pivot_offset = region.size * 0.5
	sprite.position = _sprite_position_for_anchor(region.size, anchor_point, sprite_scale)
	if sprite == _enemy_sprite and _is_practice_dummy_target():
		sprite.position += PRACTICE_DUMMY_SPRITE_OFFSET
	sprite.visible = texture != null
	fallback_card.visible = false
	if sprite == _enemy_sprite:
		_update_contact_shadow(_enemy_contact_shadow, sprite, PEASANT_VISIBLE_BOUNDS)
		if _is_practice_dummy_target():
			_enemy_contact_shadow.position += PRACTICE_DUMMY_SHADOW_OFFSET


func _sprite_position_for(frame_size: Vector2, sprite_scale: float) -> Vector2:
	var scaled_size := frame_size * sprite_scale
	return Vector2(
		(ACTOR_SIZE.x - scaled_size.x) * 0.5,
		maxf(0.0, ACTOR_SIZE.y - scaled_size.y - 8.0)
	)


func _sprite_position_for_anchor(frame_size: Vector2, anchor_point: Vector2, sprite_scale: float) -> Vector2:
	var pivot_offset := frame_size * 0.5
	var render_offset := pivot_offset - pivot_offset * sprite_scale
	return ACTOR_LOCAL_ANCHOR - render_offset - anchor_point * sprite_scale


func _update_contact_shadow(shadow: ContactShadow, sprite: TextureRect, visible_bounds: Rect2) -> void:
	if shadow == null or sprite == null:
		return
	shadow.visible = sprite.visible and sprite.texture != null
	if not shadow.visible:
		return
	var render_top_left := _sprite_render_top_left(sprite)
	var bounds := visible_bounds
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		bounds = Rect2(Vector2.ZERO, sprite.size)
	var shadow_size := Vector2(
		maxf(bounds.size.x * sprite.scale.x * CONTACT_SHADOW_WIDTH_SCALE, CONTACT_SHADOW_MIN_SIZE.x),
		CONTACT_SHADOW_MIN_SIZE.y
	)
	var foot_center := render_top_left + Vector2((bounds.position.x + bounds.size.x * 0.5) * sprite.scale.x, (bounds.position.y + bounds.size.y) * sprite.scale.y)
	shadow.size = shadow_size
	shadow.position = foot_center - shadow_size * 0.5 + Vector2(0.0, 2.0)
	shadow.queue_redraw()


func _actor_position_for_grid(stage_size: Vector2, grid_position: Vector2, frame_size: Vector2, anchor_point: Vector2, sprite_scale: float, stage_offset_px: Vector2 = Vector2.ZERO) -> Vector2:
	var clamped_grid := Vector2(
		clampf(grid_position.x, STAGE_GRID_MIN, STAGE_GRID_MAX),
		clampf(grid_position.y, STAGE_GRID_MIN, STAGE_GRID_MAX)
	)
	var desired_sprite_center := _stage_point_for_grid(clamped_grid) + stage_offset_px
	var sprite_position := _sprite_position_for_anchor(frame_size, anchor_point, sprite_scale)
	var scaled_size := frame_size * sprite_scale
	var pivot_offset := frame_size * 0.5
	var render_offset := pivot_offset - pivot_offset * sprite_scale
	var anchor_position := desired_sprite_center - ACTOR_LOCAL_ANCHOR
	var min_anchor := Vector2(
		STAGE_GRID_MARGIN_PX - sprite_position.x - render_offset.x,
		STAGE_GRID_MARGIN_PX - sprite_position.y - render_offset.y
	)
	var max_anchor := Vector2(
		stage_size.x - sprite_position.x - render_offset.x - scaled_size.x - STAGE_GRID_MARGIN_PX,
		stage_size.y - sprite_position.y - render_offset.y - scaled_size.y - STAGE_GRID_MARGIN_PX
	)
	return Vector2(
		clampf(anchor_position.x, min_anchor.x, max_anchor.x),
		clampf(anchor_position.y, min_anchor.y, max_anchor.y)
	)


func _stage_point_for_grid(grid_position: Vector2) -> Vector2:
	var grid_range := STAGE_GRID_MAX - STAGE_GRID_MIN
	var stage_size := _effective_stage_size()
	return Vector2(
		(clampf(grid_position.x, STAGE_GRID_MIN, STAGE_GRID_MAX) - STAGE_GRID_MIN) / grid_range * stage_size.x,
		(clampf(grid_position.y, STAGE_GRID_MIN, STAGE_GRID_MAX) - STAGE_GRID_MIN) / grid_range * stage_size.y
	)


func _player_offscreen_left_position() -> Vector2:
	return Vector2(-ACTOR_SIZE.x - ROGUE_FRAME_SIZE.x * ROGUE_SPRITE_SCALE, _player_base_position.y)


func _player_offscreen_right_position() -> Vector2:
	return Vector2(_effective_stage_size().x + ACTOR_SIZE.x, _player_base_position.y)


func _effective_stage_size() -> Vector2:
	return Vector2(size.x, maxf(size.y - reserved_bottom_px, 1.0))


func _sprite_anchor_point(anchor: Control, sprite: TextureRect, anchor_point: Vector2) -> Vector2:
	if anchor == null or sprite == null:
		return Vector2.ZERO
	return anchor.position + _sprite_render_top_left(sprite) + anchor_point * sprite.scale


func _sprite_render_top_left(sprite: TextureRect) -> Vector2:
	return sprite.position + sprite.pivot_offset - sprite.pivot_offset * sprite.scale


func _animation_region_for(animation_regions: Dictionary, animation_key: String, frame_size: Vector2i) -> Rect2:
	if animation_regions.has(animation_key):
		return animation_regions[animation_key]
	if animation_regions.has("idle"):
		return animation_regions["idle"]
	return Rect2(Vector2.ZERO, Vector2(frame_size))


func _frame_texture(path: String, region: Rect2) -> Texture2D:
	if path == "":
		return null
	var source := _texture_from_path(path)
	if source == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = region
	return atlas


func _texture_from_path(path: String) -> Texture2D:
	if path == "":
		return null
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null:
		return null
	return ImageTexture.create_from_image(image)


func _player_animation_frame_paths(animation_key: String) -> PackedStringArray:
	var animation := _player_animation_for_key(animation_key)
	var paths := PackedStringArray()
	for frame in animation.get("frames", []):
		if frame.has("path"):
			paths.append(frame["path"])
	return paths


func _player_animation_for_key(animation_key: String) -> Dictionary:
	var resolved_key := animation_key
	if not PLAYER_ANIMATION_MANIFEST_PATHS.has(resolved_key):
		resolved_key = "idle"
	if _player_animation_cache.has(resolved_key):
		return _player_animation_cache[resolved_key]
	var manifest_path: String = PLAYER_ANIMATION_MANIFEST_PATHS[resolved_key]
	var manifest := _load_json_manifest(manifest_path)
	var frames: Array = []
	var manifest_base := manifest_path.get_base_dir()
	for frame in manifest.get("frames", []):
		var relative_path: String = frame.get("file", "")
		if relative_path == "":
			continue
		var visible_data: Dictionary = frame.get("visible_bounds", {})
		var visible_bounds := ROGUE_VISIBLE_BOUNDS
		if not visible_data.is_empty():
			visible_bounds = Rect2(
				Vector2(float(visible_data.get("x", 0.0)), float(visible_data.get("y", 0.0))),
				Vector2(float(visible_data.get("w", ROGUE_VISIBLE_BOUNDS.size.x)), float(visible_data.get("h", ROGUE_VISIBLE_BOUNDS.size.y)))
			)
		frames.append({
			"path": "%s/%s" % [manifest_base, relative_path],
			"duration_ms": int(frame.get("duration_ms", 100)),
			"visible_bounds": visible_bounds,
		})
	var frame_size_data: Dictionary = manifest.get("frame_size", {})
	var pivot_data: Dictionary = manifest.get("pivot", {})
	var animation := {
		"frames": frames,
		"frame_size": Vector2(float(frame_size_data.get("w", ROGUE_FRAME_SIZE.x)), float(frame_size_data.get("h", ROGUE_FRAME_SIZE.y))),
		"anchor_point": Vector2(float(pivot_data.get("x", ROGUE_ANCHOR_POINT.x)), float(pivot_data.get("y", ROGUE_ANCHOR_POINT.y))),
		"loop": bool(manifest.get("loop", resolved_key == "idle")),
		"fps": float(manifest.get("fps", 8.0)),
	}
	_player_animation_cache[resolved_key] = animation
	return animation


func _load_json_manifest(path: String) -> Dictionary:
	if path == "" or not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}


func _apply_player_animation_frame() -> void:
	if _player_sprite == null or _player_actor_card == null:
		return
	var animation: Dictionary = _player_animation_cache.get(_player_animation_key, {})
	var frames: Array = animation.get("frames", [])
	if frames.is_empty():
		_player_sprite.visible = false
		_player_actor_card.visible = false
		_update_contact_shadow(_player_contact_shadow, _player_sprite, _player_current_visible_bounds)
		return
	_player_animation_frame_index = clampi(_player_animation_frame_index, 0, frames.size() - 1)
	var frame: Dictionary = frames[_player_animation_frame_index]
	var path: String = frame.get("path", "")
	last_player_animation_frame_path = path
	var texture := _texture_from_path(path)
	_player_sprite.texture = texture
	if texture != null:
		_player_sprite.size = texture.get_size()
	else:
		_player_sprite.size = animation.get("frame_size", Vector2(ROGUE_FRAME_SIZE))
	_player_sprite.scale = Vector2(ROGUE_SPRITE_SCALE, ROGUE_SPRITE_SCALE)
	_player_sprite.pivot_offset = _player_sprite.size * 0.5
	_player_current_anchor_point = animation.get("anchor_point", ROGUE_ANCHOR_POINT)
	_player_sprite.position = _sprite_position_for_anchor(_player_sprite.size, _player_current_anchor_point, ROGUE_SPRITE_SCALE)
	if _is_practice_dummy_target():
		_player_sprite.position += PRACTICE_ROGUE_SPRITE_OFFSET
	_player_sprite.flip_h = false
	_player_sprite.visible = texture != null
	_player_actor_card.visible = false
	_player_current_visible_bounds = frame.get("visible_bounds", ROGUE_VISIBLE_BOUNDS)
	_update_contact_shadow(_player_contact_shadow, _player_sprite, _player_current_visible_bounds)
	if _debug_grid_overlay != null:
		_debug_grid_overlay.queue_redraw()


func _set_player_animation(kind: String, animate: bool = true, duration_override_sec: float = -1.0) -> void:
	var animation_key := _player_animation_key_for_kind(kind)
	var animation := _player_animation_for_key(animation_key)
	var frames: Array = animation.get("frames", [])
	_player_animation_key = animation_key
	_player_animation_frame_index = 0
	_player_animation_elapsed = 0.0
	_player_animation_loop = bool(animation.get("loop", animation_key == "idle")) and animate
	_player_animation_playing = animate and frames.size() > 1
	last_player_animation_key = animation_key
	last_player_animation_frame_count = frames.size()
	if frames.size() > 0:
		var first_frame: Dictionary = frames[0]
		_player_animation_frame_sec = maxf(float(first_frame.get("duration_ms", 100)) / 1000.0, 0.001)
		if duration_override_sec > 0.0 and frames.size() > 1:
			_player_animation_frame_sec = maxf(duration_override_sec / float(frames.size()), 0.001)
	_apply_player_animation_frame()
	set_process(_player_animation_playing)


func _player_animation_key_for_kind(kind: String) -> String:
	if kind == ANIMATION_PHYSICAL:
		return "attack_physical"
	if kind == ANIMATION_POISON:
		return "attack_poison"
	if kind == "walk":
		return "walk"
	if kind == "hurt":
		return "hurt"
	if kind == "defeat":
		return "defeat"
	return "idle"


func _player_animation_duration_sec(animation_key: String) -> float:
	var animation := _player_animation_for_key(animation_key)
	var frames: Array = animation.get("frames", [])
	var duration_sec := 0.0
	for frame in frames:
		duration_sec += maxf(float(frame.get("duration_ms", 100)) / 1000.0, 0.001)
	return duration_sec


func player_defeat_animation_duration_sec() -> float:
	return _player_animation_duration_sec("defeat")


func _player_animation_contact_sec(animation_key: String) -> float:
	var animation := _player_animation_for_key(animation_key)
	var frames: Array = animation.get("frames", [])
	if frames.size() < 2:
		return _player_animation_duration_sec(animation_key)
	var contact_frame_index := frames.size() - 2
	var contact_sec := 0.0
	for index in contact_frame_index:
		var frame: Dictionary = frames[index]
		contact_sec += maxf(float(frame.get("duration_ms", 100)) / 1000.0, 0.001)
	return contact_sec


func _set_enemy_animation(kind: String) -> void:
	var animation_key := "idle"
	if kind == "hurt":
		animation_key = "hurt"
	elif kind == "defeat":
		animation_key = "defeat"
	last_enemy_animation_key = animation_key
	_apply_enemy_visual(animation_key)


func _apply_enemy_visual(animation_key: String) -> void:
	if _is_static_enemy_visual():
		_apply_static_enemy_visual(animation_key)
		return
	_apply_actor_visual(_enemy_sprite, _enemy_actor_card, _enemy_animation_paths_for(_enemy_visual_key), _enemy_animation_regions_for(_enemy_visual_key), animation_key, PEASANT_FRAME_SIZE, _enemy_sprite_scale(), _enemy_flip_h(), _enemy_anchor_point())


func _is_practice_dummy_target() -> bool:
	return _enemy_visual_key == PRACTICE_DUMMY_VISUAL_KEY


func _is_static_enemy_visual() -> bool:
	return _is_static_enemy_visual_key(_enemy_visual_key)


func _is_static_enemy_visual_key(visual_key: String) -> bool:
	return STATIC_ENEMY_VISUAL_KEYS.has(visual_key)


func _enemy_sprite_scale() -> float:
	var role_scale := enemy_combat_role_scale(_enemy_combat_role)
	if _is_static_enemy_visual():
		return STATIC_ENEMY_SPRITE_SCALE * role_scale
	return (PRACTICE_DUMMY_SPRITE_SCALE if _is_practice_dummy_target() else PEASANT_SPRITE_SCALE) * role_scale


func _enemy_anchor_point() -> Vector2:
	if _is_static_enemy_visual():
		return _static_enemy_anchor_point(_enemy_layout_frame_size())
	return PRACTICE_DUMMY_ANCHOR_POINT if _is_practice_dummy_target() else PEASANT_ANCHOR_POINT


func _enemy_flip_h() -> bool:
	if _is_static_enemy_visual():
		return bool(STATIC_ENEMY_FLIP_H_BY_VISUAL_KEY.get(_enemy_visual_key, false))
	return false if _is_practice_dummy_target() else true


func _enemy_layout_frame_size() -> Vector2:
	if not _is_static_enemy_visual():
		return Vector2(PEASANT_FRAME_SIZE)
	if _enemy_sprite != null and _enemy_sprite.texture != null and _enemy_sprite.size.x > 0.0 and _enemy_sprite.size.y > 0.0:
		return _enemy_sprite.size
	var paths := _enemy_animation_paths_for(_enemy_visual_key)
	var texture := _texture_from_path(paths.get("idle", ""))
	if texture != null:
		return texture.get_size()
	return STATIC_ENEMY_LAYOUT_FRAME_SIZE


func _static_enemy_anchor_point(frame_size: Vector2) -> Vector2:
	return Vector2(frame_size.x * STATIC_ENEMY_ANCHOR_RATIO.x, frame_size.y * STATIC_ENEMY_ANCHOR_RATIO.y)


func _apply_static_enemy_visual(animation_key: String) -> void:
	if _enemy_sprite == null or _enemy_actor_card == null:
		return
	var paths := _enemy_animation_paths_for(_enemy_visual_key)
	var texture := _texture_from_path(paths.get(animation_key, paths.get("idle", "")))
	_enemy_sprite.texture = texture
	_enemy_sprite.size = texture.get_size() if texture != null else STATIC_ENEMY_LAYOUT_FRAME_SIZE
	var sprite_scale := _enemy_sprite_scale()
	_enemy_sprite.scale = Vector2(sprite_scale, sprite_scale)
	_enemy_sprite.pivot_offset = _enemy_sprite.size * 0.5
	_enemy_sprite.position = _sprite_position_for_anchor(_enemy_sprite.size, _static_enemy_anchor_point(_enemy_sprite.size), sprite_scale)
	_enemy_sprite.flip_h = _enemy_flip_h()
	_enemy_sprite.visible = texture != null
	_enemy_actor_card.visible = false
	_update_contact_shadow(_enemy_contact_shadow, _enemy_sprite, Rect2(Vector2.ZERO, _enemy_sprite.size))
	if _debug_grid_overlay != null:
		_debug_grid_overlay.queue_redraw()


func _apply_enemy_frame_path(path: String) -> void:
	if _enemy_sprite == null or _enemy_actor_card == null:
		return
	var texture := _texture_from_path(path)
	_enemy_sprite.texture = texture
	_enemy_sprite.size = texture.get_size() if texture != null else Vector2(PEASANT_FRAME_SIZE)
	var sprite_scale := _enemy_sprite_scale()
	_enemy_sprite.scale = Vector2(sprite_scale, sprite_scale)
	_enemy_sprite.pivot_offset = _enemy_sprite.size * 0.5
	_enemy_sprite.position = _sprite_position_for_anchor(_enemy_sprite.size, _enemy_anchor_point(), sprite_scale)
	if _is_practice_dummy_target():
		_enemy_sprite.position += PRACTICE_DUMMY_SPRITE_OFFSET
	_enemy_sprite.flip_h = _enemy_flip_h()
	_enemy_sprite.visible = texture != null
	_enemy_actor_card.visible = false
	_update_contact_shadow(_enemy_contact_shadow, _enemy_sprite, PEASANT_VISIBLE_BOUNDS)
	if _is_practice_dummy_target():
		_enemy_contact_shadow.position += PRACTICE_DUMMY_SHADOW_OFFSET
	if _debug_grid_overlay != null:
		_debug_grid_overlay.queue_redraw()


func _presentation_duration_for_cast(cast: CombatResolver.CastEvent, playback_speed: float, animation_key: String = "") -> float:
	if cast != null and cast.min_cast_time_proc_applied:
		return MIN_CAST_ANIMATION_SEC
	var speed_scale := maxf(playback_speed, 0.001)
	var source_ms := 700
	if cast != null and cast.skill != null:
		source_ms = cast.skill.base_execution_ms
	var base_sec := float(source_ms) / 1000.0 / speed_scale
	var cast_duration := clampf(base_sec * 0.28, MIN_CAST_ANIMATION_SEC, MAX_CAST_ANIMATION_SEC)
	var resolved_animation_key := animation_key
	if resolved_animation_key == "":
		resolved_animation_key = _player_animation_key_for_kind(animation_kind_for_cast(cast))
	var animation_duration := _player_animation_duration_sec(resolved_animation_key)
	return maxf(cast_duration, animation_duration)


func _contact_delay_for_cast(cast: CombatResolver.CastEvent, animation_key: String, duration: float, include_triggered_followup: bool = true) -> float:
	var contact_sec := _player_animation_contact_sec(animation_key)
	var animation_duration := _player_animation_duration_sec(animation_key)
	if animation_duration > 0.0 and duration < animation_duration:
		contact_sec *= duration / animation_duration
	if include_triggered_followup and cast != null and not cast.triggered_skill_names.is_empty():
		contact_sec = duration + TRIGGERED_FOLLOWUP_ANIMATION_SEC * 0.45
	return contact_sec


func _play_enemy_recoil(delay_sec: float, is_crit: bool) -> void:
	_kill_enemy_tween(true)
	last_enemy_recoil_delay_sec = delay_sec
	last_contact_feedback_delay_sec = delay_sec
	last_contact_feedback_was_crit = is_crit
	contact_feedback_count += 1
	if _is_practice_dummy_target():
		_play_practice_dummy_reaction(delay_sec)
		return
	if _is_static_enemy_visual():
		_play_static_enemy_hit_reaction(delay_sec, is_crit)
		return
	var recoil_distance := CRIT_RECOIL_DISTANCE_PX if is_crit else RECOIL_DISTANCE_PX
	last_enemy_recoil_distance_px = recoil_distance
	var recoil_out_sec := 0.055 if is_crit else 0.07
	var recoil_back_sec := 0.105 if is_crit else 0.13
	var hurt_color := UIColors.COMBAT_CRIT_FLASH if is_crit else UIColors.COMBAT_HIT_FLASH
	var recoil_target := _enemy_base_position + Vector2(recoil_distance, 0.0)
	var hit_animation := "idle" if is_crit else "hurt"
	_enemy_tween = create_tween()
	_enemy_tween.tween_interval(delay_sec)
	_enemy_tween.tween_callback(func(): _set_enemy_animation(hit_animation))
	_enemy_tween.tween_property(enemy_actor_anchor, "position", recoil_target, recoil_out_sec)
	_enemy_tween.parallel().tween_property(enemy_actor_anchor, "modulate", hurt_color, recoil_out_sec)
	_enemy_tween.tween_property(enemy_actor_anchor, "position", _enemy_base_position, recoil_back_sec)
	_enemy_tween.parallel().tween_property(enemy_actor_anchor, "modulate", _enemy_poison_modulate(), recoil_back_sec)
	_enemy_tween.tween_callback(func(): _set_enemy_animation("idle"))


func _play_static_enemy_hit_reaction(delay_sec: float, is_crit: bool) -> void:
	var flash_color := UIColors.COMBAT_CRIT_FLASH if is_crit else UIColors.COMBAT_HIT_FLASH
	var shake_px := 9.0 if is_crit else 8.0
	last_enemy_recoil_distance_px = shake_px
	_enemy_tween = create_tween()
	_enemy_tween.tween_interval(delay_sec)
	_enemy_tween.tween_callback(func(): _set_enemy_animation("hurt"))
	_enemy_tween.tween_property(enemy_actor_anchor, "modulate", flash_color, 0.045)
	_enemy_tween.parallel().tween_property(enemy_actor_anchor, "position", _enemy_base_position + Vector2(shake_px, -2.0), 0.045)
	_enemy_tween.tween_property(enemy_actor_anchor, "position", _enemy_base_position + Vector2(-shake_px * 0.7, 2.0), 0.055)
	_enemy_tween.tween_property(enemy_actor_anchor, "position", _enemy_base_position + Vector2(shake_px * 0.35, 0.0), 0.045)
	_enemy_tween.tween_property(enemy_actor_anchor, "position", _enemy_base_position, 0.07)
	_enemy_tween.parallel().tween_property(enemy_actor_anchor, "modulate", _enemy_poison_modulate(), 0.11)
	_enemy_tween.tween_callback(func(): _set_enemy_animation("idle"))


func _play_practice_dummy_reaction(delay_sec: float) -> void:
	if PRACTICE_DUMMY_REACTION_FRAME_PATHS.is_empty():
		return
	var reaction_index := _effect_rng.randi_range(0, PRACTICE_DUMMY_REACTION_FRAME_PATHS.size() - 1)
	var frames: Array = PRACTICE_DUMMY_REACTION_FRAME_PATHS[reaction_index]
	if frames.is_empty():
		return
	practice_dummy_reaction_count += 1
	last_practice_dummy_reaction_index = reaction_index
	last_practice_dummy_reaction_frame_count = frames.size()
	_enemy_tween = create_tween()
	if delay_sec > 0.0:
		_enemy_tween.tween_interval(delay_sec)
	_enemy_tween.tween_callback(func():
		if enemy_actor_anchor != null:
			enemy_actor_anchor.position = _enemy_base_position
	)
	for frame_path in frames:
		var path := String(frame_path)
		_enemy_tween.tween_callback(_apply_enemy_frame_path.bind(path))
		_enemy_tween.tween_interval(PRACTICE_DUMMY_REACTION_FRAME_SEC)
	_enemy_tween.tween_callback(func(): _set_enemy_animation("idle"))


func _play_bandit_coin_spray(delay_sec: float, is_crit: bool) -> void:
	var coin_count := BANDIT_COIN_CRIT_COUNT if is_crit else BANDIT_COIN_NORMAL_COUNT
	bandit_coin_spray_count += 1
	last_bandit_coin_count = coin_count
	if enemy_actor_anchor == null:
		return
	var impact_position := _bandit_coin_impact_position()
	var generation := _effect_generation
	if delay_sec > 0.0:
		var contact_tween := create_tween()
		contact_tween.tween_interval(delay_sec)
		contact_tween.tween_callback(func():
			if generation == _effect_generation:
				_spawn_bandit_coin_particles(coin_count, impact_position)
		)
		return
	_spawn_bandit_coin_particles(coin_count, impact_position)


func _spawn_bandit_coin_particles(coin_count: int, impact_position: Vector2) -> void:
	for index in coin_count:
		var coin := TextureRect.new()
		coin.name = "BanditCoinParticle"
		coin.texture = BANDIT_COIN_TEXTURE
		coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var coin_size := _effect_rng.randf_range(BANDIT_COIN_SIZE_RANGE.x, BANDIT_COIN_SIZE_RANGE.y)
		coin.size = Vector2(coin_size, coin_size)
		coin.pivot_offset = coin.size * 0.5
		coin.position = impact_position - coin.pivot_offset + Vector2(
			_effect_rng.randf_range(-5.0, 5.0),
			_effect_rng.randf_range(-5.0, 5.0)
		)
		coin.rotation = _effect_rng.randf_range(-0.7, 0.7)
		coin.modulate = Color(1.0, _effect_rng.randf_range(0.78, 0.94), 0.34, BANDIT_COIN_START_ALPHA)
		coin.z_index = 30
		add_child(coin)

		var drift := Vector2(
			_effect_rng.randf_range(BANDIT_COIN_SPREAD_X_RANGE.x, BANDIT_COIN_SPREAD_X_RANGE.y),
			_effect_rng.randf_range(BANDIT_COIN_SPREAD_Y_RANGE.x, BANDIT_COIN_SPREAD_Y_RANGE.y)
		)
		var tween := coin.create_tween()
		tween.set_parallel(true)
		tween.tween_property(coin, "position", coin.position + drift, BANDIT_COIN_LIFETIME_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(coin, "rotation", coin.rotation + _effect_rng.randf_range(-1.3, 1.3), BANDIT_COIN_LIFETIME_SEC)
		tween.tween_property(coin, "modulate:a", 0.0, BANDIT_COIN_LIFETIME_SEC - BANDIT_COIN_FADE_DELAY_SEC).set_delay(BANDIT_COIN_FADE_DELAY_SEC)
		tween.finished.connect(coin.queue_free)


func _bandit_coin_impact_position() -> Vector2:
	if _enemy_sprite != null and _enemy_sprite.visible and _enemy_sprite.texture != null:
		return _sprite_anchor_point(enemy_actor_anchor, _enemy_sprite, PEASANT_ANCHOR_POINT) + BANDIT_COIN_SPRITE_CONTACT_OFFSET + _enemy_hit_effect_offset()
	return enemy_actor_anchor.position + BANDIT_COIN_FALLBACK_IMPACT_OFFSET + _enemy_hit_effect_offset()


func _clear_bandit_coin_particles() -> void:
	for child in get_children():
		var child_name := String(child.name)
		if child_name.begins_with("BanditCoinParticle") or child_name.begins_with("MechanicText") or child_name.begins_with("CleanseBurstEffect") or child_name.begins_with("InterruptSlashEffect") or child_name.begins_with("DodgeAfterimage"):
			remove_child(child)
			child.queue_free()


func _spawn_dodge_afterimages() -> void:
	if enemy_actor_anchor == null or _enemy_sprite == null or not _enemy_sprite.visible or _enemy_sprite.texture == null:
		return
	for offset in DODGE_AFTERIMAGE_OFFSETS:
		var ghost := TextureRect.new()
		ghost.name = "DodgeAfterimage"
		ghost.texture = _enemy_sprite.texture
		ghost.size = _enemy_sprite.size
		ghost.scale = _enemy_sprite.scale
		ghost.pivot_offset = _enemy_sprite.pivot_offset
		ghost.position = enemy_actor_anchor.position + _enemy_sprite.position + offset
		ghost.flip_h = _enemy_sprite.flip_h
		ghost.expand_mode = _enemy_sprite.expand_mode
		ghost.stretch_mode = _enemy_sprite.stretch_mode
		ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ghost.modulate = Color(0.78, 0.9, 1.0, DODGE_AFTERIMAGE_ALPHA)
		ghost.z_index = enemy_actor_anchor.z_index + 1
		add_child(ghost)
		dodge_afterimage_count += 1
		var drift: Vector2 = offset.normalized() * 10.0 if offset.length() > 0.0 else Vector2(0.0, -8.0)
		var tween := ghost.create_tween()
		tween.set_parallel(true)
		tween.tween_property(ghost, "position", ghost.position + drift, DODGE_AFTERIMAGE_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(ghost, "modulate:a", 0.0, DODGE_AFTERIMAGE_SEC)
		tween.finished.connect(ghost.queue_free)


func _play_dodge_shift() -> void:
	if enemy_actor_anchor == null:
		return
	_kill_enemy_tween(true)
	_enemy_tween = create_tween()
	_enemy_tween.tween_property(enemy_actor_anchor, "position", _enemy_base_position + DODGE_SHIFT_OFFSET, DODGE_SHIFT_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_enemy_tween.tween_property(enemy_actor_anchor, "position", _enemy_base_position, DODGE_SHIFT_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _spawn_mechanic_text(text: String, center: Vector2, color: Color, animate: bool = true) -> void:
	mechanic_text_count += 1
	last_mechanic_text = text
	if not animate:
		return
	var label := Label.new()
	label.name = "MechanicText"
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", MECHANIC_TEXT_FONT)
	label.add_theme_font_size_override("font_size", MECHANIC_TEXT_FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", UIColors.TEXT_OUTLINE_STRONG)
	label.add_theme_constant_override("outline_size", 5)
	label.size = Vector2(132, 34)
	label.position = center - label.size * 0.5
	label.z_index = 32
	add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0.0, -MECHANIC_TEXT_RISE_PX), MECHANIC_TEXT_FLOAT_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, MECHANIC_TEXT_FLOAT_SEC * 0.55).set_delay(MECHANIC_TEXT_FLOAT_SEC * 0.45)
	tween.finished.connect(label.queue_free)


func _enemy_effect_anchor_point() -> Vector2:
	if enemy_actor_anchor == null:
		return Vector2.ZERO
	if _enemy_sprite != null and _enemy_sprite.visible:
		return enemy_actor_anchor.position + _sprite_render_top_left(_enemy_sprite) + _enemy_sprite.size * _enemy_sprite.scale * 0.5 + _enemy_hit_effect_offset()
	return enemy_actor_anchor.position + ACTOR_SIZE * 0.5 + _enemy_hit_effect_offset()


func _enemy_hit_effect_offset() -> Vector2:
	return Vector2.ZERO if _is_practice_dummy_target() else ADVENTURE_ENEMY_HIT_EFFECT_OFFSET


func _player_effect_anchor_point() -> Vector2:
	if player_actor_anchor == null:
		return Vector2.ZERO
	if _player_sprite != null and _player_sprite.visible:
		return player_actor_anchor.position + _sprite_render_top_left(_player_sprite) + _player_sprite.size * _player_sprite.scale * 0.5 + INTERRUPT_PLAYER_EFFECT_OFFSET
	return player_actor_anchor.position + ACTOR_SIZE * 0.5 + INTERRUPT_PLAYER_EFFECT_OFFSET


func _play_cleanse_enemy_flash() -> void:
	if enemy_actor_anchor == null:
		return
	var previous_enemy_tween := _enemy_tween
	var tween := create_tween()
	_enemy_tween = tween
	tween.tween_callback(func():
		if previous_enemy_tween != null and previous_enemy_tween.is_valid():
			previous_enemy_tween.kill()
	)
	tween.tween_property(enemy_actor_anchor, "modulate", Color(0.78, 0.92, 1.0, 1.0), 0.08)
	tween.tween_property(enemy_actor_anchor, "modulate", _enemy_poison_modulate(), 0.18)


func _play_interrupt_player_flash() -> void:
	if player_actor_anchor == null:
		return
	var previous_player_tween := _player_tween
	var tween := create_tween()
	_player_tween = tween
	tween.tween_callback(func():
		if previous_player_tween != null and previous_player_tween.is_valid():
			previous_player_tween.kill()
	)
	tween.tween_property(player_actor_anchor, "modulate", Color(1.0, 0.42, 0.34, 1.0), 0.06)
	tween.tween_property(player_actor_anchor, "position", _player_base_position + Vector2(-10.0, 0.0), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(player_actor_anchor, "modulate", Color.WHITE, 0.16)
	tween.tween_property(player_actor_anchor, "position", _player_base_position, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)


func _restore_actor_layout() -> void:
	if player_actor_anchor != null:
		player_actor_anchor.position = _player_base_position
		player_actor_anchor.modulate = Color.WHITE
	if enemy_actor_anchor != null:
		enemy_actor_anchor.position = _enemy_base_position
		enemy_actor_anchor.modulate = _enemy_poison_modulate()


func _clear_status_visuals() -> void:
	last_poison_stack_tint_stacks = 0
	outcome_pose = ""
	_clear_stun_effect()
	_clear_slow_effect()
	_clear_bandit_coin_particles()
	if player_actor_anchor != null:
		player_actor_anchor.modulate = Color.WHITE
	if enemy_actor_anchor != null:
		enemy_actor_anchor.modulate = Color.WHITE
func _enemy_poison_modulate() -> Color:
	if last_poison_stack_tint_stacks <= 0:
		return Color.WHITE
	var intensity := clampf(float(last_poison_stack_tint_stacks) / float(POISON_VISIBLE_STACK_CAP), 0.0, 1.0)
	return Color(lerpf(0.9, 0.46, intensity), 1.0, lerpf(0.9, 0.52, intensity), 1.0)


func _clear_stun_effect() -> void:
	if _stun_stars_effect != null:
		if is_instance_valid(_stun_stars_effect):
			if _stun_stars_effect.get_parent() != null:
				_stun_stars_effect.get_parent().remove_child(_stun_stars_effect)
			_stun_stars_effect.queue_free()
		_stun_stars_effect = null
	_player_stun_freeze_until_msec = 0


func _clear_slow_effect() -> void:
	if _slow_aura_effect != null:
		if is_instance_valid(_slow_aura_effect):
			if _slow_aura_effect.get_parent() != null:
				_slow_aura_effect.get_parent().remove_child(_slow_aura_effect)
			_slow_aura_effect.queue_free()
		_slow_aura_effect = null


func _freeze_player_idle_for_stun(duration_ms: int, animate: bool) -> void:
	if _player_sprite == null:
		return
	_set_player_animation("idle", false)
	if not animate:
		return
	_player_stun_freeze_until_msec = Time.get_ticks_msec() + duration_ms
	_player_animation_playing = true
	set_process(true)


func _play_stun_jolt() -> void:
	if player_actor_anchor == null:
		return
	var previous_player_tween := _player_tween
	var tween := create_tween()
	_player_tween = tween
	tween.tween_callback(func():
		if previous_player_tween != null and previous_player_tween.is_valid():
			previous_player_tween.kill()
	)
	tween.tween_property(player_actor_anchor, "position", _player_base_position + STUN_JOLT_OFFSET, STUN_JOLT_SEC)
	tween.tween_property(player_actor_anchor, "position", _player_base_position - STUN_JOLT_OFFSET * 0.5, STUN_JOLT_SEC)
	tween.tween_property(player_actor_anchor, "position", _player_base_position, STUN_JOLT_SEC)


func _kill_actor_tweens() -> void:
	if _player_tween != null and _player_tween.is_valid():
		_player_tween.kill()
	if _enemy_tween != null and _enemy_tween.is_valid():
		_enemy_tween.kill()


func _kill_player_tween() -> void:
	if _player_tween != null and _player_tween.is_valid():
		_player_tween.kill()


func _kill_enemy_tween(restore_position: bool = false) -> void:
	if _enemy_tween != null and _enemy_tween.is_valid():
		_enemy_tween.kill()
	if restore_position and enemy_actor_anchor != null:
		enemy_actor_anchor.position = _enemy_base_position


func _layout_stage() -> void:
	if player_actor_anchor == null:
		return
	var stage_size := _effective_stage_size()
	if stage_size.x <= 0.0 or stage_size.y <= 0.0:
		return

	var previous_player_base := _player_base_position
	var previous_enemy_base := _enemy_base_position
	var previous_player_position := player_actor_anchor.position
	var previous_enemy_position := enemy_actor_anchor.position
	var practice_dummy := _is_practice_dummy_target()
	var enemy_offset := PRACTICE_DUMMY_STAGE_OFFSET if practice_dummy else ACTOR_GROUP_STAGE_OFFSET_PX
	var enemy_grid := PRACTICE_DUMMY_STAGE_GRID if practice_dummy else ENEMY_STAGE_GRID
	var player_position := _actor_position_for_grid(stage_size, PLAYER_STAGE_GRID, Vector2(ROGUE_FRAME_SIZE), ROGUE_ANCHOR_POINT, ROGUE_SPRITE_SCALE, ACTOR_GROUP_STAGE_OFFSET_PX)
	var enemy_position := _actor_position_for_grid(stage_size, enemy_grid, _enemy_layout_frame_size(), _enemy_anchor_point(), _enemy_sprite_scale(), enemy_offset)
	var actor_y := minf(player_position.y, enemy_position.y)

	player_actor_anchor.position = player_position
	enemy_actor_anchor.position = enemy_position
	_player_base_position = player_actor_anchor.position
	_enemy_base_position = enemy_actor_anchor.position
	_apply_outcome_pose_position_after_layout(previous_player_base, previous_enemy_base, previous_player_position, previous_enemy_position)
	if _player_exited_right and player_actor_anchor != null:
		player_actor_anchor.position = _player_offscreen_right_position()
		player_actor_anchor.visible = false
	contact_effect_anchor.position = Vector2(stage_size.x * 0.5 - CONTACT_SIZE.x * 0.5 + ACTOR_GROUP_STAGE_OFFSET_PX.x, actor_y + ACTOR_SIZE.y * 0.35)
	floating_text_anchor.position = Vector2(stage_size.x * 0.5 - CONTACT_SIZE.x * 0.5 + ACTOR_GROUP_STAGE_OFFSET_PX.x, maxf(safe_top_px, actor_y - CONTACT_SIZE.y * 0.75))
	var stun_star_anchor_point := Vector2(player_position.x + ACTOR_SIZE.x * 0.5, _stage_point_for_grid(Vector2(PLAYER_STAGE_GRID.x, STUN_STAR_STAGE_GRID_Y)).y)
	player_status_anchor.position = stun_star_anchor_point - StunStarsEffect.ORBIT_CENTER
	enemy_status_anchor.position = Vector2(enemy_position.x + ACTOR_SIZE.x * 0.5 - STATUS_SIZE.x * 0.5, maxf(safe_top_px, enemy_position.y - STATUS_SIZE.y - 8.0))
	if _slow_aura_effect != null and is_instance_valid(_slow_aura_effect):
		_slow_aura_effect.position = _slow_aura_position()
	if _debug_grid_overlay != null:
		_debug_grid_overlay.queue_redraw()


func _stun_star_anchor_point() -> Vector2:
	if player_status_anchor == null:
		return Vector2.ZERO
	return player_status_anchor.position + StunStarsEffect.ORBIT_CENTER


func _slow_snow_field_rect() -> Rect2:
	if player_actor_anchor == null:
		return Rect2()
	var aura_position := player_actor_anchor.position + _slow_aura_position()
	var snow_position := aura_position + Vector2(24.0, 16.0)
	var snow_size := Vector2(maxf(SLOW_AURA_SIZE.x - 48.0, 0.0), SLOW_AURA_SIZE.y * 0.66 - 16.0)
	return Rect2(snow_position, snow_size)


func _slow_aura_position() -> Vector2:
	if player_actor_anchor == null:
		return Vector2(SLOW_AURA_OFFSET_X, 0.0)
	var snow_center_local := _slow_snow_center_local()
	var target_y := _stage_point_for_grid(Vector2(PLAYER_STAGE_GRID.x, SLOW_SNOW_STAGE_GRID_Y)).y
	return Vector2(SLOW_AURA_OFFSET_X, target_y - player_actor_anchor.position.y - snow_center_local.y)


func _slow_snow_center_local() -> Vector2:
	var snow_size := Vector2(maxf(SLOW_AURA_SIZE.x - 48.0, 0.0), SLOW_AURA_SIZE.y * 0.66 - 16.0)
	return Vector2(24.0, 16.0) + snow_size * 0.5


func _apply_outcome_pose_position_after_layout(
	previous_player_base: Vector2,
	previous_enemy_base: Vector2,
	previous_player_position: Vector2,
	previous_enemy_position: Vector2
) -> void:
	if outcome_pose == OUTCOME_VICTORY and enemy_actor_anchor != null:
		if _is_practice_dummy_target():
			return
		enemy_actor_anchor.position = _enemy_base_position + (previous_enemy_position - previous_enemy_base)
	elif outcome_pose == OUTCOME_DEFEAT and player_actor_anchor != null:
		player_actor_anchor.position = _player_base_position + (previous_player_position - previous_player_base)


## The ordinary opening attack belongs to the main actor. All extra
## contacts use one faded copy; logical events/health remain in playback.
func play_retrigger_event(event: CombatPlayback.PlaybackEvent, playback_speed: float, animate: bool) -> void:
	if not event.visual_beat: return
	if event.chain_index == 1:
		play_cast_impact(event.cast, animate, false)
		return
	_clear_flurry()
	_kill_player_tween()
	player_actor_anchor.position = _player_base_position
	player_actor_anchor.modulate = Color.WHITE
	_set_player_animation("idle", animate)
	if event.cast.was_dodged:
		play_dodge_effect(animate)
		return
	if event.cast.was_interrupted:
		play_interrupt_effect(animate, true)
		return
	if not animate or event.cast.resource_unavailable or event.cast.cooldown_blocked:
		return
	# Zero-damage status casts may attack, but Hold/failed attempts do not
	# impersonate successful weapon contacts.
	var kind := animation_kind_for_cast(event.cast)
	if kind == ANIMATION_HOLD: return
	var animation := _player_animation_for_key(_player_animation_key_for_kind(kind))
	var frames: Array = animation.get("frames", [])
	if frames.is_empty(): return
	if not is_instance_valid(_retrigger_ghost):
		_retrigger_ghost = RetriggerGhost.new()
		_retrigger_ghost.name = "RetriggerGhost"
		_retrigger_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_retrigger_ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_retrigger_ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_retrigger_ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_retrigger_ghost.z_index = 28
		var shader := Shader.new()
		shader.code = "shader_type canvas_item; void fragment() { float l = dot(COLOR.rgb, vec3(0.299,0.587,0.114)); COLOR.rgb = mix(COLOR.rgb, vec3(l), 0.28); }"
		var ghost_material := ShaderMaterial.new()
		ghost_material.shader = shader
		_retrigger_ghost.material = ghost_material
		add_child(_retrigger_ghost)
	_retrigger_ghost.textures.clear()
	for index in range(maxi(frames.size() - 2, 0), frames.size()):
		var frame: Dictionary = frames[index]
		var texture := _texture_from_path(frame.get("path", ""))
		if texture != null: _retrigger_ghost.textures.append(texture)
	if _retrigger_ghost.textures.is_empty(): return
	_retrigger_ghost.texture = _retrigger_ghost.textures[0]
	_retrigger_ghost.size = _retrigger_ghost.texture.get_size()
	_retrigger_ghost.scale = Vector2(ROGUE_SPRITE_SCALE, ROGUE_SPRITE_SCALE)
	_retrigger_ghost.pivot_offset = _retrigger_ghost.size * 0.5
	var side := -1.0 if event.chain_index % 2 == 0 else 1.0
	var target := _flurry_contact_point() + Vector2(-70.0 + side * 8.0, 12.0 + side * 4.0)
	_retrigger_ghost.start_position = target - ACTOR_LOCAL_ANCHOR + _sprite_position_for_anchor(_retrigger_ghost.size, animation.get("anchor_point", ROGUE_ANCHOR_POINT), ROGUE_SPRITE_SCALE)
	_retrigger_ghost.position = _retrigger_ghost.start_position
	_retrigger_ghost.drift = Vector2(12.0, side * -3.0)
	_retrigger_ghost.duration = maxf(RETRIGGER_GHOST_MIN_REAL_SEC, RETRIGGER_GHOST_SEC / maxf(playback_speed, 0.01))
	_retrigger_ghost.elapsed = 0.0
	_retrigger_ghost.modulate = Color(0.9, 0.92, 0.95, 0.48)
	_retrigger_ghost.show()
	_retrigger_ghost.set_process(true)
	play_cast_impact(event.cast, true, false)


func _clear_flurry() -> void:
	if is_instance_valid(_retrigger_ghost): _retrigger_ghost.stop()


func _flurry_contact_point() -> Vector2:
	# Imported frames include transparent margins; use the visible target.
	if _enemy_sprite == null or _enemy_sprite.texture == null:
		return _enemy_effect_anchor_point() - _enemy_hit_effect_offset()
	var texture := _enemy_sprite.texture
	var key := texture.get_instance_id()
	if not _flurry_contact_centers.has(key):
		var pixels := texture.get_image()
		var visible_rect := pixels.get_used_rect() if pixels != null else Rect2i()
		_flurry_contact_centers[key] = Vector2(visible_rect.position) + Vector2(visible_rect.size) * 0.5 if visible_rect.has_area() else texture.get_size() * 0.5
	var center: Vector2 = _flurry_contact_centers[key]
	if _enemy_sprite.flip_h: center.x = texture.get_width() - center.x
	return enemy_actor_anchor.position + _sprite_render_top_left(_enemy_sprite) + center * _enemy_sprite.scale
