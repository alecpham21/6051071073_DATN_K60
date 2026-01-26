extends Node3D

@onready var light: OmniLight3D = $OmniLight3D
@onready var halo: MeshInstance3D = $Halo

@export var move_speed: float = 1.5
@export var move_range: float = 0.4
@export var base_energy: float = 1.2

var start_pos: Vector3
var time: float = 0.0
var offset: float

func _ready() -> void:
	start_pos = global_position
	offset = randf() * PI * 2.0
	
	if TimeManager.has_signal("tick"):
		TimeManager.tick.connect(_on_time_tick)
	_on_time_tick()

func _process(delta: float) -> void:
	if not visible: return
	
	time += delta
	
	var move_time = time * move_speed
	var movement = Vector3(
		sin(move_time + offset) * move_range,
		cos(move_time * 1.3 + offset) * (move_range * 0.5),
		sin(move_time * 0.7 + offset) * move_range
	)
	global_position = start_pos + movement

	if light:
		var flicker = (sin(time * 4.0) + sin(time * 2.5)) / 2.0
		var pulse = remap(flicker, -1.0, 1.0, 0.4, 1.2)
		
		light.light_energy = pulse * base_energy
		
		if halo:
			var mat = halo.get_active_material(0)
			if mat is StandardMaterial3D:
				mat.albedo_color.a = pulse * 0.6 
				halo.scale = Vector3.ONE * (0.8 + pulse * 0.4)

func _on_time_tick() -> void:
	var hour = TimeManager.current_hour
	var is_night = (hour >= 18 or hour < 5)
	
	if visible != is_night:
		visible = is_night
		print("Firefly state changed: ", visible)
