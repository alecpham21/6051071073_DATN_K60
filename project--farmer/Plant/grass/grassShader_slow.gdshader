shader_type spatial;
render_mode cull_disabled;

uniform sampler2D leaf_texture : source_color;
uniform vec4 leaf_color : source_color = vec4(1.0);
uniform float wind_strength = 0.04;
uniform float wind_speed = 0.4;
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.5;

void vertex() {
    float offset = sin(TIME * wind_speed + VERTEX.z * 0.1) * wind_strength;
    VERTEX.z += offset;
}

void fragment() {
    vec4 tex_color = texture(leaf_texture, UV);
    if (tex_color.a < alpha_cutoff) {
        discard;
    }
    ALBEDO = tex_color.rgb * leaf_color.rgb;
    ALPHA = tex_color.a;
}
