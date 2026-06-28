extends Control

@onready var settings_panel = $SettingsPanel
@onready var btn_start = $ButtonContainer/BtnStart
@onready var btn_settings = $ButtonContainer/BtnSettings
@onready var btn_quit = $ButtonContainer/BtnQuit
@onready var btn_back = $SettingsPanel/BtnBack

func _ready():
	settings_panel.visible = false
	
	btn_start.pressed.connect(_on_start)
	btn_settings.pressed.connect(_on_settings)
	btn_quit.pressed.connect(_on_quit)
	btn_back.pressed.connect(_on_back)
	
	# Support controller — fokus ke tombol pertama
	btn_start.grab_focus()

func _on_start():
	get_tree().change_scene_to_file("res://Scenes/Levels/world.tscn")

func _on_settings():
	settings_panel.visible = true
	btn_back.grab_focus()

func _on_back():
	settings_panel.visible = false
	btn_settings.grab_focus()

func _on_quit():
	get_tree().quit()
