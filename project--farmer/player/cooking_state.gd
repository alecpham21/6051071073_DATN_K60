extends GardeningState

func _enter() -> void:
	super()
	character.ani.animation_finished.connect(func(a):
		limbo_hsm.cook = false
		dispatch("idle")
		, CONNECT_ONE_SHOT)
	if safe_guard: overtimed.connect(func(): dispatch("idle"), CONNECT_ONE_SHOT)
	GState.lock_state = true

#func _update(delta: float) -> void:
	#super(delta)
	#print("Animation: %s, %s"%[character.ani.current_animation, character.ani.current_animation_position])

func _exit() -> void:
	super()
	GState.lock_state = false
