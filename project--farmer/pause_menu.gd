extends CanvasLayer

@onready var control: Control = $Control
@onready var v_box: VBoxContainer = $Control/PanelContainer/VBoxContainer
@onready var setting_options: VBoxContainer = $Control/PanelContainer/SettingOptions
@onready var audio_settings: VBoxContainer = $Control/PanelContainer/AudioSettings
@onready var save_slot_ui: Panel = $SaveSlotUI
@onready var key_binding_menu: Control = $Control/KeyBindingMenu

func _ready() -> void:
	control.hide()
	setting_options.hide()
	audio_settings.hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	v_box.get_node("ResumeBtn").pressed.connect(_on_resume_pressed)
	v_box.get_node("SaveBtn").pressed.connect(_on_save_pressed)
	v_box.get_node("Setting").pressed.connect(_on_setting_pressed)
	v_box.get_node("MenuBtn").pressed.connect(_on_menu_pressed)
	v_box.get_node("ExitBtn").pressed.connect(_on_exit_pressed)
	
	setting_options.get_node("AudioBtn").pressed.connect(_on_audio_setting_pressed)
	setting_options.get_node("BackBtn").pressed.connect(_on_setting_back_pressed)
	
	setting_options.get_node("KeyBindBtn").pressed.connect(_on_key_bind_pressed)
	
	_setup_bus_slider("Master", audio_settings.get_node("MasterSlider"))
	_setup_bus_slider("Music", audio_settings.get_node("MusicSlider"))
	_setup_bus_slider("SFX", audio_settings.get_node("SFXSlider"))
	audio_settings.get_node("BackToSettingBtn").pressed.connect(_on_audio_back_pressed)
	
	key_binding_menu.visibility_changed.connect(_on_key_bind_visibility_changed)

func _on_key_bind_pressed() -> void:
	setting_options.hide()
	key_binding_menu.show()

func _on_key_bind_visibility_changed() -> void:
	if not key_binding_menu.visible and control.visible:
		setting_options.show()


func _on_setting_pressed() -> void:
	v_box.hide()
	setting_options.show()

func _on_setting_back_pressed() -> void:
	setting_options.hide()
	v_box.show()

func _on_audio_setting_pressed() -> void:
	setting_options.hide()
	audio_settings.show()

func _on_audio_back_pressed() -> void:
	audio_settings.hide()
	setting_options.show()

func _setup_bus_slider(bus_name: String, slider: HSlider) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		print("AUDIO_ERROR: Bus %s not found!" % bus_name)
		return
		
	slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus_index))
	
	slider.value_changed.connect(func(value):
		var db_value = linear_to_db(value)
		AudioServer.set_bus_volume_db(bus_index, db_value)
		print("AUDIO_SYSTEM: %s set to %f dB" % [bus_name, db_value])
	)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var current_scene = get_tree().current_scene
		if current_scene and current_scene.name == "MainMenu":
			return
		
		if save_slot_ui.visible:
			save_slot_ui.hide()
		elif key_binding_menu.visible and key_binding_menu.is_rebinding:
			return
		elif key_binding_menu.visible:
			key_binding_menu.hide()
		else:
			toggle_pause()
func toggle_pause() -> void:
	var new_state = !get_tree().paused
	get_tree().paused = new_state
	control.visible = new_state
	
	if new_state:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		audio_settings.hide()
		setting_options.hide()
		key_binding_menu.hide()
		v_box.show()
		save_slot_ui.hide()

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_save_pressed() -> void:
	save_slot_ui.is_loading_mode = false
	save_slot_ui.show()
	print("PAUSE_SYSTEM: Save Slot UI Opened")

func _on_menu_pressed() -> void:
	control.hide()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
