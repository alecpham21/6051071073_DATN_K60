extends RigidBody3D

@export var slot_data: SlotData
@onready var sprite_3d: Sprite3D = $Sprite3D

var can_pick_up: bool = false 

func _ready() -> void:
	sprite_3d.texture = slot_data.item_data.texture
	
	await get_tree().create_timer(0.5).timeout
	can_pick_up = true

func _physics_process(delta: float) -> void:
	sprite_3d.rotate_y(delta)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if not can_pick_up:
		return
		
	if body.inventory_data.pick_up_slot_data(slot_data):
		queue_free()
