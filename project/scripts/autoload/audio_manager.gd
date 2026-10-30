extends Node

const SETTINGS_PATH := "user://audio_settings.cfg"
const MENU_RAIN_PATH := "res://assets/audio/music/rain_storm.mp3"
const MENU_THEME_PATH := "res://assets/audio/music/epic_theme.mp3"
const TAVERN_FIREPLACE_PATH := "res://assets/audio/music/fireplace.mp3"
const TAVERN_CHATTER_PATH := "res://assets/audio/music/chatter.mp3"
const TAVERN_THEME_PATH := "res://assets/audio/music/tavern_theme.mp3"
const CONTRACT_NIGHT_PATH := "res://assets/audio/music/night_time.mp3"
const CONTRACT_SERPENT_THEME_PATH := "res://assets/audio/music/serpent_theme.mp3"
const BIOME_MOOD_PATHS := {
	"Swamp": "res://assets/audio/music/biomes/swamp_mood.mp3",
	"Cave": "res://assets/audio/music/biomes/cave_mood.mp3",
	"Graveyard": "res://assets/audio/music/biomes/graveyard_mood.mp3",
	"Haunted Forest": "res://assets/audio/music/biomes/haunted_forest_mood.mp3",
	"Ruined Keep": MENU_RAIN_PATH,
	"Ancient Ruins": "res://assets/audio/music/biomes/ancient_ruins_mood.mp3",
}
const BIOME_MUSIC_PATHS := {
	"Swamp": "res://assets/audio/music/biomes/swamp_music.mp3",
	"Cave": "res://assets/audio/music/biomes/cave_music.mp3",
	"Graveyard": "res://assets/audio/music/biomes/graveyard_music.mp3",
	"Haunted Forest": "res://assets/audio/music/biomes/haunted_forest_music.mp3",
	"Ruined Keep": "res://assets/audio/music/biomes/ruined_keep_music.mp3",
	"Ancient Ruins": "res://assets/audio/music/biomes/ancient_ruins_music.mp3",
}
const BUTTON_PRESS_SFX_PATH := "res://assets/audio/fx/button_press.mp3"
const SHOP_CHANGE_SFX_PATH := "res://assets/audio/fx/change.mp3"
const MAGIC_FIND_SFX_PATH := "res://assets/audio/fx/magic_find.mp3"
const MAGIC_FIND_SFX_POOL_SIZE := 8
const MAGIC_FIND_SFX_BASE_VOLUME := 0.36
const MAGIC_FIND_SFX_VOLUME_VARIATION := 0.04
const MAGIC_FIND_SFX_PITCH_VARIATION := 0.04
const FOOTSTEPS_SFX_PATH := "res://assets/audio/fx/footsteps.mp3"
const DODGE_SFX_PATH := "res://assets/audio/fx/sword/sword_swing.mp3"
const CATEGORY_SFX_PATHS := {
	Skill.Category.SELF_BUFF: "res://assets/audio/fx/skills/self_buff.mp3",
	Skill.Category.DEBUFF: "res://assets/audio/fx/skills/debuff.mp3",
}
const EXSANGUINATE_SFX_PATH := "res://assets/audio/fx/skills/exsanguinate.mp3"
const SKILL_SFX_PATHS := {
	"skill.poison_vile": "res://assets/audio/fx/skills/poison_vile.mp3",
	"skill.blinding_powder": "res://assets/audio/fx/skills/blinding_powder.mp3",
	"skill.pick_pocket": "res://assets/audio/fx/skills/pick_pocket.mp3",
}
const GOLD_STEAL_SFX_PATH := "res://assets/audio/fx/skills/gold_steal.mp3"
const CATEGORY_SFX_BASE_VOLUME := 0.64
const CATEGORY_SFX_VOLUME_VARIATION := 0.04
const CATEGORY_SFX_PITCH_VARIATION := 0.04
const ATTACK_SFX_PATHS := [
	"res://assets/audio/fx/sword/sword_block.mp3",
	"res://assets/audio/fx/sword/sword_clash_hit.mp3",
	"res://assets/audio/fx/sword/sword_cut_1.mp3",
	"res://assets/audio/fx/sword/sword_cut_2.mp3",
	"res://assets/audio/fx/sword/sword_slice.mp3",
]

const MUSIC_BUS := "Music"
const EFFECTS_BUS := "Effects"

