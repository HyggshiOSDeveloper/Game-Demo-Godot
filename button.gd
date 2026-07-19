extends Node

func _on_pressed() -> void:
	var sniper = get_node("/root/Control/Node2D/Sniper")
	sniper.visible = !sniper.visible
