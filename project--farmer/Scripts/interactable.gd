extends Area3D
class_name InteractArea

signal interacted


func interact():
	interacted.emit()
