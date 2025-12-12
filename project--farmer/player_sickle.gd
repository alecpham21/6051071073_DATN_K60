class_name Sickle
extends Node3D

@export var cast_path: NodePath = "../../../../../GridCheckRay" 
@onready var cast: RayCast3D = get_node_or_null(cast_path)
@onready var ground_gen = get_tree().get_first_node_in_group("ground_generator")

var current_data: ItemDataTool
var current_tool_instance: Node3D = null

#func _ready() -> void:
	#visible = false

#func set_tool_data(data: ItemDataTool) -> void:
	#if data == null:
		#visible = false
		#current_data = null
		#if current_tool_instance:
			#current_tool_instance.queue_free()
			#current_tool_instance = null
		#return
#
	## Nếu đổi tool khác
	#if current_data != data:
		#visible = true # Hiện lên
		#current_data = data
		#
		## Xóa cái cũ
		#if current_tool_instance:
			#current_tool_instance.queue_free()
			#current_tool_instance = null
		#
		## Sinh cái mới
		#if current_data.equip_scene: 
			#current_tool_instance = current_data.equip_scene.instantiate()
			#add_child(current_tool_instance)
			#current_tool_instance.position = Vector3.ZERO
			#current_tool_instance.rotation = Vector3.ZERO
#
#func swing_sickle() -> void:
	#if not cast or not visible: return
	#
	#cast.force_raycast_update()
	#if not cast.is_colliding(): return
#
	#var hit_pos = cast.get_collision_point()
	#if not ground_gen: return
		#
	#var grid_pos = ground_gen.get_grid_pos_from_world(hit_pos)
	#if not ground_gen.is_valid_grid_pos(grid_pos): return
#
	#var block = ground_gen.block_data[grid_pos.x][grid_pos.y]
#
	## 1. Harvest Crop
	#if block.crop_ready:
		#for child in ground_gen.get_children():
			#if child.has_method("harvest") and \
				#child.global_position.distance_to(ground_gen.get_world_pos_from_grid(grid_pos)) < 0.5:
				#child.harvest()
				#print("✅ Harvested crop at:", grid_pos)
				#return 
#
	## 2. Cut Grass
	#if block.mode == BlockGroundData.Mode.GRASS:
		#block.mode = BlockGroundData.Mode.CUT
		#ground_gen.renderer.set_mode(grid_pos.x, grid_pos.y, block.mode)
		#print("✂️ Cut grass at:", grid_pos)
		#return
