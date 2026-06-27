extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.002
const HAT_SPEED = 8.0
const CAM_OFFSET = Vector3(0, 1.5, 3.5)

@onready var camera_holder = $CameraHolder
@onready var camera = $CameraHolder/Camera3D
@onready var hat_anchor = $HatAnchor
@onready var anim_player = $Superhero_Male_FullBody/AnimationPlayer
@onready var hud = $"../HUD"  # sesuaikan path kalau perlu

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var hat_instance = null
var hat_scene = preload("res://Scenes/Player/hat.tscn")
var hat_out: bool = false
var hat_direction: Vector3 = Vector3.ZERO
var possessed_enemy = null

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if not hat_out and possessed_enemy == null:
			# Mode normal — mouse look player
			rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			camera_holder.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
			camera_holder.rotation.x = clamp(camera_holder.rotation.x, -1.2, 1.2)
		elif not hat_out and possessed_enemy != null:
			# Mode possess — mouse look enemy
			possessed_enemy.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			var cam_holder = possessed_enemy.get_node("CameraHolder")
			cam_holder.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
			cam_holder.rotation.x = clamp(cam_holder.rotation.x, -1.2, 1.2)
		else:
			# Mode hat — steer topi
			hat_direction.x += event.relative.x * MOUSE_SENSITIVITY * 0.5
			hat_direction.y -= event.relative.y * MOUSE_SENSITIVITY * 0.5

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event.is_action_pressed("throw_hat") and not hat_out and possessed_enemy == null:
		throw_hat()

	if event.is_action_pressed("release_enemy") and possessed_enemy:
		_release_enemy()

func throw_hat():
	hat_out = true
	hat_instance = hat_scene.instantiate()
	get_tree().root.add_child(hat_instance)

	#hat_instance.global_position = camera.global_position + (-camera.global_transform.basis.z * 0.5)
	hat_instance.global_position = camera.global_position + (-camera.global_transform.basis.z * 0.5) + Vector3(0, 0.3, 0)

	var throw_dir = -camera.global_transform.basis.z
	hat_instance.throw(throw_dir, HAT_SPEED)

	camera.reparent(get_tree().root)
	
	# Pastikan mouse tetap captured setelah reparent
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	hat_instance.hat_hit_enemy.connect(_on_hat_hit_enemy)
	hat_instance.hat_landed.connect(_on_hat_landed)
	hat_instance.hat_expired.connect(_on_hat_expired)
		
func _process(_delta):
	if hat_out and hat_instance:
		if hat_direction != Vector3.ZERO:
			var current_vel = hat_instance.linear_velocity
			var speed = current_vel.length()
			var yaw = -hat_direction.x * 2.0
			var pitch = hat_direction.y * 2.0
			var new_vel = current_vel.rotated(Vector3.UP, yaw)
			var right = new_vel.cross(Vector3.UP).normalized()
			new_vel = new_vel.rotated(right, pitch)
			hat_instance.linear_velocity = new_vel.normalized() * speed
			hat_direction = Vector3.ZERO

		# ganti bagian ini
		if hat_instance.linear_velocity.length() > 0.1:
			var fly_dir = hat_instance.linear_velocity.normalized()
			var cam_offset = -fly_dir * 3.5 + Vector3(0, 1.5, 0)
			camera.global_position = hat_instance.global_position + cam_offset
			
			# kamera ngeliatin topi dari belakang
			camera.look_at(hat_instance.global_position, Vector3.UP)

func _return_hat():
	hat_out = false
	if hat_instance:
		hat_instance.queue_free()
		hat_instance = null
	camera.reparent(camera_holder)
	camera.position = Vector3.ZERO
	camera.rotation = Vector3.ZERO

func _on_hat_hit_enemy(enemy):
	_cleanup_hat()
	_possess_enemy(enemy)
	
func _possess_enemy(enemy):
	possessed_enemy = enemy
	enemy.get_possessed()
	enemy.possess_expired.connect(_on_possess_expired)
	hud.show_possess_timer(enemy.POSSESS_DURATION)
	
	camera.reparent(enemy.get_node("CameraHolder"))
	camera.position = Vector3.ZERO
	camera.rotation = Vector3.ZERO
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_possess_expired():
	hud.hide_possess_timer()
	if possessed_enemy:
		possessed_enemy._die()
		possessed_enemy = null  # null dulu baru pindah kamera
	camera.reparent(camera_holder)
	camera.position = Vector3.ZERO
	camera.rotation = Vector3.ZERO

func _release_enemy():
	hud.hide_possess_timer()
	if possessed_enemy:
		possessed_enemy._die()
		possessed_enemy = null  # null dulu baru pindah kamera
	camera.reparent(camera_holder)
	camera.position = Vector3.ZERO
	camera.rotation = Vector3.ZERO

func _on_hat_landed():
	_return_hat()

func _on_hat_expired():
	_return_hat()
	

func _cleanup_hat():
	hat_out = false
	if hat_instance:
		hat_instance.queue_free()
		hat_instance = null

func _update_animation():
	# Kalau lagi possess enemy, player diam — tidak perlu animasi
	if possessed_enemy:
		anim_player.play("AnimPack/Idle")
		return
	
	# Kalau topi lagi terbang, player freeze di tempat
	if hat_out:
		anim_player.play("AnimPack/Idle")
		return

	#if velocity.y > 1.0:
		## Naik
		#anim_player.play("AnimPack/Jump_Start")
		#return
	#elif velocity.y < -1.0:
		## Turun
		#if anim_player.current_animation == "AnimPack/Jump_Land":
			#return  # tunggu landing animation selesai
		#anim_player.play("AnimPack/Jump")
		#return
	#elif not is_on_floor() == false and anim_player.current_animation == "AnimPack/Jump":
		## Baru landing
		#anim_player.play("AnimPack/Jump_Land")
		#return
		
	
	# Kalau tidak di lantai — cek naik atau turun
	if not is_on_floor():
		if velocity.y > 0:
			anim_player.play("AnimPack/Jump_Start")
		else:
			anim_player.play("AnimPack/Jump")
		return
	
	# Di lantai — cek baru landing
	if anim_player.current_animation == "AnimPack/Jump":
		anim_player.play("AnimPack/Jump_Land")
		return

	# Kalau bergerak
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_dir != Vector2.ZERO:
		anim_player.play("AnimPack/Jog_Fwd")
	else:
		anim_player.play("AnimPack/Idle")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if possessed_enemy:
		hud.update_possess_timer(possessed_enemy.possess_timer)
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		_update_animation()
		return

	if hat_out:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		move_and_slide()
		_update_animation()  # ← setelah move_and_slide
		return

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	_update_animation()  # ← setelah move_and_slide
