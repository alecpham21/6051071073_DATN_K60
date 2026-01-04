extends CharacterBody3D

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var bt_player: BTPlayer = $BTPlayer

var home_position: Vector3 
var hunger: float = 0.0
var move_speed: float = 2.0

func _ready():
	bt_player.blackboard.set_var("agent", self)
	
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.5
	
	await get_tree().physics_frame 
	await get_tree().physics_frame 
	
	home_position = global_position
	print("🐔 Gà đã sẵn sàng! Vị trí nhà: ", home_position)

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()

func move_to(target_pos: Vector3):
	if nav_agent.target_position != target_pos:
		nav_agent.target_position = target_pos
	
	if nav_agent.is_navigation_finished():
		velocity.x = 0
		velocity.z = 0
		return

	var current_pos = global_position
	var next_pos = nav_agent.get_next_path_position()
	
	var direction = (next_pos - current_pos)
	direction.y = 0
	direction = direction.normalized()
	
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	
	if direction.length_squared() > 0.01:
		var look_target = Vector3(next_pos.x, global_position.y, next_pos.z)
		look_at(look_target, Vector3.UP)

func eat_food():
	hunger = 0.0
	print("Chic Eating...")
