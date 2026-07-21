extends Control
class_name GameOverScreen
## Shown when GameManager.State.GAME_OVER (a zombie reached the house).
## Offers "Retry" (reload the battle scene) and "Main Menu".

@onready var _retry_button: Button = $CenterContainer/VBox/RetryButton
@onready var _menu_button: Button = $CenterContainer/VBox/MenuButton

const MENU_SCENE := "res://Scenes/UI/MainMenu.tscn"

func _ready() -> void:
	_retry_button.pressed.connect(_on_retry_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	GameManager.game_lost.connect(_on_game_lost)

func _on_game_lost() -> void:
	AudioManager.play_sfx("lose")

func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	GameManager.return_to_menu()
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)
