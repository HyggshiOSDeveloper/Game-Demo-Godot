extends Area2D
class_name LawnMower
## One lawn mower per lane, parked at the left edge. Triggers when a
## zombie reaches it, mowing down every zombie in the lane before
## disappearing (single-use per lane, PvZ-style).

signal triggered

@export var lane: int = 0
var _used: bool = false
var _speed: float = 500.0
var _moving: bool = false

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if _moving:
		global_position.x += _speed * delta
		if global_position.x > 2000:
			queue_free()

func _on_area_entered(area: Area2D) -> void:
	if _used:
		return
	if area.is_in_group("zombies"):
		_activate()

## Starts the mower rolling right, killing anything it touches, and
## marks this lane as no longer protected.
func _activate() -> void:
	_used = true
	_moving = true
	triggered.emit()
	AudioManager.play_sfx("zombie_die")

func is_used() -> bool:
	return _used
