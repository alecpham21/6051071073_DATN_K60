extends Node

@export_group("Light References")
@export var day_lights: Array[SpotLight3D] = []
@export var bulp_light: OmniLight3D
@export var day_light_source: OmniLight3D

@export_group("Settings")
@export var night_color: Color = Color("1a2036")
@export var day_color: Color = Color("e1a700")
@export var day_energy: float = 2.19
@export var night_energy: float = 0.3

func _ready() -> void:
	if TimeManager.has_signal("tick"):
		TimeManager.tick.connect(_on_time_tick)
	_update_lighting()

func _on_time_tick() -> void:
	_update_lighting()

func _update_lighting() -> void:
	var hour = TimeManager.current_hour
	var minutes = TimeManager.current_time
	
	var is_night_time = (hour >= 17 or hour < 6)
	
	if bulp_light:
		bulp_light.visible = is_night_time
	
	if day_light_source:
		day_light_source.visible = not is_night_time
	
	var weight := 0.0
	if minutes >= 960 and minutes <= 1140: # 16h - 19h
		weight = (minutes - 960) / (1140 - 960)
	elif minutes > 1140 or minutes < 300:
		weight = 1.0
	elif minutes >= 300 and minutes <= 420: # 5h - 7h
		weight = 1.0 - ((minutes - 300) / (420 - 300))
	else:
		weight = 0.0
		
	_apply_light_transition(weight)

func _apply_light_transition(weight: float) -> void:
	for light in day_lights:
		if not light: continue
		light.light_color = day_color.lerp(night_color, weight)
		light.light_energy = lerp(day_energy, night_energy, weight)
