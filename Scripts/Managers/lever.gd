#extends Node3D
#
## Path ke jail yang mau di-trigger — di-set dari editor atau world
#@export var target_jail: NodePath
#
#var is_activated: bool = false
#var player_nearby: bool = false
#
#@onready var anim_player = $AnimationPlayer
#
#func _ready():
	#pass
	#
#
#func _unhandled_input(event):
	#if not player_nearby:
		#return
	#if event.is_action_pressed("interact"):
		#_on_interact()
#
#func _on_interact():
	#if is_activated:
		## Sudah terbuka — tutup lagi
		#is_activated = false
		#anim_player.play("Lever2Bones|LeverSwitch2")  # animasi balik
		#if target_jail:
			#var jail = get_node(target_jail)
			#if jail:
				#jail.close_bar()
	#else:
		## Belum terbuka — buka
		#is_activated = true
		#anim_player.play("Lever2Bones|LeverSwitch")
		#if target_jail:
			#var jail = get_node(target_jail)
			#if jail:
				#jail.open_bar()
#
#func interact():
	#_on_interact()
#
#func _on_area_body_entered(body):
	#if body.is_in_group("player"):
		#player_nearby = true
		## Tampilkan prompt "Press F to interact"
		#print("Press F to interact")
#
#func _on_area_body_exited(body):
	#if body.is_in_group("player"):
		#player_nearby = false

extends Node3D

@export var target_jail: NodePath
var is_activated: bool = false
var player_nearby: bool = false

@onready var anim_player = $Lever2Bones/AnimationPlayer

func _ready():
	$InteractArea.body_entered.connect(_on_area_body_entered)
	$InteractArea.body_exited.connect(_on_area_body_exited)

func interact():
	_on_interact()

func _on_interact():
	if is_activated:
		is_activated = false
		anim_player.play("Lever2Bones|LeverSwitch2")
		if target_jail:
			var jail = get_node(target_jail)
			if jail:
				jail.close_bar()
	else:
		is_activated = true
		anim_player.play("Lever2Bones|LeverSwitch")
		if target_jail:
			var jail = get_node(target_jail)
			if jail:
				jail.open_bar()

func _on_area_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true
		print("Press F to interact")

func _on_area_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
