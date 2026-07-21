extends Node
## AudioManager (autoload singleton "AudioManager")
## Centralised sound playback so gameplay scripts never touch
## AudioStreamPlayer nodes directly. Missing audio files are skipped
## silently (see res://Audio/README.md) so the game still runs without
## art/audio assets.

const MUSIC_PATHS := {
	"menu": "res://Audio/music_menu.ogg",
	"battle": "res://Audio/music_battle.ogg",
}
const SFX_PATHS := {
	"plant": "res://Audio/sfx_plant.ogg",
	"shoot": "res://Audio/sfx_shoot.ogg",
	"bite": "res://Audio/sfx_zombie_bite.ogg",
	"zombie_die": "res://Audio/sfx_zombie_die.ogg",
	"explosion": "res://Audio/sfx_explosion.ogg",
	"sun_collect": "res://Audio/sfx_sun_collect.ogg",
	"win": "res://Audio/sfx_win.ogg",
	"lose": "res://Audio/sfx_lose.ogg",
}

var _music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 8

func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	add_child(_music_player)
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_pool.append(p)

## Plays looping background music by key ("menu", "battle").
func play_music(key: String) -> void:
	var path: String = MUSIC_PATHS.get(key, "")
	if path == "" or not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if _music_player.stream == stream and _music_player.playing:
		return
	_music_player.stream = stream
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()

## Plays a one-shot sound effect by key, using a small round-robin pool
## instead of creating/destroying nodes at runtime.
func play_sfx(key: String) -> void:
	var path: String = SFX_PATHS.get(key, "")
	if path == "" or not ResourceLoader.exists(path):
		return
	for p in _sfx_pool:
		if not p.playing:
			p.stream = load(path)
			p.play()
			return
	# All busy: steal the first one.
	_sfx_pool[0].stream = load(path)
	_sfx_pool[0].play()
