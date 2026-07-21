extends Node

func _on_pressed() -> void:
	var sniper = get_node("/root/Control/Node2D/Sniper")
	sniper.visible = !sniper.visible

	var panel = get_node("/root/Control/Panel")
	var panel2 = get_node("/root/Control/Panel2")
	panel.visible = !panel.visible
	panel2.visible = !panel2.visible
