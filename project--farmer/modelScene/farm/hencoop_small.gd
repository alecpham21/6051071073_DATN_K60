extends Node3D

@export var chicken_scene: PackedScene
@export var max_capacity: int = 4
@export var spawn_point: Marker3D 

var current_chickens: Array = []

func _ready():
	pass

func interact():
	print("Đang tương tác với chuồng gà -> Spawn gà")
	spawn_chicken()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		interact()

func spawn_chicken():
	if current_chickens.size() >= max_capacity:
		print("Chuồng đầy rồi!")
		return
		
	var chicken = chicken_scene.instantiate()
	get_parent().add_child(chicken) 
	
	if spawn_point:
		chicken.global_position = spawn_point.global_position
	else:
		chicken.global_position = global_position
		print("Chưa gắn Marker3D! Spawn tại tâm chuồng.")
	
	if "home_position" in chicken:
		chicken.home_position = self.global_position 
	
	current_chickens.append(chicken)
