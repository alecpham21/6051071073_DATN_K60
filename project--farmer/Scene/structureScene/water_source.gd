extends Node3D
class_name WaterSource

@export var max_capacity: float = 10.0 

@onready var interact_area: InteractArea = $InteractArea

const WATER_TAKING_SOUND = preload("res://audio/waterBucket.mp3")

func _ready() -> void:
	if interact_area:
		interact_area.interacted.connect(_on_interacted)

func _on_interacted() -> void:
	var active_slot = HotBar.active_slot
	
	if active_slot and active_slot.item_data:
		if "watering can" in active_slot.item_data.name.to_lower():
			
			active_slot.set_stat("water_max", max_capacity)
			active_slot.set_stat("water_current", max_capacity)
			
			if WATER_TAKING_SOUND:
				var sfx = AudioStreamPlayer3D.new()
				sfx.stream = WATER_TAKING_SOUND
				sfx.unit_size = 10.0
				sfx.max_db = -1.0
				sfx.bus = "SFX"
		
				get_tree().root.add_child(sfx)
				sfx.pitch_scale = randf_range(0.85, 1.15)
		
				sfx.finished.connect(sfx.queue_free) 
				sfx.play()
			
			print("💦 Đã múc đầy nước! (%s/%s)" % [max_capacity, max_capacity])
			
			PlayerData.player_inventory_data.inventory_updated.emit(PlayerData.player_inventory_data)
			
		else:
			print("🚫 Cần cầm bình tưới để lấy nước!")
	else:
		print("Tay không thì múc bằng gì?")
