extends Control
class_name PauseMenu
## Overlay shown while GameManager.State.PAUSED. Resume unpauses;
## Quit to Menu returns to the main menu.

@onready var _resume_button: Button = $CenterContainer/VBox/ResumeButton
@onready var _quit_button: Button = $CenterContainer/VBox/QuitButton

const MENU_SCENE := "res://Scenes/UI/MainMenu.tscn"

func _ready() -> void:
	_resume_button.pressed.connect(GameManager.toggle_pause)
	_quit_button.pressed.connect(_on_quit_pressed)
	process_mode = Node.PROCESS_MODE_ALWAYS # stays interactive while tree is paused

func _on_quit_pressed() -> void:
	GameManager.return_to_menu()
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)
