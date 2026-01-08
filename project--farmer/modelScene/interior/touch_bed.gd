extends StaticBody3D

@onready var interact_area: Area3D = $"../InteractArea"

func _ready() -> void:
	if interact_area:
		interact_area.interacted.connect(_on_interacted)
	else:
		printerr("❌ Bed: Missing InteractArea node!")

func _on_interacted():
	var current_hour = TimeManager.current_hour
	
	if current_hour >= 20 or current_hour < 6:
		start_sleeping(current_hour)
	else:
		print("not 20h")

func start_sleeping(hour_at_sleep: int):
	print("💤 Sleeping.")
	
	if PlayerData.player and PlayerData.player.stats:
		PlayerData.player.stats.sleep_recovery(hour_at_sleep)
	
	TimeManager.current_time += 480.0
	
	if SceneTransition:
		SceneTransition.play_sleep_transition()
