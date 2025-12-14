extends PanelContainer

signal slot_clicked(index: int, button: int)

@onready var quantity_label: Label = $QuantityLabel
@onready var texture_rect: TextureRect = $MarginContainer/TextureRect


func set_slot_data(slot_data: SlotData) -> void:
	if slot_data == null:
		texture_rect.texture = null
		quantity_label.hide()
		tooltip_text = ""
		texture_rect.modulate = Color.WHITE 
		return
	var item_data = slot_data.item_data
	

	texture_rect.modulate = Color.WHITE 
	texture_rect.texture = item_data.texture
	
	var text = "%s\n%s" % [item_data.name, item_data.description]
	

	var water_max = slot_data.get_stat("water_capacity")
	var water_cur = 0.0
	

	if item_data is ItemDataOutfit:
		var d_level = int(slot_data.get_stat("dirt"))
		var max_d = int(item_data.max_dirt_level)
		text += "\n----------------"
		var status = ""
		if d_level == 0: status = "Sạch sẽ ✨"
		elif d_level <= 20: status = "Ổn 👌"
		elif d_level <= 50: status = "Hơi dơ ☁️"
		elif d_level <= 80: status = "Dơ 💩"
		elif d_level < 100: status = "Rất dơ 🤢"
		else: status = "Gớm 🤮"
		text += "\nĐộ dơ: %s (%s/%s)" % [status, d_level, max_d]


	if water_max > 0:
		water_cur = slot_data.get_stat("water_current")
		text += "\nNước: %s / %s" % [water_cur, water_max]
		
		if water_cur <= 0:
			texture_rect.modulate = Color(0.5, 0.5, 0.5, 1.0)

	tooltip_text = text
	
	## Label Quantity
	if water_max > 0:
		quantity_label.text = "%s" % int(water_cur)
		quantity_label.show()
	elif slot_data.quantity > 1:
		quantity_label.text = "x%s" % slot_data.quantity
		quantity_label.show()
	else:
		# Ẩn
		quantity_label.hide()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and (event.button_index == MOUSE_BUTTON_LEFT \
			or event.button_index == MOUSE_BUTTON_RIGHT) \
			and event.is_pressed():
		slot_clicked.emit(get_index(), event.button_index)
