extends Node3D

signal lever_toggled(is_on)

var is_on: bool = false

@export var target_node_path: NodePath  # path ke pintu/object yang dikontrol

func interact():
	is_on = !is_on
	emit_signal("lever_toggled", is_on)
	print("Lever: ", "ON" if is_on else "OFF")
	
	# Kalau ada target node yang di-assign
	if target_node_path:
		var target = get_node(target_node_path)
		if target and target.has_method("on_lever_toggled"):
			target.on_lever_toggled(is_on)
