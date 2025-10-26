extends CanvasLayer

@onready var rect = $ColorRect


func _ready():
	rect.color.a = 0.0
	
func fade_out(duration: float = 1.0) -> void:
	rect.modulate.a = 0.0
	rect.show()
	var tween = create_tween()
	tween.tween_property(rect, "modulate:a", 1.0, duration)
	await tween.finished

func fade_in(duration: float = 1.0) -> void:
	rect.modulate.a = 1.0
	rect.show()
	var tween = create_tween()
	tween.tween_property(rect, "modulate:a", 0.0, duration)
	await tween.finished
	rect.hide()