const DEFAULT_MASTER_VOLUME := 0.8
const DEFAULT_MUSIC_VOLUME := 0.55
const DEFAULT_EFFECTS_VOLUME := 0.8
const RAIN_MIX_VOLUME := 0.32
const THEME_MIX_VOLUME := 0.88
const TAVERN_FIREPLACE_MIX_VOLUME := 0.34
const TAVERN_CHATTER_MIX_VOLUME := 0.22
const TAVERN_THEME_MIX_VOLUME := 0.16
const TAVERN_INTRO_MENU_FADE_SECONDS := 2.4
const TAVERN_INTRO_AMBIENCE_FADE_SECONDS := 1.0
const TAVERN_INTRO_THEME_LEAD_SECONDS := 0.85
const CONTRACT_NIGHT_MIX_VOLUME := 0.30
const CONTRACT_SERPENT_THEME_MIX_VOLUME := 0.15
const BIOME_MOOD_MIX_VOLUME := 0.30
const BIOME_MUSIC_MIX_VOLUME := 0.34
const BIOME_MOOD_FADE_SECONDS := 0.65
const BIOME_MUSIC_LEAD_SECONDS := 1.0
const CONTRACT_ENTRY_FADE_SECONDS := 2.4
const DEFAULT_FADE_SECONDS := 1.4
const ATTACK_SFX_POOL_SIZE := 8
const ATTACK_SFX_BASE_VOLUME := 0.72
const ATTACK_SFX_VOLUME_VARIATION := 0.16
const ATTACK_SFX_PITCH_VARIATION := 0.08
const ATTACK_SFX_REFERENCE_CAST_MS := 900.0
const ATTACK_SFX_MIN_TIMING_FACTOR := 0.84
const ATTACK_SFX_MAX_TIMING_FACTOR := 1.18
const ATTACK_SFX_MIN_PITCH_SCALE := 0.55
const ATTACK_SFX_MAX_PITCH_SCALE := 2.65
const ATTACK_SFX_PROC_OFFSET_SEC := 0.075
const BUTTON_PRESS_SFX_POOL_SIZE := 8
const BUTTON_PRESS_SFX_VOLUME := 0.48
const SHOP_CHANGE_SFX_VOLUME := 0.64
const SHOP_CHANGE_SFX_PITCH_SCALE := 0.82
const FOOTSTEPS_SFX_VOLUME := 0.54
const FOOTSTEPS_SFX_PITCH_SCALE := 1.0
const BUTTON_PRESS_SFX_META := "audio_manager_button_press_sfx_connected"
const AUDIO_SCENE_NONE := "none"
const AUDIO_SCENE_MENU := "menu"
const AUDIO_SCENE_TAVERN := "tavern"
const AUDIO_SCENE_CONTRACT := "contract"

var master_volume := DEFAULT_MASTER_VOLUME
var music_volume := DEFAULT_MUSIC_VOLUME
var effects_volume := DEFAULT_EFFECTS_VOLUME

var _rain_player: AudioStreamPlayer
var _theme_player: AudioStreamPlayer
var _fireplace_player: AudioStreamPlayer
var _chatter_player: AudioStreamPlayer
var _tavern_theme_player: AudioStreamPlayer
var _night_player: AudioStreamPlayer
var _serpent_theme_player: AudioStreamPlayer
var _biome_mood_player: AudioStreamPlayer
var _biome_music_player: AudioStreamPlayer
var _button_press_stream: AudioStreamMP3
var _shop_change_stream: AudioStreamMP3
var _magic_find_stream: AudioStreamMP3
var _magic_find_sfx_players: Array[AudioStreamPlayer] = []
var _magic_find_sfx_player_index := 0
var _footsteps_stream: AudioStreamMP3
var _button_sfx_players: Array[AudioStreamPlayer] = []
var _button_sfx_player_index := 0
var _shop_change_player: AudioStreamPlayer
var _footsteps_player: AudioStreamPlayer
var _footsteps_generation := 0
var _last_button_sfx_frame_by_instance: Dictionary = {}
var _button_down_sfx_consumed_by_instance: Dictionary = {}
var _attack_sfx_streams: Array[AudioStreamMP3] = []
var _dodge_sfx_stream: AudioStreamMP3
var _category_sfx_streams: Dictionary = {}
var _exsanguinate_sfx_stream: AudioStreamMP3
var _skill_sfx_streams := {}
var _gold_steal_sfx_stream: AudioStreamMP3
var skill_sfx_play_counts := {}
var gold_steal_sfx_play_count := 0
var exsanguinate_sfx_play_count := 0
var last_exsanguinate_sfx_pitch_scale := 0.0
var _attack_sfx_players: Array[AudioStreamPlayer] = []
var _attack_sfx_player_index := 0
var _rain_tween: Tween
var _theme_tween: Tween
var _fireplace_tween: Tween
var _chatter_tween: Tween
var _tavern_theme_tween: Tween
var _night_tween: Tween
var _serpent_theme_tween: Tween
var _biome_mood_tween: Tween
var _biome_music_tween: Tween
var _rng := RandomNumberGenerator.new()
var _combat_sfx_generation := 0
var _web_audio_unlocked := true
var _pending_audio_scene := AUDIO_SCENE_NONE
var _pending_contract_biome := ""
var _current_contract_biome := ""
var _contract_transition_id := 0

var attack_sfx_play_count := 0
var dodge_sfx_play_count := 0
var category_sfx_play_count := 0
var self_buff_sfx_play_count := 0
var debuff_sfx_play_count := 0
var last_category_sfx_category := -1
var last_category_sfx_pitch_scale := 0.0
var last_category_sfx_volume_db := 0.0
var last_attack_sfx_pitch_scale := 0.0
var last_attack_sfx_volume_db := 0.0
var last_attack_sfx_cast_duration_ms := 0
var last_attack_sfx_playback_speed := 0.0
var last_attack_sfx_hit_count := 0
var last_attack_sfx_proc_hit_count := 0
var button_press_sfx_play_count := 0
var shop_change_sfx_play_count := 0
var magic_find_sfx_play_count := 0
var last_magic_find_sfx_pitch_scale := 0.0
var last_magic_find_sfx_volume_db := 0.0
var footsteps_sfx_play_count := 0
var last_shop_change_pitch_scale := 0.0
var last_footsteps_duration_sec := 0.0


func _ready() -> void:
	_rng.randomize()
	_web_audio_unlocked = not OS.has_feature("web")
	set_process_input(OS.has_feature("web"))
	_ensure_audio_buses()
	_load_settings()
	_apply_all_bus_volumes()
	_build_music_players()
	_build_attack_sfx_pool()
	_build_ui_sfx_players()
	_connect_existing_button_sfx()
	if not get_tree().node_added.is_connected(_on_tree_node_added):
		get_tree().node_added.connect(_on_tree_node_added)


func _input(event: InputEvent) -> void:
	if _web_audio_unlocked or not _is_audio_unlock_input(event):
		return
	_unlock_web_audio()


