extends Node3D

@onready var interact_area: InteractArea = $InteractArea

func _ready() -> void:
	if interact_area:
		interact_area.interacted.connect(_on_interacted)

func _on_interacted():
	var player = PlayerData.player
	if player:
		interact(player)

func interact(_player: CharacterBody3D):
	print("DEBUG: [FastTravelSign] interact called!")
	var fast_travel_ui = get_tree().get_first_node_in_group("fast_travel_ui")
	
	if fast_travel_ui:
		if fast_travel_ui.visible:
			if fast_travel_ui.has_method("close"):
				fast_travel_ui.close()
			else:
				fast_travel_ui.visible = false
				GState.play()
		else:
			fast_travel_ui.open()
	else:
		printerr("DEBUG: [FastTravelSign] ERROR: FastTravelUI not found!")
