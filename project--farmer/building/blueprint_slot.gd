extends PanelContainer

signal request_build(data: BuildingData)

@onready var icon_rect: TextureRect = $HBoxContainer/IconRect
@onready var name_label: Label = $HBoxContainer/InfoContainer/NameLabel
@onready var desc_label: Label = $HBoxContainer/InfoContainer/DescLabel
@onready var build_btn: Button = $HBoxContainer/ActionContainer/BuildButton

var current_data: BuildingData

func setup(data: BuildingData):
	current_data = data
	name_label.text = data.name
	if data.icon: icon_rect.texture = data.icon
	
	var can_afford = true
	var price_text = "Free"
	var text_color = Color.WHITE
	
	if data.required_item and data.item_cost > 0:
		var player_inv = PlayerData.player.inventory_data 
		var current_have = player_inv.get_total_item_count(data.required_item)
		
		price_text = "%s: %d/%d" % [data.required_item.name, current_have, data.item_cost]
		
		if current_have < data.item_cost:
			can_afford = false
			text_color = Color(1, 0.3, 0.3)
	
	if desc_label:
		desc_label.text = price_text
		desc_label.modulate = text_color
	
	build_btn.disabled = not can_afford
	
	if build_btn.pressed.is_connected(_on_build_pressed):
		build_btn.pressed.disconnect(_on_build_pressed)
	build_btn.pressed.connect(_on_build_pressed)

func _on_build_pressed():
	request_build.emit(current_data)
