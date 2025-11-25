extends GardeningState

func _update(delta: float) -> void:
	super(delta)

func check_dispatch():
	if (character.velocity).is_zero_approx(): dispatch("idle")
	if limbo_hsm.can_till(): dispatch("till")
	if limbo_hsm.can_plant(): dispatch("plant")
	if limbo_hsm.can_harvest(): dispatch("harvest")
