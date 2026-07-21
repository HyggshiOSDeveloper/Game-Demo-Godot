extends HBoxContainer
class_name SeedPacketBar
## Builds one SeedPacket per available PlantData and re-broadcasts taps
## as `packet_pressed(data)`. Also dims packets the player can't afford.

signal packet_pressed(data: PlantData)

@export var seed_packet_scene: PackedScene
var _packets: Dictionary = {} ## plant_name -> SeedPacket

func build(plant_data_list: Array[PlantData]) -> void:
	for child in get_children():
		child.queue_free()
	_packets.clear()
	for data in plant_data_list:
		var packet: SeedPacket = seed_packet_scene.instantiate()
		add_child(packet)
		packet.setup(data)
		packet.pressed_with_data.connect(func(d): packet_pressed.emit(d))
		_packets[data.plant_name] = packet
	SunManager.sun_changed.connect(_on_sun_changed)
	_on_sun_changed(SunManager.sun)

func set_cooldown(plant_name: String, fraction: float) -> void:
	if _packets.has(plant_name):
		_packets[plant_name].set_cooldown(fraction)

func _on_sun_changed(new_amount: int) -> void:
	for plant_name in _packets:
		var packet: SeedPacket = _packets[plant_name]
		packet.set_affordable(new_amount >= packet.data.cost)
