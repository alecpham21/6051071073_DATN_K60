extends PanelContainer

const Slot = preload("res://Inventory_ui/slot.tscn")

@onready var item_grid: GridContainer = $MarginContainer/ItemGrid
@onready var recipe_texture: TextureRect = $RecipeTexture

var current_craft_data: InventoryData

func _ready() -> void:
	visible = false
	GameData.game_state_changed.connect(func(old, new):
		if GState.is_cook():
			visible = true
			# Khi mở UI nấu ăn -> Hiện chuột lên để click
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE 
		else:
			visible = false
			# Khi tắt UI -> Khóa chuột lại để xoay camera
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED 
			
			if current_craft_data:
				pass 
	)
	GameData.current_recipe_changed.connect(func(x:Recipe): recipe_texture.texture = x.goal_item.item_data.duplicate().texture)

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
			if !PlayerData.player_inventory_data.has_item(slot_data.item_data): continue
			slot.set_slot_data(slot_data)
