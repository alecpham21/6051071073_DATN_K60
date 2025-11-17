class_name AnimationSet
extends Resource

@export_enum(
	"Cooking_Cutting", "Cooking_Pan", "Cooking_Stirring", 
	"Cutting_Plant", "DJ", "DefaultPose", "Fishing_Catch", 
	"Fishing_Drag", "Fishing_Fail", "Fishing_Idle", 
	"Fishing_Start", "Fishing_Sucess", "Harvesting_Hand", 
	"Harvesting_Knife", "Holding", "Holding_Idle", "Holding_Walking", 
	"Idle1", "Idle1_001", "Idle2_Long_Tool", "Interact", "Interact_NPC", 
	"Running", "Seeding", "Till_Dirt", "Tired", "Tired2", "Walking")
var ani_name:String
@export var blend : float = -1
@export var ani_speed : float = 1
@export var from_end : bool = false
@export var play_marker : bool = false
var start_marker : StringName = "start"
var end_marker : StringName = "end"

func play(ani:AnimationPlayer):
	if play_marker: ani.play_section_with_markers(ani_name, start_marker, end_marker, blend, ani_speed, from_end)
	else: ani.play(ani_name, blend, ani_speed, from_end)
