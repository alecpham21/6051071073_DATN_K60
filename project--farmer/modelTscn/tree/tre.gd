extends Node3D

@export var item_data: ItemData 
@export_range(1, 5) var min_qty: int = 1
@export_range(1, 5) var max_qty: int = 3
@export var days_to_regrow: int = 1


var has_bamboo_shoot: bool = true 
var respawn_timestamp: float = -1.0

var is_harvestable: bool:
	get: return has_bamboo_shoot

func _ready():
	$HarvestArea.body_entered.connect(_on_area_entered)
	$HarvestArea.body_exited.connect(_on_area_exited)
	
	
	TimeManager.tick.connect(_on_time_tick)

func _on_area_entered(body):
	if body is Player:
		body.register_interactable(self)

func _on_area_exited(body):
	if body is Player:
		body.unregister_interactable(self)

func harvest():
	if not has_bamboo_shoot: return

	var quantity = randi_range(min_qty, max_qty)
	
	var added = PlayerData.player_inventory_data.add_item(item_data, quantity)
	
	if added:
		print("Hái thành công!")
		has_bamboo_shoot = false
		
		var current_total_minutes = TimeManager.get_total_minutes_played()
		
		var minutes_per_day = TimeManager.total_game_minutes 
		respawn_timestamp = current_total_minutes + (days_to_regrow * minutes_per_day)
		
		print("Đã set lịch mọc lại vào phút thứ: ", respawn_timestamp)
	else:
		print("Kho đầy!")


func _on_time_tick():
	if has_bamboo_shoot: return
	
	if respawn_timestamp != -1.0:
		if TimeManager.get_total_minutes_played() >= respawn_timestamp:
			respawn_bamboo()

func respawn_bamboo():
	has_bamboo_shoot = true
	respawn_timestamp = -1.0
	print("Măng đã mọc lại!")

func get_save_data() -> Dictionary:
	return {
		"has_shoot": has_bamboo_shoot,
		"respawn_timestamp": respawn_timestamp
	}

func load_save_data(data: Dictionary):
	if data.has("has_shoot"):
		has_bamboo_shoot = data["has_shoot"]
	
	if data.has("respawn_timestamp"):
		respawn_timestamp = data["respawn_timestamp"]
		
	if not has_bamboo_shoot and respawn_timestamp != -1.0:
		if TimeManager.get_total_minutes_played() >= respawn_timestamp:
			respawn_bamboo()
