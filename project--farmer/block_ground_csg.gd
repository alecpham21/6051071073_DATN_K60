extends Node3D
class_name BlockGroundCSG

enum Mode { GRASS, TILLED }

@export var mode: Mode = Mode.GRASS
@export_file("*.tres") var grass_mat_path: String = "res://Materials/block_grass.tres"
@export_file("*.tres") var tilled_mat_path: String = "res://Materials/block_tilled.tres"

var _mat_grass: Material
var _mat_tilled: Material
var is_block := true

@onready var csg: CSGBox3D = $CSGBox3D


func _ready() -> void:
	_mat_grass = load(grass_mat_path)
	_mat_tilled = load(tilled_mat_path)
	if _mat_grass == null or _mat_tilled == null:
		push_error("Block Ground khong co file .tres")
	set_mode(mode)


func set_mode(v: Mode) -> void:
	mode = v
	if csg:
		csg.material = (_mat_grass if mode == Mode.GRASS else _mat_tilled)


func till_block() -> void:
	if mode != Mode.TILLED:
		set_mode(Mode.TILLED)


#test
static func get_block_from_hit(hit: Object) -> BlockGround:
	if hit is BlockGround:
		return hit
	if hit is Node:
		var n := hit as Node
		while n != null:
			if n is BlockGround:
				return n
			n = n.get_parent()
	return null
