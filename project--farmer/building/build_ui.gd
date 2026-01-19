extends Control

@export var building_manager: BuildingManager 
@export var build_list: Array[BuildingData] 
@export var slot_scene: PackedScene

@onready var content_container = $MainContainer/BlueprintPanel/VBoxContainer/ScrollContainer/ContentContainer
@onready var blueprint_panel = $MainContainer/BlueprintPanel

@onready var btn_house = $MainContainer/CategoryBar/BtnHouse
@onready var btn_farm = $MainContainer/CategoryBar/BtnFarm
@onready var btn_decor = $MainContainer/CategoryBar/BtnDecor
@onready var btn_quest = $MainContainer/CategoryBar/BtnQuest
@onready var btn_destroy = $MainContainer/CategoryBar/BtnDestroy
@onready var btn_cancel_destroy = $MainContainer/CategoryBar/BtnCancelDestroy

func _ready():
	visible = false
	if GameData:
		GameData.game_state_changed.connect(_on_game_state_changed)
	
	btn_house.pressed.connect(_load_category.bind(BuildingData.BuildingCategory.HOUSE))
	btn_farm.pressed.connect(_load_category.bind(BuildingData.BuildingCategory.FARM))
	btn_decor.pressed.connect(_load_category.bind(BuildingData.BuildingCategory.DECORATION))
	btn_quest.pressed.connect(_load_category.bind(BuildingData.BuildingCategory.QUEST))
	
	if btn_destroy:
		btn_destroy.pressed.connect(_on_btn_destroy_pressed)
	
	if btn_cancel_destroy:
		btn_cancel_destroy.pressed.connect(_on_cancel_destroy_clicked)
		btn_cancel_destroy.visible = false

func _on_game_state_changed(_old_state, new_state):
	if new_state == GState.state_enum.BUILD:
		visible = true
		_reset_ui_state()
		_load_category(BuildingData.BuildingCategory.HOUSE)
	else:
		visible = false
		if building_manager:
			building_manager.cancel_build()
			building_manager.toggle_destroy_mode(false)

func _load_category(category_type: int):
	if building_manager and building_manager.is_destroy_mode:
		_on_cancel_destroy_clicked()
		
	print("📂 Load category: ", category_type)
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
		print("🏗️ Starting build: ", data.id)
		building_manager.start_placing_building(data)
		visible = false

func _on_btn_destroy_pressed():
	if building_manager:
		building_manager.toggle_destroy_mode(true)
		
		blueprint_panel.visible = false
		btn_destroy.visible = false
		_set_category_buttons_visible(false)
		
		btn_cancel_destroy.visible = true
		
		print("🔨 Destroy Mode: Only showing Cancel button")

func _on_cancel_destroy_clicked():
	if building_manager:
		building_manager.toggle_destroy_mode(false)
		_reset_ui_state()
		print("🔨 Exit Destroy Mode: Restoring UI")

func _reset_ui_state():
	blueprint_panel.visible = true
	btn_destroy.visible = true
	
	_set_category_buttons_visible(true)
	
	if btn_cancel_destroy:
		btn_cancel_destroy.visible = false

func _set_category_buttons_visible(is_visible: bool):
	btn_house.visible = is_visible
	btn_farm.visible = is_visible
	btn_decor.visible = is_visible
	btn_quest.visible = is_visible
