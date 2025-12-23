extends MainState
class_name MovingState


@export var run_ani: AnimationSet

func _update(delta: float) -> void:
	super(delta)
	
	var speed = character.velocity.length()
	if speed > 0.1:
		if blackboard.get_var(BBNames.run_var, false) and run_ani:
			run_ani.play(character.ani)
		else:
			if ani_set: 
				ani_set.play(character.ani)
	else:
		dispatch("idle")

	check_tool_transitions()
