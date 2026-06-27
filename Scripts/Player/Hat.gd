extends RigidBody3D

# ==============================
# CAMERA TOPI — versi lama (kamera jadi child hat, ikut muter)
# @onready var hat_camera = $Camera3D
# func activate_hat_camera():
#     hat_camera.current = true
# func deactivate_hat_camera():
#     hat_camera.current = false
# ==============================

var is_flying: bool = false

signal hat_hit_enemy(enemy)
signal hat_landed
signal hat_expired

var return_timer: float = 0.0
const RETURN_TIME: float = 10.0  # ← custom waktu di sini
const GRAVITY: float = 9.8      # ← custom gravitasi topi di sini
const GRAVITY_SCALE: float = 0.0 # ← 1.0 = berat, 0.0 = melayang

func _ready():
	contact_monitor = true
	max_contacts_reported = 4

func throw(direction: Vector3, speed: float):
	is_flying = true
	linear_velocity = direction * speed
	angular_velocity = Vector3(0, 10, 0)  # topi muter
	return_timer = RETURN_TIME

func _process(delta):
	if not is_flying:
		return
	linear_velocity.y -= GRAVITY * GRAVITY_SCALE * delta
	return_timer -= delta
	if return_timer <= 0.0:
		_expire()

func _expire():
	is_flying = false
	emit_signal("hat_expired")

#func _on_body_entered(body):
	#if not is_flying:
		#return
	#print("Nabrak: ", body.name)
	#print("Is enemy: ", body.is_in_group("enemies"))
	#
	#if body.is_in_group("enemies"):
		#is_flying = false
		#emit_signal("hat_hit_enemy", body)
	#else:
		#is_flying = false
		#emit_signal("hat_expired") 

func _on_body_entered(body):
	if not is_flying:
		return
	if body.is_in_group("enemies"):
		is_flying = false
		emit_signal("hat_hit_enemy", body)
	else:
		is_flying = false
		emit_signal("hat_expired") #aku ganti ini dari hat_expired to hat_landed

#func _on_body_entered(body):
	#if not is_flying:
		#return
	#if body.is_in_group("enemies"):
		#is_flying = false
		#emit_signal("hat_hit_enemy", body)
	#else:
		#is_flying = false
		#linear_velocity = Vector3.ZERO
		#angular_velocity = Vector3.ZERO
		#emit_signal("hat_landed")
