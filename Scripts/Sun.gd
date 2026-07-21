extends Area2D
class_name Sun
## A collectible sun: either falls from the sky (spawned periodically by
## Main) or pops out of a Sunflower. Click/tap to collect.

@export var amount: int = 25
@export var fall_speed: float = 60.0
@export var fall_target_y: float = 400.0
@export var lifetime: float = 8.0 ## Seconds visible before auto-despawn.

var _falling: bool = false
var _timer: float = 0.0

func _ready() -> void:
	input_event.connect(_on_input_event)
	set_physics_process(true)

## Configures and (re)starts this sun instance. `target_y` is where it
## stops falling (ground level); pass target_y == start position's y for
## a sunflower "pop" (no falling).
func spawn(start_pos: Vector2, target_y: float, sun_amount: int = 25) -> void:
	global_position = start_pos
	fall_target_y = target_y
	amount = sun_amount
	_falling = global_position.y < fall_target_y
	_timer = 0.0
	visible = true
	monitoring = true

func _physics_process(delta: float) -> void:
	if not visible:
		return
	if _falling:
		global_position.y += fall_speed * delta
		if global_position.y >= fall_target_y:
			global_position.y = fall_target_y
			_falling = false
	_timer += delta
	if _timer >= lifetime:
		_despawn()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_collect()
	elif event is InputEventScreenTouch and event.pressed:
		_collect()

func _collect() -> void:
	SunManager.add_sun(amount)
	AudioManager.play_sfx("sun_collect")
	_despawn()

func _despawn() -> void:
	visible = false
	monitoring = false
