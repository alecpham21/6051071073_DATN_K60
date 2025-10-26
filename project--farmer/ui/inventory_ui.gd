extends Control

#@onready var player_inventory = $"../../PlayerInventory"
@export var player_inventory : Node

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	update_inventory()

func update_inventory():
	var i = 0
	for inv_slot in $HBoxContainer.get_children():
		if player_inventory.inventory[i].item_name == "null":
			inv_slot.get_node("TextureRect").texture = null
		else:
			var texture_path = "res://ui/item_icons/" + player_inventory.inventory[i].item_name + ".png"
			inv_slot.get_node("TextureRect").texture = load(texture_path)
		#set texture slot
		if player_inventory.active_item_slot == i:
			inv_slot.get_node("Selected").visible = true
		else:
			inv_slot.get_node("Selected").visible = false
		i += 1
