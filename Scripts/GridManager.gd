extends Node2D
class_name GridManager
## Owns the planting grid: converts between grid coordinates (col,row)
## and world pixels, and tracks which cells are occupied. Lives as a
## child of Main.tscn (not an autoload) because it's specific to a
## single battle instance.

signal cell_planted(col: int, row: int, plant: Node2D)
signal cell_cleared(col: int, row: int)

@export var columns: int = 9
@export var rows: int = 5
@export var cell_size: Vector2 = Vector2(80, 100)
@export var grid_origin: Vector2 = Vector2(180, 80) ## Top-left world position of cell (0,0).

## occupied[row][col] = Plant node or null.
var _occupied: Array = []

func _ready() -> void:
	_occupied.resize(rows)
	for r in rows:
		var row_array: Array = []
		row_array.resize(columns)
		_occupied[r] = row_array

func is_valid_cell(col: int, row: int) -> bool:
	return col >= 0 and col < columns and row >= 0 and row < rows

func is_cell_empty(col: int, row: int) -> bool:
	return is_valid_cell(col, row) and _occupied[row][col] == null

## Converts a grid cell to the world-space position of its center.
func grid_to_world(col: int, row: int) -> Vector2:
	return grid_origin + Vector2(col * cell_size.x + cell_size.x / 2.0, row * cell_size.y + cell_size.y / 2.0)

## Converts a world position to the grid cell it falls in, or (-1,-1) if outside.
func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local: Vector2 = world_pos - grid_origin
	var col: int = int(floor(local.x / cell_size.x))
	var row: int = int(floor(local.y / cell_size.y))
	if not is_valid_cell(col, row):
		return Vector2i(-1, -1)
	return Vector2i(col, row)

## Registers `plant` as occupying (col,row). Caller must have already
## checked is_cell_empty().
func place_plant(col: int, row: int, plant: Node2D) -> void:
	_occupied[row][col] = plant
	cell_planted.emit(col, row, plant)

## Frees (col,row); called when a plant dies or is dug up.
func clear_cell(col: int, row: int) -> void:
	if is_valid_cell(col, row):
		_occupied[row][col] = null
		cell_cleared.emit(col, row)

func get_plant_at(col: int, row: int) -> Node2D:
	if not is_valid_cell(col, row):
		return null
	return _occupied[row][col]

## Returns the world Y center of `row`, used to keep zombies/mowers aligned.
func lane_y(row: int) -> float:
	return grid_origin.y + row * cell_size.y + cell_size.y / 2.0