func play_menu_intro_audio() -> void:
	_pending_audio_scene = AUDIO_SCENE_MENU
	_pending_contract_biome = ""
	if _should_wait_for_web_audio_unlock():
		return
	_apply_audio_scene(AUDIO_SCENE_MENU)


func play_tavern_map_rain() -> void:
	transition_to_tavern_ambience()


func transition_to_tavern_intro_ambience() -> void:
	_pending_audio_scene = AUDIO_SCENE_TAVERN
	_pending_contract_biome = ""
	if _should_wait_for_web_audio_unlock():
		return
	_transition_to_tavern_intro_ambience_now()


func transition_to_tavern_ambience(fade_seconds: float = DEFAULT_FADE_SECONDS) -> void:
	_pending_audio_scene = AUDIO_SCENE_TAVERN
	_pending_contract_biome = ""
	if _should_wait_for_web_audio_unlock():
		return
	_apply_audio_scene(AUDIO_SCENE_TAVERN, fade_seconds)


func transition_to_contract_ambience(fade_seconds: float = CONTRACT_ENTRY_FADE_SECONDS) -> void:
	_pending_audio_scene = AUDIO_SCENE_CONTRACT
	_pending_contract_biome = ""
	if _should_wait_for_web_audio_unlock():
		return
	_apply_audio_scene(AUDIO_SCENE_CONTRACT, fade_seconds)


func transition_to_contract_biome_ambience(biome: String, fade_seconds: float = CONTRACT_ENTRY_FADE_SECONDS) -> void:
	var resolved_biome := _normalized_biome_audio_key(biome)
	if _is_current_contract_biome_ambience(resolved_biome):
		return
	_pending_audio_scene = AUDIO_SCENE_CONTRACT
	_pending_contract_biome = resolved_biome
	if _should_wait_for_web_audio_unlock():
		return
	_apply_audio_scene(AUDIO_SCENE_CONTRACT, fade_seconds)


func fade_out_menu_theme(fade_seconds: float = DEFAULT_FADE_SECONDS) -> void:
	_fade_out_player(_theme_player, "_theme_tween", fade_seconds)


func fade_out_menu_rain(fade_seconds: float = DEFAULT_FADE_SECONDS) -> void:
	_fade_out_player(_rain_player, "_rain_tween", fade_seconds)


func fade_out_all_menu_audio(fade_seconds: float = DEFAULT_FADE_SECONDS) -> void:
	_pending_audio_scene = AUDIO_SCENE_NONE
	_pending_contract_biome = ""
	if _should_wait_for_web_audio_unlock():
		return
	_apply_audio_scene(AUDIO_SCENE_NONE, fade_seconds)


func fade_out_tavern_ambience(fade_seconds: float = DEFAULT_FADE_SECONDS) -> void:
	_fade_out_player(_fireplace_player, "_fireplace_tween", fade_seconds)
	_fade_out_player(_chatter_player, "_chatter_tween", fade_seconds)
	_fade_out_player(_tavern_theme_player, "_tavern_theme_tween", fade_seconds)


func fade_out_contract_ambience(fade_seconds: float = DEFAULT_FADE_SECONDS, include_rain: bool = true) -> void:
	_contract_transition_id += 1
	_current_contract_biome = ""
	if include_rain:
		fade_out_menu_rain(fade_seconds)
	_fade_out_player(_night_player, "_night_tween", fade_seconds)
	_fade_out_player(_serpent_theme_player, "_serpent_theme_tween", fade_seconds)
	_fade_out_player(_biome_mood_player, "_biome_mood_tween", fade_seconds)
	_fade_out_player(_biome_music_player, "_biome_music_tween", fade_seconds)


func _apply_audio_scene(audio_scene: String, fade_seconds: float = DEFAULT_FADE_SECONDS) -> void:
	if audio_scene == AUDIO_SCENE_MENU:
		_play_menu_intro_audio_now()
	elif audio_scene == AUDIO_SCENE_TAVERN:
		_transition_to_tavern_ambience_now(fade_seconds)
	elif audio_scene == AUDIO_SCENE_CONTRACT:
		if _pending_contract_biome != "":
			_transition_to_contract_biome_ambience_now(_pending_contract_biome, fade_seconds)
		else:
			_transition_to_contract_ambience_now(fade_seconds)
	else:
		fade_out_menu_theme(fade_seconds)
		fade_out_tavern_ambience(fade_seconds)
		fade_out_contract_ambience(fade_seconds)


func _play_menu_intro_audio_now() -> void:
	fade_out_tavern_ambience(0.35)
	fade_out_contract_ambience(0.35, false)
	_play_player(_rain_player, RAIN_MIX_VOLUME)
	_play_player(_theme_player, THEME_MIX_VOLUME)


func _transition_to_tavern_ambience_now(fade_seconds: float = DEFAULT_FADE_SECONDS) -> void:
	fade_out_contract_ambience(fade_seconds, false)
	fade_out_menu_rain(fade_seconds)
	fade_out_menu_theme(fade_seconds)
	_fade_in_player(_fireplace_player, "_fireplace_tween", TAVERN_FIREPLACE_MIX_VOLUME, fade_seconds)
	_fade_in_player(_chatter_player, "_chatter_tween", TAVERN_CHATTER_MIX_VOLUME, fade_seconds)
	_fade_in_player(_tavern_theme_player, "_tavern_theme_tween", TAVERN_THEME_MIX_VOLUME, fade_seconds)


