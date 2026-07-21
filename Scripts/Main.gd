extends Node2D
## Main.gd — the battle scene root. Wires GridManager, PlantManager,
## ZombieManager and WaveManager together, spawns falling sun, forwards
## clicks to planting, and reacts to GameManager state changes to show
## the pause/victory/game-over UI.

@onready var grid_manager: GridManager = $GridManager
@onready var plant_manager: PlantManager = $PlantManager
@onready var zombie_manager: ZombieManager = $ZombieManager
@onready var wave_manager: WaveManager = $WaveManager

@onready var plants_layer: Node2D = $World/PlantsLayer
@onready var zombies_layer: Node2D = $World/ZombiesLayer
@onready var pea_layer: Node2D = $World/PeaLayer
@onready var sun_layer: Node2D = $World/SunLayer
@onready var mowers_layer: Node2D = $World/MowersLayer

@onready var seed_packet_bar = $UILayer/SeedPacketBar
@onready var sun_counter = $UILayer/SunCounter
@onready var wave_progress_bar = $UILayer/WaveProgressBar
@onready var pause_menu = $UILayer/PauseMenu
@onready var victory_screen = $UILayer/VictoryScreen
@onready var game_over_screen = $UILayer/GameOverScreen
@onready var pause_button: Button = $UILayer/PauseButton

@export var sun_scene: PackedScene
@export var lawn_mower_scene: PackedScene
@export var sun_fall_interval: float = 8.0
@export var sun_fall_amount: int = 25

var _sun_fall_timer: float = 0.0

func _ready() -> void:
	add_to_group("main")
	SunManager.reset(50)
	plant_manager.setup(grid_manager, plants_layer, pea_layer)
	zombie_manager.setup(grid_manager, zombies_layer)
	wave_manager.setup(zombie_manager)
	_spawn_lawn_mowers()

	seed_packet_bar.build(plant_manager.plant_data_list)
	seed_packet_bar.packet_pressed.connect(plant_manager.select_plant)
	plant_manager.cooldown_updated.connect(seed_packet_bar.set_cooldown)

	sun_counter.bind()
	wave_progress_bar.bind(wave_manager)

	pause_button.pressed.connect(GameManager.toggle_pause)
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.start_game(1)
	AudioManager.play_music("battle")

	pause_menu.visible = false
	victory_screen.visible = false
	game_over_screen.visible = false

func _spawn_lawn_mowers() -> void:
	for row in grid_manager.rows:
		var mower = lawn_mower_scene.instantiate()
		mowers_layer.add_child(mower)
		mower.lane = row
		mower.global_position = Vector2(grid_manager.grid_origin.x - 60, grid_manager.lane_y(row))
		mower.triggered.connect(func(): zombie_manager.mow_lane(row))

func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return
	_sun_fall_timer += delta
	if _sun_fall_timer >= sun_fall_interval:
		_sun_fall_timer = 0.0
		_spawn_falling_sun()

func _spawn_falling_sun() -> void:
	var x: float = grid_manager.grid_origin.x + randf() * grid_manager.columns * grid_manager.cell_size.x
	spawn_sun_at(Vector2(x, -40), grid_manager.grid_origin.y + 40, sun_fall_amount)

## Public helper used by both the periodic sky-fall and Sunflowers.
func spawn_sun_at(start_pos: Vector2, target_y: float, amount: int) -> void:
	var sun: Sun = sun_scene.instantiate()
	sun_layer.add_child(sun)
	sun.spawn(start_pos, target_y, amount)
	# Suns aren't pooled (low frequency); free once fully collected/expired.
	sun.tree_exiting.connect(func(): pass) # placeholder hook for future pooling

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		plant_manager.try_plant_at_world(get_global_mouse_position())
	elif event is InputEventScreenTouch and event.pressed:
		plant_manager.try_plant_at_world(event.position)

func _on_state_changed(state) -> void:
	pause_menu.visible = state == GameManager.State.PAUSED
	victory_screen.visible = state == GameManager.State.VICTORY
	game_over_screen.visible = state == GameManager.State.GAME_OVER
