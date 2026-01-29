extends MainState
class_name RestingState

@export var default_rest_ani: AnimationSet
var target_marker: Marker3D
var target_ani: AnimationSet
var stamina_regen_multiplier: float = 1.0

func _enter() -> void:
	super()
	
	var ani_to_play = target_ani if target_ani else default_rest_ani
	if ani_to_play:
		ani_to_play.play(character.ani)
	
	if target_marker:
		character.velocity = Vector3.ZERO
		#character.set_physics_process(false)
		
		character.set_collision_layer_value(1, false)
		character.set_collision_mask_value(1, false)
		
		character.reparent(target_marker)
		character.transform = Transform3D.IDENTITY
		character.global_transform.basis = character.global_transform.basis.orthonormalized()
		
		print("DEBUG: [RestingState] Enter rest at: ", target_marker.get_parent().name)

func _update(delta: float) -> void:
	if character.stats:
		var regen_amount = character.stats.get_restore_speed() * stamina_regen_multiplier * delta
		character.stats.regenerate(regen_amount)
	
	var input_vec3 = blackboard.get_var(BBNames.direction_var, Vector3.ZERO)
	if input_vec3.length() > 0.1:
		dispatch("idle")

func _exit() -> void:
	print("DEBUG: [RestingState] Exit rest")
	character.reparent(get_tree().current_scene)
	
	character.set_physics_process(true)
	character.set_collision_layer_value(1, true)
	character.set_collision_mask_value(1, true)
	
	character.global_transform.basis = character.global_transform.basis.orthonormalized()
	character.global_position += Vector3.UP * 0.5
	
	target_marker = null
	target_ani = null
	stamina_regen_multiplier = 1.0
	
	if reset_ani:
		character.ani.play("RESET")