func _transition_to_tavern_intro_ambience_now() -> void:
	fade_out_contract_ambience(TAVERN_INTRO_AMBIENCE_FADE_SECONDS, false)
	fade_out_menu_rain(TAVERN_INTRO_MENU_FADE_SECONDS)
	fade_out_menu_theme(TAVERN_INTRO_MENU_FADE_SECONDS)
	_fade_in_player(_fireplace_player, "_fireplace_tween", TAVERN_FIREPLACE_MIX_VOLUME, TAVERN_INTRO_AMBIENCE_FADE_SECONDS)
	_fade_in_player(_chatter_player, "_chatter_tween", TAVERN_CHATTER_MIX_VOLUME, TAVERN_INTRO_AMBIENCE_FADE_SECONDS)
	_fade_out_player(_tavern_theme_player, "_tavern_theme_tween", TAVERN_INTRO_AMBIENCE_FADE_SECONDS)
	await get_tree().create_timer(TAVERN_INTRO_THEME_LEAD_SECONDS).timeout
	if _pending_audio_scene != AUDIO_SCENE_TAVERN:
		return
	_fade_in_player(_tavern_theme_player, "_tavern_theme_tween", TAVERN_THEME_MIX_VOLUME, DEFAULT_FADE_SECONDS)


func _transition_to_contract_ambience_now(fade_seconds: float = DEFAULT_FADE_SECONDS) -> void:
	_next_contract_transition_id()
	_current_contract_biome = ""
	fade_out_tavern_ambience(fade_seconds)
	fade_out_menu_theme(fade_seconds)
	fade_out_menu_rain(fade_seconds)
	_fade_out_player(_biome_mood_player, "_biome_mood_tween", fade_seconds)
	_fade_out_player(_biome_music_player, "_biome_music_tween", fade_seconds)
	_fade_in_player(_night_player, "_night_tween", CONTRACT_NIGHT_MIX_VOLUME, fade_seconds)
	_fade_in_player(_serpent_theme_player, "_serpent_theme_tween", CONTRACT_SERPENT_THEME_MIX_VOLUME, fade_seconds)


func _transition_to_contract_biome_ambience_now(biome: String, fade_seconds: float = DEFAULT_FADE_SECONDS) -> void:
	var transition_id := _next_contract_transition_id()
	var resolved_biome := _normalized_biome_audio_key(biome)
	_pending_contract_biome = resolved_biome
	_current_contract_biome = resolved_biome
	fade_out_tavern_ambience(fade_seconds)
	fade_out_menu_theme(fade_seconds)
	fade_out_menu_rain(fade_seconds)
	_fade_out_player(_night_player, "_night_tween", fade_seconds)
	_fade_out_player(_serpent_theme_player, "_serpent_theme_tween", fade_seconds)
	_fade_out_player(_biome_mood_player, "_biome_mood_tween", fade_seconds)
	_fade_out_player(_biome_music_player, "_biome_music_tween", fade_seconds)
	await get_tree().create_timer(maxf(fade_seconds, 0.01)).timeout
	if transition_id != _contract_transition_id or _pending_audio_scene != AUDIO_SCENE_CONTRACT:
		return
	_set_biome_contract_streams(resolved_biome)
	_fade_in_player(_biome_mood_player, "_biome_mood_tween", BIOME_MOOD_MIX_VOLUME, BIOME_MOOD_FADE_SECONDS)
	await get_tree().create_timer(BIOME_MUSIC_LEAD_SECONDS).timeout
	if transition_id != _contract_transition_id or _pending_audio_scene != AUDIO_SCENE_CONTRACT:
		return
	_fade_in_player(_biome_music_player, "_biome_music_tween", BIOME_MUSIC_MIX_VOLUME, fade_seconds)


func play_random_attack_sfx(playback_speed: float, cast_duration_ms: int, suppress: bool = false) -> bool:
	if suppress or _attack_sfx_streams.is_empty() or _attack_sfx_players.is_empty():
		return false
	var stream_index := _rng.randi_range(0, _attack_sfx_streams.size() - 1)
	if not _play_combat_sfx(_attack_sfx_streams[stream_index], playback_speed, cast_duration_ms):
		return false
	attack_sfx_play_count += 1
	return true


func play_dodge_sfx(playback_speed: float, cast_duration_ms: int, suppress: bool = false) -> bool:
	if suppress or not _play_combat_sfx(_dodge_sfx_stream, playback_speed, cast_duration_ms):
		return false
	dodge_sfx_play_count += 1
	return true


func _play_combat_sfx(stream: AudioStreamMP3, playback_speed: float, cast_duration_ms: int) -> bool:
	if stream == null:
		return false
	var player := _next_attack_sfx_player()
	if player == null:
		return false
	var random_volume := ATTACK_SFX_BASE_VOLUME + _rng.randf_range(-ATTACK_SFX_VOLUME_VARIATION, ATTACK_SFX_VOLUME_VARIATION)
	var random_pitch := 1.0 + _rng.randf_range(-ATTACK_SFX_PITCH_VARIATION, ATTACK_SFX_PITCH_VARIATION)
	var timing_factor := _attack_sfx_timing_factor(cast_duration_ms)
	var speed_factor := maxf(playback_speed, 0.01)

	player.stop()
	player.stream = stream
	player.bus = EFFECTS_BUS
	player.volume_db = linear_to_db(clampf(random_volume, 0.001, 1.0))
	player.pitch_scale = clampf(
		random_pitch * timing_factor * speed_factor,
		ATTACK_SFX_MIN_PITCH_SCALE,
		ATTACK_SFX_MAX_PITCH_SCALE
	)
	player.play()

	last_attack_sfx_pitch_scale = player.pitch_scale
	last_attack_sfx_volume_db = player.volume_db
	last_attack_sfx_cast_duration_ms = cast_duration_ms
	last_attack_sfx_playback_speed = playback_speed
	return true


