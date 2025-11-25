shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_disabled;

uniform sampler2D grass_texture : filter_nearest, source_color;

// Chỉ giữ lại màu đất và biến thiên nhẹ
uniform vec4 terrain_color : source_color;
uniform vec4 color_variation : source_color;

// Hàm random
float random(vec2 uv) {
	return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void vertex() {
	// 1. GIỮ NGUYÊN CHUYỂN ĐỘNG GIÓ
	float sway_x = sin(NODE_POSITION_WORLD.x + TIME * 1.25 + UV.y) * (1.0 - UV.y) * 0.2;
	float sway_z = cos(NODE_POSITION_WORLD.z + TIME * 0.45 + UV.y) * (1.0 - UV.y) * 0.15;
	
	VERTEX.x += sway_x;
	VERTEX.z += sway_z;

	// 2. ÉP PHÁP TUYẾN (Quan trọng nhất để đồng bộ sáng với đất)
	NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	vec4 grass_sample = texture(grass_texture, UV);
	
	// Cắt nền trong suốt
	if (grass_sample.a < 0.5) {
		discard;
	}

	// 3. XỬ LÝ MÀU SẮC ĐƠN GIẢN
	// Random nhẹ để thảm cỏ không bị đều màu quá mức (chết cứng)
	float noise = random(NODE_POSITION_WORLD.xz);
	
	// Pha màu đất với màu biến thiên (khoảng 20% thôi cho tự nhiên)
	vec3 final_color = mix(terrain_color.rgb, color_variation.rgb, noise * 0.2);
	
	// Nhân với texture gốc (Nếu texture bạn là màu trắng thì nó ra đúng màu đất. 
	// Nếu texture có vân xám thì nó sẽ giữ lại vân chi tiết đó)
	final_color *= grass_sample.rgb;

	ALBEDO = final_color;
}

void light() {
	float NdotL = dot(NORMAL, LIGHT);
	
	float light_intensity = smoothstep(0.0, 0.05, abs(NdotL));
	
	DIFFUSE_LIGHT += light_intensity * LIGHT_COLOR * ALBEDO;
}