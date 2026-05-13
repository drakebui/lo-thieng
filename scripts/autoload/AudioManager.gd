extends Node

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

var music_volume: float = 0.8
var sfx_volume: float = 1.0

func play_music(track: AudioStream, fade: bool = true) -> void:
	music_player.stream = track
	music_player.play()

func play_sfx(sfx: AudioStream) -> void:
	sfx_player.stream = sfx
	sfx_player.play()
