extends Control

@onready var button_container = $Panel/VBoxContainer
@export var locations: Array[FastTravelLocation]

func _ready():
	visible = false
	# Clear placeholder buttons if any
	for child in button_container.get_children():
		child.queue_free()
	
	setup_buttons()

func setup_buttons():
	for loc in locations:
		var btn = Button.new()
		btn.text = loc.location_name
		btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_location_selected.bind(loc))
		button_container.add_child(btn)

func _unhandled_input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		close()

func open():
	print("DEBUG: [UI] open() called. Current locations count: ", locations.size())
	if locations.size() == 0:
		print("DEBUG: [UI] WARNING: No locations assigned to UI!")
		
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if button_container.get_child_count() > 0:
		button_container.get_child(0).grab_focus()
	else:
		print("DEBUG: [UI] No buttons to focus!")

func close():
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_location_selected(loc: FastTravelLocation):
	if loc.target_scene_path.is_empty():
		print("⚠️ Fast Travel: Target path is empty!")
		return

	if PlayerData.player and PlayerData.player.has_node("LimboHSM"):
		var current_state = PlayerData.player.limbo_hsm.get_active_state()
		PlayerData.is_transitioning_with_bike = (current_state.name == "BikingState")
		print("🚀 Fast Travel: Bike status - ", PlayerData.is_transitioning_with_bike)

	var current_level = get_tree().current_scene
	if current_level.has_method("save_level_state"):
		print("🚀 Fast Travel: Saving level data...")
		current_level.save_level_state()
	
	close()
	print("🚀 Fast Travel: Moving to ", loc.location_name)
	SceneTransition.change_scene(loc.target_scene_path, loc.target_spawn_position)
