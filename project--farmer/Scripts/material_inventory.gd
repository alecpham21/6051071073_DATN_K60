extends PanelContainer

const Slot = preload("res://Inventory_ui/slot.tscn")

@onready var item_grid: GridContainer = $MarginContainer/ItemGrid

func _ready() -> void:
	GameData.game_state_changed.connect(func(old, new):
		if GState.is_cook():
			visible = true
		else: visible = false
		)

func set_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_updated.connect(populate_item_grid)
	populate_item_grid(inventory_data)

func clear_inventory_data(inventory_data: InventoryData) -> void:
	inventory_data.inventory_updated.disconnect(populate_item_grid)


func populate_item_grid(inventory_data: InventoryData) -> void:
	for child in item_grid.get_children():
		child.queue_free()
		
	for slot_data in inventory_data.slot_datas:
		var slot = Slot.instantiate()
		item_grid.add_child(slot)
		
		slot.slot_clicked.connect(inventory_data.on_slot_clicked)
		
		if slot_data:
			if !PlayerData.player_inventory_data.has_item(slot_data.item_data):
				slot.modulate.s = 0.5
			else: slot_data.quantity = PlayerData.player_inventory_data.get_slot_from_item(slot_data.item_data).quantity
			slot_data.locked = true
			slot.set_slot_data(slot_data)
