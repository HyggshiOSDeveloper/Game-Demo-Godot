extends Node
class_name ZombieManager
## Owns the zombie object pool and per-lane spawning/tracking. Lives as a
## child of Main.tscn. WaveManager calls spawn_zombie(); Plant.gd (cherry
## bomb) calls damage_area(); LawnMower nodes report through mower_triggered.

@export var zombie_scene: PackedScene
@export var pool_size: int = 30

var _pool: Array[Zombie] = []
var _active_zombies: Array[Zombie] = []
var _grid: GridManager
var _zombies_layer: Node2D

signal zombie_died(zombie: Zombie)
signal zombie_reached_house(zombie: Zombie)
signal wave_cleared

func setup(grid: GridManager, zombies_layer: Node2D) -> void:
	_grid = grid
	_zombies_layer = zombies_layer
	add_to_group("zombie_manager")
	for i in pool_size:
		var z: Zombie = zombie_scene.instantiate()
		z.visible = false
		z.monitoring = false
		z.add_to_group("zombies")
		_zombies_layer.add_child(z)
		z.died.connect(_on_zombie_died)
		z.reached_house.connect(_on_zombie_reached_house)
		_pool.append(z)

## Pulls an inactive zombie from the pool and activates it at the right
## edge of `lane`. Returns false (and does nothing) if the pool is full.
func spawn_zombie(data: ZombieData, lane: int) -> bool:
	var zombie: Zombie = _get_pooled_zombie()
	if zombie == null:
		push_warning("ZombieManager: pool exhausted, increase pool_size.")
		return false
	var start_pos := Vector2(1400, _grid.lane_y(lane))
	zombie.activate(data, lane, start_pos)
	_active_zombies.append(zombie)
	return true

func _get_pooled_zombie() -> Zombie:
	for z in _pool:
		if not z.visible:
			return z
	return null

func _on_zombie_died(zombie: Zombie) -> void:
	# Let the death animation play briefly, then truly return to pool.
	var t := get_tree().create_timer(0.4)
	t.timeout.connect(func():
		zombie.deactivate()
		_active_zombies.erase(zombie)
		zombie_died.emit(zombie)
		_check_wave_cleared()
	)

func _on_zombie_reached_house(zombie: Zombie) -> void:
	_active_zombies.erase(zombie)
	zombie_reached_house.emit(zombie)
	GameManager.lose_game()

## Called by a LawnMower when it activates: kills every active zombie in `lane`.
func mow_lane(lane: int) -> void:
	for z in _active_zombies.duplicate():
		if z.lane == lane:
			z.take_damage(99999)

## Called by Plant.gd for area-of-effect damage (Cherry Bomb). `center_row`/
## `center_col` is the plant's cell; `radius_cells` cells around it are hit.
func damage_area(center_row: int, center_col: int, radius_cells: int, damage: int, grid: GridManager) -> void:
	for z in _active_zombies.duplicate():
		if z.lane != center_row:
			continue
		var z_col: int = int(floor((z.global_position.x - grid.grid_origin.x) / grid.cell_size.x))
		if abs(z_col - center_col) <= radius_cells:
			z.take_damage(damage)

func get_active_count() -> int:
	return _active_zombies.size()

## Only meaningful once WaveManager has stopped spawning; UI/WaveManager
## use this signal to know when the board is fully clear.
func _check_wave_cleared() -> void:
	if _active_zombies.is_empty():
		wave_cleared.emit()
