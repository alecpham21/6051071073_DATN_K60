shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, unshaded;

uniform sampler2D grass_texture : filter_nearest, source_color;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float brightness_boost : hint_range(0.8, 1.5) = 1.1; 

uniform sampler2D gradient_texture : filter_linear_mipmap, source_color;
uniform float gradient_blend : hint_range(0, 1) = 0.5;

void vertex() {
	NORMAL = vec3(0.0, 1.0, 0.0);
	VERTEX.x += sin(NODE_POSITION_WORLD.x + TIME * 1.25 + UV.y) * (1.0 - UV.y) * 0.2;
	VERTEX.z += cos(NODE_POSITION_WORLD.z + TIME * 0.45 + UV.y) * (1.0 - UV.y) * 0.15;
}

void fragment() {
	vec4 grass_sample = texture(grass_texture, UV);
	
	if (grass_sample.a < 0.5) {
		discard;
	}

	// --- LOGIC CHAMELEON ---
	vec3 ground_color = texture(screen_texture, SCREEN_UV).rgb;
	
	vec3 base_color = ground_color * brightness_boost * grass_sample.rgb;
	// -----------------------

	vec3 gradient_color = texture(gradient_texture, vec2(UV.y, 0.5)).rgb;
	
	// Pha Chameleon với Gradient
	vec3 final_color = mix(base_color, base_color * gradient_color, gradient_blend);

	ALBEDO = final_color;
}