extends Button
class_name SeedPacket
## A single seed packet in the SeedPacketBar: shows icon, cost, and a
## cooldown overlay. Emits `pressed_with_data` so the bar (and
## ultimately PlantManager) knows which PlantData to select.

signal pressed_with_data(data: PlantData)

@onready var _icon: TextureRect = $Icon
@onready var _cost_label: Label = $CostLabel
@onready var _cooldown_overlay: ColorRect = $CooldownOverlay

var data: PlantData

func setup(plant_data: PlantData) -> void:
	data = plant_data
	_cost_label.text = str(data.cost)
	if data.icon:
		_icon.texture = data.icon
	_cooldown_overlay.anchor_top = 0.0
	pressed.connect(func(): pressed_with_data.emit(data))

## fraction: 0 = ready, 1 = just used. Draws a bottom-up cooldown wipe
## and dims the button while affordability/cooldown blocks planting.
func set_cooldown(fraction: float) -> void:
	_cooldown_overlay.visible = fraction > 0.0
	_cooldown_overlay.anchor_top = 1.0 - fraction
	_cooldown_overlay.offset_top = 0

func set_affordable(can_afford: bool) -> void:
	modulate = Color(1, 1, 1) if can_afford else Color(0.6, 0.6, 0.6)
