extends Area2D
class_name Pea
## A plant's projectile. Pooled by PlantManager/ZombieManager interaction:
## Pea nodes are never freed during play, only deactivated and reused
## (see reset()/deactivate()) to avoid per-shot instantiate/free cost.

signal hit_zombie(zombie: Node2D, damage: int)

@export var speed: float = 400.0
var damage: int = 20
var _active: bool = false

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	set_physics_process(false)

## Activates this pooled pea at `start_pos`, moving right at `dmg`.
func fire(start_pos: Vector2, dmg: int, spd: float) -> void:
	global_position = start_pos
	damage = dmg
	speed = spd
	visible = true
	monitoring = true
	_active = true
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if not _active:
		return
	global_position.x += speed * delta
	# Off-screen safety net: deactivate instead of leaking forever.
	if global_position.x > 2000:
		deactivate()

func _on_area_entered(area: Area2D) -> void:
	if not _active:
		return
	if area.is_in_group("zombies"):
		hit_zombie.emit(area, damage)
		deactivate()

## Returns this pea to its pool (called by self on hit, or by ZombieManager pool).
## `monitoring` must be changed with set_deferred(): this is frequently called
## from inside Pea's own area_entered signal, and Godot's physics server
## locks the Area2D against synchronous monitoring changes during that
## callback ("Condition 'locked' is true").
func deactivate() -> void:
	_active = false
	visible = false
	set_deferred("monitoring", false)
	set_physics_process(false)