## Resolved activation only: category cues belong to casts, never their proc hits.
## Attack chains retain their existing bounded visual-beat contact policy.
func play_skill_sfx_for_cast(cast: CombatResolver.CastEvent, playback_speed: float, suppress: bool = false, retrigger: bool = false, visual_beat: bool = true) -> int:
	if suppress or cast == null or cast.was_interrupted or cast.interrupt_skipped or cast.cooldown_blocked or cast.resource_unavailable:
		return 0
	if cast.skill != null and cast.skill.id == "skill.hold":
		return 0
	# One quiet receipt cue per credited cast, including passive/retrigger theft.
	# The recorded amount already excludes failed theft and rounded-to-zero gold.
	var theft_cues := 0
	if cast.gold_stolen > 0:
		if _play_varied_skill_sfx(_gold_steal_sfx_stream, 0.40, 0.03) != null:
			gold_steal_sfx_play_count += 1
			theft_cues = 1
	if cast.skill != null and cast.skill.id == "skill.exsanguinate":
		if cast.was_dodged: return theft_cues
		var player := _play_varied_skill_sfx(_exsanguinate_sfx_stream)
		if player == null: return theft_cues
		exsanguinate_sfx_play_count += 1
		last_exsanguinate_sfx_pitch_scale = player.pitch_scale
		return theft_cues + 1
	if cast.skill != null and _skill_sfx_streams.has(cast.skill.id):
		if cast.was_dodged: return theft_cues
		var player := _play_varied_skill_sfx(_skill_sfx_streams[cast.skill.id])
		if player == null: return theft_cues
		skill_sfx_play_counts[cast.skill.id] = int(skill_sfx_play_counts.get(cast.skill.id, 0)) + 1
		return theft_cues + 1
	if cast.skill != null and CATEGORY_SFX_PATHS.has(cast.skill.category):
		if cast.was_dodged:
			return theft_cues
		return theft_cues + int(_play_category_sfx(cast.skill.category))
	if retrigger:
		return theft_cues + (play_retrigger_sfx(cast, playback_speed) if visual_beat else 0)
	return theft_cues + play_attack_sfx_for_cast(cast, playback_speed)


func _play_category_sfx(category: int) -> bool:
	var stream: AudioStreamMP3 = _category_sfx_streams.get(category)
	var player := _play_varied_skill_sfx(stream)
	if player == null: return false
	category_sfx_play_count += 1
	if category == Skill.Category.SELF_BUFF: self_buff_sfx_play_count += 1
	if category == Skill.Category.DEBUFF: debuff_sfx_play_count += 1
	last_category_sfx_category = category
	last_category_sfx_pitch_scale = player.pitch_scale
	last_category_sfx_volume_db = player.volume_db
	return true


func _play_varied_skill_sfx(stream: AudioStreamMP3, base_volume: float = CATEGORY_SFX_BASE_VOLUME, volume_variation: float = CATEGORY_SFX_VOLUME_VARIATION) -> AudioStreamPlayer:
	if stream == null:
		return null
	var player := _next_attack_sfx_player()
	if player == null:
		return null
	player.stop()
	player.stream = stream
	player.bus = EFFECTS_BUS
	player.volume_db = linear_to_db(base_volume + _rng.randf_range(-volume_variation, volume_variation))
	# Playback speed changes cadence; subtle variation preserves the cue's pitch.
	player.pitch_scale = 1.0 + _rng.randf_range(-CATEGORY_SFX_PITCH_VARIATION, CATEGORY_SFX_PITCH_VARIATION)
	player.play()
	return player


func play_attack_sfx_for_cast(cast: CombatResolver.CastEvent, playback_speed: float, suppress: bool = false) -> int:
	if cast != null and cast.was_dodged:
		last_attack_sfx_hit_count = 0
		last_attack_sfx_proc_hit_count = 0
		return 1 if play_dodge_sfx(playback_speed, maxi(cast.time_ms - cast.cast_start_ms, 1), suppress) else 0
	var hit_count := attack_sfx_hit_count_for_cast(cast)
	last_attack_sfx_hit_count = hit_count
	last_attack_sfx_proc_hit_count = maxi(hit_count - 1, 0)
	if suppress or hit_count <= 0:
		return 0
	var cast_duration_ms := maxi(cast.time_ms - cast.cast_start_ms, 1)
	var scheduled_count := 0
	if play_random_attack_sfx(playback_speed, cast_duration_ms, false):
		scheduled_count += 1
	for hit_index in range(1, hit_count):
		var delay_sec := ATTACK_SFX_PROC_OFFSET_SEC * float(hit_index) / maxf(playback_speed, 0.01)
		get_tree().create_timer(delay_sec).timeout.connect(_play_delayed_attack_sfx.bind(playback_speed, cast_duration_ms, _combat_sfx_generation))
		scheduled_count += 1
	return scheduled_count


func play_button_press_sfx() -> bool:
	if _button_press_stream == null or _button_sfx_players.is_empty():
		return false
	var player := _next_button_sfx_player()
	if player == null:
		return false
	player.stop()
	player.stream = _button_press_stream
	player.bus = EFFECTS_BUS
	player.volume_db = linear_to_db(BUTTON_PRESS_SFX_VOLUME)
	player.pitch_scale = 1.0
	player.play()
	button_press_sfx_play_count += 1
	return true


func play_shop_change_sfx() -> bool:
	if _shop_change_stream == null or _shop_change_player == null:
		return false
	_shop_change_player.stop()
	_shop_change_player.stream = _shop_change_stream
	_shop_change_player.bus = EFFECTS_BUS
	_shop_change_player.volume_db = linear_to_db(SHOP_CHANGE_SFX_VOLUME)
	_shop_change_player.pitch_scale = SHOP_CHANGE_SFX_PITCH_SCALE
	_shop_change_player.play()
	shop_change_sfx_play_count += 1
	last_shop_change_pitch_scale = _shop_change_player.pitch_scale
	return true


