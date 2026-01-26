shader_type spatial;
render_mode depth_prepass_alpha, cull_disabled, diffuse_toon, specular_disabled;

uniform sampler2D terrain_noise_texture : filter_linear_mipmap; 
uniform vec4 color_light : source_color;
uniform vec4 color_dark : source_color;  
uniform float terrain_scale = 0.1;        
uniform sampler2D grass_texture : filter_nearest, source_color;
uniform float wind_speed : hint_range(0.0, 5.0) = 0.5;

// --- CLOUD SHADOW ---
group_uniforms Cloud_Settings;
uniform bool use_clouds = true; // Tick để bật/tắt mây
uniform sampler2D cloud_noise : filter_linear_mipmap, repeat_enable;
uniform vec4 cloud_color : source_color = vec4(0.1, 0.1, 0.3, 1.0);
uniform float cloud_strength : hint_range(0.0, 1.0) = 0.5;
uniform float cloud_scale : hint_range(0.0, 0.5) = 0.05;
uniform vec2 cloud_speed_1 = vec2(0.5, 0.0);
uniform vec2 cloud_speed_2 = vec2(-0.2, 0.1);
uniform float cloud_cutoff : hint_range(0.0, 1.0) = 0.5;
uniform float cloud_fuzziness : hint_range(0.0, 1.0) = 0.1;
uniform vec2 shadow_projection_dir = vec2(0.5, 0.5); 

// --- VARYING ---
varying flat vec3 v_instance_pos; 

// --- HÀM TÍNH MÂY ---
float get_cloud_noise(vec3 world_pos, float time) {
	vec2 proj_uv = world_pos.xz + (world_pos.y * shadow_projection_dir);
	vec2 uv1 = proj_uv * cloud_scale + (time * cloud_speed_1 * 0.01);
	vec2 uv2 = proj_uv * cloud_scale * 1.5 + (time * cloud_speed_2 * 0.01);
	float noise1 = texture(cloud_noise, uv1).r;
	float noise2 = texture(cloud_noise, uv2).r;
	return mix(noise1, noise2, 0.5);
}

void vertex() {
	vec3 world_origin = MODEL_MATRIX[3].xyz;
	v_instance_pos = world_origin;

	// BILLBOARD
	vec3 dir_to_camera = normalize(CAMERA_POSITION_WORLD - world_origin);
	dir_to_camera.y = 0.0;
	dir_to_camera = normalize(dir_to_camera);

	vec3 up_vec = vec3(0.0, 1.0, 0.0);
	vec3 new_z = dir_to_camera;
	vec3 new_x = normalize(cross(up_vec, new_z));
	vec3 new_y = cross(new_z, new_x); 

	mat3 rotation_matrix = mat3(new_x, new_y, new_z);
	VERTEX = rotation_matrix * VERTEX;

	// GIÓ
	float speed_x = 1.25 * wind_speed;
	float speed_z = 0.45 * wind_speed;
	float sway_x = sin(world_origin.x + TIME * speed_x + UV.y) * (1.0 - UV.y) * 0.2;
	float sway_z = cos(world_origin.z + TIME * speed_z + UV.y) * (1.0 - UV.y) * 0.15;
	VERTEX.x += sway_x;
	VERTEX.z += sway_z;

	NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	vec4 grass_sample = texture(grass_texture, UV);
	if (grass_sample.a < 0.5) {
		discard;
	}

	// 1. Màu nền khớp đất
	vec2 ground_uv = v_instance_pos.xz * terrain_scale;
	float noise_value = texture(terrain_noise_texture, ground_uv).r;
	vec3 base_color_mix = mix(color_dark.rgb, color_light.rgb, noise_value);
	vec3 grass_final_color = base_color_mix * grass_sample.rgb;

	// 2. Tính mây nếu bật
	if (use_clouds) {
		float cloud_val = get_cloud_noise(v_instance_pos, TIME);
		float cloud_mask = smoothstep(cloud_cutoff, cloud_cutoff + cloud_fuzziness, cloud_val);
		grass_final_color = mix(grass_final_color, grass_final_color * cloud_color.rgb, cloud_mask * cloud_strength);
	}

	ALBEDO = grass_final_color; 
	NORMAL = (VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
}

void light() {
	vec3 world_up_view = (VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
	float NdotL = dot(normalize(world_up_view), LIGHT);
	float cuts_f = 3.0; 
	
	float stepped_atten = floor(ATTENUATION * cuts_f) / cuts_f;
	float diffuse_stepped = floor(NdotL * cuts_f) / cuts_f;
	
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * stepped_atten * smoothstep(0.0, 0.05, diffuse_stepped);
}