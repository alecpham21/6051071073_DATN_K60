shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D leaf_texture;
uniform vec4 leaf_color : source_color; // Đúng chuẩn Godot 4.3
uniform float wind_strength = 0.2;
uniform float wind_speed = 2.0;

void vertex() {
    float offset = sin(TIME * wind_speed + VERTEX.x * 0.1) * wind_strength;
    VERTEX.x += offset;
}

void fragment() {
    vec4 tex_color = texture(leaf_texture, UV);
    ALBEDO = tex_color.rgb * leaf_color.rgb;
    ALPHA = tex_color.a;
}
