extends Area3D
class_name HouseDoor

@export var interior_scene: PackedScene
@export var entrance_id: String = "house_1"

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.near_door = self
		print("Player entered door area")

func _on_body_exited(body):
	if body.is_in_group("player") and body.near_door == self:
		body.near_door = null
		print("Player left door area")
