extends CharacterBody3D
class_name BaseNPC 

@export_group("References")
@export var bt_player: BTPlayer 
@export var animation_player: AnimationPlayer
@export var nav_agent: NavigationAgent3D
@export var push_area: Area3D
@export var behavior_tree_resource: BehaviorTree

@export_group("Visual Customization")
@export var mesh_to_color: MeshInstance3D
@export var surface_index: int = 0
@export var shirt_colors: Array[Color] = [
	Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.CYAN, Color.WHITE
]

@export_group("Animation Settings")
@export var walk_anim_name: String = "Walk_Male"
@export var idle_anim_name: String = "Idle"


var _push_timer: float = 0.0
var target_destination: Vector3
var home_destination: Vector3
var stay_duration: float = 0.0

func _ready() -> void:
	if not nav_agent: nav_agent = $NavigationAgent3D
	if not bt_player: bt_player = $BTPlayer
	
	if bt_player and behavior_tree_resource:
		bt_player.behavior_tree = behavior_tree_resource
	
	if animation_player:
		bt_player.blackboard.set_var("anim_player_node", animation_player)
	
	if nav_agent:
		if not nav_agent.velocity_computed.is_connected(_on_velocity_computed):
			nav_agent.velocity_computed.connect(_on_velocity_computed)
	
	if push_area:
		push_area.body_entered.connect(_on_push_area_body_entered)
			
	randomize_shirt_color()

func _physics_process(delta: float) -> void:
	if _push_timer > 0:
		_push_timer -= delta

func _on_push_area_body_entered(body: Node3D) -> void:
	if _push_timer <= 0 and body.is_in_group("player"):
		_handle_push(body)

func setup_ai(target_marker: Marker3D, home_marker: Marker3D, is_initial: bool = false) -> void:
	var target_pos = target_marker.global_position
	var is_already_at_target = global_position.distance_to(target_pos) < 0.5
	
	bt_player.blackboard.set_var("is_at_start", is_already_at_target)
	
	var base_stay = randf_range(60.0, 180.0) 
	if is_initial:
		base_stay = randf_range(30.0, 100.0)
	
	if not animation_player:
		animation_player = get_node_or_null("AnimationPlayer") 
	
	if animation_player:
		bt_player.blackboard.set_var("anim_player_node", animation_player)
	
	bt_player.blackboard.set_var("target_pos", target_pos)
	bt_player.blackboard.set_var("target_rot", target_marker.global_rotation.y)
	bt_player.blackboard.set_var("home_pos", home_marker.global_position)
	bt_player.blackboard.set_var("stay_time", base_stay)
	
	if is_already_at_target:
		global_rotation.y = target_marker.global_rotation.y
	
	bt_player.active = true 
	bt_player.restart()

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	if bt_player and bt_player.active:
		velocity = safe_velocity
		move_and_slide()
		
		if velocity.length() > 0.2:
			do_walk_anim()
	else:
		velocity = Vector3.ZERO

func do_walk_anim() -> void:
	if animation_player and animation_player.has_animation(walk_anim_name):
		if animation_player.current_animation != walk_anim_name:
			animation_player.play(walk_anim_name)

func do_idle_anim() -> void:
	if animation_player and animation_player.has_animation(idle_anim_name):
		animation_player.play(idle_anim_name)

func randomize_gender() -> void:
	if randf() > 0.5:
		walk_anim_name = "Walk_Female"
	else:
		walk_anim_name = "Walk_Male"

func randomize_shirt_color() -> void:
	if not mesh_to_color:
		printerr("LỖI: Chưa kéo node Shirt vào Inspector!")
		return
	
	if shirt_colors.is_empty():
		return
		
	var current_mat = mesh_to_color.get_surface_override_material(surface_index)
	if not current_mat:
		current_mat = mesh_to_color.mesh.surface_get_material(surface_index)
	
	if not current_mat:
		printerr("LỖI: Node Shirt này không có Material nào cả!")
		return

	var new_mat = current_mat.duplicate()
	var random_color = shirt_colors.pick_random()
	
	if new_mat is StandardMaterial3D:
		new_mat.albedo_color = random_color
		print("Đã đổi màu StandardMaterial thành: ", random_color)
		
	elif new_mat is ShaderMaterial:
		var param_name = "albedo"
		
		var param_list = RenderingServer.get_shader_parameter_list(new_mat.shader.get_rid())
		var found = false
		for p in param_list:
			if p.name == param_name:
				found = true
				break
		
		if found:
			new_mat.set_shader_parameter(param_name, random_color)
			print("Đã đổi màu Shader (param '", param_name, "') thành: ", random_color)
		else:
			printerr("LỖI: Shader không có biến tên là '", param_name, "'. Hãy kiểm tra lại Inspector!")
			print("Gợi ý: Các biến màu có thể dùng trong shader này là:")
			for p in param_list:
				if p.type == 5:
					print(" - ", p.name)
	
	mesh_to_color.set_surface_override_material(surface_index, new_mat)

func play_interact_anim() -> void:
	if not animation_player: return
	var anims = ["Interact_One", "Interact_Two", "Interact_Three", "Interact_Four"]
	var valid_anim = ""
	anims.shuffle()
	for anim_name in anims:
		if animation_player.has_animation(anim_name):
			valid_anim = anim_name
			break
	if valid_anim != "":
		animation_player.play(valid_anim)

func finish_lifecycle() -> void:
	queue_free()

func _handle_push(player: Node3D) -> void:
	_push_timer = 1.5
	
	velocity = Vector3.ZERO
	if nav_agent:
		nav_agent.set_velocity(Vector3.ZERO)
		nav_agent.target_position = global_position 

	var npc_forward = -global_transform.basis.z 
	var to_player = (player.global_position - global_position).normalized()
	var dot = npc_forward.dot(to_player)
	
	if dot > 0:
		if animation_player.has_animation("Pushed_Front"):
			animation_player.play("Pushed_Front")
	else:
		if animation_player.has_animation("Pushed_Back"):
			animation_player.play("Pushed_Back")
	
	if bt_player:
		bt_player.active = false
		nav_agent.avoidance_enabled = false
		
		var t = get_tree().create_timer(1.2)
		t.timeout.connect(func():
			bt_player.active = true
			nav_agent.avoidance_enabled = true
			
			if nav_agent and bt_player.blackboard.has_var("target_pos"):
				nav_agent.target_position = bt_player.blackboard.get_var("target_pos")
				do_walk_anim() 
		)
		
