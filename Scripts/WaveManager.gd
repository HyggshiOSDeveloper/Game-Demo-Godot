extends Node
class_name WaveManager
## Drives zombie wave progression: spawns zombies from each WaveData in
## sequence, waits for the board to clear, and signals victory after the
## final wave. Lives as a child of Main.tscn.

@export var waves: Array[WaveData] = []
@export var rows: int = 5
@export var time_between_waves: float = 6.0

var _zombie_manager: ZombieManager
var _current_wave_index: int = -1
var _spawned_this_wave: int = 0
var _spawn_timer: float = 0.0
var _waiting_for_next_wave: bool = false
var _wave_active: bool = false

signal wave_started(wave_index: int, total_waves: int)
signal wave_progress(fraction: float) ## 0..1 across the whole level, for the progress bar.
signal all_waves_cleared

func setup(zombie_manager: ZombieManager) -> void:
	_zombie_manager = zombie_manager
	_zombie_manager.wave_cleared.connect(_on_board_cleared)
	_start_next_wave()
	set_process(true)

func _start_next_wave() -> void:
	_current_wave_index += 1
	if _current_wave_index >= waves.size():
		return
	_spawned_this_wave = 0
	_spawn_timer = 0.0
	_wave_active = true
	wave_started.emit(_current_wave_index, waves.size())

func _process(delta: float) -> void:
	if _waiting_for_next_wave:
		_spawn_timer += delta
		if _spawn_timer >= time_between_waves:
			_waiting_for_next_wave = false
			_start_next_wave()
		return

	if not _wave_active:
		return
	var wave: WaveData = waves[_current_wave_index]
	if _spawned_this_wave >= wave.zombie_count:
		_wave_active = false
		return

	_spawn_timer += delta
	if _spawn_timer >= wave.spawn_interval:
		_spawn_timer = 0.0
		_spawn_one(wave)
		_spawned_this_wave += 1
		_emit_progress()

func _spawn_one(wave: WaveData) -> void:
	if wave.zombies.is_empty():
		return
	var data: ZombieData = wave.zombies[randi() % wave.zombies.size()]
	var lane: int = randi() % rows
	_zombie_manager.spawn_zombie(data, lane)

func _on_board_cleared() -> void:
	# Only advance if we've finished *spawning* the current wave too.
	if _wave_active:
		return
	if _current_wave_index >= waves.size() - 1:
		all_waves_cleared.emit()
		GameManager.win_game()
	else:
		_waiting_for_next_wave = true
		_spawn_timer = 0.0

func _emit_progress() -> void:
	var total: int = 0
	var done: int = 0
	for i in waves.size():
		total += waves[i].zombie_count
		if i < _current_wave_index:
			done += waves[i].zombie_count
		elif i == _current_wave_index:
			done += _spawned_this_wave
	wave_progress.emit(float(done) / float(max(total, 1)))
