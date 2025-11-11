extends Node

var current_stage: Node = null
var player_inventory = {}
var gold: int = 0
var last_door_id: String = ""

func set_current_stage(stage: Node):
	current_stage = stage

func get_current_stage() -> Node:
	return current_stage

func _ready() -> void:
	pass
	#InventoryData.inv_init()
	#InventoryData.add_item()
	#InventoryData.add_item()
	#InventoryData.add_item()
	#InventoryData.add_item()
	#HotBar.select_hand(0)

func _input(event):
	pass
	#if GState.is_playing():
		#if event.is_action_pressed("item_slot_0"):
			#HotBar.select_hand(0)
		#if event.is_action_pressed("item_slot_1"):
			#HotBar.select_hand(1)
		#if event.is_action_pressed("item_slot_2"):
			#HotBar.select_hand(2)
		#if event.is_action_pressed("item_slot_3"):
			#HotBar.select_hand(3)
		#if event.is_action_pressed("item_slot_4"):
			#HotBar.select_hand(4)
		#if event.is_action_pressed("item_slot_5"):
			#HotBar.select_hand(5)
		#if event.is_action_pressed("item_slot_6"):
			#HotBar.select_hand(6)
	#if event.is_action_pressed("ui_cancel"):
		#match GState.game_state:
			##GState.state_enum.PLAYING: GState.pause()
			#_: GState.play()
