extends Node3D

func _ready():
	# Ambil semua waypoint
	var waypoint_nodes = $Waypoints.get_children()
	var waypoint_positions = []
	for wp in waypoint_nodes:
		waypoint_positions.append(wp.global_position)
	
	# Assign ke enemy
	# Kalau ada banyak enemy, bisa loop juga
	$enemy_female.set_waypoints(waypoint_positions)
