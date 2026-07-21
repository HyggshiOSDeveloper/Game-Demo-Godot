extends Node
## SaveManager (autoload singleton "SaveManager")
## Persists unlocked levels, settings and high scores to user://save.dat
## as JSON. Kept deliberately small and defensive: any read failure
## falls back to sane defaults instead of crashing the game.

const SAVE_PATH := "user://save.dat"

var data: Dictionary = {
	"unlocked_level": 1,
	"high_score": 0,
	"settings": {
		"music_volume": 1.0,
		"sfx_volume": 1.0,
	},
}

func _ready() -> void:
	load_game()

## Marks a level as unlocked (keeps the highest value reached).
func unlock_level(level: int) -> void:
	data["unlocked_level"] = max(data.get("unlocked_level", 1), level)
	save_game()

func is_level_unlocked(level: int) -> bool:
	return level <= int(data.get("unlocked_level", 1))

## Updates the high score if `score` beats the current one.
func report_score(score: int) -> void:
	if score > int(data.get("high_score", 0)):
		data["high_score"] = score
		save_game()

func get_high_score() -> int:
	return int(data.get("high_score", 0))

func set_setting(key: String, value) -> void:
	data["settings"][key] = value
	save_game()

func get_setting(key: String, default_value):
	return data.get("settings", {}).get(key, default_value)

## Writes `data` to disk as JSON.
func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: could not open save file for writing.")
		return
	file.store_string(JSON.stringify(data))
	file.close()

## Reads `data` from disk, if present; keeps defaults on any failure.
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		for key in parsed.keys():
			data[key] = parsed[key]
