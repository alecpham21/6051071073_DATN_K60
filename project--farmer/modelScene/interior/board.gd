class_name Board
extends Node3D

# Kéo file InventoryData (1 ô) vào đây trong Inspector
@export var inventory_data: InventoryData 
@export var camera_marker: Marker3D
@export var player_marker: Marker3D


@onready var board_area: Area3D = $BoardArea

func _ready() -> void:
	inventory_data = PlayerData.board_data
	if board_area:
		board_area.interacted.connect(on_interact_stove)

func on_interact_stove():
	GameData.open_kitchen_interface.emit(self, "board")
	GState.cook()
	
	if camera_marker and PlayerData.player.cam_ref:
		PlayerData.player.cam_ref.focus_on_target(camera_marker)
		
	if player_marker and PlayerData.player:
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		
		tween.tween_property(PlayerData.player, "global_position", player_marker.global_position, 0.2)
		
		var target_rot = player_marker.global_rotation
		tween.parallel().tween_property(PlayerData.player, "global_rotation:y", target_rot.y, 0.2)
