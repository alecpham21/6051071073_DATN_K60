extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	GameData.set_current_stage(self)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
