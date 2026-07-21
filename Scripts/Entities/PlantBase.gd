class_name PlantBase
extends Node2D
## Base class for all plants. Subclasses (Sunflower, Peashooter, WallNut,
## CherryBomb) override the exported stats and hook their own behaviour
## into `_on_attack_tick()` / `_on_planted()` / `_on_death()`.
##
## Every plant shares: health, a grid position, damage-flash + death
## animation, and a signal other systems (GridManager) listen to when
## the plant dies so its grid tile frees up.

signal died(plant: PlantBase)
signal health_changed(current: int, max: int)

@export var plant_name: String = "Plant"
@export var cost: int = 50
@export var cooldown: float = 5.0        ## seconds before this seed can be replanted
@export var max_health: int = 100
@export var attack_damage: int = 20
@export var attack_interval: float = 1.5

var current_health: int
var grid_x: int = -1
var grid_y: int = -1
var _attack_timer: float = 0.0

@onready var visual: ColorRect = $Visual
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	current_health = max_health
	_on_planted()

func _process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	_attack_timer += delta
	if _attack_timer >= attack_interval:
		_attack_timer = 0.0
		_on_attack_tick()

## Applies damage, flashes the sprite, and triggers death at 0 HP.
func take_damage(amount: int) -> void:
	current_health -= amount
	emit_signal("health_changed", current_health, max_health)
	_flash_damage()
	if current_health <= 0:
		_die()

func _flash_damage() -> void:
	if anim_player and anim_player.has_animation("damage_flash"):
		anim_player.play("damage_flash")

func _die() -> void:
	_on_death()
	emit_signal("died", self)
	if anim_player and anim_player.has_animation("death"):
		anim_player.play("death")
		await anim_player.animation_finished
	queue_free()

# --- Overridable hooks for subclasses ---
func _on_planted() -> void:
	pass

func _on_attack_tick() -> void:
	pass

func _on_death() -> void:
	pass
