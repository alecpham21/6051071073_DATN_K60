extends CanvasLayer

@onready var control: Control = $Control
@onready var v_box: VBoxContainer = $Control/PanelContainer/VBoxContainer
@onready var save_slot_ui: Panel = $SaveSlotUI

func _ready() -> void:
	control.hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	v_box.get_node("ResumeBtn").pressed.connect(_on_resume_pressed)
	v_box.get_node("SaveBtn").pressed.connect(_on_save_pressed)
	v_box.get_node("MenuBtn").pressed.connect(_on_menu_pressed)
	v_box.get_node("ExitBtn").pressed.connect(_on_exit_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var current_scene = get_tree().current_scene
		if current_scene and current_scene.name == "MainMenu":
			return
		
		if save_slot_ui.visible:
			save_slot_ui.hide()
		else:
			toggle_pause()

func toggle_pause() -> void:
	var new_state = !get_tree().paused
	get_tree().paused = new_state
	control.visible = new_state
	
	if new_state:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		print("PAUSE_SYSTEM: Game Paused")
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		save_slot_ui.hide()
		print("PAUSE_SYSTEM: Game Resumed")

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
