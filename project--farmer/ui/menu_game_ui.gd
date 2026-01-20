extends Control

@onready var main_vbox = $PanelContainer/VBoxContainer 
@onready var play_options = $PanelContainer/PlayOptions 
@onready var save_slot_ui = $"../SaveSlotUI" 

func _ready() -> void:
	main_vbox.get_node("Start").pressed.connect(_on_start_pressed)
	
	play_options.get_node("NewGame").pressed.connect(_on_new_game_selected)
	play_options.get_node("LoadGame").pressed.connect(_on_load_game_selected)
	play_options.get_node("Back").pressed.connect(_on_back_pressed)
	
	main_vbox.show()
	play_options.hide()
	if save_slot_ui:
		save_slot_ui.hide()

func _on_start_pressed() -> void:
	main_vbox.hide()
	play_options.show()

func _on_back_pressed() -> void:
	play_options.hide()
	main_vbox.show()

func _on_new_game_selected() -> void:
	SceneTransition.change_scene("res://Scene/intro_cutscene.tscn", Vector3.ZERO)

func _on_load_game_selected() -> void:
	if save_slot_ui:
		save_slot_ui.is_loading_mode = true
		save_slot_ui.show()
