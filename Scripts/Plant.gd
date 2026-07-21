extends Area2D
class_name Plant
## Generic plant controller driven entirely by a PlantData resource, so
## Sunflower/Peashooter/WallNut/CherryBomb share one script (no
## duplicated code). Instantiated fresh per placement by PlantManager
## (plants are not pooled since they're far less numerous than zombies/peas).

signal died(plant: Plant)
signal ammo_changed(current: int, max_ammo: int) ## For future UI (e.g. an ammo counter over the plant).

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _placeholder: ColorRect = $Placeholder
@onready var _health_bar: ProgressBar = $HealthBar
@onready var _hit_flash_timer: Timer = $HitFlashTimer
@onready var _attack_timer_node: Timer = $AttackTimer
@onready var _sun_timer_node: Timer = $SunTimer
@onready var _fuse_timer_node: Timer = $FuseTimer
@onready var _reload_timer_node: Timer = $ReloadTimer

var data: PlantData
var col: int = 0
var row: int = 0
var lane: int = 0
var health: int = 0
var current_ammo: int = 0
var _grid: GridManager
var _pea_pool_getter: Callable ## Injected by PlantManager: Callable -> Pea

func _ready() -> void:
	monitoring = false
	_hit_flash_timer.timeout.connect(_on_hit_flash_timeout)
	_attack_timer_node.timeout.connect(_on_attack_timer_timeout)
	_sun_timer_node.timeout.connect(_on_sun_timer_timeout)
	_fuse_timer_node.timeout.connect(_on_fuse_timer_timeout)
	_reload_timer_node.timeout.connect(_on_reload_timer_timeout)
	_reload_timer_node.one_shot = true

## Configures this freshly-instantiated plant. Called once by PlantManager
## right after instancing Plant.tscn.
func setup(plant_data: PlantData, grid: GridManager, grid_col: int, grid_row: int, pea_pool_getter: Callable) -> void:
	data = plant_data
	_grid = grid
	col = grid_col
	row = grid_row
	lane = grid_row
	health = data.max_health
	_pea_pool_getter = pea_pool_getter
	add_to_group("plants")

	if data.texture:
		_sprite.texture = data.texture
		_sprite.visible = true
		_placeholder.visible = false
		_fit_sprite_to_cell()
	else:
		_sprite.visible = false
		_placeholder.visible = true
	_update_health_bar()
	AudioManager.play_sfx("plant")

	if data.can_attack:
		_attack_timer_node.wait_time = data.attack_interval
		_attack_timer_node.start()
		if data.max_ammo > 0:
			current_ammo = data.max_ammo
			ammo_changed.emit(current_ammo, data.max_ammo)
	if data.produces_sun:
		_sun_timer_node.wait_time = data.sun_interval
		_sun_timer_node.start()
	if data.is_instant:
		_fuse_timer_node.wait_time = data.fuse_time
		_fuse_timer_node.start()

func is_alive() -> bool:
	return health > 0

## Applies damage from a zombie bite; flashes red and may trigger death.
func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health -= amount
	_update_health_bar()
	_flash_damage()
	if health <= 0:
		_die()

func _die() -> void:
	_play_animation("death")
	AudioManager.play_sfx("zombie_die")
	_grid.clear_cell(col, row)
	died.emit(self)
	# Give the death animation a beat before freeing.
	var t := get_tree().create_timer(0.3)
	t.timeout.connect(queue_free)

## Peashooter-style: fires a pooled Pea down this lane if a zombie is present.
## Consumes ammo when data.max_ammo > 0; once ammo hits zero, stops firing
## and kicks off a reload (see _start_reload / _on_reload_timer_timeout).
func _on_attack_timer_timeout() -> void:
	if not is_alive():
		return
	var pea: Pea = _pea_pool_getter.call()
	if pea == null:
		return
	_play_animation("attack")
	if data.attack_sound:
		AudioManager.play_stream(data.attack_sound)
	else:
		AudioManager.play_sfx("shoot")
	var muzzle: Vector2 = global_position + Vector2(30, 0)
	pea.fire(muzzle, data.attack_damage, data.projectile_speed)

	if data.max_ammo > 0:
		current_ammo -= 1
		ammo_changed.emit(current_ammo, data.max_ammo)
		if current_ammo <= 0:
			_start_reload()

## Stops firing and starts the reload countdown.
func _start_reload() -> void:
	_attack_timer_node.stop()
	_reload_timer_node.wait_time = data.reload_time
	_reload_timer_node.start()

## Refills ammo and resumes firing once the reload timer elapses.
func _on_reload_timer_timeout() -> void:
	current_ammo = data.max_ammo
	ammo_changed.emit(current_ammo, data.max_ammo)
	if is_alive():
		_attack_timer_node.start()

## Sunflower-style: periodically pops a Sun instance at this plant's position.
func _on_sun_timer_timeout() -> void:
	if not is_alive():
		return
	var main: Node = get_tree().get_first_node_in_group("main")
	if main and main.has_method("spawn_sun_at"):
		main.spawn_sun_at(global_position, global_position.y, data.sun_amount)

## Cherry Bomb-style: explodes in a radius, damaging all zombies in range,
## then removes itself.
func _on_fuse_timer_timeout() -> void:
	_play_animation("explode")
	AudioManager.play_sfx("explosion")
	var zombie_manager: Node = get_tree().get_first_node_in_group("zombie_manager")
	if zombie_manager and zombie_manager.has_method("damage_area"):
		zombie_manager.damage_area(row, col, data.explosion_radius_cells, data.explosion_damage, _grid)
	_grid.clear_cell(col, row)
	queue_free()

## Scales the sprite so any source art (arbitrary resolution) fits neatly
## inside the plant's grid cell footprint while preserving aspect ratio.
func _fit_sprite_to_cell() -> void:
	var tex_size: Vector2 = _sprite.texture.get_size()
	if tex_size.x <= 0 or tex_size.y <= 0:
		return
	const TARGET_SIZE := Vector2(70, 86)
	var uniform_scale: float = min(TARGET_SIZE.x / tex_size.x, TARGET_SIZE.y / tex_size.y)
	_sprite.scale = Vector2(uniform_scale, uniform_scale)

func _update_health_bar() -> void:
	_health_bar.max_value = data.max_health
	_health_bar.value = health
	_health_bar.visible = health < data.max_health

func _flash_damage() -> void:
	var target: CanvasItem = (_sprite as CanvasItem) if _sprite.visible else (_placeholder as CanvasItem)
	target.modulate = Color(1, 0.4, 0.4)
	_hit_flash_timer.start(0.12)

func _on_hit_flash_timeout() -> void:
	var target: CanvasItem = (_sprite as CanvasItem) if _sprite.visible else (_placeholder as CanvasItem)
	target.modulate = Color(1, 1, 1)

func _play_animation(anim_name: String) -> void:
	var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
	if anim_player and anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
