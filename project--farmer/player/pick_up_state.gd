extends MainState
class_name PickUpState

@export_group("Animations")
@export var pickup_ani: AnimationSet
@export var pickup_delay: float = 0.91

var target_found: bool = false

func _setup() -> void:
	super()
	can_move = false
	can_run = false

func _enter() -> void:
	super()
	character.is_busy = true
	character.velocity = Vector3.ZERO
	target_found = false
	
	if pickup_ani:
		pickup_ani.play(character.ani)
	
	get_tree().create_timer(pickup_delay).timeout.connect(func():
		var target = _get_target_from_area()
		if target:
			character.pick_up_object(target)
			blackboard.set_var("is_carrying", true)
			target_found = true
			print("Object attached to hand early")
	)
	
	if not character.ani.animation_finished.is_connected(_on_ani_finished):
		character.ani.animation_finished.connect(_on_ani_finished, CONNECT_ONE_SHOT)

func _on_ani_finished(_name: String) -> void:
	if target_found:
		dispatch("carried")
	else:
		print("Pickup failed: No object found at delay time")
		dispatch("idle")

func _get_target_from_area() -> Node3D:
	var areas = character.interact_area.get_overlapping_areas()
	for a in areas:
		if a.collision_layer & (1 << 7):
			return a.get_parent()
	return null

func _exit() -> void:
	character.is_busy = false
