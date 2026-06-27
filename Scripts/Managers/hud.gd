extends CanvasLayer

@onready var possess_timer_label = $Label

func show_possess_timer(duration: float):
	possess_timer_label.visible = true
	possess_timer_label.text = str(int(duration))

func update_possess_timer(time_left: float):
	possess_timer_label.text = str(int(time_left) + 1)

func hide_possess_timer():
	possess_timer_label.visible = false
