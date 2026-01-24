extends MainState
class_name PlaceDownState

@export_group("Animations")
@export var placedown_ani: AnimationSet
@export var drop_delay: float = 0.4

func _enter() -> void:
	super()
	character.is_busy = true
	character.velocity = Vector3.ZERO
	if placedown_ani: placedown_ani.play(character.ani)
	
	get_tree().create_timer(drop_delay).timeout.connect(func():
		if character.carried_node:
			character.place_down_object()
			
			var current_lvl = get_tree().current_scene
			if current_lvl.has_method("save_level_state"):
				current_lvl.save_level_state()
	)
	
	if not character.ani.animation_finished.is_connected(_on_ani_finished):
		character.ani.animation_finished.connect(_on_ani_finished, CONNECT_ONE_SHOT)

func _on_ani_finished(_name: String) -> void:
	blackboard.set_var("is_carrying", false)
	dispatch("idle")

func _exit() -> void:
	character.is_busy = false
