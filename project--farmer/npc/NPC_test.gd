extends CharacterBody3D
class_name BaseNPC 

@export_group("References")
@export var bt_player: BTPlayer 
@export var animation_player: AnimationPlayer
@export var nav_agent: NavigationAgent3D

@export_group("Visual Customization")
@export var mesh_to_color: MeshInstance3D
@export var surface_index: int = 0
@export var shirt_colors: Array[Color] = [
	Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.CYAN, Color.WHITE
]

@export_group("Animation Settings")
@export var walk_anim_name: String = "Walk_Male"
@export var idle_anim_name: String = "Idle"

var target_destination: Vector3
var home_destination: Vector3
var stay_duration: float = 0.0

func _ready() -> void:
	if not nav_agent: nav_agent = $NavigationAgent3D
	if not bt_player: bt_player = $BTPlayer
	
	if nav_agent:
		if not nav_agent.velocity_computed.is_connected(_on_velocity_computed):
			nav_agent.velocity_computed.connect(_on_velocity_computed)
			
	randomize_shirt_color()

func setup_ai(target_marker: Marker3D, home_marker: Marker3D) -> void:
	target_destination = target_marker.global_position
	home_destination = home_marker.global_position
	
	nav_agent.target_position = target_destination
	
	var target_rot_y = target_marker.global_rotation.y
	stay_duration = randf_range(20.0, 30.0) 
	
	bt_player.blackboard.set_var("nav_agent", nav_agent)
	bt_player.blackboard.set_var("target_pos", target_destination)
	bt_player.blackboard.set_var("target_rot", target_rot_y)
	bt_player.blackboard.set_var("home_pos", home_destination)
	bt_player.blackboard.set_var("stay_time", stay_duration)
	
	bt_player.restart()

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = safe_velocity
	move_and_slide()

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
		var param_name = "albedo"  # <--- Nếu shader bạn dùng tên khác (ví dụ "color"), sửa chữ này!
		
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
