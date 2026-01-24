extends CharacterBody3D

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var bt_player: BTPlayer = $BTPlayer

@export var model_baby: Node3D
@export var model_male: Node3D
@export var model_female: Node3D

var current_anim: AnimationPlayer
var chicken_data: ChickenData
var home_position: Vector3 
var move_speed: float = 2.0

func _ready():
	bt_player.blackboard.set_var("agent", self)
	bt_player.blackboard.set_var("is_hungry", false)
	
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.5
	
	if home_position == Vector3.ZERO:
		home_position = global_position

func setup(data: ChickenData):
	chicken_data = data
	update_visual()
	
	bt_player.blackboard.set_var("home_pos", home_position)
	bt_player.blackboard.set_var("is_adult", chicken_data.stage == LivestockEnums.Stage.ADULT)
	bt_player.blackboard.set_var("is_hungry", chicken_data.feed_count == 0)
	nav_agent.navigation_layers = 2
	
func update_visual():
	if not chicken_data: return
	
	if model_baby: model_baby.visible = false
	if model_male: model_male.visible = false
	if model_female: model_female.visible = false
	
	current_anim = null
	
	if chicken_data.stage == LivestockEnums.Stage.BABY:
		if model_baby: model_baby.visible = true
		scale = Vector3(0.15, 0.15, 0.15) 
	else:
		scale = Vector3(0.2, 0.2, 0.2) 
		if chicken_data.gender == LivestockEnums.Gender.MALE:
			if model_male: 
				model_male.visible = true
				current_anim = model_male.get_node_or_null("AnimationPlayer")
		else:
			if model_female: 
				model_female.visible = true
				current_anim = model_female.get_node_or_null("AnimationPlayer")
	
	if bt_player and bt_player.blackboard:
		bt_player.blackboard.set_var("is_adult", chicken_data.stage == LivestockEnums.Stage.ADULT)
		bt_player.blackboard.set_var("is_hungry", chicken_data.feed_count == 0)

func _physics_process(_delta):
	if not is_on_floor():
		velocity += get_gravity() * _delta
	
	_handle_animations()
	move_and_slide()

func _handle_animations():
	if not current_anim: return
	
	if current_anim.current_animation == "Eating" and current_anim.is_playing():
		return
	
	if velocity.length() > 0.1:
		play_animation("Walk")
	else:
		play_animation("Idle")

func play_animation(anim_name: String):
	if current_anim and current_anim.has_animation(anim_name):
		if current_anim.current_animation != anim_name:
			current_anim.play(anim_name)

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
	if bt_player.blackboard.get_var("is_hungry", false):
		play_animation("Eating")
		bt_player.blackboard.set_var("is_hungry", false)
