# GameManager.gd (Autoload)
extends Node

var current_state: String = "playing"  # "playing", "possessing", "dead"
var hat_in_air: bool = false
var possessed_enemy = null

signal state_changed(new_state)
signal hat_thrown
signal hat_returned
