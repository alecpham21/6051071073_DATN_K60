class_name BlockGroundData
enum Mode { GRASS, CUT, TILLED }

var mode: Mode = Mode.GRASS
var has_dark_grass: bool = false
var has_light_grass: bool = false
var crop_ready: bool = false
var plant_type = PlantDatabase.PLANT_VARIANT.NONE
