extends Node
class_name PlantManager
## Handles seed selection and planting. Lives as a child of Main.tscn.
## Also owns the Pea object pool, since peas are always fired by plants.

@export var plant_scene: PackedScene
@export var pea_scene: PackedScene
@export var pea_pool_size: int = 24
@export var plant_data_list: Array[PlantData] = []

var _grid: GridManager
var _plants_layer: Node2D
var _pea_pool: Array[Pea] = []
var _selected_data: PlantData = null
var _cooldowns: Dictionary = {} ## plant_name -> seconds remaining

signal plant_selected(data: PlantData)
signal plant_placed(data: PlantData, col: int, row: int)
signal cooldown_updated(plant_name: String, fraction: float)

func setup(grid: GridManager, plants_layer: Node2D, pea_layer: Node2D) -> void:
	_grid = grid
	_plants_layer = plants_layer
	_init_pea_pool(pea_layer)
	set_process(true)

func _init_pea_pool(pea_layer: Node2D) -> void:
	for i in pea_pool_size:
		var pea: Pea = pea_scene.instantiate()
		pea.visible = false
		pea.monitoring = false
		pea_layer.add_child(pea)
		pea.hit_zombie.connect(_on_pea_hit_zombie)
		_pea_pool.append(pea)

## Returns an inactive Pea from the pool, or null if the pool is exhausted.
func get_pooled_pea() -> Pea:
	for pea in _pea_pool:
		if not pea.visible:
			return pea
	return null

func _on_pea_hit_zombie(zombie: Node2D, damage: int) -> void:
	if zombie is Zombie:
		zombie.take_damage(damage)

## Called by the seed packet UI when the player taps a packet.
func select_plant(data: PlantData) -> void:
	if _cooldowns.get(data.plant_name, 0.0) > 0.0:
		return
	if not SunManager.can_afford(data.cost):
		return
	_selected_data = data
	plant_selected.emit(data)

func deselect_plant() -> void:
	_selected_data = null

func has_selection() -> bool:
	return _selected_data != null

## Called by Main when the player taps a grid cell. Returns true if planted.
func try_plant_at_world(world_pos: Vector2) -> bool:
	if _selected_data == null:
		return false
	var cell: Vector2i = _grid.world_to_grid(world_pos)
	if cell.x < 0:
		return false
	if not _grid.is_cell_empty(cell.x, cell.y):
		return false
	if not SunManager.try_spend(_selected_data.cost):
		return false

	var plant: Plant = plant_scene.instantiate()
	_plants_layer.add_child(plant)
	plant.global_position = _grid.grid_to_world(cell.x, cell.y)
	plant.setup(_selected_data, _grid, cell.x, cell.y, get_pooled_pea)
	_grid.place_plant(cell.x, cell.y, plant)

	_cooldowns[_selected_data.plant_name] = _selected_data.cooldown
	plant_placed.emit(_selected_data, cell.x, cell.y)
	deselect_plant()
	return true

## Ticks per-plant-type cooldowns and broadcasts their remaining fraction
## (0..1) so the seed packet UI can draw a cooldown overlay.
func _process(delta: float) -> void:
	for plant_data in plant_data_list:
		var remaining: float = _cooldowns.get(plant_data.plant_name, 0.0)
		if remaining > 0.0:
			remaining = max(0.0, remaining - delta)
			_cooldowns[plant_data.plant_name] = remaining
			var fraction: float = remaining / plant_data.cooldown if plant_data.cooldown > 0 else 0.0
			cooldown_updated.emit(plant_data.plant_name, fraction)
