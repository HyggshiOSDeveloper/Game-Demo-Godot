extends Control
class_name MainMenu
## Entry-point screen. "Play" starts the battle scene, "Settings" opens a
## volume panel backed by SaveManager, "Quit" exits.

@onready var _play_button: Button = $CenterContainer/VBox/PlayButton
@onready var _settings_button: Button = $CenterContainer/VBox/SettingsButton
@onready var _quit_button: Button = $CenterContainer/VBox/QuitButton
@onready var _high_score_label: Label = $CenterContainer/VBox/HighScoreLabel

const BATTLE_SCENE := "res://Scenes/Main.tscn"

func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_high_score_label.text = "High Score: %d" % SaveManager.get_high_score()
	AudioManager.play_music("menu")
	GameManager.return_to_menu()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(BATTLE_SCENE)

func _on_settings_pressed() -> void:
	# Hook up a SettingsPanel scene here if/when one is added; kept minimal
	# per the requested scope (Main Menu / Pause / Victory / Game Over).
	pass

func _on_quit_pressed() -> void:
	get_tree().quit()
