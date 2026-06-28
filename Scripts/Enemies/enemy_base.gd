class_name BaseEnemy
extends CharacterBody3D

# ============================================================
# CONSTANTS & VARIABLES
# ============================================================
const WAYPOINT_THRESHOLD = 0.5

var SPEED: float = 7.0
var PATROL_SPEED: float = 1.5
var WAIT_TIME: float = 1.5
var POSSESS_DURATION: float = 10.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var anim_player: AnimationPlayer = null

# State
enum State { PATROL, POSSESSED, STUNNED }
var current_state: State = State.PATROL

# Flags
var is_possessed: bool = false
var is_dying: bool = false
var is_waiting: bool = false

# Timers
var possess_timer: float = 0.0
var wait_timer: float = 0.0

# Waypoints
var waypoints: Array = []
var current_waypoint: int = 0

# Signals
signal possess_expired
signal enemy_possessed
signal enemy_released

# ============================================================
# LIFECYCLE
# ============================================================
func _ready():
	add_to_group("enemies")
	if anim_player:
		anim_player.play("AnimPack/Idle")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	match current_state:
		State.PATROL:
			_do_patrol(delta)
		State.POSSESSED:
			_do_possessed(delta)
			possess_timer -= delta
			if possess_timer <= 0.0:
				emit_signal("possess_expired")
		State.STUNNED:
			pass

	move_and_slide()
	_update_animation()

# ============================================================
# MOVEMENT
# ============================================================
func _do_patrol(_delta):
	if waypoints.is_empty():
		velocity.x = 0
		velocity.z = 0
		return

	if is_waiting:
		velocity.x = 0
		velocity.z = 0
		wait_timer -= _delta
		if wait_timer <= 0.0:
			is_waiting = false
			current_waypoint = (current_waypoint + 1) % waypoints.size()
		return

	var target = waypoints[current_waypoint]
	var direction = (target - global_position)
	direction.y = 0
	var distance = direction.length()

	if distance < WAYPOINT_THRESHOLD:
		is_waiting = true
		wait_timer = WAIT_TIME
		velocity.x = 0
		velocity.z = 0
	else:
		direction = direction.normalized()
		velocity.x = direction.x * PATROL_SPEED
		velocity.z = direction.z * PATROL_SPEED
		look_at(global_position + Vector3(direction.x, 0, direction.z), Vector3.UP)

func _do_possessed(_delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

# ============================================================
# POSSESSION
# ============================================================
func get_possessed():
	current_state = State.POSSESSED
	is_possessed = true
	possess_timer = POSSESS_DURATION
	emit_signal("enemy_possessed")
	_set_color(Color.BLUE)

func _die():
	current_state = State.STUNNED
	is_possessed = false
	is_dying = true
	is_waiting = false        # ← reset waiting
	current_waypoint = 0     # ← balik ke waypoint pertama
	velocity = Vector3.ZERO
	_set_color(Color.RED)
	await get_tree().create_timer(5.0).timeout
	is_dying = false
	current_state = State.PATROL

func get_released():
	current_state = State.STUNNED
	is_possessed = false
	emit_signal("enemy_released")
	_set_color(Color.RED)

# ============================================================
# ANIMATION
# ============================================================
func _update_animation():
	if not anim_player:
		return

	match current_state:
		State.PATROL:
			if waypoints.is_empty() or velocity.length() < 0.1:
				anim_player.play("AnimPack/Idle")
				anim_player.speed_scale = 1.0
			else:
				anim_player.play("AnimPack/Walk")
				anim_player.speed_scale = velocity.length() / PATROL_SPEED
		State.POSSESSED:
			var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
			if input_dir != Vector2.ZERO:
				anim_player.play("AnimPack/Jog_Fwd")
				anim_player.speed_scale = velocity.length() / SPEED
			else:
				anim_player.play("AnimPack/Idle")
				anim_player.speed_scale = 1.0
		State.STUNNED:
			if is_dying and anim_player.current_animation != "AnimPack/Death01":
				anim_player.play("AnimPack/Death01")
				anim_player.speed_scale = 1.0

# ============================================================
# HELPERS
# ============================================================
func set_waypoints(points: Array):
	waypoints = points

func _set_color(color: Color):
	var mesh = find_child("*", true, false) as MeshInstance3D
	if mesh:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mesh.set_surface_override_material(0, mat)

# ============================================================
# UNUSED / DEPRECATED
# ============================================================
# func get_possessed() — versi lama pakai $Enemy_Female langsung
# func get_released() — versi lama pakai $Enemy_Female langsung
