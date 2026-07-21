extends Node
## GameManager (autoload singleton "GameManager")
## Owns the overall game state machine: menu -> playing -> paused ->
## victory / game_over. Other systems (UI, WaveManager, ZombieManager)
## react to its signals instead of polling it, keeping coupling low.

enum State { MENU, PLAYING, PAUSED, VICTORY, GAME_OVER }

signal state_changed(new_state: State)
signal game_started
signal game_paused
signal game_resumed
signal game_won
signal game_lost

var current_state: State = State.MENU
var current_level: int = 1
var score: int = 0

## Called by MainMenu when the player presses "Play".
func start_game(level: int = 1) -> void:
	current_level = level
	score = 0
	_set_state(State.PLAYING)
	get_tree().paused = false
	game_started.emit()

## Toggles pause; ignored outside of PLAYING/PAUSED.
func toggle_pause() -> void:
	if current_state == State.PLAYING:
		_set_state(State.PAUSED)
		get_tree().paused = true
		game_paused.emit()
	elif current_state == State.PAUSED:
		_set_state(State.PLAYING)
		get_tree().paused = false
		game_resumed.emit()

## Called by WaveManager once the final wave is fully cleared.
func win_game() -> void:
	if current_state != State.PLAYING:
		return
	_set_state(State.VICTORY)
	get_tree().paused = true
	SaveManager.unlock_level(current_level + 1)
	SaveManager.report_score(score)
	game_won.emit()

## Called by ZombieManager when a zombie reaches the house (leftmost edge).
func lose_game() -> void:
	if current_state != State.PLAYING:
		return
	_set_state(State.GAME_OVER)
	get_tree().paused = true
	game_lost.emit()

## Adds to the running score (e.g. per zombie killed).
func add_score(amount: int) -> void:
	score += amount

func _set_state(new_state: State) -> void:
	current_state = new_state
	state_changed.emit(new_state)

## Fully resets state and unpauses the tree; used when returning to the menu.
func return_to_menu() -> void:
	get_tree().paused = false
	_set_state(State.MENU)
