extends Node3D

@onready var anim_player = $AnimationPlayer

func open_bar():
	anim_player.play("BarOpen")

func close_bar():
	anim_player.play_backwards("BarOpen")
