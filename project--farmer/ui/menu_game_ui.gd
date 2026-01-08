extends Control

@onready var start_button = $PanelContainer/VBoxContainer/Start

func _ready():
	start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed():
	SceneTransition.change_scene(
		"res://Scene/intro_cutscene.tscn",
		Vector3.ZERO
	)
