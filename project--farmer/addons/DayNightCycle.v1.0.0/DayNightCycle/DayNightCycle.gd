extends DirectionalLight3D

@export var worldEnvironment: WorldEnvironment
@export var nightLight: DirectionalLight3D
@export var rotationOffset: Vector3
var sky: ShaderMaterial

# --- BỎ CÁC BIẾN TIME SETTING CŨ ---
# Vì giờ đã có TimeManager quản lý rồi, không chỉnh ở đây nữa
@export var sunriseHour: int = 6
@export var sunsetHour: int = 18

@export_group("Lighting")
@export var dayLightEnergy: float = 1.0
@export var nightLightEnergy: float = 0.1

@export var dayStarIntensity: float
@export var nightStarIntensity: float = 0.5

@export_group("Colors")
@export var transitionSpeed: float = 0.001
@export_subgroup("Sky")
@export var sunriseColor := Color("ffa052")
@export var dayColor := Color("037dff")
@export var sunsetColor := Color("ffa052")
@export var nightColor := Color("000214")
@export var daySunScatter := Color("4c4c4c")
@export var nightSunScatter := Color("0e0929")
var currentColor: Color
var colorToLerp: Color

@export_subgroup("Clouds")
@export var dayCloudColor := Color("ffffff")
@export var nightCloudColor := Color("0a0b18")

var daylightDuration: float
var myRotation: float

## Use these to determine in-game time
var hours: int
var minutes: int

func _ready():
	# References
	if worldEnvironment and worldEnvironment.environment and worldEnvironment.environment.sky:
		sky = worldEnvironment.environment.sky.sky_material
	
	# Tính toán góc quay dựa trên giờ mọc/lặn
	daylightDuration = (sunsetHour - sunriseHour) * 60.0
	myRotation = 180.0 / daylightDuration
	
	# Khởi tạo màu ban đầu ngay lập tức (để tránh bị nháy màu khi vừa vào game)
	var initial_time = TimeManager.current_time
	update_time_vars(initial_time)
	
	# Set màu ngay lập tức không cần Lerp cho frame đầu tiên
	if hours >= sunriseHour and hours < sunsetHour:
		colorToLerp = dayColor
	elif hours == sunsetHour:
		colorToLerp = sunsetColor
	elif hours == sunriseHour:
		colorToLerp = sunriseColor
	else:
		colorToLerp = nightColor
	currentColor = colorToLerp
	
	# Gọi update visuals 1 lần ngay lập tức
	update_visuals(0.1) # Hack nhẹ delta để nó chạy logic

func _physics_process(delta):
	# --- THAY ĐỔI LỚN NHẤT Ở ĐÂY ---
	# Không tự cộng currentTime += delta nữa
	# Mà lấy trực tiếp từ TimeManager
	var current_global_time = TimeManager.current_time
	
	# Cập nhật các biến giờ/phút
	update_time_vars(current_global_time)
	
	# Tính góc quay mặt trời
	var timeSinceSunrise: float = current_global_time - sunriseHour * 60.0
	rotation_degrees = Vector3(timeSinceSunrise * myRotation + 180.0, 0.0, 0.0) + rotationOffset
	
	# Cập nhật màu sắc và ánh sáng
	update_visuals(delta)

func update_time_vars(t_time):
	hours = int(t_time / 60)
	minutes = int(t_time) % 60

func update_visuals(delta):
	if hours == sunriseHour: currentColor = sunriseColor
	elif hours == sunriseHour + 1: currentColor = dayColor
	elif hours == sunsetHour - 1: currentColor = sunsetColor
	elif hours == sunsetHour: currentColor = nightColor
	elif (hours > sunsetHour) or (hours < sunriseHour): currentColor = nightColor 
	
	var lerpSpeed: float = transitionSpeed * TimeManager.speed_multiplier
	
	if sky:
		colorToLerp = colorToLerp.lerp(currentColor, lerpSpeed)
		sky.set_shader_parameter("top_color", colorToLerp)
		sky.set_shader_parameter("bottom_color", colorToLerp)
	
	if hours >= sunriseHour && hours <= sunsetHour - 1:
		# BAN NGÀY
		light_energy = lerp(light_energy, dayLightEnergy, lerpSpeed)
		if nightLight: nightLight.light_energy = lerp(nightLight.light_energy, 0.0, lerpSpeed)
		
		if sky:
			sky.set_shader_parameter("stars_intensity", lerp(sky.get_shader_parameter("stars_intensity"), dayStarIntensity, lerpSpeed))
			
			var cloudLerp: Color = sky.get_shader_parameter("clouds_light_color")
			cloudLerp = cloudLerp.lerp(dayCloudColor, lerpSpeed)
			sky.set_shader_parameter("clouds_light_color", cloudLerp)
			
			var sunLerp: Color = sky.get_shader_parameter("sun_scatter")
			sunLerp = sunLerp.lerp(daySunScatter, lerpSpeed)
			sky.set_shader_parameter("sun_scatter", sunLerp)
	else:
		# BAN ĐÊM
		light_energy = lerp(light_energy, 0.0, lerpSpeed)
		if nightLight: nightLight.light_energy = lerp(nightLight.light_energy, nightLightEnergy, lerpSpeed)
		
		if sky:
			sky.set_shader_parameter("stars_intensity", lerp(sky.get_shader_parameter("stars_intensity"), nightStarIntensity, lerpSpeed))
			
			var cloudLerp: Color = sky.get_shader_parameter("clouds_light_color")
			cloudLerp = cloudLerp.lerp(nightCloudColor, lerpSpeed)
			sky.set_shader_parameter("clouds_light_color", cloudLerp)
			
			var sunLerp: Color = sky.get_shader_parameter("sun_scatter")
			sunLerp = sunLerp.lerp(nightSunScatter, lerpSpeed)
			sky.set_shader_parameter("sun_scatter", sunLerp)
