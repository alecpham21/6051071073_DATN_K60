extends PanelContainer

signal request_build(data: BuildingData)

@onready var icon_rect: TextureRect = $HBoxContainer/IconRect
@onready var name_label: Label = $HBoxContainer/InfoContainer/NameLabel
@onready var build_btn: Button = $HBoxContainer/ActionContainer/BuildButton

var current_data: BuildingData

func setup(data: BuildingData):
	current_data = data
	name_label.text = data.name
	if data.icon:
		icon_rect.texture = data.icon
	
	if build_btn.pressed.is_connected(_on_build_pressed):
		build_btn.pressed.disconnect(_on_build_pressed)
	build_btn.pressed.connect(_on_build_pressed)

func _on_build_pressed():
	request_build.emit(current_data)
