extends BaseEnemy

@onready var _model_anim = $Enemy_Male/AnimationPlayer

func _ready():
	SPEED = 4.0
	PATROL_SPEED = 1.0
	POSSESS_DURATION = 7.0
	WAIT_TIME = 3.0
	anim_player = _model_anim
	super._ready()
	anim_player.play("AnimPack/Idle")
