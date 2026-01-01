shader_type spatial;
render_mode cull_disabled,diffuse_toon, specular_toon;

// --- PHẦN 1: MÀU ĐẤT ---
// Sửa lỗi: Bỏ ngoặc kép, viết liền
group_uniforms Terrain_Colors; 
uniform sampler2D noise_texture : filter_linear_mipmap;
uniform vec4 color_light : source_color = vec4(0.4, 0.8, 0.4, 1.0);
uniform vec4 color_dark : source_color = vec4(0.2, 0.5, 0.2, 1.0);
uniform float noise_scale = 0.1;

// --- PHẦN 2: TOON SETTINGS ---
group_uniforms Toon_Settings;
uniform int cuts : hint_range(1, 8) = 3;
uniform float wrap : hint_range(-1.0, 1.0) = 0.0;
uniform float steepness : hint_range(1.0, 10.0) = 1.0;

// --- PHẦN 3: SPECULAR ---
group_uniforms Specular;
uniform bool use_specular = true;
uniform float specular_strength : hint_range(0.0, 5.0) = 1.0;
uniform float specular_shininess : hint_range(0.0, 64.0) = 16.0;

// --- PHẦN 4: RIM LIGHT ---
group_uniforms Rim_Light;
uniform bool use_rim = true;
uniform float rim_width : hint_range(0.0, 16.0) = 4.0;
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float rim_sharpness : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float noise_value = texture(noise_texture, world_pos.xz * noise_scale).r;
	vec3 final_color = mix(color_dark.rgb, color_light.rgb, noise_value);
	
	ALBEDO = final_color;
	ROUGHNESS = 0.9; 
}

void light() {
	// Diffuse
	float NdotL = dot(NORMAL, LIGHT);
	float attenuation = ATTENUATION;
	float diffuse_amount = NdotL * attenuation + wrap;
	diffuse_amount *= steepness;
	
	float cuts_inv = 1.0 / float(cuts);
	float diffuse_stepped = floor(diffuse_amount * float(cuts)) * cuts_inv;
	float smooth_diffuse = smoothstep(0.0, 0.05, diffuse_stepped); 
	
	vec3 diffuse_final = ALBEDO * LIGHT_COLOR * smooth_diffuse;
	DIFFUSE_LIGHT += diffuse_final;

	// Specular
	if (use_specular) {
		vec3 H = normalize(VIEW + LIGHT);
		float NdotH = dot(NORMAL, H);
		float specular_intensity = pow(max(0.0, NdotH), specular_shininess);
		float specular_stepped = step(0.5, specular_intensity * attenuation);
		SPECULAR_LIGHT += specular_strength * specular_stepped * LIGHT_COLOR;
	}

	// Rim Light
	if (use_rim) {
		float NdotV = dot(NORMAL, VIEW);
		float rim_intensity = 1.0 - NdotV;
		float rim_light_align = dot(NORMAL, LIGHT); 
		float rim_threshold = pow(rim_intensity, rim_width);
		rim_threshold = smoothstep(rim_sharpness - 0.1, rim_sharpness + 0.1, rim_threshold);
		rim_threshold *= step(0.0, rim_light_align);
		SPECULAR_LIGHT += rim_threshold * rim_color.rgb * LIGHT_COLOR;
	}
}