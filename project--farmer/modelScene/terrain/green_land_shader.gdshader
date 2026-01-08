shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_toon;

// --- PHẦN 1: MÀU ĐẤT (Cũ) ---
group_uniforms Terrain_Colors;
uniform sampler2D noise_texture : filter_nearest; // Để nearest cho noise đất nếu thích pixel
uniform vec4 color_light : source_color = vec4(0.4, 0.8, 0.4, 1.0);
uniform vec4 color_dark : source_color = vec4(0.2, 0.5, 0.2, 1.0);
uniform float noise_scale = 0.1;

// --- PHẦN 2: CLOUD SHADOW (MỚI THÊM) ---
group_uniforms Cloud_Settings;
uniform sampler2D cloud_noise : filter_linear_mipmap, repeat_enable; // Texture mây (Perlin noise mờ mờ)
uniform vec4 cloud_color : source_color = vec4(0.1, 0.1, 0.3, 1.0); // Màu bóng mây (xanh đậm/tím tối)
uniform float cloud_strength : hint_range(0.0, 1.0) = 0.5; // Độ đậm bóng
uniform float cloud_scale : hint_range(0.0, 0.5) = 0.05; // Độ to của mây
uniform vec2 cloud_speed_1 = vec2(0.5, 0.0); // Lớp 1 trôi
uniform vec2 cloud_speed_2 = vec2(-0.2, 0.1); // Lớp 2 trôi (tạo hiệu ứng biến hình)
uniform float cloud_cutoff : hint_range(0.0, 1.0) = 0.5; // Ngưỡng cắt để tạo mảng miếng pixel
uniform float cloud_fuzziness : hint_range(0.0, 1.0) = 0.1; // Độ mờ viền mây

// CÁI "CLEVER MIX" MÀ ARTIST NÓI:
// Chỉnh cái này để bóng mây không bị kéo giãn trên tường thẳng đứng
uniform vec2 shadow_projection_dir = vec2(0.5, 0.5);

// --- PHẦN 3: TOON SETTINGS (Cũ) ---
group_uniforms Toon_Settings;
uniform int cuts : hint_range(1, 8) = 3;
uniform float wrap : hint_range(-1.0, 1.0) = 0.0;
uniform float steepness : hint_range(1.0, 10.0) = 1.0;

// --- PHẦN 4: SPECULAR/RIM (Tắt mặc định) ---
group_uniforms Specular_Rim;
uniform bool use_specular = false;
uniform bool use_rim = false;

// --- VARYING ---
varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// Hàm tạo mây "biến hình" (FBM giả 2 lớp)
float get_cloud_noise(vec3 world_pos, float time) {
	// Đây là công thức "Clever Mix":
	// UV gốc là XZ (mặt phẳng)
	// Cộng thêm (Y * dir) để bóng "trườn" lên dốc một cách tự nhiên theo hướng sáng,
	// thay vì bị kéo giãn sọc dưa.
	vec2 proj_uv = world_pos.xz + (world_pos.y * shadow_projection_dir);

	vec2 uv1 = proj_uv * cloud_scale + (time * cloud_speed_1 * 0.01);
	vec2 uv2 = proj_uv * cloud_scale * 1.5 + (time * cloud_speed_2 * 0.01); // Lớp 2 nhỏ hơn chút

	float noise1 = texture(cloud_noise, uv1).r;
	float noise2 = texture(cloud_noise, uv2).r;

	// Trộn 2 lớp noise để tạo ra đám mây "đang cuộn" (evolving)
	return mix(noise1, noise2, 0.5);
}

void fragment() {
	// 1. TÍNH MÀU ĐẤT (Cũ)
	float terrain_noise = texture(noise_texture, v_world_pos.xz * noise_scale).r;
	vec3 base_color = mix(color_dark.rgb, color_light.rgb, terrain_noise);

	// 2. TÍNH BÓNG MÂY (Mới)
	float cloud_val = get_cloud_noise(v_world_pos, TIME);

	// Cắt ngưỡng (Threshold) để tạo style Pixel/Toon sắc cạnh
	// smoothstep giúp viền mềm hơn một tí xíu để đỡ bị răng cưa quá mức (hoặc step cứng nếu muốn)
	float cloud_mask = smoothstep(cloud_cutoff, cloud_cutoff + cloud_fuzziness, cloud_val);

	// Trộn màu đất với màu bóng mây dựa trên mask
	vec3 final_color = mix(base_color, base_color * cloud_color.rgb, cloud_mask * cloud_strength);

	ALBEDO = final_color;
	ROUGHNESS = 1.0;
}

void light() {
	// (Giữ nguyên code ánh sáng Toon cũ của bạn ở đây)
	// Diffuse
	float NdotL = dot(NORMAL, LIGHT);
	float diffuse_amount = NdotL * ATTENUATION + wrap;
	diffuse_amount *= steepness;
	float cuts_inv = 1.0 / float(cuts);
	float diffuse_stepped = floor(diffuse_amount * float(cuts)) * cuts_inv;
	float smooth_diffuse = smoothstep(0.0, 0.05, diffuse_stepped);
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * smooth_diffuse;
}