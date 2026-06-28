extends Panel

# Daftar action yang bisa di-remap
const ACTIONS = {
	"move_forward": "Move Forward",
	"move_back": "Move Back",
	"move_left": "Move Left",
	"move_right": "Move Right",
	"jump": "Jump",
	"throw_hat": "Throw Hat",
	"release_enemy": "Release Enemy"
}

@onready var keybind_list = $ScrollContainer/KeybindList

var listening_action: String = ""
var listening_button: Button = null

func _ready():
	_build_keybind_list()

func _build_keybind_list():
	# Clear dulu
	for child in keybind_list.get_children():
		child.queue_free()
	
	for action in ACTIONS:
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Label nama action
		var label = Label.new()
		label.text = ACTIONS[action]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 20)
		
		# Button keybind
		var btn = Button.new()
		btn.text = _get_key_name(action)
		btn.custom_minimum_size = Vector2(150, 40)
		btn.pressed.connect(_on_keybind_pressed.bind(action, btn))
		
		row.add_child(label)
		row.add_child(btn)
		keybind_list.add_child(row)

func _get_key_name(action: String) -> String:
	var events = InputMap.action_get_events(action)
	if events.is_empty():
		return "---"
	var event = events[0]
	if event is InputEventKey:
		return event.as_text()
	if event is InputEventJoypadButton:
		return "🎮 " + event.as_text()
	if event is InputEventMouseButton:
		return "Mouse " + str(event.button_index)
	return "---"

func _on_keybind_pressed(action: String, btn: Button):
	listening_action = action
	listening_button = btn
	btn.text = "Press any key..."

func _input(event):
	if listening_action == "":
		return
	
	# Terima keyboard, mouse, atau controller
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton:
		if event.is_pressed():
			# Remap action
			InputMap.action_erase_events(listening_action)
			InputMap.action_add_event(listening_action, event)
			listening_button.text = _get_key_name(listening_action)
			listening_action = ""
			listening_button = null
			get_viewport().set_input_as_handled()
