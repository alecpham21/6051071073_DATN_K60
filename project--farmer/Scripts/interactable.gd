extends Area3D
class_name InteractArea

signal interacted
var par: Node

func _ready() -> void:
	par = get_parent()
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	if not area_exited.is_connected(_on_area_exited):
		area_exited.connect(_on_area_exited)

func _on_area_entered(area: Area3D) -> void:
	var p = area.get_parent()
	if p and p.has_method("register_interactable"):
		p.register_interactable(par)
		print("✅ [SUCCESS] Đã đăng ký LivestockMachine: ", par.name)

func _on_area_exited(area: Area3D) -> void:
	var p = area.get_parent()
	if p and p.has_method("unregister_interactable"):
		p.unregister_interactable(par)
		print("📢 [EXIT] Đã hủy đăng ký")
