extends Control

@onready var main_vbox = $PanelContainer/VBoxContainer 
@onready var play_options = $PanelContainer/PlayOptions 
@onready var save_slot_ui = $"../SaveSlotUI" 

@onready var setting_options: VBoxContainer = $PanelContainer/SettingOptions
@onready var audio_settings: VBoxContainer = $PanelContainer/AudioSettings
@onready var key_binding_menu: Control = $KeyBindingMenu

func _ready() -> void:
	play_options.hide()
	setting_options.hide()
	audio_settings.hide()
	if save_slot_ui: save_slot_ui.hide()
	
	main_vbox.get_node("Start").pressed.connect(_on_start_pressed)
	main_vbox.get_node("Setting").pressed.connect(_on_setting_pressed)
	main_vbox.get_node("Quit").pressed.connect(get_tree().quit)
	
	play_options.get_node("NewGame").pressed.connect(_on_new_game_selected)
	play_options.get_node("LoadGame").pressed.connect(_on_load_game_selected)
	play_options.get_node("Back").pressed.connect(_on_back_pressed)
	
	setting_options.get_node("AudioBtn").pressed.connect(_on_audio_setting_pressed)
	setting_options.get_node("KeyBindBtn").pressed.connect(_on_key_bind_pressed)
	setting_options.get_node("BackBtn").pressed.connect(_on_setting_back_pressed)
	
	_setup_bus_slider("Master", audio_settings.get_node("MasterSlider"))
	_setup_bus_slider("Music", audio_settings.get_node("MusicSlider"))
	_setup_bus_slider("SFX", audio_settings.get_node("SFXSlider"))
	audio_settings.get_node("BackToSettingBtn").pressed.connect(_on_audio_back_pressed)

	key_binding_menu.visibility_changed.connect(_on_key_bind_visibility_changed)
	
func _on_start_pressed() -> void:
	main_vbox.hide()
	play_options.show()

func _on_setting_pressed() -> void:
	main_vbox.hide()
	setting_options.show()

func _on_setting_back_pressed() -> void:
	setting_options.hide()
	main_vbox.show()

func _on_audio_setting_pressed() -> void:
	setting_options.hide()
	audio_settings.show()

func _on_audio_back_pressed() -> void:
	audio_settings.hide()
	setting_options.show()

func _on_key_bind_pressed() -> void:
	setting_options.hide()
	key_binding_menu.show()

func _on_back_pressed() -> void:
	play_options.hide()
	main_vbox.show()

func _on_key_bind_visibility_changed() -> void:
	if not key_binding_menu.visible:
		setting_options.show()


func _setup_bus_slider(bus_name: String, slider: HSlider) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1: return
	slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus_index))
	slider.value_changed.connect(func(value):
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
	)


func _on_new_game_selected() -> void:
	SceneTransition.change_scene("res://Scene/intro_cutscene.tscn", Vector3.ZERO)

func _on_load_game_selected() -> void:
	if save_slot_ui:
		save_slot_ui.is_loading_mode = true
		save_slot_ui.show()
