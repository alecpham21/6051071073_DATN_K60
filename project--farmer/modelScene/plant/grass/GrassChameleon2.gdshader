shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_disabled;

uniform sampler2D grass_texture : filter_nearest, source_color;

// Chỉ giữ lại màu đất và biến thiên nhẹ
uniform vec4 terrain_color : source_color;
uniform vec4 color_variation : source_color;

// --- MỚI: THANH CHỈNH TỐC ĐỘ GIÓ ---
// Số càng nhỏ thì lắc càng chậm (Mặc định 0.5 cho nhẹ nhàng)
uniform float wind_speed : hint_range(0.0, 5.0) = 0.5;
// -----------------------------------

// Hàm random
float random(vec2 uv) {
	return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void vertex() {
	// --- PHẦN BILLBOARD (XOAY THEO CAMERA) ---
	vec3 world_origin = MODEL_MATRIX[3].xyz;
	vec3 dir_to_camera = normalize(CAMERA_POSITION_WORLD - world_origin);
	
	dir_to_camera.y = 0.0;
	dir_to_camera = normalize(dir_to_camera);

	vec3 up_vec = vec3(0.0, 1.0, 0.0);
	vec3 new_z = dir_to_camera;
	vec3 new_x = normalize(cross(up_vec, new_z));
	vec3 new_y = cross(new_z, new_x); 

	mat3 rotation_matrix = mat3(new_x, new_y, new_z);
	VERTEX = rotation_matrix * VERTEX;

	// --- PHẦN GIÓ (Đã giảm tốc độ) ---
	
	// Tôi đã thêm biến 'wind_speed' nhân vào chỗ TIME
	// TIME * 1.25 là tần số gốc, nhân thêm wind_speed để làm chậm lại
	float speed_x = 1.25 * wind_speed;
	float speed_z = 0.45 * wind_speed;
	
	// Biên độ lắc (độ nghiêng nhiều hay ít)
	float sway_amount_x = 0.2; // Muốn nghiêng ít hơn thì giảm số này
	float sway_amount_z = 0.15; // Muốn nghiêng ít hơn thì giảm số này

	float sway_x = sin(NODE_POSITION_WORLD.x + TIME * speed_x + UV.y) * (1.0 - UV.y) * sway_amount_x;
	float sway_z = cos(NODE_POSITION_WORLD.z + TIME * speed_z + UV.y) * (1.0 - UV.y) * sway_amount_z;
	
	VERTEX.x += sway_x;
	VERTEX.z += sway_z;

	// KỸ THUẬT "ĐÁNH LỪA ÁNH SÁNG"
	NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	vec4 grass_sample = texture(grass_texture, UV);
	
	if (grass_sample.a < 0.5) {
		discard;
	}

	float noise = random(NODE_POSITION_WORLD.xz);
	vec3 final_color = mix(terrain_color.rgb, color_variation.rgb, noise * 0.2);
	final_color *= grass_sample.rgb;

	ALBEDO = final_color;
}

void light() {
	float NdotL = dot(NORMAL, LIGHT);
	float light_intensity = smoothstep(0.0, 0.05, abs(NdotL));
	float shadow = ATTENUATION;
	DIFFUSE_LIGHT += light_intensity * LIGHT_COLOR * ALBEDO * shadow;
}