## One cue per visible Magic Find tier upgrade; callers omit skipped reveal beats.
func play_magic_find_sfx() -> bool:
	if _magic_find_stream == null or _magic_find_sfx_players.is_empty():
		return false
	var player := _magic_find_sfx_players[_magic_find_sfx_player_index]
	_magic_find_sfx_player_index = (_magic_find_sfx_player_index + 1) % _magic_find_sfx_players.size()
	player.stop()
	player.stream = _magic_find_stream
	player.bus = EFFECTS_BUS
	player.volume_db = linear_to_db(MAGIC_FIND_SFX_BASE_VOLUME + _rng.randf_range(-MAGIC_FIND_SFX_VOLUME_VARIATION, MAGIC_FIND_SFX_VOLUME_VARIATION))
	player.pitch_scale = 1.0 + _rng.randf_range(-MAGIC_FIND_SFX_PITCH_VARIATION, MAGIC_FIND_SFX_PITCH_VARIATION)
	player.play()
	magic_find_sfx_play_count += 1
	last_magic_find_sfx_pitch_scale = player.pitch_scale
	last_magic_find_sfx_volume_db = player.volume_db
	return true


## Stop reveal tails when skipping, closing, or replacing a reward/shop reveal.
func cancel_magic_find_sfx() -> void:
	for player in _magic_find_sfx_players:
		player.stop()


func play_footsteps_sfx(duration_sec: float) -> bool:
	if duration_sec <= 0.0 or _footsteps_stream == null or _footsteps_player == null:
		return false
	_footsteps_generation += 1
	_footsteps_player.stop()
	_footsteps_player.stream = _footsteps_stream
	_footsteps_player.bus = EFFECTS_BUS
	_footsteps_player.volume_db = linear_to_db(FOOTSTEPS_SFX_VOLUME)
	_footsteps_player.pitch_scale = FOOTSTEPS_SFX_PITCH_SCALE
	_footsteps_player.play()
	footsteps_sfx_play_count += 1
	last_footsteps_duration_sec = duration_sec
	var generation := _footsteps_generation
	get_tree().create_timer(duration_sec).timeout.connect(func() -> void:
		if generation == _footsteps_generation and _footsteps_player != null:
			_footsteps_player.stop()
	)
	return true


func stop_footsteps_sfx() -> void:
	_footsteps_generation += 1
	if _footsteps_player != null:
		_footsteps_player.stop()


func attack_sfx_hit_count_for_cast(cast: CombatResolver.CastEvent) -> int:
	if cast == null or cast.was_dodged or (cast.physical_damage <= 0.0 and cast.blocked_amount <= 0.0):
		return 0
	var hit_count := 1
	for contribution in cast.damage_contributions:
		if String(contribution.get("kind", "")) == "proc" and float(contribution.get("damage", 0.0)) > 0.0:
			hit_count += 1
	return hit_count


func set_master_volume(value: float, persist: bool = true) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume("Master", master_volume)
	if persist:
		_save_settings()


func set_music_volume(value: float, persist: bool = true) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume(MUSIC_BUS, music_volume)
	if persist:
		_save_settings()


func set_effects_volume(value: float, persist: bool = true) -> void:
	effects_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume(EFFECTS_BUS, effects_volume)
	if persist:
		_save_settings()


func _build_music_players() -> void:
	_rain_player = _build_music_player("MenuRainPlayer", MENU_RAIN_PATH)
	_theme_player = _build_music_player("MenuEpicThemePlayer", MENU_THEME_PATH)
	_fireplace_player = _build_music_player("TavernFireplacePlayer", TAVERN_FIREPLACE_PATH)
	_chatter_player = _build_music_player("TavernChatterPlayer", TAVERN_CHATTER_PATH)
	_tavern_theme_player = _build_music_player("TavernThemePlayer", TAVERN_THEME_PATH)
	_night_player = _build_music_player("ContractNightPlayer", CONTRACT_NIGHT_PATH)
	_serpent_theme_player = _build_music_player("ContractSerpentThemePlayer", CONTRACT_SERPENT_THEME_PATH)
	_biome_mood_player = _build_music_player("ContractBiomeMoodPlayer", "")
	_biome_music_player = _build_music_player("ContractBiomeMusicPlayer", "")


