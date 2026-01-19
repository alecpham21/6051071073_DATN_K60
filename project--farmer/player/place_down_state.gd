extends MainState
class_name PlaceDownState


@export_group("Animations")
@export var placedown_ani: AnimationSet
@export var drop_delay: float = 0.4

func _setup() -> void:
	super()


func _enter() -> void:
	super()
	character.is_busy = true
	character.velocity = Vector3.ZERO
	if placedown_ani: placedown_ani.play(character.ani)
	
	if character.get_meta("is_in_delivery_zone", false):
		var crate = character.carried_node
		if crate is ContractCrate and crate.is_full():
			character.place_down_object()
			
			blackboard.set_var("is_carrying", false) 
			
			dispatch("idle")
			return

	get_tree().create_timer(drop_delay).timeout.connect(func():
		if character.carried_node:
			character.place_down_object()
	)
	
	if not character.ani.animation_finished.is_connected(_on_ani_finished):
		character.ani.animation_finished.connect(_on_ani_finished, CONNECT_ONE_SHOT)

func _on_ani_finished(_name: String) -> void:
	blackboard.set_var("is_carrying", false)
	dispatch("idle")

func _exit() -> void:
	character.is_busy = false
