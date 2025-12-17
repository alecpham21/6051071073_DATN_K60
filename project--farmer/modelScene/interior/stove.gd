class_name Stove
extends Node3D

@export var inventory_data: InventoryData 
@export var camera_marker: Marker3D
@export var player_marker: Marker3D

@onready var stove_area: Area3D = $StoveArea



func _ready() -> void:
	
	
	if inventory_data == null:
		inventory_data = load("res://inventory_script/inventory_data/craft_bar_inventory.tres").duplicate()
	
	if stove_area:
		stove_area.interacted.connect(on_interact_stove)

func on_interact_stove():
	GameData.open_kitchen_interface.emit(self, "stove") 
	GState.cook()
	
	if camera_marker and PlayerData.player.cam_ref:
		PlayerData.player.cam_ref.focus_on_target(camera_marker)

	if player_marker and PlayerData.player:
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		
		tween.tween_property(PlayerData.player, "global_position", player_marker.global_position, 0.2)
		
		var target_rot = player_marker.global_rotation
		tween.parallel().tween_property(PlayerData.player, "global_rotation:y", target_rot.y, 0.2)
