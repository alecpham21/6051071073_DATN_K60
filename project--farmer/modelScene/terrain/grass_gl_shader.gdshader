shader_type spatial;
render_mode depth_prepass_alpha, cull_disabled, diffuse_toon, specular_disabled, shadows_disabled;

// --- UNIFORMS ---
uniform sampler2D terrain_noise_texture : filter_linear_mipmap; 
uniform vec4 color_light : source_color;
uniform vec4 color_dark : source_color;  
uniform float terrain_scale = 0.1;       
uniform sampler2D grass_texture : filter_nearest, source_color;
uniform float wind_speed : hint_range(0.0, 5.0) = 0.5;

// --- VARYING (KÊNH LIÊN LẠC GIỮA VERTEX VÀ FRAGMENT) ---
// "flat": Quan trọng! Báo cho GPU biết KHÔNG ĐƯỢC làm mượt giá trị này.
// Nó sẽ lấy giá trị của vertex đầu tiên áp cho cả tam giác -> Tạo hiệu ứng màu khối pixel art.
varying flat vec3 v_instance_pos; 

void vertex() {
    // 1. LẤY VỊ TRÍ GỐC CỦA TỪNG BỤI CỎ (QUAN TRỌNG)
    // MODEL_MATRIX[3].xyz là vị trí world của từng instance trong MultiMesh
    vec3 world_origin = MODEL_MATRIX[3].xyz;
    
    // Gửi vị trí này sang Fragment để tô màu
    v_instance_pos = world_origin;

    // 2. BILLBOARD
    vec3 dir_to_camera = normalize(CAMERA_POSITION_WORLD - world_origin);
    dir_to_camera.y = 0.0;
    dir_to_camera = normalize(dir_to_camera);

    vec3 up_vec = vec3(0.0, 1.0, 0.0);
    vec3 new_z = dir_to_camera;
    vec3 new_x = normalize(cross(up_vec, new_z));
    vec3 new_y = cross(new_z, new_x); 

    mat3 rotation_matrix = mat3(new_x, new_y, new_z);
    VERTEX = rotation_matrix * VERTEX;

    // 3. GIÓ (Đã sửa logic để dùng world_origin thay vì NODE_POSITION)
    float speed_x = 1.25 * wind_speed;
    float speed_z = 0.45 * wind_speed;
    float sway_amount_x = 0.2;
    float sway_amount_z = 0.15;

    // Dùng world_origin để mỗi cây cỏ rung rinh khác nhau
    float sway_x = sin(world_origin.x + TIME * speed_x + UV.y) * (1.0 - UV.y) * sway_amount_x;
    float sway_z = cos(world_origin.z + TIME * speed_z + UV.y) * (1.0 - UV.y) * sway_amount_z;
    
    VERTEX.x += sway_x;
    VERTEX.z += sway_z;

    // 4. NORMAL LOCK
    NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
    vec4 grass_sample = texture(grass_texture, UV);
    if (grass_sample.a < 0.5) {
        discard;
    }

    vec2 ground_uv = v_instance_pos.xz * terrain_scale;
    float noise_value = texture(terrain_noise_texture, ground_uv).r;
    
    vec3 final_color = mix(color_dark.rgb, color_light.rgb, noise_value);

    ALBEDO = final_color * grass_sample.rgb; 

    // --- THÊM DÒNG NÀY ĐỂ TẮT OUTLINE ---
    // Ép Normal của mọi pixel cỏ (cả mặt trước và mặt sau) đều hướng thẳng lên trời (World Up)
    // Dòng này cần chuyển (0,1,0) sang View Space để ghi vào Normal Buffer cho Outline Shader đọc
    NORMAL = (VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
}

void light() {
	// --- FIX LỖI NGƯỢC SÁNG ---
	// Lấy vector UP (0,1,0) của thế giới chuyển sang View Space để đồng bộ với LIGHT
	// Không dùng NORMAL vì nó bị Godot lật ngược ở mặt sau
	vec3 world_up_view = (VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
	
	// Tính NdotL bằng vector UP cố định này
	float NdotL = dot(normalize(world_up_view), LIGHT);

	// --- CÁC PHẦN CÒN LẠI GIỮ NGUYÊN ---
	float attenuation = ATTENUATION; 
	
	// Toon Shading Settings
	float cuts = 3.0;
	float wrap = 0.0;
	float steepness = 1.0;

	float diffuse_amount = NdotL * attenuation + wrap;
	diffuse_amount *= steepness;
	
	float cuts_inv = 1.0 / cuts;
	float diffuse_stepped = floor(diffuse_amount * cuts) * cuts_inv;
	float smooth_diffuse = smoothstep(0.0, 0.05, diffuse_stepped); 
	
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * smooth_diffuse;
}
