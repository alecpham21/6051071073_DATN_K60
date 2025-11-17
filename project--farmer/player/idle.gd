extends GardeningState

func _update(delta: float) -> void:
	super(delta)
	if !(character.velocity).is_zero_approx(): dispatch("move")
