extends HBoxContainer

signal rebind_requested(action_name, button_node)

@onready var action_label: Label = $ActionLabel
@onready var key_button: Button = $KeyButton

var action_name: String = ""

func setup(action_id: String, display_name: String) -> void:
	action_name = action_id
	action_label.text = display_name
	update_key_display()
	
	key_button.pressed.connect(_on_key_button_pressed)

func update_key_display() -> void:
	var events = InputMap.action_get_events(action_name)
	if events.size() > 0:
		key_button.text = events[0].as_text().replace(" (Physical)", "")
	else:
		key_button.text = "None"

func _on_key_button_pressed() -> void:
	key_button.text = "???"
	rebind_requested.emit(action_name, key_button)

func set_waiting_style() -> void:
	key_button.release_focus()
