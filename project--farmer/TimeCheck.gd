extends Label

func _process(delta):
	var total_minutes = TimeManager.current_time
	
	var hours = int(total_minutes / 60)
	
	var minutes = int(total_minutes) % 60
	
	#Format: 08:05 thay vì 8:5
	# %02d nghĩa là số nguyên, bắt buộc có 2 chữ số (tự thêm số 0 đằng trước)
	text = "Time: %02d:%02d" % [hours, minutes]
