extends Node

const SFX_POOL_SIZE := 8

# Bảng tra key → đường dẫn file âm thanh
const SFX_PATHS: Dictionary = {
	# --- Combat ---
	"sword_hit":       "res://assets/audio/sfx/combat/sword_hit.wav",
	"blunt_swing":     "res://assets/audio/sfx/combat/blunt_swing.wav",
	"arrow_hit":       "res://assets/audio/sfx/combat/arrow_hit.wav",
	"bow_draw":        "res://assets/audio/sfx/combat/bow_draw.wav",
	"bow_release":     "res://assets/audio/sfx/combat/bow_release.wav",
	"shield_block":    "res://assets/audio/sfx/combat/shield_block.mp3",
	"skill_fire":      "res://assets/audio/sfx/combat/skill_fire.wav",
	"skill_ice":       "res://assets/audio/sfx/combat/skill_ice.wav",
	"enemy_hit":       "res://assets/audio/sfx/combat/enemy_hit.wav",
	"enemy_death":     "res://assets/audio/sfx/combat/enemy_death.wav",
	"player_hurt":     "res://assets/audio/sfx/combat/player_hurt.wav",
	"player_death":    "res://assets/audio/sfx/combat/player_death.wav",
	"combat_victory":  "res://assets/audio/sfx/combat/combat_victory.wav",
	# --- Forge ---
	"furnace_burn":    "res://assets/audio/sfx/forge/furnace_burn_loop.wav",
	"bellows_puff":    "res://assets/audio/sfx/forge/bellows_puff.wav",
	"heat_tick":       "res://assets/audio/sfx/forge/heat_tick.wav",
	"hammer_good":     "res://assets/audio/sfx/forge/hammer_hit_good.wav",
	"hammer_miss":     "res://assets/audio/sfx/forge/hammer_hit_miss.wav",
	"hammer_perfect":  "res://assets/audio/sfx/forge/hammer_hit_perfect.mp3",
	"quench_sizzle":   "res://assets/audio/sfx/forge/quench_sizzle.wav",
	"weapon_reveal":   "res://assets/audio/sfx/forge/weapon_reveal.wav",
	# --- Workshop ---
	"footstep_wood_1": "res://assets/audio/sfx/workshop/footstep_wood_1.wav",
	"footstep_wood_2": "res://assets/audio/sfx/workshop/footstep_wood_2.wav",
	"book_flip":       "res://assets/audio/sfx/workshop/book_flip.wav",
	"chest_open":      "res://assets/audio/sfx/workshop/chest_open.wav",
	"door_wood":       "res://assets/audio/sfx/workshop/door_wood.wav",
	"zone_prompt":     "res://assets/audio/sfx/workshop/zone_prompt.wav",
	# --- Shop (chưa có file, thêm sau) ---
	# "coin_clink":    "res://assets/audio/sfx/shop/coin_clink.wav",
	# "deal_success":  "res://assets/audio/sfx/shop/deal_success.wav",
	# "deal_fail":     "res://assets/audio/sfx/shop/deal_fail.wav",
	# --- UI (chưa có file, thêm sau) ---
	# "button_click":  "res://assets/audio/sfx/ui/button_click.wav",
	# "menu_open":     "res://assets/audio/sfx/ui/menu_open.wav",
}

var music_volume: float = 0.8
var sfx_volume: float = 1.0

var _music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []

# Cache stream đã load để tránh load lại nhiều lần
var _sfx_cache: Dictionary = {}

# Player riêng cho SFX loop (furnace, v.v.)
var _sfx_loop_player: AudioStreamPlayer = null


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music" if AudioServer.get_bus_index("Music") != -1 else "Master"
	add_child(_music_player)

	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_sfx_pool.append(player)

	_sfx_loop_player = AudioStreamPlayer.new()
	_sfx_loop_player.bus = "Master"
	_sfx_loop_player.finished.connect(_on_loop_finished)
	add_child(_sfx_loop_player)


# Phát nhạc nền
func play_music(track: AudioStream, _fade: bool = true) -> void:
	if track == null:
		return
	_music_player.stream = track
	_music_player.volume_db = linear_to_db(music_volume)
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()


# Phát SFX bằng key (vd: AudioManager.play_sfx_key("sword_hit"))
func play_sfx_key(
	key: String,
	volume_scale: float = 1.0,
	pitch_scale: float = 1.0
) -> void:
	if not SFX_PATHS.has(key):
		push_warning("AudioManager: không tìm thấy SFX key '%s'" % key)
		return
	if not _sfx_cache.has(key):
		_sfx_cache[key] = load(SFX_PATHS[key])
	play_sfx(_sfx_cache[key], volume_scale, pitch_scale)


# Phát SFX bằng AudioStream trực tiếp
func play_sfx(
	sfx: AudioStream,
	volume_scale: float = 1.0,
	pitch_scale: float = 1.0
) -> void:
	if sfx == null:
		return
	var player := _get_free_player()
	if player == null:
		return
	player.stream = sfx
	var vol := clampf(sfx_volume * volume_scale, 0.001, 2.0)
	player.volume_db = linear_to_db(vol)
	player.pitch_scale = clampf(pitch_scale, 0.5, 2.0)
	player.play()


func _get_free_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.is_playing():
			return player
	# Tất cả đang bận — dùng player đầu tiên (cắt âm cũ)
	return _sfx_pool[0]


# Phát SFX lặp liên tục (dùng cho furnace, v.v.) — gọi stop_sfx_loop() để dừng
func play_sfx_loop(key: String, volume_scale: float = 1.0) -> void:
	if not SFX_PATHS.has(key):
		push_warning("AudioManager: không tìm thấy SFX key '%s'" % key)
		return
	if not _sfx_cache.has(key):
		_sfx_cache[key] = load(SFX_PATHS[key])
	var target_stream: AudioStream = _sfx_cache[key]
	if target_stream == null:
		return
	var vol := clampf(sfx_volume * volume_scale, 0.001, 2.0)
	_sfx_loop_player.volume_db = linear_to_db(vol)
	if _sfx_loop_player.is_playing() and _sfx_loop_player.stream == target_stream:
		return
	_sfx_loop_player.stream = target_stream
	_sfx_loop_player.play()


func set_sfx_loop_volume(volume_scale: float) -> void:
	if _sfx_loop_player == null or not _sfx_loop_player.is_playing():
		return
	var vol := clampf(sfx_volume * volume_scale, 0.001, 2.0)
	_sfx_loop_player.volume_db = linear_to_db(vol)


func stop_sfx_loop() -> void:
	if _sfx_loop_player == null:
		return
	_sfx_loop_player.stop()
	_sfx_loop_player.stream = null


func _on_loop_finished() -> void:
	if _sfx_loop_player.stream != null:
		_sfx_loop_player.play()
