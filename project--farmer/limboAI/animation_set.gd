class_name AnimationSet
extends Resource

@export_enum(
	"Care_debugging","Care_fertilize","Care_watering","Chatting_hi","Chatting_inLove","Chatting_shy","Cooking_Cutting", "Cooking_Pan", "Cooking_Stirring", 
	"Crouching_Harvest","Cutting_Plant","Cycling", "DJ","DanceRandom_1","DanceRandom_2", "DefaultPose","Feed_livestock", "Fishing_Catch", 
	"Fishing_Drag", "Fishing_Fail", "Fishing_Idle", 
	"Fishing_Start", "Fishing_Sucess","HammerBed_Swing", "Harvesting_Hand", 
	"Harvesting_Knife", "Holding","Holding_Crate_Idle","Holding_Crate_Walking", "Holding_Idle", "Holding_Walking","Human_Cycling", 
	"Idle1", "Idle2_Long_Tool","Idle_sit","Idle_sit_leaning","Idle_thinking", "Interact", "Interact_NPC","Lying_Hammer_Bed", "Mad_Cycling","Placing_low", 
	"Running", "Seeding","Sit","Sit_leaning","Sit_leaning_stand","Sit_stand","Taking_low", "Till_Dirt", "Tired", "Tired2", "Walking")
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