func _build_attack_sfx_pool() -> void:
	_exsanguinate_sfx_stream = _load_mp3_stream(EXSANGUINATE_SFX_PATH)
	for id in SKILL_SFX_PATHS:
		_skill_sfx_streams[id] = _load_mp3_stream(SKILL_SFX_PATHS[id])
	_gold_steal_sfx_stream = _load_mp3_stream(GOLD_STEAL_SFX_PATH)
	_dodge_sfx_stream = _load_mp3_stream(DODGE_SFX_PATH)
	for category in CATEGORY_SFX_PATHS:
		_category_sfx_streams[category] = _load_mp3_stream(CATEGORY_SFX_PATHS[category])
	_attack_sfx_streams.clear()
	for path in ATTACK_SFX_PATHS:
		var stream := _load_mp3_stream(path)
		if stream != null:
			_attack_sfx_streams.append(stream)
	_attack_sfx_players.clear()
	for index in range(ATTACK_SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "AttackSfxPlayer%d" % index
		player.bus = EFFECTS_BUS
		add_child(player)
		_attack_sfx_players.append(player)


func _build_ui_sfx_players() -> void:
	_button_press_stream = _load_mp3_stream(BUTTON_PRESS_SFX_PATH)
	_shop_change_stream = _load_mp3_stream(SHOP_CHANGE_SFX_PATH)
	_magic_find_stream = _load_mp3_stream(MAGIC_FIND_SFX_PATH)
	_magic_find_sfx_players.clear()
	for index in range(MAGIC_FIND_SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "MagicFindSfxPlayer%d" % index
		player.bus = EFFECTS_BUS
		add_child(player)
		_magic_find_sfx_players.append(player)
	_footsteps_stream = _load_mp3_stream(FOOTSTEPS_SFX_PATH)
	if _footsteps_stream != null:
		_footsteps_stream.loop = true
	_button_sfx_players.clear()
	for index in range(BUTTON_PRESS_SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "ButtonPressSfxPlayer%d" % index
		player.bus = EFFECTS_BUS
		add_child(player)
		_button_sfx_players.append(player)
	_shop_change_player = AudioStreamPlayer.new()
	_shop_change_player.name = "ShopChangeSfxPlayer"
	_shop_change_player.bus = EFFECTS_BUS
	add_child(_shop_change_player)
	_footsteps_player = AudioStreamPlayer.new()
	_footsteps_player.name = "FootstepsSfxPlayer"
	_footsteps_player.bus = EFFECTS_BUS
	add_child(_footsteps_player)


func _build_music_player(player_name: String, stream_path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = MUSIC_BUS
	player.stream = null if stream_path == "" else _load_mp3_stream(stream_path)
	if player.stream != null:
		player.stream.loop = true
	add_child(player)
	return player


func _load_mp3_stream(path: String) -> AudioStreamMP3:
	if path == "":
		return null
	if ResourceLoader.exists(path):
		var loaded := load(path)
		if loaded is AudioStreamMP3:
			return loaded
	var stream := AudioStreamMP3.load_from_file(ProjectSettings.globalize_path(path))
	return stream


func _play_player(player: AudioStreamPlayer, mix_volume: float) -> void:
	if player == null or player.stream == null:
		return
	_stop_player_tween(player)
	player.volume_db = linear_to_db(clampf(mix_volume, 0.001, 1.0))
	if not player.playing:
		player.play()


func _fade_in_player(player: AudioStreamPlayer, tween_property_name: String, mix_volume: float, fade_seconds: float) -> void:
	if player == null or player.stream == null:
		return
	_stop_player_tween(player)
	var target_volume := linear_to_db(clampf(mix_volume, 0.001, 1.0))
	if not player.playing:
		player.volume_db = -60.0
		player.play()
	var tween := create_tween()
	set(tween_property_name, tween)
	tween.tween_property(player, "volume_db", target_volume, maxf(fade_seconds, 0.01))
	tween.tween_callback(func() -> void:
		set(tween_property_name, null)
	)


func _next_attack_sfx_player() -> AudioStreamPlayer:
	if _attack_sfx_players.is_empty():
		return null
	var player := _attack_sfx_players[_attack_sfx_player_index]
	_attack_sfx_player_index = (_attack_sfx_player_index + 1) % _attack_sfx_players.size()
	return player


func _next_button_sfx_player() -> AudioStreamPlayer:
	if _button_sfx_players.is_empty():
		return null
	var player := _button_sfx_players[_button_sfx_player_index]
	_button_sfx_player_index = (_button_sfx_player_index + 1) % _button_sfx_players.size()
	return player


func _attack_sfx_timing_factor(cast_duration_ms: int) -> float:
	var safe_duration := maxf(float(cast_duration_ms), 1.0)
	return clampf(
		ATTACK_SFX_REFERENCE_CAST_MS / safe_duration,
		ATTACK_SFX_MIN_TIMING_FACTOR,
		ATTACK_SFX_MAX_TIMING_FACTOR
	)


func _play_delayed_attack_sfx(playback_speed: float, cast_duration_ms: int, generation: int = -1) -> void:
	if generation >= 0 and generation != _combat_sfx_generation: return
	play_random_attack_sfx(playback_speed, cast_duration_ms, false)


func cancel_combat_sfx(stop_active: bool = true) -> void:
	_combat_sfx_generation += 1
	if stop_active:
		for player in _attack_sfx_players:
			player.stop()


func _next_contract_transition_id() -> int:
	_contract_transition_id += 1
	return _contract_transition_id


func _set_biome_contract_streams(biome: String) -> void:
	var resolved_biome := _normalized_biome_audio_key(biome)
	_assign_looping_stream(_biome_mood_player, String(BIOME_MOOD_PATHS.get(resolved_biome, "")))
	_assign_looping_stream(_biome_music_player, String(BIOME_MUSIC_PATHS.get(resolved_biome, "")))


func _assign_looping_stream(player: AudioStreamPlayer, stream_path: String) -> void:
	if player == null:
		return
	var stream := _load_mp3_stream(stream_path)
	player.stream = stream
	if player.stream != null:
		player.stream.loop = true


func _normalized_biome_audio_key(biome: String) -> String:
	if BIOME_MUSIC_PATHS.has(biome):
		return biome
	if biome == "Forest":
		return "Haunted Forest"
	if biome == "Keep" or biome == "Ancient Keep":
		return "Ruined Keep"
	if biome == "Ruins":
		return "Ancient Ruins"
	return "Swamp"


func _is_current_contract_biome_ambience(biome: String) -> bool:
	return (
		_pending_audio_scene == AUDIO_SCENE_CONTRACT
		and _pending_contract_biome == biome
		and _current_contract_biome == biome
	)


func _on_tree_node_added(node: Node) -> void:
	if node is BaseButton:
		_connect_button_sfx(node)


func _connect_existing_button_sfx() -> void:
	if get_tree() == null or get_tree().root == null:
		return
	_connect_button_sfx_recursive(get_tree().root)


func _connect_button_sfx_recursive(node: Node) -> void:
	if node is BaseButton:
		_connect_button_sfx(node)
	for child in node.get_children():
		_connect_button_sfx_recursive(child)


func _connect_button_sfx(button: BaseButton) -> void:
	if button == null or button.has_meta(BUTTON_PRESS_SFX_META):
		return
	button.button_down.connect(_on_button_down_for_sfx.bind(button))
	button.button_up.connect(_on_button_up_for_sfx.bind(button))
	button.pressed.connect(_on_button_pressed_for_sfx.bind(button))
	button.set_meta(BUTTON_PRESS_SFX_META, true)


func _on_button_down_for_sfx(button: BaseButton) -> void:
	if button == null or button.disabled:
		return
	_unlock_web_audio()
	var instance_id: int = button.get_instance_id()
	_button_down_sfx_consumed_by_instance[instance_id] = true
	_play_deduped_button_sfx(instance_id)


func _on_button_up_for_sfx(button: BaseButton) -> void:
	if button == null:
		return
	call_deferred("_clear_button_down_sfx_consumed", button.get_instance_id())


func _on_button_pressed_for_sfx(button: BaseButton) -> void:
	if button == null or button.disabled:
		return
	_unlock_web_audio()
	var instance_id: int = button.get_instance_id()
	if bool(_button_down_sfx_consumed_by_instance.get(instance_id, false)):
		return
	_play_deduped_button_sfx(instance_id)


func _clear_button_down_sfx_consumed(instance_id: int) -> void:
	_button_down_sfx_consumed_by_instance.erase(instance_id)


func _play_deduped_button_sfx(instance_id: int) -> void:
	var current_frame := Engine.get_process_frames()
	if int(_last_button_sfx_frame_by_instance.get(instance_id, -1)) == current_frame:
		return
	_last_button_sfx_frame_by_instance[instance_id] = current_frame
	play_button_press_sfx()


func _should_wait_for_web_audio_unlock() -> bool:
	return OS.has_feature("web") and not _web_audio_unlocked


func _unlock_web_audio() -> void:
	if _web_audio_unlocked:
		return
	_web_audio_unlocked = true
	_apply_all_bus_volumes()
	if _pending_audio_scene != AUDIO_SCENE_NONE:
		_apply_audio_scene(_pending_audio_scene, 0.15)


func _is_audio_unlock_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.pressed
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventJoypadButton:
		return event.pressed
	return false


func _fade_out_player(player: AudioStreamPlayer, tween_property_name: String, fade_seconds: float) -> void:
	if player == null or not player.playing:
		return
	_stop_player_tween(player)
	var tween := create_tween()
	set(tween_property_name, tween)
	tween.tween_property(player, "volume_db", -60.0, maxf(fade_seconds, 0.01))
	tween.tween_callback(func() -> void:
		player.stop()
		player.volume_db = 0.0
		set(tween_property_name, null)
	)


func _stop_player_tween(player: AudioStreamPlayer) -> void:
	if player == _rain_player and _rain_tween != null:
		_rain_tween.kill()
		_rain_tween = null
	elif player == _theme_player and _theme_tween != null:
		_theme_tween.kill()
		_theme_tween = null
	elif player == _fireplace_player and _fireplace_tween != null:
		_fireplace_tween.kill()
		_fireplace_tween = null
	elif player == _chatter_player and _chatter_tween != null:
		_chatter_tween.kill()
		_chatter_tween = null
	elif player == _tavern_theme_player and _tavern_theme_tween != null:
		_tavern_theme_tween.kill()
		_tavern_theme_tween = null
	elif player == _night_player and _night_tween != null:
		_night_tween.kill()
		_night_tween = null
	elif player == _serpent_theme_player and _serpent_theme_tween != null:
		_serpent_theme_tween.kill()
		_serpent_theme_tween = null
	elif player == _biome_mood_player and _biome_mood_tween != null:
		_biome_mood_tween.kill()
		_biome_mood_tween = null
	elif player == _biome_music_player and _biome_music_tween != null:
		_biome_music_tween.kill()
		_biome_music_tween = null


func _ensure_audio_buses() -> void:
	_ensure_bus(MUSIC_BUS)
	_ensure_bus(EFFECTS_BUS)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")


func _apply_all_bus_volumes() -> void:
	_apply_bus_volume("Master", master_volume)
	_apply_bus_volume(MUSIC_BUS, music_volume)
	_apply_bus_volume(EFFECTS_BUS, effects_volume)


func _apply_bus_volume(bus_name: String, value: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	var clamped := clampf(value, 0.0, 1.0)
	AudioServer.set_bus_mute(index, clamped <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(clamped, 0.001)))


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	master_volume = clampf(float(config.get_value("audio", "master_volume", DEFAULT_MASTER_VOLUME)), 0.0, 1.0)
	music_volume = clampf(float(config.get_value("audio", "music_volume", DEFAULT_MUSIC_VOLUME)), 0.0, 1.0)
	effects_volume = clampf(float(config.get_value("audio", "effects_volume", DEFAULT_EFFECTS_VOLUME)), 0.0, 1.0)


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "effects_volume", effects_volume)
	config.save(SETTINGS_PATH)


## One bounded contact per visible chain beat, with no queued proc echoes.
func play_retrigger_sfx(cast: CombatResolver.CastEvent, playback_speed: float) -> int:
	if cast == null or cast.was_interrupted or cast.resource_unavailable or cast.cooldown_blocked: return 0
	if cast.was_dodged: return int(play_dodge_sfx(playback_speed, 180))
	if cast.physical_damage <= 0.0 and cast.blocked_amount <= 0.0: return 0
	return int(play_random_attack_sfx(playback_speed, 180))
