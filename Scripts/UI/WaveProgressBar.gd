extends ProgressBar
class_name WaveProgressBar
## Shows overall level progress (fraction of all zombies across all
## waves spawned so far) and flashes a "wave incoming" label at each
## new wave.

@onready var _label: Label = $WaveLabel

func bind(wave_manager: WaveManager) -> void:
	min_value = 0.0
	max_value = 1.0
	value = 0.0
	wave_manager.wave_progress.connect(func(fraction): value = fraction)
	wave_manager.wave_started.connect(_on_wave_started)

func _on_wave_started(wave_index: int, total_waves: int) -> void:
	_label.text = "Wave %d / %d" % [wave_index + 1, total_waves]
