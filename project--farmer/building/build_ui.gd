extends Control

@export var building_manager: BuildingManager 
@export var build_list: Array[BuildingData] 
@export var slot_scene: PackedScene

@onready var content_container = $MainContainer/BlueprintPanel/VBoxContainer/ScrollContainer/ContentContainer

@onready var btn_house = $MainContainer/CategoryBar/BtnHouse
@onready var btn_farm = $MainContainer/CategoryBar/BtnFarm
@onready var btn_decor = $MainContainer/CategoryBar/BtnDecor

func _ready():
	visible = false
	if GameData:
		GameData.game_state_changed.connect(_on_game_state_changed)
	
	btn_house.pressed.connect(_load_category.bind(BuildingData.BuildingCategory.HOUSE))
	btn_farm.pressed.connect(_load_category.bind(BuildingData.BuildingCategory.FARM))
	btn_decor.pressed.connect(_load_category.bind(BuildingData.BuildingCategory.DECORATION))

func _on_game_state_changed(old_state, new_state):
	if new_state == GState.state_enum.BUILD:
		visible = true
		_load_category(BuildingData.BuildingCategory.HOUSE)
	else:
		visible = false
		if building_manager:
			building_manager.cancel_build()

func _load_category(category_type: int):
	print("📂 Load folder: ", category_type)
	
	for child in content_container.get_children():
		child.queue_free()
	
	for data in build_list:
		if data == null: continue
		
		if data.category == category_type:
			var slot = slot_scene.instantiate()
			content_container.add_child(slot)
			
			slot.setup(data)
			
			slot.request_build.connect(_on_slot_build_requested)

func _on_slot_build_requested(data: BuildingData):
	if building_manager:
		print("🏗️ Build Start: ", data.id)
		building_manager.start_placing_building(data)
		
		visible = false
