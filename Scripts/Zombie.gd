extends Area2D
class_name Zombie
## Generic zombie controller driven entirely by a ZombieData resource,
## so Basic/Conehead/Buckethead/Fast zombies share one script (no
## duplicated code). Designed for object pooling: use activate()/
## deactivate() rather than instantiate()/queue_free() during a wave.

signal died(zombie: Zombie)
signal reached_house(zombie: Zombie)

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _placeholder: ColorRect = $Placeholder
@onready var _health_bar: ProgressBar = $HealthBar
@onready var _hit_flash_timer: Timer = $HitFlashTimer

var data: ZombieData
var lane: int = 0
var health: int = 0
var armor: int = 0

var _target_plant: Plant = null
var _attack_timer: float = 0.0
var _active: bool = false
const HOUSE_X: float = 60.0 ## World X considered "reached the house".

func _ready() -> void:
	monitoring = true
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	_hit_flash_timer.timeout.connect(_on_hit_flash_timeout)
	set_physics_process(false)

## (Re)activates a pooled zombie with fresh stats at `start_pos` on `lane_index`.
func activate(zombie_data: ZombieData, lane_index: int, start_pos: Vector2) -> void:
	data = zombie_data
	lane = lane_index
	health = data.max_health
	armor = data.armor_health
	global_position = start_pos
	_target_plant = null
	_attack_timer = 0.0
	_active = true
	visible = true
	monitoring = true
	if data.texture:
		_sprite.texture = data.texture
		_sprite.visible = true
		_placeholder.visible = false
	else:
		_sprite.visible = false
		_placeholder.visible = true
	_update_health_bar()
	set_physics_process(true)
	_play_animation("walk")

func _physics_process(delta: float) -> void:
	if not _active:
		return
	if _target_plant and is_instance_valid(_target_plant) and _target_plant.is_alive():
		_attack_timer += delta
		if _attack_timer >= data.attack_interval:
			_attack_timer = 0.0
			_attack_plant()
	else:
		_target_plant = null
		_play_animation("walk")
		global_position.x -= data.speed * delta
		if global_position.x <= HOUSE_X:
			reached_house.emit(self)
			deactivate()

func _attack_plant() -> void:
	_play_animation("eat")
	AudioManager.play_sfx("bite")
	_target_plant.take_damage(data.attack_damage)

func _on_area_entered(area: Area2D) -> void:
	if area is Pea:
		return # handled by Pea's own signal in ZombieManager
	if area is Plant and area.lane == lane and _target_plant == null:
		_target_plant = area

func _on_area_exited(area: Area2D) -> void:
	if area == _target_plant:
		_target_plant = null

## Applies damage, armor first, then body health; flashes and may die.
func take_damage(amount: int) -> void:
	if not _active:
		return
	if armor > 0:
		armor = max(0, armor - amount)
	else:
		health -= amount
	_update_health_bar()
	_flash_damage()
	if health <= 0:
		_die()

func _die() -> void:
	_active = false
	_play_animation("death")
	AudioManager.play_sfx("zombie_die")
	GameManager.add_score(10)
	died.emit(self)
	# Actual pool-return/hide is handled by ZombieManager after the death
	# animation via deactivate(), so a brief death animation can play.

func deactivate() -> void:
	_active = false
	visible = false
	monitoring = false
	set_physics_process(false)
	_target_plant = null

func is_alive() -> bool:
	return _active and health > 0

func _update_health_bar() -> void:
	var total: int = data.max_health + data.armor_health
	var current: int = health + armor
	_health_bar.max_value = total
	_health_bar.value = current
	_health_bar.visible = current < total

func _flash_damage() -> void:
	# Simple damage flash: tint red briefly (works for sprite or placeholder).
	var target: CanvasItem = (_sprite as CanvasItem) if _sprite.visible else (_placeholder as CanvasItem)
	target.modulate = Color(1, 0.4, 0.4)
	_hit_flash_timer.start(0.12)

func _on_hit_flash_timeout() -> void:
	var target: CanvasItem = (_sprite as CanvasItem) if _sprite.visible else (_placeholder as CanvasItem)
	target.modulate = Color(1, 1, 1)

## Plays the given AnimationPlayer animation if it exists ("walk"/"eat"/"death").
func _play_animation(anim_name: String) -> void:
	var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
	if anim_player and anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
