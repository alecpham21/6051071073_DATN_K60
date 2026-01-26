extends Node

@export_group("Light References")
@export var day_lights: Array[SpotLight3D] = []
@export var omni_day_light: OmniLight3D
@export var town_windows_mesh: MeshInstance3D

@export_group("Settings")
@export var night_color: Color = Color("1a2036")
@export var day_color: Color = Color("e1a700")
@export var window_emission_color: Color = Color("f1c40f")
@export var max_window_energy: float = 2.0

func _ready() -> void:
	if TimeManager.has_signal("tick"):
		TimeManager.tick.connect(_on_time_tick)
	_update_lighting()

func _on_time_tick() -> void:
	_update_lighting()

func _update_lighting() -> void:
	var hour = TimeManager.current_hour
	var minutes = TimeManager.current_time
	var is_night = (hour >= 17 or hour < 6)

	get_tree().call_group("street_lights", "set_visible", is_night)
	
	if omni_day_light:
		omni_day_light.visible = not is_night

	_update_window_emission(hour, minutes)

	var weight := 0.0
	if minutes >= 960 and minutes <= 1140: # 16h - 19h
		weight = (minutes - 960) / (1140 - 960.0)
	elif minutes > 1140 or minutes < 300:
		weight = 1.0
	elif minutes >= 300 and minutes <= 420: # 5h - 7h
		weight = 1.0 - ((minutes - 300) / (420 - 300.0))
	
	_apply_transition(weight)

func _update_window_emission(hour: int, minutes: float) -> void:
	if not town_windows_mesh: return
	
	var mat = town_windows_mesh.get_active_material(0)
	
	if not mat is StandardMaterial3D: 
		return
	
	var energy = 0.0
	
	if hour >= 17 and hour < 23:
		#17h (1020) 19h (1140p)
		if minutes < 1140:
			var w = (minutes - 1020) / (1140 - 1020)
			energy = lerp(0.0, max_window_energy, w)
		else:
			energy = max_window_energy
	else:
		energy = 0.0
		
	mat.emission_enabled = energy > 0
	mat.emission_energy_multiplier = energy
	
	if energy > 0:
		mat.emission = window_emission_color

func _apply_transition(weight: float) -> void:
	for light in day_lights:
		if light:
			light.light_color = day_color.lerp(night_color, weight)
			light.light_energy = lerp(2.19, 0.3, weight)
