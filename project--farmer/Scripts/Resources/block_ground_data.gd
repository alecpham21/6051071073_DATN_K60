class_name BlockGroundData
enum Mode { GRASS, CUT, TILLED, PLANTED, OCCUPIED }

var mode: Mode = Mode.GRASS
var crop_ready: bool = false
var plant_type = PlantDatabase.PLANT_VARIANT.NONE
var has_building: bool = false
var is_watered: bool = false
