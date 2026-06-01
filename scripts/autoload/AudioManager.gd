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
	"hammer_good":     "res://assets/audio/sfx/forge/hammer_hit_good.wav",
	"hammer_miss":     "res://assets/audio/sfx/forge/hammer_hit_miss.wav",
	"hammer_perfect":  "res://assets/audio/sfx/forge/hammer_hit_perfect.mp3",
	# --- Forge zone feedback ---
	# Placeholder dùng file hiện có; cần thay bằng:
	# zone_enter_cam.wav, zone_enter_peak.wav, overheat_hiss.wav, forge_fail_sizzle.wav
	"forge_zone_cam":  "res://assets/audio/sfx/forge/hammer_hit_good.wav",
	"forge_zone_peak": "res://assets/audio/sfx/forge/hammer_hit_perfect.mp3",
	"forge_overheat":  "res://assets/audio/sfx/combat/player_hurt.wav",
	"forge_fail":      "res://assets/audio/sfx/combat/player_hurt.wav",
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
	_music_player.bus = "Music"
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
func play_sfx_key(key: String) -> void:
	if not SFX_PATHS.has(key):
		push_warning("AudioManager: không tìm thấy SFX key '%s'" % key)
		return
	if not _sfx_cache.has(key):
		_sfx_cache[key] = load(SFX_PATHS[key])
	play_sfx(_sfx_cache[key])


# Phát SFX bằng AudioStream trực tiếp
func play_sfx(sfx: AudioStream) -> void:
	if sfx == null:
		return
	var player := _get_free_player()
	if player == null:
		return
	player.stream = sfx
	player.volume_db = linear_to_db(sfx_volume)
	player.play()


func _get_free_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.is_playing():
			return player
	# Tất cả đang bận — dùng player đầu tiên (cắt âm cũ)
	return _sfx_pool[0]


# Phát SFX lặp liên tục (dùng cho furnace, v.v.) — gọi stop_sfx_loop() để dừng
func play_sfx_loop(key: String) -> void:
	if not SFX_PATHS.has(key):
		push_warning("AudioManager: không tìm thấy SFX key '%s'" % key)
		return
	if _sfx_loop_player.is_playing():
		return
	if not _sfx_cache.has(key):
		_sfx_cache[key] = load(SFX_PATHS[key])
	_sfx_loop_player.stream = _sfx_cache[key]
	_sfx_loop_player.volume_db = linear_to_db(sfx_volume)
	_sfx_loop_player.play()


func stop_sfx_loop() -> void:
	_sfx_loop_player.stop()


func _on_loop_finished() -> void:
	if _sfx_loop_player.stream != null:
		_sfx_loop_player.play()
