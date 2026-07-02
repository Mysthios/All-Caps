extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.002
const HAT_SPEED = 8.0
const CAM_OFFSET = Vector3(0, 1.5, 3.5)
const MAX_STEP_HEIGHT: float = 0.5 

@onready var camera_holder = $CameraHolder
@onready var camera = $CameraHolder/Camera3D
@onready var interact_ray = $CameraHolder/Camera3D/InteractRay
@onready var hat_anchor = $HatAnchor
@onready var anim_player = $Superhero_Male_FullBody/AnimationPlayer
@onready var hud = $"../HUD"  # sesuaikan path kalau perlu


var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var hat_instance = null
var hat_scene = preload("res://Scenes/Player/hat.tscn")
var hat_out: bool = false
var hat_direction: Vector3 = Vector3.ZERO
var possessed_enemy = null
var _snapped_to_stairs_last_frame := false
var _last_frame_was_on_floor = -INF

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	interact_ray.add_exception(self)
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if not hat_out and possessed_enemy == null:
			# Mode normal — mouse look player
			rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			camera_holder.rotate_x(event.relative.y * MOUSE_SENSITIVITY)
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

	if event.is_action_pressed("interact") and possessed_enemy == null and not hat_out:
		_try_interact()

func _try_interact():
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider.has_method("interact"):
			collider.interact()


func throw_hat():
	hat_out = true
	hat_instance = hat_scene.instantiate()
	get_tree().root.add_child(hat_instance)

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

		if hat_instance.linear_velocity.length() > 0.1:
			var fly_dir = hat_instance.linear_velocity.normalized()
			var cam_offset = -fly_dir * 3.5 + Vector3(0, 1.5, 0)
			camera.global_position = hat_instance.global_position + cam_offset
			
			# kamera ngeliatin topi dari belakang
			camera.look_at(hat_instance.global_position, Vector3.UP)
			if not hat_out and possessed_enemy == null:
				if interact_ray.is_colliding():
					var collider = interact_ray.get_collider()
					if collider.has_method("interact"):
						$CanvasLayer/BoxContainer/InteractText.show()
					else:
						$CanvasLayer/BoxContainer/InteractText.hide()
			else:
				$CanvasLayer/BoxContainer/InteractText.hide()



# Note to followers of my previous tutorials: This function has been simplified but does the same thing.
func is_surface_too_steep(normal : Vector3) -> bool:
	return normal.angle_to(Vector3.UP) > self.floor_max_angle

func _snap_down_to_stairs_check()->void:
	var did_snap := false
	var was_on_floor_last_frame = Engine.get_physics_frames() - _last_frame_was_on_floor == 1
	if not is_on_floor() and velocity.y <= 0 and (was_on_floor_last_frame or _snapped_to_stairs_last_frame):
		var body_test_result = PhysicsTestMotionResult3D.new()
		if _run_body_motion_(self.global_transform, Vector3(0, -MAX_STEP_HEIGHT,0), body_test_result):
			var translate_y = body_test_result.get_travel().y
			self.position.y += translate_y
			apply_floor_snap()
			did_snap = true
	_snapped_to_stairs_last_frame = did_snap

func _snap_up_stairs_check(delta) -> bool:
	if not is_on_floor() and not _snapped_to_stairs_last_frame: return false
	# Don't snap stairs if trying to jump, also no need to check for stairs ahead if not moving
	if self.velocity.y > 0 or (self.velocity * Vector3(1,0,1)).length() == 0: return false
	var expected_move_motion = self.velocity * Vector3(1,0,1) * delta
	var step_pos_with_clearance = self.global_transform.translated(expected_move_motion + Vector3(0, MAX_STEP_HEIGHT * 2, 0))
	var down_check_result = KinematicCollision3D.new()
	if (self.test_move(step_pos_with_clearance, Vector3(0,-MAX_STEP_HEIGHT*2,0), down_check_result)
	and (down_check_result.get_collider().is_class("StaticBody3D") or down_check_result.get_collider().is_class("CSGShape3D"))):
		var step_height = ((step_pos_with_clearance.origin + down_check_result.get_travel()) - self.global_position).y
		if step_height > MAX_STEP_HEIGHT or step_height <= 0.01 or (down_check_result.get_position() - self.global_position).y > MAX_STEP_HEIGHT: return false
		%StairsAheadRayCast3D.global_position = down_check_result.get_position() + Vector3(0,MAX_STEP_HEIGHT,0) + expected_move_motion.normalized() * 0.1
		%StairsAheadRayCast3D.force_raycast_update()
		if %StairsAheadRayCast3D.is_colliding() and not is_surface_too_steep(%StairsAheadRayCast3D.get_collision_normal()):
			self.global_position = step_pos_with_clearance.origin + down_check_result.get_travel()
			apply_floor_snap()
			_snapped_to_stairs_last_frame = true
			return true
	return false

func _reset_camera_to(target_node: Node) -> void:
	camera.reparent(target_node)
	camera.position = Vector3.ZERO
	camera.rotation = Vector3.ZERO

func _return_hat():
	hat_out = false
	if hat_instance:
		hat_instance.queue_free()
		hat_instance = null
	_reset_camera_to(camera_holder)

func _on_hat_hit_enemy(enemy):
	_cleanup_hat()
	_possess_enemy(enemy)
	
func _possess_enemy(enemy):
	possessed_enemy = enemy
	enemy.get_possessed()
	
	# Cek dulu sebelum connect biar tidak double
	if not enemy.possess_expired.is_connected(_on_possess_expired):
		enemy.possess_expired.connect(_on_possess_expired)
	
	if hud:
		hud.show_possess_timer(enemy.POSSESS_DURATION)
	
	_reset_camera_to(enemy.get_node("CameraHolder"))
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _end_possession() -> void:
	hud.hide_possess_timer()
	if possessed_enemy:
		possessed_enemy._die()
		possessed_enemy = null
	_reset_camera_to(camera_holder)

func _on_possess_expired():
	_end_possession()

func _release_enemy():
	_end_possession()

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

func _run_body_motion_(from: Transform3D, motion: Vector3, result = null) -> bool:
	if result == null:
		result = PhysicsTestMotionResult3D.new()
	var params = PhysicsTestMotionParameters3D.new()
	params.from = from
	params.motion = motion
	return PhysicsServer3D.body_test_motion(self.get_rid(), params, result)


func _physics_process(delta):
	if is_on_floor() or _snapped_to_stairs_last_frame: 
		_last_frame_was_on_floor = Engine.get_physics_frames()

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
	var direction = (transform.basis * Vector3(-input_dir.x, 0, -input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if not _snap_up_stairs_check(delta):
		_snap_down_to_stairs_check()
		move_and_slide()
		_update_animation()  # ← setelah move_and_slide
