class_name BlockGroundData
enum Mode { GRASS, CUT, TILLED }

var mode: Mode = Mode.GRASS
var has_dark_grass: bool = false
var has_light_grass: bool = false
var crop_ready: bool = false
var plant_type = PlantDatabase.PLANT_VARIANT.NONE
@export var variant: int = 0
@export var has_wind_grass: bool = false
