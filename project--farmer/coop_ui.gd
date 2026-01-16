extends Control

@export var row_scene: PackedScene
@onready var row_container = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/RowContainer
@onready var close_button = $PanelContainer/MarginContainer/VBoxContainer/CloseButton

var target_coop: CoopMachine

func _ready():
	close_button.pressed.connect(close) 
	
	if GameData.has_signal("game_state_changed"):
		GameData.game_state_changed.connect(_on_game_state_changed)
	
	hide()

func open(coop: CoopMachine):
	target_coop = coop
	if not target_coop.input_inv.inventory_updated.is_connected(refresh_ui):
		target_coop.input_inv.inventory_updated.connect(refresh_ui.unbind(1))
	if not target_coop.output_inv.inventory_updated.is_connected(refresh_ui):
		target_coop.output_inv.inventory_updated.connect(refresh_ui.unbind(1))
		
	show()
	refresh_ui()
	GState.coop()

func close():
	if GState.is_coop():
		GState.play()
	hide()

func _on_game_state_changed(_old_state, new_state):
	if new_state != GState.state_enum.COOP and visible:
		hide()

func refresh_ui():
	if not target_coop: return
	
	for child in row_container.get_children():
		child.queue_free()
	
	for i in range(target_coop.max_capacity):
		var row = row_scene.instantiate()
		row_container.add_child(row)
		row.update_row(i, target_coop)
