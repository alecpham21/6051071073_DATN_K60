extends Control

const INPUT_ROW = preload("res://ui/input_row.tscn") 

@export var player_actions: PlayerActions 

@onready var action_list: VBoxContainer = $MainContainer/VBoxContainer/ScrollContainer/ActionList
@onready var return_btn: Button = $MainContainer/VBoxContainer/BottomButtons/ReturnBtn
@onready var reset_btn: Button = $MainContainer/VBoxContainer/BottomButtons/ResetBtn
@onready var save_btn: Button = $MainContainer/VBoxContainer/BottomButtons/SaveBtn

var is_rebinding: bool = false
var current_action: StringName = &""
var current_button: Button = null

var display_names = {
	"forward": "Move Forward",
	"back": "Move Backward",
	"left": "Move Left",
	"right": "Move Right",
	"interact": "Interact / Pick Up",
	"use_item": "Use Item",
	"running": "Sprint",
	"inventory": "Inventory",
	"toggle_journal": "Journal"
}

var default_map = {
	"forward": KEY_W,
	"back": KEY_S,
	"left": KEY_A,
	"right": KEY_D,
	"interact": KEY_F,
	"use_item": KEY_E,
	"running": KEY_SHIFT,
	"inventory": KEY_I,
	"toggle_journal": KEY_J
}

func update_ui_display() -> void:
	for row in action_list.get_children():
		if row.has_method("update_key_display"):
			row.update_key_display()

func _ready() -> void:
	_create_action_list()
	_load_keys_from_disk()
	
	visibility_changed.connect(func():
		if visible:
			update_ui_display()
	)
	
	return_btn.pressed.connect(func(): hide())
	reset_btn.pressed.connect(_on_reset_pressed)
	save_btn.pressed.connect(_on_save_pressed)
	
func _create_action_list() -> void:
	if not player_actions:
		print("KEYBIND_ERROR: Missing PlayerActions Resource!")
		return

	for child in action_list.get_children():
		child.queue_free()
	
	var targets = [
		player_actions.move_forward,
		player_actions.move_backward,
		player_actions.move_left,
		player_actions.move_right,
		player_actions.interact,
		player_actions.use_item,
		player_actions.run
	]

	for action in targets:
		if action == &"": continue
		var row = INPUT_ROW.instantiate()
		action_list.add_child(row)
		
		var d_name = display_names.get(action, str(action).capitalize())
		row.setup(action, d_name)
		row.rebind_requested.connect(_on_rebind_requested)

func _on_rebind_requested(action_name: String, button_node: Button) -> void:
	if is_rebinding: return
	
	is_rebinding = true
	current_action = action_name
	current_button = button_node
	current_button.text = "..." 
	
	current_button.release_focus()

func _unhandled_input(event: InputEvent) -> void:
	if not is_rebinding: return
	
	if (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed():
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			return
			
		_update_action_key(event)
		get_viewport().set_input_as_handled()

func _update_action_key(new_event: InputEvent) -> void:
	InputMap.action_erase_events(current_action)
	InputMap.action_add_event(current_action, new_event)
	
	current_button.text = new_event.as_text().replace(" (Physical)", "")
	
	is_rebinding = false
	current_action = &""
	current_button = null

func _on_reset_pressed() -> void:
	for action in default_map:
		var new_event = InputEventKey.new()
		new_event.keycode = default_map[action]
		
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, new_event)
	
	for row in action_list.get_children():
		if row.has_method("update_key_display"):
			row.update_key_display()
	print("INPUT_SYSTEM: Reset to defaults")

func _on_save_pressed() -> void:
	_save_keys_to_disk()
	print("INPUT_SYSTEM: Settings saved to config file")
	hide()

func _save_keys_to_disk() -> void:
	var config = ConfigFile.new()
	
	for action in display_names.keys():
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			config.set_value("Keybinding", action, events[0])
	
	config.save("user://settings.cfg")

func _load_keys_from_disk() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err != OK: return
	
	for action in config.get_section_keys("Keybinding"):
		var event = config.get_value("Keybinding", action)
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, event)
	
	update_ui_display()
