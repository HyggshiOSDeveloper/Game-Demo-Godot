extends Control
class_name VictoryScreen
## Shown when GameManager.State.VICTORY. Displays final score, offers
## "Next Level" (if the win path unlocked one) and "Main Menu".

@onready var _score_label: Label = $CenterContainer/VBox/ScoreLabel
@onready var _menu_button: Button = $CenterContainer/VBox/MenuButton

const MENU_SCENE := "res://Scenes/UI/MainMenu.tscn"

func _ready() -> void:
	_menu_button.pressed.connect(_on_menu_pressed)
	GameManager.game_won.connect(_on_game_won)

func _on_game_won() -> void:
	_score_label.text = "Score: %d" % GameManager.score
	AudioManager.play_sfx("win")

func _on_menu_pressed() -> void:
	GameManager.return_to_menu()
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)
