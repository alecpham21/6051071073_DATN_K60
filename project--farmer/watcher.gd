extends Node

var local_gs:int = 0:
	set(val):
		if val != local_gs: game_state_changed.emit(val)
		local_gs = val
var player:Player
var current_block:BlockGround
var indoor:bool = false

signal game_state_changed(_new:int)

func _process(delta: float) -> void:
	local_gs = GState.game_state
	#print(GState.game_state)
