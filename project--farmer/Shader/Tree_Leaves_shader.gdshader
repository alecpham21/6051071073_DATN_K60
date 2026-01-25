shader_type spatial;
render_mode cull_disabled, blend_mix, depth_draw_opaque;

uniform sampler2D leaf_texture : source_color;
uniform vec4 leaf_color : source_color = vec4(1.0,1.0,1.0,1.0);
uniform float alpha_cutoff = 0.1;

uniform float wind_strength = 0.2;
uniform float wind_speed = 2.0;

uniform float fresnelStrength : hint_range(-2.0, 2.0) = 0.5;
uniform float fresnelBlend : hint_range(-1.0,1.0) = 1.0;
uniform vec4 fresnelColor : source_color = vec4(0.58,0.65,0.33,1.0);

void vertex() {
	float offset = sin(TIME * wind_speed + VERTEX.x * 0.1) * wind_strength;
	VERTEX.x += offset;
	

}

void fragment() {
	vec4 tex_color = texture(leaf_texture, UV);
	if (tex_color.a < alpha_cutoff) {
		discard;
	}

	vec3 base_albedo = tex_color.rgb * leaf_color.rgb;
	ALBEDO = base_albedo;
	ALPHA = tex_color.a;

	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	
	vec3 fres_col = base_albedo * (1.0 - fresnelStrength);
	fres_col += fresnelColor.rgb * fresnelStrength;
	fres_col *= fresnel;
	fres_col *= fresnelBlend;
	
	EMISSION = fres_col;
}