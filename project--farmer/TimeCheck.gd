extends Label

func _process(delta):
	var total_minutes = TimeManager.current_time
	
	var hours = int(total_minutes / 60)
	
	var minutes = int(total_minutes) % 60
	
	text = "Time: %02d:%02d" % [hours, minutes]
