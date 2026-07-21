extends Label
class_name SunCounter
## Displays the player's current sun total, updated via SunManager's signal.

func bind() -> void:
	SunManager.sun_changed.connect(_on_sun_changed)
	_on_sun_changed(SunManager.sun)

func _on_sun_changed(new_amount: int) -> void:
	text = str(new_amount)
