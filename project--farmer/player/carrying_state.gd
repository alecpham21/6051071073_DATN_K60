extends MainState
class_name CarryingState

@export_group("Animations")
@export var carry_idle_ani: AnimationSet
@export var carry_walk_ani: AnimationSet

func _setup() -> void:
	super()

func _update(delta: float) -> void:
	super(delta)
	
	if character.velocity.length() > 0.1:
		if carry_walk_ani: carry_walk_ani.play(character.ani)
	else:
		if carry_idle_ani: carry_idle_ani.play(character.ani)
	
	check_interaction_transitions()
	
	#if limbo_hsm.can_place_down():
		#dispatch("placedown")
