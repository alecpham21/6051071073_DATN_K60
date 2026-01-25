shader_type spatial;
render_mode cull_disabled;

uniform sampler2D texture_albedo : source_color, filter_nearest;
uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 emission_color : source_color = vec4(0.0);
uniform float emission_energy = 0.0;

uniform float sway_speed = 2.0;
uniform float sway_strength = 0.1;

// Instance uniform cho phép mỗi cây có offset riêng trên GPU
instance uniform float sway_phase_offset = 0.0;

void vertex() {
	float strength = VERTEX.y * sway_strength;
	float time = TIME * sway_speed + sway_phase_offset;
	
	// Dùng NODE_POSITION_WORLD để các cây ở vị trí khác nhau có nhịp khác nhau
	float sway = sin(time + NODE_POSITION_WORLD.x + NODE_POSITION_WORLD.z) * strength;
	
	VERTEX.x += sway;
	VERTEX.z += sway * 0.5;
}

void fragment() {
	vec4 tex = texture(texture_albedo, UV);
	ALBEDO = albedo.rgb * tex.rgb;
	EMISSION = emission_color.rgb * emission_energy;
	
	ALPHA = tex.a * albedo.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}