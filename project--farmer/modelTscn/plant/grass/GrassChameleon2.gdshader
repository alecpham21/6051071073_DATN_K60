shader_type spatial;
// Tắt cull_disabled để nó hiện 2 mặt, các chế độ khác giữ nguyên
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
	// --- PHẦN MỚI: XOAY THEO CAMERA (Y-BILLBOARD) ---
	
	// 1. Lấy vị trí gốc của bụi cỏ trong thế giới thực
	// MODEL_MATRIX[3].xyz là vị trí gốc (origin) của object hiện tại
	vec3 world_origin = MODEL_MATRIX[3].xyz;

	// 2. Tính vector hướng từ gốc cỏ đến camera
	vec3 dir_to_camera = normalize(CAMERA_POSITION_WORLD - world_origin);
	
	// 3. "Ép" phẳng vector này xuống mặt đất (chỉ giữ lại X và Z)
	// Để cỏ chỉ xoay trái phải, không bị ngửa lên trời hay úp xuống đất
	dir_to_camera.y = 0.0;
	dir_to_camera = normalize(dir_to_camera); // Chuẩn hóa lại sau khi ép phẳng

	// 4. Tạo hệ trục tọa độ mới để xoay
	vec3 up_vec = vec3(0.0, 1.0, 0.0); // Trục lên chuẩn của thế giới
	vec3 new_z = dir_to_camera; // Trục Z mới hướng về camera
	vec3 new_x = normalize(cross(up_vec, new_z)); // Trục X mới vuông góc với Y và Z (Tích có hướng)
	// Tính lại trục Y mới để đảm bảo vuông góc hoàn toàn (dù thường thì nó vẫn là 0,1,0)
	vec3 new_y = cross(new_z, new_x); 

	// 5. Tạo ma trận xoay từ 3 trục mới
	mat3 rotation_matrix = mat3(new_x, new_y, new_z);

	// 6. Áp dụng ma trận xoay vào vị trí đỉnh (VERTEX) BAN ĐẦU
	// Lưu ý: Phải xoay trước khi áp dụng gió
	VERTEX = rotation_matrix * VERTEX;


	// --- PHẦN CŨ: HIỆU ỨNG GIÓ (Áp dụng lên VERTEX đã được xoay) ---
	
	// Dùng NODE_POSITION_WORLD để gió đồng bộ trên cả bụi cỏ sau khi đã xoay
	float sway_x = sin(NODE_POSITION_WORLD.x + TIME * 1.25 + UV.y) * (1.0 - UV.y) * 0.2;
	float sway_z = cos(NODE_POSITION_WORLD.z + TIME * 0.45 + UV.y) * (1.0 - UV.y) * 0.15;
	
	// Lúc này VERTEX.x là trục ngang nhìn từ camera, VERTEX.z là trục sâu nhìn từ camera
	VERTEX.x += sway_x;
	VERTEX.z += sway_z;

	// KỸ THUẬT "ĐÁNH LỪA ÁNH SÁNG" (Vẫn giữ nguyên)
	NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	vec4 grass_sample = texture(grass_texture, UV);
	
	// Cắt nền trong suốt
	if (grass_sample.a < 0.5) {
		discard;
	}

	// XỬ LÝ MÀU SẮC
	float noise = random(NODE_POSITION_WORLD.xz);
	vec3 final_color = mix(terrain_color.rgb, color_variation.rgb, noise * 0.2);
	final_color *= grass_sample.rgb;

	ALBEDO = final_color;
}

void light() {
	float NdotL = dot(NORMAL, LIGHT);
	float light_intensity = smoothstep(0.0, 0.05, abs(NdotL));
	
	// Thêm bóng đổ (ATTENUATION) để cỏ có chiều sâu hơn khi có vật che
	float shadow = ATTENUATION;
	DIFFUSE_LIGHT += light_intensity * LIGHT_COLOR * ALBEDO * shadow;
}