extends Control

@export var building_manager: BuildingManager 

@export var build_list: Array[BuildingData] 

@onready var button_container: Container = $PanelContainer/ButtonContainer

func _ready():
	visible = false
	if GameData:
		GameData.game_state_changed.connect(_on_game_state_changed)
	
	_generate_buttons()

func _on_game_state_changed(old_state, new_state):
	if new_state == GState.state_enum.BUILD:
		visible = true
	else:
		visible = false
		if building_manager:
			building_manager.cancel_build()

func _generate_buttons():
	for child in button_container.get_children():
		child.queue_free()
		
	for data in build_list:
		if data == null: continue
		
		var btn = Button.new()
		
		btn.text = data.name if "name" in data else data.id
		
		btn.custom_minimum_size = Vector2(80, 40)
		
		btn.pressed.connect(_on_building_selected.bind(data))
		
		button_container.add_child(btn)

func _on_building_selected(data: BuildingData):
	if building_manager:
		print("🏗️ Chọn xây: ", data.id)
		building_manager.start_placing_building(data)
