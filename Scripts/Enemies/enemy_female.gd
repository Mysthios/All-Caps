extends BaseEnemy

@onready var _model_anim = $Enemy_Female/AnimationPlayer

func _ready():
	anim_player = _model_anim
	super._ready()
	anim_player.play("AnimPack/Idle")
